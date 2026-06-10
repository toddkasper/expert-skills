---
name: salesforce-platform-developer-2
description: Advanced Apex, integration, async processing, and performance work on the Salesforce platform — design patterns (Singleton, Strategy, fflib, Bulk State Transition), asynchronous patterns (Batch/Queueable/Future/Schedulable, chaining), SOQL selectivity and Large Data Volume tuning, Platform Events, Change Data Capture, REST/Bulk API integration, dynamic Apex with FLS/CRUD enforcement, and test mocking (Stub API). Use when designing or reviewing advanced Apex, integration, or performance-critical code. Not Apex fundamentals (see salesforce-platform-developer-1) or declarative config (see salesforce-administrator). Scoped and benchmarked by the Platform Developer II (Plat-Dev-301) blueprint.
metadata:
  credential: Salesforce Certified Platform Developer II
  exam-code: Plat-Dev-301
  domain: salesforce
  type: certification-playbook
---

# Salesforce Platform Developer II — Skills Reference

## Overview

The Salesforce Certified Platform Developer II (PD2 / PDII) certification validates advanced proficiency in designing, building, and optimizing Salesforce applications using Apex, Lightning Web Components, Aura, Visualforce, and the full suite of Salesforce integration and automation tools. It targets experienced developers who write *correct, performant, and maintainable* code at enterprise scale — not just code that compiles.

The credential has **two parts**: a multiple-choice exam **and four Trailhead Superbadges** (Apex Specialist, Data Integration Specialist, Lightning Component Framework Specialist, Advanced Apex Specialist). The superbadges replace the legacy Programming Assignment and are still required — both parts must be completed to earn the credential.

**This file is an operational playbook, not an exam outline.** It states the rules as actionable instructions with concrete limits, decision criteria, and anti-patterns to catch in review. Read **Operational Rules Quick Reference** first, then drill into the topic sections.

> **Deeper context:** Study resources and the NPSP/nonprofit relevance notes live in [references/study-resources.md](references/study-resources.md) (loaded on demand). For org-specific applications of these rules, see a per-org appendix you maintain in your own project, referenced from a CLAUDE.md.

> **Verify steps assume nothing about your tooling** — use your project's Salesforce MCP connection, the Salesforce CLI (`sf`), or the Salesforce setup UI, in that order of preference.

---

Credential logistics and study path: see [references/study-resources.md](references/study-resources.md).

---

## Governor Limits — Memorize These Numbers

These are the hard ceilings every decision below is measured against. Per-transaction unless noted; "async" = future/queueable/batch-execute/schedulable context.

