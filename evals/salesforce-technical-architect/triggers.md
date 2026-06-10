# Trigger tests — salesforce-technical-architect (Lens 2)

Routing regression set. Test each phrasing against skill DESCRIPTIONS only. Each routes to exactly one skill.

## Should route to salesforce-technical-architect  (5)

1. "Design the end-to-end integration architecture for a bi-directional sync between our Salesforce org and an external ERP, covering auth, error handling, idempotency, and governor-limit risk"
2. "Our org has a multi-cloud setup (Sales + Service + Experience) — review the proposed OWD + sharing model and flag any access gaps or over-exposure"
3. "Evaluate whether Platform Events or an outbound REST callout is the right pattern for this near-real-time notification requirement, and justify the trade-offs"
4. "We need a JWT Bearer flow between a headless Node.js service and Salesforce — walk me through the auth setup, certificate rotation, and what breaks at sandbox refresh"
5. "Assess our proposed Large Data Volume strategy for 50 million Contact records — skinny tables, custom indexes, selective SOQL, and archiving options"

## Near-misses → a sibling  (3)

1. "Configure the OWD and create sharing rules for the Opportunity object in our Sales Cloud org" → `salesforce-sales-cloud-consultant` (single-cloud declarative config scoped to Sales Cloud, not cross-cloud architecture design)
2. "Write the Apex trigger handler and bulkification logic for the Contact object following the one-trigger-per-object pattern" → `salesforce-platform-developer-1` (hands-on Apex code, not architecture review or design)
3. "Set up permission sets and profiles for our new Service Cloud implementation, including FLS and OWD for Case" → `salesforce-administrator` (declarative org configuration, not cross-org integration or solution architecture)
