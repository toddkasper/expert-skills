# Scorecard — salesforce-marketing-cloud-email-specialist

- **Skill:** `salesforce-marketing-cloud-email-specialist`
- **Assessed:** 2026-06-09
- **Model (auditor):** claude-sonnet-4-6 (static audit)
- **Skill last-reviewed:** 2026-06-09

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | 3 | Description leads with task vocabulary (Journey Builder, Automation Studio, Content Builder, AMPscript, data extensions, SQL Data Views, Triggered/Single/User-Initiated sends, deliverability SPF/DKIM/DMARC, IP warming, bounce handling, MC Connect), explicit use-when, names SFMC vs Pardot boundary; ≤600 chars. |
| D2 | Scope contract | 3 | "Load this skill when…" / "Not this skill:" block in Overview names `salesforce-sales-cloud-consultant`, `salesforce-service-cloud-consultant` as CRM email scope; SFMC vs Pardot boundary stated in description and Overview; tooling note present. |
| D3 | Operational depth | 3 | §3 Automation Studio same-step parallel trap (race condition), §3 Journey versioning trap (in-flight contacts stay on old version), §4 Overwrite import truncates DE, §4 unsubscribe scope (List vs Global vs Master), §1 TSD must-be-Active-and-republished, §4 Data Views ~6-month retention, MCC FLS blank-not-error rule (§4). These are genuine operational scars practitioners learn the hard way. |
| D4 | Decision support | 3 | Decision tables in §1 (consent model by law/audience), §2 (personalization tool by need), §2 (send type by trigger), §3 (Journey Builder vs Automation Studio), §3 (re-entry mode), §4 (DE type), §4 (import update mode), §4 (segmentation: Data Filter vs SQL). Every fork names the constraint. |
| D5 | Failure-mode coverage | 3 | RED FLAGs throughout with trigger + mechanism + fix + detection: purchased-list trap (§1), TSD Paused/un-republished (§2 + Scenarios 4–5 reference), same-step race condition (§3 + Scenario 1), Overwrite on appended DE (§4), Global vs. List unsubscribe confusion (§4 + Scenario 2), open-rate unreliability post-MPP (§5/QR), MCC FLS blank (§4). |
| D6 | Verification discipline | 3 | All 3 workflows have explicit verify gates; §3 Workflow 2 step 2 specifies a SOQL-equivalent query on the DE row count; §3 Workflow 3 step 5 gives a SQL query against `_Bounce` Data View; verify note at top names MCP → `sf` CLI → UI fallback. |
| D7 | Uncertainty & escalation | 3 | Dedicated section: re-verify-live list (CAN-SPAM penalties, Gmail/Yahoo bulk-sender thresholds, 10DLC, Data Views retention, IP warming schedule, Einstein prerequisites), live-wins, escalate-to-human list (large send on new IP, reactivating a stale segment, Master Unsubscribe modification, consent/erasure workflows), confidence taxonomy. |
| D8 | Executable workflows | 3 | Three numbered end-to-end workflows (welcome journey; AS batch import→SQL→send; deliverability hardening) with verify gates; covers the 3 highest-frequency multi-step operations in SFMC email. |
| D9 | Teaching scenarios | 2 | Three full POLICY-format scenarios inline (AS step ordering, unsubscribe scope, Journey re-entry mode); Scenarios 4–5 deferred to references/scenarios.md. 3 of ≥4 required body-resident — same shortfall as sales-cloud and service-cloud. |
| D10 | Context economy | 2 | Snapshot: 4,566 words (4,300–5,000 band, near lower boundary). References used for analytics reports, coverage additions, MCC deep-dive, and scenarios. Body is well-offloaded relative to peers; slight trim (~300 words) from QR and §6 would reach 4,300. Trim flag active but less severe than other skills in this batch. |
| D11 | Freshness & provenance | 3 | `last-reviewed: 2026-06-09`, `blueprint-verified: 2026-06-07`; Changelog dated entry; `[volatile — verify live]` on CAN-SPAM penalty, Gmail/Yahoo thresholds, Data Views retention, IP warming schedule, Einstein features. |
| D12 | Measurability | 2 | Eval infra present (triggers.md, situations.md, tasks.md, answer-key.md); no recorded run in RESULTS.md. Eval infra not model-run → 2. |
| | **Total** | **32/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: publish-ready**

