# Scorecard — salesforce-advanced-administrator

- **Skill:** `salesforce-advanced-administrator`
- **Assessed:** 2026-06-09
- **Model (auditor):** claude (static audit)
- **Skill last-reviewed:** 2026-06-09

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | 3 | Frontmatter description names specific advanced-admin constructs (session-based permission sets, OOE debugging, DLRS roll-ups, SFDX deployment, Event Monitoring); explicit use-when + 2 named sibling pointers; cert framing in `metadata:` only; ~555 chars. |
| D2 | Scope contract | 3 | Overview block states Load-when / Not-this-skill with named siblings (`salesforce-administrator`, `salesforce-platform-developer-1`); assumed tooling preamble present; router can decide from the block alone. |
| D3 | Operational depth | 3 | Full 14-step order-of-execution list (most practitioners learn the hard way); approval + record-lock collision with mechanism (`ENTITY_IS_LOCKED`); Field History 20-field silent cap; Connected App vs ECA gotcha; ECA policy assignment path error; each with error text or precise limit. |
| D4 | Decision support | 3 | Five decision tables: profile/permset/PSG/session-based; relationship type (MD/Lookup/Junction); import tool; sandbox type selection; deployment tool (SFDX vs Change Sets vs Metadata API); every fork names the governing constraint. |
| D5 | Failure-mode coverage | 3 | "Red flags" blocks per section with plausible-but-wrong reasoning (e.g. "grant access via hierarchies ON for a Lookup when silos required"; "relying on debug logs for forensics days later"); Scenarios include Tempting-but-wrong with root-cause mechanism. |
| D6 | Verification discipline | 3 | Every section ends with tool-agnostic triple (MCP / `sf ...` / Setup UI); copy-runnable SOQL (`OrgWideDefault`, `FieldPermissions`, `Obj__History`); JWT-bearer smoke test specified for deployment verification. |
| D7 | Uncertainty & escalation | 3 | Dedicated block: volatile marks on sandbox intervals, Field History retention, governor limits; "Live wins" rule; escalation list covers OWD in prod, sharing additions exposing PII, mass-delete >1k rows, Event Monitoring compliance changes. |
| D8 | Executable workflows | 3 | Three numbered workflows (sharing model change safely, bulk load with automation disabled, sandbox→prod validation-only deploy), each with verify gates; gates name the exact failure they catch at that step. |
| D9 | Teaching scenarios | 3 | Two POLICY scenarios in body (invisible field after deploy, approval + ENTITY_IS_LOCKED collision), three more in references/scenarios.md; each probes a different section's highest-value fork; Tempting-but-wrong reasoning supplied. |
| D10 | Context economy | 2 | Snapshot word count 4,735 — in the 4,300–5,000 weak-but-passing range. The Quick Reference section (~32 bullets) has significant overlap with body content; the "Cloud Applications" section is a one-line stub pointing to references (which is correct) but the QR alone adds ~350 words of duplication. Trim candidate: QR bullets that restate body rules verbatim. |
| D11 | Freshness & provenance | 3 | `last-reviewed: 2026-06-09`, `blueprint-verified: 2026-06-07`; inline `[volatile — verify live]` tags on sandbox intervals, Field History retention, governor limits; Changelog entry; Feedback protocol present. |
| D12 | Measurability | 2 | `evals/salesforce-advanced-administrator/` has situations.md (12 probes), answer-key.md, tasks.md, triggers.md; probes map to all major sections (Security, OOE/Automation, Data/Analytics, Auditing/Monitoring, Environment/Deployment, Sharing Model edge cases); no model run yet — infra complete, results pending. |
| | **Total** | **34/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: publish-ready**

Sub-2 dimensions filed as inbox items: none.

---

## Lens 2 — Trigger testing

Source phrasings: `evals/salesforce-advanced-administrator/triggers.md`. Test against descriptions only (snapshot: /tmp/skills-snapshot.md).

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| "I need to configure a session-based permission set so finance users only get the export permission after they complete an MFA step — how do I wire that up?" | salesforce-advanced-administrator | salesforce-advanced-administrator — "muting and session-based permission sets" explicit in description; admin description does not mention session-based permsets | ✅ |
| "My SFDX deploy pipeline is failing because the org-wide code coverage dropped below 75% after we deleted a legacy test class — what are my options?" | salesforce-advanced-administrator | salesforce-advanced-administrator — "SFDX deployment" and "sandbox strategy" in description; the 75% coverage gate is a deployment concern, not a code-writing concern (PD1 covers the writing; adv-admin covers the deployment pipeline) | ✅ |
| "I need to track field history on 22 fields on a custom object but Field History Tracking silently caps it — what's the limit and what do I do with the overflow fields?" | salesforce-advanced-administrator | salesforce-advanced-administrator — "auditing/monitoring (Setup Audit Trail, Field History, Event Monitoring)" explicit in description | ✅ |
| "Setup Audit Trail shows nothing for who changed our password policy last week — am I looking in the wrong place?" | salesforce-advanced-administrator | salesforce-advanced-administrator — "auditing/monitoring (Setup Audit Trail...)" explicit in description | ✅ |
| "Deploying a custom report type that traverses two Lookup fields to Contact fails with a duplicate relationship name error even though the field API names are different — what's the actual conflict?" | salesforce-advanced-administrator | salesforce-advanced-administrator — "custom object and relationship design" in description; Lookup `relationshipName` uniqueness is advanced-admin design territory | ✅ |
| (near-miss) "Help me set OWD on Opportunity to Private and create a sharing rule so the sales team can see each other's records" | salesforce-administrator | salesforce-administrator — basic OWD + sharing rule setup matches "OWD, sharing rules" in the admin description; adv-admin is scoped to "beyond day-to-day admin" and emphasizes architecture | ✅ |
| (near-miss) "Write a before-insert Apex trigger on Account that enforces FLS before updating fields" | salesforce-platform-developer-1 | salesforce-platform-developer-1 — "Writing, reviewing, and deploying Apex, SOQL/SOSL, triggers" leads PD1; adv-admin explicitly says "Not Apex/code" | ✅ |
| (near-miss) "My SOQL query in a Batch Apex execute() method is causing non-selective query errors on 2 million Account records — how do I tune it?" | salesforce-platform-developer-2 | salesforce-platform-developer-2 — "SOQL selectivity and Large Data Volume tuning" explicit in PD2 description; adv-admin description does not mention SOQL selectivity | ✅ |

**Trigger pass rate:** 8/8.

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/salesforce-advanced-administrator/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: none

---

## Notes / trend

First static audit — no prior runs to trend against.

Lowest dimensions: D10 (2) and D12 (2). D10 trim candidate: the Quick Reference section (~32 bullets) substantially duplicates body rules already stated with mechanism; trimming or collapsing the QR to the 10–12 highest-surprise rules would bring the body under 4,300 words. D12 awaits a model run; hardest sections to show lift on likely are the Order of Execution subtleties (step 10 workflow-field-update re-trigger) and the session-based permset MFA configuration, which the base model may partially know.
