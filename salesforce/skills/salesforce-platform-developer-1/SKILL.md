---
name: salesforce-platform-developer-1
description: Writing, reviewing, and deploying Apex, SOQL/SOSL, triggers, and Lightning Web Components on the Salesforce platform — trigger handlers (before/after, one-trigger-per-object), bulkification against governor limits (100 SOQL / 150 DML / 10s CPU), synchronous vs async Apex (@future, Queueable, Batch, Schedulable), LWC decorators and lifecycle, FLS/sharing enforcement in code, test classes to the 75% gate, and SFDX deployment. Use when building or reviewing Apex/trigger/SOQL/LWC code. Not declarative-only config (see salesforce-administrator) or advanced integration/async/LDV patterns (see salesforce-platform-developer-2). Scoped and benchmarked by the Platform Developer I blueprint.
metadata:
  credential: Salesforce Certified Platform Developer I
  domain: salesforce
  type: certification-playbook
  status: current
  last-reviewed: 2026-06-09
  blueprint-verified: 2026-06-07
---

# Salesforce Platform Developer I — Skills Reference

## Overview

The Salesforce Certified Platform Developer I (PD1) credential validates that a developer understands how to build, deploy, and maintain custom business logic and user interfaces on the Lightning Platform using programmatic tools. It covers the full Apex development lifecycle — data modeling, SOQL/SOSL queries, trigger design, asynchronous processing, Lightning Web Components, Visualforce, unit testing, and deployment tooling — alongside an understanding of when declarative tools (Flow, validation rules, formula fields) are preferable to code.

**This file is an operational playbook, not an exam outline.** Each section states the rule as an actionable instruction with concrete limits, decision criteria, anti-patterns to catch in review, and live-org verification steps. Always verify structural assumptions against the live org — SFDX metadata can lag, and FLS/picklist state is not captured in XML.

> **Load this skill when…** writing or reviewing Apex triggers, SOQL/SOSL queries, or LWC components; debugging governor-limit errors or FLS/sharing issues in code; designing trigger handlers or async Apex patterns; deploying SFDX metadata and hitting field-permission or deployment errors.
> **Not this skill:** declarative-only config (profiles, flows, sharing rules) → see `salesforce-administrator`; advanced async/integration/LDV patterns or design patterns → see `salesforce-platform-developer-2`; LWC front-end JavaScript deep dives → see `salesforce-javascript-developer-1`.

> **Verify steps assume nothing about your tooling** — use your project's Salesforce MCP connection, the Salesforce CLI (`sf`), or the Salesforce setup UI, in that order of preference.

---

Credential logistics and study path: see [references/study-resources.md](references/study-resources.md).

---

## Governor Limits — Know These Cold

These are the hard ceilings the runtime enforces per transaction. Internalize the numbers; most "this will fail in bulk" decisions reduce to one of these.

| Limit | Synchronous | Asynchronous (batch/future/queueable) |
|---|---|---|
| SOQL queries | **100** | **200** |
| Rows retrieved by SOQL | **50,000** | 50,000 |
| DML statements | **150** | 150 |
| Rows per DML / processed | **10,000** | 10,000 |
| Heap size | **6 MB** | **12 MB** |
| CPU time | **10,000 ms** | **60,000 ms** |
| SOSL queries | 20 | 20 |
| Callouts (HTTP/Web service) | 100 | 100 |
| `@future` calls per transaction | 50 | n/a |
| Queueable jobs enqueued (sync) | 50 | 1 (chaining) |

**Apply it:** managed-package triggers consume part of the SOQL/DML budget before your code runs. Treat the budget as shared.

**Verify:** query the actual record count first (`SELECT COUNT() FROM Object__c WHERE ...`) rather than assuming.

---

## Developer Fundamentals (23–27%)

### Declarative vs. programmatic — decide before you write Apex

PD1 heavily tests whether a requirement can be met with clicks before code. Default to declarative; reach for Apex only when the requirement crosses what config can do.

