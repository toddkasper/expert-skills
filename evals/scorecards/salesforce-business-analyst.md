# Scorecard — salesforce-business-analyst

- **Skill:** `salesforce-business-analyst`
- **Assessed:** 2026-06-09
- **Model (auditor):** claude-sonnet-4-6 (static audit)
- **Skill last-reviewed:** 2026-06-09

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | 3 | Description leads with task vocab (INVEST, Given/When/Then, MoSCoW, swimlanes, RACI, RAID, UAT go/no-go), explicit use-when/not, names sibling skills; fits ≤600 chars. |
| D2 | Scope contract | 2 | Load-when/not-this-skill in Overview box; tooling fallback stated; no explicit "assumed context" block (org access for describe/list, managed-package state, project type agile vs waterfall). |
| D3 | Operational depth | 3 | Automation audit before requirements (managed-package side effects), RACI dual-Accountable as a defect, MoSCoW fake-priority detection (>60% Must = arithmetic impossibility), go/no-go criteria, defect severity vs. priority distinction, requirement traceability chain — non-obvious operational layer throughout. |
| D4 | Decision support | 3 | Tables for elicitation method by situation, requirement class by owner/validator, automation tool by need, story split patterns; every fork names the constraint. |
| D5 | Failure-mode coverage | 3 | Per-section anti-patterns with plausible-wrong reasoning: designing solution inside a requirements interview; NPSP as clean slate; logging new requirements as defects during UAT; requirements phrased as solutions; verbal scope-change acceptance. |
| D6 | Verification discipline | 3 | Every section ends with a concrete verification step: describe object for field type/length, list active automations, query records post-UAT, arithmetic capacity check for MoSCoW; tool-agnostic (MCP → sf CLI → Setup UI). |
| D7 | Uncertainty & escalation | 3 | Dedicated "Uncertainty & Escalation" section; three inline `[volatile — verify live]` tags (blueprint weights, Workflow/PB retirement date, NPSP automation); Live wins rule; escalation to named Accountable for go/no-go, sponsor approval for deferred Musts. |
| D8 | Executable workflows | 3 | Three numbered workflows with verify gates: (1) elicit → user story → UAT-ready, (2) UAT to go/no-go decision, (3) as-is/to-be process map + RACI. Each gate catches the dominant failure at that step. |
| D9 | Teaching scenarios | 2 | Two scenarios inline (automation audit before requirement; fake MoSCoW prioritization); three additional deferred to `references/scenarios.md` — five total but only two in the main body load. |
| D10 | Context economy | 1 | 5,086 words (snapshot) — exceeds 5,000-word threshold → score 1. Quick Reference (27 rules, ~330 words) contains significant overlap with section bodies; §6 UAT has 8 anti-pattern bullets that rehash section content. **D10 trim required before publish bar can be met.** |
| D11 | Freshness & provenance | 3 | `last-reviewed: 2026-06-09`, `blueprint-verified: 2026-06-07`; Changelog entry; inline volatile tags present. |
| D12 | Measurability | 2 | `evals/salesforce-business-analyst/` has 12 situations, answer-key, tasks, and triggers — full infra present; no model run recorded yet. |
| | **Total** | **31/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: needs content pass**

Sub-2 dimensions filed as inbox items: **D10** (body exceeds 5,000 words; trim ~600–800 words to reach ≤4,300 and score 3, or ≤5,000 for score 2).

---

## Lens 2 — Trigger testing

Source phrasings: `evals/salesforce-business-analyst/triggers.md`. Test against descriptions only.

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| "Turn this stakeholder interview transcript into INVEST user stories with Given/When/Then acceptance criteria and a MoSCoW priority call for the next sprint" | salesforce-business-analyst | salesforce-business-analyst (description: "writing and sizing user stories (INVEST, Given/When/Then, MoSCoW)…eliciting and documenting requirements") | ✓ |
| "Facilitate a process-mapping session output: I have the swim-lane notes — help me write the current-state process map, RACI, and RAID log" | salesforce-business-analyst | salesforce-business-analyst (description: "mapping current/future-state processes (swimlanes, RACI, RAID)") | ✓ |
| "Run the go/no-go UAT checklist for our release: three Must-have scenarios passed, one failed with a major defect — what is the competent call and how do I document it?" | salesforce-business-analyst | salesforce-business-analyst (description: "running user acceptance testing to a go/no-go decision") | ✓ |
| "A stakeholder said 'make the grant application faster' — help me decompose this vague ask into measurable acceptance criteria the dev team can estimate" | salesforce-business-analyst | salesforce-business-analyst (description: "eliciting and documenting requirements…facilitating stakeholder workshops and discovery") | ✓ |
| "I need to write a requirements traceability matrix that links our business requirements to user stories, UAT scenarios, and sign-off status" | salesforce-business-analyst | salesforce-business-analyst (description: "eliciting and documenting requirements") | ✓ |
| "Build the Flow automation that sends an email when an Application record moves to 'Approved' status" | salesforce-administrator | salesforce-administrator (description: "Flow automation…configuring or reviewing declarative org settings…automation") | ✓ |
| "Write the Apex class and trigger to enforce the business rule that an Application cannot be submitted without an attached document" | salesforce-platform-developer-1 | salesforce-platform-developer-1 (description: "Writing, reviewing, and deploying Apex, SOQL/SOSL, triggers") | ✓ |
| "Configure the reports and dashboards so the Finance team can see grant disbursements filtered by region" | salesforce-administrator | salesforce-administrator (description: "reports, dashboards…configuring or reviewing declarative org settings") | ✓ |

**Trigger pass rate:** 8/8.

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/salesforce-business-analyst/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: none

---

## Notes / trend

- **D10 (1) — BLOCKS PUBLISH:** Body is 5,086 words, above the >5,000 threshold. Trim plan:
  1. Quick Reference (27 rules, ~330 words): consolidate rules that duplicate section text to one-liners; target -200 words.
  2. §6 UAT anti-patterns (8 bullets, ~120 words): reduce to the 3-4 highest-value red flags; target -80 words.
  3. §3 Customer Discovery automation-audit section: the NPSP example is detailed enough to move the core rule + pointer to references/ and keep only the imperative; target -100 words.
  4. Traceability paragraph in §4 (concrete SF-field-chain example): move the implementation detail to references/change-management.md; target -80 words.
  Total target: ~460 words trimmed → ~4,600 words → D10 scores 2, unblocking publish. Trim to ≤3,500 for D10=3 if a deeper pass is warranted.
- **D9 (2):** Only two scenarios inline; three deferred to references/scenarios.md. Unlike the architect/JS skills, the BA scenarios cover more distinct domains — consider promoting the UAT defect-vs-new-requirement scenario inline as it is a high-frequency judgment call.
- **D2 (2):** No explicit "assumed context" block. One line suffices (org access for describe/list, managed-package state).
- Strong content quality across D3–D8; the word-count issue alone blocks publication. Fix is mechanical (trim), not a content gap.
