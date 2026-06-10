# PD1 — Additional Decision Scenarios

Overflow scenarios from [../SKILL.md](../SKILL.md). Load when working through edge-case trigger design, bulkification failures, or Quick Action cache issues. The two highest-priority scenarios (FLS after deploy, callout-in-trigger) are kept in the main skill body.

---

## Scenario 3 — Package-owned object: raw trigger vs. framework registration

> **Situation:** A developer needs custom logic to run whenever a `Contact` is inserted or updated on an org where a managed package already owns the `Contact` trigger (e.g. an NPSP org where NPSP has its own master `ContactTrigger`). The developer writes a new `ContactTrigger.trigger` and deploys it.
>
> **Competent move:** When a managed package already owns a trigger on an object, deploying a second trigger of the same name fails on deploy (duplicate trigger name error). Even with a different API name, the result is two triggers on the same object with **undefined firing order** — which can corrupt the package's automation or cause recursion. The correct approach: use the package's own extension mechanism. For NPSP this means creating a handler class that implements `npsp.TDTM_Runnable` and registering it in `TDTM_Config__mdt` with the target object, action, and load order, slotting custom logic into the managed execution sequence without touching managed code. See [salesforce-nonprofit-cloud-consultant](../../salesforce-nonprofit-cloud-consultant/SKILL.md) for TDTM specifics.
>
> **Tempting-but-wrong:** Naming the custom trigger something like `CustomContactTrigger` to avoid the duplicate-name error. This appears to work but produces two triggers on the same object firing in unpredictable order, which can interfere with the package's automation or cause recursion that hits governor limits.
>
> **Verify:** After registering the handler in the package framework, insert a Contact in a sandbox and pull the debug log. Confirm the custom handler's entry and exit appear within the package's trigger execution stack. Run the package's Apex test suite to confirm no regressions.

---

## Scenario 4 — Bulkification: "it works in dev, fails in production"

> **Situation:** A developer tests a trigger by updating a single Account. It works. In production, a nightly batch process updates 500 Accounts at once, and the trigger throws `"System.LimitException: Too many SOQL queries: 101"`.
>
> **Competent move:** The trigger contains a SOQL query inside a `for (Account a : Trigger.new)` loop — each record issues one query, so 500 records = 500 queries, far above the synchronous limit of 100. Fix: extract all Account Ids from `Trigger.new` into a `Set<Id>` before the loop, run one `SELECT … WHERE Id IN :acctIds` query into a `Map<Id, SObject>`, then iterate `Trigger.new` doing only in-memory map lookups. Issue a single `update` or `insert` after the loop.
>
> **Tempting-but-wrong:** Catching the `LimitException` and processing in smaller chunks inside the trigger. `LimitException` is not catchable in Apex — it terminates the transaction immediately. There is no retry path from inside a trigger.
>
> **Verify:** Write a test that inserts or updates 200+ records in a single DML call and run it against the trigger. If the query count stays at 1–2 regardless of record volume, the bulkification is correct. The test will surface the `LimitException` before production does.

---

## Scenario 5 — Quick Action cache: new fields silently missing after deploy

> **Situation:** A developer adds three new fields to an existing Quick Action's layout via SFDX (`quickActionLayoutItems` in the `.quickAction-meta.xml`) and deploys successfully. Testers report that the new fields do not appear in the Quick Action dialog — no error, just the old field list.
>
> **Competent move:** Salesforce caches Quick Action layouts at the org level. Adding or removing fields from `quickActionLayoutItems` does **not** bust this cache, even on full logout/login. To force a cache invalidation, make a change to any *non-field-list* property of the Quick Action metadata — typically edit the `<description>` or `<label>` by one character — then redeploy. Salesforce treats the structural metadata change as new and flushes the cached layout.
>
> **Tempting-but-wrong:** Clearing browser cache, logging out and back in, or using a different browser. The cache is server-side at the org level, not in the client browser. Client-side cache clearing has no effect.
>
> **Verify:** After the cache-bust redeploy, open the Quick Action in a fresh browser session (incognito). The new fields should render. If they still do not, confirm the `quickActionLayoutItems` XML is correctly structured and that the deploy completed without errors using `sf project deploy report`.

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
