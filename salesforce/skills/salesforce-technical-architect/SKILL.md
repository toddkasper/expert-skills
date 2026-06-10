---
name: salesforce-technical-architect
description: End-to-end Salesforce architecture and trade-off design — multi-org strategy, security and identity (SSO, OAuth, JWT Bearer, SAML, FLS), enterprise data modeling and LDV, solution architecture across clouds, integration patterns (Named Credentials, Platform Events, Bulk/REST API, middleware), governor-limit-aware design, and development-lifecycle/deployment governance. Use when designing or reviewing cross-cloud architecture, integration pipelines, access models, or org strategy. Not single-cloud config or hands-on coding (see the cloud-consultant and platform-developer skills). Scoped and benchmarked by the Certified Technical Architect (CTA) review-board blueprint.
metadata:
  credential: Salesforce Certified Technical Architect
  domain: salesforce
  type: certification-playbook
  status: current
  last-reviewed: 2026-06-09
  blueprint-verified: 2026-06-07
---

# Salesforce Certified Technical Architect (CTA) — Skills Reference

## Overview

The Salesforce Certified Technical Architect (CTA) is the pinnacle credential in the Salesforce ecosystem. It validates the ability to design and implement secure, high-performance, integrated solutions on the Salesforce Lightning Platform at enterprise scale — and to defend those decisions under challenge before a panel of senior peers. Unlike every other Salesforce certification, the CTA is not a multiple-choice exam; it is a live architectural defense before three to four sitting CTAs who probe trade-offs, attack weak decisions, and score independently across seven domains.

**This file is an operational playbook, not an exam outline.** Each section states the actual rule, the concrete numbers, the decision criteria, and the anti-patterns to catch in review. When you make an architecture or implementation decision, apply these rules and use them to catch your own mistakes. Verify assumptions against the live org with describe/SOQL tooling before writing a mapper or trusting a UI tool's "success."

> **Load this skill when…** designing cross-cloud or multi-org architecture; reviewing integration patterns (API choice, auth flow, idempotency); evaluating org strategy (single vs. multi-org); reviewing security models at the architecture level (SSO/OAuth, identity federation, FLS design across systems).
> **Not this skill:** single-cloud configuration (cases, flows, console) → see the cloud-consultant skills; Apex/LWC coding → see `salesforce-platform-developer-1` / `salesforce-platform-developer-2`.

> **Verify steps assume nothing about your tooling** — use your project's Salesforce MCP connection, the Salesforce CLI (`sf`), or the Salesforce setup UI, in that order of preference.

---

Credential logistics and study path: see [references/study-resources.md](references/study-resources.md).

---

## Uncertainty & Escalation

- **Always re-verify live:** `[volatile — verify live]` items include: Salesforce governor limit values (they are updated between releases), Bulk API 2.0 daily API allocation formulas, OAuth flow support in External Client Apps vs. Connected Apps, and Data Cloud / MuleSoft feature availability per license edition.
- **Live wins:** when this file and the live org, release notes, or official docs disagree — for example, a governor limit that has changed in a recent release — trust the live system and flag this skill as stale via the Feedback protocol below.
- **Escalate to a human:** surface — never silently execute — any operation that is irreversible, crosses a security boundary, or has compliance or spend implications: production data-model or sharing changes (object deletion, field removal, OWD tightening), security-boundary modifications (JWT key rotation, ECA policy changes, permission escalation for an integration user), destructive deploys, and any architecture decision that trades off the Trusted axis of Well-Architected.
- **Confidence taxonomy:** every fact in this file is considered stable unless tagged `[volatile — verify live]` or `[opinion — house style]`.

