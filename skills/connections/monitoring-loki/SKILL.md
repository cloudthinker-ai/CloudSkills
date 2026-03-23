---
name: monitoring-loki
description: |
  Use when working with Loki — grafana Loki log aggregation with LogQL queries,
  label management, tenant analysis, ingestion health, and ruler configuration.
  Covers log stream queries, metric queries from logs, alerting rules, and
  storage analysis. Use when querying logs via LogQL, analyzing label
  cardinality, managing alert rules, or monitoring Loki cluster health.
connection_type: loki
preload: false
---

# Grafana Loki Monitoring Skill

Query and analyze logs using Grafana Loki and LogQL.

## API Conventions

### Authentication
Loki API uses Basic auth, Bearer token, or tenant header (`X-Scope-OrgID`) — injected by connection.

### Base URL
- Loki API: `http://<host>:3100/loki/api/v1/`
- Use connection-injected `LOKI_BASE_URL`.

### Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `jq` to extract log lines and labels
- NEVER dump full query responses — extract and summarize

### Core Helper Function

```bash
#!/bin/bash

loki_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "X-Scope-OrgID: ${LOKI_TENANT_ID:-default}" \
            -H "Content-Type: application/json" \
            "${LOKI_BASE_URL}/loki/api/v1${endpoint}" \
            -d "$data"
    else
        curl -s \
            -H "X-Scope-OrgID: ${LOKI_TENANT_ID:-default}" \
            "${LOKI_BASE_URL}/loki/api/v1${endpoint}"
    fi
}

loki_query() {
    local logql="$1"
    local limit="${2:-100}"
    local since="${3:-1h}"
    local end=$(date +%s)
    local start=$((end - $(echo "$since" | sed 's/h/*3600/;s/m/*60/;s/d/*86400/' | bc)))

    loki_api GET "/query_range?query=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${logql}'))")&limit=${limit}&start=${start}&end=${end}"
}
```

## Parallel Execution

```bash
{
    loki_api GET "/labels" &
    loki_api GET "/series?match[]={job=~\".+\"}&start=$(date -d '1 hour ago' +%s)&end=$(date +%s)" &
}
wait
```

## Anti-Hallucination Rules

**NEVER assume label names, label values, or stream selectors. ALWAYS discover first.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Available Labels ==="
loki_api GET "/labels" | jq -r '.data[]' | sort

echo ""
echo "=== Label Values for 'job' ==="
loki_api GET "/label/job/values" | jq -r '.data[]' | sort | head -20

echo ""
echo "=== Label Values for 'namespace' ==="
loki_api GET "/label/namespace/values" | jq -r '.data[]' | sort | head -20

echo ""
echo "=== Active Streams Sample ==="
loki_api GET "/series?match[]={job=~\".+\"}&start=$(($(date +%s)-3600))&end=$(date +%s)" \
    | jq -r '.data[:10][] | to_entries | map("\(.key)=\(.value)") | join(", ")'
```

## Common Operations

### Log Search with LogQL

```bash
#!/bin/bash
echo "=== Error Logs (last 1h) ==="
loki_query '{job=~".+"} |= "error" | line_format "{{.timestamp}} {{.message}}"' 50 "1h" \
    | jq -r '.data.result[].values[] | "\(.[0])\t\(.[1][0:120])"' | head -20

echo ""
echo "=== Logs by Label Filter ==="
JOB="${1:?Job label required}"
loki_query "{job=\"${JOB}\"} | json | level=~\"error|warn\"" 30 "1h" \
    | jq -r '.data.result[].values[] | "\(.[0])\t\(.[1][0:100])"' | head -20
```

### Metric Queries from Logs

```bash
#!/bin/bash
echo "=== Error Rate by Job (last 1h) ==="
loki_query 'sum(rate({job=~".+"} |= "error" [5m])) by (job)' 100 "1h" \
    | jq -r '.data.result[] | "\(.metric.job)\t\(.values[-1][1]) errors/s"' \
    | sort -t$'\t' -k2 -rn | head -15

echo ""
echo "=== Log Volume by Namespace ==="
loki_query 'sum(rate({namespace=~".+"} [5m])) by (namespace)' 100 "1h" \
    | jq -r '.data.result[] | "\(.metric.namespace)\t\(.values[-1][1]) lines/s"' \
    | sort -t$'\t' -k2 -rn | head -15
```

### Label Cardinality Analysis

```bash
#!/bin/bash
echo "=== Label Cardinality ==="
for label in $(loki_api GET "/labels" | jq -r '.data[]' | head -15); do
    count=$(loki_api GET "/label/${label}/values" | jq '.data | length')
    echo "$label: $count unique values"
done | sort -t: -k2 -rn

echo ""
echo "=== High-Cardinality Labels (>100 values) ==="
for label in $(loki_api GET "/labels" | jq -r '.data[]'); do
    count=$(loki_api GET "/label/${label}/values" | jq '.data | length')
    [ "$count" -gt 100 ] && echo "WARNING: $label has $count values"
done
```

### Alerting Rules (Ruler)

```bash
#!/bin/bash
echo "=== Configured Alert Rules ==="
loki_api GET "/rules" \
    | jq -r '.data.groups[] | "\(.name) (\(.rules | length) rules):\n\(.rules[] | "  \(.alert // .record): \(.state // "N/A")")"' \
    | head -30

echo ""
echo "=== Firing Alerts ==="
loki_api GET "/rules" \
    | jq -r '.data.groups[].rules[] | select(.state == "firing") | "\(.alert)\t\(.labels | to_entries | map("\(.key)=\(.value)") | join(","))"'
```

### Ingestion Health

```bash
#!/bin/bash
echo "=== Loki Build Info ==="
loki_api GET "/status/buildinfo" | jq '{version: .version, goVersion: .goVersion}'

echo ""
echo "=== Ring Health (Distributors) ==="
curl -s "${LOKI_BASE_URL}/distributor/ring" 2>/dev/null | head -20

echo ""
echo "=== Ingester Status ==="
curl -s "${LOKI_BASE_URL}/ingester/ring" 2>/dev/null | head -20

echo ""
echo "=== Ready Check ==="
curl -s "${LOKI_BASE_URL}/ready"
```

## Output Format

Present results as a structured report:
```
Monitoring Loki Report
══════════════════════
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

- **LogQL syntax**: Stream selector `{label="value"}` is required — bare filter expressions are invalid
- **Label matching**: Use `=~` for regex, `!=` for negation — `{job=~"api.*"}` not `{job LIKE 'api%'}`
- **Pipeline stages**: Log pipeline uses `|` — `{job="x"} |= "error" | json | line_format "{{.msg}}"`
- **Metric queries**: Wrap in aggregation — `rate({job="x"}[5m])` not `{job="x"}[5m]`
- **Timestamp format**: Loki uses nanosecond Unix timestamps — divide by 1e9 for seconds
- **Multi-tenancy**: Always set `X-Scope-OrgID` header for multi-tenant deployments
- **Query limits**: Default query timeout is 1 minute — use shorter time ranges for large datasets
- **Rate vs count_over_time**: `rate` returns per-second, `count_over_time` returns total count in window
