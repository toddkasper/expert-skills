# Application tasks — salesforce-agentforce-specialist (Lens 4, held-out)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

A skilled agent produces the artifact; a judge grades against the trap-keyed rubric. Run baseline vs skilled.

---

## Task 1 — Prompt template audit: Flex template with grounding, PII, and overflow traps

**Prompt to the agent:** Audit the Agentforce Flex prompt template configuration below. Identify every grounding flaw, PII/Trust Layer risk, field overflow issue, and structural problem. For each finding, name the issue, explain the production impact, and specify the correct fix.

**Template spec (submitted for pre-activation review):**

```
Template name: Constituent_OutreachFlex_v2
Template type: Flex
Invocation: Agent action "Draft Constituent Outreach"
Channel: Agentforce Service Agent (web messaging)

--- SYSTEM INSTRUCTIONS (static) ---
You are a helpful outreach coordinator for Acme Nonprofit.
Always refer to constituents by their full legal name and
their assigned case worker.

When drafting outreach, follow this example format:
  Dear [Legal Name],
  Your case worker [Case Worker Name] has reviewed your file.
  Your diagnosis from the intake form is: [Diagnosis Text].
  Please contact us regarding your benefit status.

--- INPUT MERGE FIELDS ---
{!$Record.Contact.FullName}
{!$Record.Contact.SSN__c}
{!$Record.Contact.Intake_Diagnosis__c}
{!$Record.CaseWorker__r.Name}
{!$Record.BenefitSummary__c}   <!-- custom long-text field, max 32,000 chars -->

--- OUTPUT ---
Target field: Outreach_Draft__c  (custom text field, length 255)
Output instruction: "Write a complete personalized outreach letter
including case history, diagnosis summary, and next steps."
```

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — `SSN__c` (Social Security Number) is passed as a merge field directly into the prompt context. PII transmitted to the LLM must pass through the Einstein Trust Layer's data masking. Static merge fields for sensitive data like SSN are not automatically masked; the correct remediation is to remove `SSN__c` from the template entirely (it should never appear in LLM prompt context) and, if an identifier is needed, use an anonymized reference ID. The audit must flag this as a Trust Layer / data-masking gap.
- [ ] Trap 2 — `Intake_Diagnosis__c` (medical/health data) appears both as a merge field input and is echoed verbatim in the static system instructions example ("Your diagnosis from the intake form is: [Diagnosis Text]"). Embedding sensitive field values in static instructional text bypasses data masking because static text is not processed by the masking layer. Fix: remove the example that echoes diagnosis text from the static instructions; reference the field only via merge field (where masking policies can apply), and evaluate whether diagnosis content should be in the prompt at all.
- [ ] Trap 3 — `BenefitSummary__c` is a 32,000-character long-text field injected directly into the prompt context. A long-text field at or near its maximum will overflow the effective context window for the merge-field slot, pushing out or truncating other merge fields silently. Fix: add a character-limit truncation instruction (e.g., `{!LEFT($Record.BenefitSummary__c, 1500)}`) or use a Flow data provider that summarizes the field before injection; document the tested maximum safe length.
- [ ] Trap 4 — The output target field `Outreach_Draft__c` is a 255-character text field, but the output instruction asks for "a complete personalized outreach letter including case history, diagnosis summary, and next steps." A full letter will consistently exceed 255 characters and be silently truncated on save, with no error surfaced to the user or agent. Fix: change the target field to a Long Text Area (minimum 2,000 chars for a letter) and update the output instruction to specify a maximum character count that fits within the field length.
- [ ] Trap 5 — The template is a Flex type but there is no explicit topic-to-action linkage verified in the spec. A Flex template used as an agent action must be linked to the specific agent topic in Agent Builder; a template that is activated but not linked to a topic will never be invoked by the agent's reasoning loop, or may be invocable by any topic indiscriminately. The audit must flag the missing topic–action binding confirmation as a pre-activation checklist item.
- [ ] No new errors introduced

