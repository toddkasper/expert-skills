---
name: github-actions
description: Authoring, maintaining, and securing GitHub Actions — CI/CD workflows, triggers, matrix builds, contexts and expressions, reusable and composite workflows, custom actions (action.yml; JS/Docker/composite), self-hosted and GitHub-hosted runners, secrets and OIDC cloud auth, and enterprise governance. Use when building, reviewing, or debugging GitHub Actions workflows, pipelines, release automation, or runner/security policy. Scoped and benchmarked by the GitHub Actions (GH-200) certification blueprint.
metadata:
  credential: "GitHub Actions (GH-200)"
  exam-code: GH-200
  domain: github
  type: certification-playbook
  status: current
  last-reviewed: 2026-06-09
  blueprint-verified: 2026-06-07
  blueprint: January 2026 revision
---

# GitHub Actions — Skills Reference

## Overview

**This file is an operational playbook, not an exam outline.** Each section states the rules an agent must apply when building or reviewing Actions automation: syntax constraints, security invariants, decision criteria, and anti-patterns to catch in review. Benchmarked against the GitHub Actions (GH-200) certification blueprint.

> **Load this skill when…** authoring or reviewing GitHub Actions workflow YAML; designing reusable workflows, composite actions, or custom JS/Docker actions; configuring self-hosted runners, OIDC cloud auth, or enterprise runner/policy governance; or hardening an Actions pipeline against script-injection and supply-chain risks.
> **Not this skill:** general Git/GitHub repository administration, branch protection without Actions, or application code in the repository.

> **Study resources, domain weights, and credential logistics:** [references/study-resources.md](references/study-resources.md).

> **Verify steps assume nothing about your tooling** — use your project's MCP/automation, the GitHub CLI (`gh`) and Actions log/`act`/workflow-lint, or the GitHub web UI, in that order of preference.

---

## Uncertainty & Escalation

- **Always re-verify live — volatile facts:** GitHub-hosted runner image versions and pre-installed software (`ubuntu-latest`, `windows-latest`, `macos-latest` image mappings change on a rolling basis) `[volatile — verify live]`, action SHA pins for commonly-used actions (e.g., `actions/checkout`, `actions/setup-node`) `[volatile — verify live]`, free-tier minute allotments and per-minute pricing for larger runners `[volatile — verify live]`, reusable workflow nesting limit (currently 4 levels) `[volatile — verify live]`, artifact retention defaults and per-repo cache quota `[volatile — verify live]`.
- **Live wins:** when the live GitHub platform, workflow logs, or official GitHub docs contradict a claim in this file, the live source is authoritative. Log the discrepancy via the Feedback protocol below so the skill can be corrected.
- **Escalate to a human — do not silently execute:** enterprise runner policy changes (restricting which actions can run org-wide); modifying branch protection rules or required status checks; registering or deregistering self-hosted runners, especially on public repos; force-merging protected branches; rotating or deleting org-level secrets; enabling or disabling Actions for an org or enterprise; any OIDC trust policy change on a production cloud role.
- **Confidence taxonomy:** every fact in this file is considered *stable* unless tagged `[volatile — verify live]` (changes with platform updates) or `[opinion — house style]` (a defensible default, not the only valid choice).

---

## 1. Authoring and Managing Workflows

### Triggers

Every workflow starts with `on:`. Pick the narrowest trigger that fits.

| Pattern | Trigger |
|---|---|
| Push/PR to specific branches | `push: branches:` / `pull_request: branches:` |
| Manual with inputs | `workflow_dispatch: inputs:` |
| Called by another workflow | `workflow_call: inputs: secrets:` |
| Schedule (cron) | `schedule: cron:` |
| Webhook event (e.g. issue labeled) | `on: issues: types: [labeled]` |
| After another workflow completes | `workflow_run: workflows: types: [completed]` |

`workflow_dispatch` inputs have types: `string`, `boolean`, `choice`, `environment`, `number`. Always declare `required` and `default`. Pass inputs into a called workflow via `with:` (for inputs) and `secrets: inherit` or explicit mapping (for secrets).

