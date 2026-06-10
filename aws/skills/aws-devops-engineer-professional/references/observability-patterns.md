# Observability Patterns — AWS DevOps Engineer Professional

> Loaded on demand from SKILL.md §4 (Monitoring and Logging). Load this file when designing centralized logging across accounts or configuring X-Ray distributed tracing.

## Centralized Logging Across Accounts

Use a dedicated **log archive account** as the single destination for all log data.

**Pattern 1 — CloudWatch Logs subscription filters (push):** configure a subscription filter on each source log group to push events to a Kinesis Data Stream or Kinesis Data Firehose in the central log archive account. Add an IAM resource-based policy on the Kinesis destination (or Firehose delivery stream) that allows `logs.amazonaws.com` from source account IDs to call `kinesis:PutRecord` / `firehose:PutRecord`. Firehose can then deliver to S3, OpenSearch, or Splunk without custom Lambda.

**Pattern 2 — CloudWatch cross-account observability (native, since 2022):** designate a monitoring account and link source accounts via the CloudWatch cross-account observability console. Source accounts share metrics, logs, and traces with the monitoring account; no subscription filter setup required for metrics and traces. Log groups must still be shared explicitly via the sharing config.

**Key constraints:**
- Subscription filter CloudWatch → Kinesis cross-account: the Kinesis resource policy must allow the source account's `logs.amazonaws.com` service principal.
- Each log group supports only one subscription filter at a time — plan for this if you also need real-time Lambda-based alerting.
- Cross-account observability does not replace S3 archival — Firehose to S3 is still needed for long-term retention.

**Verify:** In the source account, `aws logs describe-subscription-filters --log-group-name <group>` shows the destination ARN; in the central account, `aws kinesis get-shard-iterator` + `get-records` or the Firehose monitoring metrics confirm data is flowing.

---

## AWS X-Ray Distributed Tracing

**Enable active tracing** on Lambda, API Gateway, and ECS tasks — passive mode only captures a sample on API Gateway.

**Sampling rules:** the default rule samples 5% of requests plus the first request of each second from any host. Define custom rules in the X-Ray console to raise sampling on critical services (e.g., sample 100% of payment-service requests) and lower it on high-volume health-check paths. Sampling rules are account-scoped and apply across all instrumented services.

**X-Ray groups:** filter traces by annotation key-value pairs (e.g., `Error = true`) and create a CloudWatch alarm on the group's error rate. This allows service-level error alarming from trace data without custom metric filters.

**Service map:** shows node-to-node latency and error rates. A node in `Error` state (4xx) vs `Fault` state (5xx) vs `Throttle` (429) is visible at a glance — use this to triage whether a problem is client-side, server-side, or downstream throttling.

**Red flag:** X-Ray active tracing disabled on Lambda functions — passive mode misses the majority of invocations. Enable via `aws lambda update-function-configuration --function-name <fn> --tracing-config Mode=Active`.

**Verify:** `aws xray get-service-graph --start-time <epoch> --end-time <epoch>` returns nodes and edges; `aws xray get-trace-summaries --start-time <epoch> --end-time <epoch>` lists sampled trace IDs for inspection.
