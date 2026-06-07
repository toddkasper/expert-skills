# Skill Evaluation Method

How we measure whether a skill actually makes an agent more competent — **not** whether a human
could pass an exam. A skill earns its place only if a skill-loaded agent makes better calls than
the same agent without it.

## What we measure

- **Pass rate** — % of held-out decision scenarios a *skill-loaded* agent answers competently.
- **Lift** — `skilled pass rate − baseline pass rate` (baseline = same agent, no skill). **Lift is
  the skill's real value.** A skill with ~0 lift only restates what the model already knows and
  isn't earning its context.

## Eval set (per skill)

Lives in `evals/<skill-name>/`, **outside** the plugin tree, so a skilled agent under test can't
read the answer key and the scenarios stay held-out.

- `situations.md` — ~12–20 original decision scenarios, **Situation text only** (the prompt).
- `answer-key.md` — each scenario's **competent move**, the **tempting-but-wrong** trap, and the
  **verify** step (the grading rubric).

Rules: original content only (POLICY §rules 1–2 — never real exam questions). **Held-out** — must
not duplicate any teaching scenarios inside the skill. Probe the skill's *value-add* (non-obvious
operational specifics), not generic textbook facts.

## Sourcing eval scenarios

Same clean-room rule as authoring teaching content: use public material to learn *what* is
tested; write the *expression* yourself.

- ✅ **Free official blueprint** (domains, weights, task statements) → build the coverage map so
  the set is complete. These are facts; use freely.
- ✅ **Vendor-published sample questions** (free) → calibrate style and difficulty only. Read
  them; never copy or closely paraphrase.
- ✅ **Real operational situations + the skill's own content** → the actual source of scenarios.
  Operational gotchas (real scars, traps, edge cases) make the sharpest, highest-lift probes —
  usually better than anything modeled on an exam question.
- ❌ **Never** copy or paraphrase actual exam questions — official paid practice exams,
  third-party question banks, or (especially) leaked "braindump" questions. Leaked content is
  not legitimately public; using it violates vendor certification agreements and taints the work.

Why this also protects eval *validity*: original, operationally-grounded scenarios won't be
contaminated by published or leaked question banks that may sit in model training data, so the
measurement stays trustworthy.

## Protocol (two-condition)

1. **Baseline** — an agent answers `situations.md` using only its own knowledge (no skill, no repo files).
2. **Skilled** — an agent answers the same situations with the skill's `SKILL.md` (+ `references/`) available.
3. **Judge** — an LLM judge (a panel, for reliability) grades each answer against `answer-key.md`.
4. **Report** — baseline pass rate, skilled pass rate, lift, and a per-scenario table.

## Rubric (per scenario)

- **PASS (1.0)** — identifies the competent action **and** avoids the tempting-but-wrong option.
- **Partial (0.5)** — right instinct but misses the key rule or the trap.
- **FAIL (0.0)** — wrong action, or falls for the trap.

## Threshold

- **Publish-ready:** skilled pass rate **≥ 85%** AND lift **> 0**.
- **< 85%:** content gaps — prioritize for the content pass.

## Cadence

Run before first publish, and again on any blueprint change or significant skill edit (regression
check). At scale, run as a multi-agent batch: per skill × scenario × condition → judge → aggregate.

## Honesty notes

- This measures *judgment on scenarios* — a proxy for competence, not the real exam.
- Base models already know a lot, so expect **smaller lift on common domains** (e.g. Administrator)
  and **larger lift on niche operational specifics** (NPSP gotchas, Agentforce config). Design
  scenarios to probe what the skill uniquely adds.
