# Trigger tests — aws-devops-engineer-professional (Lens 2)

Routing regression set. Test each phrasing against skill DESCRIPTIONS only. Each routes to exactly one skill.

## Should route to aws-devops-engineer-professional (5)

1. "Our CodePipeline manual-approval stage is skipping when no one approves within the timeout — how do I configure a rejection action and notify the team?"
2. "Walk me through adding a canary deployment strategy to our CodeDeploy application so we shift 10% of traffic and automatically roll back if the error-rate alarm fires."
3. "Our CloudFormation drift detection job is running but never auto-remediates — review this EventBridge + SSM Automation setup and tell me what's broken."
4. "I need a buildspec.yml that pulls DB credentials from Parameter Store at build time instead of hardcoding them as environment variables."
5. "Help me design a multi-region CodePipeline that deploys to us-east-1 first, waits for a CloudWatch alarm to be healthy, then promotes to eu-west-1."

## Near-misses → a sibling (3)

1. "Design a transit-gateway-based hub-and-spoke architecture to connect 15 VPCs across four AWS accounts." → `aws-solutions-architect-professional`  (enterprise cross-account networking architecture trade-off, not pipeline/IaC delivery)
2. "Our KMS key policy is blocking cross-account decrypt calls — review it for privilege-escalation risks and wildcard permissions." → `aws-security-specialty`  (IAM/KMS policy evaluation and security controls, not CI/CD)
3. "Write a GuardDuty findings processor that automatically revokes EC2 instance profile credentials when a credential-exfiltration finding fires." → `aws-security-specialty`  (threat detection and incident-response containment, not DevOps pipeline delivery)
