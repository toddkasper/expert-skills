---
name: aws-security-specialty
description: Operational playbook for AWS security engineering at the Specialty level (SCS-C03) — threat detection, incident response, security logging and monitoring, infrastructure and network security, identity and access management, data protection and encryption, and security governance in multi-account AWS environments. Use when designing or reviewing AWS security controls, IAM policy evaluation, detection/response automation, KMS encryption strategy, or compliance guardrails. Reflects the SCS-C03 blueprint (launched December 2, 2025).
metadata:
  credential: AWS Certified Security – Specialty
  exam-code: SCS-C03
  domain: aws
  type: certification-playbook
  blueprint: SCS-C03 (December 2025)
---

# AWS Certified Security – Specialty (SCS-C03) — Skills Reference

## Overview

The AWS Certified Security – Specialty credential (exam code SCS-C03, launched December 2, 2025) validates specialized competence in designing, implementing, and operating security controls across AWS environments. It targets practitioners with several years of hands-on AWS security experience who configure threat detection pipelines, write and audit IAM policies, architect network defenses, design encryption strategies, and build multi-account governance guardrails.

This file is an **operational playbook, not an exam outline**. Each section states the rules an agent must apply when doing AWS security work: the decision criteria, concrete limits, anti-patterns to catch in review, and verification steps. The guiding principle throughout: **verify against the live account — never assume from documentation alone** because effective permissions result from combining multiple policy types, and a single missing allow or extra deny changes the outcome.

> **Study resources** (official guides, service docs, study sequencing, SCS-C02→SCS-C03 changes) live in [references/study-resources.md](references/study-resources.md). Load that file when planning a study path.

---

## Exam Details

| Field | Value |
|---|---|
| Exam code | SCS-C03 |
| Questions | 65 total (mix of scored and unscored pretest items — AWS does not publish the scored/unscored split for this exam) |
| Question formats | Multiple choice, multiple response, ordering, matching |
| Time limit | 170 minutes |
| Passing score | 750 / 1000 (scaled) |
| Cost | $300 USD |
| Prerequisites | None required; AWS recommends 5+ years IT security experience and 2+ years securing AWS workloads |
| Format | Pearson VUE — online proctored or test center |
| Recertification | Valid 3 years; recertify via current exam or an approved higher-level exam |

Blueprint domains and weights (SCS-C03, source: official exam guide):
- Domain 1 — Detection — **16%**
- Domain 2 — Incident Response — **14%**
- Domain 3 — Infrastructure Security — **18%**
- Domain 4 — Identity and Access Management — **20%** ← heaviest domain
- Domain 5 — Data Protection — **18%**
- Domain 6 — Security Foundations and Governance — **14%**

> Blueprint weights are subject to change. Verify against the official exam guide PDF linked in [references/study-resources.md](references/study-resources.md).

---

## 1. Identity and Access Management (20%)

IAM is the heaviest domain in SCS-C03. Errors here compound: a misconfigured policy evaluation or a boundary gap affects everything downstream.

### Policy evaluation order — the evaluation stack

Every authorization decision passes through this stack in order. An **explicit Deny at any layer is an immediate, unconditional halt** — no Allow anywhere overrides it.

1. **Explicit Deny** (any policy type) → AccessDenied, full stop.
2. **SCPs (Service Control Policies)** — ceiling on what principals *in that OU/account* may do. SCPs do not grant; they cap. An Allow in an SCP is a maximum; the account still needs an identity-policy Allow.
3. **RCPs (Resource Control Policies)** — ceiling on what *any* principal may do to resources in the OU/account, including external principals. Introduced in late 2023; tested in SCS-C03.
4. **Permission Boundaries** — ceiling on what *an IAM principal's identity policies* may grant. Does not cap resource-policy grants made directly to the role.
5. **Session Policies** — ceiling applied at `AssumeRole` / `GetFederationToken` time; caps the session below the role's full permissions.
6. **Resource Policies + Identity Policies** — the grant layer. Evaluation logic differs by account boundary:
   - **Same account:** resource policy OR identity policy may grant (either is sufficient).
   - **Cross-account:** resource policy AND identity policy must both grant (both required).

