---
name: managing-seq
description: |
  Seq structured log server for centralized log collection, querying, dashboards, alerting, and retention management. Covers log searching with Seq query language, signal management, alert configuration, API key management, and workspace administration. Use when querying Seq logs, investigating structured events, managing signals and alerts, or reviewing log retention policies.
connection_type: seq
preload: false
---

# Seq Monitoring Skill

Query, analyze, and manage Seq structured log data using the Seq HTTP API.

## API Overview

Seq uses a REST API at `https://<SEQ_HOST>/api`.

### Core Helper Function

```bash
#!/bin/bash

seq_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    if [ -n "$data" ]; then
        curl -s -X "$method" "${SEQ_URL}/api/${endpoint}" \
            -H "X-Seq-ApiKey: $SEQ_API_KEY" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "${SEQ_URL}/api/${endpoint}" \
            -H "X-Seq-ApiKey: $SEQ_API_KEY"
    fi
}

seq_query() {
    local filter="$1"
    local count="${2:-30}"
    seq_api GET "events?filter=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${filter}'))")&count=${count}"
}
```

## MANDATORY: Discovery-First Pattern

**Always discover signals, dashboards, and API keys before querying.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Server Info ==="
seq_api GET "" | jq -r '"Version: \(.Version)\nInstance: \(.InstanceName)"'

echo ""
echo "=== Signals ==="
seq_api GET "signals" | jq -r '.[] | "\(.Id)\t\(.Title)\t\(.Filters[0].Filter // "no filter")"' | head -20

echo ""
echo "=== Dashboards ==="
seq_api GET "dashboards" | jq -r '.[] | "\(.Id)\t\(.Title)"' | head -15

echo ""
echo "=== Alert Configurations ==="
seq_api GET "alertconfigurations" | jq -r '.[] | "\(.Id)\t\(.Title)\t\(.NotificationAppInstanceId)"' | head -15

echo ""
echo "=== Retention Policies ==="
seq_api GET "retentionpolicies" | jq -r '.[] | "\(.Id)\t\(.RetentionTime)\t\(.DeletedAt // "active")"' | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Recent Error Events ==="
seq_query "@Level = 'Error'" 20 \
    | jq -r '.[] | "\(.Timestamp[0:19])\t\(.Properties["SourceContext"] // "unknown")\t\(.RenderedMessage[0:80])"' | head -20

echo ""
echo "=== Event Volume by Level ==="
seq_api GET "events/signal?signal=level" \
    | jq -r '.[] | "\(.Label)\t\(.Count)"' | head -10

echo ""
echo "=== Recent Warnings ==="
seq_query "@Level = 'Warning'" 15 \
    | jq -r '.[] | "\(.Timestamp[0:19])\t\(.RenderedMessage[0:80])"' | head -15

echo ""
echo "=== Active Alerts ==="
seq_api GET "alerts" | jq -r '.[] | "\(.Id)\t\(.State)\t\(.OwnerTitle)"' | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines — use `count` parameter and Seq filters
- Use Seq query language for filtering (e.g., `@Level = 'Error' and SourceContext like '%Payment%'`)
- Leverage signals for pre-defined log groupings instead of ad-hoc queries
