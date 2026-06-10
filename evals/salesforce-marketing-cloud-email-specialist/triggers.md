# Trigger tests — salesforce-marketing-cloud-email-specialist (Lens 2)

Routing regression set. Test each phrasing against skill DESCRIPTIONS only. Each routes to exactly one skill.

## Should route to salesforce-marketing-cloud-email-specialist (5)

1. "Design a welcome Journey in Journey Builder for new subscribers: a day-0 welcome email, a day-3 nurture email, and a day-7 offer — and flag the re-entry and double-welcome traps."
2. "Our IP reputation tanked after a large send. Walk me through an IP warming schedule and the SPF/DKIM/DMARC records we need to verify before the next campaign."
3. "We need to segment our appeal audience with a SQL Query activity in Automation Studio and send via a User-Initiated Send. What are the sequencing and Data Extension traps to avoid?"
4. "Set up Marketing Cloud Connect so our Salesforce CRM Contacts sync to SFMC and we can segment by CRM fields in a Journey. What are the sync-field and data-view gotchas?"
5. "Our AMPscript personalization block is rendering blank for a subset of subscribers even though the Data Extension has values for them. Help me debug the LookupRows logic."

## Near-misses → a sibling (3)

1. "Configure an email alert in Salesforce that fires when a sales rep closes an Opportunity, using an HTML email template with the deal details." → `salesforce-administrator`  (this is a core-CRM workflow/Flow email alert using a Salesforce Classic/Lightning email template — not SFMC Journey Builder or Content Builder)
2. "Build an Agentforce Sales Email prompt template that drafts a follow-up email to a prospect based on the Opportunity record fields." → `salesforce-agentforce-specialist`  (this is a Prompt Builder Sales Email template within Agentforce, not an SFMC email campaign or journey)
3. "We use Pardot (Account Engagement) for lead nurturing. Set up a prospect engagement score and an email drip sequence for our webinar registrants." → not marketing-cloud-email-specialist  (Pardot/Account Engagement is a separate product from SFMC; this routes outside the marketing-cloud-email-specialist scope which covers the SFMC Studio/Builder stack)
