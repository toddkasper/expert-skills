# Scorecard — salesforce-administrator

- **Skill:** `salesforce-administrator`
- **Assessed:** 2026-06-09
- **Model (auditor):** claude (static audit)
- **Skill last-reviewed:** 2026-06-09

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | 3 | Frontmatter description leads with concrete task nouns (profiles, OWD, FLS, Flow, Data Import Wizard/Loader, dashboards, Agentforce setup); explicit use-when + 3 named sibling pointers; ~575 chars — under the 600-char ceiling. |
| D2 | Scope contract | 3 | Overview block states Load/Not-this-skill with sibling pointers (`salesforce-platform-developer-1`, `salesforce-advanced-administrator`, `salesforce-agentforce-specialist`); assumed tooling (MCP/CLI/UI) stated in the verify preamble — router can decide load/skip from that block alone. |
| D3 | Operational depth | 3 | SFDX FLS scar (field invisible including System Admin), ECA assignment gotcha (wrong UI page), QA cache scar (structural-change flush), managed-package automation trap (NPSP `Phone→MobilePhone` example), muting-permset-only subtraction rule — each includes mechanism + error text. |
| D4 | Decision support | 3 | Five named decision tables: profile-vs-permset, relationship type (Lookup/MD), flow type by trigger, import tool (Wizard vs Loader), permissions-settings location (§2); every fork names the constraint that drives the pick. |
| D5 | Failure-mode coverage | 3 | Every section carries "Red flags" with the plausible-but-wrong reasoning (e.g. "trusting a browser-tool 'success' on ECA assignment"; "assuming an agent bypasses sharing/FLS"); Scenarios include Tempting-but-wrong with mechanism. |
| D6 | Verification discipline | 3 | Every section ends with tool-agnostic triple (MCP / `sf data query` / Developer Console or Object Manager); SOQL queries are copy-runnable (`FieldPermissions`, `PermissionSetAssignment`, `FlowDefinitionView`). |
| D7 | Uncertainty & escalation | 3 | Dedicated "Uncertainty & Escalation" block: volatile marks on limits and availability, "Live wins" rule, explicit escalate-before-proceeding list (OWD in prod, mass-delete, multi-currency enable), confidence taxonomy. |
| D8 | Executable workflows | 3 | Three numbered end-to-end workflows (field deploy, record-access diagnosis, managed-package deactivation), each with verify gates between steps; gates name the exact failure they catch. |
| D9 | Teaching scenarios | 3 | Two POLICY scenarios in body (SFDX invisible field, before-save vs after-save), three more in references/scenarios.md (5 total); each probes a different section's hardest fork; Tempting-but-wrong reasoning provided for each. |
| D10 | Context economy | 2 | Snapshot word count 4,731 — falls in the 4,300–5,000 weak-but-passing range. The Quick Reference section (~30 bullets, several repeating body content) and the Sales/Service §6 stub both inflate the body. Deep detail is already offloaded to `references/`; trim candidate is the QR bullet duplication. |
| D11 | Freshness & provenance | 3 | `last-reviewed: 2026-06-09`, `blueprint-verified: 2026-06-07`; volatile facts inline-tagged; Changelog entry with scope of 2026-06-09 changes; Feedback protocol in-skill. |
| D12 | Measurability | 2 | `evals/salesforce-administrator/` has situations.md (12 probes), answer-key.md, tasks.md, triggers.md; probes map to each body section (Security §1, Config §2, Object Manager §3, Automation §4, Data/Analytics §5, Sales/Service §6, Agentforce §7); no model run yet — infra complete, results pending. |
| | **Total** | **34/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: publish-ready**

Sub-2 dimensions filed as inbox items: none.

---

## Lens 2 — Trigger testing

Source phrasings: `evals/salesforce-administrator/triggers.md`. Test against descriptions only (snapshot: /tmp/skills-snapshot.md).

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| "How do I set OWD on the Case object to Private and still let support reps see their team's cases?" | salesforce-administrator | salesforce-administrator — description explicitly lists "OWD, sharing rules" and "security/sharing" use-when | ✅ |
| "A user can edit a field they shouldn't be able to — I've checked the profile, what else controls FLS?" | salesforce-administrator | salesforce-administrator — "profiles, permission sets, OWD, sharing rules, FLS" all in description | ✅ |
| "My nightly Flow is hitting Too many DML rows when it processes 12,000 accounts — the loop finishes before the Update Records element, is that the problem?" | salesforce-administrator | salesforce-administrator — "Flow automation" is a named capability; governor-limit wording doesn't trigger PD1 (which lists "Apex/triggers/SOQL") | ✅ |
| "I need to build a dashboard showing won-revenue by region from a summary report — the Add to Dashboard button is grayed out, what's wrong?" | salesforce-administrator | salesforce-administrator — "reports, dashboards" explicitly in description | ✅ |
| "We enabled Duplicate Management on Lead with Alert mode but reps save duplicates without any warning — how do I verify the matching rule is active?" | salesforce-administrator | salesforce-administrator — "duplicate management" explicitly listed | ✅ |
| (near-miss) "Write an Apex trigger handler that bulkifies DML for Opportunity after insert" | salesforce-platform-developer-1 | salesforce-platform-developer-1 — "Writing, reviewing, and deploying Apex, SOQL/SOSL, triggers" leads the PD1 description; admin description says "Not Apex/triggers/SOQL" | ✅ |
| (near-miss) "I need to configure a session-based permission set so a user gets elevated export rights only after MFA — how do I set that up?" | salesforce-advanced-administrator | salesforce-advanced-administrator — "muting and session-based permission sets" is explicit in adv-admin description; admin description does not mention session-based permsets | ✅ |
| (near-miss) "Set up an Agentforce agent topic with a Flow-backed action and write the topic description" | salesforce-agentforce-specialist | salesforce-agentforce-specialist — "Agentforce agents (topics, actions, agent-user security, the reasoning loop)" leads that description; admin is scoped only to "Agentforce admin setup" | ✅ |

**Trigger pass rate:** 8/8.

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/salesforce-administrator/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: none

---

## Notes / trend

First static audit — no prior runs to trend against.

Lowest dimensions: D10 (2) and D12 (2). D10 is a trim candidate: the Quick Reference section duplicates content already stated precisely in body sections, inflating the body ~200–300 words above the exemplary ceiling. The §6 Sales/Service body stub could move to a single reference-load cue. D12 awaits a model run to confirm whether the 12 probes actually produce lift on the hardest sections (Agentforce §7 and the QA cache scar in §3 are the likely low-lift candidates for the base model).
