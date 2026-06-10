# Sales Cloud, Service Cloud & Productivity — Deep Detail

Referenced from the main SKILL.md §6. Load this file when configuring lead assignment rules, case queues, entitlements/milestones, Omni-Channel, Knowledge, or AppExchange installs.

---

## Sales Cloud

- **Leads:** assignment rules route by criteria to a user or queue; web-to-lead default cap is **500/day** `[volatile — verify live]`; submissions above the cap enter a **pending request queue** and are processed when the daily limit resets — they are not lost, but may be delayed. Lead conversion maps Lead fields → Account/Contact/Opportunity (configurable in Setup → Lead Settings → Map Lead Fields); the Lead record becomes read-only/archived after conversion.
- **Accounts/Contacts — account model matters:** Business Accounts (standard), Person Accounts (individual as an account), or a package's Household model (NPSP). Confirm which is active before building reports or rollups on relationships/membership — each model changes how Contacts attach and how membership counts work.
- **Opportunities:** stages carry probability (editable in the Sales Process); Opportunity Contact Roles link multiple people to one deal; a managed package may repurpose Opportunities for a non-sales process (e.g. donations, grants). Always confirm the business use before treating Stage as a pipeline metric.
- **Campaigns:** member statuses drive response tracking; campaign hierarchy rolls up member and response counts to a parent campaign; ROI fields (Actual Cost, Expected Revenue) feed campaign reporting.
- **Products & Price Books:** Products define what you sell; Price Books set price per product per currency; an Opportunity must select a Price Book before line items can be added; the Standard Price Book is the default and cannot be deleted.

**Red flags:** treating a repurposed Opportunity object as a real sales pipeline; reporting on Contacts without confirming the active account model; adding Opportunity line items without first associating a Price Book; assuming web-to-lead overflow records are immediately available — they queue until the daily limit resets (no records are lost, but processing is delayed).

---

## Service Cloud

- **Cases:** case queues group work items; assignment rules send to user/queue on case creation; **escalation rules** are time-based and **business-hours-aware** — the same mechanism underlies any "awaiting action" reminder pattern (milestones, SLAs).
- **Email-to-Case:** Standard Email-to-Case requires an open inbound firewall port; **On-Demand Email-to-Case** routes through Salesforce servers and avoids the firewall requirement — prefer On-Demand unless you have a specific reason to route mail directly. Both thread replies to the original case via a threading key in the subject line.
- **Web-to-Case:** captures form submissions as Cases; default cap is **5,000 cases/24 hours** `[volatile — verify live]`; submissions above the cap enter a **pending request queue** and are processed when the limit resets — they are not emailed or dropped. Requires no code — generate HTML from Setup → Web-to-Case.
- **Entitlements & Milestones:** entitlements attach to accounts or products; milestone actions (warning/violation) fire on a time-based schedule relative to case creation or a status change; milestones require a **process** (Setup → Entitlement Processes) associated with the entitlement record — they do not activate automatically on all cases.
- **Omni-Channel:** routes by presence/capacity/skills. Agent status (Available/Busy/Away) is set by the agent; a supervisor can override. Routing configurations define priority and model: Most Available (least-busy agent), Least Active (fewest open items), or External Routing (custom logic). Omni-Channel Supervisor app provides a real-time queue/agent view.
- **Knowledge:** articles attach to cases and are searchable by support agents and in Experience Cloud portals; article visibility is controlled by data categories and the user's **data category visibility** settings (Setup → Data Category Visibility). Lightning Knowledge replaces Classic Knowledge — a one-way migration. Article types in Classic become record types in Lightning Knowledge.

**Red flags:** expecting Standard Email-to-Case to work without an open firewall port; assuming milestones activate without an entitlement process; building a reminder flow when an escalation rule is the right native tool; migrating to Lightning Knowledge and expecting Classic article types to carry over as-is.

---

## Productivity & Collaboration

- **Quick Actions:** object-specific (create/update/log-a-call on a record) vs global. Contextual record tabs backed by object-specific Quick Actions are **subject to the QA cache trap** (SKILL.md §3) — apply the cache-bust (edit `<description>` or `<label>` and redeploy) after editing field lists.
- **Activities (Tasks/Events):** group tasks assign to up to **100 users** `[volatile — verify live]` (SF creates a copy per user); shared activities link one activity to multiple contacts (up to 50 contacts per activity).
- **Email:** org-wide email addresses allow sending on behalf of a shared address; letterhead/HTML templates use merge fields; Email-to-Salesforce BCC logging captures outbound email to lead/contact activity feeds. Transactional email is often handled outside SF (e.g. Amazon SES), while approval-notification copy lives in SF Flow email actions.
- **Chatter/Collaboration:** groups, file sharing, @mentions, topic tagging. External Chatter is possible with Experience Cloud licenses. Chatter Feed Tracking (Setup → Chatter → Feed Tracking) controls which object/fields appear in the record's feed — enable per object.

---

## AppExchange & Managed Packages

- **Install in sandbox first** — always. Test integration, data model impacts, and automation conflicts before production.
- **Security review badge** — check it is present before installing; unreviewed packages may be experimental or partner-only.
- **Managed-package updates:** updates install centrally (Setup → Installed Packages → Upgrade); review the release notes; updates can add new fields, automation, or change existing logic. Regression-test automation after a major package upgrade.
- **Never edit managed metadata directly** — you can't save it (it's locked), but browser tooling may let you edit it temporarily; changes are overwritten on next package upgrade. The correct pattern is to **extend alongside**: custom fields, custom flow paths, override actions that call managed flows.
- **Namespace isolation:** managed-package fields, flows, and triggers run under the package's namespace prefix (e.g. `npsp__`). When debugging mystery automation, filter by namespace in Setup → Workflow Rules and Setup → Flows (see SKILL.md §4 and Scenario 4).

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