**KMS is a special case:** the key policy is the *primary* access control. Unless the key policy explicitly delegates to IAM (`"Principal": {"AWS": "arn:aws:iam::<account>:root"}`), IAM policies granting `kms:Decrypt` etc. have no effect. Always verify the key policy first before debugging IAM-side KMS denials.

### Permission boundaries

A permission boundary caps the effective permissions of a principal but does not grant anything itself. The principal's effective permissions are the **intersection** of what the identity policy allows and what the boundary permits. Attaching an `AdministratorAccess` policy to a role that has a narrow boundary yields only the narrow boundary's scope. Common trap: a developer can't create an S3 bucket because the boundary lacks `s3:CreateBucket` even though the identity policy allows it.

### Least privilege tools

- **IAM Access Analyzer** continuously scans resource-based policies for unintended external access (cross-account or public). It is **region-scoped** — create an analyzer in every region where you have resources, or use the organization-level analyzer to cover all accounts in the org. Access Analyzer also generates policy suggestions from CloudTrail activity history.
- **IAM Access Advisor** shows last-accessed timestamps for services/actions per principal — the data source for pruning unused permissions.
- **Amazon Verified Permissions** (added in SCS-C03 scope) — fine-grained authorization for applications using Cedar policy language, separate from IAM; useful when IAM is too coarse for per-resource app-level authorization.

### Federation and IAM Identity Center

- **IAM Identity Center (SSO)** is the recommended approach for human access across multiple accounts — one place to manage permission sets (collections of inline/managed policies), assigned to accounts, with automatic temporary-credential issuance. Never create long-lived IAM users for human access in a multi-account org.
- **SAML 2.0 federation** uses a trust between your IdP and AWS, resulting in `AssumeRoleWithSAML` temporary credentials. The SAML assertion's attributes map to IAM role conditions.
- **OIDC federation** (used by GitHub Actions, EKS pod identity, etc.) — the IAM role's trust policy allows the OIDC provider as a principal and uses `Condition` to scope which subjects can assume the role.

**Red flags:** identity-policy Allow to a KMS key with no matching key policy delegation; cross-account S3 access configured in only the bucket policy with no role Allow (or vice versa); a permission boundary treated as a grant; a single organization-region analyzer expected to cover resources in all regions; long-lived IAM user credentials for human access in a multi-account org.

**Verify:** Use the IAM Policy Simulator for a specific principal + action + resource to see which policy type is denying; check Access Analyzer findings for unintended external access; review CloudTrail `AssumeRole` and `GetCallerIdentity` calls to confirm which role sessions are active.

---

## 2. Infrastructure Security (18%)

### Security groups vs NACLs — pick the right tool

| Dimension | Security Groups | NACLs |
|---|---|---|
| Scope | Per ENI (instance level) | Per subnet |
| State | Stateful — return traffic automatically allowed | Stateless — must allow inbound AND outbound explicitly |
| Default | Deny all inbound; allow all outbound | Allow all (default NACL) |
| Rules | Allow only; no deny rules | Allow and deny rules; evaluated lowest-number first |
| Best for | Application-layer allow rules; referencing other SGs for dynamic scaling | Blocking specific IPs/CIDR ranges; broad subnet-level blocks |

**NACLs are stateless** — if you allow inbound TCP 443, you must also allow outbound ephemeral ports (1024–65535) for the response or connections silently stall. This is the most common NACL debugging trap.

Reference security groups by ID (not CIDR) when the set of allowed instances changes dynamically — the rule tracks membership, not IP addresses.

### VPC endpoints and PrivateLink

