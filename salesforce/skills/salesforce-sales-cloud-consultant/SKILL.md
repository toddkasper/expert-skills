---
name: salesforce-sales-cloud-consultant
description: Designing and configuring Salesforce Sales Cloud — leads and lead conversion, opportunities and pipeline stages, forecasting, territory management, price books and products, campaigns, and sales-productivity/AI features. Use when scoping or implementing Sales Cloud, picking automation tools, modeling the sales data layer, designing the sharing model, planning migrations/dedupe, or building sales reports and dashboards. Not Service Cloud (see salesforce-service-cloud-consultant), external portals (see salesforce-experience-cloud-consultant), or general org admin (see salesforce-administrator). Scoped and benchmarked by the Sales Cloud Consultant (Sales-Con-201) blueprint.
metadata:
  credential: Salesforce Certified Sales Cloud Consultant
  exam-code: Sales-Con-201
  domain: salesforce
  type: certification-playbook
  blueprint: June 2024 restructure (5 domains)
---

# Sales Cloud Consultant — Skills Reference

> This file is an **operational playbook**, not an exam outline. Every section
> states the rule as an actionable instruction, gives the real limits/numbers,
> tells you *when* to choose one tool over another, and flags the anti-patterns
> to catch in review. Read the **Operational Rules Quick Reference** first.

## Overview

The **Salesforce Certified Sales Cloud Consultant** credential validates the
ability to translate business requirements into scalable, maintainable Sales
Cloud configurations across the full sales lifecycle (lead → opportunity →
order → analytics). The lasting value is the platform-design judgment it
exercises: sharing models, declarative-vs-code decisions, data migration,
governor limits, and deployment discipline — applicable to any Salesforce org.

**Exam code:** Sales-Con-201
**Credential level:** Consultant (intermediate)
**Maintenance:** Pass a short release-maintenance module each Salesforce release
cycle; the credential expires if not maintained.

The exam outline was restructured in June 2024, collapsing nine topic areas into
five consolidated domains. The skills tested are identical; only the
labels/groupings changed. Current blueprint: Practical Application of Sales Cloud
Expertise 33%, Sales Lifecycle 23%, Implementation Strategies 15%, Data
Management 15%, Consulting Practices 14%.

> **Deeper context:** Study resources live in [references/study-resources.md](references/study-resources.md) (loaded on demand). For org-specific applications of these rules, see a per-org appendix you maintain in your own project, referenced from a CLAUDE.md. For NPSP/nonprofit-specific guidance, see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md).

> **Verify steps assume nothing about your tooling** — use your project's Salesforce MCP connection, the Salesforce CLI (`sf`), or the Salesforce setup UI, in that order of preference.

---

Credential logistics and study path: see [references/study-resources.md](references/study-resources.md).

---

## 1. Automation: choosing the right tool (declarative vs. code)

**The rule: always solve at the lowest-power tier that meets the requirement.**
Reach for code only when declarative tools genuinely can't do it. Over-engineering
(an Apex trigger for what a validation rule does) is a review failure, not a
flex.

| Requirement | Use | Why / threshold |
|---|---|---|
| Block a bad save with a field-level condition | **Validation Rule** | Runs before save, no code, shows inline error. First choice for data integrity. |
| Field default, simple field update on same record, screen-based intake | **Flow** (record-triggered or screen) | Salesforce's strategic no-code engine. Workflow Rules and Process Builder are **retired** for new builds — do not create them. |
| Multi-object orchestration, complex branching, subflows | **Flow** | Still the default before code. |
| Bulk logic, recursion control, complex rollups, callouts with retry, > Flow's comfort zone | **Apex trigger / class** | Justify it. Triggers run in bulk and you control the transaction. |
| Cross-record dedupe at entry | **Duplicate + Matching Rules** | Declarative; no code. |
| Prevent two flows/triggers on the same object fighting | **One trigger per object** + handler class | Order of operations is otherwise non-deterministic. |

