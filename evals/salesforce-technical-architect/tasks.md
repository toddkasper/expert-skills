# Application tasks — salesforce-technical-architect (Lens 4, held-out)

A skilled agent produces the artifact; a judge grades against the trap-keyed rubric. Run baseline vs skilled.

---

## Task 1 — Integration architecture review: inbound webhook-to-Salesforce sync

**Prompt to the agent:** Review the integration design below and produce a written redline: identify every governor-limit risk, security flaw, idempotency gap, and FLS/sharing blind spot. For each finding, name the problem, explain the impact at scale, and specify the correct architectural fix.

**Design spec (submitted by a developer for CTA review):**

> **Use case:** An external grant-management portal sends a webhook POST to a Heroku middleware whenever a grant application is submitted. The middleware calls Salesforce REST API to upsert the `Application__c` record using `External_ID__c` as the key.
>
> **Auth:** The middleware authenticates via the OAuth Username-Password flow using a dedicated integration user. The username and password are stored as Heroku config vars.
>
> **Trigger behavior:** An after-insert Apex trigger on `Application__c` fires on every insert. Inside the trigger, for each new application it calls a helper method that makes an HTTP callout to a PDF-generation service to attach the intake PDF synchronously. The trigger also runs a SOQL query to fetch the related `Account` record and copies three fields to the Application.
>
> **Error handling:** If the Heroku middleware receives a non-200 from Salesforce, it logs the error to a Splunk dashboard and retries immediately up to five times in a for-loop.
>
> **Idempotency:** `External_ID__c` is a custom text field on `Application__c`. It is used as the upsert key in the REST call.
>
> **Sharing/FLS:** The integration user's profile has "Modify All Data" to ensure all records can be written without sharing errors.
>
> **Volume:** Expected steady-state is 200 applications/day with bursts up to 2,000/day during open enrollment.

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — Synchronous HTTP callout inside an Apex trigger. Apex forbids callouts in a trigger context unless they are `@future(callout=true)` or Queueable with `Database.AllowsCallouts`. A synchronous callout in the trigger body will throw `System.CalloutException: You have uncommitted work pending. Please commit or rollback before calling out`. Fix: move the PDF callout to a `@future(callout=true)` method or a Queueable, enqueued from the trigger.
- [ ] Trap 2 — `External_ID__c` is described as a custom text field but is NOT marked as an External ID (no `externalId: true` in field metadata). REST upsert keyed on a non-External-ID field will fail at the API level or fall back to insert, creating duplicates on retry. Fix: deploy the field with `externalId: true` and a unique index, then re-test idempotency.
- [ ] Trap 3 — OAuth Username-Password flow for a server-to-server headless integration is the wrong OAuth grant. Username-Password sends credentials on every token request, cannot use MFA (which Salesforce is requiring for all users), and credentials stored in env vars are a secret-management risk. Fix: replace with JWT Bearer flow using a certificate stored in a connected app; rotate via certificate expiry, not credential rotation.
- [ ] Trap 4 — "Modify All Data" on the integration user's profile is FLS-blind: even with MAD, field-level security can restrict reads/writes to specific fields when Apex runs in user context (i.e., without `without sharing` + explicit FLS bypass). More critically, MAD is a blast-radius risk — a compromised integration credential can read/write every object. Fix: create a minimum-privilege permission set scoped to `Application__c` + required lookup objects; revoke MAD.
- [ ] Trap 5 — The retry loop in the middleware retries immediately up to five times synchronously. At burst volume (2,000/day in a short window) this can produce a thundering-herd of concurrent REST calls that exhaust Salesforce concurrent API limits (default 25 concurrent long-running requests) and the org's daily API call limit. Fix: implement exponential back-off with jitter in the retry; use Bulk API 2.0 for burst ingestion at enrollment time.
- [ ] No new errors introduced

**Reference — a competent redline:**
- Flags synchronous callout in trigger and prescribes `@future(callout=true)` or Queueable.
- Identifies missing `externalId` annotation as the idempotency root cause and provides the field metadata fix.
- Replaces Username-Password OAuth with JWT Bearer and explains MFA/credential-rotation rationale.
- Scopes integration user permission to minimum privilege; removes Modify All Data.
- Identifies thundering-herd retry pattern and specifies back-off + Bulk API for burst traffic.

---

## Task 2 — Sharing model design: multi-role nonprofit org spec

