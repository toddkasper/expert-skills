# Decision Scenarios — GitHub Actions

Scenarios 2–4 (GITHUB_OUTPUT vs GITHUB_ENV, OIDC org-scope trust, reusable workflow nesting depth) have been inlined into the SKILL.md body. Scenario 1 is also in the body. This file now holds Scenario 5 only.

---

**Scenario 5 — Self-hosted runner on a public repository**

> **Situation:** An open-source project registers a self-hosted GPU runner to the public repo for ML tests. Within a day, a fork PR triggers the workflow on the GPU runner and runs attacker-controlled code. The maintainer is surprised: "The workflow requires approval for first-time contributors."

> **Competent move:** "Require approval for first-time contributors" gates whether a workflow run is created — it does not prevent a workflow from running on a self-hosted runner once triggered. Approved contributors (anyone who has had a PR merged) can trigger runs without approval. Any fork PR code runs on the self-hosted runner once the workflow executes. **Never attach self-hosted runners to public repositories.** For GPU workloads, use GitHub-hosted larger runners (isolated) or a separate private repo — never a self-hosted runner on the public repo.

> **Tempting-but-wrong:** Tightening the approval policy to "require approval for all external contributors." A motivated attacker can wait for a maintainer to approve a benign first PR. The only safe posture is no self-hosted runners on public repos.

> **Verify:** `gh api repos/{owner}/{repo}/actions/runners --jq '.runners[].labels'` to list runners; confirm no self-hosted runners are registered to the public repo. For private GPU runners, restrict via runner groups at the org level to specific private repos only.

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
