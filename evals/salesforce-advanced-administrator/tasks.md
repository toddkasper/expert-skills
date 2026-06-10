# Application tasks — salesforce-advanced-administrator (Lens 4, held-out)

A skilled agent produces the artifact; a judge grades it against the trap-keyed rubric. Run baseline vs skilled. Do not reveal this rubric to the solving agent.

## Task 1 — SFDX permission-set XML redline: fieldPermissions traps

**Prompt to the agent:** Review the SFDX permission set metadata file below. Produce a redline of every error that would cause a deploy failure or a silent misconfiguration, with the corrected XML for each issue.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <label>Case Manager Elevated</label>
    <hasActivationRequired>false</hasActivationRequired>

    <!-- Object permissions for Case -->
    <objectPermissions>
        <allowCreate>true</allowCreate>
        <allowDelete>false</allowDelete>
        <allowEdit>true</allowEdit>
        <allowRead>true</allowRead>
        <modifyAllRecords>false</modifyAllRecords>
        <object>Case</object>
        <viewAllRecords>false</viewAllRecords>
    </objectPermissions>

    <!-- Field permissions -->
    <fieldPermissions>
        <editable>true</editable>
        <field>Case.Status</field>
        <readable>true</readable>
    </fieldPermissions>

    <fieldPermissions>
        <editable>true</editable>
        <field>Case.Priority</field>
        <readable>true</readable>
    </fieldPermissions>

    <!-- Escalation_Reason__c is a required custom field on Case -->
    <fieldPermissions>
        <editable>false</editable>
        <field>Case.Escalation_Reason__c</field>
        <readable>true</readable>
    </fieldPermissions>

    <!-- Compliance_Notes__c is a custom long text area; marked required in field metadata -->
    <fieldPermissions>
        <editable>true</editable>
        <field>Case.Compliance_Notes__c</field>
        <readable>true</readable>
    </fieldPermissions>

    <!-- Session-based activation for export permission -->
    <userPermissions>
        <enabled>true</enabled>
        <name>ExportReport</name>
    </userPermissions>

    <!-- Sharing rule: restrict Case access to only Case Manager profiles -->
    <!-- NOTE: this permission set is intended to be used as a "restricting" sharing mechanism -->
</PermissionSet>
```

**Trap-keyed grading rubric** (judge marks caught / missed / new-error):
- [ ] Trap 1: `Escalation_Reason__c` is required — a `<fieldPermissions>` entry with `<editable>false</editable>` on a required field will cause the deploy to fail with "You cannot deploy to a required field" (or similar); the fix is `<editable>true</editable>` (required fields must be editable in any permission set that grants Read on the object)
- [ ] Trap 2: `Compliance_Notes__c` is marked required in field metadata — same issue; `<editable>true</editable>` is correct, but agent must flag that required long-text fields cannot have `readable=true, editable=false` in a permission set; both traps are present but distinct fields
- [ ] Trap 3: The comment claims this permission set functions as a "restricting sharing mechanism" — permission sets are strictly additive; they cannot restrict access. Agent must call this out as architecturally wrong and note that muting permission sets (if available) or OWD/sharing rules are the correct tools for restriction
- [ ] Trap 4: `ExportReport` listed under `<userPermissions>` without `<hasActivationRequired>true</hasActivationRequired>` at the top level — for this to function as a session-based permission set (granting export only after MFA), `hasActivationRequired` must be `true`; as written it grants `ExportReport` unconditionally
- [ ] Trap 5: No `<fieldPermissions>` entry for any system-required fields that must be present to correctly round-trip; specifically, omitting `<readable>false</readable>` / `<editable>false</editable>` for sensitive fields is not a deploy error but is a coverage gap — agent should note fields missing from the set are simply not addressed, not that they default to denied (FLS defaults to no-access in a permission set if not listed)
- [ ] Introduced no NEW errors / regressions

**Reference — a competent artifact:**
- Corrects `Escalation_Reason__c` to `editable=true` and explains the required-field constraint
- Corrects `Compliance_Notes__c` to `editable=true` for the same reason
- Flags the "restricting" comment as architecturally incorrect and distinguishes additive vs restrictive mechanisms
- Adds `<hasActivationRequired>true</hasActivationRequired>` for the session-based ExportReport intent
- Notes that unlisted fields are simply not granted (default deny) and that the permission set should be explicit about its intended coverage

---

## Task 2 — Sharing architecture review: role hierarchy propagation & criteria-based rules

**Prompt to the agent:** A senior admin wrote the sharing design notes below for a new custom object. Identify every architectural error, explain what will actually happen at runtime, and provide the corrected design decision for each issue.

```
Object: Engagement__c  (custom)
OWD: Private
Grant Access Using Hierarchies: Enabled

