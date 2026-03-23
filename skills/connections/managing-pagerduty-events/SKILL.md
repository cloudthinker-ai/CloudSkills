---
name: managing-pagerduty-events
description: |
  Use when working with Pagerduty Events — pagerDuty Events API v2 for event
  routing, change events, alert grouping, and incident triggering. Covers
  trigger/acknowledge/resolve events, change tracking, alert deduplication,
  custom event transformations, and integration key management. Use when sending
  events to PagerDuty, managing alert grouping, tracking deployments, or
  automating incident lifecycle via Events API.
connection_type: pagerduty-events
preload: false
---

# PagerDuty Events API v2 Skill

Send and manage events using the PagerDuty Events API v2.

## API Conventions

### Authentication
Events API v2 uses integration/routing keys in the payload — not Authorization headers. Keys are injected by connection.

### Base URL
- Events API: `https://events.pagerduty.com/v2/`
- Change Events: `https://events.pagerduty.com/v2/change/enqueue`
- This is DIFFERENT from the PagerDuty REST API (`api.pagerduty.com`).

### Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Events API returns minimal responses — extract `dedup_key` and `status`
- NEVER expose routing keys in output

### Core Helper Function

```bash
#!/bin/bash

pd_event() {
    local action="$1"      # trigger, acknowledge, resolve
    local dedup_key="$2"
    local summary="${3:-}"
    local severity="${4:-error}"  # critical, error, warning, info
    local source="${5:-cloudskills}"

    local payload=""
    if [ "$action" = "trigger" ]; then
        payload="{
            \"routing_key\": \"${PD_ROUTING_KEY}\",
            \"event_action\": \"trigger\",
            \"dedup_key\": \"${dedup_key}\",
            \"payload\": {
                \"summary\": \"${summary}\",
                \"severity\": \"${severity}\",
                \"source\": \"${source}\",
                \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\"
            }
        }"
    else
        payload="{
            \"routing_key\": \"${PD_ROUTING_KEY}\",
            \"event_action\": \"${action}\",
            \"dedup_key\": \"${dedup_key}\"
        }"
    fi

    curl -s -X POST \
        -H "Content-Type: application/json" \
        "https://events.pagerduty.com/v2/enqueue" \
        -d "$payload"
}

pd_change_event() {
    local summary="$1"
    local source="${2:-deployment}"
    local custom_details="${3:-{}}"

    curl -s -X POST \
        -H "Content-Type: application/json" \
        "https://events.pagerduty.com/v2/change/enqueue" \
        -d "{
            \"routing_key\": \"${PD_ROUTING_KEY}\",
            \"payload\": {
                \"summary\": \"${summary}\",
                \"source\": \"${source}\",
                \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\",
                \"custom_details\": ${custom_details}
            }
        }"
}
```

## Parallel Execution

```bash
# Send multiple independent events in parallel
{
    pd_event "trigger" "disk-full-srv01" "Disk usage >90% on srv01" "critical" "monitoring" &
    pd_event "trigger" "high-cpu-srv02" "CPU usage >95% on srv02" "error" "monitoring" &
    pd_change_event "Deployed api-service v2.3.1" "deployment-pipeline" &
}
wait
```

## Anti-Hallucination Rules

**NEVER assume routing keys, dedup keys, or service configurations. ALWAYS validate first.**

### Phase 1: Validation

```bash
#!/bin/bash
echo "=== Validate Routing Key ==="
# Send a test event with acknowledge to verify key works
TEST_RESULT=$(pd_event "trigger" "test-$(date +%s)" "Integration test event" "info" "validation")
STATUS=$(echo "$TEST_RESULT" | jq -r '.status')
DEDUP=$(echo "$TEST_RESULT" | jq -r '.dedup_key')

if [ "$STATUS" = "success" ]; then
    echo "Routing key valid. Status: $STATUS"
    # Immediately resolve the test event
    pd_event "resolve" "$DEDUP" | jq -r '.status'
else
    echo "ERROR: Invalid routing key. Response: $(echo "$TEST_RESULT" | jq -r '.message')"
fi
```

