# Trigger tests — github-actions (Lens 2)

Routing regression set. Test each phrasing against skill DESCRIPTIONS only. Each routes to exactly one skill.

## Should route to github-actions (5)

1. "Write a reusable workflow that builds a Docker image, pushes it to ECR using OIDC (no long-lived AWS keys), and can be called from any repo in the org."
2. "Review this workflow YAML — it uses `pull_request_target` to run tests on fork contributions. Is there a security risk, and how do I fix it?"
3. "My matrix build across four Node versions runs all four jobs even when only the linting step fails on Node 18. How do I configure fail-fast and which `continue-on-error` setting controls that?"
4. "I need a composite action that wraps our test setup (cache restore, npm ci, env file write) so every repo can call it in one step. Show me the action.yml and how to version-pin it safely."
5. "Our release workflow sets `permissions: write-all` at the top level so the publish step can create a GitHub Release. The security team flagged it — what's the minimum permission set I actually need?"

## Near-misses → non-skill targets (3)

1. "Our GitHub org requires branch protection on `main` — how do I enforce required reviewers and prevent force-pushes across all repos from the org settings?" → general GitHub repo/org administration  (not CI/CD workflow authoring; this is repository policy configuration, not Actions)
2. "Help me write the Node.js Express middleware that validates the GitHub webhook HMAC signature before processing push events." → general application code / web:nodejs  (this is application code consuming GitHub webhooks, not authoring Actions workflows)
3. "Set up an SQS queue that ingests GitHub push-event payloads forwarded by an API Gateway webhook — design the fan-out to Lambda processors." → `aws-solutions-architect-professional` / general app architecture  (AWS event-driven architecture design, not Actions workflow authoring or CI/CD pipeline)