**Decision criteria:**
- **Validation rule vs. Flow:** if you only need to *reject* a save, use a
  validation rule. If you need to *change* data or *do* something, use a Flow.
- **Flow vs. Apex:** if a Flow needs > ~3 nested loops, does DML inside a loop
  you can't bulkify, or needs guaranteed bulk-safe behavior at scale, move to
  Apex. Multi-object writes that must be transactional and bulk-safe (e.g. a
  record-approval handler that upserts a Contact, creates related records, and
  sets role flags) belong in Apex precisely because of those guarantees.

**Anti-patterns / red flags:**
- New Workflow Rule or Process Builder — both retired; rebuild as Flow.
- Apex doing what a validation rule does.
- Multiple record-triggered Flows + a trigger on the same object with no defined
  order.
- A managed-package Workflow Rule silently mutating your data. Managed packages can ship workflow rules that copy or overwrite field values on insert/update — always audit installed automation when a field value changes unexpectedly. (e.g. NPSP's `npe01` package; see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md) for NPSP-specific details.)

---

## 2. Apex governor limits & bulkification

**Bulkify everything. Never put SOQL or DML inside a `for` loop.** Query once
into a `Map`, iterate in memory, collect into a `List`, DML once at the end.

**The numbers you must hold (per synchronous transaction):**

| Limit | Value |
|---|---|
| SOQL queries | **100** |
| DML statements | **150** |
| Rows retrieved by SOQL | **50,000** |
| Rows processed per DML | **10,000** |
| Records per trigger invocation (batch) | **200** |
| CPU time (sync) | **10,000 ms** |
| Heap (sync) | **6 MB** |
| Callouts | **100** per transaction; **120 s** total callout time |
| Future methods | **50** per transaction |
| Async (Batch/Queueable) SOQL rows | **50,000**, CPU **60,000 ms**, heap **12 MB** |

**Decision criteria:**
- > 50,000 rows or > 10,000 DML rows in one go → **Batch Apex** (200-record
  chunks) or **Bulk API** for data loads, not a single trigger transaction.
- External HTTP calls → never inside a trigger's synchronous path if avoidable;
  use `@future(callout=true)` or Queueable so a slow endpoint doesn't blow the
  120 s callout ceiling and roll back the user's save.

**Anti-patterns / red flags to catch in review:**
- Any `[SELECT ...]` or `insert`/`update`/`delete`/`upsert` inside a `for` loop
  body.
- Trigger logic that assumes `Trigger.new` has one record (it can have 200).
- Hard-coded record IDs.
- Recursion with no static guard (trigger re-firing itself).
- Truncation that silently loses data instead of validating upstream. A
  defensive truncate in Apex is at best a last-line fallback for legacy /
  direct-API records — it is never a substitute for validating field length at
  the application/integration boundary against the field's real max length.

---

## 3. Field-Level Security vs. Object access — they are separate

**Object access (CRUD on the object) does NOT grant field access (FLS).** A user
or integration can have full Read/Edit on an object and still get *"Invalid
field"* on a SOQL query because FLS on that field is granted to no one.

**The rule:** every field a profile/permset/integration user needs to read or
write must have an explicit `<fieldPermissions>` entry in a profile or permission
set. There is no inheritance from object access.

**Hard deployment trap:** **SFDX `field-meta.xml` does NOT carry FLS.**
Deploying a custom field via SFDX creates the field but grants FLS to *no one* —
not even System Administrator. You must follow every field deploy with a
permission set (or profile) that lists `<fieldPermissions>`.

**Two more rules that bite on the permset:**
- **Required fields cannot appear in `<fieldPermissions>`.** Salesforce rejects
  the deploy with *"You cannot deploy to a required field"* — required fields are
  always visible/editable, so **omit them** from the permset's field permissions.
- **Restricted picklist values rejected by the API** look like a field problem
  but are a value-allowlist problem. A write of a value not in a restricted
  picklist's allowed set fails even with full FLS — describe the field and check
  its allowed values before assuming any string is valid.

**Anti-patterns / red flags:**
- A field added in SFDX with no matching permset change → guaranteed "Invalid
  field" at query time.
- Trusting a browser-AI tool that "assigned the permission" without an API check.

---

## 4. Lookups, relationships & the data model

**Rules:**
- **`relationshipName` must be unique per parent object.** Two Lookups on the
  same child both pointing at the same parent object cannot share a
  `relationshipName` — deploy fails with *"Duplicate relationship name"*. Use
  role-specific suffixes. SOQL parent traversal (`Parent__r.Name`) keys on
  **field name**, not relationshipName, so renaming the relationship is safe.
- **Master-Detail vs. Lookup:** Master-Detail cascades delete, locks the child
  to the parent, supports roll-up summary fields, and inherits sharing. Lookup is
  loosely coupled and optional. Choose **Lookup** when the child should survive
  parent deletion and have independent sharing — e.g. an immutable audit record
  that must persist forever even if its related person record is reworked.
- **External IDs for upsert:** mark a field `External Id` + `Unique` to upsert
  idempotently from an integration. Keying re-link operations on a stable
  External Id (e.g. a submission identifier) lets later writes find the same
  parent records with no new write logic.

**Field-length discipline:** any string an integration writes to a Salesforce
field should be validated against that field's real max length *at the
boundary*, not silently truncated downstream. When length/picklist constants are
generated from the org's metadata, treat the generated files as read-only and
regenerate them when the org changes — never hand-edit, which drifts from the org
silently.

**Anti-patterns / red flags:**
- Two same-target lookups sharing a relationshipName.
- A hand-typed length/enum constraint instead of one derived from the org's
  actual metadata.
- Master-Detail used where the child must outlive the parent.

---

## 5. Sharing & security model

**Design from the most-restrictive baseline up.** OWD sets the floor; you open
access selectively.

| Mechanism | When to use |
|---|---|
| **Org-Wide Defaults (OWD)** | Set the baseline. Private for sensitive PII; Public Read-Only only if everyone should see everything. |
| **Role Hierarchy** | Grant managers access to subordinates' records. Vertical access. |
| **Sharing Rules** (owner/criteria-based) | Open records laterally to a role/group beyond the hierarchy. |
| **Manual / Apex sharing** | One-off or programmatic grants. |
| **Teams (Account/Opportunity)** | Per-record collaborator access without changing OWD. |
| **Permission Sets / Permset Groups** | Grant *abilities* (object CRUD, FLS, system perms) additively. Prefer over editing profiles. |

**Rules:**
- **OWD is the floor — you can only widen, never narrow, with sharing rules.** If
  a requirement is "most users see nothing, a few see all," set OWD Private and
  share up.
- **Permission sets over profiles** for granting access — additive, composable,
  and the modern best practice (Salesforce is deprecating permissions on
  profiles).
- **External Client App / Connected App authorization is configured on the app,
  not via a "permission set assigned apps" page.** In modern org configs the
  working path is ECA detail → **Policies → Edit → App Policies → Select
  Permission Sets**. The classic "Assigned Connected Apps" page does **not**
  authorize ECA usage. Verify via API (`PermissionSetAssignment`,
  `SetupEntityAccess`) before trusting it.
- **PII / sensitive documents:** keep OWD restrictive; never log PII; keep file
  contents in object storage (encrypted), referenced by key, never duplicated
  into Salesforce field values.

**Anti-patterns / red flags:**
- Editing a profile to grant something a permission set should grant.
- Public Read/Write OWD on an object holding PII.
- Assuming an ECA is authorized because the permset "assigned apps" page was
  edited.

---

## 6. Data management: migration & quality

**Tool selection by volume and object:**

| Tool | Use when |
|---|---|
| **Data Import Wizard** | ≤ 50,000 records, standard + some custom objects, simple loads, built-in dedupe. |
| **Data Loader** | Bulk (millions), all objects, insert/update/**upsert**/delete, scriptable/automatable. |
| **Bulk API 2.0** | Programmatic large-volume loads; async, chunked. |
| **Purpose-built package import tools** | e.g. NPSP Data Import / Gift Entry for nonprofit-shaped imports — use the org's native import tool when one exists. |

**Rules:**
- **Use upsert with an External ID** for idempotent, re-runnable migrations — no
  duplicates on re-run.
- **Load order = dependencies first:** objects before fields, parents before
  children, **permission sets before assignments**, FLS before data that needs
  the fields visible.
- **Always have a rollback plan** (keep source keys, load in reversible batches).
- **Dedupe before and after**: configure Matching + Duplicate Rules to prevent duplicate records.

**Anti-patterns / red flags:**
- Insert (not upsert) on a re-runnable migration → duplicate explosion.
- Loading child records before parents exist.
- Migrating into fields whose FLS hasn't been granted (loads silently drop or
  error per-row).