**Filtering is a first-class cost control:** use `paths:` and `branches:` filters to avoid triggering expensive matrix builds on unrelated changes. A workflow with no filters runs on every push to every branch.

### Jobs, Steps, and Needs

- Jobs run in parallel by default. Use `needs: [job-a, job-b]` to declare dependencies. A job only starts when all its `needs` have succeeded (or set `if: always()` / `if: failure()` to override).
- Steps within a job run sequentially and share the runner filesystem. Use `id:` on steps whose `outputs` you need downstream.
- **Conditional logic:** `if:` expressions are evaluated with `${{ }}` syntax. Use `success()`, `failure()`, `always()`, `cancelled()` status functions. `if: always()` runs even when a previous step fails — use it for cleanup. Omitting `if:` means the step runs only if all prior steps in the job succeeded.

### Matrix Builds

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest]
    node: [18, 20]
  fail-fast: false
  max-parallel: 4
```

- `fail-fast: true` (the default) cancels remaining matrix jobs the moment one fails — useful for cost savings but obscures how many variants are broken. Set `false` when you need full coverage data.
- `include:` adds specific combinations; `exclude:` prunes them.
- Runner image changes affect matrix silently: `ubuntu-20.04` was deprecated; `windows-latest` migrated to Windows Server 2025. Check the runner-images release notes before assuming a matrix is stable.

### Contexts and Expressions

Key contexts: `github`, `runner`, `env`, `vars`, `secrets`, `inputs`, `matrix`, `needs`, `strategy`, `job`, `steps`, `github.event`, `github.ref`.

- Contexts are evaluated at runtime (inside `${{ }}`); some values are only available in certain job phases.
- **Secret leakage in expressions:** never construct a shell command string by interpolating `${{ secrets.FOO }}` directly into a `run:` step's inline script — a log echoing the expression would expose the secret. Instead, pass secrets via environment variables: set `env: MY_SECRET: ${{ secrets.FOO }}` on the step and reference `$MY_SECRET` in the script.
- `github.ref` is the full ref (`refs/heads/main`); `github.ref_name` is the short name (`main`). Use `github.event_name` to branch behavior between push and PR triggers.

### YAML Reuse within a File

YAML anchors and merge keys reduce repetition within a single workflow file but are **not** cross-file. Full syntax reference in [references/advanced-features.md](references/advanced-features.md). For cross-workflow reuse, use reusable workflows or composite actions.

### Environments, Protections, and Concurrency

```yaml
environment:
  name: production
  url: ${{ steps.deploy.outputs.url }}
