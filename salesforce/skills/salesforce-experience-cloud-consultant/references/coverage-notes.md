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
