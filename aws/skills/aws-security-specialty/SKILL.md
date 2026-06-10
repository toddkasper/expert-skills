---
name: aws-security-specialty
description: AWS security engineering — threat detection (GuardDuty, Security Hub, Detective, Security Lake), incident response and containment, IAM policy evaluation and permission boundaries, infrastructure/network security (security groups, NACLs, WAF, Shield, PrivateLink), data protection and KMS encryption strategy, Secrets Manager, Macie, and multi-account governance (SCPs, Control Tower, Config, Firewall Manager). Use when designing or reviewing AWS security controls, detection/response automation, or compliance guardrails. Not pipeline/IaC delivery (see aws-devops-engineer-professional) or broad architecture trade-offs (see aws-solutions-architect-professional). Scoped and benchmarked by the AWS Security – Specialty (SCS-C03) blueprint.
metadata:
  credential: AWS Certified Security – Specialty
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

**This file is an operational playbook, not an exam outline.** Each section states the rules an agent must apply when doing AWS security work: decision criteria, concrete limits, anti-patterns, and verification steps. Guiding principle: **verify against the live account** — effective permissions result from combining multiple policy types, and a single missing allow or extra deny changes the outcome. Benchmarked against the AWS Security – Specialty (SCS-C03, December 2025) blueprint.

> **Load this skill when…** designing or reviewing IAM policies, permission boundaries, SCPs, or RCPs; configuring threat detection (GuardDuty, Security Hub, Detective, Security Lake); implementing KMS encryption strategy or Secrets Manager rotation; auditing network defenses (WAF, Shield, PrivateLink, NACLs) or building incident-response and containment automation.
> **Not this skill:** pipeline/IaC delivery or observability stacks → see `aws-devops-engineer-professional`; enterprise architecture trade-offs or cross-account network design → see `aws-solutions-architect-professional`.

> **Study resources, service docs, SCS-C02→SCS-C03 changes, and credential logistics:** [references/study-resources.md](references/study-resources.md).

> **Verify steps assume nothing about your tooling** — use your project's MCP/automation, the AWS CLI (`aws`) or CloudShell, or the AWS Console, in that order of preference.

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

- **IAM Identity Center (SSO):** recommended for human access across accounts — permission sets assigned to accounts, automatic temporary credentials. Never long-lived IAM user credentials for humans in a multi-account org.
- **SAML 2.0 federation:** `AssumeRoleWithSAML`; SAML assertion attributes map to IAM role conditions.
- **OIDC federation:** role trust policy allows OIDC provider principal; `Condition` scopes which subjects can assume the role.

**Red flags:** identity-policy Allow to KMS key with no key policy delegation; cross-account S3 with only one side configured; permission boundary treated as a grant; single-region analyzer expected to cover all regions; long-lived IAM user credentials for humans.

**Verify:** IAM Policy Simulator for specific principal + action + resource; Access Analyzer findings; CloudTrail `AssumeRole` and `GetCallerIdentity` calls.

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

**Envelope encryption** is the universal pattern: KMS generates a data key; the data key encrypts the payload; only the encrypted data key and ciphertext are stored. The plaintext data key is never persisted. `GenerateDataKey` → encrypt locally → discard plaintext key. `Decrypt` on the stored ciphertext calls KMS again to get the plaintext data key for decryption.

**Key policy primacy for KMS:** if the key policy does not contain `"Principal": {"AWS": "arn:aws:iam::<account-id>:root"}`, no IAM policy in the account can grant access to the key. Every CMK must have a key policy that names at least one principal (typically the account root delegation statement); IAM policies can then add or restrict beyond that floor.

### S3 data protection

- **Block Public Access** — four settings, configurable at account level or per-bucket. The account-level settings take effect regardless of bucket or object ACLs; always enable at the account level to prevent any bucket in the account from becoming publicly accessible.
- **Bucket policies with TLS enforcement:** add a `Deny` statement with condition `"aws:SecureTransport": "false"` to reject unencrypted requests.
- **Object lock** (WORM) — `Governance` mode allows override by privileged users; `Compliance` mode is irrevocable for the retention period even by root. Use `Compliance` for regulated retention requirements.
- **Replication and encryption:** SSE-KMS encrypted objects replicate only if the destination bucket's key policy allows the replication role to use the destination key.

### Secrets Manager and Macie