```

Environments support required reviewers, wait timers, and deployment branch restrictions. A job targeting a protected environment pauses until a reviewer approves — the primary declarative approval gate in Actions.

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

`cancel-in-progress: true` cancels any in-progress run for the same group when a new one starts — essential for branch-based CD to avoid simultaneous deployments. For the default branch where you never want to drop a run, set `cancel-in-progress: false`.

**Red flags in review:** `on: push:` with no `branches:` filter on a high-traffic repo (every push triggers a full matrix); `if: always()` on a deploy step that should only run on success; `fail-fast: true` on a cross-OS test matrix where you need all failure data; `${{ secrets.X }}` interpolated directly into a `run:` command string.

---

## 2. Consuming Workflows and Troubleshooting

### Reusable Workflows vs. Composite Actions vs. Starter Workflows

| | Reusable workflow | Composite action | Starter workflow |
|---|---|---|---|
| Definition location | `.github/workflows/` in a repo | `action.yml` in a repo | `.github/workflow-templates/` in org `.github` repo |
| Invoked via | `uses: org/repo/.github/workflows/ci.yml@ref` | `uses: org/repo/path@ref` (as a step) | Copied into a new repo (scaffold, then independent) |
| Gets own runners? | Yes — each job in the called workflow spawns its own runner | No — runs as steps on the caller's runner | N/A — it's a scaffold, not live invocation |
| Passes secrets | `secrets: inherit` or explicit map | via `inputs:` (secrets not natively supported; pass via env) | N/A |
| Best for | Full job/pipeline reuse across repos | Step-level logic encapsulation | Giving teams a starting template |

Caller limitations: a reusable workflow can itself call another reusable workflow, up to 4 levels deep. The called workflow's jobs appear in the caller's UI as nested job groups.

### Artifacts and Caching

- **Artifacts** (`actions/upload-artifact` / `actions/download-artifact`) persist files across jobs within a run, or across runs if `retention-days:` is set. Default retention is 90 days (configurable at repo/org level). Artifacts are scoped to a workflow run.
- **Cache** (`actions/cache`) restores and saves by key + restore-keys. Cache is branch-scoped: a PR branch can read from the default branch cache but not write to it. Cache entries expire after 7 days of no access (or when the repo's 10 GB quota is reached and old entries are evicted).
- **Do not confuse them:** use cache for build/dependency artifacts that are reproducible (node_modules, Gradle cache, pip wheels); use artifacts for files you need to keep (test reports, build binaries, signed packages).

### Passing Data Between Jobs

Three mechanisms, in order of preference:

1. **`GITHUB_OUTPUT`** — write `key=value` to `$GITHUB_OUTPUT` in a step; reference via `${{ needs.job-id.outputs.key }}` in downstream jobs. This is the current pattern; `::set-output` is deprecated.
2. **`GITHUB_ENV`** — write `VAR=value` to `$GITHUB_ENV`; available in all subsequent steps of the same job only (not across jobs).
3. **Artifacts** — when the data is a file or too large for an output string.

**Job summaries:** write Markdown to `$GITHUB_STEP_SUMMARY` to generate rich per-job summaries visible in the Actions UI (test results tables, coverage badges, links). No output variable needed — it renders automatically.

### Troubleshooting Failed Runs

1. **Check the job log:** expand each step; the red X pinpoints the failing step. Look for exit code, error message, and preceding output.
2. **Enable debug logging:** set repository secret `ACTIONS_STEP_DEBUG=true` and `ACTIONS_RUNNER_DEBUG=true` for verbose runner/step logs on the next run.
3. **Matrix failures:** you can re-run individual matrix jobs (not the whole matrix) from the UI — use this to confirm a fix without burning the full matrix.
4. **Interpret YAML anchors in logs:** anchors and aliases are expanded at parse time; the log shows the resolved commands, not the anchor reference.

**Red flags in review:** downloading artifacts in a job with no corresponding upload; relying on `GITHUB_ENV` to pass data across jobs (it only spans within a job); cache keys with no versioning component (a dependency upgrade won't bust the cache).

---

## 3. Authoring Custom Actions

Three action types: **JavaScript** (Node.js, fast, cross-OS, no container spin-up), **Docker** (custom OS/tools, compiled binaries), **Composite** (YAML steps, runs on the caller's runner). With immutable actions enforcement, floating tags (`@v3`) resolve against a GHCR snapshot rather than the live repo — pin to a full SHA for auditability. Full type comparison table and immutable-actions details: [references/advanced-features.md](references/advanced-features.md) → "Action Types."

### `action.yml` Structure

```yaml
name: My Action
description: One-sentence description
inputs:
  my-input:
    description: What it controls
    required: true
    default: 'fallback'
outputs:
  result:
    description: What is returned
    value: ${{ steps.compute.outputs.result }}
runs:
  using: 'composite'   # or 'node20', 'docker'
  steps: ...
