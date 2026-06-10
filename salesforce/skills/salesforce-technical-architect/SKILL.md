---
name: salesforce-technical-architect
description: End-to-end Salesforce architecture and trade-off design — multi-org strategy, security and identity (SSO, OAuth, JWT Bearer, SAML, FLS), enterprise data modeling and LDV, solution architecture across clouds, integration patterns (Named Credentials, Platform Events, Bulk/REST API, middleware), governor-limit-aware design, and development-lifecycle/deployment governance. Use when designing or reviewing cross-cloud architecture, integration pipelines, access models, or org strategy. Not single-cloud config or hands-on coding (see the cloud-consultant and platform-developer skills). Scoped and benchmarked by the Certified Technical Architect (CTA) review-board blueprint.
metadata:
  credential: Salesforce Certified Technical Architect
  domain: salesforce
  type: certification-playbook
---

# Salesforce Certified Technical Architect (CTA) — Skills Reference

> This file is an **operational playbook**, not an exam outline. Each section states
> the actual rule, the concrete numbers, the decision criteria, and the anti-patterns
> to catch in review. When you make an architecture or implementation decision,
> apply these rules and use them to catch your own mistakes. Verify assumptions
> against the live org with describe/SOQL tooling before writing a mapper or trusting
> a UI tool's "success."

## Overview

The Salesforce Certified Technical Architect (CTA) is the pinnacle credential in the Salesforce ecosystem, held by fewer than 600 professionals globally. It validates the ability to design and implement secure, high-performance, integrated solutions on the Salesforce Lightning Platform at enterprise scale — and to defend those decisions under challenge before a panel of senior peers. Unlike every other Salesforce certification, the CTA is not a multiple-choice exam; it is a live architectural defense before three to four sitting CTAs who probe trade-offs, attack weak decisions, and score independently across seven domains.

The credential targets senior Salesforce architects with 5+ years of implementation experience, 3+ years in an architect role, and 2+ years leading Lightning Platform engagements. Earning it requires first completing the full Application Architect and System Architect credential stacks (eight underlying certifications), then passing a two-stage review board. Exam fees alone total $6,000; all-in cost including coaching and workshops commonly reaches $8,000–$20,000. Preparation typically spans 12–24 months after prerequisites are met.

The value of CTA-domain thinking is operational, not just the badge: it is exactly the discipline that keeps an integration pipeline correct, secure, and within governor limits. The rules below are written to be applied at decision time.

> **Verify steps assume nothing about your tooling** — use your project's Salesforce MCP connection, the Salesforce CLI (`sf`), or the Salesforce setup UI, in that order of preference.

---

Credential logistics and study path: see [references/study-resources.md](references/study-resources.md).

---

## System Architecture — operational rules

**Stay single-org unless you have a hard reason to split.** Split into multiple orgs ONLY for: legal/data-residency separation, distinct business units with zero shared data, or M&A integration timelines. For a small single-entity org, a single Salesforce org is correct and any "let's add an org" instinct is wrong. Splitting costs you cross-org reporting, duplicated security-model maintenance, and middleware to sync shared Contacts.

**Treat governor limits as design inputs, not runtime surprises.** Memorize the per-transaction ceilings and design under them:

| Limit | Synchronous | Asynchronous (Batch/Future/Queueable) |
|---|---|---|
| SOQL queries | 100 | 200 |
| SOQL rows returned | 50,000 | 50,000 |
| DML statements | 150 | 150 |
| DML rows | 10,000 | 10,000 |
| CPU time | 10,000 ms | 60,000 ms |
| Heap size | 6 MB | 12 MB |
| Callouts | 100 | 100 |
| Callout timeout (total) | 120 s | 120 s |

A REST/Bulk integration that upserts from an external system is bound by **API limits**, not Apex limits — but any **trigger/Flow Apex** that fires on a record change IS bound by the table above. When approval automation creates a parent record plus several child/relationship records in one transaction, that is multiple DML targets in one transaction; bulk-safe design matters even at low volume, because backfills re-toggle many records at once.

