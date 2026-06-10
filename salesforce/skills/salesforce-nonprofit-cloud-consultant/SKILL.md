---
name: salesforce-nonprofit-cloud-consultant
description: Salesforce nonprofit implementation across BOTH the NPSP managed package (Household Accounts, Relationships, Affiliations, hard/soft credit, TDTM, Customizable Rollups, Recurring Donations, Batch Gift Entry, LYBUNT/SYBUNT) and Industries Nonprofit Cloud (Gift Entry, Program/Outcome Management, Grantmaking, OmniStudio, Action/Care Plans, Data Processing Engine). Use when configuring or troubleshooting either model, or deciding which applies. This is the nonprofit data model/program layer; for the underlying platform see salesforce-administrator and the platform-developer skills. Scoped and benchmarked by the Nonprofit (NP-Con-101 NPSP, NP-Con-102 NPC) blueprints.
metadata:
  anchor-credential: Salesforce Certified Nonprofit Cloud Consultant
  exam-codes: NP-Con-101, NP-Con-102
  domain: salesforce
  type: certification-playbook
  status: current
  last-reviewed: 2026-06-10
  blueprint-verified: 2026-06-07
---

# Salesforce Nonprofit Cloud Consultant — Skills Reference

> This file is an **operational playbook**, not an exam outline. It states the rules an AI agent applies at decision time on an NPSP / Nonprofit Cloud org: the actual rule, the real limits, the "when X → do Y" criteria, the red flags to catch in review, and how to verify against the live org (describe objects, run SOQL, list objects, run reports — via MCP, `sf` CLI, or the Salesforce setup UI). All describe/SOQL reads are safe; any write/metadata change belongs in a sandbox, never Production.

## Overview

This file covers **two related but distinct** Salesforce certifications for nonprofit practitioners. Salesforce historically branded the nonprofit credential as "Nonprofit Cloud Consultant," but in **July 2025** the credential line was split and renamed. Both are **active** as of mid-2026:

- **NP-Con-101 — Salesforce Certified Nonprofit Success Pack Consultant.** This is the original exam, *renamed* in July 2025 (it was previously titled "Nonprofit Cloud Consultant"). It tests deep knowledge of the **NPSP managed package** — Household Accounts, Relationships, Affiliations, Recurring Donations, Engagement Plans, TDTM (Table-Driven Trigger Management), Customizable Rollups, and the classic NPSP data model. Target audience: implementers working with NPSP on any Salesforce edition.

- **NP-Con-102 — Salesforce Certified Nonprofit Cloud Consultant (NPC).** This is the newer exam, introduced alongside the July 2025 rename. It tests the **Salesforce Industries Nonprofit Cloud** platform solution — fundraising built on Industries objects, Program Management, Outcome Management, Grantmaking, OmniStudio, Action Plans, and Care Plans. Target audience: implementers delivering Nonprofit Cloud on Salesforce Industries.

Both exams once shared a single Trailhead credential page and are still discussed interchangeably in the community, which causes confusion. Read the official exam guide carefully to confirm which version you are registering for.

> **Current product naming (Dec 2025):** Salesforce rebranded Nonprofit Cloud as **"Agentforce Nonprofit"** in October 2025 `[volatile — verify live]`. The Power of Us program now grants eligible nonprofits 10 **Agentforce Nonprofit** licenses (not free NPSP licenses, which were removed from the Power of Us offering in December 2025). In community discussions and documentation you may still see "Nonprofit Cloud (NPC)" used — treat "Agentforce Nonprofit" and "Nonprofit Cloud" as referring to the same Industries-based platform. `[volatile — verify live]`

