# Scorecard — <skill-name>

- **Skill:** `<skill-name>`
- **Assessed:** YYYY-MM-DD
- **Model (auditor):** <model id, e.g. claude-opus-4-8>
- **Skill last-reviewed:** YYYY-MM-DD

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | | |
| D2 | Scope contract | | |
| D3 | Operational depth | | |
| D4 | Decision support | | |
| D5 | Failure-mode coverage | | |
| D6 | Verification discipline | | |
| D7 | Uncertainty & escalation | | |
| D8 | Executable workflows | | |
| D9 | Teaching scenarios | | |
| D10 | Context economy | | |
| D11 | Freshness & provenance | | |
| D12 | Measurability | | |
| | **Total** | **/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: <publish-ready | needs content pass>**

Sub-2 dimensions filed as inbox items: <list, or "none">.

---

## Lens 2 — Trigger testing

Source phrasings: `evals/<skill-name>/triggers.md`. Test against descriptions only.

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| | | | |

**Trigger pass rate:** <n/m>.

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/<skill-name>/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: <links / "none">

---

## Notes / trend

<observations across runs — is lift trending toward zero? which sections are weakest?>
