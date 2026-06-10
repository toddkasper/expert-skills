---
name: salesforce-advanced-administrator
description: Advanced declarative Salesforce administration — the full sharing/security model (role hierarchy, owner/criteria sharing rules, muting and session-based permission sets), complex Flow automation and order-of-execution debugging, custom object and relationship design (master-detail, junctions, DLRS roll-ups), data management (Data Loader, duplicate/matching rules, External IDs), sandbox strategy, SFDX deployment, and auditing/monitoring (Setup Audit Trail, Field History, Event Monitoring). Use when designing or debugging org config beyond day-to-day admin. Not basic setup (see salesforce-administrator) or Apex/code (see salesforce-platform-developer-1). Scoped and benchmarked by the Advanced Administrator (Plat-Admn-301) blueprint.
metadata:
  credential: Salesforce Certified Advanced Administrator (Platform Administrator II)
  exam-code: Plat-Admn-301
  domain: salesforce
  type: certification-playbook
---

# Salesforce Advanced Administrator — Skills Reference

> This file is an **operational playbook**, not an exam outline. Each section states
> the rule as an actionable instruction, gives the real limit/number, tells you when to
> pick one tool over another, and flags the anti-patterns to catch in review. Read the
> **Operational Rules Quick Reference** near the bottom first.

## Overview

The Salesforce Certified Advanced Administrator (now branded **Salesforce Certified
Platform Administrator II**, exam code Plat-Admn-301) validates that a Salesforce
administrator can go beyond basic configuration to solve complex business problems
declaratively: the full sharing and security model, advanced automation (Flow, approval
processes, order of execution), custom object design, analytics, deployment pipelines, and
org-health monitoring. It is the next step after the Administrator credential (ADM-201 /
Plat-Admn-201) for anyone managing a non-trivial production org.

> **Deeper context:** Study resources and the NPSP/nonprofit relevance notes live in [references/study-resources.md](references/study-resources.md) (loaded on demand). For org-specific applications of these rules, see a per-org appendix you maintain in your own project, referenced from a CLAUDE.md.

---

## Exam Details

| Field | Value |
|---|---|
| Questions | 60 multiple-choice / multiple-select (+ up to 5 unscored pilot questions) |
| Time Limit | 105 minutes |
| Passing Score | 65% |
| Cost | USD $200 registration; USD $100 retake (plus applicable taxes) |
| Prerequisites | Salesforce Certified Administrator (ADM-201 / Plat-Admn-201) |
| Retake Policy | No mandatory waiting period stated; additional preparation recommended before rescheduling; standard voucher rules apply |
| Delivery | Online proctored (OnVUE) or in-person at a Pearson VUE testing center |

---

## Security and Access — Operational Knowledge

**Access is additive-only, and FLS is a separate gate from object access.** The stack is:
OWD (baseline) → role hierarchy → sharing rules → manual/Apex sharing. Every layer can only
*widen* access, never narrow it. If a record is invisible, the fix is *more* sharing, never
"less" — to restrict, you must lower the OWD first.

**FLS ≠ object access ≠ record access.** A user can have "Read All" on an object and still
get `INVALID_FIELD` on a SOQL field because FLS isn't granted. These three are independent
layers — verify all three when access fails.

- **FLS must be granted explicitly in a profile or permission set.** Deploying a custom
  field via SFDX `field-meta.xml` grants FLS to **no one — not even System Administrator.**
  The field exists but every query returns *"Invalid field."* You must add `<fieldPermissions>`
  to a permset/profile XML.
- **Never put `<fieldPermissions>` on a `<required>true</required>` field.** Deploy fails with
  *"You cannot deploy to a required field."* Required fields are always readable/editable, so
  **omit them** from fieldPermissions.
- **Page layouts control visibility but never enforce security.** Removing a field from a
  layout does not protect it — the API, reports, and SOQL still return it if FLS allows. Use
  FLS for security, layouts for UX only.

**Decision table — profiles vs. permission sets vs. permission set groups:**

| Need | Use | Why |
|---|---|---|
| Org-wide baseline (login hours, IP ranges, default record type, one profile per user) | Profile | Exactly one profile per user; it's the floor |
| Grant extra access to a subset of users (an API user, staff reporting fields) | Permission Set | Additive, reusable, assign many per user |
| Bundle 5+ permsets for a job role | Permission Set Group | Aggregates permsets; use Muting Permission Sets to subtract |
| Elevated access only during a verified/MFA session | Session-based permission set | Time-boxed privilege escalation |

