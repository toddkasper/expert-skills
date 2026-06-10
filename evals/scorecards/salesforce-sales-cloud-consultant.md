# Scorecard — salesforce-sales-cloud-consultant

- **Skill:** `salesforce-sales-cloud-consultant`
- **Assessed:** 2026-06-09
- **Model (auditor):** claude-sonnet-4-6 (static audit)
- **Skill last-reviewed:** 2026-06-09

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | 3 | Description leads with task vocabulary (leads, opportunities, forecasting, territory, price books, migration/dedupe, reports), states explicit use-when, names three sibling skills by slug; ≤600 chars. |
| D2 | Scope contract | 3 | Dedicated "Load this skill when…" / "Not this skill:" block in Overview; naming `salesforce-service-cloud-consultant`, `salesforce-experience-cloud-consultant`, `salesforce-administrator`; assumed tooling noted in verify-steps note. Agent can route without reading body. |
| D3 | Operational depth | 2 | Strong on SFDX FLS gap, QA cache-bust, ECA auth path, restricted picklist trap, ETM activation sequence; weaker on core Sales Cloud mechanics (forecasting adjustments, CPQ vs native Quotes criteria are present but lightweight; AI scoring prerequisites thin inline). |
| D4 | Decision support | 3 | Explicit decision tables in §1 (automation tier), §6 (migration tool by volume), §10 (report type), §12 (territory vs. forecast category); every choice names the constraint that drives it. |
| D5 | Failure-mode coverage | 3 | Per-section Red Flags with mechanism + fix + detection: FLS after SFDX deploy (§3), QA cache bug (§9), assignment rule not firing on API inserts (implied in §8/workflow), stage/forecast category drift (§12), duplicate-on-re-run insert trap (§6). |
| D6 | Verification discipline | 3 | Every executable workflow step has a verify gate; §3 Scenario 3 provides a Tooling API SOQL query; verify note at top names MCP → `sf` CLI → UI fallback hierarchy. |
| D7 | Uncertainty & escalation | 3 | Dedicated section with four sub-bullets: re-verify-live list, live-wins rule, escalate-to-human list (OWD changes, destructive data ops, ECA creation, license changes), confidence taxonomy with `[volatile — verify live]` inline. |
| D8 | Executable workflows | 3 | Three numbered end-to-end workflows (lead routing, forecasting+ETM, price book/stage model) with verify gates between steps; covers the domain's 3 highest-frequency multi-step operations. |
| D9 | Teaching scenarios | 2 | Three full POLICY-format scenarios inline (automation, OWD, FLS); Scenarios 4–5 deferred to references/scenarios.md. Only 3 of ≥4 required are body-resident; the remaining two are "load on demand" — does not satisfy the ≥4 inline requirement. |
| D10 | Context economy | 2 | Snapshot: 4,696 words (4,300–5,000 band). Heavy content sections inline (§1–§13 + workflows + scenarios). Reference files used for AI features, LDV, and consulting practices but body still dense. Trim flag: §2 (Apex limits stub) is minimal but §9 deployment section and QR are verbose; could move 200–400 words to references to clear 4,300. |
| D11 | Freshness & provenance | 3 | `last-reviewed: 2026-06-09`, `blueprint-verified: 2026-06-07` in frontmatter; Changelog section with dated entry describing what changed and why; `[volatile — verify live]` tags on limits and feature thresholds inline. |
| D12 | Measurability | 2 | Eval infra exists (triggers.md, situations.md, tasks.md, answer-key.md); no recorded run results in RESULTS.md; coverage mapping to sections not formally documented. Per rubric guidance: eval infra present but not model-run → 2. |
| | **Total** | **32/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: publish-ready**

Sub-2 dimensions filed as inbox items: none. D9 (3→2) and D10 (2) are the lowest — flag for content pass to bring 2 more scenarios inline and trim body toward 4,300 words.

---

## Lens 2 — Trigger testing

Source phrasings: `evals/salesforce-sales-cloud-consultant/triggers.md`. Test against descriptions only (snapshot `/tmp/skills-snapshot.md`).

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| "We need to set up territory management so each rep only sees accounts in their assigned region and forecasts roll up by territory hierarchy." | salesforce-sales-cloud-consultant | salesforce-sales-cloud-consultant — "forecasting, territory management … designing the sharing model" | Y |
| "Our collaborative forecast totals are off — manager adjustments at one level aren't propagating up to the VP layer." | salesforce-sales-cloud-consultant | salesforce-sales-cloud-consultant — "forecasting" in description | Y |
| "Design the lead assignment rules and lead conversion field mapping for this B2B spec, and flag any deduplication pitfalls." | salesforce-sales-cloud-consultant | salesforce-sales-cloud-consultant — "leads and lead conversion … planning migrations/dedupe" | Y |
| "We want to activate Einstein Opportunity Scoring for our 20-person team that has been live eight months. What data prerequisites do we need?" | salesforce-sales-cloud-consultant | salesforce-sales-cloud-consultant — "sales-productivity/AI features" | Y |
| "A nightly integration syncing Sales Orders to a restricted picklist field is failing with a field-level error even though the integration user has FLS edit on the field. What is wrong?" | salesforce-sales-cloud-consultant | salesforce-sales-cloud-consultant — "modeling the sales data layer" covers data/integration concerns; restricted-picklist trap is Sales Cloud scope; no competing skill describes Sales Orders specifically | Y |
| "Set up escalation rules and entitlement milestones so cases breaching SLA automatically move to a senior queue." | salesforce-service-cloud-consultant | salesforce-service-cloud-consultant — "entitlements and milestones (SLAs)" in description | Y (near-miss correctly routes away) |
| "Configure a partner portal so resellers can log in, register deals, and see only their own opportunities." | salesforce-experience-cloud-consultant | salesforce-experience-cloud-consultant — "partner/customer portals … external license selection" | Y (near-miss correctly routes away) |
| "Add a validation rule to the Opportunity object and set up duplicate matching rules for Accounts across the org." | salesforce-administrator | salesforce-administrator — "validation rules, duplicate management" | Y (near-miss correctly routes away) |

**Trigger pass rate:** 8/8.

Notes: Phrasing 5 is the hardest test — the restricted picklist + FLS + integration angle touches both Sales Cloud and Administrator descriptions. The Sales Cloud description's "modeling the sales data layer" and "planning migrations/dedupe" plus the Sales Cloud context (Sales Orders) give it the edge over the administrator description's more generic "data import" framing. Routing held as a hit.

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/salesforce-sales-cloud-consultant/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: none

---

## Notes / trend

Strong first static pass. Lowest dimensions are D9 (only 3 of ≥4 scenarios are body-resident; 2 more deferred to references) and D10 (4,696 words; above 4,300 trim target). No dimension below 2. Primary inbox items for next content pass: (1) pull Scenarios 4–5 from references/scenarios.md inline or add 2 new POLICY scenarios to the body; (2) move ~400 words of deployment detail or QR content to a references/deployment.md to bring body under 4,300. D12 upgrades to 3 once a model run is recorded.
