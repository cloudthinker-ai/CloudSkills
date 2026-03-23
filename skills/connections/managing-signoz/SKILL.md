---
name: managing-signoz
description: |
  Use when working with Signoz — sigNoz open-source observability platform for
  metrics, traces, and logs with OpenTelemetry-native ingestion. Covers service
  performance monitoring, trace analysis, log querying, dashboard management,
  and alert rule configuration. Use when querying SigNoz metrics, analyzing
  distributed traces, searching logs, or managing alert rules and dashboards.
connection_type: signoz
preload: false
---

# SigNoz Monitoring Skill

Query, analyze, and manage SigNoz observability data using the SigNoz API.

## API Overview

SigNoz uses a REST API at `https://<SIGNOZ_HOST>/api/v1`.

### Core Helper Function

```bash
#!/bin/bash

sz_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    if [ -n "$data" ]; then
        curl -s -X "$method" "${SIGNOZ_URL}/api/v1/${endpoint}" \
            -H "Authorization: Bearer $SIGNOZ_API_KEY" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "${SIGNOZ_URL}/api/v1/${endpoint}" \
            -H "Authorization: Bearer $SIGNOZ_API_KEY"
    fi
}
```

## MANDATORY: Discovery-First Pattern

**Always discover services, dashboards, and alert rules before querying.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Services ==="
sz_api GET "services?start=$(date -d '1 hour ago' +%s)000000000&end=$(date +%s)000000000" \
    | jq -r '.[] | "\(.serviceName)\tp99:\(.p99 // "N/A")ms\terrors:\(.numErrors // 0)\tops:\(.numCalls // 0)"' | head -20

echo ""
echo "=== Dashboards ==="
sz_api GET "dashboards" | jq -r '.[] | "\(.id)\t\(.data.title)"' | head -15

echo ""
echo "=== Alert Rules ==="
sz_api GET "rules" | jq -r '.data[] | "\(.id)\t\(.alert)\t\(.state // "unknown")"' | head -15

echo ""
echo "=== Channels (Notification) ==="
sz_api GET "channels" | jq -r '.data[] | "\(.id)\t\(.name)\t\(.type)"' | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Service Performance (last 1h) ==="
sz_api GET "services?start=$(date -d '1 hour ago' +%s)000000000&end=$(date +%s)000000000" \
    | jq -r '.[] | "\(.serviceName)\tp50:\(.p50 // 0)ms\tp99:\(.p99 // 0)ms\terr%:\(if .numCalls > 0 then (.numErrors / .numCalls * 100 * 10 | round / 10) else 0 end)"' \
    | sort -t$'\t' -k4 -rn | head -15

echo ""
echo "=== Top Endpoints by Latency ==="
sz_api GET "service/top_endpoints?service=${1:-}&start=$(date -d '1 hour ago' +%s)000000000&end=$(date +%s)000000000" \
    | jq -r '.[] | "\(.name)\tp99:\(.p99 // 0)ms\tcalls:\(.numCalls // 0)"' | head -15

echo ""
echo "=== Recent Error Logs ==="
sz_api POST "logs" '{"start":"'"$(date -d '1 hour ago' +%s)"'000000000","end":"'"$(date +%s)"'000000000","limit":20,"orderBy":"timestamp","order":"desc","filter":{"items":[{"key":"severity_text","op":"=","value":"ERROR"}]}}' \
    | jq -r '.[] | "\(.timestamp[0:19])\t\(.severityText)\t\(.body[0:80])"' | head -15

echo ""
echo "=== Firing Alerts ==="
sz_api GET "rules" | jq -r '.data[] | select(.state == "firing") | "\(.id)\t\(.alert)\t\(.labels | to_entries | map("\(.key)=\(.value)") | join(","))"' | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines — use query parameters for time ranges and limits
- Use service-level overview before drilling into individual traces
- Filter logs at API level with filter items instead of post-processing

## Output Format

Present results as a structured report:
```
Managing Signoz Report
══════════════════════
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

