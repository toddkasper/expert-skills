# Business Analyst Decision Scenarios — Extended Set

> Overflow scenarios from SKILL.md. Load when working through UAT defect-vs.-new-requirement classification, requirements phrased as solutions, or to-be process verification before a design session.

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