```

- `outputs.value` for composite actions must reference a step output via `${{ steps.<id>.outputs.<name> }}`.
- For JavaScript actions, outputs are set by calling `core.setOutput('result', value)` from the `@actions/core` toolkit.
- `branding:` (`icon` + `color`) is required to publish to the Marketplace but has no effect on functionality.

**Versioning and publishing details** (semantic tags, Marketplace requirements, private actions): [references/advanced-features.md](references/advanced-features.md) → "Action Versioning and Publishing."

**Red flags in review:** a JavaScript action without a compiled `dist/` committed (the runner has no build step; the source must be pre-compiled); a Docker action with no health check or CMD; an action with hardcoded secrets in `action.yml` (use inputs mapped from `secrets:`).

---

## 4. Enterprise Management of Runners and Policies

### Runner Types

| | GitHub-hosted | Self-hosted |
|---|---|---|
| Provisioning | Automatic | You manage |
| Cost | Billed per minute (beyond free tier) | Infrastructure cost; Actions minutes free |
| Isolation | Fresh VM per job | Shared state between jobs unless you clean up |
| OS choice | Ubuntu, Windows, macOS (fixed image versions) | Any OS you provision |
| Preinstalled software | Fixed; see runner-images release notes | You control |
| Network access to private resources | Not without VNET integration or tunneling | Yes (on-prem or VPC) |

**Runner groups** (org/enterprise level) gate which repos can use which self-hosted runners. Default group is accessible to all repos; restrict by creating named groups and assigning repos explicitly.

**Self-hosted runner hardening:**
- Never run self-hosted runners on public repos — any fork PR can trigger a workflow that runs on your runner with your network access.
- Treat the runner machine as untrusted code execution: no persistent credentials on disk, no elevated privileges, ephemeral runners (re-image after each job) preferred for sensitive environments.
- Runner registration tokens expire in 1 hour; do not store them in CI artifacts.

### Secrets and Variables

Three scopes, each inherited downward:

| Scope | Visible to |
|---|---|
| Organization secret | All repos in the org (or selected repos) |
| Repository secret | That repo only |
| Environment secret | Jobs targeting that named environment only |

Variables (`vars.`) follow the same scope hierarchy and are non-sensitive (appear in logs as plain text). Use variables for configuration values (region, URL, feature flags); use secrets for credentials.

- **Access in workflows:** `${{ secrets.NAME }}` / `${{ vars.NAME }}`. Secrets are masked in logs (replaced with `***`); variables are not.
- **Programmatic management:** REST API endpoints exist for CRUD on org/repo/environment secrets and variables — useful for rotation automation.
- `secrets.GITHUB_TOKEN` is the ephemeral token minted per run (see §5).

### Policies and Governance

At the org and enterprise level, administrators can:
- **Restrict which actions can run:** allow only actions from GitHub, from verified creators, or a specific allowlist (by `owner/repo@ref` pattern).
- **Require approval for first-time contributors** on public repos.
- **Restrict self-hosted runner registration** to admins (prevent repos from adding their own runners to the org pool).
- **Enforce required status checks** at the branch protection level — specific workflow job names must pass before merge.

**Red flags in review:** a self-hosted runner registered to a public repo; secrets scoped to org-wide when only one repo needs them; no branch protection requiring CI to pass before merge on the default branch.

---

## 5. Security and Optimization

### `GITHUB_TOKEN` — the ephemeral identity

`GITHUB_TOKEN` is minted at workflow start, scoped to the repo, and expires when the run ends. Its default permissions are set at the repo/org level (either "permissive" — read/write to most resources — or "restricted" — read only). Override at the workflow or job level:

```yaml
permissions:
  contents: read
  pull-requests: write
  id-token: write   # required for OIDC
