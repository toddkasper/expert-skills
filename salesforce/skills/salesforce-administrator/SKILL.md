---
name: salesforce-administrator
description: Day-to-day Salesforce org configuration — profiles, permission sets, OWD, sharing rules, FLS, the object/field data model, Flow automation, data import (Data Import Wizard, Data Loader), validation rules, duplicate management, reports, dashboards, and Agentforce admin setup. Use when configuring or reviewing declarative org settings, security/sharing, automation, or analytics. Not Apex/triggers/SOQL (see salesforce-platform-developer-1), advanced sharing architecture, deployment pipelines or auditing (see salesforce-advanced-administrator), or building AI agents (see salesforce-agentforce-specialist). Scoped and benchmarked by the Platform Administrator (Plat-Admn-201) blueprint.
metadata:
  anchor-credential: Salesforce Certified Platform Administrator
  exam-code: Plat-Admn-201
  domain: salesforce
  type: certification-playbook
  blueprint: December 2025 refresh
  status: current
  last-reviewed: 2026-06-10
  blueprint-verified: 2026-06-07
---

# Salesforce Administrator — Skills Reference

## Overview

The Salesforce Certified Platform Administrator credential (exam code Plat-Admn-201) covers everything an admin touches day-to-day: security and sharing models, object and field customization, Flow automation, data quality, reports and dashboards, and — as of the December 2025 refresh — foundational Agentforce AI capabilities.

**This is an operational playbook, not an exam outline.** A recurring principle: **query the org — never assume from metadata XML.** XML in a repo is not always deployed, and metadata does not carry runtime state (FLS, cache, active flows).

> **Load this skill when…** configuring org security (profiles, permission sets, OWD, FLS, sharing rules); building or debugging Flow automation; importing or cleaning data; setting up reports/dashboards; doing initial Agentforce agent setup.
> **Not this skill:** Apex/triggers/SOQL → see `salesforce-platform-developer-1`; advanced sharing architecture, deployment pipelines, or audit monitoring → see `salesforce-advanced-administrator`; building or governing Agentforce agents → see `salesforce-agentforce-specialist`.

> Study resources: [references/study-resources.md](references/study-resources.md). Nonprofit/NPSP applications: [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md). Org-specific rules: keep a per-org appendix in your project CLAUDE.md.

> **Verify steps assume nothing about your tooling** — use your project's Salesforce MCP connection, the Salesforce CLI (`sf`), or the Salesforce setup UI, in that order of preference. The SOQL and describe calls below are written to work through any of them.

---

Credential logistics and study path: see [references/study-resources.md](references/study-resources.md).

---

## Uncertainty & Escalation

- **Always re-verify live:** governor limit numbers `[volatile — verify live]`; API/platform version and feature availability `[volatile — verify live]`; org-specific settings (OWD, active flows, installed packages, sandbox types); any cap or quota cited in this skill.
- **Live wins:** if any rule or number in this skill conflicts with what the live org shows, the live org is authoritative. Log the discrepancy immediately using the Feedback protocol below, then act on what you observed.
- **Escalate to a human before proceeding:** OWD changes in production; deactivating managed-package automation in production; mass-update or hard-delete operations on production data; any sharing change that could expose PII or financial records; enabling or disabling multi-currency (irreversible).
- **Confidence taxonomy:** facts in this skill are stable unless tagged `[volatile — verify live]` or `[opinion — house style]`. When in doubt, describe the object or run a SOQL query rather than trusting a tag.

---

## 1. Security & Access Model — the rule that governs everything

Access is computed by **layering** — reason about the whole stack, not one layer.

**The layering rule (memorize the order):**
1. **OWD (Org-Wide Defaults)** set the floor — the most restrictive baseline per object (Private / Public Read Only / Public Read/Write / Controlled by Parent).
2. **Role hierarchy** grants *upward* visibility — a manager sees records owned by subordinates, never sideways.
3. **Sharing rules** (owner-based or criteria-based) open access *up* from the OWD floor to groups/roles. Sharing rules can only grant, never restrict.
4. **Manual sharing / Apex sharing** for one-off record grants.
5. **Profiles** set object CRUD + the FLS baseline + app/tab/record-type/layout assignments + login hours/IP.
6. **Permission sets & permission set groups** are **purely additive** — they grant, never revoke. The only way to "take away" inside a group is a **muting permission set**.

