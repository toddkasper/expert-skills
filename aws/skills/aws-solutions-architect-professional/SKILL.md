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

Operational playbook for designing complex AWS architectures. Each section states the rule an architect applies when reviewing or designing: decision criteria for picking services, anti-patterns to catch in design reviews. **Verify against the live account** — limits, pricing, and feature availability change frequently.

> **Load this skill when…** evaluating or designing complex AWS architectures across multiple accounts or regions; choosing connectivity patterns (TGW, VPC Peering, Direct Connect, PrivateLink); planning migration strategy (7 Rs, tooling, wave planning); or making cost/resilience/performance trade-offs at enterprise scale.
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

**SCP vs IAM:** SCPs define the *maximum permissions* an account's IAM principals can have — they do not grant. A principal needs both an SCP allow *and* an IAM grant. An explicit SCP Deny blocks even root. Use SCPs for non-negotiable guardrails (block CloudTrail disable, restrict regions); use IAM for fine-grained access within accounts.

**Red flags:** single AWS account for all workloads; IAM alone to isolate prod vs dev; SCPs on root instead of specific OUs; forgetting SCPs don't affect the management account.

**Verify:** `aws organizations list-policies --filter SERVICE_CONTROL_POLICY`; `aws organizations describe-effective-policy --policy-type SERVICE_CONTROL_POLICY`.

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

**Transitive routing trap:** VPC Peering is non-transitive — A→B and B→C does not mean A→C. Use Transit Gateway for transitive routing.

**DNS in hybrid architectures:** Route 53 Resolver inbound endpoints let on-premises resolvers forward queries to Route 53; outbound endpoints let VPC resources forward queries on-premises. Forwarding rules wire which domains go where.

