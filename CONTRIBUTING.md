# Contributing

How to add or change a skill in this repo. The pieces are spread across several governing
docs; this file is the **sequence** that ties them together.

## Read first
- [POLICY.md](POLICY.md) — content rules: 100% original, never real exam questions,
  competence-not-credential framing, nominative trademark use, ship the disclaimer, mark
  volatile facts.
- [TEMPLATE.md](TEMPLATE.md) — the canonical skill anatomy (frontmatter + sections, in order).
- [docs/SKILL-STANDARD.md](docs/SKILL-STANDARD.md) — the 12-dimension publish rubric (bar: no
  dimension < 2, total ≥ 28/36).
- [docs/ASSESSMENT.md](docs/ASSESSMENT.md) and [EVALS.md](EVALS.md) — how a skill is measured.
- [docs/LEARNING-LOOP.md](docs/LEARNING-LOOP.md) — how field/eval/audit feedback flows back.

## Add or change a skill — the sequence

1. **Author the SKILL.md** to [TEMPLATE.md](TEMPLATE.md): single-line task-vocab `description`
   (≤ 750 chars, disambiguating); `metadata` with `anchor-credential`, `status`,
   `last-reviewed`, and `blueprint-verified` (cert skills); Overview + Scope block +
   tooling-convention line; numbered domain sections (rules→table→red-flags→verify);
   Uncertainty & Escalation; Executable Workflows; ≥ 4 in-body Decision Scenarios; deduped
   Quick Reference; references pointer; Feedback protocol; Changelog; Disclaimer.
2. **Right-size:** keep every rule/limit/red-flag/verify/workflow in the body; relocate niche
   detail to `references/<topic>.md` with a load cue. Every `references/*.md` must be linked
   from the SKILL.md and carry a disclaimer footer.
3. **Validate:** run `bash scripts/validate.sh` until it exits 0.
4. **Score it (Lens 1 + 2):** write `evals/scorecards/<skill>.md` from
   [`evals/scorecards/_TEMPLATE.md`](evals/scorecards/_TEMPLATE.md) — rubric scores with
   evidence, and the trigger-routing table from `evals/<skill>/triggers.md`.
5. **Hold-out eval set:** `evals/<skill>/` needs `situations.md` + `answer-key.md` (≥ 12
   numbered items), `triggers.md` (Lens 2), and `tasks.md` (Lens 4). These are **held out** —
   never copy eval text into a skill or skill text into an eval.
6. **Measure (Lens 3 + 4):** run [`evals/run-eval.md`](evals/run-eval.md); record a row in
   [`evals/RESULTS.md`](evals/RESULTS.md). Publish bar: skilled ≥ 85% AND lift > 0.
7. **Publish:** only when validate.sh passes, the rubric clears the bar, and the eval clears
   the threshold.

## Changing an existing skill from feedback
Don't hand-edit in response to a one-off report. Route it through the loop
([docs/LEARNING-LOOP.md](docs/LEARNING-LOOP.md)): file to `feedback/INBOX.md` → validate against
official docs → integrate → add a held-out eval scenario probing the lesson → Changelog entry +
bump `last-reviewed` → re-run Lens 2/3 → mark the inbox item `integrated`.

## Versioning (per plugin)
Plugins use semver in `marketplace.json` + `.claude-plugin/plugin.json`:
- **patch** (`0.2.0 → 0.2.1`) — a curation fix: corrected facts, new scars/red flags, eval or
  doc tweaks; no new skill and no section-level restructuring.
- **minor** (`0.2.0 → 0.3.0`) — a new skill added to the plugin, or a substantial content pass
  across existing skills (new sections, re-scoped descriptions).
- **major** (`0.x → 1.0.0`) — first stable release, or a breaking change to plugin identity
  (e.g. a plugin rename or removal) — a namespace break for installers.

Bump `last-reviewed` (and `blueprint-verified` if you re-checked the blueprint) on every
substantive skill edit, and add a `## Changelog` line.

## Don't
- Rename a skill folder or its `name` field (breaks installed namespaces). Plugin-identity
  changes are major bumps and a last resort.
- Put exam logistics (fees, passing scores, retake/proctor details) in a SKILL.md body — they
  live in `references/study-resources.md`.
- Assert a volatile fact (limit, price, version, weight) without marking it
  `[volatile — verify live]` and citing where to confirm.
