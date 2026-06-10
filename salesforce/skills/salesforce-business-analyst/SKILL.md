---
name: salesforce-business-analyst
description: Salesforce business-analysis work — eliciting and documenting requirements, writing and sizing user stories (INVEST, Given/When/Then, MoSCoW), facilitating stakeholder workshops and discovery, mapping current/future-state processes (swimlanes, RACI, RAID), defect triage, and running user acceptance testing to a go/no-go decision. Use when gathering requirements, mapping process, or driving UAT on a Salesforce project. This is the requirements/process discipline — not building the config or code (see salesforce-administrator and the platform-developer skills). Scoped and benchmarked by the Business Analyst (BA-201) blueprint.
metadata:
  credential: Salesforce Certified Business Analyst
  exam-code: BA-201
  domain: salesforce
  type: certification-playbook
  status: current
  last-reviewed: 2026-06-09
  blueprint-verified: 2026-06-07
---

# Salesforce Business Analyst — Skills Reference

## Overview

**This file is an operational playbook, not an exam outline.** Each section states the rules a BA applies at decision time — requirements vs. user stories, story sizing, testable acceptance criteria, UAT go/no-go — plus the anti-patterns to catch in review and the way to verify against the live org before trusting any assumption. The recurring discipline is to confirm org reality (objects, fields, picklists, active automations) before committing to a requirement or estimate.

Credential background and study path: [references/study-resources.md](references/study-resources.md).

> **Load this skill when…** eliciting or documenting requirements for a Salesforce project; writing or reviewing user stories and acceptance criteria; facilitating a discovery or UAT session; mapping as-is/to-be processes including automation implications.
> **Not this skill:** building the declarative config (fields, flows, layouts) → see `salesforce-administrator`; writing Apex, LWC, or integration code → see `salesforce-platform-developer-1` / `salesforce-platform-developer-2`.

> **Deeper context:** Study resources live in [references/study-resources.md](references/study-resources.md) (loaded on demand). For org-specific applications of these rules, see a per-org appendix you maintain in your own project, referenced from a CLAUDE.md. For NPSP/nonprofit-specific guidance, see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md).

> **Verify steps assume nothing about your tooling** — use your project's Salesforce MCP connection, the Salesforce CLI (`sf`), or the Salesforce setup UI, in that order of preference.

---

Credential logistics and study path: see [references/study-resources.md](references/study-resources.md).

---

## Uncertainty & Escalation

- **Always re-verify live:** `[volatile — verify live]` items include: BA-201 blueprint topic weights and question counts, Salesforce automation tooling retirement dates (Workflow Rules / Process Builder deprecation timeline), specific org edition/license feature availability, and managed-package automation behavior (NPSP, Nonprofit Cloud) across package versions.
- **Live wins:** when this file and the live org, current exam guide, or official Salesforce release notes disagree — for example, a new Salesforce automation tool introduced in a recent release — trust the live system and flag this skill as stale via the Feedback protocol below.
- **Escalate to a human:** surface — never silently decide — any action that constitutes a sign-off or go-live decision (go/no-go for production deployment, sponsor approval to defer a Must requirement, acceptance of a residual defect risk). These decisions belong to the named human Accountable in the RACI; the BA facilitates and documents, not decides.
- **Confidence taxonomy:** every fact in this file is considered stable unless tagged `[volatile — verify live]` or `[opinion — house style]`.

Inline volatile tags applied:
- BA-201 blueprint topic weights (24% / 18% / 17% / 17% / 16% / 8%) `[volatile — verify live]` — Salesforce updates exam blueprints; verify against the current official exam guide before studying or quoting weights.
- Workflow Rules and Process Builder "retired for new work" status `[volatile — verify live]` — Salesforce has announced deprecation; verify the current enforcement date and any grace periods in the latest release notes.
- NPSP managed-package automation side effects (Household Account creation, `npe01__PreferredPhone__c` workflow rule) `[volatile — verify live]` — package version-specific; confirm active automations in the target org before writing requirements.

