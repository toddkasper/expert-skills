---
name: salesforce-advanced-administrator
description: Advanced declarative Salesforce administration — the full sharing/security model (role hierarchy, owner/criteria sharing rules, muting and session-based permission sets), complex Flow automation and order-of-execution debugging, custom object and relationship design (master-detail, junctions, DLRS roll-ups), data management (Data Loader, duplicate/matching rules, External IDs), sandbox strategy, SFDX deployment, and auditing/monitoring (Setup Audit Trail, Field History, Event Monitoring). Use when designing or debugging org config beyond day-to-day admin. Not basic setup (see salesforce-administrator) or Apex/code (see salesforce-platform-developer-1). Scoped and benchmarked by the Advanced Administrator (Plat-Admn-301) blueprint.
metadata:
  anchor-credential: Salesforce Certified Advanced Administrator (Platform Administrator II)
  exam-code: Plat-Admn-301
  domain: salesforce
  type: certification-playbook
  status: current
  last-reviewed: 2026-06-10
  blueprint-verified: 2026-06-07
---

# Salesforce Advanced Administrator — Skills Reference

> This file is an **operational playbook**, not an exam outline. Each section states
> the rule as an actionable instruction, gives the real limit/number, tells you when to
> pick one tool over another, and flags the anti-patterns to catch in review. Read the
> **Operational Rules Quick Reference** near the bottom first.

## Overview

The Salesforce Certified Advanced Administrator (Salesforce Certified Platform Administrator II, exam code Plat-Admn-301) extends the Administrator credential into complex declarative problem-solving: full sharing and security, advanced Flow and approval automation, custom object design, deployment pipelines, and org-health monitoring.

> **Load this skill when…** designing or debugging the full sharing/security model (OWD, role hierarchy, sharing rules, muting permsets, session-based permsets); debugging Flow order-of-execution or recursion bugs; planning SFDX deployment pipelines or sandbox strategy; setting up auditing (Field History, Event Monitoring, debug logs).
> **Not this skill:** day-to-day org config, basic profiles/permsets, simple Flow builds → see `salesforce-administrator`; Apex triggers, SOQL, code review → see `salesforce-platform-developer-1`.

> Study resources: [references/study-resources.md](references/study-resources.md). NPSP applications: [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md). Org-specific rules: per-org appendix in your project CLAUDE.md.

> **Verify steps assume nothing about your tooling** — use your project's Salesforce MCP connection, the Salesforce CLI (`sf`), or the Salesforce setup UI, in that order of preference. The SOQL and describe calls below are written to work through any of them.

---

Credential logistics and study path: see [references/study-resources.md](references/study-resources.md).

---

## Uncertainty & Escalation

- **Always re-verify live:** governor limit numbers `[volatile — verify live]`; sandbox refresh intervals and storage quotas `[volatile — verify live]`; Field History retention windows `[volatile — verify live]`; feature availability and retirement dates (e.g. Workflow Rules/Process Builder retirement); any cap or quota cited in this skill.
- **Live wins:** if any rule or number in this skill conflicts with what the live org or Salesforce release notes show, the live org is authoritative. Log the discrepancy immediately using the Feedback protocol below, then act on what you observed.
- **Escalate to a human before proceeding:** OWD changes in a production org; any sharing rule addition/removal that broadens access to PII or financial data in production; mass-update or hard-delete on production data (>1k rows); deactivating managed-package automation in production without a sandbox-validated test; any Event Monitoring or Transaction Security policy change that could affect compliance logging.
- **Confidence taxonomy:** facts in this skill are stable unless tagged `[volatile — verify live]` or `[opinion — house style]`. When in doubt, query the org directly before acting.

---

## Security and Access — Operational Knowledge

**Access is additive-only.** The stack: OWD (baseline) → role hierarchy → sharing rules → manual/Apex sharing. Every layer only *widens* access. To restrict, lower the OWD — sharing rules cannot take access away.

**FLS ≠ object access ≠ record access — three independent gates.** Full object Read + `INVALID_FIELD` on a query = FLS not granted. Verify all three when access fails.

- **SFDX `field-meta.xml` grants FLS to no one.** Deploy a `<fieldPermissions>` entry in a permset/profile alongside every new custom field or every query returns *"Invalid field"* — including for System Administrator.
- **Omit required fields from `<fieldPermissions>`.** Deploy fails: *"You cannot deploy to a required field."*
- **Page layouts do not enforce security.** Removing a field from a layout still lets the API, reports, and SOQL return it if FLS allows. Use FLS for security, layouts for UX.

