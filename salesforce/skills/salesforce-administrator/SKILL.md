---
name: salesforce-administrator
description: Day-to-day Salesforce org configuration — profiles, permission sets, OWD, sharing rules, FLS, the object/field data model, Flow automation, data import (Data Import Wizard, Data Loader), validation rules, duplicate management, reports, dashboards, and Agentforce admin setup. Use when configuring or reviewing declarative org settings, security/sharing, automation, or analytics. Not Apex/triggers/SOQL (see salesforce-platform-developer-1), advanced sharing architecture, deployment pipelines or auditing (see salesforce-advanced-administrator), or building AI agents (see salesforce-agentforce-specialist). Scoped and benchmarked by the Platform Administrator (Plat-Admn-201) blueprint.
metadata:
  credential: Salesforce Certified Platform Administrator
  exam-code: Plat-Admn-201
  domain: salesforce
  type: certification-playbook
  blueprint: December 2025 refresh
---

# Salesforce Administrator — Skills Reference

## Overview

The Salesforce Certified Platform Administrator credential (formerly "Salesforce Certified Administrator," exam code Plat-Admn-201) validates that a practitioner can configure and manage a Salesforce org to meet business needs without writing code. It covers everything an admin touches day-to-day: security and sharing models, object and field customization, automation with Flow Builder, data quality, reports and dashboards, and — as of the December 2025 exam refresh — foundational AI capabilities via Agentforce.

**This file is an operational playbook, not an exam outline.** Each section states the actual rules an agent must apply when doing admin work in an org, the concrete limits, the decision criteria for picking a tool, and the anti-patterns to catch in review. A recurring principle throughout: when in doubt about org state, **query the org — never assume from metadata XML**, because XML in a repo is not always deployed, and metadata does not carry runtime state (FLS, cache, active flows).

> **Deeper context:** Study resources and the NPSP/nonprofit relevance notes live in [references/study-resources.md](references/study-resources.md) (loaded on demand). For org-specific applications of these rules, see a per-org appendix you maintain in your own project, referenced from a CLAUDE.md.

---

Credential logistics and study path: see [references/study-resources.md](references/study-resources.md).

---

## 1. Security & Access Model — the rule that governs everything

This is the most-tested domain. Access is computed by **layering**, and you must reason about the whole stack, not one layer.

**The layering rule (memorize the order):**
1. **OWD (Org-Wide Defaults)** set the floor — the most restrictive baseline per object (Private / Public Read Only / Public Read/Write / Controlled by Parent).
2. **Role hierarchy** grants *upward* visibility — a manager sees records owned by subordinates, never sideways.
3. **Sharing rules** (owner-based or criteria-based) open access *up* from the OWD floor to groups/roles. Sharing rules can only grant, never restrict.
4. **Manual sharing / Apex sharing** for one-off record grants.
5. **Profiles** set object CRUD + the FLS baseline + app/tab/record-type/layout assignments + login hours/IP.
6. **Permission sets & permission set groups** are **purely additive** — they grant, never revoke. The only way to "take away" inside a group is a **muting permission set**.

**Object access ≠ field access ≠ record access. All three must line up:**
- **Object (CRUD):** profile or permission set says you can Read/Create/Edit/Delete the object at all.
- **Field (FLS):** even with full object Read, a field hidden by FLS returns *"Invalid field"* in SOQL and is absent from the UI. **FLS is independent of OWD** — a Public Read/Write object can still have invisible fields.
- **Record (sharing):** OWD + role + sharing rules decide *which rows* you see.

**CRITICAL — SFDX field-meta.xml does NOT carry FLS.** Deploying a custom field via SFDX creates the field but grants field-level security to **no one — not even System Administrator**. Queries hit *"Invalid field"* even with full object access until a profile or permission set explicitly lists `<fieldPermissions>`. Always deploy `<fieldPermissions>` alongside every new non-required field.

**Required-field exception:** Required fields (`<required>true</required>`) are *always* visible/editable and **must be omitted** from `<fieldPermissions>`. Including one fails the permset deploy with *"You cannot deploy to a required field."*