---

## 1. Collaboration with Stakeholders (24% — highest weight)

**Map stakeholders before the first workshop, not after.** Build a power/interest grid: high-power/high-interest = manage closely (project lead, executive board); high-power/low-interest = keep satisfied (executive sponsor); low-power/high-interest = keep informed (end users whose daily work changes); low-power/low-interest = monitor. **Decision rule:** the person who can say "no, ship it differently" is a primary stakeholder and must sign off; everyone else is consulted or informed.

**Use a RACI matrix to kill the "who decides?" ambiguity.** Exactly one **A**ccountable per decision. If two people are Accountable for the same decision, that is a red flag — escalate to make it one. **R**esponsible can be many; **C**onsulted before; **I**nformed after.

**Pick the elicitation method to fit the source, not your habit:**

| Situation | Method | Why |
|---|---|---|
| One SME with deep tacit knowledge | 1:1 interview (open questions first, then closed to confirm) | Won't speak up in a group |
| Process truth differs from the SOP | Observation / shadowing (process walk) | People describe the ideal, not what they do |
| Many stakeholders, conflicting wants | Facilitated workshop (JAD) + dot voting | Surfaces conflict early, builds shared ownership |
| Large dispersed user base | Survey / questionnaire | Cheap breadth; weak on "why" |
| Existing system or paper artifacts | Document analysis | Free, factual, no scheduling cost |

**Anti-patterns / red flags:**
- Designing a solution in a requirements interview ("so we'll add a flow that…") — your job is to extract the *need*, not pre-commit the build.
- Letting the loudest stakeholder set scope. Manage dominant voices: round-robin, write-then-share (affinity mapping), anonymous dot voting.
- No decision log. Every contested decision needs a one-line record (decision, date, who, rationale) so it isn't relitigated.
- A RAID log (Risks, Assumptions, Issues, Dependencies) that nobody updates — it must be living or it is theater.

**Verification step:** Before claiming "staff need X," confirm the org reality — inspect existing objects and fields, and run a report or query to check whether the "missing capability" is actually already there. Don't write a requirement for something the org already does.

---

## 2. User Stories (18%)

**Write every story in the canonical form:** *"As a [persona], I want [capability] so that [business value]."* The "so that" is mandatory — a story without a value clause is a task, and tasks don't get prioritized against business value.

**Apply INVEST to gate a story into a sprint:**

| Letter | Test it must pass | Red flag if… |
|---|---|---|
| Independent | Can be built without waiting on another story | Story can't start until 3 others ship |
| Negotiable | Describes the need, not a frozen spec | Story is a UI mockup with pixel coords |
| Valuable | Delivers value to a user/business | "Refactor the Lambda" with no user value |
| Estimable | Team can size it | Too vague to estimate → split or spike |
| Small | Fits in one sprint | "Build the portal" |
| Testable | Has acceptance criteria you can pass/fail | "Should be fast/intuitive" |

**Write acceptance criteria in Given/When/Then (Gherkin)** so they convert 1:1 into UAT test cases. **Decision rule:** if you can't phrase the criterion as a pass/fail observation, it's not done — rewrite it.

**Split big stories with a real pattern, never arbitrarily:** by workflow step, by data variation (one record type/scenario at a time), by user role, by happy-path-then-exception, by CRUD operation. Each split must keep its own "so that" value.

**Backlog hierarchy:** Epic → Story → Task. Don't flatten these — prioritization happens at the story level, sizing at the task level.

**Prioritize with MoSCoW and mean it:** Must (launch blocked without it) / Should (painful to omit, not blocking) / Could (nice-to-have) / Won't (explicitly out, this release). **Red flag:** everything is a "Must." If >60% of the backlog is Must, the prioritization is fake.

**Salesforce-specific story granularity:** state the *config artifact* so an admin vs. developer can estimate. "Add field X (text, max N) to object Y, FLS on permset Z, surface on layout/Quick Action W" is estimable; "make the form capture X" is not. Any story that adds a field also has a downstream chain (schema/validation, UI, security, tests) that must be named to be estimable.

