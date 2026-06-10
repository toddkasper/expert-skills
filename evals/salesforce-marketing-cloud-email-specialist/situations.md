# Eval situations — salesforce-marketing-cloud-email-specialist (held-out set, 2026-06-07)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

Answer each: state the **competent action** and the **reason**. Be concise (2–4 sentences each).

1. A marketing team launches a new dedicated sending IP for their SFMC account. On day one they queue their entire 500,000-subscriber donor list for a single send. Deliverability reports show Gmail deferring 60% of the messages. What caused this, and what should they have done instead?

2. An SFMC admin exports a suppression list of 8,000 lapsed or hard-bounced addresses, then re-imports that same file into the All Subscribers list using "Add/Update" mode to "update their records." The next send to the full donor list reaches those addresses again. Explain why, and what the admin should never do with such a file.

3. You are designing a monthly "program newsletter" that goes to an audience built by a SQL Query activity in Automation Studio. The SQL writes to a target DE. A teammate places the SQL Query and the Send Email activity in the same Automation Studio step to keep the flow compact. The newsletter sends immediately but pulls a two-month-old audience. What is wrong and what is the fix?

4. An email to Canadian subscribers promoting a new fundraising initiative is ready to send. The list was purchased from a third-party data broker specializing in nonprofits. The legal team has approved CAN-SPAM compliance (physical address + unsubscribe link). Is this send compliant and safe to proceed? Justify your answer.

5. A donor-welcome journey has been running for three months. The communications team updates the welcome email copy (headline and CTA button) in Content Builder, saves the email, and verifies it looks correct in preview. New donors who enter the journey the next week are still receiving the original headline. What is the cause and what step was missed?

6. A team wants to suppress all contacts currently active inside a running welcome journey from receiving a separate one-off "year-end appeal" batch send. They have a DE of welcome-journey entrants. How should this DE be used in the appeal send setup, and what common mistake would accidentally send to nobody instead?

7. An analyst queries the `_Open` Data View to build a 90-day re-engagement suppression list — excluding from future sends anyone who "opened" in the past 90 days (treating them as engaged). After applying this suppression, the team notices they are excluding a large segment that internal sales data shows as completely inactive. What is the underlying measurement problem and what metric should drive the re-engagement decision instead?

8. A developer is building an AMPscript-driven email that loops through a subscriber's last five donation transactions using `LookupOrderedRows()`. In testing with a subscriber who has three donations, the rendered output shows only three rows correctly. When a test send goes to a subscriber with zero donations in the DE, the email renders with no donation table at all — no error, no fallback message, just a blank section. What guard is missing and what should be added?

9. A nonprofit org uses Marketing Cloud Connect to sync Salesforce CRM Contacts into SFMC. A campaign manager wants to segment the upcoming appeal by a custom field `Program_Region__c` added to the Contact object last month. After the field was added to CRM, the MCC sync was re-run. When she queries the Synchronized DE in SFMC, `Program_Region__c` returns blank for every record, even though the field is populated in CRM. What are the two most likely causes?

10. A content author creates a new email using a Content Builder slot-based template. She assigns image and text blocks to all required slots and sends. After deployment, colleagues in a child business unit report they cannot use the same template — the email editor shows a "content not found" error for one of the image blocks. What is the most likely cause and what is the correct fix?

11. Your team wants to use Einstein Send Time Optimization (ESTO) on a Journey Builder sequence. A colleague suggests also running an A/B test on the same journey emails to simultaneously measure subject-line performance. Another colleague proposes using Einstein Engagement Scoring to pick which contacts receive the journey at all. Which of these three Einstein features is appropriate in this context, which creates a measurement conflict, and which is applied at the wrong layer?

12. After a large send, the Email Performance by Domain report shows a 4.2% spam complaint rate from a single major ISP domain. All other domains are under 0.05%. You have confirmed the list was legitimately built and SPF/DKIM/DMARC are correctly configured. What two operational steps should you take immediately, and what longer-term hygiene change should you make to prevent recurrence?
