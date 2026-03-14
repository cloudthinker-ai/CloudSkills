---
name: monitoring-appdynamics
description: |
  AppDynamics application performance monitoring with flow maps, business transaction analysis, tier health, analytics queries, and baseline management. Covers application topology, node health, error analysis, metric browsing, and health rule violations. Use when analyzing application performance, investigating business transactions, reviewing health rules, or querying AppDynamics metrics via REST API.
connection_type: appdynamics
preload: false
---

# AppDynamics Monitoring Skill

Monitor and analyze application performance using the AppDynamics REST API.

## API Conventions

### Authentication
AppDynamics uses Basic auth (`user@account:password`) or OAuth token — injected by connection.

### Base URL
- Controller: `https://<controller>.saas.appdynamics.com/controller/`
- Use connection-injected `APPD_BASE_URL`.

### Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `jq` to extract metric values and entity names
- NEVER dump full metric trees — always filter to relevant nodes

### Core Helper Function

```bash
#!/bin/bash

appd_api() {
    local endpoint="$1"
    local params="${2:-}"
    curl -s -u "${APPD_USER}@${APPD_ACCOUNT}:${APPD_PASSWORD}" \
        "${APPD_BASE_URL}/controller/rest${endpoint}${params:+?${params}}" \
        -H "Content-Type: application/json"
}

appd_metric() {
    local app="$1"
    local metric_path="$2"
    local duration="${3:-60}"  # minutes
    appd_api "/applications/${app}/metric-data" \
        "metric-path=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${metric_path}'))")&time-range-type=BEFORE_NOW&duration-in-mins=${duration}&output=JSON"
}
```

## Parallel Execution

```bash
{
    appd_api "/applications" "output=JSON" &
    appd_api "/applications/${APP_NAME}/tiers" "output=JSON" &
    appd_api "/applications/${APP_NAME}/business-transactions" "output=JSON" &
}
wait
```

## Anti-Hallucination Rules

**NEVER assume application names, tier names, BT names, or metric paths. ALWAYS discover first.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Applications ==="
appd_api "/applications" "output=JSON" \
    | jq -r '.[] | "\(.id)\t\(.name)"' | head -20

echo ""
echo "=== Tiers for Application ==="
APP="${1:?Application name required}"
appd_api "/applications/${APP}/tiers" "output=JSON" \
    | jq -r '.[] | "\(.id)\t\(.name)\t\(.type)\tnodes:\(.numberOfNodes)"'

echo ""
echo "=== Business Transactions ==="
appd_api "/applications/${APP}/business-transactions" "output=JSON" \
    | jq -r '.[] | "\(.id)\t\(.tierName)\t\(.name)"' | head -20
```

## Common Operations

### Application Flow Map & Health

```bash
#!/bin/bash
APP="${1:?Application name required}"

echo "=== Application Health ==="
{
    echo "--- Tiers ---"
    appd_api "/applications/${APP}/tiers" "output=JSON" \
        | jq -r '.[] | "\(.name)\tnodes:\(.numberOfNodes)\ttype:\(.type)"' &

    echo "--- Overall Metrics (last 15m) ---"
    appd_metric "$APP" "Overall Application Performance|Average Response Time (ms)" 15 \
        | jq -r '.[0] | "Avg Response Time: \(.metricValues[0].value // "N/A")ms"' &

    appd_metric "$APP" "Overall Application Performance|Calls per Minute" 15 \
        | jq -r '.[0] | "Calls/min: \(.metricValues[0].value // "N/A")"' &

    appd_metric "$APP" "Overall Application Performance|Errors per Minute" 15 \
        | jq -r '.[0] | "Errors/min: \(.metricValues[0].value // "N/A")"' &
}
wait
```

### Business Transaction Analysis

```bash
#!/bin/bash
APP="${1:?Application name required}"

echo "=== Top Business Transactions by Response Time ==="
appd_metric "$APP" "Business Transaction Performance|Business Transactions|*|Average Response Time (ms)" 60 \
    | jq -r '.[] | "\(.metricPath | split("|")[2])\t\(.metricValues[0].value // 0)ms"' \
    | sort -t$'\t' -k2 -rn | head -15

