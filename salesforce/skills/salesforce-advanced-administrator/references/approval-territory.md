# Approval Processes & Territory Management — Deep Dive

Referenced from the main SKILL.md Process Automation section. Load this file when configuring multi-step approval processes, debugging automation collisions on locked records, or working with Enterprise Territory Management.

---

## Approval Processes

Approval processes are a distinct exam domain with their own quirks:

- **Validation rules do not fire on approval submission.** Use entry criteria on the process, or a before-save flow that runs before the record is locked.
- **Record lock on submission.** Once submitted, the record is read-only to non-approvers. Flows/triggers that try to write it will fail with a lock error (`ENTITY_IS_LOCKED`). If automation must run, add a Recall step, let automation complete, then resubmit — or use an Apex action with `Database.rollback`-aware logic. The preferred declarative solution is to move the stamp logic into a **before-save** flow or a **final-approval action** within the process itself (which runs in the process's own unlock context).
- **Delegated approvers** inherit the original approver's queue but can't re-delegate. The delegatee must also have the appropriate object/FLS access to see the record — a delegatee without field access sees the record but can't read restricted fields.
- **Approval step order matters:** step 1 runs before step 2 regardless of "who approves." Each step can require unanimous or first-response from a group. Know the difference between per-step approver and process-level approver configurations.
- **Recall vs. rejection:** Recall returns the record to the submitter (draft state); rejection can trigger a final-rejection action and unlock the record or send a notification — configure final-rejection actions explicitly. An admin can perform a recall on behalf of a submitter from the Approval History related list.
- **Approval history visibility:** the Approval History related list is the definitive source of the current step, delegated approver, and historical decisions. Always check it before diagnosing "why hasn't X approved?"

**Numbers to know:** Max 30 approval steps per process. An object can have multiple approval processes; only one can be active at a time for automated submission, but multiple can be submitted manually. Approval email notifications use classic email templates (Visualforce or Text) — Lightning Email Templates are not supported in native approval emails.

**Anti-patterns / red flags:**
- Relying on a validation rule to block approval submission when the record is in the wrong state — it won't fire; use entry criteria.
- An after-save flow that stamps a field on an Opportunity in the "Closed Won" stage that is also part of an approval process — may hit `ENTITY_IS_LOCKED`. Move to before-save or a final-approval action.
- Forgetting to configure Final Rejection Actions — the record stays locked after rejection until an explicit unlock or final rejection action runs.

---

## Enterprise Territory Management (ETM)

Enterprise Territory Management (ETM) is blueprint-tested and often skipped in prep:

- **Territory model states:** Planning → Active → Archived. You can only assign records and run territory rules in **Active** state. You cannot delete an Active model — archive it first. Only one model can be Active at a time.
- **Assignment rules** (account-field criteria) run when accounts are saved or when you manually run rules against the model. Territory assignment does **not** automatically cascade to related Opportunities; Opportunity territory assignment is a separate step (run it manually or via a scheduled job in the territory model).
- **User access via territory:** members of a territory get at minimum Read on the accounts in that territory. OWD for Account can be Private while ETM grants the read — the two coexist. Territory membership grants access on top of OWD/role hierarchy; it doesn't replace them.
- **Collaborative Forecasting integrates with ETM** — forecasts roll up through the territory hierarchy, not the role hierarchy, when ETM is the forecast source. Don't confuse the two hierarchies. Switching from role-based to territory-based forecasting is a one-way change that requires re-configuring all forecast quotas.
- **Hierarchy inheritance:** a territory inherits the assignment rules of its parent unless overridden. Sub-territories can have their own rules that run in addition to the parent's.

**Anti-patterns / red flags:**
- Trying to run territory assignment rules while the model is in Planning state — rules don't fire until the model is Active.
- Expecting Opportunity territory to update automatically when Account territory changes — it does not; you must trigger Opportunity territory alignment explicitly.
- Assuming the role hierarchy and territory hierarchy are the same — they are independent structures with independent forecast rollups.
