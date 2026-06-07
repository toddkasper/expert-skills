# AWS Skills

A Claude Code **plugin** that upskills an agent with the operational competence of expert AWS
practitioners — Professional tier plus the Security Specialty.

> **Not test-prep.** The AWS certifications below are used as the *scaffold and benchmark* for
> these skills, not the product — see [../POLICY.md](../POLICY.md). Skills are guidance, not
> ground truth: AWS changes service limits, pricing, and exam facts often, so verify against
> official docs and the live account before acting.

## Install (as a plugin)

```
/plugin marketplace add toddkasper/expert-skills
/plugin install aws@expert-skills
```

## Skills

| Domain (scaffold) | Exam code | Skill |
|---|---|---|
| Solutions Architect – Professional | SAP-C02 | [aws-solutions-architect-professional](skills/aws-solutions-architect-professional/SKILL.md) |
| DevOps Engineer – Professional | DOP-C02 | [aws-devops-engineer-professional](skills/aws-devops-engineer-professional/SKILL.md) |
| Security – Specialty | SCS-C03 | [aws-security-specialty](skills/aws-security-specialty/SKILL.md) |

*Associate and other Specialty domains can be added later following the same pattern.*
