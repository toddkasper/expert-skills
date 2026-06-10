# Decision Scenarios — AWS Security Specialty

Five additional judgment scenarios. The inline scenario in SKILL.md covers VPC endpoint policy for S3 exfiltration prevention; these cover complementary high-lift judgment areas.

---

**Scenario 2 — IAM Access Analyzer: organization-level vs per-region analyzers**

> **Situation:** A security engineer creates a single organization-level IAM Access Analyzer in `us-east-1` and declares the org's external-access detection posture complete. The org has workloads in `us-east-1`, `eu-west-1`, and `ap-southeast-1`. A week later a penetration test finds an unintended cross-account KMS key policy in `ap-southeast-1` that Access Analyzer never flagged.

> **Competent move:** IAM Access Analyzer is **region-scoped** for resource analysis. An organization-level analyzer in `us-east-1` covers resources *in* `us-east-1` across all org accounts — it does not analyze resources in other regions. Create an organization-level analyzer in every region where the org has resources (here: `eu-west-1` and `ap-southeast-1` as well). Use a CloudFormation StackSet with SERVICE_MANAGED to deploy the analyzer in all active regions across the org in a single operation.

> **Tempting-but-wrong:** Assuming an "organization-level" analyzer means org-wide across all regions. The org scope means it covers all *accounts* in the org, but still only for resources located in the same region as the analyzer. A single-region org analyzer is not a substitute for per-region deployment.

> **Verify:** `aws accessanalyzer list-analyzers --region ap-southeast-1` — if empty, no analyzer covers that region. After deploying: `aws accessanalyzer list-findings --analyzer-arn <arn> --region ap-southeast-1` to confirm findings are generated for resources in that region.

---

**Scenario 3 — S3 Object Lock: Governance vs Compliance mode for audit logs**

> **Situation:** A regulated financial services firm must retain trade-audit S3 logs for seven years and prevent deletion by any principal, including the account root user. A cloud engineer enables S3 Object Lock on the bucket, sets the default retention to 7 years, and selects **Governance** mode. The compliance officer signs off. Six months later an engineer with the `s3:BypassGovernanceRetention` IAM permission accidentally deletes a batch of locked objects.

> **Competent move:** Use **Compliance** mode, not Governance mode. Compliance mode prevents any principal — including the account root — from shortening the retention period or deleting objects before the retention period expires, with no bypass mechanism whatsoever. Governance mode is defeatable by any principal who has `s3:BypassGovernanceRetention` — which makes it inappropriate for truly irrevocable retention requirements. Enable Compliance mode on Object Lock and remove any `s3:BypassGovernanceRetention` grants from all IAM policies as a defense-in-depth measure.

> **Tempting-but-wrong:** Using Governance mode and revoking `s3:BypassGovernanceRetention` from all roles. While revoking the permission removes the ability to bypass today, it can be re-granted by any administrator with IAM rights — the control is not immutable. Compliance mode is the only S3 mechanism that is truly irrevocable without AWS Support involvement.

> **Verify:** `aws s3api get-object-lock-configuration --bucket <bucket>` — confirm `ObjectLockEnabled: Enabled` and `DefaultRetention.Mode: COMPLIANCE`. Attempt a delete from a principal with `s3:BypassGovernanceRetention` — it must be denied. `aws s3api head-object --bucket <bucket> --key <key>` shows individual object lock mode and retain-until date.

---

**Scenario 4 — Permission boundary gap blocks legitimate IAM role creation**

> **Situation:** A security team deploys a permission boundary (`DeveloperBoundary`) to all developer IAM roles, intending to allow developers to create and manage their own IAM service roles for Lambda and EC2 but prevent privilege escalation. The boundary explicitly allows `iam:CreateRole`, `iam:AttachRolePolicy`, and `iam:PassRole`. A developer tries to create a new Lambda execution role with `AmazonS3ReadOnlyAccess` and gets `AccessDenied` — but the developer's identity policy allows all `iam:*` actions.

> **Competent move:** The permission boundary caps what the developer can do — the developer's effective permissions are the *intersection* of what the identity policy allows AND what the boundary permits. If `AmazonS3ReadOnlyAccess` includes `s3:GetObject` and the developer boundary does not permit `iam:PutRolePolicy` or the developer's identity policy allows it, the issue is that attaching the managed policy to the new role may be denied because the boundary does not allow `iam:AttachRolePolicy` on policies outside a permitted set. The fix is to review the `DeveloperBoundary` — it must explicitly allow all IAM actions the developer needs (including attaching policies to new roles) and typically should require that the created roles also carry the boundary (`iam:PutRolePermissionsBoundary` condition).

