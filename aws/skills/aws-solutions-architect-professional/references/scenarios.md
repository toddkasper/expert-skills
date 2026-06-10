# Decision Scenarios — AWS Solutions Architect Professional

Two additional judgment scenarios (Scenarios 2–4 are now inlined in the SKILL.md body). These cover complementary high-lift judgment areas.

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

---
*Companion reference — independent educational content, not affiliated with or endorsed by any vendor; product/credential names are used for identification only. Guidance, not ground truth — verify against official docs. Full disclaimer: the parent `SKILL.md` and the repo `POLICY.md`.*
