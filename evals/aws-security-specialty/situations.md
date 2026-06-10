# Eval situations — aws-security-specialty

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

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

13. Your team is procuring a new AWS security tool. A vendor's slide deck describes it as "the AWS product that replaced Security Hub" and says it "provides attack-path analysis and exposure scoring across your AWS environment." A second AWS-native product in your current stack aggregates findings from GuardDuty, Inspector, and Macie into a unified compliance dashboard. The vendor claims those two products are the same thing under different names. Are they? Identify each product by its current name and explain what distinguishes them.

14. A junior engineer is tasked with blocking all cross-account principals from reading objects in your org's S3 buckets unless the request uses TLS. She drafts an RCP and says, "I checked — RCPs have been available since re:Invent 2023, and they enforce controls across every AWS service, so this approach will cover all our data stores." Before approving the change, you need to correct her understanding. What two factual errors must you address, and what are the correct details?

15. The SOC receives a GuardDuty notification classified at the highest available severity tier — a tier that did not exist in the service two years ago. The finding's type begins with a prefix that the on-call analyst has not seen before. The analyst routes it to the standard High-severity queue and begins working the most recently flagged resource. A senior engineer escalates immediately and says the analyst is handling this wrong on two counts. What are those two counts?

16. Your team deploys AWS Firewall Manager to centrally manage WAF policies across all accounts in your organization. After deployment, one account's ALBs still do not have WAF policies applied. The Firewall Manager admin says, "Firewall Manager requires Organizations and Security Hub to be enabled — I confirmed both are on." Is this the correct prerequisite? What is the actual required service that Firewall Manager needs enabled in member accounts, and how should the team verify compliance status?

17. An S3 bucket stores financial audit logs. A compliance officer confirms: "We have S3 Block Public Access enabled at the bucket level. That means no object in the bucket can be made public, even if someone adds a permissive ACL to an individual object." Is the compliance officer correct about why BPA prevents public access? Additionally, what control is still needed to prevent a bucket owner in a member account from disabling bucket-level BPA?

18. You are investigating why CloudTrail shows no `PutObject` API calls for a critical S3 bucket despite confirmed writes by application pods over the past 24 hours. Management events are enabled on the trail. You see no S3 data-plane events at all. What is the most likely explanation, and what is the exact configuration change needed to capture future S3 object-level activity?
