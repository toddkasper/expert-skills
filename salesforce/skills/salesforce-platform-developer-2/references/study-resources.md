# Platform Developer II — Study Resources & Relevance

Load-on-demand companion to [../SKILL.md](../SKILL.md). Use when planning a study path for the Platform Developer II exam or mapping the operational rules to a nonprofit (NPSP) org.

## Study Resources

### Official Salesforce

- [Prepare for Your Salesforce Platform Developer II Credential — Official Trailmix](https://trailhead.salesforce.com/users/strailhead/trailmixes/prepare-for-your-salesforce-platform-developer-ii-credential) — Official / Trailhead (covers async Apex, REST/SOAP integration, LDV, LWC)
- [Superbadge: Apex Specialist](https://trailhead.salesforce.com/en/content/learn/superbadges/superbadge_apex) — Official / Required superbadge (triggers, async, scheduling)
- [Superbadge: Advanced Apex Specialist](https://trailhead.salesforce.com/en/content/learn/superbadges/superbadge_aap) — Official / Required superbadge (design patterns, integration, testing)
- [Superbadge: Data Integration Specialist](https://trailhead.salesforce.com/en/content/learn/superbadges/superbadge_integration) — Official / Required superbadge (REST, SOAP, Bulk API, external services)
- [Superbadge: Lightning Component Framework Specialist](https://trailhead.salesforce.com/en/content/learn/superbadges/superbadge_lcf_specialist) — Official / Required superbadge (Aura/LWC)
- [Apex Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_dev_guide.htm) — Official reference documentation
- [Platform Developer II Exam Guide (PDF)](https://developer.salesforce.com/resources2/certification-site/files/SGCertifiedPlatformDeveloperII.pdf) — Official exam guide with topic/weight breakdown
- [Trailhead Academy — Exam Registration (Plat-Dev-301)](https://trailheadacademy.salesforce.com/certificate/exam-platform-dev2---Plat-Dev-301) — Official registration portal (replaced Webassessor July 2025)

### Community Study Guides

- [Salesforce Ben — PD2 Certification Guide & Tips](https://www.salesforceben.com/salesforce-platform-developer-2-certification-guide-tips/) — Comprehensive topic breakdown, exam strategy, superbadge tips
- [Focus on Force — Platform Developer 2 Study Guide](https://focusonforce.com/courses/platform-developer-2-study-guide/) — Paid but highly regarded; topic-by-topic notes + practice questions
- [sfdc99 (David Liu)](https://www.sfdc99.com/) — Foundational Apex learning; best for conceptual understanding of patterns
- [Apex Hours](https://www.apexhours.com/apex-design-patterns/) — Community blog/YouTube covering design patterns, LWC, integrations
- [Apex Design Patterns — SFDC Brewery (Medium)](https://medium.com/@sfdcbrewery/apex-design-patterns-sfdc-brewery-salesforce-developer-interview-preparation-series-2c5296a9ed0f) — Deep dives on Singleton, Strategy, Decorator, Facade, Composite, Bulk State Transition

## Relevance to NPSP and Nonprofit Cloud

The PD2 skill set maps directly onto the hardest parts of building on NPSP.

### NPSP TDTM, not raw triggers
NPSP governs Contact/Account/Opportunity automation through **Table-Driven Trigger Management**. To add behavior to an NPSP object, extend `npsp.TDTM_Runnable`, override `run()`, and register the handler with a **Load Order** in `Trigger_Handler__c` so it sequences correctly relative to NPSP's own handlers. Dropping a raw trigger on Contact fights NPSP automation — and NPSP's hidden managed-package automation (e.g., the `npe01` workflow that copies `Phone → MobilePhone` when `PreferredPhone__c = "Mobile"`) will silently mutate your data if you don't account for execution order first.

### Apex Managed Sharing
NPSP has its own sharing model for Households, Organizations, and Opportunities. Custom code reaching records outside a user's role hierarchy needs the PD2 `Share`-object / row-cause / `without sharing` toolkit — applied carefully, since FLS must still be enforced in code.

### Inbound REST + External Id upsert
A common NPSP integration pattern POSTs to NPSP via REST and upserts on a custom External Id field for idempotency — the exact PD2 inbound-integration pattern, and a clean hook for later related-record re-linking without new write logic.

### Platform Events for status flow-back
"Record status changes flow back to an external portal" is a textbook Platform Events use case (`EventBus.publish` → subscriber, `ReplayId` durability) — decoupled, fire-and-forget, no polling.

### Custom Metadata Types for config
NPSP keeps config in CMTs (`Trigger_Handler__mdt`, relationship auto-create config). PD2's CMT skills (free SOQL, deployable, packageable) are essential for reading/extending NPSP config safely without mutating settings that drive core behavior.

### Large Data Volume
As custom objects and Contact grow, PD2's LDV toolkit — selective queries, skinny tables, owner-skew avoidance, Big Objects for archival — keeps approval/processing logic performant past 10k/100k records.

### Testing with mocks
Any future status-webhook callouts must be mocked (`HttpCalloutMock`/`StubProvider`) to test without hitting real endpoints.

### Source-driven deployment
SFDX (`force-app/main/default/`) with `sf project deploy start` is the exact source-driven workflow PD2 tests, and the home of every deployment gotcha above.
