# Application tasks — salesforce-nonprofit-cloud-consultant (Lens 4, held-out)

A skilled agent produces the artifact; a judge grades against the trap-keyed rubric. Run baseline vs skilled.

---

## Task 1 — Bulk gift import design and TDTM / rollup trap review

**Prompt to the agent:** A nonprofit is migrating 15,000 historical donation records from a legacy database into their NPSP org. The data migration lead has shared the import plan below. Review it, redline every error, and produce a corrected import runbook the team can execute safely.

**Spec (flawed — embedded traps):**

> **Tool choice:**
> - The team will use the Data Import Wizard to load all 15,000 Opportunity records, matching donors by `Email` on the Contact object.
>
> **TDTM handling:**
> - TDTM trigger handlers will be left **active** during the load to ensure "all NPSP logic fires correctly and rollups are kept current during the import."
>
> **Hard and soft credit:**
> - Each gift in the source file has one donor (hard credit). For 3,200 of the gifts, a board member also gets soft credit because they facilitated the donation. The team plans to load two Opportunity records per facilitated gift: one for the donor (hard credit) and one for the board member (soft credit), both with `Amount` populated.
>
> **Rollup verification:**
> - After the import, the team will verify rollup totals by running a summary report on Contacts summing `npo02__TotalOppAmount__c`. They consider this sufficient to confirm the import is complete.
>
> **Contact matching:**
> - The Data Import Wizard will match Contacts by Email. If no match is found, a new Contact (and Household Account) will be created automatically.
>
> **Post-import:**
> - The team does not plan to run "Recalculate Rollups" after the import because "TDTM was active so rollups should already be correct."

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — Data Import Wizard does not support bulk Opportunity import for NPSP orgs; it bypasses NPSP's gift-entry logic (TDTM, Household Account assignment, OCR creation). The correct tool for bulk gift import in NPSP is **Data Loader** (which calls the standard API and TDTM fires) or **Batch Gift Entry** (BGE) for staff-entered gifts. Agent must flag the wrong tool and prescribe Data Loader with TDTM enabled or BGE.
- [ ] Trap 2 — Leaving TDTM active during a bulk Data Loader import will cause each inserted Opportunity to fire all TDTM handlers synchronously, consuming governor limits (SOQL, DML) per record. On large loads (15,000 records) this will result in governor limit exceptions and partial failures. The correct approach is to **disable TDTM handlers** during the bulk load (via `TDTM_Config_API` or the NPSP Settings UI trigger disable) and then run Recalculate Rollups and re-enable handlers after the load completes. Agent must prescribe the disable-import-enable-recalculate sequence.
- [ ] Trap 3 — Loading two Opportunity records per facilitated gift (one for hard credit, one for soft credit) with Amount on both will **double-count** the gift in any report summing Opportunity Amount. Soft credit in NPSP is handled via the **Opportunity Contact Role** (OCR) with Role = "Soft Credit" (or a custom soft-credit role), NOT via a separate Opportunity record. The existing Opportunity carries the hard credit; an OCR on the same Opportunity carries the soft credit. Agent must flag the double-count and prescribe OCR-based soft credit.
- [ ] Trap 4 — Verifying rollup totals via a report on `npo02__TotalOppAmount__c` immediately after an import where TDTM was disabled will show **stale or zero totals** because rollup recalculation has not yet run. The report reflects cached rollup field values, not live Opportunity sums. Agent must note that the report is not a valid verification method until after Recalculate Rollups completes, and recommend a cross-check SOQL query against live Opportunity amounts as the true verification.
- [ ] Trap 5 — Email-based Contact matching will create duplicate Contacts when the legacy database has multiple donors with the same email (family members, shared inboxes) or when the email field is blank. Agent must flag the risk of duplicate Household Accounts being created and recommend using an External ID field (populated from the legacy system's donor ID) as the primary match key, with Email as a secondary.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Tool correction: use Data Loader targeting the Opportunity object with standard API; for staff-entered gifts use BGE; document why Data Import Wizard is wrong for NPSP.
- TDTM sequence: (1) disable relevant TDTM handlers in NPSP Settings, (2) load via Data Loader, (3) re-enable handlers, (4) run Recalculate Rollups from NPSP Settings, (5) verify with SOQL cross-check.
- Soft credit via OCR: single Opportunity per gift; add OCR record with `ContactId` = board member, `Role` = "Soft Credit," `IsPrimary` = false; NPSP recognizes this for soft-credit rollup fields (`npo02__Soft_Credit_Total__c`).
- Rollup verification: SOQL `SELECT SUM(Amount) FROM Opportunity WHERE ... GROUP BY AccountId` cross-checked against `npo02__TotalOppAmount__c` after recalculation.
- Matching key: add `Legacy_Donor_ID__c` External ID field to Contact; use as primary match key in Data Loader upsert.

---

## Task 2 — NPSP vs. NPC determination and recurring gift configuration

**Prompt to the agent:** A new client engagement has started. The client says they "have Salesforce for nonprofits" and wants to set up a monthly recurring giving program. Before configuring anything, you need to determine which nonprofit data model is running in the org and then produce the correct configuration steps for recurring gifts — including the traps that cause double-counting or stale rollups.

**Spec (flawed — embedded traps):**

> **Org determination (client's description):**
> - The client's admin says: "We have the NPSP package — we can see `npo02__`, `npe01__`, and `npsp__` namespace objects. But we also see a `Gift__c` object and an `ActionPlan__c` object with no namespace."
> - The admin concludes: "We must be running both NPSP and Nonprofit Cloud simultaneously on the same org."
>
> **Recurring gift setup (what the admin plans to do):**
> - To create a monthly recurring gift for a major donor, the admin plans to create a `npe03__Recurring_Donation__c` record (the classic NPSP RD object) with `npe03__Amount__c` = $100 and `npe03__Installment_Period__c` = "Monthly."
> - They also plan to create one `Opportunity` record manually for the first installment so the donor sees an immediate gift on their record — reasoning: "The recurring donation won't create the first Opportunity fast enough."
>
> **Rollup configuration:**
> - After the recurring donation is saved, the admin notices `npo02__TotalOppAmount__c` on the donor's Contact does not immediately reflect the first installment. They run a summary report summing `npo02__TotalOppAmount__c` to check. The report shows zero for this donor.
> - The admin concludes: "The rollup is broken and I need to create a new rollup field."
>
> **Enhanced Recurring Donations:**
> - The org has Enhanced Recurring Donations (ERD) enabled (confirmed via NPSP Settings). The admin is using the classic RD object (`npe03__Recurring_Donation__c`) for the new setup.

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — The presence of both NPSP namespaces (`npo02__`, `npe01__`, `npsp__`) AND namespace-free `Gift__c` and `ActionPlan__c` objects does NOT mean both NPSP and Nonprofit Cloud (Industries) are running simultaneously. A single org cannot run both managed packages at the same time. Namespace-free `Gift__c` is the Industries NPC Gift object, indicating this is an **NPC (Industries) org** where NPSP objects may be legacy remnants or migration artifacts, not an active dual-package org. Agent must flag this misconception and describe how to definitively determine which model is active (e.g., `sf sobject list` or Setup > Installed Packages).
- [ ] Trap 2 — If Enhanced Recurring Donations is enabled, the classic `npe03__Recurring_Donation__c` object is replaced by the Enhanced RD object (which uses the same API name but a different schema). Creating a record on `npe03__Recurring_Donation__c` with ERD enabled will use the Enhanced RD schema, which has different required fields and behavior than classic RDs. The admin must use the ERD-compatible fields (`npsp__Amount__c` on the enhanced schema, `Day_of_Month__c`, etc.) and understand that ERD auto-creates installment Opportunities on its own schedule. Agent must flag the ERD schema difference and correct field usage.
- [ ] Trap 3 — Manually creating a first installment Opportunity alongside an ERD record will result in a duplicate first-month Opportunity (ERD creates its own first installment automatically). This double-counts the first gift in rollup totals and in donor reporting. Agent must flag the manual-Opportunity plan as wrong and explain that ERD manages installment creation automatically.
- [ ] Trap 4 — `npo02__TotalOppAmount__c` is a **rollup field** updated by TDTM or Customizable Rollups, not a formula. If TDTM handlers were recently disabled (e.g., after a data migration) or Customizable Rollups has not processed the new record yet, the field will not reflect the new gift immediately. The admin's conclusion that "the rollup is broken" is premature; the correct diagnosis is to trigger a Recalculate Rollups run from NPSP Settings and then re-check. Agent must distinguish stale rollup from broken rollup and prescribe recalculation.
- [ ] Trap 5 — If the org is actually running NPC (Industries) — as suggested by `Gift__c` — then `npe03__Recurring_Donation__c` is not the correct object for recurring gifts; the NPC equivalent is `RecurringDonation__c` (or the Industries Gift Commitment object). Using NPSP RD objects on an NPC org will create orphaned records that NPC automation does not process. Agent must flag the object mismatch and recommend confirming the active model before creating any records.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Org determination: run `sf sobject list --target-org <alias>` or check Setup > Installed Packages; presence of `Gift__c` (no namespace) = NPC (Industries); `npe03__Recurring_Donation__c` active schema = NPSP. They cannot co-exist actively.
- ERD correct setup: use Enhanced Recurring Donation UI in NPSP (or the `npsp__RecurringDonation__c` enhanced fields); set `npsp__Day_of_Month__c`, `npsp__Amount__c`, and `npsp__StartDate__c`; ERD creates first installment automatically — do not pre-create.
- No manual first installment: document that ERD auto-generates installment Opportunities on the scheduled date; manual creation causes deduplication problems.
- Rollup recalculation: NPSP Settings > Bulk Data Processes > Recalculate Rollups; after completion, `npo02__TotalOppAmount__c` should reflect all posted Closed Won Opportunities.
- NPC path (if confirmed): use Gift Commitment record type in NPC; do not use `npe03__` namespace objects.
