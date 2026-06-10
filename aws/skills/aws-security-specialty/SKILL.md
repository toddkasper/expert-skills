---
name: aws-security-specialty
description: AWS security engineering — threat detection (GuardDuty, Security Hub, Detective, Security Lake), incident response and containment, IAM policy evaluation and permission boundaries, infrastructure/network security (security groups, NACLs, WAF, Shield, PrivateLink), data protection and KMS encryption strategy, Secrets Manager, Macie, and multi-account governance (SCPs, Control Tower, Config, Firewall Manager). Use when designing or reviewing AWS security controls, detection/response automation, or compliance guardrails. Not pipeline/IaC delivery (see aws-devops-engineer-professional) or broad architecture trade-offs (see aws-solutions-architect-professional). Scoped and benchmarked by the AWS Security – Specialty (SCS-C03) blueprint.
metadata:
  anchor-credential: AWS Certified Security – Specialty
  exam-code: SCS-C03
  domain: aws
  type: certification-playbook
  status: current
  last-reviewed: 2026-06-09
  blueprint-verified: 2026-06-07
  blueprint: SCS-C03 (December 2025)
---

# AWS Certified Security – Specialty (SCS-C03) — Skills Reference

## Overview

Operational playbook for AWS security work. Each section states the rule to apply: decision criteria, concrete limits, anti-patterns, and verification steps. **Verify against the live account** — effective permissions result from combining multiple policy types, and a single missing allow or extra deny changes the outcome. Benchmarked against AWS Security – Specialty (SCS-C03, December 2025).

> **Load this skill when…** designing or reviewing IAM policies, permission boundaries, SCPs, or RCPs; configuring threat detection (GuardDuty, Security Hub, Detective, Security Lake); implementing KMS encryption strategy or Secrets Manager rotation; auditing network defenses (WAF, Shield, PrivateLink, NACLs) or building IR/containment automation.
> **Not this skill:** pipeline/IaC delivery → see `aws-devops-engineer-professional`; enterprise architecture trade-offs → see `aws-solutions-architect-professional`.

> **Study resources, SCS-C02→SCS-C03 changes, and credential logistics:** [references/study-resources.md](references/study-resources.md).

> **Verify steps** — use your project's MCP/automation, the AWS CLI (`aws`) or CloudShell, or the Console, in that order.

---

## Uncertainty & Escalation

- **Always re-verify live — volatile facts:** KMS automatic-rotation minimum interval `[volatile — verify live]`, Shield Advanced pricing `[volatile — verify live]`, GuardDuty finding type catalog (new finding families added quarterly) `[volatile — verify live]`, IAM Access Analyzer supported resource types `[volatile — verify live]`, RCP (Resource Control Policy) region/service availability `[volatile — verify live]`, and any feature flagged in the `blueprint:` frontmatter as a recent addition.
- **Live wins:** when the live AWS account, CLI output, or official AWS docs contradict a claim in this file, the live source is authoritative. Log the discrepancy via the Feedback protocol below so the skill can be corrected.
- **Escalate to a human — do not silently execute:** modifying KMS key policies or deleting CMKs; changing SCPs or RCPs; revoking IAM sessions or attaching explicit-deny policies to production roles; quarantining or terminating EC2 instances (even as an IR step); disabling GuardDuty or CloudTrail in any account; opening security-group or network-boundary rules; any Secrets Manager rotation that affects a production database.
- **Confidence taxonomy:** every fact in this file is considered *stable* unless tagged `[volatile — verify live]` (changes with AWS service updates) or `[opinion — house style]` (a defensible default, not the only valid choice).

---

## 1. Identity and Access Management (20%)

### Policy evaluation order — the evaluation stack

Every authorization decision passes through this stack in order. **Explicit Deny at any layer is an immediate, unconditional halt.**

