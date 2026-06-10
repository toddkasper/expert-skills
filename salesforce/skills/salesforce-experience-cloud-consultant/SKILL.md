---
name: salesforce-experience-cloud-consultant
description: Building and configuring Salesforce Experience Cloud sites and portals — communities, partner/customer portals, LWR and Aura templates, the external sharing model (sharing sets, share groups, guest-user hardening), external license selection, user provisioning and authentication (SSO, self-registration, JIT), audiences and personalization. Use when scoping a portal to the right license/user model, configuring external-user access, or debugging external-user CRUD/FLS/OWD/sharing failures. Not internal-org sharing alone (see salesforce-advanced-administrator) or Service/Sales console config (see those consultant skills). Scoped and benchmarked by the Experience Cloud Consultant (EX-Con-101) blueprint.
metadata:
  credential: Salesforce Certified Experience Cloud Consultant
  exam-code: EX-Con-101
  domain: salesforce
  type: certification-playbook
  status: current
  last-reviewed: 2026-06-09
  blueprint-verified: 2026-06-07
---

# Salesforce Experience Cloud Consultant — Skills Reference

## Overview

Operational playbook for designing, building, and reviewing external-facing Salesforce digital experiences (portals, communities, sites). Each section states the *rule* to apply — with concrete limits, decision criteria, and anti-patterns. The recurring framing is "given this requirement, which approach is correct and **why**, and what breaks if I pick wrong."

> **Load this skill when…** scoping or building a Salesforce portal, community, or external site; selecting an external license type (Customer/Partner/External Apps); configuring the external sharing model (sharing sets, share groups, guest profile hardening); provisioning or authenticating external users (SSO, self-registration, JIT); or debugging an external-user access failure (CRUD, FLS, OWD, sharing).
> **Not this skill:** internal-org sharing model or permission sets for employees alone → see `salesforce-advanced-administrator`; service console configuration for internal agents → see `salesforce-service-cloud-consultant`; sales pipeline configuration → see `salesforce-sales-cloud-consultant`.

> **Deeper context:** Study resources live in [references/study-resources.md](references/study-resources.md) (loaded on demand). For NPSP/nonprofit-specific guidance, see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md).

> **Verify steps assume nothing about your tooling** — use your project's Salesforce MCP connection, the Salesforce CLI (`sf`), or the Salesforce setup UI, in that order of preference.

---

---

## Uncertainty & Escalation

- **Always re-verify live:** volatile facts in this skill include external license names and pricing tiers `[volatile — verify live]`, which OOTB components are available on LWR vs Aura (the list grows each release) `[volatile — verify live]`, ARO enablement restrictions, Spring '21+ guest-user hardening changes, and Account Role Optimization behavior at scale — confirm against current Salesforce release notes and your org.
- **Live wins:** when the live org or official documentation contradicts a statement in this file, trust the live source and log the discrepancy via the Feedback protocol below.
- **Escalate to a human before proceeding on:** guest-user profile CRUD/FLS changes in production (blast-radius risk); widening OWD or sharing rules for external users; enabling public self-registration on a production org; ARO enablement on an org with existing portal users; any change that affects PII or document visibility for unauthenticated users.
- **Confidence taxonomy:** every fact in this file is considered stable unless tagged `[volatile — verify live]` or `[opinion — house style]`. If you act on an untagged fact and the live system disagrees, file feedback — do not silently trust this file over the live org.

---

## 1. Scoping the Experience — Pick the Right Model First

**Rule: decide the *user model* first — it locks your license, sharing mechanism, and provisioning path.** Changing it later means rebuilding the site (templates cannot be migrated in place).