Design decisions recorded by admin:

D1. "We created a criteria-based sharing rule: share all Engagement__c records where
    Region__c = 'West' with the 'West Sales' public group, Read/Write.
    This means users NOT in 'West Sales' cannot see West records — the rule restricts them."

D2. "We set OWD = Private. This means even record owners cannot see their own records
    unless a sharing rule explicitly grants them access."

D3. "Dana's manager is in the 'Director' role above her 'Sales Rep' role. We gave Dana
    a Manual Share (Read Only) on a specific Engagement record. Because the share is
    manual and not a sharing rule, Dana's manager will NOT see this record."

D4. "We need Compliance users to see ALL Engagement records. We added a sharing rule:
    share ALL records with the 'Compliance' public group. This satisfies the requirement."

D5. "We have a lookup from Engagement__c to Account. If a user can see the Account,
    they automatically get Read access to all Engagement__c records linked to that Account
    because Salesforce 'inherits' lookup access."
```

**Trap-keyed grading rubric** (judge marks caught / missed / new-error):
- [ ] Trap 1: D1 is wrong — criteria-based sharing rules are purely additive; the rule grants West Sales users access to West records but does NOT prevent other users from seeing West records through other access paths (owner access, role hierarchy, other rules). Sharing rules cannot restrict.
- [ ] Trap 2: D2 is wrong — OWD = Private means non-owners cannot see records by default; record owners always retain Full Access to their own records regardless of OWD. Private OWD does not lock out owners.
- [ ] Trap 3: D3 is wrong — Manual Shares are subject to "Grant Access Using Hierarchies" just like sharing rules; Dana's manager in a higher role WILL see the record because hierarchy propagation is enabled on the object. To prevent this, Grant Access Using Hierarchies must be disabled (not possible on standard objects; allowed on custom objects).
- [ ] Trap 4: D4 is partially wrong — a sharing rule that shares "ALL records" gives the Compliance group Read (or Read/Write) access but does NOT grant "View All" object-level visibility needed to guarantee they see records created after the rule runs or records in edge cases (e.g., ownership transferred to a user outside the sharing rule's scope before the rule recalculates). For guaranteed all-record access, the "View All" object permission on a permission set is the correct tool.
- [ ] Trap 5: D5 is wrong — Salesforce does not propagate access from a parent lookup to child records automatically (that is Master-Detail behavior, not Lookup); in a Lookup relationship the child record's visibility is governed entirely by the child object's OWD and sharing rules, independent of whether the user can see the parent Account.
- [ ] Introduced no NEW errors / regressions

**Reference — a competent artifact:**
- Corrects all five design decisions with the actual runtime behavior
- Distinguishes additive vs restrictive sharing clearly (D1)
- States the owner-always-has-access rule (D2)
- Explains hierarchy propagation applies to manual shares and how to disable it on custom objects (D3)
- Distinguishes sharing rules vs "View All" object permission for guaranteed coverage (D4)
- Distinguishes Master-Detail implicit access from Lookup relationships (D5)