1. **Explicit Deny** (any policy type) → AccessDenied, full stop.
2. **SCPs** — ceiling on what principals in the OU/account may do. SCPs do not grant; they cap.
3. **RCPs (Resource Control Policies)** — ceiling on what any principal (including cross-account) may do to resources in the OU/account. Introduced late 2023; tested in SCS-C03 `[volatile — verify live]`.
4. **Permission Boundaries** — ceiling on what an IAM principal's identity policies may grant. Does not cap resource-policy grants made directly to the role.
5. **Session Policies** — ceiling applied at `AssumeRole` / `GetFederationToken`; caps the session below the role's full permissions.
6. **Resource Policies + Identity Policies** — the grant layer:
   - Same account: resource policy **OR** identity policy may grant (either is sufficient).
   - Cross-account: resource policy **AND** identity policy must both grant.

**KMS special case:** the key policy is the primary access control. Unless it explicitly delegates to IAM (`"Principal": {"AWS": "arn:aws:iam::<account>:root"}`), IAM policies for `kms:Decrypt` etc. have no effect. Always verify the key policy first when debugging KMS denials.

**Permission boundaries** cap but don't grant — effective permissions = intersection of identity policy and boundary. An `AdministratorAccess` policy on a role with a narrow boundary yields only the boundary's scope.

### Least privilege tools

- **IAM Access Analyzer** — region-scoped; scans resource-based policies for unintended external access. Create one per region, or use an org-level analyzer (covers all accounts in that region). Also generates policy suggestions from CloudTrail history.
- **IAM Access Advisor** — last-accessed timestamps per service/action; prune unused permissions.
- **Amazon Verified Permissions** — Cedar-based fine-grained app authorization, separate from IAM.

### Federation

**IAM Identity Center (SSO):** recommended for human multi-account access — permission sets, automatic temporary credentials, no long-lived keys. **SAML 2.0** uses `AssumeRoleWithSAML`; **OIDC** uses an OIDC provider principal with a `Condition` to scope subjects.

**Red flags:** identity-policy Allow to KMS key with no key policy delegation; cross-account S3 with only one side configured; permission boundary treated as a grant; single-region analyzer covering all regions; long-lived IAM user credentials for humans.

**Verify:** IAM Policy Simulator; Access Analyzer findings; CloudTrail `AssumeRole` and `GetCallerIdentity`.

---

## 2. Infrastructure Security (18%)

### Security groups vs NACLs

| Dimension | Security Groups | NACLs |
|---|---|---|
| Scope | Per ENI | Per subnet |
| State | Stateful (return traffic automatic) | Stateless (explicit inbound + outbound required) |
| Default | Deny all inbound; allow all outbound | Allow all (default NACL) |
| Rules | Allow only | Allow and deny; lowest-number evaluated first |
| Best for | App-layer allow rules; SG-by-ID for dynamic scaling | Blocking IP/CIDR ranges; broad subnet blocks |

**NACL stateless trap:** allowing inbound TCP 443 without allowing outbound ephemeral ports (1024–65535) silently stalls connections. Reference security groups by ID (not CIDR) when instance membership changes.

### VPC endpoints, WAF, Shield, and EC2 host security

- **Gateway endpoints** (S3, DynamoDB) — free, added to route tables. **Interface endpoints** (PrivateLink) — deploy ENIs into subnets with private DNS; required for all other services.
- **Endpoint policies** restrict which resources the endpoint can reach — use to prevent exfiltration (e.g., limit S3 access to company-owned buckets only).
- **WAF:** Layer 7 on CloudFront, ALB, API Gateway, AppSync, Cognito. Managed rule groups cover OWASP Top 10, bot control, IP reputation. Deploy on CloudFront AND ALB — protecting only ALB allows origin-IP bypass.
- **Shield Standard:** automatic, free, L3/L4. **Shield Advanced `[volatile — verify live]`:** paid; L7 DDoS detection, SRT engagement, cost protection.
- **SSM Session Manager:** no SSH/RDP required — instance needs SSM Agent + `AmazonSSMManagedInstanceCore` profile. All session activity logged to CloudTrail. Never maintain standing port-22/3389 ingress.
- **Inspector:** continuous CVE assessment for EC2, Lambda, ECR images; findings flow to Security Hub.