| Requirement | Model | License | Why |
|---|---|---|---|
| Unauthenticated public visitors only (read content, maybe submit a form) | Guest user | Free (guest profile) | No User records; one shared guest profile |
| Authenticated customers see *their own* records, no peer visibility | Customer model (Contact + Account) | Customer Community | Cheapest authenticated tier; no role hierarchy |
| Authenticated customers need reports, dashboards, sharing rules, or cross-account visibility | Customer model | Customer Community **Plus** | Adds role hierarchy + reports |
| Resellers/partners working Leads, Opportunities, Campaigns | Partner (Business Account) | Partner Community (PRM) | Full CRM objects + role hierarchy |
| Custom high-object-count app, many logins | Customer model | External Apps license | Flexible object access, login- or member-based pricing |
| Managed-package org (e.g. NPSP nonprofit portal) | Customer model | **Experience Cloud for Nonprofits** (or vendor-specific tier) | Package-aware licensing; see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md) for NPSP specifics |

**Unauthenticated/low-friction audiences:** when there is no Contact-with-Account and login is unacceptable friction, use a guest or external-token model — a tokenized bearer scoped to a single record has narrower blast radius than a guest profile.

**Anti-pattern / red flag:** Partner Community when users have no Account relationship, or Customer Community when "partners must see reports of their team's deals" (needs Plus or Partner). Mismatched license = missing features or wasted spend.

---

## 2. Sharing, Visibility & Licensing — The Highest-Consequence Topic

**Rule: external users see *nothing* by default — ALL layers must pass.** Trace failures top-down:

```
Profile/Permission Set (CRUD)  →  FLS  →  OWD  →  Sharing Set / Rule / Role Hierarchy  →  record visible
```

Fix the first failing layer; do not jump to sharing rules before confirming CRUD + FLS.

### CRUD and FLS still apply to external users — separately from sharing

**CRUD and FLS are independent of record sharing.** A sharing set grants *which records* a user sees, never *which objects/fields*. Both must be on the profile or permission set.

- **RED FLAG:** "Added a sharing set but user still gets *Insufficient Privileges* / *Invalid field*" → CRUD or FLS is missing, not sharing. Same failure applies when a field is deployed via metadata without explicit field permissions.

### Sharing Set vs. Sharing Rule vs. Share Group — pick correctly

| Mechanism | What it does | Use when |
|---|---|---|
| **Sharing Set** | Grants an external user access to records *related to their Account or Contact* via a lookup (e.g. `Case.Contact = the user's Contact`) | The record has a lookup path back to the portal user — the default external-user sharing tool |
| **Share Group** | Extends a sharing set's access to *other internal/external users* in the set (so account peers see each other's records) | Customer Community users (no role hierarchy) need to see each other's records within an account |
| **Sharing Rule** | Criteria- or owner-based, opens records to roles/groups | Cross-cutting visibility not expressible as a lookup; works for Plus/Partner with roles |
| **Role Hierarchy** | Account-scoped external roles roll records up to managers | Customer Community **Plus** / Partner only — NOT available on base Customer Community |

**Decision rule:** record has a lookup to the portal user's Contact/Account → **sharing set**. Account peers must see each other → add a **share group** on that set. Reach for sharing rules only when neither fits.

- **Anti-pattern:** base Customer Community users + role-hierarchy roll-up — that license has no usable role hierarchy. Upgrade to Plus or use a share group.

### Guest user profile — the #1 security risk

**Rule: harden the guest profile to the absolute minimum.** In Spring '21+ orgs:
- One **shared profile** across all unauthenticated traffic — no per-visitor scoping.
- **Cannot own records**; record creation locked down by default.
- OWD for guest forced to **Private** for most objects; "View All Users" and "secure guest user record access" enforced.
- CRUD/FLS only on the objects/fields the public flow truly needs.

- **RED FLAG:** guest profile with broad Read, "Modify All," or FLS on PII fields. Any guest-writable object with a lookup that could expose other records. Guest write paths must be scoped by Apex `with sharing` + explicit record-key filtering.

- **Key limitation:** no per-visitor record scoping without custom Apex. For unauthenticated write scoped to a single record, an external bearer token (scoped to one record key) has narrower blast radius than any guest-profile configuration.

### External license cheat values

- **Customer Community:** own records only, no peer sharing, no role hierarchy,
  cheapest. Self-service support. `[volatile — verify live]`
- **Customer Community Plus:** + role hierarchy, + reports/dashboards, + sharing
  rules. Authenticated portals needing cross-visibility. `[volatile — verify live]`
