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

The AWS Certified Solutions Architect – Professional credential validates that a practitioner can design and evaluate complex, enterprise-scale cloud architectures on AWS. Unlike the Associate-level exam, the Professional exam targets candidates with 2+ years of hands-on AWS experience who must reason across organizational boundaries, trade-offs between cost/resilience/performance, and the full migration lifecycle.

**This file is an operational playbook, not an exam outline.** Each section states the rules an architect actually applies when reviewing or designing AWS architecture, the concrete decision criteria for picking between services, and the anti-patterns to catch in a design review. The recurring principle: **verify against the live account and official docs** — never assume from memory or blog posts, because service limits, pricing, and feature availability change frequently.

> **Load this skill when…** evaluating or designing complex AWS architectures across multiple accounts or regions; choosing between connectivity patterns (Transit Gateway, VPC Peering, Direct Connect, PrivateLink); planning a migration strategy (7 Rs, tooling selection, wave planning); or making cost/resilience/performance trade-offs at enterprise scale.
> **Not this skill:** hands-on pipeline/IaC delivery or deployment strategies → see `aws-devops-engineer-professional`; deep security control design (GuardDuty, KMS, IAM policy evaluation) → see `aws-security-specialty`.

> **Study resources** (official links, whitepapers, practice exams) live in [references/study-resources.md](references/study-resources.md). Load that file when planning a study path.

> **Verify steps assume nothing about your tooling** — use your project's MCP/automation, the AWS CLI (`aws`) or CloudShell, or the AWS Console, in that order of preference.

---

Credential logistics and study path: see [references/study-resources.md](references/study-resources.md).

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

**Pick the rollout pattern by risk tolerance:**

| Pattern | Zero downtime | Rollback speed | Cost | Use when |
|---|---|---|---|---|
| All-at-once | No | Slow (redeploy) | Lowest | Dev/test, batch |
| Rolling | Partial | Medium | Low | Tolerates brief mixed-version |
| Blue/green | Yes | Instant (swap) | 2x capacity during deploy | Production, stateless services |
| Canary | Yes | Instant (shift traffic back) | Slight overhead | Gradual validation in production |

AWS CodeDeploy, ECS deployment configuration, and Lambda aliases + weighted aliases all support blue/green and canary natively. CloudFormation change sets are the IaC equivalent of a pre-deployment plan view.

**IaC discipline:** CloudFormation stacks should be parameterized and linted before deploy (cfn-lint, cfn-nag for security checks). Drift detection (`aws cloudformation detect-stack-drift`) catches out-of-band changes that will cause the next update to fail unexpectedly.

**Red flag:** manual console changes in production outside of IaC; blue/green for a stateful service where session state is not externalized (session drain or externalize to ElastiCache first).

### 2.2 Business Continuity and DR Design

This maps to the same RTO/RPO table in §1.3. For greenfield solutions:
- Multi-AZ is the baseline for any production workload — it is not a DR strategy, it is the availability floor.
- Multi-region is required when RTO < ~10 minutes or when a single-region outage is an unacceptable business risk.
- Route 53 health checks + routing policies (failover, latency, weighted) are the DNS layer for cross-region active/passive or active/active.
- S3 Cross-Region Replication (CRR) and RDS cross-region read replicas are the data-plane components.

**Red flag:** treating Multi-AZ RDS as a DR solution across regions (it is not cross-region); using a single S3 bucket in us-east-1 for DR storage.

### 2.3 Security Controls for New Architectures

**Principle of least privilege at every layer:**

- **Network layer:** security groups are stateful and default-deny inbound. NACLs are stateless and apply at subnet level — require both inbound and outbound rules. Use NACLs for broad block-lists; use security groups for fine-grained application-level control.
- **Identity layer:** IAM roles (not access keys) for EC2/Lambda/ECS tasks. Use IAM Roles Anywhere for on-premises workloads. Cross-account: assume role with external ID to prevent confused deputy.
- **Data layer:** encrypt at rest (KMS CMKs for data you control; AWS-managed keys for lower operational overhead). Enforce encryption in transit via TLS; use `aws:SecureTransport` condition in S3 bucket policies.
- **Detection layer:** GuardDuty for threat detection (enable org-wide from the delegated admin account); Security Hub aggregates findings across services; Config tracks configuration drift; CloudTrail logs all API calls.

**Secrets management:** Secrets Manager (auto-rotation, costs per secret per month) vs SSM Parameter Store SecureString (KMS-encrypted, lower cost, no auto-rotation built in). Use Secrets Manager when rotation is required; use Parameter Store for non-rotating config values and tokens.