**Object CRUD ≠ FLS ≠ record sharing — all three must pass:**
- **Object CRUD:** can the user Read/Create/Edit/Delete the object at all?
- **FLS:** even with full object Read, a field hidden by FLS returns *"Invalid field"* in SOQL and is absent from the UI. FLS is independent of OWD.
- **Record sharing:** OWD + role + sharing rules decide *which rows* are visible.

**CRITICAL — SFDX field-meta.xml does NOT carry FLS.** A deployed custom field is invisible to everyone — including System Administrator — until a profile or permset lists `<fieldPermissions>`. Always deploy `<fieldPermissions>` alongside every new non-required field.

**Required-field exception:** Required fields are always readable/editable — **omit them from `<fieldPermissions>`**. Including one fails deploy: *"You cannot deploy to a required field."*

**ECA assignment gotcha:** ECA usage is authorized on the **ECA itself** (ECA detail → Policies → Edit → App Policies → Select Permission Sets), not on the classic Permission Set "Assigned Connected Apps" page. Browser-AI tools edit the wrong place and report success — verify via `PermissionSetAssignment` query.

| Need | Use | Why |
|---|---|---|
| Same access for everyone in a job function | Profile baseline | One assignment, sets login/IP/layout too |
| Extra access for a subset | Permission set | Additive, no profile sprawl |
| Bundle several permsets for a role | Permission set group | Single assignment, manage as unit |
| Remove one permission from a group | Muting permission set | Only mechanism that subtracts |
| Open records above the OWD floor | Sharing rule | Grants without lowering the baseline |
| One record, one person | Manual share | Surgical, owner-or-above only |

**Red flags:** a new SFDX field deployed with no accompanying `<fieldPermissions>`; a permset XML listing a required field; "grant access" attempted by editing OWD to Public (nukes the floor for everyone); assuming a permission set can revoke; trusting a browser-tool "success" on ECA assignment.

**Verify against the live org:**
- Describe the object (MCP / `sf sobject describe --sobject <object>` / Object Manager → Fields & Relationships) — if a field you expect is missing from the output, suspect FLS.
- Confirm FLS landed: `SELECT PermissionsRead, PermissionsEdit, Field FROM FieldPermissions WHERE ParentId IN (SELECT Id FROM PermissionSet WHERE Name='<permset>')` (MCP / `sf data query` / Developer Console).
- Confirm permset assignment: `SELECT AssigneeId, PermissionSet.Name FROM PermissionSetAssignment WHERE PermissionSet.Name='<permset>'` (MCP / `sf data query` / Developer Console).

**Setup Audit Trail:** 180-day log of Setup changes. First stop when behavior changes unexpectedly — including silent managed-package changes (see §4).

---

## 2. Configuration & Setup — org, users, company

**Users are deactivated, never deleted.** Deactivating frees the license; freezing (Setup → Users → Freeze) blocks login immediately without freeing the license — use freeze for urgent lockout, deactivate later (blocked if the user owns open approvals).

**Company settings:** fiscal year, business hours (drive escalation timing), locale/language/currency. Multi-currency, once enabled, **cannot be disabled.**

**Login & session security:** login hours + IP ranges → profile only. Trusted IP ranges (skip-verification) → Network Access. MFA is mandatory for direct logins.

**Sandbox creation can be gated** — some orgs require a Public Group with the admin as a member before creation (check this first if sandbox creation fails).

**Decision — where does a permission live?**

| Setting | Profile | Permission set | Notes |
|---|---|---|---|
| Object CRUD | ✅ baseline | ✅ additive | Permset can't remove profile grant |
| FLS | ✅ baseline | ✅ additive | Both can grant; required fields excluded |
| App / tab visibility | ✅ | ✅ | |
| Record type assignment | ✅ | ✅ | |
| Login hours / IP ranges | ✅ only | ❌ | Profile-exclusive |
| Page layout assignment | ✅ only | ❌ | Profile × record type intersection |