- **Partner Community:** + Leads/Opps/Campaigns, role hierarchy. Resellers/channel. `[volatile — verify live]`
- **External Apps:** high object count, custom apps. `[volatile — verify live]`

---

## 3. Branding, Personalization & Content

**Rule: declaratively in Experience Builder first; custom LWC only when a standard component cannot meet the requirement.** Every custom component adds CSP, Locker, and upgrade-path cost.

- **Branding sets:** one site, different visual identities per audience — use instead of cloning for a re-skin.
- **Audience targeting:** show/hide components or page variants by profile, permission set, record field, or geolocation — "staff see X, applicants see Y" in one site.
- **Site search:** explicitly choose which objects are searchable; add promoted terms + synonyms. **RED FLAG:** search box returns nothing — objects not added to search index.
- **Knowledge + Data Categories:** gate article visibility by Data Category — standard mechanism for "partners see internal KB, customers don't."
- **CMS vs. record pages:** CMS for marketing/editorial; record pages for live data. Don't rebuild live records as static CMS.

**Anti-pattern:** hardcoding brand colors/logos in custom CSS instead of the Theme panel — breaks no-code maintainability and theme export.

---

## 4. Templates & Themes — Choose Once, Cannot Migrate

**Rule: template choice is permanent.** Migrating a live site from one template to another is **not supported** — you build a new site and re-create everything.

| Template | Runtime | Use for |
|---|---|---|
| Customer Account Portal | Aura | Authenticated self-service, account/case mgmt, rich OOTB |
| Partner Central | Aura | PRM: lead distribution, deal reg, MDF |
| Help Center | Aura | Public KB/FAQ, searchable without login |
| Build Your Own (Aura) | Aura | Max flexibility, Aura + LWC, no use-case layout |
| Build Your Own (LWR) | LWR | LWC-only, fastest, Salesforce's strategic direction |
| Microsite (LWR) | LWR | Campaign landing / minimal single-page |

**Aura vs. LWR:** new build, performance-sensitive, public → **LWR**. Need Reputation, certain CMS components, or rich prebuilt use-case pages → **Aura** (not all features exist on LWR yet). LWR is faster because the UI layer is rendered static on publish and CDN-cached; Aura fetches data dynamically on every load.

- **Anti-pattern:** choosing LWR, then discovering Reputation (Aura-only) is required — forces a rebuild. Confirm the component matrix against the chosen runtime before committing.
- **Theme export/import** carries theme settings, not custom components — redeploy custom LWCs separately when moving themes between orgs.

---

## 5. User Creation & Authentication

**Rule: every Experience Cloud user except the guest is backed by a Contact.** No Contact → no external User. Customer/partner contacts must belong to an Account.

| Volume / scenario | Method | Notes |
|---|---|---|
| Handful of known users | Manual enablement from Contact | "Enable Customer/Partner User" button |
| Bulk load | Data Loader / API | Use a Contact **external ID** for upsert idempotency |
| Public self-signup | Self-registration | Apex handler; creates Contact + User; set default profile + account |
| Enterprise SSO, no pre-provisioning | JIT | Creates/updates User from SAML assertion on first login |

- **Partner users** are enabled at the Account level (Convert to Partner Account → Enable Partner User on Contact) — different from customer users.
- **SSO selection:** SAML for enterprise IdP (SP- vs IdP-initiated); OIDC/Auth Provider for social login; Login Discovery when multiple methods coexist.
- **Membership gate:** user profile or permission set must be added as a site member. Guests always get the guest profile.
- **Delegated External User Administration:** partner super users can create/manage lower-tier users without admin rights — scope which profiles/fields they can touch.

- **RED FLAG — managed-package gotcha:** A self-registration handler that creates Contacts fires every Contact-insert automation in the portal user's session context, including managed-package automation. Always test self-reg Contact creation end-to-end in sandbox (governor-limit errors, unexpected field mutations). NPSP orgs: a workflow rule copies `Phone → MobilePhone` on every Contact insert — see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md).

---

## 6. Adoption & Analytics