- **Gateway endpoints** (S3, DynamoDB only) — free, added to route tables; traffic stays within the AWS network.
- **Interface endpoints** (PrivateLink) — deploy elastic network interfaces into subnets; add private DNS so existing service calls resolve to private IPs. Required for services other than S3/DynamoDB.
- Endpoint policies are resource-based policies attached to the endpoint that restrict *which resources* in the service the endpoint can reach — use them to prevent exfiltration through an endpoint (e.g. block all S3 buckets except your own).

### WAF and Shield

- **WAF** operates at Layer 7 on CloudFront, ALB, API Gateway, AppSync, and Cognito user pools. Rules evaluate HTTP request attributes (headers, URI, body, IP). Managed rule groups (AWS and third-party Marketplace) cover OWASP Top 10, bot control, and IP reputation lists.
- **Shield Standard** — automatic, no-cost DDoS protection at Layers 3 and 4 for all AWS resources.
- **Shield Advanced** — paid; adds Layer 7 DDoS detection, proactive engagement from the Shield Response Team (SRT), cost protection, and visibility into attack history. Required if you want SRT assistance or layer-7 DDoS mitigation for high-traffic apps.

### EC2 host security

- **AWS Systems Manager (SSM) Session Manager** — browser or CLI shell access to instances *without* opening port 22/3389 or managing SSH keys. The instance needs the SSM Agent and an instance profile with `AmazonSSMManagedInstanceCore`. No bastion hosts required; all session activity is logged to CloudTrail.
- **Amazon Inspector** — continuous vulnerability assessment for EC2 (OS/package CVEs), Lambda functions, and container images in ECR. Findings flow to Security Hub.
- Never maintain standing SSH/RDP ingress rules. Security groups with `0.0.0.0/0` on ports 22 or 3389 are always a red flag in review.

**Red flags:** stateless return-traffic not allowed in NACL; VPC endpoint with no endpoint policy allowing exfiltration to arbitrary S3 buckets; WAF deployed only on ALB but not on CloudFront (origin bypass possible); Shield Advanced not enrolled for production-critical internet-facing workloads; SSH/RDP open to `0.0.0.0/0`; missing SSM Agent instance profile for EC2 fleet.

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

### Secrets Manager

Secrets Manager stores secrets encrypted with a CMK (or the aws/secretsmanager managed key). Automatic rotation uses a Lambda function; the function must have network access to both Secrets Manager and the target service (use interface endpoints to avoid internet exposure). Rotation stages: `AWSPENDING` (new secret version created), `AWSCURRENT` (promoted after rotation confirmed), `AWSPREVIOUS` (retained for graceful cutover). Applications that cache secrets must handle the `AWSPREVIOUS` → `AWSCURRENT` transition without errors.

### Amazon Macie

Macie scans S3 buckets using machine learning and pattern matching to find sensitive data (PII, credentials, financial data). Macie continuously evaluates bucket-level preventive controls (encryption status, public access status, cross-account sharing) and generates findings. Findings flow to Security Hub. Use Macie organization-wide via AWS Organizations to cover all accounts centrally.

**Red flags:** CMK with no key policy root delegation (IAM policies ineffective); SSE-S3 used where audit logs of key usage are required (use SSE-KMS); S3 Block Public Access disabled at the account level; secrets stored in environment variables or SSM Parameter Store standard tier instead of Secrets Manager when rotation is required; multi-region replication of SSE-KMS objects without configuring destination key policy.

---

## 4. Detection (16%)

### GuardDuty — the threat detection anchor

GuardDuty is a regional service that analyzes CloudTrail management events, CloudTrail S3 data events, VPC Flow Logs, DNS query logs, EKS audit logs, Lambda network activity, and RDS login activity without requiring you to enable or manage those log sources yourself. Enable GuardDuty in every region and every account; use the organization delegated-administrator pattern so member accounts cannot disable it.