---

## 7. Large Data Volume (LDV) & performance

**Rules:**
- **Avoid data skew.** *Ownership skew*: > ~10,000 records owned by one user
  slows sharing recalculation. *Lookup skew*: > ~10,000 child records pointing at
  one parent causes record-lock contention on parallel loads.
- **Index your filters.** Selective SOQL (indexed field, < 10% / 300k rows
  returned) avoids full table scans. Standard indexed fields: Id, Name, External
  Id, lookups, audit fields. Custom: mark `External Id` or request a custom
  index.
- **Skinny tables / Big Objects** for read-heavy reporting on millions of rows
  (Salesforce-support-managed).
- **Defer sharing recalculation** during large loads; archive cold data.

**Anti-pattern:** non-selective SOQL on a multi-million-row object (no indexed
filter) → query timeout / `QueryException`.

---

## 8. Lead, Opportunity & sales pipeline design

**Rules:**
- **Lead conversion maps Lead → Account + Contact + (optional) Opportunity.**
  Configure field mapping in Setup so custom lead fields don't vanish on convert.
- **Opportunity Stage drives Forecast Category and probability.** Keep them
  aligned; a stage with the wrong forecast category corrupts pipeline reports.
- **Sales Process + Record Type** restrict which stages a given record type sees.
- **Validation rules enforce stage gates** (e.g. can't reach "Closed Won" without
  required fields).
