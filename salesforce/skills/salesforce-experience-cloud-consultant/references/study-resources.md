# Experience Cloud Consultant — Study Resources & Relevance

Load-on-demand companion to [../SKILL.md](../SKILL.md). Use when planning a study path for the Experience Cloud Consultant exam or mapping the operational rules to a nonprofit (NPSP) org.

## Credential logistics

*Logistics are volatile — verify against the official exam guide before relying on any number.*

| Field | Value |
|---|---|
| Exam Name | Salesforce Certified Experience Cloud Consultant |
| Exam Code | EX-Con-101 |
| Questions | 60 scored multiple-choice/multiple-select (up to 5 additional unscored pretest questions may appear) |
| Time Limit | 105 minutes |
| Passing Score | 65% |
| Cost | $200 USD registration + applicable tax; $100 USD retake fee |
| Prerequisites | Salesforce Certified Administrator credential required. Recommended: ~6 months hands-on Experience Cloud experience |
| Retake Policy | No mandatory waiting period between attempts |

Delivery: proctored — online or at a testing center; no reference materials
permitted. Recommended prep time ≈ 33 hours 45 minutes (Trailhead estimate).
Instructor-led option: ADX271 (Create and Manage Experience Cloud Sites).

**Domain weights** (each point ≈ 0.6 scored questions): Admin/Setup/Config 25% ·
Sharing/Visibility/Licensing 17% · Branding/Personalization/Content 15% ·
User Creation/Auth 13% · Templates/Themes 10% · Basics 8% ·
Customization Considerations 7% · Adoption/Analytics 5%. **Spend prep time
proportionally: the sharing model and the external license matrix are where you
both fail the exam and break a production portal.**

## Study Resources

### Official Salesforce

| Resource | URL |
|---|---|
| Credential page (Trailhead) | https://trailhead.salesforce.com/credentials/experiencecloudconsultant |
| Official Exam Guide | https://trailhead.salesforce.com/help?article=Salesforce-Certified-Experience-Cloud-Consultant-Exam-Guide |
| Official Trailmix | https://trailhead.salesforce.com/users/strailhead/trailmixes/prepare-for-your-salesforce-experience-cloud-consultant-credenti |
| Trailhead Academy listing | https://trailheadacademy.salesforce.com/certificate/exam-exp-cld-consultant---EX-Con-101 |
| LWR Developer Docs | https://developer.salesforce.com/docs/atlas.en-us.exp_cloud_lwr.meta/exp_cloud_lwr/template_overview.htm |
| Experience Cloud User Licenses Help | https://help.salesforce.com/s/articleView?id=sf.users_license_types_communities.htm |
| Learn Experience Cloud (community learning hub) | https://www.learnexperiencecloud.com/s/ |

### Key Trailhead Modules (mapped to the operational sections above)

- **Scoping & Basics (§1)** — "Digital Experiences: Quick Look", "Experience Cloud for Salesforce Admins"
- **Sharing & Licensing (§2)** — "Experience Cloud User Licenses and Permissions", "Sharing and Visibility in Experience Cloud"
- **Branding & Content (§3)** — "Experience Cloud: Branding and Personalization", "Salesforce CMS Basics"
- **Templates (§4)** — "Guide to Lightning Web Runtime" (https://trailhead.salesforce.com/content/learn/modules/lightning-web-runtime-for-experience-cloud/get-started-with-lightning-web-runtime)
- **Authentication (§5)** — "Identity for Partners", "Single Sign-On for Salesforce Communities"
- **Administration (§7)** — "Partner Relationship Management", "Delegated Administration for Communities"

### Third-Party Study Guides

| Resource | URL |
|---|---|
| Salesforce Ben — Experience Cloud Consultant guide | https://www.salesforceben.com/experience-cloud-consultant-certification-guide-tips/ |
| FocusOnForce — Community Cloud exam guide (now Experience Cloud) | https://focusonforce.com/courses/community-cloud-study-guide/ |
| SFDC Developers — Exam prep guide for developers (2026) | https://sfdcdevelopers.com/2026/03/28/experience-cloud-consultant-exam-prep-guide-for-developers/ |
| Dinesh Yadav — Exam guide with topic breakdown | https://dineshyadav.com/salesforce-certified-experience-cloud-consultant/ |
| Advanced Communities — Experience Cloud templates guide | https://advancedcommunities.com/blog/how-to-choose-the-right-experience-cloud-template/ |

### Practice Exams

- **FocusOnForce** — community-cloud-certification-practice-exams (now redirects to K2 University / Salesforce practice content)
- **Udemy** — multiple instructors offer timed practice sets; search "Experience Cloud Consultant", filter by recent update date
- **ExamTopics** — free community-sourced questions (https://www.examtopics.com/exams/salesforce/certified-experience-cloud-consultant/)

---

## Relevance to NPSP & Nonprofit Cloud

Experience Cloud is how nonprofits engage external stakeholders (donors, volunteers,
program participants) on Salesforce. Operational touch points:

### Nonprofit-Specific License

Salesforce offers an **Experience Cloud for Nonprofits** license tier (≈ Partner
Community pricing) giving NPSP/Nonprofit Cloud orgs Experience Builder, authenticated
portals, and native access to NPSP objects (Contacts, Opportunities, Campaigns,
Volunteers for Salesforce). **Rule:** when scoping a nonprofit portal, default to this
tier — not standard Customer/Partner Community — and confirm the needed NPSP objects
are license-exposed before designing sharing.

### Donor Portal (sharing-model rule in practice)

A donor portal exposes `npe01__OppPayment__c`, `Opportunity` (giving history), RD2
recurring donations, campaign participation, and soft-credit/household roll-ups.
**The sharing rule:** donors must see their own Opportunities, not others'. Key a
**sharing set** on `Opportunity.npe01__Contact_Opp_For__r` (primary contact lookup) —
exactly the §2 mechanism. **NPSP twist:** the Household **Account** model creates one
Account per household, so configure the sharing set against the **Household Account**,
not the Contact, or visibility is wrong. **Verify with** a `describe` of `Opportunity`
to confirm the lookup path before building.

### Volunteer Portal

V4SF objects (`Volunteer_Job__c`, `Volunteer_Shift__c`, `Volunteer_Hours__c`) can be
surfaced for shift self-signup and hours logging. They're custom objects — apply the
**same CRUD + FLS + sharing-set** discipline as any external-user scenario; nothing
about "it's a managed package" exempts them from the §2 layers.

### Program Participant Access

Nonprofit Cloud Case Management (NCCM) maps to the **Customer Account Portal**
template + the §5 self-registration pattern for participants to view referrals and
update contact info.

### NPSP-Specific Operational Gotchas

- **Household Account sharing:** key sharing sets on the Household Account, not the
  Contact, or external users inherit wrong visibility.
- **Managed-package FLS still required:** `npe01__*` / `npsp__*` fields need explicit
  FLS on the member permset/profile — same as custom fields.
- **NPSP Flows fire in the portal session:** self-registration Contact/Opportunity
  creation triggers NPSP automation under the portal user's context — test for
  governor-limit errors AND unexpected field mutations.

> For org-specific applications of these rules, see the per-org appendices under `../orgs/<org-name>.md`.
