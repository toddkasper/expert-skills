# Eval situations — salesforce-service-cloud-consultant (held-out set, 2026-06-07)

Answer each: state the **competent action** and the **reason**. Be concise (2–4 sentences each).

1. A regional utility deploys Entitlement milestones with a "First Response" milestone set to 4 business hours. After go-live, agents notice that cases logged at 4:45 PM Friday are showing a `TargetDate` of Monday 9:00 AM rather than Monday 8:45 AM — a 15-minute discrepancy. Business Hours are configured as Mon–Fri 8:00 AM–5:00 PM. No one has changed the Entitlement Process. What is the most likely cause, and how do you confirm it?

2. A non-profit runs Email-to-Case. Support emails are forwarded from a shared Gmail inbox to the Salesforce routing address. Agents complain that replies sent from the Gmail inbox (not Salesforce) are creating brand new cases instead of appending as comments to the original case. The original cases were created by Email-to-Case. What is happening, and what do you tell the team?

3. Your team adds a new `Specialist_Notes__c` long-text-area field to the Case object and deploys it via SFDX. The deploy succeeds. You then add `<fieldPermissions>` for Read and Edit to the "Support Specialist" permission set in the same SFDX project and redeploy. That deploy also succeeds. But when Support Specialists open a case, the field is invisible. What do you check first, and in what order?

4. You are designing a service center for a healthcare company that handles patient inquiries. A product manager proposes embedding a "Medical Record Number" field directly in the Knowledge article body so agents can quickly copy it into a case. You're asked to approve the design. What is your response, and what do you recommend instead?

5. A service operations manager wants real-time visibility into how many cases are currently sitting in each support queue and which agents are logged in and available. She opens the standard Cases list view filtered by queue and refreshes it periodically. Your Salesforce admin says Omni Supervisor already exists in the org. What should you recommend, and why does the current approach fall short?

6. A developer writes a Record-Triggered Flow on the Case object (after-save) that loops through all related Case Comments and, inside the loop, executes a Record Create element to generate a follow-up task for each comment. In testing with 3 comments this works fine. The org expects some cases to have 50 or more comments. What is the design flaw, and what is the correct fix?

7. Your org needs to let any member of the public submit a service request without logging in. The project lead insists on using Salesforce Experience Cloud with a self-registration page because "it's a professional portal." You have concerns. What specific trade-offs do you raise, and what alternative would you propose if the audience is truly one-time, low-tech, or shared-device users?

8. A nonprofit's data team wants to re-import 12,000 Case records from a legacy system. They plan to use the Data Import Wizard with the case's original external ID from the legacy system. Halfway through the first import run, the server times out and the import is interrupted. They want to simply run the import again with the full file. What could go wrong, and what is the correct approach?

9. A support team is rolling out Knowledge. They publish 40 internal-only articles and expect agents to search for them from the Service Console. Two weeks later, agents report that searches return no results. An admin confirms the articles are Published. What are the two most likely gaps to investigate?

10. A consultant is asked to configure a new escalation rule that should automatically escalate any case unresolved for more than 8 hours to a senior queue. The client says a previous escalation rule is already configured but no longer in use. The consultant creates a new rule, populates one rule entry, and activates it. Cases are not escalating. What is the most likely cause?

11. A telephony vendor proposes integrating their cloud PBX with Salesforce by building a custom Lightning Web Component that launches in the console's utility bar and makes REST API calls to their system when a call begins. The proposal does not mention Open CTI. Your architect asks if this approach has any functional gaps compared to a proper Open CTI integration. What are the key limitations of the custom LWC approach?

12. A service team operates in three time zones. Business Hours are configured org-wide for 9 AM–5 PM Eastern. A VIP tier of accounts should receive support 9 AM–5 PM Pacific (i.e., support until 8 PM Eastern). The Entitlement Process is shared between standard and VIP accounts. A consultant proposes adding a second Entitlement Process for VIP. Is that the right approach, and what is the more targeted fix?
