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

This file is an **operational playbook**, not an exam outline. Each section states
the *rule* an agent should apply when designing, building, or reviewing an
external-facing digital experience (portal/community/site) on Salesforce —
followed by concrete limits, decision criteria, and anti-patterns to catch in
review.

The Experience Cloud Consultant credential validates that you can scope a use case
to the right experience type, pick the correct external license, configure the
external sharing model safely, provision and authenticate external users, and
harden the guest user surface. The recurring exam (and real-world) framing is not
"how do I configure X" but "given this requirement, which approach is correct and
**why**, and what breaks if I pick wrong."

> **Load this skill when…** scoping or building a Salesforce portal, community, or external site; selecting an external license type (Customer/Partner/External Apps); configuring the external sharing model (sharing sets, share groups, guest profile hardening); provisioning or authenticating external users (SSO, self-registration, JIT); or debugging an external-user access failure (CRUD, FLS, OWD, sharing).
> **Not this skill:** internal-org sharing model or permission sets for employees alone → see `salesforce-advanced-administrator`; service console configuration for internal agents → see `salesforce-service-cloud-consultant`; sales pipeline configuration → see `salesforce-sales-cloud-consultant`.

> **Deeper context:** Study resources live in [references/study-resources.md](references/study-resources.md) (loaded on demand). For org-specific applications of these rules, see a per-org appendix you maintain in your own project, referenced from a CLAUDE.md. For NPSP/nonprofit-specific guidance, see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md).

> **Verify steps assume nothing about your tooling** — use your project's Salesforce MCP connection, the Salesforce CLI (`sf`), or the Salesforce setup UI, in that order of preference.

---

Credential logistics and study path: see [references/study-resources.md](references/study-resources.md).

---

## Uncertainty & Escalation

- **Always re-verify live:** volatile facts in this skill include external license names and pricing tiers `[volatile — verify live]`, which OOTB components are available on LWR vs Aura (the list grows each release) `[volatile — verify live]`, ARO enablement restrictions, Spring '21+ guest-user hardening changes, and Account Role Optimization behavior at scale — confirm against current Salesforce release notes and your org.
- **Live wins:** when the live org or official documentation contradicts a statement in this file, trust the live source and log the discrepancy via the Feedback protocol below.
- **Escalate to a human before proceeding on:** guest-user profile CRUD/FLS changes in production (blast-radius risk); widening OWD or sharing rules for external users; enabling public self-registration on a production org; ARO enablement on an org with existing portal users; any change that affects PII or document visibility for unauthenticated users.
- **Confidence taxonomy:** every fact in this file is considered stable unless tagged `[volatile — verify live]` or `[opinion — house style]`. If you act on an untagged fact and the live system disagrees, file feedback — do not silently trust this file over the live org.

---

## 1. Scoping the Experience — Pick the Right Model First

**Rule: decide the *user model* before anything else, because it locks your license,
your sharing mechanism, and your provisioning path.** Changing it later means
rebuilding the site (templates cannot be migrated in place).

Decision table — match the requirement to the model:

| Requirement | Model | License | Why |
|---|---|---|---|
| Unauthenticated public visitors only (read content, maybe submit a form) | Guest user | Free (guest profile) | No User records; one shared guest profile |
| Authenticated customers see *their own* records, no peer visibility | Customer model (Contact + Account) | Customer Community | Cheapest authenticated tier; no role hierarchy |
| Authenticated customers need reports, dashboards, sharing rules, or cross-account visibility | Customer model | Customer Community **Plus** | Adds role hierarchy + reports |
| Resellers/partners working Leads, Opportunities, Campaigns | Partner (Business Account) | Partner Community (PRM) | Full CRM objects + role hierarchy |
| Custom high-object-count app, many logins | Customer model | External Apps license | Flexible object access, login- or member-based pricing |
| Managed-package org (e.g. NPSP nonprofit portal) | Customer model | **Experience Cloud for Nonprofits** (or vendor-specific tier) | Package-aware licensing; see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md) for NPSP specifics |

**Decision heuristic for unauthenticated, shared-device, or low-friction audiences:**
when there is no Contact-with-Account to authenticate against and re-identifying a
user via login is unacceptable friction (e.g. a senior audience on a shared kiosk),
the correct answer is a **guest or external-token model, not an authenticated
portal**. A tokenized bearer (scoped to a single record) can give even tighter
blast-radius scoping than a guest profile.

