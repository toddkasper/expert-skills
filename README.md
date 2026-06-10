# Expert Skills

Reusable **agent skills** that upskill AI agents with the operational competence of expert
practitioners — the rules, real limits, decision criteria, and anti-patterns an expert applies
on the job. Built on the open [`SKILL.md`](https://agentskills.io) format and packaged as
Claude Code plugins.

> **The product is AI competence — not certification.** Certification blueprints are used only
> as the *scaffold* (what a competent practitioner must know) and the *benchmark* (the held-out
> evals in [EVALS.md](EVALS.md)). These skills do **not** replace, prepare you for, or confer any
> certification — the certification is simply how the competence is scoped and measured. See
> [POLICY.md](POLICY.md) for the content policy and vendor non-affiliation disclaimer. Skills are
> guidance, not ground truth — verify against live systems and official docs before acting.

## Domains

| Plugin | Skills | Coverage |
|---|---|---|
| [`salesforce/`](salesforce/) | 13 | Administrator, Advanced Administrator, Platform Developer I/II, JavaScript Developer I, Technical Architect, the Consultants, Business Analyst, Agentforce Specialist |
| [`aws/`](aws/) | 3 | Solutions Architect – Professional, DevOps Engineer – Professional, Security – Specialty |
| [`github/`](github/) | 1 | GitHub Actions |
| [`web/`](web/) | 5 | nodejs, typescript, react, nextjs, react-native |

## Install

As a Claude Code plugin marketplace:

```
/plugin marketplace add toddkasper/expert-skills
/plugin install salesforce@expert-skills
```

Installed skills are namespaced, e.g. `/salesforce:salesforce-administrator`. Install only the
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

## Per-org / per-project specialization

The skills are deliberately org-agnostic. To tie a rule to one organization's specific fields,
decisions, or scars, keep a **per-org appendix in your own project** and reference it from that
project's `CLAUDE.md` — keeping the shared skills clean and reusable.

## Contributing & policy

Read [POLICY.md](POLICY.md) before adding skills: original content only, **never** real exam
questions, competence-not-credential framing, and the vendor non-affiliation disclaimer.
Licensed under [MIT](LICENSE).
