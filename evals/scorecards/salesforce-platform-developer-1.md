# Scorecard — salesforce-platform-developer-1

- **Skill:** `salesforce-platform-developer-1`
- **Assessed:** 2026-06-09
- **Model (auditor):** claude (static audit)
- **Skill last-reviewed:** 2026-06-09

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | 3 | Frontmatter description leads with task-vocab phrases ("trigger handlers (before/after, one-trigger-per-object)", "bulkification against governor limits (100 SOQL / 150 DML / 10s CPU)", "@future, Queueable, Batch, Schedulable", "FLS/sharing enforcement in code", "75% gate"); explicit use-when + 3 named sibling pointers; cert framing only in `metadata:`; ~555 chars. |
| D2 | Scope contract | 3 | Overview block states Load-when / Not-this-skill with named siblings (`salesforce-administrator`, `salesforce-platform-developer-2`, `salesforce-javascript-developer-1`); assumed tooling preamble; router can decide from block alone. |
| D3 | Operational depth | 3 | Governor limits table with exact sync/async numbers; SFDX FLS scar (System Admin cannot query custom field without `<fieldPermissions>`); 13-step order of execution with the workflow-field-update re-trigger step; QA cache scar; SOQL injection via LIKE; callout-in-trigger `CalloutException` mechanism; `seeAllData=true` vs mock distinction. Each includes the specific error text or limit that practitioners learn the hard way. |
| D4 | Decision support | 3 | Six decision tables: declarative vs programmatic; relationship type; before/after trigger context; async tool (future/Queueable/Batch/Schedulable); DML vs Database.insert; LWC vs Aura vs Visualforce; each fork names the governing constraint. |
| D5 | Failure-mode coverage | 3 | Red flags per section with the plausible-but-wrong reasoning (e.g. "wrapping Http.send() in try/catch in the trigger — the CalloutException fires regardless of catch blocks"); Scenarios have Tempting-but-wrong with mechanism; bulkify red flag labeled "catch it on sight." |
| D6 | Verification discipline | 3 | Every section ends with tool-agnostic triple (MCP / `sf` CLI / Developer Console/UI); copy-runnable SOQL (`FieldPermissions`, `PermissionSetAssignment`); smoke-test sequence (auth → describe → upsert → cleanup) stated for deployment. |
| D7 | Uncertainty & escalation | 3 | Dedicated Uncertainty & Escalation block: volatile marks on governor limits, LWC lifecycle API versions, coverage threshold; Live wins rule; escalation list (prod deploys to managed-package Apex without sandbox validation, code adding `without sharing` to PII paths). |
| D8 | Executable workflows | 3 | Three numbered workflows (add field + surface in LWC, bulk-safe trigger + test class to 75%, SFDX deploy with fieldPermissions), each with verify gates; gates name the specific failure at that step (e.g. "no `Invalid field` error" confirms FLS landed). |
| D9 | Teaching scenarios | 3 | Two POLICY scenarios in body (SFDX FLS, callout-from-trigger async choice), three more in references/scenarios.md; each probes a different section's hardest fork; Tempting-but-wrong reasoning provided with mechanism. |
| D10 | Context economy | 2 | Snapshot word count 4,600 — in the 4,300–5,000 weak-but-passing range. The Apex code example (~15 lines) adds legitimate body value; the Visualforce subsection adds ~150 words that are mostly a stub pointing to references/visualforce.md; the Quick Reference (~30 bullets) duplicates body content. Trim candidate: QR bullet duplication and the Visualforce stub (which could be a single load-cue line). |
| D11 | Freshness & provenance | 3 | `last-reviewed: 2026-06-09`, `blueprint-verified: 2026-06-07`; inline `[volatile — verify live]` on all governor limits and LWC lifecycle; Changelog entry with scope; Feedback protocol present. |
| D12 | Measurability | 2 | `evals/salesforce-platform-developer-1/` has situations.md (12 probes), answer-key.md, tasks.md, triggers.md; probes cover all major sections (Governor Limits, Bulkify/Triggers, Async, Testing, LWC, Deployment, SOQL injection, OOE, NPSP TDTM, Visualforce View State); no model run yet — infra complete, results pending. |
| | **Total** | **34/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: publish-ready**

