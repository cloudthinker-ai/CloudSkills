---
name: gcp-cloud-logging
description: |
  Use when working with Gcp Cloud Logging — google Cloud Logging log analysis,
  log-based metrics, sink management, exclusion filters, and log routing
  configuration via gcloud CLI.
connection_type: gcp
preload: false
---

# Cloud Logging Skill

Manage and analyze Google Cloud Logging using `gcloud logging` commands.

## Discovery-First Rule

**ALWAYS discover before acting.** Never assume log names, sink names, metric names, or exclusion filter names.

```bash
# Discover log names
gcloud logging logs list --format=json --limit=50 \
  | jq '[.[] | split("/") | last]'

# Discover sinks
gcloud logging sinks list --format=json \
  | jq '[.[] | {name: .name, destination: .destination, filter: .filter, disabled: .disabled}]'
```

## Parallel Execution Requirement

**ALL independent operations MUST run in parallel using background jobs (&) and wait.**

```bash
for sink in $(gcloud logging sinks list --format="value(name)"); do
  {
    gcloud logging sinks describe "$sink" --format=json
  } &
done
wait
```

## Helper Functions

```bash
# Read logs with filter
read_logs() {
  local filter="$1" limit="${2:-100}"
  gcloud logging read "$filter" --limit="$limit" --format=json \
    | jq '[.[] | {timestamp: .timestamp, severity: .severity, logName: .logName | split("/") | last, message: .textPayload // .jsonPayload.message // (.jsonPayload | tostring | .[:200])}]'
}

# List log-based metrics
list_log_metrics() {
  gcloud logging metrics list --format=json \
    | jq '[.[] | {name: .name, description: .description, filter: .filter, metricDescriptor: .metricDescriptor.type}]'
}

# Get sink details
get_sink_details() {
  local sink="$1"
  gcloud logging sinks describe "$sink" --format=json \
    | jq '{name: .name, destination: .destination, filter: .filter, disabled: .disabled, exclusions: .exclusions, writerIdentity: .writerIdentity, includeChildren: .includeChildren}'
}

# List exclusion filters
list_exclusions() {
  gcloud logging sinks list --format=json \
    | jq '[.[] | select(.exclusions) | {sink: .name, exclusions: .exclusions}]'
}
```

## Common Operations

### 1. Log Analysis

```bash
# Recent errors across all services
read_logs "severity>=ERROR" 50

# Errors for a specific service
read_logs "resource.type=\"cloud_run_revision\" AND severity>=ERROR" 50

# Audit logs for IAM changes
read_logs "logName:\"activity\" AND protoPayload.methodName:\"SetIamPolicy\"" 20

# GKE container logs
read_logs "resource.type=\"k8s_container\" AND resource.labels.namespace_name=\"$NAMESPACE\"" 100
```

### 2. Log-Based Metrics

```bash
# List all custom metrics
list_log_metrics

# Get metric details
gcloud logging metrics describe "$METRIC_NAME" --format=json \
  | jq '{name: .name, filter: .filter, description: .description, labelExtractors: .labelExtractors, bucketOptions: .bucketOptions}'

# Check metric values via monitoring
gcloud monitoring time-series list \
  --filter="metric.type=\"logging.googleapis.com/user/$METRIC_NAME\"" \
  --interval-start-time="$(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)" \
  --format=json
```

### 3. Sink Management

```bash
# All sinks with destinations
gcloud logging sinks list --format=json \
  | jq '[.[] | {name: .name, destination: .destination, filter: .filter, disabled: .disabled, writerIdentity: .writerIdentity}]'

# Check sink writer identity permissions
for sink in $(gcloud logging sinks list --format="value(name)"); do
  {
    echo "Sink: $sink"
    get_sink_details "$sink"
  } &
done
wait
```

### 4. Exclusion Filter Analysis

```bash
# List all exclusion filters
gcloud logging sinks describe "_Default" --format=json \
  | jq '.exclusions // [] | [.[] | {name: .name, filter: .filter, disabled: .disabled, description: .description}]'

# Check what percentage of logs are excluded
gcloud monitoring time-series list \
  --filter="metric.type=\"logging.googleapis.com/exports/byte_count\"" \
  --interval-start-time="$(date -u -v-24H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)" \
  --format=json
```

### 5. Log Volume and Cost Analysis

```bash
# Ingestion volume by log type
gcloud monitoring time-series list \
  --filter="metric.type=\"logging.googleapis.com/billing/bytes_ingested\"" \
  --interval-start-time="$(date -u -v-24H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)" \
  --format=json

# Monthly ingested bytes per log name
gcloud monitoring time-series list \
  --filter="metric.type=\"logging.googleapis.com/billing/monthly_bytes_ingested\"" \
  --interval-start-time="$(date -u -v-24H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)" \
  --format=json
```

## Output Format

Present results as a structured report:
```
Gcp Cloud Logging Report
════════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

## Anti-Hallucination Rules

1. **NEVER assume resource names** — always discover via CLI/API in Phase 1 before referencing in Phase 2.
2. **NEVER fabricate metric names or dimensions** — verify against the service documentation or `--help` output.
3. **NEVER mix CLI commands between service versions** — confirm which version/API you are targeting.
4. **ALWAYS use the discovery → verify → analyze chain** — every resource referenced must have been discovered first.
5. **ALWAYS handle empty results gracefully** — an empty response is valid data, not an error to retry.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

## Common Pitfalls

1. **_Required vs _Default sink**: The `_Required` sink cannot be disabled or filtered (audit logs, access transparency). Only `_Default` and custom sinks can be configured.
2. **Exclusion filter cost**: Excluded logs are not stored but are still ingested. They count toward ingestion quotas but not storage costs.
3. **Log filter syntax**: Cloud Logging uses a filter expression language, not regex. Use `=~` for regex matching: `textPayload =~ "error.*timeout"`.
4. **Sink permissions**: Each sink has a `writerIdentity` service account that needs write permissions on the destination (BigQuery, GCS, Pub/Sub).
5. **Retention periods**: Default retention is 30 days for `_Default` bucket. Custom buckets can have different retention. Locked buckets cannot be shortened.
