# NPSP Deep Dive — Sections 3–15

Load-on-demand companion to [../SKILL.md](../SKILL.md). Contains the full operational detail for PART A (NP-Con-101 / NPSP) beyond the Data Model and Hard/Soft Credit sections that appear in SKILL.md.

---

## 3. Customizable Rollups (CRLP) — stale totals are a config problem, not magic

**Rule: rollup fields are calculated, not real-time after bulk loads.** CRLP recalculates on Opportunity DML in normal operation, but **bulk imports, TDTM handler disables, and data migrations leave rollups stale.** Always run **NPSP Settings → Bulk Data Processes → Recalculate Donor Statistics / Recalculate Rollups** after any bulk Opportunity/Payment load.

- Rollup operation types: Count, Sum, Average, Largest, Smallest, First, Last — plus time-bound filters (this year / last year / Years Ago N) that power LYBUNT/SYBUNT.
- RED FLAG: someone reports "the donor's total is wrong" right after a migration — the answer is almost always "recalculate rollups," not "the data is wrong."
- Verify a rollup is even configured before debugging its value: it's a `Rollup__mdt` custom-metadata record; check the source field actually feeds it.

---

## 4. Recurring Donations — Enhanced (ERD) vs legacy, status semantics

**Rule: know which format the org runs before touching Recurring Donations.** Enhanced Recurring Donations (ERD) is the modern model (`npe03__Recurring_Donation__c` with `RecurringType` = Open/Fixed, `Status` = Active/Lapsed/Closed/Paused). Legacy format is being retired. Decision matrix:

| Situation | Do |
|---|---|
| Donor giving until they stop | **Open-ended** schedule |
| Pledge of N installments | **Fixed-length** schedule |
| Donor card declined, want to keep the commitment | **Pause** (not Close) |
| Missed expected installment | NPSP sets **Lapsed** automatically |
| Donor cancelled for good | **Close** |

- ERD generates the **next** Opportunity, not all future ones — don't expect a year of Opportunities to exist up front.
- If standing up a donor module, confirm ERD (not legacy) is enabled before designing flows against it.

---

## 5. TDTM — NPSP's trigger framework, and the migration foot-gun

**Rule: TDTM is a table of trigger-handler records, not raw Apex triggers.** Each NPSP trigger is a `npsp__Trigger_Handler__c` row (object, class, load order, active flag). To customize NPSP behavior you insert a handler row; to speed up a bulk load you **deactivate** handlers, load, **reactivate**, then **recalculate rollups.**

- **Anti-pattern: bulk-loading 50k Contacts/Opportunities with all TDTM handlers active.** Each insert fires household creation, address mgmt, rollups, relationship mirroring — you'll blow governor limits and the load crawls. Disable handlers for the load window.
- **Anti-pattern: leaving handlers disabled after the load.** New records stop getting Household Accounts, rollups, reciprocal relationships. Always re-enable.
- Verify: run `SELECT Name, npsp__Object__c, npsp__Class__c, npsp__Active__c, npsp__Load_Order__c FROM npsp__Trigger_Handler__c ORDER BY npsp__Load_Order__c` via your Salesforce MCP/connection, or `sf data query --query "SELECT Name, npsp__Object__c, npsp__Class__c, npsp__Active__c, npsp__Load_Order__c FROM npsp__Trigger_Handler__c ORDER BY npsp__Load_Order__c"` (Salesforce CLI), or the Developer Console Query Editor.

---

## 6. Addresses — NPSP manages them on the Household, not the Contact

**Rule: in NPSP the Household Account owns the canonical address** via `npsp__Address__c` records; Contact address fields are synced down from the Primary Address. Editing a Contact's mailing address directly can be overwritten by the Address management TDTM handler. Seasonal Addresses (date-ranged) let snowbirds auto-swap Primary. Decision: change addresses on the Address object / Household, not the raw Contact field, unless Address management is disabled.

---

## 7. Governor limits you must respect in any Apex you write or review

These are the **synchronous** per-transaction limits:

