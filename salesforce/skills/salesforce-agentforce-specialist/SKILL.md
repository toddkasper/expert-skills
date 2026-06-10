---
name: salesforce-agentforce-specialist
description: Building and governing Salesforce Agentforce and generative-AI features — Agentforce agents (topics, actions, agent-user security, the reasoning loop), Prompt Builder templates (Sales Email, Field Generation, Record Summary, Flex), Data 360 (formerly Data Cloud) and Knowledge grounding/RAG, and the Einstein Trust Layer (data masking, zero-retention, audit). Use when implementing or reviewing agents, prompt templates, grounding, or AI guardrails. Not admin-level Agentforce permission setup alone (see salesforce-administrator) or Apex action-code internals (see salesforce-platform-developer-2). Scoped and benchmarked by the Agentforce Specialist (AI-201) blueprint.
metadata:
  anchor-credential: Salesforce Certified Agentforce Specialist
  exam-code: AI-201
  domain: salesforce
  type: certification-playbook
  status: current
  last-reviewed: 2026-06-10
  blueprint-verified: 2026-06-07
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
Builder, Agentforce agents (formerly Einstein Copilot), Model Builder, Data 360
(formerly Data Cloud) grounding, and the Einstein Trust Layer. This document is
an **operational playbook**, not an exam outline: every section states the rule
as an actionable instruction, the real limits, the decision criteria, and the
anti-patterns to catch in review.

> **Product rename (Oct 2025):** Salesforce **Data Cloud** was renamed
> **Data 360** at Dreamforce on October 13, 2025. The underlying product,
> licenses, data model, and integrations are unchanged. This document uses
> "Data 360 (formerly Data Cloud)" on first use and "Data 360" thereafter.

The certification sits between entry-level **AI Associate** (conceptual, no
hands-on) and senior architecture credentials. Recommended (not required)
prior knowledge: Salesforce Administrator or Platform App Builder.

> **Load this skill when…** building or reviewing Agentforce agents (topics, actions, agent-user security); creating Prompt Builder templates (Sales Email, Field Generation, Record Summary, Flex); configuring Data 360 (formerly Data Cloud) grounding or Knowledge RAG for a prompt or agent; or reviewing Einstein Trust Layer settings (data masking, zero-retention, audit trail).
> **Not this skill:** admin-level Agentforce permission setup (enabling features, assigning licenses) without building an agent → see `salesforce-administrator`; writing the Apex code behind an agent action → see `salesforce-platform-developer-2`.

> **Deeper context:** Study resources live in [references/study-resources.md](references/study-resources.md) (loaded on demand). For org-specific applications of these rules, see a per-org appendix you maintain in your own project, referenced from a CLAUDE.md. For NPSP/nonprofit-specific guidance, see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md).

> **Verify steps assume nothing about your tooling** — use your project's Salesforce MCP connection, the Salesforce CLI (`sf`), or the Salesforce setup UI, in that order of preference.

---

Credential logistics and study path: see [references/study-resources.md](references/study-resources.md).

---

## Uncertainty & Escalation

- **Always re-verify live:** `[volatile — verify live]` items include: Agentforce agent type availability per edition and license (Service Agent, SDR Agent, Sales Coach Agent), Prompt Builder template type capabilities across releases, Data 360 RAG/Data Library feature availability, Einstein Trust Layer masking configuration UI paths, and AI-201 blueprint topic weights.
- **Live wins:** when this file and the live org or official AI-201 blueprint disagree — for example, a template type added or renamed in a recent release — trust the live system and flag this skill as stale via the Feedback protocol below.
- **Escalate to a human:** surface — never silently execute — any configuration that points an agent at sensitive or PII-containing records without first verifying the running-user's FLS and sharing scope, grants an agent user a broad profile or "Modify All" permission, publishes a prompt template with no Trust Layer masking review for sensitive fields, or configures a production agent without Testing Center validation.
- **Confidence taxonomy:** every fact in this file is considered stable unless tagged `[volatile — verify live]` or `[opinion — house style]`.

Inline volatile tags applied:
- Agent type roster (Service Agent, SDR Agent, Sales Coach Agent, Employee Agent) `[volatile — verify live]` — new agent types are introduced each release; verify available types in your org's Agentforce Setup.
- AI Associate credential retired "in early 2026" `[volatile — verify live]` — retirement dates and credential transitions are announced on Trailhead; verify current status.
- Data 360 (formerly Data Cloud) RAG / Data Library / vector search availability `[volatile — verify live]` — requires Data 360 provisioning; feature names and configuration paths change across releases.
- Einstein Trust Layer masking configuration for custom fields `[volatile — verify live]` — masking entity configuration UI and defaults evolve; verify which custom fields require explicit registration in your org's current release.