Finding severity tiers: **Low** (informational, rarely auto-remediate), **Medium** (investigate; auto-notify), **High** (auto-contain). Do not auto-isolate for Low findings — false positive rate is too high.

Key finding categories and containment responses:

| Finding family | Canonical high-severity example | Auto-remediation action |
|---|---|---|
| Compromised EC2 | `UnauthorizedAccess:EC2/MaliciousIPCaller` | Quarantine SG (deny all), snapshot EBS for forensics, notify |
| Credential exfiltration | `UnauthorizedAccess:IAMUser/InstanceCredentialExfiltration` | Revoke active sessions (`aws iam delete-role-policy` / `PutUserPolicy` explicit deny), notify |
| S3 data exposure | `Policy:S3/BucketPublicAccessGranted` | Re-enable Block Public Access, quarantine bucket policy |
| Malware | `Execution:EC2/MaliciousFile` | Isolate instance, initiate GuardDuty Malware Protection scan |

### Security Hub — the aggregation layer

Security Hub aggregates GuardDuty, Inspector, Macie, IAM Access Analyzer, and Firewall Manager findings into a normalized format (AWS Security Finding Format, ASFF). It also runs its own checks against the CIS AWS Benchmarks, AWS Foundational Security Best Practices, and PCI DSS standards. Use the organization delegated-administrator so findings from all member accounts flow to a central security account.

### Amazon Security Lake (OCSF)

Security Lake creates a purpose-built S3 data lake in a Log Archive account, normalizing log data to the **Open Cybersecurity Schema Framework (OCSF)** in Apache Parquet format. Sources include CloudTrail management and data events, VPC Flow Logs, Route 53 resolver query logs, WAF logs, EKS audit logs, and Security Hub findings. Use Security Lake when you need long-term retention of normalized security telemetry for SIEM/analytics tools (Athena, OpenSearch, partner SIEMs).

### Amazon Detective

Detective uses graph analysis (behavior graph) to help investigate the scope and root cause of security findings. When a GuardDuty finding triggers, Detective shows the entities involved (principals, IPs, instances) and their interaction timeline — without manually joining CloudTrail, VPC Flow Logs, and GuardDuty data. Detective is a complement to GuardDuty/Security Hub, not a replacement.

**Automated detection pipeline pattern:**
GuardDuty → EventBridge rule (on finding severity) → Lambda / Step Functions / SSM Automation → containment action + SNS notification + Security Hub update.

**Red flags:** GuardDuty enabled only in the account's home region; member accounts allowed to disable GuardDuty; Security Hub without a delegated administrator (findings siloed per account); routing all GuardDuty finding severities to the same auto-remediation Lambda (low severity findings do not warrant auto-isolation); skipping Detective and attempting to manually correlate CloudTrail + VPC Flow Logs for a compromise investigation.

---

## 5. Incident Response (14%)

### Containment playbooks

Incident response on AWS follows the same Prepare → Detect → Contain → Investigate → Eradicate → Recover pattern, but AWS provides automation primitives that reduce MTTC (mean time to containment) from hours to minutes when pre-built.

**EC2 compromise:**
1. Isolate: replace instance's security groups with a forensic/quarantine SG (allow only security-team bastion or SSM endpoint, block all else). This is faster and more surgical than terminating.
2. Preserve evidence: create EBS snapshot before any remediation.
3. Investigate: use SSM Session Manager to access the isolated instance without re-opening ports; enable SSM memory capture if needed.
4. Tag the instance `{"IncidentStatus": "Quarantined", "Ticket": "<ID>"}` for traceability.

**Credential compromise (`InstanceCredentialExfiltration` or leaked key):**
1. Attach an explicit-deny IAM policy to the role/user immediately (fastest revocation path — effective within seconds; does not require deactivating the key or invalidating all sessions first).
2. Rotate or deactivate the actual credential (access key deactivation, `sts:RevokeSession` for role sessions).
3. Review CloudTrail `GetCallerIdentity`, `AssumeRole`, and API calls in the affected time window.
4. Check for resources created or exfiltrated during the exposure window.