**Secrets Manager:** CMK-encrypted; auto-rotation via Lambda (must have network access to Secrets Manager + target service via interface endpoints). Rotation stages: `AWSPENDING` (new version) → `AWSCURRENT` (promoted) → `AWSPREVIOUS` (retained for graceful cutover). Cached-secret apps must handle the `AWSPREVIOUS` → `AWSCURRENT` transition.

**Macie:** ML+pattern scanning for PII/credentials/financial data in S3. Continuous monitoring evaluates bucket-level preventive controls (encryption, public access, cross-account sharing); findings flow to Security Hub. Deploy org-wide via Organizations.

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
- **Security Lake:** purpose-built S3 data lake normalizing sources (CloudTrail, VPC Flow Logs, Route 53, WAF, EKS, Security Hub findings) to OCSF/Parquet. Use for long-term SIEM/analytics (Athena, OpenSearch, partner SIEMs).
- **Detective:** graph-based investigation (behavior graph) of GuardDuty findings — shows entity interaction timelines without manually joining CloudTrail + VPC Flow Logs. Complement to GuardDuty/Security Hub, not a replacement.

**Pipeline:** GuardDuty → EventBridge (on severity) → Lambda / Step Functions / SSM Automation → containment + SNS + Security Hub update.

**Red flags:** GuardDuty not org-wide; member accounts can disable GuardDuty; Security Hub without delegated admin; all finding severities routed to the same auto-remediation Lambda (low severity = high false-positive rate); manual CloudTrail + Flow Log correlation instead of Detective.

---

## 5. Incident Response (14%)

### Containment playbooks

**EC2 compromise (in order):**
1. Isolate: replace security groups with a forensic/quarantine SG (allow only SSM endpoint, block all else) — faster and more surgical than terminating.
2. Preserve: create EBS snapshot before any remediation.
3. Investigate: access via SSM Session Manager (no new open ports).
4. Tag the instance `{"IncidentStatus":"Quarantined","Ticket":"<ID>"}` for traceability.

**Credential compromise (instance role or leaked key):**
1. Attach an explicit-deny inline IAM policy immediately — effective within seconds without disrupting the instance's SSM access.
2. Rotate or deactivate the credential; use `aws iam delete-role-policy` or `PutUserPolicy` explicit deny.
3. CloudTrail: review `GetCallerIdentity`, `AssumeRole`, and all API calls in the exposure window.
4. Check for resources created or data exfiltrated during the window.

**SSM Automation runbooks:** pre-build and version-control for EC2 isolation, credential revocation, and restore-from-backup. Use managed runbooks (`AWS-IsolateEC2Instance`) where available. Run with a least-privilege assumed role; add Approval steps for destructive actions.

**Forensic accounts:** isolate all forensic work (EBS snapshots, memory, log analysis) in a dedicated forensic account — no internet egress, VPC-endpoint-only access to S3/CloudTrail/Athena, strict role-based access.

**Red flags:** no pre-built runbooks; terminating an instance before EBS snapshot; using root credentials for IR; no org-level multi-region CloudTrail capturing data events.

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

- **Config** records configuration changes and evaluates rules (managed or custom Lambda). Config aggregators roll up compliance to a central delegated-admin account.
- **Conformance packs** (Config rules via StackSets) for CIS, NIST, PCI baselines — deploy org-wide, don't configure per-account manually.
- **Firewall Manager** centrally deploys WAF rules, Shield Advanced, Security Groups (audit/enforce mode), and Network Firewall policies. Policies propagate to new accounts as they join a target OU — the key advantage over per-account WAF config. Requires Organizations + Security Hub.

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

Further scenarios (IAM Access Analyzer region scope, S3 Object Lock Compliance vs Governance, permission boundary gap, EC2 credential exfiltration containment, Macie discovery job vs continuous monitoring): [references/scenarios.md](references/scenarios.md).

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

- **2026-06-09** — Conformed to the 12-dimension skill standard: task-vocab description + Scope block, Uncertainty & Escalation guidance with inline `[volatile — verify live]` marks, executable workflows, tool-agnostic verify steps, and the feedback protocol above. Exam logistics relocated to references/study-resources.md; `last-reviewed` set to 2026-06-09.

---

_Independent educational content for upskilling AI agents. Not affiliated with, authorized by, endorsed by, or sponsored by Amazon Web Services or any certification body. All product names and trademarks — including "AWS Certified Security – Specialty" — are the property of their respective owners and are used here for identification purposes only. Content is provided as guidance only; verify against official AWS documentation and live accounts. No certification outcome is implied or guaranteed._
