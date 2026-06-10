# Running a Skill Eval — Agent-Executable Protocol

This is a precise checklist an orchestrating Claude agent follows to run the held-out
competence eval for one skill and record the result. It implements the two-condition protocol
in [../EVALS.md](../EVALS.md). A fresh agent should be able to run a full eval for one skill
using only this file.

> **Held-out discipline (non-negotiable):** the *answer key is never shown* to a baseline or
> skilled agent. Only the judge sees it. Never paste `answer-key.md` into a solving agent's
> context. Never copy eval text into a skill or skill text into an eval.

---

## Inputs

For skill `X`:
- `evals/X/situations.md` — the numbered scenario prompts (Situation text only).
- `evals/X/answer-key.md` — competent move + tempting-but-wrong + verify, per scenario (judge only).
- `<skill-path>/SKILL.md` (+ its `references/`) — the skill under test. Find `<skill-path>` by
  matching `name: X` (e.g. `salesforce/skills/X/SKILL.md`).

## Output

A row appended to [RESULTS.md](RESULTS.md) and a short per-scenario table saved alongside (or
pasted into the run summary).

---

## Procedure

### Step 0 — Pick the model and count the scenarios
Choose the model under test (record its exact id, e.g. `claude-opus-4-8`). Read
`situations.md` and note `N` = number of numbered scenarios.

### Step 1 — Baseline condition (no skill)
Spawn a **fresh** sub-agent (the `Agent` tool, or `claude -p` in a clean working dir) with **no
access to the repo and no skill loaded**. Give it exactly:

> "You are a domain expert. Answer each of the following numbered scenarios: state the
> competent action and the rule behind it, name the tempting-but-wrong move, and give a
> concrete verify step. Be specific. Here are the scenarios:\n\n<paste situations.md verbatim>"

Collect its answers as `baseline_answers` (keyed by scenario number). The agent must NOT see
`answer-key.md` or the skill.

### Step 2 — Skilled condition (skill loaded)
Spawn another **fresh** sub-agent. Give it the **full `SKILL.md` body plus its `references/`
files** (paste them, or instruct it to read `<skill-path>/`), then the **same** situations and
the same instruction as Step 1. Collect `skilled_answers`. Still NO answer key.

### Step 3 — Judge each answer
Spawn a **judge** sub-agent (ideally a panel of 3 for reliability; take the majority/мaverage).
For each scenario `i`, give the judge: the situation text, the scenario's entry from
`answer-key.md`, and ONE candidate answer (run the judge once per condition per scenario).
Instruct the judge to grade on the EVALS.md rubric:

- **1.0 (PASS)** — identifies the competent action AND avoids the tempting-but-wrong trap.
- **0.5 (Partial)** — right instinct, misses the key rule or the trap.
- **0.0 (FAIL)** — wrong action, or falls for the trap.

The judge returns `{score, one-line justification}`. Blind the judge to which condition it is
grading (don't tell it "baseline" vs "skilled").

### Step 4 — Aggregate
- `baseline_rate = mean(baseline scores) / 1.0` as a percentage.
- `skilled_rate  = mean(skilled scores)` as a percentage.
- `knowledge_lift = skilled_rate − baseline_rate`.
- Build a per-scenario table: `# | baseline | skilled | note`.

### Step 5 — Verdict and record
- **Publish-ready** if `skilled_rate ≥ 85%` AND `knowledge_lift > 0` (EVALS.md threshold).
- **Needs content pass** otherwise — and the per-scenario table localizes the gap: any scenario
  the skilled agent failed points at the section that needs deepening. File it (see the
  learning loop) as a content-gap item.
- Append/Update the skill's row in [RESULTS.md](RESULTS.md) with date, model, baseline, skilled,
  lift, and status. Keep prior rows — the history is the trend line.

---

## Lens 2 — Trigger testing (routing)

Cheap and run on every `description` edit. Inputs: `evals/<skill>/triggers.md` and **the
`description` frontmatter of every skill in the marketplace** (the router sees nothing else).

1. Build the routing table: collect each skill's `name` + `description` (the validator's `fm`
   helper, or just read the frontmatter).
2. For each phrasing in `triggers.md`, give a fresh sub-agent ONLY the task phrasing and the list
   of `{name: description}` pairs, and ask: "Which single skill best matches this task? Answer
   with one skill name." Do not reveal the expected route.
3. Compare to the expected route in `triggers.md`:
   - "Should route to X" phrasings must return `X`.
   - "Near-miss" phrasings must return the **named sibling**, not `X`.
4. `trigger_pass_rate = correct / total`. A miss means the descriptions overlap or under-specify
   — fix the boundary (and re-run). Record the rate in the scorecard and RESULTS.md.

---

## Application eval (task-based) — Lens 4

Knowledge evals measure *knowing*; they don't catch a skill that knows but can't *do*. If
`evals/X/tasks.md` exists, run the same baseline-vs-skilled split on each task: the agent
produces the work product (a redline, a sharing-model design, a workflow), and the judge grades
the artifact against the task's trap-keyed rubric (trap caught / missed / new error introduced).
Record `application baseline/skilled/lift` in the RESULTS.md row. Application lift is the truest
measure of "certified professional in the project."

---

## Optional: `claude -p` scaffolding

A minimal non-interactive shape (pseudo-code; adapt to your CLI):

```bash
# baseline
claude -p "$(cat evals/$X/situations.md)\n\n<instruction>" --no-tools > /tmp/$X.baseline.md
# skilled
claude -p "$(cat <skill-path>/SKILL.md)\n\n$(cat evals/$X/situations.md)\n\n<instruction>" > /tmp/$X.skilled.md
# judge each — loop scenarios, never expose the key to the solvers
```

Keep the answer key out of the solver invocations. A reference `run-eval.sh` may automate this;
the markdown protocol above is the source of truth.