Inline volatile tags applied:
- Synchronous governor limits table `[volatile — verify live]` — Salesforce adjusts limits between major releases; verify against the current Apex Developer Guide before using these numbers in a capacity design.
- Daily API allocation formula `[volatile — verify live]` — Bulk API daily limits scale with license count per a formula Salesforce updates; check the current limits documentation.
- External Client App (ECA) UI workflow `[volatile — verify live]` — ECA Policies tab path and Connected App migration behavior change with each release; confirm in your org's current Setup UI.
- Data Cloud identity resolution and Calculated Insights behavior `[volatile — verify live]` — Data Cloud feature set evolves rapidly; verify feature availability and configuration steps in the current Data Cloud documentation.

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

A REST/Bulk integration that upserts from an external system is bound by **API limits**, not Apex limits — but any **trigger/Flow Apex** that fires on a record change IS bound by the table above. When approval automation creates a parent record plus several child/relationship records in one transaction, that is multiple DML targets; bulk-safe design matters even at low volume, because backfills re-toggle many records at once.

**Document management: files go to object storage, references go to Salesforce.** Keep file bytes in external object storage (e.g. S3 with customer-managed encryption) and store only the key/reference in Salesforce. When you DO surface a document inside Salesforce, use `ContentVersion` → `ContentDocumentLink` (junction to the record). One `ContentDocument` can link to many records via multiple `ContentDocumentLink` rows.

**Red flags:** second org "for the portal" (sandbox covers it); file blobs as base64 in a long-text field; approval automation that loops record-by-record.

**Verify:** enumerate the custom-object inventory before assuming an object exists; describe the object to confirm field count and types before writing a mapper.

---

## Security — operational rules

**Object access and Field-Level Security (FLS) are two separate gates. You need both.** Granting a profile/permset access to an object does NOT grant access to its fields. The most expensive lesson in this space: **SFDX `field-meta.xml` carries no FLS** — a freshly deployed custom field is invisible to everyone, including System Administrator, until a profile or permission set explicitly lists `<fieldPermissions>`. Symptom: SOQL returns *"Invalid field"* even with full object access. Fix: every non-required custom field must appear in a permset's `fieldPermissions`.

**Never put `<fieldPermissions>` on a required field.** Salesforce rejects the deploy with *"You cannot deploy to a required field"* — required fields are always visible/editable, so they must be **omitted** from `fieldPermissions`. A permset should list FLS for the non-required custom fields and skip the required ones.

**Use Permission Sets / Permission Set Groups, not Profiles, for grants.** Profiles are legacy. New access goes in a permission set so it is composable and removable without touching a user's base profile.

**JWT Bearer for headless server → SF integration.** Server-to-server, no interactive login, no refresh-token storage. Private RSA key in a secrets store (e.g. SSM SecureString), never in env vars, rotated annually.

OAuth flow decision table:

| Scenario | Flow |
|---|---|
| Server-to-server, no user | **JWT Bearer** |
| Web app with backend secret | Web Server (auth code) + PKCE |
| SPA / mobile, no secret | Auth code + PKCE (never implicit/User-Agent) |
| Machine client with its own SF identity | Client Credentials |

**External Client App (ECA) permission assignment lives on the ECA, not the permission set.** Connected App *creation* can be blocked in modern orgs, pushing you to an ECA. The classic "Assigned Connected Apps" section on a permset page does NOT govern ECAs. Working path: **ECA detail → Policies tab → Edit → App Policies → Select Permission Sets.** Browser-AI tools edit the wrong page and report success — verify via `SetupEntityAccess` query before trusting it. An ECA's Consumer Key is UI-only (behind email verification) and not exposed via any API.

**No PII or sensitive data in logs. Ever.** Log record IDs and identity subject IDs only.

**Red flags:** assuming object access implies field access; `<fieldPermissions>` on a required field (deploy fails); implicit/User-Agent OAuth flow; trusting a UI tool's "success" on ECA assignment; new Contact-writing field missing from FLS permset.

**Verify:** after deploying a field, SOQL-select it — *"Invalid field"* = FLS missing, not deploy failure. Confirm permset assignment via `PermissionSetAssignment` / `SetupEntityAccess`, not the UI.

---

## Data — operational rules