**WAF + Shield:** AWS WAF for Layer 7 rules (attach to CloudFront, ALB, API Gateway, AppSync). Shield Standard is free and protects against common L3/L4 DDoS. Shield Advanced ($3,000/month org-wide) adds response team access, cost protection, and L7 DDoS mitigation at scale.

**Red flag:** long-lived IAM access keys in Lambda environment variables or EC2 userdata; security groups with 0.0.0.0/0 on non-public-facing ports; no CloudTrail org-level trail; no GuardDuty in non-production accounts.

### 2.4 Reliability — Compute and Data Stores

**Compute:** Auto Scaling Groups (EC2) with target tracking policies respond to load with minimal lag. For containers, ECS/EKS on Fargate removes capacity management. Lambda scales transparently but has concurrency limits — set reserved concurrency to protect downstream systems.

**Databases — pick by access pattern:**

| Workload | Service | Why |
|---|---|---|
| Relational, OLTP | Amazon Aurora (MySQL/PostgreSQL) or RDS | Multi-AZ, read replicas, automated failover |
| Key-value / document, variable scale | DynamoDB | Serverless, auto-scaling, global tables for multi-region |
| In-memory cache / session | ElastiCache (Redis) | Sub-ms latency; Redis supports complex data structures and pub/sub |
| Search / analytics | OpenSearch Service | Full-text search, log analytics, Kibana dashboards |
| Data warehouse | Amazon Redshift | Columnar storage, petabyte scale, RA3 nodes with S3-backed storage |

**Loose coupling:** SQS decouples producers from consumers (standard for at-least-once; FIFO for exactly-once + ordering). SNS fans out to multiple subscribers. EventBridge routes events by rule to targets (Lambda, SQS, Step Functions) without point-to-point wiring. Step Functions orchestrates multi-step workflows with retry/error handling.

**Red flag:** synchronous calls between microservices with no timeout or circuit breaker; DynamoDB with hot partition keys (choose high-cardinality partition keys); single-AZ RDS for production.

### 2.5 Performance

- **Caching:** CloudFront (CDN, edge) → ElastiCache (application-tier, in-memory) → DAX (DynamoDB Accelerator, microsecond reads). Apply caching at the layer closest to the bottleneck.
- **Instance selection:** Compute-optimized (C family) for CPU-bound; Memory-optimized (R/X family) for in-memory datasets; Storage-optimized (I/D family) for NVMe workloads; Accelerated (P/G/Inf family) for ML.
- **Global acceleration:** CloudFront reduces latency for static/dynamic content delivery. AWS Global Accelerator provides Anycast IP routing to the nearest AWS edge, improving TCP connection time for non-HTTP workloads.

### 2.6 Cost Optimization for New Designs

- **Purchasing model:** On-Demand for variable/unpredictable. Reserved Instances or Compute Savings Plans (1yr or 3yr, no/partial/all upfront) for steady-state baseline — Compute Savings Plans are more flexible (EC2 + Fargate + Lambda). Spot Instances for fault-tolerant, interruptible workloads (batch, stateless web, ML training) at up to 90% discount.
- **Storage tiering:** S3 Intelligent-Tiering for objects with unknown access patterns; S3 Glacier Instant/Flexible/Deep Archive for progressively cheaper long-term retention. EBS gp3 is cheaper and more flexible than gp2 — default to gp3.
- **Data transfer costs are real:** inter-AZ data transfer costs money (significant for chatty microservices). Egress to the internet costs money; S3 Gateway endpoints and Interface endpoints can eliminate internet-facing egress charges for supported services.

**Red flag:** On-Demand for all compute in a 24/7 production environment (missing Savings Plan opportunity); gp2 EBS volumes (migrate to gp3 for lower cost); not accounting for inter-AZ transfer in a multi-AZ microservices cost model.

---

## 3. Continuous Improvement for Existing Solutions (25%)

### 3.1 Operational Excellence

**Observability stack:**
- **Metrics:** CloudWatch metrics with custom namespaces for application-level signals; set alarms on P99 latency, error rate, and queue depth — not just average.
- **Logs:** CloudWatch Logs Insights for ad-hoc log queries. Use structured (JSON) logging for queryable log events. Set log retention policies — uncapped log groups are a silent cost leak.
- **Traces:** AWS X-Ray for distributed tracing across Lambda, ECS, EC2, API Gateway; find bottlenecks in call chains without log diving.
- **Dashboards:** CloudWatch dashboards or Amazon Managed Grafana for unified operational views.

