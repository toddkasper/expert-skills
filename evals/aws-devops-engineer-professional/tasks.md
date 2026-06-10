# Application tasks — aws-devops-engineer-professional (Lens 4, held-out)

A skilled agent produces the artifact; a judge grades against the trap-keyed rubric. Run baseline vs skilled.

---

## Task 1 — CodePipeline cross-account deployment redline

**Prompt to the agent:** Review the following CodePipeline + IAM configuration for a cross-account blue/green deployment to production and redline every flaw. Produce an annotated version that names each problem, explains the risk, and states the fix.

```yaml
# pipeline-role-policy.json  (tools account — attached to CodePipeline service role)
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}

# buildspec.yml  (CodeBuild project in tools account)
version: 0.2
env:
  variables:
    DB_PASSWORD: "prod-db-secret-abc123"
phases:
  build:
    commands:
      - npm ci
      - npm run build
  post_build:
    commands:
      - aws deploy create-deployment \
          --application-name MyApp \
          --deployment-group-name ProdGroup \
          --s3-location bucket=artifacts-bucket,key=build.zip,bundleType=zip

# codedeploy-appspec.yml
version: 0.0
os: linux
files:
  - source: /
    destination: /var/www/html
hooks:
  ApplicationStart:
    - location: scripts/start_server.sh
      timeout: 300

# pipeline stage — manual approval (absent: no approval stage defined between staging and prod)

# codedeploy-deployment-group (prod) — relevant excerpts
DeploymentConfigName: CodeDeployDefault.AllAtOnce
AutoRollbackConfiguration:
  Enabled: false
AlarmConfiguration:
  Enabled: false
  Alarms: []
```

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — Wildcard IAM action (`"Action": "*"`, `"Resource": "*"`) on the CodePipeline service role grants full AWS access; must be scoped to the minimum required actions and specific resource ARNs.
- [ ] Trap 2 — Plaintext secret in buildspec `env.variables` (`DB_PASSWORD`); secrets must be retrieved from Secrets Manager or SSM Parameter Store (SecureString) at runtime using `parameter-store` or `secrets-manager` blocks in the buildspec env section.
- [ ] Trap 3 — No manual-approval stage between staging and production; a human gate must exist so that only a reviewed artifact promotes to prod.
- [ ] Trap 4 — `AutoRollbackConfiguration.Enabled: false` and no alarm-based rollback configured; a failed deployment will leave production in a broken state instead of automatically reverting to the previous revision.
- [ ] Trap 5 — `DeploymentConfigName: CodeDeployDefault.AllAtOnce` for production; this brings all instances out of service simultaneously — use `CodeDeployDefault.HalfAtATime` or a canary/linear config to preserve availability.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Scopes the pipeline role to the specific CodePipeline, CodeBuild, CodeDeploy, S3, and cross-account assume-role actions needed, with resource-level ARNs.
- Replaces the `env.variables` DB_PASSWORD block with a `parameter-store` or `secrets-manager` reference so the secret is never in plaintext in the buildspec.
- Inserts an `Approval` stage with an SNS topic notification between the staging and production deploy stages.
- Sets `AutoRollbackConfiguration.Enabled: true` with `DEPLOYMENT_FAILURE` and `DEPLOYMENT_STOP_ON_ALARM` events.
- Adds an `AlarmConfiguration` pointing at a CloudWatch alarm (e.g., 5xx error rate or unhealthy host count) to trigger rollback automatically.
- Changes the deployment config to `CodeDeployDefault.HalfAtATime` (or a canary config) to preserve capacity during rollout.

---

## Task 2 — CloudFormation drift + auto-remediation pipeline redline

**Prompt to the agent:** Review this CloudFormation drift-detection and auto-remediation setup. Redline every flaw — name each problem, explain the risk, and state the fix.

```yaml
# drift-detection-rule.json  (AWS Config rule — CloudFormation stack drift)
{
  "ConfigRuleName": "cfn-stack-drift-detection",
  "Source": {
    "Owner": "AWS",
    "SourceIdentifier": "CLOUDFORMATION_STACK_DRIFT_DETECTION_CHECK"
  },
  "Scope": {
    "ComplianceResourceTypes": ["AWS::CloudFormation::Stack"]
  }
}

# auto-remediation-ssm-document: AWS-DeleteCloudFormationStack
# (attached to Config rule above with Auto Remediation = Yes, no throttle, no approval)

# eventbridge-rule.json  (triggers on ALL Config compliance state changes)
{
  "EventPattern": {
    "source": ["aws.config"],
    "detail-type": ["Config Rules Compliance Change"],
    "detail": {
      "configRuleName": ["cfn-stack-drift-detection"]
    }
  },
  "Targets": [
    {
      "Id": "RemediateDrift",
      "Arn": "arn:aws:lambda:us-east-1:123456789012:function:DeleteDriftedStack"
    }
  ]
}

# StackSet targeting the entire AWS Organization root — permission model: SELF_MANAGED
# Only the AWSCloudFormationStackSetExecutionRole has been created in the management account.
# No execution role created in member accounts.

# CloudTrail: single-region trail in us-east-1 only (management events)
```

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — Auto-remediation action is `AWS-DeleteCloudFormationStack` with no concurrency throttle (`MaximumAutomaticAttempts`/`RetryAttemptSeconds`) and no approval gate; a false-positive or misclassified stack triggers a destructive deletion with zero human oversight.
- [ ] Trap 2 — EventBridge rule fires on ALL compliance changes (including `COMPLIANT` transitions), not filtered to `NON_COMPLIANT`; this means any re-evaluation that flips back to compliant also invokes the Lambda, causing spurious executions.
- [ ] Trap 3 — SELF_MANAGED StackSet requires `AWSCloudFormationStackSetExecutionRole` in **every target account**, not just the management account; member accounts are missing the role so stack instance deployments fail.
- [ ] Trap 4 — Single-region CloudTrail trail captures management events in us-east-1 only; drift events and API calls in other regions are invisible to incident investigation — a multi-region (or organization) trail is required.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Replaces the auto-remediation document with a safer action (e.g., `AWS-PublishSNSNotification`) or adds an SSM Automation approval step before any destructive action, plus `MaximumAutomaticAttempts: 1` and a throttle window.
- Filters the EventBridge pattern to `"detail": {"newEvaluationResult": {"complianceType": ["NON_COMPLIANT"]}}` so only newly non-compliant stacks trigger remediation.
- Documents that SELF_MANAGED StackSets require the execution role deployed to every target account (or recommends switching to SERVICE_MANAGED with the org integration).
- Upgrades CloudTrail to a multi-region organization trail so all accounts and regions are covered.
- Notes that Config drift detection is triggered on a schedule and is not real-time; remediation latency expectations should be set accordingly.
