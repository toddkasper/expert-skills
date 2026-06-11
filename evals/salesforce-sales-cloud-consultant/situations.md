# Eval situations — salesforce-sales-cloud-consultant (held-out set, 2026-06-07)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

Answer each: state the **competent action** and the **reason**. Be concise (2–4 sentences each).

1. A client's integration user runs a nightly SOQL query against the Opportunity object filtered on a custom text field `Integration_Key__c` that was recently deployed via SFDX. The query is returning zero rows even though Data Loader confirms 50,000 matching records exist in the org. No error is thrown — just an empty result set. What is the most likely cause, and how do you confirm and fix it?

2. A developer deploys two new custom Lookup fields to the Contact object via SFDX, both pointing at the Account object. One is named `Primary_Account__c` with `relationshipName` set to `PrimaryAccounts` and the other is `Secondary_Account__c` with `relationshipName` also set to `PrimaryAccounts`. The deploy completes on the first field but fails partway through. What is the error and how do you fix it?

3. Your org is running a re-runnable nightly data migration that loads Opportunity records from an external CRM. After the first run, the migration is re-run due to a data correction. Sales reps report seeing duplicate Opportunities for the same deals. What went wrong and what is the correct idempotency mechanism to use?

4. A sales ops manager wants to give five reps read-only access to a competitor pricing analysis stored in Salesforce Files (ContentDocument). Currently, the document's library is set to Viewer access for "All Internal Users." Several reps still cannot open the file. The reps have the standard Sales User profile. What access layer is likely missing, and what is the correct fix without granting broader permissions than needed?

5. An org has Collaborative Forecasting enabled with Opportunity Amount rolling up. A regional VP complains that her manager-adjusted forecast numbers are not reflected when her manager's manager pulls the forecast. The subordinate VP's adjustments appear correct when she views her own forecast. What is the likely cause, and what should you check?

6. A consultant is designing the data model for a B2B client. Each Deal (Opportunity) must permanently record which Price Book it used at time of close, even if the Price Book is later deleted or renamed for rebranding. The consultant proposes a Master-Detail from a custom `Deal_Price_Book_Snapshot__c` object to Opportunity. Is this the right relationship type, and why or why not?

7. An integration writes incoming sales order data to a custom `Sales_Order__c` object using a restricted picklist field `Order_Status__c`. The integration sends a value that is valid in the source system but not in the Salesforce allowed-value list. The write fails with a generic field-level error. A developer proposes adding FLS edit permissions to the integration user's permission set. Will that fix it? What is the actual problem and the correct fix?

8. A new Quick Action "Log Call with Outcome" is deployed to the Opportunity record page via SFDX. The action includes three custom fields in its `quickActionLayoutItems`. The deploy succeeds, but when reps open the Quick Action in Lightning Experience, only the original fields appear — the three new fields are absent, with no error. What is happening and what must you do to make the new fields appear?

9. Leadership wants a dashboard showing pipeline-over-time — specifically, how total open Opportunity amount changed week-over-week for the past six months. A report of current Opportunities already exists. What native Salesforce mechanism lets you trend this data historically, and what is the limiting factor you must plan around?

10. A client wants to use Einstein Opportunity Scoring to prioritize which deals to focus on in a 15-person sales team that was established eight months ago. The team has closed 22 deals in that period. Should you recommend activating Einstein Opportunity Scoring now? What is the blocking data prerequisite?

11. A mid-market company has Accounts with OWD set to Private. A new sharing requirement emerges: a "Partner Success" team needs read access to all Accounts in the "Technology" industry, regardless of which rep owns them. The current role hierarchy does not give Partner Success any visibility into these records. What is the most appropriate declarative mechanism to grant this access, and what is a common mistake to avoid when configuring it?

12. A client's org policy blocks creation of Connected Apps via metadata deployment (the deploy returns "You can't create a connected app…"). The team needs to authorize an external web app to access the org's API. The consultant recommends creating an External Client App (ECA) instead. Once the ECA is created in the UI, how must API access permissions be authorized — and what is the wrong approach that developers commonly attempt first?

13. A Sales Cloud implementation manager is preparing a study plan for the Sales-Con-201 exam and asks which domain to prioritize because "the blueprint hasn't changed since the June 2024 restructure." She references a guide showing five domains: Practical Application 33%, Sales Lifecycle 23%, Implementation Strategies 15%, Data Management 15%, Consulting Practices 14%. She is unfamiliar with any AI-specific content on the exam. What should the consultant tell her about the current blueprint structure, and what topic area does she need to add to her study plan?

14. During an implementation kickoff, a sales ops director asks the consultant to configure "Einstein Copilot" so that reps can use it to draft follow-up emails and prepare for meetings using CRM data. She says she saw it demonstrated at Dreamforce. The consultant is about to open Setup and search for "Einstein Copilot." What name should the consultant actually look for in Setup, why has the name changed, and what is the one prerequisite category (besides data quality) that must be addressed before deploying this feature?
