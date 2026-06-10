# Scorecard — aws-solutions-architect-professional

- **Skill:** `aws-solutions-architect-professional`
- **Assessed:** 2026-06-09
- **Model (auditor):** claude-sonnet-4-6 (static audit)
- **Skill last-reviewed:** 2026-06-09

Standard: [../../docs/SKILL-STANDARD.md](../../docs/SKILL-STANDARD.md) ·
Protocol: [../../docs/ASSESSMENT.md](../../docs/ASSESSMENT.md)

---

## Lens 1 — Static audit (rubric /36)

| Dim | Name | Score (0–3) | Evidence (one line, cite section/file) |
|---|---|---|---|
| D1 | Trigger precision | 3 | Description names concrete deliverables (Transit Gateway, PrivateLink, Direct Connect, 7 Rs, DR design); use-when covers four distinct architect motions; scope boundary names both siblings. ~525 chars. |
| D2 | Scope contract | 3 | Load/Not-this block in Overview (pipeline/IaC → devops; security controls → security); Uncertainty & Escalation lists escalation triggers (TGW provisioning, RI purchases, DR failover). Agent can route without reading body. |
| D3 | Operational depth | 2 | Transitive-routing trap and Direct Connect encryption gap are well-stated; 7 Rs table with When-to-use is useful. However, §4 migration tooling and §4.3 architecture patterns defer significant detail to `references/migration-tooling.md` and `references/architecture-patterns.md` — body-only load has shallower coverage of those sub-topics than the other AWS skills have in their equivalent sections. |
| D4 | Decision support | 3 | Six decision tables (connectivity pattern with key constraints, DR RTO/RPO × cost, 7 Rs, database workload, deployment pattern, multi-account tools); every row names the deciding constraint. |
| D5 | Failure-mode coverage | 2 | Red flags per section with mechanism (VPC Peering non-transitive trap, DMS without SCT first, single NAT Gateway SPOF); Scenario 1 (TGW vs peering) covers trigger+mechanism+fix+verify. Only 1 full scenario in body; 5 more in `references/scenarios.md`. |
| D6 | Verification discipline | 3 | Every section ends with CLI commands (`aws organizations`, `aws ec2 describe-transit-gateway-attachments`, `aws route53resolver`); Workflow 3 (DR) has negative test (disable health check, confirm DNS flips). |
| D7 | Uncertainty & escalation | 3 | Top-of-file block: `[volatile — verify live]` tags on TGW pricing, DX speeds, Lambda concurrency limits, Shield Advanced pricing, Snow device capacity; live-wins rule; escalation list specific to architectural commitments (RI/SP purchases, OU moves). |
| D8 | Executable workflows | 3 | Three numbered workflows (TGW connectivity decision→build→verify, 7 Rs migration execution, DR pattern design→build→test); every step has a verify gate including negative tests. |
| D9 | Teaching scenarios | 1 | Only 1 full POLICY-format scenario in body (TGW vs peering); 5 additional scenarios are pointer-only to `references/scenarios.md`. Standard requires ≥4 in-body. |
| D10 | Context economy | 2 | 4,311 words — upper end of 3,500–4,300 band; two sub-sections intentionally defer detail to `references/` which partially mitigates bloat, but body word count is still above ideal. **D10 trim flag: reduce to ≤3,500.** |
| D11 | Freshness & provenance | 2 | `last-reviewed: 2026-06-09`, `blueprint-verified: 2026-06-07`; Changelog records one conformance-pass entry; no per-scar source citations. |
| D12 | Measurability | 2 | Eval infra exists (`situations.md`, `tasks.md`, `answer-key.md`) with coverage across all 4 sections; no model run recorded yet. |
| | **Total** | **29/36** | |

**Publish bar:** no dimension < 2 AND total ≥ 28. → **Result: needs content pass**

Sub-2 dimensions filed as inbox items: **D9** (only 1 of ≥4 required teaching scenarios present in SKILL.md body). D3 is also softer than sibling AWS skills due to migration/architecture-pattern sections deferring to references; monitor for practitioner feedback.

---

## Lens 2 — Trigger testing

Source phrasings: `evals/aws-solutions-architect-professional/triggers.md`. Test against descriptions only (from `/tmp/skills-snapshot.md`).