**Anti-pattern / red flag:** Recommending Partner Community when the external users
have no Account relationship, or Customer Community when the requirement says
"partners must see reports of their team's deals" (that needs Plus or Partner).
Mismatched license = either missing features or paying for capability never used.

---

## 2. Sharing, Visibility & Licensing — The Highest-Consequence Topic

**Rule: external users see *nothing* by default. Access is granted in a strict
layered order, and ALL layers must pass.** Trace failures in this exact sequence:

```
Profile/Permission Set (CRUD)  →  Field-Level Security (FLS)  →  OWD (org-wide default)
   →  Sharing Set / Sharing Rule / Role Hierarchy  →  record actually visible
```

If the user can't see a record, the gap is at the FIRST layer that fails, working
top-down. Do not jump to sharing rules before confirming CRUD + FLS.

### CRUD and FLS still apply to external users — separately from sharing

**Object access (CRUD) and field access (FLS) are independent of record sharing.** A
sharing set can grant *which records* a user sees but never *which objects/fields*.
Both the object permission AND the field permission must be on the profile or a
permission set that makes the user a site member.

- **RED FLAG:** "I added a sharing set but the user still gets *Insufficient
  Privileges* / *Invalid field*." → CRUD or FLS is missing, not sharing. The same
  class of failure bites when a field is deployed via metadata without explicit
  field permissions: the field exists, access is granted to no one.

### Sharing Set vs. Sharing Rule vs. Share Group — pick correctly

| Mechanism | What it does | Use when |
|---|---|---|
| **Sharing Set** | Grants an external user access to records *related to their Account or Contact* via a lookup (e.g. `Case.Contact = the user's Contact`) | The record has a lookup path back to the portal user — the default external-user sharing tool |
| **Share Group** | Extends a sharing set's access to *other internal/external users* in the set (so account peers see each other's records) | Customer Community users (no role hierarchy) need to see each other's records within an account |
| **Sharing Rule** | Criteria- or owner-based, opens records to roles/groups | Cross-cutting visibility not expressible as a lookup; works for Plus/Partner with roles |
| **Role Hierarchy** | Account-scoped external roles roll records up to managers | Customer Community **Plus** / Partner only — NOT available on base Customer Community |

**Decision rule:** if the record has a lookup to the portal user's Contact/Account →
**sharing set** (no role-hierarchy entry needed). If account peers must see each
other → add a **share group** on that set. Reach for sharing rules only when neither
fits.

- **Anti-pattern:** Trying to give base Customer Community users role-hierarchy
  roll-up — that license has no usable role hierarchy. Either upgrade to Plus or use a
  share group.

### Guest user profile — the #1 security risk

**Rule: harden the guest profile to the absolute minimum.** In Spring '21+ orgs guest
users:
- Get **one shared profile** across all unauthenticated traffic — there is no
  per-visitor scoping.
- **Cannot own records** and record creation is locked down by default.
- Have OWD for guest forced to **Private** for most objects; "View All Users" and
  "secure guest user record access" are enforced.
- Should have CRUD/FLS only on the few objects/fields the public flow truly needs.

- **RED FLAG:** A guest profile with broad object Read, "Modify All," or FLS on PII
  fields. Any guest-writable object with a lookup that could expose other applicants'
  data. Guest write paths must be scoped by Apex `with sharing` + explicit
  record-key filtering, never by trusting the guest session.

- **Key limitation to know:** a guest user profile permits unauthenticated access but
  gives **no per-visitor record scoping** without custom Apex. When a use case needs
  unauthenticated *write* access scoped tightly to a single record, an external
  write-only bearer token (scoped to one record key) can have a narrower blast radius
  than any guest-profile configuration.

### External license cheat values

- **Customer Community:** own records only, no peer sharing, no role hierarchy,
  cheapest. Self-service support. `[volatile — verify live]`
- **Customer Community Plus:** + role hierarchy, + reports/dashboards, + sharing
  rules. Authenticated portals needing cross-visibility. `[volatile — verify live]`
- **Partner Community:** + Leads/Opps/Campaigns, role hierarchy. Resellers/channel. `[volatile — verify live]`
- **External Apps:** high object count, custom apps. `[volatile — verify live]`

---

## 3. Branding, Personalization & Content

