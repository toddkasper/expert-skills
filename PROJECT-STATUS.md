# Project Status

_Last updated: 2026-06-11 (wind-down). This file is the single place to read where the project
stands, what is evidence-backed, what is not, and how to safely restart measurement._

> **Unofficial / educational.** See [POLICY.md](POLICY.md) and the [README](README.md) disclaimers.
> The product is AI competence; certification blueprints are only the scaffold and benchmark.

---

## Current state — paused at a clean stopping point

- **22 expert skills** (Salesforce ×13, AWS ×3, GitHub ×1, web ×5), each with `SKILL.md`,
  `references/`, and a held-out eval set in `evals/<skill>/`.
- Packaged as Claude Code plugins: `salesforce-skills` 0.3.0, `aws-skills` / `github-skills` /
  `web-skills` 0.2.0.
- **Validator is green** (`scripts/validate.sh`, enforced in CI) — all 22 skills meet the
  structural standard ([docs/SKILL-STANDARD.md](docs/SKILL-STANDARD.md)).
- **Four curation cycles complete** (PRs #1–#4, all merged). The continuous learning loop
  ([docs/LEARNING-LOOP.md](docs/LEARNING-LOOP.md)) has been run end-to-end on its own findings.
- **Feedback inbox is at zero ambiguity** ([feedback/INBOX.md](feedback/INBOX.md)) — every item is
  `integrated`, `closed-noise`, or `deferred` with a one-line reason.

## What is proven

- **Rubric (Lens 1):** all 22 skills clear the publish bar — no dimension < 2, total ≥ 28/36.
- **Knowledge lift (Lens 3, Cycle 4, `claude-opus-4-8`, 3-judge blinded median panel):** positive
  lift on **16 of 22** skills. The **trustworthy, mirror-free wins** — where Cycle-4 curation added
  knowledge the base model lacked — are: **experience-cloud +36.7, pd1 +19.3, typescript +18.8,
  agentforce +14.7, nonprofit +14.7, js-dev-1 +10, aws-devops +9.4, aws-security +5.6, marketing
  +3.6**, each with strong new-probe lift on the corrected facts. This is the core result: the
  curation demonstrably moved the needle on the facts it fixed.
- **Content freshness:** the 72 Cycle-4 Lens-5 audit findings were each re-verified against live
  official sources before integration; one held-out probe was added per integrated lesson.

## Known limitations (read before trusting any number)

These are stated in full at the top of [evals/RESULTS.md](evals/RESULTS.md); in brief:

1. **The mirror-detector over-fires.** It conflates "tests the same fact" with "lifts skill
   wording," so it flagged many cleanly-authored original probes. Mirror flags are a **weak, noisy**
   signal, and the *large* lifts on heavily-flagged skills (**github +66.7, admin, advanced-admin,
   aws-sa**) are **partly fact-overlap-confounded and were not human-reviewed.** Trust the
   **direction** of lift on those rows, not the magnitude.
2. **Cross-cycle deltas are model-confounded.** Cycle 2 used `claude-fable-5`; Cycles 3–4 used
   `claude-opus-4-8`. Only within-run baseline-vs-skilled lift is a valid comparison.
3. **`[volatile — verify live]` blueprint percentages are unconfirmed.** Domain weights / passing
   scores corrected in Cycles 3–4 came from secondary sources and still await official exam-guide
   confirmation. They carry the `[volatile]` marker in-skill.
4. **Saturation on strong models.** pd2, nodejs, react, react-native, and aws-sa overall show zero
   lift — the frontier model already aces them. Not failures; the signal to deepen with genuinely
   obscure operational specifics or accept low-lift.
5. **Lens 4 (application) and Lens 5 (web audit) not re-run in Cycle 4.** App was uninformative
   (ceiling) in prior cycles; Lens 5 was last run in Cycle 3.

## Resume checklist (when measurement restarts)

1. **Detector fix first.** Refine the `evals/run-eval.md` judge instruction so the mirror check
   flags only verbatim / near-verbatim *wording* overlap, not *fact* overlap. This is the deferred
   item in [feedback/INBOX.md](feedback/INBOX.md) and a hard prerequisite — until it lands, the
   flagged Cycle-4 lifts cannot be trusted on magnitude.
2. **Re-run the mirror check** on the heavily-flagged + high-new-probe-lift skills (admin,
   advanced-admin, github, aws-sa) to separate real lift from fact-overlap.
3. **Confirm `[volatile]` blueprint percentages** against official exam guides; clear the markers
   on the ones that hold, correct the ones that don't, and file any change to the inbox.
4. **Sharpen saturated evals** (pd2, nodejs, react, react-native, aws-sa) toward post-cutoff
   operational specifics, or formally accept them as low-lift for frontier models.
5. **Re-run Lens 4 and Lens 5** if a content cycle has occurred since Cycle 4.

Append new dated rows to `evals/RESULTS.md` — never overwrite history. Honor the solver fence
(solvers see only the skill path + situations/tasks prompts; never the answer key, scorecards, or
RESULTS).
