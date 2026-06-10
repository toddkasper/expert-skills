# Technical Architect — Study Resources & Relevance

Load-on-demand companion to [../SKILL.md](../SKILL.md). Use when planning a study path for the CTA review board or mapping the operational rules to a nonprofit (NPSP / Nonprofit Cloud) org.

## Credential logistics

*Logistics are volatile — verify against the official exam guide before relying on any number.*

The CTA credential is a **two-part sequential process**. You must pass Part 1 (Architect Review Board Evaluation) before being invited to Part 2 (Technical Architect Review Board Exam). Both parts are scenario-based oral defenses with no multiple-choice component.

| Field | Value |
|---|---|
| Questions | No fixed question count — scenario-driven oral assessment in both parts |
| Time Limit | Part 1: ~165 min (60 read + 30 present + 30 Q&A + ~45 feedback). Part 2: ~265 min (180 solution design + 45 present + 40 Q&A) |
| Passing Score | Pass/fail. Part 2 scores 7 domains; failing >1 domain = overall failure, failing exactly 1 = Section Retake allowed |
| Cost | $6,000 total: $1,500 Part 1 + $4,500 Part 2 (plus applicable taxes) |
| Prerequisites | Salesforce Certified Application Architect **and** Salesforce Certified System Architect (both required) before Part 1; passing Part 1 gates Part 2 |
| Retake Policy | Part 1 retake $750; Part 2 retake $2,250 (full or single-domain Section Retake). Wait 6 months after a failed attempt; written feedback within ~2 weeks. Annual maintenance required to stay current |

Additional logistics: Part 1 is virtual (Zoom screen-share). Part 2 is virtual or in-person before a panel of 3–4 sitting CTAs. The scenario document is provided ~30 minutes before the board session begins. Allowed materials are G Suite tools (Docs, Slides, Sheets) or paper; offline materials require photo documentation.

## Study Resources

### Official Salesforce Resources

- [Architect Journey: Prepare to Become a CTA Trailmix](https://trailhead.salesforce.com/users/strailhead/trailmixes/architect-trailmix-master) — Trailhead / official; master trailmix covering all architect domain areas
- [Certified Technical Architect Credential Page](https://trailhead.salesforce.com/credentials/architectreviewboard) — Trailhead / official; credential overview, prerequisites, exam guide links
- [CTA601 Architect Preparation Workshop](https://trailheadacademy.salesforce.com/classes/cta601-prepare-for-your-technical-architect-credential) — Trailhead Academy / official; expert-led virtual workshop with mock scenario; closest thing to the real board
- [Official CTA Exam Guide PDF](https://developer.salesforce.com/resources2/certification-site/files/SGCertifiedTechnicalArchitect.pdf) — developer.salesforce.com / official; domain-by-domain skill bullets
- [Architect Trailblazer Community Group](https://trailhead.salesforce.com/trailblazer-community/topics/reviewboard) — Trailhead / official; mock scenario partners and CTA mentors
- [Salesforce Well-Architected Framework](https://architect.salesforce.com/well-architected/overview) — architect.salesforce.com / official; the trusted/easy/adaptable framework underpinning board scoring
- [Apex Developer Guide — Governor Limits](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_gov_limits.htm) — official; authoritative per-transaction limit reference behind the tables above

### Community Resources

- [Salesforce Ben: CTA Certification Guide & Tips](https://www.salesforceben.com/certified-technical-architect-certification-guide-tips/) — community; overview of the board process and preparation timeline
- [Salesforce Ben: Becoming a CTA — Thoughts from 9 CTAs](https://www.salesforceben.com/become-a-salesforce-certified-technical-architect/) — community; candid prep-time (150–1000+ hrs) and cost context
- [CTA Gang of Four (ctagof.com)](https://ctagof.com) — community / video; recorded mock CTA presentations with real feedback
- [FlowRepublic CTA Coaching](https://flowrepublic.com/) — paid coaching; mock scenarios with sitting-CTA feedback
- [Apex Hours CTA YouTube Playlist](https://www.youtube.com/c/ApexHours) — YouTube / free; scenario walkthroughs and domain deep-dives
- [Tameem Bahri: "Becoming a Salesforce Certified Technical Architect" (book)](https://www.amazon.com/Becoming-Salesforce-Certified-Technical-Architect/dp/1800568754) — Packt / book; all 7 domains with practice scenarios
- [Architect Ohana Slack Community](https://salesforce-architect.slack.com) — Slack / community; mock partners and feedback
- [The Salesforce CTA Exam Guide](https://the-salesforce-cta-exam-guide.com/) — community study guide; domain-by-domain coverage

## Relevance to NPSP & Nonprofit Cloud

The seven CTA domains map directly to common NPSP / Nonprofit Cloud decisions:

**Data — NPSP data model complexity.** The Household Account model (one Account per household, Contacts as members) vs. the Individual Account model is a canonical CTA decision with downstream effects on reporting, dedup, Relationships, and portal access. Approval automation that upserts a `Contact` (matched on email + birthdate) and creates NPSP `Relationship` records for spouse/buddy/emergency contacts exercises exactly the LDV, dedup, and parent-child-load-order concerns the Data domain tests.

**Security — Experience Cloud, FLS, and least-privilege.** The hardest-won scar (FLS separate from object access) lives here, as does the JWT Bearer integration-user design and the ECA permission-assignment trap. A tokenized magic-link upload (high-entropy, write-only, single-record bearer) is a deliberate alternative to community-user licensing — a board-grade "right-sized auth for the audience" decision.

**Integration — Salesforce as system of record.** A submit pipeline (form → object storage → sweep job → JWT upsert → email) embodies fire-and-forget async + idempotent external-ID upsert + resilient failure handling. Donor/payment/email integrations extend the same pattern catalog (Bulk API for imports, CDC/Platform Events for change-driven sync).

**Solution Architecture — managed-package constraints.** NPSP's `npe01` automation (e.g. a workflow rule that overwrites a phone field) is the textbook "design around the managed package" case the domain probes. The declarative-vs-Apex discipline shows up in picklist-edit approvals vs. a native approval flow.

**Development Lifecycle — SFDX + sandbox strategy for NPSP.** NPSP must be installed before metadata deploy; deploy from the SFDX root; FLS/required-field/relationshipName gotchas are caught by the smoke test; production is never touched outside a planned cutover with backfill-first sequencing.

**System Architecture — nonprofit licensing.** Salesforce's Power of Us program (10 free licenses + discounts) shapes the license mix; anonymous-submit + tokenized-upload designs deliberately avoid per-user community licensing for low-tech or senior applicant audiences.

**Communication — presenting to a volunteer board.** Architecture trade-offs must be expressed to a non-technical executive director and volunteer board in cost/risk/time-saved terms — the same audience-adjustment the Communication domain scores.
