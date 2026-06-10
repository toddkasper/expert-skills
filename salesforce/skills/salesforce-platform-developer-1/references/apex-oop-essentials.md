# PD1 — Apex OOP Essentials: Collections, Interfaces & Exceptions

Deep-dive companion to [../SKILL.md](../SKILL.md). Load when you need worked explanations of Apex collections, OOP inheritance mechanics, or exception-handling patterns beyond the Quick Reference rules.

---

## Collections

Three collection types, each with a distinct role:

- **List** — ordered, allows duplicates; integer-indexed (`list[0]`). The required type for DML — always pass `List<SObject>` to `insert`/`update`/`upsert`/`delete`.
- **Set** — unordered, no duplicates; no index access. The deduplication workhorse before SOQL: build a `Set<Id>` from `Trigger.new`, then use it in `WHERE Id IN :idSet` to get a single selective query.
- **Map** — key→value pairs. The bulkification workhorse: `Map<Id, SObject>` keyed on parent Id gives O(1) lookup inside a loop, avoiding the O(n²) problem of `List.contains()`.

**Anti-pattern to catch:** iterating a `List` with `contains()` in an inner loop is O(n²). Replace the lookup container with a `Set` or `Map`.

**Initialization shortcuts:**

```apex
// Map from SOQL result (Id auto-keyed)
Map<Id, Account> byId = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE Id IN :ids]);

// Dedup ids from trigger
Set<Id> acctIds = new Set<Id>();
for (Contact c : Trigger.new) acctIds.add(c.AccountId);
```

---

## Interfaces and Inheritance

```apex
// Interface — contract only
public interface Validator {
    Boolean validate(SObject record);
}

// Concrete implementation
public class RequiredFieldValidator implements Validator {
    public Boolean validate(SObject record) {
        return record.get('Name') != null;
    }
}

// Abstract class — partial implementation
public abstract class BaseHandler {
    public abstract void handle(List<SObject> records); // must override
    public virtual void log(String msg) { System.debug(msg); } // may override
}

// Extension
public class ContactHandler extends BaseHandler {
    public override void handle(List<SObject> records) { /* ... */ }
}
```

Key modifiers:
- `virtual` — method can be overridden; `override` keyword required on child.
- `abstract` — method must be overridden; class itself is also abstract (cannot be instantiated).
- Access modifiers: `public`, `private`, `protected` (visible in subclasses only), `global` (visible to managed-package consumers and external code). Default is `private`.

**Package framework application:** plugging into a managed-package trigger framework (e.g. implementing `npsp.TDTM_Runnable` for NPSP) directly exercises these mechanics — `implements`, signature matching, access modifiers, and `override` all apply.

---

## Exception Handling

```apex
try {
    insert records;
} catch (DmlException e) {
    for (Integer i = 0; i < e.getNumDml(); i++) {
        System.debug('Row ' + i + ': ' + e.getDmlMessage(i));
    }
} catch (Exception e) {
    throw new MyException('Unexpected: ' + e.getMessage(), e); // wrap + rethrow
} finally {
    // always runs — clean up resources
}

// Custom exception type
public class MyException extends Exception {}
```

**Partial-success DML:** use `Database.insert(records, false)` when you want good rows to commit even if some fail. Inspect `SaveResult[]`:

```apex
List<Database.SaveResult> results = Database.insert(records, false);
for (Database.SaveResult sr : results) {
    if (!sr.isSuccess()) {
        for (Database.Error err : sr.getErrors()) {
            System.debug(LoggingLevel.ERROR, 'Failed: ' + err.getMessage());
        }
    }
}
```

Never silently swallow exceptions — at minimum log the error Id before re-throwing.

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