| Requirement | Use | Not |
|---|---|---|
| Field must be non-blank / format-checked / cross-field compared on same record | **Validation rule** | Apex trigger |
| Compute a read-only value from other fields on the same record (or parent via cross-object formula) | **Formula field** | Apex |
| Roll up child values to a Master-Detail parent (SUM/COUNT/MIN/MAX) | **Roll-up summary field** | Apex trigger |
| Roll up across a Lookup, or with complex criteria | **Declarative Lookup Rollup Summary (DLRS)** or Apex | hand-rolled trigger first |
| Multi-step record updates, record creation, screen interaction, scheduled jobs | **Flow** | Apex (unless logic is too complex/bulk-heavy for Flow) |
| Callouts, complex bulk transforms, recursion control, >50k-row processing, anything Flow can't bulkify safely | **Apex** | Flow |

**Anti-pattern:** writing a trigger to do what a validation rule or roll-up summary already does. **Red flag in review:** an Apex trigger whose entire job is "if field A is blank, throw an error" — that's a validation rule.

**Watch for legacy automation.** Workflow Rules and Process Builder are retired for new build — use Flow or Apex. But an org may still *contain* live legacy automation — see Order of Execution.

### Relationship types — pick the right one

| Type | Child required? | Cascade delete | Roll-up summary | Reparentable | Use when |
|---|---|---|---|---|---|
| **Lookup** | No (nullable) | Optional | No | Yes | Loose association; child can exist alone |
| **Master-Detail** | Yes | Yes (always) | Yes | Optional (off by default) | Child is owned by parent; you need roll-ups; child inherits sharing |
| **Many-to-many** | via junction | — | — | — | Two-sided association → junction object with two M-D |
| **Hierarchical** | — | — | — | — | Self-reference, **User object only** |

**Lookup `relationshipName` must be unique per parent object.** Two Lookups on the same child pointing at the same parent cannot share a `relationshipName` — deploy fails with *"Duplicate relationship name."* Use role-specific suffixes (`..._Primary`, `..._Secondary`).

**Verify:** describe the object to see actual relationship names before adding a new lookup.

### External IDs & upsert

An External ID field is unique + indexed and is the key for `upsert` and integration dedup — re-running the same payload updates rather than duplicates.

### Field-level security is NOT object access — and SFDX does not carry it

Deploying a custom field via SFDX `field-meta.xml` creates the field but grants FLS to **no one — not even System Administrator.** Without explicit `<fieldPermissions>` in a profile or permission set, SOQL on that field returns *"Invalid field"* even with full object access.

**Required fields must be omitted from `<fieldPermissions>`.** Salesforce rejects field permissions on a `<required>true</required>` field with *"You cannot deploy to a required field"*. A field is either required (no FLS entry needed) or you must add an explicit FLS entry.

**Verify before trusting a field is queryable:** a SOQL query selecting the field is the definitive check. If it errors "Invalid field," the field exists but FLS is missing.

### Data import/export tooling — pick by volume

| Tool | Volume | Objects | Use when |
|---|---|---|---|
| Import Wizard | < 50k | standard + custom | one-off, UI-driven, dedup needed |
| Data Loader | 5M+ | all | bulk, CLI/scriptable, scheduled |

### Apex OOP essentials

**Collections:** `List` for DML (ordered); `Set<Id>` to dedup before SOQL (`WHERE Id IN :idSet`); `Map<Id, SObject>` keyed by parent Id for O(1) in-loop lookups.
**Interfaces/inheritance:** `implements` for contract, `extends` for inheritance; `virtual`/`abstract`/`override` modifiers; access: `public`, `protected`, `global` (default is `private`).
**Exceptions:** `try/catch(DmlException)/finally`; custom types via `extends Exception`; `Database.insert(records, false)` for partial-success with `SaveResult[]` inspection.

Deep dive with worked examples: [references/apex-oop-essentials.md](references/apex-oop-essentials.md) — load when implementing collection algorithms, extending package frameworks, or handling DML partial-success.

---

## Process Automation & Logic (25–30%) — heaviest section

### Bulkify everything — the #1 rule

**Never put SOQL or DML inside a for loop.** Query once into a Map keyed by Id, iterate in memory, collect results into a List, then issue one DML at the end. A trigger that does SOQL-in-loop hits the 100-query limit at ~100 records; DML-in-loop hits 150 statements.

**Red flag in review:** any `[SELECT ...]`, `Database.query`, `insert`, `update`, `upsert`, or `delete` whose lexical position is inside a `for`/`while` body. Catch it on sight.

