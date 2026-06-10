# Scorecard — salesforce-technical-architect

- **Skill:** `salesforce-technical-architect`
- **Assessed:** 2026-06-09
- **Model (auditor):** claude-sonnet-4-6 (static audit)
- **Skill last-reviewed:** 2026-06-09

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | 3 | Description leads with task vocab (multi-org strategy, SSO/OAuth/JWT Bearer, LDV, Named Credentials, Platform Events, Bulk API, governor-limit-aware design), explicit use-when/not, names sibling classes; fits ≤600 chars. |
| D2 | Scope contract | 2 | Load-when/not-this-skill present in Overview box; tooling fallback stated; no explicit "assumed context" block naming what the project must provide (e.g. org access, secrets-store, SFDX project). |
| D3 | Operational depth | 3 | Synchronous governor-limit table with exact numbers, FLS deploy gap (`field-meta.xml` carries no FLS), ECA Policies-tab gotcha (not permset), `relationshipName` duplicate-deploy failure, LDV non-selective query error threshold, QA cache-bust mechanism, idempotent upsert via External ID — all non-obvious operational scars. |
| D4 | Decision support | 3 | Decision tables for OAuth flow selection, integration pattern (sync/async/bulk/event-driven), object-relationship choice (master-detail vs lookup), SSO protocol, declarative-vs-code automation; every fork names the constraint. |
| D5 | Failure-mode coverage | 3 | Per-section red flags with plausible-wrong reasoning: re-deploying field when FLS is missing; trusting Role Hierarchy for lateral access; row-by-row REST for bulk; silent drop on SF write failure; deploy running from wrong directory. |
| D6 | Verification discipline | 3 | SOQL verify steps after every section (field queryable, permset via `SetupEntityAccess`, idempotency count stays at 1 on retry, JWT smoke chain); tool-agnostic; copy-runnable. |
| D7 | Uncertainty & escalation | 3 | Dedicated "Uncertainty & Escalation" section; four inline `[volatile — verify live]` tags (governor limits, Bulk API formula, ECA UI path, Data Cloud); Live wins rule; escalation list covers destructive deploys, JWT rotation, production data-model changes. |
| D8 | Executable workflows | 3 | Three numbered workflows with verify gates: (1) cross-cloud integration design, (2) JWT Bearer setup end-to-end, (3) LDV data model sizing. Each gate catches the dominant failure at that step. |
| D9 | Teaching scenarios | 2 | Two scenarios inline (FLS invisible post-deploy; OWD + Role Hierarchy misread as lateral sharing); three additional scenarios deferred to `references/scenarios.md` — five total but only two in the main body load. |
| D10 | Context economy | 2 | 4,972 words (snapshot); in the 4,300–5,000 band → score 2. Quick Reference is long (39 bullet rules) and some overlap with section bodies; Well-Architected section correctly offloads detail to references/. No exam logistics in body. |
| D11 | Freshness & provenance | 3 | `last-reviewed: 2026-06-09`, `blueprint-verified: 2026-06-07`; Changelog entry explains what changed; inline volatile tags present. |
| D12 | Measurability | 2 | `evals/salesforce-technical-architect/` has 12 situations, answer-key, tasks, and triggers — full infra present; no model run recorded yet. |
| | **Total** | **32/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: publish-ready**

Sub-2 dimensions filed as inbox items: none.

---

## Lens 2 — Trigger testing

Source phrasings: `evals/salesforce-technical-architect/triggers.md`. Test against descriptions only.

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| "Design the end-to-end integration architecture for a bi-directional sync between our Salesforce org and an external ERP, covering auth, error handling, idempotency, and governor-limit risk" | salesforce-technical-architect | salesforce-technical-architect (description: "integration patterns…Named Credentials, Platform Events, Bulk/REST API…governor-limit-aware design") | ✓ |
| "Our org has a multi-cloud setup (Sales + Service + Experience) — review the proposed OWD + sharing model and flag any access gaps or over-exposure" | salesforce-technical-architect | salesforce-technical-architect (description: "solution architecture across clouds…security and identity…FLS") | ✓ |
| "Evaluate whether Platform Events or an outbound REST callout is the right pattern for this near-real-time notification requirement, and justify the trade-offs" | salesforce-technical-architect | salesforce-technical-architect (description: "integration patterns…Platform Events…designing or reviewing cross-cloud architecture, integration pipelines") | ✓ |
| "We need a JWT Bearer flow between a headless Node.js service and Salesforce — walk me through the auth setup, certificate rotation, and what breaks at sandbox refresh" | salesforce-technical-architect | salesforce-technical-architect (description: "security and identity (SSO, OAuth, JWT Bearer, SAML)") | ✓ |
| "Assess our proposed Large Data Volume strategy for 50 million Contact records — skinny tables, custom indexes, selective SOQL, and archiving options" | salesforce-technical-architect | salesforce-technical-architect (description: "enterprise data modeling and LDV") | ✓ |
| "Configure the OWD and create sharing rules for the Opportunity object in our Sales Cloud org" | salesforce-sales-cloud-consultant | salesforce-sales-cloud-consultant (description: "designing and configuring Salesforce Sales Cloud…designing the sharing model") | ✓ |
| "Write the Apex trigger handler and bulkification logic for the Contact object following the one-trigger-per-object pattern" | salesforce-platform-developer-1 | salesforce-platform-developer-1 (description: "trigger handlers…bulkification against governor limits") | ✓ |
| "Set up permission sets and profiles for our new Service Cloud implementation, including FLS and OWD for Case" | salesforce-administrator | salesforce-administrator (description: "profiles, permission sets, OWD, sharing rules, FLS…declarative org settings") | ✓ |

**Trigger pass rate:** 8/8.

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/salesforce-technical-architect/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: none

---

## Notes / trend

- **D9 (2):** Three of five scenarios deferred to `references/scenarios.md`. The two inline scenarios (FLS gap, Role Hierarchy lateral-access misread) are the highest-frequency gotchas — well chosen. Promote one more inline if body trim creates room.
- **D10 (2):** At 4,972 words the skill is near the top of the 4,300–5,000 band. The Quick Reference (39 bullet rules) is the primary trim target on a future content pass; many bullets restate section guidance. Well-Architected section correctly defers detail to references/. Not worth a trim pass until Lens 3/4 results show a specific gap.
- **D2 (2):** No explicit "assumed context" block (org access, secrets store, SFDX project root, sandbox). Minor gap — add one line to the load-when block on next pass.
- Strongest skills in this set for D3/D4/D5/D8 — the operational scars (ECA Policies tab, QA cache bust, `relationshipName` uniqueness, JWT sandbox-refresh gotcha) are exactly the non-obvious layer the standard targets.
