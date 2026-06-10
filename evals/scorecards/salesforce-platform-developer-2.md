# Scorecard — salesforce-platform-developer-2

- **Skill:** `salesforce-platform-developer-2`
- **Assessed:** 2026-06-09
- **Model (auditor):** claude (static audit)
- **Skill last-reviewed:** 2026-06-09

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | 3 | Frontmatter description names PD2-specific constructs (Singleton/Strategy/fflib/Bulk State Transition, Queueable chaining, SOQL selectivity, LDV tuning, Platform Events, CDC, REST/Bulk API, dynamic Apex, Stub API); explicit use-when + 2 named sibling pointers; cert framing in `metadata:` only; ~580 chars. |
| D2 | Scope contract | 3 | Overview block states Load-when / Not-this-skill with named siblings (`salesforce-platform-developer-1`, `salesforce-administrator`); assumed tooling preamble; router can decide from block alone. |
| D3 | Operational depth | 3 | Selectivity thresholds (<10% standard / <33% custom indexed with 1M row ceiling); Queueable one-child-per-execute constraint with depth-guard pattern; CDC events not suppressed on rollback (idempotency requirement); mixed DML setup-object workaround; `FOR UPDATE` row locking; `getGlobalDescribe()` expense warning with cache instruction; Bulk State Transition pattern for watched-field branching. Each includes the mechanism or error, not just the imperative. |
| D4 | Decision support | 3 | Six decision tables: async tool (future/Queueable/Batch/Schedulable) with key constraints; trigger context (before/after/delete); declarative vs programmatic; inbound API selection (REST/custom Apex/Bulk 2.0/Composite/Streaming); wire vs imperative Apex; component framework (LWC/Aura/VF); every fork names the constraint that drives the pick. |
| D5 | Failure-mode coverage | 3 | RED FLAGS labeled in-line for SOQL (leading wildcard, negation, functions on indexed field), bulkify (`EventBus.publish` inside loop), async (synchronous callout from trigger), LWC (unguarded state change in `renderedCallback`); Scenarios include Tempting-but-wrong with mechanism. |
| D6 | Verification discipline | 3 | Every section ends with tool-agnostic verify steps; Query Plan tool specifically named for SOQL selectivity; copy-runnable SOQL (`FieldPermissions`, `AsyncApexJob`, `EventBusSubscriber`); deploy smoke test sequence specified. |
| D7 | Uncertainty & escalation | 3 | Dedicated Uncertainty & Escalation block: volatile marks on governor limits, Platform Event retention, selectivity thresholds, Batch API limits; Live wins rule; escalation list specific to PD2 concerns (async chaining to prod without sandbox validation, setup-object DML, `without sharing` on PII paths, CDC idempotency for duplicate-write risk). |
| D8 | Executable workflows | 3 | Three numbered workflows (Queueable chain with depth guard, Platform Event producer + subscriber, slow SOQL → Query Plan → selective rewrite), each with verify gates; gates name the specific failure mode at that step (e.g. Query Plan must show `Index` not `TableScan`). |
| D9 | Teaching scenarios | 3 | Two POLICY scenarios in body (async chaining / Batch-from-finish vs Queueable, SFDX FLS silent null), three more in references/scenarios.md; each probes a different section's hardest fork (chaining rules, FLS silent null vs error, integration API choice); Tempting-but-wrong with mechanism. |
| D10 | Context economy | 2 | Snapshot word count 4,747 — in the 4,300–5,000 weak-but-passing range. The Quick Reference section (~35 bullets) is the largest body section and substantially duplicates body rules already stated with mechanism; the "Advanced Fundamentals" section is a one-paragraph stub pointing to references/advanced-fundamentals.md (appropriate) but the QR alone accounts for ~400 words of duplication. Trim candidate: QR to the 12 highest-surprise rules + convert Advanced Fundamentals stub to a load-cue line. |
| D11 | Freshness & provenance | 3 | `last-reviewed: 2026-06-09`, `blueprint-verified: 2026-06-07`; inline `[volatile — verify live]` on governor limits, Platform Event retention, selectivity thresholds, Queueable limits; Changelog entry; Feedback protocol present. |
| D12 | Measurability | 2 | `evals/salesforce-platform-developer-2/` has situations.md (12 probes), answer-key.md, tasks.md, triggers.md; probes map to all major sections (Async/Queueable, SOQL selectivity/LDV, Platform Events/CDC, FLS, integration APIs, LWC wire, NPSP TDTM, testing/seeAllData, sharing keywords, CMT vs Custom Settings, fieldPermissions on auto-number/OwnerId); no model run yet — infra complete, results pending. |
| | **Total** | **34/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: publish-ready**

