# Trigger tests — aws-security-specialty (Lens 2)

Routing regression set. Test each phrasing against skill DESCRIPTIONS only. Each routes to exactly one skill.

## Should route to aws-security-specialty (5)

1. "Review this IAM role policy and SCP — I need to know if any combination of actions allows privilege escalation to administrator."
2. "Set up GuardDuty findings of HIGH severity to automatically quarantine the affected EC2 instance by replacing its security group with an isolation group via EventBridge + Lambda."
3. "Our KMS customer-managed key policy has `kms:*` on the key for the account root — walk me through the lockout risk and how to fix the key policy safely."
4. "Design a detective control stack for our 30-account org: which combination of Security Hub, GuardDuty, Macie, and Config gives us coverage without duplicate alerting?"
5. "An S3 bucket that holds PII is showing as publicly accessible in Macie. Walk me through all the layers — bucket ACL, bucket policy, Block Public Access, and S3 Access Points — that could be causing it."

## Near-misses → a sibling (3)

1. "Build a CodePipeline that automatically runs `aws configservice start-config-rules-evaluation` after every CloudFormation deployment and pages the team if any rule goes non-compliant." → `aws-devops-engineer-professional`  (CI/CD pipeline automation and remediation wiring, not security-control design)
2. "We need to decide between AWS Managed Microsoft AD and Simple AD for our 5,000-user hybrid workforce; compare cost, feature set, and integration with WorkSpaces." → `aws-solutions-architect-professional`  (enterprise architecture trade-off and service selection, not security-control depth)
3. "Our Secrets Manager rotation Lambda is failing silently — debug the CloudWatch Logs and fix the Lambda execution role." → `aws-devops-engineer-professional`  (Lambda debugging and IAM role for pipeline/automation, not security detection/response design)
