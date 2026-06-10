# Decision Scenarios — AWS Solutions Architect Professional

Five additional judgment scenarios. The inline scenario in SKILL.md covers Transit Gateway vs VPC Peering for hub-and-spoke; these cover complementary high-lift judgment areas.

---

**Scenario 2 — Direct Connect encryption gap**

> **Situation:** An enterprise migrates a payment-processing application to AWS over a dedicated 10 Gbps AWS Direct Connect connection. The network team provisions the DX connection and confirms link-state is up. The security team signs off on the architecture because "Direct Connect is a private connection." The compliance team later flags the design: traffic traversing the DX link does not meet the PCI-DSS requirement for encryption in transit.

> **Competent move:** AWS Direct Connect is a dedicated Layer 2 circuit — it is private in the sense that it bypasses the public internet, but it is **not encrypted** in transit by default. For PCI-DSS and similar mandates that require encryption of data in transit, run a Site-to-Site VPN *over* the Direct Connect connection (a DX-backed VPN). This gives the dedicated, low-latency path of DX plus IPsec encryption. Alternatively, use MACsec (available on dedicated DX connections at 1/10/100 Gbps) for Layer 2 encryption at the DX port level — check that the DX location and partner support MACsec before committing.

> **Tempting-but-wrong:** Treating a private/dedicated connection as equivalent to an encrypted connection and skipping the VPN overlay. "Private" means no shared internet path; it does not mean the signal is encrypted. An insider at the colocation facility or a DX partner router compromise would expose cleartext traffic.

> **Verify:** `aws directconnect describe-connections --connection-id <id> --query 'connections[0].encryptionMode'` — on a plain DX connection this returns `no_encrypt`; with MACsec it returns `must_encrypt` or `should_encrypt`. For VPN-over-DX: `aws ec2 describe-vpn-connections --query 'VpnConnections[?State==\`available\`].VgwTelemetry'` to confirm both VPN tunnels are UP.

---

**Scenario 3 — Lambda concurrency exhaustion attacking Aurora connection pool**

> **Situation:** A Lambda function processes events from an SQS queue and writes results to an Aurora MySQL database. During a Black Friday traffic spike, Lambda scales to 800 concurrent executions. The Aurora `db.r6g.2xlarge` instance (max_connections ≈ 900) immediately hits connection exhaustion: `Too many connections` errors appear in Lambda logs, and Aurora CPU spikes to 100%. An engineer proposes increasing Lambda reserved concurrency to 200 as a "throttle." Another proposes upgrading Aurora to `db.r6g.4xlarge`.

