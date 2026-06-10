# The Assessment Protocol — Exercise Every Skill From All Aspects

Assessment is not a read-through. A skill is exercised the way it will be used. Five lenses,
each producing evidence that lands in the skill's scorecard (`evals/scorecards/<skill>.md`) and
the scoreboard ([`../evals/RESULTS.md`](../evals/RESULTS.md)) so quality is **trendable per skill
over time**. The rubric is in [`SKILL-STANDARD.md`](SKILL-STANDARD.md); findings flow back via
[`LEARNING-LOOP.md`](LEARNING-LOOP.md).

---

## Lens 1 — Static audit (rubric)
Score all 12 dimensions (0–3) with **one line of evidence per score**, citing the file/section.
An auditing agent does this from the files alone. Output → the scorecard's rubric table.
*Publish bar: no dimension < 2, total ≥ 28/36.*

## Lens 2 — Trigger testing
For each skill, 6–10 realistic task phrasings: **4–6 that SHOULD trigger it**, **2–4 near-misses
that should route to a sibling** instead. Test against **descriptions only** — that's all the
router sees. Record hit/miss. The phrasing sets live in `evals/<skill>/triggers.md` and are
reusable regression tests for every future `description` edit.
*Pass: every should-trigger phrase routes here; every near-miss routes to the named sibling.*

## Lens 3 — Knowledge eval (two-condition)
Baseline vs skilled on `situations.md`, judged against `answer-key.md` per
[`../EVALS.md`](../EVALS.md) and run via [`../evals/run-eval.md`](../evals/run-eval.md). Measures
**knowing**. *Pass: skilled ≥ 85% AND lift > 0.*

## Lens 4 — Application eval (task-based)
Knowledge evals can't catch a skill that knows but can't *do*. Each skill has 2–3 task-based
evals in `evals/<skill>/tasks.md`: a realistic work product to produce (review this flawed
config/code and produce the redline; design the sharing model for this org spec; write the
workflow for this release), seeded with the domain's classic traps. A skilled agent performs the
task; a judge grades the artifact against a **trap-keyed rubric** (caught / missed /
introduced-new-error). Run baseline-vs-skilled — **application lift is the truest measure** of
"certified professional in the project."

## Lens 5 — Adversarial freshness & coverage audit
A red-team agent **with live web access to official docs** attacks the skill on three fronts:
- **(a) Staleness** — verify every volatile fact against current official sources.
- **(b) Coverage** — diff the skill's sections against the current cert blueprint / official docs
  ToC; list gaps.
- **(c) Internal contradiction** — any rule stated differently in two places.
Output: a findings list with severity, filed into the feedback inbox
([`../feedback/INBOX.md`](../feedback/INBOX.md)).

---

## Cadence

| Lens | When |
|---|---|
| 1 — Static audit | every significant edit (cheap, automatable) |
| 2 — Trigger tests | every significant edit, especially any `description` change |
| 3 — Knowledge eval | before publish; after any content pass (regression) |
| 4 — Application eval | before publish; after any content pass |
| 5 — Freshness/coverage audit | quarterly, and on any blueprint / major-version change |

All results land in the scorecard and scoreboard. A skill whose lift trends toward zero is
restating what models now know natively — the signal to deepen (new scars) or retire content.

## Scorecard

One per skill at `evals/scorecards/<skill>.md` (template:
[`../evals/scorecards/_TEMPLATE.md`](../evals/scorecards/_TEMPLATE.md)). It records the rubric
scores+evidence (Lens 1), trigger results (Lens 2), and pointers to the latest knowledge/
application runs (Lens 3–4) and audit findings (Lens 5), with the date and model of the run.