```

**Least privilege rule:** set `permissions:` at the workflow level to the minimum required. If different jobs need different scopes, set a restrictive workflow-level default and override per job. Never leave the default permissive setting active for a workflow that writes to the repo or calls external services.

`GITHUB_TOKEN` cannot trigger other workflow runs by default (prevents infinite loops from push-triggered workflows that commit). Use a PAT or app token only when cross-workflow triggering is genuinely needed, and scope it narrowly.

### OIDC — Eliminating Long-Lived Cloud Credentials

OIDC lets a workflow authenticate to a cloud provider (AWS, Azure, GCP) without storing a long-lived key as a secret. The workflow requests a short-lived token from GitHub's OIDC provider, which the cloud provider validates.

Requirements:
1. `permissions: id-token: write` in the workflow/job.
2. A cloud provider trust policy that grants access only when the OIDC token's claims match expected values (`repository`, `ref`, `environment`, `workflow`).
3. A setup action provided by the cloud provider (e.g., `aws-actions/configure-aws-credentials`, `azure/login`, `google-github-actions/auth`) that exchanges the token.

**Scope the trust policy tightly:** restrict to a specific repo, branch, or environment in the cloud trust policy — not to the entire org. An overly broad trust allows any repo in the org to assume the role.

### Pinning Actions to Commit SHAs

```yaml
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2
```

Pinning to a full SHA is the only guarantee that the action code cannot change between runs. Tags are mutable; a malicious or compromised publisher can repoint `v4` to different code. SHA-pinning is especially important for actions that have `id-token: write` or elevated `contents: write` permission.

With immutable actions enforcement on GitHub-hosted runners, GitHub resolves tag-pinned actions from an immutable GHCR snapshot — this closes the tag-mutation attack vector for hosted runners, but SHA pinning remains the best practice for auditability and self-hosted runner consistency.

### Script Injection

Script injection occurs when user-controlled input (e.g., a PR title, issue body, branch name) is interpolated into a `run:` shell script via `${{ github.event.pull_request.title }}`. An attacker can craft a PR title containing shell metacharacters to execute arbitrary code.

**Mitigations:**
- Pass untrusted context values through an intermediate environment variable, never directly into the script body:
  ```yaml
  env:
    PR_TITLE: ${{ github.event.pull_request.title }}
  run: echo "$PR_TITLE"   # shell-quoted variable, not ${{ }} expression
  ```
- Prefer vetted marketplace actions over inline `run:` scripts for complex processing.
- Never grant `pull_request_target` workflows write permissions without careful review — this trigger runs in the context of the base repo (with secrets access) even for fork PRs.

**Artifact Attestations (SLSA provenance):** generate and verify signed build provenance for release artifacts. Full details, required permissions, and verify steps: [references/advanced-features.md](references/advanced-features.md) → "Artifact Attestations."

**Red flags in review:** `permissions: write-all` or unscoped permissions on any workflow; `${{ github.event.*.body }}` or similar user-controlled context values inside a `run:` script; a `pull_request_target` workflow that checks out the PR head and runs it (classic code-exec attack surface); floating action tags (`@main`, `@v3`) without a SHA comment; OIDC trust policies scoped to an entire org rather than a specific repo+branch.

---

## Executable Workflows

### Workflow 1 — Ship a Reusable Workflow Safely (Typed Inputs/Secrets → Pin Actions to SHA → Test from a Caller)

1. Create `.github/workflows/reusable-build.yml` in the shared repo. Declare `on: workflow_call:` with typed inputs (`string`, `boolean`, `choice`) and explicit secret declarations; set `required:` and `default:` on every input.
   → gate: `gh workflow list --repo platform-org/platform` shows the file; it must NOT appear as a directly triggerable workflow (only callable via `workflow_call`).
2. Pin every third-party action to a full 40-char SHA: `uses: actions/checkout@<sha>  # v4.x.x`.
   → gate: `grep -r 'uses:' .github/workflows/reusable-build.yml | grep -v '@[0-9a-f]\{40\}'` returns no lines.
3. Set `permissions:` at workflow level to the minimum required (e.g., `contents: read`).
   → gate: `permissions:` block present; no job declares `write-all` or omits `permissions:`.
4. In a caller repo, invoke the reusable workflow via `uses: platform-org/platform/.github/workflows/reusable-build.yml@main` with `with:` inputs and `secrets: inherit` (or explicit mapping).
   → gate: `gh workflow run` triggers it; called workflow's jobs appear as nested groups in the caller UI; a debug step echoing `${{ inputs.my-input }}` confirms inputs are received.
5. Confirm secrets are masked: all secret values in step logs must appear as `***`; if any appear in plain text the secret was passed via `inputs:` instead of `secrets:` — move it to the `secrets:` declaration.

---

### Workflow 2 — Set Up OIDC Cloud Auth (No Long-Lived Secrets) with a Scoped Trust Policy