```apex
// WRONG — SOQL + DML in loop
for (Contact c : Trigger.new) {
    Account a = [SELECT Id FROM Account WHERE Id = :c.AccountId]; // dies at scale
    update a;
}
// RIGHT — query once, DML once
Set<Id> acctIds = new Set<Id>();
for (Contact c : Trigger.new) acctIds.add(c.AccountId);
Map<Id, Account> accts = new Map<Id, Account>(
    [SELECT Id, Number_Of_Contacts__c FROM Account WHERE Id IN :acctIds]);
for (Contact c : Trigger.new) accts.get(c.AccountId).Number_Of_Contacts__c++;
update accts.values();
```

### DML statements vs. Database methods

- `insert lst;` → all-or-nothing; one bad row rolls back the whole list and throws `DmlException`.
- `Database.insert(lst, false);` → partial success; returns `Database.SaveResult[]`; inspect `.isSuccess()` / `.getErrors()` per row.

**Decision:** use `Database.insert(records, false)` when partial success is acceptable; use bare `insert` when atomicity is required.

### Trigger design — one trigger per object, logic in a handler

- **Exactly one trigger per object.** Multiple triggers on the same object have undefined firing order. Route all context to a handler class.
- **before vs. after:**
  - `before insert/update` → modify field values on the records being saved (no DML on Trigger.new needed). Lowest cost.
  - `after insert/update` → access system-set fields (Id, CreatedDate, formula recalcs) and create/update *related* records.
- **Recursion control:** guard with a static Boolean so a re-entrant save doesn't re-run the handler.
- **Context variables:** `Trigger.new/old/newMap/oldMap`, `Trigger.isInsert/isUpdate/isDelete`, `Trigger.isBefore/isAfter`. `Trigger.old`/`oldMap` are null on insert.

**Package coexistence:** some managed packages own a trigger framework — register custom logic into it, never add a second raw trigger (e.g. NPSP/TDTM). See [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md).

### Order of Execution — the 14 steps that decide what fires when

