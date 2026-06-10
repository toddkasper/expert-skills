# Trigger tests — salesforce-javascript-developer-1 (Lens 2)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

Routing regression set. Test each phrasing against skill DESCRIPTIONS only. Each routes to exactly one skill.

## Should route to salesforce-javascript-developer-1  (5)

1. "Review this LWC and flag any reactivity bugs where tracked property mutations won't re-render the template"
2. "My @wire adapter is firing once but not re-firing when a reactive property changes — what is wrong with my LWC?"
3. "Audit this Jest/LWC-Jest test: the test passes but the feature is broken because no flush-promises is awaited"
4. "I passed a class method as a callback to an event handler and now `this` is undefined inside it — how do I fix it?"
5. "We have an XSS risk in our LWC because a developer used `innerHTML` to render user-supplied text — walk me through the remediation"

## Near-misses → a sibling  (3)

1. "Write Apex trigger logic to bulkify a contact update on after-insert and avoid hitting the 100-SOQL limit" → `salesforce-platform-developer-1` (Apex/server-side trigger code, not JavaScript or LWC)
2. "Fix my React useEffect that is causing an infinite re-render loop in our customer portal" → `react` (generic React, not a Salesforce LWC component; description explicitly excludes generic React)
3. "Build a Queueable Apex chain that fans out async callouts after a Platform Event fires" → `salesforce-platform-developer-2` (advanced async Apex, not JavaScript/LWC)