**Picking the right model at decision time:** an org running the **NPSP managed package** maps to **NP-Con-101**; an org running **Industries-based Nonprofit Cloud / Agentforce Nonprofit** maps to **NP-Con-102**. NPSP is in stable maintenance mode — **feature development ended in March 2023** when Salesforce launched Nonprofit Cloud; NPSP remains fully supported with no announced end-of-life date `[volatile — verify live]`. **Default all operational decisions to the NPSP (101) model unless someone has confirmed Nonprofit Cloud / Industries is enabled** — verify by listing the org's objects (your Salesforce MCP, `sf sobject list`, or Setup → Object Manager): NPSP objects carry `npe01__` / `npo02__` / `npsp__` / `npe4__` / `npe5__` namespaces `[volatile — verify live]`, while NPC objects are namespace-free Industries standard objects like `Gift`, `Program`, and `ProgramEnrollment`.

> **Deeper context:** Study resources (official Salesforce + community, hands-on environments), the Relevance map, and full deep-dive operational detail live in:
> - [references/study-resources.md](references/study-resources.md) — study paths, links, certification sequence recommendation, exam-topic ↔ operational-rule relevance table
> - [references/npsp-deep-dive.md](references/npsp-deep-dive.md) — PART A detail: CRLP, ERD, TDTM, Addresses, Governor Limits, FLS, Custom Fields, Lookup uniqueness, QA cache, managed-pkg automation, Data Import, Duplicate management, Analytics
> - [references/nonprofit-cloud-industries.md](references/nonprofit-cloud-industries.md) — PART B detail: full NPC term-translation table, PSL gating, Program Management & Outcome objects, OmniStudio tool selection
>
> For org-specific applications, keep a per-org appendix in your own project, referenced from a CLAUDE.md.

> **Load this skill when…** configuring or troubleshooting an NPSP org (Household Accounts, TDTM, rollups, recurring donations, gift entry, hard/soft credit); implementing Salesforce Industries Nonprofit Cloud (Program Management, Outcome Management, Grantmaking, OmniStudio); or deciding which nonprofit model applies to an org.
> **Not this skill:** underlying platform rules (Apex governor limits, FLS, deployment discipline) not specific to nonprofit objects → see `salesforce-administrator` and the platform-developer skills; Experience Cloud portals for nonprofit constituent engagement → see `salesforce-experience-cloud-consultant`.

> **Verify steps assume nothing about your tooling** — use your project's Salesforce MCP connection, the Salesforce CLI (`sf`), or the Salesforce setup UI, in that order of preference. The SOQL and describe calls below are written to work through any of them.

---

Credential logistics and study path: see [references/study-resources.md](references/study-resources.md).

---

## Uncertainty & Escalation

- **Always re-verify live:** volatile facts in this skill include NPSP namespace versions (`npe01__`, `npo02__`, `npsp__` namespaces may shift across managed package upgrades `[volatile — verify live]`), TDTM handler names and activation fields, CRLP rollup field names, NPC Permission Set License names and required permsets `[volatile — verify live]`, and whether the July 2025 credential split is reflected in a given org's contract — confirm all against the live org's installed package version and current Salesforce Help.
- **Live wins:** when the live org or official documentation contradicts a statement in this file, trust the live source and log the discrepancy via the Feedback protocol below.
- **Escalate to a human before proceeding on:** disabling or permanently deactivating TDTM handlers in a production org; any bulk delete or hard delete of Opportunity, Contact, or Account records in production; mass re-parenting Contacts to different Households; recalculating rollups on a production org with > 100k records without a maintenance window plan.
- **Confidence taxonomy:** every fact in this file is considered stable unless tagged `[volatile — verify live]` or `[opinion — house style]`. If you act on an untagged fact and the live system disagrees, file feedback — do not silently trust this file over the live org.

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
- **Verify:** Run `SELECT npe01__SYSTEM_AccountType__c, COUNT(Id) FROM Account GROUP BY npe01__SYSTEM_AccountType__c` via your Salesforce MCP/connection, or `sf data query --query "SELECT npe01__SYSTEM_AccountType__c, COUNT(Id) FROM Account GROUP BY npe01__SYSTEM_AccountType__c"` (Salesforce CLI), or the Developer Console Query Editor — to confirm the org's account model.

