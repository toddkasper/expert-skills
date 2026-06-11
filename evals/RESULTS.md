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

> **Read these numbers honestly — three standing caveats (see the Cycle-4 block at the bottom for
> the full account):**
> 1. **The mirror-detector over-fires.** It conflates "the probe tests the same fact the skill
>    teaches" (expected, fine) with "the answer lifts the skill's *wording*" (the real leakage we
>    care about), so it flagged many cleanly-authored original probes — even whole sets. Treat
>    mirror flags as a **weak, noisy** signal. Where a *large* new-probe lift sits on a
>    heavily-flagged skill (**github +66.7, admin, advanced-admin, aws-sa**), the lift is
>    **partly fact-overlap-confounded and was not human-reviewed** — do not over-trust the
>    magnitude. The fix is filed and **deferred** (project paused); run it before any future cycle.
> 2. **Cross-cycle deltas are model-confounded.** Cycle 2 used `claude-fable-5`; Cycle 3–4 used
>    `claude-opus-4-8`. Only the **within-run baseline-vs-skilled lift** is a valid comparison;
>    do not read trends *across* cycles as like-for-like.
> 3. **`[volatile — verify live]` blueprint percentages are unconfirmed.** Domain weights / passing
>    scores corrected in Cycle 3–4 came from secondary sources (e.g. salesforceben.com) and still
>    **await official exam-guide confirmation**. They carry the `[volatile]` marker in-skill for
>    that reason.
>
> **Bottom line:** on flagged rows, trust the **direction** of lift (the curation helped), not the
> **magnitude**. The unflagged, mirror-free wins (experience-cloud, pd1, typescript, agentforce,
> nonprofit, js-dev-1, aws-devops, aws-security, marketing) are the trustworthy evidence.

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
| salesforce-administrator | 2026-06-10 | claude-opus-4-8 (C4) | 75→91.7 (+16.7) | — | — | — | **C4 knowledge.** new13-18 +25 — but all 6 new probes mirror-flagged → lift partly fact-overlap (see note). |
| salesforce-advanced-administrator | 2026-06-10 | claude-opus-4-8 (C4) | 89.3→100 (+10.7) | — | — | — | **C4.** new +25 (both flagged — partly fact-overlap). |
| salesforce-platform-developer-1 | 2026-06-10 | claude-opus-4-8 (C4) | 71.3→90.6 (+19.3) | — | — | — | **C4 — real lift.** new +25, mirror-free. v67 Apex-sharing + OOE corrections discriminate. |
| salesforce-platform-developer-2 | 2026-06-10 | claude-opus-4-8 (C4) | 100→100 (0) | — | — | — | **C4 — saturated** (model already aces, incl. corrected selectivity probes). |
| salesforce-javascript-developer-1 | 2026-06-10 | claude-opus-4-8 (C4) | 90→100 (+10) | — | — | — | **C4 — real lift.** new +33.3, mirror-free (LWS/Node-runtime corrections). |
| salesforce-technical-architect | 2026-06-10 | claude-opus-4-8 (C4) | 92.9→96.4 (+3.5) | — | — | — | **C4.** new probes 0 lift; broad (noisy) mirror flags. |
| salesforce-business-analyst | 2026-06-10 | claude-opus-4-8 (C4) | 96.2→92.3 (−3.9) | — | — | — | **C4 — NEGATIVE LIFT.** Skilled scored below baseline; skill misled on a scenario → investigate (INBOX). |
| salesforce-sales-cloud-consultant | 2026-06-10 | claude-opus-4-8 (C4) | 82.1→96.4 (+14.3) | — | — | — | **C4.** new +25 (13/14 flagged — partly fact-overlap). |
| salesforce-service-cloud-consultant | 2026-06-10 | claude-opus-4-8 (C4) | 97.1→100 (+2.9) | — | — | — | **C4.** Near-ceiling; new probes 0 lift; broad (noisy) mirror flags. |
| salesforce-experience-cloud-consultant | 2026-06-10 | claude-opus-4-8 (C4) | 63.3→100 (+36.7) | — | — | — | **C4 — biggest real lift.** new +50, mirror-free. Enhanced-LWR/license corrections add genuine knowledge. |
| salesforce-marketing-cloud-email-specialist | 2026-06-10 | claude-opus-4-8 (C4) | 96.4→100 (+3.6) | — | — | — | **C4 — real.** new +25, mirror-free (6-domain blueprint, design domain). |
| salesforce-nonprofit-cloud-consultant | 2026-06-10 | claude-opus-4-8 (C4) | 85.3→100 (+14.7) | — | — | — | **C4 — mostly real.** new +50 (2/5 flagged); Grantmaking-object + Agentforce-Nonprofit corrections. |
| salesforce-agentforce-specialist | 2026-06-10 | claude-opus-4-8 (C4) | 85.3→100 (+14.7) | — | — | — | **C4 — real lift.** new +40, mirror-free (Data 360, blueprint reweight, Dev-Lifecycle/Multi-Agent). |
| aws-solutions-architect-professional | 2026-06-10 | claude-opus-4-8 (C4) | 93.8→93.8 (0) | — | — | — | **C4 — overall saturated**; new +12.5 but all 4 new flagged (fact-overlap), so even that is suspect. |
| aws-devops-engineer-professional | 2026-06-10 | claude-opus-4-8 (C4) | 90.6→100 (+9.4) | — | — | — | **C4 — real lift.** new +12.5, mirror-free (CodeDeploy hooks, FIS/Resilience Hub, DRS, CodeCommit). |
| aws-security-specialty | 2026-06-10 | claude-opus-4-8 (C4) | 94.4→100 (+5.6) | — | — | — | **C4 — real lift** (recovered from Cycle-3 ceiling). new +8.3, mirror-free after the 13-15 rewrite. |
| github-actions | 2026-06-10 | claude-opus-4-8 (C4) | 80→86.7 (+6.7) | — | — | — | **C4.** new +66.7 but all 3 new flagged → likely mirror-inflated; lowest skilled (86.7) — trim+rewrite candidate. |
| nodejs | 2026-06-10 | claude-opus-4-8 (C4) | 96.9→96.9 (0) | — | — | — | **C4 — saturated** (incl. corrected require(esm)/highWaterMark probes). |
| typescript | 2026-06-10 | claude-opus-4-8 (C4) | 78.1→96.9 (+18.8) | — | — | — | **C4 — real lift.** new +50 (only 1/4 flagged); 7.0-timeline + deprecated-vs-removed + 9-flag corrections. |
| react | 2026-06-10 | claude-opus-4-8 (C4) | 100→100 (0) | — | — | — | **C4 — saturated** (broad noisy mirror flags; no new C4 edits this skill). |
| nextjs | 2026-06-10 | claude-opus-4-8 (C4) | 96.2→100 (+3.8) | — | — | — | **C4.** Near-ceiling; new probe 0 lift; broad (noisy) mirror flags. |
| react-native | 2026-06-10 | claude-opus-4-8 (C4) | 100→100 (0) | — | — | — | **C4 — saturated** (broad noisy mirror flags). |

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
>
> **Cycle 3 Lens 5 (2026-06-10) — live-web freshness/coverage/contradiction audit of the 19
> un-pilot skills + volatile-fact confirmation on the 3 pilot skills.** 22 agents, official-source
> cited. **80 findings filed** to [../feedback/INBOX.md](../feedback/INBOX.md) (72 `new` across 19
> skills; the 3 pilot skills' volatile facts confirmed → markers cleared, or corrected in-body and
> filed `integrated`). Dominant themes: stale cert blueprints / domain weights / passing scores
> (most consultant + specialist skills), renamed-or-retired products (QLDB EOL, Snowmobile,
> Social Studio, Einstein Copilot→Agentforce, Data Cloud→Data 360, Nonprofit Cloud→Agentforce
> Nonprofit), and a few hard technical errors (PD2 SOQL selectivity thresholds inverted; Apex
> default sharing now WITH sharing in API v67+; GH reusable-workflow nesting 4→10; a fabricated
> GuardDuty AttackSequence finding type — fixed). One unresolved source conflict: Data Loader
> 5M vs 150M (two official Salesforce pages disagree) → left `[volatile]`, filed `new`. These
> `new` items are the work-list for the next curation cycle (validate → integrate → eval probe)._
>
> **Cycle 4 (2026-06-10) — knowledge-only (Lens 3) across ALL 22 skills, model `claude-opus-4-8`**
> (110 agents; 3-judge blinded median panel; per-scenario parity blinding; instruction-enforced
> solver fence). After the Cycle-4 curation of the 72 audit findings. Honest read:
> - **Positive lift on 16 of 22** (skilled ≥85 AND lift >0). The clearest *real* (mirror-free)
>   wins are exactly where Cycle-4 added knowledge the base model lacked: experience-cloud +36.7,
>   pd1 +19.3, typescript +18.8, agentforce +14.7, nonprofit +14.7, js-dev-1 +10, aws-devops +9.4,
>   aws-security +5.6 (recovered from its Cycle-3 ceiling), marketing +3.6 — with strong
>   **new-probe (n≥13) lift** (+50/+40/+33/+25/+12.5) on the corrected facts. This is the core
>   result: the curation demonstrably moved the needle on the facts it fixed.
> - **Saturated (0 lift):** pd2, nodejs, react, react-native, and aws-sa overall — the frontier
>   model already aces these (incl. corrected probes). Not failures; the signal to deepen with
>   genuinely obscure operational specifics or accept low-lift for strong models.
> - **NEGATIVE lift — business-analyst −3.9** (skilled 92.3 < baseline 96.2): the skill made the
>   solver *worse* on a scenario. Filed for investigation.
> - **Mirror-detector over-fired (methodology caveat):** judges flagged many *original* (n<13)
>   scenarios — even whole sets (react, service-cloud, nextjs, react-native ~all) — which is
>   implausible for cleanly-authored older probes. The detector is conflating "tests the same
>   fact" (expected: a correct answer resembles the skill) with "lifts skill *wording*." So mirror
>   flags here are a **weak/noisy** signal; large new-probe lift on heavily-flagged skills
>   (admin, advanced-admin, **github +66.7**, aws-sa) is **partly fact-overlap-confounded** and
>   should not be over-trusted. Filed a run-eval mirror-instruction refinement.
> - **Cross-cycle/model caveat:** model differs from earlier cycles for some rows; within-run
>   baseline-vs-skilled lift is the valid signal. App (Lens 4) not run this cycle (was uninformative)._
