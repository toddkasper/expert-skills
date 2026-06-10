# Trigger tests — salesforce-platform-developer-2 (Lens 2)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

Routing regression set. Test each phrasing against skill DESCRIPTIONS only (that is all the router sees). Each phrasing must route to exactly one skill.

## Should route to salesforce-platform-developer-2  (5)
1. "My Batch Apex is hitting non-selective query errors on 2.5 million Account records on the third chunk but never the first — how do I diagnose and fix the SOQL selectivity issue?"
2. "Design an async retry pattern for a @future callout that should retry up to 3 times on HTTP 5xx before logging a permanent failure — @future loops won't work, what's the right architecture?"
3. "We need to ingest 80,000 Order records nightly from an ERP system into Salesforce — the REST SObject API one-record-at-a-time is too slow, what API and pattern should we use?"
4. "I'm building a Platform Events consumer in Apex — how do I handle high-volume events reliably and what's the resume-after-failure replay pattern?"
5. "A Queueable chains into itself for pagination but the chain breaks silently after a certain depth in production — what limit governs Queueable chaining and how do I work around it?"

## Near-misses → a sibling  (3)
1. "Write an Apex trigger on Contact that bulkifies a SOQL query and a DML update using a Map pattern" → `salesforce-platform-developer-1`  (fundamental trigger bulkification is PD1 scope, not advanced PD2 patterns)
2. "Set up an SFDX deployment pipeline that runs unit tests and enforces 75% coverage before promoting to production" → `salesforce-advanced-administrator`  (SFDX CI pipeline and deployment coverage is advanced-admin scope)
3. "Build an LWC component that imperatively calls an Apex method and refreshes the wire cache after a save operation" → `salesforce-javascript-developer-1`  (LWC front-end imperative calls and wire cache management is JS Developer I scope)