## 2. Hard Credit vs Soft Credit — the single most-tested NPSP concept

**Rule: hard credit = the donor of record; soft credit = recognition only.** Hard credit flows from the Opportunity's Primary `OpportunityContactRole` (OCR) and rolls up into the donor's lifetime giving totals (`npo02__TotalOppAmount__c` etc.). Soft credit is recognition for someone who influenced the gift and rolls up **separately** into soft-credit fields — it must **never** double-count into hard-credit totals.

- **Sum of hard credits = total raised. Soft credits are a parallel recognition layer.** RED FLAG: a report that adds hard + soft and calls it "total raised" double-counts.
- NPSP auto-creates household soft credits via the OCR + Household Soft Credit setting.
- Verify: run `SELECT Role, IsPrimary, ContactId FROM OpportunityContactRole WHERE OpportunityId = '…'` (MCP / `sf data query` / Developer Console).

> For full PART A detail (CRLP, Enhanced Recurring Donations, TDTM, Addresses, Governor Limits, FLS, Custom Fields, Lookup uniqueness, QA cache, managed-package automation, Data Import tool selection, Duplicate management, Analytics/LYBUNT/SYBUNT), see [references/npsp-deep-dive.md](references/npsp-deep-dive.md).

---

# PART B — Nonprofit Cloud (Industries) Operational Knowledge (NP-Con-102)

> Applies only if the org has **Agentforce Nonprofit / Nonprofit Cloud / Industries** enabled. For an NPSP org, treat this as forward-looking. Confirm by listing the org's objects (MCP / `sf sobject list` / Object Manager) — NPC uses namespace-free Industries objects.

**Rule: Permission Set Licenses gate NPC features.** In Nonprofit Cloud, access errors are usually a missing Permission Set License, not a sharing problem. Each module (Fundraising, Program Management, Outcome Management, Grantmaking) requires its specific PSL **plus** a Permission Set assigned to the user. Troubleshoot "can't see the feature" by checking the PSL assignment first.

> **NP-Con-102 coverage note:** The four exam domains and approximate weights are: Nonprofit Cloud Feature Configuration (~35%), Solution Design (~32%), Nonprofit Cloud Setup (~22%), and Nonprofit Implementation Strategy (~11%). Solution Design (32%) and Implementation Strategy (11%) together represent ~43% of the exam. Solution Design tests selecting the right Salesforce solution for customer requirements — declarative vs custom vs third-party; Implementation Strategy tests facilitating a successful engagement: discovery, user stories, change management, testing, and deployment strategy. See [references/study-resources.md](references/study-resources.md) for the full blueprint map. `[volatile — verify live against the current NP-Con-102 exam guide]`

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
- **DO** verify any field/picklist/relationship against the live org (describe the object, run SOQL) before writing code that depends on it.
- **DO** treat data-model changes as all-three: doc + SFDX XML + app-layer types (and permset FLS + schema regen if it touches Contact).
- **DO** default to the NPSP (101) model; only use NPC/Agentforce Nonprofit (Industries) patterns if listing the org's objects confirms Industries objects exist.
- **DO** check PSL assignment first when a Nonprofit Cloud feature is inaccessible — it's usually a missing Permission Set License, not a sharing issue.

---

## 3. Engagement Plans (NP-Con-101) — automate touchpoint sequences

**Rule: Engagement Plans let you assign a templated sequence of tasks to a Contact or other record.** An Engagement Plan Template defines the task sequence (name, days offset, assignee type, reminder). You apply it to a Contact by creating an Engagement Plan record — NPSP then generates the individual task records per the template. This is the NPSP native equivalent of NPC's Action Plans.

- Decision: use Engagement Plans for repeatable stewardship sequences (e.g. major-donor cultivation); use standard Task manual creation for one-off contact.
- **Anti-pattern:** building Flows or Apex to create task sequences when Engagement Plan Templates already do it natively — prefer NPSP-native before custom logic.
- Verify a template exists: run `SELECT Name, npsp__Description__c FROM npsp__Engagement_Plan_Template__c` (MCP / `sf data query` / Developer Console).