**Permission-set assignment gotcha for External Client Apps:** ECA usage is authorized on the **ECA itself** (ECA detail → Policies tab → Edit → App Policies → Select Permission Sets), **not** on the classic Permission Set "Assigned Connected Apps" page. Browser-AI tools edit the wrong place and report success — verify the assignment via a `PermissionSetAssignment` query before trusting it.

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
- `describe_object(<object>)` → inspect each field; if a field you expect is missing, suspect FLS, not a missing field.
- `soql_query("SELECT PermissionsRead, PermissionsEdit, Field FROM FieldPermissions WHERE ParentId IN (SELECT Id FROM PermissionSet WHERE Name='<permset>')")` to confirm FLS actually landed.
- `soql_query("SELECT AssigneeId, PermissionSet.Name FROM PermissionSetAssignment WHERE PermissionSet.Name='<permset>'")` to confirm assignment before trusting it.

**Setup Audit Trail:** 180-day log of who changed what in Setup. First stop when behavior changes and nobody admits to a change — including silent changes introduced by managed packages (see §4).

---

## 2. Configuration & Setup — org, users, company

**Users are deactivated, never deleted.** You cannot delete a user. Deactivating frees the license; freezing (Setup → Users → Freeze) instantly blocks login without freeing the license — use freeze when you need to lock someone out *now* and deactivate later (deactivation can be blocked by pending records the user owns, e.g. open approvals).

**Company settings to know:** fiscal year (standard vs custom), business hours (drive escalation/milestone timing), locale/language/currency. Multi-currency, once enabled, **cannot be disabled.**

**Login & session security:** login hours and login IP ranges live on the **profile**; trusted IP ranges (skip-verification) live in Network Access. Session timeout and "lock session to IP" live in Session Settings. MFA is mandatory for direct logins.

**Sandbox creation can be gated by org policy** — some orgs require a Public Group with the admin as a member before a sandbox can be created (a one-time setup quirk worth checking if sandbox creation fails).

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

**Roll-up summary fields** exist **only on the master side of a master-detail** (COUNT/SUM/MIN/MAX, optionally filtered). Need a roll-up over a Lookup? You can't declaratively — use a record-triggered Flow or Apex trigger, or Declarative Lookup Rollup Summaries (DLRS).

**Lookup `relationshipName` must be unique per parent object** — two Lookups to the same parent can't share a relationshipName (deploy fails: *"Duplicate relationship name"*). Use role-specific suffixes to disambiguate. SOQL parent traversal is keyed on **field name** (e.g. `Parent__r.Name`), not relationshipName, so renaming relationshipName is safe.

**Formula fields never store data** — they compute at read time, so they can't be set, indexed normally, or used as external IDs. Cross-object formulas span up to **10 relationship hops**.

**Field sizing should be treated as a contract.** When a system writes from application/form code into Salesforce fields, the code's string-length and picklist constraints should be **derived from the live Salesforce field metadata**, not hand-set literals — and regenerated whenever a field is resized or a picklist edited. A defensive truncation at the write boundary is a last-line fallback for legacy/API-bypass records, **not** a substitute for keeping the constraints current. So a field resize is rarely a one-file change: the SF metadata, any generated schema/validation artifacts, and the data-model docs must all move together — all or none.

**Record types** drive page-layout assignment (profile × record type → layout) and picklist value subsets. **External IDs** are the upsert key for idempotency and for late re-link paths — they must be unique, are indexed, and a record can have up to 7 external ID fields.

**Quick Action / Lightning cache scar:** Adding fields to an existing Quick Action's `quickActionLayoutItems` via SFDX updates the metadata but **does NOT invalidate the runtime QA cache** that renders Lightning contextual tabs (`console:relatedRecord`) — even after full logout/login. New fields are silently absent, no error. **Cache-bust fix:** edit any non-field-list metadata on the QA (`<description>`, `<label>`, `<layoutSectionStyle>`) and redeploy; SF treats the structural change as meaningful and flushes the org-level cache.

**Red flags:** choosing master-detail when the child must sometimes exist alone (use Lookup); expecting a roll-up over a Lookup; two same-parent Lookups with identical relationshipName; hand-editing generated schema/validation files; a form `max()` literal that doesn't trace to the field-length source of truth; adding QA fields and not seeing them on the tab (apply the cache-bust).

**Verify:** `describe_object(<object>)` to read true field lengths and picklist values before trusting any schema file; `list_objects()` to confirm an object exists before referencing it.

---

## 4. Automation — Flow first, and the managed-package trap

**Workflow Rules and Process Builder were retired Dec 31, 2025 — build all new automation in Flow.** You still must *recognize* them because managed packages and legacy org config still contain them, and they still fire.

