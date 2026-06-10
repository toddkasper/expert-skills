# Decision Scenarios — Overflow (Scenarios 3–5)

Referenced from the main SKILL.md body. Load this file when diagnosing sharing-model restriction attempts, Lookup-to-rollup gaps, or Flow recursion bugs.

---

## Scenario 3 — Sharing model tightening without lowering OWD

> **Situation:** A manager reports that when her direct reports create Accounts, she can see all of them — but she is not supposed to see Accounts owned by peers in a different region. The Account OWD is Public Read/Write. The security team asks you to restrict cross-region visibility without touching the role hierarchy.

> **Competent move:** You cannot *narrow* access with a sharing rule — sharing is additive-only. The only way to restrict record visibility is to **lower the OWD** (to Private or Public Read Only). Once OWD is Private, re-open only the access you need (e.g., an owner-based sharing rule that shares records within each region's role). Explain this constraint before committing to a timeline — lowering OWD on a large object triggers a sharing recalculation job that can take hours.

> **Tempting-but-wrong:** Creating a sharing rule that "blocks" peers. No such construct exists. Criteria-based or owner-based sharing rules can only grant access to more users, never remove it from users who already have it via OWD or hierarchy.

> **Verify:** After changing OWD to Private, log in as a rep in Region A and confirm they cannot see Region B accounts. Run a SOQL query with `WITH USER_MODE` (Apex) or check via the Sharing button on a record to see the sharing reason.

---

## Scenario 4 — DLRS vs. roll-up summary on a Lookup

> **Situation:** A consultant needs a `Total_Donations__c` currency field on Account that sums all related Opportunity amounts where `StageName = 'Closed Won'`. The Account → Opportunity relationship is a standard Lookup (not Master-Detail). The consultant tries to create a Roll-Up Summary field on Account and can't find the option.

> **Competent move:** Roll-up summary fields are only available on the **master** side of a Master-Detail relationship. Account → Opportunity is a Lookup; you cannot create a native SOQL roll-up here. The correct tools are: (a) **DLRS** (Declarative Lookup Rollup Summaries) managed package — configure a rollup record pointing at the Lookup field; (b) a **record-triggered after-save flow** on Opportunity that aggregates and writes back to Account; or (c) Apex. DLRS is the least-code path for a standard admin.

> **Tempting-but-wrong:** Converting the Opportunity Lookup to a Master-Detail to enable roll-up summaries. This is destructive — it requires every Opportunity to have a non-null Account (breaking standalone opps), deletes Opp records if the parent Account is deleted, and changes sharing behavior. Never convert unless the business model truly mandates parent-required lifecycle coupling.

> **Verify:** After installing DLRS and configuring the rollup, trigger a recalculate job and run `SELECT Total_Donations__c FROM Account WHERE Id = '<test-id>'` (MCP / `sf data query` / Developer Console) to confirm the value matches the sum of Closed Won Opportunities.

---

## Scenario 5 — Flow recursion from a field update

> **Situation:** A record-triggered after-save flow on Contact fires when `Email` changes. It also writes back a `Last_Email_Updated__c` timestamp on the same Contact. In production the flow works — but occasionally a Contact's flow fires twice (seen in debug logs), and some contacts end up in an infinite-loop error.

> **Competent move:** Writing back to the triggering record from an after-save flow re-triggers the same flow (order-of-execution step 10 re-fires after-save triggers/flows). Add a **before-save** flow instead: set `Last_Email_Updated__c` on the in-flight record (no DML, no re-trigger). If after-save is required, add a `ISCHANGED(Email)` entry condition *and* a static recursion guard (a custom metadata flag or a flow variable reset after first execution — a text-type `$GlobalVariable` doesn't work for this; use a before-save flow or Apex static variable).

> **Tempting-but-wrong:** Using a `{!$GlobalVariable}` to guard recursion — Flow's global variables are re-initialized each transaction interview; they don't persist across a re-fire within the same transaction. An Apex-based static boolean is the correct cross-trigger guard, or simply move to before-save.

> **Verify:** Reproduce by updating `Email` on a Contact in a debug log session. A non-recursive fix shows exactly one flow interview for the email change. Confirm `Last_Email_Updated__c` is set after a single pass.

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
