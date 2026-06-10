# Eval situations — github-actions

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

Answer each: state the **competent action** and the **reason**. Be concise (2–4 sentences each).

1. You have a CD workflow triggered by `push:` with no `branches:` filter. It runs a matrix across four OSes and deploys to production. A teammate argues the matrix is the expensive part; you argue the trigger is. Who is right, and what is the single highest-leverage fix?

2. Your `release` job checks out code, builds a binary, and then calls a notify job that announces the release in Slack. The notify job needs the download URL that the build step produces. A colleague sets `GITHUB_ENV` in the build step with the URL. Will this work? If not, why, and what is the correct mechanism?

3. A reusable workflow at `org/platform/.github/workflows/deploy.yml` itself calls another reusable workflow at `org/shared/.github/workflows/checks.yml`, which in turn calls `org/base/.github/workflows/lint.yml`. A fourth reusable workflow is called from `lint.yml`. Will all four levels execute? What is the limit, and what happens if you exceed it?

4. You are reviewing a JavaScript action. The `action.yml` declares `runs.using: 'node20'` and points to `src/index.js`. The `dist/` directory does not exist. Everything passes in a local test using `act`. Will this action work on GitHub-hosted runners in production? Why or why not?

5. Your organization's enterprise policy allows only "GitHub-authored actions and actions from verified creators." A team wants to use `aws-actions/configure-aws-credentials` for OIDC login. Will the policy block it? If so, how should the administrator enable it?

6. A workflow uses `pull_request_target` to post a label on PRs from forks. A new engineer extends it to also check out `${{ github.event.pull_request.head.sha }}` and run the contributor's test suite. The workflow has `contents: read` and `pull-requests: write`. What is the security risk, and what is the correct remediation?

7. You are setting up OIDC federation between GitHub Actions and AWS. The IAM role's trust policy uses `Condition: StringLike: token.actions.githubusercontent.com:sub: repo:my-org/*`. Deployments succeed. A security reviewer flags this as a critical misconfiguration. Why, and what should the condition be?

8. A team has a matrix build across `os: [ubuntu-latest, windows-latest]` and `node: [18, 20]`. One of the four combinations fails in CI. A developer re-runs the entire matrix workflow from the Actions UI to confirm their fix. Is this the most efficient approach? What is the alternative?

9. You add `concurrency: group: ${{ github.workflow }}-${{ github.ref }} cancel-in-progress: true` to your CD workflow. During a late-night release, a colleague pushes a hot-fix directly to `main` while the production deployment is 80% through. What happens, and under what circumstance would you change the setting to prevent this?

10. A workflow step uses `${{ github.event.pull_request.title }}` directly inside a `run:` block to grep for a Jira ticket number: `run: echo "${{ github.event.pull_request.title }}" | grep -E 'PROJ-[0-9]+'`. A security reviewer rejects it. Why? Rewrite the step correctly.

11. Your team pins all third-party actions to a full commit SHA (e.g., `uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683`). A new member argues this is unnecessary because GitHub now resolves tag-pinned actions from an immutable GHCR snapshot. Is the new member correct that SHA pinning is therefore redundant?

12. A workflow passes `secrets: inherit` when calling a reusable workflow. The called workflow's job targets an environment named `production` that has a required reviewer gate and its own environment secrets. Which secrets does the called workflow's job actually see: the inherited org/repo secrets, the environment secrets, or both?