---

## 1. Prompt Engineering & Prompt Builder (20%) [volatile — verify live]

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
  data providers, (d) **Data 360 RAG retriever** for unstructured content.
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

## 2. AI Agents — agents, topics, actions, security (35% — largest domain) [volatile — verify live]

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

## 3. Data 360 (formerly Data Cloud) for Agentforce — grounding (20%) [volatile — verify live]

### The rules

- **Data 360 must be enabled before any Data Library / RAG feature exists.**
  RAG grounding, vector search, and Data Library are not available in an org
  without first provisioning Data 360 (formerly Data Cloud). Don't design a
  solution that assumes them unless Data 360 is confirmed enabled.
- **Use the Data Library for unstructured grounding** (PDFs, Knowledge articles,
  uploaded files, Data 360 objects). Structured CRM facts should still come
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

- Designing RAG features for an org where Data 360 isn't enabled → the build
  won't have the objects.
- Using vector search for exact-ID lookups → keyword is faster and exact.
- One giant chunk per document → poor retrieval relevance.

### Verify against the live org

- Confirm Data 360 presence/absence by checking whether Data 360 DMO/DLO
  objects appear in the object list. Treat Data 360 features as a future,
  post-provisioning capability if they're absent.

---

## 4. Development Lifecycle — testing, deployment, adoption (20%) [volatile — verify live]

> **Blueprint note:** Development Lifecycle is a top-level AI-201 domain (≈20%). Service Cloud and Sales Cloud are **not** standalone exam domains; their agent patterns are covered within §2 (AI Agents). The key Service/Sales guard-rules are retained below.

### The rules

- **Test with Agentforce Testing Center before any production release.** Author test utterances covering happy-path, adversarial/out-of-scope, and edge cases (record not found, ambiguous input). Review both **trustworthiness** and **topic-and-action accuracy** scores — these are quality signals to iterate on, not a binary pass/fail.
- **Deploy agent metadata + backing automation + agent user together.** A change set or metadata deployment that includes the agent Bot, topics, and prompt templates must also include the backing Flows/Apex. The agent user, their profile, and permission set assignments must exist in the target org. Missing any of these three layers is the most common cutover failure.
- **Activation does not travel with deployment.** A Prompt Builder template deployed via change set lands in Draft status in the target org. Reactivate it in Prompt Builder before the agent action can invoke it.
- **Monitor adoption post-launch.** Review agent conversation logs, escalation rates, and topic-accuracy scores in production. Falling trustworthiness scores or rising escalation rates are signals that topic instructions or action logic needs iteration.

**Service/Sales agent guard-rules (no standalone exam domains; patterns sit within AI Agents):** ground service agents on Knowledge articles and always configure an escalation/hand-off path; confirm `Case`/`KnowledgeArticleVersion` are in use before proposing a Service Cloud-grounded agent; don't force-fit SDR/Coach agents to orgs with no sales pipeline (see [salesforce-nonprofit-cloud-consultant](../salesforce-nonprofit-cloud-consultant/SKILL.md)). Full feature-to-scenario tables and cloud-specific anti-patterns: [references/study-resources.md](references/study-resources.md).

Anti-patterns: (a) "it worked in sandbox" as a production gate — always run Testing Center in the production org post-deploy; (b) deploying the agent Bot without its backing Flows or agent user → every action fails at run time; (c) assuming a deployed template is Active — reactivate it in the target org.

---

## 5. Multi-Agent Interoperability (5%) [volatile — verify live]

Key operational rules: use MCP for agent-to-agent communication; use Agent API to trigger an Agentforce agent from an external system or orchestrator; design each agent with a single responsibility. Least-privilege applies to every agent in a multi-agent network — inter-agent calls do not expand the called agent's access. Trust Layer masking and audit apply to all AI calls regardless of call origin.

Full rules, anti-patterns, and A2A protocol decision criteria: [references/study-resources.md](references/study-resources.md).

---

