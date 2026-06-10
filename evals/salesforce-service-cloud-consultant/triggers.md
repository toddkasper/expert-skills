# Trigger tests — salesforce-service-cloud-consultant (Lens 2)

Routing regression set. Test each phrasing against skill DESCRIPTIONS only. Each routes to exactly one skill.

## Should route to salesforce-service-cloud-consultant (5)

1. "Configure entitlement milestones and business-hours calendars so VIP cases escalate to a senior queue when the first-response clock hits 4 hours."
2. "Our Email-to-Case routing is creating duplicate cases instead of threading agent replies as comments. Walk me through the threading model and what is breaking."
3. "We need Omni-Channel routing to distribute cases to the right tier of agents based on skill and availability, with a fallback queue for overflow."
4. "Design the Knowledge base data-category structure and article record types for a two-tier support team that publishes both internal and external articles."
5. "Agents report that the Web-to-Case form stops accepting submissions mid-day. We think we are hitting a daily limit. How do we confirm and what is the cap?"

## Near-misses → a sibling (3)

1. "Build a customer self-service portal where logged-in users can open support tickets and track their case status without calling in." → `salesforce-experience-cloud-consultant`  (external-facing portal with authenticated users is Experience Cloud scope — license selection, sharing sets, and guest-user model — even though cases are involved)
2. "Create assignment rules that route new Leads to the right sales rep by territory and send an auto-response email to the prospect." → `salesforce-sales-cloud-consultant`  (lead assignment rules and lead auto-response are Sales Cloud mechanics, not case management)
3. "Set up escalation rules and workflow email alerts on the Case object so managers are notified when any case is open longer than 2 hours." → `salesforce-administrator`  (declarative escalation rule + workflow alert config is general admin scope; no entitlement process or SLA milestone design involved)
