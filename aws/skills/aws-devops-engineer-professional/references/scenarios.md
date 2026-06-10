# Decision Scenarios — AWS DevOps Engineer Professional

Five additional judgment scenarios. The inline scenario in SKILL.md covers ECS blue/green deployment lifecycle hooks; these cover complementary high-lift judgment areas.

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

---

**Scenario 5 — Config remediation throttled; 6-hour non-compliance window**

> **Situation:** A Config Rule `s3-bucket-server-side-encryption-enabled` marks 40 buckets non-compliant after a bulk infrastructure import. Auto-remediation is enabled and targets an SSM Automation document that calls `PutBucketEncryption`. Six hours later, 28 buckets are remediated but 12 remain non-compliant. The SSM Automation execution history shows only 28 entries. No error is visible.

> **Competent move:** Check the SSM Automation `MaxConcurrentCount` and `MaxErrorCount` settings on the Config remediation configuration. By default, Config auto-remediation applies concurrency limits — if `MaxConcurrentPercentage` is set low (e.g., 10%), only a fraction of non-compliant resources are remediated per remediation execution. The remaining 12 are waiting for the next evaluation cycle or a manual re-trigger. Re-run the remediation manually via the Config console or `aws configservice start-remediation-execution --config-rule-name <rule> --resource-keys <keys>` for the remaining resources, and increase `MaxConcurrentPercentage` for future runs.

> **Tempting-but-wrong:** Assuming the Lambda backing the Config Rule has a timeout and disabling/re-enabling the rule. Config auto-remediation throttling is a separate concern from Lambda execution errors — disabling/re-enabling the rule triggers a re-evaluation but does not guarantee that previously non-compliant resources (already evaluated) are re-queued for remediation without a manual trigger or a configuration change event.

> **Verify:** `aws configservice describe-remediation-configurations --config-rule-names <rule>` — inspect `MaxConcurrentCount`/`MaxConcurrentPercentage` and `MaxErrorCount`/`MaxErrorPercentage`; `aws ssm list-automation-executions --filters Key=DocumentName,Values=<document>` to count executions and check status.

---

**Scenario 6 — EC2 Image Builder pipeline produces AMI but ASG keeps launching old image**

> **Situation:** EC2 Image Builder runs on a weekly schedule and successfully produces a new golden AMI tagged `golden-ami-latest`. The Auto Scaling Group's launch template references the AMI by the specific AMI ID (e.g., `ami-0abc123`) hardcoded at the time the launch template was created. After three Image Builder runs, the ASG is still launching the original AMI. A developer argues the Image Builder pipeline is broken because instances are not updated.

> **Competent move:** Image Builder produces a new AMI each run, but the ASG launch template still references the original AMI ID. The fix is to update the launch template to reference the new AMI — either by updating the launch template version to the new AMI ID (and setting the ASG default version) or by using SSM Parameter Store to store the latest AMI ID and referencing the SSM parameter in the launch template (`resolve:ssm:/my/golden-ami-id`). Coupling Image Builder output to SSM Parameter Store (Image Builder can write the AMI ID to a parameter on success) and referencing the SSM parameter in the launch template means new instances always use the current golden AMI without manual launch template updates.

> **Tempting-but-wrong:** Triggering an ASG instance refresh after every Image Builder run without updating the launch template. Instance refresh replaces running instances — but if the launch template still points to the old AMI ID, all replacement instances also use the old AMI. The launch template version must be updated first.

> **Verify:** `aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names <asg> --query 'AutoScalingGroups[0].LaunchTemplate'` shows the launch template ID and version; `aws ec2 describe-launch-template-versions --launch-template-id <id> --versions '$Default'` shows the AMI ID in use; compare to `aws ssm get-parameter --name /my/golden-ami-id` or the latest Image Builder output.
