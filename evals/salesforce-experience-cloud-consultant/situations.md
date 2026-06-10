# Eval situations — salesforce-experience-cloud-consultant (held-out set, 2026-06-07)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

Answer each: state the **competent action** and the **reason**. Be concise (2–4 sentences each).

1. A nonprofit organization wants to build a donor portal where supporters can log in, update their contact information, and view their own giving history. The nonprofit runs NPSP. The program director says, "Partners see each other's deals in our vendor portal, so we should use Partner Community for donors too — it's more capable." What license do you recommend for the donor portal, and why is the program director's reasoning wrong?

2. You are configuring Experience Cloud for the first time in a sandbox org that was recently refreshed. When you navigate to Digital Experiences in Setup and click "New," the option to create a site is grayed out and unavailable. No permission errors appear. What is the most likely cause, and what is the prerequisite step you must complete first?

3. A Customer Community Plus portal is live. The admin wants external users to be able to view reports summarizing their account's open cases. The admin creates a report, puts it in a public reports folder, and adds a dashboard to the portal. External users log in but see no data in the dashboard. What layers does the admin need to check and in what order?

4. A company is launching a public-facing job-application portal. Applicants submit personal information through an unauthenticated Screen Flow embedded on an LWR site. A security reviewer flags a concern: "Multiple applicants could inadvertently see each other's submitted applications via the guest profile." How does the guest profile architecture create this risk, and what is the correct technical control to prevent it?

5. A partner portal is configured with SAML SSO. Partners report that when they click the company's login link from their IdP's app launchpad, they are redirected to the Experience Cloud login page instead of being logged in automatically. The SAML configuration in Salesforce appears complete. What is the likely misconfiguration, and what setting controls the login behavior?

6. An admin deploys a change set from sandbox to production for a new Experience Cloud site configuration. After deployment, the external user profiles look correct in production, but newly created external users cannot log in to the site. The admin confirms the users' profiles match. What is the most likely step that was missed, and why does it not come through in a change set?

7. A developer building a Customer Account Portal (Aura) embeds a third-party live-chat widget by pasting a `<script>` tag into a custom HTML component. The widget loads and works perfectly in the sandbox org. After deploying to production, the chat widget is completely silent — no errors shown to users, no visible component. What should the developer check first, and why does it fail silently?

8. An architect is scoping a new portal for a financial services firm. The requirement states: "High-net-worth clients should see personalized market commentary based on their investment profile tier (Bronze, Silver, Gold), and the portal must load in under two seconds on a 4G mobile connection." The architect proposes Build Your Own (Aura) because it has more out-of-the-box components. Is this the best template choice given the stated requirements, and what trade-off does the architect need to weigh?

9. A self-registration flow for a customer portal creates a new Contact and User on submission. After launch, the team notices that every self-registered Contact has `MobilePhone` populated with the same value that was entered in the `Phone` field on the registration form — even when the applicant left `MobilePhone` blank. No one touched the self-reg Apex handler. What is the most likely cause, and where do you look to confirm it?

10. An admin wants to give a subset of Customer Community users the ability to see reports and dashboards in the portal. The admin assigns a permission set that includes "Run Reports." The users still cannot access the reports tab. What is the root cause, and what is the correct fix?

11. A portal is live in production. The admin publishes a change to the site's branding (new hero image and updated color palette via the Theme panel in Experience Builder) and clicks Publish. Users report that the old branding is still appearing 30 minutes later, even after clearing their browser cache. What is the most likely infrastructure reason, and what action should the admin take in Salesforce?

12. A Customer Community portal has a sharing set configured on the Case object, keyed on `Case.ContactId = Community User's Contact`. After a schema change, a developer renames the `ContactId` field on Case to `Portal_Contact__c` (a custom lookup). External users immediately lose access to all their cases. The sharing set configuration in Setup still shows `Case.ContactId`. What happened and what must the admin do to restore access?
