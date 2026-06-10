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

**This file is an operational playbook, not an exam outline.** Each section states the actual rules an agent must apply when doing DevOps work on AWS — decision criteria for deployment strategy, failure modes to catch in review, and verify-against-the-live-account steps. Recurring principle: **query the AWS APIs — never assume from IaC source or console screenshots** (state diverges from templates the moment a manual change is made). Benchmarked against the AWS DevOps Engineer – Professional (DOP-C02) blueprint.

> **Load this skill when…** building or reviewing a CI/CD pipeline (CodePipeline, CodeBuild, CodeDeploy); authoring or debugging CloudFormation/CDK/SAM templates; designing deployment strategies (blue/green, canary, rolling); configuring observability stacks, automated remediation, or compliance-as-code on AWS.
> **Not this skill:** threat-detection, IAM policy depth, or encryption → see `aws-security-specialty`; enterprise architecture trade-offs or multi-account design → see `aws-solutions-architect-professional`.

> **Study resources and credential logistics:** [references/study-resources.md](references/study-resources.md).

> **Verify steps assume nothing about your tooling** — use your project's MCP/automation, the AWS CLI (`aws`) or CloudShell, or the AWS Console, in that order of preference.

---

## Uncertainty & Escalation

- **Always re-verify live — volatile facts:** service quotas (e.g., default CodePipeline pipelines per region `[volatile — verify live]`, CodeBuild concurrent builds per account `[volatile — verify live]`), EC2 instance type availability by region `[volatile — verify live]`, CloudWatch high-resolution metric pricing `[volatile — verify live]`, CodeDeploy deployment config names and timeout defaults `[volatile — verify live]`, and any feature announced after the `last-reviewed` date in this file's frontmatter.
- **Live wins:** when the live AWS account, CLI output, or official AWS docs contradict a claim in this file, the live source is authoritative. Log the discrepancy via the Feedback protocol below so the skill can be corrected.
- **Escalate to a human — do not silently execute:** deleting CloudFormation stacks or stack sets; IAM role/SCP/permission-boundary changes; KMS key policy modifications; enabling or disabling GuardDuty or CloudTrail; any action that incurs significant cost (large Snowball order, Reserved Instance purchase, EC2 fleet scaling); opening security-group or network-boundary rules; force-merging or runner policy changes in enterprise settings.
- **Confidence taxonomy:** every fact in this file is considered *stable* unless tagged `[volatile — verify live]` (changes with AWS service updates) or `[opinion — house style]` (a defensible default, not the only valid choice).

---

## 1. SDLC Automation (22%)

### Pipeline Architecture

**Core stack:** CodeCommit/CodeConnections (source) → CodeBuild (build/test) → CodeDeploy or ECS/EKS deploy action → CodePipeline (orchestrator). CodeArtifact for private artifact repositories (npm, Maven, PyPI).

**Role boundaries:** build role has no deploy permissions; deploy role has no build permissions. Cross-account pipelines require a KMS CMK (not SSE-S3) on the artifact bucket, plus trust policies in both accounts.

**Secrets in builds:** reference Secrets Manager ARNs or Parameter Store SecureString paths in the CodeBuild environment block — never plaintext in buildspec.yml or environment variables. Rotation does not require pipeline changes.

### Deployment Strategies — Pick by Risk and Target

| Strategy | What it does | Best for | Rollback |
|---|---|---|---|
| **In-place (rolling)** | Replace instances one batch at a time | EC2 fleets when immutability isn't required | Re-deploy prior revision; slow |
| **Blue/green** | Traffic cut from old (blue) to new (green) environment | EC2 + ALB, ECS, Lambda aliases; near-zero-downtime required | Shift traffic back to blue instantly |
| **Canary** | Route small % to new version first, then all | Lambda, ECS with CodeDeploy; risk-averse rollouts | Automatic rollback on CloudWatch alarm |
| **Linear** | Incrementally shift traffic in equal steps | Lambda, ECS when you want gradual exposure | Automatic rollback on alarm |
| **All-at-once** | Replace all instances simultaneously | Dev/test environments; fastest but riskiest | Re-deploy; no gradual fallback |

