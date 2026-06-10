# Trigger tests — salesforce-business-analyst (Lens 2)

Routing regression set. Test each phrasing against skill DESCRIPTIONS only. Each routes to exactly one skill.

## Should route to salesforce-business-analyst  (5)

1. "Turn this stakeholder interview transcript into INVEST user stories with Given/When/Then acceptance criteria and a MoSCoW priority call for the next sprint"
2. "Facilitate a process-mapping session output: I have the swim-lane notes — help me write the current-state process map, RACI, and RAID log"
3. "Run the go/no-go UAT checklist for our release: three Must-have scenarios passed, one failed with a major defect — what is the competent call and how do I document it?"
4. "A stakeholder said 'make the grant application faster' — help me decompose this vague ask into measurable acceptance criteria the dev team can estimate"
5. "I need to write a requirements traceability matrix that links our business requirements to user stories, UAT scenarios, and sign-off status"

## Near-misses → a sibling  (3)

1. "Build the Flow automation that sends an email when an Application record moves to 'Approved' status" → `salesforce-administrator` (building the declarative config/automation, not gathering requirements or mapping process)
2. "Write the Apex class and trigger to enforce the business rule that an Application cannot be submitted without an attached document" → `salesforce-platform-developer-1` (building the code, not eliciting or documenting requirements)
3. "Configure the reports and dashboards so the Finance team can see grant disbursements filtered by region" → `salesforce-administrator` (configuring analytics in the org, not requirements/process/UAT discipline)
