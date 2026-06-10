---
name: salesforce-platform-developer-1
description: Writing, reviewing, and deploying Apex, SOQL/SOSL, triggers, and Lightning Web Components on the Salesforce platform — trigger handlers (before/after, one-trigger-per-object), bulkification against governor limits (100 SOQL / 150 DML / 10s CPU), synchronous vs async Apex (@future, Queueable, Batch, Schedulable), LWC decorators and lifecycle, FLS/sharing enforcement in code, test classes to the 75% gate, and SFDX deployment. Use when building or reviewing Apex/trigger/SOQL/LWC code. Not declarative-only config (see salesforce-administrator) or advanced integration/async/LDV patterns (see salesforce-platform-developer-2). Scoped and benchmarked by the Platform Developer I blueprint.
metadata:
  credential: Salesforce Certified Platform Developer I
  domain: salesforce
  type: certification-playbook
---

# Salesforce Platform Developer I — Skills Reference

## Overview

The Salesforce Certified Platform Developer I (PD1) credential validates that a developer understands how to build, deploy, and maintain custom business logic and user interfaces on the Lightning Platform using programmatic tools. It covers the full Apex development lifecycle — data modeling, SOQL/SOSL queries, trigger design, asynchronous processing, Lightning Web Components, Visualforce, unit testing, and deployment tooling — alongside an understanding of when declarative tools (Flow, validation rules, formula fields) are preferable to code.

**This file is an operational playbook, not an exam outline.** Each section below states the actual rule as an actionable instruction, gives the concrete limit/number, provides decision criteria for choosing one tool over another, flags the anti-patterns to catch in review, and names the live-org verification step. Always verify a structural assumption against the live org before trusting it — SFDX metadata in source control can lag the org, and FLS/required/picklist state is *not* fully captured in the metadata XML.

The target audience is developers with object-oriented background building on or customizing Salesforce orgs. PD1 is Salesforce's entry-level developer credential and the practical prerequisite for Platform Developer II, Application Architect, and most advanced developer credentials. On an NPSP org, PD1 underpins writing safe Apex that coexists with NPSP's Table-Driven Trigger Management (TDTM) without blowing governor limits or causing trigger recursion.

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

**Apply it:** when a managed package (e.g. NPSP) has its own triggers firing inside the same transaction, they consume part of the SOQL/DML budget *before* your code runs, so you have far less than the full 100/150 in practice. Treat the budget as shared.

**Verify:** when reasoning about a real batch size, query the actual record count first — `SELECT COUNT() FROM Object__c WHERE ...` — rather than assuming.

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

**Watch for legacy automation.** Workflow Rules and Process Builder are retired for new build — use Flow or Apex. But an org may still *contain* live legacy automation (e.g. a managed-package workflow rule) — see Order of Execution. Legacy automation that already exists can still bite you.

### Relationship types — pick the right one

| Type | Child required? | Cascade delete | Roll-up summary | Reparentable | Use when |
|---|---|---|---|---|---|
| **Lookup** | No (nullable) | Optional | No | Yes | Loose association; child can exist alone |
| **Master-Detail** | Yes | Yes (always) | Yes | Optional (off by default) | Child is owned by parent; you need roll-ups; child inherits sharing |
| **Many-to-many** | via junction | — | — | — | Two-sided association → junction object with two M-D |
| **Hierarchical** | — | — | — | — | Self-reference, **User object only** |

**Lookup `relationshipName` must be unique per parent object.** Two Lookups on the same child object both pointing at the same parent object cannot share a `relationshipName` — deploy fails with *"Duplicate relationship name."* Use role-specific suffixes (e.g. `..._Primary`, `..._Secondary`). SOQL parent traversal is keyed on the field API name (`Parent_Object__r.Name`), not relationshipName, so renaming the relationship is safe.

**Verify:** describe the object to see actual relationship names and reference targets before adding a new lookup.

### External IDs & upsert

An External ID field is unique + indexed and is the key for `upsert` and integration dedup. Keying late re-linking on a stable external ID (e.g. a submission identifier) is what lets a record processed *after* the initial write re-link to the right parent with no new write logic.

