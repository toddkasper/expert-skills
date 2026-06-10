---
name: aws-devops-engineer-professional
description: AWS DevOps engineering — CI/CD pipelines (CodePipeline, CodeBuild, CodeDeploy), infrastructure as code (CloudFormation, CDK, Systems Manager), deployment strategies (blue/green, canary), resilient multi-AZ/multi-region design, CloudWatch monitoring and logging, event-driven incident response and automated remediation, and security/compliance automation. Use when building, reviewing, or debugging AWS delivery pipelines, IaC templates, observability stacks, or auto-remediation. Not security-first design (see aws-security-specialty) or enterprise architecture trade-offs (see aws-solutions-architect-professional). Scoped and benchmarked by the AWS DevOps Engineer – Professional (DOP-C02) blueprint.
metadata:
  credential: AWS Certified DevOps Engineer – Professional
  exam-code: DOP-C02
  domain: aws
  type: certification-playbook
  status: current
  last-reviewed: 2026-06-09
  blueprint-verified: 2026-06-07
  blueprint: DOP-C02 (launched March 2023; verify at official exam guide link below)
---

# AWS Certified DevOps Engineer – Professional (DOP-C02) — Skills Reference

## Overview

The AWS Certified DevOps Engineer – Professional credential validates that a practitioner can provision, operate, and manage distributed systems and services on AWS with a high degree of automation. It targets engineers with 2+ years of hands-on AWS experience who own the delivery pipeline end-to-end: building and securing CI/CD systems, expressing infrastructure as code, designing for resilience, instrumenting observability, and enforcing security and compliance programmatically.

**This file is an operational playbook, not an exam outline.** Each section states the actual rules an agent must apply when doing DevOps work on AWS — the decision criteria for picking a deployment strategy, the failure modes to catch in review, and the "verify against the live account" steps. A recurring principle: when in doubt about account state, **query the AWS APIs — never assume from IaC source or console screenshots**, because infrastructure state diverges from templates the moment manual changes are made.

> **Load this skill when…** building or reviewing a CI/CD pipeline (CodePipeline, CodeBuild, CodeDeploy); authoring or debugging CloudFormation/CDK/SAM templates; designing deployment strategies (blue/green, canary, rolling); configuring observability stacks, automated remediation, or compliance-as-code on AWS.
> **Not this skill:** threat-detection, IAM policy depth, or encryption strategy → see `aws-security-specialty`; enterprise architecture trade-offs, migration planning, or multi-account design patterns → see `aws-solutions-architect-professional`.

> **Study resources** live in [references/study-resources.md](references/study-resources.md) (loaded on demand).

> **Verify steps assume nothing about your tooling** — use your project's MCP/automation, the AWS CLI (`aws`) or CloudShell, or the AWS Console, in that order of preference.

---

Credential logistics and study path: see [references/study-resources.md](references/study-resources.md).

---

## Uncertainty & Escalation

- **Always re-verify live — volatile facts:** service quotas (e.g., default CodePipeline pipelines per region `[volatile — verify live]`, CodeBuild concurrent builds per account `[volatile — verify live]`), EC2 instance type availability by region `[volatile — verify live]`, CloudWatch high-resolution metric pricing `[volatile — verify live]`, CodeDeploy deployment config names and timeout defaults `[volatile — verify live]`, and any feature announced after the `last-reviewed` date in this file's frontmatter.
- **Live wins:** when the live AWS account, CLI output, or official AWS docs contradict a claim in this file, the live source is authoritative. Log the discrepancy via the Feedback protocol below so the skill can be corrected.
- **Escalate to a human — do not silently execute:** deleting CloudFormation stacks or stack sets; IAM role/SCP/permission-boundary changes; KMS key policy modifications; enabling or disabling GuardDuty or CloudTrail; any action that incurs significant cost (large Snowball order, Reserved Instance purchase, EC2 fleet scaling); opening security-group or network-boundary rules; force-merging or runner policy changes in enterprise settings.
- **Confidence taxonomy:** every fact in this file is considered *stable* unless tagged `[volatile — verify live]` (changes with AWS service updates) or `[opinion — house style]` (a defensible default, not the only valid choice).

---

## 1. SDLC Automation (22%)

The heaviest domain. Master the pipeline services, deployment strategies, and how they compose differently for EC2, ECS/EKS, Lambda, and multi-account environments.

### Pipeline Architecture

**The core AWS pipeline stack:** CodeCommit/CodeConnections (source) → CodeBuild (build/test) → CodeDeploy or ECS/EKS deploy action (deploy) → CodePipeline (orchestrator). CodeArtifact sits alongside for private artifact repositories (npm, Maven, PyPI, etc.).