**Red flags:** NACL missing outbound ephemeral port rules; VPC endpoint with no endpoint policy; WAF only on ALB (not CloudFront); SSH/RDP open to `0.0.0.0/0`; no SSM Agent instance profile.

---

## 3. Data Protection (18%)

### KMS — the key decision table

| Key type | Who manages material | Auto-rotation | Cross-region | Use case |
|---|---|---|---|---|
| AWS managed key (`aws/<service>`) | AWS | Yes (annual) | No | Default encryption for most services; least operational overhead |
| Customer managed key (CMK) | Customer | Optional (configurable interval, min 90 days) | No (per-region) | Audit trails, key policy control, cross-service sharing |
| Multi-region key | Customer | Optional | Yes (replicate into target regions) | Disaster recovery, global applications, cross-region replication |
| Imported key material | Customer | No (must re-import) | No | Regulatory requirements to control key material source |

Only **symmetric** CMKs with AWS-generated material support automatic rotation. Asymmetric keys and imported-material keys do not support automatic rotation. When you rotate a key, the old backing material is retained to decrypt data encrypted with it; the new material encrypts new data.

**Envelope encryption:** KMS generates a data key; data key encrypts the payload; only the encrypted data key and ciphertext are stored. `GenerateDataKey` → encrypt locally → discard plaintext key. `Decrypt` calls KMS to get the plaintext data key.

**Key policy primacy:** if the key policy lacks `"Principal": {"AWS": "arn:aws:iam::<account-id>:root"}`, no IAM policy can grant access. Every CMK needs the account root delegation statement; IAM policies can then add or restrict beyond it.

### S3 data protection

- **Block Public Access:** account-level settings override bucket/object ACLs — always enable at account level.
- **TLS enforcement:** `Deny` with `"aws:SecureTransport": "false"` in the bucket policy.
- **Object lock (WORM):** `Governance` mode can be bypassed by principals with `s3:BypassGovernanceRetention`; `Compliance` mode is irrevocable through the retention period even by root. Use `Compliance` for regulated retention.
- **Replication + encryption:** SSE-KMS objects replicate only if the destination key policy allows the replication role.

### Secrets Manager and Macie

**Secrets Manager:** CMK-encrypted; auto-rotation via Lambda (needs network access to both Secrets Manager and the target service — VPC interface endpoints in private subnets). Rotation stages: `AWSPENDING` → `AWSCURRENT` → `AWSPREVIOUS`; cached-secret apps must handle the overlap window gracefully.

**Macie:** ML+pattern scanning for PII/credentials in S3. Continuous monitoring evaluates bucket-level controls; findings flow to Security Hub. Deploy org-wide. Run a **discovery job** to classify existing object content — continuous monitoring alone does not scan object data.

**Red flags:** CMK with no key policy root delegation; SSE-S3 where key-usage audit trail is required (use SSE-KMS); S3 Block Public Access disabled at account level; secrets in environment variables or Parameter Store standard tier when rotation is required; SSE-KMS objects replicated cross-region without configuring destination key policy.

---

## 4. Detection (16%)

### GuardDuty — the threat detection anchor

GuardDuty analyzes CloudTrail, VPC Flow Logs, DNS, EKS audit logs, Lambda network activity, and RDS login activity — no log source setup required. Enable in every region and account; use the org delegated-administrator so member accounts cannot disable it.

Severity: **Low** (informational — do not auto-isolate), **Medium** (investigate + auto-notify), **High** (auto-contain).

| Finding family | High-severity example | Auto-remediation |
|---|---|---|
| Compromised EC2 | `UnauthorizedAccess:EC2/MaliciousIPCaller` | Quarantine SG + EBS snapshot + notify |
| Credential exfiltration | `UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration` | Explicit-deny role policy + notify |
| S3 data exposure | `Policy:S3/BucketPublicAccessGranted` | Re-enable Block Public Access |
| Malware | `Execution:EC2/MaliciousFile` | Isolate instance + Malware Protection scan |

### Security Hub, Security Lake, and Detective