## 6. Einstein Trust Layer & data protection (woven through all domains)

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
- **DO** deploy agent metadata + backing Flows/Apex + agent user + permission sets together to the target org — omitting any layer causes run-time failures.
- **DO** test in Agentforce Testing Center with happy-path, adversarial, and edge-case utterances before production; run the same set post-deployment in prod; treat trustworthiness/topic-accuracy scores as iteration signals, not a binary gate.
- **DO** reactivate a Prompt Builder template in the target org after deployment; activation status does not travel with a change set.
- **DO** pick search type by query shape: keyword for exact IDs, vector for conceptual, hybrid as production default.
- **DON'T** assume Data 360 / Data Library / RAG features exist unless Data 360 (formerly Data Cloud) is confirmed enabled.
- **DON'T** propose Sales Cloud agents (SDR/Coach/pipeline) for an org with no sales pipeline.
- **DON'T** build a single "super-agent" for multi-agent workflows — compose focused specialist agents and use MCP/Agent API for orchestration.
- **DO** configure Trust Layer masking explicitly for SSN, medical, DOB, and PII fields; **DON'T** assume defaults cover custom fields.
- **DO** keep the Trust Layer audit trail on — it's the compliance record. **DON'T** put PII/sensitive content in static grounding or logs.
- **DO** verify field API names + lengths + FLS with `describe` before wiring merge fields or agent actions.
- **DO** dry-run an action's SOQL as the agent user before trusting it.

---

## Executable Workflows

### Workflow 1 — Build and ship an agent topic + action with a least-privilege agent user

1. Create a dedicated named Salesforce user for the agent. Assign a minimal base profile (e.g. Minimum Access). Do NOT assign System Administrator or any "Modify All" permission.
   → gate: user created; profile confirmed as restrictive in Setup.
2. Identify exactly which objects and fields the agent's action(s) will read or write. Create a permission set granting only those object permissions and FLS (`readable`/`editable` as needed).
   → gate: describe each object as the agent user (or via `runAs` in Apex) — only the required objects/fields are accessible.
3. In Agent Builder, create the agent topic: write a tight scope description and explicit instructions including "when NOT to use this topic."
   → gate: topic scope is narrower than the default; Testing Center correctly routes a representative utterance to this topic and not to an unrelated one.
4. Build the action (Flow preferred over Apex when both work). Wire it to the topic. Dry-run the underlying SOQL/DML as the agent user before activating.
   → gate: SOQL returns the expected records as the agent user; no `INSUFFICIENT_ACCESS` error.
5. Test in Agentforce Testing Center with at least one happy-path utterance, one out-of-scope utterance, and one edge case (e.g. record not found). Review trustworthiness and topic-accuracy scores.
   → gate: scores meet your quality bar; misrouted utterances are addressed by tightening topic instructions.
6. Deploy the agent, its backing Flows/Apex, the agent user, and the permission set together to the target org. Confirm the agent user exists and the permission set is assigned before activating the agent.
   → gate: post-deploy query confirms agent user + permset assignment; agent activates without errors.

---

### Workflow 2 — Build a grounded Field Generation prompt template safely (match field length, dynamic grounding)

1. Describe the target object: confirm the exact API name and character length of the destination field before writing the template.
   → gate: field length is documented; template's max-output instruction will be set to this value or below.
2. Identify all facts the template needs. Map each to a dynamic merge field (resolved at run time from the record or a related object via lookup traversal). Do NOT paste any record data as static text in the template body.
   → gate: zero hard-coded record facts in the template body; all variable content enters via merge fields.
3. Build the template in Prompt Builder as Field Generation type. Set an explicit max-output instruction in the prompt that matches (or is below) the field length from step 1. Assign the template's object/field target.
   → gate: template compiles; preview pane output is within field length on a real sandbox record.
4. Activate the template. Verify status = Active before referencing it from a Flow, page, or agent action.
   → gate: template status shows "Active" in Prompt Builder; draft templates don't resolve at run time.
5. Review Trust Layer masking configuration: confirm that any PII or sensitive fields flowing through merge fields are registered for masking. Verify in the Trust Layer audit trail after the first run.
   → gate: audit trail entry for the template invocation shows masked tokens where PII fields were grounded; no raw PII visible in the audit log.

---

### Workflow 3 — Diagnose "agent can't access a record" (running-user CRUD → FLS → sharing)

1. Identify the agent user: check which named Salesforce user the agent is configured to run as in Agent Builder.
   → gate: agent user identity confirmed.