1. Add `permissions: id-token: write` to the workflow or job that needs cloud access.
   → gate: run the workflow; if the auth step errors with "credentials could not be loaded" the permission is missing.
2. Create an IAM OIDC identity provider for `token.actions.githubusercontent.com`: `aws iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com --client-id-list sts.amazonaws.com --thumbprint-list <thumbprint>`.
   → gate: `aws iam list-open-id-connect-providers` confirms the provider; `get-open-id-connect-provider` shows the correct URL and client ID.
3. Create the IAM role with a trust policy scoped to the specific repo + branch or environment using `StringEquals` (not `StringLike`) on the `sub` claim: `"repo:my-org/my-service:ref:refs/heads/main"` or `"repo:my-org/my-service:environment:production"`.
   → gate: `aws iam get-role --role-name <role> --query 'Role.AssumeRolePolicyDocument'` — confirm `StringEquals` and the exact repo. Test from a different repo — `AssumeRoleWithWebIdentity` must return `AccessDenied`.
4. Add the cloud provider's setup action (e.g., `aws-actions/configure-aws-credentials@<sha>`) with `role-to-assume:` and `aws-region:` set explicitly.
   → gate: step output shows `Assumed role ... with web identity`; `aws sts get-caller-identity` confirms the expected role ARN.
5. Confirm no long-lived credentials remain: `gh secret list` — delete any `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` after confirming OIDC works end-to-end.

---

### Workflow 3 — Harden a Public-Repo Workflow Against Fork-PR Injection (pull_request_target, Least-Privilege GITHUB_TOKEN)

1. Audit the trigger. If it uses `pull_request_target:`, it runs with base-branch secrets access — the highest-risk trigger for public repos. Check whether it also checks out PR-head code.
   → gate: `grep -r 'pull_request_target' .github/workflows/` — any hit requires review; a `checkout` step with `ref: ${{ github.event.pull_request.head.sha }}` is actively exploitable and must be fixed immediately.
2. Set `permissions: {}` (all deny) as the workflow-level default; grant minimum overrides per job (typical CI: `contents: read`, `pull-requests: write`).
   → gate: `grep -A5 'permissions:' .github/workflows/<workflow>.yml` — no job has `write-all` or omits `permissions:` against the restrictive default.
3. For any step processing user-controlled input (PR title, issue body, branch name), pass through an `env:` variable and reference `$ENV_VAR` in the shell — never interpolate `${{ github.event.pull_request.title }}` directly in a `run:` block.
   → gate: `grep -rn '\${{ github.event' .github/workflows/` — every hit must be in an `env:` assignment, not inside a `run:` body.
4. Pin all external actions to full commit SHAs.
   → gate: `grep -rn 'uses:' .github/workflows/ | grep -v '@[0-9a-f]\{40\}'` — no unpinned external actions.
5. For workflows that must use `pull_request_target` (e.g., posting a comment from a fork), use the two-workflow pattern: `pull_request` (untrusted, no secrets) uploads artifacts; `workflow_run:` (trusted) downloads artifacts and posts the comment — never executes PR code.
   → gate: the `workflow_run` workflow must have no checkout step using the PR head SHA; it only downloads artifacts from the untrusted `pull_request` workflow.

---

## Decision Scenarios

**Scenario 1 — Composite action vs reusable workflow: which for a shared build step**

> **Situation:** A platform team wants to share a "build and push Docker image" sequence across 15 repositories. The sequence is 4 steps: log in to ECR, build image, tag image, push image. A senior engineer proposes creating a reusable workflow (`.github/workflows/docker-build.yml`) in a shared `platform` repo and calling it from each app repo. A colleague suggests a composite action (`action.yml`) instead. The senior engineer says "they do the same thing, just pick one."

> **Competent move:** Use a **composite action**, not a reusable workflow, for step-level logic you want to embed as a step inside a calling job. A composite action runs on the *caller's* runner and shares the runner's filesystem — it can access checked-out source code and build artifacts from preceding steps without artifact uploads/downloads. A reusable workflow spawns its own independent runner(s), requires explicit artifact passing, and counts as a full workflow nesting level against the 4-level limit. For "N steps that run in the context of a caller's job," composite action is the right abstraction.