**ECS blue/green with CodeDeploy** registers new tasks, waits for health checks, then shifts the ALB listener rule. Lifecycle hooks (`BeforeInstallHook`, `AfterInstallHook`, `AfterAllowTestTraffic`, `BeforeAllowTraffic`, `AfterAllowTraffic`) invoke Lambda functions; failures trigger automatic rollback.

**Lambda strategies** use aliases pointing to weighted versions (e.g., `CodeDeployDefault.LambdaCanary10Percent5Minutes` = 10% for 5 min then 100%, or rollback if the alarm fires).

**EC2 Image Builder** bakes golden AMIs (recipe = base OS + components); couple with ASG launch template updates to roll new images into the fleet.

### Automated Testing Gates

CodeBuild buildspec phases: `pre_build` (setup), `build` (unit tests/SAST), `post_build` (packaging). Non-zero exit from any phase fails the build and blocks the pipeline. Use a separate CodePipeline Test stage + CodeBuild project for integration/acceptance tests against a deployed staging environment.

**Red flags in review:**
- Plaintext secrets in buildspec or pipeline environment variables.
- A single pipeline role with both build and deploy permissions.
- Blue/green deployment on EC2 with no termination hook — old instances linger and cost money.
- No automated rollback trigger (CloudWatch alarm) on a canary or linear Lambda deployment.
- SSE-S3 on the artifact bucket in a cross-account pipeline (CMK required).

**Verify:** `aws codepipeline get-pipeline-state --name <pipeline>` to see current stage/action status; `aws codedeploy list-deployments --application-name <app>` to inspect deployment history and failure reason.

---

## 2. Configuration Management and Infrastructure as Code (17%)

### CloudFormation Fundamentals

**Stack lifecycle:** Create → Update → Delete. Never modify CloudFormation-owned resources outside of CloudFormation — drift causes the next update to fail. Run `aws cloudformation detect-stack-drift` regularly; treat non-zero drift as a defect.

**Update behaviors:** `No interruption` (safe) | `Some interruption` (brief stop) | `Replacement` (new resource, old deleted). Preview with `aws cloudformation create-change-set` before any production update — watch for `Replacement` actions.

**StackSets:** `SELF_MANAGED` = manual trust setup per account; `SERVICE_MANAGED` = Organizations-integrated, auto-deploys to OUs and new accounts.

**Nested stacks:** root stack owns the lifecycle. Anti-pattern: deep nesting that makes change sets unreadable — prefer flat stacks with SSM Parameter Store exports.

**Custom Resources (Lambda-backed):** the Lambda must always respond to CloudFormation's pre-signed S3 URL with `SUCCESS` or `FAILED` — no response leaves the stack in `UPDATE_IN_PROGRESS` forever. Set Lambda timeout < CloudFormation's 1-hour wait.

**CDK:** `cdk diff` = change set equivalent; run before every `cdk deploy` in production. `cdk bootstrap` is account/region-specific; re-run on CDK major version upgrades.

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

### Event-Driven Architecture

**EventBridge:** rules match JSON path filters on the event envelope and route to targets (Lambda, SQS, SNS, Step Functions, CodePipeline, SSM Automation). Buses: default (AWS service events), custom (app events), partner (SaaS). Cross-account delivery requires a resource-based policy on the target bus.

**AWS Health events** (`aws.health`): subscribe to `AWS_EC2_INSTANCE_STOP_SCHEDULED` and `AWS_EC2_INSTANCE_RETIREMENT_SCHEDULED` to automate graceful replacement before AWS terminates instances.

**SQS vs SNS vs EventBridge:**
- **SNS** — fan-out, push-based, no replay.
- **SQS** — buffer/decouple, pull-based, 14-day retention, DLQ for failures.
- **EventBridge** — content-based routing, archive + replay, schema registry, cross-account.

### Automated Remediation

**Config rule → remediation loop:** Config Rule evaluates → marks non-compliant → SSM Automation document corrects. Managed rules (`restricted-ssh`, `s3-bucket-public-read-prohibited`, `iam-root-access-key-check`) cover common checks without custom code.

**SSM Automation runbooks:** pre-author for common incidents (restart, credential rotation, EC2 isolation, restore from backup). Trigger from EventBridge or manually from OpsCenter. Add Approval steps to gate destructive actions on human sign-off.

**OpsCenter:** aggregates OpsItems from CloudWatch alarms, Config, Security Hub, and Health events. Associate runbooks with OpsItem types for one-click remediation.