**Pick the flow type by trigger:**

| Requirement | Flow type |
|---|---|
| React to a record create/update, modify the *same* record cheaply | **Before-save** record-triggered (no DML, fastest) |
| React to a record save, create/update *related* records or send email | **After-save** record-triggered |
| Run on a schedule over a set of records (nightly cleanup, reminders) | **Scheduled** flow |
| User-facing wizard / form embedded in a page or Quick Action | **Screen** flow |
| Reusable logic called by other flows/Apex/REST | **Autolaunched** (invocable) |
| React to a Platform Event | **Platform-event-triggered** flow |

**Before-save vs after-save is the single most important automation choice:** before-save can set fields on the triggering record with **zero added DML** (huge for performance and limits); after-save runs post-commit and is required to touch *other* records. Default field values and same-record validation → before-save. Roll-ups, child records, emails → after-save.

**Governor limits inside a transaction (flows + Apex + triggers all share these):** 100 SOQL queries, 150 DML statements, 50,000 rows retrieved, 10,000 DML rows, 6 MB heap (sync) / 12 MB (async), 10s CPU (sync). Flows process records in **batches of 200**. Bulk integration paths can run near these — keep work bulk and out of loops.

**Bulkify everything.** Never put a Get Records / Create / Update / Delete element (or SOQL/DML) **inside a Loop**. Pattern: Get once into a collection → Loop in memory to build a second collection → one Create/Update **after** the loop. Same rule in Apex: query into a Map, iterate in memory, collect into a List, DML once.

**Managed-package automation silently mutates your data.** A managed package can ship its own Workflow Rules, flows, and triggers in its namespace that fire on your records — often driven by package-default picklist values you never set. The canonical example: NPSP's Contacts & Organizations package ships a workflow rule that copies `Phone → MobilePhone` when its preferred-phone picklist defaults to "Mobile", which can silently overwrite data on every new Contact. **Lesson:** when a field changes value with no code of yours responsible, **suspect managed-package automation** (workflow rules, flows, triggers in a namespace), not your own — and check it *before* blaming a more visible package. An Apex debug-log probe in a sandbox is the fastest way to catch the real culprit; the fix is usually to deactivate the offending rule in Setup.

**Approval processes** — action timing you must place correctly: Initial Submission Actions, Approval Actions, Rejection Actions, Recall Actions, and Final Approval/Rejection Actions. Approver sources: specific user, role, queue, related-user field, or manager. A native Approval Process and a picklist-edit-plus-flow are both valid patterns; pick by complexity.

**Red flags:** any Get/Create/Update/Delete element inside a Loop; before-save flow doing DML on other objects (use after-save); building a *new* Workflow Rule or Process Builder; assuming "the field changed itself" without checking managed-package automation; an after-save flow that re-triggers itself (recursion — add entry criteria / `ISCHANGED` guards).

**Verify:** `soql_query("SELECT Id, MasterLabel, TriggerType, Status FROM FlowDefinitionView WHERE Status='Active'")` to see what's actually firing; `describe_object` on the affected object to inspect managed-package fields and their defaults before debugging mystery data changes; Setup Audit Trail for recent automation changes.

---

## 5. Data & Analytics — import, quality, reporting

**Pick the import tool:**

| | Data Import Wizard | Data Loader |
|---|---|---|
| Max records | 50,000 | 5,000,000 |
| Objects | Accounts, Contacts, Leads, Campaign Members, Person Accounts, custom objects | All objects incl. custom |
| Upsert by external ID | Limited | ✅ full |
| Hard delete | ❌ | ✅ |
| Built-in dup matching | ✅ | ❌ |
| Interface | Browser wizard | Desktop app / CLI (CLI for scheduled jobs) |

For nonprofit (NPSP) orgs, **NPSP Data Import** is purpose-built and supports NPSP custom field mappings — prefer it over vanilla Data Loader for bulk Contact loads and recovery imports. Configure NPSP custom Field Mappings once so recovery is one-pass.

**Recycle Bin retention is 15 days**; hard delete (Data Loader) skips it and is unrecoverable.

**Duplicate management** = Matching Rules (define what counts as a dup, e.g. fuzzy name + exact email) + Duplicate Rules (Alert allows-with-warning vs Block prevents save).

