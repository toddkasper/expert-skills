# PD2 — Additional Decision Scenarios

Overflow scenarios from [../SKILL.md](../SKILL.md). Load when working through platform event publish timing, Flow/trigger recursion interactions, or dynamic SOQL injection. The two highest-priority scenarios (async chaining, FLS after deploy) are kept in the main skill body.

---

## Scenario 3 — Platform event publish timing and transaction rollback

> **Situation:** An Apex trigger on Order uses `EventBus.publish(new Fulfillment_Request__e(...))` to notify a downstream fulfillment system. In testing, the developer discovers that when the Order DML fails (a validation rule fires), the fulfillment system still occasionally receives the event and tries to fulfill a non-existent Order.
>
> **Competent move:** By default, platform events published via `EventBus.publish()` use **publish-after-commit** semantics — the event is only delivered if the triggering transaction commits successfully. If the Order DML fails and rolls back, the event is suppressed. The developer should confirm the event definition's `Publish Behavior` is set to `Publish After Commit` (the default). If they are using `publish-immediately` (explicit opt-in on the event definition), the event fires regardless of transaction outcome — which is the cause of the phantom fulfillment requests. Switch to `Publish After Commit`.
>
> **Tempting-but-wrong:** Wrapping the publish in a try/catch and checking the `Database.SaveResult` from `EventBus.publish()` to decide whether to proceed. `EventBus.publish()` returns save results, but a "success" result only means the event was *accepted into the bus*, not that the parent transaction will commit.
>
> **Verify:** Set `Publish Behavior` on the event definition to `Publish After Commit` in Setup → Platform Events. Write an Apex test that inserts a record, publishes the event, then forces a rollback via `Database.rollback(savepoint)`, and assert the subscriber trigger does **not** execute (use a static counter in the subscriber trigger, assert it remains 0 after `Test.stopTest()`).

---

## Scenario 4 — Recursion from a Record-Triggered Flow and an Apex trigger on the same object

> **Situation:** An Account object has both a Record-Triggered Flow (fires on update, sets a field) and an Apex trigger (fires on update, does roll-up logic). In production, some Account updates cause a `System.LimitException: Too many SOQL queries: 101` error, but only when both automations are active.
>
> **Competent move:** The Flow's field update fires the Apex trigger a second time (Flow DML counts as a new trigger invocation). The Apex trigger's SOQL queries are consumed twice per original update — if they were already near the 100-limit, the second invocation pushes over. Apply the "one automation owner per (object, event)" principle: pick one owner. If both are needed, add a recursion guard in the Apex trigger (`TriggerGuard.hasRun`) so the second invocation from the Flow's DML exits immediately. Alternatively, refactor the Flow update into the Apex handler and remove the Flow.
>
> **Tempting-but-wrong:** Moving queries into a Queueable to "buy headroom." This masks the root cause — the trigger is still firing twice, consuming CPU and DML headroom twice — and adds async complexity. The fix is to eliminate the double-invocation, not to absorb it.
>
> **Verify:** Enable debug logs at `APEX_CODE: FINEST` during a test update. Count how many times the trigger handler's entry log line appears — it should appear once per DML. If it appears twice, recursion is confirmed. See [references/recursion-control.md](references/recursion-control.md) for guard implementation.

---

## Scenario 5 — Dynamic SOQL injection via concatenated filter

> **Situation:** A developer writes an Apex REST endpoint that accepts a `status` parameter from the request body and builds a SOQL query: `String q = 'SELECT Id FROM Order__c WHERE Status__c = \'' + status + '\''; List<Order__c> results = Database.query(q);`. A security review flags this as a critical vulnerability.
>
> **Competent move:** Use a bind variable to parameterize the filter: `String q = 'SELECT Id FROM Order__c WHERE Status__c = :status'; List<Order__c> results = Database.query(q);`. Apex bind variables in dynamic SOQL are never concatenated into the query string — the platform substitutes them safely, preventing injection. Where bind variables cannot be used (e.g., dynamic field names in the SELECT clause), sanitize with `String.escapeSingleQuotes()` before concatenation. Also add `WITH USER_MODE` to enforce FLS/sharing.
>
> **Tempting-but-wrong:** Validating the `status` value against an allowlist in Apex before concatenating it. Allowlist validation is a useful defense-in-depth measure but should never replace parameterization — the platform's bind variable mechanism is the correct primary defense.
>
> **Verify:** Write a test that passes a value like `' OR '1'='1` as the status parameter and assert it throws an exception or returns 0 rows (not all rows). With bind variables, the value is treated as a literal string, so the injected SQL logic is inert.

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