> **Competent move:** The root cause is that each Lambda invocation opens a new Aurora connection (Lambda's execution environment does not persist connections between invocations when cold-started). At 800 concurrent Lambdas, each holding a connection, Aurora's connection limit is exhausted. The correct architectural fix is **Amazon RDS Proxy**: RDS Proxy maintains a persistent connection pool to Aurora and multiplexes many Lambda connections through far fewer backend connections. This breaks the linear scaling relationship between Lambda concurrency and DB connections. Reducing Lambda reserved concurrency to 200 trades a database problem for a queue backlog problem. Upgrading Aurora to a larger instance raises the ceiling but does not eliminate the underlying pooling problem and adds cost.

> **Tempting-but-wrong:** Raising the Aurora instance class. A larger instance has more max_connections, but at full Lambda scale the problem recurs — Aurora instance sizing is not a substitute for connection pooling. RDS Proxy is the architectural fix regardless of instance size.

> **Verify:** `aws rds describe-db-clusters --db-cluster-identifier <id> --query 'DBClusters[0].Endpoint'` to confirm connectivity; `aws rds describe-db-proxies` to confirm RDS Proxy is deployed and associated with the cluster; in CloudWatch, watch the `DatabaseConnections` metric on the Aurora cluster — with RDS Proxy it should plateau well below `max_connections` even as Lambda concurrency scales.

---

**Scenario 4 — Snow family vs DataSync: which to use for a 14 TB migration**

> **Situation:** A company needs to migrate 14 TB of on-premises NFS data to Amazon S3 before a datacenter decommission. The network team reports a 500 Mbps internet uplink with typical sustained throughput of 300 Mbps. The migration lead immediately orders a Snowball Edge device, reasoning "14 TB is a lot of data." The project timeline allows 3 weeks for the migration.

> **Competent move:** At 300 Mbps sustained, 14 TB transfers online in approximately 14 TB × 8 bits/byte ÷ 300 Mbps ≈ 374,000 seconds ≈ 4.3 days — well within the 3-week window. Snowball Edge has a minimum 10-business-day shipping + return cycle; for 14 TB with a healthy internet link it is slower and adds cost (device rental + shipping). Use **AWS DataSync** for an online transfer: install the DataSync agent on-premises, configure an NFS location, and schedule a full sync followed by an incremental sync near cutover. The 10 TB–1 Gbps rule of thumb for choosing Snow family means Snow is appropriate when online transfer would take weeks or months (>10 TB and <10 Mbps effective throughput) — not when the link is 300+ Mbps.

> **Tempting-but-wrong:** Defaulting to Snowball Edge because the dataset "sounds large." The Snow family is the right tool when network bandwidth makes online transfer impractical (weeks of transfer time). 14 TB at 300 Mbps is comfortably online. Ordering Snowball adds shipping delay and device rental cost unnecessarily.

> **Verify:** Before committing, use the AWS DataSync console bandwidth calculator or estimate transfer time manually (dataset size ÷ available throughput). After DataSync starts: `aws datasync list-task-executions --task-arn <arn>` and `describe-task-execution` to monitor bytes transferred and estimated time remaining.

---

**Scenario 5 — Single NAT Gateway SPOF in a multi-AZ architecture**

> **Situation:** A team deploys a production application across three AZs: `us-east-1a`, `us-east-1b`, and `us-east-1c`. They create one NAT Gateway in `us-east-1a` and add a route to it in all three private subnet route tables. A reliability review flags this. The architect responds: "NAT Gateway is a managed service — AWS guarantees its availability, so one is fine."

> **Competent move:** NAT Gateways are highly available *within* a single AZ — AWS does not guarantee that a NAT Gateway in AZ-A survives an AZ-A failure. If AZ-A experiences an outage, instances in AZ-B and AZ-C lose outbound internet access because their route tables point to the NAT Gateway in AZ-A. The correct design is **one NAT Gateway per AZ**, with each private subnet's route table pointing to the NAT Gateway in its own AZ. This also eliminates cross-AZ data transfer charges (private subnet → NAT Gateway in another AZ → internet generates inter-AZ transfer fees).

> **Tempting-but-wrong:** Treating "managed service" as a synonym for "region-scoped HA." Many AWS managed services are AZ-scoped by design (NAT Gateway, EFS mount targets, individual ALB nodes). The architect's reasoning would be valid for a service like S3 (which is region-scoped), but not for AZ-local resources like NAT Gateways.

> **Verify:** `aws ec2 describe-nat-gateways --query 'NatGateways[*].{ID:NatGatewayId,AZ:SubnetId,State:State}'` — map each NAT Gateway to its AZ; `aws ec2 describe-route-tables --query 'RouteTables[?Associations[0].SubnetId!=null].{SubnetId:Associations[0].SubnetId,NatGW:Routes[?DestinationCidrBlock==\`0.0.0.0/0\`].NatGatewayId}'` — confirm each private subnet routes to a NAT Gateway in the same AZ.

---

**Scenario 6 — SCP region restriction via IAM permission boundary is the wrong tool**

> **Situation:** A platform team wants to restrict all workload accounts to only launch EC2 instances in `us-east-1` and `eu-west-1`. A cloud architect proposes writing an IAM permission boundary with a `Deny` on `ec2:RunInstances` for all regions except those two and attaching it to all IAM roles in the workload accounts. The boundary is deployed via a CloudFormation StackSet.

> **Competent move:** Use a **Service Control Policy (SCP)** on the workload OU — not a permission boundary. SCPs apply to every principal in every account in the OU, including root; they cannot be bypassed by account-level IAM administrators. Permission boundaries are per-IAM-entity ceilings — they must be attached to each role individually, any admin can remove them, and they do not protect against principals who are granted permissions outside the boundary (e.g., new roles created by account admins without the boundary). The SCP with a `Deny` on `ec2:RunInstances` conditioned on `aws:RequestedRegion NotStringLike [us-east-1, eu-west-1]` applies automatically to all current and future principals in the OU.

> **Tempting-but-wrong:** Using permission boundaries as region guardrails. Boundaries are the right tool for limiting what an individual developer or Lambda function can do — not for enforcing org-wide account-level invariants. A developer with IAM admin rights in the workload account can create a new role without the boundary and bypass the control entirely.

> **Verify:** `aws organizations list-policies-for-target --target-id <ou-id> --filter SERVICE_CONTROL_POLICY` confirms an SCP is attached to the target OU; `aws ec2 run-instances --image-id <ami> --region ap-southeast-1` from a principal in the OU should return `ExplicitDeny` — confirm via CloudTrail `errorCode: Client.UnauthorizedOperation` with `errorMessage` citing the SCP.
