# Application tasks — github-actions (Lens 4, held-out)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

A skilled agent produces the artifact; a judge grades against the trap-keyed rubric. Run baseline vs skilled.

---

## Task 1 — Workflow security redline (injection, secret exposure, token over-privilege)

**Prompt to the agent:** Review the following GitHub Actions workflow. Redline every security flaw — injection vectors, secret-exposure risks, over-privileged tokens, and unsafe action pinning. Name each problem, explain the exploitable risk, and rewrite the affected step or block correctly.

```yaml
name: PR Validate and Deploy

on:
  pull_request_target:
    types: [opened, synchronize]

permissions: write-all

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout PR code
        uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }}

      - name: Install deps
        run: npm ci

      - name: Run tests
        run: npm test

      - name: Post result comment
        run: |
          curl -s -X POST \
            -H "Authorization: token ${{ secrets.GITHUB_TOKEN }}" \
            https://api.github.com/repos/${{ github.repository }}/issues/${{ github.event.pull_request.number }}/comments \
            -d '{"body": "Tests passed for PR: ${{ github.event.pull_request.title }}"}'

  deploy:
    needs: validate
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Deploy to staging
        run: |
          echo "Deploying branch: ${{ github.event.pull_request.head.ref }}"
          ./deploy.sh --env staging --branch ${{ github.event.pull_request.head.ref }}
```

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — `pull_request_target` + checkout of `github.event.pull_request.head.sha` (fork code) allows untrusted fork code to run in a privileged context (with access to secrets and the elevated `GITHUB_TOKEN`). The fix is to never check out fork code in a `pull_request_target` workflow, or to split into a two-workflow pattern: an unprivileged `pull_request` workflow runs tests, and a separate privileged workflow reacts to a completed check result.
- [ ] Trap 2 — `permissions: write-all` grants every available permission to all jobs; must be set to `permissions: {}` at the workflow level and then grant only the specific permissions each job needs (e.g., `pull-requests: write` for the comment job).
- [ ] Trap 3 — `${{ github.event.pull_request.title }}` interpolated directly into a shell `run:` block via the `curl -d` body is a script-injection vector: a PR title containing shell metacharacters or a JSON-breaking string could alter the curl payload or execute arbitrary commands. Assign the value to an environment variable and reference `$ENV_VAR` in the shell instead.
- [ ] Trap 4 — Long-lived AWS IAM access keys (`AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`) stored as repository secrets; must be replaced with OIDC federation (`id-token: write` permission, `role-to-assume` parameter) to eliminate static credentials entirely.
- [ ] Trap 5 — `uses: aws-actions/configure-aws-credentials@v2` is pinned to a mutable tag, not a full commit SHA; a compromised tag push could substitute malicious action code. Pin to the full commit SHA (e.g., `@v2` → `@aaaa...` full 40-char SHA).
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Splits the workflow: uses `pull_request` (unprivileged) for test execution against fork code; uses a separate privileged workflow triggered by `workflow_run` with `types: [completed]` for any action requiring secrets or elevated permissions.
- Sets `permissions: {}` at the top level; adds `pull-requests: write` only to the comment job and `id-token: write` only to the deploy job.
- Moves `github.event.pull_request.title` to an `env:` block (`PR_TITLE: ${{ github.event.pull_request.title }}`) and references `$PR_TITLE` in the shell command.
- Replaces static AWS keys with OIDC: `aws-actions/configure-aws-credentials` with `role-to-assume` and `id-token: write` permission.
- Pins `aws-actions/configure-aws-credentials` to a full commit SHA.

---

## Task 2 — Reusable workflow + self-hosted runner governance redline

**Prompt to the agent:** Review the following reusable workflow definition and its caller. Redline every flaw related to secret inheritance, environment gate bypass, runner trust, and expression safety. Name each problem, explain the risk, and state the fix.

```yaml
# .github/workflows/deploy-reusable.yml  (in org/platform repo)
name: Deploy Reusable

on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
    secrets:
      inherit                      # inherits ALL caller secrets

jobs:
  deploy:
    runs-on: self-hosted           # no labels — any registered runner
    environment: ${{ inputs.environment }}
    steps:
      - uses: actions/checkout@v4  # pinned to tag, not SHA

      - name: Deploy
        run: ./scripts/deploy.sh --env ${{ inputs.environment }}

      - name: Notify Slack
        run: |
          curl -X POST $SLACK_WEBHOOK \
            -d "{\"text\": \"Deployed to ${{ inputs.environment }} by ${{ github.actor }}\"}"
        env:
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK_URL }}

# .github/workflows/caller.yml  (in org/app-repo)
name: Release

on:
  push:
    branches: [main]

jobs:
  call-deploy:
    uses: org/platform/.github/workflows/deploy-reusable.yml@main
    with:
      environment: production
    secrets: inherit
```

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — `runs-on: self-hosted` with no labels means the job can be picked up by **any** self-hosted runner registered to the org, including runners attached to untrusted or lower-security repos. Production deployments must target a specific labeled runner group (e.g., `runs-on: [self-hosted, production, linux]`) scoped to that environment.
- [ ] Trap 2 — `secrets: inherit` in both the reusable workflow declaration and the caller passes every secret available to the caller (org + repo + environment secrets) into the reusable workflow, violating least-privilege. The reusable workflow should declare only the specific secrets it needs as named `secrets:` inputs; the caller should pass only those.
- [ ] Trap 3 — `uses: actions/checkout@v4` pinned to a mutable tag in a production deployment workflow; must be pinned to a full commit SHA to prevent tag-hijacking supply-chain attacks.
- [ ] Trap 4 — `${{ inputs.environment }}` used directly in the `run:` shell command (`./scripts/deploy.sh --env ${{ inputs.environment }}`); if the caller passes a value with shell metacharacters (e.g., `production; rm -rf /`) this becomes a command-injection vector. Assign to an `env:` variable and reference `$ENV_NAME` in the shell.
- [ ] Trap 5 — The caller references the reusable workflow at `@main` (a mutable branch ref); if the platform repo's `main` branch is updated, the caller silently picks up new (potentially breaking or malicious) workflow code. Pin the ref to a specific SHA or a protected semver tag.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Changes `runs-on` to `[self-hosted, production, linux]` (or the org's equivalent label) and documents that self-hosted runner groups must be restricted to specific repos in org settings.
- Replaces `secrets: inherit` in both places with explicit named secrets (`secrets: SLACK_WEBHOOK_URL: required: true` in the reusable workflow; explicit key mapping in the caller).
- Pins `actions/checkout` to a full commit SHA.
- Moves `inputs.environment` to `env: DEPLOY_ENV: ${{ inputs.environment }}` and references `$DEPLOY_ENV` in the shell run step.
- Changes the caller's `@main` ref to a pinned SHA or a protected tag (e.g., `@v1.2.3`) of the platform workflow.
- Notes that the `environment: ${{ inputs.environment }}` dynamic environment name means the required-reviewer gate is applied at runtime based on caller input — this is correct behavior but should be documented as intentional, and the environment name should be validated against an allowlist if possible.
