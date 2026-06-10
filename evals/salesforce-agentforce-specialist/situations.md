# Eval situations — salesforce-agentforce-specialist (held-out set, 2026-06-07)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

Answer each: state the **competent action** and the **reason**. Be concise (2–4 sentences each).

1. A Prompt Builder Flex template was built to back an agent action that generates a follow-up message for a constituent record. The template preview pane works correctly in sandbox. After the org is refreshed, a developer deploys the template via change set and immediately wires it into a new agent action. The agent action fails at run time in the target org. No deployment error was raised. What is the most likely cause, and what is the fix?

2. A nonprofit org has sensitive medical intake fields (`Diagnosis__c`, `Treatment_Plan__c`) on a custom object `Intake__c`. A staff member builds a Record Summary template that pulls these fields via merge fields. They also add a paragraph of example diagnostic language directly in the template body "so the model understands the context." An audit finds that sensitive medical language is reaching the LLM unmasked. Which part of the design is responsible, and what is the correct remediation?

3. An Agentforce Service Agent is deployed to serve website visitors. The agent answers FAQ questions well but, when a visitor's question falls outside the agent's configured topics, it fabricates an answer rather than declining or escalating. The agent has a single broad topic called "General Support" with a description of "Handle all customer inquiries." What is the architectural problem, and what is the fix?

4. A developer builds a Field Generation template that writes a 300-character product blurb into a custom field `Product_Blurb__c`. The prompt instruction says "Write a product description in exactly 300 characters." In the preview pane the output is always 300 characters. After the template is activated and records are saved, blurbs are consistently 255 characters and cut off mid-sentence. No error is logged. What went wrong, and what must the developer do before re-activating?

5. You are configuring a new Employee Agent to answer internal HR policy questions. The HR team wants it grounded on a library of PDF policy documents stored in SharePoint. Your org does not have Data Cloud enabled. The team insists on a go-live date two weeks away. What options do you have, and what commitment is premature to make?

6. A QA engineer authors 15 test utterances in the Agentforce Testing Center and runs an evaluation. All 15 utterances route to the correct topic and the trustworthiness score is 0.91 out of 1.0. The QA engineer marks the agent as "ready for production." A senior reviewer pushes back. What key gap does the reviewer likely see, and what additional step is needed before a production release decision?

7. An org has two agents: a public-facing Service Agent for customer support and an internal Employee Agent for staff use. The same named Salesforce user is assigned as the agent user for both agents to simplify management. A staff member notices that the public customer agent occasionally returns internal HR policy content in its answers. What is the root cause, and how do you fix it?

8. A Prompt Builder Sales Email template is being reviewed before activation. The template references fifteen merge fields pulled via lookup traversal across four related objects and also calls a Flow data provider that runs five SOQL queries. In the preview pane, the output occasionally shows "[Field Unavailable]" for some merge fields on certain records. The reviewer is unsure whether to approve it as-is. What is the likely problem, and what is the review checklist item that catches this?

9. You need to add a new action to an existing Agentforce agent that looks up open Cases for a customer and returns a summary. The simplest implementation is a single SOQL query. A colleague recommends building the action as an Apex `@InvocableMethod`. You are deciding whether Apex is warranted. What is the correct build choice and the decision rule that governs it?

10. An org deploys an Agentforce agent from sandbox to production via a change set that includes the agent (Bot), its topics, and two prompt template actions. The deployment succeeds. After go-live, every invocation of the agent's Flow-backed action fails immediately. The Flow itself was not in the change set. What is the correct diagnosis, and what must happen before the agent is considered production-ready?

11. A company recently switched from the default Einstein LLM to a third-party model via Model Builder to get a larger context window. All Prompt Builder templates worked in sandbox post-switch. Two weeks into production, users report that grounded prompts for records with many related child records are silently returning partial output — fewer related items than expected. No error appears. What is the likely cause, and what should be verified?

12. An Agentforce Service Agent is being deployed to both a web messaging widget and an SMS channel for the same use case. The web widget response templates average 400 characters. The team copies the same response templates to the SMS channel configuration without modification. What problem will emerge, and what is the correct design approach?

13. A consultant is preparing study materials for a colleague taking the AI-201 exam. The colleague's notes say: "Focus most of your time on Prompt Engineering — it's the largest domain at 30%. AI Agents is also 30%. Skip Development Lifecycle, it's probably a small add-on." Identify every error in that study guidance and state the correct domain structure.

14. After a successful sandbox run, a team deploys an Agentforce agent to production. Three days after go-live the production success metrics look fine, but the same testing utterances that scored 0.89 in sandbox are now scoring 0.74 in production. No configuration changes were made post-deployment. What is the most likely oversight in the deployment and validation process, and what should have been done before declaring production-ready?

15. An architect is designing a grounding strategy for an agent that needs to answer questions from a library of technical specification sheets stored as PDFs. The org's contract with Salesforce predates Dreamforce 2025. The architect refers to this feature set as "Data Cloud vector search" throughout the design doc. A reviewer flags the terminology. What should the reviewer say, and does the terminology difference affect the technical design?

16. A junior developer is asked to implement a "lookup-and-notify" agent action: the agent queries open opportunities for a contact and sends an internal Chatter post summarizing them. The developer argues the action must be built in Apex because "agent actions that do multiple things always need Apex." Is the developer correct? State the decision rule and the correct build approach.

17. A project manager asks the team lead: "What score does a candidate need to pass the AI-201 exam, and how many questions does the exam have?" The team lead answers from memory: "72%, and it's 60 questions." Evaluate the accuracy of that answer and state what the team should do before relying on it for planning a retake policy.