**Red flags:** trying to delete a user; putting login-hour restrictions in a permission set (impossible); enabling multi-currency "to test"; editing the System Administrator profile expecting to clone it down to a standard profile (you can't).

---

## 3. Object Manager & Lightning — the data model

**Relationships — pick deliberately:**

| | Lookup | Master-Detail |
|---|---|---|
| Coupling | Loose | Tight |
| Child required? | Optional | Always required |
| Parent delete | Set null / restrict / cascade (configurable) | Always cascade-deletes children |
| Sharing | Independent | Child inherits master's sharing |
| Roll-up summary on parent? | ❌ | ✅ |
| Max per object | 40 | 2 |
| Reparenting | Yes | Off by default |

**Roll-up summary fields** exist **only on the master side of a master-detail** (COUNT/SUM/MIN/MAX). For a Lookup roll-up use a record-triggered Flow, Apex, or DLRS.

**Lookup `relationshipName` must be unique per parent** — two Lookups to the same parent with the same name fail deploy: *"Duplicate relationship name."* SOQL parent traversal keys on the **field name** (`Parent__r.Name`), not relationshipName, so renaming is safe.

**Formula fields never store data** — computed at read time; can't be set, indexed normally, or used as external IDs. Cross-object formulas: up to **10 hops**.

**Field sizing is a contract.** Form/integration string lengths and picklist constraints must be **derived from live Salesforce field metadata**, not hand-set literals, and regenerated whenever a field is resized or a picklist changes. A field resize is rarely a one-file change: SF metadata, generated schema/validation artifacts, and data-model docs move together — all or none. Truncation at the write boundary is a fallback, not a substitute.

**Record types** drive page-layout assignment (profile × record type → layout) and picklist subsets. **External IDs** are the upsert key for idempotency and late re-linking — unique, indexed, max **25 per object** (shared pool with unique custom fields).

**Quick Action / Lightning cache scar:** Adding fields to a Quick Action's layout via SFDX does **not** invalidate the runtime QA cache on Lightning contextual tabs (`console:relatedRecord`). New fields are silently absent even after logout/login. **Cache-bust:** edit any non-field-list metadata on the QA (`<description>`, `<label>`, or `<layoutSectionStyle>`) and redeploy — SF treats the structural change as meaningful and flushes the cache.

**Lightning App Builder (LAB)** — 15% of the December 2025 exam domain "Object Manager and Lightning App Builder":

- **Page types:** App pages (standalone), Home pages (per-app or org default), Record pages (per object).
- **Dynamic Forms:** put individual fields/sections on the record page as components with **visibility rules** (by field value, profile, permission, device) — replaces separate layouts. The layout "Upgrade" migration is all-or-nothing (sections migrate as units).
- **Activation & assignment:** org default → app default → **app + record type + profile**; the **most specific** assignment wins; Lightning Experience only (Classic ignores LAB assignments).

**Red flags:** choosing master-detail when the child must sometimes exist alone (use Lookup); expecting a roll-up over a Lookup; two same-parent Lookups with identical relationshipName; hand-editing generated schema/validation files; a form `max()` literal that doesn't trace to the field-length source of truth; adding QA fields and not seeing them on the tab (apply the cache-bust); setting a Dynamic Forms visibility rule on a field that has Required = true at the field level (the field still enforces its required constraint even when hidden).

**Verify:** Describe the object (MCP / `sf sobject describe --sobject <object>` / Object Manager) to read true field lengths and picklist values before trusting any schema file. List objects (MCP / `sf sobject list` / Object Manager) to confirm an object exists before referencing it.

---

## 4. Automation — Flow first, and the managed-package trap

**Workflow Rules and Process Builder reached end of support Dec 31, 2025 — build all new automation in Flow.** Existing automation continues to execute; still recognize them — managed packages and legacy configs still contain them and they still fire.

**Pick the flow type by trigger:**

| Requirement | Flow type |
|---|---|
| React to a record create/update, modify the *same* record cheaply | **Before-save** record-triggered (no DML, fastest) |
| React to a record save, create/update *related* records or send email | **After-save** record-triggered |
| Run on a schedule over a set of records (nightly cleanup, reminders) | **Scheduled** flow |
| User-facing wizard / form embedded in a page or Quick Action | **Screen** flow |
| Reusable logic called by other flows/Apex/REST | **Autolaunched** (invocable) |
| React to a Platform Event | **Platform-event-triggered** flow |

**Before-save vs after-save is the key automation choice:** before-save sets fields on the triggering record with **zero added DML** (fastest, no recursion); after-save runs post-commit and is required for related records, email, or Apex. Same-record field sets → before-save. Rolls-ups, child records, emails → after-save.

**Governor limits (all flows + Apex + triggers share one transaction):** 100 SOQL, 150 DML statements, 50k rows, 10k DML rows, 6 MB heap (sync), 10s CPU. Flows batch in **200s**.

**Bulkify.** Never put Get/Create/Update/Delete (or SOQL/DML) **inside a Loop** — collect once, work in memory, one DML after the loop.

**Fault paths — every faultable element needs one.** Any Flow element that can fault — DML (Create/Update/Delete Records), Send Email, Action calls, HTTP callouts — must have a **Fault path** connector. Without it, a fault in a bulk transaction causes the entire batch to fail **silently**, with no user-visible error and no log entry. Best practice: connect the Fault path to a Create Records element that logs the fault message to a custom `Flow_Error_Log__c` object (or similar), then fault-terminate gracefully. A Flow with zero fault handling is a silent data-integrity risk in production.

**Managed-package automation silently mutates your data.** A managed package ships Workflow Rules, flows, and triggers in its namespace that fire on your records. When a field changes with no code of yours responsible, **suspect managed-package automation first** — check Setup → Workflow Rules and Flows filtered by namespace, then enable an Apex debug log in a sandbox to catch the culprit. The fix is usually deactivating the offending rule. Canonical scar: NPSP copies `Phone → MobilePhone` from a defaulted preferred-phone picklist on insert (worked example: [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md)).

**Approval processes** — place actions correctly: Initial Submission, Approval, Rejection, Recall, Final Approval/Rejection. Approver sources: specific user, role, queue, related-user field, or manager field.

**Red flags:** any Get/Create/Update/Delete element inside a Loop; before-save flow doing DML on other objects (use after-save); building a *new* Workflow Rule or Process Builder; assuming "the field changed itself" without checking managed-package automation; an after-save flow that re-triggers itself (recursion — add entry criteria / `ISCHANGED` guards); a DML, email, or action element with no Fault path (silent bulk failure).

**Verify:** `SELECT Id, MasterLabel, TriggerType, Status FROM FlowDefinitionView WHERE Status='Active'` (MCP / `sf data query` / Developer Console) to see what's firing; describe the affected object (MCP / `sf sobject describe` / Object Manager) to inspect managed-package fields before debugging mystery data changes; Setup Audit Trail for recent automation changes.

---

## 5. Data & Analytics — import, quality, reporting

**Pick the import tool:**

| | Data Import Wizard | Data Loader |
|---|---|---|
| Max records | 50,000 | 5,000,000 `[volatile — verify live]` (sources conflict: limits cheat-sheet 5M vs data-import FAQ 150M) |
| Objects | Accounts, Contacts, Leads, Campaign Members, Person Accounts, custom objects | All objects incl. custom |
| Upsert by external ID | Limited | ✅ full |
| Hard delete | ❌ | ✅ |
| Built-in dup matching | ✅ | ❌ |
| Interface | Browser wizard | Desktop app / CLI (CLI for scheduled jobs) |

**On a managed-package org, prefer the package's own loader** — it understands required relationships and field mappings a generic loader gets wrong (e.g. NPSP Data Import for Household/Contact/gift loads; see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md)).

**Recycle Bin retention is 15 days by default**; orgs with Extended Retention enabled may retain up to **30 days**. Hard delete (Data Loader) skips the Recycle Bin entirely and is unrecoverable.

**Duplicate management:** Matching Rules (define similarity) + Duplicate Rules (Alert = warn; Block = prevent save) — you need both; neither works alone.

**Validation rules** fire on save; `TRUE` → blocks the save. Use `ISCHANGED()`, `ISNEW()`, `PRIORVALUE()`, `$Permission`, `$Profile` to scope. Place the error on a specific field, not top-of-page.

**Reports:** tabular (no grouping, can't drive dashboards), summary (row groups), matrix (row × column), joined. Cross-filters = "Contacts WITHOUT applications." Custom Report Types expose object relationships not in standard types.

**Dashboards:** run as a fixed running user **unless** dynamic (runs as viewer). Folder access + running user's record access both gate what data appears.

**Red flags:** Data Import Wizard for >50k rows or for an unsupported object; hard delete without a backup; a dashboard exposing data because its running user is an admin; expecting a report to show records the running user can't see.

**Verify:** `SELECT COUNT() FROM <object>` (MCP / `sf data query` / Developer Console) to sanity-check row counts before/after import; run the report (MCP / Reports tab / Analytics REST API) to confirm output; spot-query Contacts (MCP / `sf data query` / list view) to verify a backfill landed.

---

## 6. Sales, Service & Productivity — key rules

Rules and red flags for Sales Cloud, Service Cloud, and productivity features. Full detail for lead assignment, case queues, entitlements, Omni-Channel, AppExchange, and key caps: [references/sales-service-detail.md](references/sales-service-detail.md) — load that file when configuring any of those features.

**Quick operational callouts (load references for anything deeper):**
- Confirm the active **account model** (Business Accounts / Person Accounts / package Household) before any Contact-roll-up report — wrong model, wrong counts.
- **On-Demand Email-to-Case** over Standard — avoids requiring an open firewall port.
- Quick Actions are subject to the **QA cache trap in §3** — apply the cache-bust after any field-list change.
- Install AppExchange packages in **sandbox first**; never edit managed-package metadata directly.

**Red flags:** treating a repurposed Opportunity as a sales pipeline; editing managed-package metadata directly; adding Quick Action fields without cache-busting; expecting Standard Email-to-Case to work without an open firewall port.

---

## 7. Agentforce AI (8%) — awareness + permissions

**Permission reasoning is identical to §1** — the same OWD + FLS + permission sets stack.

> **Naming note:** As of October 2025, Salesforce markets the agent platform under the **"Agentforce 360"** product umbrella. The Setup studio is now labeled **"Agentforce Builder"** (formerly Agent Builder); the exam guide may still use older terminology.

- **Agentforce** = configurable, autonomous conversational agents. Distinct from **Einstein** (predictive/generative features on standard objects: Opportunity/Lead Scoring, Next Best Action).
- **Agent Builder:** configure identity/persona, **instructions** (guardrails evaluated before every response), **topics** (scope — if a request doesn't match an active topic, the agent declines), and **actions** (Flow, Apex, API, standard email) within topics. Actions not linked to a topic are unreachable.
- **Prompt Builder:** template types — Flex, Sales Email, Record Summary, Field Generation. Running user's FLS controls which fields merge.
- **Security:** an agent **runs in a configured user context — OWD + FLS + permission sets apply.** "Agent can't see a record" → diagnose as a normal access problem: object CRUD, FLS, sharing. Use conversation transcripts + debug logs.
- **Einstein (not Agentforce):** Opportunity Scoring, Lead Scoring, Next Best Action, Einstein Activity Capture — predictive/generative features on standard objects; configured separately from Agent Builder; no topics/actions model.

**Conversation-preview testing:** use Agent Builder's built-in **conversation preview** panel to exercise topics, actions, and instruction guardrails interactively before activation — it runs as the configured agent user so sharing/FLS gaps surface in preview rather than in a live deployment.

**Red flag:** assuming an agent bypasses sharing/FLS (it does not); an action that exists but is not linked to a topic (agent can't reach it); pointing an agent at PII without checking the running user's data scope; confusing Einstein feature configuration with Agentforce Agent Builder.

---

## Executable Workflows

### 1. Add a custom field end-to-end (create → FLS → layout → deploy → cache-bust → verify)

1. In Object Manager (or SFDX `field-meta.xml`), create the field with the correct type/length.
   → **gate:** describe the object (`sf sobject describe --sobject <object>` / Object Manager) — confirm the field appears in the schema output before proceeding.
2. Add `<fieldPermissions>` (readable + editable) to the target permission set XML. Omit if the field is `<required>true</required>`.
   → **gate:** open the permset XML and confirm the entry is present; confirm the field is *not* marked required (required fields fail deploy).
3. Add the field to the relevant page layout and Quick Action layout. If updating a QA field list, also edit `<description>` or `<label>` on the QA to trigger a cache-bust (see §3).
   → **gate:** open the layout XML and confirm the field reference appears.
4. Deploy via `sf project deploy start` from the SFDX project root.
   → **gate:** deploy log must show `Deploy Succeeded`; no partial-success warnings.
5. QA cache-bust check: if the field was added to a Quick Action, confirm the field now renders on the Lightning contextual tab after a hard reload. If absent, re-deploy with the QA `<description>` changed.
6. Verify FLS landed: `SELECT Field, PermissionsRead FROM FieldPermissions WHERE ParentId IN (SELECT Id FROM PermissionSet WHERE Name='<permset>')` (MCP / `sf data query` / Developer Console).
   → **gate:** field row present with `PermissionsRead = true`.
7. Smoke-test with a SOQL SELECT: `SELECT <Field__c> FROM <Object__c> LIMIT 1` as a non-admin user with the permset assigned.
   → **gate:** no `"Invalid field"` error; value returns (even if null).

---

### 2. Diagnose a record-access failure (object CRUD → FLS → sharing, in that order)

1. Identify the running user and the record in question.
   → **gate:** confirm user Id and record Id are known.
2. Check object CRUD: does the user's profile/permset grant Read on the object?
   → **gate:** describe the object for the user's session — if the object doesn't appear, CRUD is the blocker; grant object Read on the permset.
3. Check FLS: does the user's profile/permset grant Read on the specific field(s) returning errors?
   → **gate:** `SELECT Field, PermissionsRead FROM FieldPermissions WHERE ParentId IN (SELECT Id FROM PermissionSet WHERE Name='<permset>') AND SobjectType='<object>'` — missing rows mean no FLS. Add `<fieldPermissions>` and redeploy.
4. Check record sharing: can the user see this specific row?
   → **gate:** `SELECT Id FROM <Object__c> WHERE Id = '<recordId>'` as the user — zero rows means a sharing gap. Check OWD, role hierarchy, and sharing rules; grant access at the appropriate layer.
5. Confirm fix end-to-end: repeat the user's original action (report, UI field, SOQL query) and confirm no error.
   → **gate:** field returns a value; no CRUD/FLS/sharing error messages.

---

### 3. Safely deactivate managed-package automation in a sandbox first

1. Reproduce the mystery field change in a sandbox: trigger the DML that causes it, then check Setup Audit Trail and active Workflow Rules/Flows filtered by the package namespace.
   → **gate:** confirm the package automation is identified (namespace + rule/flow name visible in Setup).
2. In the sandbox, deactivate the automation (Workflow Rule: Deactivate button; Flow: Deactivate version).
   → **gate:** re-run the DML and confirm the field change no longer occurs; run affected test classes to confirm no regressions.
3. Check downstream dependencies: reports, other flows, or integrations that relied on the automated value.
   → **gate:** list of dependent components reviewed; no critical downstream failures in sandbox.
4. Create a change set or SFDX metadata snapshot of the deactivation (for documentation); then deactivate in production.
   → **gate:** Setup Audit Trail in production shows the deactivation event; re-run the DML and confirm behavior matches sandbox.

---

## Decision Scenarios

Five original scenarios covering the highest-value operational gotchas. Scenarios 1 and 2 are in this body; Scenarios 3–5 are in [references/scenarios.md](references/scenarios.md) — load when diagnosing sharing-model changes, managed-package mystery writes, or Agentforce access failures.

---

**Scenario 1 — The invisible field after SFDX deploy**

> **Situation:** A developer deploys a new custom text field `Preferred_Language__c` on Contact via SFDX pipeline. The CI job reports success. A support agent logs in and the field is absent from the page layout and returns `"Invalid field"` when queried via SOQL. The developer confirms the field exists in Object Manager. What is happening and what is the fix?

> **Competent move:** No `<fieldPermissions>` was deployed alongside the field. SFDX `field-meta.xml` does not carry FLS — every non-required field starts invisible to everyone including System Administrators until a profile or permset explicitly grants Read. Fix: add `<fieldPermissions>` (readable + editable) to the permset XML and redeploy.

> **Tempting-but-wrong:** Re-run the deploy or add the field to the page layout. Both leave the root cause untouched — the field exists but is FLS-invisible; a page layout with a missing-FLS field still renders without it.

> **Verify:** Describe the Contact object (MCP / `sf sobject describe --sobject Contact` / Object Manager) — if `Preferred_Language__c` is absent from the field list for the current user context, FLS is the culprit. After deploying the fix, confirm: `SELECT Field, PermissionsRead FROM FieldPermissions WHERE ParentId IN (SELECT Id FROM PermissionSet WHERE Name='<permset>')` (MCP / `sf data query` / Developer Console).

---

**Scenario 2 — Choosing between before-save and after-save Flow**

> **Situation:** A new business rule: when an Opportunity's Stage changes to "Closed Won," automatically set a custom `Close_Fiscal_Quarter__c` formula-derived text field to a calculated value AND create a follow-up Task assigned to the Opportunity owner. How many flows, and of which types?

> **Competent move:** Two concerns, two trigger contexts. Setting `Close_Fiscal_Quarter__c` on the *same* Opportunity → **before-save** record-triggered flow (zero added DML, runs before commit). Creating a Task on a *different* record → **after-save** record-triggered flow (post-commit DML). A before-save flow cannot perform DML on other objects — attempting it errors.

> **Tempting-but-wrong:** One after-save flow that does both. Technically it works, but setting a field from after-save triggers an extra DML update on the Opportunity (a second save), consuming a DML statement and potentially re-triggering other automation. Before-save is always preferable for same-record field sets.

> **Verify:** In Flow Builder, confirm the first flow is Record-Triggered with "Before the record is saved" and contains no DML elements; the second uses "After the record is saved." Bulk-test with 250+ Opportunities to confirm governor limits are not breached.

---

## Operational Rules Quick Reference

Read this first. Each rule is concrete and imperative.

- **DO** assume a freshly SFDX-deployed field is invisible until a profile/permset grants FLS — deploy `<fieldPermissions>` alongside every new non-required field.
- **DON'T** put a required field in `<fieldPermissions>` — the permset deploy fails. Omit all required fields.
- **DO** treat object CRUD, FLS, and record sharing as three separate gates that must all pass.
- **DON'T** expect a permission set to revoke anything — permsets are additive; use a muting permset to subtract inside a group.
- **DO** assign External Client App access on the ECA → Policies → App Policies → Select Permission Sets, and verify via `PermissionSetAssignment` query.
- **DON'T** ever build a new Workflow Rule or Process Builder — both reached end of support Dec 31, 2025; existing automation still executes, but build all new automation in Flow.
- **DO** prefer a before-save record-triggered flow for same-record field changes (zero added DML); use after-save only for related records/email.
- **DON'T** place any Get/Create/Update/Delete element (or SOQL/DML) inside a Loop — bulkify: collect, then one DML after the loop.
- **DO** add a Fault path to every DML, Send Email, Action, and callout element in a Flow — without one, faults fail silently in bulk transactions. Log the fault message (e.g. to a custom error-log object).
- **DO** stay under per-transaction limits: 100 SOQL, 150 DML, 50k rows retrieved, 10k DML rows; flows batch in 200s.
- **DO** suspect managed-package automation (e.g. NPSP namespaces) when a field changes value with no code of yours responsible.
- **DON'T** edit managed-package (NPSP) metadata directly; extend alongside it.
- **DO** put roll-up summaries only on the master side of a master-detail; for a Lookup rollup use Flow/Apex/DLRS.
- **DON'T** give two Lookups to the same parent the same `relationshipName` — use role-specific suffixes.
- **DO** derive form/integration string `max()` and picklist constraints from live field metadata; regenerate after any field resize/picklist edit; never hand-edit generated schema files.
- **DO** cache-bust a Quick Action after adding fields: edit `<description>`/`<label>` and redeploy, or the new fields won't render on the contextual tab.
- **DON'T** use Data Import Wizard for >50k rows or unsupported objects — use Data Loader (5M cap); on a managed-package org prefer the package's own loader (e.g. NPSP Data Import).
- **DO** remember Recycle Bin default retention is 15 days (up to 30 days with Extended Retention); hard delete skips the Recycle Bin entirely and is unrecoverable — back up first.
- **DON'T** delete a user — deactivate (frees license) or freeze (instant lockout, keeps license).
- **DO** check Setup Audit Trail (180-day) first when org behavior changes unexpectedly.
- **DO** verify against the live org (describe objects, run SOQL, list objects, query contacts) before trusting repo XML or a schema file.
- **DON'T** assume an agent (Agentforce) or dashboard bypasses sharing/FLS — both honor the running user's access.
- **DON'T** rely on web-to-lead above 500/day or web-to-case above 5,000/day without overflow handling.
- **DON'T** install an AppExchange package in production first — sandbox first, check security-review badge.

---

## References

- [references/study-resources.md](references/study-resources.md) — credential logistics, exam weights, study path, official links.
- [references/scenarios.md](references/scenarios.md) — Scenarios 3–5 (sharing model tightening, managed-package mystery field change, Agentforce access failure).
- [references/sales-service-detail.md](references/sales-service-detail.md) — deep detail for Sales Cloud (lead assignment, account models, campaigns), Service Cloud (entitlements, milestones, Omni-Channel, Knowledge), and AppExchange.

---

## Feedback protocol

Using this skill and hit a wall? If you find a claim contradicted by the live system or official docs, a missing rule that cost you a wrong attempt, or a decision this skill gave no criteria for — append an entry **in the moment** to `.skill-feedback/salesforce-administrator.md` at the project root (create it if absent):

`date | skill last-reviewed | claim or gap | what you observed instead | evidence (error text / doc URL / query output) | suggested fix`

These are harvested back into the skill via the learning loop. When the live system and this file disagree, trust the live system.

## Changelog

- **2026-06-09** — Conformed to the 12-dimension skill standard: task-vocab description + Scope block, Uncertainty & Escalation guidance with inline `[volatile — verify live]` marks, executable workflows, tool-agnostic verify steps, and the feedback protocol above. Exam logistics relocated to references/study-resources.md; `last-reviewed` set to 2026-06-09.
- **2026-06-10** — Curation (inbox audit, 2026-06-10):
  - **Finding 1:** External ID limit corrected 7 → **25** (shared pool with unique custom fields); updated §3 body and Quick Reference. Source: help.salesforce.com 000385134.
  - **Finding 2:** Group task user limit corrected 200 → **100**; updated references/sales-service-detail.md. Source: help.salesforce.com 000380133.
  - **Finding 3:** Web-to-Lead overflow behavior corrected: "silently dropped" → **pending request queue processed when limit resets**; updated references/sales-service-detail.md lead bullet and red-flags paragraph. Source: help.salesforce.com 000382807.
  - **Finding 4:** Web-to-Case overflow behavior corrected: "emailed to default case address" → **pending request queue**; fixed internal contradiction in references/sales-service-detail.md. Source: help.salesforce.com 000382807.
  - **Finding 5:** Workflow Rules / Process Builder "retired" → **"reached end of support (Dec 31 2025); still executes"**; updated §4 and Quick Reference. Source: help.salesforce.com 001096524.
  - **Finding 6:** Added **Lightning App Builder** subsection to §3 (page types, Dynamic Forms, activation/assignment) to close 15% domain coverage gap. Source: admin.salesforce.com 2026 exam-update blog.
  - **Finding 7:** Added **Agentforce 360** dual-naming note (Oct 2025 rebrand) to §7, marked `[volatile — verify live]`. Source: TDX 2026 blog.
  - **Finding 8:** Recycle Bin retention nuanced to **"15 days default; up to 30 days with Extended Retention"**; added Agent Builder conversation-preview testing note to §7. Source: help.salesforce.com 000387160.
  - **Finding 9:** Added **Flow fault-path** guidance to §4 (every faultable element needs a Fault path + error log; silent-failure risk in bulk); added to §4 red flags and Quick Reference.
- **2026-06-10** — Cycle-3 volatile reconciliation: 9 facts confirmed against official docs (markers cleared); Data Loader marker kept (source conflict); Setup studio renamed Agentforce Builder.

## Disclaimer

Independent educational content to upskill AI agents. Not affiliated with, authorized by, endorsed by, or sponsored by Salesforce, Inc. or any certification body. "Salesforce," "Salesforce Certified Platform Administrator," "Agentforce," "Einstein," "NPSP," and related marks are trademarks of Salesforce, Inc., used here solely to identify the subject matter. All other product names and brands are the property of their respective owners. Content is provided as-is, as guidance only — verify all rules, limits, and configuration steps against official Salesforce documentation and your live org before acting. Governor limits, blueprint weights, exam fees, and feature availability are subject to change at any time. No certification outcome is implied or guaranteed.
