# PD2 — Change Data Capture (CDC)

Deep-dive companion to [../SKILL.md](../SKILL.md). Load when implementing CDC-based integration, designing real-time data replication, or debugging change-event delivery and rollback behavior.

---

## What CDC Is and When to Use It

Change Data Capture publishes change events (`AccountChangeEvent`, `ContactChangeEvent`, custom-object `MyObject__ChangeEvent`) on the change-event channel bus whenever records are created, updated, deleted, or undeleted in Salesforce.

Use CDC when:
- An external system needs a near-real-time copy of Salesforce records (replaces polling `SELECT … WHERE LastModifiedDate > :checkpoint`).
- You need to know *which specific fields* changed on an update, not just that the record changed.
- You want to decouple the originating Salesforce transaction from downstream processing.

CDC is more reliable than outbound messages for high-volume objects because it is channel-based and supports durable replay.

## Enabling CDC

Enable per-object in Setup → Integrations → Change Data Capture. Standard objects and custom objects can be enabled. Managed-package objects can be enabled only if the package publisher allows it.

## Consuming Change Events

**Apex trigger on the change-event object** (in-org processing):

```apex
trigger AccountChangeTrigger on AccountChangeEvent (after insert) {
    for (AccountChangeEvent event : Trigger.new) {
        EventBus.ChangeEventHeader header = event.ChangeEventHeader;
        String changeType = header.changeType; // CREATE, UPDATE, DELETE, UNDELETE
        List<String> changedFields = header.changedFields; // null on CREATE/DELETE
        List<String> recordIds = header.recordIds; // affected record Ids
        
        if (changeType == 'UPDATE' && changedFields.contains('Status__c')) {
            // react to status change
        }
    }
}
```

Note: only `after insert` is valid on change-event objects — `before` contexts and other DML events are not supported.

**CometD / external subscriber**: subscribe to the `/data/AccountChangeEvent` channel using a CometD client and a valid Salesforce session. External consumers use `ReplayId` for durable replay.

## Key Payload Fields

| Field | Values / Notes |
|---|---|
| `ChangeEventHeader.changeType` | `CREATE`, `UPDATE`, `DELETE`, `UNDELETE` |
| `ChangeEventHeader.changedFields` | List of API field names that changed (only populated on UPDATE; null on CREATE/DELETE/UNDELETE) |
| `ChangeEventHeader.recordIds` | Ids of affected records (batch updates can have multiple) |
| `ChangeEventHeader.entityName` | API name of the object (e.g. `Account`) |
| `ReplayId` | Durable cursor for replay; 72-hour retention (24h standard-volume orgs) |

## Rollback Behavior — Critical Gotcha

CDC change events are **not rolled back** if the originating transaction rolls back. Once an event is published to the bus (which happens at commit), it is delivered even if a subsequent operation in the originating system fails. Design downstream consumers to be **idempotent**: processing the same event twice must produce the same result (use the `recordId` + `ReplayId` as an idempotency key).

This differs from Platform Events with `Publish After Commit` behavior — Platform Events are suppressed on rollback; CDC events are committed as part of the transaction's commit, so if the transaction commits and then a downstream step fails, the event is already delivered.

## Testing CDC in Apex

Salesforce does not support publishing CDC events directly in Apex tests (`Test.enableChangeDataCapture()` is required in the test class, and events are delivered at `Test.stopTest()`):

```apex
@isTest
static void testCdcTrigger() {
    Test.enableChangeDataCapture();
    Account a = new Account(Name='Test CDC');
    insert a;
    Test.getEventBus().deliver(); // or Test.stopTest()
    // assert downstream effects
}
```

`Test.getEventBus().deliver()` forces immediate delivery of all pending change events in the test context without requiring `stopTest()`.