- **Price books:** every product needs a Standard Price Book entry before it can
  go on a custom price book. Associate currency entries for multi-currency orgs.
- **CPQ/Revenue Cloud vs. native Quotes:** native Quotes for simple line items;
  CPQ when you need configurable bundles, complex discounting, approval-gated
  pricing.

**Anti-patterns:** orphaned lead custom fields lost on convert; stage/forecast
category drift; a product on a custom price book with no standard price.

---

## 9. Implementation & deployment discipline

**Rules:**
- **Sandbox → UAT → Production.** Never deploy untested metadata straight to prod.
  Sandbox types: **Developer** (config only, daily refresh), **Developer Pro**
  (more storage), **Partial Copy** (config + sample data, 5-day refresh), **Full**
  (complete copy, 29-day refresh — use for UAT/performance/staging).
- **Deployment order of operations:** objects → fields → FLS (permsets) →
  automation → assignments. Get this wrong and the deploy fails on missing
  dependencies.
- **Use source-driven deploys** (SFDX / `sf project deploy`, DevOps Center) over
  Change Sets for repeatable, version-controlled metadata.
- **Run all `sf project ...` commands from the SFDX project root**, not the
  surrounding repo root, or they fail with *"InvalidProjectWorkspaceError"*.

**Common deployment traps:**
- **Connected App creation can be gated** by org policy — deploying a
  `connectedApp-meta.xml` may return *"You can't create a connected app…"*. The
  modern workaround is an **External Client App**; stage classic Connected App
  metadata for the day creation is unblocked.
- **External Client App Consumer Key is UI-only** — no Tooling/REST/metadata path
  exposes it; it's behind email verification in the SF UI.