**Rule: instrument for *case deflection* — the ROI metric leadership asks for.** Enable Experience Dashboards (Workspaces → Dashboards) for logins, unique visitors, page views, and search terms.

- **Customer Community Plus / Partner** users can run reports and dashboards scoped to their own data — configure report-folder sharing and dashboard running-user. Base Customer Community cannot.
- **Moderation:** enable banned-keyword rules, post rate limits, and member flagging before opening to UGC.
- **Reputation/gamification is Aura-only** — don't promise it on an LWR site.
- **Anti-pattern:** launching with an empty site, then blaming low adoption — seed content + a clear CTA at launch.

---

## 7. Administration, Setup & Configuration (largest domain)

**Rule: My Domain must be deployed before you can create a site; inactive sites are admin-only.** Activation is a deliberate step.

- **Flows:** set the running context deliberately — guest flows run with guest profile permissions; scope carefully or DML silently fails. **RED FLAG:** guest-facing flow doing DML on an object the guest profile can't write.
- **CSP & Lightning Locker:** third-party scripts need origin added as a **CSP Trusted Site** in Experience Builder. **RED FLAG:** embedded script dead → check browser console for CSP violation first.
- **PRM config:** Partner Central + lead distribution + deal registration + MDF; partner-sourced Opportunity record types and lead-conversion rules.
- **Sandbox→prod deployment:** sites move via change sets or SFDX metadata, but domain, external-user profiles, and some settings are org-specific — NOT portable. FLS, permissions, and org-wired settings need manual reconfiguration. Plan a manual checklist for cutover.
- **Email deliverability:** portal notification senders must come from a verified Org-Wide Address; confirm domain/SES verification before relying on portal emails.

---

## 8. Customization Considerations & Limitations

**Rule: know the hard ceilings before you design past them.**

- **One profile, one experience:** a user generally cannot belong to multiple experiences with the *same* profile — plan distinct profiles/permission sets for multi-site users.
- **Account Role Optimization (ARO):** default hierarchy creates ~3 roles per account per portal — degrades at scale. ARO collapses it for portals that don't need peer visibility. **Must be enabled before any portal users exist on the account**; retroactive enablement causes data integrity issues.
- **Governor limits apply to external sessions:** same per-transaction limits — **100 SOQL / 150 DML / 50,000 rows queried per synchronous transaction**, 6 MB heap, 10s CPU. Bulkify everything the portal triggers.
- **CDN:** edge-caches static assets for high-traffic public pages; irrelevant for highly personalized/dynamic pages. **Purge the CDN cache after publishing** or users see stale assets.
- **AppExchange vs. custom:** prefer a managed package when it covers the use case; build custom only when nothing fits — every custom component is yours to maintain.

---

## Operational Rules Quick Reference

Each rule is imperative and concrete.

1. **DO decide the user model (guest / customer / partner) before picking a license or
   template** — it locks everything downstream.
2. **DON'T pick a template you might outgrow** — template migration in place is
   unsupported; you rebuild the whole site.
3. **DO trace sharing failures top-down:** Profile CRUD → FLS → OWD → sharing
   set/rule/role. Fix the first failing layer.
4. **DON'T assume a sharing set grants object or field access** — it only grants
   *which records*. CRUD + FLS are separate and both required.
5. **DO use a sharing set when the record has a lookup back to the portal user's
   Contact/Account**; add a share group only when account peers must see each other.
6. **DON'T expect role-hierarchy roll-up on base Customer Community** — it has no
   usable role hierarchy. Upgrade to Plus/Partner or use a share group.
7. **DO harden the guest profile to the minimum** — one shared profile, no record
   ownership, no PII FLS, no broad Read.
8. **DON'T trust the guest session for record scoping** — enforce it in `with sharing`
   Apex filtered by an explicit record key.
9. **DO match license to features:** Plus for reports/role hierarchy, Partner for
   Leads/Opps/Campaigns, External Apps for high-object custom apps.
10. **DON'T recommend Partner Community for users with no Account relationship.**
11. **DO back every non-guest user with a Contact** (and an Account for
    customer/partner models).
12. **DO use a Contact external ID for any bulk/API user provisioning** (upsert
    idempotency).
