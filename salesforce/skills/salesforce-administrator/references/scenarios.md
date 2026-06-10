# Decision Scenarios — Overflow (Scenarios 3–5)

These scenarios are referenced from the main SKILL.md body. Load this file when diagnosing sharing-model restriction attempts, managed-package mystery field changes, or Agentforce record-access failures.

---

## Scenario 3 — Sharing rules cannot restrict; only OWD can lower the floor

> **Situation:** An org has Opportunity OWD set to Public Read/Write. Sales reps can see each other's deals. A new requirement: reps should only see their own pipeline; managers should still see their team's. An admin proposes creating a sharing rule that "restricts access to the owner only." Is this possible? What is the correct approach?

> **Competent move:** Sharing rules can only **grant** access above the OWD floor — they cannot restrict. The fix is to change the OWD on Opportunity to **Private**, which sets the floor to owner-only visibility. Then use the **role hierarchy** to automatically give managers upward visibility into their subordinates' records (no sharing rule needed — role hierarchy is automatic when OWD < Public Read/Write). If cross-role access is needed beyond the hierarchy, add owner-based or criteria-based sharing rules to open it back up selectively.

> **Tempting-but-wrong:** Create a criteria-based sharing rule that says "share records where Owner = Viewer" — there is no such sharing rule syntax. Or try to use a permission set to restrict record visibility — permission sets are additive on object/field access and have no mechanism to restrict sharing. The only mechanism to *lower* record visibility is to change the OWD.

> **Verify:** After changing OWD, run `SELECT Id, Name FROM Opportunity LIMIT 10` (MCP / `sf data query` / Developer Console) as a rep user (or via a guest/community session) to confirm row-level filtering. Check that managers can still see subordinate records by querying under a manager's user context.

---

## Scenario 4 — Mystery field change: managed-package automation

> **Situation:** Staff report that new Contact records created via a data import have their `Phone` field overwritten with a different number within seconds of saving. No custom trigger or flow in the org's namespace touches `Phone` on Contact after insert. What should the admin investigate first?

> **Competent move:** When a field changes value with no locally-owned automation responsible, **suspect managed-package automation** — Workflow Rules, flows, or triggers in a managed-package namespace that fire on your objects. In this org (likely NPSP), NPSP's Contacts & Organizations package ships a workflow rule that can copy `Phone → MobilePhone` or vice versa based on a preferred-phone picklist value that defaults to "Mobile." Check Setup → Workflow Rules and filter by namespace (look for `npsp__` prefix). Also check Setup → Flows and sort by namespace. Enable an Apex debug log for a System Administrator user, re-trigger the scenario in a sandbox, and inspect the log for triggers and flows in non-default namespaces.

> **Tempting-but-wrong:** Assume the import tool itself is transforming the data and re-test the import. Or check your own org's flows and triggers — they are in the default namespace and are not the culprit. Blaming the visible, known automation before checking managed-package namespaces wastes time.

> **Verify:** In the Apex debug log, search for `WORKFLOW_ACTION` or `FLOW_START_INTERVIEWS` entries. Note the namespace prefix. Once the offending rule is identified, deactivate it in Setup (you can deactivate managed-package Workflow Rules even if you can't edit them). Retest the import.

---

## Scenario 5 — Agentforce agent cannot retrieve a record

> **Situation:** An Agentforce agent is configured in Agent Builder with a Flow-backed action that queries open Cases for a contact. In testing, users report the agent responds "I wasn't able to find any open Cases" even though the Cases exist. The Flow is active and works when invoked manually by a System Administrator. What is the diagnostic approach?

> **Competent move:** The agent runs under a **configured running user context**, not as a System Administrator. The running user's OWD, FLS, and permission sets govern what the agent can see. The most likely cause is that the running user lacks Read on the Case object (object CRUD), cannot see a required filter field due to FLS, or the Cases are owned by others and the OWD on Case is Private with no sharing rule granting the running user access. Diagnostic steps: (1) identify the agent's running user in Agent Builder; (2) check that user's profile and permsets for Case Read access; (3) run the SOQL query the Flow uses as that user to confirm it returns records; (4) check Case OWD and sharing rules.

> **Tempting-but-wrong:** Assume the Flow has a bug because it returns results when run as an admin. Or rebuild the Flow. The Flow itself is correct — the access problem is upstream of it. Elevating the running user to System Administrator "to fix" is a security anti-pattern that bypasses all OWD/FLS/sharing controls for every action the agent can perform.

> **Verify:** Run `SELECT PermissionsRead FROM ObjectPermissions WHERE ParentId IN (SELECT Id FROM PermissionSet WHERE IsOwnedByProfile=true AND Profile.Name='<running_user_profile>') AND SObjectType='Case'` (MCP / `sf data query` / Developer Console) to confirm Case Read. Then run the Case SOQL with a `LIMIT 1` filter matching the scenario as the running user context. Check Setup Audit Trail for any recent change to Case OWD.
