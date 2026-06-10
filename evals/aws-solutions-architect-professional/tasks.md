# Application tasks — aws-solutions-architect-professional (Lens 4, held-out)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

A skilled agent produces the artifact; a judge grades against the trap-keyed rubric. Run baseline vs skilled.

---

## Task 1 — Multi-account networking + DR architecture redline

**Prompt to the agent:** Review the following multi-account AWS architecture spec. Produce an annotated redline that identifies every connectivity, resilience, cost, and DR-pattern flaw. For each flaw: name it, explain the failure mode or cost risk, and state the correct design.

```
# Architecture spec: FinanceCo Production Platform

## Account structure
- Management account: root of AWS Organization
- Shared-services account: Transit Gateway hub, centralized DNS (Route 53 Resolver)
- Three workload accounts: AppA, AppB, AppC
- Each workload account has one VPC (10.0.0.0/16, 10.1.0.0/16, 10.2.0.0/16)

## Connectivity
- AppA, AppB, and AppC VPCs are connected via VPC Peering (full mesh: 3 peering connections).
- Each VPC has one NAT Gateway deployed in a single Availability Zone (AZ-a).
- Direct Connect connection (1 Gbps) from on-premises to the management account VPC.
  No MACsec or IPsec overlay configured on the Direct Connect connection.
- On-premises DNS server forwards all *.internal.financeco.com queries to the
  Route 53 Inbound Resolver endpoint in the shared-services VPC.
  No Outbound Resolver endpoint configured.

## Disaster recovery
- RTO target: 4 hours. RPO target: 30 minutes.
- DR strategy: Nightly AMI snapshots + RDS automated backups sent to the same region (us-east-1).
- No cross-region replication configured for S3 buckets or RDS.
- Route 53 health checks are configured, but no failover routing policy exists.

## Database tier
- Aurora MySQL cluster in AppA account, us-east-1, two instances (one writer, one reader).
  Both instances are in the same Availability Zone (AZ-a).
- Lambda functions in AppA and AppB connect directly to the Aurora writer endpoint.
  No RDS Proxy configured. Lambda reserved concurrency: 500 per function.
```

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — VPC Peering full mesh does not scale: with 3 VPCs it is manageable, but the spec implies future growth; peering is non-transitive and becomes O(n²) connections. Replace with Transit Gateway for the hub-and-spoke model the shared-services account implies.
- [ ] Trap 2 — Single-AZ NAT Gateway is a single point of failure (SPOF): if AZ-a goes down all outbound internet traffic from private subnets fails. Deploy one NAT Gateway per AZ; note the inter-AZ data-transfer cost trade-off.
- [ ] Trap 3 — Direct Connect without MACsec or IPsec overlay means data traversing the physical DX connection is unencrypted in transit; for financial data this is a compliance and exfiltration risk. Add an IPsec VPN over DX or enable MACsec for encryption at layer 2.
- [ ] Trap 4 — No Outbound Resolver endpoint means Route 53 cannot forward DNS queries from AWS workloads to on-premises resolvers; any service in the workload VPCs that needs to resolve on-premises hostnames (e.g., legacy LDAP, on-prem databases) will silently fail DNS resolution. An Outbound Resolver endpoint with forwarding rules is required.
- [ ] Trap 5 — DR strategy (nightly snapshots, same-region only, no Route 53 failover policy) does not match the stated RTO/RPO: a 30-minute RPO requires at minimum cross-region RDS automated backup replication or Aurora Global Database, and 4-hour RTO requires a warm standby in a second region with Route 53 failover routing, not cold AMI restores. Current design is closest to backup-and-restore, which typically yields RTO of 24+ hours.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Recommends replacing VPC Peering mesh with Transit Gateway attachments from each workload VPC to the shared-services TGW, with route tables to control east-west traffic.
- Specifies one NAT Gateway per AZ in each VPC; documents the per-GB cross-AZ cost vs. availability trade-off.
- Specifies MACsec (if the DX partner supports it) or an AWS Site-to-Site VPN over the DX connection for encryption in transit; flags that a single 1 Gbps DX without a backup VPN is also a connectivity SPOF.
- Adds a Route 53 Outbound Resolver endpoint with forwarding rules for `*.internal.financeco.com` to the on-premises DNS server IP.
- Recommends Aurora Global Database (or cross-region read replica with promotion plan) plus Route 53 failover routing policy to a pilot-light stack in a secondary region, which matches the 4-hour RTO / 30-minute RPO profile.
- Flags the Aurora single-AZ placement as an additional availability risk; both writer and reader must span at least two AZs for Multi-AZ protection.
- Flags that Lambda at 500 concurrent connections per function directly to Aurora without RDS Proxy will exhaust the Aurora connection pool; add RDS Proxy.

