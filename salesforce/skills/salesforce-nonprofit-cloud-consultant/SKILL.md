---
name: salesforce-nonprofit-cloud-consultant
description: Operational playbook for Salesforce nonprofit implementation across BOTH the NPSP managed package (Household Accounts, Relationships, Affiliations, hard/soft credit, TDTM, Customizable Rollups, Recurring Donations, LYBUNT/SYBUNT) and Industries-based Nonprofit Cloud (Gift, Program Management, Outcome Management, Grantmaking, OmniStudio, Action Plans, Care Plans, Data Processing Engine). Use when configuring or troubleshooting either model, or deciding which applies to a given org. The two nonprofit certifications (NP-Con-101 NPSP, NP-Con-102 NPC) are the scaffold and benchmark used to scope and measure this skill, not its subject.
metadata:
  credential: Salesforce Certified Nonprofit Cloud Consultant
  exam-codes: NP-Con-101, NP-Con-102
  domain: salesforce
  type: certification-playbook
---

# Salesforce Nonprofit Cloud Consultant — Skills Reference

> This file is an **operational playbook**, not an exam outline. It states the rules an AI agent applies at decision time on an NPSP / Nonprofit Cloud org: the actual rule, the real limits, the "when X → do Y" criteria, the red flags to catch in review, and how to verify against the live org (e.g. `describe_object`, `soql_query`, `list_objects`, `run_report`). All `describe_object` / `soql_query` reads are safe; any write/metadata change belongs in a sandbox, never Production.

## Overview

This file covers **two related but distinct** Salesforce certifications for nonprofit practitioners. Salesforce historically branded the nonprofit credential as "Nonprofit Cloud Consultant," but in **July 2025** the credential line was split and renamed. Both are **active** as of mid-2026:

- **NP-Con-101 — Salesforce Certified Nonprofit Success Pack Consultant.** This is the original exam, *renamed* in July 2025 (it was previously titled "Nonprofit Cloud Consultant"). It tests deep knowledge of the **NPSP managed package** — Household Accounts, Relationships, Affiliations, Recurring Donations, Engagement Plans, TDTM (Table-Driven Trigger Management), Customizable Rollups, and the classic NPSP data model. Target audience: implementers working with NPSP on any Salesforce edition.

- **NP-Con-102 — Salesforce Certified Nonprofit Cloud Consultant (NPC).** This is the newer exam, introduced alongside the July 2025 rename. It tests the **Salesforce Industries Nonprofit Cloud** platform solution — fundraising built on Industries objects, Program Management, Outcome Management, Grantmaking, OmniStudio, Action Plans, and Care Plans. Target audience: implementers delivering Nonprofit Cloud on Salesforce Industries.

Both exams once shared a single Trailhead credential page and are still discussed interchangeably in the community, which causes confusion. Read the official exam guide carefully to confirm which version you are registering for.

**Picking the right model at decision time:** an org running the **NPSP managed package** maps to **NP-Con-101**; an org running **Industries-based Nonprofit Cloud** maps to **NP-Con-102**. NPSP is the legacy model Salesforce is sunsetting in favor of Nonprofit Cloud over the coming years. **Default all operational decisions to the NPSP (101) model unless someone has confirmed Nonprofit Cloud / Industries is enabled** — verify with `list_objects`: NPSP objects carry `npe01__` / `npo02__` / `npsp__` / `npe4__` / `npe5__` namespaces, while NPC objects are namespace-free Industries standard objects like `Gift`, `Program`, and `ProgramEnrollment`.