**Validation rules** fire on save; a rule that evaluates `TRUE` **blocks** the save. Use `ISCHANGED()`, `ISNEW()`, `PRIORVALUE()`, and profile/permission checks (`$Permission`, `$Profile`) to scope. Place the error on a specific field where possible, not just top-of-page.

**Reports:** tabular (lists, no grouping — can't drive most dashboards), summary (group by rows), matrix (rows × columns), joined (multiple report types). Cross-filters answer "Contacts WITHOUT applications." Custom Report Types are required to report across custom-object relationships not in standard types.

**Dashboards & sharing:** dashboards run as a fixed running user (everyone sees that user's data) **unless** it's a dynamic dashboard (runs as viewer). Folder sharing controls who can open the report/dashboard at all — **report visibility is gated by both folder access and the running user's record access** (OWD/sharing still apply to the data).

**Red flags:** Data Import Wizard for >50k rows or for an unsupported object; hard delete without a backup; a dashboard exposing data because its running user is an admin; expecting a report to show records the running user can't see.

**Verify:** `soql_query("SELECT COUNT() FROM <object>")` to sanity-check row counts before/after an import; `run_report(...)` to confirm a report returns what staff expect; `find_contacts(...)` to spot-check that a backfill landed.

---

## 6. Sales & Marketing — Sales Cloud objects

The exam tests Sales Cloud even where an org doesn't run a traditional pipeline; NPSP repurposes several of these objects.

- **Leads:** assignment rules route by criteria to a user or queue; web-to-lead default cap is **500/day**; lead conversion maps Lead fields → Account/Contact/Opportunity and the Lead becomes read-only/archived. NPSP largely bypasses Leads in favor of direct Contact creation.
- **Accounts/Contacts:** NPSP uses **Household Accounts** by default — every Contact rolls up to a Household Account (Contact → Account → Household). Understand this before reporting on "donors per household."
- **Opportunities** = donations/gifts in NPSP; stages carry probability; Opportunity Contact Roles link multiple people to one gift.
- **Campaigns** = NPSP appeals/outreach; campaign member statuses, hierarchy, and ROI fields (Actual Cost, Expected Revenue).

**Red flag:** treating NPSP Opportunities as a sales pipeline; forgetting Household Account rollup when counting donors.

---

## 7. Service & Support — Cases

- **Cases:** queues route incoming work; assignment rules send to user/queue; **escalation rules** are time-based and **business-hours-aware** — the same time-based-escalation pattern underlies any "awaiting action" reminder workflow.
- **Email-to-Case** (on-demand variant needs no firewall change) threads replies via a threading key in the email subject. Standard Email-to-Case requires an open firewall port; On-Demand Email-to-Case routes through Salesforce servers and avoids the firewall requirement — pick On-Demand unless you have a specific reason to route inbound mail directly.
- **Web-to-Case:** captures form submissions as Cases; default cap is 5,000 cases per 24 hours. Cases above the cap are emailed to the org's default case email address. Requires no code — just generate the HTML from Setup.
- **Entitlements & Milestones** enforce SLAs with time-based milestone actions (warning/violation). Milestones require a process associated with a product/account entitlement — they do not activate automatically on all cases.
- **Omni-Channel** routes by presence/capacity/skills. Agent status (Available/Busy/Away) is set by the agent; a supervisor can override. Routing configurations define the priority and model (most available, least active, or external routing).
- **Knowledge:** articles attach to cases and are searchable by support agents and in Experience Cloud portals; article visibility is controlled by data categories and the user's data category visibility settings.

**Relevance flag:** Knowledge + entitlements apply wherever a staff/volunteer support portal is added; "missing-document reminder" automation is conceptually case escalation.

---

## 8. Productivity & Collaboration

- **Quick Actions:** object-specific (create/update/log-a-call on a record) vs global. Contextual record tabs backed by object-specific Quick Actions are **subject to the QA cache trap in §3** — apply the cache-bust after editing their field lists.
- **Activities:** Tasks/Events; group tasks assign to up to 200 users (creates a copy per user); shared activities link one activity to multiple contacts.
- **Email:** org-wide email addresses, letterhead/HTML templates, merge fields, Email-to-Salesforce BCC logging. Transactional email is often handled outside SF (e.g. SES), while approval-notification copy lives in SF Flow email actions.
- **AppExchange:** install in **sandbox first**, look for the security-review badge, manage managed-package updates centrally. NPSP itself is a managed package — never edit managed components directly; extend alongside.

**Red flag:** editing managed-package (NPSP) metadata directly; adding Quick Action fields and not cache-busting.

---

## 9. Agentforce AI (8%) — awareness + permissions

Newest domain. The **permission reasoning is the same access stack as §1.**

- **Agentforce** = configurable, conversational, action-taking autonomous agents; distinct from **Einstein** (predictive/generative features embedded in standard objects, e.g. Opportunity/Lead Scoring, Next Best Action).
- **Agent Builder** (declarative): set agent identity/persona, **instructions** (guardrails), **topics** (what it can help with), and **actions** (Apex-backed, Flow-backed, API, email) within topics. Topics define scope — if a user request doesn't match an active topic's description, the agent declines even if an action exists. Instructions are evaluated before every response and are the primary guardrail mechanism.
- **Prompt Builder:** prompt template types — Flex, Sales Email, Record Summary, Field Generation. Templates merge runtime data; the running user's FLS controls which fields merge successfully.
- **Actions:** an agent action can be a Flow, an Apex method, an API call, or a standard action (e.g. Send Email). Each action must be explicitly added to a topic — actions not linked to any topic are unreachable.
- **Security:** an agent **runs in a configured user context and is bound by that user's OWD + FLS + permission sets.** The #1 failure mode is "agent can't access a record" — diagnose as a normal access problem: check the running user's object CRUD, FLS, and sharing, exactly as in §1. Use conversation transcripts + debug logs.
- **Einstein features (not Agentforce):** Opportunity Scoring, Lead Scoring, Next Best Action, Einstein Activity Capture — these are predictive/generative features on standard objects, configured separately from Agent Builder, and do not use the topics/actions model.

**Red flag:** assuming an agent bypasses sharing/FLS (it does not); an action that exists but is not linked to a topic (agent can't reach it); pointing an agent at PII without checking the running user's data scope; confusing Einstein feature configuration with Agentforce Agent Builder.

---

## Decision Scenarios

Five original scenarios covering the highest-value operational gotchas. Each one probes a judgment call where the wrong move looks reasonable until you understand the underlying rule.

---

**Scenario 1 — The invisible field after SFDX deploy**

> **Situation:** A developer deploys a new custom text field `Preferred_Language__c` on Contact via SFDX pipeline. The CI job reports success. A support agent logs in and the field is absent from the page layout and returns `"Invalid field"` when queried via SOQL. The developer confirms the field exists in Object Manager. What is happening and what is the fix?

> **Competent move:** The field was created but no `<fieldPermissions>` block was included in the permset or profile XML deployed alongside it. SFDX field-meta.xml does not carry FLS; every non-required field starts invisible to everyone — including System Administrators — until a profile or permission set explicitly grants at least Read. Fix: add `<fieldPermissions>` granting `editable`/`readable` to the appropriate profile or permission set and redeploy. Verify with `soql_query("SELECT Field, PermissionsRead FROM FieldPermissions WHERE ParentId IN (SELECT Id FROM PermissionSet WHERE Name='<permset>')")`.

> **Tempting-but-wrong:** Assume the field was not actually deployed and re-run the deploy, or add it to the page layout. Neither addresses the root cause — the field exists but is FLS-invisible. Adding a missing-FLS field to a page layout produces a layout that renders with the field still absent.

> **Verify:** `describe_object('Contact')` — if `Preferred_Language__c` appears in the field list, it exists; check `filterable` and `updateable` flags. If the field is absent from describe output for the current user context, FLS is the culprit. After adding `<fieldPermissions>` and redeploying, re-run the SOQL above to confirm the grant landed.

---

**Scenario 2 — Choosing between before-save and after-save Flow**

> **Situation:** A new business rule: when an Opportunity's Stage changes to "Closed Won," automatically set a custom `Close_Fiscal_Quarter__c` formula-derived text field to a calculated value AND create a follow-up Task assigned to the Opportunity owner. How many flows, and of which types?

> **Competent move:** Two separate concerns require two trigger contexts. Setting `Close_Fiscal_Quarter__c` on the *same* Opportunity record — use a **before-save** record-triggered flow: it writes back to the triggering record with zero added DML, is fastest, and runs before the record commits. Creating a Task (a *different* record) — use a **separate after-save** record-triggered flow (or add an after-save path): it runs post-commit and can perform DML on related records. Attempting to create the Task in the before-save context will fail — before-save flows cannot perform DML on other objects.

> **Tempting-but-wrong:** Build a single after-save flow that does both. It works, but setting a field on the Opportunity record from an after-save flow causes an extra DML update on the triggering record (a second save), consuming an additional DML statement and potentially re-triggering other automation. The before-save approach is always preferable for same-record field sets.

> **Verify:** In Flow Builder, confirm the first flow's type is Record-Triggered with "Before the record is saved" selected and contains no DML elements. Confirm the second uses "After the record is saved." Test with a bulk update of 250+ Opportunities to verify governor limits are not breached.

---

**Scenario 3 — Sharing rules cannot restrict; only OWD can lower the floor**

> **Situation:** An org has Opportunity OWD set to Public Read/Write. Sales reps can see each other's deals. A new requirement: reps should only see their own pipeline; managers should still see their team's. An admin proposes creating a sharing rule that "restricts access to the owner only." Is this possible? What is the correct approach?

> **Competent move:** Sharing rules can only **grant** access above the OWD floor — they cannot restrict. The fix is to change the OWD on Opportunity to **Private**, which sets the floor to owner-only visibility. Then use the **role hierarchy** to automatically give managers upward visibility into their subordinates' records (no sharing rule needed — role hierarchy is automatic when OWD < Public Read/Write). If cross-role access is needed beyond the hierarchy, add owner-based or criteria-based sharing rules to open it back up selectively.

> **Tempting-but-wrong:** Create a criteria-based sharing rule that says "share records where Owner = Viewer" — there is no such sharing rule syntax. Or try to use a permission set to restrict record visibility — permission sets are additive on object/field access and have no mechanism to restrict sharing. The only mechanism to *lower* record visibility is to change the OWD.

> **Verify:** After changing OWD, run `soql_query("SELECT Id, Name FROM Opportunity LIMIT 10")` as a rep user (or via a guest/community session) to confirm row-level filtering. Check that managers can still see subordinate records by querying under a manager's user context.

---

**Scenario 4 — Mystery field change: managed-package automation**

> **Situation:** Staff report that new Contact records created via a data import have their `Phone` field overwritten with a different number within seconds of saving. No custom trigger or flow in the org's namespace touches `Phone` on Contact after insert. What should the admin investigate first?

> **Competent move:** When a field changes value with no locally-owned automation responsible, **suspect managed-package automation** — Workflow Rules, flows, or triggers in a managed-package namespace that fire on your objects. In this org (likely NPSP), NPSP's Contacts & Organizations package ships a workflow rule that can copy `Phone → MobilePhone` or vice versa based on a preferred-phone picklist value that defaults to "Mobile." Check Setup → Workflow Rules and filter by namespace (look for `npsp__` prefix). Also check Setup → Flows and sort by namespace. Enable an Apex debug log for a System Administrator user, re-trigger the scenario in a sandbox, and inspect the log for triggers and flows in non-default namespaces.

> **Tempting-but-wrong:** Assume the import tool itself is transforming the data and re-test the import. Or check your own org's flows and triggers — they are in the default namespace and are not the culprit. Blaming the visible, known automation before checking managed-package namespaces wastes time.

> **Verify:** In the Apex debug log, search for `WORKFLOW_ACTION` or `FLOW_START_INTERVIEWS` entries. Note the namespace prefix. Once the offending rule is identified, deactivate it in Setup (you can deactivate managed-package Workflow Rules even if you can't edit them). Retest the import.

---

**Scenario 5 — Agentforce agent cannot retrieve a record**

> **Situation:** An Agentforce agent is configured in Agent Builder with a Flow-backed action that queries open Cases for a contact. In testing, users report the agent responds "I wasn't able to find any open Cases" even though the Cases exist. The Flow is active and works when invoked manually by a System Administrator. What is the diagnostic approach?

> **Competent move:** The agent runs under a **configured running user context**, not as a System Administrator. The running user's OWD, FLS, and permission sets govern what the agent can see. The most likely cause is that the running user lacks Read on the Case object (object CRUD), cannot see a required filter field due to FLS, or the Cases are owned by others and the OWD on Case is Private with no sharing rule granting the running user access. Diagnostic steps: (1) identify the agent's running user in Agent Builder; (2) check that user's profile and permsets for Case Read access; (3) run the SOQL query the Flow uses as that user to confirm it returns records; (4) check Case OWD and sharing rules.

> **Tempting-but-wrong:** Assume the Flow has a bug because it returns results when run as an admin. Or rebuild the Flow. The Flow itself is correct — the access problem is upstream of it. Elevating the running user to System Administrator "to fix" is a security anti-pattern that bypasses all OWD/FLS/sharing controls for every action the agent can perform.

> **Verify:** `soql_query("SELECT PermissionsRead FROM ObjectPermissions WHERE ParentId IN (SELECT Id FROM PermissionSet WHERE IsOwnedByProfile=true AND Profile.Name='<running_user_profile>') AND SObjectType='Case'")` to confirm Case Read. Then run the Case SOQL with a `LIMIT 1` filter matching the scenario as the running user context. Check Setup Audit Trail for any recent change to Case OWD.

---

## Operational Rules Quick Reference

Read this first. Each rule is concrete and imperative.

- **DO** assume a freshly SFDX-deployed field is invisible until a profile/permset grants FLS — deploy `<fieldPermissions>` alongside every new non-required field.
- **DON'T** put a required field in `<fieldPermissions>` — the permset deploy fails. Omit all required fields.
- **DO** treat object CRUD, FLS, and record sharing as three separate gates that must all pass.
- **DON'T** expect a permission set to revoke anything — permsets are additive; use a muting permset to subtract inside a group.
- **DO** assign External Client App access on the ECA → Policies → App Policies → Select Permission Sets, and verify via `PermissionSetAssignment` query.
- **DON'T** ever build a new Workflow Rule or Process Builder — both retired Dec 31, 2025; build in Flow.
- **DO** prefer a before-save record-triggered flow for same-record field changes (zero added DML); use after-save only for related records/email.
- **DON'T** place any Get/Create/Update/Delete element (or SOQL/DML) inside a Loop — bulkify: collect, then one DML after the loop.
- **DO** stay under per-transaction limits: 100 SOQL, 150 DML, 50k rows retrieved, 10k DML rows; flows batch in 200s.
- **DO** suspect managed-package automation (e.g. NPSP namespaces) when a field changes value with no code of yours responsible.
- **DON'T** edit managed-package (NPSP) metadata directly; extend alongside it.
- **DO** put roll-up summaries only on the master side of a master-detail; for a Lookup rollup use Flow/Apex/DLRS.
- **DON'T** give two Lookups to the same parent the same `relationshipName` — use role-specific suffixes.
- **DO** derive form/integration string `max()` and picklist constraints from live field metadata; regenerate after any field resize/picklist edit; never hand-edit generated schema files.
- **DO** cache-bust a Quick Action after adding fields: edit `<description>`/`<label>` and redeploy, or the new fields won't render on the contextual tab.
- **DON'T** use Data Import Wizard for >50k rows or unsupported objects — use Data Loader (5M cap); for nonprofit loads use NPSP Data Import.
- **DO** remember Recycle Bin is 15 days; hard delete is unrecoverable — back up first.
- **DON'T** delete a user — deactivate (frees license) or freeze (instant lockout, keeps license).
- **DO** check Setup Audit Trail (180-day) first when org behavior changes unexpectedly.
- **DO** verify against the live org with MCP tools (`describe_object`, `soql_query`, `list_objects`, `find_contacts`) before trusting repo XML or a schema file.
- **DON'T** assume an agent (Agentforce) or dashboard bypasses sharing/FLS — both honor the running user's access.

---

## Study resources & relevance

Study resources (official Salesforce + community) and the NPSP/nonprofit relevance notes are kept in [references/study-resources.md](references/study-resources.md) so this skill stays focused on operational rules. Load that file when planning a study path or mapping these rules to a nonprofit org.

---

## Disclaimer

Independent educational content to upskill AI agents. Not affiliated with, authorized by, endorsed by, or sponsored by Salesforce, Inc. or any certification body. "Salesforce," "Salesforce Certified Platform Administrator," "Agentforce," "Einstein," "NPSP," and related marks are trademarks of Salesforce, Inc., used here solely to identify the subject matter. All other product names and brands are the property of their respective owners. Content is provided as-is, as guidance only — verify all rules, limits, and configuration steps against official Salesforce documentation and your live org before acting. Governor limits, blueprint weights, exam fees, and feature availability are subject to change at any time. No certification outcome is implied or guaranteed.