**Single object + `Type__c` discriminator over one-object-per-variant** when variants are structurally similar — keeps mapper, IaC, and schema-sync simple. Trade-off: wide object. Pair with Record Types for per-type page layouts.

**Discrete columns over JSON when staff need to report.** JSON only for genuinely free-form, never-reported nested data.

**String field max-lengths from a generated schema, never hand-picked.** Derive `max(...)` from a sync script reading the org's metadata. Never hand-edit the generated files. Apex truncation is a last-line fallback for legacy/direct-API records, NOT a substitute for boundary validation.

**Lookup `relationshipName` must be unique per parent object.** Two lookups to the same parent can't share a `relationshipName` (deploy fails: *"Duplicate relationship name"*). Use role-specific suffixes. SOQL traversal keys on field name, not relationshipName, so renaming is safe.

**Selective SOQL at volume.** Filter on indexed fields. A non-selective query over an LDV object hits the *"non-selective query against large object"* error at ~200k+ rows.

| Need | Choice |
|---|---|
| Roll-up summaries, cascade delete, child must have parent | Master-detail |
| Independent lifecycle, optional parent, reparenting | Lookup |

**Red flags:** hand-editing a generated schema file; a `max()` literal not tracing to a generated constant; two lookups to the same object sharing a `relationshipName`; Apex truncation as the primary length guard.

**Verify:** describe the target object to read current field length / picklist values before changing a form field; if they differ from the generated file, regenerate. SOQL-spot-check external-ID upsert idempotency (no duplicates on retry).

---

## Solution Architecture — operational rules

**Declarative-first, escalate to code only when declarative genuinely can't do it.** Default to configuration; reach for Apex when you need bulk-safe complex logic, callouts with rollback, or behavior Flow can't express cleanly.

| Need | Use | Avoid |
|---|---|---|
| Field data-entry constraint | Validation Rule | trigger |
| Record-change automation | Record-Triggered Flow | Workflow Rules / Process Builder (deprecated) |
| Screen-guided input | Screen Flow | custom LWC unless UX demands it |
| Scheduled batch | Schedule-Triggered Flow or Batch Apex | future methods in a loop |
| Complex multi-object, callouts | Apex handler / Queueable | overstuffed Flow |
| Approval routing | Approval Process / Flow | hand-rolled status Apex |

**One trigger per object, logic in a handler class.** Bulk-safe: no SOQL/DML inside a `for` loop. Query once into a `Map`, iterate in memory, collect into a `List`, DML once. Recursion-guard with a static boolean. Approval handlers copying fields to a Contact must be **additive** — role flags OR-merged, never overwritten to `false` on re-approval.

**Design around the managed package, don't fight it.** Managed packages ship their own triggers/automation in namespaced Apex you cannot edit — design your automation to coexist. When a field changes value with no code of yours touching it, suspect managed-package automation first. The fix is usually deactivating the offending rule in Setup, not writing counter-code. See [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md) for NPSP specifics.

**Quick Action cache-bust trick.** Adding fields to an existing Quick Action via SFDX updates the metadata, but the runtime QA cache does NOT invalidate — even after logout/login. New fields are silently absent. Fix: edit any non-field-list metadata on the QA (`<description>`, `<label>`, `<layoutSectionStyle>`) and redeploy; SF treats it as a structural change and flushes the cache.

**Red flags:** SOQL or DML inside a `for` loop; more than one trigger on the same object; new Workflow Rule or Process Builder; overwriting a Contact role flag to `false` on re-approval (must be additive); adding QA fields and not seeing them render (cache, not deploy failure).

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

**Idempotency via external-ID upsert is mandatory.** Upsert keyed on a stable external ID so a retried job does not create duplicates. Any new write path must reuse that key — a late re-link by the same external ID needs no new SF write logic.

**Resilience: on SF write failure, persist and alert — do not silently drop.** Catch the SF error, write the full payload to durable storage, alert staff, enable manual recovery. 3-try exponential backoff before falling to manual. Never let a user-facing success vanish before reaching Salesforce.

