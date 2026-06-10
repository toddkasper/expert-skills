# Application tasks — salesforce-experience-cloud-consultant (Lens 4, held-out)

A skilled agent produces the artifact; a judge grades against the trap-keyed rubric. Run baseline vs skilled.

---

## Task 1 — External sharing model design for a customer portal

**Prompt to the agent:** A B2B software company is building a Customer Community portal. External users (customers) must see only their own Cases and the Cases of the Account they belong to. The architect has drafted the sharing design below. Review it, redline every error, and produce a corrected sharing model spec.

**Spec (flawed — embedded traps):**

> **License and profile:**
> - License type: Customer Community (not Customer Community Plus). The portal team chose this because "it is cheaper and customers only need to see Cases."
> - External profile: "Customer Portal User" — a clone of the standard "Customer Community Login User" profile.
>
> **Sharing set:**
> - A Sharing Set is configured on the Case object. Access mapping: `Case.AccountId = Community User's Account`.
> - Access level: **Read/Write** (so customers can update their own cases).
> - A second sharing set is configured on the Opportunity object (same mapping) so customers can view related deals.
>
> **Household scenario:**
> - This is a consumer-goods client. Some customers are individual consumers (Person Accounts) who should also see Cases linked to their household. The sharing set is keyed on `Case.AccountId`, which for Person Account Cases holds the Person Account's ID. The architect says: "That covers household cases because every household member shares the same Account."
>
> **Guest user:**
> - The site has a public FAQ page powered by Knowledge articles. The guest-user profile has been granted Read access on the Knowledge object and on the Contact object (so the FAQ page can display a "suggested contacts" sidebar).
> - CRUD for guest user on Case: Create is enabled so visitors can submit a support request from the public page without logging in.
>
> **Change set deployment:**
> - The full configuration (profile, sharing set, site settings) will be deployed from sandbox to production via a change set.

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — Customer Community license does not support Sharing Sets keyed on Account for Case access. Sharing Sets are supported for Customer Community Plus and Partner Community licenses. With Customer Community, external users see only records they own or records shared via the portal's default sharing. Agent must flag the license mismatch and recommend upgrading to Customer Community Plus (or documenting the record-ownership model required for base Customer Community).
- [ ] Trap 2 — Sharing Set on the Opportunity object: Customer Community (and even Community Plus) external users cannot access Opportunity records by default; Opportunities require Partner Community license or explicit sharing via Share Groups / manual share. Agent must flag the Opportunity sharing set as non-functional for Customer Community users and clarify the license or mechanism required.
- [ ] Trap 3 — Guest-user Read access on the Contact object is an over-sharing risk: all Contacts in the org become accessible to unauthenticated visitors via SOQL unless object-level permissions are combined with scoping filters. Agent must flag this as a guest-user over-sharing violation and recommend removing Contact Read from the guest profile or scoping the FAQ sidebar to Knowledge-only data.
- [ ] Trap 4 — Change sets do not deploy Experience Cloud site activation, member profiles, or guest-user profile assignments. The site will exist in production but will be in Preview (not Active) state, and external users will not be able to log in until the admin manually activates the site and assigns member profiles in production Setup. Agent must call out this post-deployment manual step.
- [ ] Trap 5 — Guest-user Create on Case without a before-save Flow or validation to set `OwnerId` and `AccountId` will leave cases owned by the guest user with no Account association, making them invisible to any sharing set and unreachable by logged-in customers. Agent must flag the missing owner/account-stamp logic.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- License correction: upgrade to Customer Community Plus to support Sharing Sets and reports/dashboards; document cost delta.
- Opportunity access: Customer Community Plus does not grant Opportunity access by default; clarify whether this is truly needed and, if so, use manual sharing or a Share Group (for Customer Community Plus).
- Guest-user Contact Read removal: remove Contact from the guest profile; if the FAQ sidebar needs a contact lookup, scope it to an Apex controller that enforces `without sharing` is NOT used, or use a Guest User sharing rule on a specific public-facing Contact subset.
- Post-deployment activation checklist: activate site in production, assign member profiles, verify guest-user profile is active.
- Case owner/account stamp: before-save Flow on Case insert from guest context sets `OwnerId` to a queue and stamps `AccountId` via the email address lookup.

