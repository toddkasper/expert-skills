# Platform Developer I — Study Resources & Relevance

Load-on-demand companion to [../SKILL.md](../SKILL.md). Use when planning a study path for the Platform Developer I exam or mapping the operational rules to a nonprofit (NPSP) org.

## Study Resources

### Official Salesforce Resources

- [Prepare for Your Salesforce Platform Developer I Credential (Trailmix)](https://trailhead.salesforce.com/users/strailhead/trailmixes/prepare-for-your-salesforce-platform-developer-i-credential) — Official Salesforce-curated trailmix (~43 hours); start here
- [Platform Developer I Certification Study Guide Trail](https://trailhead.salesforce.com/content/learn/trails/platform-developer-i-certification-study-guide) — Four interactive modules with flashcards and scenarios aligned to the four exam domains
- [Salesforce Certified Platform Developer I Credential Page](https://trailhead.salesforce.com/credentials/platformdeveloperi) — Official credential overview with links to the exam guide PDF
- [Apex Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/) — The authoritative Apex reference; essential for governor limits, async patterns, and DML/SOQL details
- [Lightning Web Components Developer Guide](https://developer.salesforce.com/docs/component-library/documentation/en/lwc) — Official LWC reference for decorators, lifecycle, events, and wire service

### Community Study Guides & Practice Exams

- [Focus on Force PD1 Study Guide](https://focusonforce.com/courses/platform-developer-1-study-guide/) (now at k2university.com) — The most widely recommended paid community study guide; organized by official exam sections with practice questions (~$49)
- [Salesforce Ben: Platform Developer Certification Guide](https://www.salesforceben.com/platform-developer-certification-guide-tips/) — Free overview with section-by-section tips and resource pointers
- [Nick Frates: PD1 Comprehensive Study Guide (2025)](https://www.nickfrates.com/blog/salesforce-platform-developer-i-2025-comprehensive-study-guide) — Free detailed breakdown of all four domains with flashcard-style governor limit facts
- [TrailblazePrep PD1 Prep (Winter '26)](https://www.trailblazeprep.com/certifications/developer-1) — Free practice questions with detailed explanations; up to date with current exam weightings
- [S2 Labs: Platform Developer 1 Practice Exam](https://s2-labs.com/blog/salesforce-platform-developer-1-practice-exam/) — Free practice exam questions with explanations

### Video & Interactive Learning

- [David K. Liu YouTube Channel (SFDC99 / Apex Academy)](https://www.youtube.com/@dvdkliu) — Salesforce MVP (Hall of Fame); beginner-to-advanced Apex video tutorials; the go-to starting point for developers coming from a non-Salesforce background
- [SFDC99 Apex Academy](https://www.sfdc99.com/apex-academy/) — Written + video curriculum that parallels PD1 topics; free foundational content with paid advanced tiers
- [Apex Hours YouTube (Community)](https://www.youtube.com/@ApexHours) — Community-run channel with live coding sessions, PD1/PD2 prep walkthroughs, and NPSP-specific Apex content

## Relevance to NPSP & Nonprofit Cloud

Virtually every PD1 topic has direct application when developing on or alongside Salesforce NPSP (Nonprofit Success Pack). Key intersections:

### Governor Limits & Bulkification

NPSP's own triggers (Contacts, Opportunities, Accounts, Relationships, Households) consume a significant portion of each transaction's SOQL and DML budget *before* custom code runs. Any Apex that issues SOQL inside loops will hit the 100-query limit in bulk — the exact failure tested in PD1. Integration writes and upserts must produce bulkified records.

### NPSP's TDTM Framework

NPSP uses Table-Driven Trigger Management — one master trigger per object delegating to handler classes registered in `TDTM_Config__mdt`. PD1's "one trigger per object, handler class pattern" *is* TDTM. Custom handlers implement `npsp.TDTM_Runnable` without modifying managed code; trigger context, before/after semantics, and recursion control all apply.

### Apex Interfaces & Inheritance

Implementing `npsp.TDTM_Runnable` is a direct application of PD1's interfaces/inheritance content — `implements`, signature matching, and access modifiers all come into play wiring a class into TDTM.

### Order of Execution

NPSP fires TDTM handlers in the after-trigger phase; custom handlers, validation rules, and any legacy managed-package workflow all compete in the same transaction. PD1's 14-step order is essential for predicting why a Contact upsert mutates or fails.

### Asynchronous Apex

NPSP-heavy transactions (Opportunity close, household merges) can exhaust synchronous limits. PD1's async patterns are the offload tools. Where integration writes happen via REST from an external runtime, in-org post-processing (SF Files / ContentDocumentLink) should use Queueable/Batch.

### Testing

NPSP managed code doesn't run by default in tests (`SeeAllData=false`); rollups/household/relationship automation fire only if NPSP features are explicitly enabled in the test. PD1's test isolation and data-management content is the foundation for valid NPSP test classes.

### Deployment

Deploy via `sf project deploy start` (DX source format). PD1 covers SFDX, `package.xml`, sandbox types, and the 75% coverage gate. NPSP managed metadata can't be retrieved/modified via SFDX, but custom fields, permsets, flows, and Apex on top of it are fully SFDX-managed.

### Integration / LWC

`@AuraEnabled` + `@wire` are how a Lightning staff UI surfaces custom data in-org. Declarative Quick Actions cover simple per-record displays; a richer approval UI would be LWC with wired Apex.
