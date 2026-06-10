---
name: aws-solutions-architect-professional
description: Designing and evaluating complex AWS architectures — multi-account AWS Organizations, hybrid and cross-account networking (Transit Gateway, PrivateLink, Direct Connect), business-continuity and DR design, migration and modernization strategy (the 7 Rs), and cost/resilience/performance trade-offs at enterprise scale. Use when making or reviewing enterprise AWS design decisions across organizational complexity, new solutions, continuous improvement, or workload migration. Not hands-on pipeline/IaC delivery (see aws-devops-engineer-professional) or security-control depth (see aws-security-specialty). Scoped and benchmarked by the AWS Solutions Architect – Professional (SAP-C02) blueprint.
metadata:
  credential: AWS Certified Solutions Architect – Professional
  exam-code: SAP-C02
  domain: aws
  type: certification-playbook
  status: current
  last-reviewed: 2026-06-09
  blueprint-verified: 2026-06-07
  blueprint: SAP-C02 (2026-06-07 verified)
---

# AWS Certified Solutions Architect – Professional (SAP-C02) — Skills Reference

## Overview

**This file is an operational playbook, not an exam outline.** Each section states the rules an architect applies when reviewing or designing AWS architecture: decision criteria for picking between services, anti-patterns to catch in design reviews. Recurring principle: **verify against the live account** — limits, pricing, and feature availability change frequently. Benchmarked against the AWS Solutions Architect – Professional (SAP-C02) blueprint.

> **Load this skill when…** evaluating or designing complex AWS architectures across multiple accounts or regions; choosing connectivity patterns (Transit Gateway, VPC Peering, Direct Connect, PrivateLink); planning migration strategy (7 Rs, tooling, wave planning); or making cost/resilience/performance trade-offs at enterprise scale.
> **Not this skill:** pipeline/IaC delivery → see `aws-devops-engineer-professional`; deep security control design → see `aws-security-specialty`.

> **Study resources, whitepapers, practice exams, and credential logistics:** [references/study-resources.md](references/study-resources.md).

> **Verify steps assume nothing about your tooling** — use your project's MCP/automation, the AWS CLI (`aws`) or CloudShell, or the AWS Console, in that order of preference.

---

## Uncertainty & Escalation

- **Always re-verify live — volatile facts:** Transit Gateway per-attachment and per-GB pricing `[volatile — verify live]`, Direct Connect port speeds and availability by location `[volatile — verify live]`, Lambda default concurrent executions per account per region `[volatile — verify live]`, Shield Advanced monthly pricing `[volatile — verify live]`, Snow family device capacity and lead times `[volatile — verify live]`, and service quota defaults for any critical-path service before a scaling event.
- **Live wins:** when the live AWS account, CLI output, or official AWS docs (especially the Pricing Calculator and Service Quotas console) contradict a claim in this file, the live source is authoritative. Log the discrepancy via the Feedback protocol below so the skill can be corrected.
- **Escalate to a human — do not silently execute:** multi-account Organization changes (OU moves, SCP attachments); Transit Gateway or Direct Connect provisioning; Reserved Instance or Savings Plan purchases (significant spend commitment); cross-account IAM trust policy changes; any DR failover or failback; deleting S3 buckets, RDS instances, or VPCs; Control Tower account vending that modifies org-level SCPs.
- **Confidence taxonomy:** every fact in this file is considered *stable* unless tagged `[volatile — verify live]` (changes with AWS service updates) or `[opinion — house style]` (a defensible default, not the only valid choice).

---

## 1. Design Solutions for Organizational Complexity (26%)

### 1.1 Multi-Account Strategy

An AWS Organization with multiple accounts is the baseline for any enterprise. Accounts are the primary isolation boundary — IAM policies cannot span accounts without explicit cross-account trust.

**Pick the right structure:**

| Scenario | Recommendation |
|---|---|
| Enforce policy guardrails org-wide | Service Control Policies (SCPs) on OUs in AWS Organizations |
| Automate account vending + guardrails | AWS Control Tower with Landing Zone |
| Central identity with SSO across accounts | IAM Identity Center (formerly SSO) with SAML/OIDC federation |
| Share resources across accounts (VPCs, subnets, RAM) | AWS Resource Access Manager |
| Centralize security findings | Security Hub with delegated admin account |
| Centralize CloudTrail logs | Org-level trail to a dedicated logging account |

