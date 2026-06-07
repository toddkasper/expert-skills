# Agentforce Specialist — Study Resources & Relevance

Load-on-demand companion to [../SKILL.md](../SKILL.md). Use when planning a study path for the Agentforce Specialist (AI-201) exam or mapping the operational rules to a nonprofit (NPSP) org.

## Study Resources

### Official Salesforce Resources

| Resource | URL | Notes |
|---|---|---|
| Agentforce Specialist exam page (Trailhead) | https://trailhead.salesforce.com/credentials/agentforcespecialist | Exam guide PDF, official topic weights |
| AI Specialist exam page (legacy) | https://trailhead.salesforce.com/credentials/aispecialist | Redirects; archived guide still linked |
| Cert Prep: Agentforce Specialist module | https://trailhead.salesforce.com/content/learn/modules/cert-prep-agentforce-specialist | Official study module with flashcards |
| Drive Productivity with Salesforce AI (trail) | https://trailhead.salesforce.com/content/learn/trails/drive-productivity-with-einstein-ai | 5 hands-on modules; official cert-prep trail |
| Become an Agentblazer Champion 2026 (trail) | https://trailhead.salesforce.com/content/learn/trails/become-an-agentblazer-champion-2026 | 22 modules from AI fundamentals to hands-on agent building |
| Build Your Path to AI Success (trail) | https://trailhead.salesforce.com/content/learn/trails/build-your-path-to-ai-success-with-salesforce | Broad AI trail; good for prerequisite coverage |
| Agentblazer Status program | https://trailhead.salesforce.com/agentblazer | Structured Champion → Innovator → Legend learning path |
| Trailhead Academy (instructor-led) | https://trailheadacademy.salesforce.com/certificate/exam-agentforce-specialist---AI-201 | Paid; live instruction option |
| Salesforce Admins prep guide | https://admin.salesforce.com/blog/2024/prepare-for-the-salesforce-ai-specialist-exam-and-agentforce | Admin-focused study strategy |
| BYOLLM developer blog | https://developer.salesforce.com/blogs/2024/03/bring-your-own-large-language-model-in-einstein-1-studio | Deep dive on Model Builder + external LLM wiring |

### Community & Third-Party Resources

| Resource | URL | Notes |
|---|---|---|
| Salesforce Ben — Agentforce Specialist guide | https://www.salesforceben.com/salesforce-agentforce-specialist-certification-guide-tips/ | Comprehensive community guide, regularly updated |
| Salesforce Ben — AI to Agentforce rebrand | https://www.salesforceben.com/salesforce-changes-ai-specialist-exam-to-certified-agentforce-specialist/ | Explains what changed in March 2025 |
| Focus on Force — certification guide | https://focusonforce.com/salesforce-certifications/salesforce-ai-specialist-certification-guide/ | Topic-by-topic breakdown + practice questions |
| Apex Hours — certification guide | https://www.apexhours.com/salesforce-ai-specialist-certification-guide/ | Free; good original AI Specialist topic coverage |
| S2 Labs — ultimate guide (2026) | https://s2-labs.com/blog/salesforce-ai-specialist-certification/ | Includes original topic weights + study plan |
| Your Cloud Coach | https://yourcloudcoach.learnworlds.com/blog/salesforce-agentforce-specialist-certification | Skill-by-skill breakdown per domain |
| Salesforce Trail — rebrand details | https://salesforcetrail.com/certified-agentforce-specialist-exam-details/ | Quick facts on the March 2025 transition |
| Trailblazer Community forums | https://trailhead.salesforce.com/trailblazer-community | Study groups, "got certified" posts with tips |

### Practice Exams

- **Focus on Force practice questions:** https://focusonforce.com/salesforce-agentforce-ai-specialist-practice-exams/
- **Salesforce Admins quiz:** https://admin.salesforce.com (search "AI Specialist quiz")
- **Udemy — AI Specialist Exam Prep:** https://www.udemy.com/course/salesforce-certified-ai-specialist-exam-prep/
- **ExamTopics (free, community-sourced):** https://www.examtopics.com/exams/salesforce/certified-ai-specialist/

