# Eval situations — aws-devops-engineer-professional

Answer each: state the **competent action** and the **reason**. Be concise (2–4 sentences each).

1. Your cross-account CodePipeline deploys successfully to the dev account but fails at the artifact-download step in the prod account with "Access Denied." Both accounts' IAM roles have correct CodePipeline permissions. The artifact bucket lives in the tools account and uses SSE-S3 encryption. What is the root cause, and what must you change?

2. A Lambda canary deployment (`CodeDeployDefault.LambdaCanary10Percent5Minutes`) has been running at 10% for eight minutes. No CloudWatch alarm has fired, but the deployment has not shifted to 100% — it is stuck in `IN_PROGRESS`. Your team wants to manually advance it. What is likely wrong, and what is the correct resolution path?

3. A CloudFormation stack update is submitted to change an RDS instance's `DBInstanceClass` from `db.t3.medium` to `db.t3.large`. A junior engineer says "it's just a resize, no downtime." Is this accurate? What must you do before applying this change to production, and what does the change set tell you to watch for?

4. You deploy a new version of a CloudFormation Custom Resource backed by a Lambda function. The stack enters `UPDATE_IN_PROGRESS` and never completes — it has been 45 minutes. CloudWatch Logs show the Lambda function executed successfully and returned HTTP 200 to your own test. What is the actual cause, and how do you unblock the stack?

5. An Auto Scaling group serves a stateful session workload behind an ALB. During a scale-in event, users report mid-session errors. The ASG has a CloudWatch scale-in policy and a target tracking policy. No lifecycle hook is configured. What is the immediate fix to prevent these errors, and what must you configure to verify it works?

6. A Security team audit finds that CloudTrail is enabled in `us-east-1` only, not the six other regions where workloads run. The account owner says "CloudTrail is on — I can see events." What type of CloudTrail trail is missing, what does this gap mean for incident investigation, and how do you remediate it without disrupting the existing trail?

7. A CloudWatch alarm configured to alert on a new Lambda function is in `INSUFFICIENT_DATA` state 20 minutes after the function's first invocations. Your on-call engineer says "that means the function is healthy." Are they right? What does `INSUFFICIENT_DATA` actually mean here, and what should you check?

8. An SSM Patch Manager Maintenance Window is scheduled to run `AWS-RunPatchBaseline` on a fleet of EC2 instances, but 30% of the instances are not being patched. All instances have the SSM Agent installed and show as "Online" in Fleet Manager. What is the most likely cause, and what do you check first?

9. A team member creates a CloudFormation StackSet targeting three accounts in an AWS Organization. They set `--permission-model SELF_MANAGED` and manually created the execution role in one account. Stack instances deploy to that account but fail with "Stack instance was not found" or IAM errors in the other two. What is the correct remediation?

10. You are investigating a production incident. A Config Rule `s3-bucket-public-read-prohibited` shows a bucket as non-compliant, but the Config remediation action is configured and enabled. The bucket has been non-compliant for 6 hours. Why hasn't the auto-remediation run, and what do you check to diagnose this?

11. A developer stores a database password directly in the `environment` section of a CodeBuild buildspec as `DB_PASSWORD: mysecretvalue`. A security review flags it. The developer argues "the buildspec is in a private CodeCommit repo, so it's safe." Why is this wrong, and what is the correct pattern?

12. A Route 53 Failover routing policy has a primary record pointing to an ALB in `us-east-1` and a secondary record pointing to an ALB in `us-west-2`. During a simulated regional failure, traffic does not automatically shift to `us-west-2`. You verify the primary endpoint is down. What is the most likely missing configuration, and what command do you run to diagnose it?