**Rule: do it declaratively in Experience Builder first; only drop to custom LWC when
a standard component cannot meet the requirement.** Every custom component adds CSP,
Locker, and upgrade-path cost.

- **Branding sets** let one site present different visual identities to different
  audiences — use them instead of cloning a site for a re-skin.
- **Audience targeting (Personalization):** show/hide components or serve page
  variants by profile, permission set, record field, or geolocation. Use this for
  "staff see X, applicants see Y" within one site rather than separate pages.
- **Site search:** explicitly choose which objects are searchable and which fields
  appear in results; add promoted terms + synonyms so self-service actually deflects
  contact. **RED FLAG:** a search box that returns nothing because no objects were
  added to the search index.
- **Knowledge + Data Categories:** gate article visibility by Data Category per
  audience segment — the standard mechanism for "partners see internal KB, customers
  don't."
- **CMS vs. record pages:** CMS-driven content pages for marketing/editorial content;
  object record pages for live data. Don't rebuild live records as static CMS.

**Anti-pattern:** Hardcoding brand colors/logos in custom CSS instead of the Theme
panel — breaks the no-code maintainability promise and the theme export path.

---

## 4. Templates & Themes — Choose Once, Cannot Migrate

**Rule: template choice is permanent.** Migrating a live site from one template to
another is **not supported** — you build a new site and re-create everything. Get this
right at scoping time.

| Template | Runtime | Use for |
|---|---|---|
| Customer Account Portal | Aura | Authenticated self-service, account/case mgmt, rich OOTB |
| Partner Central | Aura | PRM: lead distribution, deal reg, MDF |
| Help Center | Aura | Public KB/FAQ, searchable without login |
| Build Your Own (Aura) | Aura | Max flexibility, Aura + LWC, no use-case layout |
| Build Your Own (LWR) | LWR | LWC-only, fastest, Salesforce's strategic direction |
| Microsite (LWR) | LWR | Campaign landing / minimal single-page |

**Aura vs. LWR decision rule:**
- New build, performance-sensitive, public, willing to live with fewer OOTB
  components → **LWR**.
- Need Reputation, certain CMS components, some moderation tools, or rich prebuilt
  use-case pages → **Aura** (not all features exist on LWR yet).

- **Why LWR is faster:** UI layer is rendered static on publish and CDN-cached; Aura
  fetches component data dynamically on every page load.
- **Anti-pattern:** Choosing LWR then discovering a required OOTB component (e.g.
  Reputation, which is Aura-only) doesn't exist — forcing a from-scratch rebuild on
  Aura. Confirm the component list against the chosen runtime *before* committing.
- **Theme export/import** carries theme settings, **not** custom components — plan to
  redeploy custom LWCs separately when moving a theme between orgs.

---

## 5. User Creation & Authentication

**Rule: every Experience Cloud user except the guest is backed by a Contact.** No
Contact → no external User. For customer/partner models the Contact must belong to an
Account.

Provisioning method decision table:

| Volume / scenario | Method | Notes |
|---|---|---|
| A handful of known users | Manual enablement from Contact | "Enable Customer/Partner User" button |
| Bulk load from a system of record | Data Loader / API | Use a Contact **external ID** for upsert idempotency |
| Public self-signup | Self-registration | Needs a self-reg Apex handler (standard or custom); creates Contact + User; set default profile + account |
| Enterprise SSO, no pre-provisioning | Just-in-Time (JIT) | Creates/updates User from SAML assertion on first login |

- **Partner users are enabled at the Account level** (Convert to Partner Account →
  Enable Partner User on the Contact) — a different workflow from customer users.
- **SSO selection:** SAML when an enterprise IdP exists (map assertion attributes;
  know SP- vs IdP-initiated); OIDC/Auth Provider for social/consumer login;
  Login Discovery when multiple auth methods coexist.
- **Membership gate:** a user can only log in if their profile or permission set is
  added to the site as a member. Guests always get the guest profile.
- **Delegated External User Administration** lets partner super users create/manage
  lower-tier users without admin rights — scope which profiles/fields they can touch.

- **RED FLAG / managed-package gotcha:** A self-registration handler that creates Contacts will fire **every Contact-insert automation in the portal user's session context**, including any managed-package automation installed in the org. Always test self-reg Contact creation end to end in sandbox for governor-limit errors AND unexpected field mutations from managed-package automation. (e.g. NPSP ships a workflow rule that copies `Phone → MobilePhone` on every Contact insert; see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md) for details.)