**SCP vs IAM boundary rule:** SCPs define the *maximum permissions* an account's IAM principals can have — they do not grant permissions. A principal needs both an SCP that allows the action *and* an IAM policy that grants it. An explicit Deny in an SCP blocks even the root user. Use SCPs for non-negotiable guardrails (e.g., block disabling CloudTrail, restrict to approved regions); use IAM for fine-grained access within accounts.

**Red flags in review:** using a single AWS account for all workloads; relying on IAM alone to isolate prod vs dev; attaching SCPs to the root instead of specific OUs (overly broad); forgetting that SCPs do not affect the management account.

**Verify:** `aws organizations list-policies --filter SERVICE_CONTROL_POLICY` to see SCPs in force; `aws organizations describe-effective-policy --policy-type SERVICE_CONTROL_POLICY` to see what applies to a given account.

### 1.2 Cross-Account and Hybrid Networking

**Choose the connectivity pattern deliberately:**

| Need | Pattern | Key constraint |
|---|---|---|
| Two VPCs, same or different accounts, low-volume private traffic | VPC Peering | Non-transitive — each pair needs its own peering; no overlapping CIDRs |
| Hub-and-spoke across many VPCs or accounts | Transit Gateway (TGW) | Transitive routing; costs per attachment + data processing; supports VPN and Direct Connect attachments |
| Private access to a service (e.g. S3, API endpoint) without routing through internet | VPC Endpoint (Gateway for S3/DynamoDB, Interface for most others) | Interface endpoints cost per AZ per hour + data; Gateway endpoints are free |
| Expose your service to consumers without full VPC access | AWS PrivateLink | Consumer VPCs connect via Interface endpoint; no VPC peering needed; consumers cannot initiate connections back |
| On-premises to AWS, dedicated bandwidth | AWS Direct Connect | 1 Gbps or 10 Gbps dedicated; does not encrypt in transit by default — add a VPN over DX for encryption |
| On-premises to AWS, internet-based encrypted | Site-to-Site VPN | Up to 1.25 Gbps per tunnel; dual-tunnel for redundancy |

**Transitive routing trap:** VPC Peering is non-transitive. If VPC A peers with VPC B and VPC B peers with VPC C, A cannot reach C through B. To route transitively, use Transit Gateway.

**DNS in hybrid architectures:** Route 53 Resolver endpoints handle DNS query resolution between on-premises and VPC. An *inbound endpoint* lets on-premises resolvers forward queries to Route 53. An *outbound endpoint* lets VPC resources forward queries to on-premises. Forwarding rules wire up which domains go where.

