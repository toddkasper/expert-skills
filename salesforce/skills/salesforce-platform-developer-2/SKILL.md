---
name: salesforce-platform-developer-2
description: Advanced Apex, integration, async processing, and performance work on the Salesforce platform — design patterns (Singleton, Strategy, fflib, Bulk State Transition), asynchronous patterns (Batch/Queueable/Future/Schedulable, chaining), SOQL selectivity and Large Data Volume tuning, Platform Events, Change Data Capture, REST/Bulk API integration, dynamic Apex with FLS/CRUD enforcement, and test mocking (Stub API). Use when designing or reviewing advanced Apex, integration, or performance-critical code. Not Apex fundamentals (see salesforce-platform-developer-1) or declarative config (see salesforce-administrator). Scoped and benchmarked by the Platform Developer II (Plat-Dev-301) blueprint.
metadata:
  anchor-credential: Salesforce Certified Platform Developer II
  exam-code: Plat-Dev-301
  domain: salesforce
  type: certification-playbook
  status: current
  last-reviewed: 2026-06-09
  blueprint-verified: 2026-06-07
---

# Salesforce Platform Developer II — Skills Reference

## Overview

The Salesforce Certified Platform Developer II (PD2 / PDII) certification validates advanced proficiency in designing, building, and optimizing Salesforce applications using Apex, Lightning Web Components, Aura, Visualforce, and the full integration and automation stack. It targets developers who write *correct, performant, and maintainable* code at enterprise scale.

The credential has **two parts**: a multiple-choice exam **and four Trailhead Superbadges** (Apex Specialist, Data Integration Specialist, Lightning Component Framework Specialist, Advanced Apex Specialist).

**This file is an operational playbook, not an exam outline.** Rules are stated as actionable instructions with concrete limits, decision criteria, and anti-patterns to catch in review.

> **Load this skill when…** designing or reviewing advanced Apex (design patterns, async chaining, LDV processing); building or debugging REST/Bulk API integrations or Platform Events; optimizing SOQL selectivity or Large Data Volume performance; implementing dynamic Apex with programmatic FLS/CRUD enforcement.
> **Not this skill:** Apex fundamentals (triggers, basic SOQL, LWC essentials, 75% test coverage) → see `salesforce-platform-developer-1`; declarative config (profiles, Flow, sharing rules) → see `salesforce-administrator`.

> **Verify steps assume nothing about your tooling** — use your project's Salesforce MCP connection, the Salesforce CLI (`sf`), or the Salesforce setup UI, in that order of preference.

---

Credential logistics and study path: see [references/study-resources.md](references/study-resources.md).

---

## Uncertainty & Escalation

- **Always re-verify live:** all governor limit numbers (SOQL/DML/CPU/heap/callout/Queueable chain depth) `[volatile — verify live]`; Platform Event retention windows and replay behavior `[volatile — verify live]`; SOQL selectivity thresholds `[volatile — verify live]`; Batch API and Bulk API 2.0 limits and behaviors; any quota or cap cited in this skill.
- **Live wins:** if this skill's numbers or rules conflict with Apex runtime behavior, Query Plan output, or official Salesforce release notes, the live system is authoritative. Log the discrepancy immediately using the Feedback protocol below.
- **Escalate to a human before proceeding:** production deploys of async chaining patterns (Queueable/Batch) not validated in a sandbox; any code that writes to setup objects (User, PermissionSetAssignment) in a non-test context; adding `without sharing` to a class processing PII or financial data; deploying a Platform Event subscriber that could duplicate-write production records if CDC events replay.
- **Confidence taxonomy:** facts in this skill are stable unless tagged `[volatile — verify live]` or `[opinion — house style]`. When in doubt, use Query Plan or run a test transaction in a sandbox before assuming a limit applies.

---

## Governor Limits — Memorize These Numbers

These are the hard ceilings every decision below is measured against. Per-transaction unless noted; "async" = future/queueable/batch-execute/schedulable context.

