# Experience Cloud Consultant — Decision Scenarios (Extended)

Overflow from [../SKILL.md](../SKILL.md). Scenarios 1–4 are inlined in the body. Load this file for Scenario 5 (Authentication — JIT vs. self-registration for enterprise partner onboarding).

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

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
