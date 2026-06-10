---
name: salesforce-business-analyst
description: Salesforce business-analysis work — eliciting and documenting requirements, writing and sizing user stories (INVEST, Given/When/Then, MoSCoW), facilitating stakeholder workshops and discovery, mapping current/future-state processes (swimlanes, RACI, RAID), defect triage, and running user acceptance testing to a go/no-go decision. Use when gathering requirements, mapping process, or driving UAT on a Salesforce project. This is the requirements/process discipline — not building the config or code (see salesforce-administrator and the platform-developer skills). Scoped and benchmarked by the Business Analyst (BA-201) blueprint.
metadata:
  credential: Salesforce Certified Business Analyst
  exam-code: BA-201
  domain: salesforce
  type: certification-playbook
---

# Salesforce Business Analyst — Skills Reference

## Overview

The Salesforce Certified Business Analyst credential (exam code BA-201) validates that a practitioner can act as the liaison between business stakeholders and the technical team implementing a Salesforce solution. Certified BAs elicit and document business needs, translate them into well-formed requirements and user stories, map current and future-state processes, facilitate collaboration across stakeholder groups, and guide user acceptance testing through to a go-live decision.

This file is an **operational playbook**, not an exam outline. Each section below states the rules a BA actually applies at decision time — when to write a requirement vs. a user story, how to size a story, what makes acceptance criteria testable, how to run UAT to a defensible go/no-go — plus the anti-patterns to catch in review and the way to verify against the live org before trusting any assumption. The recurring discipline throughout is to confirm org reality (objects, fields, picklists, active automations) before committing to a requirement or estimate.

> **Deeper context:** Study resources and the NPSP/nonprofit relevance notes live in [references/study-resources.md](references/study-resources.md) (loaded on demand). For org-specific applications of these rules, see a per-org appendix you maintain in your own project, referenced from a CLAUDE.md.

---

## Exam Details

| Field | Value |
|---|---|
| Exam Name | Salesforce Certified Business Analyst |
| Exam Code | BA-201 |
| Questions | 60 scored + up to 5 unscored pretest = up to 65 total |
| Time Limit | 105 minutes |
| Passing Score | 72% |
| Cost | US$200 registration + applicable tax; $100 retake fee |
| Prerequisites | None (the formerly required Administrator certification was dropped as a hard prerequisite on May 2, 2023) |
| Retake Policy | Half-price ($100) retakes; up to three attempts per release cycle |

**Recommended experience:** 2+ years hands-on Salesforce platform experience and 2+ years functioning as a business analyst on real implementations.

**Delivery:** Proctored online or in-person at a Kryterion test center. No reference materials permitted.

**Maintenance:** Annual release-specific Trailhead maintenance module (one per year, free).

**Domain weights (60 scored questions; each point ≈ 0.6 questions):** Collaboration with Stakeholders 24% · User Stories 18% · Customer Discovery 17% · Requirements 17% · Business Process Mapping 16% · User Acceptance Testing 8%.

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

**Do a real current-state assessment of the actual org — don't assume.** Inventory: installed managed packages (e.g. NPSP `npe01`/`npe5`/`npo02` namespaces), the live data model, active automations (workflow rules, flows, triggers, process builders), integrations, and data quality. **Rule:** enumerate active automations on any object you plan to write to, because side effects are invisible until they bite — a managed-package workflow rule can silently corrupt data on insert, and only a current-state automation audit catches it.

**Categorize every gap so the build path is obvious:**

| Gap type | Resolution | Cost/risk |
|---|---|---|
| Config | Point-and-click (field, layout, validation rule, flow) | Low |
| Customization | Apex / LWC / integration | High; needs dev + tests |
| Third-party | AppExchange package | License cost + package side effects |
| Process change | Train people, change behavior | No code; hardest to adopt |

**Decision rule:** prefer config over code over package over custom integration, ascending cost/risk — but only if the lower-cost option meets the *non-functional* requirements too (volume, security, audit). Choose Apex over a flow when record creation has managed-package side effects a flow can't safely orchestrate.

