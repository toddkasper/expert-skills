# Trigger tests — salesforce-experience-cloud-consultant (Lens 2)

Routing regression set. Test each phrasing against skill DESCRIPTIONS only. Each routes to exactly one skill.

## Should route to salesforce-experience-cloud-consultant (5)

1. "We are launching a customer portal where external users log in to view their own cases and submit new ones. Help us pick the right license and configure the sharing model."
2. "External users in our partner portal can see each other's Opportunities even though OWD is Private. Walk me through where the over-sharing is coming from."
3. "Set up SAML SSO for our Experience Cloud site so partners are logged in automatically from their company's IdP without landing on our login page."
4. "We need self-registration on our LWR site: visitors fill out a form, a Contact and Community User are created automatically. What Flow pattern and profile assignment do we need?"
5. "Our guest-user profile has Read access on the Account object and now a security reviewer says any unauthenticated visitor can query any Account via the API. How do we lock this down?"

## Near-misses → a sibling (3)

1. "Configure role hierarchy and criteria-based sharing rules so the internal regional sales team can see all Accounts in their territory without being the record owner." → `salesforce-advanced-administrator`  (internal org sharing architecture — OWD, role hierarchy, sharing rules — with no external portal or Experience Cloud site in scope)
2. "Design the Service Console layout and case assignment rules so our internal support team handles cases faster." → `salesforce-service-cloud-consultant`  (internal console and case routing is Service Cloud scope; no external community or portal involved)
3. "Build a public job-application form using a Screen Flow and embed it on a Salesforce site so applicants can submit without logging in." → `salesforce-experience-cloud-consultant`  (this IS experience-cloud — unauthenticated LWR site with guest-user hardening is Experience Cloud scope; included to confirm it routes here, not to administrator)