**Verification step:** Before sizing a story that touches a field, describe the target object to confirm the field's real type, length, and whether it already exists. Stories that "add" an existing field, or assume a wrong type, blow estimates.

---

## 3. Customer Discovery (17%)

**Translate vague goals into measurable success criteria before design.** "We want less data entry" → "reduce volunteer keying time per record from ~15 min to 0; eliminate transcription errors; give applicants self-service status." If you can't attach a number or a yes/no outcome, keep digging.

**Do a real current-state assessment of the actual org — don't assume.** Inventory: installed managed packages (note their namespaces), the live data model, active automations (workflow rules, flows, triggers, process builders), integrations, and data quality. **Rule:** enumerate active automations on any object you plan to write to, because side effects are invisible until they bite — a managed-package workflow rule can silently corrupt data on insert, and only a current-state automation audit catches it.

**Categorize every gap** (Config / Customization / Third-party / Process change) and prefer config over code over package over custom integration, ascending cost/risk — only escalate when the lower-cost option fails non-functional requirements (volume, security, audit). Choose Apex over Flow when managed-package side effects require it. Full gap-type table and implementation lifecycle phase map (Discovery → Design → Build → Test → Train → Deploy → Operate) with BA ownership per phase: [references/change-management.md](references/change-management.md) — load when sizing a discovery or scoping build paths.

**Scope discipline:** write down what is explicitly *out*. A scope statement without an out-of-scope list invites scope creep.

**Anti-patterns / red flags:**
- Assuming the org is a clean slate. Managed-package orgs are opinionated: a package like NPSP adds auto Household Accounts, Relationships, Affiliations, and hidden workflow rules so that a requirement like "just create a Contact" hides significant side effects. Always audit managed-package automation before scoping. See [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md) for NPSP specifics.
- Promising a cloud/feature you haven't verified is licensed/enabled in the org.

**Verification step:** List the real object inventory; describe core objects (e.g. `Contact`) to see real fields and record types before scoping anything that touches them.

---

## 4. Requirements (17%)

**Know which artifact you owe, and don't blur them.** Requirements = the *what* (business-owned contract). User stories = the *what, from the user's perspective, sized for a sprint*. **Decision rule:** use a formal Business Requirements Document / Functional Spec when the environment is regulated, fixed-price, or audited; use a story backlog when delivery is agile and the team is trusted.

**Classify every requirement, because the class determines who validates it:**

| Class | Definition | Owner / validator |
|---|---|---|
| Business | What the org needs to achieve | Sponsor |
| Functional | What the system must do | BA + users (UAT) |
| Non-functional | How well — performance, security, availability, accessibility | BA + technical + security |
| Technical/constraint | Implementation limits (e.g. "must use SSM, not Secrets Manager") | Architect/dev |

**Non-functional requirements are where projects live or die — capture them explicitly.** Common examples: PII/medical-data handling (no PII in logs, files in object storage only), accessibility for elderly users on shared devices (44px tap targets, no off-viewport buttons), audit trail on every write, and API throttling. A functional requirement that ignores these will pass a demo and fail go-live.

**Give every requirement manageable metadata:** unique ID, priority (MoSCoW), status, owner, source (which stakeholder/interview), and an acceptance-test reference. Without a source you can't go back and ask "did we hear this right?"; without a test reference you can't prove it's met.

**Verification vs. validation — keep them straight:**
- **Verification** = "did we build it to spec?" (QA/system test, against acceptance criteria).
- **Validation** = "is the spec the right spec?" (UAT, business confirms it solves the real need).
A solution can pass verification and fail validation — a feature built exactly to spec can still miss the real need that only surfaces by validating against the actual workflow.

**Maintain traceability:** requirement → user story → test case → defect. When a field changes, you must be able to see everything downstream. A typical concrete trace is: SF field metadata → generated schema constants → validation schema → form field → automated test. Breaking that chain (e.g. hand-editing a generated file) breaks traceability.