**Document management: files go to object storage, references go to Salesforce.** A sound rule for sensitive-document systems is to keep file bytes in external object storage (e.g. S3 with customer-managed encryption) and store only the key/reference in Salesforce — never file contents in Salesforce or in a NoSQL cache. When you DO surface a document inside Salesforce, the correct path is `ContentVersion` (the file bytes) → `ContentDocumentLink` (junction to the record). One `ContentDocument` can link to many records via multiple `ContentDocumentLink` rows — this is exactly how a late document upload re-links to both an application record and the related Contact.

**Anti-patterns / red flags:**
- Proposing a second org "for the portal" or "for testing" — the sandbox tier covers that.
- Storing file blobs as base64 in a long text field or in a NoSQL cache.
- Designing approval automation that loops record-by-record instead of operating on the trigger's collection.

**Verify:** enumerate the custom-object inventory before assuming a custom object exists; describe the object to confirm field count and types before writing a mapper.

---

## Security — operational rules

**Object access and Field-Level Security (FLS) are two separate gates. You need both.** Granting a profile/permset access to an object does NOT grant access to its fields. The most expensive lesson in this space: **SFDX `field-meta.xml` carries no FLS** — a freshly deployed custom field is invisible to everyone, including System Administrator, until a profile or permission set explicitly lists `<fieldPermissions>`. Symptom: SOQL returns *"Invalid field"* even with full object access. Fix: every non-required custom field must appear in a permset's `fieldPermissions`.

**Never put `<fieldPermissions>` on a required field.** Salesforce rejects the deploy with *"You cannot deploy to a required field"* — required fields are always visible/editable, so they must be **omitted** from `fieldPermissions`. A permset should list FLS for the non-required custom fields and skip the required ones.

**Use Permission Sets / Permission Set Groups, not Profiles, for grants.** Profiles are legacy. New access goes in a permission set so it is composable and removable without touching a user's base profile.

**JWT Bearer flow is the right pattern for a headless server → Salesforce integration.** It is server-to-server with no interactive login and no refresh-token storage. The private RSA key should live in a secrets store (e.g. SSM SecureString), never in env vars at rest, and be rotated annually.

OAuth flow decision table:

| Scenario | Flow |
|---|---|
| Server-to-server, no user (headless sweep/sync job) | **JWT Bearer** |
| Web app with backend that can keep a secret | Web Server (auth code) + PKCE |
| SPA / mobile, no secret | Auth code + PKCE (never implicit/User-Agent) |
| Machine client with its own SF identity | Client Credentials |

**External Client App (ECA) permission assignment lives on the ECA, not the permission set.** In modern org configs, Connected App *creation* can be blocked (Salesforce returns *"You can't create a connected app… contact Customer Support"*), pushing you to an **External Client App**. The classic Permission Set "Assigned Connected Apps" page does NOT authorize ECA usage. The working path is: **ECA detail → Policies tab → Edit → App Policies → Select Permission Sets.** Browser-AI tools will edit the wrong page and report success — verify via API before trusting it. Note also that an ECA's Consumer Key is UI-only (behind email verification) and not exposed via any API.

**No PII or sensitive data in logs. Ever.** Log record IDs and identity subject IDs only — never names, addresses, DOB, medical/financial fields, or file contents. A log line that interpolates a Contact field is a red flag to reject in review.

