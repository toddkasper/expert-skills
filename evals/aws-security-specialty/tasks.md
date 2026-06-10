# Application tasks — aws-security-specialty (Lens 4, held-out)

A skilled agent produces the artifact; a judge grades against the trap-keyed rubric. Run baseline vs skilled.

---

## Task 1 — IAM policy + KMS key policy privilege-escalation redline

**Prompt to the agent:** Review the following IAM role policy, KMS key policy, and S3 bucket policy for a data-processing workload. Redline every privilege-escalation, wildcard, exfiltration, and misconfiguration flaw. Name each problem, explain the exploitable risk, and state the minimum-privilege fix.

```json
// iam-role-policy.json  (attached to DataProcessorRole in account 111111111111)
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowIAMManagement",
      "Effect": "Allow",
      "Action": "iam:*",
      "Resource": "*"
    },
    {
      "Sid": "AllowS3Access",
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    },
    {
      "Sid": "AllowKMS",
      "Effect": "Allow",
      "Action": "kms:*",
      "Resource": "arn:aws:kms:us-east-1:111111111111:key/mrk-abc123"
    }
  ]
}

// kms-key-policy.json  (customer-managed key mrk-abc123)
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EnableRootAccess",
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::111111111111:root"},
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "AllowDataProcessor",
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::111111111111:role/DataProcessorRole"},
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}

// s3-bucket-policy.json  (bucket: pii-audit-logs-prod)
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::pii-audit-logs-prod/*"
    }
  ]
}
```

Additionally, the bucket has `BlockPublicAcls: false`, `BlockPublicPolicy: false`, `IgnorePublicAcls: false`, `RestrictPublicBuckets: false`.

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — `iam:*` on `Resource: *` in the role policy enables privilege escalation: the role can create new IAM users/roles with `AdministratorAccess`, attach policies to itself, or create console login profiles — effectively granting full account takeover. Must be scoped to the minimum IAM actions needed (e.g., `iam:PassRole` on specific role ARNs only).
- [ ] Trap 2 — `s3:*` on `Resource: *` allows data exfiltration to any bucket in any account; must be scoped to the specific bucket ARN(s) and only the required actions (`s3:GetObject`, `s3:PutObject`).
- [ ] Trap 3 — `kms:*` granted to `DataProcessorRole` in the key policy (including `kms:PutKeyPolicy`, `kms:ScheduleKeyDeletion`, `kms:DisableKey`) allows the role to lock out all other principals or destroy the key; must be scoped to `kms:Decrypt`, `kms:GenerateDataKey` only for this role.
- [ ] Trap 4 — S3 bucket policy `Principal: "*"` with `s3:GetObject` and `s3:PutObject` makes PII audit logs publicly readable and writable to the entire internet; must specify the exact role ARN as the principal and add a `Deny` for `aws:SecureTransport: false` to enforce HTTPS.
- [ ] Trap 5 — All four S3 Block Public Access settings are disabled on the PII bucket; Block Public Access must be enabled at both the bucket and account level for a bucket containing audit logs.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Replaces `iam:*` with the specific `iam:PassRole` permission scoped to the role ARN(s) the processor legitimately needs to assume; removes all other IAM write actions.
- Scopes `s3:*` to `["s3:GetObject", "s3:PutObject"]` on `arn:aws:s3:::pii-audit-logs-prod/*` only.
- Reduces KMS key policy for `DataProcessorRole` to `["kms:Decrypt", "kms:GenerateDataKey"]`; retains the root statement only for break-glass account recovery with `kms:*` narrowed to non-destructive admin operations.
- Replaces `Principal: "*"` in the bucket policy with the specific IAM role ARN; adds a `Deny` statement on `s3:*` when `aws:SecureTransport` is `false`.
- Enables all four Block Public Access settings on the bucket; recommends an SCP to enforce this org-wide.

---

## Task 2 — Security group + VPC flow log + GuardDuty detection gap redline

**Prompt to the agent:** Review the following network security configuration for a production VPC hosting a payment-processing service. Redline every flaw — unrestricted ingress, missing detective controls, and exfiltration vectors. Name each problem, explain the risk, and state the fix.

```yaml
# security-group: sg-payment-app (attached to payment EC2 instances)
SecurityGroupIngress:
  - IpProtocol: tcp
    FromPort: 22
    ToPort: 22
    CidrIp: 0.0.0.0/0          # SSH open to the world
  - IpProtocol: tcp
    FromPort: 443
    ToPort: 443
    CidrIp: 0.0.0.0/0          # HTTPS — intentional
  - IpProtocol: tcp
    FromPort: 3306
    ToPort: 3306
    CidrIp: 0.0.0.0/0          # MySQL open to the world
  - IpProtocol: "-1"
    FromPort: 0
    ToPort: 0
    CidrIp: 0.0.0.0/0          # All traffic inbound

SecurityGroupEgress:
  - IpProtocol: "-1"
    FromPort: 0
    ToPort: 0
    CidrIp: 0.0.0.0/0          # All traffic outbound

# VPC configuration
EnableDnsHostnames: true
EnableDnsSupport: true
# No VPC Flow Logs configured

# GuardDuty: not enabled in this account
# AWS Config: not enabled
# CloudTrail: management events only, no S3 data events
```

**Trap-keyed grading rubric** (caught / missed / new-error):
- [ ] Trap 1 — SSH (port 22) open to `0.0.0.0/0` exposes instances to brute-force and credential-stuffing attacks from the entire internet; restrict to a specific bastion host CIDR or, better, remove SSH entirely and use SSM Session Manager with no open port.
- [ ] Trap 2 — MySQL port 3306 open to `0.0.0.0/0` exposes the database tier directly to internet-wide scanning; must be restricted to the application-tier security group ID as the source, not a CIDR.
- [ ] Trap 3 — An "all traffic inbound" rule (`-1 / 0.0.0.0/0`) overrides all other ingress restrictions; this rule must be removed entirely.
- [ ] Trap 4 — No VPC Flow Logs configured means there is no network-level audit trail; cannot detect data exfiltration, lateral movement, or unexpected connection attempts post-incident. Enable flow logs to CloudWatch Logs or S3 with ALL traffic captured.
- [ ] Trap 5 — GuardDuty is not enabled; without it, findings like `UnauthorizedAccess:EC2/SSHBruteForce`, `Recon:EC2/PortProbeUnprotectedPort`, and `Exfiltration:S3/ObjectRead` will never fire. Enable GuardDuty and route HIGH/MEDIUM findings to a Security Hub aggregator.
- [ ] No new errors introduced

**Reference — a competent artifact:**
- Removes the SSH `0.0.0.0/0` rule; replaces with SSM Session Manager (requires VPC endpoint for `ssm`, `ssmmessages`, `ec2messages`) and removes port 22 entirely from the security group.
- Restricts MySQL ingress source to the application-tier security group ID (not a CIDR).
- Deletes the `"-1" / 0.0.0.0/0` inbound catch-all rule.
- Enables VPC Flow Logs with `TrafficType: ALL`, retention of 90 days minimum, and a log-group in CloudWatch Logs.
- Enables GuardDuty with S3 protection and EC2 malware scanning; delegates findings to a Security Hub administrator account.
- Recommends restricting egress to known destinations (e.g., port 443 to payment gateway IPs only) and enabling S3 data-event CloudTrail to detect exfiltration via the data plane.
