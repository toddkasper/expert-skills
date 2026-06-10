# Decision Scenarios — GitHub Actions

Four additional judgment scenarios. The inline scenario in SKILL.md covers composite action vs reusable workflow; these cover complementary areas.

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

---

**Scenario 5 — Self-hosted runner on a public repository**

> **Situation:** An open-source project registers a self-hosted GPU runner to the public repo for ML tests. Within a day, a fork PR triggers the workflow on the GPU runner and runs attacker-controlled code. The maintainer is surprised: "The workflow requires approval for first-time contributors."

> **Competent move:** "Require approval for first-time contributors" gates whether a workflow run is created — it does not prevent a workflow from running on a self-hosted runner once triggered. Approved contributors (anyone who has had a PR merged) can trigger runs without approval. Any fork PR code runs on the self-hosted runner once the workflow executes. **Never attach self-hosted runners to public repositories.** For GPU workloads, use GitHub-hosted larger runners (isolated) or a separate private repo — never a self-hosted runner on the public repo.

> **Tempting-but-wrong:** Tightening the approval policy to "require approval for all external contributors." A motivated attacker can wait for a maintainer to approve a benign first PR. The only safe posture is no self-hosted runners on public repos.

> **Verify:** `gh api repos/{owner}/{repo}/actions/runners --jq '.runners[].labels'` to list runners; confirm no self-hosted runners are registered to the public repo. For private GPU runners, restrict via runner groups at the org level to specific private repos only.
