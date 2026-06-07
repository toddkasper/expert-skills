# Eval situations — aws-security-specialty

Answer each: state the **competent action** and the **reason**. Be concise (2–4 sentences each).

1. A developer's Lambda function needs to call `kms:Decrypt` on a customer-managed key. You attached an IAM role to the function with `kms:Decrypt` allowed on that key ARN. The function still gets `AccessDenied`. No SCP denies KMS actions in this account. What is the most likely cause, and what is the fix?

2. You are told to create an IAM Access Analyzer to detect unintended external access to S3 buckets, KMS keys, and IAM roles across your AWS Organization's 40 accounts and six regions. You create one organization-level analyzer in `us-east-1`. Is this sufficient? Explain.

3. Your org uses an SCP that explicitly denies `s3:DeleteBucket` on all accounts in the Prod OU. A new senior engineer has been granted an IAM policy with `AdministratorAccess`. They attempt to delete a bucket in a Prod-OU account and get `AccessDenied`. They argue the SCP must be broken because they are an admin. What do you tell them, and how do you confirm?

4. A compliance team mandates that no S3 bucket in any member account may be accessed over unencrypted HTTP — regardless of whether individual teams configure their bucket policies correctly. What is the most operationally scalable mechanism to enforce this org-wide, and what specifically must that mechanism include?

5. A security engineer is debugging why a cross-account role assumption fails. Account A's role trust policy allows Account B's role as a principal. Account B's IAM role has an `AssumeRole` allow for the Account A role ARN. The call still fails with `AccessDenied`. The engineer says, "Both sides allow it — something must be broken at the SCP level." Is the engineer right? What would you check first?

6. During incident response, a GuardDuty finding `UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration` fires for an EC2 instance role. Your colleague immediately deactivates the access key in the IAM console and says the compromise is contained. What critical step did they skip, and what is the correct immediate containment action?

7. You are building a detection pipeline where GuardDuty findings of ALL severities trigger an EventBridge rule that calls a Lambda function to automatically isolate the affected EC2 instance by replacing its security group. A security architect reviews the design and objects. What is wrong with this design, and what is the correct threshold?

8. A team deploys a VPC Gateway Endpoint for S3 so that EC2 instances in private subnets can reach S3 without going through the internet. Two weeks later, the security team discovers that instances are exfiltrating data to an external attacker's S3 bucket through the same endpoint. What control was missing, and how do you add it?

9. An engineering team is rotating a database password stored in Secrets Manager. After the rotation Lambda runs successfully, a subset of application pods immediately start failing with authentication errors, then recover on their own within 30 seconds. The rotation Lambda logs show no errors. What is most likely happening, and what should you fix?

10. Your company runs production workloads. The CISO asks you to ensure that even if an engineer with `AdministratorAccess` in a workload account accidentally (or maliciously) disables AWS Config and CloudTrail, those services will be automatically re-enabled within minutes. What AWS-native combination of services accomplishes this, and at what layer is the enforcement?

11. A regulated workload requires that S3 objects serving as audit logs cannot be deleted or overwritten for seven years under any circumstances — even if the account root user issues the delete command. What S3 feature and mode must you configure, and what makes this mode different from the alternative?

12. You are asked to architect EC2 access for a fleet of 200 instances in a private subnet with no internet gateway and no bastion host. The fleet must be accessible to the operations team for interactive shell sessions, and all session activity must be auditable in CloudTrail. What is the required per-instance configuration, and what VPC-level component is needed if the subnet has no internet route?