### Field-level security is NOT object access — and SFDX does not carry it

Deploying a custom field via SFDX `field-meta.xml` creates the field but grants FLS to **no one — not even System Administrator.** Without explicit `<fieldPermissions>` in a profile or permission set, SOQL on that field returns *"Invalid field"* even with full object access. A permission set must explicitly grant FLS on each custom field that needs to be queried/edited.

**Required fields must be omitted from `<fieldPermissions>`.** Salesforce rejects field permissions on a `<required>true</required>` field with *"You cannot deploy to a required field"* (required fields are always visible/editable). So: a field is either required (no FLS entry needed) or you must add an explicit FLS entry — there is no third state where it "just works."

**Verify before trusting a field is queryable:** describing the object shows whether your running user can see the field; a SOQL query selecting the field is the definitive check. If it errors "Invalid field," the field exists but FLS is missing.

### Data import/export tooling — pick by volume

| Tool | Volume | Objects | Use when |
|---|---|---|---|
| Import Wizard | < 50k | standard + custom | one-off, UI-driven, dedup needed |
| Data Loader | 5M+ | all | bulk, CLI/scriptable, scheduled |
| **NPSP Data Import** | any | NPSP objects | nonprofit recovery/load (purpose-built for nonprofits) |

For nonprofit orgs, prefer NPSP Data Import over vanilla Data Loader for failed-write recovery and bulk loads that must respect NPSP's data model.

---

## Process Automation & Logic (25–30%) — heaviest section

### Bulkify everything — the #1 rule

**Never put SOQL or DML inside a for loop.** Query once into a Map keyed by Id, iterate in memory, collect results into a List, then issue one DML at the end. A trigger that does SOQL-in-loop hits the 100-query limit at ~100 records; DML-in-loop hits 150 statements.

**Red flag in review:** any `[SELECT ...]`, `Database.query`, `insert`, `update`, `upsert`, or `delete` whose lexical position is inside a `for`/`while` body. Catch it on sight.