### Failure Diagnosis Flow

1. Identify scope — CloudWatch alarms, Health dashboard.
2. Trace — X-Ray service map + trace timeline.
3. Logs — Logs Insights across relevant log groups.
4. Recent changes — CloudTrail `LookupEvents`; CodePipeline/CodeDeploy history.
5. Deployment health — `aws codedeploy get-deployment`; `aws ecs describe-services`; `aws lambda list-event-source-mappings`.
6. Remediate and verify — confirm metric/alarm recovery; write post-mortem.

**Red flags in review:**
- Config Rules with remediation disabled — compliance violations pile up with no automated fix.
- No DLQ on SQS queues used for event-driven automation — failed events are silently dropped.
- SSM Automation runbook with no error handling (`onFailure: Abort` without notification) — failures are invisible.
- Manual-only incident response procedures — no EventBridge rule to trigger remediation.
- CloudTrail not enabled in all regions — gaps in the audit record used for root-cause analysis.

**Verify:** `aws config get-compliance-details-by-config-rule --config-rule-name <rule>` to see non-compliant resources; `aws ssm list-automation-executions` to confirm remediation ran; `aws cloudtrail lookup-events --lookup-attributes AttributeKey=ResourceName,AttributeValue=<resource>` to reconstruct the change timeline.

---

## 6. Security and Compliance (17%)

### IAM at Scale

Policy evaluation order: SCPs → Resource-based policies → Identity policies → Permission boundaries → Session policies. Explicit Deny at any layer wins.

- **Permission boundaries** cap maximum permissions without granting anything — the effective permission is the intersection of identity policy and boundary.
- **SCPs** restrict every principal in an OU/account; do not grant. Common patterns: deny disabling CloudTrail, deny leaving the org, restrict regions.
- **Machine identities:** EC2 instance profiles, ECS task roles, Lambda execution roles — never long-lived credentials. Reference Secrets Manager ARNs (not values) in config.
- **IAM Identity Center (SSO):** prefer over per-account IAM users for any multi-account org.

### Automated Compliance and Threat Detection

- **Config:** records configuration changes; evaluates Config Rules; audits change history; triggers SSM Automation remediation. Use FSBP or CIS standards via Security Hub.
- **Security Hub:** aggregates GuardDuty, Inspector, Macie, Config, Access Analyzer findings. Route HIGH/CRITICAL to EventBridge → SNS → on-call.
- **GuardDuty:** threat detection (not compliance) — VPC Flow Logs, DNS, CloudTrail, S3 data events. Enable org-wide via delegated admin; never disable.
- **Macie:** PII/credential discovery in S3 via ML. Run a discovery job on new buckets before marking them compliant.
- **CloudTrail:** multi-region trail, log file validation, delivered to a cross-account log archive bucket (source accounts: no delete permissions). CloudTrail Lake for SQL querying without S3/Athena export.

### Encryption Discipline

- **KMS CMKs** when you need key policy control, custom rotation schedule, or cross-account access. AWS managed keys when overhead doesn't matter.
- Envelope encryption: data key encrypts payload; CMK encrypts data key; plaintext data key never persisted.
- **Secrets Manager** for rotating credentials; **Parameter Store SecureString** for static config values.

**Red flags:** IAM user long-lived access keys for application auth; S3 public ACL or no Block Public Access; GuardDuty disabled; CloudTrail without log file validation or cross-account archive; KMS CMK with `"Principal": "*"`; Secrets Manager rotation disabled.

**Verify:** `aws securityhub get-findings --filters '{"SeverityLabel":[{"Value":"CRITICAL","Comparison":"EQUALS"}]}'`; `aws guardduty list-detectors`; `aws cloudtrail get-trail-status --name <trail>` confirms `IsLogging: true`.

---

## Executable Workflows

### Workflow 1 — Ship a Blue/Green Deploy with Automated CloudWatch-Alarm Rollback

1. Create a CodeDeploy application (`ECS` or `Lambda`) and deployment group with `BlueGreenDeploymentConfiguration` pointing to the ALB listener and target groups.
   → gate: `aws codedeploy get-deployment-group --application-name <app> --deployment-group-name <dg> --query 'deploymentGroupInfo.blueGreenDeploymentConfiguration'` confirms hook timeouts and termination settings.
