# Eval situations — salesforce-administrator (held-out set, 2026-06-07)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

Answer each: state the **competent action** and the **reason**. Be concise (2–4 sentences each).

1. A manager at your org loses access to see their team's Opportunity records overnight — no one touched security settings. The manager is in the correct role and the role hierarchy is intact. OWD on Opportunity is Private. Where do you look first, and what likely happened?

2. A flow runs nightly to update a large set of Account records. It processes correctly for small batches in testing, but fails in production with a "Too many DML rows" governor-limit error when the record set exceeds ~10,000 rows. The flow does one Update Records call after a loop. What is the root cause and how do you fix it?

3. You need to lock a user out of the org immediately while an HR investigation is in progress. IT says the user must still appear in the system and their records must remain owned by them. What action do you take, and why is it different from what you'd do once the investigation concludes?

4. An admin tries to place login-hour restrictions for a subset of users who share a profile by adding those restrictions to a permission set assigned only to that subset. They report the restrictions aren't applying. Why not, and what is the correct approach?

5. A business analyst builds a summary report on Opportunities grouped by Account to show total pipeline per account. They then try to use it as the data source for a dashboard chart, but the option to add it to a dashboard is grayed out. What type of report did they likely create, and what should they use instead?

6. Your org has duplicate management configured with a Matching Rule and a Duplicate Rule on Contacts set to **Alert** mode. A user reports that they are still able to save a clearly duplicate Contact without any warning appearing. What are the two most likely configuration reasons, and how do you verify each?

7. A stakeholder wants to know which Contacts have **no** related Opportunity Contact Roles. They ask you to build a standard report on Contacts filtered to show only those without roles. Can a standard report type accomplish this, and if not, what is the mechanism that can?

8. An Agentforce agent is configured with a Flow-backed action that sends a summary email. The action is built and the Flow is active. In testing, the agent responds correctly to questions but never executes the email action. What is the most likely configuration gap, and what is the fix?

9. A new field `Contract_Value__c` (currency, not required) is deployed via SFDX to the `Opportunity` object alongside a `<fieldPermissions>` block granting Read and Edit to the "Sales Rep" permission set. Shortly after, the deploy fails with "You cannot deploy to a required field" — but the field is definitely not required. What else could trigger that error message?

10. You need to report on Cases that were created by web form submission (Web-to-Case) and remained unresolved for more than 48 business hours. Business hours are configured in the org. Can standard Salesforce reports satisfy this requirement, and what is the limiting factor?

11. You are setting up Email-to-Case. Your org's IT team says they cannot open any inbound firewall ports on the mail server. Which Email-to-Case variant do you configure, and what is the key architectural difference that makes it viable without a firewall change?

12. A screen flow is embedded on a record page via a Lightning App Builder component. After a release, users report the flow no longer saves correctly — it shows a generic error on the final screen. The flow itself has not changed. What should you check in Setup first, and what is a common deployment-related cause of this symptom?