---

## 6. Adoption & Analytics

**Rule: instrument for *case deflection* — that's the ROI metric leadership asks for.**
Enable Experience Dashboards (Workspaces → Dashboards) to see logins, unique
visitors, page views, and search terms natively.

- External users on **Customer Community Plus / Partner** can run reports and view
  dashboards scoped to their own data — configure report-folder sharing and the
  dashboard running-user. Base Customer Community **cannot**.
- **Moderation:** banned-keyword rules, post rate limits, member flagging — enable
  before opening a public community to UGC, not after the first incident.
- **Reputation/gamification is Aura-only** — don't promise it on an LWR site.
- **Anti-pattern:** Launching with an empty site and no seeded content/champions, then
  blaming low adoption. Seed content + a clear CTA at launch.

---

## 7. Administration, Setup & Configuration (largest domain)

**Rule: My Domain must be deployed before you can create a site; inactive sites are
admin-only.** Activation is a deliberate step.

- **Flows in Experience Cloud:** embed via the Flow component and **set the running
  context deliberately** — logged-in user vs. system context. A flow run by a guest
  user runs with the guest profile's (minimal) permissions; scope it carefully or it
  silently fails on missing CRUD/FLS. **RED FLAG:** a guest-facing flow that does DML
  on an object the guest profile can't write.
- **CSP & Lightning Locker:** any third-party script (analytics, chat) needs its
  origin added as a **CSP Trusted Site** in Experience Builder, and Locker isolates
  component DOM. **RED FLAG:** embedded script silently dead → check the browser
  console for a CSP violation first.
- **PRM config:** Partner Central + lead distribution + deal registration + MDF;
  partner-sourced Opportunity record types and lead-conversion rules.
- **Sandbox→prod deployment:** sites move via change sets or SFDX metadata, but
  **domain, external-user profiles, and some settings are org-specific and must be
  reconfigured by hand** — they are NOT portable. As a general rule, metadata
  deploys but FLS, permissions, and org-wired settings need manual reconfiguration.
  Plan a manual reconfiguration checklist for cutover.
- **Email deliverability:** portal notification senders must come from a verified
  Org-Wide Address; confirm the address is domain/SES verified before relying on
  portal emails, especially in a mixed external-mail (e.g. AWS SES) + Salesforce
  setup.

---

## 8. Customization Considerations & Limitations

**Rule: know the hard ceilings before you design past them.**

- **One profile, one experience:** a user generally cannot belong to multiple
  experiences with the *same* profile — plan distinct profiles/permission sets for
  multi-site users.
- **Account Role Optimization (ARO):** default hierarchy creates ~3 roles per account
  per portal; at millions of account-roles this degrades performance. ARO collapses
  the hierarchy for portals that don't need peer visibility — **must be enabled
  before the account has portal users**; retroactive enablement causes data issues.
- **Governor limits apply to external sessions too:** Apex run in guest/portal context
  hits the same per-transaction limits as any Apex — **100 SOQL / 150 DML / 50,000
  rows queried per synchronous transaction**, 6 MB heap (sync), 10s CPU (sync). A
  self-reg handler or portal flow doing per-record SOQL/DML in a loop will blow these
  under load. **Bulkify everything** the portal triggers.
- **CDN:** Salesforce CDN edge-caches static assets; great for high-traffic public
  pages, irrelevant for highly personalized/dynamic pages. **Purge the CDN cache
  after publishing** or users see stale assets.
- **AppExchange vs. custom:** prefer a Lightning Bolt / managed package when it
  covers the use case and you value the upgrade path; build custom only when nothing
  fits — every custom component is yours to maintain through Salesforce releases.

---

## Operational Rules Quick Reference

Read this first. Each is imperative and concrete.

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

**Rule: the "Basics" blueprint domain (8%) tests whether you can orient a new site
correctly before configuration begins. These feel simple but are silent failure points.**

- **My Domain is a hard prerequisite.** You cannot create an Experience Cloud site in a
  production or sandbox org without My Domain deployed to all users. Attempting setup
  before deployment surfaces an error that is easy to misdiagnose as a permission problem.