| Limit | Value |
|---|---|
| SOQL queries | **100** |
| SOQL rows returned | **50,000** |
| DML statements | **150** |
| DML rows | **10,000** |
| CPU time | **10,000 ms** (60s async) |
| Heap | **6 MB** sync / 12 MB async |
| Callouts | 100 per transaction; 120s total |
| Future calls | 50 per transaction |

**Bulkify all DML and SOQL.** Never put `[SELECT …]`, `insert`, `update`, `upsert`, or `delete` inside a `for` loop. Query once into a `Map<Id, …>`, iterate in memory, collect into a `List`, DML once after the loop. **RED FLAG in review:** any SOQL or DML statement whose lexical position is inside a loop body — even "it's only a few records" fails when a batch arrives.

---

## 8. Field-Level Security is separate from object access

**Rule: granting object access does NOT grant field access.** A user/permset with full read/edit on an object still gets *"Invalid field"* on SOQL/page layout for any field whose FLS isn't explicitly granted. **SFDX `field-meta.xml` deploys carry NO FLS** — a freshly deployed custom field is visible to **no one, not even System Administrator,** until a profile or permission set lists `<fieldPermissions>` for it.

- When adding a custom field via SFDX, you must also add it to a permission set's `<fieldPermissions>` block (or it's invisible).
- **Required fields must be OMITTED from `<fieldPermissions>`.** Salesforce rejects the permset deploy with *"You cannot deploy to a required field"* — required fields are always visible/editable, so listing them errors.
- Verify the assignment actually landed: query `PermissionSetAssignment` and the permset's `SetupEntityAccess` / field perms via the API, or just run a SOQL query for the field (MCP / `sf data query` / Developer Console) — if it returns, FLS is real.

---

## 9. Custom field length & picklist values must match the live org

**Rule: any form/Zod field that ultimately writes to a Salesforce field must use the real `max()` length and the real picklist enum from the org** — never a guessed number. If you maintain generated schema constants from the org, **never hand-edit them; regenerate** from the org when SF metadata changes and commit the result.

- **Anti-pattern: relying on Apex truncation as your length guard.** A defensive Apex truncation helper exists for legacy/direct-API records, but the form/integration layer must FAIL at validation rather than silently lose data. Truncation is a fallback, not a strategy.
- A restricted picklist rejects out-of-list values at the API layer — submitting one throws, it does not coerce.
- Verify: describe the `Contact` object (your Salesforce MCP, `sf sobject describe --sobject Contact`, or Setup → Object Manager → Contact → Fields & Relationships) — it returns each field's `length`, `type`, and for picklists the active `picklistValues` and `restrictedPicklist` flag. This is the source of truth.

---

## 10. Lookup `relationshipName` uniqueness

**Rule: two Lookup fields on the same object that target the same parent object cannot share a `relationshipName`** — deploy fails with *"Duplicate relationship name."* Use role-specific suffixes. SOQL parent traversal keys on the **field name** (e.g. `Parent_Object__r.Name`), not the relationshipName, so renaming the relationshipName later is safe and won't break queries.

---

## 11. Quick Action cache-bust

**Rule: adding fields to an existing Quick Action's `quickActionLayoutItems` via SFDX often does NOT invalidate the runtime QA cache** — even after browser logout/login the new fields are silently absent on Lightning contextual tabs (`console:relatedRecord`), with no error. **Fix: edit any non-field-list metadata on the QA (`<description>`, `<label>`, `<layoutSectionStyle>`) and redeploy.** Salesforce treats the structural change as meaningful and flushes the org-level QA cache. This is the go-to whenever a deployed QA field doesn't render.

---

## 12. Managed-package automation can silently mutate your data

**Rule: when a field's value changes unexpectedly, suspect managed-package workflow rules / TDTM before suspecting your own code.** A classic example: NPSP's `npe01` Contacts & Organizations package ships a workflow rule (`PhoneChanged_Mobile`) that copies `Phone → MobilePhone` when `npe01__PreferredPhone__c = "Mobile"` — and NPSP defaults that picklist to "Mobile" on every Contact insert, so a custom `Phone` write can overwrite `MobilePhone` unexpectedly. Diagnose with an Apex debug-log probe in **sandbox**, then deactivate the offending workflow rule (admin-supported even on managed packages). RED FLAG: "my insert sets field X but it reads back different" → trace the debug log for package-namespaced automation.