13. **DON'T let self-registration Contact creation fire untested** — managed-package automation runs in the portal session and can mutate fields or hit limits.
14. **DO set Flow running context explicitly** in Experience Cloud; guest flows run
    with guest permissions.
15. **DON'T embed third-party scripts without a CSP Trusted Site entry** — check the
    browser console for CSP violations first when a widget is dead.
16. **DO bulkify all Apex/flows the portal triggers** — external sessions hit the same
    100 SOQL / 150 DML / 50k-row governor limits.
17. **DON'T use Reputation/gamification on an LWR site** — Aura-only.
18. **DO enable ARO before an account has portal users** if scaling to many accounts;
    never retroactively.
19. **DO purge the CDN cache after publishing** static-asset changes.
20. **DON'T assume site config is fully portable sandbox→prod** — domain, external
    profiles, and some settings are org-specific manual steps.
21. **DO measure case deflection** as the primary adoption ROI metric.

---

## 9. Basics — Domain Foundations Often Overlooked

- **My Domain is a hard prerequisite** — cannot create an Experience Cloud site without it deployed to all users. Misdiagnosed as a permission problem when skipped.
- **Site URL:** path suffix under My Domain (`yourdomain.my.site.com/portalname`). Custom domain (CNAME) maps in Setup → Custom URLs; My Domain base must be active.
- **Site states:** *Inactive* (admin-only, members get an error) → *Preview* (members with the right profile can see) → *Published/Active* (live, guests included). **RED FLAG:** user can't reach the portal after being added as a member — check site status first.
- **IP restrictions:** portal users subject to org-level trusted IP ranges unless the site skips IP verification; SSO can bypass this.
- **Object support by license:** Lead and Opportunity are Partner/Plus only — base Customer Community cannot surface them regardless of CRUD on the profile.

---

## 10. Coverage Notes & Known Gaps

> PRM depth (deal-registration, MDF, lead distribution), CMS workspaces and channels, moderation rule depth (rate limits, keyword lists, review queues), and Mobile Publisher coverage notes are in [references/coverage-notes.md](references/coverage-notes.md). Load that file if your work targets any of those areas.

---

## Executable Workflows

### 1. Stand up an external portal (license → template → sharing set → guest-user hardening → verify external access)

1. Confirm My Domain is deployed to all users. → **gate: Setup → My Domain shows "Deployed to All Users."**
2. Select the external license type (Customer Community / Plus / Partner / External Apps) based on the user model decision table in §1. → **gate: license type confirmed with business owner before proceeding.**
3. Create the site: Setup → All Sites → New. Select a template (decision criteria: §4). → **gate: site is created in Inactive state; no public access yet.**
4. Configure the guest profile: restrict CRUD/FLS to the minimum objects and fields the public flow needs. Remove any broad Read, Modify All, or PII FLS. → **gate: run Setup → Guest User Profile and confirm no object has more access than needed.**
5. Add the sharing set: Setup → Sharing Sets → New. Link to the site, pick the profile, add the lookup-match rule (e.g. `Case.Contact = portal user's Contact`). → **gate: create a test Contact-linked record; log in as a test external user; confirm the record is visible.**
6. Set the site to Published (Active). → **gate: visit the site URL as an incognito browser session and confirm the public home page loads; authenticated users can log in.**

### 2. Provision + authenticate external users (SSO / self-registration / JIT)

1. Decide the provisioning method (manual / bulk API / self-reg / JIT) using the volume/scenario decision table in §5. → **gate: method agreed before any user creation.**
2. For **SSO (SAML):** configure an Identity Provider record in Setup → Identity → Identity Providers. Map assertion attributes to Salesforce User fields. Choose SP-initiated vs IdP-initiated flow. → **gate: test login from IdP; SAML assertion is received; user record created/linked.**
3. For **self-registration:** deploy the self-reg Apex handler (standard or custom). Set the default profile and account in the site's Administration → Registration settings. → **gate: register a test user end-to-end in sandbox; confirm Contact + User record created; confirm managed-package automation did not mutate unexpected fields (check sandbox debug log).**
4. Ensure every user's profile (or permission set) is added as a site member: Setup → All Sites → [site] → Administration → Members. → **gate: test user can log in; no "site not found" or "member not authorized" error.**
5. For **JIT:** configure the SAML JIT handler class in the SSO settings. Map assertion fields to User fields for create and update. → **gate: first login creates the User record with expected field values; repeat login updates fields without creating a duplicate.**

