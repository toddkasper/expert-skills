# Scorecard — salesforce-agentforce-specialist

- **Skill:** `salesforce-agentforce-specialist`
- **Assessed:** 2026-06-09
- **Model (auditor):** claude-sonnet-4-6 (static audit)
- **Skill last-reviewed:** 2026-06-09

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | 3 | Description leads with task vocab (topics, actions, agent-user security, reasoning loop, Prompt Builder types, Trust Layer, Data Cloud RAG), explicit use-when/not, names sibling skills; fits ≤600 chars. |
| D2 | Scope contract | 2 | Load-when/not-this-skill in Overview box; tooling fallback stated; no explicit "assumed context" block (Data Cloud provisioning, Agentforce license, org edition). |
| D3 | Operational depth | 3 | Silent truncation of Field Generation to field length, static-vs-dynamic grounding masking gap, ECA/agent-user least-privilege blast-radius, template draft-not-resolving at run time, Data Cloud RAG prerequisite (provisioning required), chunk-size retrieval-quality trade-off — all non-obvious operational layer. |
| D4 | Decision support | 3 | Tables for template-type-by-output-target, agent-type-by-audience, action-mechanism-by-need, retriever-type (individual vs ensemble), search-type-by-query-shape; every fork names the constraint. |
| D5 | Failure-mode coverage | 3 | Per-section anti-patterns with plausible-wrong reasoning: raising max-token setting for truncation (wrong constraint); System Admin profile "to make it work" (blast-radius risk); assuming Trust Layer masks static text; single mega-topic mirouting; Testing Center treated as optional. |
| D6 | Verification discipline | 3 | Every section ends with verify steps: `describe` for field length before wiring, SOQL as agent user for CRUD/FLS/sharing, Data Cloud object presence check, Trust Layer audit trail review; tool-agnostic. |
| D7 | Uncertainty & escalation | 3 | Dedicated "Uncertainty & Escalation" section; four inline `[volatile — verify live]` tags (agent type roster, AI Associate retirement, Data Cloud RAG availability, masking config UI); Live wins rule; escalation list covers PII/agent-security decisions and Testing Center bypass. |
| D8 | Executable workflows | 3 | Three numbered workflows with verify gates: (1) agent topic+action with least-privilege user, (2) Field Generation grounding with field-length safety, (3) diagnose "agent can't access record" (CRUD → FLS → sharing). Each gate catches the dominant failure at that step. |
| D9 | Teaching scenarios | 3 | Five scenarios in body, all inline (Field Generation silent truncation; over-privileged agent user; draft template not resolving; RAG in org without Data Cloud; PII in static grounding). Each probes a different section's hardest judgment call with no overlap between them. |
| D10 | Context economy | 2 | 4,993 words (snapshot); at the top of the 4,300–5,000 band → score 2. §4&5 (Service/Sales Cloud, 10% each) is correctly thin and delegates to references/; Quick Reference is long. No exam logistics in body. Near the trim threshold — monitor. |
| D11 | Freshness & provenance | 3 | `last-reviewed: 2026-06-09`, `blueprint-verified: 2026-06-07`; Changelog entry; inline volatile tags; rebrand note (AI Specialist → Agentforce Specialist) present and dated. |
| D12 | Measurability | 2 | `evals/salesforce-agentforce-specialist/` has 12 situations, answer-key, tasks, and triggers — full infra present; no model run recorded yet. |
| | **Total** | **33/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: publish-ready**

Sub-2 dimensions filed as inbox items: none.

---

## Lens 2 — Trigger testing

Source phrasings: `evals/salesforce-agentforce-specialist/triggers.md`. Test against descriptions only.

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| "Review this Agentforce agent topic and its action definitions — flag any grounding gaps, over-broad topic descriptions, or Einstein Trust Layer risks" | salesforce-agentforce-specialist | salesforce-agentforce-specialist (description: "Agentforce agents (topics, actions, agent-user security, the reasoning loop)…Einstein Trust Layer") | ✓ |
| "My Prompt Builder Field Generation template is truncating output at 255 characters even though the field length is 512 — diagnose and fix" | salesforce-agentforce-specialist | salesforce-agentforce-specialist (description: "Prompt Builder templates (Sales Email, Field Generation, Record Summary, Flex)") | ✓ |
| "Design the Data Cloud RAG grounding strategy for our Agentforce Service Agent so it answers from our Knowledge articles without hallucinating" | salesforce-agentforce-specialist | salesforce-agentforce-specialist (description: "Data Cloud and Knowledge grounding/RAG") | ✓ |
| "Walk me through setting up the agent user for our new Employee Agent — what permissions are minimum-privilege and what risks come from reusing the same agent user across multiple agents?" | salesforce-agentforce-specialist | salesforce-agentforce-specialist (description: "agent-user security") | ✓ |
| "Audit this Flex prompt template for PII exposure and ungrounded static context before we activate it in production" | salesforce-agentforce-specialist | salesforce-agentforce-specialist (description: "Prompt Builder templates…Flex…Einstein Trust Layer (data masking, zero-retention, audit)") | ✓ |
| "Enable Einstein Activity Capture and configure the Agentforce setup permissions for our sales reps in Setup" | salesforce-administrator | salesforce-administrator (description: "Agentforce admin setup…declarative org settings, security/sharing, automation") | ✓ |
| "Write the Apex @InvocableMethod that backs an Agentforce action to query open Cases and return a structured result to the agent" | salesforce-platform-developer-2 | salesforce-platform-developer-2 (description: "advanced Apex…dynamic Apex with FLS/CRUD enforcement"; agentforce-specialist description explicitly excludes "Apex action-code internals") | ✓ |
| "Set up Einstein Opportunity Scoring and configure the Sales AI features in our Sales Cloud org" | salesforce-sales-cloud-consultant | salesforce-sales-cloud-consultant (description: "sales-productivity/AI features…designing and configuring Salesforce Sales Cloud") | ✓ |

**Trigger pass rate:** 8/8.

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/salesforce-agentforce-specialist/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: none

---

## Notes / trend

- **Highest D9 in this batch (3):** All five scenarios are inline, each targeting a different section's hardest fork. This is the strongest teaching-scenario implementation reviewed.
- **D10 (2):** At 4,993 words the skill is one edit away from the >5,000 threshold. §4&5 correctly delegates Service/Sales Cloud depth to references/. On the next content pass, tighten the Quick Reference (currently ~20 bullets that largely restate section text) to create headroom. **Flag: D10 trim watch.**
- **D2 (2):** No explicit "assumed context" block (Agentforce license, Data Cloud provisioning state, org edition). One sentence added to the load-when block would complete D2 to a 3.
- **Freshness risk:** Agent type roster and Data Cloud features are tagged `[volatile]` correctly — this skill will need the most frequent re-review of the four as the Agentforce platform evolves.