> **Tempting-but-wrong:** Removing the permission boundary from the developer's role to fix the immediate error. This resolves the symptom but eliminates the guardrail entirely, allowing privilege escalation. The correct path is to refine the boundary to permit the specific IAM actions needed while still capping the maximum scope of any created role.

> **Verify:** Use the IAM Policy Simulator: choose the developer principal, action `iam:AttachRolePolicy`, and specify the target managed policy ARN — it will identify which policy type (boundary vs identity) is causing the denial. Inspect `aws iam get-role --role-name <developer-role> --query 'Role.PermissionsBoundary'` to confirm the boundary ARN in effect.

---

**Scenario 5 — GuardDuty finding: EC2 credential exfiltration — correct immediate containment**

> **Situation:** GuardDuty fires a High-severity `UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration.InsideAWS` finding. An EC2 instance's role credentials are being used from an IP address outside AWS. An on-call engineer runs `aws iam deactivate-mfa-device` and `aws iam delete-access-key` — but then realizes this is an instance role, not an IAM user, so there is no access key to delete. They escalate saying "there's nothing to revoke."

> **Competent move:** Instance role credentials are temporary STS-issued credentials — you cannot "delete" them, but you can immediately attach an explicit-deny inline policy to the IAM role that contains a `Condition: StringNotEquals: aws:TokenIssueTime: <current-time>` block. This revokes all sessions issued before the policy attachment without affecting future sessions the EC2 instance legitimately acquires. As a parallel action: replace the EC2 instance's security group with a quarantine group (deny all inbound and outbound except to the security team's investigation tooling) to cut off the C2 channel. Do not terminate the instance before taking an EBS snapshot for forensics.

> **Tempting-but-wrong:** Stopping or terminating the EC2 instance as the first action. Stopping the instance does not invalidate already-issued STS credentials — the attacker retains those credentials until they expire (up to 1 hour for instance role credentials). Termination before forensic evidence preservation destroys artifacts needed for incident investigation.

> **Verify:** `aws iam list-role-policies --role-name <role-name>` confirms the explicit-deny inline policy is attached; `aws sts get-caller-identity` from a test call using the compromised credentials (obtained from CloudTrail) should return `AccessDenied` after the deny policy is in place; `aws ec2 describe-instances --instance-ids <id> --query 'Reservations[0].Instances[0].SecurityGroups'` confirms the quarantine SG is applied.

---

**Scenario 6 — Macie sensitive data in a new data-lake bucket: scan order matters**

> **Situation:** A data engineering team creates a new S3 bucket to receive daily CSV dumps of customer records from an on-premises ETL job. A security engineer is asked to ensure the bucket is compliant before the first data load arrives. They enable Macie organization-wide and confirm Macie is running. The security engineer marks the bucket as "compliant" without running a Macie discovery job against it, reasoning that Macie continuously monitors and will catch any issues after data arrives.

> **Competent move:** Macie's continuous monitoring evaluates **bucket-level preventive controls** (encryption status, public access, cross-account access) in near real-time — but it does **not** scan existing object content for PII until a discovery job is run. The team should configure and run a Macie sensitive data discovery job against the bucket after the first data load arrives (or against a sample before production loads begin) to classify what types of sensitive data it contains before designating it as compliant. Continuous monitoring alone is not a data-classification scan.

> **Tempting-but-wrong:** Treating Macie's green bucket status (no preventive-control findings) as a full data classification clearance. A bucket can have no public access, full encryption, and no cross-account sharing — and still contain unclassified PII that Macie has not yet analyzed because no discovery job was run. The continuous monitoring and the discovery job are complementary, not interchangeable.

> **Verify:** In the Macie console or via `aws macie2 list-findings --finding-criteria '{"criterion":{"type":{"eq":["SensitiveData:S3Object/Personal"]}}}'` — findings only appear after a discovery job has run and detected sensitive data; an empty result means either no PII exists or no job has run yet (check `aws macie2 list-classification-jobs --filter-criteria '{"includes":{"simpleCriterion":[{"comparator":"EQ","key":"S3_BUCKET_NAME","values":["<bucket>"]}]}}'`).