**Red flags:** designing a hub VPC for transitive routing using peering (it won't work); Direct Connect without a VPN overlay when in-transit encryption is required; overlapping CIDRs in a VPC peering or TGW architecture (cannot be fixed without re-addressing).

**Verify:** `aws ec2 describe-transit-gateway-attachments` to check TGW attachment state; `aws route53resolver list-resolver-endpoints` to confirm Resolver configuration; always validate route table entries in each VPC after wiring connections.

### 1.3 Resilience and DR at Org Scale

Resilience decisions hinge on RTO (how fast you recover) and RPO (how much data you can lose). Match the pattern to the requirement, not to the maximum:

| Pattern | Typical RTO | Typical RPO | Cost tier |
|---|---|---|---|
| Backup and restore | Hours | Hours (last backup) | Lowest |
| Pilot light | 10s of minutes | Minutes | Low-medium |
| Warm standby | Minutes | Near-zero | Medium-high |
| Multi-site active/active | Near-zero | Near-zero | Highest |

**AWS Elastic Disaster Recovery (DRS)** is the managed replication + failover service for lift-and-shift DR (replaces CloudEndure); use it for server-based workloads that need sub-minute RPO at reasonable cost.

**Red flag:** specifying "multi-region active/active" when RTO = 4 hours and RPO = 1 hour — the cost is unjustifiable; warm standby almost always suffices. Conversely, specifying "backup and restore" when RTO = 15 minutes.

### 1.4 Cost Visibility

Tag everything before you need cost attribution — retrofitting tags is painful. Governance: require tags via SCP (`aws:RequestedRegion`, `CostCenter`, `Project`, `Environment`) or AWS Config rules that auto-remediate untagged resources.

Use AWS Cost Explorer for trend analysis and forecasts. Use AWS Budgets to trigger alerts and (optionally) automated responses. Use Compute Optimizer for rightsizing signals. Use Trusted Advisor for flagging idle resources and coverage gaps.

---

## 2. Design for New Solutions (29%)

### 2.1 Deployment Strategy

| Pattern | Zero downtime | Rollback | Cost | Use when |
|---|---|---|---|---|
| All-at-once | No | Slow | Lowest | Dev/test, batch |
| Rolling | Partial | Medium | Low | Tolerates brief mixed-version |
| Blue/green | Yes | Instant (swap) | 2× capacity | Production, stateless services |
| Canary | Yes | Instant (shift back) | Slight overhead | Gradual validation in production |

CodeDeploy, ECS deployment config, and Lambda aliases support blue/green and canary natively. CloudFormation change sets are the pre-deploy plan view.

**Red flag:** manual console changes in production outside of IaC; blue/green for a stateful service without externalizing session state first.

### 2.2 Business Continuity and DR Design

Maps to the RTO/RPO table in §1.3. For greenfield:
- Multi-AZ is the availability floor — not a DR strategy.
- Multi-region required when RTO < ~10 min or single-region failure is unacceptable.
- Route 53 failover/latency/weighted routing is the DNS layer for cross-region; S3 CRR and RDS cross-region read replicas are the data plane.

**Red flag:** Multi-AZ RDS presented as cross-region DR; single S3 bucket in one region as DR storage.

### 2.3 Security Controls for New Architectures

- **Network:** security groups (stateful, per-ENI, allow-only) for application-level rules; NACLs (stateless, subnet-level, explicit inbound+outbound) for broad block-lists.
- **Identity:** IAM roles for all compute (EC2/Lambda/ECS tasks); IAM Roles Anywhere for on-premises; cross-account assume-role with external ID to prevent confused deputy.
- **Data:** KMS CMKs for data you control or need key-policy audit; AWS-managed keys for lower overhead. Enforce TLS via `aws:SecureTransport` condition in S3 bucket policies.
- **Detection:** GuardDuty (enable org-wide); Security Hub (aggregates findings); Config (configuration drift); CloudTrail (all API calls, org-level trail).
- **Secrets:** Secrets Manager for rotating credentials; SSM Parameter Store SecureString for non-rotating config. Shield Standard (free, L3/L4); Shield Advanced ($3,000/mo `[volatile — verify live]`) for L7 DDoS + SRT access.

**Red flag:** long-lived IAM access keys in Lambda/EC2 config; security groups with `0.0.0.0/0` on non-public ports; no org-level CloudTrail; no GuardDuty in non-production accounts.

### 2.4 Reliability — Compute and Data Stores

**Compute:** ASGs (EC2) with target tracking; ECS/EKS on Fargate for containers; Lambda (set reserved concurrency to protect downstream systems).

**Databases — pick by access pattern:**

| Workload | Service |
|---|---|
| Relational, OLTP | Aurora (MySQL/PostgreSQL) or RDS — Multi-AZ, read replicas |
| Key-value / document | DynamoDB — serverless, auto-scaling, Global Tables |
| In-memory cache | ElastiCache Redis — sub-ms latency |
| Search / analytics | OpenSearch Service |
| Data warehouse | Amazon Redshift — columnar, petabyte scale |

**Loose coupling:** SQS (standard: at-least-once; FIFO: exactly-once + ordering); SNS fan-out; EventBridge content-based routing; Step Functions for multi-step orchestration with retry/error handling.

**Red flag:** synchronous microservice calls with no timeout or circuit breaker; DynamoDB hot partition keys; single-AZ RDS for production.

### 2.5 Performance and Cost for New Designs

**Caching:** CloudFront (edge) → ElastiCache (app-tier) → DAX (DynamoDB microsecond reads). Apply at the layer closest to the bottleneck.

**Instance selection:** C family (CPU-bound); R/X (in-memory); I/D (NVMe); P/G/Inf (ML). Use Global Accelerator for Anycast TCP routing to AWS edge for non-HTTP workloads.

**Purchasing:** On-Demand for variable workloads. Compute Savings Plans (1yr/3yr, covers EC2+Fargate+Lambda) for steady-state. Spot (up to 90% discount) for fault-tolerant batch/ML. Default to EBS gp3 over gp2.

**Data transfer:** inter-AZ transfer costs money for chatty microservices. Use S3/DynamoDB Gateway endpoints (free) to eliminate NAT Gateway egress.

**Red flag:** On-Demand for 24/7 production (no Savings Plan); gp2 EBS; ignoring inter-AZ transfer in cost model.

---

## 3. Continuous Improvement for Existing Solutions (25%)

### 3.1 Operational Excellence

**Observability:** CloudWatch metrics (alarm on P99, not average); structured JSON logs with retention policies (uncapped = silent cost leak); X-Ray distributed traces; CloudWatch dashboards or Managed Grafana. Move console deployments to CodePipeline; schedule `aws cloudformation detect-stack-drift` to catch manual changes.

**Red flag:** alarms only on Average latency; no log retention policy; no runbooks for common failure modes.

### 3.2 Security Posture Improvement

Security Hub aggregates findings from GuardDuty, Inspector, Macie, Firewall Manager, and IAM Access Analyzer; prioritize by severity × blast radius. IAM Access Analyzer identifies unintended external access — run org-wide from the delegated admin account. Add managed Config rules (`s3-bucket-public-read-prohibited`, `rds-instance-public-access-check`) with SSM Automation remediation. Use SSM Patch Manager + Inspector for OS/package CVE management.

**Red flag:** GuardDuty not org-wide; S3 Block Public Access not enabled at org level; IAM roles with `*:*` for Lambda or EC2.

### 3.3 Performance and Reliability Improvement

**Performance:** instrument before resizing — X-Ray service maps, CloudWatch Container Insights, Lambda Insights. Compute Optimizer recommends right-sizes based on p99 data. For databases: Performance Insights (7-day free tier), Slow Query Logs, read replicas for read-heavy, DAX for DynamoDB.

**Reliability — eliminate SPOFs in blast-radius order:**
- Single NAT Gateway per region → add one per AZ
- Single EC2 → ASG min 2
- Single RDS → enable Multi-AZ
- Hard-coded endpoints → Route 53 / load balancer DNS
- Synchronous calls with no retry → add SQS or exponential backoff

Lambda default: 1,000 concurrent executions per region per account `[volatile — verify live]`. Document quota headroom for critical services; request increases before load events.

**Red flag:** resizing on Average CPU without checking peak; single NAT Gateway for all AZs; Lambda with no reserved concurrency protecting a downstream service.

### 3.4 Cost Optimization for Existing Workloads

1. **Unused resources:** Trusted Advisor + `aws ec2 describe-volumes --filters Name=status,Values=available` for unattached EBS.
2. **Savings Plan gap:** Cost Explorer coverage report → purchase 1yr Compute Savings Plans for the On-Demand baseline.
3. **S3 cost:** S3 Storage Lens → lifecycle policies or Intelligent-Tiering for objects with uncertain access patterns.
4. **Data transfer:** Cost and Usage Reports (CUR) expose transfer line items → replace NAT Gateway egress for S3/DynamoDB with free Gateway endpoints.

**Red flag:** no S3 lifecycle policies on buckets older than 90 days; gp2 EBS; no Savings Plan in a 24/7 production environment.

---

## 4. Accelerate Workload Migration and Modernization (20%)

### 4.1 Migration Assessment — The 7 Rs

Every migration decision maps to one of the 7 Rs. Apply them in assessment order:

| Strategy | Summary | When to use |
|---|---|---|
| **Retire** | Decommission — it's not needed | Application has no active users; duplicate of another system |
| **Retain** | Leave on-premises (for now) | Regulatory constraint; recent CapEx; complex dependency |
| **Rehost** (Lift & Shift) | Move as-is to EC2 | Fast migration, minimal risk; optimize later |
| **Relocate** | Hypervisor-level move (VMware Cloud on AWS) | VMware shops that want speed without re-platforming |
| **Replatform** | Lift, tinker, shift — minor optimization | Move RDS → Aurora; Tomcat → Elastic Beanstalk |
| **Repurchase** | Replace with SaaS | On-prem CRM → Salesforce; on-prem email → M365 |
| **Refactor / Re-architect** | Redesign for cloud-native | Maximum agility/scale; highest effort and cost |

**Wave planning:** group workloads into migration waves by dependency, risk, and team capacity. Low-complexity standalone apps go first (build team muscle); shared platform services (AD, DNS, monitoring) migrate with or before their dependents.

**Red flag:** defaulting every workload to Refactor (over-engineering); not mapping dependencies before wave planning (causes migration failures when a dependent service isn't ready); skipping Retire/Retain evaluation (wastes migration effort).

**Verify TCO:** use AWS Migration Evaluator or the AWS Pricing Calculator to compare on-premises run rate (include hardware refresh, datacenter, licensing, staff) against AWS equivalent.

### 4.2 Migration Tooling

> Full tool-by-tool reference (ADS, MGN, DataSync, Snow Family, DMS, SCT, Transfer Family, Directory Service) lives in [references/migration-tooling.md](references/migration-tooling.md). Load that file when selecting a specific migration tool. Key decision rules inline below.

**Core decision rules (always loaded):**
- Use **MGN** for server Rehost (block-level replication; test launch before cutover).
- Use **DMS** for database migration; always run **SCT first** for heterogeneous migrations (Oracle/SQL Server → Aurora/PostgreSQL) — schema incompatibilities discovered mid-migration are expensive.
- Use **DataSync** for file-share sync (NFS/SMB → S3/EFS/FSx) when network bandwidth is sufficient. Use **Snow family** when online transfer is impractical (rule of thumb: >10 TB with <1 Gbps link) `[volatile — verify live]`.
- Use **AD Connector** (proxy) when on-premises AD must remain authoritative; use **AWS Managed Microsoft AD** when you need a full AD in AWS for domain-join and trust relationships.

**Red flag:** using DMS without running SCT first on heterogeneous migrations; choosing Snow family for a 500 GB dataset with a 1 Gbps link (DataSync is faster); forgetting to re-point DNS during cutover.

### 4.3 Replatform/Refactor Patterns

> Full compute, storage, decoupling, serverless-candidate, and purpose-built-database reference: [references/architecture-patterns.md](references/architecture-patterns.md). Core rules below.

- **Compute:** EC2 in ASG (Rehost) → Elastic Beanstalk (managed platform) → ECS/EKS on Fargate (containers) → Lambda (event-driven short tasks). Match to workload shape.
- **Storage:** EBS gp3 (block), EFS/FSx (file), S3 (object), Storage Gateway Volume (hybrid iSCSI).
- **Decoupling:** replace synchronous calls with SQS; fan-out with SNS+SQS; custom schedulers with EventBridge Scheduler; workflow engines with Step Functions.
- Lambda is cost-optimal for spiky/event-driven; EC2 + Compute Savings Plan is cheaper for consistent 24/7 throughput.

**Red flag:** migrating a stateful monolith to Lambda without externalizing state; using RDS for a key-value workload; refactoring to microservices without service contracts and observability.

---

## Executable Workflows

### Workflow 1 — Choose and Build Cross-Account/VPC Connectivity (Peering vs Transit Gateway Decision → Build → Verify Routes)

1. **Decide:** ≤3 VPCs, no transitive routing, no hybrid attachment → VPC Peering. 4+ VPCs, transitive routing, or VPN/DX attachment → Transit Gateway. Document before provisioning.
   → gate: no overlapping CIDRs between any VPC pair (both Peering and TGW reject overlapping CIDRs); `aws ec2 describe-vpcs --query 'Vpcs[].CidrBlock'` in each account.
2. **Create TGW** in the hub account: `aws ec2 create-transit-gateway --description "<name>" --options AmazonSideAsn=64512,AutoAcceptSharedAttachments=disable,DefaultRouteTableAssociation=enable,DefaultRouteTablePropagation=enable`.
   → gate: `aws ec2 describe-transit-gateways --query 'TransitGateways[?State==\`available\`]'` — must reach `available` before creating attachments.
3. Share TGW to spoke accounts via AWS RAM; accept the share in each spoke account.
   → gate: spoke account `aws ec2 describe-transit-gateways` lists the shared TGW; `aws ram get-resource-share-invitations` shows no `PENDING` entries.
4. Create VPC attachments from each spoke: `aws ec2 create-transit-gateway-vpc-attachment --transit-gateway-id <tgw-id> --vpc-id <vpc-id> --subnet-ids <subnet-ids>`.
   → gate: `aws ec2 describe-transit-gateway-vpc-attachments --filters Name=state,Values=available` — every attachment `available`.
5. Update each spoke's VPC route tables to send traffic to peer CIDRs via the TGW.
   → gate: `aws ec2 describe-route-tables --route-table-ids <rtb>` confirms the route; `traceroute` from an instance in one VPC to a private IP in another confirms packets traverse the TGW.

---

### Workflow 2 — Select and Execute a Migration R (The 7 Rs)

1. **Classify each workload** in elimination order: Retire → Retain → Rehost → Relocate → Replatform → Repurchase → Refactor. Never default to Refactor without an approved business case.
   → gate: every workload has a documented R + rationale; any Refactor needs a business case before wave planning proceeds.
2. **Discover dependencies:** run AWS Application Discovery Service (agent or agentless); export the dependency map from Migration Hub.
   → gate: `aws discovery describe-agents` shows `HEALTHY` status; no wave plan is valid without a dependency map.
3. **Provision MGN for Rehost workloads:** install the AWS Replication Agent on each source server.
   → gate: `aws mgn describe-source-servers` shows `dataReplicationInfo.dataReplicationState: Replicating` for all servers before scheduling test launches.
4. **Test launch (non-disruptive):** `aws mgn start-test`; validate application behavior, licensing, and networking before scheduling the cutover window.
   → gate: test instance passes all acceptance checks; results documented.
5. **Cutover:** finalize replication (`aws mgn finalize-cutover`); update DNS to the new AWS endpoint; monitor 24–48 hours before decommissioning the source.
   → gate: `aws route53 list-resource-record-sets --hosted-zone-id <zone>` confirms the new record; application health checks pass.

---

### Workflow 3 — Design a DR Pattern to a Stated RTO/RPO (Backup-Restore vs Pilot Light vs Warm Standby vs Active-Active)

1. **Map RTO/RPO to pattern:** RTO > 1 hr / RPO > 1 hr → Backup & Restore. RTO 10–60 min / RPO minutes → Pilot Light. RTO 1–10 min / RPO near-zero → Warm Standby. RTO < 1 min / RPO near-zero → Multi-site Active-Active. Document before any infrastructure work.
   → gate: confirm cost envelope with the AWS Pricing Calculator; over-engineering to active-active when warm standby satisfies the SLA is a budget red flag.
2. **Establish data replication (warm standby example):** enable RDS cross-region read replica or Aurora Global Database; S3 CRR for critical buckets; DynamoDB Global Tables if applicable.
   → gate: `aws rds describe-db-instances` confirms `ReplicaMode: open-read-only`; CloudWatch `ReplicaLag` metric < RPO target.
3. **Deploy the reduced-capacity stack in the DR region** (warm standby = scaled-down but running).
   → gate: `aws ecs describe-services` shows `runningCount >= 1`; Route 53 health check on DR endpoint is `Healthy`.
4. **Configure Route 53 failover routing:** primary health check on production endpoint; secondary failover record to DR endpoint; TTL = 60s.
   → gate: `aws route53 get-health-check-status` on primary is `Healthy`; disable primary health check and confirm DNS resolves to DR within 2× TTL.
5. **Test the runbook end-to-end** at least quarterly: promote the RDS read replica (`aws rds promote-read-replica`); run application smoke tests.
   → gate: `aws rds describe-db-instances` shows the replica as a standalone instance; smoke tests pass in the DR region.

---

## Decision Scenarios

**Scenario 1 — Transit Gateway vs VPC Peering: the transitive routing trap**

> **Situation:** An architect designs connectivity for 8 VPCs across 3 accounts using hub-and-spoke peering (7 connections to a shared-services VPC). Three months later two application VPCs need to communicate directly; reaching a full mesh would require N×(N-1)÷2 = 28 peering connections.

> **Competent move:** Use **Transit Gateway** from the start. TGW supports transitive routing — any attached VPC reaches any other through a single route table; adding a new VPC requires one attachment, not N new peering connections. TGW also supports VPN and Direct Connect attachments for hybrid extension. Per-attachment and per-GB charges are justified at ~4+ VPCs.

> **Tempting-but-wrong:** Extending the peering design on demand. Each new pair requires a dedicated connection, route table entries in both VPCs, and security group updates — operational overhead grows quadratically.

> **Verify:** `aws ec2 describe-transit-gateways`; `aws ec2 describe-transit-gateway-attachments --filters Name=state,Values=available`; `aws ec2 describe-transit-gateway-route-tables`; `traceroute` from VPC-A to a private IP in VPC-B confirms routing traverses the TGW.

Further scenarios (Direct Connect encryption gap, Lambda + Aurora connection pool exhaustion, Snow family vs DataSync selection, single NAT Gateway SPOF, SCP vs IAM boundary for region restriction): [references/scenarios.md](references/scenarios.md).

---

## Operational Rules Quick Reference

Read this first. Each rule is concrete and imperative.

- **DO** use SCPs for non-negotiable org-level guardrails; **DON'T** confuse SCPs with IAM grants — SCPs restrict, they do not grant.
- **DO** default to Transit Gateway for hub-and-spoke multi-VPC/account connectivity; **DON'T** design transitive routing with VPC Peering — peering is non-transitive.
- **DON'T** use Direct Connect without a VPN overlay when in-transit encryption is required — DX does not encrypt by default.
- **DO** match DR pattern to actual RTO/RPO requirements before committing to multi-region; over-engineering to active/active when warm standby suffices wastes budget.
- **DO** externalise session/state before applying blue/green deployments; **DON'T** blue/green a stateful service with local session storage.
- **DO** encrypt at rest with KMS and enforce TLS via `aws:SecureTransport` in S3 bucket policies; use Secrets Manager when automatic rotation is required.
- **DO** use IAM roles (not access keys) for all compute workloads (EC2/Lambda/ECS tasks/EKS pods).
- **DON'T** put a cross-account trust without an external ID condition — prevents confused-deputy attacks.
- **DO** tag resources at creation and enforce via SCP + Config; **DON'T** try to retrofit tagging post-deploy on thousands of resources.
- **DO** treat multi-AZ as the availability floor, not a DR strategy; multi-region is required only when region-level failure is an unacceptable risk.
- **DO** default to gp3 EBS volumes over gp2 — lower cost, independently configurable IOPS/throughput.
- **DON'T** add caching (ElastiCache, DAX, CloudFront) before measuring the actual cache hit rate opportunity — cache misses add latency, not reduce it.
- **DO** apply the 7 Rs assessment before migrating any workload; Retire and Retain candidates should be identified before wave planning.
- **DO** run AWS Schema Conversion Tool before Database Migration Service on heterogeneous migrations; **DON'T** discover schema incompatibilities mid-migration.
- **DO** enable GuardDuty and Security Hub org-wide from a delegated admin account; **DON'T** scope threat detection only to production accounts.
- **DO** remove single points of failure in order of blast radius: single NAT Gateway per region → single RDS (enable Multi-AZ) → single EC2 (add ASG) → synchronous hard-coded dependencies.
- **DON'T** Lambda-ize a workload that runs 24/7 at consistent high throughput — EC2 + Compute Savings Plan is cheaper at that utilization profile.
- **DO** verify all service quotas for critical paths before scaling events; **DON'T** assume default quotas are sufficient for production growth.

---

> **Study resources** (official AWS links, whitepapers, practice exams, community guides) are in [references/study-resources.md](references/study-resources.md).

---

## Feedback protocol

Using this skill and hit a wall? If you find a claim contradicted by the live system or official docs, a missing rule that cost you a wrong attempt, or a decision this skill gave no criteria for — append an entry **in the moment** to `.skill-feedback/aws-solutions-architect-professional.md` at the project root (create it if absent):

`date | skill last-reviewed | claim or gap | what you observed instead | evidence (error text / doc URL / query output) | suggested fix`

These are harvested back into the skill via the learning loop. When the live system and this file disagree, trust the live system.

---

## Changelog

- **2026-06-09** — Conformed to the 12-dimension skill standard: task-vocab description + Scope block, Uncertainty & Escalation guidance with inline `[volatile — verify live]` marks, executable workflows, tool-agnostic verify steps, and the feedback protocol above. Exam logistics relocated to references/study-resources.md; `last-reviewed` set to 2026-06-09.

---

_Independent educational content for upskilling AI agents. Not affiliated with or endorsed by Amazon Web Services; all trademarks belong to their owners. Guidance only — verify against official AWS documentation and live accounts._