---

## 13. Data import tool selection

| Need | Tool | Limit / why |
|---|---|---|
| Load Contacts/Opps/GAU/Recurring into NPSP correctly (creates Households) | **NPSP Data Import** | Purpose-built; dry-run mode; handles account model |
| Generic object, < 50k records, no Household logic | Data Import Wizard | 50,000-record cap |
| > 50k records, hard delete, scripted/CLI, External-ID upsert | Data Loader | No 50k cap; supports upsert keys |
| Recover a failed integration submission into NPSP | NPSP Data Import (one CSV row) | NPSP-aware recovery path |

**Rule: use External ID fields as upsert keys for any recurring integration**, so re-runs update instead of duplicating. A stable external-ID idempotency key also lets late/secondary writes (e.g. a deferred document attachment) re-link to the existing record with no new write logic.

---

## 14. Duplicate management with the Household model

**Rule: standard Duplicate/Matching Rules are complicated by Households** because many real people share a household address. Match Contacts on a stable combination (e.g. **email + birthdate**), not on name+address alone. RED FLAG: a matching rule keyed on address alone will collapse spouses into one Contact. Verify candidate dupes by querying matching Contacts (MCP / `sf data query` / a list view) before any merge.

---

## 15. Analytics — recognize the right report, know LYBUNT/SYBUNT

- **LYBUNT** = gave **L**ast **Y**ear **B**ut **U**nfortunately **N**ot **T**his year. **SYBUNT** = gave **S**ome **Y**ear But not this year. Both are donor-retention/lapse reports built from time-bound giving rollups.
- Run the report (your Salesforce MCP, the Reports tab, or the Analytics/reports REST API), or run a SOQL query with date filters (MCP / `sf data query` / Developer Console) for ad-hoc retention math, rather than rebuilding report types blindly.
- Decision: standard Reports/Dashboards for internal KPIs; CRM Analytics/Tableau only when you need blended data sources or external-stakeholder dashboards — don't recommend the heavier tool for a small nonprofit's basic fundraising KPIs.

---

## 16. Experience Cloud / external portals on an NPSP org

External-facing portals (donor, volunteer, program-participant) layer Experience Cloud on top of the NPSP data model. The general external-sharing discipline (CRUD + FLS + OWD + sharing set/share group, guest-user hardening) lives in [salesforce-experience-cloud-consultant](../../salesforce-experience-cloud-consultant/SKILL.md); the NPSP-specific deltas are:

- **License tier:** for a nonprofit portal, default to the **Experience Cloud for Nonprofits** tier (not standard Customer/Partner Community) and confirm the NPSP objects you need are license-exposed **before** designing the sharing model — an object the license doesn't expose can't be shared into the portal no matter how the sharing set is built.
- **Donor Portal sharing set — key on the Household, not the Contact.** A donor's gifts are Opportunities whose primary contact is reached via `Opportunity.npe01__Contact_Opp_For__r`. Because the Household Account model creates **one Account per household**, configure the sharing set against the **Household Account**, not the Contact, or spouses won't see shared household giving. Also in scope: `npe01__OppPayment__c` (payments), Enhanced Recurring Donations (RD2), and soft-credit/household roll-ups. **Verify:** describe `Opportunity` to confirm the `npe01__Contact_Opp_For__r` lookup path before building the sharing set.
- **Volunteer Portal (Volunteers for Salesforce / V4SF):** the objects `Volunteer_Job__c`, `Volunteer_Shift__c`, `Volunteer_Hours__c` get the **same** CRUD + FLS + sharing-set discipline as any external-user scenario — being managed-package objects does not exempt them from the external-access layers.
- **Program-participant access (Nonprofit Case Management / NCCM):** maps to the Customer Account Portal template + self-registration so participants can view referrals and update their own contact info.

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