**Deployment improvement:** move console-based deployments to CodePipeline. Add pre-production integration tests as a pipeline gate. Use `aws cloudformation detect-stack-drift` on a schedule to catch manual changes.

**Red flag:** alarms only on Average latency (misses tail latency problems); no log retention policy (uncapped storage cost); no runbooks for common failure modes.

### 3.2 Security Posture Improvement

Security Hub aggregates findings from GuardDuty, Inspector, Macie, Firewall Manager, and IAM Access Analyzer into a single pane. Prioritize by severity and by how many accounts/resources are affected.

**IAM Access Analyzer** identifies resources shared with external principals (cross-account, public) that you may not have intended. Run org-wide from the delegated admin account to catch unintended public S3 buckets, KMS key policies, and Lambda function policies.

**Config rules + remediation:** use managed Config rules for common controls (e.g., `s3-bucket-public-read-prohibited`, `rds-instance-public-access-check`) and attach SSM Automation remediation documents to auto-fix violations where safe.

**Patching:** SSM Patch Manager for OS patching across EC2 at scale; Inspector for vulnerability scanning (now agentless for EC2); use Patch Groups and maintenance windows to control blast radius.

**Red flag:** GuardDuty enabled only in the production account, not org-wide; S3 Block Public Access not enabled at the org level; IAM roles with `*:*` in the policy used for Lambda or EC2.

### 3.3 Performance Improvement

- **Identify the bottleneck first:** use X-Ray service maps to find the slowest segment. Use CloudWatch Container Insights (ECS/EKS) and Lambda Insights for function-level profiling. Never guess — instrument first.
- **Rightsizing:** Compute Optimizer analyzes CloudWatch metrics and recommends EC2, ECS task, Lambda memory, and EBS volume right-sizes. Cross-reference with actual p99 CPU/memory before resizing — a temporarily quiet service will appear over-provisioned.
- **Database performance:** Aurora query plan management, Performance Insights (available for RDS and Aurora; free tier for 7 days; paid for longer retention), and Slow Query Logs are the tools. Add read replicas for read-heavy workloads; add DAX for DynamoDB.

**Red flag:** resizing instances based on Average CPU without checking peak; adding a read replica before checking whether the bottleneck is actually on read path; enabling caching without validating cache hit rate.

### 3.4 Reliability Improvement

Single points of failure (SPOF) are the primary target. Common SPOFs in existing architectures:
- Single NAT Gateway per region (add one per AZ)
- Single EC2 instance (add ASG with min 2)
- Single RDS instance (enable Multi-AZ)
- Hard-coded endpoints (move to Route 53 or a load balancer DNS)
- Synchronous cross-service calls with no retry/backoff (add SQS or implement exponential backoff)

**Service quotas matter at scale.** Lambda has a default 1,000 concurrent executions per region per account. SQS has no inherent throughput limit but Lambda event source mapping concurrency is bounded. Document the quota headroom for every critical service and proactively request increases before load events.

**Red flag:** single NAT Gateway for all AZs (single AZ failure kills cross-AZ outbound traffic); Lambda with no reserved concurrency guard protecting a downstream throttle-sensitive service.

### 3.5 Cost Optimization for Existing Workloads

1. **Unused resources:** Trusted Advisor flags idle load balancers, unattached EBS volumes, EC2 instances with low CPU. `aws ec2 describe-volumes --filters Name=status,Values=available` finds unattached volumes directly.
2. **Savings Plan coverage:** Cost Explorer shows Savings Plan coverage and utilization. Gap = On-Demand spend that could be covered — purchase 1yr Compute Savings Plans to cover the stable baseline.
3. **S3 cost audit:** S3 Storage Lens gives bucket-level metrics. Lifecycle policies that transition objects to cheaper storage tiers are the first lever; Intelligent-Tiering automates this for uncertain access patterns.
4. **Data transfer audit:** Cost and Usage Reports (CUR) expose data-transfer line items at resource level. Replace NAT Gateway egress for S3/DynamoDB with Gateway endpoints (free) to eliminate that cost category entirely.

**Red flag:** no lifecycle policies on S3 buckets older than 90 days; gp2 EBS volumes (migrate to gp3 for lower cost + higher baseline performance); no Savings Plan in a stable production environment running 24/7.

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

**Discover first:**
- **AWS Application Discovery Service (ADS):** agentless (VMware vCenter integration) or agent-based discovery; collects server config, performance, and process data; feeds Migration Hub.
- **AWS Migration Hub:** single pane of glass for tracking all migration activities across tools.

