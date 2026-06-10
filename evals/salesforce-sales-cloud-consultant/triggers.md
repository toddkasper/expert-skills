# Trigger tests — salesforce-sales-cloud-consultant (Lens 2)

Routing regression set. Test each phrasing against skill DESCRIPTIONS only. Each routes to exactly one skill.

## Should route to salesforce-sales-cloud-consultant (5)

1. "We need to set up territory management so each rep only sees accounts in their assigned region and forecasts roll up by territory hierarchy."
2. "Our collaborative forecast totals are off — manager adjustments at one level aren't propagating up to the VP layer. Walk me through what to check."
3. "Design the lead assignment rules and lead conversion field mapping for this B2B spec, and flag any deduplication pitfalls before we go live."
4. "We want to activate Einstein Opportunity Scoring for our 20-person team that has been live eight months. What data prerequisites do we need?"
5. "A nightly integration syncing Sales Orders to a restricted picklist field is failing with a field-level error even though the integration user has FLS edit on the field. What is wrong?"

## Near-misses → a sibling (3)

1. "Set up escalation rules and entitlement milestones so cases breaching SLA automatically move to a senior queue." → `salesforce-service-cloud-consultant`  (entitlements/milestones are Service Cloud SLA mechanics, not Sales Cloud pipeline)
2. "Configure a partner portal so resellers can log in, register deals, and see only their own opportunities." → `salesforce-experience-cloud-consultant`  (external portal license selection, sharing sets, and guest-user model are Experience Cloud scope, even though Opportunities are involved)
3. "Add a validation rule to the Opportunity object and set up duplicate matching rules for Accounts across the org." → `salesforce-administrator`  (general declarative org config — validation rules and duplicate management — not Sales Cloud pipeline design or forecasting)
