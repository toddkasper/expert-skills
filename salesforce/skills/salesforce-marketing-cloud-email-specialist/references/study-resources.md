# Marketing Cloud Email Specialist — Study Resources & Relevance

Load-on-demand companion to [../SKILL.md](../SKILL.md). Use when planning a study path for the Marketing Cloud Email Specialist exam (MC-202).

## Credential logistics

*Logistics are volatile — verify against the official exam guide before relying on any number.*

| Detail | Value |
|---|---|
| Exam Code | MC-202 |
| Questions | 60 scored multiple-choice/multiple-select (+ up to 5 unscored pilot questions) |
| Time Limit | 90 minutes |
| Passing Score | 67% (approximately 40 of 60 scored questions correct) |
| Cost | $200 USD (retake: $100 USD), plus applicable taxes |
| Prerequisites | None formally required; MKT 101 course and 6+ months SFMC experience strongly recommended |
| Retake Policy | Up to two retakes; first retake at the discounted retake fee. Maintained via annual Trailhead maintenance modules |

Delivery is proctored — onsite testing center or online remote proctoring (no open-book).
Recommended prep is ~28 hours via the official Trailmix.

Domain weights (official guide): Email Marketing Best Practices **10%**, Content Creation &
Delivery **24%**, Marketing Automation **26%**, Subscriber & Data Management **26%**, Insights &
Analytics **14%**.

## Study Resources

### Official Salesforce Resources

| Resource | URL |
|---|---|
| Official credential page | https://trailhead.salesforce.com/credentials/marketingcloudemailspecialist |
| Trailhead Academy exam page | https://trailheadacademy.salesforce.com/certificate/exam-mc-email---MC-202 |
| Official exam guide (PDF) | https://developer.salesforce.com/resources2/certification-site/files/SGCertifiedMarketingCloudEmailSpecialist.pdf |
| Official Certification Trailmix | https://trailhead.salesforce.com/users/strailhead/trailmixes/prepare-for-your-marketing-cloud-email-specialist-credential |
| MKT 101 course (recommended) | https://trailheadacademy.salesforce.com (search "Build and Analyze Customer Journeys") |

### Key Trailhead Modules & Trails

Complete in domain order:

- **Best Practices:** Email Marketing Best Practices · CAN-SPAM Compliance · Deliverability Fundamentals
- **Content & Delivery:** Content Builder Basics · AMPscript for Personalization (trail) · Content Studio modules
- **Subscriber & Data:** Marketing Cloud Data Management (trail) · Contact Builder Basics · Data Extension Basics · Marketing Cloud Data Views
- **Automation:** Automation Studio Basics · Journey Builder Basics · Build Customer Journeys with Journey Builder (trail)
- **Insights & Analytics:** Marketing Cloud Reporting · Analytics Builder Basics

### Community & Third-Party Resources

| Resource | URL / Notes |
|---|---|
| Salesforce Ben — MCES guide | https://www.salesforceben.com/marketing-cloud-email-specialist-certification-guide-tips/ |
| Automation Champion study guide | https://automationchampion.com/2022/08/01/how-to-pass-salesforce-marketing-cloud-email-specialist-exam-2/ |
| DataChai certification guide | https://www.datachai.com/post/salesforce-marketing-cloud-email-specialist-certification |
| Focus on Force practice exams | https://focusonforce.com/salesforce-marketing-cloud-email-specialist-certification-practice-exams/ |
| Certification Practice (free mock) | https://certificationpractice.com/practice-exams/salesforce-marketing-cloud-email-specialist |
| SkillCertPro practice bank | https://skillcertpro.com/product/salesforce-marketing-cloud-email-specialist-exam-questions/ |
| Score calculator tool | https://scuvanov.github.io/SalesforceCertScoreCalculator/ |
| Trailblazer Community MCES tag | https://trailhead.salesforce.com/trailblazer-community (search "Email Specialist") |

## Recommended Study Plan

1. **Weeks 1–2:** Complete the official Certification Trailmix (~28 hours). Do the hands-on challenges.
2. **Weeks 3–4:** Drill the two 26% domains — Marketing Automation and Subscriber & Data Management.
   Build real journeys and automations in a free SFMC developer org or trial.
3. **Week 5:** Two to three full practice exams; trace every miss back to the exam guide section.
4. **Week 6:** Review weak areas; watch multi-select questions (must get *all* correct options).

**Common exam traps (and the operational rule that resolves each):**
- List vs. Data Extension boundary → default to DE; List only for simple publication grouping.
- Triggered Send vs. Journey Builder vs. Automation Studio → transactional 1:1 / real-time
  orchestration / scheduled batch, respectively.
- Unsubscribe scope → List (one list) vs. Global (whole BU) vs. Master (whole account).
- Hard vs. soft bounce → Bounced/suppressed vs. retried-then-Held.
- IP warming → ~30 days, gradual ramp.
- SQL Data Views → know `_Open` `_Click` `_Bounce` `_Sent` `_Unsubscribe` and their key columns.
- Einstein → ESTO (best send time) vs. Engagement Scoring (who'll engage) vs. Copy Insights (subject copy).
- Automation step execution → same step = parallel, steps = sequential.

## Relevance to other verticals

The journey design, segmentation, deliverability, and automation patterns in this skill apply to any SFMC deployment. For NPSP/Nonprofit Cloud-specific guidance — Marketing Cloud for Nonprofits edition, donor-journey templates, NPSP Opportunity sync via MCC, and lapsed-donor segmentation — see [salesforce-nonprofit-cloud-consultant](../../salesforce-nonprofit-cloud-consultant/SKILL.md).

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