**Decision table — profiles vs. permission sets vs. permission set groups:**

| Need | Use | Why |
|---|---|---|
| Org-wide baseline (login hours, IP ranges, default record type, one profile per user) | Profile | Exactly one profile per user; it's the floor |
| Grant extra access to a subset of users (an API user, staff reporting fields) | Permission Set | Additive, reusable, assign many per user |
| Bundle 5+ permsets for a job role | Permission Set Group | Aggregates permsets; use Muting Permission Sets to subtract |
| Elevated access only during a verified/MFA session | Session-based permission set | Time-boxed privilege escalation |

Salesforce's strategic direction: **permission-set-first** — new grants in permsets, thin profiles.

**Key limits:** Field History Tracking ≤ 20 fields/object `[volatile — verify live]`. Approval steps ≤ 30 `[volatile — verify live]`.

**Red flags:**
- New SFDX field with no `<fieldPermissions>` → silently fails every query. Catch in every field-add PR.
- "Grant access via hierarchies" ON for a Lookup object when silos are required — managers inherit access they shouldn't.
- ECA FLS edited on the classic Permission Set "Assigned Connected Apps" page → does **not** authorize ECA usage. Correct path: ECA detail → Policies → Edit → App Policies → Select Permission Sets.

**Verify against the live org:**
- Describe the object (MCP / `sf sobject describe --sobject <object>` / Object Manager) — if the field is absent from the output, FLS is missing.
- `SELECT Id,Field__c FROM Obj__c LIMIT 1` (MCP / `sf data query` / Developer Console) → `INVALID_FIELD` = FLS problem, not object access.
- Confirm permset assignment: `SELECT Id FROM PermissionSetAssignment WHERE AssigneeId='…' AND PermissionSet.Name='…'` (MCP / `sf data query` / Developer Console) — never trust a UI toast, especially for ECA.

---

## Objects and Applications — Operational Knowledge

**Pick the relationship type by the lifecycle and reporting you need, not by habit:**