**Bulk API 2.0 for multi-thousand-row loads.** Daily API allowance scales with licenses — design imports to use Bulk, not thousands of individual REST upserts.

**Outbound SF→external callouts: Named Credentials + External Credentials.** Never hard-code endpoints or secrets in Apex.

**Red flags:** row-by-row REST where Bulk API belongs; write path without external-ID key (breaks idempotency); SF write failure with no durable fallback; polling on a timer where CDC/Platform Events would deliver on change; hard-coded endpoints in Apex.

**Verify:** after a test write, SOQL-confirm exactly one record landed for the external ID; re-run the job and confirm the count stays at one (idempotency proof). A fast JWT smoke chain (auth → describe → upsert idempotency → cleanup) should run after any metadata or cert change.

---

## Development Lifecycle & Deployment — operational rules

**SFDX is source of truth; deploy from the SFDX project root.** All `sf project …` commands must run from the SFDX project root or they fail with *"InvalidProjectWorkspaceError"*.

**Apex requires ≥75% code coverage org-wide to deploy to production** (and every trigger must have at least some coverage). Test with `Test.startTest()`/`Test.stopTest()` to get a fresh set of governor limits and force async to run; use `@TestSetup` for shared fixtures; mock callouts with `HttpCalloutMock`. Tests must assert behavior, not just execute lines.

**Treat production Salesforce as off-limits for incidental deploys; do metadata work in a sandbox.** Production cutover is a separate, planned, documented event, not an incidental deploy.

**Run a smoke test after any metadata, cert, or sandbox change.** A fast JWT/metadata smoke script catches the FLS, required-field, relationshipName, and JWT gotchas at the layer they bite, in seconds. Keep a known-good end-to-end baseline and treat regressions as blockers.

**Sandbox-bringup gotchas to pre-empt:** some org policies require a Public Group (with the admin as member) before sandbox creation. Managed packages (e.g. NPSP) must be installed before metadata deploy in sandboxes that depend on them. Partial-copy sandboxes carrying managed-package data can fire package automation unexpectedly on load.

**Destructive changes need a plan.** Field deletion, permset removal, and JSON-to-discrete migrations can drop data. Sequence: backfill → verify → destructive deploy → re-verify. Never destructive-deploy before the data it would orphan has been migrated.

**Commit-and-push discipline.** After each completed logical change: lint + build pass, then commit (Conventional Commit) and push. Never commit broken code. Branch first if on the default branch.

**Red flags:** `sf project deploy` from repo root (not SFDX root); incidental change against production; destructive deploy without prior backfill; Apex tests that only execute lines without assertions; skipping smoke test after cert rotation.

