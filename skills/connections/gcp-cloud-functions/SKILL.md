---
name: gcp-cloud-functions
description: |
  Use when working with Gcp Cloud Functions — google Cloud Functions management,
  execution analysis, scaling configuration, event trigger inspection, and
  runtime diagnostics via gcloud CLI.
connection_type: gcp
preload: false
---

# Cloud Functions Skill

Manage and analyze Google Cloud Functions using `gcloud functions` commands.

## Discovery-First Rule

**ALWAYS discover before acting.** Never assume function names, regions, runtimes, or trigger types.

```bash
# Discover all functions (v2 and v1)
gcloud functions list --format=json \
  | jq '[.[] | {name: .name, status: .state // .status, runtime: .buildConfig.runtime // .runtime, region: .name | split("/") | .[3], generation: (if .buildConfig then "v2" else "v1" end), entryPoint: .buildConfig.entryPoint // .entryPoint}]'
```

## Parallel Execution Requirement

**ALL independent operations MUST run in parallel using background jobs (&) and wait.**

```bash
for fn in $(gcloud functions list --format="value(name)" --uri); do
  {
    gcloud functions describe "$fn" --format=json
  } &
done
wait
```

## Helper Functions

```bash
# Get function details (v2)
get_function_v2() {
  local name="$1" region="$2"
  gcloud functions describe "$name" --region="$region" --gen2 --format=json \
    | jq '{name: .name, state: .state, runtime: .buildConfig.runtime, entryPoint: .buildConfig.entryPoint, trigger: .eventTrigger // "HTTP", serviceConfig: {memory: .serviceConfig.availableMemory, timeout: .serviceConfig.timeoutSeconds, maxInstances: .serviceConfig.maxInstanceCount, minInstances: .serviceConfig.minInstanceCount, concurrency: .serviceConfig.maxInstanceRequestConcurrency, serviceAccountEmail: .serviceConfig.serviceAccountEmail}}'
}

# Get function logs
get_function_logs() {
  local name="$1" region="$2" limit="${3:-50}"
  gcloud functions logs read "$name" --region="$region" --gen2 --limit="$limit" --format=json
}

# Get execution metrics via Cloud Monitoring
get_function_metrics() {
  local project="$1" function_name="$2"
  gcloud monitoring time-series list \
    --filter="metric.type=\"cloudfunctions.googleapis.com/function/execution_count\" AND resource.labels.function_name=\"$function_name\"" \
    --interval-start-time="$(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)" \
    --format=json
}

# List event triggers
list_event_triggers() {
  local region="$1"
  gcloud functions list --region="$region" --format=json \
    | jq '[.[] | select(.eventTrigger) | {name: .name | split("/") | last, eventType: .eventTrigger.eventType, resource: .eventTrigger.pubsubTopic // .eventTrigger.eventFilters[0].value, retryPolicy: .eventTrigger.retryPolicy}]'
}
```

## Common Operations

### 1. Function Inventory and Health

```bash
regions=$(gcloud functions regions list --format="value(name)")
for region in $regions; do
  {
    functions=$(gcloud functions list --region="$region" --format=json 2>/dev/null)
    if [ "$(echo "$functions" | jq length)" -gt 0 ]; then
      echo "$functions" | jq '[.[] | {name: .name | split("/") | last, state: .state // .status, runtime: .buildConfig.runtime // .runtime, region: "'"$region"'"}]'
    fi
  } &
done
wait
```

### 2. Execution Analysis

```bash
# Recent executions and errors from logs
gcloud functions logs read "$FUNCTION" --region="$REGION" --gen2 --limit=100 --format=json \
  | jq '[.[] | select(.severity == "ERROR")] | length as $errors | {totalLogs: length, errors: $errors}'

# Execution count and latency via monitoring
gcloud monitoring time-series list \
  --filter="metric.type=\"cloudfunctions.googleapis.com/function/execution_times\" AND resource.labels.function_name=\"$FUNCTION\"" \
  --interval-start-time="$(date -u -v-24H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)" \
  --format=json
```

### 3. Scaling Configuration

```bash
# Check instance limits and concurrency (v2)
gcloud functions describe "$FUNCTION" --region="$REGION" --gen2 --format=json \
  | jq '{minInstances: .serviceConfig.minInstanceCount, maxInstances: .serviceConfig.maxInstanceCount, concurrency: .serviceConfig.maxInstanceRequestConcurrency, availableMemory: .serviceConfig.availableMemory, timeout: .serviceConfig.timeoutSeconds, availableCpu: .serviceConfig.availableCpu}'
```

### 4. Event Trigger Configuration

```bash
# List all event-triggered functions
gcloud functions list --format=json \
  | jq '[.[] | select(.eventTrigger) | {name: .name | split("/") | last, eventType: .eventTrigger.eventType, triggerRegion: .eventTrigger.triggerRegion, retryPolicy: .eventTrigger.retryPolicy, channel: .eventTrigger.channel, filters: .eventTrigger.eventFilters}]'
```

### 5. Build and Deployment Status

```bash
# Check build details
gcloud functions describe "$FUNCTION" --region="$REGION" --gen2 --format=json \
  | jq '{buildConfig: {runtime: .buildConfig.runtime, entryPoint: .buildConfig.entryPoint, source: .buildConfig.source, buildServiceAccount: .buildConfig.serviceAccount}, updateTime: .updateTime, createTime: .createTime}'

# Check recent deployments
gcloud builds list --filter="substitutions.FUNCTION_NAME=$FUNCTION" --limit=5 --format=json \
  | jq '[.[] | {id: .id, status: .status, startTime: .startTime, duration: .duration}]'
```

## Output Format

Present results as a structured report:
```
Gcp Cloud Functions Report
══════════════════════════
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

1. **v1 vs v2**: Cloud Functions v2 uses `--gen2` flag. Commands differ between versions. Check the generation before running describe/update.
2. **Cold starts**: Min instances of 0 means cold starts on first invocation. Set `minInstanceCount` for latency-sensitive functions.
3. **Concurrency (v2 only)**: v2 functions support concurrent requests per instance. v1 processes one request per instance. Check `maxInstanceRequestConcurrency`.
4. **Timeout limits**: v1 max timeout is 540s, v2 max is 3600s for event-driven and 3600s for HTTP. Check runtime for long-running operations.
5. **VPC connector**: Functions in a VPC connector route all egress through the VPC. Check connector throughput settings to avoid bottlenecks.