**Anti-patterns / red flags:**
- A requirement phrased as a solution ("add a trigger") instead of a need ("on approval, the person must exist as a Contact").
- No change-request / impact-analysis process — changes land without anyone checking downstream stories and tests.
- Requirements that silently assume a field length; enforce lengths from the org's real field metadata, not guesses, because last-resort code-side truncation otherwise loses data silently.

**Verification step:** Describing an object returns each field's real `length`, `type`, `picklistValues`, and `required` flag — use it to validate that a documented requirement matches the org, especially max-length and picklist-value requirements.

---

## 5. Business Process Mapping (16%)

**Map as-is before to-be, with SMEs, in a swimlane.** Lanes = actors (end user, intake volunteer, data-entry volunteer, Salesforce, staff reviewer). Capture handoffs, bottlenecks, manual workarounds, and the **exception paths SOPs never mention** (incomplete submission, illegible document, applicant with no email).

**Keep the to-be map at the business level.** It shows *what changes and who benefits*, not a click-by-click Salesforce walkthrough — otherwise stakeholders can't read it and it rots the moment a button moves.

**Mine the map for configuration requirements:**
- Decision diamonds → validation rules, flow decision elements, approval criteria.
- Swimlane handoffs → automation triggers and integration boundaries.
- Data-entry steps → fields and page layouts.
- Reporting extraction points → report/dashboard requirements.

**Decision rule for the automation tool the process implies** (the BA should recommend, the admin/dev confirms):

| Need | Tool | Don't use because |
|---|---|---|
| Block bad data at save | Validation rule | A flow for this is overkill and slower |
| No-code record automation, multi-step, async, scheduled | Flow (Record-Triggered / Screen / Scheduled) | Workflow rules and Process Builder are retired for new work |
| Complex logic, bulk DML, callouts, transaction control, managed-package side-effect orchestration | Apex trigger/class | Flow can't safely bulk-orchestrate managed-package side effects |
| Multi-stage human sign-off | Approval Process / Flow approval | Hand-rolling status picklists loses audit trail |