- **Security Hub:** aggregates GuardDuty, Inspector, Macie, Access Analyzer, Firewall Manager findings (ASFF format); runs CIS, FSBP, PCI DSS checks. Use org delegated-admin so all-account findings flow centrally. Route HIGH/CRITICAL to EventBridge → SNS → on-call.
- **Security Lake** normalizes sources (CloudTrail, VPC Flow Logs, WAF, EKS, Security Hub) to OCSF/Parquet for long-term SIEM analytics. **Detective** provides graph-based investigation of GuardDuty findings — use instead of manually joining CloudTrail + VPC Flow Logs.

**Pipeline:** GuardDuty → EventBridge (on severity) → Lambda / Step Functions / SSM Automation → containment + SNS + Security Hub update.

**Red flags:** GuardDuty not org-wide; member accounts can disable GuardDuty; Security Hub without delegated admin; all finding severities routed to the same auto-remediation Lambda (low severity = high false-positive rate); manual CloudTrail + Flow Log correlation instead of Detective.

---

## 5. Incident Response (14%)

### Containment playbooks

**EC2 compromise (in order):** (1) Replace SGs with a forensic/quarantine SG (allow SSM endpoint only). (2) Create EBS snapshot before remediation. (3) Access via SSM Session Manager. (4) Tag `{"IncidentStatus":"Quarantined","Ticket":"<ID>"}`.

**Credential compromise:** (1) Attach explicit-deny inline IAM policy immediately. (2) Rotate or deactivate the credential. (3) CloudTrail: review `GetCallerIdentity`, `AssumeRole`, and all API calls in the exposure window. (4) Check for resources created or data exfiltrated.

**SSM Automation runbooks:** pre-build for EC2 isolation, credential revocation, and restore-from-backup. Use managed runbooks (`AWS-IsolateEC2Instance`) where available; add Approval steps for destructive actions.

**Forensic accounts:** VPC-endpoint-only access (S3/CloudTrail/Athena), no internet egress, strict role-based access.

**Red flags:** no pre-built runbooks; terminating an instance before EBS snapshot; root credentials for IR; no org-level multi-region CloudTrail.

---

## 6. Security Foundations and Governance (14%)

### Multi-account structure (AWS SRA canonical)

- **Management account** — Organizations, billing, Control Tower. No workloads.
- **Security OU** → Log Archive account (CloudTrail, VPC Flow Logs, Security Lake) + Audit/Security Tooling account (GuardDuty delegated admin, Security Hub delegated admin, Firewall Manager).
- **Workload OUs** — Sandbox, Dev, Staging, Prod with appropriate SCPs per OU.

### SCPs, RCPs, and Control Tower