**Prompt to the agent:** Using the org spec below, design the complete sharing and access model. Specify OWD settings per object, the role hierarchy, sharing rules needed, and any Apex managed sharing or manual sharing requirements. Call out every gap or risk in the proposed approach, and explain what the architect gives up with each choice.

**Org spec:**

> **Org type:** Nonprofit on NPSP. ~120 internal users.
>
> **Objects in scope:** `Contact`, `Account` (HH and Org), `Application__c`, `Grant__c`, `Case`.
>
> **Business rules:**
> 1. Program Officers (POs) can see and edit only Applications they own.
> 2. Program Managers can see all Applications in their region but can only edit Applications owned by their direct reports.
> 3. Finance staff can see all Applications org-wide (read-only) for reporting.
> 4. Executive Director sees everything, edits everything.
> 5. `Grant__c` records are highly sensitive — only the owning PO and Finance should ever see them. No manager should have read access unless explicitly granted.
> 6. External contacts (applicants) have a Community/Experience Cloud login. They should see only their own `Application__c` and the `Case` records linked to their Application.
>
> **Proposed approach (from a senior developer for review):**
> - OWD for Application__c: Public Read/Write "so POs don't have sharing issues"
> - OWD for Grant__c: Public Read Only
> - Role hierarchy: ED → Regional Manager → Program Officer (3 levels)
> - No Apex sharing, no sharing rules — "the role hierarchy handles it"

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — OWD for `Application__c` set to Public Read/Write violates rule 1: POs would be able to edit any Application, not just their own. The correct OWD is Private (or Read/Write with role-hierarchy access), enforced by role hierarchy upward visibility plus criteria-based sharing rules for the Finance read-only requirement.
- [ ] Trap 2 — OWD for `Grant__c` set to Public Read Only violates rule 5: all managers and the ED would inherit read access via role hierarchy. `Grant__c` must be Private OWD; Finance access delivered via a sharing rule (criteria-based: all Grant records → Finance role, read-only); PO access is owner-default; ED access requires a separate sharing rule or Apex managed sharing (role hierarchy alone won't work when OWD is Private and the record owner is a PO below the ED if the field is Private — actually the role hierarchy DOES propagate upward, so ED inherits via hierarchy). Architect must recognize the hierarchy propagation vs. the "no manager access" rule tension and resolve it: if managers must be excluded, the role hierarchy cannot be used for Grant__c — Apex managed sharing or manual sharing with a collapsed hierarchy segment is required.
- [ ] Trap 3 — "No Apex sharing, no sharing rules" with a three-level role hierarchy does not satisfy rule 2 (managers can edit only direct-report-owned records) or rule 3 (Finance read-only). Role hierarchy grants read + edit upward by default. Criteria-based sharing rules are required for Finance read-only access; for the edit-restriction on managers, the OWD + role hierarchy cannot restrict edit to "direct reports only" — this requires Apex managed sharing to grant read to managers and withhold edit, or a permission set that removes edit permission at the profile level combined with sharing rules that grant read.
- [ ] Trap 4 — External (Experience Cloud) user access is not addressed at all in the proposed model. External users are governed by their own OWD (External Access on each object), the sharing set or sharing rules configured in Experience Cloud, and the guest user profile permissions. The design must specify: Application__c External OWD = Private, a Sharing Set granting each portal user access to their own Application__c records, and Case access via the related Application__c sharing set or a portal sharing rule.
- [ ] Trap 5 — Rule 4 ("ED sees everything, edits everything") appears satisfied by the role hierarchy, but NPSP's managed package objects and HH Account model have their own OWD settings that are outside the custom object model. The architect must note that NPSP enforces its own sharing on `npe01__OppPayment__c`, `npsp__Allocation__c`, etc., and that role hierarchy alone may not propagate through managed package objects without additional configuration.
- [ ] No new errors introduced

**Reference — a competent design:**
- Sets Application__c OWD to Private and uses role hierarchy for manager upward visibility, plus a criteria-based sharing rule for Finance read-only.
- Sets Grant__c OWD to Private, flags that role hierarchy conflicts with the "no manager read" rule, and specifies Apex managed sharing or a flattened hierarchy segment to enforce the exclusion.
- Specifies Experience Cloud sharing sets (not just OWD) for portal user access to Application__c and Case.
- Calls out the NPSP managed-package OWD caveat.
- Names what is given up: Apex managed sharing adds complexity and a DML/sharing recalculation cost; flattening the hierarchy removes natural upward visibility for other objects.
