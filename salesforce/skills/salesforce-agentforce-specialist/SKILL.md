---
name: salesforce-agentforce-specialist
description: Building and governing Salesforce Agentforce and generative-AI features — Agentforce agents (topics, actions, agent-user security, the reasoning loop), Prompt Builder templates (Sales Email, Field Generation, Record Summary, Flex), Data Cloud and Knowledge grounding/RAG, and the Einstein Trust Layer (data masking, zero-retention, audit). Use when implementing or reviewing agents, prompt templates, grounding, or AI guardrails. Not admin-level Agentforce permission setup alone (see salesforce-administrator) or Apex action-code internals (see salesforce-platform-developer-2). Scoped and benchmarked by the Agentforce Specialist (AI-201) blueprint.
metadata:
  credential: Salesforce Certified Agentforce Specialist
  exam-code: AI-201
  domain: salesforce
  type: certification-playbook
---

# Salesforce Agentforce Specialist (AI-201) — Skills Reference

## Overview

> **Rebrand note (read first):** The original **"Salesforce Certified AI
> Specialist"** exam (launched September 2024) was rebranded
> **"Salesforce Certified Agentforce Specialist" (AI-201)** on March 3, 2025.
> Topic areas and weights shifted significantly. Existing AI Specialist
> credential holders were automatically transitioned with no retest required.
> "AI Specialist" is no longer the current name — use **Agentforce Specialist
> (AI-201)**. (Distinct from the entry-level **AI Associate** credential, which
> was retired in early 2026.)

The Agentforce Specialist (formerly AI Specialist) validates the ability to
implement, configure, and govern Salesforce generative + agentic AI — Prompt
Builder, Agentforce agents (formerly Einstein Copilot), Model Builder, Data
Cloud grounding, and the Einstein Trust Layer. This document is an
**operational playbook**, not an exam outline: every section states the rule
as an actionable instruction, the real limits, the decision criteria, and the
anti-patterns to catch in review.

The certification sits between entry-level **AI Associate** (conceptual, no
hands-on) and senior architecture credentials. Recommended (not required)
prior knowledge: Salesforce Administrator or Platform App Builder.

> **Deeper context:** Study resources live in [references/study-resources.md](references/study-resources.md) (loaded on demand). For org-specific applications of these rules, see a per-org appendix you maintain in your own project, referenced from a CLAUDE.md. For NPSP/nonprofit-specific guidance, see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md).

> **Verify steps assume nothing about your tooling** — use your project's Salesforce MCP connection, the Salesforce CLI (`sf`), or the Salesforce setup UI, in that order of preference.

---

Credential logistics and study path: see [references/study-resources.md](references/study-resources.md).

---

## 1. Prompt Engineering & Prompt Builder (30% — largest topic)

### The rules

- **Reach for an out-of-the-box Einstein feature before building a template.**
  Build a Prompt Builder template only when no standard generative feature
  (Einstein Sales Emails, Work Summaries, Service Replies) covers the need, OR
  when you need it grounded on **custom** objects/fields the standard feature
  can't see. When everything you need lives on custom objects or custom fields
  that no standard feature grounds on, custom templates become the norm.
- **Pick the template type by output target, not by vibe:**

  | Need | Template type |
  |---|---|
  | Personalized outbound email to a person from CRM data | **Sales Email** |
  | Write AI text into a record *field* | **Field Generation** |
  | Natural-language summary of one record for a human to read | **Record Summary** |
  | Anything else / multi-input / used inside Flow/Apex/Agent action | **Flex** |

  Flex is the catch-all and the one you use to back an **agent action**. Field
  Generation must target a writable field whose length you control (see length
  rule below).
- **Ground every template.** Ungrounded prompts hallucinate. Grounding sources,
  in increasing power: (a) **merge fields** off the template's input record/object,
  (b) **related-record merge fields** via lookup traversal, (c) **flow/Apex**
  data providers, (d) **Data Cloud RAG retriever** for unstructured content.
  Use the lightest one that supplies the needed facts.
- **Static vs. dynamic grounding:** static = fixed text baked into the template
  (policy, tone, disclaimers). Dynamic = merge fields resolved at run time from
  the record. Put PII-shaped facts in dynamic grounding so they're masked by the
  Trust Layer (see §6); never paste a real record's data as static text.
- **Lifecycle is draft → version → activate → test in the preview pane → deploy.**
  A template must be **activated** before a Lightning page, Flow, or agent action
  can reference it. Edits create a new version; reactivate to publish.