Sub-2 dimensions filed as inbox items: none.

---

## Lens 2 — Trigger testing

Source phrasings: `evals/salesforce-platform-developer-1/triggers.md`. Test against descriptions only (snapshot: /tmp/skills-snapshot.md).

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| "Review this Apex trigger on Opportunity — it does a SOQL query inside a for loop and I know that's bad, but I'm not sure how to bulkify it" | salesforce-platform-developer-1 | salesforce-platform-developer-1 — "trigger handlers", "bulkification against governor limits" and "reviewing...Apex...triggers" all explicit in description | ✅ |
| "My test class is at 74% coverage and the deploy to production is failing — which lines are uncovered and how do I write tests for trigger handler methods?" | salesforce-platform-developer-1 | salesforce-platform-developer-1 — "test classes to the 75% gate" and "SFDX deployment" explicit; adv-admin covers deploy pipeline health, not test authorship | ✅ |
| "I deployed a field via SFDX with a fieldPermissions block for our Sales Rep permission set but the field still shows as hidden — what's wrong with the XML?" | salesforce-platform-developer-1 | salesforce-platform-developer-1 — "FLS/sharing enforcement in code" and SFDX deployment both in description; the XML debugging framing is a code/deploy task | ✅ |
| "Write a Queueable Apex class that calls an external REST endpoint and re-enqueues itself for the next page of results" | salesforce-platform-developer-1 | salesforce-platform-developer-1 — "synchronous vs async Apex (@future, Queueable, Batch, Schedulable)" explicit; PD2 covers chaining patterns but the basic write-a-Queueable ask matches PD1 first | ✅ |
| "An LWC child component has an @api method — the parent calls it in connectedCallback and it never fires. What lifecycle hook should I use instead?" | salesforce-platform-developer-1 | salesforce-platform-developer-1 — "LWC decorators and lifecycle" explicit in description; JS Developer I covers front-end LWC but the platform lifecycle + @api question is PD1 territory | ✅ |
| (near-miss) "Set up a Flow to create a follow-up Task whenever an Opportunity stage changes to Closed Won" | salesforce-administrator | salesforce-administrator — "Flow automation" and "declarative org settings" in admin description; PD1 says "Not declarative-only config" | ✅ |
| (near-miss) "My Batch Apex is hitting non-selective query errors on 3 million Account records — how do I tune the SOQL for Large Data Volume?" | salesforce-platform-developer-2 | salesforce-platform-developer-2 — "SOQL selectivity and Large Data Volume tuning" leads the PD2 description explicitly; PD1 does not mention selectivity or LDV | ✅ |
| (near-miss) "Design the sharing model so that the West Sales team can see each other's Opportunity records under a Private OWD" | salesforce-administrator | salesforce-administrator — "OWD, sharing rules" in admin description; this is declarative sharing config | ✅ |
| (near-miss) "Write a custom LWC that uses a wire adapter to fetch data and renders a dynamic table — I need the shadow DOM event bubbling explained too" | salesforce-javascript-developer-1 | salesforce-javascript-developer-1 — "wire adapters and Lightning Data Service", "custom events and shadow DOM" explicit in JS-Dev-1 description; the shadow DOM + wire-adapter front-end framing pushes past PD1 | ✅ |

**Trigger pass rate:** 9/9.

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/salesforce-platform-developer-1/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: none

---

## Notes / trend

First static audit — no prior runs to trend against.

Lowest dimensions: D10 (2) and D12 (2). D10 trim candidate: the Quick Reference (~30 bullets) substantially overlaps body content; trimming to the 10–12 highest-surprise rules and converting the Visualforce stub to a single load-cue line would bring the body closer to 4,200 words. D12 hardest sections to show lift: NPSP TDTM coexistence (situation 11) and the `seeAllData=true` + callout mock interaction (situation 5) — these are the probes most likely to expose a base-model gap.