**Anti-patterns / red flags:**
- A to-be map with no exception/unhappy paths — go-live will hit them on day one.
- Mapping the SOP instead of reality (people don't follow the SOP — observe).
- A process map that isn't version-controlled alongside the requirement that drove it.
- Recommending workflow rule / Process Builder for *new* automation — both are retired; flow or Apex.

**Verification step:** Before mapping a "future state" that adds automation, audit what already fires on the object (relationships, record types, existing automations) and confirm with the team — an unmapped existing automation can sabotage the to-be process.

---

## 6. User Acceptance Testing (8% — smallest weight, highest stakes)

**Write a UAT plan with explicit entry and exit criteria.** Entry: build is feature-complete, in a representative environment (sandbox), test data loaded, testers trained. Exit: all Must-have scenarios pass; no open blocker/critical defects; known issues documented with agreed workarounds; business sign-off recorded.

**UAT is not QA.** QA/system testing (verification) is technical: does it match spec? UAT (validation) is the *business* confirming it solves the real need, performed by real users on real scenarios. The BA facilitates; the business signs.

**Derive test cases straight from stories' acceptance criteria.** One scenario per story, each covering happy path, sad path, and edge cases. Structure: precondition → steps → expected result → actual result → pass/fail.

**Classify defects on two axes and don't conflate them:** **Severity** (technical impact: blocker/critical/major/minor/cosmetic) vs. **Priority** (business urgency to fix). A cosmetic typo on a consent page can be high priority; a rare edge-case crash can be low. Triage on both.

**Prepare test data that exercises business rules without exposing production PII.** Use a sandbox (Developer/Developer Pro/Partial/Full), never prod. Include boundary data: a date that looks valid but isn't (e.g. 2026-02-31), max-length strings, and picklist values the form offers vs. the values a *restricted* picklist actually accepts.

**Manage scope during UAT.** When a tester says "it should also do Y," decide: is Y a **defect** (fails an existing acceptance criterion) or a **new requirement** (change request, separate backlog item)? Logging new requirements as defects is the #1 way UAT slips.

**Issue a risk-based go/no-go, not a binary gut call.** Aggregate: count open defects by severity, map each known issue to a documented workaround, weigh against launch deadline. **Go** = no open blockers/criticals, Musts pass, workarounds agreed. **No-go** = any open blocker, or a Must scenario failing. Record the decision, the residual risks, and who accepted them.

**Plan regression awareness:** a fix can break a previously passing scenario. After any fix, rerun the impacted scenarios.

**Anti-patterns / red flags:**
- Running UAT in production.
- Testers signing off without exit criteria written down — sign-off then means nothing.
- Defects logged without repro steps — a dev can't fix what they can't reproduce.
- Treating "all tests pass" as "validated" when the tests only cover the happy path.

**Verification step:** After a UAT cycle that created/changed SF records in sandbox, confirm the actual outcome by querying the records — verify they landed with the right field values, role flags, and status, rather than trusting the UI screen the tester saw.

---

## Executable Workflows

### Workflow 1 — Elicit → write → size a user story to UAT-ready (INVEST + Given/When/Then)

1. Conduct the elicitation session (interview or workshop). Capture the raw need — do not propose a solution during elicitation.
   → gate: a documented need statement with a named stakeholder source, not a solution description.
2. Draft the story in canonical form: "As a [persona], I want [capability] so that [business value]." Confirm the "so that" is a real business outcome, not a restatement of the want.
   → gate: story passes the INVEST gate (Independent, Negotiable, Valuable, Estimable, Small, Testable).
3. Describe the target Salesforce object(s) in the live org to confirm field types, lengths, and whether required fields already exist. Adjust the story scope to reflect reality (don't write a story to "add" a field that already exists).
   → gate: story references actual field API names and confirmed data types; no mismatched type assumptions.
4. Write acceptance criteria in Given/When/Then form — one criterion per testable outcome, covering happy path, sad path, and at least one edge case (boundary value, missing data, restricted picklist value).
   → gate: every criterion can be answered pass/fail with no ambiguity; team confirms criteria are testable.
5. Size the story with the delivery team. If the team can't estimate, the story is too vague or too large — split by workflow step, data variation, or user role.
   → gate: story has a point estimate; no "too big to estimate" verdict remains unresolved.
6. Confirm the story has a traceability link: requirement ID → story → at least one acceptance criterion that becomes a UAT test case.
   → gate: traceability row exists in the tracking artifact before the story enters a sprint.

---

### Workflow 2 — Run UAT to a go/no-go decision

1. Before UAT begins, confirm entry criteria are met: build is feature-complete in the sandbox, test data loaded (boundary data included, no production PII), testers trained, exit criteria written and agreed.
   → gate: all entry criteria checked off and signed by the BA and project lead.
2. Derive test cases directly from stories' acceptance criteria (Given/When/Then → precondition/steps/expected result/actual result/pass-fail). Assign each test case to a named tester.
   → gate: one test case per acceptance criterion; happy path, sad path, and edge cases all have cases.
3. Execute UAT. For every failed case, log a defect with: repro steps, severity (blocker/critical/major/minor/cosmetic), and priority (business urgency). Classify tester "also do Y" requests as change requests — not defects.
   → gate: every open item is classified as defect or change request; no unclassified findings remain open.
4. After each fix, rerun impacted test cases (regression check). Do not close a defect until the retest passes.
   → gate: retest result recorded for every defect marked resolved.
5. At exit gate: aggregate open defects by severity. Apply the go/no-go rule: no open blockers or criticals; all Must-have scenarios pass; any remaining known issues have agreed workarounds documented and accepted in writing by the business Accountable.
   → gate: go/no-go decision recorded with named decision-maker, residual risks list, and date.
6. After go-live, query the sandbox or production records to confirm data actually landed with correct field values — don't rely solely on the UI screen testers saw.
   → gate: SOQL confirms records have correct status, role flags, and field values as expected.

---

### Workflow 3 — Map current → future-state process (swimlane + RACI)

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

## Decision Scenarios

Five original scenarios. Scenarios 3–5 are in [references/scenarios.md](references/scenarios.md) — load them for UAT defect-vs.-new-requirement classification, requirement phrased-as-solution rewrites, or to-be process verification examples.

---

**Scenario 1 — Automation audit before writing a requirement (Customer Discovery)**

> *This scenario illustrates the general "automation audit before requirements" rule (§3 / Quick Reference 11) using NPSP as a concrete example. The same principle applies to any managed-package org; see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md) for NPSP details.*

> **Situation:** A stakeholder asks the BA to write a requirement: "When a volunteer applicant is approved, create a Contact in Salesforce." The BA has assessed the org and confirmed it runs NPSP. The developer says "a flow that calls `Contact.insert` is straightforward."

> **Competent move:** Before writing or sizing any story, the BA runs an automation audit on the Contact object in the org — listing active workflow rules, flows, process builders, and triggers. In an NPSP org this will surface at minimum the `npe01__PreferredPhone__c` workflow rule and Household Account auto-creation logic. The requirement is then written to include these side effects as constraints: "Creating a Contact triggers Household Account creation and managed-package phone-copy logic; the implementing solution must account for these and must not disable managed-package rules to work around them."

> **Tempting-but-wrong:** Accepting the developer's estimate and writing the requirement as "insert a Contact" — treating NPSP as if it were a clean org. The managed-package workflow rule fires on every Contact insert, silently copying `Phone` to `MobilePhone`, and Household Account creation adds unintended records.

> **Verify:** In the target org, open Setup → Process Automation → Workflow Rules, filter by Contact, confirm which rules are Active. Also open Flow Builder, filter trigger type = Record-Triggered, object = Contact. List what fires before writing the requirement.

---

**Scenario 2 — MoSCoW prioritization is fake (User Stories)**

> **Situation:** The BA has facilitated a backlog grooming session. The team has labeled 38 of 45 stories as "Must." The project sponsor confirms: "They all need to be in the first release."

> **Competent move:** Flag the prioritization as non-functional. When >60% of the backlog is Must, the MoSCoW exercise has produced a wish list, not a priority order. The BA facilitates a forced-ranking re-prioritization: present the sprint capacity (e.g. 40 story points per sprint, 3 sprints before launch), show the 38 "Must" stories' point totals, and ask the sponsor to choose which 38-minus-N to defer if the team hits the wall. This converts abstract "Must" labels into a real launch scope decision that the sponsor owns.

> **Tempting-but-wrong:** Accepting the sponsor's word that everything is Must and carrying 38 Must stories into the sprint plan. When the team can't complete them all, the BA has no agreed deferral list — leading to a chaotic last-week triage where the team (not the business) decides what ships.

> **Verify:** Count Must stories, sum their estimates, divide by sprint velocity. If Must stories exceed capacity before go-live, the prioritization is arithmetically impossible — document that calculation and present it to the sponsor before sprint planning begins.

---

## Operational Rules Quick Reference

Read this first. Each rule is imperative and concrete.

1. **DO** map stakeholders on a power/interest grid before the first workshop; the person who can veto the build is a primary stakeholder and must sign off.
2. **DO** keep exactly one Accountable per decision in the RACI; two Accountables is a defect — escalate.
3. **DO** match elicitation method to the source: interview for tacit knowledge, observation when reality ≠ SOP, workshop for conflict, survey for breadth.
4. **DON'T** design the solution inside a requirements interview — extract the need, not a pre-committed build.
5. **DO** keep a living decision log and RAID log.
6. **DO** write every story as "As a [persona], I want [capability] so that [value]" — without "so that," it's a task, not a story.
7. **DO** gate stories with INVEST; split oversized stories by workflow step, data variation, role, or happy-path-then-exception — never arbitrarily.
8. **DO** write acceptance criteria in Given/When/Then so each one converts 1:1 into a UAT test case.
9. **DON'T** let >60% of the backlog be "Must" — that's fake MoSCoW prioritization.
10. **DO** translate vague goals into measured success criteria before any design.
11. **DO** audit all active automations on an object before writing to it — managed-package workflow rules can cause silent data corruption.
12. **DO** categorize each gap as config / customization / package / process; prefer the lowest-cost option that still meets non-functional requirements.
13. **DON'T** assume a managed-package org is a clean slate — Contact creation can trigger managed-package side effects (e.g. NPSP auto-creates Household Accounts and fires workflow rules; see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md)).
14. **DO** classify requirements (business / functional / non-functional / technical) and capture non-functionals explicitly (PII handling, accessibility, audit, throttling).
15. **DON'T** phrase a requirement as a solution ("add a trigger"); phrase the need ("on approval the person must exist as a Contact").
16. **DO** maintain traceability: requirement → story → test → defect; never break the chain (e.g., hand-editing a generated schema file).
17. **DO** map as-is before to-be, in swimlanes, including exception/unhappy paths SOPs omit.
18. **DON'T** recommend workflow rules or Process Builder for new automation — both are retired; use Flow or Apex.
19. **DO** use a validation rule to block bad data, Flow for no-code automation, Apex for bulk/side-effect orchestration.
20. **DO** distinguish verification (built to spec) from validation (right spec); a build can pass one and fail the other.
21. **DO** run UAT in a sandbox with boundary test data; **NEVER** run UAT against production.
22. **DO** triage defects on severity AND priority separately; classify tester asks as defect vs. new requirement (change request).
23. **DO** issue a risk-based go/no-go: no open blockers/criticals, Musts pass, workarounds agreed and accepted in writing.
24. **DO** verify every claim against the live org (describe objects, list objects, run queries/reports, fetch records) before trusting it — confirm field types, lengths, picklists, and that records actually landed.
25. **DO** identify change-impact by role before go-live; schedule training within 2 weeks of launch; define adoption metrics upfront (login rate, record creation rate, field fill-rate).
26. **DON'T** resolve conflicting stakeholder requirements unilaterally — surface the conflict, bring both parties to a decision meeting, record who made the call.
27. **DON'T** accept verbal scope-change approval — any requirement that changes the agreed scope boundary requires a written change request.

---

## References

- [references/study-resources.md](references/study-resources.md) — credential logistics and study path.
- [references/scenarios.md](references/scenarios.md) — Decision Scenarios 3–5: UAT defect vs. new requirement, requirement phrased as solution, to-be verification.
- [references/change-management.md](references/change-management.md) — extended change management and scope escalation operational guidance; load when advising on go-live change planning, training design, or conflicting-stakeholder escalation paths.

For NPSP/nonprofit-specific operational guidance, see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md).

---

## Feedback protocol

Using this skill and hit a wall? If you find a claim contradicted by the live system or official docs, a missing rule that cost you a wrong attempt, or a decision this skill gave no criteria for — append an entry **in the moment** to `.skill-feedback/salesforce-business-analyst.md` at the project root (create it if absent):

`date | skill last-reviewed | claim or gap | what you observed instead | evidence (error text / doc URL / query output) | suggested fix`

These are harvested back into the skill via the learning loop. When the live system and this file disagree, trust the live system.

---

## Changelog

- **2026-06-09** — Conformed to the 12-dimension skill standard: task-vocab description + Scope block, Uncertainty & Escalation guidance with inline `[volatile — verify live]` marks, executable workflows, tool-agnostic verify steps, and the feedback protocol above. Exam logistics relocated to references/study-resources.md; `last-reviewed` set to 2026-06-09.

---

*Independent educational content to upskill AI agents. Not affiliated with or endorsed by Salesforce, Inc.; all trademarks — including "Salesforce," "Salesforce Certified Business Analyst," and related marks — belong to their respective owners. Content is provided as guidance only; verify all details against official Salesforce documentation, the current exam guide, and your live org before acting. No certification outcome is implied or guaranteed.*