Sub-2 dimensions filed as inbox items: none. D9 and D10 are lowest — flag for content pass.

---

## Lens 2 — Trigger testing

Source phrasings: `evals/salesforce-marketing-cloud-email-specialist/triggers.md`. Test against descriptions only (snapshot `/tmp/skills-snapshot.md`).

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| "Design a welcome Journey in Journey Builder for new subscribers: a day-0 welcome email, a day-3 nurture email, and a day-7 offer — and flag the re-entry and double-welcome traps." | salesforce-marketing-cloud-email-specialist | salesforce-marketing-cloud-email-specialist — "Journey Builder welcome/nurture flows" in description | Y |
| "Our IP reputation tanked after a large send. Walk me through an IP warming schedule and the SPF/DKIM/DMARC records we need to verify before the next campaign." | salesforce-marketing-cloud-email-specialist | salesforce-marketing-cloud-email-specialist — "deliverability (SPF/DKIM/DMARC, IP warming, bounce handling)" in description | Y |
| "We need to segment our appeal audience with a SQL Query activity in Automation Studio and send via a User-Initiated Send." | salesforce-marketing-cloud-email-specialist | salesforce-marketing-cloud-email-specialist — "Automation Studio batch pipelines … data extensions and SQL Data Views … Triggered/Single/User-Initiated sends" | Y |
| "Set up Marketing Cloud Connect so our Salesforce CRM Contacts sync to SFMC and we can segment by CRM fields in a Journey." | salesforce-marketing-cloud-email-specialist | salesforce-marketing-cloud-email-specialist — "Marketing Cloud Connect to CRM" in description | Y |
| "Our AMPscript personalization block is rendering blank for a subset of subscribers even though the Data Extension has values for them. Help me debug the LookupRows logic." | salesforce-marketing-cloud-email-specialist | salesforce-marketing-cloud-email-specialist — "AMPscript personalization … data extensions" in description | Y |
| "Configure an email alert in Salesforce that fires when a sales rep closes an Opportunity, using an HTML email template with the deal details." | salesforce-administrator | salesforce-administrator — "Flow automation … validation rules" (core-CRM workflow email alert, not SFMC Journey/Content Builder) | Y (near-miss correctly routes away) |
| "Build an Agentforce Sales Email prompt template that drafts a follow-up email to a prospect based on the Opportunity record fields." | salesforce-agentforce-specialist | salesforce-agentforce-specialist — "Prompt Builder templates (Sales Email, Field Generation…)" in description | Y (near-miss correctly routes away) |
| "We use Pardot (Account Engagement) for lead nurturing. Set up a prospect engagement score and an email drip sequence for our webinar registrants." | not salesforce-marketing-cloud-email-specialist | No skill in the marketplace covers Pardot/Account Engagement; description explicitly excludes it ("not core CRM email or Pardot/Account Engagement") | Y (near-miss correctly routes away — no false claim of coverage) |

**Trigger pass rate:** 8/8.

Notes: Near-miss 3 (Pardot) is an edge case — no skill claims it, so routing "away from marketing-cloud-email-specialist" is the correct outcome and counts as a hit. Near-miss 2 (Agentforce Sales Email) is a sharp test: "email" in the phrasing could attract marketing-cloud, but the Agentforce description's "Prompt Builder templates (Sales Email…)" is more specific than SFMC's Journey Builder.

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/salesforce-marketing-cloud-email-specialist/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: none

---

## Notes / trend

Strong across the board; closest to the 4,300 word target of the five skills in this batch (4,566 words). Best-in-batch D4 variety — 8 distinct decision tables covering every major SFMC fork. D9 shortfall is consistent with the batch pattern (3 inline, 2 in references). D10 trim is the lightest of the group. No freshness risk on Apple MPP open-rate caveat (correctly flagged as unreliable). Primary inbox items: (1) pull Scenarios 4–5 (TSD paused; AMPscript blank) inline from references/scenarios.md; (2) trim QR and §6 stub (~300 words) to approach 4,300 target. D12 upgrades to 3 once a model run is recorded.
