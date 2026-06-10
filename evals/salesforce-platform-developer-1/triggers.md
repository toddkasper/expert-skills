# Trigger tests — salesforce-platform-developer-1 (Lens 2)

Routing regression set. Test each phrasing against skill DESCRIPTIONS only (that is all the router sees). Each phrasing must route to exactly one skill.

## Should route to salesforce-platform-developer-1  (5)
1. "Review this Apex trigger on Opportunity — it does a SOQL query inside a for loop and I know that's bad, but I'm not sure how to bulkify it"
2. "My test class is at 74% coverage and the deploy to production is failing — which lines are uncovered and how do I write tests for trigger handler methods?"
3. "I deployed a field via SFDX with a fieldPermissions block for our Sales Rep permission set but the field still shows as hidden — what's wrong with the XML?"
4. "Write a Queueable Apex class that calls an external REST endpoint and re-enqueues itself for the next page of results"
5. "An LWC child component has an @api method — the parent calls it in connectedCallback and it never fires. What lifecycle hook should I use instead?"

## Near-misses → a sibling  (4)
1. "Set up a Flow to create a follow-up Task whenever an Opportunity stage changes to Closed Won" → `salesforce-administrator`  (declarative Flow automation, no Apex code)
2. "My Batch Apex is hitting non-selective query errors on 3 million Account records — how do I tune the SOQL for Large Data Volume?" → `salesforce-platform-developer-2`  (LDV SOQL selectivity tuning is PD2 scope)
3. "Design the sharing model so that the West Sales team can see each other's Opportunity records under a Private OWD" → `salesforce-administrator`  (OWD + sharing rules is declarative admin config)
4. "Write a custom LWC that uses a wire adapter to fetch data and renders a dynamic table — I need the shadow DOM event bubbling explained too" → `salesforce-javascript-developer-1`  (LWC front-end UI, wire adapter, shadow DOM — JS Developer I scope)