- **Quick Action layout cache survives deploy + logout/login.** Adding fields to
  an existing Quick Action's `quickActionLayoutItems` via SFDX updates the
  metadata, but the runtime QA cache (driving Lightning contextual tabs via
  `console:relatedRecord`) often does **not** invalidate — the new fields are
  silently absent with no error. **Cache-bust by editing any non-field-list
  metadata** on the QA (`<description>`, `<label>`, `<layoutSectionStyle>`) and
  redeploying; SF treats it as a structural change and flushes the org-level
  cache.
- **Sandbox creation may need a Public Group** depending on org policy — a
  one-time setup step.

**Anti-patterns:** deploying fields without their FLS permset in the same change;
running `sf` from repo root; trusting a QA field-add without the cache-bust.

---

## 10. Reporting, dashboards & analytics

**Rules:**
- **Pick the right report type.** Standard for single-object; custom report types
  for cross-object and to expose lookup fields not in standard types.
- **Reporting Snapshots** capture report results to a custom object on a schedule
  — the only native way to trend point-in-time data (pipeline-over-time,
  backlog-over-weeks).
- **Dashboards run as a single "running user"** — every viewer sees that user's
  data visibility. Use a running user whose access matches the audience, or
  dynamic dashboards for per-viewer data.
- **Multi-currency** converts to the corporate currency in reports; be explicit
  about which currency a number is in.

**Anti-pattern:** a dashboard whose running user can see more than the audience
should → data leak.

---

## 11. AI & sales productivity features (know when to recommend, and the data prereqs)

**Rules:**
- **Einstein Lead/Opportunity Scoring needs history** — predictive models require
  a minimum volume of closed/converted records (hundreds+) to train. Don't
  recommend it for a low-volume org with no history.
- **Distinguish predictive AI** (scoring, forecasting — needs training data) from
  **generative AI** (Einstein Copilot, email drafting — needs grounding data and
  guardrails, not training history).
- **Sales Engagement (formerly High Velocity Sales)** = cadences/call lists for
  high-throughput SDR teams — overkill for a low-volume org.
- The judgment this domain tests is recognizing when *not* to recommend a
  heavyweight feature.

---

## Operational Rules Quick Reference

**DO:**
- Solve at the lowest-power tier: Validation Rule → Flow → Apex. Justify any code.
- Bulkify: query once into a Map, DML once. Respect 100 SOQL / 150 DML / 50k rows / 10k DML rows / 200 per trigger / 10s CPU.
- After any SFDX field deploy, add explicit `<fieldPermissions>` in a permset — SFDX field-meta grants FLS to no one.
- Omit required fields from `<fieldPermissions>` (deploy fails otherwise).
- Use unique `relationshipName` per parent object; suffix by role.
- Validate string lengths and picklist values against the field's real metadata; treat generated metadata constants as read-only.
- Use upsert + External ID for idempotent migrations; load parents/objects/FLS before children/data/assignments.
- Prefer permission sets over profile edits.
- Authorize an External Client App via ECA → Policies → App Policies → Select Permission Sets; verify via `PermissionSetAssignment` API.
- Run `sf project ...` from the SFDX project root, not the repo root.
- Cache-bust a Quick Action by editing `<description>`/`<label>` and redeploying.
- Verify FLS, assignments, and rendered tabs against the org, not just deploy success.

**DON'T:**
- Never put SOQL or DML inside a `for` loop, or assume `Trigger.new` has one record.
- Don't create new Workflow Rules or Process Builders (retired) — build Flows.
- Don't rely on Apex truncation to "handle" length — validate upstream.
- Don't hand-edit generated metadata-constant files.
- Don't use Master-Detail where the child must outlive the parent (audit records).
- Don't insert (vs. upsert) on a re-runnable migration.
- Don't set Public OWD on objects holding PII/sensitive data; never log PII.
- Don't trust a browser-AI "I assigned the permission" without an API check.
- Don't assume a Quick Action field-add rendered just because the deploy passed.
- Don't deploy fields without their FLS permset in the same change.

