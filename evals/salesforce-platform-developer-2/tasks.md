# Application tasks — salesforce-platform-developer-2 (Lens 4, held-out)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

A skilled agent produces the artifact; a judge grades it against the trap-keyed rubric. Run baseline vs skilled. Do not reveal this rubric to the solving agent.

## Task 1 — Async architecture redline: Batch + Queueable + callout anti-patterns

**Prompt to the agent:** Review the Apex classes below. This is an overnight data-sync job. Produce a redline of every governor-limit, architectural, and correctness bug — with the corrected design or code for each issue.

```apex
// Scheduled entry point
public class NightlySyncScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new AccountSyncBatch(), 2500);
    }
}

// Batch class
public class AccountSyncBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'SELECT Id, Name, AnnualRevenue, Industry, BillingCountry ' +
            'FROM Account ORDER BY Name'
        );
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        // Call external API for each account
        for (Account a : scope) {
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://erp.example.com/sync/' + a.Id);
            req.setMethod('POST');
            req.setBody(JSON.serialize(a));
            HttpResponse res = h.send(req);

            if (res.getStatusCode() == 200) {
                a.Sync_Status__c = 'Synced';
            } else {
                a.Sync_Status__c = 'Failed';
            }
        }
        update scope;
    }

    public void finish(Database.BatchableContext bc) {
        // Chain another batch to clean up old sync logs
        Database.executeBatch(new SyncLogCleanupBatch(), 2500);
    }
}
```

**Trap-keyed grading rubric** (judge marks caught / missed / new-error):
- [ ] Trap 1: Callout inside a loop in `execute()` — one HTTP callout per Account; the platform enforces 100 callouts per transaction. With a batch scope of 2,500 this will fail immediately on the first chunk. Fix: use a single bulk API call (composite or custom batch endpoint) per `execute()` chunk, or reduce scope to ≤ 100 and design accordingly with a documented trade-off.
- [ ] Trap 2: `ORDER BY Name` in the `QueryLocator` — using `ORDER BY` on a non-indexed field (Name is not indexed by default on Account) against large data volumes causes non-selective query errors and significantly degrades batch performance; remove `ORDER BY` or use an indexed field (e.g., `Id`).
- [ ] Trap 3: Batch scope of 2,500 — the maximum allowed scope for a batch is 2,000; any value above 2,000 is silently clamped to 2,000 (depending on API version) or will throw at runtime. Fix: use ≤ 2,000.
- [ ] Trap 4: `Database.executeBatch` in `finish()` — chaining a second batch from `finish()` is allowed but the chained batch (`SyncLogCleanupBatch`) also uses a scope of 2,500 (same bug) and there is no error handling if the first batch partially fails; the finish() should inspect `AsyncApexJob` status before chaining, or use a Platform Event / Queueable to decouple the chain.
- [ ] Trap 5: `update scope` after the callout loop — if any callout throws an uncaught exception mid-loop, `update scope` never runs and the chunk is retried (if the batch is configured for `Database.RaisesPlatformEvents`); wrapping each callout in try/catch and accumulating results before the single DML is safer and prevents partial-chunk data loss.
- [ ] Introduced no NEW errors / regressions

**Reference — a competent artifact:**
- Replaces the per-record callout loop with a single bulk/composite HTTP call per execute() chunk (or explicitly documents the 100-callout constraint and reduces scope to ≤ 100 with the trade-off)
- Removes `ORDER BY Name` or replaces with an indexed-field sort
- Reduces batch scope to ≤ 2,000
- Wraps callouts in try/catch, accumulates status into a Map, applies DML once outside the try/catch
- Adds `AsyncApexJob` status check (or Platform Event) in `finish()` before chaining the cleanup batch

---

## Task 2 — Integration design: External ID upsert + Change Data Capture consumer

**Prompt to the agent:** A developer wrote the integration design notes and code snippet below for a two-way sync between Salesforce and an external ERP. Identify every error and gap in the design, explain the real-world failure each causes, and provide the corrected approach.

```
Integration design notes (developer's summary):

Step 1 — Inbound: ERP pushes ~40,000 Product__c records nightly into Salesforce.
  - Approach: REST API POST loop, one record at a time to /services/data/v59.0/sobjects/Product__c/
  - No External ID field — we use the Salesforce-assigned Id to match on re-runs.

Step 2 — Outbound: Salesforce sends Price__c field changes on Product__c back to the ERP.
  - Approach: after-insert / after-update trigger on Product__c calls a @future(callout=true)
    method to POST each changed record to the ERP endpoint.
  - The @future method accepts a List<Product__c> parameter.

Step 3 — Idempotency: if the nightly job runs twice, duplicates are prevented because
  we check SELECT count() FROM Product__c WHERE Name = :erpName before each POST.

Step 4 — CDC: We subscribed an Apex trigger on the ChangeEventHeader to replay missed
  events after an outage — we store the replayId in a custom field and re-query it next run.
```

**Trap-keyed grading rubric** (judge marks caught / missed / new-error):
- [ ] Trap 1: REST API one-record-at-a-time for 40,000 records — this will take hours and burn API call limits (default 100,000/day shared across the org); the correct approach is the Bulk API 2.0 upsert job, which handles batching internally and is designed for this volume.
- [ ] Trap 2: No External ID — relying on Salesforce-assigned Id for matching on re-runs means any re-run after a failure will create duplicates (new records instead of updates) because the ERP doesn't know the Salesforce Id for new records that failed mid-batch. Fix: add an `ERP_Id__c` External ID field and use upsert by External ID.
- [ ] Trap 3: `@future` method accepts `List<Product__c>` as a parameter — `@future` methods cannot accept sObject lists or collections of sObjects as parameters (not serializable for the async queue); the parameter must be a primitive or a List/Set of primitives (e.g., `List<Id>`). This will cause a runtime exception.
- [ ] Trap 4: Idempotency check via `SELECT count() FROM Product__c WHERE Name = :erpName` — Name is not unique and not indexed; this check is non-selective, slow at scale, and will fail to prevent duplicates if two ERP records share a name. The correct idempotency mechanism is upsert on an indexed External ID field.
- [ ] Trap 5: CDC replay via Apex trigger on ChangeEventHeader storing replayId in a custom field — Apex CDC triggers cannot replay events by replayId; replay is a subscriber-side concept managed through the Streaming API (CometD) or the Event Bus, not re-queried via SOQL. The correct missed-event recovery pattern is to re-subscribe with the stored replayId using the Streaming API client or an External Service, not to store and re-query it in Apex.
- [ ] Introduced no NEW errors / regressions

**Reference — a competent artifact:**
- Replaces REST loop with Bulk API 2.0 upsert job for the 40,000-record inbound load
- Adds an indexed `ERP_Id__c` External ID field and uses upsert by External ID
- Changes `@future` parameter from `List<Product__c>` to `List<Id>` (or serialized JSON String) and queries records inside the method
- Replaces Name-based SOQL idempotency check with upsert-on-External-ID as the single idempotency mechanism
- Corrects the CDC replay misunderstanding: explains replayId is passed to the Streaming API subscriber at subscribe time, not stored in a field for re-query