## Common Operations

### Trigger Alert Events

```bash
#!/bin/bash
SUMMARY="${1:?Alert summary required}"
SEVERITY="${2:-error}"
SOURCE="${3:-cloudskills}"
DEDUP_KEY="${4:-$(echo "$SUMMARY" | md5sum | cut -d' ' -f1)}"

echo "=== Triggering Alert ==="
RESULT=$(pd_event "trigger" "$DEDUP_KEY" "$SUMMARY" "$SEVERITY" "$SOURCE")
echo "$RESULT" | jq '{status: .status, message: .message, dedup_key: .dedup_key}'
```

### Trigger with Custom Details

```bash
#!/bin/bash
echo "=== Triggering Detailed Alert ==="
curl -s -X POST \
    -H "Content-Type: application/json" \
    "https://events.pagerduty.com/v2/enqueue" \
    -d "{
        \"routing_key\": \"${PD_ROUTING_KEY}\",
        \"event_action\": \"trigger\",
        \"dedup_key\": \"${1:?dedup_key required}\",
        \"payload\": {
            \"summary\": \"${2:?summary required}\",
            \"severity\": \"${3:-error}\",
            \"source\": \"${4:-cloudskills}\",
            \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\",
            \"component\": \"${5:-}\",
            \"group\": \"${6:-}\",
            \"class\": \"${7:-}\",
            \"custom_details\": {
                \"environment\": \"production\",
                \"runbook\": \"https://wiki.example.com/runbooks\"
            }
        },
        \"links\": [{\"href\": \"https://monitoring.example.com\", \"text\": \"View in monitoring\"}],
        \"images\": []
    }" | jq '{status, message, dedup_key}'
```

### Acknowledge & Resolve Events

```bash
#!/bin/bash
DEDUP_KEY="${1:?Dedup key required}"
ACTION="${2:-acknowledge}"  # acknowledge or resolve

echo "=== ${ACTION} Event ==="
pd_event "$ACTION" "$DEDUP_KEY" | jq '{status, message, dedup_key}'
```

### Change Events (Deployments)

```bash
#!/bin/bash
echo "=== Sending Change Event ==="
pd_change_event \
    "${1:?Change summary required}" \
    "${2:-deployment}" \
    "{\"version\":\"${3:-unknown}\",\"environment\":\"${4:-production}\",\"deployed_by\":\"${5:-automation}\"}" \
    | jq '{status, message}'
```

### Batch Alert Management

```bash
#!/bin/bash
echo "=== Batch Resolve Alerts ==="
DEDUP_KEYS="${@:?At least one dedup_key required}"

for key in $DEDUP_KEYS; do
    pd_event "resolve" "$key" &
done
wait

echo "Resolved $(echo "$DEDUP_KEYS" | wc -w | tr -d ' ') alerts"
```

## Output Format

Present results as a structured report:
```
Managing Pagerduty Events Report
════════════════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

## Common Pitfalls

- **Events API vs REST API**: Events API (`events.pagerduty.com`) is for sending alerts — REST API (`api.pagerduty.com`) is for management
- **Routing key vs API key**: Events API uses routing/integration keys — NOT the REST API token
- **Dedup key**: Same dedup_key groups events into one alert — use consistent keys for deduplication
- **Severity levels**: Only `critical`, `error`, `warning`, `info` — case-sensitive, no other values
- **Rate limits**: Events API is rate-limited — 120 events/min per routing key
- **Change events**: Different endpoint (`/v2/change/enqueue`) — do NOT send to `/v2/enqueue`
- **Response codes**: `202`=accepted, `400`=invalid payload, `429`=rate limited — always check status
- **No query API**: Events API is fire-and-forget — use REST API to query resulting incidents