**Move servers:**
- **AWS Application Migration Service (MGN):** block-level continuous replication to AWS (replaces CloudEndure Migration); primary tool for Rehost; supports cutover testing without impacting source.

**Move data:**
- **AWS DataSync:** scheduled, agent-based sync for NFS/SMB shares to S3/EFS/FSx; good for ongoing sync before cutover.
- **AWS Snow Family:** offline bulk data transfer — Snowcone (8 TB usable, edge compute), Snowball Edge (80 TB usable, storage + compute), Snowmobile (100 PB, truck) — when network bandwidth makes online transfer impractical (rule of thumb: >10 TB with <1 Gbps link).
- **S3 Transfer Acceleration:** speeds up S3 PUT/GET over the public internet using CloudFront edge locations; useful when online transfer is acceptable but latency is high.
- **AWS Transfer Family:** managed SFTP/FTPS/FTP endpoint backed by S3 or EFS; for partners or systems that require file-protocol interfaces.

**Move databases:**
- **AWS Database Migration Service (DMS):** heterogeneous and homogeneous DB migrations; supports ongoing replication for near-zero-downtime cutovers.
- **AWS Schema Conversion Tool (SCT):** converts schema and application code from Oracle/SQL Server/etc. to Aurora/PostgreSQL/MySQL; run SCT before DMS for heterogeneous migrations.

**Identity for hybrid:**
- **IAM Identity Center + Active Directory:** AWS Managed Microsoft AD or AD Connector links on-premises AD to IAM Identity Center; users authenticate with existing credentials.
- **AWS Directory Service:** choose AD Connector (proxy to on-premises, no directory data in AWS) vs AWS Managed Microsoft AD (full AD in AWS, needed for trust relationships and domain-join of EC2).

**Red flag:** using DMS for a schema conversion without running SCT first (leaves incompatible objects); choosing Snow family for a 500 GB dataset with a 1 Gbps link (DataSync is faster and cheaper); forgetting to re-point DNS during cutover (causes post-migration connectivity failures).

### 4.3 New Architecture for Existing Workloads (Replatform/Refactor)

**Compute modernization path:**

| From | To | Key decision |
|---|---|---|
| Bare metal / VM | EC2 in ASG | Rehost; optimize instance family to workload |
| App server (Tomcat, etc.) | Elastic Beanstalk | Managed platform; still EC2 underneath |
| Stateless service | ECS/Fargate or EKS/Fargate | Container adoption; Fargate removes node management |
| Event-driven / short tasks | Lambda | Serverless; eliminates idle compute cost |

**Storage modernization:**
- Block: EBS for EC2 boot and transactional I/O; default to gp3.
- File: EFS (NFS, POSIX, multi-AZ) for shared Linux workloads; FSx for Windows (SMB/DFS) or FSx for Lustre (HPC/ML).
- Object: S3 — the default for unstructured data, backups, static assets, data lakes.
- Hybrid cache: Storage Gateway Volume Gateway for on-premises apps that need to read/write to S3 via iSCSI.

### 4.4 Modernization Opportunities

**Decoupling patterns:**
- Replace synchronous inter-service calls with SQS queues (async, buffered).
- Replace fan-out direct calls with SNS topic + SQS subscriptions.
- Replace custom schedulers with EventBridge Scheduler.
- Replace custom workflow engines with Step Functions.

**Serverless candidates:** any workload with spiky, unpredictable, or low-average traffic is a Savings Plan target or a serverless candidate. Lambda works well for: API backends (via API Gateway), event processors (S3/DynamoDB streams, SQS), scheduled jobs, and data transformations. Lambda does *not* work well for: long-running (>15 min) tasks, workloads needing persistent in-memory state, or workloads with very consistent high throughput (EC2 + Savings Plan is cheaper).

**Purpose-built databases over MySQL-for-everything:**
- High-volume time-series → Amazon Timestream
- Fraud/recommendation graphs → Amazon Neptune
- Ledger / audit trail → Amazon QLDB
- Session/cache → ElastiCache Redis
- Full-text search → OpenSearch

**Red flag:** migrating a stateful monolith to Lambda without externalizing state; using RDS MySQL for a workload that is clearly key-value (DynamoDB is cheaper and scales better); refactoring to microservices without first establishing service contracts and observability.

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

_Independent educational content for upskilling AI agents. Not affiliated with or endorsed by Amazon Web Services; all trademarks belong to their owners. Guidance only — verify against official AWS documentation and live accounts._
