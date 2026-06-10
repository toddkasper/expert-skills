# Administrator — Study Resources & Relevance

Load-on-demand companion to [../SKILL.md](../SKILL.md). Use when planning a study path for the Platform Administrator exam or mapping the operational rules to a nonprofit (NPSP) org.

## Credential logistics

*Logistics are volatile — verify against the official exam guide before relying on any number.*

| Field | Value |
|---|---|
| Questions | 60 scored + up to 5 unscored pretest = 65 total |
| Time Limit | 105 minutes |
| Passing Score | 68% (English); 65% (Japanese) — approximately 41 of 60 scored questions |
| Cost | $200 USD registration + applicable tax; $100 USD retake |
| Prerequisites | None |
| Retake Policy | No mandatory waiting period; retake voucher appears automatically after a failed attempt; no published cap on attempts |

Other facts: exam code Plat-Admn-201; delivered via Webassessor / Kryterion (proctored online or in-person test center); no reference materials permitted. The Dec 15, 2025 exam-guide refresh added an Agentforce AI domain.

Blueprint domains and weights: Data & Analytics 17%, Configuration & Setup 15%, Object Manager & Lightning App Builder 15%, Automation 15%, Sales & Marketing 10%, Service & Support 10%, Productivity & Collaboration 10%, Agentforce AI 8%.

## Study Resources

### Official Salesforce

- [Salesforce Certified Platform Administrator Exam Guide](https://help.salesforce.com/s/articleView?id=005298966&language=en_US&type=1) — the authoritative topic outline and objectives; read before anything else
- [Prepare for Your Salesforce Platform Administrator Certification Trailmix](https://trailhead.salesforce.com/users/strailhead/trailmixes/prepare-for-your-salesforce-administrator-credential) — Salesforce-curated Trailmix covering all exam domains
- [Study for the Administrator Certification Exam — Trailhead Trail](https://trailhead.salesforce.com/content/learn/trails/administrator-certification-prep) — official hands-on trail with embedded challenges; best for learning-by-doing
- [Salesforce Certified Platform Administrator — Trailhead Academy](https://trailheadacademy.salesforce.com/certificate/exam-platform-admin---Plat-Admn-201) — official registration page, links to instructor-led options
- [What the Salesforce Certified Platform Administrator Exam Update Means for Admins](https://admin.salesforce.com/blog/2026/what-the-salesforce-certified-platform-administrator-exam-update-means-for-admins) — official Salesforce Admins blog post on the December 2025 exam refresh

### Community Study Guides and Practice Exams

- [Focus on Force — Platform Administrator Study Guide](https://focusonforce.com/courses/salesforce-certified-administrator-study-guide/) — the most widely used paid study guide; covers all objectives with annotated screenshots and practice questions; trusted by 150,000+ candidates
- [Focus on Force — Practice Exams](https://focusonforce.com/courses/salesforce-certified-administrator/) — timed practice exams with explanations; closest third-party approximation to real exam style
- [Salesforce Ben — Salesforce Certified Platform Administrator Guide](https://www.salesforceben.com/salesforce-administrator-certification/) — free community guide with topic breakdowns, tips, and links to Trailhead modules
- [Salesforce Ben — Exam Update 2026 Coverage](https://www.salesforceben.com/salesforce-platform-admin-exam-updated-for-2026-more-agentforce-less-configuration/) — summary of what changed in the December 2025 refresh; good orientation before diving into study materials
- [OpenExamPrep — Free Salesforce Admin Practice Questions 2026](https://open-exam-prep.com/practice/salesforce-admin) — free practice questions updated for the 2026 blueprint
- [Trailblaze Prep — Salesforce Exam Retake Policy](https://www.trailblazeprep.com/salesforce-exam-retake-policy) — clear explanation of retake fees, timing, and voucher behavior

## Relevance to NPSP and Nonprofit Cloud

The Administrator certification is the direct prerequisite for the Nonprofit Success Pack Consultant credential, and every domain maps to live nonprofit-org work:

- **Security model:** permission sets, explicit FLS on custom fields, and OWD on custom objects are textbook scenarios — and the "required fields are always FLS-visible, never in fieldPermissions" rule is a live constraint in any SFDX-managed nonprofit org.
- **Object Manager:** custom fields, external-ID upsert keys, and role-suffixed Lookups are exam-grade configuration that NPSP orgs exercise daily.
- **Data & Analytics:** NPSP Household Accounts (Contact → Account → Household) require the same relational reasoning the exam tests; Data Loader / NPSP Data Import drive bulk recovery and Contact backfills.
- **Automation:** The Dec 2025 Workflow Rule retirement forced NPSP's own migration to Flow, making Flow mastery essential. The NPSP MobilePhone overwrite is the canonical "managed-package automation bites you" lesson.
- **Service & Support:** Even orgs with no Cases use the time-based escalation pattern conceptually (e.g. "awaiting documents" reminders); Knowledge/entitlements apply if a staff support portal is added.
- **Agentforce:** Forward-looking for AI-assisted review/donor engagement; the agent-permission model is the same access stack used throughout — critical wherever PII/medical data is handled.

**Practical recommendation:** A team member who configured a nonprofit org (permsets, custom objects, FLS, flows, NPSP data model) already has hands-on exposure to ~70% of exam content. Remaining gaps are typically Forecasting/Territories, Service Cloud case configuration, Campaigns/Web-to-Lead, and Agentforce setup — close them with a focused Trailhead pass plus a Focus on Force practice set.