> **Deeper context:** Study resources (official Salesforce + community, hands-on environments), the Relevance map, and full deep-dive operational detail live in:
> - [references/study-resources.md](references/study-resources.md) — study paths, links, certification sequence recommendation, exam-topic ↔ operational-rule relevance table
> - [references/npsp-deep-dive.md](references/npsp-deep-dive.md) — PART A detail: CRLP, ERD, TDTM, Addresses, Governor Limits, FLS, Custom Fields, Lookup uniqueness, QA cache, managed-pkg automation, Data Import, Duplicate management, Analytics
> - [references/nonprofit-cloud-industries.md](references/nonprofit-cloud-industries.md) — PART B detail: full NPC term-translation table, PSL gating, Program Management & Outcome objects, OmniStudio tool selection
>
> For org-specific applications, keep a per-org appendix in your own project, referenced from a CLAUDE.md.

---

## Exam Details

### NP-Con-101 — Salesforce Certified Nonprofit Success Pack Consultant

| Field | Value |
|---|---|
| Questions | 60 multiple-choice/multiple-select (plus up to 5 unscored) |
| Time Limit | 105 minutes |
| Passing Score | 67% (~40 of 60 scored questions) |
| Cost | $200 USD registration + applicable tax; $100 retake |
| Prerequisites | Salesforce Certified Administrator credential |
| Retake Policy | 1st retake after 1 day; 2nd+ after 14 days; max 3 attempts per release window |

Recommended experience: 2–5 years as a Salesforce Administrator or Consultant with hands-on NPSP implementation experience. Delivered as proctored online or in-person at a test center.

### NP-Con-102 — Salesforce Certified Nonprofit Cloud Consultant (NPC)

| Field | Value |
|---|---|
| Questions | 60 multiple-choice/multiple-select (plus up to 5 unscored) |
| Time Limit | 105 minutes |
| Passing Score | 64% (39 of 60 scored questions) |
| Cost | $200 USD registration + applicable tax; $100 retake |
| Prerequisites | Salesforce Certified Administrator credential |
| Retake Policy | 1st retake after 1 day; 2nd+ after 14 days; max 3 attempts per release window |

Recommended experience: 2–5 years implementing Salesforce solutions for nonprofits with Industries / Nonprofit Cloud hands-on experience. Delivered as proctored online or in-person at a test center.

---

# PART A — NPSP Operational Knowledge (NP-Con-101)

## 1. The NPSP Data Model — apply it, don't just recognize it

