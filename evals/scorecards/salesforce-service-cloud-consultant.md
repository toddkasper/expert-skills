# Scorecard — salesforce-service-cloud-consultant

- **Skill:** `salesforce-service-cloud-consultant`
- **Assessed:** 2026-06-09
- **Model (auditor):** claude-sonnet-4-6 (static audit)
- **Skill last-reviewed:** 2026-06-09

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | 3 | Description leads with task vocabulary (cases, assignment/escalation rules, entitlements/milestones, Knowledge, Omni-Channel, Web-to-Case, CTI, AHT/FCR/CSAT), explicit use-when, names three sibling skills by slug; ≤600 chars. |
| D2 | Scope contract | 3 | "Load this skill when…" / "Not this skill:" block in Overview names `salesforce-sales-cloud-consultant`, `salesforce-experience-cloud-consultant`, `salesforce-administrator`; assumed tooling stated in verify-steps note. Agent can route without reading body. |
| D3 | Operational depth | 3 | §2 covers AssignmentRuleHeader API gap, escalation clock-start basis, case merge limit (3), macro vs Quick Text scoping; §5 Web-to-Case 500/day cap; §6 Lightning Knowledge single-object model; §10 entitlement three-layer hierarchy and On-Hold pause non-default — these are exactly the "learn the hard way" traps the standard demands. |
| D4 | Decision support | 3 | Decision tables in §1 (channel selection by volume/latency/audience), §1 (automation tier), §2 (queues vs. Omni), §3 (sandbox tier), §5 (Omni routing model); all name the constraint. |
| D5 | Failure-mode coverage | 3 | RED FLAGs with trigger + mechanism + fix + detection throughout: DML-in-loop in Flow (§1), API assignment rule not firing (§2 + Scenario 1), On-Hold SLA drift (§10 + Scenario 2), QA cache miss (§4 + Scenario 3), 10DLC prerequisite omission (§5), Social Studio sunset warning (§5). |
| D6 | Verification discipline | 3 | Every workflow step has a gate; §10 specifies `CaseMilestone` SOQL query; §3 workflow gate requires `AgentWork` SOQL; verify note at top names MCP → `sf` CLI → UI fallback hierarchy consistently. |
| D7 | Uncertainty & escalation | 3 | Dedicated section: re-verify-live list (Web-to-Case cap, SMS/10DLC, Knowledge license names), live-wins, escalate-to-human list (OWD changes, guest-user widening, destructive ops, SMS channels), confidence taxonomy. |
| D8 | Executable workflows | 3 | Three numbered end-to-end workflows (Email-to-Case + assignment + escalation; entitlements + milestones; Omni-Channel) with verify gates between every step; gates catch the common failure at each step. |
| D9 | Teaching scenarios | 2 | Three full POLICY-format scenarios inline (API assignment rule, On-Hold SLA, QA cache); Scenarios 4–5 deferred to references/scenarios.md. Only 3 of ≥4 required body-resident; same shortfall as sales-cloud. |
| D10 | Context economy | 2 | Snapshot: 4,792 words (4,300–5,000 band). Body carries extensive QR + 10 numbered sections + 3 scenarios + 3 workflows. References used for CTI/Voice depth and scenarios. Trim flag: QR is long (~400 words); some redundancy between QR and section bodies. Could cut ~500 words to reach target. |
| D11 | Freshness & provenance | 3 | `last-reviewed: 2026-06-09`, `blueprint-verified: 2026-06-07`; Changelog section with dated entry; `[volatile — verify live]` on Web-to-Case cap, case merge limit, Knowledge license name, SMS/10DLC requirements. |
| D12 | Measurability | 2 | Eval infra present (triggers.md, situations.md, tasks.md, answer-key.md); no recorded run in RESULTS.md. Eval infra not model-run → 2. |
| | **Total** | **33/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: publish-ready**

Sub-2 dimensions filed as inbox items: none. D9 and D10 are the two weakest dims.

---

## Lens 2 — Trigger testing

Source phrasings: `evals/salesforce-service-cloud-consultant/triggers.md`. Test against descriptions only (snapshot `/tmp/skills-snapshot.md`).

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| "Configure entitlement milestones and business-hours calendars so VIP cases escalate to a senior queue when the first-response clock hits 4 hours." | salesforce-service-cloud-consultant | salesforce-service-cloud-consultant — "entitlements and milestones (SLAs)" explicitly in description | Y |
| "Our Email-to-Case routing is creating duplicate cases instead of threading agent replies as comments." | salesforce-service-cloud-consultant | salesforce-service-cloud-consultant — "Web-to-Case/Email-to-Case" in description | Y |
| "We need Omni-Channel routing to distribute cases to the right tier of agents based on skill and availability, with a fallback queue for overflow." | salesforce-service-cloud-consultant | salesforce-service-cloud-consultant — "Omni-Channel routing" in description | Y |
| "Design the Knowledge base data-category structure and article record types for a two-tier support team." | salesforce-service-cloud-consultant | salesforce-service-cloud-consultant — "Knowledge (Knowledge__kav, data categories, KCS)" in description | Y |
| "Agents report that the Web-to-Case form stops accepting submissions mid-day. We think we are hitting a daily limit." | salesforce-service-cloud-consultant | salesforce-service-cloud-consultant — "Web-to-Case/Email-to-Case" and "scoping or implementing a case-management/support solution" | Y |
| "Build a customer self-service portal where logged-in users can open support tickets and track their case status without calling in." | salesforce-experience-cloud-consultant | salesforce-experience-cloud-consultant — "communities, partner/customer portals … external license selection … configuring external-user access" | Y (near-miss correctly routes away) |
| "Create assignment rules that route new Leads to the right sales rep by territory and send an auto-response email to the prospect." | salesforce-sales-cloud-consultant | salesforce-sales-cloud-consultant — "leads and lead conversion … designing the sharing model" | Y (near-miss correctly routes away) |
| "Set up escalation rules and workflow email alerts on the Case object so managers are notified when any case is open longer than 2 hours." | salesforce-administrator | salesforce-administrator — "Flow automation … validation rules … reports" (generic declarative config without SLA milestones) | Y (near-miss correctly routes away) |

**Trigger pass rate:** 8/8.

Notes: Phrasing 8 is the subtlest test — "escalation rules on Case" could attract service-cloud-consultant. The differentiator is no mention of entitlements/milestones; the description explicitly says "scoping or implementing a case-management/support solution, intake channels, or routing" (requires the SLA/entitlement layer), while salesforce-administrator covers generic "Flow automation." Routing held as hit.

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/salesforce-service-cloud-consultant/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: none

---

## Notes / trend

Strongest skill in this batch on operational depth (D3=3) — entitlement three-layer hierarchy, On-Hold pause non-default, and AssignmentRuleHeader API gap are exactly the practitioner scars the standard demands. Same D9/D10 shortfall as the other skills in this batch (3 inline scenarios vs ≥4 required; body at 4,792 words). Primary inbox items: (1) pull Scenarios 4–5 from references/scenarios.md inline; (2) compress QR (~400 words) and move CTI-adjacent detail to references to approach 4,300 word target. D12 upgrades to 3 once a model run is recorded.
