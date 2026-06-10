# Scorecard — salesforce-nonprofit-cloud-consultant

- **Skill:** `salesforce-nonprofit-cloud-consultant`
- **Assessed:** 2026-06-09
- **Model (auditor):** claude-sonnet-4-6 (static audit)
- **Skill last-reviewed:** 2026-06-09

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | 3 | Description leads with task vocabulary (NPSP, Household Accounts, Relationships, Affiliations, hard/soft credit, TDTM, Customizable Rollups, Recurring Donations, BGE, LYBUNT/SYBUNT; NPC: Gift Entry, Program/Outcome Management, Grantmaking, OmniStudio), use-when, scope boundary naming `salesforce-administrator` and platform-developer skills; ≤600 chars. |
| D2 | Scope contract | 3 | "Load this skill when…" / "Not this skill:" block names `salesforce-administrator`, platform-developer skills, and `salesforce-experience-cloud-consultant`; model-detection heuristic (list org objects, check namespaces) is the "assumed context" anchor. Agent can route without reading body. |
| D3 | Operational depth | 3 | NPSP account-model rules (Household vs 1×1 vs Bucket), Relationship vs Affiliation decision (Contact↔Contact vs Contact↔Org), reciprocal-auto-mirror trap, hard vs soft credit OCR mechanics, TDTM-disable-for-bulk-load discipline, ERD `RecurringType__c` field, BGE Data Import vs. Data Loader distinction, Address TDTM revert trap (Scenario 5). These are textbook-resistant practitioner scars. |
| D4 | Decision support | 2 | Decision tables: NPSP vs. NPC model (Scenario 1 + Overview heuristic), Relationship vs. Affiliation (§1 table), import tool by need (QR bullet), provisioning method by scenario (QR). However, several major forks lack tables: when to disable TDTM vs. use batch Apex; CRLP vs. legacy rollups choice criteria; OmniStudio tool-selection matrix deferred entirely to references/nonprofit-cloud-industries.md without an inline summary. A domain expert would want at least a stub for these. |
| D5 | Failure-mode coverage | 3 | RED FLAGs with mechanism + detection: auto-mirror double-creation (§1), hard+soft double-count (§2 + Scenario 2), TDTM-active bulk-load governor-limit failure (§3/Workflow 2/Scenario 3), PSL gating vs. sharing confusion (Scenario 4), Address revert from direct Contact-field edit (Scenario 5), ECA "wrong screen" assignment (§20). |
| D6 | Verification discipline | 3 | Every workflow step has a SOQL gate with concrete query text; Scenario 5 provides a specific `npsp__Address__c` SOQL; verify note at top names MCP → `sf` CLI → UI fallback. §1 namespace-detection heuristic has a gate query. |
| D7 | Uncertainty & escalation | 3 | Dedicated section: re-verify-live list (NPSP namespace versions, TDTM handler names, NPC PSL names, July 2025 credential split), live-wins, escalate-to-human list (TDTM disable in production, bulk delete in production, mass re-parenting Contacts, rollup recalculation on >100k records without maintenance window), confidence taxonomy. |
| D8 | Executable workflows | 3 | Three numbered end-to-end workflows (Enhanced Recurring Donation end-to-end; bulk-load with TDTM disabled; hard/soft credit and giving-total verification) with SOQL verify gates at each step; covers the 3 highest-frequency NPSP operations. |
| D9 | Teaching scenarios | 3 | Five full POLICY-format scenarios body-resident (NPSP vs NPC model detection; hard/soft double-count; TDTM bulk-load failure; PSL gating vs sharing; Address TDTM revert). Satisfies ≥4 inline requirement with all five present and covering distinct sections. |
| D10 | Context economy | 2 | Snapshot: 4,383 words (3,500–4,300 band — lowest in batch, near upper boundary). However, PART A deep-dive content deferred to references/npsp-deep-dive.md (CRLP, ERD, TDTM detail, Addresses, Governor Limits, Custom Fields) and PART B deferred to references/nonprofit-cloud-industries.md. Body handles two credential scopes (NP-Con-101 + NP-Con-102); the references carry the depth load well. Near the 4,300 target and could score 3 if word count confirmed ≤3,500 after frontmatter strip — but snapshot says 4,383, keeping it at 2. |
| D11 | Freshness & provenance | 3 | `last-reviewed: 2026-06-09`, `blueprint-verified: 2026-06-07`; Changelog dated entry; `[volatile — verify live]` on NPSP namespace versions, TDTM handler names, NPC PSL names, NPSP sunset timeline, July 2025 credential split. |
| D12 | Measurability | 2 | Eval infra present (triggers.md, situations.md, tasks.md, answer-key.md); no recorded run in RESULTS.md. Eval infra not model-run → 2. |
| | **Total** | **33/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: publish-ready**

