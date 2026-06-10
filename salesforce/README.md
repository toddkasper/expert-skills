# Expert Skills for Salesforce Certification Domains (unofficial)

A Claude Code **plugin** that upskills an agent with the operational competence of expert
Salesforce practitioners. Thirteen skills, each scoped to a certification's domain (used as the
scaffold and benchmark) and rewritten into actionable rules, decision tables, real limits, and
anti-patterns.

> **Unofficial — not affiliated with, authorized by, or endorsed by Salesforce, Inc.**
> "Salesforce," "Agentforce," "NPSP," and related marks are trademarks of Salesforce, Inc., used
> here only to identify the subject matter. **This is not test-prep** — certification blueprints
> are used only as a map of *what a competent practitioner knows*. These files are **guidance,
> not ground truth** — verify against the live org (your Salesforce MCP server or the `sf` CLI)
> before acting. Full policy and disclaimer: [POLICY.md](POLICY.md) · License: [LICENSE](LICENSE).

## Install (as a plugin)

```
/plugin marketplace add toddkasper/expert-skills
/plugin install salesforce-skills@expert-skills
```

Skills are then available namespaced, e.g. `/salesforce-skills:salesforce-administrator`. You can
also just point a project's `CLAUDE.md` at `salesforce/skills/<name>/SKILL.md` directly.

## Structure

Each skill is a spec-compliant [`SKILL.md`](https://agentskills.io) directory under
`skills/`, with deeper material (study resources, deep-dives) in its own `references/`
folder, loaded on demand.

## Task → Skill routing

| Task | Skill |
|---|---|
| SOQL, Apex, triggers, governor limits, testing | [salesforce-platform-developer-1](skills/salesforce-platform-developer-1/SKILL.md) |
| Advanced Apex, async, integration, REST/SOAP, platform events | [salesforce-platform-developer-2](skills/salesforce-platform-developer-2/SKILL.md) |
| NPSP / Nonprofit Cloud, Household Accounts, donations, donor mgmt | [salesforce-nonprofit-cloud-consultant](skills/salesforce-nonprofit-cloud-consultant/SKILL.md) |
| FLS, permission sets, profiles, flows, validation rules, object model | [salesforce-administrator](skills/salesforce-administrator/SKILL.md) |
| Complex automation, data management at scale, troubleshooting | [salesforce-advanced-administrator](skills/salesforce-advanced-administrator/SKILL.md) |
| Requirements, user stories, process mapping, UAT | [salesforce-business-analyst](skills/salesforce-business-analyst/SKILL.md) |
| LWC, JavaScript, front-end components | [salesforce-javascript-developer-1](skills/salesforce-javascript-developer-1/SKILL.md) |
| Enterprise architecture, data/security/integration design, end-to-end trade-offs | [salesforce-technical-architect](skills/salesforce-technical-architect/SKILL.md) |
| Portals, communities, digital experiences | [salesforce-experience-cloud-consultant](skills/salesforce-experience-cloud-consultant/SKILL.md) |
| Email automation, journeys, deliverability | [salesforce-marketing-cloud-email-specialist](skills/salesforce-marketing-cloud-email-specialist/SKILL.md) |
| Sales process, opportunities, forecasting | [salesforce-sales-cloud-consultant](skills/salesforce-sales-cloud-consultant/SKILL.md) |
| Cases, console, knowledge, service automation | [salesforce-service-cloud-consultant](skills/salesforce-service-cloud-consultant/SKILL.md) |
| Agentforce, Prompt Builder, Data Cloud AI, Trust Layer | [salesforce-agentforce-specialist](skills/salesforce-agentforce-specialist/SKILL.md) |

## Full index

**Administrator** — [salesforce-administrator](skills/salesforce-administrator/SKILL.md) · [salesforce-advanced-administrator](skills/salesforce-advanced-administrator/SKILL.md)

**Developer** — [salesforce-platform-developer-1](skills/salesforce-platform-developer-1/SKILL.md) · [salesforce-platform-developer-2](skills/salesforce-platform-developer-2/SKILL.md) · [salesforce-javascript-developer-1](skills/salesforce-javascript-developer-1/SKILL.md)

**Architect** — [salesforce-technical-architect](skills/salesforce-technical-architect/SKILL.md)

**Consultant** — [salesforce-nonprofit-cloud-consultant](skills/salesforce-nonprofit-cloud-consultant/SKILL.md) · [salesforce-sales-cloud-consultant](skills/salesforce-sales-cloud-consultant/SKILL.md) · [salesforce-service-cloud-consultant](skills/salesforce-service-cloud-consultant/SKILL.md) · [salesforce-experience-cloud-consultant](skills/salesforce-experience-cloud-consultant/SKILL.md)

**Specialist** — [salesforce-marketing-cloud-email-specialist](skills/salesforce-marketing-cloud-email-specialist/SKILL.md) · [salesforce-business-analyst](skills/salesforce-business-analyst/SKILL.md) · [salesforce-agentforce-specialist](skills/salesforce-agentforce-specialist/SKILL.md) *(formerly "AI Specialist")*