- **Site URL structure:** each site gets a path suffix under My Domain
  (e.g. `yourdomain.my.site.com/portalname`). A custom domain (CNAME) can be mapped in
  Setup → Custom URLs, but the My Domain base must still be active.
- **Published vs. Preview vs. Inactive states:**
  - *Inactive* — only admins can see the site; members get an error page.
  - *Preview* — site members with the right profile can see it without a public publish.
  - *Published (Active)* — live to all allowed visitors including guests.
  - **RED FLAG:** A test user reporting they cannot reach the portal after being added as
    a member — check site status before troubleshooting sharing.
- **Network access / IP restrictions:** portal users are subject to the same org-level
  trusted IP ranges as internal users unless the site is configured to skip IP
  verification. SSO flows can bypass this; know when that matters.
- **Object support by license:** not every Salesforce object is available on every
  external license. Standard objects like Lead and Opportunity are Partner/Plus only;
  base Customer Community cannot surface them regardless of CRUD grants on the profile.

---

## 10. Coverage Notes & Known Gaps

The sections above map to the eight blueprint domains. Items that warrant deeper study but
are outside the scope of this file's operational rules:

- **PRM depth:** lead distribution rule logic, deal-registration approval workflows, and
  MDF request configuration are partner-portal-specific and detailed in the official
  Partner Relationship Management Trailhead trail.
- **CMS workspaces and channels:** the distinction between a CMS workspace, a channel, and
  how content is published to multiple sites simultaneously is covered in Salesforce CMS
  Basics (Trailhead) and is lightly tested on the exam.
- **Moderation rules in depth:** rate limits, keyword lists, member flagging, and review
  queues require hands-on configuration practice — not captured here beyond the
  "enable before launch" rule.
- **Mobile Publisher (Salesforce Mobile App experience wrapping):** occasionally tested; not
  covered in this skill. See official Mobile Publisher documentation.

These gaps are tracked here rather than masked. If your study plan targets any of these,
load the relevant Trailhead trail alongside this skill.

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

Five original teaching scenarios covering the highest-consequence operational gotchas —
one per major domain cluster. Full scenarios (Situation → Competent move → Tempting-but-wrong → Verify)
are in [references/scenarios.md](references/scenarios.md).

| # | Domain | Scenario |
|---|---|---|
| 1 | Sharing/Visibility | Account peers can't see each other's cases on base Customer Community |
| 2 | Templates | LWR site mid-build when Reputation gamification is added to requirements |
| 3 | Guest user / Admin | Public Screen Flow surfaces *Insufficient Privileges* on submit |
| 4 | Customization | ARO enablement requested on a portal already live with thousands of accounts |
| 5 | Authentication | JIT vs. self-registration when partners are already in an enterprise IdP |

---

## Study resources & relevance

Study resources (official Salesforce + community) are kept in [references/study-resources.md](references/study-resources.md). For NPSP/nonprofit-specific operational guidance, see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md).

---

## Feedback protocol

Using this skill and hit a wall? If you find a claim contradicted by the live system or official docs, a missing rule that cost you a wrong attempt, or a decision this skill gave no criteria for — append an entry **in the moment** to `.skill-feedback/salesforce-experience-cloud-consultant.md` at the project root (create it if absent):

`date | skill last-reviewed | claim or gap | what you observed instead | evidence (error text / doc URL / query output) | suggested fix`

These are harvested back into the skill via the learning loop. When the live system and this file disagree, trust the live system.

## Changelog

- **2026-06-09** — Conformed to the 12-dimension skill standard: task-vocab description + Scope block, Uncertainty & Escalation guidance with inline `[volatile — verify live]` marks, executable workflows, tool-agnostic verify steps, and the feedback protocol above. Exam logistics relocated to references/study-resources.md; `last-reviewed` set to 2026-06-09.

## Disclaimer

Independent educational content to upskill AI agents. Not affiliated with, authorized by, endorsed by, or sponsored by Salesforce or any certification body. "Salesforce," "Experience Cloud," and all related product names and certification titles are trademarks of Salesforce, Inc. and their respective owners, used here solely to identify the subject matter. Content is provided as guidance only — verify all configuration details against official Salesforce documentation and a live org before acting. No certification outcome is implied or guaranteed. Exam details (questions, weights, fees, score thresholds) are subject to change; confirm current values at trailhead.salesforce.com.
