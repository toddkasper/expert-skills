# Eval situations — salesforce-advanced-administrator

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

Answer each: state the **competent action** and the **reason**. Be concise (2–4 sentences each).

1. A finance team member submits an Opportunity for approval. Immediately after submission, an after-save record-triggered flow fires (triggered by the Status change that approval submission causes) and attempts to stamp a `Finance_Review_Date__c` field on that same Opportunity. The flow errors with `ENTITY_IS_LOCKED`. No one recalls seeing this in a sandbox because sandbox testing used non-submitted records. What is the root cause and the correct fix?

2. Your org uses Enterprise Territory Management. A sales ops manager reports that Opportunities are not being assigned to the correct territory even though the related Accounts *are* landing in the right territory after territory assignment rules run. The territory model is Active. What step is being skipped, and where is it performed?

3. A senior rep needs elevated permission to export a sensitive report — but only for the duration of an authenticated session with MFA, not permanently. A junior admin suggests adding a standard permission set with the export permission. Why is that wrong, and what is the correct configuration?

4. You need to track changes to the `Annual_Revenue__c`, `Rating`, `Industry`, `BillingCountry`, `BillingState`, `Phone`, `Fax`, `Type`, `OwnerId`, `NumberOfEmployees`, `Description`, `SLA__c`, `SLA_Expiration_Date__c`, `Account_Source__c`, `CustomerPriority__c`, `UpsellOpportunity__c`, `Active__c`, `SLA_Serial_Number__c`, `NumberofLocations__c`, and `Contract_Value__c` fields on a custom Account-like object. You enable Field History Tracking and try to save. The save silently drops some tracked fields. What is the limit, and what are the options for the fields that fall outside it?

5. A developer deploys a permission set via SFDX that includes a `<fieldPermissions>` entry for `Contact.Notes__c`. The field is marked `<required>true</required>` in its field metadata. The deploy fails. What went wrong and what is the fix?

6. You need to capture a trend of how many open Cases were open at the end of each week for the past six months, to populate a line chart on an executive dashboard. A colleague suggests Cross-Filters. Is that the right tool? What is the correct mechanism, and what are its limits?

7. Your SFDX CI pipeline deploys a new Apex trigger and associated test class to production. The deploy is rejected even though all tests pass locally and the test class has 100% coverage of the new trigger. The rejection message references org-wide code coverage. What threshold is failing, and what options exist to resolve it without deleting code?

8. An admin needs to import 80,000 Opportunity records linked to existing Accounts via an External ID on Account. They open Data Import Wizard, select Opportunities, and can't proceed. What is wrong, and what tool should they use instead?

9. A stakeholder wants to know who changed the org's password policies and when. You check the debug logs but find nothing. Where is the authoritative source for this information, and how long is its retention?

10. You have two Lookup fields on `Project__c` — `Primary_Contact__c` (lookup to Contact) and `Secondary_Contact__c` (also lookup to Contact). After deploying both fields you try to deploy a custom report type that traverses both relationships, but you receive a *"Duplicate relationship name"* deployment error on the second lookup. You confirm both field API names are distinct. What is the actual conflict, and how do you fix it without breaking SOQL that already traverses the first relationship?

11. The Account OWD is Private. A user named Dana is the owner of an Account. Dana's manager (via the role hierarchy) can see the Account because "Grant Access Using Hierarchies" is enabled. You now need Dana's manager to be able to see the Account but you want to prevent Dana's manager's manager (two levels up) from seeing it. The role hierarchy is already set correctly — Dana is under Manager, Manager is under Director. How do you prevent the Director from seeing it?

12. A Matching Rule and a Duplicate Rule are both active for Contact. A batch import via Data Loader completes with no errors and no duplicate alerts — but you later discover the import created hundreds of duplicate contacts that should have been merged with existing records. What are two likely causes, and what should be verified before re-running the import?
