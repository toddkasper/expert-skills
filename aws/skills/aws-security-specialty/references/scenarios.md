# Decision Scenarios — AWS Security Specialty

Two additional judgment scenarios (Scenarios 1–4 are inlined in the SKILL.md body). These cover complementary high-lift judgment areas.

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

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