### 3. Debug an external-user access failure (CRUD → FLS → OWD → sharing, in order)

1. Reproduce the error as the external user (log in as the portal user or use "Log In As" from Setup). Note the exact error: *Insufficient Privileges*, *Invalid field*, record not visible, or blank page. → **gate: error confirmed firsthand, not assumed from a user report.**
2. Check CRUD: describe the object for the user's profile/permset (Setup → Object Manager or SOQL against `ObjectPermissions`). → **gate: if Read is false on the object, add it — that is the root cause; stop here.**
3. Check FLS: `SELECT Id, SObjectType, Field, PermissionsRead FROM FieldPermissions WHERE SobjectType = '<Object>' AND ParentId IN (SELECT Id FROM PermissionSet WHERE Name = '<permset>')`. → **gate: if the field is missing, add it to the profile/permset — root cause found; stop here.**
4. Check OWD: Setup → Sharing Settings → [object] OWD. For external users, "Private" is the default for most objects. → **gate: if OWD is Private and no sharing mechanism exists, proceed to step 5.**
5. Check sharing set / sharing rule: confirm the sharing set's lookup path resolves to the user's Contact/Account for this record. Test with SOQL on the `UserRecordAccess` object: `SELECT RecordId, HasReadAccess FROM UserRecordAccess WHERE UserId = '<userId>' AND RecordId = '<recordId>'`. → **gate: `HasReadAccess = true` after any sharing fix confirms the layer is resolved.**

---

## Decision Scenarios

Scenarios 1–4 inline below. Scenario 5 (Authentication — JIT vs. self-registration) is in [references/scenarios.md](references/scenarios.md).

---

**Scenario 1 — Sharing: account peers can't see each other's cases**

> **Situation:** A customer portal (Customer Community license) is live. Each contact at a business account can see their own cases via a sharing set keyed on `Case.Contact`. A requirement arrives: contacts at the same account must also be able to see each other's cases so a team manager can monitor the whole account. The admin adds more sharing rules but the peer visibility never appears.

> **Competent move:** Add a **share group** to the existing sharing set. A share group extends a sharing set's record access to all external users in that set — the exact mechanism for intra-account peer visibility on base Customer Community. Sharing rules are role-based and base Customer Community has no usable role hierarchy, so they cannot reach peer external users on this license.

> **Tempting-but-wrong:** Adding criteria-based sharing rules referencing an account ID. This fails silently because sharing rules target roles or public groups, and Customer Community users (no role hierarchy) are not in any role or standard group that sharing rules can address.

> **Verify:** In Setup → Digital Experiences → [site] → Administration → Members, confirm the sharing set exists and the share group is added. In a sandbox, log in as two different contact users under the same account and confirm mutual case visibility.

---

**Scenario 2 — Template: LWR site, Reputation required**

> **Situation:** A project is mid-build on a Build Your Own (LWR) site. A new requirement arrives: add Reputation points and levels to gamify community engagement. The developer searches Experience Builder for the Reputation component and cannot find it.

> **Competent move:** Recognize that Reputation and gamification are **Aura-only** features. LWR sites do not support the Reputation component — this is a hard platform ceiling, not a configuration gap. The correct response is to surface this incompatibility to stakeholders immediately and evaluate whether to switch to an Aura template (requires rebuilding the site) or drop the Reputation requirement.

> **Tempting-but-wrong:** Assuming the component is just missing from the library and attempting to build a custom LWC Reputation replacement. This is an unbounded engineering effort that re-implements a managed platform feature, creates an unsupported upgrade path, and could have been avoided by confirming the feature-template matrix before committing to LWR.

