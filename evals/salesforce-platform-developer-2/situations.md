# Eval situations — salesforce-platform-developer-2 (held-out set, 2026-06-07)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

Answer each: state the **competent action** and the **reason**. Be concise (2–4 sentences each).

1. A developer writes a Queueable job that processes a list of Lead records and, partway through `execute()`, needs to fire a callout to an external enrichment API. The class implements `Queueable`. In testing, the job is enqueued and runs without errors, but the callout never reaches the external endpoint. What is missing, and what is the minimum correct fix?

2. A scheduled Apex job fires nightly and calls `Database.executeBatch(new CleanupBatch(), 200)`. The batch processes ~800,000 Account records and runs `WITH SECURITY_ENFORCED` on every SOQL query inside `execute()`. In production, the job occasionally aborts with `QueryException: Non-selective query against large object type` on the second or third chunk, never the first. What is the likely root cause, and how do you diagnose it?

3. A new `Contract_Status__c` custom field is deployed to the Opportunity object via SFDX source push. The deploy log shows success. A developer then writes a test class that queries `Contract_Status__c` and runs `System.assertEquals('Active', opp.Contract_Status__c)` — but the assertion fails because the field always returns `null` even after the test data setup inserts an Opportunity with that value explicitly set. `seeAllData=false` is in effect. What is the most likely cause?

4. An Apex trigger on the `Task` object runs `after insert`. When a task of type `Call` is inserted, the handler queries the related `Contact` and updates a `Last_Call_Date__c` field on the Contact. In regression testing you discover this trigger also fires when a Flow creates Tasks in bulk as part of a larger automation — and now the Contact updates are causing `System.LimitException: Too many SOQL queries: 101` in that Flow path. Describe the root problem and the safest fix without removing the Flow.

5. A developer is designing an integration where an external ERP system sends up to 50,000 Order records per night to Salesforce. The integration team proposes using the standard REST API's `/services/data/vXX.0/sobjects/Order__c/` endpoint in a loop, one record per HTTP POST. A tech lead flags this as unworkable at that volume. What API and pattern should replace it, and why is the proposed approach untenable?

6. A `@future(callout=true)` method is called from an Apex trigger to POST order status changes to a third-party logistics provider. The team wants to add logic so that when the callout fails (HTTP 5xx response), the system retries up to three times before logging a permanent failure. A developer proposes adding a `for` loop inside the `@future` method that retries the callout until success or three attempts. Why is this proposal technically correct in isolation but architecturally wrong, and what pattern should replace it?

7. An LWC component uses `@wire(getRelatedRecords, { recordId: '$recordId' })` to populate a table with child records. The Apex method is annotated `@AuraEnabled(cacheable=true)`. Product managers request that clicking a "Refresh" button in the component force-fetches fresh data from the database (bypassing any cache) without navigating away. A developer proposes calling the same wired Apex method imperatively from the button's click handler. Will this work as written, and what is the correct approach?

8. In an NPSP org, you need to add logic that fires whenever a Contact is inserted: if the Contact's `Department` field equals `"Major Gifts"`, set a custom field `Priority_Donor__c` to `true`. A developer adds a standard Apex trigger `trigger ContactPriority on Contact (before insert)` directly to the Contact object. What is wrong with this approach in an NPSP org, and what is the correct mechanism?

9. A developer has a complex Apex test class with 15 test methods. To avoid hitting governor limits, they annotate the class with `@isTest(seeAllData=true)` so that every test method can read real org data instead of setting up its own records. Code review flags this as a bad practice. Beyond the obvious isolation argument, explain the specific technical risk that `seeAllData=true` introduces for automated CI deployments, and what the correct pattern is.

10. You are reviewing an Apex class that enforces record-level access by declaring the class `with sharing`. A code reviewer points out that the class contains a method that calls a helper class for logging, and that helper class is declared `without sharing`. The reviewer says this means the helper class "breaks" the sharing enforcement of the caller. Is the reviewer correct, and what keyword should the logging helper use to be safe in both sharing and non-sharing callers?

11. A developer deploys a new custom object `Shipment__c` with a lookup to `Account`. They then deploy a permission set that includes object-level Create/Read/Edit/Delete access to `Shipment__c` and `<fieldPermissions>` for every field on the object — including the `Name` (auto-number) field and the `OwnerId` field. The deploy fails. What is the specific reason, and how do you fix the permission set XML?

12. A developer writes a Custom Metadata Type-based feature flag system. The CMT `Feature_Flag__mdt` has a `Is_Enabled__c` checkbox field. In Apex, the developer queries it with `[SELECT Is_Enabled__c FROM Feature_Flag__mdt WHERE DeveloperName = 'Dark_Launch']`. A senior developer says this is functional but notes one subtle benefit the developer is not taking advantage of. What is that benefit, and how would you rewrite the access to leverage it?

---

## Held-out probes — Cycle-4 curation (2026-06-10)

> _Added from Cycle-4 inbox lessons. Do not paste into a skill body._

13. An org has a custom object `Inspection__c` with 4 million records. A developer writes a SOQL query filtering on a custom indexed field `Status__c`. In a test with production data, the query performs well when filtering for `Status__c = 'Pending'` (which matches 280,000 records) but throws `QueryException: Non-selective query` when filtering for `Status__c = 'Closed'` (which matches 700,000 records). The developer is confused because both values use the same custom indexed field with an equality predicate. Explain why one query is selective and the other is not, using the correct selectivity thresholds.

14. A developer has built a system that publishes standard-volume Platform Events (`Order_Update__e`, defined as standard-volume) for real-time order processing. The architect mentions that this design carries a specific sunset risk that could break the integration within the next 12 months. What is that risk, what is the recommended migration path, and what is the key behavioral difference between the two event types to account for in the subscriber?

15. A Visualforce page is being built to display a paginated list of `Invoice__c` records (up to 10,000 records total) with a "Next" and "Previous" button. A developer writes a custom Apex list controller that manually queries and slices records. A code reviewer flags this as unnecessary. What built-in Salesforce mechanism should replace the custom pagination logic, what is the correct way to declare it in the Apex controller class, and what VF component/attribute renders the navigation controls?

16. A Visualforce page needs to call a JavaScript function that manipulates a specific `<apex:outputPanel>` component identified by `id="statusPanel"`. The developer writes `document.getElementById('statusPanel')` in the JavaScript, but it never finds the element at runtime even though the panel is rendered. Why does this happen, and what is the correct expression to use in Visualforce to get the actual rendered DOM id?
