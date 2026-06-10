# Application tasks — salesforce-platform-developer-1 (Lens 4, held-out)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

A skilled agent produces the artifact; a judge grades it against the trap-keyed rubric. Run baseline vs skilled. Do not reveal this rubric to the solving agent.

## Task 1 — Apex trigger redline: bulkification, FLS, and sharing bugs

**Prompt to the agent:** Review the Apex trigger and handler class below. Produce a redline of every governor-limit, FLS/sharing, and correctness bug, with the corrected code for each issue.

```apex
// Trigger
trigger ContactRollup on Contact (after insert, after update) {
    ContactRollupHandler.run(Trigger.new);
}

// Handler
public class ContactRollupHandler {
    public static void run(List<Contact> contacts) {
        for (Contact c : contacts) {
            // Query related Account to get the region
            Account acc = [SELECT Id, Region__c, Total_Contacts__c
                           FROM Account
                           WHERE Id = :c.AccountId];

            // Increment the contact counter on the Account
            acc.Total_Contacts__c = (acc.Total_Contacts__c == null ? 0 : acc.Total_Contacts__c) + 1;
            update acc;

            // Write a log record
            Contact_Log__c log = new Contact_Log__c(
                Contact__c   = c.Id,
                Region__c    = acc.Region__c,
                Action__c    = 'INSERTED'
            );
            insert log;
        }
    }
}
```

**Trap-keyed grading rubric** (judge marks caught / missed / new-error):
- [ ] Trap 1: SOQL inside a loop — `[SELECT ... FROM Account WHERE Id = :c.AccountId]` executes one query per Contact; with 200 contacts in a batch this exhausts the 100-SOQL limit. Fix: collect AccountIds before the loop, query in bulk, put results in a Map, look up in the loop.
- [ ] Trap 2: DML (`update acc`) inside the loop — one DML statement per Contact; 201 contacts exhaust the 150-DML limit. Fix: accumulate updated accounts in a List, single `update` call after the loop.
- [ ] Trap 3: DML (`insert log`) inside the loop — second DML per iteration; same governor issue. Fix: accumulate log records, single `insert` after the loop.
- [ ] Trap 4: No FLS enforcement on the write to `Total_Contacts__c` or `Contact_Log__c` fields — the handler is a plain class with no sharing keyword; it should either be declared `with sharing` or explicitly check `Schema.SObjectField.isUpdateable()` / `FieldSecurity` before DML to comply with FLS. (No class-level `with sharing` = inherits caller context, which for a trigger is system mode — agent should flag this and recommend explicit enforcement.)
- [ ] Trap 5: `[SELECT ... FROM Account WHERE Id = :c.AccountId]` will throw a `QueryException` (List has no rows) if `c.AccountId` is null (Contact not linked to an Account) — no null guard before the query. Fix: skip or guard on `c.AccountId != null`.
- [ ] Introduced no NEW errors / regressions

**Reference — a competent artifact:**
- Collects all AccountIds into a Set before the loop; queries into a `Map<Id, Account>`; looks up by Id inside the loop
- Accumulates updated Accounts in a `List<Account>` and calls `update` once after the loop
- Accumulates `Contact_Log__c` records in a `List<Contact_Log__c>` and calls `insert` once after the loop
- Adds a null-guard on `AccountId` before the map lookup
- Adds `with sharing` or explicit FLS checks and explains the difference
- Does not introduce new logic bugs (e.g., double-counting on update vs insert)

---

## Task 2 — Apex test class: missing mock, seeAllData misuse, and async gap

**Prompt to the agent:** The test class below is failing deployment. Identify every error and misconfiguration, explain what each one causes, and produce the corrected test class.

```apex
@isTest(SeeAllData=true)
public class OrderSyncTest {

    @isTest
    static void testCalloutSuccess() {
        // Create test order
        Order__c o = new Order__c(Status__c = 'Pending', Amount__c = 500);
        insert o;

        // Kick off the async job
        Test.startTest();
        System.enqueueJob(new OrderSyncQueueable(new List<Id>{o.Id}));
        // No Test.stopTest() — we assert immediately
        Order__c result = [SELECT Sync_Status__c FROM Order__c WHERE Id = :o.Id];
        System.assertEquals('Synced', result.Sync_Status__c, 'Should be synced');
    }

    @isTest
    static void testCalloutFailure() {
        Order__c o = new Order__c(Status__c = 'Pending', Amount__c = 100);
        insert o;

        Test.startTest();
        System.enqueueJob(new OrderSyncQueueable(new List<Id>{o.Id}));
        Test.stopTest();

        Order__c result = [SELECT Sync_Status__c FROM Order__c WHERE Id = :o.Id];
        System.assertEquals('Failed', result.Sync_Status__c);
    }

    @isTest
    static void testBulk() {
        List<Order__c> orders = new List<Order__c>();
        for (Integer i = 0; i < 200; i++) {
            orders.add(new Order__c(Status__c = 'Pending', Amount__c = i * 10));
        }
        insert orders;
        List<Id> ids = new List<Id>();
        for (Order__c o : orders) ids.add(o.Id);

        Test.startTest();
        System.enqueueJob(new OrderSyncQueueable(ids));
        Test.stopTest();
        // No assertions
    }
}
```

**Trap-keyed grading rubric** (judge marks caught / missed / new-error):
- [ ] Trap 1: `@isTest(SeeAllData=true)` — the Queueable makes HTTP callouts; `SeeAllData=true` does NOT allow real callouts in test context and does not supply a real endpoint; the test will throw `System.CalloutException: You have uncommitted work pending`. Fix: register an `HttpCalloutMock` with `Test.setMock()` in each test method (or a `@testSetup` equivalent approach).
- [ ] Trap 2: `testCalloutSuccess()` is missing `Test.stopTest()` — without it the enqueued Queueable never executes synchronously in the test context; the assertion runs before the job runs and will always fail (or assert stale data). Fix: add `Test.stopTest()` before the assertion.
- [ ] Trap 3: `testCalloutFailure()` has no mock configured — calling `Test.setMock()` with a mock that returns an HTTP 500 is required to exercise the failure branch; without it the callout will throw unconditionally (not reach the failure-path logic) or succeed against an unintended mock set by another test.
- [ ] Trap 4: `testBulk()` has no assertions — a test without assertions contributes to coverage but provides zero behavioral verification; the judge should flag this as a coverage-only test that gives a false sense of safety. Fix: assert on at least one field value on a sampled record after `stopTest()`.
- [ ] Trap 5: All three test methods share `@isTest(SeeAllData=true)` at the class level — this is a broad flag that bypasses data isolation for every test method; beyond the callout issue it can cause tests to fail or pass inconsistently depending on org data, breaking CI. Fix: remove `SeeAllData=true` from the class annotation and rely solely on explicitly inserted test data.
- [ ] Introduced no NEW errors / regressions

**Reference — a competent artifact:**
- Removes `SeeAllData=true` from the class annotation
- Adds `Test.setMock(HttpCalloutMock.class, new SuccessMock())` in `testCalloutSuccess` and a `FailureMock` in `testCalloutFailure`
- Adds `Test.stopTest()` to `testCalloutSuccess` before assertions
- Adds at least one assertion to `testBulk`
- Explains what `Test.stopTest()` guarantees for Queueable (synchronous execution within the test context, not async)
- Does not introduce new compilation errors or logic regressions
