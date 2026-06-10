# Decision Scenarios — AWS DevOps Engineer Professional

Two additional judgment scenarios (Scenarios 2–4 are now inlined in the SKILL.md body). These cover complementary high-lift judgment areas.

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
