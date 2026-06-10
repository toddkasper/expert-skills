---
name: aws-devops-engineer-professional
description: AWS DevOps engineering — CI/CD pipelines (CodePipeline, CodeBuild, CodeDeploy), infrastructure as code (CloudFormation, CDK, Systems Manager), deployment strategies (blue/green, canary), resilient multi-AZ/multi-region design, CloudWatch monitoring and logging, event-driven incident response and automated remediation, and security/compliance automation. Use when building, reviewing, or debugging AWS delivery pipelines, IaC templates, observability stacks, or auto-remediation. Not security-first design (see aws-security-specialty) or enterprise architecture trade-offs (see aws-solutions-architect-professional). Scoped and benchmarked by the AWS DevOps Engineer – Professional (DOP-C02) blueprint.
metadata:
  anchor-credential: AWS Certified DevOps Engineer – Professional
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

Operational playbook for AWS DevOps work. Each section states the rule to apply: decision criteria for deployment strategy, failure modes to catch in review, and verify steps. **Query the AWS APIs — never assume from IaC source or console screenshots** (state diverges from templates the moment a manual change is made).

> **Load this skill when…** building or reviewing a CI/CD pipeline (CodePipeline, CodeBuild, CodeDeploy); authoring or debugging CloudFormation/CDK/SAM templates; designing deployment strategies (blue/green, canary, rolling); configuring observability stacks, automated remediation, or compliance-as-code on AWS.
> **Not this skill:** threat-detection, IAM policy depth, or encryption → see `aws-security-specialty`; enterprise architecture trade-offs → see `aws-solutions-architect-professional`.

> **Study resources and credential logistics:** [references/study-resources.md](references/study-resources.md).

> **Verify steps** — use your project's MCP/automation, the AWS CLI (`aws`) or CloudShell, or the Console, in that order.

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

**ECS blue/green with CodeDeploy** registers new tasks, waits for health checks, then shifts the ALB listener. Lifecycle hooks (`BeforeInstallHook`, `AfterInstallHook`, `AfterAllowTestTraffic`, `BeforeAllowTraffic`, `AfterAllowTraffic`) invoke Lambda; failures trigger automatic rollback.

**Lambda strategies** use aliases with weighted versions (`CodeDeployDefault.LambdaCanary10Percent5Minutes` = 10% for 5 min then 100%, or rollback on alarm).

**EC2 Image Builder** bakes golden AMIs; couple with ASG launch template updates to roll new images into the fleet.

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

**Custom Resources (Lambda-backed):** the Lambda must respond to CloudFormation's pre-signed S3 URL with `SUCCESS` or `FAILED` — no response leaves the stack in `UPDATE_IN_PROGRESS` forever. Set Lambda timeout < CloudFormation's 1-hour wait.

**CDK:** `cdk diff` = change set equivalent; run before every `cdk deploy` in production. `cdk bootstrap` is account/region-specific; re-run on major CDK version upgrades.

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

**Auto Scaling groups:** separate scale-out policy from scale-in protection (termination policies, instance protection, cooldown periods). Key failure mode: scale-in kills instances with active sessions — use connection draining (ALB deregistration delay) and lifecycle hooks (`autoscaling:EC2_INSTANCE_TERMINATING`) to drain first.

**Route 53 health checks:** Failover (active-passive) or Weighted routing (DNS blue/green). Health checks can monitor an endpoint, another check (calculated), or a CloudWatch alarm — alarm form ties DNS failover to application signals. Simple routing has no health check support.

### DR Strategy Selection

Match the DR pattern to the stated RTO/RPO: Backup & Restore (hours/hours, lowest cost) → Pilot Light (tens of minutes/minutes) → Warm Standby (minutes/near-zero) → Multi-site Active-Active (near-zero/near-zero, highest cost). Do not default to multi-region active/active when warm standby meets the requirement.

**AWS Backup** centralizes backup policies across RDS, DynamoDB, EFS, EC2 (EBS snapshots), FSx, and S3. Use Backup Plans with lifecycle rules. Cross-region copies require a Backup Vault in the destination region. Test restores — an untested backup is not a backup.