**Know the implementation lifecycle and the BA's job in each phase:** Discovery → Design → Build → Test → Train → Deploy → Operate. The BA owns Discovery and Requirements, co-owns Design (translates), drives UAT in Test, leads Train, advises the go/no-go in Deploy.

**Scope discipline:** write down what is explicitly *out*. A scope statement without an out-of-scope list invites scope creep.

**Anti-patterns / red flags:**
- Assuming the org is a clean slate. NPSP is opinionated: Contact-centric, auto Household Accounts, Relationships, Affiliations. A requirement that says "just create a Contact" hides Household auto-creation and managed workflow side effects.
- Promising a cloud/feature you haven't verified is licensed/enabled in the org.

**Verification step:** List the real object inventory; describe core objects (e.g. `Contact`) to see real fields and record types; review the NPSP data shape (Households, Opportunities) before scoping anything that touches them.

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

**Map as-is before to-be, with SMEs, in a swimlane.** Lanes = actors (end user, intake volunteer, data-entry volunteer, Salesforce, staff reviewer). Capture handoffs, bottlenecks, manual workarounds, and the **exception paths SOPs never mention** (incomplete submission, illegible document, applicant with no email). A backend pipeline (form POST → storage snapshot → sweep job → SF upsert → approval → Contact create → downstream assignment) is a swimlane expressed in code; a BA should be able to draw it both ways.

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

**Derive test cases straight from stories' acceptance criteria.** One scenario per story, each covering happy path, sad path, and edge cases. Structure: precondition → steps → expected result → actual result → pass/fail. An automated e2e harness with one fixture per scenario is this layer automated.

**Classify defects on two axes and don't conflate them:** **Severity** (technical impact: blocker/critical/major/minor/cosmetic) vs. **Priority** (business urgency to fix). A cosmetic typo on a consent page can be high priority; a rare edge-case crash can be low. Triage on both.

**Prepare test data that exercises business rules without exposing production PII.** Use a sandbox (Developer/Developer Pro/Partial/Full), never prod. Include boundary data: a date that looks valid but isn't (e.g. 2026-02-31), max-length strings, and picklist values the form offers vs. the values a *restricted* picklist actually accepts (a classic source of silent UAT failures).

**Manage scope during UAT.** When a tester says "it should also do Y," decide: is Y a **defect** (fails an existing acceptance criterion) or a **new requirement** (change request, separate backlog item)? Logging new requirements as defects is the #1 way UAT slips.

**Issue a risk-based go/no-go, not a binary gut call.** Aggregate: count open defects by severity, map each known issue to a documented workaround, weigh against launch deadline. **Go** = no open blockers/criticals, Musts pass, workarounds agreed. **No-go** = any open blocker, or a Must scenario failing. Record the decision, the residual risks, and who accepted them.

**Plan regression awareness:** a fix can break a previously passing scenario. After any fix, rerun the impacted scenarios — in a mature setup that means re-running the automated test harness.

**Anti-patterns / red flags:**
- Running UAT in production.
- Testers signing off without exit criteria written down — sign-off then means nothing.
- Defects logged without repro steps — a dev can't fix what they can't reproduce.
- Treating "all tests pass" as "validated" when the tests only cover the happy path.

**Verification step:** After a UAT cycle that created/changed SF records in sandbox, confirm the actual outcome by querying the records — verify they landed with the right field values, role flags, and status, rather than trusting the UI screen the tester saw.

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
13. **DON'T** assume NPSP is a clean slate — Contact creation triggers Household Accounts, Relationships, and managed-package side effects.
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

---

## 7. Change Management & Training (BA's role in the Deploy and Operate phases)

The BA's job does not end at UAT sign-off. The credential and real implementations expect a BA to:

**Identify who changes and how much.** Before go-live, map each affected role to the process steps that change. End users who need to learn a new screen have lower change impact than staff whose entire data-entry workflow is eliminated. Score each group on impact and readiness — high impact / low readiness = intensive training; low impact / high readiness = job aid.

**Author training artifacts at the right level.** Write quick-reference guides (job aids) for frequent tasks; leave system administration topics to the admin. A job aid for an intake volunteer should describe their new Salesforce screen workflow, not how approval processes work internally.