2. Create or update a CloudWatch alarm on the error-rate or latency metric (e.g., `HTTPCode_Target_5XX_Count > 10 for 1 datapoint`).
   → gate: `aws cloudwatch describe-alarms --alarm-names <alarm>` — state must be `OK` before deploying; deploying into `ALARM` state causes immediate rollback.
3. Wire the alarm ARN into the deployment group: `aws codedeploy update-deployment-group ... --alarm-configuration alarms=[{name=<alarm-name>}],enabled=true,ignorePollAlarmFailure=false`.
   → gate: `get-deployment-group` confirms `alarmConfiguration.enabled: true`.
4. Trigger the deployment. Monitor lifecycle events: `BeforeInstallHook` → `AfterInstallHook` → `AfterAllowTestTraffic` → `BeforeAllowTraffic` → `AfterAllowTraffic`.
   → gate: new task set / Lambda version is receiving test traffic at the ALB test port before `AfterAllowTestTraffic` hook completes.
5. After traffic shifts to 100%, the alarm must stay `OK` through the evaluation period.
   → gate: `aws codedeploy get-deployment --deployment-id <id> --query 'deploymentInfo.status'` — `Succeeded` = done; `Stopped` with `autoRollbackConfiguration` = alarm-triggered rollback.
6. Confirm old (blue) instances/task sets are terminated per `terminateBlueInstancesOnDeploymentSuccess` — stale blue capacity is a cost leak.

---

### Workflow 2 — Stand Up a CodePipeline with Test/Approval Gates

1. Create an S3 artifact bucket (SSE-KMS for cross-account) and a pipeline service role with separate source-read, build, and deploy permissions (no role gets all three).
   → gate: `aws s3api get-bucket-encryption --bucket <bucket>` confirms KMS; `aws iam simulate-principal-policy` confirms build role cannot invoke CodeDeploy.
2. Define stages: Source → Build → Test (separate CodeBuild targeting staging) → ManualApproval → Deploy.
   → gate: `aws codepipeline get-pipeline --name <pipeline>` shows all stages; `actionTypeId.category: Approval` appears between Test and Deploy.
3. Configure the Test stage buildspec to exit non-zero on failure.
   → gate: deliberately fail a test; pipeline stops at Test with `Failed` status and does not reach Approval.
4. Configure SNS notification on ManualApproval so approvers receive the approval URL.
   → gate: `aws codepipeline get-pipeline-state` shows `InProgress` with approval token when awaiting review.
5. Approve (`aws codepipeline put-approval-result`) and confirm Deploy executes.
   → gate: `aws codedeploy get-deployment` for the triggered deployment shows `Succeeded`.

---

### Workflow 3 — Wire Automated Remediation (Config Rule → EventBridge → SSM Automation)

1. Enable the Config managed rule (e.g., `s3-bucket-public-read-prohibited`).
   → gate: `aws configservice get-compliance-details-by-config-rule` shows `COMPLIANT` or `NON_COMPLIANT` resources; `NO_RESULTS` means Config is not recording that resource type.
2. Test the SSM Automation document (or managed `AWS-DisableS3BucketPublicReadWrite`) against a non-production bucket first.
   → gate: `aws ssm start-automation-execution --document-name <doc> --parameters BucketName=<test-bucket>` completes with `Success` and the bucket policy is updated.
3. Create an EventBridge rule matching `{"source":["aws.config"],"detail-type":["Config Rules Compliance Change"],"detail":{"configRuleName":["s3-bucket-public-read-prohibited"],"newEvaluationResult":{"complianceType":["NON_COMPLIANT"]}}}` targeting the SSM Automation ARN, with an IAM role allowing `ssm:StartAutomationExecution`.
   → gate: `aws events describe-rule` shows `ENABLED`; `aws events list-targets-by-rule` confirms the SSM Automation ARN.
4. Trigger non-compliance (make a test bucket public); confirm EventBridge fires and SSM Automation starts.
   → gate: `aws ssm list-automation-executions` — latest execution references the test bucket and shows `InProgress` → `Success`.
5. Confirm the Config rule marks the bucket `COMPLIANT` within the next evaluation cycle.
   → gate: `aws configservice get-compliance-details-by-config-rule` shows test bucket as `COMPLIANT`.

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
