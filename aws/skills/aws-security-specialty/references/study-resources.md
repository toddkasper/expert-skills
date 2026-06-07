# Study Resources — AWS Certified Security – Specialty (SCS-C03)

> Load this file when planning a study path. The operational rules live in SKILL.md.
> All links point to free official sources unless noted. Verify links are current against
> https://aws.amazon.com/certification/certified-security-specialty/

## Official AWS Resources

- **Exam landing page:** https://aws.amazon.com/certification/certified-security-specialty/
  Includes the exam guide PDF link, scheduling links, and the official sample questions page.

- **SCS-C03 Exam Guide (PDF):** https://docs.aws.amazon.com/pdfs/aws-certification/latest/security-specialty-03/security-specialty-03.pdf
  Definitive source for domain names, weights, and task statements. Treat this as the
  coverage checklist; the skill's operational rules are what fill each task statement with
  working knowledge.

- **AWS Security Documentation hub:** https://docs.aws.amazon.com/security/
  Entry point for every security-service user guide referenced in this skill.

- **AWS Well-Architected Security Pillar whitepaper:**
  https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html
  The SEC-BP (Security Best Practice) codes cited in the operational rules trace back here.
  Focus on SEC01–SEC09 design principles and the control objectives for each pillar section.

- **AWS Security Reference Architecture (SRA):**
  https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/welcome.html
  Shows the canonical multi-account landing-zone structure (Management, Security OU, Log
  Archive, Audit accounts). Critical context for Domain 6.

- **IAM Policy Evaluation Logic (official):**
  https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_evaluation-logic.html
  The authoritative walk-through of the evaluation order: explicit deny → SCP/RCP ceiling →
  permission boundary ceiling → session policy ceiling → resource policy + identity policy
  grant (within-account OR logic; cross-account AND logic).

- **AWS Encryption Best Practices (Prescriptive Guidance):**
  https://docs.aws.amazon.com/prescriptive-guidance/latest/encryption-best-practices/welcome.html

- **AWS KMS Developer Guide — Key Policies:**
  https://docs.aws.amazon.com/kms/latest/developerguide/key-policies.html

- **Amazon Security Lake user guide:**
  https://docs.aws.amazon.com/security-lake/latest/userguide/what-is-security-lake.html

## AWS Whitepapers (free)

- AWS Security Best Practices whitepaper — search "AWS Security Best Practices" on
  https://aws.amazon.com/whitepapers/ (filter: Security, Identity & Compliance).
- DDoS Resiliency Best Practices — covers Shield + WAF deployment patterns tested in Domain 3.
- AWS KMS Best Practices — envelope encryption, key policy design, grant patterns.

## AWS re:Invent / re:Inforce sessions (free on YouTube)

Search YouTube for:
- "re:Inforce SEC301" — IAM deep dives (policy evaluation, permission boundaries, Access Analyzer)
- "re:Inforce SEC401" — incident response automation
- "re:Invent NET301" — VPC and network security architecture

## Key Service User Guides to Bookmark

The following service guides are directly tested. Read the "Security" and "Best Practices"
chapters of each:

| Service | Guide path |
|---|---|
| GuardDuty | docs.aws.amazon.com/guardduty/latest/ug/ |
| Security Hub | docs.aws.amazon.com/securityhub/latest/userguide/ |
| Detective | docs.aws.amazon.com/detective/latest/userguide/ |
| CloudTrail | docs.aws.amazon.com/awscloudtrail/latest/userguide/ |
| Config | docs.aws.amazon.com/config/latest/developerguide/ |
| IAM Access Analyzer | docs.aws.amazon.com/IAM/latest/UserGuide/what-is-access-analyzer.html |
| AWS WAF | docs.aws.amazon.com/waf/latest/developerguide/ |
| AWS Shield | docs.aws.amazon.com/waf/latest/developerguide/shield-chapter.html |
| KMS | docs.aws.amazon.com/kms/latest/developerguide/ |
| Secrets Manager | docs.aws.amazon.com/secretsmanager/latest/userguide/ |
| Macie | docs.aws.amazon.com/macie/latest/user/ |
| IAM Identity Center | docs.aws.amazon.com/singlesignon/latest/userguide/ |
| Verified Permissions | docs.aws.amazon.com/verifiedpermissions/latest/userguide/ |
| Control Tower | docs.aws.amazon.com/controltower/latest/userguide/ |
| Firewall Manager | docs.aws.amazon.com/waf/latest/developerguide/fms-chapter.html |
| Security Lake | docs.aws.amazon.com/security-lake/latest/userguide/ |
| Audit Manager | docs.aws.amazon.com/audit-manager/latest/userguide/ |
| Bedrock (GenAI security) | docs.aws.amazon.com/bedrock/latest/userguide/security.html |

## Study Sequencing (based on domain weights)

Highest return per hour of study by weight:

1. **IAM (20%)** — policy evaluation logic, permission boundaries, SCPs, Access Analyzer.
   This is now the single heaviest domain in SCS-C03. Spend extra time on cross-account
   evaluation (AND logic), RCP vs SCP differences, and Verified Permissions.

2. **Infrastructure Security (18%)** and **Data Protection (18%)** — tie; cover together.
   Key services: WAF, Shield, PrivateLink, VPC endpoints, KMS, Macie, Secrets Manager.

3. **Detection (16%)** — GuardDuty findings taxonomy, Security Hub aggregation, Security Lake.

4. **Incident Response (14%)** and **Security Foundations & Governance (14%)** — tie.
   For IR: EventBridge + Lambda containment runbooks, SSM Automation documents.
   For Governance: Organizations, Control Tower, Firewall Manager, Audit Manager.

## What Changed SCS-C02 → SCS-C03 (launched Dec 2, 2025)

- "Threat Detection and Incident Response" split into separate Detection and Incident Response
  domains. IAM jumped from 16% to 20% (now the heaviest domain). Infrastructure Security
  dropped from 20% to 18%.
- Generative AI / ML security content added (Bedrock guardrails, model access controls).
- Amazon Security Lake with OCSF normalization added to detection/logging scope.
- Amazon Verified Permissions added to IAM scope.
- New question formats: ordering and matching (not only multiple-choice / multiple-response).
- Approximately 15 new services added to scope; some foundational topics removed.

---

_Independent educational content. Not affiliated with or endorsed by Amazon Web Services._
