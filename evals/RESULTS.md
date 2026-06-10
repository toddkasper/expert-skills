# Eval Scoreboard

Per-skill competence results. One row per assessment run — **history is kept**, so lift and
scores are trendable per skill across content/curation cycles. Protocol:
[run-eval.md](run-eval.md). Method and thresholds: [../EVALS.md](../EVALS.md). Per-skill
detail: [scorecards/](scorecards/).

**Publish-ready** (knowledge): skilled ≥ 85% AND lift > 0. **Publish-ready** (rubric): no
dimension < 2 AND total ≥ 28/36. A skill whose lift trends toward zero is restating what models
already know natively — the signal to deepen (new scars) or retire content.

Columns: **K** = knowledge eval (`situations.md`, Lens 3) as `baseline→skilled (lift)`. **App** =
application eval (`tasks.md`, Lens 4), same format. **Rubric** = 12-dimension static audit total
/36 (Lens 1). **Trig** = trigger-test pass rate (Lens 2). `—` = that lens not run yet.

> **Cycle 1 (2026-06-09):** Lens 1 (static rubric) + Lens 2 (trigger routing) run for all 22
> (auditor: static-audit agent). Lens 3–5 (live-model knowledge/application evals + adversarial
> web audit) are a separate session → `pending`. Sub-2 rubric findings filed to
> [../feedback/INBOX.md](../feedback/INBOX.md).

| Skill | Date | Model | K | App | Rubric /36 | Trig | Status |
|---|---|---|---|---|---|---|---|
| salesforce-administrator | 2026-06-09 | static-audit | — | — | 34 | 100% | L3–5 pending; rubric publish-ready |
| salesforce-advanced-administrator | 2026-06-09 | static-audit | — | — | 34 | 100% | L3–5 pending; rubric publish-ready |
| salesforce-platform-developer-1 | 2026-06-09 | static-audit | — | — | 34 | 100% | L3–5 pending; rubric publish-ready |
| salesforce-platform-developer-2 | 2026-06-09 | static-audit | — | — | 34 | 100% | L3–5 pending; rubric publish-ready |
| salesforce-javascript-developer-1 | 2026-06-09 | static-audit | — | — | 32 | 100% | L3–5 pending; rubric publish-ready |
| salesforce-technical-architect | 2026-06-09 | static-audit | — | — | 32 | 100% | L3–5 pending; rubric publish-ready |
| salesforce-business-analyst | 2026-06-09 | static-audit | — | — | 32 | 100% | L3–5 pending; rubric publish-ready (D10 cured) |
| salesforce-sales-cloud-consultant | 2026-06-09 | static-audit | — | — | 32 | 100% | L3–5 pending; rubric publish-ready |
| salesforce-service-cloud-consultant | 2026-06-09 | static-audit | — | — | 33 | 100% | L3–5 pending; rubric publish-ready |
| salesforce-experience-cloud-consultant | 2026-06-09 | static-audit | — | — | 34 | 100% | L3–5 pending; rubric publish-ready (D9 cured) |
| salesforce-marketing-cloud-email-specialist | 2026-06-09 | static-audit | — | — | 32 | 100% | L3–5 pending; rubric publish-ready |
| salesforce-nonprofit-cloud-consultant | 2026-06-09 | static-audit | — | — | 33 | 100% | L3–5 pending; rubric publish-ready |
| salesforce-agentforce-specialist | 2026-06-09 | static-audit | — | — | 33 | 100% | L3–5 pending; rubric publish-ready |
| aws-solutions-architect-professional | 2026-06-09 | static-audit | — | — | 32 | 100% | L3–5 pending; rubric publish-ready (D9/D3 cured) |
| aws-devops-engineer-professional | 2026-06-09 | static-audit | — | — | 32 | 100% | L3–5 pending; rubric publish-ready (D9 cured) |
| aws-security-specialty | 2026-06-09 | static-audit | — | — | 32 | 100% | L3–5 pending; rubric publish-ready (D9 cured) |
| github-actions | 2026-06-09 | static-audit | — | — | 30 | 100% | L3–5 pending; rubric publish-ready (D9 cured; D1/D2=2, no GH sibling) |
| nodejs | 2026-06-09 | static-audit | — | — | 32 | 100% | L3–5 pending; rubric publish-ready |
| typescript | 2026-06-09 | static-audit | — | — | 32 | 100% | L3–5 pending; rubric publish-ready |
| react | 2026-06-09 | static-audit | — | — | 32 | 100% | L3–5 pending; rubric publish-ready (D9 cured) |
| nextjs | 2026-06-09 | static-audit | — | — | 33 | 100% | L3–5 pending; rubric publish-ready |
| react-native | 2026-06-09 | static-audit | — | — | 32 | 100% | L3–5 pending; rubric publish-ready (D9 cured) |
| salesforce-administrator | 2026-06-10 | claude-fable-5 | 91.7→100 (+8.3) | 91.7→91.7 (0) | 34 | 100% | **Knowledge publish-ready** (skilled ≥85, lift >0). App lift 0: both conditions missed the same Task 1 trap (flow fault paths) → content gap filed to INBOX. L5 audit: 9 findings filed |
| react | 2026-06-10 | claude-fable-5 | 87.5→87.5 (0) | 100→100 (0) | 32 | 100% | **Needs content pass** (zero lift — restates model knowledge). NOTE: answer-key.md scenario 6 contradicts react.dev (useTransition vs useDeferredValue) — both conditions scored 0.0 for giving the react.dev-correct answer; fix key + skill together (INBOX). L5: 6 findings filed |
| aws-security-specialty | 2026-06-10 | claude-fable-5 | 100→100 (0) | 100→100 (0) | 32 | 100% | **Eval at ceiling — does not discriminate.** Sharpen scenarios toward post-2024 specifics (Security Hub split, RCP scoping, Extended Threat Detection) per INBOX. L5: 8 findings filed |

_Lens 3–4 (live baseline-vs-skilled) and Lens 5 (adversarial web audit) run in a separate
session per [run-eval.md](run-eval.md). The 8 rubric findings from this cycle (7× D9, 1× D10)
were validated and **cured the same day** via the curation pass (see
[../feedback/INBOX.md](../feedback/INBOX.md)) — rubric totals above reflect the post-curation
state, and all 22 skills now meet the rubric publish bar (no dimension < 2, total ≥ 28)._

> **Cycle 2 (2026-06-10) — pilot Lens 3+4+5 on 3 skills** (salesforce-administrator, react,
> aws-security-specialty), model claude-fable-5 for both conditions. Protocol deviations to fix in
> run-eval.md before the full 22-skill run: (a) single judge per skill grading both candidates
> blinded A/B in one pass, not a 3-judge panel run per-scenario-per-condition; (b) judges read
> `tasks.md` rubrics from disk. Harness lessons: knowledge evals saturate where base models are
> strong (aws ceiling, react zero-lift) — eval items must probe post-cutoff/post-2024 operational
> specifics to discriminate; one answer-key defect found (react #6); Lens 5 findings (23 items)
> filed to the INBOX with sources._