**Define adoption metrics upfront, before launch.** "Adoption" is measurable: login rate, record creation rate, picklist fill-rate on required fields. Without a baseline and a target, you can't tell whether training succeeded or the change failed.

**Anti-patterns / red flags:**
- Scheduling training more than two weeks before go-live — users forget.
- One-size-fits-all training when roles have very different workflows.
- No feedback loop after go-live — the BA should collect post-launch friction and convert it to change-request stories.

---

## 8. Conflicting Stakeholder Requirements & Scope Escalation

When two stakeholders give incompatible requirements, the BA's job is to surface the conflict explicitly — not to resolve it unilaterally.

**Resolution path:**
1. Document both positions neutrally in the RAID log (as an Issue).
2. Bring both stakeholders into a decision meeting; use the power/interest grid to identify who holds Accountability.
3. Present the tradeoffs (not a recommendation disguised as information).
4. Record the decision, rationale, and who made it in the decision log — even if a senior stakeholder overrules a process expert.

**Scope escalation trigger:** any requirement that changes the agreed-upon scope boundary — new objects, new integrations, new record types, expanded user base — must go through a formal change-request. A verbal "can we also add X?" from a stakeholder in a UAT session is not scope approval.

**Anti-patterns / red flags:**
- The BA picks the "better" requirement without escalating — transfers risk silently.
- The change request is approved verbally but not in writing — leads to "I never agreed to that" at go-live.
- Scope changes that are logged as defects to avoid a change-request process — they look like bugs but are net-new features.

---

## Decision Scenarios

Five original scenarios covering the skill's highest-value operational gotchas. Each is concrete and independently authored.

---

**Scenario 1 — Automation audit before writing a requirement (Customer Discovery)**

> **Situation:** A stakeholder asks the BA to write a requirement: "When a volunteer applicant is approved, create a Contact in Salesforce." The BA has assessed the org and confirmed it runs NPSP. The developer says "a flow that calls `Contact.insert` is straightforward."

> **Competent move:** Before writing or sizing any story, the BA runs an automation audit on the Contact object in the org — listing active workflow rules, flows, process builders, and triggers. In an NPSP org this will surface at minimum the `npe01__PreferredPhone__c` workflow rule and Household Account auto-creation logic. The requirement is then written to include these side effects as constraints: "Creating a Contact triggers Household Account creation and managed-package phone-copy logic; the implementing solution must account for these and must not disable managed-package rules to work around them." That sentence prevents a silent data-corruption bug.

> **Tempting-but-wrong:** Accepting the developer's estimate and writing the requirement as "insert a Contact" — treating NPSP as if it were a clean org. The managed-package workflow rule fires on every Contact insert, silently copying `Phone` to `MobilePhone`, and Household Account creation adds unintended records. The UAT tester sees the Contact but misses the side effects; they surface post-go-live as data quality complaints.

> **Verify:** In the target org, open Setup → Process Automation → Workflow Rules, filter by Contact, confirm which rules are Active. Also open Flow Builder, filter trigger type = Record-Triggered, object = Contact. List what fires before writing the requirement.

---

**Scenario 2 — MoSCoW prioritization is fake (User Stories)**

> **Situation:** The BA has facilitated a backlog grooming session. The team has labeled 38 of 45 stories as "Must." The project sponsor confirms: "They all need to be in the first release."

> **Competent move:** Flag the prioritization as non-functional. When >60% of the backlog is Must, the MoSCoW exercise has produced a wish list, not a priority order. The BA facilitates a forced-ranking re-prioritization: present the sprint capacity (e.g. 40 story points per sprint, 3 sprints before launch), show the 38 "Must" stories' point totals, and ask the sponsor to choose which 38-minus-N to defer if the team hits the wall. This conversation converts abstract "Must" labels into a real launch scope decision that the sponsor owns.

> **Tempting-but-wrong:** Accepting the sponsor's word that everything is Must and carrying 38 Must stories into the sprint plan. When the team can't complete them all, the BA has no agreed deferral list — leading to a chaotic last-week triage where the team (not the business) decides what ships.

> **Verify:** Count Must stories, sum their estimates, divide by sprint velocity. If Must stories exceed capacity before go-live, the prioritization is arithmetically impossible — document that calculation and present it to the sponsor before sprint planning begins.