Sub-2 dimensions filed as inbox items: none.

---

## Lens 2 — Trigger testing

Source phrasings: `evals/salesforce-platform-developer-2/triggers.md`. Test against descriptions only (snapshot: /tmp/skills-snapshot.md).

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| "My Batch Apex is hitting non-selective query errors on 2.5 million Account records on the third chunk but never the first — how do I diagnose and fix the SOQL selectivity issue?" | salesforce-platform-developer-2 | salesforce-platform-developer-2 — "SOQL selectivity and Large Data Volume tuning" explicit in description; PD1 does not mention selectivity or LDV | ✅ |
| "Design an async retry pattern for a @future callout that should retry up to 3 times on HTTP 5xx before logging a permanent failure — @future loops won't work, what's the right architecture?" | salesforce-platform-developer-2 | salesforce-platform-developer-2 — "asynchronous patterns (Batch/Queueable/Future/Schedulable, chaining)" explicit; the retry-architecture framing (not "write a future method") signals advanced async design | ✅ |
| "We need to ingest 80,000 Order records nightly from an ERP system into Salesforce — the REST SObject API one-record-at-a-time is too slow, what API and pattern should we use?" | salesforce-platform-developer-2 | salesforce-platform-developer-2 — "REST/Bulk API integration" explicit; the integration API selection framing at that volume matches PD2 scope | ✅ |
| "I'm building a Platform Events consumer in Apex — how do I handle high-volume events reliably and what's the resume-after-failure replay pattern?" | salesforce-platform-developer-2 | salesforce-platform-developer-2 — "Platform Events, Change Data Capture" explicit in description; no other skill mentions Platform Events in its description | ✅ |
| "A Queueable chains into itself for pagination but the chain breaks silently after a certain depth in production — what limit governs Queueable chaining and how do I work around it?" | salesforce-platform-developer-2 | salesforce-platform-developer-2 — "asynchronous patterns...chaining" explicit; depth limit is a PD2-specific construct; PD1 covers basic Queueable usage | ✅ |
| (near-miss) "Write an Apex trigger on Contact that bulkifies a SOQL query and a DML update using a Map pattern" | salesforce-platform-developer-1 | salesforce-platform-developer-1 — "trigger handlers (before/after, one-trigger-per-object)", "bulkification against governor limits" in PD1; PD2 says "Not Apex fundamentals (see salesforce-platform-developer-1)" | ✅ |
| (near-miss) "Set up an SFDX deployment pipeline that runs unit tests and enforces 75% coverage before promoting to production" | salesforce-advanced-administrator | salesforce-advanced-administrator — "SFDX deployment" and "sandbox strategy" explicit in adv-admin description; neither PD1 nor PD2 description mentions deployment pipelines as a primary topic | ✅ |
| (near-miss) "Build an LWC component that imperatively calls an Apex method and refreshes the wire cache after a save operation" | salesforce-javascript-developer-1 | salesforce-javascript-developer-1 — "wire adapters and Lightning Data Service" explicit in JS-Dev-1 description; the wire cache management + imperative call framing is front-end LWC scope, not advanced server-side Apex | ✅ |

**Trigger pass rate:** 8/8.

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/salesforce-platform-developer-2/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: none

---

## Notes / trend

First static audit — no prior runs to trend against.

Lowest dimensions: D10 (2) and D12 (2). D10 trim candidate: the Quick Reference (~35 bullets) is the single largest context-economy problem across all four skills reviewed in this batch — it duplicates body DO/DON'T pairs already stated with mechanism, and trimming to 12–15 high-surprise rules would bring the body to approximately 4,200 words. D12 hardest sections to show lift: the CMT zero-SOQL-cost benefit (situation 12, which the base model partially knows), and the `inherited sharing` keyword behavior in nested classes (situation 10, which is a common misconception even among experienced developers).
