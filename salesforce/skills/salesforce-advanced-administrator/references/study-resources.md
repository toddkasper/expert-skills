# Advanced Administrator — Study Resources & Relevance

Load-on-demand companion to [../SKILL.md](../SKILL.md). Use when planning a study path for the Platform Administrator II exam or mapping the operational rules to a nonprofit (NPSP) org.

## Study Resources

### Official Salesforce

- [Prepare for Your Salesforce Platform Administrator II Certification Trailmix](https://trailhead.salesforce.com/users/strailhead/trailmixes/prepare-for-your-salesforce-advanced-administrator-credential) — Official Salesforce-curated trailmix; the canonical starting point
- [Salesforce Certified Platform Administrator II — Trailhead Credentials Page](https://trailhead.salesforce.com/credentials/advancedadministrator) — Links to exam guide, scheduling, and credential details
- [Salesforce Certified Platform Administrator II — Trailhead Academy](https://trailheadacademy.salesforce.com/certificate/exam-platform-admin2---Plat-Admn-301) — Official exam page with scheduling link
- [CRT-211: Prepare for Your Advanced Administrator Certification Exam](https://trailheadacademy.salesforce.com/classes/crt211-prepare-for-your-advanced-administrator-certification-exam) — Instructor-led Salesforce course (paid); covers all exam domains with hands-on exercises
- [Process Automation Specialist Superbadge](https://trailhead.salesforce.com/content/learn/superbadges/superbadge_process_automation_specialist) — Hands-on Trailhead superbadge; covers Flow end-to-end; strongly recommended for the Process Automation domain
- [Security Specialist Superbadge](https://trailhead.salesforce.com/content/learn/superbadges/superbadge_security) — Hands-on; covers the full sharing model, the Security and Access domain
- [Business Administration Specialist Superbadge](https://trailhead.salesforce.com/content/learn/superbadges/superbadge_business_administration_specialist) — Covers admin scenarios that cross multiple domains

### Community & Third-Party

- [Salesforce Ben — Advanced Administrator Certification Guide](https://www.salesforceben.com/advanced-administrator-certification-guide-tips/) — Free community guide; clear topic breakdowns with exam tips per domain; well maintained
- [Focus on Force — Platform Administrator II Practice Exams](https://focusonforce.com/salesforce-advanced-admin-certification-practice-exams/) — Paid; widely regarded as the best practice-question bank; question style closely mirrors the real exam
- [Automation Champion — How to Pass the Advanced Administrator Exam](https://automationchampion.com/2022/09/26/how-to-pass-salesforce-advanced-administrator-certification-exam-2/) — Free blog post by Rakesh Gupta; particularly strong on the Process Automation domain
- [Salesforce Memo — Prep and Pass the Advanced Administrator Exam](https://salesforcememo.com/how-to-prepare-for-and-pass-advanced-administrator-exam/) — Free; detailed topic-by-topic notes including Apex order-of-execution and entitlements deep-dive
- [Udemy — Salesforce Advanced Admin Practice Tests](https://www.udemy.com/course/salesforce-advanced-administrator-practice-tests/) — Paid (frequently discounted); 1,500+ practice questions; useful volume for repetition

---

## Relevance to NPSP & Nonprofit Cloud

The Advanced Administrator credential maps directly onto day-to-day NPSP administration.
Highest-leverage domains for a nonprofit org:

**Security and Access — directly applicable.**
NPSP orgs have layered sharing requirements: volunteers must not see donor giving history;
board members need campaign read access but not Contact financial data; staff scope varies by
program. The OWD → role hierarchy → sharing rules → FLS stack is exactly how sensitive
medical/PII fields are kept correctly scoped — and why every custom field needs an explicit
`<fieldPermissions>` grant to be queryable at all.

**Process Automation — directly applicable.**
NPSP ships heavy native automation (gift entry, recurring donations, Household maintenance)
plus managed-package workflow rules. Order-of-execution mastery is what lets you extend the
org without triggering recursion or governor failures — and is the exact knowledge that
diagnoses a managed-package field overwrite.

**Data and Analytics Management — directly applicable.**
NPSP's BDI has specific Contact/Account/Opportunity matching behavior; Data Loader vs. Data
Import Wizard vs. BDI object support and upsert-by-External-ID drive every migration.
Duplicate + Matching Rules keep one donor from fragmenting across web/check/event channels.

**Environment Management and Deployment — directly applicable.**
Deploying NPSP metadata (custom fields on Contact/Opportunity/npe01/npo02, permsets, layouts,
Quick Actions) requires dependency-ordering and the FLS-isn't-carried gotcha. An SFDX
source-driven pipeline maps straight to the exam's ALM/source-driven content.

**Auditing and Monitoring — directly applicable.**
Field History Tracking on Contact/Opportunity/npe03 is the standard way to prove to board
auditors a gift record wasn't altered; Setup Audit Trail tracks who deployed what — essential
in a shared-admin environment.

**Objects and Applications — moderately applicable.**
NPSP's Household Account model, Soft Credits (junction), and Relationships (junction between
Contacts) are advanced relationship patterns; the exam's junction/master-detail content
explains why NPSP behaves as it does.

**Cloud Applications — partially applicable.**
Sales/Service Cloud are largely out of scope for a fundraising org. Experience Cloud is the
relevant one if a nonprofit ever builds a hosted volunteer/donor portal.
