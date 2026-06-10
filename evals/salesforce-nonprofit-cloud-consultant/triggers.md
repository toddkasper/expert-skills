# Trigger tests — salesforce-nonprofit-cloud-consultant (Lens 2)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

Routing regression set. Test each phrasing against skill DESCRIPTIONS only. Each routes to exactly one skill.

## Should route to salesforce-nonprofit-cloud-consultant (5)

1. "Configure Recurring Donations in NPSP for a monthly giving program, including the Household Account model and the rollup fields that track lifetime giving — and flag the double-count trap."
2. "Our NPSP org shows zero lifetime giving for donors we bulk-loaded last week via Data Loader. TDTM was active during the load. What happened and how do we fix the rollup totals?"
3. "We are implementing Industries Nonprofit Cloud and need to set up Program Enrollment records linked to a mental-health program, with outcome measurement forms for each session."
4. "A major donor's Contact record has both a hard credit and a soft credit Opportunity for the same gift. Walk me through whether that is correct in NPSP and what the reporting impact is."
5. "Decide whether this org is running NPSP or Nonprofit Cloud (Industries) and explain which recurring-gift object we should use to create a new monthly pledge."

## Near-misses → a sibling (3)

1. "Build an Apex trigger handler on the Opportunity object that fires after insert to create a follow-up Task for the assigned development officer." → `salesforce-platform-developer-1`  (Apex trigger/handler code is platform developer scope, not the nonprofit data model or TDTM layer — even though Opportunities are central to fundraising)
2. "Configure a donor self-service portal where constituents can log in, update their contact info, and view their giving history." → `salesforce-experience-cloud-consultant`  (external portal license selection, sharing sets, and guest-user model are Experience Cloud scope, even though the data is NPSP donor records)
3. "Set up a duplicate rule and matching rule on the Contact object to prevent staff from creating duplicate donor records when entering gifts." → `salesforce-administrator`  (duplicate/matching rule configuration is general declarative admin scope; the nonprofit data model is not involved unless NPSP-specific dedup logic is in question)
