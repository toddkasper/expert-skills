# Experience Cloud Consultant — Decision Scenarios

Load-on-demand companion to [../SKILL.md](../SKILL.md). Five original teaching scenarios covering the highest-consequence operational gotchas. Each is independently authored; none duplicate the held-out eval set in `evals/`.

Format: **Situation → Competent move → Tempting-but-wrong → Verify**

---

## Scenario 1 — Sharing: account peers can't see each other's cases

**Situation:** A customer portal (Customer Community license) is live. Each contact at a
business account can see their own cases via a sharing set keyed on `Case.Contact`.
A requirement arrives: contacts at the same account must also be able to see each other's
cases so a team manager can monitor the whole account. The admin adds more sharing rules
but the peer visibility never appears.

**Competent move:** Add a **share group** to the existing sharing set. A share group
extends a sharing set's record access to all external users in that set — the exact
mechanism for intra-account peer visibility on base Customer Community. Sharing rules are
role-based and base Customer Community has no usable role hierarchy, so they cannot reach
peer external users on this license.

**Tempting-but-wrong:** Adding criteria-based sharing rules referencing an account ID.
This fails silently because sharing rules target roles or public groups, and Customer
Community users (no role hierarchy) are not in any role or standard group that sharing
rules can address.

**Verify:** In Setup → Digital Experiences → [site] → Administration → Members, confirm
the sharing set exists and the share group is added. In a sandbox, log in as two different
contact users under the same account and confirm mutual case visibility.

---

## Scenario 2 — Template: LWR site, Reputation required

**Situation:** A project is mid-build on a Build Your Own (LWR) site. A new requirement
arrives: add Reputation points and levels to gamify community engagement. The developer
searches Experience Builder for the Reputation component and cannot find it.

**Competent move:** Recognize that Reputation and gamification are **Aura-only** features.
LWR sites do not support the Reputation component — this is a hard platform ceiling, not a
configuration gap. The correct response is to surface this incompatibility to stakeholders
immediately and evaluate whether to switch to an Aura template (requires rebuilding the
site) or drop the Reputation requirement.

**Tempting-but-wrong:** Assuming the component is just missing from the library and
attempting to build a custom LWC Reputation replacement. This is an unbounded engineering
effort that re-implements a managed platform feature, creates an unsupported upgrade path,
and could have been avoided by confirming the feature-template matrix before committing to
LWR.

**Verify:** Check the official Salesforce Experience Cloud feature comparison table (Help
article: "Considerations for Experience Cloud Sites Built on LWR") before locking in a
template. Add a feature-matrix review step to every project scoping checklist.

---

## Scenario 3 — Guest user: flow tries to write a record

**Situation:** A public (unauthenticated) application form is built as a Screen Flow embedded
via the Flow component on an LWR site. When a visitor submits the form, they receive an
*Insufficient Privileges* error. The admin checks the flow in Flow Builder — it looks
correct. Sharing settings look fine.

**Competent move:** The flow runs **in the guest user's session** and therefore under the
guest profile's permissions. Trace the access failure top-down: confirm the guest profile
has **Create** CRUD on the target object AND **FLS write access** on every field the flow
populates. Because the guest profile is shared across all unauthenticated traffic, any
missing permission silently blocks DML for every visitor.

**Tempting-but-wrong:** Assuming it is a sharing problem and adding the object to the guest
user's "secure guest user record access" or trying to open OWD. Sharing controls *which
records* a user sees, not *whether they can create*. The correct layer to fix is CRUD and
FLS on the guest profile.

**Verify:** In Setup → Profiles → [Guest User Profile for the site] → Object Settings,
confirm Create is checked for the target object and each mapped field shows Write. Test
end-to-end as an unauthenticated user in a sandbox; confirm the record appears in the org
after submission.

---

## Scenario 4 — ARO: enabling Account Role Optimization on a live portal

**Situation:** A Customer Community Plus portal has been live for six months with thousands
of account-user pairs. Performance is degrading; Salesforce support attributes it to role
hierarchy bloat (~3 roles per account × thousands of accounts). An admin finds the Account
Role Optimization (ARO) setting in Digital Experiences and wants to enable it immediately.

**Competent move:** **Stop.** ARO must be enabled *before* any portal users are associated
with accounts. Enabling ARO retroactively on an org that already has portal users and
role-hierarchy entries causes data integrity issues — existing role assignments can be
orphaned or corrupted. The correct remediation path at this stage is to open a Salesforce
support case to discuss migration options, not to flip the switch unilaterally.

**Tempting-but-wrong:** Enabling ARO in production immediately to fix the performance
issue. This is a destructive configuration change on a live portal and is explicitly
unsupported after account-user pairs exist.

**Verify:** Before any portal goes live, add ARO enablement to the pre-launch checklist if
scaling to many accounts is expected. Confirm the org has zero portal users attached to
accounts before flipping the ARO setting. Reference: Salesforce Help article "Enable
Account Role Optimization."

---

## Scenario 5 — Authentication: JIT vs. self-registration for enterprise onboarding

**Situation:** A company wants to launch a Partner Community portal. Partners are managed in
an enterprise IdP (Azure AD). Two architects debate the right provisioning approach:
Architect A proposes self-registration with a custom Apex handler; Architect B proposes
SAML SSO with Just-in-Time (JIT) provisioning.

**Competent move:** Choose **SAML SSO with JIT**. The partner user population already
exists in the IdP; JIT creates or updates Salesforce User records automatically on first
login using SAML assertion attributes — no separate registration step, no duplicated
identity source. Self-registration is for audiences that do not exist in a system of record
and need to create their own identity.

**Tempting-but-wrong:** Using self-registration as a convenience shortcut. This creates a
second identity source that drifts from Azure AD, forces partner users through an extra
form, and requires a custom Apex handler to be maintained through every release. It also
introduces the NPSP-automation-fire gotcha (§5 of the main skill) if the org runs NPSP.

**Verify:** In Setup → Single Sign-On Settings, configure the SAML IdP with the correct
Entity ID and ACS URL. Enable JIT and map IdP assertion attributes to Salesforce User
fields. Test with a new partner contact not yet in Salesforce; confirm the User record is
created with the correct profile and site membership on first login.