> **Tempting-but-wrong:** Defaulting to a reusable workflow because it is more familiar. Reusable workflows are the right abstraction for full independent jobs or multi-job pipelines (e.g., a complete deploy pipeline) — not for step sequences that need access to the calling job's runner workspace without artifact overhead.

> **Verify:** In the `action.yml`'s `runs` section, confirm `using: composite` and that `steps:` lists the 4 steps directly; in the calling workflow, the action appears as a single `uses:` step within the job (not as a separate `uses:` at job level). `gh workflow list` in the shared repo should NOT show a new workflow file for a composite action.

---

**Scenario 2 — GITHUB_OUTPUT vs GITHUB_ENV for cross-job data**

> **Situation:** A CI workflow has two jobs: `build` and `deploy`. The `build` job produces a Docker image tag. A developer writes `echo "IMAGE_TAG=$TAG" >> $GITHUB_ENV` and references `${{ env.IMAGE_TAG }}` in the `deploy` job. The workflow runs but `env.IMAGE_TAG` is empty in the `deploy` job.

> **Competent move:** `GITHUB_ENV` propagates environment variables to subsequent steps within the same job only — it does not cross job boundaries. To pass data between jobs, write to `GITHUB_OUTPUT` (`echo "image_tag=$TAG" >> $GITHUB_OUTPUT`), declare a job-level `outputs:` block mapping the output (`image_tag: ${{ steps.<step-id>.outputs.image_tag }}`), and reference it in the `deploy` job via `${{ needs.build.outputs.image_tag }}`. The `deploy` job must also declare `needs: build`.

> **Tempting-but-wrong:** Using an artifact to pass a single string value. Artifacts work for files; for scalars, `GITHUB_OUTPUT` + job outputs is the canonical low-overhead pattern.

> **Verify:** Add `- run: echo "${{ needs.build.outputs.image_tag }}"` as the first step in `deploy` and confirm the tag appears. In the `build` step log, the Actions runner logs `Set output image_tag=<value>`.

---

**Scenario 3 — OIDC trust policy scoped to organization rather than repo+branch**

> **Situation:** A team sets up OIDC federation with AWS. The IAM role trust policy condition is `"StringLike": { "token.actions.githubusercontent.com:sub": "repo:my-org/*" }`. Production deployments succeed. A security reviewer flags the condition as dangerously broad.

> **Competent move:** A wildcard `repo:my-org/*` allows any repository in the org — including forks and any future repo — to assume the production IAM role. Scope the condition to the specific repo and branch or environment: `"StringEquals": { "token.actions.githubusercontent.com:sub": "repo:my-org/my-service:ref:refs/heads/main" }` or `repo:my-org/my-service:environment:production` for protected environments.

> **Tempting-but-wrong:** Adding an environment condition alongside the broad org wildcard. If `StringLike` with `repo:my-org/*` is the sub-claim check, any repo in the org can still assume the role — the repo restriction must be specific.

> **Verify:** `aws iam get-role --role-name <role> --query 'Role.AssumeRolePolicyDocument'` — confirm `StringEquals` (not `StringLike`) and the exact repo+branch or environment. Test from a different repo in the org — `AssumeRoleWithWebIdentity` should return `AccessDenied`.

---

**Scenario 4 — Reusable workflow nesting depth exceeded**

> **Situation:** A platform team builds a layered architecture: `app-pipeline.yml` → `build.yml` → `lint.yml` → `security-scan.yml` → `notify.yml`. The workflow fails at the `notify.yml` level. The team suspects a permissions issue.

> **Competent move:** GitHub Actions limits reusable workflow nesting to 4 levels (caller + 3 levels of called workflows). A fifth level causes a runtime failure, not a permissions error. Fix: promote `notify.yml`'s steps into a composite action and call it from `security-scan.yml`, or collapse layers by inlining notify steps. The 4-level limit is a hard platform constraint `[volatile — verify live]`.

