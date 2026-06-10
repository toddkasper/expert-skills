# Application tasks — salesforce-business-analyst (Lens 4, held-out)

A skilled agent produces the artifact; a judge grades against the trap-keyed rubric. Run baseline vs skilled.

---

## Task 1 — User story authoring: vague stakeholder ask → INVEST stories with MoSCoW and org-reality checks

**Prompt to the agent:** A program director gave you the following notes from a requirements workshop. Transform this into well-formed INVEST user stories with Given/When/Then acceptance criteria, a MoSCoW priority call for each story, and a list of org-reality checks the BA must verify before committing these to the backlog. Do not write technical implementation details into the stories.

**Workshop notes (raw):**

> "We need a dashboard that shows the intake team how many applications are in each status. Also the team lead wants to be able to reassign applications from one case worker to another — maybe a button on the record or something. Oh and we need to make sure volunteers can't accidentally delete applications. And it should send an email to the applicant when their application status changes. We might also want to track how long each application spends in each status for reporting later — I know that's a big one. Also can we automatically convert the lead to a contact when the application is approved? That's a compliance thing, so it's mandatory."

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — Solutioning in requirements: the raw notes contain implementation hints ("a button on the record," "automatically convert the lead"). A competent BA strips implementation language from the story's user-need statement and captures it only in notes or discussion, not in the acceptance criteria. The stories must describe WHAT and WHY, not HOW. Any story that includes "button," "trigger," "Flow," or "Apex" in the acceptance criteria fails the INVEST Independent/Small test.
- [ ] Trap 2 — Fake all-Must MoSCoW: the director flagged the lead-conversion story as "mandatory / compliance," but at least two other asks (dashboard visibility, reassignment) are also framed as critical. A competent BA must challenge whether every item is truly Must, push back on "all Must" backlogs with scope/velocity math, and explicitly call out when a stated Must lacks a verifiable compliance citation that would confirm Must over Should. The output must include at least two Should or Could stories from this list and a brief rationale.
- [ ] Trap 3 — Untestable acceptance criteria: "the team lead wants to be able to reassign applications" is vague. Acceptance criteria must be specific, binary, and testable — e.g., "Given I am logged in as a Team Lead, When I open an Application record that is not in Closed status, Then I see a 'Reassign' option that allows me to select a different Case Worker from active users, And the Application owner field updates to reflect the new assignee." Any acceptance criterion containing "should work correctly," "as expected," or "easily" fails.
- [ ] Trap 4 — Missing org-reality automation audit: "send an email when application status changes" requires verifying whether an existing workflow rule, Process Builder, or Flow already sends emails on status change. Shipping a duplicate email automation is a classic BA miss. The org-reality checklist must include: (a) audit existing automation on Application__c for email sends on status change; (b) check email deliverability limits and existing email templates; (c) confirm the applicant Contact has a valid email field.
- [ ] Trap 5 — "Track how long each application spends in each status" is a significant hidden data model requirement (requires status history tracking or a custom History__c object). A competent BA must flag this as an epic requiring decomposition and a separate discovery spike, not a single story, and must note that standard field history tracking in Salesforce does not support duration calculations natively. Sizing it as a single story without that caveat misleads the team.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Produces 5–6 stories, each with a clean "As a [role], I want [need], so that [outcome]" format free of implementation language.
- Assigns MoSCoW with at least 2 Should/Could items and challenges the "compliance mandatory" label with a request for citation.
- Writes Given/When/Then ACs that are binary and testable (specific user, specific action, specific observable outcome).
- Includes an org-reality checklist covering: existing automation audit, field history tracking capability, lead conversion process existence, profile/permission model for volunteer delete restriction.
- Flags the status-duration story as an epic requiring a spike and data model discovery.

---

## Task 2 — UAT facilitation: defect triage and go/no-go recommendation

**Prompt to the agent:** You are the BA running UAT for the Application Intake project. Use the UAT results below to produce: (1) a defect triage with classification (blocker / major / minor / cosmetic) and recommended disposition for each, (2) a go/no-go recommendation with written justification, and (3) a post-launch risk register entry for any defect deferred to post-launch.

**UAT results (end of sprint 4, launch scheduled Friday):**

| # | Scenario | Priority | Result | Defect Description |
|---|----------|----------|--------|--------------------|
| 1 | Submit application with all required fields | Must | PASS | — |
| 2 | Submit application — attached document saved to record | Must | FAIL | Attachment silently drops when record is created via the intake Flow; no error message shown to user |
| 3 | Team lead reassigns application to new case worker | Must | PASS | — |
| 4 | Status-change email sent to applicant | Should | FAIL | Email sends correctly but the applicant name merge field shows "{!Contact.Name}" as literal text instead of the resolved value |
| 5 | Volunteer cannot delete an Application record | Must | PASS | — |
| 6 | Dashboard displays application counts by status | Should | PASS | — |
| 7 | Application record page loads in under 3 seconds | Could | FAIL | Page load averages 5.2 seconds in UAT sandbox; not tested in production-scale environment |

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — Scenario 2 (attachment silently drops) must be classified as a blocker, not merely major. Silent data loss with no user feedback on a Must-have scenario is a go-live blocker: users will submit applications believing attachments are saved when they are not, resulting in compliance and data integrity failures. Any recommendation to go-live with this defect deferred — without a full risk sign-off from the sponsor in writing — is incompetent. The BA's go/no-go must be NO-GO unless this is resolved.
- [ ] Trap 2 — Scenario 4 (merge field literal text in email) is classified as a Should-priority scenario. A competent BA must classify this as at minimum a major defect (not minor/cosmetic): sending emails with unresolved merge fields ("{!Contact.Name}") damages constituent trust, looks unprofessional, and may violate communication standards. The triage must flag this for resolution before launch even on a Should story, not defer it as cosmetic.
- [ ] Trap 3 — Scenario 7 (5.2-second page load, tested in sandbox only) cannot be validly triaged without noting the testing environment gap. Sandbox performance data is not representative of production. A competent BA must flag this defect as untriageable without a production-scale performance test and add a risk register entry for performance degradation at production load. Classifying it as minor based on sandbox data alone is a triage error.
- [ ] Trap 4 — The go/no-go recommendation must address sponsor override risk. If the sponsor says "go live anyway and fix in week 2," the BA's documented role is to record the decision, the identified risks (data loss on attachment, unresolved merge fields), and the names of who accepted those risks in writing. Simply acquiescing without documentation is a governance failure. The artifact must include a risk acceptance memo or risk register entry with owner and date.
- [ ] Trap 5 — Post-launch risk register entries must specify a measurable monitoring plan, not just list the deferred defect. For example, a deferred attachment defect risk entry must include: how staff will identify affected records (a report on Applications with zero ContentDocumentLinks), who is responsible, and the remediation SLA. A risk register entry that only says "attachment defect — fix in sprint 5" is incomplete.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Classifies Scenario 2 as a blocker with an explicit NO-GO recommendation and written justification referencing silent data loss.
- Classifies Scenario 4 as major (not cosmetic) and recommends resolution before launch.
- Flags Scenario 7 as untriageable without production-scale testing; adds a performance risk register entry.
- Documents sponsor override protocol: written risk acceptance with named owner, date, and scope of accepted risk.
- Produces a risk register entry for any deferred defect with a monitoring report, responsible owner, and remediation SLA.