| Limit | Synchronous | Asynchronous |
|---|---|---|
| SOQL queries | 100 `[volatile — verify live]` | 200 |
| SOQL rows retrieved | 50,000 | 50,000 |
| DML statements | 150 `[volatile — verify live]` | 150 |
| DML rows | 10,000 | 10,000 |
| SOSL queries | 20 | 20 |
| HTTP callouts | 100 | 100 |
| CPU time | 10,000 ms `[volatile — verify live]` | 60,000 ms |
| Heap size | 6 MB `[volatile — verify live]` | 12 MB |
| Future calls | 50 | n/a (can't call future from future) |
| Queueable jobs enqueued | 50 (sync) / 1 (from queueable) `[volatile — verify live]` | 1 from within execute |
| Batch QueryLocator rows | n/a | 50,000,000 `[volatile — verify live]` |
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

The trigger body is a thin dispatcher; all logic lives in a handler. **Anti-pattern:** two triggers on the same object — execution order between them is undefined. If you find a second trigger on an object, consolidate.

**Recursion control:** guard with a static Boolean so a re-entrant save doesn't re-run the handler. Deep dive with patterns and edge cases: [references/recursion-control.md](references/recursion-control.md) — load when diagnosing trigger re-entry or implementing context-scoped guards.

**Package trigger framework note:** some managed packages own objects through their own trigger framework. To add behavior to such an object, plug into the framework's registration mechanism rather than dropping a second raw trigger (e.g. NPSP uses TDTM; see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md)).

### Trigger contexts — pick the right one

| Need | Context |
|---|---|
| Default/validate field values before save (no extra DML, no Id yet on insert) | `before insert` / `before update` |
| Mutate the record itself | `before` (just set the field; do **not** issue DML on Trigger.new) |
| Create/relate **other** records, roll-ups, send events | `after insert` / `after update` (Id exists) |
| React to deletes / restore | `before delete` / `after delete` / `after undelete` |

`Trigger.new` is read-write only in `before` contexts; in `after`, it's read-only (assigning to it throws). Use `Trigger.newMap`/`oldMap` keyed by Id for old-vs-new comparison (the **Bulk State Transition** pattern — only act on records whose watched field actually changed).

### Declarative vs. programmatic — choose deliberately

| Scenario | Tool | Why |
|---|---|---|
| Required-field / cross-field validation, no DML | **Validation Rule** | Cheapest, runs first, no code |
| Field updates, record creation, simple branching, email | **Record-Triggered Flow** | Admin-maintainable, no test coverage burden |
| Complex branching, recursion control, bulk algorithmic logic, callouts, dynamic SOQL | **Apex Trigger + handler** | Flow can't do callouts inline or complex collection logic safely |
| Scheduled/async heavy processing | **Batch/Queueable/Scheduled Apex** | Governor headroom + chaining |

**One-automation-per-object principle:** don't have a Flow AND a trigger both mutating the same object on the same event — ordering is hard to reason about and you double the limit consumption.

**Verify before extending:** describe the object and check existing automation; on a package-managed org, query the package's handler-registration table (e.g. `Trigger_Handler__c` for NPSP).

---

## Error Handling & Transactional Integrity

- **Partial-success DML:** `Database.insert(records, false)` lets good rows commit while bad rows fail; inspect `Database.SaveResult[]` → `.isSuccess()` / `.getErrors()`. Plain `insert` is all-or-nothing and throws `DmlException` on any failure.
- **Savepoints:** `Savepoint sp = Database.setSavepoint(); ... Database.rollback(sp);` to undo partial work. Setting and rolling back still counts against DML statement limits.
- **Surface errors to UI:** `record.addError('msg')` or `record.Field__c.addError('msg')` in a `before` trigger blocks the save and shows the message inline.
- **Unhandled exceptions roll back the entire transaction** — including prior successful DML. Catch at the boundary, log, decide whether to re-throw.
- **Capture, don't lose:** when an integration write fails, persist the payload somewhere durable rather than dropping it.

---

## Asynchronous Apex — Pick the Right Tool

| Tool | Use when | Key limits / notes |
|---|---|---|
| `@future(callout=true)` | Fire-and-forget callout, simple primitive args | **No sObject params** (pass Ids/JSON), no chaining, no return, can't call from batch/future. Prefer Queueable in new code. |
| `Queueable` | Async work needing complex state, chaining, or callouts | Pass sObjects/objects via constructor. Implement `Database.AllowsCallouts` for HTTP. Chain via `System.enqueueJob()` in `execute()` — **only 1 child per execute**. Monitorable via `AsyncApexJob`. |
| `Batchable` | >10k records / LDV processing | `start()` returns `Database.QueryLocator` (50M rows). Default 200 records/`execute`; tune scope down for heavy logic. `Database.Stateful` to accumulate state across chunks. Each `execute` gets fresh governor limits. |
| `Schedulable` | Time-based kickoff | `System.schedule('name', cronExpr, job)`. Cron is `sec min hr day month weekday [year]`. Query `CronTrigger`/`CronJobDetail`. Usually schedules a Batch/Queueable. |

**Mixed DML error:** you cannot DML a setup object (User, Group, PermissionSetAssignment) and a non-setup object (Contact) in the same synchronous transaction. Workaround: do the setup-object DML in a `@future` method.

**RED FLAG:** synchronous HTTP callout in a trigger/UI path — move it async to avoid the 10s CPU / callout-in-trigger restrictions and to keep the UI responsive.

**Invocable Apex (`@InvocableMethod`):** exposes Apex to Flow. Method must be `static`, in a non-inner class; input/output are `List<T>` (Flow always passes a collection). Process the full input list at once — never SOQL per input. Deep dive with callout rules and `@InvocableVariable` patterns: [references/invocable-apex.md](references/invocable-apex.md) — load when writing or debugging Flow-invoked Apex actions.

---

## SOQL, SOSL & Selectivity

### Write selective queries

A query is **selective** when its `WHERE` filters on an indexed field returning under the threshold: **<10% of rows (first 1M) for standard fields, <33% for custom-indexed fields** `[volatile — verify live]`, capped at 1M rows examined. Non-selective queries on large objects throw `QueryException: Non-selective query against large object type`.

**Indexed by default:** `Id`, `Name`, `CreatedDate`, `SystemModstamp`, lookup/master-detail fields, External Id fields, Unique fields. Custom indexes are requested via Salesforce Support.

**Kills the index (forces full scan) — RED FLAGS:**
- Leading wildcard: `LIKE '%smith'`
- Negation: `!=`, `NOT IN`, `NOT LIKE`
- `NULL` checks on non-indexed fields
- Functions/operations on the indexed field in the filter
- `OR` across mixed indexed/non-indexed fields

**Verify:** use the **Query Plan** tool in Developer Console (or `EXPLAIN` via the REST Query Plan resource) to confirm `Leading Operation Type = Index`.

### SOQL features worth knowing

- `FOR UPDATE` — row lock to prevent concurrent-update races (releases at transaction end).
- `WITH SECURITY_ENFORCED` — strips fields/objects the running user can't see; throws if any selected field is inaccessible. Use `WITH USER_MODE` (newer) for full FLS+sharing enforcement in queries and DML.
- Aggregates: `COUNT()`, `SUM()`, `GROUP BY`, `HAVING` — capped at 2,000 grouped rows.
- Relationship queries: parent→child (subquery), child→parent dot-walk up to **5 levels**.
- Semi/anti-join: `WHERE Id IN (SELECT ...)` / `NOT IN (...)`.

### SOSL vs SOQL

Use **SOSL** for full-text search across multiple objects/fields (`FIND 'term' IN ALL FIELDS RETURNING Contact(Id,Name), Lead(Id)`). It hits the search index, not the row store. Use **SOQL** when you know the object and are filtering on structured fields.

---

## Dynamic Apex & FLS/CRUD Enforcement

- Runtime metadata: `Schema.getGlobalDescribe()`, `obj.getDescribe()`, `field.getDescribe()`. Describes are **not free** — cache `getGlobalDescribe()` results; each call is expensive.
- Dynamic SOQL: `Database.query(String)`. **Injection risk** — never concatenate user input; use bind variables (`:var`) or `String.escapeSingleQuotes()`.
- Dynamic instantiation: `Type.forName('MyClass').newInstance()` (Strategy/Factory patterns).
- **Programmatic FLS/CRUD checks:** `Schema.sObjectType.Contact.fields.Email.isAccessible()/isUpdateable()/isCreateable()`, or `Security.stripInaccessible()` to drop fields the user can't touch before DML. PD2 expects FLS enforcement in code that runs `without sharing` or in API context.

---

## Sharing & Security

- **Three independent layers:** object CRUD → FLS → record access (OWD + role hierarchy + sharing rules + manual/Apex shares). All three must pass. **FLS is independent of object access.**
- **Sharing keywords:** `with sharing` (enforce record visibility), `without sharing` (ignore sharing — use sparingly), `inherited sharing` (adopt caller's context; safe default for reusable classes).
- **Apex managed sharing:** insert `AccountShare`/`OpportunityShare`/`MyObject__Share` rows with a custom `RowCause` (Apex Sharing Reason) so recalculation can find them.

**Deployment gotcha:** SFDX `field-meta.xml` grants **FLS to no one**. You must add `<fieldPermissions>` in a permission set or profile, or every query returns *"Invalid field."* Salesforce rejects `<fieldPermissions>` on `<required>true</required>` fields — omit them. Verify with a `FieldPermissions` SOQL query, not by trusting the deploy success message.

---

## Platform Events & Integration

### Platform Events

- Define as `MyEvent__e`; publish with `EventBus.publish(events)`; subscribe via an **after-insert trigger on the event** (only after-insert is valid), a Flow, or CometD/external subscriber.
- `publish-after-commit` (default): suppressed on rollback. `publish-immediately`: delivered regardless of transaction outcome.
- `ReplayId` enables durable replay. 72-hour retention (24h standard-volume) `[volatile — verify live]`.
- Use for decoupled, fire-and-forget integration.

**Change Data Capture (CDC):** publishes change events (`AccountChangeEvent`, `MyObject__ChangeEvent`, etc.) on record changes; subscribe via after-insert trigger on the change-event object. Key payload: `ChangeEventHeader.changeType` (CREATE/UPDATE/DELETE/UNDELETE), `changedFields`, `recordIds`. CDC events are NOT suppressed on transaction rollback — design consumers to be idempotent. Deep dive with enabling, payload, and testing: [references/cdc.md](references/cdc.md) — load when implementing CDC-based integration or debugging delivery behavior.

### Inbound integration — pick the API

| Need | API |
|---|---|
| Standard CRUD, single/few records | REST API (sObject endpoints) |
| Custom server-side endpoint | `@RestResource` Apex (`@HttpGet/Post/Put/Patch/Delete`) |
| Large batch loads (CSV, 1000s–millions) | Bulk API 2.0 (async, job-based) |
| Several dependent ops in one round-trip | Composite / Composite Graph API |
| Real-time push to subscribers | Streaming API / Platform Events / CDC |

**Idempotent upsert on an External Id** is the canonical inbound pattern: define a custom field marked External Id and Unique, and have the integration client upsert against it. Re-running the same payload updates rather than duplicates.

### Outbound callouts

`Http`/`HttpRequest`/`HttpResponse`. Store endpoints + auth in **Named Credentials** (never hardcode secrets/URLs). Callout limit 100/transaction; total timeout 120s, 10s default per call. **Every callout must be mocked in tests** (`HttpCalloutMock`).

---

## Lightning Web Components

### Wire vs imperative Apex

| Use | When |
|---|---|
| `@wire(apexMethod, {params})` | Read-only, reactive, **cacheable** data for display. Method must be `@AuraEnabled(cacheable=true)` and side-effect-free. Re-invokes when reactive params (`$param`) change. |
| Imperative (`import m from '@salesforce/apex/...'; await m({})`) | On-demand fresh data, mutations (DML), or when you need to call in an event handler / control timing. |

`cacheable=true` Apex **cannot do DML**. For mutations, call imperatively.

### Component communication

| Direction | Mechanism |
|---|---|
| Parent → child | `@api` properties / `@api` methods |
| Child → parent | `this.dispatchEvent(new CustomEvent('name', {detail}))` |
| Unrelated components | Lightning Message Service: `MessageChannel`, `publish`, `subscribe` |

`@api` = public reactive; `@track` only needed for deep mutation of objects/arrays. Lifecycle order: `constructor` → `connectedCallback` → `render` → `renderedCallback` (fires after every render — **never** put unguarded state changes here, causes infinite re-render).

### Framework selection

LWC (default) > Aura (only for platform features still requiring it; Aura can host LWC, not vice-versa) > Visualforce (PDF rendering via `renderAs="pdf"`, legacy). Don't write new Aura/VF unless a specific platform capability forces it.

---

## Testing, Debugging & Deployment

Fundamentals (75% coverage gate, `Test.startTest()/stopTest()`, `seeAllData=false`, `HttpCalloutMock`) are in `salesforce-platform-developer-1`. PD2-specific additions:

- **Meaningful coverage:** assert concrete outcomes and async state — coverage that only executes lines without asserting results does not catch regressions.
- **`StubProvider`:** dynamic mocking without a hand-rolled mock class. Use when the mock logic varies per test or when mocking a service interface.
- **LWC Jest:** `createElement` + `appendChild`, `shadowRoot.querySelector`, mock `@wire` with `@salesforce/wire-service-jest-util`. Apex Replay Debugger requires `FINEST` log level; never log PII via `System.debug`.
- **Deploy order:** objects → fields → permsets that reference them. Run `sf project deploy start` from the SFDX project root (`sfdx-project.json` directory) or get `InvalidProjectWorkspaceError`.
- **Quick Action cache:** cache-bust by editing non-field-list metadata (`<description>`) and redeploying.

---

## Performance & Large Data Volumes

- **Selectivity first** (see SOQL section) — the #1 LDV lever.
- **CPU/heap:** build strings with `List<String>` + `String.join()` (not `+=` in loop); `Map`/`Set` for lookups; null out large collections when done (6MB sync / 12MB async).
- **LDV tools:** Skinny Tables · custom indexes (both via Support) · Big Objects (`__b`, billions of rows, Async SOQL) · archiving.
- **Skew — RED FLAG:** owner skew (one user owning >10k records → sharing-recalc lock contention); lookup skew (many children under one parent → DML lock contention).
- **N+1 detection:** query/DML inside loop, SOQL count scaling with input, `List.contains()` in loop, repeated `getGlobalDescribe()`.
- **UI perf:** prefer cached `@wire`; keep `renderedCallback` cheap and idempotent.

---

## Advanced Fundamentals

CMT vs Custom Settings decision, multi-currency handling, and enterprise design patterns (Singleton, Strategy, fflib Service/Selector/Domain): [references/advanced-fundamentals.md](references/advanced-fundamentals.md) — load when choosing a config storage mechanism or implementing an enterprise-layer architecture.

**One-line decision rules (load references for full detail):**
- Config ships with app / needs deployment → **Custom Metadata Type (`__mdt`)** (free SOQL, packageable).
- Per-user/profile runtime toggle → **Hierarchy Custom Setting** (in-memory, no SOQL cost).
- Multi-currency: guard with `UserInfo.isMultiCurrencyOrganization()`; never hardcode currency math.

---

## Executable Workflows

### 1. Build a Queueable chain safely (one child per execute, depth/limits)

1. Define the first Queueable class with its state (Ids, parameters) passed via constructor. Implement `Queueable` (and `Database.AllowsCallouts` if making HTTP calls).
   → **gate:** class compiles; constructor stores only serializable state (avoid holding live SObject lists if heap is a concern).
2. In the `execute()` method, do the work (query once outside loops, DML once after loops). At the end of `execute()`, enqueue exactly one child: `System.enqueueJob(new NextStepQueueable(state))`.
   → **gate:** code review confirms exactly one `System.enqueueJob` call per `execute()` path; never enqueue inside a loop.
3. Add a depth guard: pass a `depth` integer via constructor and abort if `depth > maxDepth` (typically keep chains ≤ 5 levels for safety).
   → **gate:** unit test with `depth = maxDepth + 1` confirms the chain stops and logs a meaningful message.
4. Test: wrap in `Test.startTest()/stopTest()` to flush the first job synchronously. Assert state after the first step; test each step class independently.
   → **gate:** all test methods pass; no `System.LimitException`; assertions on final state are concrete (not just "no exception").
5. Deploy and monitor via `SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType='Queueable' ORDER BY CreatedDate DESC`.
   → **gate:** each enqueued job shows `Status = Completed`; no `Failed` rows for the chain.

---

### 2. Stand up a Platform Event producer + subscriber

1. Define the Platform Event object (`MyEvent__e`) in Object Manager with the required fields. Set `Publish Behavior` to `Publish After Commit` (default) unless immediate delivery on rollback is required.
   → **gate:** `MyEvent__e` appears in `sf sobject list` output; describe confirms expected fields.
2. Write the producer: `EventBus.publish(new MyEvent__e(Field__c = value))` inside an `after insert/update` trigger or invocable method. Capture and log publish results.
   → **gate:** in a sandbox, trigger the producer and confirm `EventBus.publish` returns `isSuccess = true`; verify the event appears in Event Monitoring or a debug log.
3. Write the subscriber trigger: `trigger MyEventSub on MyEvent__e (after insert)`. Process `Trigger.new` as a collection (bulkify). Avoid SOQL/DML inside loops.
   → **gate:** subscriber trigger compiles; query `EventBusSubscriber` or check Setup → Platform Events to confirm the subscriber is registered.
4. Write test: mock the event in a test method (`Test.startTest(); EventBus.publish(...); Test.stopTest();`). Assert subscriber side effects.
   → **gate:** test passes; subscriber logic assertions are on concrete field values, not just "no error."
5. Deploy producer and subscriber together. Smoke-test end-to-end in the sandbox: trigger the produce action and confirm subscriber side effects (e.g. related record created/updated).
   → **gate:** side-effect record exists with expected values; no debug-log errors.

---

### 3. Make a slow SOQL query selective (Query Plan → index/selective filter → re-check)

1. Open Developer Console → Query Plan tool (or REST API `EXPLAIN` endpoint). Paste the slow SOQL query and run the plan.
   → **gate:** note the `Leading Operation Type`; a result of `TableScan` means the query is non-selective.
2. Identify the filter condition causing the table scan: leading wildcard (`LIKE '%...'`), negation (`!=`, `NOT IN`), non-indexed field, or `OR` across mixed indexed/non-indexed.
   → **gate:** locate the specific clause in the WHERE that produces the scan.
3. Rewrite the filter to use an indexed field (Id, Name, External Id, lookup, audit fields like `CreatedDate`) and an equality or range predicate. If no native index exists, request a custom index via Salesforce Support.
   → **gate:** re-run Query Plan on the rewritten query — `Leading Operation Type` must change to `Index`.
4. If a custom index was requested, confirm it is active: describe the field and check `filterable` + `sortable` attributes, or run the Query Plan again after Salesforce confirms the index is built.
   → **gate:** Query Plan shows `Index` as leading operation; estimated row count is within the selectivity threshold.
5. Load-test the rewritten query with production-scale data (use a Full sandbox): confirm query returns in under 5 seconds and does not throw `QueryException: Non-selective query`.
   → **gate:** query executes without error; response time acceptable under peak load in Full sandbox.

---

## Decision Scenarios

The two scenarios below cover the highest-value PD2 operational gotchas. Additional scenarios: [references/scenarios.md](references/scenarios.md) — load for platform event rollback, Flow/trigger recursion, and dynamic SOQL injection patterns.

---

**Scenario 1 — Async chaining and the "one child per execute" rule**

> **Situation:** A nightly data-quality job must process 2 million Contact records in stages: first normalize phone formats, then deduplicate, then update a roll-up on Account. A developer proposes three separate Batch Apex jobs chained by calling `Database.executeBatch(new DeduplicateBatch())` at the end of the phone-format batch's `finish()` method.
>
> **Competent move:** Chaining from `finish()` is the correct Batchable pattern — `finish()` runs in a fresh transaction, so `Database.executeBatch` there is allowed and does not violate the "one Queueable child per execute" rule (that applies to Queueable, not Batch). Model each stage as its own `Batchable` class; pass state via `Database.Stateful` or a shared Custom Object. Tune scope size conservatively (50–100) for SOQL-heavy stages.
>
> **Tempting-but-wrong:** Calling `System.enqueueJob(...)` from inside a Batch `execute()` — blocked; only allowed from `finish()`. Also: a developer may try chaining multiple Queueable children from one `execute()`, but each execute may enqueue **exactly one** child.
>
> **Verify:** Check `AsyncApexJob` records after a test run — each stage should appear as a separate job with `Status = Completed`. In unit tests, wrap each stage in `Test.startTest()/stopTest()` to force synchronous execution and assert intermediate state.

---

**Scenario 2 — FLS after a successful SFDX deploy**

> **Situation:** A developer deploys a new custom field `Loan_Rate__c` on the Opportunity object via SFDX source push. The deploy log shows `Deploy Succeeded`. The developer then writes an Apex class that queries `Loan_Rate__c` and runs it as a System Administrator. The query returns `null` for every row even though the field has data in the org.
>
> **Competent move:** SFDX field metadata grants the field's existence — it does **not** grant FLS to any profile or permission set, including System Administrator. Add an explicit `<fieldPermissions>` entry (`readable: true`, `editable: true`) to a permission set and deploy it. Verify with `SELECT Id, Field, PermissionsRead FROM FieldPermissions WHERE SobjectType = 'Opportunity' AND Field = 'Opportunity.Loan_Rate__c'`.
>
> **Tempting-but-wrong:** Assuming System Administrator bypasses FLS in Apex queries. It does not — fields the running user can't read are stripped from query results *silently* (returning `null`, not an error, making this bug hard to spot). Also: adding `<fieldPermissions>` for a `<required>true</required>` field fails deploy — required fields are always accessible; omit them.
>
> **Verify:** Query `FieldPermissions` in Developer Console or via the REST API. A missing row means no permission was granted — the deploy succeeded at the metadata layer but FLS was never assigned.

---

## Operational Rules Quick Reference

Read this first. Each is imperative and concrete.

- **DO** query once into a `Map` and DML once outside loops. **DON'T** ever put SOQL/DML/`EventBus.publish` inside a `for` loop (100 SOQL / 150 DML / 50k rows ceiling).
- **DO** keep one trigger per object with logic in a handler class. **DON'T** add a second trigger to an object, or a raw trigger to an object owned by a package's trigger framework (register through the framework instead).
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

## References

- [references/study-resources.md](references/study-resources.md) — credential logistics, study path, official links, superbadge requirements.
- [references/recursion-control.md](references/recursion-control.md) — static Boolean guard patterns, context-scoped guards, package framework interaction.
- [references/invocable-apex.md](references/invocable-apex.md) — `@InvocableMethod` signature rules, callout paths, bulkification, testing patterns.
- [references/cdc.md](references/cdc.md) — Change Data Capture: enabling, payload structure, rollback behavior, Apex testing.
- [references/scenarios.md](references/scenarios.md) — additional decision scenarios (platform event rollback, Flow/trigger recursion, dynamic SOQL injection).
- [references/advanced-fundamentals.md](references/advanced-fundamentals.md) — CMT vs Custom Settings decision, multi-currency handling, and enterprise design patterns (Singleton, Strategy, fflib).

---

## Feedback protocol

Using this skill and hit a wall? If you find a claim contradicted by the live system or official docs, a missing rule that cost you a wrong attempt, or a decision this skill gave no criteria for — append an entry **in the moment** to `.skill-feedback/salesforce-platform-developer-2.md` at the project root (create it if absent):

`date | skill last-reviewed | claim or gap | what you observed instead | evidence (error text / doc URL / query output) | suggested fix`

These are harvested back into the skill via the learning loop. When the live system and this file disagree, trust the live system.

## Changelog

- **2026-06-09** — Conformed to the 12-dimension skill standard: task-vocab description + Scope block, Uncertainty & Escalation guidance with inline `[volatile — verify live]` marks, executable workflows, tool-agnostic verify steps, and the feedback protocol above. Exam logistics relocated to references/study-resources.md; `last-reviewed` set to 2026-06-09.

*Independent educational content to upskill AI agents. Not affiliated with or endorsed by Salesforce; "Salesforce," "Apex," "Lightning," and all related marks are trademarks of Salesforce, Inc., used here solely to identify the subject matter. All trademarks belong to their respective owners. Guidance only — verify against official Salesforce documentation and live orgs before acting. No certification outcome is implied or guaranteed.*
