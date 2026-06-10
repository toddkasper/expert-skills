# Scorecard — aws-security-specialty

- **Skill:** `aws-security-specialty`
- **Assessed:** 2026-06-09
- **Model (auditor):** claude-sonnet-4-6 (static audit)
- **Skill last-reviewed:** 2026-06-09

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | 3 | Description names specific services (GuardDuty, Security Hub, Detective, Security Lake, WAF, Shield, PrivateLink, Macie), states use-when for "designing or reviewing security controls, detection/response automation, or compliance guardrails," names both siblings. ~580 chars. |
| D2 | Scope contract | 3 | Load/Not-this in Overview (pipeline/IaC → devops skill; architecture trade-offs → SAP skill); Uncertainty & Escalation lists concrete escalation triggers. Agent can route without reading body. |
| D3 | Operational depth | 3 | KMS key policy primacy explained with root-delegation mechanics; RCP evaluation layer (late 2023) called out; NACL ephemeral port trap (1024–65535) named; Secrets Manager rotation stages (AWSPENDING/AWSCURRENT/AWSPREVIOUS); IAM Access Analyzer region-scoping trap. |
| D4 | Decision support | 3 | KMS key-type decision table (4 types × 5 dimensions); SG vs NACL comparison table; GuardDuty severity → auto-remediation table; multi-account structure table; denial-list vs allow-list SCP recommendation with constraint. |
| D5 | Failure-mode coverage | 2 | Red flags per section including mechanism (NACL missing ephemeral ports, VPC endpoint with no policy = exfiltration channel); Scenario 1 (VPC endpoint exfiltration) covers trigger+mechanism+fix. Only 1 full scenario in body; 5 more deferred to `references/scenarios.md`. |
| D6 | Verification discipline | 3 | Every section ends with CLI verify commands; IR Workflow 3 has a gate after every step (including snapshot completion before proceeding); `aws iam simulate-principal-policy` for permission testing is present. |
| D7 | Uncertainty & escalation | 3 | Top-of-file block: `[volatile — verify live]` tags on RCP availability, KMS rotation interval, GuardDuty finding families, Shield Advanced pricing; live-wins rule; escalation list includes IR destructive steps (quarantine SG, revoke sessions). |
| D8 | Executable workflows | 3 | Three numbered workflows (cross-account role + trust, KMS key + grants, GuardDuty credential-exfiltration IR); verify gate after each step including negative tests (wrong external ID = AccessDenied). |
| D9 | Teaching scenarios | 3 | 4 scenarios now inline in body (POLICY-format): VPC endpoint exfiltration, IAM Access Analyzer region-scope trap, NACL ephemeral port stall, and GuardDuty severity auto-remediation calibration. references/scenarios.md pointer removed. |
| D10 | Context economy | 2 | 4,355 words — upper end of 3,500–4,300 band; content is dense and operational; exam logistics removed to references. **D10 trim flag: reduce to ≤3,500.** |
| D11 | Freshness & provenance | 2 | `last-reviewed: 2026-06-09`, `blueprint-verified: 2026-06-07` (SCS-C03 December 2025); Changelog records one conformance-pass entry; no per-scar source citations. |
| D12 | Measurability | 2 | Eval infra exists (`situations.md`, `tasks.md`, `answer-key.md`) covering all 6 sections; no model run recorded yet. |
| | **Total** | **32/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: publish-ready**

---

## Lens 2 — Trigger testing

Source phrasings: `evals/aws-security-specialty/triggers.md`. Test against descriptions only (from `/tmp/skills-snapshot.md`).

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| "Review this IAM role policy and SCP — I need to know if any combination of actions allows privilege escalation to administrator." | aws-security-specialty | aws-security-specialty — "IAM policy evaluation and permission boundaries" + "multi-account governance (SCPs…)" | ✓ |
| "Set up GuardDuty findings of HIGH severity to automatically quarantine the affected EC2 instance by replacing its security group with an isolation group via EventBridge + Lambda." | aws-security-specialty | aws-security-specialty — "threat detection (GuardDuty…)" + "incident response and containment" | ✓ |
| "Our KMS customer-managed key policy has `kms:*` on the key for the account root — walk me through the lockout risk and how to fix the key policy safely." | aws-security-specialty | aws-security-specialty — "KMS encryption strategy" + "IAM policy evaluation" | ✓ |
| "Design a detective control stack for our 30-account org: which combination of Security Hub, GuardDuty, Macie, and Config gives us coverage without duplicate alerting?" | aws-security-specialty | aws-security-specialty — "threat detection (GuardDuty, Security Hub, Detective, Security Lake)" + "compliance guardrails" | ✓ |
| "An S3 bucket that holds PII is showing as publicly accessible in Macie. Walk me through all the layers — bucket ACL, bucket policy, Block Public Access, and S3 Access Points — that could be causing it." | aws-security-specialty | aws-security-specialty — "data protection and KMS encryption strategy, Secrets Manager, Macie" | ✓ |
| "Build a CodePipeline that automatically runs `aws configservice start-config-rules-evaluation` after every CloudFormation deployment and pages the team if any rule goes non-compliant." (→ aws-devops-engineer-professional) | aws-devops-engineer-professional | aws-devops-engineer-professional — "CI/CD pipelines (CodePipeline…)" + "building…AWS delivery pipelines" | ✓ |
| "We need to decide between AWS Managed Microsoft AD and Simple AD for our 5,000-user hybrid workforce; compare cost, feature set, and integration with WorkSpaces." (→ aws-solutions-architect-professional) | aws-solutions-architect-professional | aws-solutions-architect-professional — "enterprise AWS design decisions…organizational complexity" + "migration and modernization strategy" (AD is an architecture trade-off) | ✓ |
| "Our Secrets Manager rotation Lambda is failing silently — debug the CloudWatch Logs and fix the Lambda execution role." (→ aws-devops-engineer-professional) | aws-devops-engineer-professional | aws-devops-engineer-professional — "CI/CD pipelines…CloudWatch monitoring and logging…automated remediation" — Lambda debugging with IAM role repair is IaC/observability delivery, not security-control design | ✓ |

**Trigger pass rate: 8/8.**

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/aws-security-specialty/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: none

---

## Notes / trend

D9 is the sole structural blocker. The body needs ≥3 additional POLICY-format scenarios covering the remaining sections: IAM Access Analyzer region-scope trap (§1), NACL ephemeral port stall (§2), S3 Object Lock Compliance vs Governance choice (§3), and/or GuardDuty finding-severity auto-remediation calibration (§4). Moving these from `references/scenarios.md` or authoring them fresh both satisfy the requirement. D10 trim advisory: at 4,355 words a moderate cut after adding D9 content will help hold the word count. The KMS and IR workflow depth (D3, D8) is among the strongest in the portfolio — these should be preserved in any trim.
Cycle-1 curation (2026-06-09): D9 1→3 (4 scenarios now inline) → now publish-ready.
