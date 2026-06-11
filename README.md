# Expert Skills

[![validate](https://github.com/toddkasper/expert-skills/actions/workflows/validate.yml/badge.svg)](https://github.com/toddkasper/expert-skills/actions/workflows/validate.yml)

Reusable **agent skills** that upskill AI agents with the operational competence of expert
practitioners — the rules, real limits, decision criteria, and anti-patterns an expert applies
on the job. Built on the open [`SKILL.md`](https://agentskills.io) format and packaged as
Claude Code plugins.

> **Unofficial.** Independent educational content — not affiliated with, authorized by, or
> endorsed by Salesforce, Amazon Web Services, GitHub, or any other vendor. All product and
> certification names are trademarks of their owners, used only to identify subject matter.

> **The product is AI competence — not certification.** Certification blueprints are used only
> as the *scaffold* (what a competent practitioner must know) and the *benchmark* (the held-out
> evals in [EVALS.md](EVALS.md)). These skills do **not** replace, prepare you for, or confer any
> certification — the certification is simply how the competence is scoped and measured. See
> [POLICY.md](POLICY.md) for the content policy and vendor non-affiliation disclaimer. Skills are
> guidance, not ground truth — verify against live systems and official docs before acting.

> **Project status:** see [PROJECT-STATUS.md](PROJECT-STATUS.md) for current state, what is
> evidence-backed (Cycle-4 lift), known measurement caveats, and the resume checklist.

## Domains

| Plugin | Skills | Coverage |
|---|---|---|
| [`salesforce/`](salesforce/) | 13 | Administrator, Advanced Administrator, Platform Developer I/II, JavaScript Developer I, Technical Architect, the Sales/Service/Experience/Nonprofit Consultants, Marketing Cloud Email Specialist, Business Analyst, Agentforce Specialist |
| [`aws/`](aws/) | 3 | Solutions Architect – Professional, DevOps Engineer – Professional, Security – Specialty |
| [`github/`](github/) | 1 | GitHub Actions |
| [`web/`](web/) | 5 | nodejs, typescript, react, nextjs, react-native |

## Install

As a Claude Code plugin marketplace:

```
/plugin marketplace add toddkasper/expert-skills
/plugin install salesforce-skills@expert-skills
```

Installed skills are namespaced, e.g. `/salesforce-skills:salesforce-administrator`. Install only the
plugins a project needs — progressive disclosure keeps context lean (only each skill's short
description is always loaded; the full body loads on demand when relevant).

**Without installing:** point a project's `CLAUDE.md` at the relevant `SKILL.md`, or clone the
repo. Claude Code also auto-discovers skills in `~/.claude/skills/` or a project's `.claude/skills/`.

## How skills work

Each skill is a directory with a `SKILL.md` (YAML metadata + instructions) and an optional
`references/` folder loaded on demand (progressive disclosure). All skills follow one
**standardized anatomy** — see [TEMPLATE.md](TEMPLATE.md): a task-vocabulary `description`, an
Overview + Scope block, numbered domain sections with the rules→decision-table→red-flags→verify
rhythm, decision scenarios, a deduped DO/DON'T quick reference, and a disclaimer. Frontmatter
carries **freshness metadata** (`last-reviewed`, and `blueprint-verified` where a cert applies)
so a reader can tell how stale any claim might be; exam logistics live in
`references/study-resources.md`, never in the body. Every skill is measured by a held-out
competence eval — method in [EVALS.md](EVALS.md), the executable protocol in
[evals/run-eval.md](evals/run-eval.md), and the scoreboard in [evals/RESULTS.md](evals/RESULTS.md).

## Quality standard & learning loop

Every skill is held to a 12-dimension rubric ([docs/SKILL-STANDARD.md](docs/SKILL-STANDARD.md)) —
trigger precision, operational depth, decision support, failure-mode coverage, verification
discipline, uncertainty/escalation behavior, executable workflows, and more (publish bar: no
dimension below 2, total ≥ 28/36). Skills are exercised, not just read, through a five-lens
assessment ([docs/ASSESSMENT.md](docs/ASSESSMENT.md): static audit, trigger tests, knowledge
eval, application eval, adversarial freshness audit), recorded per skill in
[evals/scorecards/](evals/scorecards/) and trended in [evals/RESULTS.md](evals/RESULTS.md).

Skills improve from real use through a closed loop ([docs/LEARNING-LOOP.md](docs/LEARNING-LOOP.md)):
each `SKILL.md` carries a **Feedback Protocol** footer telling the using agent to log gaps and
contradictions to a project-local `.skill-feedback/<skill>.md`; `scripts/harvest-feedback.sh`
collects those into [feedback/INBOX.md](feedback/INBOX.md), where a curation pass validates each
item against official docs, integrates accepted ones, and closes the loop with a new held-out
eval scenario + a changelog entry + a `last-reviewed` bump.

## For consuming projects

When a skill is loaded into your project and you hit a wrong, missing, or ambiguous claim, the
skill's **Feedback protocol** footer tells the agent to log it to `.skill-feedback/<skill>.md`
at your project root. To get those lessons back into the skills:

- **Commit `.skill-feedback/`** in your project (don't gitignore it) so the entries persist, then
  either run `scripts/harvest-feedback.sh /path/to/your/project` from a clone of this repo, or
- **File a [skill-feedback issue](../../issues/new?template=skill-feedback.yml)** — the human
  channel into the same curation pipeline.

Either way the entry is validated against official docs before any skill changes (see
[docs/LEARNING-LOOP.md](docs/LEARNING-LOOP.md)). Concrete evidence (a doc URL, error text, query
output) is what lets a report be accepted rather than deferred.

## Per-org / per-project specialization

The skills are deliberately org-agnostic. To tie a rule to one organization's specific fields,
decisions, or scars, keep a **per-org appendix in your own project** and reference it from that
project's `CLAUDE.md` — keeping the shared skills clean and reusable.

## Contributing & policy

Read [CONTRIBUTING.md](CONTRIBUTING.md) for the author → validate → scorecard → eval → publish
sequence, and [POLICY.md](POLICY.md) for the content rules: original content only, **never** real
exam questions, competence-not-credential framing, and the vendor non-affiliation disclaimer.
Licensed under [MIT](LICENSE).