```apex
// WRONG — SOQL + DML in loop
for (Contact c : Trigger.new) {
    Account a = [SELECT Id FROM Account WHERE Id = :c.AccountId]; // dies at scale
    a.Number_Of_Contacts__c += 1;
    update a; // dies at scale
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

**Decision:** use `Database.insert(records, false)` when partial success is acceptable (bulk loads where you log and continue); use bare `insert` when atomicity is required.

### Trigger design — one trigger per object, logic in a handler

- **Exactly one trigger per object.** Multiple triggers on the same object have undefined firing order. Route all context to a handler class.
- **before vs. after:**
  - `before insert/update` → modify field values on the records being saved (no DML on Trigger.new needed; the save persists your changes for free). Lowest cost.
  - `after insert/update` → access system-set fields (Id, CreatedDate, formula recalcs) and create/update *related* records.
- **Recursion control:** guard with a static Boolean so a re-entrant save doesn't re-run the handler.
- **Context variables:** `Trigger.new/old/newMap/oldMap`, `Trigger.isInsert/isUpdate/isDelete`, `Trigger.isBefore/isAfter`. `Trigger.old`/`oldMap` are null on insert.

**NPSP note:** NPSP uses **TDTM (Table-Driven Trigger Management)** — one managed master trigger per object delegates to handler classes registered in `TDTM_Config__mdt`. Custom handlers implement `npsp.TDTM_Runnable` and register *without* touching managed code. PD1's "one trigger per object + handler" pattern *is* the TDTM pattern. Do not add a second raw trigger to an NPSP-managed object; register a TDTM handler instead.

### Order of Execution — the 14 steps that decide what fires when

1. Load record; system validation (required fields, field format, max length)
2. **Before triggers**
3. System + **custom validation rules**, duplicate rules
4. Record saved to DB (**not committed**)
5. **After triggers**
6. Assignment rules
7. Auto-response rules
8. **Workflow rules** (legacy) — *if a workflow does a field update, before+after triggers fire AGAIN on that object*
9. Escalation rules
10. Roll-up summary recalc on parent (re-triggers parent's automation)
11. Criteria-based sharing recalc
12. **Processes (legacy Process Builder) + record-triggered Flows**
13. **Commit** to database
14. Post-commit: email alerts, async (`@future`, Queueable, Batch enqueued), Platform Event publish

**Why it matters:** a later step in the order of execution can silently overwrite a field your trigger just set. A classic case: a legacy managed-package workflow rule (order-of-execution step 8) copies one field onto another after insert, undoing what your `before` trigger wrote. When a field mysteriously changes after your trigger, suspect a later step (workflow/flow/rollup), not your own code — and confirm with an Apex debug-log probe, which reveals *which automation step* mutated the field.

### Validation rules vs. Apex truncation — fail early, don't silently lose data

A field write that exceeds the target field length will be truncated or rejected. **Rule:** enforce target-field length and picklist constraints at your *input-validation* boundary (e.g. a form/API schema), so a too-long value fails at validation rather than being silently truncated downstream. A defensive Apex truncation helper should exist only as a last-line fallback for legacy records and direct-API submissions that bypass the validated path — **not** as a substitute for keeping the input constraints current with the org's field metadata.

**Keep the source of truth in sync.** When the length/picklist constraints are generated from the org, regenerate them whenever field metadata changes (field resized, picklist edited) rather than hand-editing the generated artifacts.

**Verify field lengths/picklists against the live org:** describing an object returns each field's `length` and picklist `values` — that is the source of truth. If a validation max disagrees with the describe, regenerate/update it.

### SOQL & SOSL

- **Child→parent:** dot notation, up to 5 levels — `SELECT Contact.Account.Owner.Name FROM Contact`.
- **Parent→child:** subquery using the *child relationship name* — `SELECT Id, (SELECT Id FROM Children__r) FROM Parent__c`.
- **SOQL vs. SOSL:** SOQL when you know the object(s) and filter structured fields; **SOSL** (`FIND 'term' IN ALL FIELDS RETURNING Contact(Id,Name)`) for full-text search across multiple objects. SOSL counts against its own 20/transaction limit.
- **Selective queries / LDV:** filter on indexed fields (Id, Name, External ID, lookup fields, audit fields) to stay selective and avoid full-table scans on large objects.

**Dynamic SOQL injection:** use bind variables (`:var`) — never string-concatenate user input. If you must concatenate, `String.escapeSingleQuotes()`.

**Verify a query before relying on it:** run it against the live org. This simultaneously confirms FLS (an "Invalid field" error means missing field permissions), relationship names, and that records actually match.

### Asynchronous Apex — pick the right async tool

| Need | Use | Key constraints |
|---|---|---|
| Fire-and-forget after txn; HTTP callout from trigger context | **@future** (`callout=true`) | `static void`, **primitive params only — no sObjects (pass Ids)**, no chaining, 50/txn |
| Chainable jobs, hold sObject state, monitor via job Id | **Queueable** (`implements Queueable`) | 1 child chain depth in async; `Database.AllowsCallouts` for callouts |
| >10k records, process in chunks | **Batch** (`Database.Batchable<SObject>`) | `start()`→QueryLocator, `execute()` per chunk, `finish()`; batch size default 200, max 2000; each chunk its own governor limits |
| Time-based / recurring | **Schedulable** (`implements Schedulable`) | cron via `System.schedule`; often just enqueues a Batch |

**Decision shortcut:** callout from a trigger → @future or Queueable. Need to chain or keep object state → Queueable. Huge volume → Batch. Recurring clock → Schedulable.

When integration writes happen via the REST API from an external runtime rather than Apex, async Apex isn't on that hot path — but any in-org post-processing (e.g. creating `ContentVersion` / `ContentDocumentLink` records on approval) should use Queueable/Batch to stay within limits.

### with/without/inherited sharing

- `with sharing` → enforces the running user's record-level sharing.
- `without sharing` → ignores sharing (system context). **Apex runs `without sharing` by default if unspecified in a top-level entry class.**
- `inherited sharing` → adopts the caller's sharing; safest default for reusable classes.
- Note: sharing keywords govern *record access*, not FLS/CRUD — enforce those separately with `WITH SECURITY_ENFORCED` in SOQL or `Security.stripInaccessible()`.

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

- **Three files:** `.html` (template), `.js` (controller), `.js-meta.xml` (targets/exposure); optional scoped `.css`.
- **Decorators:** `@api` (public, reactive, parent→child), `@wire` (reactive data binding to Apex/wire adapter), `@track` (rarely needed now — fields are reactive by default; only for deep mutation of object/array).
- **Lifecycle:** `constructor()` → `connectedCallback()` (DOM not ready; good for init/subscriptions) → `renderedCallback()` (after render; guard against loops) → `disconnectedCallback()` → `errorCallback()`.
- **Events:** child→parent via `this.dispatchEvent(new CustomEvent('name', {detail}))`; parent→child via `@api` property/method; cross-tree via LMS (Lightning Message Service).
- **Apex from LWC:** `@AuraEnabled(cacheable=true)` for read-only wired methods (cacheable methods **cannot do DML**); `@AuraEnabled` (no cacheable) for mutations, called imperatively. Import: `import m from '@salesforce/apex/Class.method'`.

**Anti-pattern:** DML inside a `cacheable=true` method (won't compile/run as wired). Unbounded work in `renderedCallback()` that re-renders and loops.

### Quick Actions and the runtime cache

Declarative Quick Actions drive per-record Lightning contextual tabs/panels without custom code; a richer custom UI would be an LWC with wired Apex.

**Quick Action cache gotcha:** adding fields to an existing Quick Action's `quickActionLayoutItems` via SFDX updates the metadata but the **runtime QA cache does NOT invalidate** — even after full logout/login. New fields silently don't render, no error. **Fix:** edit any *non-field-list* metadata on the QA (`<description>`, `<label>`, `<layoutSectionStyle>`) and redeploy; Salesforce treats it as a structural change and flushes the org-level cache. Keep this as the go-to cache-bust pattern.

### Visualforce (still tested)

- Controller types: **Standard** (`standardController="Account"`), **Custom** (Apex class, no extension), **Extension** (augments standard/custom).
- View State limit **170 KB**; mark non-persistent fields `transient`.
- Default output is HTML-encoded (XSS-safe); `escape="false"` needs explicit justification; `{!JSENCODE()}` for inline JS.

---

## Testing, Debugging & Deployment (20–22%)

### Apex testing — coverage and structure

- **75% org-wide Apex coverage required to deploy to production** (measured across all Apex, not just new code). Every trigger must have *some* coverage. Aim well above 75% for real confidence — coverage is a floor, not a goal.
- `@isTest` on class/methods; `@testSetup` runs once per class and rolls back after each test method.
- **Tests see no org data by default** (`SeeAllData=false`). Create all test data in the test. Avoid `SeeAllData=true`.
- **`Test.startTest()` / `Test.stopTest()`**: reset governor limits between setup and the code under test; `stopTest()` forces enqueued async (future/queueable/batch) to run synchronously so you can assert results.
- **Callouts in tests are prohibited** without a mock: implement `HttpCalloutMock`, register via `Test.setMock(...)` before invoking.
- Use real assertions: `Assert.areEqual(expected, actual, msg)` (or legacy `System.assertEquals`). Test single-record, **bulk (200+ records)**, and negative/exception paths. Never hardcode Ids.

**NPSP caveat:** NPSP managed code does not auto-run in tests; rollups/household/relationship automation only fire if you explicitly enable NPSP features in the test setup. Don't assume NPSP side effects in assertions unless you've enabled them.

### Debugging

- `System.debug(LoggingLevel.ERROR, msg)` — structured output; **never log PII** (names, addresses, DOB, medical, file contents). Log record Ids and user/subject Ids only.
- Debug logs: 20 MB per log, capped retention; set user trace flags / class log levels in Setup or via CLI.
- CLI: `sf apex run` (anonymous Apex), `sf apex get log`, `sf apex tail log`.
- A sandbox Apex debug-log probe is the fastest way to find *which automation step* mutated a field when a value changes unexpectedly after save.

### Deployment tooling — pick by team/scale

| Tool | Use when |
|---|---|
| **Salesforce CLI + DX source format** (`sf project deploy start` / `retrieve start`) | Team dev, CI/CD, Git diff at field level |
| Change Sets | Quick ad-hoc org↔org, no VCS, small changes |
| Metadata API / package.xml | Scripted/enterprise, underlies all the above |

**SFDX rules:**
- The **SFDX project root is the directory containing `sfdx-project.json`, not necessarily the repo root.** All `sf project ...` commands must run from that directory or they fail with `InvalidProjectWorkspaceError`.
- DX source format is decomposed (one XML per field) — Git-diffable. Custom fields/permsets/flows/Apex on top of a managed package are SFDX-managed; the managed package itself (e.g. NPSP) cannot be retrieved/modified via SFDX.
- After any metadata change, cert rotation, or new sandbox, run a smoke test that exercises the full auth → describe → upsert idempotency → cleanup chain — it catches FLS/required/relationship gotchas at the layer they bite.
- **Sandbox types:** Developer (200 MB), Developer Pro (1 GB), Partial Copy (5 GB, 10k records/object), Full Copy (exact prod copy, UAT/perf).
- **Test levels in deploy:** `RunLocalTests` (excludes managed-package tests) is the right CI default; `RunAllTestsInOrg` includes managed. Production deploys run tests automatically.

**Connected App / External Client App gotchas:**
- Classic Connected App creation may be **gated** in modern org configs — deploying `connectedApp-meta.xml` returns *"You can't create a connected app… contact Salesforce Customer Support."* The pivot is to an **External Client App (ECA)**; stage the classic Connected App metadata for the day it's unblocked.
- **ECA permission assignment is on the ECA itself, not the permission set.** The classic "Assigned Connected Apps" page does NOT authorize ECA usage. Working path: ECA detail → Policies tab → Edit → App Policies → **Select Permission Sets.** Verify via API (`PermissionSetAssignment` query / `SetupEntityAccess`) — browser-AI/UI tools often edit the wrong place and report false success.
- **ECA Consumer Key is UI-only** — not exposed by Tooling API, REST, Connect API, or metadata retrieve; it's behind email verification in the SF UI. No scriptable path.

---

## Operational Rules Quick Reference

Read this first. Each rule is imperative and concrete.

- **DON'T** put any SOQL/DML inside a loop. Query into a Map once, DML a List once. (100 SOQL sync / 150 DML / 50k rows / 10s CPU.)
- **DO** assume managed-package triggers (e.g. NPSP) already ate part of your SOQL/DML budget — leave headroom.
- **DON'T** write a trigger for what a validation rule, formula field, or roll-up summary does declaratively.
- **DO** keep exactly one trigger per object; all logic in a handler class. On NPSP objects, register a TDTM handler — never add a second raw trigger.
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

## Developer Fundamentals — Apex OOP Essentials

PD1 tests object-oriented foundations in the Developer Fundamentals domain (23–27%). These are actionable rules, not theory.

### Collections

- **List** — ordered, allows duplicates; indexed access; the default for DML (pass a `List<SObject>` to `insert`/`update`).
- **Set** — unordered, no duplicates; use to deduplicate Ids before a SOQL `WHERE Id IN :idSet`.
- **Map** — key→value; the bulkify workhorse: `Map<Id, SObject>` keyed on the parent Id so you can look up related records in O(1) during the loop.

**Anti-pattern:** iterating a `List` with `contains()` in an inner loop → O(n²). Move the lookup values into a `Set` first.

### Interfaces and inheritance

- `implements InterfaceName` — class must provide all methods declared in the interface with matching signatures.
- `extends` — inherits concrete methods; child can `override` virtual/abstract methods.
- `virtual` → can be overridden. `abstract` → must be overridden (class is also abstract). `override` keyword is required on the child method.
- Access modifiers: `public`, `private`, `protected` (visible in subclasses), `global` (visible to managed-package consumers and external code). Default is `private`.

**NPSP application:** `implements npsp.TDTM_Runnable` is a PD1 interface pattern. The interface declares `run(List<SObject>, List<SObject>, npsp.TDTM_Runnable.Action, Schema.DescribeSObjectResult)`; your handler provides the body.

### Exception handling

- `try { } catch (DmlException e) { } catch (Exception e) { } finally { }` — `finally` always runs.
- Rethrowing: `throw e;` or wrap in a custom exception type (`public class MyException extends Exception {}`).
- `Database.insert(records, false)` returns `SaveResult[]` — inspect `.isSuccess()` per row to avoid losing partial successes in a silent catch block.

---

## Decision Scenarios

The five scenarios below cover the highest-value operational gotchas for PD1 work. Each follows the format from the authoring policy: Situation → Competent move → Tempting-but-wrong → Verify.

---

**Scenario 1 — FLS after SFDX deploy: field exists but SOQL fails**

> **Situation:** A developer deploys a new custom field `Revenue_Tier__c` (Text, 50) on `Account` via `sf project deploy start`. The field appears in Setup → Object Manager. A SOQL query `SELECT Revenue_Tier__c FROM Account LIMIT 1` run as System Administrator in Execute Anonymous immediately throws `"System.QueryException: Invalid field: Revenue_Tier__c"`.
>
> **Competent move:** The field was created but FLS was granted to nobody — not even System Administrator. SFDX `field-meta.xml` creates the field schema; it does **not** grant field permissions. Add an explicit `<fieldPermissions>` entry for the field to a permission set or profile that covers the System Administrator, redeploy, then re-run the SOQL. Confirm with `Schema.SObjectType.Account.fields.Revenue_Tier__c.getDescribe().isAccessible()` in Anonymous Apex before relying on the field in production code.
>
> **Tempting-but-wrong:** Assuming that System Administrator's "View All Data" / "Modify All Data" profile permissions bypass FLS on custom fields. They do not. Object-level access and FLS are independent. The sysadmin sees the field in Setup UI because Setup uses system context; runtime SOQL uses the running-user's FLS.
>
> **Verify:** Run `SELECT Revenue_Tier__c FROM Account LIMIT 1` as the target user (or use `Security.stripInaccessible` to see what gets stripped). If it still errors after adding the `<fieldPermissions>` entry, confirm the permission set is assigned to the user.

---

**Scenario 2 — Async tool choice: outbound callout needed from a trigger**

> **Situation:** A business rule requires that when an `Opportunity` is closed-won, the org must POST the opportunity data to an external REST endpoint. A developer proposes doing this in an `after update` trigger directly, using `Http.send()`.
>
> **Competent move:** Callouts are **prohibited in trigger context** — Apex throws `"System.CalloutException: You have uncommitted work pending"` if DML has already run in the transaction (which a trigger guarantees). The fix is to offload the callout to an `@future(callout=true)` method or a `Queueable` that implements `Database.AllowsCallouts`. Pass the Opportunity Id (primitive) to `@future`, or enqueue a `Queueable` from the trigger's after-update handler. Choose Queueable if you need to chain further jobs or track the job Id.
>
> **Tempting-but-wrong:** Wrapping the `Http.send()` call in a `try/catch` inside the trigger and hoping it won't throw. The `CalloutException` is a runtime enforcement, not a code-path issue — it fires regardless of catch blocks because the runtime checks for uncommitted DML before allowing the callout.
>
> **Verify:** In a sandbox trigger, call `Http.send()` directly — you'll see the exception immediately. Then replace with `System.enqueueJob(new MyCalloutQueueable(oppId))` from the after-update handler and confirm the callout fires via debug log after the transaction commits.

---

**Scenario 3 — NPSP object trigger: raw trigger vs. TDTM registration**

> **Situation:** A developer needs custom logic to run whenever a `Contact` is inserted or updated on an NPSP org. They write a standard `ContactTrigger.trigger` and deploy it.
>
> **Competent move:** NPSP already has its own master `ContactTrigger` managing its TDTM framework. Deploying a second raw `ContactTrigger` either fails on deploy (duplicate trigger name error) or, on a different API name, creates a second trigger with **undefined firing order relative to NPSP's trigger**. The correct approach: create a handler class that implements `npsp.TDTM_Runnable`, then register it in `TDTM_Config__mdt` with the target object, action (Insert/Update), and load order. This slots the custom logic into NPSP's managed execution sequence without touching managed code.
>
> **Tempting-but-wrong:** Naming the custom trigger something like `CustomContactTrigger` to avoid the duplicate-name problem. This appears to work but produces two triggers on the same object firing in unpredictable order, which can corrupt NPSP's household and relationship rollups or cause recursion that hits governor limits.
>
> **Verify:** After registering the TDTM handler, insert a Contact in a sandbox and pull the debug log. Confirm the custom handler's entry and exit appear inside NPSP's trigger execution stack, not after it. Run the full suite of NPSP Apex tests to confirm no regressions.

---

**Scenario 4 — Bulkification: "it works in dev, fails in production"**

> **Situation:** A developer tests a trigger by updating a single Account. It works. In production, a nightly batch process updates 500 Accounts at once, and the trigger throws `"System.LimitException: Too many SOQL queries: 101"`.
>
> **Competent move:** The trigger contains a SOQL query inside a `for (Account a : Trigger.new)` loop — each record issues one query, so 500 records = 500 queries, far above the synchronous limit of 100. Fix: extract all Account Ids from `Trigger.new` into a `Set<Id>` before the loop, run one `SELECT … WHERE Id IN :acctIds` query into a `Map<Id, SObject>`, then iterate `Trigger.new` doing only in-memory map lookups. Issue a single `update` or `insert` after the loop.
>
> **Tempting-but-wrong:** Catching the `LimitException` and processing in smaller chunks inside the trigger. `LimitException` is not catchable in Apex — it terminates the transaction immediately. There is no retry path from inside a trigger.
>
> **Verify:** Write a test that inserts or updates 200+ records in a single DML call and run it against the trigger. If the query count stays at 1–2 regardless of record volume, the bulkification is correct. The test will surface the `LimitException` before production does.

---

**Scenario 5 — Quick Action cache: new fields silently missing after deploy**

> **Situation:** A developer adds three new fields to an existing Quick Action's layout via SFDX (`quickActionLayoutItems` in the `.quickAction-meta.xml`) and deploys successfully. Testers report that the new fields do not appear in the Quick Action dialog — no error, just the old field list.
>
> **Competent move:** Salesforce caches Quick Action layouts at the org level. Adding or removing fields from `quickActionLayoutItems` does **not** bust this cache, even on full logout/login. To force a cache invalidation, make a change to any *non-field-list* property of the Quick Action metadata — typically edit the `<description>` or `<label>` by one character — then redeploy. Salesforce treats the structural metadata change as new and flushes the cached layout.
>
> **Tempting-but-wrong:** Clearing browser cache, logging out and back in, or using a different browser. The cache is server-side at the org level, not in the client browser. Client-side cache clearing has no effect.
>
> **Verify:** After the cache-bust redeploy, open the Quick Action in a fresh browser session (incognito). The new fields should render. If they still do not, confirm the `quickActionLayoutItems` XML is correctly structured and that the deploy completed without errors using `sf project deploy report`.

---

## Study resources & relevance

Study resources (official Salesforce + community) and the NPSP/nonprofit relevance notes are kept in [references/study-resources.md](references/study-resources.md) so this skill stays focused on operational rules. Load that file when planning a study path or mapping these rules to a nonprofit org.

---

*Independent educational content to upskill AI agents. Not affiliated with or endorsed by Salesforce; all trademarks belong to their owners. "Salesforce," "Apex," "Lightning," "NPSP," and related names are trademarks of Salesforce, Inc., used here solely to identify the subject matter. Guidance only — verify against official documentation and live orgs before acting.*