- **Permissions are two distinct grants.** "Prompt Template Manager" (create/edit)
  is separate from "Prompt Template User" (execute at run time). A staff user who
  should only *run* a template must not get Manager. Grant via permission set,
  not by widening a profile.
- **Write prompts with structure:** assign a role, state the task, constrain the
  output format explicitly (length, tone, "do not invent facts not present in the
  grounded data"), and iterate in the preview pane against real sandbox records.

### Concrete numbers

- A Field Generation result **silently truncates to the target field's length**.
  Match the prompt's max-output instruction to the field size, and verify the
  field length first with `describe` — do not assume.
- Sales Email / Record Summary outputs are bounded by the model context window;
  keep grounded record sets small. Don't ground a template on a giant related
  list expecting all rows — retrieval/merge limits apply and the model will
  drop the tail.

### Anti-patterns / red flags

- A template with **no grounding** that nonetheless asks for record-specific
  facts → it will fabricate them. Red flag in any review.
- Pasting real PII (names, DOB, medical notes, SSN, sensitive document text) as
  **static** grounding → bypasses Trust Layer masking. Always use dynamic merge
  fields.
- A Field Generation template whose output instruction is longer than the
  target field → silent data loss on write.
- Referencing a template from a Lightning page that is still in **draft** → it
  won't resolve at run time.

### Verify against the live org

- `describe` the target object(s) to confirm the exact API names and **lengths**
  of every merge field before wiring it into a template.
- Pull a real sandbox record to test the template against in the preview pane.
- List objects to confirm which custom objects exist before assuming a merge source.

---

## 2. Agentforce Concepts — agents, topics, actions, security (30%)

### The rules

- **Understand the loop:** the reasoning engine (LLM planner + executor) reads
  the user utterance, classifies it to a **topic**, then chains the **actions**
  attached to that topic. Topic classification quality is driven by the topic's
  scope, description, and instructions — vague topics misroute.
- **Pick the agent type by audience and job:**

  | Job | Agent type |
  |---|---|
  | Inbound customer/constituent service | **Service Agent** |
  | Autonomous prospecting / lead qualification | **SDR Agent** |
  | Rep coaching via role-play | **Sales Coach Agent** |
  | Internal staff productivity | **Employee Agent** |

- **Standard topics ship pre-built; custom topics encode org intent.** Add a
  custom topic when no standard topic matches the request; give it a tight scope,
  a clear description, and explicit instructions that tell the planner when to
  use it and when NOT to.
- **Choose the action mechanism by what it must do:**

  | Action need | Build it as |
  |---|---|
  | Deterministic query/DML on Salesforce data | **Flow action** (preferred — declarative, testable) |
  | Logic Flow can't express, or complex SOQL/transaction | **Apex action** (`@InvocableMethod`) |
  | Generate natural-language text | **Prompt template action** |
  | Call out to an external system | **External service / API action** |

  Prefer Flow over Apex when both work; it's declarative and easier to govern.
- **The agent runs as a real, named Salesforce user.** Its profile + permission
  sets + sharing define exactly what it can read/write. Design **least
  privilege**: an Employee Agent answering status questions needs read on the
  relevant object, not modify-all. Never give an agent user broad admin.
- **Constrain behavior deterministically.** Use topic/action instructions,
  input/output filters, and response templates to keep the agent on-rails. Don't
  rely on the LLM's good intentions for compliance-sensitive output.
- **Test in Agentforce Testing Center, not by eyeballing.** Author test
  utterances, run evaluations, read the **trustworthiness / topic-and-action
  accuracy** scores. Results are graded quality scores, not a binary pass/fail —
  iterate the topic/action descriptions to raise them.

### Concrete behaviors

- Agent metadata that ships sandbox → prod: the agent (Bot), its topics,
  actions, and referenced prompt templates. The backing **Flows/Apex must also
  be deployed**, and the **agent user, profile, and permission set assignments
  must exist in the target org** — these are environment-specific and a frequent
  cutover miss.
- An agent can only act on data its assigned user can see; FLS and sharing apply
  exactly as they would for that user (see §6).

### Anti-patterns / red flags

- One mega-topic that "handles everything" → the planner can't route reliably.
  Split into scoped topics.
- Agent user granted a powerful profile "to make it work" → least-privilege
  violation; the blast radius of a prompt-injection grows to whatever that user
  can do.
- Deploying an agent to prod without deploying its Flows/Apex or creating its
  agent user → agent loads but every action fails at run time.
- Treating Testing Center as optional → untested agents misroute on real
  utterances.

### Verify against the live org

- List/describe objects to confirm the objects + FLS an agent action will touch,
  then size the agent user's permission set to exactly that.
- Dry-run the exact query a Flow/Apex action will execute, as the intended agent
  user's visibility, before wiring it in.
- After a cutover, query through the agent's expected access path to confirm the
  agent user can actually see the records.

---

## 3. Agentforce + Data Cloud grounding (20%)

### The rules

- **Data Cloud must be enabled before any Data Library / RAG feature exists.**
  RAG grounding, vector search, and Data Library are not available in an org
  without first provisioning Data Cloud. Don't design a solution that assumes
  them unless Data Cloud is confirmed enabled.
- **Use the Data Library for unstructured grounding** (PDFs, Knowledge articles,
  uploaded files, Data Cloud objects). Structured CRM facts should still come
  from merge fields / Flow, not RAG.
- **Chunking governs retrieval quality.** Chunk unstructured docs into
  retrievable segments with sensible size + overlap: too large dilutes relevance,
  too small loses context; overlap preserves meaning across boundaries. Indexing
  turns chunks into vector embeddings that semantic search queries.
- **Pick the retriever by source count:** single source → **individual
  retriever**; multiple sources needing merged/re-ranked results → **ensemble
  retriever**.
- **Pick the search type by query shape:**

  | Query | Search type |
  |---|---|
  | Exact token (SKU, policy #, record ID) | **Keyword** |
  | Conceptual / natural-language ("how do I qualify?") | **Vector / semantic** |
  | Mixed / unsure / production default | **Hybrid** |

### Anti-patterns / red flags

- Designing RAG features for an org where Data Cloud isn't enabled → the build
  won't have the objects.
- Using vector search for exact-ID lookups → keyword is faster and exact.
- One giant chunk per document → poor retrieval relevance.

### Verify against the live org

- Confirm Data Cloud presence/absence by checking whether Data Cloud DMO/DLO
  objects appear in the object list. Treat Data Cloud features as a future,
  post-provisioning capability if they're absent.

---

## 4. Agentforce + Service Cloud (10%)

### The rules

- **Ground service agents on Knowledge articles** and set a confidence
  threshold so low-confidence matches don't surface as authoritative answers.
- **Match the generative feature to the service moment:**

  | Moment | Feature |
  |---|---|
  | Suggest replies to a *human* agent | **Einstein Reply Recommendations** |
  | AI-drafted first reply | **Service Replies** |
  | End-of-case summary for QA/CSAT | **Work Summary** |
  | Auto-fill case category/priority from text | **Case Classification** |
  | Route case to right queue/skill | **Case Routing** (uses classification) |
  | Surface KB articles to agents | **Article Recommendations** |

- **Always configure an escalation/hand-off path** to a human and an
  end-of-conversation action. An autonomous agent must know its exits.
- A public-site Service Agent grounded on a small Knowledge base is a common
  near-term fit; it requires Knowledge enabled and grounds on articles, not RAG.

### Verify against the live org

- Confirm whether `Case` / `KnowledgeArticleVersion` are in use before proposing
  a Service Cloud-grounded agent.

---

## 5. Agentforce + Sales Cloud (10%)

### The rules

- **SDR Agent** = autonomous prospecting, lead qualification, meeting booking.
  **Sales Coach Agent** = rep skill development via simulated buyer conversations.
- Match sales generative features to the scenario: **Einstein Sales Emails**
  (drafted outreach from CRM), **Call Summary/Coaching** (transcription + next
  steps), **Lead/Opportunity Scoring** (predictive scores on records), **Pipeline
  Inspection** (deal-risk surfacing).
- Sales Cloud agents only fit orgs that actually run a sales pipeline. In orgs where there is no sales motion (e.g. nonprofits using NPSP where Opportunities represent donations rather than deals), don't force-fit SDR/Coach/pipeline agents — see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md) for the NPSP/Nonprofit Cloud context.

---

## 6. Einstein Trust Layer & data protection (woven through all topics)

### The rules

- **Every AI call in the org passes through the Trust Layer.** It provides
  zero-data-retention with Salesforce's LLM partners, dynamic data masking
  before the external call, toxicity/bias scoring on the response, and an audit
  trail of prompts + responses.
- **Zero retention** means PII and sensitive data sent in a grounded prompt is
  **not** used to train external models. This is the property that makes it
  acceptable to ground on records containing sensitive data at all.
- **Configure masking for sensitive fields explicitly.** Mask SSN, sensitive
  document content, medical detail, DOB, and contact PII so they're tokenized
  before the prompt leaves Salesforce and de-tokenized in the response. Do not
  assume defaults cover custom sensitive fields — verify.
- **The audit trail is your compliance evidence.** Keep it on; it records what
  was sent and returned for every prompt over sensitive data.

### Anti-patterns / red flags

- Any design that puts sensitive data (medical info, SSN, document content) into
  **static** grounding or into a logged debug string → bypasses masking and
  violates a "no PII in logs" policy.
- Assuming masking auto-covers custom sensitive fields → custom fields often need
  explicit entity configuration. Verify.

### Verify against the live org

- `describe` the relevant objects to enumerate the exact medical/PII custom
  fields that must be in the masking configuration.

---

## Operational Rules Quick Reference

- **DO** prefer an out-of-the-box Einstein feature; build Prompt Builder templates only when grounding on custom objects/fields a standard feature can't see.
- **DO** ground every prompt template — ungrounded prompts hallucinate.
- **DO** put record facts in **dynamic** merge-field grounding so the Trust Layer can mask them; **DON'T** paste PII as static grounding text.
- **DO** match a Field Generation template's max-output instruction to the target field length (`describe` first) — output **silently truncates** otherwise.
- **DO** activate a template before referencing it from a page/Flow/agent; a draft won't resolve at run time.
- **DO** separate "manage template" from "execute template" permissions; grant via permission set.
- **DO** pick the template type by output target: Sales Email / Field Generation / Record Summary / Flex (Flex backs agent actions).
- **DO** give each agent a scoped topic with clear instructions; **DON'T** build one mega-topic — the planner will misroute.
- **DO** prefer Flow actions over Apex actions when both work; use Apex only when Flow can't express it.
- **DO** run the agent as a **least-privilege named user**; **DON'T** hand it a powerful profile "to make it work."
- **DO** deploy the agent's backing Flows/Apex AND create its agent user + permission sets in the target org — a frequent cutover miss.
- **DO** validate agents in Testing Center; treat trustworthiness scores as quality signals to iterate on, not a binary pass/fail.
- **DO** pick search type by query shape: keyword for exact IDs, vector for conceptual, hybrid as production default.
- **DON'T** assume Data Cloud / Data Library / RAG features exist unless Data Cloud is confirmed enabled.
- **DON'T** propose Sales Cloud agents (SDR/Coach/pipeline) for an org with no sales pipeline.
- **DO** configure Trust Layer masking explicitly for SSN, medical, DOB, and PII fields; **DON'T** assume defaults cover custom fields.
- **DO** keep the Trust Layer audit trail on — it's the compliance record. **DON'T** put PII/sensitive content in static grounding or logs.
- **DO** verify field API names + lengths + FLS with `describe` before wiring merge fields or agent actions.
- **DO** dry-run an action's SOQL as the agent user before trusting it.

---

## Decision scenarios

Original teaching scenarios — distinct from held-out eval scenarios in `evals/`.

---

**Scenario 1 — Field Generation silent truncation**

> **Situation:** A developer builds a Field Generation template that writes an
> AI-generated product description to a custom `Description__c` field. In the
> preview pane the output looks correct and reads naturally at ~500 characters.
> In the live org, saved descriptions are always cut off mid-sentence at the
> same spot. No error appears anywhere.
>
> **Competent move:** Run `describe` on the object to check the actual length of
> `Description__c`. The field is almost certainly shorter than 500 characters
> (e.g., 255). Update the prompt's max-output instruction to stay within that
> length, re-activate the template, and re-test. Never assume a field length —
> always confirm with `describe` before wiring.
>
> **Tempting-but-wrong:** Increase the model's max-token output setting,
> thinking the model is cutting off its own generation. The model isn't the
> constraint — the Salesforce field length is. Raising the model limit changes
> nothing; the write still silently truncates.
>
> **Verify:** `describe` the object, read the `length` property on the target
> field, and confirm the prompt's output constraint is at or below that value.

---

**Scenario 2 — Agent user over-privileged "to make it work"**

> **Situation:** A new Service Agent keeps failing at run time because its
> Apex action returns no records. The developer discovers the agent user's
> profile has restrictive object access. The quick fix applied: assign the agent
> user the System Administrator profile so the agent can always see the data
> it needs.
>
> **Competent move:** Identify exactly which objects, fields, and sharing the
> Apex action requires. Grant those permissions through a dedicated permission
> set assigned to the agent user — nothing more. Dry-run the SOQL from the Apex
> action logged in as the agent user (or via `runAs` in a test) to confirm
> the records are visible with minimal rights before going live.
>
> **Tempting-but-wrong:** Assigning the System Administrator profile solves the
> immediate error but creates a critical security gap: a prompt injection or
> misconfigured action now runs with org-wide admin rights. The blast radius of
> any exploit or logic error grows to the entire org. Least-privilege is a
> non-negotiable design constraint, not a nice-to-have.
>
> **Verify:** Query the affected objects as the agent user's profile + permission
> set combination in Workbench or via Apex `runAs`, confirm records are
> returned, then remove any excess permissions.

---

**Scenario 3 — Draft template not resolving at run time**

> **Situation:** A Flow references a Prompt Builder Flex template to generate a
> follow-up message. In testing the Flow throws a generic error on the Prompt
> Builder step. The template was built last week and tested in the preview pane.
>
> **Competent move:** Check the template's status in Prompt Builder. If it reads
> "Draft" rather than "Active," activate it. A template must be in Active status
> before any Flow, Lightning page, or agent action can invoke it. Reactivate and
> re-run the Flow.
>
> **Tempting-but-wrong:** Assume the error is in the Flow logic, spend time
> debugging elements, or open a support case. The template itself is the issue —
> drafts don't resolve at run time, and the error message is often generic enough
> to mask this.
>
> **Verify:** Open the template in Prompt Builder, confirm status = Active, and
> re-run the Flow in a fresh debug. Add a pre-deploy checklist step that
> verifies all referenced templates are Active.

---

**Scenario 4 — RAG retriever for an org without Data Cloud**

> **Situation:** A solution design calls for a Service Agent grounded on a
> library of internal process PDFs using Data Cloud vector search. The architect
> starts building the Data Library and retriever configuration, then discovers
> the feature is unavailable in Setup.
>
> **Competent move:** Confirm whether Data Cloud is provisioned by checking
> whether Data Cloud DMO/DLO objects appear in the object list, or whether the
> Data Cloud section is visible in Setup. If Data Cloud is absent, RAG / Data
> Library / vector search are unavailable. Pivot to Knowledge articles for
> unstructured grounding (requires Knowledge to be enabled), or scope in Data
> Cloud provisioning as a prerequisite work item with budget and timeline impact.
>
> **Tempting-but-wrong:** Begin building Data Library configurations assuming the
> feature exists, or promise a go-live date without first validating Data Cloud's
> presence. This wastes build effort and sets a delivery date against a
> dependency that hasn't been funded.
>
> **Verify:** Check the object list for Data Cloud objects before any design
> work. Document Data Cloud as a dependency in the solution spec.

---

**Scenario 5 — PII in static grounding bypasses Trust Layer masking**

> **Situation:** To make a record summary template feel more personal, a
> developer pastes a customer's full name and contract ID as fixed example text
> directly into the template body (static grounding) so the model always has
> context about the account structure. The same approach is later used in
> production for real account data.
>
> **Competent move:** Move all record-specific facts — especially anything that
> could be PII (name, ID, contact info, DOB, financial data) — into dynamic
> merge fields resolved at run time. Dynamic merge fields flow through the Trust
> Layer where masking rules apply. Static text in the template is never masked
> regardless of Trust Layer configuration.
>
> **Tempting-but-wrong:** Assume the Trust Layer will mask static text the same
> way it masks dynamic merge-field output. It does not. Static template body
> text is sent to the LLM exactly as written; there is no masking pass applied
> to it.
>
> **Verify:** Review the template's body for any hard-coded record data. Use
> `describe` to enumerate PII fields and ensure each one enters the prompt only
> via a dynamic merge field, never as literal text.

---

## Study resources & relevance

Study resources (official Salesforce + community, practice exams, hands-on environments) and supplemental rules for **Model Builder** and **Agent Channels** (blueprint-covered topics with lower exam weight) are kept in [references/study-resources.md](references/study-resources.md). For NPSP/nonprofit-specific guidance, see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md).

---

*Independent educational content to upskill AI agents. Not affiliated with or endorsed by Salesforce; all trademarks belong to their owners. Guidance only — verify against official documentation and live orgs.*
