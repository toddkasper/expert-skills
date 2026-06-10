# CTA Decision Scenarios — Extended Set

> Overflow scenarios from SKILL.md. Load when working through trigger bulkification failures on backfills, ECA assignment failures, or multi-cloud Data Cloud architectural decisions.

---

**Scenario 3 — Trigger bulkification failure on backfill**

**Situation:** An `OpportunityLineItem` after-insert trigger runs a SOQL query and a DML update inside a `for (OpportunityLineItem item : Trigger.new)` loop to sync a pricing field to the parent Opportunity. In unit tests (1–2 records) everything passes. A data backfill loads 5,000 records at once and the org hits `"System.LimitException: Too many SOQL queries: 101"` and rolls back.

**Competent move:** Rewrite the trigger to be bulk-safe: collect all parent Opportunity IDs from `Trigger.new` into a `Set<Id>`, query all parents in a single SOQL into a `Map<Id, Opportunity>`, compute updates in memory, then perform a single DML on the collected list. Move logic into a handler class. Add a static boolean recursion guard if the trigger could fire on the Opportunity update it makes.

**Tempting-but-wrong:** Increasing the batch size to "something smaller" or switching to a future method. A future method moves the problem to async but does not fix the per-iteration SOQL — and a future called inside a trigger iterating 5,000 records will hit the future call limit (50 per transaction). The root fix is bulkification, not async deferral.

**Verify:** After refactoring, write a test that inserts 200 `OpportunityLineItem` records in a single `insert` call and assert that `Limits.getQueries()` remains well below 100 after the trigger fires. Run the test with `Test.startTest()`/`Test.stopTest()` to isolate the trigger's limit consumption.

---

**Scenario 4 — ECA assignment confirmed by UI, integration fails**

**Situation:** A developer configures a JWT Bearer integration using an External Client App. They grant access by going to the Permission Set detail page, clicking "Assigned Connected Apps," selecting the ECA, and clicking Save. The UI confirms the assignment. The integration service calls the token endpoint and receives `"invalid_client_id"`.

**Competent move:** The classic ECA trap. The "Assigned Connected Apps" section on a Permission Set page does NOT govern External Client Apps — it is for legacy Connected Apps only. For an ECA, the assignment path is: **ECA detail page → Policies tab → Edit → App Policies → Select Permission Sets → add the permset → Save**. Go directly there and make the assignment; do not rely on the permset page.

**Tempting-but-wrong:** Re-generating the Consumer Key or re-uploading the certificate. The credential itself is fine — the error is an authorization gap, not a credential mismatch. Also wrong: trusting the UI confirmation on the permset page; the UI accepted the action but it had no effect for an ECA.

**Verify:** After correcting the assignment on the ECA Policies tab, run the JWT token flow end-to-end: sign the assertion, POST to the token endpoint, confirm a `200` with an `access_token`. Then SOQL-query `SetupEntityAccess` where `SetupEntityType = 'ExternalClientApplication'` to confirm the record exists, rather than reading any UI page.

---

**Scenario 5 — Multi-cloud architecture: Data Cloud vs. custom ETL**

**Situation:** A retail enterprise has customer purchase data in Commerce Cloud, engagement data in Marketing Cloud, and service cases in Sales/Service Cloud. A VP asks for a "360-degree customer view" with AI-driven next-best-action surfaced to service reps. The architect proposes building a nightly ETL to copy all three data sources into a custom `UnifiedCustomer__c` object in the CRM and run a batch Apex job to score customers.

**Competent move:** This is a canonical Data Cloud use case, not a custom ETL problem. Data Cloud's Data Streams ingest from all three clouds natively; Identity Resolution creates a Unified Individual profile by matching on email/phone/cookie; Calculated Insights derive the scoring metric; and Agentforce Agents or Einstein Next Best Action consume the Unified Profile via grounding — zero custom ETL, no stale batch copies, no custom object to maintain. Propose Data Cloud as the architectural layer and explain why: out-of-box connectors, Identity Resolution replaces hand-rolled dedup logic, and it is the platform's intended 360-profile answer.

**Tempting-but-wrong:** The custom ETL + batch Apex design is not wrong in isolation, but it ignores the platform capability that exists for this exact requirement. In a board session, proposing custom-built solutions where a Salesforce product directly covers the need — without even mentioning that product — is scored as an architectural gap.

**Verify:** Confirm Data Cloud licensing is included or procured before committing to this architecture — it is a separate SKU. Validate that the specific Commerce Cloud and Marketing Cloud connectors (Data Streams) cover the data sources in the scenario. Then prototype a Data Stream and Identity Resolution ruleset in a sandbox before presenting the design as final.