**Red flags in review:**
- RDS Multi-AZ presented as a DR solution for regional failures (it isn't).
- Auto Scaling group with no lifecycle hook on termination — active sessions killed mid-flight.
- Route 53 failover with no health check on the primary — failover never triggers.
- DR runbook that requires manual console steps — automate with SSM Automation documents.
- AWS Backup plan with no restore test in the last 90 days.

**Verify:** `aws route53 get-health-check-status --health-check-id <id>` to confirm health check state; `aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names <asg>` to inspect lifecycle hooks and termination policies.

---

## 4. Monitoring and Logging (15%)

### Metrics and Alarms

**CloudWatch metric hierarchy:** Namespace → Metric Name → Dimensions → Statistics → Period. Custom metrics require `PutMetricData`. High-resolution metrics (1-second) cost more but enable sub-minute alarming.

**Alarm states:** `OK`, `ALARM`, `INSUFFICIENT_DATA`. `INSUFFICIENT_DATA` ≠ OK — metric has no data points; suppress with `treat_missing_data: notBreaching` only when genuinely correct.

**Composite alarms** combine alarms with Boolean logic — alert only when BOTH high CPU AND high latency are ALARM (reduces noise).

**Anomaly detection** trains on historical data and alarms outside the expected band — useful for time-of-day patterns.

### Log Management

**CloudWatch Logs:** log group → log stream → log event. Retention defaults to `Never expire` — set a retention policy on every log group. Export to S3; subscribe to Kinesis Data Firehose for near-real-time delivery to S3/OpenSearch/Splunk.

**Metric filters** publish log-derived values as custom metrics — primary way to alarm on application errors without code changes. Logs Insights for ad-hoc queries; Athena for recurring analysis.

> Centralized logging patterns (cross-account subscription filters, CloudWatch cross-account observability) and X-Ray distributed tracing setup: [references/observability-patterns.md](references/observability-patterns.md).

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

Explicit Deny wins at any layer (SCPs → resource-based → identity → boundary → session).

- **Permission boundaries** cap without granting — effective permission = intersection of identity policy and boundary.
- **SCPs** restrict every principal in an OU/account; do not grant. Patterns: deny disabling CloudTrail, deny leaving the org, restrict regions.
- **Machine identities:** EC2 instance profiles, ECS task roles, Lambda execution roles — never long-lived credentials; reference Secrets Manager ARNs in config.
- **IAM Identity Center (SSO):** prefer over per-account IAM users for multi-account orgs.

### Automated Compliance and Threat Detection

- **Config:** records changes; evaluates rules; triggers SSM Automation remediation. Use FSBP or CIS standards via Security Hub.
- **Security Hub:** aggregates GuardDuty, Inspector, Macie, Config, Access Analyzer. Route HIGH/CRITICAL to EventBridge → SNS → on-call.
- **GuardDuty:** threat detection — enable org-wide via delegated admin; never disable.
- **Macie:** PII/credential discovery in S3. Run a discovery job on new buckets before marking compliant.
- **CloudTrail:** multi-region trail, log file validation, cross-account log archive (source accounts: no delete permissions). CloudTrail Lake for SQL querying.

### Encryption Discipline

- **KMS CMKs** for key policy control, custom rotation, or cross-account access; AWS managed keys for lower overhead.
- **Secrets Manager** for rotating credentials; **Parameter Store SecureString** for static config.

**Red flags:** long-lived IAM access keys for application auth; S3 public ACL or no Block Public Access; GuardDuty disabled; CloudTrail without log file validation or cross-account archive; KMS CMK with `"Principal": "*"`; Secrets Manager rotation disabled.

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

---

**Scenario 2 — StackSet SERVICE_MANAGED vs SELF_MANAGED for a new OU**

> **Situation:** A platform team needs to deploy a CloudFormation StackSet to every account in the `Production` OU (12 accounts today, growing). They have Organizations enabled and the management account is the CloudFormation delegated admin. A junior engineer sets `--permission-model SELF_MANAGED` and creates `AWSCloudFormationStackSetAdministrationRole` in the management account plus `AWSCloudFormationStackSetExecutionRole` in each of the 12 target accounts manually. The StackSet deploys successfully to all 12. Three months later a new account joins the OU and the stack instance is never created there.

> **Competent move:** Switch to `--permission-model SERVICE_MANAGED` with `--auto-deployment Enabled=true,RetainStacksOnAccountRemoval=false`. With SERVICE_MANAGED, CloudFormation uses the Organizations service-linked role and automatically creates stack instances in accounts as they join the target OU — no per-account role setup required. The manual role approach works for SELF_MANAGED only when you explicitly add each target account ID; it does not respond to OU membership changes.

> **Tempting-but-wrong:** Keeping SELF_MANAGED and writing a Lambda or EventBridge rule to detect `CreateAccount` events and call `create-stack-instances`. This is operational toil that SERVICE_MANAGED eliminates natively, and it is error-prone (the Lambda needs its own IAM permissions and error handling, and if the event is missed the account stays uncovered).

> **Verify:** `aws cloudformation describe-stack-set --stack-set-name <name> --query 'StackSet.PermissionModel'` confirms the model; `aws cloudformation list-stack-instances --stack-set-name <name>` shows whether the new account has an instance; `aws cloudformation describe-stack-set --query 'StackSet.AutoDeployment'` confirms auto-deployment is enabled.

---

**Scenario 3 — CDK bootstrap version mismatch on upgrade**

> **Situation:** A team upgrades their CDK CLI from v2.80 to v2.150 across all developer laptops and the CI/CD pipeline. The first `cdk deploy` after the upgrade fails in production with `This CDK CLI is not compatible with the CDK library used by your application`. A senior engineer says the fix is to run `cdk bootstrap` again in the target account and region.

> **Competent move:** Run `cdk bootstrap aws://<account-id>/<region>` in every target account and region. CDK bootstrap creates the `CDKToolkit` CloudFormation stack that contains the S3 staging bucket, ECR repository, and IAM execution roles the CDK needs at deploy time. The bootstrap stack has a `BootstrapVersion` number; major CDK upgrades require a higher bootstrap version. Because bootstrap is account/region-scoped, every account–region pair must be re-bootstrapped. After bootstrapping, verify the `CDKToolkit` stack version matches the CLI requirement.

> **Tempting-but-wrong:** Pinning the CDK CLI back to the previous version to avoid the error. This avoids the symptom but blocks all new CDK features and security fixes, and eventually the mismatch will recur. The correct resolution is always to re-bootstrap so the CDKToolkit stack version satisfies the CLI.

> **Verify:** `aws cloudformation describe-stacks --stack-name CDKToolkit --query 'Stacks[0].Parameters[?ParameterKey==\`BootstrapVersion\`].ParameterValue'` — the value must be ≥ the version required by the CDK CLI version in use (check `cdk --version` and the CDK changelog for the minimum bootstrap version).

---

**Scenario 4 — CodeBuild cross-account ECR pull fails with "no basic auth credentials"**

> **Situation:** A CodeBuild project in the `tools` account builds a Docker image and pushes it to an ECR repository in the same `tools` account — this works. A second CodeBuild project in the `app` account needs to pull that same base image from the `tools` account ECR repository at build time. The `app` account CodeBuild service role has `ecr:GetAuthorizationToken`, `ecr:BatchGetImage`, and `ecr:GetDownloadUrlForLayer` on the `tools` account ECR ARN. The build still fails with "no basic auth credentials" or "access denied."

> **Competent move:** Add a resource-based policy to the ECR repository in the `tools` account that allows the `app` account's CodeBuild service role (or the entire `app` account) to call `ecr:GetDownloadUrlForLayer`, `ecr:BatchGetImage`, and `ecr:BatchCheckLayerAvailability`. ECR is a cross-account resource, and like S3, cross-account access requires both an identity policy in the calling account AND a resource policy on the ECR repository in the owning account. Note that `ecr:GetAuthorizationToken` is not resource-specific — it must be allowed against `*` in the identity policy, and it is account-level, not cross-account; the registry login step must target the `tools` account registry URL explicitly (`aws ecr get-login-password --region … | docker login --username AWS --password-stdin <tools-account-id>.dkr.ecr.<region>.amazonaws.com`).

> **Tempting-but-wrong:** Adding `ecr:*` to the `app` account CodeBuild service role and assuming that is sufficient. Without the resource-based policy on the `tools` account ECR repository, the cross-account grant is incomplete — same-account ECR grants work with identity policy alone, but cross-account requires both sides.

> **Verify:** `aws ecr get-repository-policy --repository-name <name> --region <region>` (run in the `tools` account) confirms the resource policy includes the `app` account principal; attempt `aws ecr get-login-password | docker login` from a test role in the `app` account targeting the `tools` account registry URL.

Further scenarios (Config remediation throttling, EC2 Image Builder + ASG launch template): [references/scenarios.md](references/scenarios.md).

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
- **2026-06-09** — Curation pass (inbox: D9 audit finding): inlined 3 decision scenarios into the body (Scenarios 2–4: StackSet permission models, CDK bootstrap versioning, cross-account ECR pull) to meet the teaching-scenario standard (body now has 4 scenarios total).

---

_Independent educational content for upskilling AI agents. Not affiliated with, authorized by, endorsed by, or sponsored by Amazon Web Services. All product names, logos, and brands are the property of their respective owners and are used here for identification purposes only. Content is provided as-is, as guidance only; verify against official AWS documentation and live accounts. No certification outcome is implied or guaranteed._