---

## Task 2 — External user authentication and SSO misconfiguration review

**Prompt to the agent:** A professional-services firm is migrating their partner portal from a legacy system to Salesforce Experience Cloud with SAML SSO. Their admin has written up the SSO and user-provisioning configuration notes below. Review the notes, identify every misconfiguration, and produce a step-by-step remediation plan.

**Spec (flawed — embedded traps):**

> **SAML configuration:**
> - A SAML Identity Provider (IdP) has been configured in Setup under "Identity Providers." The IdP Entity ID is `https://idp.partnerfirm.com/saml`.
> - The SFDC SP Metadata has been exported and sent to the IdP team.
> - The IdP is configured to send the SAML assertion with `NameID` = the partner user's corporate email address.
> - In Salesforce, the SAML SSO settings have "Identity Location" set to **"Identity is in the Subject element"** and "Identity Type" set to **"Salesforce Username"**.
> - Partners' Salesforce usernames follow the pattern `firstname.lastname@partnerfirm.com.portal`.
>
> **SSO login flow:**
> - The IdP is configured as SP-initiated (partners click a Salesforce-supplied login URL). When partners click "Login with SSO," they land on the standard Salesforce login page, not the portal.
> - The admin says this is fine: "Partners can click the SSO button on that page."
>
> **JIT provisioning:**
> - JIT provisioning is enabled. The JIT handler is set to create a new User record if the username is not found. The JIT mapping sets Profile to the portal's "Partner Community User" profile.
> - The admin did not configure a Role mapping in JIT because "roles are optional."
>
> **License:**
> - Partners are assigned the "Partner Community" license. There are 85 active partner users today and the firm expects to grow to 400. The org has 500 Partner Community licenses purchased.

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — Identity Type mismatch: `NameID` in the assertion is the partner's corporate email (`firstname.lastname@partnerfirm.com`), but Identity Type is set to "Salesforce Username" and Salesforce usernames follow the pattern `firstname.lastname@partnerfirm.com.portal`. These do not match. Every SSO attempt will fail with a user-not-found error. Agent must flag the mismatch and prescribe either (a) changing Identity Type to "Federation ID" and populating `FederationIdentifier` on users, or (b) having the IdP send the full Salesforce username in `NameID`.
- [ ] Trap 2 — SP-initiated SSO for an Experience Cloud site requires the **Start URL** in the SAML SSO settings (or the My Domain > Authentication Configuration login URL) to point to the Experience Cloud site URL, not the standard Salesforce login page. Partners landing on the standard login page instead of the portal is the symptom of a missing or incorrect Start URL / login page override. Agent must call out the Start URL configuration and the Experience Cloud site's Authentication Configuration page where the SSO method must be enabled.
- [ ] Trap 3 — JIT provisioning without Role mapping leaves new partner users with no Role. In Salesforce, Partner Community users must have a Role to participate in the role hierarchy and for manager-level portal sharing to function correctly. Users with no role cannot be assigned to the partner portal's sharing model properly. Agent must flag the missing Role mapping in the JIT handler.
- [ ] Trap 4 — 400 expected users against 500 licenses leaves only 100 license headroom. While not currently over-limit, the agent should flag this as a capacity risk and recommend confirming the license count covers concurrent active users vs. all-time provisioned users (Community licenses are per active user, not per login).
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Identity matching fix: option A — set Identity Type to "Federation ID," populate `FederationIdentifier` on each User record with the corporate email; option B — configure IdP to send the full Salesforce username. Document the trade-offs (JIT easiest with Federation ID).
- Start URL / site login configuration: in the SAML SSO settings, set the Start URL to the Experience Cloud site's URL; in Setup > Digital Experiences > [Site] > Administration > Login & Registration, enable the SAML IdP as a login option. Verify `My Domain` routing.
- JIT Role mapping: add a Role attribute to the JIT handler mapping (or a default Portal Role via JIT custom attribute); document that users without a role cannot be part of the partner portal hierarchy.
- License capacity note: flag 100-license headroom; recommend proactive procurement trigger at 350 active users (87.5% utilization).