**Verify:** describe/SOQL post-deploy to confirm metadata landed AND is queryable (catches missing FLS that the deploy itself won't surface). Confirm idempotency and role-flag correctness before considering a change done.

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

**Delegated Authentication** replaces Salesforce's own password check with an external web service you own. Use only when a corporate directory must remain the sole credential store and SAML is not feasible. Endpoint must have an IP allowlist.

**Experience Cloud:** Guest user OWD controls unauthenticated access; authenticated users follow standard sharing + sharing sets / share groups. Never grant a Guest User write access beyond what the experience explicitly requires — audit finding.

**Red flags:** confusing SF-as-SP (inbound) with SF-as-IdP (outbound); relying on Role Hierarchy for lateral access (upward only); Guest User with edit/delete on sensitive objects; Delegated Auth endpoint without IP allowlist.

---

## Well-Architected & Multi-Cloud — operational rules

**Score every proposal against Trusted / Easy / Adaptable** — every design choice is defensible on all three axes; when a trade-off sacrifices one, name it. **MuleSoft** is enterprise API mesh, not point-to-point glue. **Data Cloud** owns the Unified Profile when a 360 view across clouds is required. **Marketing Cloud** sees synchronized CRM copies, not live data — never assume otherwise.

Key one-liners (check Quick Reference below): score Trusted/Easy/Adaptable on every design; no MuleSoft for simple one-to-one SF↔system syncs; Marketing Cloud sees synchronized copies, not live CRM data.

Full worked examples — Well-Architected trade-off framing, MuleSoft vs. Named Credentials decision criteria, Data Cloud Identity Resolution, Marketing Cloud integration patterns, and stakeholder-facing defense communication: [references/communication-well-architected.md](references/communication-well-architected.md) — load when designing multi-cloud architecture or preparing an architectural defense presentation.

---

## Executable Workflows

### Workflow 1 — Design a cross-cloud integration (pick pattern → Named Credential → bulk-safe → verify)

1. Identify the latency and reliability requirement: does the caller need an answer now (sync/request-reply), or can it wait (async/fire-and-forget)? Does data move in bulk (>1,000 rows) or record-by-record?
   → gate: one row of the integration pattern table selected; rationale documented.
2. Create a Named Credential + External Credential in the target org for the external endpoint. Store any secret in the credential store — never in Apex code or env vars.
   → gate: a test callout from Apex `Http.send` using the Named Credential returns HTTP 200 without hard-coded URL.
3. Design the write path to be idempotent: every SF write keyed on a stable External ID. For >1,000 rows, use Bulk API 2.0.
   → gate: re-run the job twice; SOQL count of records for that External ID = 1 both times.
4. Add a durable failure fallback: on SF write error, persist the payload and alert staff; implement 3-try exponential backoff.
   → gate: simulate a write failure; confirm the payload lands in durable storage and an alert fires.
5. Verify governor-limit headroom: confirm the integration path (including any trigger/Flow on the target object) stays under 150 DML / 100 SOQL / 10k DML rows per transaction. Use async (Queueable/Batch) if sync limits are at risk.
   → gate: Apex debug log shows no governor-limit warnings on a representative batch size.

---

### Workflow 2 — Stand up secure cross-org access (JWT Bearer flow)

1. Generate an RSA key pair. Store the private key in a secrets store (e.g. AWS SSM SecureString, Azure Key Vault). Never store it in an env var or commit it to source control.
   → gate: private key retrievable only via the secrets store API; not present in any repo or CI variable.
2. Create a Connected App (or External Client App) in the target Salesforce org: upload the certificate (public key), enable OAuth scopes, and restrict to the integration user's profile.
   → gate: Connected App Consumer Key is captured (UI-only in ECA — do it now); App is saved.
3. Assign the integration user to the Connected App / ECA via the Policies tab (ECA) or permset "Assigned Connected Apps" (Connected App). Confirm via `SetupEntityAccess` query — do not trust the UI "success."
   → gate: `SELECT SetupEntityId FROM SetupEntityAccess WHERE SetupEntityId = '<AppId>' AND AssigneeId = '<UserId>'` returns a row.
4. Test the JWT token exchange: sign a JWT assertion with the private key, POST to `https://<instance>/services/oauth2/token`, receive an access token.
   → gate: access token returned with no `invalid_grant` or `unauthorized_client` error.
5. Smoke-test the integration user's access: use the access token to run a describe + idempotent upsert + cleanup in the target org. Confirm FLS, object access, and no governor-limit errors.
   → gate: describe returns the expected object; upsert creates exactly one record; cleanup removes it.
6. Schedule annual key rotation; document the rotation runbook now, before you need it under pressure.

---

### Workflow 3 — Size an LDV data model (selectivity, skew, indexes)

1. Estimate the record count for the object at 5-year growth. If projected count exceeds ~2M rows, classify as LDV and apply LDV design rules throughout.
   → gate: documented record-count estimate with growth assumption.
2. Identify every filter used in SOQL queries against this object. Confirm each filter column is indexed (standard indexed fields, External IDs, or custom indexes via Salesforce support request).
   → gate: at least one leading indexed field in every production SOQL WHERE clause; no non-selective query paths remain.
3. Check for ownership skew: if a single user or queue will own >10,000 records, that OWD + sharing model will produce a "fat node" in the sharing tree. Redesign OWD to Private + Sharing Rules, or use org-wide-default Public Read/Write if sharing is not sensitive, to avoid the skew calculation penalty.
   → gate: no single owner accounts for >10% of the total row count, OR a Salesforce architect review has confirmed the sharing design is skew-safe.
4. Verify query selectivity: run candidate SOQL with `EXPLAIN` (via Tooling API or Developer Console). Confirm the query uses an index (cost < 1); a table scan on an LDV object will trigger the *"non-selective query against large object"* error in production.
   → gate: EXPLAIN returns `leadingOperationType: Index` for every production query path.
5. Plan archival or soft-delete strategy before the object reaches LDV scale — retrofitting indexes or archival to a live LDV object is expensive.
   → gate: archival policy documented and scheduled.

---

## Decision Scenarios

Five original scenarios covering the highest-value operational gotchas across CTA domains. Scenarios 3–5 are in [references/scenarios.md](references/scenarios.md) — load them when working through trigger bulkification failures, ECA assignment gotchas, or multi-cloud Data Cloud decisions.

---

**Scenario 1 — FLS invisible after deploy**

**Situation:** A developer deploys `Application__c.ReviewScore__c` via SFDX. Deploy succeeds. SOQL immediately returns `"INVALID_FIELD: No such column 'ReviewScore__c' on entity 'Application__c'"`. The field exists in Setup UI.

**Competent move:** This is the FLS gap, not a deployment failure. `field-meta.xml` carries no FLS — the field exists but is visible to no one. Add it to the relevant permset's `<fieldPermissions>` (`<readable>true</readable>` + `<editable>true</editable>`), deploy the permset, re-run the SOQL.

**Tempting-but-wrong:** Re-deploy the field, or check the `required` flag. Neither helps — the field is present; the missing layer is FLS.

**Verify:** `SELECT ReviewScore__c FROM Application__c LIMIT 1` as the integration user — error = FLS still missing; null result = FLS granted. Query `SetupEntityAccess` to confirm the permset assignment landed.

---

**Scenario 2 — OWD + Role Hierarchy misread as lateral sharing**

**Situation:** A regional manager needs read access to Opportunities owned by a *peer* region's role — lateral, not reporting. The architect proposes: "OWD = Private; roles at the same tier; Role Hierarchy propagates access, so her manager sees both regions. Requirement satisfied."

**Competent move:** Role Hierarchy propagates access **upward** (parent sees child's records), not sideways. Peer roles don't inherit each other. The correct mechanism is a **Sharing Rule** ("owned by members of Role X, share to Role Y"). The manager above both regions gains access via hierarchy automatically; peers need an explicit sharing rule.

**Tempting-but-wrong:** Treating Role Hierarchy as "nearby roles share access" — strictly upward. Designing on this assumption silently breaks lateral access requirements.

**Verify:** After adding the Sharing Rule, SOQL as a user in the target role for an Opportunity owned by a user in the source role. Confirm the reverse direction does not automatically apply without a reciprocal rule.

---

## Operational Rules Quick Reference

- **DO** treat governor limits as design inputs: 100 SOQL / 50k rows / 150 DML / 10k DML rows / 10s CPU sync.
- **DON'T** put SOQL or DML inside a `for` loop — query into a Map, DML once. #1 review red flag.
- **DO** add `<fieldPermissions>` in a permset for every new non-required custom field — SFDX field-meta grants FLS to no one.
- **DON'T** add `<fieldPermissions>` for a `<required>` field — deploy will fail.
- **DON'T** assume object access implies field access — separate gates.
- **DO** use Permission Sets / Groups for all new access; Profiles are legacy.
- **DO** use JWT Bearer for headless service→SF; RSA key in secrets store, rotated annually.
- **DO** assign ECA access on the ECA Policies tab (not the permset "Assigned Connected Apps" page).
- **DON'T** trust a UI "success" on ECA assignment — verify via `SetupEntityAccess` query.
- **DON'T** log PII or sensitive data — record IDs and identity subjects only.
- **DO** key every SF write on a stable external ID for idempotent upsert; verify count stays at one after retry.
- **DON'T** row-by-row REST for bulk loads — use Bulk API 2.0.
- **DO** persist failed writes to durable storage + alert staff; never silently drop.
- **DO** source string `max()` lengths from a generated constant; never hand-edit the generated schema file.
- **DON'T** use Apex truncation as the primary length guard — validate at the boundary.
- **DO** give each lookup to the same parent a unique `relationshipName` (role-suffixed).
- **DO** one trigger per object, bulk-safe handler; role-flag writes additive, never overwrite to false.
- **DON'T** create new Workflow Rules or Process Builders — deprecated; use Flow or Apex.
- **DO** suspect managed-package automation when a field changes with no code of yours involved.
- **DO** bust the QA cache by editing non-field metadata (`<description>`) and redeploying when QA fields don't render.
- **DO** run `sf project` commands from the SFDX project root only.
- **DON'T** make incidental deploys to production; sandbox only, cutover is a planned event.
- **DON'T** destructive-deploy before backfilling and verifying the data it would orphan.
- **DO** run a JWT/metadata smoke test after any metadata/cert/sandbox change.
- **DO** verify metadata is *queryable* post-deploy (SOQL) — catches missing FLS the deploy won't surface.
- **DO** score every design against Trusted / Easy / Adaptable; name any axis sacrificed.
- **DON'T** propose MuleSoft for a simple one-to-one SF↔system sync.
- **DON'T** assume Marketing Cloud sees live CRM data — synchronized copies only.
- **DO** frame every architecture decision as "chose X over Y because Z, accepting risk R."

> For org-specific applications of these rules, see a per-org appendix in your own project, referenced from a CLAUDE.md.

---

## References

- [references/study-resources.md](references/study-resources.md) — credential logistics, prerequisites, and study path.
- [references/scenarios.md](references/scenarios.md) — Decision Scenarios 3–5: trigger bulkification failure, ECA assignment gotcha, and multi-cloud Data Cloud vs. custom ETL.
- [references/communication-well-architected.md](references/communication-well-architected.md) — stakeholder communication patterns, architectural defense framing, and extended Well-Architected trade-off examples.

For NPSP/nonprofit-specific operational guidance, see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md).

---

## Feedback protocol

Using this skill and hit a wall? If you find a claim contradicted by the live system or official docs, a missing rule that cost you a wrong attempt, or a decision this skill gave no criteria for — append an entry **in the moment** to `.skill-feedback/salesforce-technical-architect.md` at the project root (create it if absent):

`date | skill last-reviewed | claim or gap | what you observed instead | evidence (error text / doc URL / query output) | suggested fix`

These are harvested back into the skill via the learning loop. When the live system and this file disagree, trust the live system.

---

## Changelog

- **2026-06-09** — Conformed to the 12-dimension skill standard: task-vocab description + Scope block, Uncertainty & Escalation guidance with inline `[volatile — verify live]` marks, executable workflows, tool-agnostic verify steps, and the feedback protocol above. Exam logistics relocated to references/study-resources.md; `last-reviewed` set to 2026-06-09.

---

## Disclaimer

Independent educational content to upskill AI agents. Not affiliated with, authorized by, endorsed by, or sponsored by Salesforce, Inc. or any certification body. "Salesforce," "Salesforce Certified Technical Architect," "CTA," "NPSP," "Agentforce," "MuleSoft," "Data Cloud," and all related trademarks and product names are the property of their respective owners and are used here solely for identification purposes. Content is provided as-is for guidance only — verify all rules, limits, fees, and procedures against official Salesforce documentation and your live org before acting. No certification outcome is implied or guaranteed. Governor limits, exam fees, and product capabilities are subject to change; check the official exam guide and release notes for current values.
