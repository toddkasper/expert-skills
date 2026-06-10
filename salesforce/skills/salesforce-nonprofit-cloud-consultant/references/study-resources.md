# Nonprofit Cloud Consultant — Study Resources & Relevance

Load-on-demand companion to [../SKILL.md](../SKILL.md). Use when planning a study path for either nonprofit credential (NP-Con-101 or NP-Con-102), or when mapping the operational rules to a specific nonprofit org's configuration.

## Credential logistics

*Logistics are volatile — verify against the official exam guide before relying on any number.*

### NP-Con-101 — Salesforce Certified Nonprofit Success Pack Consultant

| Field | Value |
|---|---|
| Questions | 60 multiple-choice/multiple-select (plus up to 5 unscored) |
| Time Limit | 105 minutes |
| Passing Score | 67% (~40 of 60 scored questions) |
| Cost | $200 USD registration + applicable tax; $100 retake |
| Prerequisites | Salesforce Certified Administrator credential |
| Retake Policy | 1st retake after 1 day; 2nd+ after 14 days; max 3 attempts per release window |

Recommended experience: 2–5 years as a Salesforce Administrator or Consultant with hands-on NPSP implementation experience. Delivered as proctored online or in-person at a test center.

### NP-Con-102 — Salesforce Certified Nonprofit Cloud Consultant (NPC)

| Field | Value |
|---|---|
| Questions | 60 multiple-choice/multiple-select (plus up to 5 unscored) |
| Time Limit | 105 minutes |
| Passing Score | 64% (39 of 60 scored questions) |
| Cost | $200 USD registration + applicable tax; $100 retake |
| Prerequisites | Salesforce Certified Administrator credential |
| Retake Policy | 1st retake after 1 day; 2nd+ after 14 days; max 3 attempts per release window |

Recommended experience: 2–5 years implementing Salesforce solutions for nonprofits with Industries / Nonprofit Cloud hands-on experience. Delivered as proctored online or in-person at a test center.

---

## Study Resources

### Official Salesforce Resources