echo ""
echo "=== BTs with High Error Rate ==="
appd_metric "$APP" "Business Transaction Performance|Business Transactions|*|Errors per Minute" 60 \
    | jq -r '.[] | select(.metricValues[0].value > 0) | "\(.metricPath | split("|")[2])\t\(.metricValues[0].value) errors/min"' \
    | sort -t$'\t' -k2 -rn | head -10

echo ""
echo "=== BT Call Volume ==="
appd_metric "$APP" "Business Transaction Performance|Business Transactions|*|Calls per Minute" 60 \
    | jq -r '.[] | "\(.metricPath | split("|")[2])\t\(.metricValues[0].value // 0) calls/min"' \
    | sort -t$'\t' -k2 -rn | head -10
```

### Tier & Node Health

```bash
#!/bin/bash
APP="${1:?Application name required}"
TIER="${2:?Tier name required}"

echo "=== Tier Health: ${TIER} ==="
{
    appd_metric "$APP" "Application Infrastructure Performance|${TIER}|Individual Nodes|*|Agent|App|Availability" 15 \
        | jq -r '.[] | "\(.metricPath | split("|")[3])\tavailability:\(.metricValues[0].value // "N/A")"' &

    echo "--- Tier Response Time ---"
    appd_metric "$APP" "Application Infrastructure Performance|${TIER}|Average Response Time (ms)" 15 \
        | jq -r '.[0] | "Avg Response Time: \(.metricValues[0].value // "N/A")ms"' &

    echo "--- Tier CPU ---"
    appd_metric "$APP" "Application Infrastructure Performance|${TIER}|Individual Nodes|*|Hardware Resources|CPU|%Busy" 15 \
        | jq -r '.[] | "\(.metricPath | split("|")[3])\tCPU:\(.metricValues[0].value // "N/A")%"' &
}
wait
```

### Health Rule Violations

```bash
#!/bin/bash
APP="${1:?Application name required}"

echo "=== Health Rule Violations (last 1h) ==="
FROM=$(( $(date +%s) * 1000 - 3600000 ))
TO=$(( $(date +%s) * 1000 ))

appd_api "/applications/${APP}/problems/healthrule-violations" \
    "output=JSON&time-range-type=BETWEEN_TIMES&start-time=${FROM}&end-time=${TO}" \
    | jq -r '.[] | "\(.severity)\t\(.name)\t\(.affectedEntityDefinition.name)\t\(.status)"' | head -15

echo ""
echo "=== Active Health Rules ==="
appd_api "/applications/${APP}/healthrules" "output=JSON" \
    | jq -r '.[] | "\(.id)\t\(.name)\t\(.enabled)"' | head -20
```

### Error Analysis

```bash
#!/bin/bash
APP="${1:?Application name required}"

echo "=== Top Errors (last 1h) ==="
appd_metric "$APP" "Overall Application Performance|Exceptions per Minute" 60 \
    | jq -r '.[0] | "Total Exceptions/min: \(.metricValues[0].value // 0)"'

echo ""
echo "=== Error Transactions ==="
appd_api "/applications/${APP}/business-transactions" "output=JSON" \
    | jq -r '.[] | "\(.id)\t\(.name)"' | while IFS=$'\t' read id name; do
    errors=$(appd_metric "$APP" "Business Transaction Performance|Business Transactions|${name}|Errors per Minute" 60 \
        | jq -r '.[0].metricValues[0].value // 0')
    [ "$errors" != "0" ] && echo "$name: $errors errors/min"
done | sort -t: -k2 -rn | head -10
```

## Common Pitfalls

- **Metric path separator**: Use `|` pipe character — `Overall Application Performance|Average Response Time (ms)`
- **URL encoding**: Metric paths with spaces and pipes must be URL-encoded in query parameters
- **Time format**: Uses milliseconds since epoch for time ranges — multiply Unix seconds by 1000
- **Output format**: Always add `output=JSON` parameter — default is XML
- **Wildcard queries**: Use `*` in metric paths to get all children — `Business Transactions|*|Calls per Minute`
- **Rate limits**: Controller-dependent — typically 200 calls/min for SaaS controllers
- **Auth format**: `user@account:password` — account name is required in Basic auth
- **Baseline data**: Baselines need 2+ weeks of data — new applications may not have baseline metrics