**Red flags:** hub VPC for transitive routing via peering (won't work); Direct Connect without VPN when in-transit encryption required; overlapping CIDRs in a peering or TGW architecture.

**Verify:** `aws ec2 describe-transit-gateway-attachments`; `aws route53resolver list-resolver-endpoints`; validate route table entries in each VPC after wiring.

### 1.3 Resilience and DR at Org Scale

Match the DR pattern to the RTO/RPO requirement, not to the maximum:

| Pattern | Typical RTO | Typical RPO | Cost tier |
|---|---|---|---|
| Backup and restore | Hours | Hours (last backup) | Lowest |
| Pilot light | 10s of minutes | Minutes | Low-medium |
| Warm standby | Minutes | Near-zero | Medium-high |
| Multi-site active/active | Near-zero | Near-zero | Highest |

**AWS Elastic Disaster Recovery (DRS):** managed replication + failover for lift-and-shift DR (replaces CloudEndure); sub-minute RPO for server-based workloads.

**Red flag:** multi-region active/active for RTO = 4 hr / RPO = 1 hr (warm standby suffices); backup & restore for RTO = 15 min.

### 1.4 Cost Visibility

Tag at creation — retrofitting is painful. Enforce via SCP or Config rules. Cost Explorer for trend analysis/forecasts; Budgets for alerts; Compute Optimizer for rightsizing; Trusted Advisor for idle resources and coverage gaps.

---

## 2. Design for New Solutions (29%)

### 2.1 Deployment Strategy

| Pattern | Zero downtime | Rollback | Cost | Use when |
|---|---|---|---|---|
| All-at-once | No | Slow | Lowest | Dev/test, batch |
| Rolling | Partial | Medium | Low | Tolerates brief mixed-version |
| Blue/green | Yes | Instant (swap) | 2× capacity | Production, stateless services |
| Canary | Yes | Instant (shift back) | Slight overhead | Gradual validation in production |

CodeDeploy, ECS deployment config, and Lambda aliases support blue/green and canary natively. CloudFormation change sets = pre-deploy plan view.

**Red flag:** manual console changes outside IaC; blue/green for a stateful service without externalizing session state first.

### 2.2 Business Continuity and DR Design

Maps to §1.3. Multi-AZ is the availability floor — not a DR strategy. Multi-region required when RTO < ~10 min or single-region failure is unacceptable. Route 53 (failover/latency/weighted) is the DNS layer; S3 CRR and RDS cross-region read replicas are the data plane.

**Red flag:** Multi-AZ RDS presented as cross-region DR; single-region S3 bucket as DR storage.

### 2.3 Security Controls for New Architectures

- **Network:** security groups (stateful, per-ENI, allow-only); NACLs (stateless, explicit inbound+outbound) for broad block-lists.
- **Identity:** IAM roles for all compute; cross-account assume-role with external ID (confused-deputy prevention); IAM Roles Anywhere for on-premises.
- **Data:** KMS CMKs when audit trail or cross-service sharing needed; AWS-managed keys for lower overhead. Enforce TLS via `aws:SecureTransport` in S3 bucket policies.
- **Detection:** GuardDuty org-wide; Security Hub for aggregated findings; Config for drift; org-level CloudTrail.
- **Secrets:** Secrets Manager for rotating credentials; SSM Parameter Store SecureString for non-rotating config. Shield Standard (free, L3/L4); Shield Advanced `[volatile — verify live]` for L7 DDoS + SRT.

**Red flag:** long-lived IAM access keys in Lambda/EC2; SGs with `0.0.0.0/0` on non-public ports; no org-level CloudTrail; no GuardDuty in non-production accounts.

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

**Loose coupling:** SQS (standard: at-least-once; FIFO: exactly-once + ordering); SNS fan-out; EventBridge content-based routing; Step Functions for multi-step orchestration.

**Red flag:** synchronous calls with no timeout or circuit breaker; DynamoDB hot partition keys; single-AZ RDS in production.

### 2.5 Performance and Cost for New Designs

**Caching:** CloudFront (edge) → ElastiCache (app-tier) → DAX (DynamoDB microsecond). Apply at the layer closest to the bottleneck.

**Instance selection:** C (CPU); R/X (memory); I/D (NVMe); P/G/Inf (ML). Use Global Accelerator for Anycast TCP routing for non-HTTP workloads.

**Purchasing:** On-Demand for variable; Compute Savings Plans (1yr/3yr, EC2+Fargate+Lambda) for steady-state; Spot for fault-tolerant batch/ML. Default to EBS gp3 over gp2.

**Data transfer:** inter-AZ transfer costs money. Use S3/DynamoDB Gateway endpoints (free) to eliminate NAT Gateway egress.

**Red flag:** On-Demand for 24/7 production; gp2 EBS; ignoring inter-AZ transfer costs.

---

## 3. Continuous Improvement for Existing Solutions (25%)

### 3.1 Operational Excellence

**Observability:** alarm on P99, not average; structured JSON logs with retention policies (uncapped = cost leak); X-Ray distributed traces; CloudWatch dashboards or Managed Grafana. Move console deployments to CodePipeline; schedule `detect-stack-drift` to catch manual changes.

**Red flag:** alarms on Average latency only; no log retention policy; no runbooks for common failure modes.

### 3.2 Security Posture Improvement

Security Hub aggregates GuardDuty, Inspector, Macie, Firewall Manager, and IAM Access Analyzer findings — prioritize by severity × blast radius. IAM Access Analyzer finds unintended external access (run org-wide). Add managed Config rules with SSM Automation remediation. Use SSM Patch Manager + Inspector for CVE management.

**Red flag:** GuardDuty not org-wide; S3 Block Public Access not enabled at org level; IAM roles with `*:*`.

### 3.3 Performance and Reliability Improvement

**Performance:** instrument before resizing — X-Ray service maps, Container Insights, Lambda Insights. Compute Optimizer recommends right-sizes based on p99. For databases: Performance Insights, Slow Query Logs, read replicas, DAX for DynamoDB.

**Reliability — eliminate SPOFs in blast-radius order:** single NAT Gateway → one per AZ; single EC2 → ASG min 2; single RDS → Multi-AZ; hard-coded endpoints → Route 53/LB DNS; synchronous calls no retry → SQS or exponential backoff.

Lambda default: 1,000 concurrent executions per region `[volatile — verify live]`. Document quota headroom; request increases before load events.

**Red flag:** resizing on Average CPU; single NAT Gateway for all AZs; Lambda with no reserved concurrency on a critical downstream.

### 3.4 Cost Optimization for Existing Workloads

Key levers: unused resources (Trusted Advisor; unattached EBS: `aws ec2 describe-volumes --filters Name=status,Values=available`); Compute Savings Plans for steady-state; S3 lifecycle policies or Intelligent-Tiering; free Gateway endpoints to replace NAT Gateway egress for S3/DynamoDB.

> Step-by-step cost optimization workflow (CUR analysis, rightsizing signals, Savings Plan purchase process, S3 Storage Lens setup): [references/cost-optimization.md](references/cost-optimization.md).

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

**Wave planning:** group by dependency, risk, and team capacity. Low-complexity standalone apps first; shared platform services (AD, DNS, monitoring) migrate with or before their dependents.

**Red flag:** defaulting every workload to Refactor; not mapping dependencies before wave planning; skipping Retire/Retain evaluation.

**Verify TCO:** AWS Migration Evaluator or Pricing Calculator — include hardware refresh, datacenter, licensing, and staff in the on-premises run rate.

### 4.2 Migration Tooling

> Full tool-by-tool reference (ADS, MGN, DataSync, Snow Family, DMS, SCT, Transfer Family, Directory Service) lives in [references/migration-tooling.md](references/migration-tooling.md). Load that file when selecting a specific migration tool. Key decision rules inline below.

**Core decision rules (always loaded):**
- **MGN** for server Rehost (block-level replication; test launch does not interrupt the source server).
- **DMS** for database migration; always run **SCT first** for heterogeneous migrations (Oracle/SQL Server → Aurora/PostgreSQL) — schema incompatibilities mid-migration are expensive.
- **DataSync** for file-share sync (NFS/SMB → S3/EFS/FSx) when bandwidth is sufficient. **Snow family** when online transfer is impractical (>10 TB with <1 Gbps) `[volatile — verify live]`.
- **AD Connector** (proxy) when on-premises AD must stay authoritative; **AWS Managed Microsoft AD** when you need a full AD in AWS for domain-join and trusts.
- **AWS Application Discovery Service** before wave planning — dependency mapping must precede grouping.
- Run DMS in **CDC mode** for near-zero-downtime cutovers — full-load + CDC keeps target in sync; cutover window is minutes, not hours.

**Red flag:** using DMS without running SCT first on heterogeneous migrations; choosing Snow family for a 500 GB dataset with a 1 Gbps link (DataSync is faster); forgetting to re-point DNS during cutover; skipping a test launch with MGN before the production cutover window.

### 4.3 Replatform/Refactor Patterns

> Full compute, storage, decoupling, serverless-candidate, and purpose-built-database reference: [references/architecture-patterns.md](references/architecture-patterns.md). Core rules below.

- **Compute modernization:** EC2 in ASG → Elastic Beanstalk → ECS/EKS on Fargate → Lambda. Don't jump to Lambda without verifying task duration <15 min and state can be externalized.
- **Storage:** EBS gp3 (block, default over gp2); EFS for Linux POSIX / FSx for Windows SMB/DFS or Lustre HPC; S3 (object); Storage Gateway Volume (hybrid iSCSI).
- **Decoupling:** SQS for async; SNS+SQS for fan-out; EventBridge Scheduler for custom schedules; Step Functions for multi-step workflows.
- **Purpose-built databases:** DynamoDB (key-value); Neptune (graph); Timestream (time-series); QLDB (ledger); OpenSearch (full-text) — don't default everything to RDS.
- Lambda cost-optimal for spiky/event-driven; EC2 + Savings Plan cheaper for 24/7 consistent throughput — cross-compare at ~50% utilization.

**Red flag:** migrating a stateful monolith to Lambda without externalizing state; using RDS MySQL for a key-value workload; refactoring to microservices without service contracts and observability; choosing EFS when FSx for Windows is required for SMB/DFS.

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

1. **Map RTO/RPO to pattern:** RTO > 1 hr → Backup & Restore. RTO 10–60 min → Pilot Light. RTO 1–10 min → Warm Standby. RTO < 1 min → Multi-site Active-Active. Confirm with AWS Pricing Calculator — never commit to multi-region active/active when warm standby satisfies the SLA.
2. **Establish data replication:** RDS cross-region read replica or Aurora Global Database; S3 CRR; DynamoDB Global Tables. Gate: CloudWatch `ReplicaLag` < RPO target.
3. **Deploy the DR stack** scaled-down in the DR region. Gate: Route 53 health check on DR endpoint is `Healthy`.
4. **Configure Route 53 failover** routing with TTL = 60s; test by disabling the primary health check and confirming DNS resolves to DR within 2× TTL.
5. **Test the runbook quarterly:** promote the RDS read replica (`aws rds promote-read-replica`); run smoke tests. An untested DR runbook is not a DR strategy.

> The primary gate commands for each step are in the workflow above. For full RDS/Aurora cross-region replication setup, see the data-store details in §1.3.

---

## Decision Scenarios

**Scenario 1 — Transit Gateway vs VPC Peering: the transitive routing trap**

> **Situation:** An architect designs connectivity for 8 VPCs across 3 accounts using hub-and-spoke peering (7 connections to a shared-services VPC). Three months later two application VPCs need to communicate directly; reaching a full mesh would require N×(N-1)÷2 = 28 peering connections.

> **Competent move:** Use **Transit Gateway** from the start. TGW supports transitive routing — any attached VPC reaches any other through a single route table; adding a new VPC requires one attachment, not N new peering connections. TGW also supports VPN and Direct Connect attachments for hybrid extension. Per-attachment and per-GB charges are justified at ~4+ VPCs.

> **Tempting-but-wrong:** Extending the peering design on demand. Each new pair requires a dedicated connection, route table entries in both VPCs, and security group updates — operational overhead grows quadratically.

> **Verify:** `aws ec2 describe-transit-gateways`; `aws ec2 describe-transit-gateway-attachments --filters Name=state,Values=available`; `aws ec2 describe-transit-gateway-route-tables`; `traceroute` from VPC-A to a private IP in VPC-B confirms routing traverses the TGW.

---

**Scenario 2 — Direct Connect encryption gap**

> **Situation:** An enterprise migrates a payment-processing application to AWS over a dedicated 10 Gbps AWS Direct Connect connection. The network team provisions the DX connection and confirms link-state is up. The security team signs off on the architecture because "Direct Connect is a private connection." The compliance team later flags the design: traffic traversing the DX link does not meet the PCI-DSS requirement for encryption in transit.

> **Competent move:** AWS Direct Connect is a dedicated Layer 2 circuit — it is private in the sense that it bypasses the public internet, but it is **not encrypted** in transit by default. For PCI-DSS and similar mandates that require encryption of data in transit, run a Site-to-Site VPN *over* the Direct Connect connection (a DX-backed VPN). This gives the dedicated, low-latency path of DX plus IPsec encryption. Alternatively, use MACsec (available on dedicated DX connections at 1/10/100 Gbps) for Layer 2 encryption at the DX port level — check that the DX location and partner support MACsec before committing.

> **Tempting-but-wrong:** Treating a private/dedicated connection as equivalent to an encrypted connection and skipping the VPN overlay. "Private" means no shared internet path; it does not mean the signal is encrypted. An insider at the colocation facility or a DX partner router compromise would expose cleartext traffic.

> **Verify:** `aws directconnect describe-connections --connection-id <id> --query 'connections[0].encryptionMode'` — on a plain DX connection this returns `no_encrypt`; with MACsec it returns `must_encrypt` or `should_encrypt`. For VPN-over-DX: `aws ec2 describe-vpn-connections --query 'VpnConnections[?State==\`available\`].VgwTelemetry'` to confirm both VPN tunnels are UP.

---

**Scenario 3 — Lambda concurrency exhaustion attacking Aurora connection pool**

> **Situation:** A Lambda function processes events from an SQS queue and writes results to an Aurora MySQL database. During a Black Friday traffic spike, Lambda scales to 800 concurrent executions. The Aurora `db.r6g.2xlarge` instance (max_connections ≈ 900) immediately hits connection exhaustion: `Too many connections` errors appear in Lambda logs, and Aurora CPU spikes to 100%. An engineer proposes increasing Lambda reserved concurrency to 200 as a "throttle." Another proposes upgrading Aurora to `db.r6g.4xlarge`.

> **Competent move:** The root cause is that each Lambda invocation opens a new Aurora connection (Lambda's execution environment does not persist connections between invocations when cold-started). At 800 concurrent Lambdas, each holding a connection, Aurora's connection limit is exhausted. The correct architectural fix is **Amazon RDS Proxy**: RDS Proxy maintains a persistent connection pool to Aurora and multiplexes many Lambda connections through far fewer backend connections. This breaks the linear scaling relationship between Lambda concurrency and DB connections. Reducing Lambda reserved concurrency to 200 trades a database problem for a queue backlog problem. Upgrading Aurora to a larger instance raises the ceiling but does not eliminate the underlying pooling problem and adds cost.

> **Tempting-but-wrong:** Raising the Aurora instance class. A larger instance has more max_connections, but at full Lambda scale the problem recurs — Aurora instance sizing is not a substitute for connection pooling. RDS Proxy is the architectural fix regardless of instance size.

> **Verify:** `aws rds describe-db-clusters --db-cluster-identifier <id> --query 'DBClusters[0].Endpoint'` to confirm connectivity; `aws rds describe-db-proxies` to confirm RDS Proxy is deployed and associated with the cluster; in CloudWatch, watch the `DatabaseConnections` metric on the Aurora cluster — with RDS Proxy it should plateau well below `max_connections` even as Lambda concurrency scales.

---

**Scenario 4 — Snow family vs DataSync: which to use for a 14 TB migration**

> **Situation:** A company needs to migrate 14 TB of on-premises NFS data to Amazon S3 before a datacenter decommission. The network team reports a 500 Mbps internet uplink with typical sustained throughput of 300 Mbps. The migration lead immediately orders a Snowball Edge device, reasoning "14 TB is a lot of data." The project timeline allows 3 weeks for the migration.

> **Competent move:** At 300 Mbps sustained, 14 TB transfers online in approximately 14 TB × 8 bits/byte ÷ 300 Mbps ≈ 374,000 seconds ≈ 4.3 days — well within the 3-week window. Snowball Edge has a minimum 10-business-day shipping + return cycle; for 14 TB with a healthy internet link it is slower and adds cost (device rental + shipping). Use **AWS DataSync** for an online transfer: install the DataSync agent on-premises, configure an NFS location, and schedule a full sync followed by an incremental sync near cutover. The 10 TB–1 Gbps rule of thumb for choosing Snow family means Snow is appropriate when online transfer would take weeks or months (>10 TB and <10 Mbps effective throughput) — not when the link is 300+ Mbps.

> **Tempting-but-wrong:** Defaulting to Snowball Edge because the dataset "sounds large." The Snow family is the right tool when network bandwidth makes online transfer impractical (weeks of transfer time). 14 TB at 300 Mbps is comfortably online. Ordering Snowball adds shipping delay and device rental cost unnecessarily.

> **Verify:** Before committing, use the AWS DataSync console bandwidth calculator or estimate transfer time manually (dataset size ÷ available throughput). After DataSync starts: `aws datasync list-task-executions --task-arn <arn>` and `describe-task-execution` to monitor bytes transferred and estimated time remaining.

Additional scenarios (single NAT Gateway SPOF, SCP vs IAM boundary): [references/scenarios.md](references/scenarios.md).

---

## Operational Rules Quick Reference

Each rule is concrete and imperative.

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

- **2026-06-09** — Conformed to 12-dimension skill standard: task-vocab description, Scope block, Uncertainty & Escalation with `[volatile — verify live]` marks, executable workflows, tool-agnostic verify steps, feedback protocol. Exam logistics relocated to references/study-resources.md.
- **2026-06-09** — Inlined 4 decision scenarios; restored D3 migration/architecture core decision rules inline in §4.2 and §4.3; prose compression pass.

---

_Independent educational content for upskilling AI agents. Not affiliated with or endorsed by Amazon Web Services; all trademarks belong to their owners. Guidance only — verify against official AWS documentation and live accounts._
