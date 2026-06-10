# Trigger tests — aws-solutions-architect-professional (Lens 2)

> _Held-out eval content — original, not exam material (no real exam questions; see POLICY.md). Do not paste into a skill body._

Routing regression set. Test each phrasing against skill DESCRIPTIONS only. Each routes to exactly one skill.

## Should route to aws-solutions-architect-professional (5)

1. "We're migrating a 50 TB on-premises Oracle data warehouse to AWS — compare Redshift, Aurora, and keeping Oracle on RDS, and recommend the right 7-R strategy for each tier."
2. "Our 20-account AWS Organization uses VPC peering today; traffic patterns have grown to the point where the mesh is unmanageable. Design a Transit Gateway hub-and-spoke replacement and flag the routing and security trade-offs."
3. "The CTO wants RTO of 15 minutes and RPO of 5 minutes for our order-management system. Evaluate warm standby vs. pilot light vs. active/active, pick the right DR pattern, and justify the cost delta."
4. "We need a hybrid DNS architecture: on-premises resolvers must query private Route 53 hosted zones, and Route 53 must forward some queries to on-premises. What Route 53 Resolver endpoints do we need and where?"
5. "Design a multi-account landing zone for a 200-engineer org: how should we structure OUs, SCPs, and centralized logging accounts in Control Tower to enforce least-privilege at scale?"

## Near-misses → a sibling (3)

1. "Write the CloudFormation template that provisions the Transit Gateway, route tables, and VPC attachments for our hub-and-spoke network." → `aws-devops-engineer-professional`  (hands-on IaC delivery, not architecture trade-off; the SA designs it, DevOps builds it)
2. "Review our SCP that's supposed to deny `ec2:RunInstances` outside approved regions and tell me why it's still allowing launches in ap-southeast-1." → `aws-security-specialty`  (SCP policy evaluation and security-control debugging, not enterprise architecture design)
3. "Set up CloudWatch dashboards and alarms to monitor the Transit Gateway packet-drop metric across all attached VPCs." → `aws-devops-engineer-professional`  (observability stack configuration and monitoring delivery, not architecture/trade-off work)