**Pipeline role boundaries:** CodePipeline has a service role; each action can assume a different action role. Least-privilege means the build role should have no deploy permissions, and the deploy role should have no build permissions. Cross-account pipelines require a CMK in KMS (not SSE-S3) for the artifact bucket, plus trust policies in both accounts.

**Secrets in builds:** never embed credentials in buildspec.yml or environment variables passed as plaintext. Reference Secrets Manager ARNs or Parameter Store SecureString paths in the environment block — CodeBuild injects them at runtime. Rotation of those secrets does not require pipeline changes.

### Deployment Strategies — Pick by Risk and Target

| Strategy | What it does | Best for | Rollback |
|---|---|---|---|
| **In-place (rolling)** | Replace instances one batch at a time | EC2 fleets when immutability isn't required | Re-deploy prior revision; slow |
| **Blue/green** | Traffic cut from old (blue) to new (green) environment | EC2 + ALB, ECS, Lambda aliases; near-zero-downtime required | Shift traffic back to blue instantly |
| **Canary** | Route small % to new version first, then all | Lambda, ECS with CodeDeploy; risk-averse rollouts | Automatic rollback on CloudWatch alarm |
| **Linear** | Incrementally shift traffic in equal steps | Lambda, ECS when you want gradual exposure | Automatic rollback on alarm |
| **All-at-once** | Replace all instances simultaneously | Dev/test environments; fastest but riskiest | Re-deploy; no gradual fallback |

**ECS blue/green with CodeDeploy** replaces task definitions, not instances — the controller registers new tasks in the target group, waits for health checks, then shifts the listener rule. The deployment lifecycle hooks (`BeforeInstallHook`, `AfterInstallHook`, `AfterAllowTestTraffic`, `BeforeAllowTraffic`, `AfterAllowTraffic`) invoke Lambda functions for validation; failures trigger automatic rollback.

**Lambda deployment strategies** use Lambda aliases pointing to weighted versions. `CodeDeployDefault.LambdaCanary10Percent5Minutes` means 10% traffic to the new version for 5 minutes, then 100% — or rollback if the configured alarm fires.

**EC2 Image Builder** automates golden-AMI baking — define a recipe (base OS + components), schedule builds, distribute to regions, and tag outputs. Couple with an Auto Scaling group launch template update to roll new images into the fleet.

### Automated Testing Gates

Put tests in CodeBuild buildspec phases: `pre_build` for dependency setup, `build` for unit tests/linting/SAST, `post_build` for packaging. A non-zero exit code from any phase fails the build and blocks the pipeline. Use a separate test stage in CodePipeline with a different CodeBuild project for integration/acceptance tests that run against a deployed staging environment.

**Red flags in review:**
- Plaintext secrets in buildspec or pipeline environment variables.
- A single pipeline role with both build and deploy permissions.
- Blue/green deployment on EC2 with no termination hook — old instances linger and cost money.
- No automated rollback trigger (CloudWatch alarm) on a canary or linear Lambda deployment.
- SSE-S3 on the artifact bucket in a cross-account pipeline (CMK required).

**Verify:** `aws codepipeline get-pipeline-state --name <pipeline>` to see current stage/action status; `aws codedeploy list-deployments --application-name <app>` to inspect deployment history and failure reason.

---

## 2. Configuration Management and Infrastructure as Code (17%)

IaC is not optional — it is the mechanism that makes environments reproducible, auditable, and driftless.

### CloudFormation Fundamentals

**Stack lifecycle discipline:** Create → Update → Delete. Never modify a resource that CloudFormation owns outside of CloudFormation — the resulting drift causes the next update to fail or produce unintended replacements. Run `aws cloudformation detect-stack-drift --stack-name <stack>` regularly; treat non-zero drift as a defect.

**Update behaviors:** `No interruption` (safe), `Some interruption` (brief stop), `Replacement` (new resource, old deleted). Know which resource properties cause replacement — changing an RDS `DBInstanceClass` is an interruption; changing its `Engine` is a replacement. Preview with `aws cloudformation create-change-set` before applying any update to production.

**StackSets** deploy a single template across multiple accounts and regions. Requires a delegated-admin account or CloudFormation's managed execution. Use `SELF_MANAGED` for manual trust setup; `SERVICE_MANAGED` for Organizations-integrated automated deployment to OUs.

**Nested stacks** decompose large templates; the root stack owns the lifecycle. The anti-pattern is deeply nested chains that make change sets unreadable — prefer flat stacks connected by SSM Parameter Store exports over deep nesting.