---

**Scenario 3 — UAT defect vs. new requirement (User Acceptance Testing)**

> **Situation:** During UAT, a tester reports: "When I save an application, it should also send an email confirmation to the applicant." No acceptance criterion in the story mentions email confirmation. The tester logs it as a blocker defect.

> **Competent move:** The BA classifies this as a new requirement, not a defect. A defect is a failure against an existing, agreed acceptance criterion. Email confirmation was never in the story's Given/When/Then criteria, so there is no criterion to fail. The BA closes the defect ticket, opens a change-request story ("As an applicant, I want an email confirmation on submission so that I know my application was received"), adds it to the backlog, and re-prioritizes it with the sponsor. It does not block go/no-go unless the sponsor escalates it to Must and there is sprint capacity to build it.

> **Tempting-but-wrong:** Logging it as a defect and putting it on the blocker list. This artificially holds the go/no-go for a net-new feature that was never scoped, inflating the defect severity count and giving stakeholders a misleading picture of the build's quality.

> **Verify:** Pull up the original user story and its acceptance criteria. If the expected behavior appears nowhere in Given/When/Then, it cannot be a defect — it is scope expansion.

---

**Scenario 4 — Requirement phrased as a solution (Requirements)**

> **Situation:** A stakeholder submits this requirement: "Add an Apex trigger on Opportunity that fires on before-insert and before-update to validate that Account is not null and set Stage to 'Prospecting' if blank."

> **Competent move:** Rewrite to the business need: "An Opportunity must always be associated with an Account (cannot be saved without one). Opportunities saved without a Stage value must default to 'Prospecting'." Then categorize: the Account constraint is likely a validation rule (config); the Stage default is a field default or a flow (config). No Apex is required. The BA documents the business rule, not the implementation, so the admin can choose the lowest-cost config option that meets it.

> **Tempting-but-wrong:** Accepting the Apex trigger requirement verbatim and sizing it as a development story. This locks in a high-cost solution (Apex = governor limits, bulkification, test coverage, deployment) for a problem solvable by validation rule + field default — a config-level solution with a fraction of the risk and cost.

> **Verify:** In the org, check whether the Account field on Opportunity is already required at the field or page-layout level. Check whether a field default is already set on Stage. The "problem" may not require any new config at all.

---

**Scenario 5 — Verification before to-be mapping (Business Process Mapping)**

> **Situation:** The BA is designing a future-state process that includes an automated approval routing step: when an application record reaches "Under Review" status, the flow should assign it to the next available reviewer. The sponsor confirms the org has "a flow for approvals" already.

> **Competent move:** Before drawing the to-be swimlane, the BA opens Flow Builder and the Approval Process setup in the actual org to enumerate what exists. "A flow for approvals" could mean a Screen Flow, a Record-Triggered Flow, or an Approval Process — they behave very differently. The BA documents what the existing automation actually does (object, trigger, actions, entry criteria) and then designs the to-be process around the real as-is state, not the sponsor's informal description.

> **Tempting-but-wrong:** Designing the to-be process from the sponsor's description and handing it to the developer. The developer discovers an existing Record-Triggered Flow on the same object with overlapping entry criteria — two flows in the same transaction fighting over the same record, causing duplicate assignments or governor limit errors.

> **Verify:** In the org, open Flow Builder → filter by object and trigger type; open Approval Processes → filter by object. List every active automation on the record type in scope before the to-be design session.

---

## Study resources & relevance

Study resources (official Salesforce + community) and the NPSP/nonprofit relevance notes are kept in [references/study-resources.md](references/study-resources.md) so this skill stays focused on operational rules. Load that file when planning a study path or mapping these rules to a nonprofit org.

---

*Independent educational content to upskill AI agents. Not affiliated with or endorsed by Salesforce, Inc.; all trademarks — including "Salesforce," "Salesforce Certified Business Analyst," and related marks — belong to their respective owners. Content is provided as guidance only; verify all details against official Salesforce documentation, the current exam guide, and your live org before acting. No certification outcome is implied or guaranteed.*