**Reference — a competent audit:**
- Flags SSN__c as PII that must not appear in prompt context; recommends removal, not masking alone.
- Calls out the static-text echo of diagnosis data as a masking bypass and removes the example from system instructions.
- Identifies the 32,000-char long-text overflow risk and specifies a truncation strategy.
- Catches the 255-char output field vs. full-letter instruction mismatch and prescribes Long Text Area.
- Confirms topic-to-action binding is a required pre-activation step not evidenced in the spec.

---

## Task 2 — Agent topic and action design review: over-broad topic and unlinked action

**Prompt to the agent:** Review the Agentforce agent configuration below. Redline the topic definition quality, action linkage, agent-user privilege, and escalation/out-of-scope handling. Produce a prioritized findings list with specific fixes for each issue.

**Agent configuration spec:**

```
Agent name: Benefits_Service_Agent
Agent type: Agentforce Service Agent (external, web messaging)
Agent user: benefits_integration@acme.org (System Administrator profile)

Topics configured: 1
  Topic name: "Benefits Help"
  Description: "Handle all benefits-related questions from constituents."
  Scope: Benefits, claims, applications, general questions, anything a
         constituent might ask about.

Actions linked to topic "Benefits Help": 2
  1. Action: "Look Up Application Status"
     Type: Flow action
     Flow: Get_Application_Status_Flow
     (linked to topic: YES)

  2. Action: "Escalate to Human Agent"
     Type: Flow action
     Flow: Escalate_To_Queue_Flow
     (linked to topic: NO — action exists in org but not added to this topic)

Out-of-scope handling: none configured

Grounding: None (no Knowledge base, no Data Cloud)
```

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — The agent user is assigned the System Administrator profile. Agent users must follow least-privilege: they should have only the object-level CRUD, FLS, and record access needed for the actions they perform. A System Administrator agent user can read and write any data in the org; if the agent is compromised or the reasoning loop is manipulated (prompt injection via user input), an attacker can exfiltrate or modify any record. Fix: create a dedicated agent user with a minimum-privilege permission set scoped to `Application__c` read access and the escalation flow.
- [ ] Trap 2 — The "Escalate to Human Agent" action is not linked to the "Benefits Help" topic. An action not linked to a topic is never surfaced to the agent's reasoning loop for that topic — the agent cannot invoke it regardless of how appropriate escalation would be. Fix: add the Escalate action to the "Benefits Help" topic in Agent Builder, and add an escalation instruction in the topic description.
- [ ] Trap 3 — The topic description ("anything a constituent might ask about") is over-broad and unscoped. An over-broad topic description causes the agent to attempt to answer questions outside its intended domain (e.g., legal, medical, financial advice) rather than declining or escalating. Fix: rewrite the description to enumerate specific intent categories the topic handles (e.g., "Checking application submission status, understanding required documents, or requesting to speak with a case worker") and add a negative scope statement ("Does not handle legal advice, medical questions, or payment disputes").
- [ ] Trap 4 — No out-of-scope handling is configured. When a constituent asks a question that does not match any topic, the agent will generate a free-form response with no guardrails, potentially hallucinating answers. Fix: configure an "I don't know" / fallback topic that declines gracefully and offers escalation; set the agent's general instructions to specify behavior for unmatched queries.
- [ ] Trap 5 — There is no grounding configured (no Knowledge base, no Data Cloud). The agent has only the two actions and the LLM's parametric knowledge. For a benefits service context, this means policy answers will be generated from general LLM training data, which may be outdated, jurisdiction-specific, or simply wrong. Fix: at minimum, upload a Knowledge base of policy FAQs and link it as a grounding source; clearly communicate to stakeholders that without grounding, the agent cannot reliably answer policy questions and should be scoped only to action-backed lookups until grounding is in place.
- [ ] No new errors introduced

**Reference — a competent redline:**
- Replaces System Administrator agent user with a minimum-privilege permission set; explains prompt-injection blast radius.
- Links the Escalate action to the topic and adds escalation instruction to the topic description.
- Rewrites the topic description with enumerated intents and a negative scope.
- Configures a fallback/out-of-scope topic with graceful decline behavior.
- Calls out the no-grounding gap and its production risk; recommends Knowledge-base grounding as a prerequisite before policy-answer use cases are enabled.