**Rule: every individual lives in a Household Account.** In the Household Account model (NPSP's current best practice), each `Contact` has an `AccountId` pointing to a Household `Account` (`npe01__SYSTEM_AccountType__c = "Household Account"`). One household can hold multiple Contacts (e.g. spouses). NPSP's `ACCT_IndividualAccounts_TDTM` handler auto-creates the Household Account on Contact insert if you don't supply one.

- **Never insert a Contact with a blank `AccountId` and then immediately re-parent it** — you'll create an orphan Household Account. Let NPSP create it, or set `npe01__Private__c` / the Account up front.
- **Account models are mutually exclusive and org-wide.** The three: Household Account (current best practice), 1×1 (one Account per Contact, deprecated), and Bucket/Individual (never recommend). Decision: for any new nonprofit → Household Account, always.
- **Relationship vs Affiliation — pick by "person or org?"**

  | You're linking… | Use | NPSP object |
  |---|---|---|
  | Contact ↔ Contact | **Relationship** | `npe4__Relationship__c` |
  | Contact ↔ Organization Account | **Affiliation** | `npe5__Affiliation__c` |

- **Relationships are reciprocal and auto-mirrored.** Creating a Husband→Wife Relationship makes NPSP create the Wife→Husband reverse via `REL_Relationships_TDTM`. **Do not hand-create both directions** — you'll get duplicate reverse records.
- **Verify:** `soql_query("SELECT npe01__SYSTEM_AccountType__c, COUNT(Id) FROM Account GROUP BY npe01__SYSTEM_AccountType__c")` to confirm the org's account model.

## 2. Hard Credit vs Soft Credit — the single most-tested NPSP concept

**Rule: hard credit = the donor of record; soft credit = recognition only.** Hard credit flows from the Opportunity's Primary `OpportunityContactRole` (OCR) and rolls up into the donor's lifetime giving totals (`npo02__TotalOppAmount__c` etc.). Soft credit is recognition for someone who influenced the gift and rolls up **separately** into soft-credit fields — it must **never** double-count into hard-credit totals.

- **Sum of hard credits = total raised. Soft credits are a parallel recognition layer.** RED FLAG: a report that adds hard + soft and calls it "total raised" double-counts.
- NPSP auto-creates household soft credits via the OCR + Household Soft Credit setting.
- Verify: `soql_query("SELECT Role, IsPrimary, ContactId FROM OpportunityContactRole WHERE OpportunityId = '…'")`.

> For full PART A detail (CRLP, Enhanced Recurring Donations, TDTM, Addresses, Governor Limits, FLS, Custom Fields, Lookup uniqueness, QA cache, managed-package automation, Data Import tool selection, Duplicate management, Analytics/LYBUNT/SYBUNT), see [references/npsp-deep-dive.md](references/npsp-deep-dive.md).

---

# PART B — Nonprofit Cloud (Industries) Operational Knowledge (NP-Con-102)

> Applies only if the org has **Nonprofit Cloud / Industries** enabled. For an NPSP org, treat this as forward-looking. Confirm with `list_objects` — NPC uses namespace-free Industries objects.

**Rule: Permission Set Licenses gate NPC features.** In Nonprofit Cloud, access errors are usually a missing Permission Set License, not a sharing problem. Each module (Fundraising, Program Management, Outcome Management, Grantmaking) requires its specific PSL **plus** a Permission Set assigned to the user. Troubleshoot "can't see the feature" by checking the PSL assignment first.

**Key NPC term translations:**

| NPSP (101) | Nonprofit Cloud (102) |
|---|---|
| Opportunity / Payment | Gift / Gift transaction |
| Recurring Donation | Gift Commitment + Gift Commitment Schedule |
| Campaign / appeal | Outreach Source Code |
| Engagement Plan | Action Plan (Template) |
| Household Account | Person Account / Household |
| NPSP batch rollups | Data Processing Engine (DPE) |
| Custom Flow intake | OmniScript |

> For full PART B detail (complete NPC term-translation table, PSL gating rules, Program Management & Outcome objects, full OmniStudio tool-selection matrix, Care Plans), see [references/nonprofit-cloud-industries.md](references/nonprofit-cloud-industries.md).

---

# PART C — Salesforce Platform / Integration Scars (apply on every task)

## 20. External Client App (ECA) vs Connected App — and permission location

**Rule: some modern orgs cannot create Connected Apps** (*"To enable connected app creation, contact Salesforce Customer Support"*). The workaround is an **External Client App** for the JWT bearer flow.

- **ECA permission assignment is on the ECA itself, not the permission set.** The classic Permission Set "Assigned Connected Apps" page does NOT authorize ECA usage. Correct path: **ECA detail → Policies tab → Edit → App Policies → Select Permission Sets.** Browser-AI tools will edit the wrong screen and report success — **verify via API** (`PermissionSetAssignment`, `SetupEntityAccess`) before trusting it.
- **The ECA Consumer Key is UI-only** (behind email verification). No Tooling API, REST, Connect API, or metadata retrieve exposes it. There is no scriptable path.

## 21. SFDX project root and smoke testing

- **All `sf project …` commands must run from the SFDX project root** (the directory containing `sfdx-project.json`), not an arbitrary repo root, or they fail with *"InvalidProjectWorkspaceError."*
- **Run a JWT smoke test after any SF metadata change, cert rotation, or new sandbox** — exercise the full chain (auth → describe → upsert idempotency → cleanup). It catches the FLS/ECA/relationship gotchas above at the layer they bite.
- Sandbox creation in some orgs requires a **Public Group** to exist first — a one-time setup step.

## 22. The three-places rule for data-model changes

**Rule: a data-model change is all three or none** — update the data-model docs, the SFDX field XML, **and** the application-layer types/schema. Plus, if the field writes to Contact, regenerate any generated schema constants and add `<fieldPermissions>` to the permset. Deploy with `sf project deploy start`; metadata changes don't land in the org until you do.

---

## Operational Rules Quick Reference

Read this first. Each rule is imperative and concrete.

- **DON'T** make changes to a Production Salesforce org. Use a sandbox. Reads are fine.
- **DO** put every person in a Household Account; let NPSP's TDTM create it on Contact insert.
- **DO** use Relationship for Contact↔Contact, Affiliation for Contact↔Org Account.
- **DON'T** hand-create both directions of a Relationship — NPSP auto-mirrors the reciprocal.
- **DO** keep hard credit (donor of record) and soft credit (recognition) separate; never sum them as "total raised."
- **DO** recalculate rollups after any bulk load or TDTM-disabled operation — stale totals are config, not data corruption.
- **DON'T** put SOQL/DML inside a loop. Query into a Map, iterate, collect into a List, DML once. Limits: 100 SOQL / 50k rows / 150 DML / 10k DML rows / 10s CPU.
- **DO** add `<fieldPermissions>` to a permset for every new SFDX field — field-meta.xml grants FLS to no one, not even SysAdmin.
- **DON'T** list required fields in `<fieldPermissions>` — the permset deploy fails ("can't deploy to a required field").
- **DON'T** hand-edit generated schema constants; regenerate from the org and commit. Use real lengths/picklists, not guesses.
- **DON'T** rely on Apex truncation as your length guard — fail at form/integration validation instead.
- **DO** disable TDTM handlers for big bulk loads, then re-enable and recalculate rollups. Never leave them disabled.
- **DO** give same-parent Lookups unique `relationshipName`s (role suffixes). SOQL traversal keys on field name, so renaming is safe.
- **DO** cache-bust a Quick Action by editing non-field metadata (`<description>`) and redeploying when new QA fields don't render.
- **DO** suspect managed-package workflow rules/TDTM (e.g. npe01 Phone→MobilePhone) when a field changes unexpectedly; probe via sandbox debug log.
- **DO** match Contacts on email + birthdate, not name+address — Households share addresses.
- **DO** use External IDs as upsert keys so re-runs and late writes re-link instead of duplicating.
- **DO** pick the import tool by need: NPSP Data Import for NPSP objects, Data Import Wizard < 50k generic, Data Loader for > 50k / hard delete / CLI.
- **DO** assign ECA permissions on the ECA's Policies tab (not the permset page); verify via `PermissionSetAssignment` API — browser tools lie.
- **DO** run all `sf project` commands from the SFDX project root and run a JWT smoke test after any metadata/cert change.
- **DO** verify any field/picklist/relationship against the live org with `describe_object`/`soql_query` before writing code that depends on it.
- **DO** treat data-model changes as all-three: doc + SFDX XML + app-layer types (and permset FLS + schema regen if it touches Contact).
- **DO** default to the NPSP (101) model; only use NPC/Industries patterns if `list_objects` confirms Industries objects exist.
- **DO** check PSL assignment first when a Nonprofit Cloud feature is inaccessible — it's usually a missing Permission Set License, not a sharing issue.

---

## 3. Engagement Plans (NP-Con-101) — automate touchpoint sequences

**Rule: Engagement Plans let you assign a templated sequence of tasks to a Contact or other record.** An Engagement Plan Template defines the task sequence (name, days offset, assignee type, reminder). You apply it to a Contact by creating an Engagement Plan record — NPSP then generates the individual task records per the template. This is the NPSP native equivalent of NPC's Action Plans.

- Decision: use Engagement Plans for repeatable stewardship sequences (e.g. major-donor cultivation); use standard Task manual creation for one-off contact.
- **Anti-pattern:** building Flows or Apex to create task sequences when Engagement Plan Templates already do it natively — prefer NPSP-native before custom logic.
- Verify a template exists: `soql_query("SELECT Name, npsp__Description__c FROM npsp__Engagement_Plan_Template__c")`.

## 4. Gift Entry (Batch Gift Entry) — the correct NPSP intake path for batches

**Rule: NPSP's Gift Entry (Batch Gift Entry, GE) is the correct path for processing a batch of offline gifts.** GE uses data import batch records backed by `npsp__DataImport__c` and respects the NPSP data model (Household Accounts, soft credits, GAU allocations). Importing Opportunities directly with Data Loader bypasses household auto-creation and GAU allocation logic.

- GE supports **matching rules** — it can find and update an existing Contact/Opportunity instead of creating duplicates.
- GE templates let admins configure which fields appear; only expose what the gift-entry staff need.
- **Anti-pattern:** using Data Loader to bulk-import Opportunities for batch gift processing — you lose GAU split logic and may orphan Household Accounts. Reserve Data Loader for full migration loads run by a consultant, not day-to-day gift entry.
- Verify a GE batch exists: `soql_query("SELECT Name, npsp__Batch_Status__c FROM npsp__DataImportBatch__c LIMIT 10")`.

---

## Decision scenarios

These scenarios test judgment in the highest-consequence operational situations. Each covers a specific gotcha where the competent move and the tempting-but-wrong move look nearly identical on the surface.

---

**Scenario 1 — NPSP or Nonprofit Cloud?**

> **Situation:** A new client has a Salesforce org. A user says "we're on Nonprofit Cloud" and asks you to configure a Gift Commitment Schedule for a recurring donor. Before touching anything, you run `list_objects`.  The results include `npe03__Recurring_Donation__c` but no `GiftCommitment` or `GiftCommitmentSchedule` object.
>
> **Competent move:** Treat this as an NPSP org. The `npe03__` namespace is the NPSP Recurring Donations package. "Gift Commitment" is the Nonprofit Cloud (NPC/Industries) term. The correct action is to configure an NPSP Enhanced Recurring Donation (`npe03__Recurring_Donation__c`), not a `GiftCommitment`. Inform the client of the distinction so scope and documentation are accurate.
>
> **Tempting-but-wrong:** Accept the client's framing ("we're on Nonprofit Cloud") and attempt to find or create a `GiftCommitment` record, which either errors or creates an unmanaged custom object — neither correct.
>
> **Verify:** `list_objects` for `GiftCommitment` returns nothing; `describe_object("npe03__Recurring_Donation__c")` returns fields including `RecurringType__c` confirming ERD is active. Official source: NPC object reference in Salesforce Help.

---

**Scenario 2 — Hard credit vs soft credit double-count**

> **Situation:** A major-gifts officer asks you to run a report of "total amount raised" and gives you a report that sums both `npo02__TotalOppAmount__c` (lifetime hard credit) and `npo02__Soft_Credit_Total__c` (lifetime soft credit) for each Contact.
>
> **Competent move:** Refuse to accept the report as-is. Hard credit and soft credit are parallel recognition layers; summing them double-counts every gift where a household member or influencer also received soft credit. The correct "total raised" figure is the sum of hard credit only (Opportunity amounts via OCR primary roles). Soft credit fields are for donor-recognition reporting, not fundraising totals.
>
> **Tempting-but-wrong:** Run the report as requested because the officer is the business owner and "it's just a report." This produces inflated totals that distort fundraising KPIs, major-gift segmentation, and board reporting.
>
> **Verify:** `soql_query("SELECT Role, IsPrimary, ContactId FROM OpportunityContactRole WHERE OpportunityId = '…'")` confirms which role carries hard credit (IsPrimary = true, Role = "Donor"). Cross-check `npo02__TotalOppAmount__c` matches the sum of that Contact's primary OCR Opportunities.

---

**Scenario 3 — Bulk load with TDTM handlers active**

> **Situation:** A consultant plans to import 80,000 Opportunities via Data Loader into an NPSP org, with all TDTM trigger handlers active, to save time on re-enabling them afterward.
>
> **Competent move:** Disable the relevant TDTM handlers before the load (deactivate rows in `npsp__Trigger_Handler__c`), run the load, re-enable all handlers, then run **NPSP Settings → Bulk Data Processes → Recalculate Rollups**. Skipping the disable step on 80k records risks blowing governor limits (SOQL/DML per transaction), causing partial failures, and leaving the import in an inconsistent state.
>
> **Tempting-but-wrong:** Leave handlers active to avoid the extra steps, reasoning that "the org handled 5,000 records fine." Volume changes the math — 80k records in a single Data Loader batch will hit synchronous SOQL and DML limits that 5k never triggered.
>
> **Verify:** After re-enabling, `soql_query("SELECT npsp__Active__c, Name FROM npsp__Trigger_Handler__c WHERE npsp__Active__c = false")` should return zero rows (all re-enabled). Then confirm rollup totals by spot-checking a few donor records against the raw Opportunity sum.

---

**Scenario 4 — NPC feature not visible: PSL vs sharing**

> **Situation:** A program officer on a Nonprofit Cloud org cannot see the Program Engagement tab. Their profile has full object permissions on standard objects. A junior admin concludes it must be an OWD sharing restriction and opens a sharing rule.
>
> **Competent move:** Check Permission Set License assignment first. In Nonprofit Cloud, module access is gated by PSL — the user must have the Nonprofit Cloud Program Management PSL assigned, **then** the corresponding Permission Set. A sharing rule does nothing if the user cannot even see the object in the UI due to a missing PSL.
>
> **Tempting-but-wrong:** Adding or widening sharing rules. This wastes time, adds unnecessary access risk, and will not fix the root cause.
>
> **Verify:** Setup → Users → [User] → Permission Set License Assignments — confirm the Program Management PSL is listed. Then check Permission Set Assignments for the associated permset. Official path: NPC Admin Guide, "Assign Nonprofit Cloud Permission Sets."

---

**Scenario 5 — Address edit on the Contact vs the Household**

> **Situation:** A volunteer updates a donor's mailing address by editing the Mailing Street field directly on the Contact record in NPSP. Two hours later the address has reverted to the old value.
>
> **Competent move:** Edit the address on the `npsp__Address__c` record linked to the Household Account (or use the NPSP Manage Household UI), not the raw Contact field. NPSP's Address management TDTM handler (`ADDR_Addresses_TDTM`) syncs the canonical Household Address down to the Contact — overwriting any direct Contact-field edit.
>
> **Tempting-but-wrong:** Disabling Address management to prevent future overwrites. This breaks Seasonal Address, Primary Address switching, and household-level address inheritance for all Contacts in that household going forward.
>
> **Verify:** `soql_query("SELECT npsp__MailingStreet__c, npsp__Primary__c FROM npsp__Address__c WHERE npsp__Household_Account__c = '[HH Account Id]'")` shows the canonical address. The Contact's Mailing fields should match the Primary Address record; if they don't, run Verify Addresses from NPSP Settings.

---

## Study resources & relevance

Study resources (official Salesforce + community), the exam-topic → operational-rule relevance table, and the certification sequence recommendation are kept in [references/study-resources.md](references/study-resources.md) so this skill stays focused on operational rules. Load that file when planning a study path or mapping these rules to a nonprofit org.

---

*Independent educational content to upskill AI agents. Not affiliated with or endorsed by Salesforce; all trademarks — including "Salesforce," "NPSP," "Nonprofit Cloud," and "Salesforce Certified" — belong to their respective owners. Guidance only — verify all configuration, limits, and feature availability against official Salesforce documentation and your live org before making changes.*