1. System validation (required, format, length)
2. **Before triggers**
3. Custom **validation rules**, duplicate rules
4. Record saved to DB (not committed)
5. **After triggers**
6. Assignment / auto-response rules
7. **Workflow rules** (legacy) — *if a workflow field-updates, before+after triggers fire AGAIN*
8. Escalation rules
9. Roll-up summary recalc on parent (re-triggers parent's automation)
10. Criteria-based sharing recalc
11. **Legacy Process Builder + record-triggered Flows**
12. **Commit** to database
13. Post-commit: email alerts, async (`@future`, Queueable, Batch enqueued), Platform Event publish

**Why it matters:** a later step can silently overwrite a field your trigger just set. When a field mysteriously changes after your trigger, suspect a later step (workflow/flow/rollup) — confirm with an Apex debug-log probe.

### Validation rules vs. Apex truncation — fail early

Enforce target-field length and picklist constraints at your *input-validation* boundary, not via Apex truncation. Keep generated schema constants in sync with the org: regenerate whenever field metadata changes.

**Verify:** describe an object to get each field's `length` and picklist `values` — that is the source of truth.

### SOQL & SOSL

- **Child→parent:** dot notation, up to 5 levels — `SELECT Contact.Account.Owner.Name FROM Contact`.
- **Parent→child:** subquery using the child relationship name — `SELECT Id, (SELECT Id FROM Children__r) FROM Parent__c`.
- **SOQL vs. SOSL:** SOQL for structured-field filtering on known objects; **SOSL** (`FIND 'term' IN ALL FIELDS RETURNING Contact(Id,Name)`) for full-text search across multiple objects (20/transaction limit).
- **Selective queries:** filter on indexed fields (Id, Name, External ID, lookup fields, audit fields) to avoid full-table scans.

**Dynamic SOQL injection:** use bind variables (`:var`), never concatenate user input. If you must concatenate, `String.escapeSingleQuotes()`.

**Verify a query against the live org** — simultaneously confirms FLS, relationship names, and record match.

### Asynchronous Apex — pick the right async tool

| Need | Use | Key constraints |
|---|---|---|
| Fire-and-forget after txn; HTTP callout from trigger context | **@future** (`callout=true`) | `static void`, **primitive params only — no sObjects**, no chaining, 50/txn |
| Chainable jobs, hold sObject state, monitor via job Id | **Queueable** (`implements Queueable`) | 1 child chain depth in async; `Database.AllowsCallouts` for callouts |
| >10k records, process in chunks | **Batch** (`Database.Batchable<SObject>`) | QueryLocator, batch size default 200; each chunk its own governor limits |
| Time-based / recurring | **Schedulable** (`implements Schedulable`) | cron via `System.schedule`; often just enqueues a Batch |

**Decision shortcut:** callout from trigger → @future or Queueable. Chain/object state → Queueable. Huge volume → Batch. Recurring clock → Schedulable.

### with/without/inherited sharing

- `with sharing` → enforces running user's record-level sharing.
- `without sharing` → ignores sharing. **Apex runs `without sharing` by default if unspecified in the top-level entry class.**
- `inherited sharing` → adopts the caller's sharing; safest default for reusable classes.
- Sharing keywords govern *record access*, not FLS/CRUD — enforce FLS separately with `WITH SECURITY_ENFORCED` or `Security.stripInaccessible()`.

---

## User Interface (25%)

### LWC is the default for all new Lightning UI

| Framework | Use when |
|---|---|
| **LWC** | All new development on Lightning Experience / Salesforce Mobile / Experience Cloud |
| **Aura** | Only when target doesn't support LWC, or you must contain an LWC (LWC-in-Aura is allowed; Aura-in-LWC is NOT) |
| **Visualforce** | PDF generation (`renderAs="pdf"`), Classic orgs, legacy embeds |
| **Declarative (record forms, Quick Actions)** | No custom logic needed — prefer this over building a component |

### LWC essentials

- **Three files:** `.html`, `.js`, `.js-meta.xml`; optional scoped `.css`.
- **Decorators:** `@api` (public, reactive, parent→child), `@wire` (reactive data binding to Apex/wire adapter), `@track` (deep mutation only; fields are reactive by default).
- **Lifecycle:** `constructor()` → `connectedCallback()` (DOM not ready) → `renderedCallback()` (after render; guard against loops) → `disconnectedCallback()` → `errorCallback()`.
- **Events:** child→parent via `CustomEvent('name', {detail})`; parent→child via `@api`; cross-tree via LMS (Lightning Message Service).
- **Apex from LWC:** `@AuraEnabled(cacheable=true)` for wired reads (**no DML**); `@AuraEnabled` (no cacheable) for mutations, called imperatively.

**Anti-pattern:** DML in a `cacheable=true` method; unguarded state change in `renderedCallback()` causes infinite re-render.

### Quick Actions and the runtime cache

**Quick Action cache gotcha:** adding fields to an existing Quick Action's `quickActionLayoutItems` via SFDX updates the metadata but the **runtime QA cache does NOT invalidate** — even after full logout/login. New fields silently don't render, no error. **Fix:** edit any *non-field-list* metadata on the QA (`<description>`, `<label>`) and redeploy; Salesforce treats it as a structural change and flushes the cache.

### Visualforce (still tested on PD1)

Visualforce is used for PDF generation (`renderAs="pdf"`), Classic UI, and legacy embeds. View State limit **170 KB**; mark non-persistent fields `transient`. Default output is HTML-encoded (XSS-safe); `escape="false"` needs explicit justification; `{!JSENCODE()}` for inline JS.

Deep dive with worked examples: [references/visualforce.md](references/visualforce.md) — load when building or debugging VF pages, PDFs, or controller/extension patterns.

---

## Testing, Debugging & Deployment (20–22%)

### Apex testing — coverage and structure

- **75% org-wide Apex coverage required to deploy to production** (measured across all Apex, not just new code). Every trigger must have *some* coverage.
- `@isTest` on class/methods; `@testSetup` runs once per class and rolls back after each test method.
- **Tests see no org data by default** (`SeeAllData=false`). Create all test data in the test.
- **`Test.startTest()` / `Test.stopTest()`**: reset governor limits; `stopTest()` forces enqueued async to run synchronously so you can assert results.
- **Callouts are prohibited in tests** without a mock: `HttpCalloutMock` registered via `Test.setMock(...)`.
- Use real assertions (`Assert.areEqual`). Test single-record, **bulk (200+ records)**, and negative paths. Never hardcode Ids.

**Managed-package caveat:** package-specific automation only fires in tests if you explicitly enable it in test setup.

### Debugging

- `System.debug(LoggingLevel.ERROR, msg)` — structured output; **never log PII** (names, addresses, DOB, medical, file contents). Log record Ids and user/subject Ids only.
- Debug logs: 20 MB per log; set user trace flags in Setup or via CLI (`sf apex run`, `sf apex get log`, `sf apex tail log`).
- A sandbox debug-log probe is the fastest way to identify *which automation step* mutated a field unexpectedly after save.

### Deployment tooling — pick by team/scale

| Tool | Use when |
|---|---|
| **Salesforce CLI + DX source format** (`sf project deploy start` / `retrieve start`) | Team dev, CI/CD, Git diff at field level |
| Change Sets | Quick ad-hoc org↔org, no VCS, small changes |
| Metadata API / package.xml | Scripted/enterprise, underlies all the above |

**SFDX rules:**
- **SFDX project root is the directory containing `sfdx-project.json`.** All `sf project ...` commands must run from that directory or fail with `InvalidProjectWorkspaceError`.
- After any metadata change, cert rotation, or new sandbox, run a full auth → describe → upsert → cleanup smoke test.
- **Sandbox types:** Developer (200 MB), Developer Pro (1 GB), Partial Copy (5 GB, 10k records/object), Full Copy (exact prod copy).
- **Test levels in deploy:** `RunLocalTests` (excludes managed-package tests) is the right CI default.

**Connected App / External Client App (ECA) gotchas:**
- Classic Connected App creation may be gated — deploying `connectedApp-meta.xml` returns *"You can't create a connected app."* Pivot to an **ECA**.
- **ECA permission assignment is on the ECA itself** (ECA → Policies → App Policies → Select Permission Sets), not the classic "Assigned Connected Apps" page. Verify via `PermissionSetAssignment` SOQL.
- **ECA Consumer Key is UI-only** — not exposed by Tooling API or metadata retrieve.

---

## Decision Scenarios

The two scenarios below cover the highest-value PD1 operational gotchas. Additional scenarios: [references/scenarios.md](references/scenarios.md) — load for package trigger coexistence, bulkification failure patterns, and Quick Action cache issues.

---

**Scenario 1 — FLS after SFDX deploy: field exists but SOQL fails**

> **Situation:** A developer deploys a new custom field `Revenue_Tier__c` (Text, 50) on `Account` via `sf project deploy start`. The field appears in Setup → Object Manager. A SOQL query `SELECT Revenue_Tier__c FROM Account LIMIT 1` run as System Administrator in Execute Anonymous immediately throws `"System.QueryException: Invalid field: Revenue_Tier__c"`.
>
> **Competent move:** The field was created but FLS was granted to nobody — not even System Administrator. SFDX `field-meta.xml` creates the field schema; it does **not** grant field permissions. Add an explicit `<fieldPermissions>` entry to a permission set or profile covering the System Administrator, redeploy, then re-run the SOQL.
>
> **Tempting-but-wrong:** Assuming "View All Data" / "Modify All Data" bypasses FLS on custom fields. It does not. Object-level access and FLS are independent.
>
> **Verify:** Run `SELECT Revenue_Tier__c FROM Account LIMIT 1` as the target user. If it still errors after adding the `<fieldPermissions>` entry, confirm the permission set is assigned to the user.

---

**Scenario 2 — Async tool choice: outbound callout needed from a trigger**

> **Situation:** A business rule requires that when an `Opportunity` is closed-won, the org must POST the opportunity data to an external REST endpoint. A developer proposes doing this in an `after update` trigger directly, using `Http.send()`.
>
> **Competent move:** Callouts are **prohibited in trigger context** — Apex throws `"System.CalloutException: You have uncommitted work pending"` whenever DML has already run in the transaction (which a trigger guarantees). Offload to `@future(callout=true)` passing the Opportunity Id (primitive), or a `Queueable` implementing `Database.AllowsCallouts`. Choose Queueable if you need to chain further jobs or track the job Id.
>
> **Tempting-but-wrong:** Wrapping `Http.send()` in a `try/catch` inside the trigger. The `CalloutException` is a runtime enforcement — it fires regardless of catch blocks.
>
> **Verify:** In a sandbox, call `Http.send()` directly in the trigger — you'll see the exception immediately. Then replace with `System.enqueueJob(new MyCalloutQueueable(oppId))` and confirm the callout fires via debug log after the transaction commits.

---

## Operational Rules Quick Reference

Read this first. Each rule is imperative and concrete.

- **DON'T** put any SOQL/DML inside a loop. Query into a Map once, DML a List once. (100 SOQL sync / 150 DML / 50k rows / 10s CPU.)
- **DO** assume managed-package triggers already ate part of your SOQL/DML budget — leave headroom.
- **DON'T** write a trigger for what a validation rule, formula field, or roll-up summary does declaratively.
- **DO** keep exactly one trigger per object; all logic in a handler class. On objects managed by a package trigger framework (e.g. NPSP/TDTM), register through that framework — never add a second raw trigger.
- **DO** use `before` triggers to set fields on the saving record (free persistence); `after` triggers to touch related records / system fields.
- **DON'T** assume a field is queryable after an SFDX deploy — `field-meta.xml` grants FLS to nobody. Add explicit `<fieldPermissions>`, or confirm with a live SOQL query.
- **DON'T** put a `<fieldPermissions>` entry on a `required` field — deploy fails. Required fields need no FLS entry.
- **DO** give two lookups to the same parent object distinct `relationshipName`s (role-suffixed) or deploy fails on duplicate relationship name.
- **DO** trace mysterious post-save field changes through the 14-step order of execution — suspect later steps (workflow/flow/rollup), not your own code.
- **DON'T** hand-edit generated schema constants; regenerate them from the org when field metadata changes, and commit.
- **DO** enforce field-length/picklist limits at your input-validation boundary, not via Apex truncation. Apex truncation is a legacy fallback only.
- **DON'T** log PII (names, addresses, DOB, medical, file contents) in `System.debug` or downstream logs. Log Ids only.
- **DO** wrap async + the code under test in `Test.startTest()/stopTest()`; mock all callouts with `HttpCalloutMock`. Create all test data (`SeeAllData=false`).
- **DO** hit 75% org-wide coverage to deploy; test bulk (200+), single, and negative paths; never hardcode Ids.
- **DON'T** string-concatenate user input into dynamic SOQL — use `:bind` variables.
- **DO** use `@AuraEnabled(cacheable=true)` for read-only wired Apex (no DML); plain `@AuraEnabled` + imperative call for mutations.
- **DO** bust the Quick Action cache by editing non-field metadata (`<description>`) and redeploying when new QA fields don't render.
- **DO** run all `sf project` commands from the SFDX project root (the directory with `sfdx-project.json`).
- **DO** run a full auth/describe/DML smoke test after any SF metadata change, cert rotation, or new sandbox.
- **DON'T** trust browser-AI/UI reports for ECA permission assignment — verify with a `PermissionSetAssignment` SOQL query.
- **DO** prefer `Database.insert(records, false)` for partial-success bulk loads; bare `insert` when you need all-or-nothing atomicity.
- **DO** verify every structural assumption against the live org (describe + a real SOQL query) before acting on SFDX metadata alone.

> For org-specific applications of these rules, see a per-org appendix you maintain in your own project, referenced from a CLAUDE.md.

---

## References

- [references/study-resources.md](references/study-resources.md) — credential logistics, study path, official links.
- [references/apex-oop-essentials.md](references/apex-oop-essentials.md) — collections, interfaces, inheritance, exception handling with worked examples.
- [references/visualforce.md](references/visualforce.md) — Visualforce controller types, View State, XSS safety, and testing.
- [references/scenarios.md](references/scenarios.md) — additional decision scenarios (package trigger coexistence, bulkification failure, Quick Action cache).

---

*Independent educational content to upskill AI agents. Not affiliated with or endorsed by Salesforce; all trademarks belong to their owners. "Salesforce," "Apex," "Lightning," "NPSP," and related names are trademarks of Salesforce, Inc., used here solely to identify the subject matter. Guidance only — verify against official documentation and live orgs before acting.*