Sub-2 dimensions filed as inbox items: none. D4 (2) and D10 (2) are lowest.

---

## Lens 2 — Trigger testing

Source phrasings: `evals/salesforce-nonprofit-cloud-consultant/triggers.md`. Test against descriptions only (snapshot `/tmp/skills-snapshot.md`).

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| "Configure Recurring Donations in NPSP for a monthly giving program, including the Household Account model and the rollup fields that track lifetime giving — and flag the double-count trap." | salesforce-nonprofit-cloud-consultant | salesforce-nonprofit-cloud-consultant — "NPSP managed package (Household Accounts … Recurring Donations … LYBUNT/SYBUNT)" in description | Y |
| "Our NPSP org shows zero lifetime giving for donors we bulk-loaded last week via Data Loader. TDTM was active during the load. What happened and how do we fix the rollup totals?" | salesforce-nonprofit-cloud-consultant | salesforce-nonprofit-cloud-consultant — "TDTM, Customizable Rollups" in description; NPSP-specific terminology matches exactly | Y |
| "We are implementing Industries Nonprofit Cloud and need to set up Program Enrollment records linked to a mental-health program, with outcome measurement forms for each session." | salesforce-nonprofit-cloud-consultant | salesforce-nonprofit-cloud-consultant — "Industries Nonprofit Cloud (Gift Entry, Program/Outcome Management)" in description | Y |
| "A major donor's Contact record has both a hard credit and a soft credit Opportunity for the same gift. Walk me through whether that is correct in NPSP and what the reporting impact is." | salesforce-nonprofit-cloud-consultant | salesforce-nonprofit-cloud-consultant — "hard/soft credit" explicitly in description | Y |
| "Decide whether this org is running NPSP or Nonprofit Cloud (Industries) and explain which recurring-gift object we should use to create a new monthly pledge." | salesforce-nonprofit-cloud-consultant | salesforce-nonprofit-cloud-consultant — "deciding which applies" explicitly in description | Y |
| "Build an Apex trigger handler on the Opportunity object that fires after insert to create a follow-up Task for the assigned development officer." | salesforce-platform-developer-1 | salesforce-platform-developer-1 — "Writing, reviewing, and deploying Apex … triggers" in description; no nonprofit-specific objects in phrasing | Y (near-miss correctly routes away) |
| "Configure a donor self-service portal where constituents can log in, update their contact info, and view their giving history." | salesforce-experience-cloud-consultant | salesforce-experience-cloud-consultant — "partner/customer portals … configuring external-user access" — external portal scope | Y (near-miss correctly routes away) |
| "Set up a duplicate rule and matching rule on the Contact object to prevent staff from creating duplicate donor records when entering gifts." | salesforce-administrator | salesforce-administrator — "duplicate management" in description; no NPSP-specific dedup logic mentioned | Y (near-miss correctly routes away) |

**Trigger pass rate:** 8/8.

Notes: Near-miss 3 (duplicate/matching rule for donors) is the sharpest test — "donor records" could attract nonprofit-cloud-consultant. The differentiator is the task ("duplicate rule and matching rule configuration") which matches salesforce-administrator's description verbatim ("duplicate management"), and the description's "not this skill" boundary covers general platform rules. Routing holds. Near-miss 2 (Apex trigger on Opportunity for fundraising task) correctly routes to platform-developer-1 despite the fundraising context — the task is about Apex code, not NPSP data model configuration.

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/salesforce-nonprofit-cloud-consultant/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: none

---

## Notes / trend

Best D9 score in the batch (3) — all five scenarios are body-resident and cover distinct section gotchas (model detection, double-count, TDTM bulk failure, PSL gating, Address revert). Lowest word count of the batch (4,383) and closest to the 4,300 target. D4 is the weakest dimension (2): CRLP vs. legacy rollup decision criteria and OmniStudio tool-selection matrix are completely deferred to reference files with no inline stub or summary. Primary inbox items: (1) add 2–3 sentence inline stub for CRLP vs. legacy rollup decision (with a "load references/npsp-deep-dive.md for full detail" cue); (2) add a 3-row OmniStudio tool-selection stub inline. Both are small additions. D12 upgrades to 3 once a model run is recorded.