- **NPC (NP-Con-102) Credential Page:** [trailhead.salesforce.com/credentials/nonprofitcloudconsultant](https://trailhead.salesforce.com/credentials/nonprofitcloudconsultant)
- **NPC Trailmix (NP-Con-102):** [Prepare for Your Salesforce Nonprofit Cloud Consultant (NPC) Credential](https://trailhead.salesforce.com/users/strailhead/trailmixes/prepare-for-your-salesforce-nonprofit-cloud-consultant-npc-cred)
- **NPSP Trailmix (NP-Con-101):** [Prepare for Your Salesforce Nonprofit Success Pack Consultant Credential](https://trailhead.salesforce.com/users/strailhead/trailmixes/prepare-for-salesforce-nonprofit-cloud-consultant-credential)
- **Official NPC Exam Guide PDF:** [SGCertifiedNonprofitCloudConsultant.pdf](https://developer.salesforce.com/resources2/certification-site/files/SGCertifiedNonprofitCloudConsultant.pdf)
- **Trailhead Academy Registration (NP-Con-102):** [trailheadacademy.salesforce.com/certificate/exam-nonprofit-cld-consultant-npc---NP-Con-102](https://trailheadacademy.salesforce.com/certificate/exam-nonprofit-cld-consultant-npc---NP-Con-102)
- **Trailhead Academy Registration (NP-Con-101):** [trailheadacademy.salesforce.com/certificate/exam-npsp-consultant---NP-Con-101](https://trailheadacademy.salesforce.com/certificate/exam-npsp-consultant---NP-Con-101)
- **NPSP Data Model Trailhead Module:** [Explore the Nonprofit Success Pack Data Model Essentials](https://trailhead.salesforce.com/content/learn/modules/nonprofit-success-pack-administration-basics/understand-the-npsp-data-model)
- **Nonprofit Cloud Community Study Group:** [Non-Profit Cloud Consultant Study Group](https://trailhead.salesforce.com/trailblazer-community/groups/0F94V0000004p4bSAA)

### Community Resources

- **SalesforceBen — NPSP Consultant Guide (NP-Con-101):** [salesforceben.com/salesforce-nonprofit-success-pack-consultant-certification](https://www.salesforceben.com/salesforce-nonprofit-success-pack-consultant-certification/)
- **SalesforceBen — NPC Exam Guide (NP-Con-102):** [salesforceben.com/salesforce-nonprofit-cloud-consultant-npc-exam-guide-tips](https://www.salesforceben.com/salesforce-nonprofit-cloud-consultant-npc-exam-guide-tips/)
- **Trailblaze Prep — Free Practice Questions (NPSP):** [trailblazeprep.com/certifications/nonprofit-success-pack-consultant](https://www.trailblazeprep.com/certifications/nonprofit-success-pack-consultant)
- **Trailblaze Prep — Free Practice Questions (NPC):** [trailblazeprep.com/certifications/nonprofit-cloud](https://www.trailblazeprep.com/certifications/nonprofit-cloud)
- **DZ Insights — 4-Week Study Plan (NP-Con-101):** [dzinsights.com/blog/4-week-study-plan-for-the-salesforce-np-con-101-certification-exam](https://www.dzinsights.com/blog/4-week-study-plan-for-the-salesforce-np-con-101-certification-exam)
- **VMExam — NP-Con-101 Syllabus:** [vmexam.com/salesforce/salesforce-nonprofit-success-pack-consultant-certification-exam-syllabus](https://www.vmexam.com/salesforce/salesforce-nonprofit-success-pack-consultant-certification-exam-syllabus)
- **VMExam — NP-Con-102 Syllabus:** [vmexam.com/salesforce/salesforce-nonprofit-cloud-consultant-certification-exam-syllabus](https://www.vmexam.com/salesforce/salesforce-nonprofit-cloud-consultant-certification-exam-syllabus)

### Hands-on Practice

- **Nonprofit Cloud Trial Org:** Free 30-day trial org with Nonprofit Cloud pre-installed (request from salesforce.org or Trailhead). Primary practice environment for NP-Con-102 prep.
- **Trailhead Playground with NPSP:** For NP-Con-101 prep, install NPSP from AppExchange into a Trailhead Playground (free).
- **A configured NPSP sandbox:** Reviewing a real org's NPSP Settings, Relationship Types, Recurring Donation config, and GAU structure provides direct exam-relevant practice — and is the only safe place to make changes.

---

## Relevance to NPSP & Nonprofit Cloud

An org running the **NPSP managed package** makes **NP-Con-101** the most directly applicable credential for its implementation team today. Every major exam topic maps to live NPSP configuration:

| Exam Topic | Typical NPSP configuration | Operational rule |
|---|---|---|
| Household Account model | All Contacts live in Household Accounts | SKILL.md §1 |
| Affiliations | Contact ↔ org links via Affiliations | SKILL.md §1 |
| NPSP Relationships | Spouse / family / "buddy" relationships among Contacts | SKILL.md §1 |
| Recurring Donations | Donor-side recurring gifts (ERD vs legacy) | npsp-deep-dive.md §4 |
| Engagement Plans | Constituent cultivation / outreach automation | nonprofit-cloud-industries.md §16 (Action Plan analog) |
| GAU Allocations | Opportunity fund designation for program tracking | SKILL.md §2 / npsp-deep-dive.md §15 |
| Contact Roles / Soft Credits | Household / influencer recognition | SKILL.md §2 |
| Gift Entry | Batch entry for checks and mail-in donations | npsp-deep-dive.md §13 |
| TDTM | Disable/re-enable during bulk migration; recalc rollups | npsp-deep-dive.md §5 |
| NPSP Data Import Tool | Backfill / failed-submission recovery | npsp-deep-dive.md §13 |
| Customizable Rollups | Powers giving summary fields on Contact | npsp-deep-dive.md §3 |
| LYBUNT / SYBUNT reports | Donor retention tracking for the annual fund | npsp-deep-dive.md §15 |
| Duplicate management | Email+birthdate matching prevents duplicate Contacts | npsp-deep-dive.md §14 |
| Custom Contact fields | FLS + permset knowledge essential | npsp-deep-dive.md §8, §9 |
| Permission Sets | API-user and feature-scoped permsets | npsp-deep-dive.md §8, SKILL.md §20 |

---

## Certification Sequence Recommendation

1. **Salesforce Certified Administrator** — prerequisite for both nonprofit credentials; covers the security model, automation, and data management foundations used daily in any NPSP org.
2. **Salesforce Certified Nonprofit Success Pack Consultant (NP-Con-101)** — directly tests an NPSP org's current configuration. Highest-leverage cert for anyone managing or developing an NPSP-based nonprofit org today.
3. **Salesforce Certified Nonprofit Cloud Consultant (NP-Con-102)** — future-relevant as Salesforce shifts nonprofits from NPSP toward Industries-based Nonprofit Cloud. Pursue after NP-Con-101 once a concrete NPSP migration timeline is announced.

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
