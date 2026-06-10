# Architecture Patterns — AWS Solutions Architect Professional

> Loaded on demand from the SAP SKILL.md body (§4.3 / §4.4 — Replatform/Refactor and Modernization).

## Compute Modernization Path

| From | To | Key decision |
|---|---|---|
| Bare metal / VM | EC2 in ASG | Rehost; optimize instance family to workload |
| App server (Tomcat, etc.) | Elastic Beanstalk | Managed platform; EC2 underneath |
| Stateless service | ECS/Fargate or EKS/Fargate | Container adoption; Fargate removes node management |
| Event-driven / short tasks | Lambda | Serverless; eliminates idle compute cost |

## Storage Modernization

- **Block:** EBS for EC2 boot and transactional I/O; default to gp3.
- **File:** EFS (NFS, POSIX, multi-AZ) for shared Linux; FSx for Windows (SMB/DFS) or FSx for Lustre (HPC/ML).
- **Object:** S3 — default for unstructured data, backups, static assets, data lakes.
- **Hybrid cache:** Storage Gateway Volume Gateway for on-premises apps needing S3 access via iSCSI.

## Decoupling Patterns

- Replace synchronous inter-service calls with SQS (async, buffered).
- Replace fan-out direct calls with SNS topic + SQS subscriptions.
- Replace custom schedulers with EventBridge Scheduler.
- Replace custom workflow engines with Step Functions.

## Serverless Candidates

Lambda works well for: API backends (API Gateway), event processors (S3/DynamoDB streams, SQS), scheduled jobs, data transformations. Lambda does **not** work well for: tasks > 15 min, workloads needing persistent in-memory state, or workloads with consistent high throughput (EC2 + Savings Plan is cheaper at sustained utilization).

## Purpose-Built Databases

| Workload | Service |
|---|---|
| High-volume time-series | Amazon Timestream |
| Fraud/recommendation graphs | Amazon Neptune |
| Ledger / audit trail | Amazon QLDB |
| Session/cache | ElastiCache Redis |
| Full-text search | OpenSearch |

**Red flag:** migrating a stateful monolith to Lambda without externalizing state; using RDS MySQL for a key-value workload; refactoring to microservices without first establishing service contracts and observability.

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