- **SCPs** cap what IAM principals in the OU/account may do. Do not grant. A Deny SCP blocks even `AdministratorAccess`.
- **RCPs** cap what any principal — including cross-account and service principals — may do to resources in the OU/account. Enforce encryption at rest or block non-TLS org-wide regardless of individual bucket policies.
- **Deny-list SCP strategy** (start with `FullAWSAccess`, add targeted Denies) is preferred over allow-list (allow-list requires enumerating every allowed action, becomes unmanageable).
- **Control Tower preventive guardrails** = SCPs (block); **detective guardrails** = Config rules (alert, don't block). Deploy preventive controls only after validating with detective guardrails.

### Config, Conformance Packs, and Firewall Manager

- **Config** records configuration changes; evaluates managed or custom-Lambda rules; aggregators roll up compliance centrally.
- **Conformance packs** (Config rules via StackSets) for CIS, NIST, PCI — deploy org-wide.
- **Firewall Manager** centrally deploys WAF, Shield Advanced, Security Group audit/enforce, and Network Firewall policies — propagates to new accounts as they join a target OU. Requires Organizations + Security Hub.

**Red flags:** SCPs at root without break-glass exceptions; Config rules deployed per-account manually (use conformance packs); Firewall Manager WAF not covering all internet-facing ALBs; Log Archive with write access for workload accounts; security tooling co-mingled with workloads in the same OU.

---

## Executable Workflows

### Workflow 1 — Stand Up Cross-Account Access (Least-Privilege Role + Trust Policy + External ID)

1. In the **target account** (the account that owns the resource), create an IAM role with a trust policy allowing the source account's principal to assume it, scoped with an external ID condition:
   ```json
   "Principal": {"AWS": "arn:aws:iam::<SOURCE_ACCOUNT>:root"},
   "Condition": {"StringEquals": {"sts:ExternalId": "<UNIQUE_EXTERNAL_ID>"}}
   ```
   → gate: `aws iam get-role --role-name <role> --query 'Role.AssumeRolePolicyDocument'` in the target account — confirm `sts:ExternalId` condition is present and the principal is scoped to the specific source account (not `*`).
2. Attach a least-privilege permission policy to the role — grant only the specific actions on specific resources the source account needs; avoid `*` on actions or resources.
   → gate: `aws iam simulate-principal-policy --policy-source-arn <role-arn> --action-names s3:PutObject --resource-arns arn:aws:s3:::<bucket>/*` — confirm `allowed`; test an action outside scope and confirm `implicitDeny`.
3. In the **source account**, create an IAM policy that allows `sts:AssumeRole` on the target role ARN and attach it to the source principal (role or user).
   → gate: `aws iam get-role-policy` or `list-attached-role-policies` on the source principal — confirm `sts:AssumeRole` is present for the exact target role ARN.
4. Test the assume-role chain: `aws sts assume-role --role-arn <target-role-arn> --role-session-name test --external-id <UNIQUE_EXTERNAL_ID>` from the source account.
   → gate: command returns `Credentials` with `AccessKeyId`, `SecretAccessKey`, and `SessionToken`; without the external ID or with a wrong value it returns `AccessDenied`.
5. Confirm the session cannot exceed the role's permission boundary: attempt an action the role's policy does not allow using the temporary credentials — confirm `AccessDenied`.

---

### Workflow 2 — Create/Scope a KMS Key and Grants (Key Policy vs IAM)

1. Create a symmetric CMK with an explicit key policy. The policy must include the account root delegation statement (`"Principal": {"AWS": "arn:aws:iam::<account-id>:root"}`) so that IAM policies in the account can grant access. Add key administrators separately from key users.
   → gate: `aws kms describe-key --key-id <key-id>` confirms `KeyState: Enabled`; `aws kms get-key-policy --key-id <key-id> --policy-name default` shows the root delegation statement.
2. Grant the intended user/role key-usage actions (`kms:Decrypt`, `kms:GenerateDataKey`) via either (a) the key policy directly or (b) an IAM identity policy (only works because of the root delegation in step 1).
   → gate: `aws kms list-key-policies --key-id <key-id>` to inspect; then test with `aws kms generate-data-key --key-id <key-id> --key-spec AES_256` as the intended principal — success confirms the grant chain works.
3. If a third-party service or Lambda needs time-bounded access without modifying the key policy, create a KMS grant: `aws kms create-grant --key-id <key-id> --grantee-principal <arn> --operations Decrypt,GenerateDataKey`.
   → gate: `aws kms list-grants --key-id <key-id>` confirms the grant exists; note the `GrantId` for future revocation.
4. Enable automatic key rotation (symmetric CMKs only, minimum 90-day interval `[volatile — verify live]`): `aws kms enable-key-rotation --key-id <key-id>`.
   → gate: `aws kms get-key-rotation-status --key-id <key-id>` returns `{"KeyRotationEnabled": true}`.
5. To clean up a temporary grant, revoke it by ID: `aws kms revoke-grant --key-id <key-id> --grant-id <grant-id>`. Do NOT delete or disable the CMK while encrypted data exists — that data becomes permanently inaccessible.
   → gate: `aws kms list-grants --key-id <key-id>` no longer shows the revoked grant ID.

---

### Workflow 3 — Respond to a GuardDuty Instance-Credential-Exfiltration Finding (Contain → Revoke → Quarantine → Investigate)

1. **Identify scope:** open the finding (e.g., `UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration.OutsideAWS`). Note instance ID, IAM role, and time window.
   → gate: `aws guardduty get-findings --detector-id <id> --finding-ids <finding-id>` returns full JSON with `service.action.awsApiCallAction` details.
2. **Contain — explicit-deny the role immediately:** `aws iam put-role-policy --role-name <role> --policy-name QuarantineExplicitDeny --policy-document '{"Statement":[{"Effect":"Deny","Action":"*","Resource":"*"}]}'`.
   → gate: test a call using the role's credentials — must return `AccessDenied` with `ExplicitDeny`.
3. **Quarantine SG:** replace the instance's security groups with a forensic SG (allow only SSM endpoint TCP 443, deny all else). Do NOT terminate yet.
   → gate: `aws ec2 describe-instances --instance-ids <id> --query 'Reservations[].Instances[].SecurityGroups'` shows only the forensic SG.
4. **Preserve evidence:** `aws ec2 create-snapshot --volume-id <vol-id> --description "IR-<finding-id>-<date>"` for all volumes.
   → gate: `aws ec2 describe-snapshots --snapshot-ids <snap-id>` reaches `completed` before proceeding.
5. **Investigate:** `aws cloudtrail lookup-events --lookup-attributes AttributeKey=AccessKeyId,AttributeValue=<ASIA...> --start-time <incident-start>` — flag `CreateUser`, `AttachUserPolicy`, `PutBucketPolicy`, `GetObject`, `AssumeRole`.
   → gate: every `eventName` in the window reviewed; follow-up remediation items documented.
6. **Eradicate and recover:** replace the IAM role; remove the quarantine policy only after the replacement role is in place; restore from a known-good AMI rather than reusing the compromised instance.

---

## Decision Scenarios

**Scenario 1 — VPC endpoint policy missing: S3 data exfiltration via Gateway endpoint**

> **Situation:** A financial-services team deploys a VPC Gateway Endpoint for S3 so EC2 instances in private subnets can reach S3 without traversing the internet. Two weeks after go-live, a GuardDuty finding fires: one instance is pushing data to an S3 bucket owned by an external account. The security team assumed the Gateway endpoint kept traffic "internal" and safe. No endpoint policy was configured.

> **Competent move:** A VPC Gateway Endpoint with no endpoint policy uses the default policy — `"Principal": "*", "Action": "s3:*", "Resource": "*"` — which allows any instance in the VPC to reach *any* S3 bucket, including buckets in attacker-controlled accounts. Add an endpoint policy that restricts `Resource` to only the bucket ARNs the workload legitimately needs (e.g., `arn:aws:s3:::my-company-bucket` and `arn:aws:s3:::my-company-bucket/*`), and deny all other S3 access through the endpoint. This prevents the endpoint from becoming an exfiltration channel while keeping legitimate access intact.

> **Tempting-but-wrong:** Relying on the EC2 instance's IAM role permissions alone. The IAM role may correctly restrict `s3:PutObject` to company-owned buckets — but if the instance is compromised and the attacker obtains the instance credentials, they can use those same credentials to call S3 from outside the VPC over the internet (bypassing the endpoint policy entirely). The endpoint policy adds a complementary control that is enforced at the network/endpoint layer regardless of which caller holds the credentials.

> **Verify:** `aws ec2 describe-vpc-endpoints --query 'VpcEndpoints[?ServiceName==\`com.amazonaws.<region>.s3\`].PolicyDocument'` — confirm the policy restricts `Resource` to specific bucket ARNs; attempt `aws s3 cp` from an instance in the VPC to an external bucket through the endpoint — it should be denied.

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

Further scenarios (EC2 credential exfiltration containment, Macie discovery job vs continuous monitoring): [references/scenarios.md](references/scenarios.md).

---

## Operational Rules Quick Reference

Read this section first. Each rule is concrete and imperative.

**IAM / Policy evaluation**
- DO treat policy evaluation as an ordered stack: explicit Deny → SCP/RCP ceilings → permission boundary ceiling → session policy ceiling → grant layer. An explicit Deny at any layer wins, period.
- DO remember cross-account grant logic is AND (both resource policy and identity policy must allow). Same-account grant logic is OR (either is sufficient).
- DO check the KMS key policy first when debugging KMS access denials — IAM policies have no effect unless the key policy delegates to the account root or the principal directly.
- DON'T treat permission boundaries as grants — they are ceilings; the effective permission is the intersection.
- DO use IAM Identity Center (SSO) for human access in multi-account orgs; never create long-lived IAM user credentials for humans.
- DO run IAM Access Analyzer in every region, or use an org-level analyzer; a single-region analyzer misses resources in other regions.

**Detection and response**
- DO enable GuardDuty organization-wide via delegated administrator so member accounts cannot disable it.
- DON'T auto-remediate Low-severity GuardDuty findings — false positive rate too high. Automate Medium/High only.
- DO pre-build SSM Automation runbooks for EC2 isolation and credential revocation before an incident, not during.
- DO preserve EBS snapshots before any instance termination during IR — evidence first, eradication second.
- DO use Amazon Detective to investigate GuardDuty findings rather than manually correlating CloudTrail + VPC Flow Logs.

**Encryption and data protection**
- DO verify the KMS key policy contains the account root delegation statement before relying on IAM policies for key access.
- DO use customer-managed keys (not AWS-managed keys) when you need CloudTrail audit logs of key usage or need to share the key across services/accounts.
- DO enable S3 Block Public Access at the account level — bucket-level settings can be overridden by object ACLs; account-level cannot.
- DON'T store secrets in environment variables or SSM Parameter Store standard tier when rotation is required — use Secrets Manager.
- DO test Secrets Manager rotation before production cutover — confirm the Lambda rotator has network access (VPC endpoint or internet) to both Secrets Manager and the target service.

**Infrastructure**
- DO treat security groups as stateful (return traffic is automatic) and NACLs as stateless (must explicitly allow outbound ephemeral port range 1024–65535 for return traffic).
- DO use SSM Session Manager for EC2 access; never open port 22 or 3389 to `0.0.0.0/0`.
- DO attach endpoint policies to VPC endpoints that restrict which S3 buckets are reachable through the endpoint — prevents endpoint-based exfiltration.
- DON'T rely on WAF on ALB alone when CloudFront is in front — protect at the CloudFront distribution too or an attacker can bypass WAF by hitting the ALB origin IP directly.

**Governance**
- DO put management/billing accounts in a Management OU and never run workloads there.
- DO use deny-list SCP strategy over allow-list for most OUs to avoid maintaining exhaustive action enumerations.
- DO deploy WAF policies centrally via Firewall Manager so new accounts in the target OU inherit them automatically.
- DON'T co-mingle security tooling accounts with workload accounts in the same OU — separate Security OU with tight SCPs.

---

> **Study resources** — official exam guide PDF, service documentation links, and study sequencing by domain weight: [references/study-resources.md](references/study-resources.md).

---

## Feedback protocol

Using this skill and hit a wall? If you find a claim contradicted by the live system or official docs, a missing rule that cost you a wrong attempt, or a decision this skill gave no criteria for — append an entry **in the moment** to `.skill-feedback/aws-security-specialty.md` at the project root (create it if absent):

`date | skill last-reviewed | claim or gap | what you observed instead | evidence (error text / doc URL / query output) | suggested fix`

These are harvested back into the skill via the learning loop. When the live system and this file disagree, trust the live system.

---

## Changelog

- **2026-06-09** — Conformed to 12-dimension skill standard: task-vocab description, Scope block, Uncertainty & Escalation with `[volatile — verify live]` marks, executable workflows, tool-agnostic verify steps, feedback protocol. Exam logistics relocated to references/study-resources.md.
- **2026-06-09** — Inlined 4 decision scenarios; prose compression pass.

---

_Independent educational content for upskilling AI agents. Not affiliated with, authorized by, endorsed by, or sponsored by Amazon Web Services or any certification body. All product names and trademarks — including "AWS Certified Security – Specialty" — are the property of their respective owners and are used here for identification purposes only. Content is provided as guidance only; verify against official AWS documentation and live accounts. No certification outcome is implied or guaranteed._