## 4. Gift Entry (Batch Gift Entry) — the correct NPSP intake path for batches

**Rule: NPSP's Gift Entry (Batch Gift Entry, GE) is the correct path for processing a batch of offline gifts.** GE uses data import batch records backed by `npsp__DataImport__c` and respects the NPSP data model (Household Accounts, soft credits, GAU allocations). Importing Opportunities directly with Data Loader bypasses household auto-creation and GAU allocation logic.

- GE supports **matching rules** — it can find and update an existing Contact/Opportunity instead of creating duplicates.
- GE templates let admins configure which fields appear; only expose what the gift-entry staff need.
- **Anti-pattern:** using Data Loader to bulk-import Opportunities for batch gift processing — you lose GAU split logic and may orphan Household Accounts. Reserve Data Loader for full migration loads run by a consultant, not day-to-day gift entry.
- Verify a GE batch exists: run `SELECT Name, npsp__Batch_Status__c FROM npsp__DataImportBatch__c LIMIT 10` (MCP / `sf data query` / Developer Console).

---

## Executable Workflows

### 1. Configure an Enhanced Recurring Donation end-to-end

1. Verify ERD is enabled: NPSP Settings → Recurring Donations → Recurring Donations Enhancement. → **gate: `npe03__Recurring_Donation__c` describe includes `RecurringType__c` field (MCP / `sf sobject describe --sobject npe03__Recurring_Donation__c` / Object Manager).**
2. Create or confirm the Recurring Donation record: set `RecurringType__c` (Open vs Fixed), `npe03__Amount__c`, `npe03__Installment_Period__c`, and `npe03__Date_Established__c`. Link to a Contact with a valid Household Account. → **gate: save succeeds with no validation errors; `npe03__Next_Payment_Date__c` is populated automatically.**
3. Confirm the first Opportunity installment was created: `SELECT Id, Amount, CloseDate, StageName FROM Opportunity WHERE npe03__Recurring_Donation__c = '<RD Id>'`. → **gate: at least one installment Opportunity exists with the expected amount and close date.**
4. Update the gift amount (simulate a donor upgrade): edit the RD Amount field → choose to apply to all open installments. → **gate: query the open Opportunities — all show the updated amount.**
5. Verify rollups: check `npo02__TotalOppAmount__c` on the donor's Contact record matches the sum of their Closed Won Opportunities. → **gate: totals match; if not, run NPSP Settings → Bulk Data Processes → Recalculate Rollups.**

### 2. Bulk-load gifts with TDTM disabled → load → re-enable → recalculate rollups

1. In sandbox, identify the TDTM handlers to disable: query `SELECT Name, npsp__Active__c, npsp__Object__c FROM npsp__Trigger_Handler__c WHERE npsp__Active__c = true AND npsp__Object__c IN ('Opportunity','Contact','Account')`. → **gate: list of active handlers noted; you will re-enable all of them after the load.**
2. Disable the relevant handlers: update `npsp__Active__c = false` on each handler row (via Data Loader or SOQL in Developer Console). → **gate: query confirms `npsp__Active__c = false` for all targeted handlers.**
3. Run the bulk load (Data Loader upsert on External ID). → **gate: load log shows 0 failures; row count in target object matches source file.**
4. Re-enable all handlers: update `npsp__Active__c = true`. → **gate: query `SELECT Name FROM npsp__Trigger_Handler__c WHERE npsp__Active__c = false` returns 0 rows.**
5. Run NPSP rollup recalculation: NPSP Settings → Bulk Data Processes → Recalculate Rollups. → **gate: spot-check 3–5 donor Contacts — `npo02__TotalOppAmount__c` matches the sum of their Closed Won Opportunities.**

### 3. Set up hard/soft credit and verify giving totals don't double-count

