# Feedback Inbox

The single intake queue for the continuous learning loop ([../docs/LEARNING-LOOP.md](../docs/LEARNING-LOOP.md)).
Three sources file here: **field** (harvested `.skill-feedback/*.md` from consuming projects, via
`scripts/harvest-feedback.sh`), **eval** (failed/partial Lens 3–4 scenarios), and **audit**
(Lens 1/2/5 findings). Curation validates each item against official docs, then integrates,
rejects (with reason), or defers.

Status legend: `new` · `validated` · `rejected` · `integrated`.

> **Cycle 1 (2026-06-09):** the 8 audit findings below were all validated against the standard
> and **integrated** the same day via the curation pass — 7× D9 (inlined ≥4 decision scenarios
> into the body) and 1× D10 (moved niche detail to references). See each skill's `## Changelog`
> and updated scorecard. This is the learning loop run end-to-end on its own first findings.
>
> **Cycle 2 (2026-06-10):** the 23 Lens 3–5 findings below (salesforce-administrator ×8, react
> ×7 incl. an answer-key defect, aws-security-specialty ×8 — audit + eval source) were validated
> against the cited official sources and **integrated** the same day: corrected facts (External
> ID 25, group-task 100, RCP Nov-2024 + scoping, useTransition→useDeferredValue), the react
> answer-key scenario-6 fix, coverage additions (Lightning App Builder, Domain-1 logging, React
> 19.2 hooks), and a held-out eval scenario per lesson (situations grew 12→18 for each). Post-2024
> facts marked `[volatile — verify live]`. Lens 3/4 re-run against live models is pending.