| Phrasing | Expected route | Actual route | Hit? |
|---|---|---|---|
| "We're migrating a 50 TB on-premises Oracle data warehouse to AWS — compare Redshift, Aurora, and keeping Oracle on RDS, and recommend the right 7-R strategy for each tier." | aws-solutions-architect-professional | aws-solutions-architect-professional — "migration and modernization strategy (the 7 Rs)" + "enterprise AWS design decisions" | ✓ |
| "Our 20-account AWS Organization uses VPC peering today; traffic patterns have grown to the point where the mesh is unmanageable. Design a Transit Gateway hub-and-spoke replacement and flag the routing and security trade-offs." | aws-solutions-architect-professional | aws-solutions-architect-professional — "hybrid and cross-account networking (Transit Gateway…)" + "cost/resilience/performance trade-offs at enterprise scale" | ✓ |
| "The CTO wants RTO of 15 minutes and RPO of 5 minutes for our order-management system. Evaluate warm standby vs. pilot light vs. active/active, pick the right DR pattern, and justify the cost delta." | aws-solutions-architect-professional | aws-solutions-architect-professional — "business-continuity and DR design" + "cost/resilience/performance trade-offs" | ✓ |
| "We need a hybrid DNS architecture: on-premises resolvers must query private Route 53 hosted zones, and Route 53 must forward some queries to on-premises. What Route 53 Resolver endpoints do we need and where?" | aws-solutions-architect-professional | aws-solutions-architect-professional — "hybrid and cross-account networking (Transit Gateway, PrivateLink, Direct Connect)" — hybrid DNS fits under hybrid networking design trade-offs | ✓ |
| "Design a multi-account landing zone for a 200-engineer org: how should we structure OUs, SCPs, and centralized logging accounts in Control Tower to enforce least-privilege at scale?" | aws-solutions-architect-professional | aws-solutions-architect-professional — "multi-account AWS Organizations" + "enterprise AWS design decisions across organizational complexity" | ✓ |
| "Write the CloudFormation template that provisions the Transit Gateway, route tables, and VPC attachments for our hub-and-spoke network." (→ aws-devops-engineer-professional) | aws-devops-engineer-professional | aws-devops-engineer-professional — "infrastructure as code (CloudFormation…)" + "building…IaC templates" | ✓ |
| "Review our SCP that's supposed to deny `ec2:RunInstances` outside approved regions and tell me why it's still allowing launches in ap-southeast-1." (→ aws-security-specialty) | aws-security-specialty | aws-security-specialty — "multi-account governance (SCPs…)" + "IAM policy evaluation" | ✓ |
| "Set up CloudWatch dashboards and alarms to monitor the Transit Gateway packet-drop metric across all attached VPCs." (→ aws-devops-engineer-professional) | aws-devops-engineer-professional | aws-devops-engineer-professional — "CloudWatch monitoring and logging" + "observability stacks" | ✓ |

**Trigger pass rate: 8/8.**

---

## Lens 3 — Knowledge eval (latest run)

- Run date / model: — · See [../RESULTS.md](../RESULTS.md).
- Baseline / Skilled / Lift: — / — / —
- Gap scenarios (section pointers): —

## Lens 4 — Application eval (latest run)

- Run date / model: — · Tasks: `evals/aws-solutions-architect-professional/tasks.md`.
- Baseline / Skilled / Lift: — / — / —
- Traps caught / missed / new errors: —

## Lens 5 — Adversarial freshness & coverage audit (latest)

- Run date / model: —
- Staleness findings: — · Coverage gaps: — · Contradictions: —
- Filed to inbox: none

---

## Notes / trend

D9 is the sole structural blocker. Priority targets for the 3 additional in-body scenarios: Direct Connect encryption gap (§1.2 — DX does not encrypt in transit, common practitioner oversight); single NAT Gateway SPOF elimination (§3.3 — tempting to leave for later, expensive when it fails); and SCT-before-DMS on heterogeneous migrations (§4.2 — DMS-without-SCT is a canonical migration failure mode). D3 is at 2 partly because §4.2 and §4.3 intentionally defer to references; if field feedback shows practitioners getting the migration tool selection wrong on body-only loads, those sections should be deepened in-body. The SAP skill has the weakest operational depth of the three AWS skills on body-only load — worth watching in Lens 4 application eval results.
