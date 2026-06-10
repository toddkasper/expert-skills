# PD2 — Recursion Control in Triggers

Deep-dive companion to [../SKILL.md](../SKILL.md). Load when implementing or debugging trigger recursion guards, or when a managed-package framework's built-in recursion detection interacts with your custom handlers.

---

## The Problem

A trigger fires once per DML statement on the object. If your `after update` handler updates the same object (e.g. sets a status field on the same Account it just processed), that DML fires the trigger a second time — potentially looping until a governor limit terminates the transaction.

## Standard Guard Pattern

A static Boolean in a separate utility class:

```apex
public class TriggerGuard {
    public static Boolean hasRun = false;
}

// In the trigger handler's execute() method:
if (TriggerGuard.hasRun) return;
TriggerGuard.hasRun = true;
// ... handler logic ...
```

Static variables reset per transaction, so the guard is scoped to one execution chain — it does not persist across transactions. The guard must be in a separate class (not in the trigger itself) so that both the `before` and `after` contexts reference the same static state.

## Scoped Guards for Multi-Context Triggers

If you intentionally need the trigger to fire in both an insert and a subsequent update (e.g. initial insert creates a record, then an `after insert` update fires the trigger again for enrichment), scope the guard to context rather than a single Boolean:

```apex
public class TriggerGuard {
    public static Set<String> contextsRun = new Set<String>();
    
    public static Boolean hasRun(String context) {
        return contextsRun.contains(context);
    }
    public static void markRun(String context) {
        contextsRun.add(context);
    }
}

// In handler:
String ctx = Trigger.operationType.name(); // e.g. 'AFTER_UPDATE'
if (TriggerGuard.hasRun(ctx)) return;
TriggerGuard.markRun(ctx);
```

## Package Framework Interaction

Some managed-package trigger frameworks (e.g. NPSP's TDTM) have built-in recursion detection at the framework level. Handlers plugged into such a framework only need an additional guard if they themselves issue a DML statement that would re-fire the same handler slot via a path outside the framework's detection. Check the framework's documentation to confirm which recursion scenarios it handles natively before adding redundant guards.

## Diagnosing Recursion

Enable debug logs at `APEX_CODE: FINEST` during a test update. Count how many times the trigger handler's entry log line appears — it should appear once per DML. If it appears twice (or more), recursion is confirmed. The debug log will also show which DML statement triggered the second invocation, pointing you to the exact code path that needs the guard.