| Limit | Synchronous | Asynchronous |
|---|---|---|
| SOQL queries | 100 | 200 |
| SOQL rows retrieved | 50,000 | 50,000 |
| DML statements | 150 | 150 |
| DML rows | 10,000 | 10,000 |
| SOSL queries | 20 | 20 |
| HTTP callouts | 100 | 100 |
| CPU time | 10,000 ms | 60,000 ms |
| Heap size | 6 MB | 12 MB |
| Future calls | 50 | n/a (can't call future from future) |
| Queueable jobs enqueued | 50 (sync) / 1 (from queueable) | 1 from within execute |
| Batch QueryLocator rows | n/a | 50,000,000 |
| Aggregate query rows | 2,000 grouped rows | same |

**Decision rule:** if a transaction could touch more than ~10k records, it must be Batch Apex (QueryLocator, 50M ceiling), never a single synchronous transaction.

---

## Apex Triggers & Automation

### Bulkify all DML — the single most-tested rule

Never put SOQL or DML inside a `for` loop. Query once into a `Map`, iterate in memory, collect into a `List`, DML once after the loop.

**RED FLAG to catch in review:** any `[SELECT ...]`, `Database.query(...)`, `insert`, `update`, `upsert`, `delete`, or `EventBus.publish` whose enclosing braces are inside a loop body. Also catch `List.contains()` inside a loop (O(n²)) — replace with a `Map`/`Set` lookup (O(1)).

```apex
// WRONG — N+1, blows SOQL limit at 100 records
for (Contact c : Trigger.new) {
    Account a = [SELECT Id FROM Account WHERE Id = :c.AccountId]; // SOQL in loop
}
// RIGHT — one query, map lookup
Set<Id> acctIds = new Set<Id>();
for (Contact c : Trigger.new) acctIds.add(c.AccountId);
Map<Id, Account> byId = new Map<Id, Account>([SELECT Id FROM Account WHERE Id IN :acctIds]);
```

### One trigger per object, logic in a handler class

The trigger body is a thin dispatcher; all logic lives in a handler. **Anti-pattern:** two triggers on the same object — execution order between them is undefined, and you get duplicate/conflicting automation. If you find a second trigger on an object, consolidate.

**NPSP-specific:** NPSP objects (Contact, Account, Opportunity) are governed by **TDTM (Table-Driven Trigger Management)**, not raw triggers. To add behavior to an NPSP object, write a class extending `npsp.TDTM_Runnable`, override `run()`, and register it in the `Trigger_Handler__c` table with a **Load Order** controlling sequence relative to NPSP's own handlers. Do not drop a raw `trigger` on Contact in an NPSP org — it runs outside TDTM's ordering and fights NPSP automation.

### Trigger contexts — pick the right one

| Need | Context |
|---|---|
| Default/validate field values before save (no extra DML, no Id yet on insert) | `before insert` / `before update` |
| Mutate the record itself | `before` (just set the field; do **not** issue DML on Trigger.new) |
| Create/relate **other** records, roll-ups, send events | `after insert` / `after update` (Id exists) |
| React to deletes / restore | `before delete` / `after delete` / `after undelete` |

`Trigger.new` is read-write only in `before` contexts; in `after`, it's read-only (assigning to it throws). Use `Trigger.newMap`/`oldMap` keyed by Id for old-vs-new comparison (the "Bulk State Transition" pattern — only act on records whose watched field actually changed).

### Declarative vs. programmatic — choose deliberately

| Scenario | Tool | Why |
|---|---|---|
| Required-field / cross-field validation, no DML | **Validation Rule** | Cheapest, runs first, no code |
| Field updates, record creation, simple branching, email | **Record-Triggered Flow** | Admin-maintainable, no test coverage burden |
| Complex branching, recursion control, bulk algorithmic logic, callouts, dynamic SOQL | **Apex Trigger + handler** | Flow can't do callouts inline or complex collection logic safely |
| Scheduled/async heavy processing | **Batch/Queueable/Scheduled Apex** | Governor headroom + chaining |

**One-automation-per-object principle:** don't have a Flow AND a trigger both mutating the same object on the same event — ordering is hard to reason about and you double the limit consumption. Pick one owner per (object, event).

**Verify before extending:** before adding automation to an object, describe it and check existing flags/automation; query `Trigger_Handler__c` rows to see TDTM registrations in an NPSP org. If an object uses boolean role flags instead of Record Types to distinguish record kinds, branch on the flags, not RecordTypeId.

---

## Error Handling & Transactional Integrity

- **Partial-success DML:** `Database.insert(records, false)` (allOrNone=false) lets good rows commit while bad rows fail; inspect `Database.SaveResult[]` → `.isSuccess()` / `.getErrors()`. Plain `insert` is all-or-nothing and throws `DmlException` on any failure.
- **Savepoints:** `Savepoint sp = Database.setSavepoint(); ... Database.rollback(sp);` to undo partial work in a complex transaction. Note: setting a savepoint and rolling back still counts against DML statement limits, and rollback resets the savepoint variable.
- **Surface errors to UI:** `record.addError('msg')` or `record.Field__c.addError('msg')` in a `before` trigger blocks the save and shows the message inline.
- **Unhandled exceptions roll back the entire transaction** — including prior successful DML in the same transaction. Catch at the boundary, log, decide whether to re-throw.
- **Capture, don't lose:** when an integration write to Salesforce can fail, persist the failed payload somewhere durable and alert an operator rather than dropping the data — the same instinct PD2 tests via partial-success DML.

---

## Asynchronous Apex — Pick the Right Tool

| Tool | Use when | Key limits / notes |
|---|---|---|
| `@future(callout=true)` | Fire-and-forget callout, simple primitive args | **No sObject params** (pass Ids/JSON), no chaining, no return, can't call from batch/future. Hard to monitor. Prefer Queueable in new code. |
| `Queueable` | Async work needing complex state, chaining, or callouts | Pass sObjects/objects via constructor. Implement `Database.AllowsCallouts` for HTTP. Chain via `System.enqueueJob()` in `execute()` — **only 1 child per execute**; depth effectively unlimited but throttled. Monitorable via `AsyncApexJob`. |
| `Batchable` | >10k records / LDV processing | `start()` returns `Database.QueryLocator` (50M rows). Default 200 records/`execute`; tune scope down for heavy logic. `Database.Stateful` to accumulate state across chunks. Each `execute` gets a fresh set of governor limits. |
| `Schedulable` | Time-based kickoff | `System.schedule('name', cronExpr, job)`. Cron is `sec min hr day month weekday [year]`. Query `CronTrigger`/`CronJobDetail`. Usually schedules a Batch/Queueable. |

**Mixed DML error:** you cannot DML a setup object (User, Group, PermissionSetAssignment) and a non-setup object (Contact) in the same synchronous transaction. Workaround: do the setup-object DML in a `@future` method.

**RED FLAG:** synchronous HTTP callout in a trigger/UI path — move it async to avoid the 10s CPU / callout-in-trigger restrictions and to keep the UI responsive.

---

## SOQL, SOSL & Selectivity

### Write selective queries

A query is **selective** when its `WHERE` filters on an indexed field returning under the threshold: **<10% of rows (first 1M) for standard fields, <33% for custom-indexed fields**, capped at 1M rows examined. Non-selective queries on large objects throw `QueryException: Non-selective query against large object type`.

**Indexed by default:** `Id`, `Name`, `CreatedDate`, `SystemModstamp`, lookup/master-detail fields, `External Id` fields, `Unique` fields. Custom indexes are requested via Salesforce Support.

**Kills the index (forces full scan) — RED FLAGS:**
- Leading wildcard: `LIKE '%smith'`
- Negation: `!=`, `NOT IN`, `NOT LIKE`
- `NULL` checks on non-indexed fields
- Functions/operations on the indexed field in the filter
- `OR` across mixed indexed/non-indexed fields

**Verify:** use the **Query Plan** tool in Developer Console (or `EXPLAIN` via the REST Query Plan resource) to confirm `Cardinality`/`Leading Operation Type = Index`.

### SOQL features worth knowing

- `FOR UPDATE` — row lock to prevent concurrent-update races (releases at transaction end).
- `WITH SECURITY_ENFORCED` — strips fields/objects the running user can't see; throws if any selected field is inaccessible. Use `WITH USER_MODE` (newer) for full FLS+sharing enforcement in queries and DML.
- Aggregates: `COUNT()`, `SUM()`, `GROUP BY`, `HAVING` — capped at 2,000 grouped rows.
- Relationship queries: parent→child (subquery), child→parent dot-walk up to **5 levels**.
- Semi/anti-join: `WHERE Id IN (SELECT ...)` / `NOT IN (...)`.

### SOSL vs SOQL

Use **SOSL** for full-text search across multiple objects/fields (`FIND 'term' IN ALL FIELDS RETURNING Contact(Id,Name), Lead(Id)`). It counts as a single query regardless of objects searched and hits the search index, not the row store. Use **SOQL** when you know the object and are filtering on structured fields.

---

## Dynamic Apex & FLS/CRUD Enforcement

- Runtime metadata: `Schema.getGlobalDescribe()`, `obj.getDescribe()`, `field.getDescribe()`. Describes are **not free** — each `getGlobalDescribe()` is expensive; cache results.
- Dynamic SOQL: `Database.query(String)`. **Injection risk** — never concatenate user input; use bind variables (`:var`) or `String.escapeSingleQuotes()`.
- Dynamic instantiation: `Type.forName('MyClass').newInstance()` (Strategy/Factory patterns).
- **Programmatic FLS/CRUD checks:** `Schema.sObjectType.Contact.fields.Email.isAccessible()/isUpdateable()/isCreateable()`, or `Security.stripInaccessible()` to drop fields the user can't touch before DML. PD2 expects you to enforce FLS in code that runs `without sharing` or in API context.

---

## Sharing & Security

- **Three independent layers:** object CRUD (profile/permset) → field-level security (FLS, profile/permset) → record access (OWD + role hierarchy + sharing rules + manual/Apex shares). All three must pass. **FLS is separate from object access** — granting object access does not grant field access.
- **Sharing keywords:** `with sharing` (enforce running user's record visibility), `without sharing` (ignore it — use sparingly, for system operations), `inherited sharing` (adopt caller's context; the safe default for reusable library classes).
- **Apex managed sharing:** insert `AccountShare`/`OpportunityShare`/`MyObject__Share` rows with `RowCause` (use a custom `Apex Sharing Reason` so manual recalculation can find them). Programmatic shares survive role changes only if you maintain them.

**Deployment gotcha:** SFDX `field-meta.xml` deploys grant **FLS to no one — not even System Admin**. You must list `<fieldPermissions>` in a permission set or profile XML or every query returns *"Invalid field"* even with full object access. Salesforce also rejects `<fieldPermissions>` on `<required>true</required>` fields (*"You cannot deploy to a required field"*) — required fields are always visible/editable, so omit them from `fieldPermissions`. Verify a deploy actually landed FLS with a `PermissionSetAssignment` + `FieldPermissions` query, not by trusting the deploy success message.

---

## Platform Events & Integration

### Platform Events

- Define as `MyEvent__e`; publish with `EventBus.publish(events)`; subscribe via an **after-insert trigger on the event** (only after-insert is valid), a Flow, or CometD/external subscriber.
- `publish-after-commit` (default) vs `publish-immediately` behavior; published events are **not rolled back** with the transaction under publish-immediately.
- `ReplayId` enables durable replay (resume from last consumed event). 72-hour retention (24h standard-volume).
- Use for **decoupled, fire-and-forget** integration — e.g., record status changes flowing to an external app without tight coupling, the natural evolution over polling.

### Inbound integration — pick the API

| Need | API |
|---|---|
| Standard CRUD, single/few records | REST API (sObject endpoints) |
| Custom server-side endpoint | `@RestResource` Apex (`@HttpGet/Post/Put/Patch/Delete`) |
| Large batch loads (CSV, 1000s–millions) | Bulk API 2.0 (async, job-based) |
| Several dependent ops in one round-trip | Composite / Composite Graph API |
| Real-time push to subscribers | Streaming API / Platform Events / CDC |

**Idempotent upsert on an External Id** is the canonical inbound pattern: define a custom field marked External Id and `Unique`, and have the integration client upsert against it. Re-running the same payload then updates rather than duplicates, and lets later related writes re-link to the same record without new write logic.

### Outbound callouts

`Http`/`HttpRequest`/`HttpResponse`. Store endpoints + auth in **Named Credentials** (never hardcode secrets/URLs). Callout limit 100/transaction; total timeout 120s, 10s default per call. **Every callout must be mocked in tests** (`HttpCalloutMock`) — tests cannot make real callouts.

---

## Lightning Web Components

### Wire vs imperative Apex

| Use | When |
|---|---|
| `@wire(apexMethod, {params})` | Read-only, reactive, **cacheable** data for display. Method must be `@AuraEnabled(cacheable=true)` and side-effect-free. Re-invokes when reactive params (`$param`) change. |
| Imperative (`import m from '@salesforce/apex/...'; await m({})`) | On-demand fresh data, mutations (DML), or when you need to call in an event handler / control timing. |

`cacheable=true` Apex **cannot do DML**. For mutations, call imperatively (and the method must not be cacheable).

### Component communication

| Direction | Mechanism |
|---|---|
| Parent → child | `@api` properties / `@api` methods (call child method from parent) |
| Child → parent | `this.dispatchEvent(new CustomEvent('name', {detail}))` |
| Unrelated components | Lightning Message Service: `MessageChannel`, `publish`, `subscribe` |

`@api` = public reactive; bare fields are reactive to reassignment; `@track` only needed for deep mutation of objects/arrays (rarely now). Lifecycle order: `constructor` → `connectedCallback` → `render` → `renderedCallback` (fires after every render — **never** put unguarded state changes here, you'll cause infinite re-render, a classic perf bug).

**Error display:** server errors → `ShowToastEvent`; record-form errors via `lightning-record-edit-form`/`lightning-messages`. Run client-side `reportValidity()` before hitting the server.

### Framework selection

LWC (default — fastest, modern) > Aura (only for platform features still requiring it; Aura can host LWC, not vice-versa) > Visualforce (PDF rendering via `renderAs="pdf"`, legacy pages). Don't write new Aura/VF unless a specific platform capability forces it.

---

## Testing, Debugging & Deployment

### Tests

- **75% org-wide coverage required to deploy to production**, every trigger must have *some* coverage. Coverage must be **meaningful — assert outcomes**, don't just execute lines.
- `Test.startTest()/stopTest()` — gives a fresh set of governor limits inside, and **flushes async jobs** (future/queueable/batch run synchronously at `stopTest()`) so you can assert their results.
- `@testSetup` — create shared test data once per test class.
- **`seeAllData=false` is the default and the rule.** Create your own data. `seeAllData=true` only for the rare case of org-config dependencies you cannot insert (e.g., certain standard pricebooks); never for record data.
- **Mock all callouts:** `Test.setMock(HttpCalloutMock.class, new MyMock())` / `WebServiceMock` for SOAP. Use `StubProvider` for dynamic mock objects without real implementations.
- **LWC Jest:** `createElement` + `appendChild`, query `shadowRoot.querySelector`, mock `@wire` with `@salesforce/wire-service-jest-util`, simulate with `dispatchEvent`.

### Debugging

Developer Console (logs, Query Plan, checkpoints) · VS Code + Apex Replay Debugger (needs `FINEST` log level to replay) · `System.debug(LoggingLevel.X, msg)` · query stored `ApexLog`. **Never `System.debug` PII** — sensitive data must not land in logs.

### Deployment

- SFDX source format under `force-app/main/default/`; `sf project deploy start` / `retrieve start`. **Run commands from the SFDX project root** (the directory containing `sfdx-project.json`), not a parent repo root, or you get `InvalidProjectWorkspaceError`.
- Deploy order dependencies: objects before fields, fields before the permsets that reference them, profiles before users.
- Sandboxes: Developer (config only) < Developer Pro < Partial Copy (sample data) < Full (everything, prod-clone). Scratch orgs (source-driven, ephemeral, shape-defined) for feature dev.
- **Metadata-cache surprise:** adding fields to an existing Quick Action via SFDX updates the metadata but does **not** always invalidate the runtime Quick Action cache that drives Lightning contextual tabs (the `console:relatedRecord` component) — even after logout/login. Cache-bust by editing any non-field-list metadata on the QA (`<description>`/`<label>`/`<layoutSectionStyle>`) and redeploying; Salesforce treats that as a structural change and flushes the cache.

---

## Performance & Large Data Volumes

- **Selectivity first** (see SOQL section) — the #1 LDV lever.
- **CPU/heap:** build strings with `List<String>` + `String.join()` (not `+=` in a loop); `Map`/`Set` for lookups, not nested loops; hoist invariant work out of loops; null out large collections you're done with to free heap (6MB sync / 12MB async).
- **LDV tools:** Skinny Tables (Support-created, denormalized read acceleration) · custom indexes (Support) · Big Objects (`__b`, billions of immutable rows, Async SOQL) · archiving · avoid **owner skew** (one user owning >10k records causes sharing-recalc lock contention) and **lookup/account skew** (many children under one parent → record-lock contention on parallel DML).
- **N+1 detection — RED FLAG:** query inside loop, `SOQL_QUERIES` count scaling with input size, `List.contains()` in a loop, repeated `getGlobalDescribe()`.
- **UI perf:** prefer cached `@wire` over repeated imperative calls; lazy-load; keep `renderedCallback` cheap and idempotent.

---

## Advanced Fundamentals

- **Custom Metadata Types vs Custom Settings:**
  - **CMT (`__mdt`):** deployable, packageable, queryable in SOQL **without consuming the SOQL governor limit** (cached). Use for configuration that ships with the app / varies by environment. NPSP stores config in CMTs (e.g., `Trigger_Handler__mdt`, relationship config). Write programmatically via `Metadata.Operations.enqueueDeployment` (async).
  - **Custom Settings:** `List` (global constants) or `Hierarchy` (per-profile/per-user fallback). In-memory, no SOQL cost via `getInstance()/getValues()`. Use for per-user/per-profile runtime toggles.
  - **Decision:** configuration that needs deployment/packaging/relationships → CMT. Per-user/profile runtime override → Hierarchy Custom Setting.
- **Multi-currency:** `CurrencyIsoCode` on records; `DatedConversionRate` for historical rates; guard logic with `UserInfo.isMultiCurrencyOrganization()`; never hardcode currency math.
- **Design patterns to recognize/apply:** Singleton (one instance/transaction, avoid re-querying), Strategy (swap algorithm at runtime), Decorator (wrap an sObject for UI), Bulk State Transition (act only on changed records via old/new maps), Facade (simplify a complex subsystem), and the enterprise **Service / Selector / Domain** layering (fflib).

---

## Operational Rules Quick Reference

Read this first. Each is imperative and concrete.

- **DO** query once into a `Map` and DML once outside loops. **DON'T** ever put SOQL/DML/`EventBus.publish` inside a `for` loop (100 SOQL / 150 DML / 50k rows ceiling).
- **DO** keep one trigger per object with logic in a handler class. **DON'T** add a second trigger to an object, or a raw trigger to an NPSP object (use `npsp.TDTM_Runnable` + Load Order).
- **DO** mutate records in `before` contexts; create related records / roll-ups in `after`. **DON'T** assign to `Trigger.new` in an `after` trigger (throws).
- **DO** use Validation Rule → Flow → Apex in increasing order of complexity; one automation owner per (object, event). **DON'T** have a Flow and a trigger both mutating the same object on the same event.
- **DO** check how an object distinguishes record kinds before branching (Record Types vs. boolean flags) and branch accordingly. **DON'T** assume every object uses Record Types.
- **DO** make queries selective on indexed fields and verify with Query Plan. **DON'T** use leading wildcards, `!=`, `NOT IN`, or functions on indexed fields on large objects.
- **DO** move HTTP callouts off the synchronous/UI path (Queueable + `Database.AllowsCallouts`). **DON'T** call out synchronously from a trigger.
- **DO** pass Ids/JSON to `@future`; prefer `Queueable` for anything with state or chaining. **DON'T** pass sObjects to `@future`, or try to chain from a future.
- **DO** use Batch Apex (`QueryLocator`, 50M ceiling) above ~10k records. **DON'T** process LDV in a single synchronous transaction.
- **DO** explicitly grant FLS via `<fieldPermissions>` in a permset/profile, and **omit** `<required>true</required>` fields from it. **DON'T** assume a deployed field is visible — SFDX field XML grants FLS to no one.
- **DO** store endpoints/secrets in Named Credentials. **DON'T** hardcode URLs/keys in Apex.
- **DO** mock every callout (`HttpCalloutMock`/`WebServiceMock`) and assert real outcomes. **DON'T** rely on line-execution alone for the 75% coverage gate.
- **DO** keep `seeAllData=false` and build data in `@testSetup`. **DON'T** use `seeAllData=true` for record data.
- **DO** wrap async work in `Test.startTest()/stopTest()` to flush and assert it. **DON'T** assert async results without `stopTest()`.
- **DO** use `@wire`+`cacheable=true` for reads, imperative Apex for mutations. **DON'T** do DML in a `cacheable=true` method, or change state unguarded in `renderedCallback` (infinite render).
- **DO** enforce FLS/CRUD in code (`WITH USER_MODE` / `Security.stripInaccessible` / describe checks) in API/`without sharing` paths. **DON'T** trust object access to imply field access.
- **DO** use CMT for deployable/packaged config (free SOQL), Hierarchy Custom Settings for per-user runtime toggles.
- **DO** run `sf project deploy` from the SFDX project root. **DON'T** run it from a parent repo root (`InvalidProjectWorkspaceError`).
- **DO** verify changes against the live org via API query before trusting a deploy/config "success" message. **DON'T** assume a UI tool edited the right place.
- **DON'T** log PII (names, addresses, DOB, medical, file contents) via `System.debug`.

---

## Recursion Control in Triggers

A trigger fires once per DML statement on the object. If your `after update` handler updates the same object, that fires the trigger again — potentially looping until a governor limit kills it. The standard fix: a static Boolean guard in a separate utility class.

```apex
public class TriggerGuard {
    public static Boolean hasRun = false;
}
// In handler:
if (TriggerGuard.hasRun) return;
TriggerGuard.hasRun = true;
// ... logic ...
```

Static variables reset per transaction, so the guard is scoped to one execution chain. **Edge case:** if you intentionally need the trigger to fire twice (e.g., initial insert then a follow-up update), scope the guard to context (`before insert`, `after update`) rather than a single Boolean.

**NPSP orgs:** TDTM has its own recursion detection built in. Handlers extending `npsp.TDTM_Runnable` only need a guard if they themselves issue a DML that would re-fire the same TDTM handler at the same load-order slot.

---

## Invocable Apex — Bridging Flow and Code

When a Flow needs logic that exceeds its declarative capabilities (complex loops, callouts, collection algebra), expose an Apex method to Flow via `@InvocableMethod`.

```apex
public class RateCalculator {
    @InvocableMethod(label='Calculate Rates' description='Computes tiered rates for opportunities')
    public static List<Decimal> calculate(List<Id> oppIds) { ... }
}
```

Rules that trip developers:
- The method must be `static`, `public`/`global`, in a non-inner class.
- Input/output are **`List<T>`** — Flow passes a collection even for a single record.
- Complex inputs/outputs use an inner class whose fields are annotated `@InvocableVariable`.
- **Callouts from Flow-invoked Apex:** allowed, but the Flow must call the action in an asynchronous path (Screen Flow pause / scheduled path) or the org must permit sync callouts in the path. Test with `HttpCalloutMock` exactly as you would in any Apex test.
- **Bulkification:** the method receives all records in the batch at once. Process as a collection, not one-by-one.

---

## Change Data Capture (CDC)

CDC publishes change events (`AccountChangeEvent`, `ContactChangeEvent`, custom-object `MyObject__ChangeEvent`) on the change-event bus whenever records are created, updated, deleted, or undeleted in Salesforce.

Consume via:
- An **after-insert trigger on the change-event object** (same as platform events).
- A CometD subscriber / external system.

Key payload fields: `ChangeEventHeader.changeType` (`CREATE`, `UPDATE`, `DELETE`, `UNDELETE`), `ChangeEventHeader.changedFields` (which fields actually changed), and `ChangeEventHeader.recordIds` (the affected record Ids).

**Design use:** CDC is the preferred real-time data-replication pattern for external systems that need a near-realtime copy of Salesforce data. It replaces polling (`SELECT … WHERE LastModifiedDate > :checkpoint`) and is more reliable than outbound messages for high-volume objects.

**Gotcha:** CDC change events are **not** rolled back if the originating transaction rolls back — the event was already committed. Design downstream consumers to be idempotent.

---

## Decision Scenarios

These scenarios target the highest-value operational gotchas — places where a plausible choice turns out to be wrong in a non-obvious way. They are original teaching material, not exam questions.

---

**Scenario 1 — Async chaining and the "one child per execute" rule**

> **Situation:** A nightly data-quality job must process 2 million Contact records in stages: first normalize phone formats, then deduplicate, then update a roll-up on Account. A developer proposes three separate Batch Apex jobs chained by calling `Database.executeBatch(new DeduplicateBatch())` at the end of the phone-format batch's `finish()` method.

> **Competent move:** Chaining from `finish()` is the correct Batchable pattern — `finish()` runs in a fresh transaction context, so calling `Database.executeBatch` there is allowed and does not violate the "one Queueable child per execute" restriction (that rule applies to Queueable, not Batch). Model each stage as its own `Batchable` class and pass state between them via a shared Custom Object or `Database.Stateful`. Set scope size conservatively (50–100 records per execute) for the deduplication stage where per-record SOQL is heavier.

> **Tempting-but-wrong:** Calling `System.enqueueJob(new DeduplicateQueueable(...))` from inside a Batch `execute()` method. This is blocked — you cannot enqueue a Queueable from within a batch execute context (only from `finish()`). A developer who confuses the restriction may also try chaining a second Queueable from within a Queueable's `execute()`, thinking they can fan out; in fact each Queueable execute may enqueue **exactly one** child, so fan-out requires stacking, not parallel spawning.

> **Verify:** Check `AsyncApexJob` records after a test run — each stage should appear as a separate job with `Status = Completed`. In unit tests, wrap each stage in `Test.startTest()/stopTest()` to force synchronous execution and assert intermediate state.

---

**Scenario 2 — FLS after a successful SFDX deploy**

> **Situation:** A developer deploys a new custom field `Loan_Rate__c` on the Opportunity object via SFDX source push. The deploy log shows `Deploy Succeeded`. The developer then writes an Apex class that queries `Loan_Rate__c` and runs it as a System Administrator. The query returns `null` for every row even though the field has data in the org.

> **Competent move:** The field metadata XML in SFDX grants the field's existence — it does **not** automatically grant FLS to any profile or permission set, including System Administrator. Create or update a permission set metadata file with an explicit `<fieldPermissions>` entry (`readable: true`, `editable: true`) for `Opportunity.Loan_Rate__c` and deploy it. After the deploy, verify with `SELECT Id, Field, PermissionsRead FROM FieldPermissions WHERE SobjectType = 'Opportunity' AND Field = 'Opportunity.Loan_Rate__c'`.

> **Tempting-but-wrong:** Assuming the System Administrator profile bypasses FLS in Apex queries. It does not — Apex running in the default `without sharing` context still respects FLS, and fields the running user's profile cannot read are stripped from query results silently (they return `null`, not an error, which is why this bug is hard to spot). A developer may also try adding `<fieldPermissions>` for a field marked `<required>true</required>` in the object XML — Salesforce rejects this deployment with a metadata error ("You cannot deploy to a required field"). Required fields are always accessible; omit them.

> **Verify:** Query `FieldPermissions` in Developer Console or via the REST API. A missing row means no permission was granted — the deploy succeeded at the metadata layer but FLS was never assigned.

---

**Scenario 3 — Platform event publish timing and transaction rollback**

> **Situation:** An Apex trigger on Order uses `EventBus.publish(new Fulfillment_Request__e(...))` to notify a downstream fulfillment system. In testing, the developer discovers that when the Order DML fails (a validation rule fires), the fulfillment system still occasionally receives the event and tries to fulfill a non-existent Order.

> **Competent move:** By default, platform events published via `EventBus.publish()` use **publish-after-commit** semantics — the event is only delivered if the triggering transaction commits successfully. If the Order DML fails and rolls back, the event is suppressed. The developer should confirm the event definition's `Publish Behavior` is set to `Publish After Commit` (the default). If they are using `publish-immediately` (explicit opt-in on the event definition), the event fires regardless of transaction outcome — which is the cause of the phantom fulfillment requests. Switch to `Publish After Commit`.

> **Tempting-but-wrong:** Wrapping the publish in a try/catch and checking the `Database.SaveResult` from `EventBus.publish()` to decide whether to proceed. `EventBus.publish()` returns save results, but a "success" result only means the event was *accepted into the bus*, not that the parent transaction will commit. The downstream ordering problem is about publish behavior (when delivery occurs relative to commit), not about whether the publish call itself succeeded.

> **Verify:** Set `Publish Behavior` on the event definition to `Publish After Commit` in Setup → Platform Events. Write an Apex test that inserts a record, publishes the event, then forces a rollback via a `Database.rollback(savepoint)`, and assert the subscriber trigger does **not** execute (use a static counter in the subscriber trigger, assert it remains 0 after `Test.stopTest()`).

---

**Scenario 4 — Recursion from a Record-Triggered Flow and an Apex trigger on the same object**

> **Situation:** An Account object has both a Record-Triggered Flow (fires on update, sets a field) and an Apex trigger (fires on update, does roll-up logic). In production, some Account updates cause a `System.LimitException: Too many SOQL queries: 101` error, but only when both automations are active.

> **Competent move:** The Flow's field update fires the Apex trigger a second time (Flow DML counts as a new trigger invocation). The Apex trigger's SOQL queries are then being consumed twice per original update — if they were already near the 100-limit, the second invocation pushes over. Apply the "one automation owner per (object, event)" principle: pick one owner. If both are needed, add a recursion guard in the Apex trigger (`TriggerGuard.hasRun`) so the second invocation from the Flow's DML exits immediately. Alternatively, refactor the Flow update into the Apex handler and remove the Flow to eliminate the double-fire.

> **Tempting-but-wrong:** Increasing the SOQL budget by moving queries into a Queueable to "buy headroom." This masks the root cause — the trigger is still firing twice, consuming CPU and DML headroom twice — and adds async complexity. The fix is to eliminate the double-invocation, not to absorb it with async headroom.

> **Verify:** Enable Debug Logs at `APEX_CODE: FINEST` during a test update. Count how many times the trigger handler's entry log line appears — it should appear once per DML. If it appears twice, the recursion is confirmed and the guard is needed.

---

**Scenario 5 — Dynamic SOQL injection via concatenated filter**

> **Situation:** A developer writes an Apex REST endpoint that accepts a `status` parameter from the request body and builds a SOQL query: `String q = 'SELECT Id FROM Order__c WHERE Status__c = \'' + status + '\''; List<Order__c> results = Database.query(q);`. A security review flags this as a critical vulnerability.

> **Competent move:** Use a bind variable to parameterize the filter: `String q = 'SELECT Id FROM Order__c WHERE Status__c = :status'; List<Order__c> results = Database.query(q);`. Apex bind variables in dynamic SOQL are never concatenated into the query string — the platform substitutes them safely, preventing injection. Where bind variables cannot be used (e.g., dynamic field names in the SELECT clause), sanitize with `String.escapeSingleQuotes()` before concatenation. Also add `WITH USER_MODE` to enforce FLS/sharing: `'SELECT Id FROM Order__c WHERE Status__c = :status WITH USER_MODE'`.

> **Tempting-but-wrong:** Validating the `status` value against an allowlist in Apex before concatenating it. Allowlist validation is a useful defense-in-depth measure but should never replace parameterization — an allowlist can be bypassed if the list is incorrect, or if a future code change adds another concatenated field without updating the allowlist. The platform's bind variable mechanism is the correct primary defense.

> **Verify:** Write a test that passes a value like `' OR '1'='1` as the status parameter and assert it throws an exception or returns 0 rows (not all rows). With bind variables, the value is treated as a literal string, so the injected SQL logic is inert.

---

## Study resources & relevance

Study resources (official Salesforce + community) and the NPSP/nonprofit relevance notes are kept in [references/study-resources.md](references/study-resources.md) so this skill stays focused on operational rules. Load that file when planning a study path or mapping these rules to a nonprofit org.

---

*Independent educational content to upskill AI agents. Not affiliated with or endorsed by Salesforce; "Salesforce," "Apex," "Lightning," and all related marks are trademarks of Salesforce, Inc., used here solely to identify the subject matter. All trademarks belong to their respective owners. Guidance only — verify against official Salesforce documentation and live orgs before acting. No certification outcome is implied or guaranteed.*