2. Check object-level CRUD: as the agent user's profile + permission set combination, confirm the target object has Read (and Write if needed) access. SOQL `SELECT Id FROM Object__c LIMIT 1` as the agent user is the definitive test.
   → gate: object access confirmed or denied — if denied, add to the permission set and retest.
3. Check FLS: describe the object as the agent user and verify every field the action queries or writes is listed as accessible/editable. A missing field returns `INVALID_FIELD` in SOQL even with full object access.
   → gate: describe returns each required field with `accessible: true`; add missing fields to the permission set's `<fieldPermissions>`.
4. Check sharing: verify the agent user can see the specific record. OWD Private + no sharing rule means the agent user sees only records it owns. Confirm via `SOQL WHERE Id = '<RecordId>'` as the agent user.
   → gate: the specific record appears in the query result as the agent user; if not, add a sharing rule or adjust OWD.
5. If all three checks pass but the action still fails, inspect the Apex action's SOQL for hard-coded profile or role filters that might exclude the agent user.
   → gate: no phantom filter; action returns expected data in a test run logged as the agent user.

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

**Scenario 4 — RAG retriever for an org without Data 360**

> **Situation:** A solution design calls for a Service Agent grounded on a
> library of internal process PDFs using Data 360 (formerly Data Cloud) vector
> search. The architect starts building the Data Library and retriever
> configuration, then discovers the feature is unavailable in Setup.
>
> **Competent move:** Confirm whether Data 360 is provisioned by checking
> whether Data 360 DMO/DLO objects appear in the object list, or whether the
> Data 360 section is visible in Setup. If Data 360 is absent, RAG / Data
> Library / vector search are unavailable. Pivot to Knowledge articles for
> unstructured grounding (requires Knowledge to be enabled), or scope in Data
> 360 provisioning as a prerequisite work item with budget and timeline impact.
>
> **Tempting-but-wrong:** Begin building Data Library configurations assuming the
> feature exists, or promise a go-live date without first validating Data 360's
> presence. This wastes build effort and sets a delivery date against a
> dependency that hasn't been funded.
>
> **Verify:** Check the object list for Data 360 objects before any design
> work. Document Data 360 as a dependency in the solution spec.

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

## Feedback protocol

Using this skill and hit a wall? If you find a claim contradicted by the live system or official docs, a missing rule that cost you a wrong attempt, or a decision this skill gave no criteria for — append an entry **in the moment** to `.skill-feedback/salesforce-agentforce-specialist.md` at the project root (create it if absent):

`date | skill last-reviewed | claim or gap | what you observed instead | evidence (error text / doc URL / query output) | suggested fix`

These are harvested back into the skill via the learning loop. When the live system and this file disagree, trust the live system.

---

## Changelog

- **2026-06-10** — Cycle-4 curation (inbox): (1) Blueprint reweight: §1 Prompt Engineering corrected from 30% → 20%; §2 AI Agents corrected from 30% → 35% (largest domain); "largest topic" label removed from Prompt Engineering and moved to AI Agents. (2) New top-level sections added: §4 Development Lifecycle (20%) and §5 Multi-Agent Interoperability (5%) — both are current AI-201 exam domains. Service Cloud / Sales Cloud guard-rules folded into §4 (no longer standalone 10%-each framing). (3) Data Cloud → Data 360 rename (Dreamforce Oct 2025): all body occurrences updated; "Data 360 (formerly Data Cloud)" on first use, description field, volatile tags, scenarios, quick reference, and study-resources. (4) Passing score: 72% → 73% (44/60) `[volatile — verify live]` in study-resources.md. Sources: salesforceben.com/salesforce-agentforce-specialist-certification-guide-tips/ (domain weights, passing score); salesforceben.com/salesforce-data-cloud-renamed-to-data-360-as-part-of-agentforce-360/ (Data 360 rename). Domain percentages marked `[volatile — verify live]`.
- **2026-06-09** — Conformed to the 12-dimension skill standard: task-vocab description + Scope block, Uncertainty & Escalation guidance with inline `[volatile — verify live]` marks, executable workflows, tool-agnostic verify steps, and the feedback protocol above. Exam logistics relocated to references/study-resources.md; `last-reviewed` set to 2026-06-09.

---

*Independent educational content to upskill AI agents. Not affiliated with or endorsed by Salesforce; all trademarks belong to their owners. Guidance only — verify against official documentation and live orgs. No certification outcome is implied or guaranteed.*