**Custom Resources (Lambda-backed)** extend CloudFormation to manage resources it doesn't natively support. The Lambda function must always respond to CloudFormation's pre-signed S3 URL with `Status: SUCCESS` or `Status: FAILED` — failure to respond leaves the stack in `UPDATE_IN_PROGRESS` forever. Always set a function timeout shorter than CloudFormation's default 1-hour wait.

**AWS CDK** synthesizes CloudFormation from code. `cdk diff` is the equivalent of a change set — run it before every `cdk deploy` in production. Bootstrapping (`cdk bootstrap`) is account/region-specific and creates the CDK toolkit stack; it must be re-run when upgrading CDK major versions.

### Systems Manager as Configuration Backbone

**Parameter Store hierarchy:** `/app/env/key` naming convention. SecureString parameters use KMS encryption — the IAM role that reads them needs `ssm:GetParameter` AND `kms:Decrypt` on the CMK. Default tier parameters are free; Advanced tier allows larger values and parameter policies (TTL-based expiry triggers for secret rotation).

**SSM Documents (Runbooks):** Command documents run shell/PowerShell on instances (requires SSM Agent + instance profile with `AmazonSSMManagedInstanceCore`). Automation documents orchestrate multi-step workflows across services — use these for DR runbooks, patching workflows, and incident remediation. State Manager associations enforce desired state on a schedule.

**Patch Manager:** define a Patch Baseline (approved/rejected CVEs, auto-approval delay), assign to a Patch Group via instance tags, create a Maintenance Window that calls the `AWS-RunPatchBaseline` document. The auto-approval delay is the key tunable: too short and you patch unvalidated; too long and you drift from compliance.

### Decision — IaC Tool

| Scenario | Recommended tool |
|---|---|
| AWS-only stack, team prefers YAML/JSON | CloudFormation |
| AWS-only stack, team prefers a real programming language | CDK (synthesizes CloudFormation) |
| Lightweight serverless apps with Lambda + API Gateway + DynamoDB | SAM (extension of CloudFormation) |
| Multi-account baseline config, OU-level rollout | CloudFormation StackSets with SERVICE_MANAGED |
| OS-level config, software install, ongoing compliance | Systems Manager State Manager |

**Red flags in review:**
- CloudFormation stack with drift that has been acknowledged and ignored.
- Custom Resource Lambda with no DLQ or timeout shorter than the retry window.
- CDK deployed without `cdk diff` review in a shared/production account.
- Parameter Store SecureString read by a role missing the `kms:Decrypt` action.
- Hardcoded account IDs or region names in CloudFormation templates (use `AWS::AccountId`, `AWS::Region` pseudo-parameters).

**Verify:** `aws cloudformation describe-stack-drift-detection-status --stack-drift-detection-id <id>` after triggering drift detection; `aws ssm describe-instance-information` to confirm SSM Agent connectivity before relying on Run Command or Patch Manager.

---

## 3. Resilient Cloud Solutions (15%)

Design for failure: every layer should degrade gracefully, and recovery should be automated, not manual.

### High Availability Patterns

**Multi-AZ is not multi-Region.** Multi-AZ protects against a single datacenter failure within one AWS Region; it does not protect against a regional event. Know the distinction when mapping business requirements to architecture:
- RDS Multi-AZ: synchronous replication, automatic failover, typically 60–120 seconds; zero data loss but brief connection interruption.
- Aurora: storage is replicated across 3 AZs by default; read replicas in the same region promote to writer in <30s typically.
- DynamoDB: built-in multi-AZ; enable Global Tables for cross-region active-active.

**Auto Scaling groups:** separate the scale-out policy (CPU/request-count metric → add capacity) from the scale-in protection rules (termination policies, instance protection, cooldown periods). The key failure mode is "scale-in deletes instances with active sessions" — use connection draining (ALB deregistration delay) and lifecycle hooks (`autoscaling:EC2_INSTANCE_TERMINATING`) to drain gracefully before termination.

**Route 53 health checks and routing policies:**

| Policy | Use |
|---|---|
| Simple | Single endpoint; no health checks supported |
| Failover | Active-passive; health check on primary, Route 53 routes to secondary on failure |
| Weighted | Split traffic by weight; use for blue/green DNS-level cutover |
| Latency | Route to the region with lowest latency for the user |
| Geolocation | Route by user's geographic location |
| Multivalue answer | Returns up to 8 healthy records; basic client-side load balancing |

Health checks can monitor an endpoint, another Route 53 health check (calculated health check), or a CloudWatch alarm — use the alarm form to tie DNS failover to application-level signals, not just TCP reachability.

### DR Strategy Selection

| Strategy | RTO | RPO | Cost |
|---|---|---|---|
| Backup & Restore | Hours | Hours | Lowest |
| Pilot Light | Tens of minutes | Minutes | Low |
| Warm Standby | Minutes | Seconds–minutes | Medium |
| Multi-site Active-Active | Near-zero | Near-zero | Highest |

