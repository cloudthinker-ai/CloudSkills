---
name: managing-skywalking
description: |
  Use when working with Skywalking — apache SkyWalking application performance
  monitoring platform for distributed tracing, service mesh observability,
  metric aggregation, and log analysis. Covers service topology, endpoint
  performance, trace analysis, alarm management, and infrastructure monitoring.
  Use when monitoring service health, investigating distributed traces,
  analyzing endpoint latency, or reviewing SkyWalking alarms.
connection_type: skywalking
preload: false
---

# SkyWalking Monitoring Skill

Query, analyze, and manage Apache SkyWalking observability data using the SkyWalking GraphQL API.

## API Overview

SkyWalking uses a GraphQL API at `https://<SKYWALKING_HOST>/graphql`.

### Core Helper Function

```bash
#!/bin/bash

sw_gql() {
    local query="$1"
    curl -s -X POST "${SKYWALKING_URL}/graphql" \
        -H "Content-Type: application/json" \
        ${SKYWALKING_AUTH:+-H "Authorization: Bearer $SKYWALKING_AUTH"} \
        -d "{\"query\": $(echo "$query" | jq -Rs .)}"
}

sw_duration() {
    local hours="${1:-1}"
    local end=$(date -u +"%Y-%m-%d %H%M")
    local start=$(date -u -d "${hours} hours ago" +"%Y-%m-%d %H%M")
    echo "{start: \"${start}\", end: \"${end}\", step: HOUR}"
}
```

## MANDATORY: Discovery-First Pattern

**Always discover services, endpoints, and instances before querying.**

### Phase 1: Discovery

```bash
#!/bin/bash
DUR=$(sw_duration 1)

echo "=== Services ==="
sw_gql "{
    getAllServices(duration: ${DUR}) {
        id name group
    }
}" | jq -r '.data.getAllServices[] | "\(.id)\t\(.name)\t\(.group // "default")"' | head -20

echo ""
echo "=== Service Instances ==="
SERVICE_ID="${1:-}"
[ -n "$SERVICE_ID" ] && sw_gql "{
    getServiceInstances(serviceId: \"${SERVICE_ID}\", duration: ${DUR}) {
        id name language instanceUUID
    }
}" | jq -r '.data.getServiceInstances[] | "\(.id)\t\(.name)\t\(.language // "unknown")"' | head -20

echo ""
echo "=== Endpoints (Top 20) ==="
[ -n "$SERVICE_ID" ] && sw_gql "{
    findEndpoint(serviceId: \"${SERVICE_ID}\", keyword: \"\", limit: 20) {
        id name
    }
}" | jq -r '.data.findEndpoint[] | "\(.id)\t\(.name)"' | head -20

echo ""
echo "=== Active Alarms ==="
sw_gql "{
    getAlarm(duration: ${DUR}, paging: {pageNum: 1, pageSize: 15}) {
        msgs {
            id message startTime scope
        }
    }
}" | jq -r '.data.getAlarm.msgs[] | "\(.startTime)\t\(.scope)\t\(.message[0:60])"' | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash
DUR=$(sw_duration 1)
SERVICE_ID="${1:?Service ID required}"

echo "=== Service Health (Golden Signals) ==="
sw_gql "{
    readMetricsValues(condition: {name: \"service_resp_time\", entity: {scope: Service, serviceName: \"${SERVICE_ID}\"}}, duration: ${DUR}) {
        values { values { value } }
    }
}" | jq -r '.data.readMetricsValues.values.values | map(.value) | "Avg Response Time: \(add / length)ms"'

sw_gql "{
    readMetricsValues(condition: {name: \"service_sla\", entity: {scope: Service, serviceName: \"${SERVICE_ID}\"}}, duration: ${DUR}) {
        values { values { value } }
    }
}" | jq -r '.data.readMetricsValues.values.values | map(.value) | "Success Rate: \(add / length / 100)%"'

sw_gql "{
    readMetricsValues(condition: {name: \"service_cpm\", entity: {scope: Service, serviceName: \"${SERVICE_ID}\"}}, duration: ${DUR}) {
        values { values { value } }
    }
}" | jq -r '.data.readMetricsValues.values.values | map(.value) | "Calls/min: \(add / length)"'

echo ""
echo "=== Topology (Dependencies) ==="
sw_gql "{
    getServiceTopology(serviceId: \"${SERVICE_ID}\", duration: ${DUR}) {
        nodes { id name type }
        calls { source target detectPoints }
    }
}" | jq -r '.data.getServiceTopology.calls[] | "\(.source) -> \(.target)\t\(.detectPoints | join(","))"' | head -15

echo ""
echo "=== Slow Endpoints ==="
sw_gql "{
    sortMetrics(condition: {name: \"endpoint_avg\", topN: 15, order: DES, parentService: \"${SERVICE_ID}\"}, duration: ${DUR}) {
        name value
    }
}" | jq -r '.data.sortMetrics[] | "\(.value)ms\t\(.name)"' | head -15
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines — use `topN` and `pageSize` for limiting results
- Duration format: `{start: "YYYY-MM-DD HHmm", end: "YYYY-MM-DD HHmm", step: HOUR}`
- Metric names: `service_resp_time`, `service_sla`, `service_cpm`, `endpoint_avg`
- Use `sortMetrics` for top-N analysis instead of fetching all metric values

## Output Format

Present results as a structured report:
```
Managing Skywalking Report
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