| Date | Skill | Source | Severity | Summary | Evidence | Status |
|---|---|---|---|---|---|---|
| 2026-06-09 | salesforce-experience-cloud-consultant | audit | high | D9=1: all 5 decision scenarios deferred to references; body has 0 inline → fails publish bar | scorecards/salesforce-experience-cloud-consultant.md | integrated (curation 2026-06-09) |
| 2026-06-09 | salesforce-business-analyst | audit | high | D10=1: body 5,086 words (>5,000) → fails publish bar; trim Quick Reference + niche prose | scorecards/salesforce-business-analyst.md | integrated (curation 2026-06-09) |
| 2026-06-09 | aws-devops-engineer-professional | audit | high | D9=1: only 1 inline scenario (5 in references) → fails publish bar | scorecards/aws-devops-engineer-professional.md | integrated (curation 2026-06-09) |
| 2026-06-09 | aws-security-specialty | audit | high | D9=1: only 1 inline scenario (5 in references) → fails publish bar | scorecards/aws-security-specialty.md | integrated (curation 2026-06-09) |
| 2026-06-09 | aws-solutions-architect-professional | audit | high | D9=1: only 1 inline scenario; D3=2 (body-only depth thinned by §4 reference moves) | scorecards/aws-solutions-architect-professional.md | integrated (curation 2026-06-09) |
| 2026-06-09 | github-actions | audit | high | D9=1: only 1 inline scenario; D1/D2=2 (no sibling slugs — structural, no GH sibling exists) | scorecards/github-actions.md | integrated (curation 2026-06-09) |
| 2026-06-09 | react | audit | high | D9=1: only 1 inline scenario (4 in references) → fails publish bar | scorecards/react.md | integrated (curation 2026-06-09) |
| 2026-06-09 | react-native | audit | high | D9=1: only 1 inline scenario (5 in references) → fails publish bar | scorecards/react-native.md | integrated (curation 2026-06-09) |
| 2026-06-10 | salesforce-administrator | audit | high | External ID limit wrong: skill says 7 per object; official limit is 25 (shared with unique fields) | https://help.salesforce.com/s/articleView?id=000385134 | integrated (curation 2026-06-10) |
| 2026-06-10 | salesforce-administrator | audit | high | Group tasks: skill says up to 200 users; official limit is 100 | https://help.salesforce.com/s/articleView?id=000380133 | integrated (curation 2026-06-10) |
| 2026-06-10 | salesforce-administrator | audit | high | Web-to-lead overflow NOT "silently dropped" — official behavior is a pending request queue processed when limit resets; also internal contradiction in sales-service-detail.md (dropped vs emailed) | https://help.salesforce.com/s/articleView?id=000382807 | integrated (curation 2026-06-10) |
| 2026-06-10 | salesforce-administrator | audit | medium | Web-to-case overflow described as emailed to default case address; official behavior is the shared pending request queue | https://help.salesforce.com/s/articleView?id=000382807 | integrated (curation 2026-06-10) |
| 2026-06-10 | salesforce-administrator | audit | medium | "WFR/Process Builder retired Dec 31 2025" → was END OF SUPPORT, not retirement; existing automation keeps running (skill's "still fire" caveat correct) | https://help.salesforce.com/s/articleView?id=001096524 | integrated (curation 2026-06-10) |
| 2026-06-10 | salesforce-administrator | audit | medium | Coverage gap: domain is "Object Manager AND Lightning App Builder" (15%) but §3 lacks LAB page types, Dynamic Forms, activation/assignment | https://admin.salesforce.com/blog/2026/what-the-salesforce-certified-platform-administrator-exam-update-means-for-admins | integrated (curation 2026-06-10) |
| 2026-06-10 | salesforce-administrator | audit | medium | Agentforce 360 rebrand (Oct 2025) absent; exam guide still says Agent Builder — add dual-naming note | https://admin.salesforce.com/blog/2026/new-experiences-you-cant-miss-at-tdx-2026 | integrated (curation 2026-06-10) |
| 2026-06-10 | salesforce-administrator | audit | low | Recycle Bin "15 days" absolute; 30 days possible via Extended Retention; add Agent Builder conversation-preview testing note | https://help.salesforce.com/s/articleView?id=000387160 | integrated (curation 2026-06-10) |
| 2026-06-10 | react | audit | high | Skill recommends useTransition for laggy controlled filter input; react.dev: "Transition updates can't be used to control text inputs" — correct answer is useDeferredValue (+memo) or two-state split. NOTE: evals/react answer-key.md scenario 6 encodes the SAME wrong answer (both eval candidates gave the react.dev-correct answer and were scored 0.0) — fix skill AND answer key together | https://react.dev/reference/react/useTransition | integrated (curation 2026-06-10) |
| 2026-06-10 | react | audit | high | useEffectEvent absent — stable since React 19.2 (Oct 2025), the official solution to the non-reactive-values-in-effects problem the skill covers at length | https://react.dev/reference/react/useEffectEvent | integrated (curation 2026-06-10) |
| 2026-06-10 | react | audit | medium | useDeferredValue mischaracterized as "similar to debounce ... until the browser is idle" — docs: immediate interruptible background render, NOT debounce; memo caveat missing | https://react.dev/reference/react/useDeferredValue | integrated (curation 2026-06-10) |
| 2026-06-10 | react | audit | medium | Stale tooling: eslint-plugin-react-compiler superseded by eslint-plugin-react-hooks v6 compiler rules (React 19.2) | https://react.dev/blog/2025/10/01/react-19-2 | integrated (curation 2026-06-10) |
| 2026-06-10 | react | audit | medium | Coverage gaps: Activity component (19.2), use() hook (claimed in scope, never taught), ref-as-prop/Context-as-provider (19), Performance Tracks | https://react.dev/blog/2025/10/01/react-19-2 | integrated (curation 2026-06-10) |
| 2026-06-10 | react | audit | low | Disclaimer says React is a Meta trademark; React owned by React Foundation (Linux Foundation) since Feb 2026; also Rules-of-hooks resource link points at wrong rules page | https://react.dev/blog/2026/02/24/the-react-foundation | integrated (curation 2026-06-10) |
| 2026-06-10 | aws-security-specialty | audit | high | Security Hub rename/split not reflected: skill describes the product renamed "Security Hub CSPM" (Oct 2025) under the name of the NEW Security Hub (GA Dec 2025, risk correlation) | https://docs.aws.amazon.com/securityhub/latest/userguide/what-are-securityhub-services.html | integrated (curation 2026-06-10) |
| 2026-06-10 | aws-security-specialty | audit | high | RCP facts wrong: "introduced late 2023" (actual: Nov 2024) and no supported-services scoping (S3, STS, KMS, SQS, Secrets Manager, ECR, AOSS, DynamoDB only) | https://aws.amazon.com/about-aws/whats-new/2024/11/resource-control-policies-restrict-access-aws-resources/ | integrated (curation 2026-06-10) |
| 2026-06-10 | aws-security-specialty | audit | high | Coverage gap ~10% of exam: Domain 1 logging design/troubleshooting (org CloudTrail, CloudTrail Lake, Athena/OpenSearch analysis, missing-logs troubleshooting) absent | https://docs.aws.amazon.com/aws-certification/latest/security-specialty-03/security-specialty-03-domain1.html | integrated (curation 2026-06-10) |
| 2026-06-10 | aws-security-specialty | audit | medium | GuardDuty: Critical severity tier + Extended Threat Detection (AttackSequence findings) missing; nonexistent finding type UnauthorizedAccess:EC2/MaliciousIPCaller cited; protection-plan framing absent | https://docs.aws.amazon.com/guardduty/latest/ug/guardduty-extended-threat-detection.html | integrated (curation 2026-06-10) |
| 2026-06-10 | aws-security-specialty | audit | medium | Access Analyzer missing unused/internal analyzer types + custom policy checks; Firewall Manager prerequisite wrong (needs AWS Config, not Security Hub); Secrets Manager managed rotation + single-user/alternating-users strategy names absent; "AWS does not publish scored/unscored split" wrong (50+15) | https://aws.amazon.com/iam/access-analyzer/features/ | integrated (curation 2026-06-10) |
| 2026-06-10 | aws-security-specialty | audit | medium | Internal contradictions: Medium-severity automation rule stated two ways (§4 vs Operational Rules); S3 BPA rationale in quick-ref false (bucket-level BPA is NOT overridable by object ACLs); scenarios.md Scenario 4 competent-move paragraph garbled | https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-control-block-public-access.html | integrated (curation 2026-06-10) |
| 2026-06-10 | aws-security-specialty | audit | medium | Domains 3–6 coverage gaps: GenAI guardrails, Network Firewall/DNS Firewall/Verified Access, Cognito/Roles Anywhere/ABAC, CloudHSM/XKS/Private CA/data masking, declarative + AI-opt-out policies, centralized root access, Audit Manager | https://docs.aws.amazon.com/aws-certification/latest/security-specialty-03/security-specialty-03-domain3.html | integrated (curation 2026-06-10) |
| 2026-06-10 | aws-security-specialty | eval | low | Lens 3/4 at ceiling (baseline 100% = skilled 100%): eval set does not discriminate — sharpen scenarios toward post-2024 specifics the audit surfaced (Security Hub split, RCP scoping, Extended Threat Detection, ssmmessages-only regions) | evals/RESULTS.md cycle 2 | integrated (curation 2026-06-10) |
| 2026-06-10 | react | eval | medium | Lens 3 zero lift (87.5% = 87.5%): skill restates what the model knows; deepen with 19.2-era content (useEffectEvent, Activity, Compiler tooling) which the audit shows is missing AND would discriminate | evals/RESULTS.md cycle 2 | integrated (curation 2026-06-10) |
| 2026-06-10 | salesforce-administrator | eval | low | Lens 4 zero application lift (91.7% both): both conditions missed the same Task 1 trap (fault paths on DML/email steps) — skill's flow sections lack fault-path/error-logging guidance; add it (also closes the only skilled scenario miss) | evals/RESULTS.md cycle 2 | integrated (curation 2026-06-10) |
