# Cost Optimization — AWS Solutions Architect Professional

> Loaded on demand from SKILL.md §3.4 (Cost Optimization for Existing Workloads). Load this file when running a cost optimization engagement on an existing AWS environment.

## Step-by-Step Cost Optimization Workflow

### 1. Identify Unused and Idle Resources

- **Unattached EBS volumes:** `aws ec2 describe-volumes --filters Name=status,Values=available --query 'Volumes[*].{ID:VolumeId,Size:Size,AZ:AvailabilityZone}'` — delete or snapshot-then-delete.
- **Idle EC2 instances:** Trusted Advisor "Low Utilization Amazon EC2 Instances" (CPU <10% + network <5 MB/day over 14 days). Cross-reference with Compute Optimizer recommendations.
- **Idle load balancers:** `aws elbv2 describe-load-balancers` — check CloudWatch `RequestCount` metric; ELBs with near-zero traffic for 30+ days are candidates for deletion.
- **Unassociated Elastic IPs:** `aws ec2 describe-addresses --filters Name=association-id,Values=''` — unassociated EIPs cost $0.005/hr `[volatile — verify live]`.

### 2. Close the Savings Plan Gap

1. Open **Cost Explorer → Savings Plans → Coverage report** — identify the On-Demand spend baseline that is consistent across the past 30 days.
2. Purchase **Compute Savings Plans** (not EC2 Instance Savings Plans) for flexibility: covers EC2 (any family/region/OS), Fargate, and Lambda under a single commitment.
3. 1-year no-upfront is the minimum commitment for most teams; 3-year all-upfront gives the highest discount (~66%) `[volatile — verify live]`.
4. **Do not** purchase Reserved Instances for new workloads unless Savings Plans do not cover the service (e.g., RDS, ElastiCache — those require separate RIs).

**Verify:** Cost Explorer coverage report should show ≥80% coverage for steady-state compute within 48 hours of purchase.

### 3. Reduce S3 Storage Costs

- Enable **S3 Storage Lens** at the organization level for a unified view of bucket-level storage and access patterns.
- Apply **lifecycle policies** to transition infrequently accessed objects: Standard → Standard-IA (after 30 days) → Glacier Instant Retrieval (after 90 days) → Glacier Deep Archive (after 180 days).
- Enable **Intelligent-Tiering** for buckets with unknown or variable access patterns — AWS automatically moves objects between tiers; monitoring fee applies per object `[volatile — verify live]`.
- Delete **expired incomplete multipart uploads** via a lifecycle rule (`AbortIncompleteMultipartUpload` after N days) — these accumulate silently and are not visible in bucket size metrics.

### 4. Eliminate Unnecessary Data Transfer Costs

- **CUR (Cost and Usage Reports):** enable and export to S3; query with Athena. Filter `lineItem/Operation` = `DataTransfer-Out-Bytes` and `lineItem/UsageType` containing `NAT` to find NAT Gateway egress costs.
- Replace NAT Gateway egress for S3 and DynamoDB with **free Gateway endpoints** — add the endpoint to the VPC and update private subnet route tables.
- For EC2 ↔ S3 in the same region (but different AZ than the NAT Gateway), using the Gateway endpoint eliminates both the NAT Gateway charge and the inter-AZ data transfer charge.
- Evaluate **CloudFront** for frequently accessed S3 objects — CloudFront's origin-fetch from S3 is free (no S3 egress charge), and CloudFront per-GB pricing is typically lower than direct S3-to-internet egress `[volatile — verify live]`.

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