**SSM Automation documents (runbooks):** pre-built AWS-managed runbooks exist for common containment actions (e.g. `AWSSupport-TerminateIPMonitoringFromVPC`, `AWS-IsolateEC2Instance`). Build and version-control custom runbooks for org-specific scenarios. Run runbooks with an assumed role that has only the permissions needed for that action (least-privilege execution).

**Forensic accounts:** route all forensic work (EBS snapshots, memory dumps, log analysis) to a dedicated forensic account isolated from production. The forensic account should have no internet egress, VPC-endpoint-only access to S3/CloudTrail/Athena, and strict role-based access for the IR team.

**Red flags:** no pre-built runbooks before an incident; terminating a compromised instance before preserving forensic evidence; using the account root credentials for IR (always use a break-glass IAM role with MFA and CloudTrail monitoring); no CloudTrail multi-region organization trail capturing data events in the affected service.

---

## 6. Security Foundations and Governance (14%)

### Multi-account structure

The canonical landing zone structure (per AWS SRA):
- **Management (root) account** — AWS Organizations, billing, Control Tower. No workloads here.
- **Security OU** → **Log Archive account** (centralized CloudTrail, VPC Flow Log, Security Lake storage) + **Audit/Security Tooling account** (GuardDuty delegated admin, Security Hub delegated admin, Firewall Manager).
- **Workload OUs** — Sandbox, Dev, Staging, Prod; each with appropriate SCPs.

### SCPs and RCPs

- **SCPs** cap what IAM principals in an OU/account may do. They do not grant anything; they set a ceiling. A Deny SCP blocks an action even if the principal has `AdministratorAccess`.
- **RCPs (Resource Control Policies)** cap what any principal — including cross-account and service principals — may do to resources in the OU/account. Use RCPs to enforce encryption at rest or block non-TLS access org-wide regardless of individual bucket policies.
- Prefer **deny-list SCP strategy** (start with `FullAWSAccess`, add targeted Deny SCPs) over allow-list for most accounts; allow-list requires enumerating every allowed action which becomes unmanageable quickly.

### Control Tower guardrails

Control Tower enforces **preventive guardrails** (implemented as SCPs) and **detective guardrails** (implemented as Config rules). Examples of preventive: disallow disabling CloudTrail, disallow leaving GuardDuty. Detective guardrails alert but do not block; use them for compliance visibility before enforcing preventive controls.

### AWS Config and conformance packs

Config records every resource configuration change and evaluates it against rules (managed or custom Lambda). Conformance packs are collections of Config rules deployed via StackSets across the org. Use conformance packs for CIS, NIST, or PCI compliance baselines. Config aggregators roll up compliance status from all accounts into a central delegated-admin account.

### Firewall Manager

Firewall Manager lets you centrally deploy WAF rules, Shield Advanced protections, Security Groups (audit mode or enforce mode), and Network Firewall policies across accounts in an org. Requires AWS Organizations and Security Hub enabled. Policies propagate to new accounts automatically as they join a target OU — this is the key advantage over per-account WAF configuration.

**Red flags:** SCPs applied at the root OU without exception mechanisms for break-glass accounts; Config rules deployed per-account manually instead of via conformance packs/StackSets; Firewall Manager WAF policies not covering all internet-facing ALBs; Log Archive account with write access granted to workload accounts (should be write-once via resource policies); no dedicated Security OU isolation (security tooling co-mingled with workloads).

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

_Independent educational content for upskilling AI agents. Not affiliated with, authorized by, endorsed by, or sponsored by Amazon Web Services or any certification body. All product names and trademarks — including "AWS Certified Security – Specialty" — are the property of their respective owners and are used here for identification purposes only. Content is provided as guidance only; verify against official AWS documentation and live accounts. No certification outcome is implied or guaranteed._