> **Tempting-but-wrong:** Debugging IAM permissions or secrets inheritance first. The nesting-depth error is distinct from permission failures; check the workflow run's error message — it will reference the call depth.

> **Verify:** Count the call chain: caller (1) → build.yml (2) → lint.yml (3) → security-scan.yml (4) → notify.yml (5 = over limit). After refactoring notify into a composite action called from level 4, `gh run list --workflow app-pipeline.yml` should show successful runs.

Further scenario (self-hosted runner on a public repository): [references/scenarios.md](references/scenarios.md).

---

## Operational Rules Quick Reference

- **DO** set `permissions:` explicitly at the workflow level; never rely on the org default permissive setting for a workflow that writes or deploys.
- **DON'T** interpolate `${{ secrets.X }}` or user-controlled context values directly into a `run:` script — use `env:` to pass them as shell variables.
- **DO** pin third-party actions to a full commit SHA and add a comment with the corresponding tag for readability.
- **DON'T** register self-hosted runners to public repos — any fork PR can execute arbitrary code on your runner.
- **DO** use OIDC federation for cloud provider auth; never store long-lived cloud credentials as GitHub secrets.
- **DO** use `concurrency:` with `cancel-in-progress: true` on branch-based CD workflows to prevent simultaneous deployments.
- **DON'T** use `GITHUB_ENV` to pass data between jobs — it only spans steps within the same job; use `GITHUB_OUTPUT` + job `outputs:` for cross-job data.
- **DO** add `paths:` and `branches:` filters to push/PR triggers on large repos to avoid unnecessary matrix runs.
- **DON'T** set `fail-fast: true` (the default) on a matrix where you need complete failure data — set `false` explicitly.
- **DO** treat `pull_request_target` as a high-risk trigger; never check out and execute PR-head code in a `pull_request_target` workflow without explicit isolation.
- **DON'T** use the deprecated `::set-output` command — write to `$GITHUB_OUTPUT` instead.
- **DO** scope OIDC cloud trust policies to a specific repo + branch or environment, never to an entire org.
- **DO** use ephemeral (re-imaged) self-hosted runners for sensitive workloads; never allow persistent state between jobs on shared runners.
- **DON'T** store a runner registration token beyond its 1-hour expiry — regenerate at provisioning time.
- **DO** verify artifact attestations with `gh attestation verify` before deploying release artifacts in security-critical pipelines.

---

## Feedback protocol

Using this skill and hit a wall? If you find a claim contradicted by the live system or official docs, a missing rule that cost you a wrong attempt, or a decision this skill gave no criteria for — append an entry **in the moment** to `.skill-feedback/github-actions.md` at the project root (create it if absent):

`date | skill last-reviewed | claim or gap | what you observed instead | evidence (error text / doc URL / query output) | suggested fix`

These are harvested back into the skill via the learning loop. When the live system and this file disagree, trust the live system.

---

## Changelog

- **2026-06-09** — Conformed to the 12-dimension skill standard: task-vocab description + Scope block, Uncertainty & Escalation guidance with inline `[volatile — verify live]` marks, executable workflows, tool-agnostic verify steps, and the feedback protocol above. Exam logistics relocated to references/study-resources.md; `last-reviewed` set to 2026-06-09.
- **2026-06-09** — Curation pass (inbox: D9 audit finding): inlined 3 decision scenarios into the body (Scenarios 2–4: GITHUB_OUTPUT vs GITHUB_ENV, OIDC org-scope trust, reusable workflow nesting depth) to meet the teaching-scenario standard (≥4 inline). Scenario 5 remains in references. "Versioning and Publishing" and "Artifact Attestations" subsections moved to references/advanced-features.md to offset body length.

---

_Independent educational content for upskilling AI agents. Not affiliated with, authorized by, endorsed by, or sponsored by GitHub, Microsoft, or any certification body. "GitHub," "GitHub Actions," and related marks are property of GitHub, Inc. / Microsoft and are used here for identification purposes only. Guidance only — verify against official documentation and live systems. No certification outcome is implied or guaranteed._