| Relationship | Use when | Consequences |
|---|---|---|
| Master-Detail | Child can't exist without parent; you need roll-up summaries; child shares parent's sharing | Cascade delete; child inherits OWD/sharing; max 2 MD per object; reparenting off by default |
| Lookup | Records are independent; either side can exist alone | No roll-up summary (need DLRS/Apex/flow); independent sharing; can be required or optional |
| Junction (2 MD) | True many-to-many (e.g. Person A ↔ Person B relationships, donor soft credits) | First MD = primary (controls detail's ownership/sharing); deleting either master deletes the junction |

- **Roll-up summaries only exist on the Master of a Master-Detail** (SUM/COUNT/MIN/MAX). For Lookups: DLRS, record-triggered flow, or Apex.
- **Lookup `relationshipName` must be unique per parent.** Duplicate name → deploy fails. SOQL traversal keys on the field name (`Parent_Object__r.Name`), so renaming the `relationshipName` is safe.
- **Record Types** drive picklist values + page layout + business process per type.
- **Dynamic Forms** move fields/sections onto the Lightning record page with component-level visibility — modern replacement for layout-driven UX.

**Red flags:**
- Converting Lookup → Master-Detail when any child has a null parent — conversion fails until every child has a parent. Backfill first.
- Expecting a roll-up summary on a Lookup — it doesn't exist.
- Adding fields to a Quick Action and trusting they render — the runtime QA cache on Lightning tabs (`console:relatedRecord`) doesn't invalidate on deploy. **Cache-bust:** edit any non-field-list metadata (`<description>`, `<label>`, or `<layoutSectionStyle>`) and redeploy.

**Verify against the live org:**
- List the org's objects (your Salesforce MCP, `sf sobject list`, or Setup → Object Manager) to confirm an object's API name before referencing it.
- Describe the object (MCP / `sf sobject describe` / Object Manager) to read relationship fields, `relationshipName`s, and picklist values before writing SOQL or a flow that traverses them.

---

## Process Automation — Operational Knowledge

**Memorize the order of execution — most automation bugs are an ordering surprise:**

1. Load record / apply old values → 2. System validation → 3. **Before-save flows** → 4. **Before-save Apex** → 5. Validation rules → 6. Duplicate rules → 7. Save to DB (not committed) → 8. **After-save Apex** → 9. Assignment rules / auto-response / workflow rules (legacy) → 10. **Workflow field updates re-fire before-/after-update triggers** (main recursion source) → 11. **After-save flows** → 12. Roll-up recalculation on parent → 13. Criteria-based sharing recalc → 14. Commit; post-commit (emails, async, platform events)

**Tool selection — pick the cheapest tool that does the job:**

| Need | Use | Don't use |
|---|---|---|
| Block bad data at save | Validation rule | A flow (slower, can't stop save as cleanly) |
| Set a field on the *same* record at save | **Before-save record-triggered flow** | After-save flow (extra DML, slower, recursion risk) |
| Update *related* records / send email / call Apex | After-save record-triggered flow | Before-save (can't do related-record DML) |
| Compute a value read-only | Formula field | Any automation (no storage, no recompute cost) |
| Complex branching, bulk loops, callouts, >limits | Apex trigger / invocable | Stacked flows that blow CPU/SOQL limits |
| Multi-user, long-running, multi-stage | Flow Orchestration | A single mega-flow |

**Bulkify.** Never put SOQL/DML inside a loop (Get/Update inside a Flow loop = same problem). Query once into a collection, work in memory, one DML after the loop. **Limits:** 100 SOQL, 50k rows, 150 DML, 10k DML rows, 10s CPU (60s async), 6 MB heap, 100 callouts `[volatile — verify live]`.

- **Approval processes do NOT run validation rules on submission.** Gate entry with approval entry criteria, not validation rules.
- **Before-save flows = cheapest same-record update** — no extra DML, runs before commit.
- **Workflow Rules and Process Builder reached end of support Dec 31 2025** — Salesforce no longer provides support or bug fixes; existing active rules still execute. Build all new automation in Flow and migrate legacy ones.

**Red flags:**
- Get/Update/Create **inside a flow loop** → SOQL/DML limits on bulk loads. Move outside; operate on a collection.
- **Recursion:** after-save flow updates the record it fired on, no guard → infinite loop. Use before-save, `ISCHANGED` entry condition, or a static guard.
- **Workflow field updates re-trigger triggers/flows** (step 10) — source of double-fires.
- Automation reads a field with no FLS for the running user → silently reads null. Pattern: "works for admins, breaks for others."
- **Check ALL automation (incl. managed-package namespace) before blaming your own code.** NPSP `npe01` workflow overwrites `Phone → MobilePhone` on insert based on `PreferredPhone__c`. Use a debug log trace flag to find the actual writer.

**Verify against the live org:**
- Use an Apex debug log (set a trace flag on the user) to see *every* automation that touches
  a record during DML — this is how a hidden managed-package overwrite gets caught.
- Run a SOQL query (MCP / `sf data query` / Developer Console) before/after a test write to confirm a flow set the field you expect (and didn't clobber another).

Deep dive — Approval Process quirks and Territory Management: [references/approval-territory.md](references/approval-territory.md) — load when configuring multi-step approvals, record-lock automation collisions, or Enterprise Territory Management.

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
| Data Loader | up to ~5M (Bulk API 1.0) / up to ~150M (Bulk API 2.0) `[volatile — verify live]` | **All** objects incl. Opportunities | Large volume, CLI/batch, upsert via External ID |

Some managed packages provide a purpose-built import tool that enforces their data model (e.g. NPSP Data Importer/BDI for Contact/Account/Opp with Household matching — see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md)).

- **Upsert by External ID** is the pattern for idempotent re-linking — late-arriving records re-attach to an existing parent without new write logic.
- **File vs. data storage are separate quotas.** Keep large file contents in external storage; store only the reference key in SF. (~2 KB/record regardless of field count.)
- **Advanced reporting:** custom report types (non-standard object shapes, Lookup children), cross-filters (WITH/WITHOUT), bucket fields, summary formulas. Reporting snapshots for trends; historical trending ≤ 8 fields / 3 months; dashboard filters max 3.

**Red flags:**
- Trying to import Opportunities via Data Import Wizard — unsupported; use Data Loader (or a package-specific tool if one is available).
- A "duplicate rule" that has no matching rule, or vice versa — neither works alone.
- Bulk-loading records into a package-managed org without honoring the package's matching logic — can create duplicates (e.g. NPSP Household deduplication).

**Verify against the live org:**
- Run the report (your Salesforce MCP, the Reports tab, or the Analytics/reports REST API) to pull its output before changing its definition.
- Query the matching records (MCP / `sf data query` / a list view) to confirm a record exists / matched before an upsert.
- Run a `COUNT()` query (MCP / `sf data query` / Developer Console) to sanity-check row counts pre/post import.

---

## Auditing and Monitoring — Operational Knowledge

**Know which log answers which question, and its retention:**

| Question | Tool | Retention |
|---|---|---|
| Who changed a setup/metadata setting? | Setup Audit Trail (downloadable CSV) | 6 months (180 days) `[volatile — verify live]` |
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

**Red flags:**
- Relying on debug logs for forensics days later — they roll off in ~24h. Turn on Field
  History or Event Monitoring *before* you need the history.
- Enabling Field History on a 21st field — silently capped at 20/object.

**Verify against the live org:**
- Describe the object (MCP / `sf sobject describe` / Object Manager) to confirm which fields have history tracking enabled before promising an audit trail exists.
- Run `SELECT … FROM Obj__History WHERE …` (MCP / `sf data query` / Developer Console) to read tracked changes directly.

---

## Environment Management and Deployment — Operational Knowledge

**Sandbox selection by data need and refresh cadence:**

| Sandbox | Data | Refresh interval | Use for |
|---|---|---|---|
| Developer | Metadata only | 1 day | Dev/unit work |
| Developer Pro | Metadata only, larger storage | 1 day | Bigger dev datasets |
| Partial Copy | Metadata + sample data (template) | 5 days `[volatile — verify live]` | Integration/UAT with representative data |
| Full | Metadata + ALL data | 29 days `[volatile — verify live]` | Staging, perf, final pre-prod validation |

**Deployment-tool decision:**
- **SFDX / SF CLI** — source-driven, version-controlled, scriptable, can delete. `sf project deploy start`. **Run from the SFDX project root** — running from the repo root gives *InvalidProjectWorkspaceError*.
- **Change Sets** — UI-only, point-to-point, **cannot delete**, not version-controlled. Use only when SFDX is unavailable.
- **Code coverage gate:** production Apex deploys require **≥75% org-wide** coverage and **>0% per trigger**.

**Red flags:**
- Deploy references a component not yet in the target org → missing-reference failure. Order: object → field → permset → layout.
- Assuming SFDX `field-meta.xml` carries FLS — it does not (see Security). Deploy the permset alongside.
- **Connected App creation gated** in modern orgs — `connectedApp-meta.xml` may return *"You can't create a connected app."* Workaround: use an **External Client App (ECA)**.
- **ECA Consumer Key is UI-only** — no scriptable path; behind email verification in the SF UI.

**Verify before/after a deploy:**
- Run a JWT-bearer smoke test (auth → describe → upsert idempotency → cleanup) to catch every
  gotcha above at the layer it bites.
- Describe the object post-deploy (MCP / `sf sobject describe` / Object Manager) to confirm the new field is API-visible (proves FLS landed, not just the field).
- Query a known record (MCP / `sf data query` / Developer Console) to confirm the field is selectable, not `INVALID_FIELD`.

---

## Cloud Applications — Operational Knowledge

Sales Cloud (Price Books, schedules, Opportunity splits, Collaborative Forecasting), Service Cloud (Knowledge, Entitlements/Milestones, Omni-Channel), and Experience Cloud (site types, Experience Builder, member profiles, Audience Targeting) shape: [references/cloud-applications.md](references/cloud-applications.md) — load when configuring multi-cloud features or Experience Cloud portals.

---

## Executable Workflows

### 1. Change a sharing model safely (OWD → role hierarchy → sharing rules → verify row visibility per persona)

1. In a sandbox, document the current OWD for the object and the personas (roles/groups) that need access.
   → **gate:** run `SELECT SobjectType, DefaultAccess FROM OrgWideDefault` (or Setup → Sharing Settings) to capture the baseline before any change.
2. Tighten or loosen the OWD under Setup → Sharing Settings for the target object.
   → **gate:** sharing recalculation may take minutes; confirm the sharing job completed (Setup → Sharing Settings → Recalculate if needed).
3. Add or adjust sharing rules to re-open access for the correct groups/roles above the new OWD floor.
   → **gate:** as a test user in each affected persona, run `SELECT Id FROM <Object__c>` and confirm the expected rows are returned.
4. Verify no unintended access: as a user who should be excluded, run the same query and confirm they cannot see restricted records.
   → **gate:** zero rows (or only owned records) returned for excluded persona.
5. If results look correct in sandbox, promote the change to production. Monitor Setup Audit Trail for the OWD change event.
   → **gate:** Setup Audit Trail shows the OWD change; re-run persona spot-checks in production.

---

### 2. Bulk data load with automation/TDTM disabled → load → re-enable → recalculate rollups

1. Identify which automation (flows, workflow rules, NPSP TDTM triggers) fires on the target object. In a sandbox, disable each: deactivate flows/workflow rules; for NPSP, use NPSP Settings → disable TDTM triggers or set a custom setting flag.
   → **gate:** test-insert one record in the sandbox and confirm no automation fires (no field changes, no child records created).
2. Run the bulk load (Data Loader upsert with External ID, or NPSP Data Importer for NPSP objects). Use `--serial` mode if DML lock contention is expected.
   → **gate:** Data Loader success file shows expected row count; error file is empty or contains only expected failures.
3. Spot-check a sample of loaded records: `SELECT Id, <key fields> FROM <Object__c> WHERE ExternalId__c IN (:sampleIds)` — confirm field values landed correctly.
   → **gate:** no truncation, no blank required fields, parent lookups resolved.
4. Re-enable automation in reverse order (TDTM first if NPSP, then flows, then workflow rules).
   → **gate:** test-insert one more record and confirm automation fires as expected.
5. Recalculate rollup summaries: for DLRS rollups, run the DLRS recalculate batch; for master-detail roll-up summary fields, they recalculate on the next save; trigger a batch update if immediate recalc is needed.
   → **gate:** sample parent records show correct SUM/COUNT values matching the loaded children.

---

### 3. Promote metadata sandbox → prod with a validation-only deploy first

1. From the SFDX project root, run `sf project deploy start --dry-run --target-org <prod alias>` (validation-only deploy).
   → **gate:** validation completes with `Deploy Succeeded (Validation Only)` — no component errors; coverage gate (≥75%) passes.
2. Review the validation output for any warnings (missing dependencies, FLS gaps). Resolve in the source branch before proceeding.
   → **gate:** zero errors and zero unexpected warnings in the validation report.
3. Run the actual deploy: `sf project deploy start --target-org <prod alias>`.
   → **gate:** `Deploy Succeeded`; confirm component count matches the validation run.
4. Post-deploy, describe the object for a key new/changed field: `sf sobject describe --sobject <object> --target-org <prod alias>` and confirm the field is API-visible (proves FLS landed).
   → **gate:** field appears in describe output with `updateable: true` (or `nillable: true` for optional fields).
5. Run a SOQL smoke test against a known prod record: `SELECT <newField__c> FROM <Object__c> LIMIT 1`.
   → **gate:** no `INVALID_FIELD` error; field returns a value or null (not an exception).

---

## Decision Scenarios

Operational judgment checks covering high-value gotchas. Scenarios 1 and 2 are here; Scenarios 3–5 are in [references/scenarios.md](references/scenarios.md) — load when diagnosing sharing-model tightening, Lookup-to-rollup gaps, or Flow recursion bugs.

---

**Scenario 1 — The invisible field after deployment**

> **Situation:** A developer deploys a new `Restricted_Notes__c` field on Contact via SFDX `sf project deploy start`. A sales rep immediately reports the field is missing from their SOQL query results; no error, just absent. A System Administrator can also not SELECT it in a workbench query.
>
> **Competent move:** Recognize that `field-meta.xml` deploys the field schema but grants FLS to nobody — including System Administrator. Deploy a permission set that includes a `<fieldPermissions>` entry for the field (readable + editable as appropriate), then assign it or include it in a permission set group. Verify by describing the Contact object (MCP / `sf sobject describe --sobject Contact` / Object Manager) — the field should now appear in the field list for the running user.
>
> **Tempting-but-wrong:** Checking the page layout or assuming System Administrator bypasses FLS. System Admin *does* bypass most object/record security but **does not** bypass FLS for fields not in a profile/permset (this is a common misconception — FLS applies to all profiles including System Administrator unless explicitly granted).
>
> **Verify:** Run `SELECT Id, Restricted_Notes__c FROM Contact LIMIT 1` (MCP / `sf data query` / Developer Console) — transitions from `INVALID_FIELD` to a valid result once FLS is in place. Also describe the Contact object and confirm the field appears with `updateable: true`.

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
- **DON'T** import Opportunities via Data Import Wizard — use Data Loader (or a package-specific tool that supports Opportunities). Data Loader handles all objects and supports up to ~5M records via legacy Bulk API 1.0, or up to ~150M via Bulk API 2.0 `[volatile — verify live]`.
- **DO** upsert by External ID for idempotent re-linking; both a Matching Rule and a
  Duplicate Rule are required for de-dup.
- **DO** build new automation in Flow — Workflow Rules and Process Builder reached end of support Dec 31 2025 (existing rules still run; no support or bug fixes).
- **DO** keep large file contents in external storage, only a reference key in SF — file vs.
  data storage are separate quotas.
- **DO** run `sf project …` from the SFDX project root, not the repo root.
- **REMEMBER** Apex deploy gate: ≥75% org coverage, >0% per trigger.
- **DO** cache-bust a Quick Action by editing non-field metadata (`<description>`) when added
  fields don't render on Lightning tabs.
- **DON'T** rely on debug logs for forensics — they roll off in ~24h; enable Field History /
  Event Monitoring beforehand.
- **DO** run a JWT-bearer smoke test after any metadata/cert change and confirm by describing the object + querying a known record that new fields are API-visible.
- **DON'T** convert a Lookup to Master-Detail without first backfilling null parents — conversion fails until every child has a parent.
- **DO** use session-based permission sets for time-boxed privilege escalation (MFA-verified sessions).

---

## References

- [references/study-resources.md](references/study-resources.md) — credential logistics, exam weights, study path, official links.
- [references/scenarios.md](references/scenarios.md) — Scenarios 3–5 (sharing model tightening, DLRS vs. rollup summary on a Lookup, Flow recursion).
- [references/approval-territory.md](references/approval-territory.md) — deep dive on Approval Process quirks (record locking, delegated approvers, step ordering) and Enterprise Territory Management (model states, assignment rules, forecasting integration).
- [references/cloud-applications.md](references/cloud-applications.md) — Sales Cloud, Service Cloud, and Experience Cloud operational detail (Price Books, Entitlements, Omni-Channel, Experience Builder).

---

## Feedback protocol

Using this skill and hit a wall? If you find a claim contradicted by the live system or official docs, a missing rule that cost you a wrong attempt, or a decision this skill gave no criteria for — append an entry **in the moment** to `.skill-feedback/salesforce-advanced-administrator.md` at the project root (create it if absent):

`date | skill last-reviewed | claim or gap | what you observed instead | evidence (error text / doc URL / query output) | suggested fix`

These are harvested back into the skill via the learning loop. When the live system and this file disagree, trust the live system.

## Changelog

- **2026-06-10** — Cycle-4 curation (inbox): (1) Data Loader capacity corrected: import tool table and quick-ref now read "up to ~5M via Bulk API 1.0 / up to ~150M via Bulk API 2.0 [volatile — verify live]" — official Salesforce dev-limits cheatsheet and Data Loader guide confirm both figures for the two underlying APIs. (2) WFR/Process Builder wording corrected: "retired" replaced with "end of support Dec 31 2025; existing active rules still execute" in both the Process Automation section and Operational Rules Quick Reference — verified against https://help.salesforce.com/s/articleView?id=001096524.
- **2026-06-09** — Conformed to the 12-dimension skill standard: task-vocab description + Scope block, Uncertainty & Escalation guidance with inline `[volatile — verify live]` marks, executable workflows, tool-agnostic verify steps, and the feedback protocol above. Exam logistics relocated to references/study-resources.md; `last-reviewed` set to 2026-06-09.

## Disclaimer

Independent educational content to upskill AI agents. Not affiliated with, authorized by, endorsed by, or sponsored by Salesforce, Inc. or any certification body. "Salesforce," "Salesforce Certified Advanced Administrator," "Salesforce Certified Platform Administrator II," "Agentforce," "Einstein," "NPSP," and related marks are trademarks of Salesforce, Inc., used here solely to identify the subject matter. All other product names and brands are the property of their respective owners. Content is provided as-is, as guidance only — verify all rules, limits, and configuration steps against official Salesforce documentation and your live org before acting. Governor limits, blueprint weights, exam fees, and feature availability are subject to change at any time. No certification outcome is implied or guaranteed.
