# Business Analyst — Change Management & Scope Escalation

> Load when advising on go-live change planning, training design, adoption metrics, or navigating conflicting stakeholder requirements and formal scope escalation.

---

## Change Management & Training (BA's role in Deploy and Operate phases)

The BA's job does not end at UAT sign-off. The credential and real implementations expect a BA to own the transition from build to operational adoption.

**Identify who changes and how much.** Before go-live, map each affected role to the process steps that change. End users who need to learn a new screen have lower change impact than staff whose entire data-entry workflow is eliminated. Score each group on impact and readiness:

| Impact | Readiness | Action |
|---|---|---|
| High | Low | Intensive training + job aid + post-launch support |
| High | High | Structured training + quick-reference card |
| Low | Low | Job aid + brief demo |
| Low | High | Email announcement + self-service resource |

**Author training artifacts at the right level.** Write quick-reference guides (job aids) for frequent tasks; leave system administration topics to the admin. A job aid for an intake volunteer should describe their new Salesforce screen workflow, not how approval processes work internally.

**Define adoption metrics upfront, before launch.** "Adoption" is measurable: login rate, record creation rate, picklist fill-rate on required fields, time-to-complete per record type. Without a baseline and a target, you can't tell whether training succeeded or the change failed. Build a dashboard or report before go-live to capture the day-one baseline.

**Schedule training within 2 weeks of go-live.** Training more than two weeks before launch means users forget before they can apply what they learned. Two-week window is the outer bound; one week is ideal for high-complexity workflows.

**Plan a feedback loop after go-live.** The BA should collect post-launch friction: support tickets, informal complaints, observed workarounds. Convert recurring friction into change-request stories. A BA who disappears at go-live leaves adoption problems unaddressed until the post-project review.

**Anti-patterns / red flags:**
- Scheduling training more than two weeks before go-live — users forget.
- One-size-fits-all training when roles have very different workflows.
- No feedback loop after go-live — the BA should collect post-launch friction and convert it to change-request stories.
- Adoption metrics set after launch — then you have no baseline for comparison.
- Job aids written at the system-admin level for end users who don't need that depth.

---

## Conflicting Stakeholder Requirements & Scope Escalation

When two stakeholders give incompatible requirements, the BA's job is to surface the conflict explicitly — not to resolve it unilaterally.

**Resolution path:**
1. Document both positions neutrally in the RAID log (as an Issue).
2. Bring both stakeholders into a decision meeting; use the power/interest grid to identify who holds Accountability.
3. Present the trade-offs (not a recommendation disguised as information).
4. Record the decision, rationale, and who made it in the decision log — even if a senior stakeholder overrules a process expert.

**Scope escalation trigger:** any requirement that changes the agreed-upon scope boundary — new objects, new integrations, new record types, expanded user base — must go through a formal change-request. A verbal "can we also add X?" from a stakeholder in a UAT session is not scope approval.

**Change-request minimum content:**
- What is being added or changed (requirement statement, not implementation).
- Why (business justification).
- Impact on timeline and budget (the BA estimates effort in collaboration with the tech lead).
- Decision and sign-off (sponsor name, date, written approval).

**Anti-patterns / red flags:**
- The BA picks the "better" requirement without escalating — transfers risk silently.
- The change request is approved verbally but not in writing — leads to "I never agreed to that" at go-live.
- Scope changes that are logged as defects to avoid a change-request process — they look like bugs but are net-new features.
- Change requests that skip the impact assessment — teams discover schedule impact only after committing to a delivery date.

---

## Workflow 3 — Map current → future-state process (swimlane + RACI)

> Full executable workflow for §5 Business Process Mapping. Linked from [../SKILL.md](../SKILL.md) Workflow 3 load cue.

1. Schedule a current-state walkthrough with SMEs. Use observation/shadowing, not just interview — people describe the ideal process, not what they actually do.
   → gate: as-is map reflects observed reality, not the SOP document; exception paths are included.
2. Draw the as-is swimlane: lanes = actors (end user, staff, system/Salesforce, external system). Capture every handoff, manual workaround, bottleneck, and data-entry step.
   → gate: at least two exception paths (e.g. incomplete submission, missing data) are on the map.
3. Run an automation audit on every Salesforce object the process touches: list active workflow rules, record-triggered flows, process builders, and triggers. Document side effects.
   → gate: automation audit complete; no active automation on the relevant objects is unaccounted for in the map.
4. Build the to-be swimlane at the business level (what changes and who benefits — not a click-by-click Salesforce walkthrough). Align each decision diamond → validation rule or flow decision; each handoff → automation trigger; each data-entry step → field + layout requirement.
   → gate: to-be map is readable by a non-technical stakeholder; each difference from as-is maps to at least one backlog item.
5. Build the RACI for the to-be process: exactly one Accountable per decision. Flag any row with two Accountables as a defect — escalate before proceeding.
   → gate: RACI has no duplicate Accountables; every new automation step has an owner for monitoring and break-fix.
6. Version-control the to-be map alongside the requirements that drove it; update both when scope changes.
   → gate: map file is committed to the repo with a link to the relevant requirements in the traceability doc.

---

## Traceability and Impact Analysis

When a field is resized, a picklist value changed, or a business rule updated, a BA must be able to enumerate downstream impact before approving the change. Traceability is not a one-time document — it is a living map.

**Concrete trace example:**
`Salesforce field metadata` → `generated schema constants` → `validation schema (Zod/Yup)` → `form field + max() / picklist constraint` → `automated test` → `UAT test case`

Breaking any link in this chain means a field change in Salesforce can silently pass QA while the form still enforces the old (wrong) constraint, or the test asserts against a stale limit. The BA's job is to flag the chain at requirements time so the team builds it in, not retrofit it.

**Impact analysis checklist for any field change:**
- [ ] Is a generated schema file downstream? (must regenerate)
- [ ] Does the form/API enforce max-length from a literal or from the generated constant? (if literal, it must be updated)
- [ ] Does a UAT test case reference a specific field length or picklist value? (must update)
- [ ] Does any training material reference the old field value or label? (must update)
- [ ] Does the data-import template hard-code a value set? (must update)