---

## Task 2 — Migration strategy + service-selection architecture review

**Prompt to the agent:** Your company is migrating a three-tier on-premises application to AWS. Review the migration plan below and produce an architecture redline: identify every wrong 7-R classification, service-selection mismatch, and cost/complexity trap. For each issue, name it, explain the risk, and state the correct recommendation.

```
# Migration plan: RetailCo E-Commerce Platform

## Application inventory
Tier 1 — Web frontend: 4 x Apache/PHP servers (8 vCPU, 16 GB RAM each), stateless
Tier 2 — App servers: 6 x Java Spring Boot (16 vCPU, 64 GB RAM), stateful session cache in local memory
Tier 3 — Database: 12 TB SQL Server Enterprise on a single bare-metal server (48 vCPU, 512 GB RAM)

## Proposed migration strategy

### Tier 1 — Web frontend
Strategy: Rehost (lift-and-shift) to EC2 m5.2xlarge instances (8 vCPU, 32 GB RAM).
Rationale: "Stateless, easiest to move."

### Tier 2 — App servers
Strategy: Rehost to EC2 r5.4xlarge instances (16 vCPU, 128 GB RAM).
Rationale: "Match on-prem specs; session state is in local memory so we keep it in EC2."

### Tier 3 — Database
Strategy: Rehost SQL Server to a single EC2 r5.12xlarge (48 vCPU, 384 GB RAM) with EBS gp2 storage.
Rationale: "We can't change the database in this migration window."

## Networking
- All three tiers will be in a single public subnet with public IPs assigned to every instance.
- Security group: inbound 0-65535 from 0.0.0.0/0 on all tiers.

## Cost optimization
- All instances will be On-Demand pricing (no Savings Plans or Reserved Instances).
- No Auto Scaling configured on any tier.

## Post-migration
- No CloudWatch monitoring configured.
- No backup policy defined for Tier 3.
```

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — Tier 1 (stateless PHP web frontend) is classified as Rehost to EC2 when it is a clear Replatform or Re-architect candidate: containerize to ECS/Fargate or serve via Elastic Beanstalk, and put static assets on S3 + CloudFront. Rehosting stateless web servers to EC2 misses the cost and operational simplicity gains.
- [ ] Trap 2 — Tier 2 session state in local EC2 memory creates an availability and scaling trap: under Auto Scaling (which the plan omits), new instances have no session state, causing user logouts on scale-out. The correct fix is to externalize session state to ElastiCache (Redis) and only then can the tier be safely Auto Scaled.
- [ ] Trap 3 — Tier 3 database on a single EC2 instance with EBS gp2 is a single point of failure with no HA, no managed backups, and gp2 baseline IOPS of 3 IOPS/GB (36,000 IOPS max) may be insufficient for a 12 TB SQL Server workload that was previously on bare-metal NVMe. At minimum use gp3/io2 with provisioned IOPS; recommend RDS SQL Server Multi-AZ with automated backups as the right Replatform path for HA and licensing compliance.
- [ ] Trap 4 — All instances in a single public subnet with `0-65535` open from `0.0.0.0/0` exposes the database and app tier directly to the internet. The architecture requires at minimum three subnet tiers (public for ALB, private for app, isolated for DB) with security groups restricting each tier to only the upstream tier's security group as source.
- [ ] Trap 5 — All On-Demand with no Savings Plans or Auto Scaling means the steady-state compute cost is 30–40% higher than necessary; for a predictable baseline, 1-year Compute Savings Plans cover flexible instance-family usage, and Auto Scaling on Tier 1/2 removes the need to provision for peak capacity 24/7.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Re-classifies Tier 1 as Replatform: ECS Fargate containers behind an ALB with CloudFront + S3 for static assets, eliminating the need to manage EC2 instances for a stateless web layer.
- Prescribes ElastiCache for Redis to externalize Tier 2 session state before any horizontal scaling; then Tier 2 can be safely Auto Scaled with an ALB.
- Recommends Replatform of Tier 3 to RDS SQL Server Multi-AZ with gp3/io2 storage; flags the SQL Server Enterprise license cost under License Included vs. BYOL, and notes AWS SCT/DMS as the migration toolchain.
- Redesigns network into three subnet tiers across two AZs minimum; removes public IPs from app and DB tiers; restricts SG ingress to the correct upstream tier SG.
- Recommends 1-year Compute Savings Plans for the predictable base load and Auto Scaling on Tiers 1 and 2.
- Adds CloudWatch alarms (CPU, RDS storage, connection count) and an RDS backup window with 7-day retention as the minimum post-migration operational baseline.
