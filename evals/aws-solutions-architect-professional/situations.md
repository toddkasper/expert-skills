# Eval situations — aws-solutions-architect-professional

Answer each: state the **competent action** and the **reason**. Be concise (2–4 sentences each).

1. Your company runs 40 AWS accounts under an AWS Organization. The security team wants a rule that prevents *any* IAM principal in *any* member account — including account-level administrators — from disabling AWS CloudTrail. They plan to attach an SCP with an explicit Deny to the **root** of the organization. A colleague says this will also block the management account's CloudTrail operations and is therefore risky. Who is correct, and what is the right attachment target?

2. A team architect proposes connecting 12 VPCs across 4 AWS accounts using VPC Peering. Each VPC must be able to reach every other VPC directly. She has already assigned non-overlapping CIDRs. A colleague objects that the peering count will become unmanageable and suggests an alternative. What is the flaw in the original design at scale, how many peering connections would a full mesh require, and what service should replace it?

3. You are designing a hybrid architecture where on-premises application servers need to resolve private Route 53 DNS names (e.g., `db.internal.corp`) without routing all their DNS traffic through a VPN. Your network team has provisioned a Direct Connect connection. Which Route 53 feature resolves this, what two endpoint types do you configure, and what specific gap exists if you skip the outbound direction?

4. An enterprise is migrating a business-critical order-management system. The CTO has set an RTO of 8 hours and an RPO of 1 hour. The lead architect proposes deploying a full multi-region active/active setup with DynamoDB Global Tables and multi-region ALBs. A finance reviewer flags the cost as excessive. Evaluate the proposal: is it technically correct, is it the right fit, and what DR pattern actually matches those requirements?

5. A company's Lambda function processes messages from an SQS queue and writes results to an Aurora MySQL database. During a traffic spike the Lambda function starts throttling and messages accumulate. A developer proposes increasing the Lambda reserved concurrency limit to 2,000. Identify the real bottleneck, explain what happens at Aurora when Lambda concurrency spikes, and state the correct architecture fix.

6. You are deploying a new version of a stateful e-commerce web application running on EC2 via AWS CodeDeploy. The application stores active user session data in local instance memory. The deployment lead wants to use a blue/green deployment to minimize downtime. A QA engineer warns this will drop active sessions. Who is correct, and what must you do before blue/green is safe to use here?

7. Your organization's AWS Config rule `s3-bucket-public-read-prohibited` is firing on 300 S3 buckets across 15 accounts. The security team wants automatic remediation without human approval. A colleague plans to attach an SSM Automation remediation document that calls `aws s3api put-bucket-acl --acl private` and sets Auto Remediation to "Yes." Identify the risk in applying auto-remediation at this scale without additional safeguards and name the mechanism to bound the blast radius.

8. A platform engineering team is setting up a new AWS Control Tower landing zone. They want to ensure that workload accounts cannot create EC2 instances outside of `us-east-1` and `eu-west-1`. They plan to write an IAM permission boundary and attach it to each workload account's IAM roles. Will this achieve the goal? If not, what is the correct mechanism and where should it be applied?

9. A data engineering team runs an EMR cluster that reads and writes large datasets to an S3 bucket in the same region. The monthly Cost and Usage Report shows a surprisingly large line item for `DataTransfer-Out-Bytes` from the S3 bucket. The cluster is in a private subnet. What is the most likely cause of this data transfer charge, and what is the zero-cost fix?

10. You are evaluating a migration for a 12 TB on-premises Oracle 11g database that must become an Amazon Aurora PostgreSQL database. Your network team confirms a 100 Mbps internet-uplink with sustained availability. The migration lead suggests using AWS Snowball Edge to ship the initial data load, then using AWS DMS for ongoing replication until cutover. Evaluate this plan — is Snowball Edge the right choice, is the DMS piece sound, and what prerequisite tool is missing?

11. A company has 200 EC2 instances across 3 accounts. Trusted Advisor flags 40 instances as "low utilization." Compute Optimizer also recommends downsizing those instances. Before acting on the recommendations, what must you verify in CloudWatch, and why might a "low average CPU" signal be misleading for a latency-sensitive application?

12. A startup is building a fraud-detection pipeline that ingests transaction events via Kinesis Data Streams, processes them in a Lambda function, and writes verdicts to an RDS PostgreSQL database. During a surge the engineering team notices Lambda invocations are succeeding but RDS connections are timing out. They propose scaling up the RDS instance class. Identify the actual bottleneck, explain the underlying mechanism, and describe the correct architectural fix.
