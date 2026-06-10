# Nonprofit Cloud (Industries) Deep Dive — Sections 16–19

Load-on-demand companion to [../SKILL.md](../SKILL.md). Contains the full operational detail for PART B (NP-Con-102 / Salesforce Industries Nonprofit Cloud, now branded **Agentforce Nonprofit** as of Oct 2025 `[volatile — verify live]`). Applies only if the org has Nonprofit Cloud / Agentforce Nonprofit / Industries enabled — confirm by listing the org's objects (your Salesforce MCP, `sf sobject list`, or Setup → Object Manager); NPC uses namespace-free Industries standard objects like `Gift`, `Program`, `ProgramEnrollment`.

---

## 16. NPSP-term → NPC-term translation (so you pick the right object/feature)

| NPSP (101) | Nonprofit Cloud (102) | Note |
|---|---|---|
| Opportunity / Payment | **Gift** / Gift transaction | Industries fundraising data model |
| Recurring Donation | **Gift Commitment** + Gift Commitment Schedule | Open vs fixed, same pause/cancel semantics |
| Campaign / appeal | **Outreach Source Code** | attribution object, not standard Campaign |
| Engagement Plan | **Action Plan** (Template) | Action Plans are case/account-level |
| — (no analog) | **Care Plan** (Goals/Problems/Tasks) | clinical/longitudinal case mgmt |
| Household Account | Person Account / Household | NPC commonly uses Person Accounts |
| NPSP batch rollups | **Data Processing Engine (DPE)** | batch transforms/rollups |
| Custom Flow intake | **OmniScript** | guided multi-step UI |
| — | DataRaptor / Integration Procedure / FlexCard | OmniStudio building blocks |

---

## 17. Permission Set Licenses gate NPC features

**Rule: in Nonprofit Cloud, access errors are usually a missing Permission Set License, not a sharing problem.** Each module (Fundraising, Program Management, Outcome Management, Grantmaking) requires its specific PSL **plus** a Permission Set assigned to the user. Troubleshoot "can't see the feature" by checking the PSL assignment first. (This mirrors the External Client App lesson in SKILL.md §20: assignment location matters and browser tools report success on the wrong screen.)

Troubleshooting checklist when a user can't access a Nonprofit Cloud feature:
1. Is the correct PSL assigned? (Setup → Users → [User] → Permission Set License Assignments)
2. Is the corresponding Permission Set assigned to the user?
3. Is the user's profile/permset granting object CRUD on the NPC object?
4. Is OWD / sharing granting record-level access?

---

## 18. Program Management & Outcome objects

**Core Program Management objects:**
- **Program** = the service offered (e.g. "Emergency Housing Assistance")
- **Program Engagement** = a constituent enrolled in a Program (with status/role/start date)
- **Service** = a type of service delivery (e.g. "Meals", "Counseling")
- **Service Delivery** = a unit delivered to a specific constituent (links Service → Program Engagement + quantity/date)

**Outcome Management objects:**
- **Indicator** = what you measure (e.g. "Housing Stability Score")
- **Indicator Result** = a measurement of an Indicator at a point in time for a constituent
- **Result** = a container grouping Indicator Results for a single assessment instance

**Dynamic Assessments** = structured intake/outcome collection forms; used for repeatable measurement forms.

Decision matrix:
- OmniScript for guided multi-step intake (application, enrollment)
- Dynamic Assessment for repeatable measurement forms (monthly outcome check-ins)
- Standard Flow for simple internal automation (status change notifications)

---

## 19. OmniStudio tool selection

| Need | Tool |
|---|---|
| Guided, branching, multi-step user flow (intake, application) | **OmniScript** |
| Read/transform/write data declaratively (no Apex) | **DataRaptor** |
| Server-side orchestration / external callout sequence | **Integration Procedure** |
| Contextual data card on a record page | **FlexCard** |
| Batch rollups / mass data transform | **Data Processing Engine** |

**DataRaptor subtypes:**
- **Extract** — read data from Salesforce
- **Load** — write data to Salesforce
- **Transform** — reshape data between steps
- **Turbo Extract** — high-performance read for simple single-object reads

**Anti-pattern: reaching for OmniStudio when a plain screen Flow suffices.** OmniStudio adds licensing and maintenance overhead; use it when guided-flow complexity or Industries integration genuinely warrants it. Key signals to use OmniScript over Flow: multi-step with conditional branching across many objects, need for FlexCard integration, or the process must call an Integration Procedure.

**Grantmaking** (NP-Con-102 domain): manages grant opportunities, applications, awards, and disbursements through Industries-native objects. Key objects: `FundingOpportunity` (the grant offering a funder publishes), `IndividualApplication` (a grantee's application to a FundingOpportunity), `FundingAward` (the awarded grant), `FundingDisbursement` (each payment tranche). Additional supporting objects: `ApplicationDecision`, `ApplicationReview`, `FundingAwardRequirement`, `FundingAwardAmendment`. **There are no standard objects named `Grant` or `GrantApplication` in the Grantmaking data model** — using those names in SOQL or Apex will produce an "object not found" error. `[verified against Nonprofit Cloud for Grantmaking Developer Guide, 2026]` OmniStudio is commonly used to build grant application intake flows.

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
