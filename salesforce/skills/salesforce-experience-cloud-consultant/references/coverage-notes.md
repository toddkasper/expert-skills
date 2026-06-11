# Experience Cloud Consultant — Coverage Notes & Known Gaps

Referenced from [../SKILL.md](../SKILL.md) §10. Load this file if your work targets any of the areas below.

---

## PRM Depth

Lead distribution rule logic, deal-registration approval workflows, and MDF request configuration are partner-portal-specific. The authoritative source is the official Partner Relationship Management Trailhead trail. The SKILL.md body covers the high-level PRM config checklist (Partner Central + lead distribution + deal registration + MDF + partner-sourced Opportunity record types and lead-conversion rules).

## CMS Workspaces and Channels

The distinction between a CMS workspace, a channel, and how content is published to multiple sites simultaneously is covered in Salesforce CMS Basics (Trailhead). Lightly tested on the EX-Con-101 exam. The SKILL.md body rule is: use CMS-driven content pages for marketing/editorial content; use object record pages for live data — do not rebuild live records as static CMS.

## Moderation Rules in Depth

Rate limits, keyword lists, member flagging, and review queues require hands-on configuration practice. The body rule is: enable moderation before opening a public community to UGC, not after the first incident. For detailed configuration (banned-keyword rule structure, queue routing, escalation to Service Cloud cases), see the Salesforce Help article "Moderate Your Experience Cloud Site."

## Mobile Publisher

Salesforce Mobile App experience wrapping (Mobile Publisher) is occasionally tested on the exam. Not covered in the SKILL.md body. See the official Mobile Publisher documentation on Salesforce Help.

## Enhanced Sites and Content Platform (Enhanced LWR) `[volatile — verify live]`

Introduced as a distinct, more capable tier above standard Build Your Own (LWR). Key capabilities not available in standard LWR:

- **Expression-based visibility:** per-component visibility rules using logic expressions (field values, audience membership, custom conditions) — goes beyond standard Audience targeting.
- **Expression-based component variations:** multiple versions of the same component with rule-driven switching per visitor context.
- **Enhanced CMS workspaces:** tighter content-channel binding; data binding for rendering Salesforce CMS content directly in LWR pages.
- **Data Cloud visitor insights:** connect Data Cloud identity and segment data to personalize experiences for known and anonymous visitors.
- **Partial deployment:** deploy only changed portions of a site, not the full bundle.
- **SEO-friendly URLs:** the `/s` path suffix is removed as part of the upgrade prerequisite.

**Upgrade path:** existing standard LWR sites can be upgraded to Enhanced LWR (Setup → Digital Experiences → [site] → Upgrade); the upgrade is **one-way and cannot be reversed**. Prerequisites: (1) remove the `/s` suffix from the site URL; (2) update CI/CD pipelines — enhanced sites use `DigitalExperienceBundle` / `DigitalExperienceConfig` metadata types instead of `ExperienceBundle`; metadata operations targeting `ExperienceBundle` will silently break on an enhanced site.

**Decision rule:** for new builds requiring expression-based personalization, Data Cloud integration, or partial deployment, start on Enhanced LWR rather than standard LWR. For existing Aura or standard LWR sites, evaluate the upgrade cost (URL migration, pipeline changes, one-way commitment) against the feature benefit before migrating.

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
