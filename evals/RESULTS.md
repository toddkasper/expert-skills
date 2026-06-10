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
| salesforce-administrator | 2026-06-10 | claude-opus-4-8 | 72.2→86.1 (+13.9) | 100→100 (0) | 34 | 100% | **Cycle 3 — discrimination restored.** Skilled ≥85 AND +13.9 lift; new post-2024 scenarios 13–18 = 66.7→100 (+33.3), 0 mirror flags. App at ceiling (uninformative). 3-judge blinded panel, median. |
| react | 2026-06-10 | claude-opus-4-8 | 100→100 (0) | 100→100 (0) | 32 | 100% | **Cycle 3 — saturated for this model.** Baseline already 100% (incl. the new 19.2 scenarios); zero lift, 0 mirror flags → model already competent on these probes, not a mirroring artifact. Needs sharper/obscurer probes or accept low-lift. |
| aws-security-specialty | 2026-06-10 | claude-opus-4-8 | 100→100 (0) | 100→100 (0) | 32 | 100% | **Cycle 3 — saturated + held-out-hygiene flag.** Zero lift (ceiling). Judges flagged new scenarios **13,14,15 as mirroring skill text** — no lift inflation here (ceiling) but a validity bug → INBOX rewrite before reuse. |

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
>
> **Curation (2026-06-10):** all 23 Cycle-2 findings integrated (see INBOX) — facts corrected,
> react answer-key #6 fixed, coverage gaps closed, and 6 new held-out scenarios added per skill
> (situations 12→18) probing the post-2024 specifics that should restore discrimination.
> run-eval.md now mandates a 3-judge panel + per-scenario blinded A/B grading + a wider solver
> fence (excludes scorecards/RESULTS). **Re-run Lens 3/4 on these 3 skills next**; append new
> dated rows (don't overwrite the Cycle-2 rows above)._
>
> **Cycle 3 (2026-06-10) — re-measure of the 3 curated skills, model `claude-opus-4-8`** (orchestrated
> subagents; 3-judge blinded median panel; solver fence instruction-enforced). Trend point three.
> Result: the curation **restored discrimination on salesforce-administrator** (+13.9 overall, +33.3
> on the new post-2024 scenarios, no mirror flags) — the new scenarios probe facts the base model
> lacks. **react and aws-security-specialty remain at ceiling** (baseline already 100% on
> `claude-opus-4-8`), so zero lift is real saturation, not mirroring — these evals don't discriminate
> for a strong model and need sharper probes (filed). **Held-out-hygiene:** judges flagged
> aws-security new scenarios 13–15 as mirroring skill text (filed for rewrite). NOTE: model differs
> from Cycle-2 (`claude-fable-5`), so cross-cycle deltas are model-confounded; the within-run
> baseline-vs-skilled lift is the valid signal. Application evals all hit ceiling this run
> (uninformative)._