1. Confirm the primary OCR role is set correctly on each Opportunity: `SELECT Role, IsPrimary, ContactId FROM OpportunityContactRole WHERE OpportunityId = '<id>'`. → **gate: exactly one OCR has `IsPrimary = true` and `Role = 'Donor'` (or your org's configured hard-credit role).**
2. Enable Household Soft Credits: NPSP Settings → Contacts → Household Soft Credit → configure the Soft Credit Roles. → **gate: household members of the primary donor appear as soft-credit OCRs after NPSP processes the gift.**
3. Verify soft-credit rollup is separate: on the donor's Contact, confirm `npo02__TotalOppAmount__c` (hard credit) does NOT include soft-credit amounts — compare against `npo02__Soft_Credit_Total__c`. → **gate: hard total = sum of primary OCR Opportunities only; soft total = recognition-only; no double-count.**
4. Build the "total raised" report using hard-credit Opportunities only: report type "Opportunities with Contact Roles," filter `IsPrimary = true`, sum Amount. → **gate: report total matches the sum computed in step 3; excludes soft-credit rows.**

---

## Decision scenarios

These scenarios test judgment in the highest-consequence operational situations. Each covers a specific gotcha where the competent move and the tempting-but-wrong move look nearly identical on the surface.

---

**Scenario 1 — NPSP or Nonprofit Cloud?**

> **Situation:** A new client has a Salesforce org. A user says "we're on Nonprofit Cloud" and asks you to configure a Gift Commitment Schedule for a recurring donor. Before touching anything, you list the org's objects (your Salesforce MCP, `sf sobject list`, or Setup → Object Manager). The results include `npe03__Recurring_Donation__c` but no `GiftCommitment` or `GiftCommitmentSchedule` object.
>
> **Competent move:** Treat this as an NPSP org. The `npe03__` namespace is the NPSP Recurring Donations package. "Gift Commitment" is the Nonprofit Cloud (NPC/Industries) term. The correct action is to configure an NPSP Enhanced Recurring Donation (`npe03__Recurring_Donation__c`), not a `GiftCommitment`. Inform the client of the distinction so scope and documentation are accurate.
>
> **Tempting-but-wrong:** Accept the client's framing ("we're on Nonprofit Cloud") and attempt to find or create a `GiftCommitment` record, which either errors or creates an unmanaged custom object — neither correct.
>
> **Verify:** List the org's objects (your Salesforce MCP, `sf sobject list`, or Setup → Object Manager) — `GiftCommitment` should not appear; describe `npe03__Recurring_Donation__c` (MCP / `sf sobject describe --sobject npe03__Recurring_Donation__c` / Object Manager) and confirm fields including `RecurringType__c` exist, confirming ERD is active. Official source: NPC object reference in Salesforce Help.

---

**Scenario 2 — Hard credit vs soft credit double-count**

> **Situation:** A major-gifts officer asks you to run a report of "total amount raised" and gives you a report that sums both `npo02__TotalOppAmount__c` (lifetime hard credit) and `npo02__Soft_Credit_Total__c` (lifetime soft credit) for each Contact.
>
> **Competent move:** Refuse to accept the report as-is. Hard credit and soft credit are parallel recognition layers; summing them double-counts every gift where a household member or influencer also received soft credit. The correct "total raised" figure is the sum of hard credit only (Opportunity amounts via OCR primary roles). Soft credit fields are for donor-recognition reporting, not fundraising totals.
>
> **Tempting-but-wrong:** Run the report as requested because the officer is the business owner and "it's just a report." This produces inflated totals that distort fundraising KPIs, major-gift segmentation, and board reporting.
>
> **Verify:** Run `SELECT Role, IsPrimary, ContactId FROM OpportunityContactRole WHERE OpportunityId = '…'` (MCP / `sf data query` / Developer Console) to confirm which role carries hard credit (IsPrimary = true, Role = "Donor"). Cross-check `npo02__TotalOppAmount__c` matches the sum of that Contact's primary OCR Opportunities.

---

**Scenario 3 — Bulk load with TDTM handlers active**

> **Situation:** A consultant plans to import 80,000 Opportunities via Data Loader into an NPSP org, with all TDTM trigger handlers active, to save time on re-enabling them afterward.
>
> **Competent move:** Disable the relevant TDTM handlers before the load (deactivate rows in `npsp__Trigger_Handler__c`), run the load, re-enable all handlers, then run **NPSP Settings → Bulk Data Processes → Recalculate Rollups**. Skipping the disable step on 80k records risks blowing governor limits (SOQL/DML per transaction), causing partial failures, and leaving the import in an inconsistent state.
>
> **Tempting-but-wrong:** Leave handlers active to avoid the extra steps, reasoning that "the org handled 5,000 records fine." Volume changes the math — 80k records in a single Data Loader batch will hit synchronous SOQL and DML limits that 5k never triggered.
>
> **Verify:** After re-enabling, run `SELECT npsp__Active__c, Name FROM npsp__Trigger_Handler__c WHERE npsp__Active__c = false` (MCP / `sf data query` / Developer Console) — should return zero rows (all re-enabled). Then confirm rollup totals by spot-checking a few donor records against the raw Opportunity sum.

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
> **Verify:** Run `SELECT npsp__MailingStreet__c, npsp__Primary__c FROM npsp__Address__c WHERE npsp__Household_Account__c = '[HH Account Id]'` (MCP / `sf data query` / Developer Console) to see the canonical address. The Contact's Mailing fields should match the Primary Address record; if they don't, run Verify Addresses from NPSP Settings.

---

## Study resources & relevance

Study resources (official Salesforce + community), the exam-topic → operational-rule relevance table, and the certification sequence recommendation are kept in [references/study-resources.md](references/study-resources.md) so this skill stays focused on operational rules. Load that file when planning a study path or mapping these rules to a nonprofit org.

---

## Feedback protocol

Using this skill and hit a wall? If you find a claim contradicted by the live system or official docs, a missing rule that cost you a wrong attempt, or a decision this skill gave no criteria for — append an entry **in the moment** to `.skill-feedback/salesforce-nonprofit-cloud-consultant.md` at the project root (create it if absent):

`date | skill last-reviewed | claim or gap | what you observed instead | evidence (error text / doc URL / query output) | suggested fix`

These are harvested back into the skill via the learning loop. When the live system and this file disagree, trust the live system.

## Changelog

- **2026-06-10** — Cycle-4 curation (inbox): (1) Added Agentforce Nonprofit rebrand note (Oct 2025) and Power of Us license change (Dec 2025, now grants Agentforce Nonprofit licenses); both marked `[volatile]`. (2) Fixed NPSP framing: replaced "sunsetting over the coming years" with accurate "feature development ended March 2023, fully supported, no announced EOL." (3) Added NP-Con-102 domain-weight coverage note to PART B (Solution Design 32%, Implementation Strategy 11%, etc.). (4) Fixed Grantmaking object names in references/nonprofit-cloud-industries.md (`Grant`/`GrantApplication` → `FundingOpportunity`/`IndividualApplication`). (5) Updated references/study-resources.md: relabeled legacy PDF link, updated certification sequence recommendation, fixed NPSP EOL framing.
- **2026-06-09** — Conformed to the 12-dimension skill standard: task-vocab description + Scope block, Uncertainty & Escalation guidance with inline `[volatile — verify live]` marks, executable workflows, tool-agnostic verify steps, and the feedback protocol above. Exam logistics relocated to references/study-resources.md; `last-reviewed` set to 2026-06-09.

---

*Independent educational content to upskill AI agents. Not affiliated with or endorsed by Salesforce; all trademarks — including "Salesforce," "NPSP," "Nonprofit Cloud," and "Salesforce Certified" — belong to their respective owners. Guidance only — verify all configuration, limits, and feature availability against official Salesforce documentation and your live org before making changes. No certification outcome is implied or guaranteed.*
