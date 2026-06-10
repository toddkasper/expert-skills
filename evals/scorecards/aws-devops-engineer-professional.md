# Scorecard — aws-devops-engineer-professional

- **Skill:** `aws-devops-engineer-professional`
- **Assessed:** 2026-06-09
- **Model (auditor):** claude-sonnet-4-6 (static audit)
- **Skill last-reviewed:** 2026-06-09

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | 3 | Description leads with task-vocab terms (CodePipeline, CodeBuild, canary, SSM, CloudWatch auto-remediation); explicit use-when + scope boundary naming both siblings; ~580 chars. |
| D2 | Scope contract | 3 | Load/Not-this block in Overview and Uncertainty & Escalation section together cover all routing; an agent can load/skip/route without reading the body. |
| D3 | Operational depth | 3 | Mechanism-level throughout: hook-callback requirement for stuck blue/green, CMK vs SSE-S3 cross-account artifact bucket, `INSUFFICIENT_DATA` ≠ OK alarm state, SSM doc type distinction (Command vs Automation). |
| D4 | Decision support | 3 | Five decision tables (deployment strategy, IaC tool, Route 53 policies, DR RTO/RPO, SQS/SNS/EventBridge) — each row has the constraint driving the choice. |
| D5 | Failure-mode coverage | 2 | Red flags per section with mechanism; Scenario 1 (stuck ECS blue/green lifecycle hook) covers trigger+mechanism+fix+detect. Only 1 full scenario in body; 5 more deferred to `references/scenarios.md` — not available on body-only load. |
| D6 | Verification discipline | 3 | Every section ends with copy-runnable `aws` CLI commands in tool-agnostic preamble; three workflow-level gate patterns per Executable Workflow section. |
| D7 | Uncertainty & escalation | 3 | Dedicated block at top: volatile-fact tags inline (`[volatile — verify live]`), live-wins rule, explicit escalation list (stack deletes, KMS changes, GuardDuty disable), confidence taxonomy. |
| D8 | Executable workflows | 3 | Three numbered end-to-end workflows (blue/green rollback, CodePipeline with approval gates, Config→EventBridge→SSM remediation); verify gate after every numbered step. |
| D9 | Teaching scenarios | 1 | Only 1 full POLICY-format scenario in the SKILL.md body; 5 additional scenarios are pointer-only (`references/scenarios.md`) — not loaded at runtime. Standard requires ≥4 original in-body. |
| D10 | Context economy | 2 | 4,483 words — in 3,500–4,300 band (snapshot word count 4,483 is just above the band upper limit per snapshot); all tokens serve operational competence; exam logistics removed to references. **D10 trim flag: cut to ≤3,500.** |
| D11 | Freshness & provenance | 2 | `last-reviewed: 2026-06-09`, `blueprint-verified: 2026-06-07`; Changelog records one conformance-pass entry; no per-scar source citations yet. |
| D12 | Measurability | 2 | Eval infra exists (`situations.md`, `tasks.md`, `answer-key.md`) and coverage spans all 6 sections; no model run recorded yet in RESULTS.md. |
| | **Total** | **30/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: needs content pass**

Sub-2 dimensions filed as inbox items: **D9** (only 1 of ≥4 required teaching scenarios present in SKILL.md body).

---

## Lens 2 — Trigger testing

Source phrasings: `evals/aws-devops-engineer-professional/triggers.md`. Test against descriptions only (from `/tmp/skills-snapshot.md`).

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| "Our CodePipeline manual-approval stage is skipping when no one approves within the timeout — how do I configure a rejection action and notify the team?" | aws-devops-engineer-professional | aws-devops-engineer-professional — "CI/CD pipelines (CodePipeline…)" + "building, reviewing, or debugging AWS delivery pipelines" | ✓ |
| "Walk me through adding a canary deployment strategy to our CodeDeploy application so we shift 10% of traffic and automatically roll back if the error-rate alarm fires." | aws-devops-engineer-professional | aws-devops-engineer-professional — "deployment strategies (blue/green, canary)" + "debugging AWS delivery pipelines" | ✓ |
| "Our CloudFormation drift detection job is running but never auto-remediates — review this EventBridge + SSM Automation setup and tell me what's broken." | aws-devops-engineer-professional | aws-devops-engineer-professional — "infrastructure as code (CloudFormation…Systems Manager)" + "auto-remediation" | ✓ |
| "I need a buildspec.yml that pulls DB credentials from Parameter Store at build time instead of hardcoding them as environment variables." | aws-devops-engineer-professional | aws-devops-engineer-professional — "CI/CD pipelines (CodeBuild)" + "IaC templates" | ✓ |
| "Help me design a multi-region CodePipeline that deploys to us-east-1 first, waits for a CloudWatch alarm to be healthy, then promotes to eu-west-1." | aws-devops-engineer-professional | aws-devops-engineer-professional — "CodePipeline" + "resilient multi-AZ/multi-region design" + "CloudWatch monitoring" | ✓ |
| "Design a transit-gateway-based hub-and-spoke architecture to connect 15 VPCs across four AWS accounts." (→ aws-solutions-architect-professional) | aws-solutions-architect-professional | aws-solutions-architect-professional — "hybrid and cross-account networking (Transit Gateway…)" + "enterprise AWS design decisions" | ✓ |
| "Our KMS key policy is blocking cross-account decrypt calls — review it for privilege-escalation risks and wildcard permissions." (→ aws-security-specialty) | aws-security-specialty | aws-security-specialty — "IAM policy evaluation and permission boundaries" + "KMS encryption strategy" | ✓ |
| "Write a GuardDuty findings processor that automatically revokes EC2 instance profile credentials when a credential-exfiltration finding fires." (→ aws-security-specialty) | aws-security-specialty | aws-security-specialty — "threat detection (GuardDuty…)" + "incident response and containment" | ✓ |

**Trigger pass rate: 8/8.**

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/aws-devops-engineer-professional/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: none

---

## Notes / trend

D9 is the sole blocker. The body needs at least 3 additional POLICY-format scenarios (Situation → Competent move → Tempting-but-wrong → Verify) moved from `references/scenarios.md` into SKILL.md, or written fresh to cover the remaining sections (IaC drift, monitoring alarm states, incident response diagnosis flow, IAM at scale). D10 trim is advisory: 4,483 words is just above the ~3,500 target; a trim pass after D9 content is added will be necessary to avoid a score regression. D11 will improve once field-feedback-driven changes cite their source entries.
