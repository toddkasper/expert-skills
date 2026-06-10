# Trigger tests — salesforce-advanced-administrator (Lens 2)

Routing regression set. Test each phrasing against skill DESCRIPTIONS only (that is all the router sees). Each phrasing must route to exactly one skill.

## Should route to salesforce-advanced-administrator  (5)
1. "I need to configure a session-based permission set so finance users only get the export permission after they complete an MFA step — how do I wire that up?"
2. "My SFDX deploy pipeline is failing because the org-wide code coverage dropped below 75% after we deleted a legacy test class — what are my options?"
3. "I need to track field history on 22 fields on a custom object but Field History Tracking silently caps it — what's the limit and what do I do with the overflow fields?"
4. "Setup Audit Trail shows nothing for who changed our password policy last week — am I looking in the wrong place?"
5. "Deploying a custom report type that traverses two Lookup fields to Contact fails with a duplicate relationship name error even though the field API names are different — what's the actual conflict?"

## Near-misses → a sibling  (3)
1. "Help me set OWD on Opportunity to Private and create a sharing rule so the sales team can see each other's records" → `salesforce-administrator`  (basic OWD + sharing rule setup is day-to-day admin, not advanced sharing architecture)
2. "Write a before-insert Apex trigger on Account that enforces FLS before updating fields" → `salesforce-platform-developer-1`  (asks for Apex trigger code, outside declarative scope)
3. "My SOQL query in a Batch Apex execute() method is causing non-selective query errors on 2 million Account records — how do I tune it?" → `salesforce-platform-developer-2`  (SOQL selectivity and Large Data Volume tuning is PD2 territory, not declarative admin)
