# Eval situations — salesforce-platform-developer-1 (held-out set, 2026-06-07)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

Answer each: state the **competent action** and the **reason**. Be concise (2–4 sentences each).

1. A developer writes an `after insert` trigger on `Opportunity` that queries the related Account and updates its `Last_Opp_Date__c` field. In testing with a single record it works. A colleague points out that the same trigger also fires when the nightly batch job processes 5,000 Opportunities. The developer insists it is safe because the trigger already does just one `SELECT` and one `update`. Why is this wrong, and what must change?

2. A developer needs a new `Approval_Stage__c` picklist field on `Case` that must be visible and editable only by members of the "Case Managers" permission set. They deploy the field via SFDX and add a `<fieldPermissions>` block for "Case Managers." A week later a release includes an org change making `Approval_Stage__c` required. The next deploy of an unrelated component immediately fails. What is the specific error and why did it appear now rather than at the original deploy?

3. An Apex helper class used by a trigger is declared with no sharing keyword. A junior developer opens a code review and suggests adding `with sharing` to enforce security. The tech lead rejects this, saying the class will "inherit" whatever sharing the caller uses. Is the tech lead correct? State the precise rule and the safer alternative.

4. A developer writes a Queueable class that performs an HTTP callout to an external API, then enqueues another instance of itself to process the next page of results. The pattern works correctly in the sandbox. A code reviewer flags that it will fail under a specific runtime condition. What is that condition and what is the enforced platform limit it violates?

5. A developer must write a test for an Apex method that calls an external REST endpoint. They write the test, annotate the test class with `@isTest`, but do not register any mock. The test throws an exception. They fix it by annotating the test class with `@isTest(SeeAllData=true)`, believing org data will supply the real endpoint URL. Does this fix the problem? What is the correct fix?

6. A developer deploys an LWC named `opportunityCard` with a method decorated `@api` and a property also decorated `@api`. From the parent component they try to call the child's `@api` method directly in the parent's `connectedCallback()` using `this.template.querySelector('c-opportunity-card').refresh()`. The method never fires. What timing rule governs this, and which lifecycle hook in the parent is the correct place to call it?

7. An Apex trigger on `Contact` calls `System.enqueueJob(new MyQueueable(contactIds))` in the `after insert` handler. In a unit test, the developer wraps the trigger invocation between `Test.startTest()` and `Test.stopTest()`, but when they assert on results that the Queueable should have produced, the values are unchanged. What is missing, and what does `Test.stopTest()` actually guarantee for Queueable execution in tests?

8. A developer has a batch class whose `start()` method returns a `Database.QueryLocator`. The business requests it process 3,000 records. The developer calls `Database.executeBatch(new MyBatch(), 2000)` to finish in two chunks. What is the enforced ceiling on the batch scope parameter and what happens if you exceed it?

9. An org has a custom object `Project__c` with two Lookup fields both pointing at `Account`: one named `Client_Account__c` with `relationshipName` set to `Client_Projects` and a second named `Billing_Account__c`. A developer attempts to deploy the second field without specifying a `relationshipName` in the XML. What happens at deploy time, and what is the correct fix?

10. A developer writes a Visualforce page backed by a custom controller. The page collects user input in a large `List<Wrapper>` property. In testing with many rows, saving throws a `ViewStateException`. The developer tries to resolve this by switching the property from `public` to `private`. Does visibility scope affect the View State? What is the actual fix?

11. An NPSP org has a trigger on `Opportunity` that a developer registered as a TDTM handler implementing `npsp.TDTM_Runnable`. In a unit test, the developer inserts an Opportunity and expects the NPSP household rollup to have already updated `npo02__TotalOppAmount__c` on the Household Account by the time the test asserts. The assertion fails — the rollup value is zero. What is the cause and what must the developer do?

12. A developer is working with dynamic SOQL and receives a requirement to let users filter Accounts by a free-text search on the `Name` field. They write: `String q = 'SELECT Id, Name FROM Account WHERE Name LIKE \'%' + userInput + '%\''` and execute it via `Database.query(q)`. A security reviewer flags this as a SOQL injection risk. The developer counters that the LIKE operator "sanitizes" input automatically. Is the developer correct? What is the proper fix and what specific method must be called?

13. A team upgrades a large Apex service class — `AccountEnrichmentService` — from API version 66 to API version 67 as part of a Summer '26 release preparation. The class has no `with sharing`, `without sharing`, or `inherited sharing` keyword. Before the upgrade, when called by a nightly admin batch job, the service could read all Account records regardless of ownership. After the upgrade, the batch job returns far fewer records and several integration tests that assert on a known total record count start failing. The platform threw no compile error. What changed, and what is the correct remediation?

14. A Salesforce architect is reviewing an org's record-save automation for a `Lead` object. A before-save record-triggered Flow sets `LeadSource` to `Web` when the field is blank. A developer-written `before insert` Apex trigger also sets `LeadSource` to `Partner` when a custom flag field `Referral__c` is true. When a Lead arrives via the web portal with `Referral__c = true`, the team expects `LeadSource` to be `Partner`. In production, `LeadSource` is always `Web`. What ordering rule explains this outcome, and what is the fix if the trigger's behavior must win?

15. An org has active Workflow Rules on the `Case` object that were built three years ago. The team discovers that Salesforce's end-of-support date for Workflow Rules has passed. A junior admin proposes deleting all Workflow Rules immediately, arguing they are "retired and no longer running." Is the admin's characterization accurate? What actually happens to active Workflow Rules after end-of-support, and what is the risk the admin's proposed action would introduce?

16. A developer is migrating a data integration script from Bulk API 1.0 to Bulk API 2.0. The old script processes 4 million Account records per run. The developer's manager asks whether the migration will hit any new volume ceiling or require record-count-based batching changes. What should the developer tell them about the maximum record volumes for each API version?