**Anti-patterns / red flags:**
- Assuming object access implies field access (the #1 FLS scar).
- Adding `<fieldPermissions>` for a required field (deploy will fail).
- Implicit/User-Agent OAuth flow for any new client.
- Trusting an ECA assignment because a UI tool said "success" without API verification.
- Any new field that writes to Contact but is missing from a FLS permset.

**Verify:** after deploying a field, SOQL-select it — an *"Invalid field"* error means FLS is missing, not that the field failed to create. Confirm a permset assignment landed by querying `PermissionSetAssignment` / `SetupEntityAccess` rather than reading a UI page.

---

## Data — operational rules

**A single object + a `Type__c` discriminator can beat one-object-per-variant.** Using one object with a type picklist (e.g. application variants) rather than several near-identical objects keeps the Apex mapper, IaC, and schema-sync simple. The trade-off is a wide object; pair with Record Types for per-type page layouts when needed. Choose deliberately and record the decision so it isn't relitigated.

**Discrete columns over JSON when staff need to report.** Make type-specific fields real columns, not a JSON blob, whenever the stakeholder requirement is reportability ("we need to run reports on it"). Use JSON only for genuinely free-form, never-reported nested data (e.g. a companions/contacts array that automation then extracts into discrete fields on approval).

**String field max-lengths must come from a generated schema, never hand-picked.** Any input-validation (e.g. Zod) string field that ultimately writes to a Salesforce field on approval should derive its `max(...)` from a generated length constant (and picklist enums from a generated picklist constant), produced by a sync script that reads the org's metadata. **Never hand-edit the generated files.** When SF metadata changes, regenerate and commit. Apex truncation (a `fit()`-style helper) is a last-line fallback for legacy/direct-API records, NOT a substitute for validating at the form/service boundary — silent truncation is data loss.

**Lookup `relationshipName` must be unique per parent object.** Two lookups to the same parent object cannot share a `relationshipName` (deploy fails: *"Duplicate relationship name"*). Use role-specific suffixes. SOQL parent traversal (`Parent__r.Name`) keys on the **field name**, not `relationshipName`, so renaming the relationship is safe.

**Selective SOQL at volume.** Filter on indexed fields (Id, Name, external IDs, lookups, audit fields, custom-indexed). A non-selective query over a Large Data Volume object hits the *"non-selective query against large object"* error at ~200k+ rows. Keep the idempotency external ID indexed and filter on it.

**Master-detail vs lookup decision:**

| Need | Choice |
|---|---|
| Roll-up summaries, cascade delete, child can't exist alone | Master-detail |
| Independent lifecycle, optional parent, cross-object reparenting | Lookup |
| Long-lived person record + immutable audit record referencing it | Lookup |

**Anti-patterns / red flags:**
- Hand-editing a generated schema file (it's generated).
- A Zod `max()` literal number that doesn't trace to the generated length constant.
- Two lookups to the same object sharing a `relationshipName`.
- Relying on Apex truncation as the primary length guard instead of boundary validation.

**Verify:** describe `Contact` (or the target object) to read current field length / picklist values before changing a form field; if they differ from the generated file, the file is stale — regenerate. SOQL-spot-check that external-ID upsert idempotency held (no duplicate records for one logical submission).

---

## Solution Architecture — operational rules

**Declarative-first, escalate to code only when declarative genuinely can't do it.** Default to configuration; reach for Apex when you need bulk-safe complex logic, callouts with rollback, or behavior that Flow can't express cleanly. Be ready to answer "why not Flow?" and "why not Apex?" for every choice.

Automation tool selection:

| Need | Use | Avoid |
|---|---|---|
| Field-level data-entry constraint | Validation Rule | a trigger |
| Record-change automation, declarative | Record-Triggered Flow | Workflow Rules / Process Builder (both deprecated) |
| Screen-guided user input | Screen Flow | custom LWC unless UX demands it |
| Scheduled batch logic | Schedule-Triggered Flow or Batch Apex | future methods in a loop |
| Complex multi-object logic, bulk DML, callouts-with-rollback | Apex (trigger handler / Queueable) | overstuffed giant Flow |
| Approval routing | Approval Process / Flow | hand-rolled status Apex |

**One trigger per object, logic in a handler class.** Triggers must be bulk-safe: no SOQL/DML inside a `for` loop. Query once into a `Map<Id, SObject>`, iterate in memory, collect into a `List`, DML once. Recursion-guard with a static boolean. Approval handlers that copy fields to a Contact should be **additive** — role flags are OR-merged, never overwritten to `false` on re-approval.

**Design around the managed package, don't fight it.** NPSP ships its own triggers/automation in the `npe01`/`npsp` namespaces. You cannot edit managed Apex; you design your automation to coexist. A common scar: a managed workflow rule silently overwrites a standard field (e.g. copying `Phone → MobilePhone` based on a managed `PreferredPhone` default) on every insert. The fix is a config change — deactivate the managed workflow rule in Setup — not code. Always suspect managed-package automation when a field changes value with no code of yours touching it.

**Quick Action cache-bust trick.** Adding fields to an existing Quick Action via SFDX updates the metadata, but the runtime QA cache (driving Lightning contextual tabs via `console:relatedRecord`) often does NOT invalidate — even after logout/login. The new fields are silently absent with no error. Fix: edit any non-field-list metadata on the QA (`<description>`, `<label>`, `<layoutSectionStyle>`) and redeploy; SF treats it as a structural change and flushes the cache.

**Anti-patterns / red flags:**
- SOQL or DML inside a `for` loop body (the cardinal bulkification sin).
- More than one trigger on the same object.
- A new deprecated Workflow Rule or Process Builder.
- Overwriting a Contact role flag to `false` on a re-approval (must be additive).
- Adding QA fields and not seeing them render — then concluding the deploy failed, when it's the QA cache.

**Verify:** describe the object to confirm a new field exists and is the right type after deploy; query a real Contact to confirm approval automation set role flags and mirrored fields correctly; run a report / SOQL to confirm staff-facing reportability of discrete columns.

---

## Integration — operational rules

**Match the pattern to latency + reliability, not to convenience.**

| Requirement | Pattern | Salesforce mechanism |
|---|---|---|
| Caller needs an answer now | Request-Reply (sync) | REST/SOAP callout, Composite API |
| Don't block the user; deliver eventually | Fire-and-Forget (async) | Platform Events, future/Queueable |
| Large batch load/extract | Batch Data Sync | Bulk API 2.0 |
| External system pushes into SF | Remote Call-In | inbound REST, Bulk API |
| Near-real-time SF→external on change | Event-driven, no polling | Change Data Capture / Platform Events |

**Idempotency via external-ID upsert is mandatory.** Upsert keyed on a stable external ID (e.g. a submission ID) so a retried job does not create duplicates. Any new write path must reuse that key — a late re-link by the same external ID needs no new SF write logic.

**Resilience: on SF write failure, persist and alert — do not silently drop.** A sound pattern: the caller catches the SF error, writes the full payload to durable storage (e.g. object storage), and alerts staff; a converter turns it into an import-ready row (e.g. an NPSP Data Import CSV). Consider 3-try exponential backoff before falling to manual. Never let a write succeed to the user but vanish before reaching Salesforce with no trace.

**API-limit awareness for the integration user.** Bulk API 2.0 is the right tool for any multi-thousand-row load (imports, backfills); it batches server-side and respects daily API limits far better than row-by-row REST. The daily API request allowance scales with licenses — design imports to use Bulk, not thousands of individual REST upserts.

**Authentication for outbound SF→external callouts: Named Credentials + External Credentials.** Never hard-code endpoints or secrets in Apex. (Inbound, headless integrations use JWT Bearer; outbound-from-SF uses Named Credentials.)

**Anti-patterns / red flags:**
- Row-by-row REST upserts where Bulk API 2.0 belongs.
- A write path that doesn't key on the external ID (breaks idempotency, risks duplicates).
- A submit flow that can lose data on SF failure with no durable fallback + staff alert.
- Polling Salesforce on a timer where CDC/Platform Events would deliver on change.
- Endpoints or credentials hard-coded in Apex instead of Named Credentials.

**Verify:** after a test write, SOQL-confirm exactly one record landed for the external ID; re-run the job and confirm the count stays at one (idempotency proof). A fast JWT smoke chain (auth → describe → upsert idempotency → cleanup) should run after any metadata or cert change.

---

## Development Lifecycle & Deployment — operational rules

**SFDX is source of truth; deploy from the SFDX project root.** All `sf project …` commands must run from the SFDX project root or they fail with *"InvalidProjectWorkspaceError"*. The metadata under `force-app/main/default/` is canonical; the org is downstream of it.

**Apex requires ≥75% code coverage org-wide to deploy to production** (and every trigger must have at least some coverage). Test with `Test.startTest()`/`Test.stopTest()` to get a fresh set of governor limits and force async to run; use `@TestSetup` for shared fixtures; mock callouts with `HttpCalloutMock`. Tests must assert behavior, not just execute lines.

**Treat production Salesforce as off-limits for incidental deploys; do metadata work in a sandbox.** Production cutover is a separate, planned, documented event, not an incidental deploy.

**Run a smoke test after any metadata, cert, or sandbox change.** A fast JWT/metadata smoke script catches the FLS, required-field, relationshipName, and JWT gotchas at the layer they bite, in seconds. Keep a known-good end-to-end baseline (e.g. an E2E harness count) and treat regressions as blockers.

**Sandbox-bringup gotchas to pre-empt:** some org policies require a Public Group (with the admin as member) before sandbox creation. NPSP managed package must be installed before metadata deploy. Partial-copy sandboxes carrying NPSP data can fire NPSP automation unexpectedly on load.

**Destructive changes need a plan.** Field deletion, permset removal, and JSON-to-discrete migrations can drop data. Sequence: backfill → verify → destructive deploy → re-verify. Never destructive-deploy before the data it would orphan has been migrated.

**Commit-and-push discipline.** After each completed logical change: verify lint + build pass, then commit with a Conventional Commit message and push. Never commit broken code. Branch first if on the default branch.

**Anti-patterns / red flags:**
- Running `sf project deploy` from the repo root instead of the SFDX root.
- An incidental change against production Salesforce.
- A destructive metadata deploy with no backfill/verification step ahead of it.
- Apex shipped with line-touching tests that assert nothing.
- Skipping the smoke test after a cert rotation or metadata change.

**Verify:** describe/SOQL post-deploy to confirm metadata landed AND is queryable (catches the FLS-missing case the deploy itself won't surface). Confirm idempotency and role-flag correctness before considering a change done.

---

## Sharing & Identity — operational rules

**Sharing model layers stack, from most restrictive to least.** OWDs (org-wide defaults) set the floor; Roles + Hierarchy open upward; Sharing Rules add lateral access; Manual Sharing and Apex Sharing add case-by-case. A common board trap: an OWD of Private plus a Sharing Rule "owned by members of a Role" is correct for lateral grant — but Role Hierarchy alone propagates upward, not sideways.

**SSO decision table:**

| Scenario | Protocol | Notes |
|---|---|---|
| Enterprise IdP owns all identity (ADFS, Okta, Azure AD) | SAML 2.0 (SF as SP) | Salesforce is the Service Provider; IdP issues the assertion |
| Modern IdP with OIDC support | OpenID Connect | Token-based; SF acts as an OIDC client |
| SF → external app (SF as IdP) | Outbound SAML | Reversed direction — SF issues; external app consumes |
| Legacy / no external IdP | Salesforce identity only | No delegation needed; avoid unless truly standalone |

**Delegated Authentication pushes the password check to an external web service you own.** It replaces Salesforce's own check; the credential never lives in Salesforce at all. Use only when a corporate directory must remain the sole credential store and SAML is not feasible.

**Experience Cloud sharing is Experience-only.** Guest user OWD controls what an unauthenticated visitor can read/write; authenticated community users follow standard sharing plus sharing sets or share groups. Never grant a Guest User write access to objects beyond what the experience explicitly requires — that is an audit finding.

**Anti-patterns / red flags:**
- Mixing up SF-as-SP (inbound SSO) and SF-as-IdP (outbound) directions.
- Relying on Role Hierarchy for lateral data access (it's upward only).
- Guest User with edit/delete on sensitive objects.
- Delegated Auth endpoint that can be called without IP allowlist.

---

## Well-Architected & Multi-Cloud — operational rules

**Score every proposal against Trusted / Easy / Adaptable.** The Salesforce Well-Architected framework is the explicit rubric the board uses. Every design choice should be defensible on all three axes: Trusted (secure, compliant, reliable), Easy (usable, supportable, low friction), and Adaptable (scalable, extensible, future-proof). When a trade-off sacrifices one axis, name it.

**MuleSoft is a managed middleware layer, not glue code.** Use MuleSoft (Anypoint) when you need an enterprise API mesh: multi-protocol transformation, centralized auth enforcement, reusable APIs across systems. Avoid when the integration is a single point-to-point SF→system sync — Named Credentials + Queueable or a simple Lambda covers that with far less overhead.

**Data Cloud (formerly CDP) owns the Unified Profile.** When the requirement is a 360 customer profile across Marketing Cloud, Commerce Cloud, and CRM, Data Cloud is the architectural answer, not custom ETL. Data Streams ingest, Identity Resolution merges, Calculated Insights publish back to CRM. For an AI use-case, Agentforce Agents consume Data Cloud Unified Profiles via grounding — not raw SOQL across systems.

**Marketing Cloud integration pattern:** Marketing Cloud Connect links a single Business Unit to a single SF org. Synchronized Data Extensions mirror standard CRM objects (Contact, Lead, Campaign). For custom objects, use Automation Studio + API or Data Cloud as the bridge. Never assume Marketing Cloud SQL queries run in real-time against CRM data — they run on synchronized copies.

**Anti-patterns / red flags:**
- Proposing MuleSoft for a simple one-to-one SF↔system sync.
- Custom ETL pipeline where Data Cloud + Identity Resolution is the correct answer.
- Assuming Marketing Cloud sees live CRM data — it sees synchronized copies.
- A Well-Architected presentation that ignores the Easy or Adaptable axes.

---

## Communication — operational rules

**Frame every decision as "we chose X over Y because Z, accepting risk R."** Don't cite "Salesforce best practice" as the reason — name the trade-off. Example: "Single application object with a type discriminator over several objects, because it keeps the Apex mapper and schema-sync simple; accepting a wide object."

**Translate to the audience.** For a non-technical executive or board, express decisions in cost, risk, and time-saved terms — not governor limits. Keep the FLS/limits depth for technical readers. The same decision needs two framings.

**Surface blockers early with a proposed mitigation, never just "blocked."** Licensing gaps, approaching limits, an ECA Consumer Key that's UI-only and behind email verification (no scriptable path) — flag these the moment they appear, with the workaround.

**Record decisions so they aren't relitigated.** A "decisions worth not relitigating" log plus a session log is a lightweight ADR mechanism — when you settle a trade-off, write it down.

**Anti-patterns / red flags:**
- "Best practice" with no stated trade-off.
- Same technical depth for the board and for engineers.
- Reporting a blocker with no proposed path forward.

---

## Decision scenarios

Five original teaching scenarios covering the highest-value operational gotchas across CTA domains.

---

**Scenario 1 — FLS invisible after deploy**

**Situation:** A developer deploys a new custom field `Application__c.ReviewScore__c` via SFDX and confirms the deploy succeeded. A test SOQL query immediately returns `"INVALID_FIELD: No such column 'ReviewScore__c' on entity 'Application__c'"`. The field definitely exists in the org's Setup UI.

**Competent move:** Recognize this as the FLS gap, not a deployment failure. The field-meta.xml carries no FLS by default — the field exists but is visible to no profile/permset yet. Add the field to the relevant permission set's `<fieldPermissions>` (with both `<readable>true</readable>` and `<editable>true</editable>` for non-required fields), deploy the permset, then re-run the SOQL.

**Tempting-but-wrong:** Re-deploy the field or check the field's `required` flag. Neither helps. The deploy didn't fail; the field is present. The missing layer is FLS, which is a separate metadata artifact from the field itself.

**Verify:** Run `SELECT ReviewScore__c FROM Application__c LIMIT 1` as the integration user. Error means FLS still missing. Success, even returning null, confirms FLS is granted. Query `SetupEntityAccess` to confirm the permset assignment landed.

---

**Scenario 2 — OWD + Role Hierarchy misread as lateral sharing**

**Situation:** A regional manager needs read access to all Opportunities owned by members of her peer region's role — a lateral relationship, not a reporting one. The architect proposes: "OWD = Private; her role sits at the same tier as the peer role. The Role Hierarchy will propagate access upward through the org, so her manager will also see both regions. That satisfies the requirement."

**Competent move:** Role Hierarchy propagates access upward through the hierarchy (parent roles see what child roles own), not sideways. The regional manager's role does not inherit records owned by a peer role. The correct mechanism is a **Sharing Rule** of type "owned by members of a Role" pointing at the source role, granting read to the target role. This is lateral access — precisely what Sharing Rules exist for.

**Tempting-but-wrong:** Treating Role Hierarchy as a general "nearby roles can see each other" mechanism. It is strictly upward. A manager who reports above both regions will gain access via hierarchy, but peer roles will not — designing the solution on this assumption silently breaks the requirement.

**Verify:** After configuring the Sharing Rule, log in as a user in the target role and SOQL-query an Opportunity owned by a user in the source role. Confirm visibility. Confirm the reverse direction does not automatically apply unless a reciprocal rule exists.

---

**Scenario 3 — Trigger bulkification failure on backfill**

**Situation:** An `OpportunityLineItem` after-insert trigger runs a SOQL query and a DML update inside a `for (OpportunityLineItem item : Trigger.new)` loop to sync a pricing field to the parent Opportunity. In unit tests (1–2 records) everything passes. A data backfill loads 5,000 records at once and the org hits `"System.LimitException: Too many SOQL queries: 101"` and rolls back.

**Competent move:** Rewrite the trigger to be bulk-safe: collect all parent Opportunity IDs from `Trigger.new` into a `Set<Id>`, query all parents in a single SOQL into a `Map<Id, Opportunity>`, compute updates in memory, then perform a single DML on the collected list. Move logic into a handler class. Add a static boolean recursion guard if the trigger could fire on the Opportunity update it makes.

**Tempting-but-wrong:** Increasing the batch size to "something smaller" or switching to a future method. A future method moves the problem to async but does not fix the per-iteration SOQL — and a future called inside a trigger iterating 5,000 records will hit the future call limit (50 per transaction). The root fix is bulkification, not async deferral.

**Verify:** After refactoring, write a test that inserts 200 `OpportunityLineItem` records in a single `insert` call and assert that `Limits.getQueries()` remains well below 100 after the trigger fires. Run the test with `Test.startTest()`/`Test.stopTest()` to isolate the trigger's limit consumption.

---

**Scenario 4 — ECA assignment confirmed by UI, integration fails**

**Situation:** A developer configures a JWT Bearer integration using an External Client App. They grant access by going to the Permission Set detail page, clicking "Assigned Connected Apps," selecting the ECA, and clicking Save. The UI confirms the assignment. The integration service calls the token endpoint and receives `"invalid_client_id"`.

**Competent move:** The classic ECA trap. The "Assigned Connected Apps" section on a Permission Set page does NOT govern External Client Apps — it is for legacy Connected Apps only. For an ECA, the assignment path is: **ECA detail page → Policies tab → Edit → App Policies → Select Permission Sets → add the permset → Save**. Go directly there and make the assignment; do not rely on the permset page.

**Tempting-but-wrong:** Re-generating the Consumer Key or re-uploading the certificate. The credential itself is fine — the error is an authorization gap, not a credential mismatch. Also wrong: trusting the UI confirmation on the permset page; the UI accepted the action but it had no effect for an ECA.

**Verify:** After correcting the assignment on the ECA Policies tab, run the JWT token flow end-to-end: sign the assertion, POST to the token endpoint, confirm a `200` with an `access_token`. Then SOQL-query `SetupEntityAccess` where `SetupEntityType = 'ExternalClientApplication'` to confirm the record exists, rather than reading any UI page.

---

**Scenario 5 — Multi-cloud architecture: Data Cloud vs. custom ETL**

**Situation:** A retail enterprise has customer purchase data in Commerce Cloud, engagement data in Marketing Cloud, and service cases in Sales/Service Cloud. A VP asks for a "360-degree customer view" with AI-driven next-best-action surfaced to service reps. The architect proposes building a nightly ETL to copy all three data sources into a custom `UnifiedCustomer__c` object in the CRM and run a batch Apex job to score customers.

**Competent move:** This is a canonical Data Cloud use case, not a custom ETL problem. Data Cloud's Data Streams ingest from all three clouds natively; Identity Resolution creates a Unified Individual profile by matching on email/phone/cookie; Calculated Insights derive the scoring metric; and Agentforce Agents or Einstein Next Best Action consume the Unified Profile via grounding — zero custom ETL, no stale batch copies, no custom object to maintain. Propose Data Cloud as the architectural layer and explain why: out-of-box connectors, Identity Resolution replaces hand-rolled dedup logic, and it is the platform's intended 360-profile answer.

**Tempting-but-wrong:** The custom ETL + batch Apex design is not wrong in isolation, but it ignores the platform capability that exists for this exact requirement. In a board session, proposing custom-built solutions where a Salesforce product directly covers the need — without even mentioning that product — is scored as an architectural gap. The temptation is to solve the technical problem; the correct instinct is to first ask "is there a platform answer?"

**Verify:** Confirm Data Cloud licensing is included or procured before committing to this architecture — it is a separate SKU. Validate that the specific Commerce Cloud and Marketing Cloud connectors (Data Streams) cover the data sources in the scenario. Then prototype a Data Stream and Identity Resolution ruleset in a sandbox before presenting the design as final.

---

## Operational Rules Quick Reference

Read this first. Each is imperative and concrete.

- **DO** treat governor limits as design inputs: 100 SOQL / 50k rows / 150 DML / 10k DML rows / 10s CPU per sync transaction.
- **DON'T** put SOQL or DML inside a `for` loop — query into a Map, DML once. This is the #1 review red flag.
- **DO** add `<fieldPermissions>` to a permset for every new non-required custom field — SFDX field-meta grants FLS to no one.
- **DON'T** add `<fieldPermissions>` for a `<required>true</required>` field — the deploy will fail.
- **DO** use Permission Sets / Permission Set Groups for all new access; Profiles are legacy.
- **DON'T** assume object access implies field access — they are separate gates.
- **DO** use JWT Bearer for a headless service→SF integration; key in a secrets store, rotated annually.
- **DO** assign External Client App access on the ECA (Policies → App Policies → Select Permission Sets), not on the permset page.
- **DON'T** trust a UI tool's "success" on an ECA assignment — verify via `PermissionSetAssignment` / `SetupEntityAccess`.
- **DO** key every SF write on a stable external ID for idempotent upsert; verify exactly one record after a retried job.
- **DON'T** do row-by-row REST for bulk loads — use Bulk API 2.0.
- **DO** persist failed writes to durable storage + alert staff; never silently drop a SF write failure.
- **DO** source string `max()` lengths from a generated length constant; regenerate via the schema-sync script.
- **DON'T** hand-edit the generated schema file, and don't rely on Apex truncation as the primary length guard.
- **DO** give each lookup to the same parent a unique `relationshipName` (role-suffixed).
- **DO** keep one trigger per object with logic in a bulk-safe handler; make role-flag writes additive, never overwriting to false.
- **DON'T** create new Workflow Rules or Process Builders — they're deprecated; use Record-Triggered Flow or Apex.
- **DO** suspect NPSP managed-package automation (`npe01`) when a field changes with no code of yours involved.
- **DO** bust the Quick Action cache by editing non-field metadata (`<description>`) and redeploying when new QA fields don't render.
- **DO** run all `sf project` commands from the SFDX project root, never the repo root.
- **DON'T** make incidental deploys to production Salesforce — sandbox only; cutover is a separate planned event.
- **DON'T** destructive-deploy before backfilling and verifying the data it would orphan.
- **DO** run a JWT/metadata smoke test after any metadata/cert/sandbox change; keep the E2E baseline green.
- **DON'T** log PII or sensitive data — record IDs and identity subjects only.
- **DO** verify metadata is *queryable* post-deploy (SOQL), not just that it "deployed" — that catches missing FLS.

> For org-specific applications of these rules, see a per-org appendix you maintain in your own project, referenced from a CLAUDE.md.

---

## Study resources & relevance

Study resources (official Salesforce + community) and the NPSP/Nonprofit Cloud relevance notes are kept in [references/study-resources.md](references/study-resources.md) so this skill stays focused on operational rules. Load that file when planning a study path or mapping these rules to a nonprofit org.

---

*Independent educational content to upskill AI agents. Not affiliated with, authorized by, endorsed by, or sponsored by Salesforce, Inc. or any certification body. "Salesforce," "Salesforce Certified Technical Architect," "CTA," "NPSP," "Agentforce," "MuleSoft," "Data Cloud," and all related trademarks and product names are the property of their respective owners and are used here solely for identification purposes. Content is provided as-is for guidance only — verify all rules, limits, fees, and procedures against official Salesforce documentation and your live org before acting. No certification outcome is implied or guaranteed. Governor limits, exam fees, and product capabilities are subject to change; check the official exam guide and release notes for current values.*
