# PD2 — Invocable Apex: Bridging Flow and Code

Deep-dive companion to [../SKILL.md](../SKILL.md). Load when writing `@InvocableMethod` actions for Flow, or debugging callout/bulkification issues in Flow-invoked Apex.

---

## When to Use Invocable Apex

Use `@InvocableMethod` when a Flow needs logic that exceeds declarative capabilities: complex collection algebra, callouts, dynamic SOQL, or computations that would be brittle or non-performant in Flow's element model. Invocable Apex keeps the orchestration in Flow (admin-maintainable) while delegating the hard parts to code.

Prefer Flow → Invocable Apex over a pure Apex trigger when the business process is heavily branching and declarative, with only isolated steps that need code.

## Method Signature Rules

```apex
public class RateCalculator {
    @InvocableMethod(label='Calculate Rates' description='Computes tiered rates for opportunities')
    public static List<Decimal> calculate(List<Id> oppIds) {
        // oppIds contains ALL records in the batch — process as a collection
        Map<Id, Opportunity> opps = new Map<Id, Opportunity>(
            [SELECT Id, Amount FROM Opportunity WHERE Id IN :oppIds]
        );
        List<Decimal> results = new List<Decimal>();
        for (Id oppId : oppIds) {
            results.add(computeRate(opps.get(oppId).Amount));
        }
        return results;
    }
}
```

Mandatory rules:
- Method must be `static`, `public` or `global`, in a **non-inner class** (inner classes cannot be invoked).
- Input and output are **`List<T>`** — Flow always passes a collection, even for a single record. The output list index must correspond to the input list index.
- Complex inputs/outputs use an inner class with fields annotated `@InvocableVariable`:

```apex
public class RateInput {
    @InvocableVariable(required=true) public Id oppId;
    @InvocableVariable public Decimal overrideRate;
}
@InvocableMethod(label='Calculate Rates')
public static List<Decimal> calculate(List<RateInput> inputs) { ... }
```

## Callouts from Flow-Invoked Apex

Callouts are allowed in Invocable Apex, but the Flow context matters:
- **Record-triggered Flow (synchronous path):** callouts are blocked if DML has already occurred in the transaction (same restriction as trigger context). Move the action to an **asynchronous path** (scheduled path, paused/resumed via `FlowStageChange`).
- **Screen Flow:** callouts are allowed in screen flows because they run in a user-interactive context without open DML transactions.
- **Scheduled Flow:** runs in an async context; callouts are generally allowed.

Test every callout path with `HttpCalloutMock` exactly as you would for any Apex test.

## Bulkification in Invocable Methods

The `@InvocableMethod` runtime collects all records in a batch and passes them to the method at once. **Do not iterate and invoke SOQL/DML per input record** — that recreates the N+1 problem inside your invocable:

```apex
// WRONG — SOQL per input
public static List<Decimal> calculate(List<Id> oppIds) {
    List<Decimal> results = new List<Decimal>();
    for (Id id : oppIds) {
        Opportunity opp = [SELECT Amount FROM Opportunity WHERE Id = :id]; // N queries
        results.add(computeRate(opp.Amount));
    }
    return results;
}
// RIGHT — one query for all inputs (see example above)
```

## Testing Invocable Methods

Test the method directly (pass a List of inputs, assert the List of outputs) rather than invoking through a Flow in the test. This is faster and more reliable. For callout paths, set up `HttpCalloutMock` before calling the method.

```apex
@isTest
static void testCalculate() {
    Opportunity opp = new Opportunity(Name='Test', StageName='Prospecting',
        CloseDate=Date.today(), Amount=10000);
    insert opp;
    List<Decimal> results = RateCalculator.calculate(new List<Id>{ opp.Id });
    Assert.areEqual(1, results.size());
    Assert.isTrue(results[0] > 0);
}
```

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