Salesforce's strategic direction is **permission-set-first**: put new grants in permsets, keep
profiles thin.

**Numbers to know:** Field History Tracking max 20 fields/object. OWD options: Private,
Public Read Only, Public Read/Write, Controlled by Parent. Approval steps max 30.

**Anti-patterns / red flags:**
- A new custom field deployed via SFDX with no matching `<fieldPermissions>` entry → it will
  silently fail every query. Catch this in any field-add PR.
- "Grant access via hierarchies" left ON for a Lookup-related object when you wanted siloed
  access — managers inherit access they shouldn't have.
- Editing FLS in the *wrong* place for an External Client App: the classic Permission Set
  "Assigned Connected Apps" page does **not** authorize ECA usage. The working path is
  ECA detail → Policies → Edit → App Policies → **Select Permission Sets**.

**Verify against the live org:**
- `describe_object` on a field-bearing object → confirm the field is even visible to the API
  user (if FLS is missing, it won't appear).
- `soql_query` `SELECT Id,Field__c FROM Obj__c LIMIT 1` → an `INVALID_FIELD` error means FLS,
  not object access, is the problem.
- Confirm a permset assignment landed via `SELECT Id FROM PermissionSetAssignment WHERE
  AssigneeId='…' AND PermissionSet.Name='…'` — never trust a UI "success" toast, especially
  for ECA assignments (browser-AI tools report success while editing the wrong page).

---

## Objects and Applications — Operational Knowledge

**Pick the relationship type by the lifecycle and reporting you need, not by habit:**

| Relationship | Use when | Consequences |
|---|---|---|
| Master-Detail | Child can't exist without parent; you need roll-up summaries; child shares parent's sharing | Cascade delete; child inherits OWD/sharing; max 2 MD per object; reparenting off by default |
| Lookup | Records are independent; either side can exist alone | No roll-up summary (need DLRS/Apex/flow); independent sharing; can be required or optional |
| Junction (2 MD) | True many-to-many (NPSP Relationship, Affiliation, Soft Credit) | First MD = primary (controls detail's ownership/sharing); deleting either master deletes the junction |

- **Roll-up summary fields only exist on the Master in a Master-Detail.** SUM/COUNT/MIN/MAX
  only. For Lookups, use Declarative Lookup Rollup Summaries (DLRS), a record-triggered flow,
  or Apex.
- **Lookup `relationshipName` must be unique per parent object.** Two Lookups pointing at the
  same parent can't share a `relationshipName` (deploy fails *"Duplicate relationship name"*).
  Use role-specific suffixes. SOQL parent traversal keys on the *field* name
  (`Parent_Object__r.Name`), so renaming the relationshipName is safe.
- **Record Types control picklist values + page layout + business process per type.** Reach
  for them when one object serves multiple processes. (A common alternative is a single
  `Type__c` discriminator field on one object instead of N separate objects; Record Types are
  the path to per-type layouts on top of that.)
- **Dynamic Forms** move fields/sections off the page layout onto the Lightning record page
  with component-level visibility filters — the modern replacement for layout-driven UX.

**Anti-patterns / red flags:**
- Converting a Lookup → Master-Detail when child records have null parent values: conversion
  fails until every child has a parent. Backfill first.
- Expecting a roll-up summary on a Lookup relationship — it doesn't exist.
- Adding fields to an existing **Quick Action** and trusting they render: the runtime QA cache
  often does **not** invalidate even after deploy + logout/login. Lightning contextual tabs
  (`console:relatedRecord`) silently omit the new fields with no error. **Cache-bust fix:**
  edit any non-field-list metadata on the QA (`<description>`, `<label>`,
  `<layoutSectionStyle>`) and redeploy — SF treats that as a structural change and flushes the
  org-level QA cache.

**Verify against the live org:**
- `list_objects` (with `includeCustomOnly`) to confirm an object's API name before referencing it.
- `describe_object` to read relationship fields, `relationshipName`s, and picklist values
  before writing SOQL or a flow that traverses them.

---

## Process Automation — Operational Knowledge

**Memorize the order of execution — most automation bugs are an ordering surprise:**

1. Load record / apply old values
2. System validation (required, field formats)
3. **Before-save record-triggered flows**
4. **Before-save Apex triggers**
5. Custom **validation rules**
6. Duplicate rules
7. Record saved to DB (not committed)
8. **After-save Apex triggers**
9. Assignment rules, auto-response, workflow rules (legacy)
10. Workflow field updates re-fire before-/after-update triggers (recursion source)
11. **After-save record-triggered flows**
12. Roll-up summary recalculation on parent (can fire parent triggers/flows)
13. Criteria-based sharing recalculation
14. Commit; post-commit logic (emails, async/`@future`, platform events)

**Tool selection — pick the cheapest tool that does the job:**

| Need | Use | Don't use |
|---|---|---|
| Block bad data at save | Validation rule | A flow (slower, can't stop save as cleanly) |
| Set a field on the *same* record at save | **Before-save record-triggered flow** | After-save flow (extra DML, slower, recursion risk) |
| Update *related* records / send email / call Apex | After-save record-triggered flow | Before-save (can't do related-record DML) |
| Compute a value read-only | Formula field | Any automation (no storage, no recompute cost) |
| Complex branching, bulk loops, callouts, >limits | Apex trigger / invocable | Stacked flows that blow CPU/SOQL limits |
| Multi-user, long-running, multi-stage | Flow Orchestration | A single mega-flow |

**Bulkify everything.** Never put SOQL/DML inside a loop — in a flow, that's a Get/Update
element *inside* a loop. Query once into a collection, work in memory, do one DML on the
collection after the loop. **Per-transaction governor limits:** 100 SOQL queries, 50,000 rows
retrieved, 150 DML statements, 10,000 DML rows, 10s synchronous CPU time (60s async), 6 MB
heap (12 MB async), 100 callouts.

- **Approval processes do NOT evaluate validation rules on submission.** Don't rely on a
  validation rule to gate approval entry — put the check in the approval entry criteria.
- **Before-save flows are the cheapest same-record update** — no extra DML, runs before the
  record hits the DB. Prefer them over after-save for field defaulting.
- **Workflow Rules and Process Builder are retired/being retired.** Build new automation in
  **Flow**. Migrate legacy ones rather than extending them.

**Anti-patterns / red flags:**
- A Get Records or Update Records / Create Records element **inside a loop** in a flow → will
  hit SOQL/DML limits on bulk loads. Move it outside, operate on a collection.
- **Recursion:** an after-save flow/trigger that updates the same record it fired on, with no
  guard → infinite loop / "maximum trigger depth exceeded." Use a before-save flow, an entry
  condition (`ISCHANGED`), or a static recursion guard.
- **Field updates from automation re-trigger triggers/flows** (step 10) — the classic source
  of double-fires.
- An automation reading a field the running user has no FLS for → silently reads null (flows
  respect FLS in user context). Catch when a flow "works for admins, breaks for others."
- **Before blaming your own code, enumerate ALL automation on the object** — managed-package
  workflow rules, flows, and triggers included. A managed package can silently overwrite a
  field on insert (e.g. an NPSP workflow rule copying `Phone → MobilePhone` when
  `PreferredPhone` defaults to "Mobile"). Use a debug log to find the actual writer.

**Verify against the live org:**
- Use an Apex debug log (set a trace flag on the user) to see *every* automation that touches
  a record during DML — this is how a hidden managed-package overwrite gets caught.
- `soql_query` before/after a test write to confirm a flow set the field you expect (and
  didn't clobber another).

---

## Data and Analytics Management — Operational Knowledge

**Prevent bad data at entry, then de-dup what slips through.** Entry-time controls (required
fields, picklists, validation rules) are cheaper than cleanup. For cleanup: Matching Rules
define *similarity*; Duplicate Rules define the *action* (block / alert / report). They are
configured separately — you need both.

**Import tool selection:**

| Tool | Records | Objects | Use when |
|---|---|---|---|
| Data Import Wizard | up to 50,000 | Accounts, Contacts, Leads, Solutions, custom objects — **NOT Opportunities** | Quick UI import, simple de-dup |
| Data Loader | up to 5,000,000 | **All** objects incl. Opportunities | Large volume, CLI/batch, upsert via External ID |
| NPSP Data Importer (BDI) | batched | Contact/Account/Opp with NPSP matching | Nonprofit gift/Contact imports with Household logic |

- **Upsert needs an External ID field** (or the record Id). Upsert-by-external-ID is the
  pattern for idempotent re-linking — late-arriving related records can re-attach to an
  existing parent by its External ID without new write logic.
- **Field/data storage are separate quotas.** Files count against *file* storage; records
  against *data* storage (each record ~2 KB regardless of field count). Keeping large file
  contents in external storage and storing only a reference key in Salesforce keeps you off SF
  file storage.
- **Reporting tools to reach for:** custom report types (when standard types don't expose the
  object shape / a Lookup's child), cross-filters (WITH/WITHOUT related records), bucket
  fields, summary formulas. **Reporting snapshots** persist report rows to a custom object on a
  schedule for trend tracking. **Historical trending** tracks up to 8 fields over up to 3
  months. **Dashboard filters** max 3 per dashboard.

**Anti-patterns / red flags:**
- Trying to import Opportunities via Data Import Wizard — unsupported; use Data Loader/BDI.
- A "duplicate rule" that has no matching rule, or vice versa — neither works alone.
- Bulk-loading into NPSP without honoring its Contact/Household matching — creates duplicate
  Households.

**Verify against the live org:**
- `run_report` to pull an existing report's output before changing its definition.
- `find_applications` / `find_contacts` to confirm a record exists / matched before an upsert.
- `soql_query COUNT()` to sanity-check row counts pre/post import.

---

## Cloud Applications — Operational Knowledge

Sales/Service Cloud features are largely out of scope for a fundraising/NPSP org, but know
the shape:
- **Sales Cloud:** Products → Price Books → Price Book Entries; revenue/quantity schedules;
  Opportunity splits; Collaborative Forecasting; quote-to-opportunity sync; lead conversion
  field mapping.
- **Service Cloud:** Knowledge (article types, data categories, Lightning Knowledge),
  Entitlements/Milestones, case assignment/escalation rules, Omni-Channel routing, Service
  Console.
- **Experience Cloud:** the relevant one for any externally-facing portal (volunteer / donor /
  applicant). Site types (Customer, Partner, LWR), Experience Builder, member profiles,
  Audience Targeting. (Note: a portal does not *have* to be Experience-Cloud-gated — a
  tokenized link on external infrastructure is a valid alternative when login friction is the
  concern.)

---

## Auditing and Monitoring — Operational Knowledge

**Know which log answers which question, and its retention:**

| Question | Tool | Retention |
|---|---|---|
| Who changed a setup/metadata setting? | Setup Audit Trail (downloadable CSV) | 6 months (180 days) |
| Who logged in / from where / failed logins? | Login History | 6 months |
| What changed on this record's fields? | Field History Tracking (≤20 fields/object) | 18 months in UI; archive to FieldHistoryArchive Big Object beyond |
| What did this Apex/flow transaction do? | Debug Logs (trace flag) | ~24h or until 1,000 entries / size cap |
| API calls, report exports, URI, anomalies? | Event Monitoring ELF (add-on) | 1 day or 30 days by license |

- **Debug log levels** (least→most verbose): ERROR, WARN, INFO, DEBUG, FINE, FINER, FINEST.
  Set a trace flag on the *running user* to capture a transaction — this is the tool that
  catches hidden managed-package automation.
- **Record-modification fields:** `CreatedById` (insert only), `LastModifiedById` (user edits),
  `SystemModstamp` (any change incl. system/automation). Use `SystemModstamp` to find
  automation-touched records, `LastModifiedById` for human edits.
- **Health Check** scores the org against a security baseline — remediate from there.
- **Transaction Security Policies** can block/notify on events (bulk export, login anomalies).

**Anti-patterns / red flags:**
- Relying on debug logs for forensics days later — they roll off in ~24h. Turn on Field
  History or Event Monitoring *before* you need the history.
- Enabling Field History on a 21st field — silently capped at 20/object.

**Verify against the live org:**
- `describe_object` to confirm which fields have history tracking enabled before promising
  an audit trail exists.
- `soql_query SELECT … FROM Obj__History WHERE …` to read tracked changes directly.

---

## Environment Management and Deployment — Operational Knowledge

**Sandbox selection by data need and refresh cadence:**

| Sandbox | Data | Refresh interval | Use for |
|---|---|---|---|
| Developer | Metadata only | 1 day | Dev/unit work |
| Developer Pro | Metadata only, larger storage | 1 day | Bigger dev datasets |
| Partial Copy | Metadata + sample data (template) | 5 days | Integration/UAT with representative data |
| Full | Metadata + ALL data | 29 days | Staging, perf, final pre-prod validation |

**Deployment-tool decision:**
- **SFDX / SF CLI (source-driven)** — metadata lives in a version-controlled project and
  deploys with `sf project deploy start`. Version-controlled, can delete (destructive changes),
  scriptable. **Run all `sf project …` commands from the SFDX project root**, or you get
  *InvalidProjectWorkspaceError*.
- **Change Sets** — UI-only, point-to-point, **cannot delete**, not version-controlled, must
  manually add component dependencies. Use only when SFDX isn't available.
- **Code coverage gate:** Apex deploys to production require **≥75% org-wide** coverage and
  **>0% (at least 1%) per trigger**. A deploy with insufficient coverage is rejected.

**Anti-patterns / red flags:**
- A field/permset deploy that references components not yet in the target org → missing-
  reference failure. Deploy dependencies first (object before field before permset before
  layout).
- Assuming SFDX `field-meta.xml` carried FLS — **it does not** (see Security section). The
  permset granting FLS must deploy alongside.
- **Connected App creation can be gated** in modern org configs — deploying a
  `connectedApp-meta.xml` may return *"You can't create a connected app… contact Salesforce
  Customer Support."* The workaround is an **External Client App** (ECA).
- **External Client App Consumer Key is UI-only** — Tooling API, REST, Metadata retrieve,
  Connect API none expose it. It's behind email verification in the SF UI. No scriptable path.

**Verify before/after a deploy:**
- Run a JWT-bearer smoke test (auth → describe → upsert idempotency → cleanup) to catch every
  gotcha above at the layer it bites.
- `describe_object` post-deploy to confirm the new field is API-visible (proves FLS landed,
  not just the field).
- `soql_query` a known record to confirm the field is selectable, not `INVALID_FIELD`.

---

## Operational Rules Quick Reference

Read this first. Each is imperative and concrete.

- **DO** treat sharing as additive-only — to restrict access, lower the OWD; never expect a
  sharing rule to take access away.
- **DO** add `<fieldPermissions>` in a permset/profile for every new SFDX custom field — the
  field-meta.xml grants FLS to no one.
- **DON'T** put `<fieldPermissions>` on a `<required>true</required>` field — deploy fails;
  omit required fields.
- **DON'T** trust a page layout for security — FLS is the only field gate; the API/SOQL ignore
  layouts.
- **DO** verify permset/ECA assignments via `PermissionSetAssignment` SOQL, never a UI success
  toast.
- **DO** make Lookup `relationshipName`s unique per parent object (role-specific suffixes).
- **DON'T** expect roll-up summary fields on Lookups — only Master-Detail; use DLRS/flow/Apex.
- **DO** bulkify — one query into a collection, one DML after the loop. No Get/Update/Create
  inside a flow loop, no SOQL/DML inside an Apex loop.
- **REMEMBER** the limits: 100 SOQL, 50k rows, 150 DML, 10k DML rows, 10s CPU sync.
- **DO** use a before-save record-triggered flow for same-record field updates (cheapest, no
  extra DML); use after-save only for related-record DML / email / Apex.
- **DON'T** rely on validation rules to gate approval submission — approvals don't run them;
  put the check in entry criteria.
- **DO** add a recursion guard (before-save, `ISCHANGED`, or static flag) on any automation
  that updates its own object.
- **DO** enumerate ALL automation (incl. managed-package workflow rules) before blaming your
  own code — use a debug log trace flag.
- **DON'T** import Opportunities via Data Import Wizard — Data Loader or NPSP BDI only.
- **DO** upsert by External ID for idempotent re-linking; both a Matching Rule and a
  Duplicate Rule are required for de-dup.
- **DO** build new automation in Flow — Workflow Rules and Process Builder are retired.
- **DO** keep large file contents in external storage, only a reference key in SF — file vs.
  data storage are separate quotas.
- **DO** run `sf project …` from the SFDX project root, not the repo root.
- **REMEMBER** Apex deploy gate: ≥75% org coverage, >0% per trigger.
- **DO** cache-bust a Quick Action by editing non-field metadata (`<description>`) when added
  fields don't render on Lightning tabs.
- **DON'T** rely on debug logs for forensics — they roll off in ~24h; enable Field History /
  Event Monitoring beforehand.
- **DO** run a JWT-bearer smoke test after any metadata/cert change and confirm with
  `describe_object` + `soql_query` that new fields are API-visible.

---

## Approval Processes — Operational Knowledge (gap fill)

Approval processes are a distinct exam domain with their own quirks:

- **Validation rules do not fire on approval submission.** Use entry criteria on the process, or a before-save flow that runs before the record is locked.
- **Record lock on submission.** Once submitted, the record is read-only to non-approvers. Flows/triggers that try to write it will fail with a lock error. If automation must run, add a Recall step, let automation complete, then resubmit — or use an Apex action with `Database.rollback`-aware logic.
- **Delegated approvers** inherit the original approver's queue but can't re-delegate. The delegatee must also have the appropriate object/FLS access to see the record.
- **Approval step order matters:** step 1 runs before step 2 regardless of "who approves." Each step can require unanimous or first-response from a group. Know the difference.
- **Recall vs. rejection:** Recall returns the record to the submitter (draft state); rejection can trigger a final-rejection action and unlock the record or send a notification — configure final-rejection actions explicitly.

**Numbers to know:** Max 30 approval steps per process. An object can have multiple approval processes; only one can be active at a time for automated submission, but multiple can be submitted manually.

---

## Territory Management — Operational Knowledge (gap fill)

Enterprise Territory Management (ETM) is blueprint-tested and often skipped in prep:

- **Territory model states:** Planning → Active → Archived. You can only assign records and run territory rules in **Active** state. You cannot delete an Active model — archive it first.
- **Assignment rules** (account-field criteria) run when accounts are saved or when you manually run rules against the model. Territory assignment does **not** automatically cascade to related Opportunities; Opportunity territory assignment is a separate step.
- **User access via territory:** members of a territory get at minimum Read on the accounts in that territory. OWD for Account can be Private while ETM grants the read — the two coexist.
- **Collaborative Forecasting integrates with ETM** — forecasts roll up through the territory hierarchy, not the role hierarchy, when ETM is the forecast source. Don't confuse the two hierarchies.

---

## Decision Scenarios

Operational judgment checks — each covers a high-value gotcha from the sections above. Original scenarios; not derived from exam questions.

---

**Scenario 1 — The invisible field after deployment**

> **Situation:** A developer deploys a new `Restricted_Notes__c` field on Contact via SFDX `sf project deploy start`. A sales rep immediately reports the field is missing from their SOQL query results; no error, just absent. A System Administrator can also not SELECT it in a workbench query.
>
> **Competent move:** Recognize that `field-meta.xml` deploys the field schema but grants FLS to nobody — including System Administrator. Deploy a permission set that includes a `<fieldPermissions>` entry for the field (readable + editable as appropriate), then assign it or include it in a permission set group. Verify with `describe_object` — the field should now appear in the field list for the running user.
>
> **Tempting-but-wrong:** Checking the page layout or assuming System Administrator bypasses FLS. System Admin *does* bypass most object/record security but **does not** bypass FLS for fields not in a profile/permset (this is a common misconception — FLS applies to all profiles including System Administrator unless explicitly granted).
>
> **Verify:** `soql_query SELECT Id, Restricted_Notes__c FROM Contact LIMIT 1` — transitions from `INVALID_FIELD` to a valid result once FLS is in place. Also run `describe_object` and confirm the field appears with `updateable: true`.

---

**Scenario 2 — Approval process and automation collision**

> **Situation:** An after-save flow is configured to stamp an `Approved_Date__c` field on an Opportunity the moment `StageName` changes to "Closed Won." In UAT, submitters report the flow errors with "ENTITY_IS_LOCKED" after they approve a deal. The same flow works fine on records that were never submitted for approval.
>
> **Competent move:** Approval submission locks the record. After-save flows fire when the approver clicks Approve, but the record is still locked at that point. Move the field-stamp logic into a **before-save** record-triggered flow triggered when `StageName` becomes "Closed Won" — before-save flows run before the lock check, and they use no DML (they modify the in-flight record). Alternatively, use a final-approval action (Workflow Field Update or Flow) that runs in the approval process's own unlock context.
>
> **Tempting-but-wrong:** Adding a Recall step before the flow runs — this adds operational friction and doesn't fix the root cause. Also wrong: using an Apex trigger without `Database.setSavepoint` awareness — same lock error.
>
> **Verify:** After moving to before-save, submit a test Opportunity for approval and approve it — confirm `Approved_Date__c` is set and no ENTITY_IS_LOCKED error in the debug log.

---

**Scenario 3 — Sharing model tightening without lowering OWD**

> **Situation:** A manager reports that when her direct reports create Accounts, she can see all of them — but she is not supposed to see Accounts owned by peers in a different region. The Account OWD is Public Read/Write. The security team asks you to restrict cross-region visibility without touching the role hierarchy.
>
> **Competent move:** You cannot *narrow* access with a sharing rule — sharing is additive-only. The only way to restrict record visibility is to **lower the OWD** (to Private or Public Read Only). Once OWD is Private, re-open only the access you need (e.g., an owner-based sharing rule that shares records within each region's role). Explain this constraint before committing to a timeline — lowering OWD on a large object triggers a sharing recalculation job that can take hours.
>
> **Tempting-but-wrong:** Creating a sharing rule that "blocks" peers. No such construct exists. Criteria-based or owner-based sharing rules can only grant access to more users, never remove it from users who already have it via OWD or hierarchy.
>
> **Verify:** After changing OWD to Private, log in as a rep in Region A and confirm they cannot see Region B accounts. Use `soql_query` with `WITH USER_MODE` (Apex) or check via the Sharing button on a record to see the sharing reason.

---

**Scenario 4 — DLRS vs. roll-up summary on a Lookup**

> **Situation:** A consultant needs a `Total_Donations__c` currency field on Account that sums all related Opportunity amounts where `StageName = 'Closed Won'`. The Account → Opportunity relationship is a standard Lookup (not Master-Detail). The consultant tries to create a Roll-Up Summary field on Account and can't find the option.
>
> **Competent move:** Roll-up summary fields are only available on the **master** side of a Master-Detail relationship. Account → Opportunity is a Lookup; you cannot create a native SOQL roll-up here. The correct tools are: (a) **DLRS** (Declarative Lookup Rollup Summaries) managed package — configure a rollup record pointing at the Lookup field; (b) a **record-triggered after-save flow** on Opportunity that aggregates and writes back to Account; or (c) Apex. DLRS is the least-code path for a standard admin.
>
> **Tempting-but-wrong:** Converting the Opportunity Lookup to a Master-Detail to enable roll-up summaries. This is destructive — it requires every Opportunity to have a non-null Account (breaking standalone opps), deletes Opp records if the parent Account is deleted, and changes sharing behavior. Never convert unless the business model truly mandates parent-required lifecycle coupling.
>
> **Verify:** After installing DLRS and configuring the rollup, trigger a recalculate job and `soql_query SELECT Total_Donations__c FROM Account WHERE Id = '<test-id>'` to confirm the value matches the sum of Closed Won Opportunities.

---

**Scenario 5 — Flow recursion from a field update**

> **Situation:** A record-triggered after-save flow on Contact fires when `Email` changes. It also writes back a `Last_Email_Updated__c` timestamp on the same Contact. In production the flow works — but occasionally a Contact's flow fires twice (seen in debug logs), and some contacts end up in an infinite-loop error.
>
> **Competent move:** Writing back to the triggering record from an after-save flow re-triggers the same flow (order-of-execution step 10 re-fires after-save triggers/flows). Add a **before-save** flow instead: set `Last_Email_Updated__c` on the in-flight record (no DML, no re-trigger). If after-save is required, add a `ISCHANGED(Email)` entry condition *and* a static recursion guard (a custom metadata flag or a flow variable reset after first execution — a text-type `$GlobalVariable` doesn't work for this; use a before-save flow or Apex static variable).
>
> **Tempting-but-wrong:** Using a `{!$GlobalVariable}` to guard recursion — Flow's global variables are re-initialized each transaction interview; they don't persist across a re-fire within the same transaction. An Apex-based static boolean is the correct cross-trigger guard, or simply move to before-save.
>
> **Verify:** Reproduce by updating `Email` on a Contact in a debug log session. A non-recursive fix shows exactly one flow interview for the email change. Confirm `Last_Email_Updated__c` is set after a single pass.

---

## Study resources & relevance

Study resources (official Salesforce + community) and the NPSP/nonprofit relevance notes are kept in [references/study-resources.md](references/study-resources.md) so this skill stays focused on operational rules. Load that file when planning a study path or mapping these rules to a nonprofit org.

---

*Independent educational content to upskill AI agents. Not affiliated with or endorsed by Salesforce; all trademarks belong to their owners. Guidance only — verify against official documentation and live orgs before acting.*