### Hands-On Practice Environments

- **Developer Edition org with Agentforce:** sign up at https://developer.salesforce.com — free; includes Agentforce and Prompt Builder
- **Data Cloud dev org:** separate signup at Trailhead; required to practice Data Library, chunking, and vector search features
- **Trailhead Playground:** available from any Trailhead module; suitable for most Prompt Builder exercises

---

## Relevance to NPSP & Nonprofit Cloud

As of December 2025, Salesforce stopped offering **NPSP (Nonprofit Success
Pack)** as a preconfigured package in new production orgs, instead positioning
**Agentforce Nonprofit** (built on core Salesforce + Nonprofit Cloud) as the
successor. Existing NPSP orgs remain supported; Salesforce has confirmed no
forced migration or sunsetting.

### Where these skills apply in a nonprofit/NPSP org

**Prompt Builder (high relevance, buildable today):**
- Sales Email templates grounded on custom-object dynamic merge fields for
  constituent outreach — mask PII via the Trust Layer (§6).
- Field Generation for narrative fields surfaced via a Quick Action — size
  output to the field length (verify with `describe`).
- Record Summary for staff triaging incoming records (applications, cases).

**Agentforce agents (medium relevance, often future):**
- An **Employee Agent** answering staff status questions via a Flow action over
  a custom object — least-privilege agent user, replacing manual SOQL.
- A **Service Agent** for public FAQ — needs Knowledge enabled; grounds on
  articles, not RAG.

**Data Cloud / RAG:** Data Cloud is frequently not enabled in lean nonprofit
orgs — Data Library, chunking, and vector search are then out of reach until it
is provisioned. Plan around this; don't assume it.

**Model Builder / BYOLLM:** Low-volume nonprofit workloads rarely justify a
custom model; standard Einstein typically suffices.

**Einstein Trust Layer (always relevant):** every AI feature passes through it;
zero-retention keeps PII/medical data out of external model training. Configure
masking for sensitive document content, SSN, and medical detail explicitly — see §6 in SKILL.md.

---

## Model Builder — supplemental rules

Model Builder (~5% exam weight) is mentioned in the overview but has no dedicated section in SKILL.md. Key operational rules:

- **Use case:** bring an external LLM into Salesforce as a named model configuration and reference it from Prompt Builder templates or agent actions. Appropriate when the default Einstein model doesn't satisfy domain-specific or context-window requirements.
- **Activation sequence:** configure the model connector → test the connection → set it as the active model for the target feature → verify in the preview pane. Each feature (Prompt Builder, agent) has its own active model slot.
- **Trust Layer applies regardless of which model is selected.** Masking, audit trail, and zero-retention are Salesforce-side envelope controls; they don't depend on the downstream model vendor.
- **Don't swap the active model in production without re-testing templates.** Model behavior varies even across versions; re-run preview-pane tests and Testing Center evaluations after any model change.
- **Anti-patterns:** assuming a third-party model has the same token limits as the default Einstein model (context-window mismatches can silently truncate grounded prompts); switching models in production without a rollback plan.

Reference: [BYOLLM developer blog](https://developer.salesforce.com/blogs/2024/03/bring-your-own-large-language-model-in-einstein-1-studio)

---

## Agent channels & conversation design — supplemental rules

Channels and conversation design are not covered in SKILL.md's main sections but appear in the AI-201 exam blueprint. Key operational rules:

- **Channels determine deployment surface.** A Service Agent can be deployed to a web messaging widget, an Experience Cloud site, SMS (via Messaging), or WhatsApp Business. Each channel is configured separately; review agent behavior (tone, capabilities) per channel.
- **Always configure an explicit hand-off to a live agent and an end-of-session action.** An agent without a defined escalation path traps users. The hand-off should transfer conversation context (summary, key entities) to the receiving agent or queue.
- **Conversation design governs the agent's voice.** Set persona, tone, response-length guidance, and topic-level instructions consistently. Mismatched tone across topics signals poor prompt governance.
- **Channel-specific constraints:** SMS and WhatsApp have character or media limits that differ from web widget. Size response templates to the most constrained channel you deploy to, or maintain per-channel variants.
