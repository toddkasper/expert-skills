# Business Analyst — Study Resources & Relevance

Load-on-demand companion to [../SKILL.md](../SKILL.md). Use when planning a study path for the Business Analyst (BA-201) exam or mapping the operational rules to a nonprofit (NPSP) org.

## Credential logistics

*Logistics are volatile — verify against the official exam guide before relying on any number.*

| Field | Value |
|---|---|
| Exam Name | Salesforce Certified Business Analyst |
| Exam Code | BA-201 |
| Questions | 60 scored + up to 5 unscored pretest = up to 65 total |
| Time Limit | 105 minutes |
| Passing Score | 72% |
| Cost | US$200 registration + applicable tax; $100 retake fee |
| Prerequisites | None (the formerly required Administrator certification was dropped as a hard prerequisite on May 2, 2023) |
| Retake Policy | Half-price ($100) retakes; up to three attempts per release cycle |

**Recommended experience:** 2+ years hands-on Salesforce platform experience and 2+ years functioning as a business analyst on real implementations.

**Delivery:** Proctored online or in-person at a Kryterion test center. No reference materials permitted.

**Maintenance:** Annual release-specific Trailhead maintenance module (one per year, free).

**Domain weights (60 scored questions; each point ≈ 0.6 questions):** Collaboration with Stakeholders 24% · User Stories 18% · Customer Discovery 17% · Requirements 17% · Business Process Mapping 16% · User Acceptance Testing 8%.

## Study Resources

### Official Salesforce Resources

- **Credential page (overview + exam guide link):** [trailhead.salesforce.com/credentials/businessanalyst](https://trailhead.salesforce.com/credentials/businessanalyst)
- **Cert Prep: Salesforce Business Analyst (module):** [trailhead.salesforce.com/content/learn/modules/salesforce-business-analyst-certification-prep](https://trailhead.salesforce.com/content/learn/modules/salesforce-business-analyst-certification-prep) — interactive flashcards, practice quizzes, domain-by-domain coverage (~70 min)
- **Official trailmix — "Prepare for Your Salesforce Business Analyst Credential":** [trailhead.salesforce.com/users/strailhead/trailmixes/prepare-for-your-salesforce-business-analyst-credential](https://trailhead.salesforce.com/users/strailhead/trailmixes/prepare-for-your-salesforce-business-analyst-credential) — curated set of trails and modules (~28 hrs total)
- **Trail — "Get Started as a Salesforce Business Analyst":** [trailhead.salesforce.com/content/learn/trails/get-started-as-a-salesforce-business-analyst](https://trailhead.salesforce.com/content/learn/trails/get-started-as-a-salesforce-business-analyst) — foundational trail covering BA role, user stories, and process mapping
- **Superbadge — Business Administration Specialist:** [trailhead.salesforce.com/content/learn/superbadges/superbadge_business_specialist](https://trailhead.salesforce.com/content/learn/superbadges/superbadge_business_specialist) — hands-on scenario applying admin + BA skills in a realistic org; frequently cited as the most useful pre-exam practical exercise
- **Trailblazer Community — Business Analyst group:** [trailblazers.salesforce.com](https://trailblazers.salesforce.com) — search "Business Analyst" to find the credential-specific group; active study threads, exam debrief posts, and community study sessions
- **Exam Guide (official PDF + details):** [trailheadacademy.salesforce.com/certificate/exam-business-analyst---BA-201](https://trailheadacademy.salesforce.com/certificate/exam-business-analyst---BA-201)

### Third-Party Resources

- **Salesforce Ben — BA Certification Guide & Tips:** [salesforceben.com/salesforce-business-analyst-certification-guide-tips/](https://www.salesforceben.com/salesforce-business-analyst-certification-guide-tips/) — detailed domain breakdown, study timeline, and exam-day tips; free
- **Focus on Force (now K2 University) — BA Certification Guide:** [focusonforce.com/salesforce-certifications/salesforce-business-analyst-certification-guide/](https://focusonforce.com/salesforce-certifications/salesforce-business-analyst-certification-guide/) — study notes and practice questions organized by domain
- **CertificationPractice.com — Free BA-201 Practice Tests:** [certificationpractice.com/practice-exams/salesforce-certified-business-analyst](https://certificationpractice.com/practice-exams/salesforce-certified-business-analyst) — scenario-based free practice questions

### Suggested Study Sequence (4–6 weeks)

1. Download the official exam guide PDF from the Trailhead Academy registration page — read the domain descriptions and percentage weights first.
2. Work through the official trailmix (~28 hrs); prioritize the Collaboration with Stakeholders and User Stories modules, which together account for 42% of the exam.
3. Complete the Business Administration Specialist superbadge for hands-on practice applying configuration in a BA-driven scenario.
4. Read the Salesforce Ben guide and use its flashcard-style domain summaries as a review pass.
5. Take 2–3 full timed practice exams; identify which domains you're missing; go back to Trailhead for targeted review.
6. Re-read your user story writing and acceptance criteria notes the day before — Collaboration + User Stories is nearly half the exam.

---

## Relevance to NPSP and Nonprofit Cloud

The BA skill set is the invisible foundation of any NPSP implementation. The connections are direct and operational:

**Customer Discovery → requirements baseline.** Understanding the existing (often paper-based) workflow, the data-entry burden it imposes, and the gaps a Salesforce solution must close is Customer Discovery in practice: assess current state (including a managed-package automation audit), categorize gaps, and scope what Salesforce solves without custom code.

**Collaboration with Stakeholders → staff alignment.** Decisions like anonymous vs. authenticated submission, optional vs. required documents, and magic-link vs. login portals emerge from validating what real users need (e.g. elderly users on shared devices) versus what a technically elegant solution would impose — each recorded in a decision log.

**Business Process Mapping → Salesforce data model design.** A pipeline such as application → storage snapshot → sweep job → SF upsert → approval → Contact create → downstream assignment is a swimlane expressed in code. A single custom object with a record-type/discriminator field often comes from recognizing that review/approval is the same process regardless of type.

**Requirements → validation schemas and field lists.** Validation schemas and generated field-length/picklist constants are functional requirements expressed in code; keeping them synced to the org is requirements lifecycle management with full traceability to the org as source of truth.

**User Stories → backlog items.** A phased roadmap is a backlog; each TODO item is a story awaiting proper "As a [persona], I want… so that…" form with Given/When/Then criteria.

**User Acceptance Testing → the e2e test harness.** An automated test harness (one scenario per story, happy path plus known edge cases like date validation, restricted-picklist mismatches, and optional fields), run in a sandbox and never prod, is the automated UAT layer.

**NPSP-specific BA considerations:**
- NPSP's opinionated, Contact-centric model means "create a Contact on approval" carries hidden complexity: Household Account auto-creation, the `npe01__PreferredPhone__c` workflow rule that copies `Phone → MobilePhone`, and Relationship processing. A BA must understand these side effects before writing a requirement that assumes a simple `Contact.create()`.
- Nonprofits keep board members, volunteers, donors, and program participants as Contacts in one org; the BA must elicit which persona each story serves and ensure security (profiles, permission sets, FLS, sharing) enforces appropriate access.
- The Salesforce Certified Nonprofit Cloud Consultant (formerly NPSP Consultant) credential is the natural next step: this BA credential provides the methodology; the consultant credential adds the data-model and configuration depth on top.