**AWS Backup** centralizes backup policies across RDS, DynamoDB, EFS, EC2 (EBS snapshots), FSx, and S3. Use Backup Plans with lifecycle rules (move to cold storage after N days, expire after M days). Cross-region copies require a Backup Vault in the destination region. Test restores — an untested backup is not a backup.

**Red flags in review:**
- RDS Multi-AZ presented as a DR solution for regional failures (it isn't).
- Auto Scaling group with no lifecycle hook on termination — active sessions killed mid-flight.
- Route 53 failover with no health check on the primary — failover never triggers.
- DR runbook that requires manual console steps — automate with SSM Automation documents.
- AWS Backup plan with no restore test in the last 90 days.

**Verify:** `aws route53 get-health-check-status --health-check-id <id>` to confirm health check state; `aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names <asg>` to inspect lifecycle hooks and termination policies.

---

## 4. Monitoring and Logging (15%)

An observable system is one where any failure can be diagnosed without a code change. Build observability in from the start.

### Metrics and Alarms

**CloudWatch metric hierarchy:** Namespace → Metric Name → Dimensions → Statistics → Period. Custom metrics require `PutMetricData` calls (from the CloudWatch agent or application code). High-resolution metrics (1-second granularity) cost more but enable sub-minute alarming.

**Alarm states:** `OK`, `ALARM`, `INSUFFICIENT_DATA`. `INSUFFICIENT_DATA` is not the same as OK — it means the metric hasn't received data points in the evaluation period. This commonly fires on new resources before the first data point arrives; suppress with `treat_missing_data: notBreaching` only when that is genuinely correct.

**Composite alarms** evaluate the alarm state of other alarms using Boolean logic — use them to reduce alert noise (e.g. alert only when BOTH high CPU AND high latency are simultaneously in ALARM, not either alone).

**Anomaly detection** trains a model on historical metric data and creates an expected-value band; alarm when the metric falls outside the band. More useful than static thresholds for metrics with time-of-day patterns (web traffic, batch job durations).

### Log Management

**CloudWatch Logs key concepts:** log group → log stream → log event. Retention is `Never expire` by default — set a retention policy on every log group to control cost. Export to S3 for long-term archival (use `create-export-task`); subscribe to Kinesis Data Firehose for near-real-time delivery to S3, OpenSearch, or Splunk.

**Metric filters** extract a numeric value from log events and publish it as a CloudWatch custom metric — the primary way to alarm on application errors in logs without changing application code.

**CloudWatch Logs Insights** queries across log groups with a SQL-like syntax (`fields`, `filter`, `stats`, `sort`, `limit`). Use for ad-hoc diagnosis; for recurring analysis, export to S3 and query with Athena.

**Centralized logging across accounts:** use a log archive account. CloudWatch Logs subscription filters push to Kinesis Data Streams or Firehose in a central account; IAM resource-based policies on the destination allow cross-account delivery. Alternatively, collect via CloudWatch cross-account observability (native since 2022) which shares metrics, logs, and traces from source accounts to a monitoring account.

**AWS X-Ray** traces requests across service boundaries. Enable active tracing on Lambda, API Gateway, and ECS tasks. The service map shows node-to-node latency and error rates. Sampling rules control cost — default is 5% + first request of each second; tune per service.

**Red flags in review:**
- Log groups with `Never expire` retention (cost and compliance risk).
- CloudWatch alarm in `INSUFFICIENT_DATA` state treated as healthy.
- No centralized logging — each team's account is an island.
- X-Ray disabled on Lambda functions or API Gateway stages in production.
- Metric filter alarm threshold set to 0 with no period/evaluation-period specified — fires on first error ever.

**Verify:** `aws logs describe-log-groups --log-group-name-prefix /aws/lambda/` to inspect retention settings; `aws cloudwatch describe-alarms --alarm-names <name>` to check alarm state, thresholds, and `treat_missing_data` setting; `aws xray get-service-graph` to confirm traces are flowing.

---

## 5. Incident and Event Response (14%)

Automation is the only way to achieve consistent, repeatable incident response at cloud scale.

### Event-Driven Architecture

**EventBridge** is the routing backbone for operational events. Rules match on event patterns (JSON path filters against the event envelope) and route to targets (Lambda, SQS, SNS, Step Functions, CodePipeline, SSM Automation, etc.). Event buses: default (AWS service events), custom (your application events), and partner event buses (SaaS integrations). Cross-account delivery requires a resource-based policy on the target bus.

**AWS Health events** (`aws.health` service in EventBridge) notify about AWS service issues and scheduled maintenance affecting your account. Subscribe to `AWS_EC2_INSTANCE_STOP_SCHEDULED` and `AWS_EC2_INSTANCE_RETIREMENT_SCHEDULED` to automate graceful replacement of retiring instances before AWS terminates them.

**SQS vs SNS vs EventBridge — choose deliberately:**
- **SNS** — fan-out (one message to many subscribers), push-based, no replay.
- **SQS** — decouple and buffer, pull-based, message retention up to 14 days, DLQ for failures.
- **EventBridge** — content-based routing with rich filtering, cross-account, archive and replay, schema registry.

### Automated Remediation

**AWS Config + remediation actions** is the primary policy-enforcement loop: a Config Rule evaluates resource configuration → marks non-compliant → a remediation action (SSM Automation document) automatically corrects it. Config managed rules (`restricted-ssh`, `s3-bucket-public-read-prohibited`, `iam-root-access-key-check`, etc.) cover the most common compliance checks without custom code.

**SSM Automation for incident response:** Pre-author runbooks for common incidents (restart a service, rotate credentials, isolate an EC2 instance from the network, restore from backup). Trigger from EventBridge rules or manually from OpsCenter. Approval steps in Automation documents gate on human sign-off for destructive actions while keeping all other steps automated.

**OpsCenter** aggregates operational issues (OpsItems) from CloudWatch alarms, Config non-compliance, Security Hub findings, and AWS Health events into a single pane. Associate runbooks with OpsItem types so responders have a one-click remediation path.

### Failure Diagnosis Flow

1. **Identify scope** — CloudWatch alarms, AWS Health dashboard, service-specific consoles.
2. **Trace the request** — X-Ray service map + trace timeline for latency/error root cause.
3. **Inspect logs** — CloudWatch Logs Insights query across relevant log groups.
4. **Check for recent changes** — CloudTrail `LookupEvents` for API calls in the window before the incident; CodePipeline/CodeDeploy history for recent deployments.
5. **Check deployment health** — `aws codedeploy list-deployments` + `get-deployment` for failure reason; `aws ecs describe-services` for task placement failures; `aws lambda list-event-source-mappings` for trigger state.
6. **Remediate and verify** — apply fix, confirm via metric/alarm recovery, write post-mortem.

**Red flags in review:**
- Config Rules with remediation disabled — compliance violations pile up with no automated fix.
- No DLQ on SQS queues used for event-driven automation — failed events are silently dropped.
- SSM Automation runbook with no error handling (`onFailure: Abort` without notification) — failures are invisible.
- Manual-only incident response procedures — no EventBridge rule to trigger remediation.
- CloudTrail not enabled in all regions — gaps in the audit record used for root-cause analysis.

**Verify:** `aws config get-compliance-details-by-config-rule --config-rule-name <rule>` to see non-compliant resources; `aws ssm list-automation-executions` to confirm remediation ran; `aws cloudtrail lookup-events --lookup-attributes AttributeKey=ResourceName,AttributeValue=<resource>` to reconstruct the change timeline.

---

## 6. Security and Compliance (17%)

Security is automated or it is not done consistently. Every security control that requires a human to remember is a control that will eventually fail.

### IAM at Scale

**Least privilege means explicit allow, implicit deny.** Start with no permissions; grant only what is required for the specific task. IAM policy evaluation order: Organization SCPs → Resource-based policies → IAM identity policies → Permission boundaries → Session policies. All applicable policies must allow an action; any explicit Deny wins.

**Permission boundaries** cap the maximum permissions an IAM entity can have — useful for delegating IAM management to teams without allowing privilege escalation. A developer can create roles, but only roles whose permissions are a subset of the boundary you set.

**Service Control Policies (SCPs)** apply to every principal in an OU or account. They do not grant permissions; they restrict what IAM policies can grant. Common patterns: deny leaving the organization, deny disabling CloudTrail, require MFA for console actions, restrict which regions are usable.

**IAM roles for machine identities:** EC2 instance profiles, ECS task roles, Lambda execution roles — never store long-lived credentials in compute. Rotate Secrets Manager secrets on a schedule using built-in Lambda rotation functions; reference the secret ARN (not the value) in application configuration.

**IAM Identity Center (SSO)** for human access to multiple accounts: permission sets define what a user can do in an account; assignments attach users/groups to accounts + permission sets. Prefer Identity Center over per-account IAM users for any organization with more than a single account.

### Automated Compliance and Threat Detection

**AWS Config** records configuration changes to supported resources (configuration items). Use it for:
- Detecting drift from desired state (Config Rules).
- Auditing who changed what and when (configuration history).
- Delivering findings to Security Hub.
- Triggering remediation (managed or custom SSM Automation).

**Security Hub** aggregates findings from GuardDuty, Inspector, Macie, Config, IAM Access Analyzer, and third-party integrations into a single findings dashboard. Use AWS Foundational Security Best Practices (FSBP) or CIS Benchmarks as the standard. Route HIGH/CRITICAL findings to EventBridge → SNS → on-call system.

**GuardDuty** is threat detection, not configuration compliance — it analyzes VPC Flow Logs, DNS logs, CloudTrail, and S3 data events to detect active threats (credential exfiltration, cryptomining, unusual API calls from TOR exit nodes, etc.). Enable in every account via Organizations delegated-admin; never disable, even briefly.

**Amazon Macie** discovers sensitive data (PII, credentials) in S3 buckets using ML classifiers. Run a discovery job on new buckets before they are tagged as "compliant."

**CloudTrail:** must be enabled in all regions (multi-region trail) with log file validation and delivered to a central S3 bucket in a log archive account where the source accounts have no delete permissions. CloudTrail Lake provides SQL-based querying directly on event data without exporting to S3/Athena first.

### Encryption Discipline

- **KMS CMKs vs AWS managed keys:** use CMKs when you need to control key policy, rotate on a custom schedule, or share access cross-account. AWS managed keys are free but you cannot grant cross-account access or audit individual decrypt calls separately.
- **Envelope encryption pattern:** data encrypted with a data key; data key encrypted with a CMK. The data key never leaves KMS in plaintext.
- **Secrets Manager vs Parameter Store SecureString:** Secrets Manager adds automatic rotation, cross-account access, and resource-based policies; Parameter Store SecureString is simpler and free for Standard tier. Use Secrets Manager for anything that rotates (DB passwords, API keys); Parameter Store for static configuration values.

**Red flags in review:**
- IAM user with long-lived access keys used for application authentication (use roles).
- S3 bucket with public ACL or no bucket policy blocking public access.
- GuardDuty disabled in any account or region.
- CloudTrail without log file validation or without delivery to a cross-account archive bucket.
- KMS CMK with `"Principal": "*"` in the key policy (anyone can encrypt/decrypt).
- Secrets Manager secret with rotation disabled but referenced as "rotated" in a runbook.

**Verify:** `aws securityhub get-findings --filters '{"SeverityLabel":[{"Value":"CRITICAL","Comparison":"EQUALS"}]}'` to surface active high-severity findings; `aws guardduty list-detectors` to confirm GuardDuty is enabled in the current region; `aws cloudtrail get-trail-status --name <trail>` to confirm logging is active and `IsLogging` is `true`.

---

## Executable Workflows

### Workflow 1 — Ship a Blue/Green Deploy with Automated CloudWatch-Alarm Rollback

1. Create a CodeDeploy application (type `ECS` or `Lambda`) and deployment group with `BlueGreenDeploymentConfiguration` pointing to the ALB listener and target groups.
   → gate: `aws codedeploy get-deployment-group --application-name <app> --deployment-group-name <dg> --query 'deploymentGroupInfo.blueGreenDeploymentConfiguration'` confirms hook timeouts and termination settings.
2. Create (or update) a CloudWatch alarm on the error-rate or latency metric you want to guard (e.g., `HTTPCode_Target_5XX_Count > 10 for 1 datapoint`). Note the alarm ARN.
   → gate: `aws cloudwatch describe-alarms --alarm-names <alarm>` — confirm state is `OK` before deploying; deploying into an already-`ALARM` state causes immediate rollback.
3. Wire the alarm ARN into the CodeDeploy deployment group as a rollback alarm: `aws codedeploy update-deployment-group ... --alarm-configuration alarms=[{name=<alarm-name>}],enabled=true,ignorePollAlarmFailure=false`.
   → gate: re-check `get-deployment-group` to confirm `alarmConfiguration.enabled: true`.
4. Trigger the deployment (from CodePipeline or directly via `aws codedeploy create-deployment`). Monitor `aws codedeploy get-deployment --deployment-id <id>` — watch lifecycle events progress through `BeforeInstallHook` → `AfterInstallHook` → `AfterAllowTestTraffic` → `BeforeAllowTraffic` → `AfterAllowTraffic`.
   → gate: confirm new task set / Lambda version is receiving test traffic at the ALB test port before `AfterAllowTestTraffic` hook completes.
5. Once traffic shifts to 100%, verify the alarm remains in `OK` state for the configured evaluation period. If it fires, CodeDeploy automatically rolls traffic back to the previous version.
   → gate: `aws codedeploy get-deployment --deployment-id <id> --query 'deploymentInfo.status'` — `Succeeded` confirms completion; `Stopped` with `autoRollbackConfiguration` message confirms alarm-triggered rollback.
6. After successful cutover, confirm old (blue) instances or task sets are terminated per the `terminateBlueInstancesOnDeploymentSuccess` configuration — stale blue capacity is a cost leak.

---

### Workflow 2 — Stand Up a CodePipeline with Test/Approval Gates

1. Create an S3 artifact bucket (SSE-KMS if cross-account) and a pipeline service role with least-privilege: separate source-read, build, and deploy actions; no role gets all three.
   → gate: `aws s3api get-bucket-encryption --bucket <bucket>` confirms KMS encryption; `aws iam simulate-principal-policy` confirms the build role cannot invoke CodeDeploy.
2. Define the pipeline stages in order: **Source** (CodeConnections/CodeCommit/S3) → **Build** (CodeBuild) → **Test** (separate CodeBuild project targeting staging) → **ManualApproval** → **Deploy** (CodeDeploy/ECS/CFN).
   → gate: `aws codepipeline get-pipeline --name <pipeline>` returns all stages; confirm `actionTypeId.category: Approval` is present between Test and Deploy.
3. Configure the CodeBuild test stage buildspec to exit non-zero on test failure (any test framework's non-zero exit propagates as a pipeline failure, blocking the approval gate).
   → gate: run `aws codepipeline start-pipeline-execution --name <pipeline>`, then deliberately fail a test — confirm the pipeline stops at the Build/Test stage with `Failed` status and does not reach Approval.
4. Set up SNS notification for the ManualApproval action so approvers receive an email/Slack notification with the approval URL.
   → gate: `aws codepipeline get-pipeline-state --name <pipeline> --query 'stageStates[?stageName==`ManualApproval`]'` shows `InProgress` with the approval token when awaiting review.
5. Approve via console or CLI (`aws codepipeline put-approval-result`) and confirm the Deploy stage executes successfully.
   → gate: `aws codedeploy list-deployments --application-name <app> --query 'deployments[0]'` then `get-deployment` to confirm `Succeeded`.

---

### Workflow 3 — Wire Automated Remediation (Config Rule → EventBridge → SSM Automation)

1. Enable the desired AWS Config managed rule (e.g., `s3-bucket-public-read-prohibited`) in the account/region. Confirm the rule evaluates existing resources: `aws configservice get-compliance-details-by-config-rule --config-rule-name s3-bucket-public-read-prohibited`.
   → gate: at least one resource must appear as `COMPLIANT` or `NON_COMPLIANT`; `NO_RESULTS` means Config is not recording that resource type.
2. Author an SSM Automation document (or use the managed `AWS-DisableS3BucketPublicReadWrite`) that remediates the non-compliant state. Test it manually against a non-production bucket first.
   → gate: `aws ssm start-automation-execution --document-name <doc> --parameters BucketName=<test-bucket>` — confirm execution completes with `Success` and the bucket policy is updated.
3. Create an EventBridge rule matching `{"source": ["aws.config"], "detail-type": ["Config Rules Compliance Change"], "detail": {"configRuleName": ["s3-bucket-public-read-prohibited"], "newEvaluationResult": {"complianceType": ["NON_COMPLIANT"]}}}`, targeting the SSM Automation document as the target (via the SSM Automation EventBridge target type) with an IAM role that allows `ssm:StartAutomationExecution`.
   → gate: `aws events describe-rule --name <rule>` confirms the rule is `ENABLED`; `aws events list-targets-by-rule --rule <rule>` confirms the SSM Automation ARN is the target.
4. Trigger a non-compliance event (temporarily make a test bucket public) and confirm the EventBridge rule fires and the SSM Automation execution starts.
   → gate: `aws ssm list-automation-executions --filters Key=StartTimeBefore,Values=<now>` — most recent execution should reference the test bucket and show `InProgress` → `Success`.
5. Verify the Config rule now shows the resource as `COMPLIANT` within the next evaluation cycle (typically within a few minutes of the remediation completing).
   → gate: `aws configservice get-compliance-details-by-config-rule --config-rule-name s3-bucket-public-read-prohibited` — test bucket moves from `NON_COMPLIANT` to `COMPLIANT`.

---

## Decision Scenarios

**Scenario 1 — ECS blue/green stuck: traffic never cuts over**

> **Situation:** A team deploys an ECS service update via CodeDeploy using `ECSAllAtOnce` blue/green. The new task set registers with the target group and passes ALB health checks. CodeDeploy shows `IN_PROGRESS: AfterAllowTestTraffic` and stays there indefinitely. No CloudWatch alarm has fired. The on-call engineer re-deploys the same image thinking it is a transient glitch.

> **Competent move:** The `AfterAllowTestTraffic` lifecycle hook has invoked a Lambda validation function and is waiting for that function to call back `codedeploy:PutLifecycleEventHookExecutionStatus` with `status: Succeeded`. If the Lambda times out, errors, or never calls back, CodeDeploy waits until the deployment timeout (default 1 hour) before marking it failed. Check the Lambda function logs for the hook — it almost certainly errored silently. Fix the Lambda, and either wait for the deployment to time out and retry, or call `aws codedeploy put-lifecycle-event-hook-execution-status` manually with the execution ID from the deployment events to unblock it.

> **Tempting-but-wrong:** Re-deploying or rolling back without inspecting the hook Lambda logs. Re-deploying creates another deployment that will hit the same stuck hook. The underlying cause (Lambda error or missing callback) must be resolved first or the new deployment stalls identically.

> **Verify:** `aws codedeploy get-deployment --deployment-id <id> --query 'deploymentInfo.deploymentStatusMessages'` for the lifecycle event execution ID; then `aws lambda get-function --function-name <hook-fn>` and CloudWatch Logs for the function; `aws codedeploy list-deployment-targets --deployment-id <id>` to see per-target hook status.

Further scenarios (StackSet permission models, CDK bootstrap versioning, cross-account ECR pull, Config remediation throttling, EC2 Image Builder + ASG launch template): [references/scenarios.md](references/scenarios.md).

---

## Operational Rules Quick Reference

Each rule is concrete and imperative.

- **DO** express all infrastructure changes as IaC (CloudFormation, CDK, SAM) — manual console changes create drift and break reproducibility.
- **DON'T** apply CloudFormation updates to production without first creating and reviewing a change set — especially watch for `Replacement` actions.
- **DO** run drift detection on all CloudFormation stacks regularly; treat drift as a defect to remediate, not a state to accept.
- **DO** use least-privilege pipeline roles — separate CodeBuild role (no deploy permissions) from CodeDeploy role (no build permissions); use a separate cross-account role for multi-account pipelines with a CMK-encrypted artifact bucket.
- **DON'T** store secrets as plaintext environment variables in CodeBuild or pipeline configuration — reference Secrets Manager ARNs.
- **DO** configure a CloudWatch alarm as a rollback trigger for canary and linear Lambda/ECS deployments — without it, a bad deployment completes fully before anyone notices.
- **DO** use lifecycle hooks on Auto Scaling termination events to drain connections before instance termination.
- **DON'T** present RDS Multi-AZ as a cross-region DR solution — it protects against AZ failure only; use Aurora Global Database or read replica promotion for regional DR.
- **DO** set a retention policy on every CloudWatch log group — `Never expire` is a cost and compliance liability.
- **DO** enable GuardDuty in every account and every region via Organizations delegated-admin — never disable it, even temporarily.
- **DO** send all CloudTrail logs to a central archive account where source accounts have no delete permissions; enable log file validation.
- **DON'T** use IAM users with long-lived access keys for machine authentication — use instance profiles, task roles, and Lambda execution roles.
- **DO** run Config Rules with automated remediation (SSM Automation) — a Config rule with no remediation is a compliance dashboard that never fixes anything.
- **DO** route Security Hub HIGH/CRITICAL findings to EventBridge and on-call systems — findings sitting unacknowledged in the console are not acted on.
- **DO** verify CloudTrail `IsLogging: true` and GuardDuty detector status via API before declaring a new account "secure."

---

> **Study resources** — official exam guide, Skill Builder, whitepapers, and community guides are in [references/study-resources.md](references/study-resources.md).

---

## Feedback protocol

Using this skill and hit a wall? If you find a claim contradicted by the live system or official docs, a missing rule that cost you a wrong attempt, or a decision this skill gave no criteria for — append an entry **in the moment** to `.skill-feedback/aws-devops-engineer-professional.md` at the project root (create it if absent):

`date | skill last-reviewed | claim or gap | what you observed instead | evidence (error text / doc URL / query output) | suggested fix`

These are harvested back into the skill via the learning loop. When the live system and this file disagree, trust the live system.

---

## Changelog

- **2026-06-09** — Conformed to the 12-dimension skill standard: task-vocab description + Scope block, Uncertainty & Escalation guidance with inline `[volatile — verify live]` marks, executable workflows, tool-agnostic verify steps, and the feedback protocol above. Exam logistics relocated to references/study-resources.md; `last-reviewed` set to 2026-06-09.

---

_Independent educational content for upskilling AI agents. Not affiliated with, authorized by, endorsed by, or sponsored by Amazon Web Services. All product names, logos, and brands are the property of their respective owners and are used here for identification purposes only. Content is provided as-is, as guidance only; verify against official AWS documentation and live accounts. No certification outcome is implied or guaranteed._