---

## 12. Territory Management & Forecasting

**Territory Management:**
- **Enterprise Territory Management (ETM)** is the current model (classic is legacy). ETM uses a hierarchy: Territory Types → Territory Models → Territories. Assignment rules auto-assign Accounts (and optionally Opportunities) by field criteria.
- **A territory model must be Activated** before it affects record access; only one model is active at a time. Test in Draft state, activate, roll back by activating a prior model.
- **Territories extend the sharing model** — a rep gains access to Accounts in their territory even if OWD is Private, without a sharing rule or role hierarchy change.

**Forecasting:**
- **Collaborative Forecasting** aggregates Opportunity amounts up the role/territory hierarchy. Configure which fields roll up (amount, quantity, revenue schedule).
- **Forecast Categories** are distinct from Stage — Stage is a pipeline position; Forecast Category is the rep's confidence bucket (Pipeline, Best Case, Commit, Closed). A category mismatch corrupts the forecast. Review and correct in: Setup → Forecast Settings → Opportunity Stages.
- **Adjustments** (manager overrides on a subordinate's forecast number) do not change the underlying Opportunity data — they layer a delta on top. Useful for management confidence corrections without touching rep records.
- **Quota management** is separate from forecast — quotas are loaded via Data Loader or the Forecasting UI into the Forecasting Quotas data model.

---

## 13. Consulting Practices & Discovery

- Gather requirements as **business outcomes**, not features. Use a **fit/gap matrix**: standard (no build) → configuration → custom (Apex/integration). Tilt toward standard to reduce maintenance burden.
- Distinguish **current-state pain** from **future-state requirements** to prevent scope creep.
- **Phase 1 = core + adoption.** A lean launch with high adoption beats a full launch with low adoption. Training and enablement are deliverables, not afterthoughts.
- **Define success metrics up front** (pipeline coverage ratio, lead conversion rate, forecast accuracy) — no agreed metrics means no objective project completion criterion.

---

## Decision scenarios

**Scenario 1 — Automation tool selection (Flow vs. Apex)**

> **Situation:** A client wants to automatically create a follow-up Task and update three fields on an Opportunity when the Stage changes to "Negotiation." A developer on the team suggests writing an Apex trigger because "it's more reliable."
>
> **Competent move:** Build a record-triggered Flow. A Stage change → create a child Task + update three fields on the same record is exactly what record-triggered Flow handles well. No bulk-unsafe anti-patterns are involved, and Flow is the strategic declarative tool. Apex is unjustified overhead here.
>
> **Tempting-but-wrong:** Agreeing that Apex is "more reliable" and coding a trigger. The reliability argument is a rationalization — for straightforward single-object updates and child-record creation at this scale, Flow and Apex are equally reliable. Adding Apex without a genuine need increases maintenance cost and violates the lowest-power-tier principle.
>
> **Verify:** Open Flow in Setup, confirm the record-triggered Flow runs After Save with the Stage-change entry condition, creates the Task via Create Records element, and updates the Opportunity fields. Test in sandbox with a single record and a bulk load of 200 to confirm governor-limit safety.

---

**Scenario 2 — Sharing model: Private OWD with lateral access**

> **Situation:** A B2B company has three regional sales teams. Each team should see only its own Accounts, but regional managers need to see all Accounts across all regions. The default "Public Read/Write" OWD is currently set.
>
> **Competent move:** Set Account OWD to **Private**. Assign reps to roles under their regional manager in the Role Hierarchy — managers automatically inherit access to subordinates' records. No sharing rules are needed for this structure because the Role Hierarchy alone provides the vertical access.
>
> **Tempting-but-wrong:** Leaving OWD at Public Read/Write and attempting to lock records down with validation rules or page-layout tricks. OWD is the floor — you cannot narrow access below it with anything other than OWD itself. Validation rules control writes, not visibility.
>
> **Verify:** Log in as a rep in Region A and confirm Region B Accounts are invisible. Log in as a regional manager and confirm all Accounts in their sub-hierarchy are visible. Check Setup → Sharing Settings → Account OWD.

---

**Scenario 3 — FLS after SFDX field deploy**

> **Situation:** A developer deploys a new custom currency field `Estimated_Budget__c` to Opportunity via `sf project deploy`. The field appears in Setup. Reps report they cannot see the field on records, and an integration user gets "Invalid field" on SOQL.
>
> **Competent move:** Deploy a Permission Set that includes `<fieldPermissions>` for `Estimated_Budget__c` with `readable: true` / `editable: true`, then assign the permset to the affected profiles/users. SFDX field-meta.xml creates the field but grants FLS to no one — not even System Administrator.
>
> **Tempting-but-wrong:** Re-deploying the field or opening a support case assuming the field is broken. The field itself is fine; the problem is FLS, a separate layer. Also wrong: editing the profile directly instead of using a permission set (profiles are being deprecated as the primary access vehicle).
>
> **Verify:** Run `SELECT Id, SObjectType, Field, PermissionsRead FROM FieldPermissions WHERE Field = 'Opportunity.Estimated_Budget__c'` in the org's Tooling API or query via Data Loader. Confirm the permset assignment via `SELECT AssigneeId, PermissionSetId FROM PermissionSetAssignment`.

---

**Scenario 4 — Forecast Category vs. Stage drift**

> **Situation:** Sales leadership complains that the Collaborative Forecast shows much higher revenue in "Commit" than deals actually close. A review of Opportunity Stages shows several Stage values (e.g., "Legal Review") map to the "Commit" Forecast Category despite being early-stage deals.
>
> **Competent move:** Audit and realign the Stage-to-ForecastCategory mapping in Setup → Opportunities → Fields → Stage → Stage Picklist Values. Remap "Legal Review" to "Best Case" or "Pipeline." Re-train reps that Forecast Category represents their confidence in closing, not just process position.
>
> **Tempting-but-wrong:** Adding more stages or building a complex Flow to auto-adjust Forecast Category at close. The root cause is misconfigured Stage metadata, not missing automation. Over-engineering the fix introduces new drift opportunities.
>
> **Verify:** Open a representative Opportunity in each Stage, hover the Forecast Category, and confirm it matches the intent. Pull a forecast report before and after the fix and compare "Commit" totals to actual prior-period close rates.

---

**Scenario 5 — Territory model activation**

> **Situation:** An administrator creates a new Enterprise Territory Management model with updated assignment rules, configures territories, and tests by manually checking Account assignments in the Draft model. She activates the model. Sales reps now report they can see Accounts that belong to other regions.
>
> **Competent move:** Review the territory assignment rules — specifically, look for overly broad criteria (e.g., a rule matching all Accounts with a non-null BillingCountry) that assign more records than intended. Correct the rules, run "Run Rules" on the model in Draft state, verify the assignment preview, then re-activate.
>
> **Tempting-but-wrong:** Changing the OWD to Private in a panic. OWD affects the sharing baseline for all access mechanisms; changing it to fix a territory rule misconfiguration can break other access paths (sharing rules, team access). Fix the territory rules, not the OWD.
>
> **Verify:** In ETM Setup, use the "Preview" feature before activating to see which Accounts each territory will claim. After fix, log in as a rep and confirm Account visibility matches their assigned territory only.

---

## Study resources & relevance

Study resources (official Salesforce + community) are kept in [references/study-resources.md](references/study-resources.md). For nonprofit/NPSP-specific operational guidance, see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md).

---
*Independent educational content to upskill AI agents. Not affiliated with or endorsed by Salesforce; all trademarks belong to their respective owners. "Salesforce," "Sales Cloud," "Einstein," "Flow," "Apex," and related marks are property of Salesforce, Inc., used here solely to identify subject matter. Guidance only — verify against official Salesforce documentation and live orgs before acting. No certification outcome is implied or guaranteed.*
