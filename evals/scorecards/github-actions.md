# Scorecard — github-actions

- **Skill:** `github-actions`
- **Assessed:** 2026-06-09
- **Model (auditor):** claude-sonnet-4-6 (static audit)
- **Skill last-reviewed:** 2026-06-09

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | 2 | Description uses task-vocab terms (workflow YAML, OIDC, composite actions, pull_request_target, SHA pins) and states explicit use-when; scope boundary names "general Git/GitHub repository administration" and "application code" but no sibling skill slugs (no GH siblings exist in this marketplace — acceptable but means no machine-readable routing to a sibling). |
| D2 | Scope contract | 2 | Load/Not-this block in Overview; Uncertainty & Escalation is specific. Not-this boundary ("general Git/GitHub repo admin, branch protection without Actions, application code") is functional but the absence of named sibling skills makes it fuzzier than the AWS trio. |
| D3 | Operational depth | 3 | `GITHUB_TOKEN` cannot trigger downstream workflow runs (infinite-loop prevention); immutable action enforcement on GHCR closes tag-mutation attack; `fail-fast: true` is the default (non-obvious); `GITHUB_ENV` spans steps-only not jobs; composite action runs on caller's runner sharing filesystem — all non-obvious operational facts. |
| D4 | Decision support | 3 | Reusable workflow vs composite action vs starter workflow table (runners, secret passing, invocation method); runner type comparison (GitHub-hosted vs self-hosted × 6 dimensions); action type comparison; secrets scope hierarchy table; trigger selection table — all with deciding constraint. |
| D5 | Failure-mode coverage | 2 | Red flags per section with mechanism; §5 covers `pull_request_target` attack surface in body text; Scenario 1 (composite vs reusable) has full POLICY format. Only 1 full scenario in body; rest in `references/scenarios.md`. |
| D6 | Verification discipline | 3 | `gh workflow list`, `grep` one-liners for SHA pin compliance (`grep -v '@[0-9a-f]\{40\}'`), `aws iam list-open-id-connect-providers` and `aws sts get-caller-identity` for OIDC; each workflow gate is copy-runnable. |
| D7 | Uncertainty & escalation | 3 | Volatile tags on runner image versions, action SHA pins, free-tier pricing, nesting limit, artifact retention defaults; live-wins rule; escalation list covers enterprise policy changes, OIDC trust policy changes, runner registration/deregistration. |
| D8 | Executable workflows | 3 | Three numbered workflows (reusable workflow ship, OIDC cloud auth setup, fork-PR injection hardening); verify gate after each step including negative tests (wrong repo = AccessDenied; secrets as plain text = move to secrets: declaration). |
| D9 | Teaching scenarios | 3 | 4 scenarios now inline in body (POLICY-format): composite vs reusable workflow, GITHUB_OUTPUT vs GITHUB_ENV cross-job data passing, OIDC trust policy org vs repo+branch scope, and self-hosted runner on a public repo fork-PR risk. No sibling skill exists in the github plugin — D1/D2 at 2 is structural, not a content gap. |
| D10 | Context economy | 2 | 4,537 words — in 4,300–5,000 band; content is dense and operational throughout; exam logistics removed; YAML code blocks are justified (syntax is not prose-paraphrasable). **D10 trim flag: reduce toward ≤3,500.** |
| D11 | Freshness & provenance | 2 | `last-reviewed: 2026-06-09`, `blueprint-verified: 2026-06-07` (January 2026 revision); Changelog records one conformance-pass entry; no per-scar source citations. |
| D12 | Measurability | 2 | Eval infra exists (`situations.md`, `tasks.md`, `answer-key.md`) spanning all 5 sections; no model run recorded yet. |
| | **Total** | **30/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: publish-ready**

---

## Lens 2 — Trigger testing

Source phrasings: `evals/github-actions/triggers.md`. Test against descriptions only (from `/tmp/skills-snapshot.md`).

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| "Write a reusable workflow that builds a Docker image, pushes it to ECR using OIDC (no long-lived AWS keys), and can be called from any repo in the org." | github-actions | github-actions — "reusable and composite workflows" + "secrets and OIDC cloud auth" + "building…GitHub Actions workflows" | ✓ |
| "Review this workflow YAML — it uses `pull_request_target` to run tests on fork contributions. Is there a security risk, and how do I fix it?" | github-actions | github-actions — "securing GitHub Actions" + "reviewing…GitHub Actions workflows…runner/security policy" | ✓ |
| "My matrix build across four Node versions runs all four jobs even when only the linting step fails on Node 18. How do I configure fail-fast and which `continue-on-error` setting controls that?" | github-actions | github-actions — "CI/CD workflows, triggers, matrix builds" + "building, reviewing, or debugging GitHub Actions workflows" | ✓ |
| "I need a composite action that wraps our test setup (cache restore, npm ci, env file write) so every repo can call it in one step. Show me the action.yml and how to version-pin it safely." | github-actions | github-actions — "custom actions (action.yml; JS/Docker/composite)" + "building…GitHub Actions workflows" | ✓ |
| "Our release workflow sets `permissions: write-all` at the top level so the publish step can create a GitHub Release. The security team flagged it — what's the minimum permission set I actually need?" | github-actions | github-actions — "enterprise governance" + "securing GitHub Actions" + "reviewing…runner/security policy" | ✓ |
| "Our GitHub org requires branch protection on `main` — how do I enforce required reviewers and prevent force-pushes across all repos from the org settings?" (→ general GitHub repo/org administration — no matching skill) | no skill in marketplace matches | No skill description covers general GitHub org/repo admin without Actions context; github-actions description explicitly excludes "branch protection without Actions." Correct miss. | ✓ |
| "Help me write the Node.js Express middleware that validates the GitHub webhook HMAC signature before processing push events." (→ web:nodejs) | web:nodejs | nodejs — "Building and reviewing Node.js applications and services…HTTP services with security." Application code consuming webhooks. | ✓ |
| "Set up an SQS queue that ingests GitHub push-event payloads forwarded by an API Gateway webhook — design the fan-out to Lambda processors." (→ aws-solutions-architect-professional / general app architecture) | aws-solutions-architect-professional | aws-solutions-architect-professional — "Designing and evaluating complex AWS architectures" + "cost/resilience/performance trade-offs at enterprise scale" — event-driven fan-out architecture design. | ✓ |

**Trigger pass rate: 8/8.**

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/github-actions/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: none

---

## Notes / trend

D9 is the sole structural blocker. Priority targets for the 3 additional in-body scenarios: `GITHUB_OUTPUT` vs `GITHUB_ENV` cross-job data passing (§2 — a very common wrong branch); OIDC trust policy scoped to org vs repo+branch (§5 — overly broad trust is the canonical misconfiguration); and self-hosted runner on a public repo (§4 — fork PR execution is non-obvious to practitioners unfamiliar with runner isolation). D10 trim is meaningful here: at 4,537 words this skill has the most tokens to cut among the four; the YAML code blocks justify some overhead but prose sections can be tightened. D1/D2 at 2 reflect the absence of sibling GH skills to name — if github-admin or github-security skills are ever added to the marketplace, the description and scope block should be updated to reference them by slug.
Cycle-1 curation (2026-06-09): D9 1→3 (4 scenarios now inline) → now publish-ready.