> **Verify:** Check the official Salesforce Experience Cloud feature comparison table (Help article: "Considerations for Experience Cloud Sites Built on LWR") before locking in a template. Add a feature-matrix review step to every project scoping checklist.

---

**Scenario 3 — Guest user: flow tries to write a record**

> **Situation:** A public (unauthenticated) application form is built as a Screen Flow embedded via the Flow component on an LWR site. When a visitor submits the form, they receive an *Insufficient Privileges* error. The admin checks the flow in Flow Builder — it looks correct. Sharing settings look fine.

> **Competent move:** The flow runs **in the guest user's session** and therefore under the guest profile's permissions. Trace the access failure top-down: confirm the guest profile has **Create** CRUD on the target object AND **FLS write access** on every field the flow populates. Because the guest profile is shared across all unauthenticated traffic, any missing permission silently blocks DML for every visitor.

> **Tempting-but-wrong:** Assuming it is a sharing problem and adding the object to the guest user's "secure guest user record access" or trying to open OWD. Sharing controls *which records* a user sees, not *whether they can create*. The correct layer to fix is CRUD and FLS on the guest profile.

> **Verify:** In Setup → Profiles → [Guest User Profile for the site] → Object Settings, confirm Create is checked for the target object and each mapped field shows Write. Test end-to-end as an unauthenticated user in a sandbox; confirm the record appears in the org after submission.

---

**Scenario 4 — ARO: enabling Account Role Optimization on a live portal**

> **Situation:** A Customer Community Plus portal has been live for six months with thousands of account-user pairs. Performance is degrading; Salesforce support attributes it to role hierarchy bloat (~3 roles per account × thousands of accounts). An admin finds the Account Role Optimization (ARO) setting in Digital Experiences and wants to enable it immediately.

> **Competent move:** **Stop.** ARO must be enabled *before* any portal users are associated with accounts. Enabling ARO retroactively on an org that already has portal users and role-hierarchy entries causes data integrity issues — existing role assignments can be orphaned or corrupted. The correct remediation path at this stage is to open a Salesforce support case to discuss migration options, not to flip the switch unilaterally.

> **Tempting-but-wrong:** Enabling ARO in production immediately to fix the performance issue. This is a destructive configuration change on a live portal and is explicitly unsupported after account-user pairs exist.

> **Verify:** Before any portal goes live, add ARO enablement to the pre-launch checklist if scaling to many accounts is expected. Confirm the org has zero portal users attached to accounts before flipping the ARO setting. Reference: Salesforce Help article "Enable Account Role Optimization."

---

## Study resources

[references/study-resources.md](references/study-resources.md). For NPSP-specific guidance: [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md).

---

## Feedback protocol

Using this skill and hit a wall? If you find a claim contradicted by the live system or official docs, a missing rule that cost you a wrong attempt, or a decision this skill gave no criteria for — append an entry **in the moment** to `.skill-feedback/salesforce-experience-cloud-consultant.md` at the project root (create it if absent):

`date | skill last-reviewed | claim or gap | what you observed instead | evidence (error text / doc URL / query output) | suggested fix`

These are harvested back into the skill via the learning loop. When the live system and this file disagree, trust the live system.

## Changelog

- **2026-06-09** — Conformed to 12-dimension skill standard: task-vocab description, Scope block, Uncertainty & Escalation with `[volatile — verify live]` marks, executable workflows, tool-agnostic verify steps, feedback protocol. Exam logistics relocated to references/study-resources.md.
- **2026-06-09** — Inlined 4 decision scenarios; §10 Coverage Notes moved to references/coverage-notes.md; prose compression pass.

## Disclaimer

Independent educational content to upskill AI agents. Not affiliated with, authorized by, endorsed by, or sponsored by Salesforce or any certification body. "Salesforce," "Experience Cloud," and all related product names and certification titles are trademarks of Salesforce, Inc. and their respective owners, used here solely to identify the subject matter. Content is provided as guidance only — verify all configuration details against official Salesforce documentation and a live org before acting. No certification outcome is implied or guaranteed. Exam details (questions, weights, fees, score thresholds) are subject to change; confirm current values at trailhead.salesforce.com.
