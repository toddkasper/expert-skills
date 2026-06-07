# Eval situations — salesforce-nonprofit-cloud-consultant (held-out set, 2026-06-07)

Answer each: state the **competent action** and the **reason**. Be concise (2–4 sentences each).

1. A nonprofit org has NPSP installed. A new consultant logs in and is asked to configure a recurring gift for a major donor. The client calls the feature "Gift Commitments" and says their previous consultant set one up last year. Before creating any records, what must you verify, and how do you verify it?

2. A data migration team loaded 120,000 Contact records directly via Data Loader into an NPSP org with all TDTM handlers active. The load completed without API errors, but the development team now reports that rollup fields (`npo02__TotalOppAmount__c`) are all zero for the newly loaded donors. What is the most likely cause and what is the correct fix?

3. A major-gifts officer asks you to pull a list of all donors who gave last year but have not yet given this year, so they can be prioritized for phone outreach. The officer's colleague suggests just writing a SOQL query joining Opportunities with date filters. What is the NPSP-native way to identify this donor segment, and why is it the preferred approach?

4. A fundraising staff member reports that after she manually types a new mailing address into the Mailing Street field on a donor Contact record and saves, the address saves fine but reverts to the old value by the following morning. No other user has edited the record. What is happening and what is the correct way to update this donor's address?

5. An NPSP admin is building a volunteer stewardship process and wants to automate a sequence of follow-up tasks (a thank-you call at day 3, a check-in email at day 30, and a survey link at day 90) for any Contact who completes an event. A junior admin suggests building an Apex trigger to create all three Task records. What is the NPSP-native alternative, and why should it be preferred?

6. You are reviewing a report that a development associate uses to present "total funds raised this fiscal year" at board meetings. The report is a summary on Contacts and sums both `npo02__TotalOppAmount__c` and `npo02__Soft_Credit_Total__c` for each Contact, then shows the grand total. What is wrong with this approach, and what does the inflated total represent?

7. A nonprofit running Salesforce Industries Nonprofit Cloud — confirmed via `list_objects` showing namespace-free `Gift`, `Program`, and `ProgramEnrollment` objects — reports that a program officer cannot see the Program Engagement tab even though her profile has full CRUD on all standard objects. A senior admin immediately adds a new OWD sharing rule to broaden access to Program Engagement records. Will this fix the problem? What should have been done first?

8. You are handed an NPSP org where a colleague hand-created both a "Husband→Wife" Relationship record and a "Wife→Husband" Relationship record on the same Contact pair, reasoning that both directions need to exist. What is the actual problem this creates, and what does NPSP do automatically that makes the second manual record unnecessary?

9. A consultant is building a data integration that sends new donation records from a payment processor to an NPSP org nightly via the Salesforce REST API. The integration currently uses the donor's full name as the matching key to find and update existing Contact records. After three months in production, the development team notices hundreds of duplicate Contact records for households with common names. What matching strategy should have been used, and why does the current one fail in an NPSP context?

10. A Nonprofit Cloud (Industries) org needs to collect structured monthly outcome measurements for each client enrolled in a mental-health program — a repeatable, multi-field form the case manager fills out at each session. A developer proposes building a custom OmniScript for this. Is OmniScript the right tool, and what is the more appropriate NPC-native mechanism for repeatable measurement forms?

11. An NPSP org recently ran a bulk Opportunity import using Data Loader with TDTM handlers disabled to keep import speed up. The import finished, handlers were re-enabled, but the team skipped running Recalculate Rollups because "rollups will catch up on the next nightly job." Three days later donors are calling in saying their online giving history shows zero lifetime giving. What is the root cause of the stale totals, and what is the correct remediation step?

12. A junior consultant at a nonprofit SI wants to process a batch of 200 offline check gifts from a phonathon drive. They plan to create Opportunity records in bulk using the Data Import Wizard, associating each to the correct donor Account. Explain why this approach is wrong for an NPSP org, what tool should be used instead, and what NPSP-specific logic would be bypassed by the proposed approach.
