# Application tasks — salesforce-administrator (Lens 4, held-out)

A skilled agent produces the artifact; a judge grades it against the trap-keyed rubric. Run baseline vs skilled. Do not reveal this rubric to the solving agent.

## Task 1 — Flow audit: screen flow with DML inside a loop and bad sharing

**Prompt to the agent:** Review the Flow design specification below. Produce a redline identifying every governor-limit, security, and configuration error, and provide the corrected design for each issue.

```
Flow: Auto-Assign_Cases  (Record-Triggered Flow, After Save, on Case)
Trigger: when Case is created or updated
Entry criteria: Status changed to "Escalated"

Step 1 — Get Records: query Cases WHERE OwnerId = {!$User.Id}
         (no filter on Status or RecordType — returns all cases for current user)

Step 2 — Loop over {!getCases} collection
   Step 2a — Update Records: set each Case.Priority = "High"
              (DML inside the loop)
   Step 2b — Create Records: create a Task linked to each Case
              (DML inside the loop)

Step 3 — Assignment Rule: reassign the triggering Case using the active Case assignment rule
         (Run mode: System Context Without Sharing)

Step 4 — Send Email Alert to Case Owner

Notes from the admin who built it:
- "I used System Context Without Sharing so the flow works for all users"
- "The loop only iterates over the current user's cases so it's fine for limits"
- "I filtered the Get Records to only current user to keep it small"
```

**Trap-keyed grading rubric** (judge marks caught / missed / new-error):
- [ ] Trap 1: DML (Update Records + Create Records) inside the loop — must be extracted to bulk collections updated/created in a single element outside the loop
- [ ] Trap 2: "System Context Without Sharing" on the assignment step defeats record-level security for all downstream operations in the flow context, not just step 3; correct context is "System Context With Sharing" (or User or System depending on requirement, with explicit justification)
- [ ] Trap 3: Get Records query has no selective filter — querying all Cases for the user without a Status or RecordType filter is non-selective on large orgs and will cause performance issues; a proper filter on Status or CreatedDate scope is needed
- [ ] Trap 4: A Record-Triggered Flow set to "After Save" cannot perform DML on the triggering record (would require a separate Update Records or a before-save flow for field updates on the same record) — the design creates a potential recursion risk if the Case Priority update re-triggers the flow
- [ ] Trap 5: Missing fault-path handling on the Create Records and email steps — any uncaught fault will surface as a generic error to the end user with no logging
- [ ] Introduced no NEW errors / regressions

**Reference — a competent artifact:**
- Flags all three DML-in-loop violations and prescribes a collection variable + single Update Records / Create Records element outside the loop
- Identifies the sharing-context choice and explains the correct option with least-privilege reasoning
- Notes the non-selective Get Records query and recommends a bounded filter
- Calls out the after-save recursion risk and proposes either a before-save flow for field stamps or an entry-criteria guard (`ISCHANGED` + a formula checkbox) to prevent re-entry
- Adds fault paths to each DML and email step with a Create Records → ErrorLog__c (or platform event) fallback

---

## Task 2 — Sharing model design: Private OWD with targeted access, no over-sharing

**Prompt to the agent:** Your org has the following requirements. Design the complete sharing model (OWD settings, sharing rules, permission sets, and any manual-share considerations). Call out any requirement that sharing rules cannot satisfy and propose the correct mechanism.

```
Object: Project__c (custom)
Records: ~50,000 active projects

Requirements:
R1. By default, only the record owner can see a Project__c record.
R2. All members of the "Executive" role (and their subordinates) must see every Project__c.
R3. Users assigned the "Partner Portal" profile must see Projects where
    Project__c.Region__c = "EMEA" — but must NOT be able to see any other Projects.
R4. A single named user, Dana (not an executive, no special role), needs read access
    to every Project owned by users in the "APAC Sales" role — but Dana's manager
    must NOT automatically get that same access through role hierarchy.
R5. Two users (internal, same profile, same role) need to collaborate on a single
    Project record for 30 days, after which the extra access should expire automatically.
R6. The "Compliance Auditor" permission set must grant visibility into ALL Project__c
    records regardless of owner or sharing rules, for users holding that permission set.
```

**Trap-keyed grading rubric** (judge marks caught / missed / new-error):
- [ ] Trap 1: R1 is satisfied by OWD = Private on Project__c — agent must state this explicitly and note that "Grant Access Using Hierarchies" defaults to enabled, which is relevant to R4
- [ ] Trap 2: R3 asks Partner Portal users to see ONLY EMEA records — agent must identify that sharing rules grant access but cannot restrict it; a criteria-based sharing rule will ADD access for EMEA, but if the OWD is Private that is correct (they cannot see non-EMEA records already); agent must not recommend using sharing rules as a restriction mechanism
- [ ] Trap 3: R4 requires that Dana's manager NOT inherit access — agent must recognize that role hierarchy propagation (Grant Access Using Hierarchies) would give Dana's manager visibility, and the only correct solution is to grant Dana access via a Manual Share or a criteria-based sharing rule scoped to Dana's user record, not a role-based sharing rule (which would propagate up the hierarchy)
- [ ] Trap 4: R5 requires time-limited access — agent must state that standard sharing rules and manual shares have no native expiry and propose either a scheduled Flow/Apex that removes the manual share after 30 days, or Salesforce's native Temporary Record Access if available in the org's edition
- [ ] Trap 5: R6 "regardless of sharing rules" — agent must recognize this cannot be done with sharing rules alone (which are additive) and requires either the "View All" object permission on the permission set or the "View All Data" system permission, and must distinguish between the two and recommend the least-privilege option (object-level View All)
- [ ] Introduced no NEW errors / regressions

**Reference — a competent artifact:**
- Sets OWD = Private on Project__c, notes hierarchy propagation is on by default
- Implements criteria-based sharing rule for EMEA + Partner Portal profile (not role), explains it adds but doesn't restrict
- Correctly flags the hierarchy problem for R4 and recommends Manual Share scoped to Dana (not a role-based sharing rule)
- Calls out R5 native expiry gap and proposes the scheduled-Flow removal pattern or Temporary Record Access
- Recommends "View All" on the permission set for R6, not "View All Data", with a one-sentence least-privilege justification
