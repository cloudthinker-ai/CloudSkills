---
name: managing-logdna
description: |
  LogDNA (now Mezmo) log management platform for log aggregation, search, alerting, and analysis. Covers log querying, view management, alert configuration, and usage monitoring. Use when searching LogDNA logs, investigating application issues through log data, managing views and alerts, or analyzing log ingestion volume.
connection_type: logdna
preload: false
---

# LogDNA Monitoring Skill

Query, analyze, and manage LogDNA log data using the LogDNA API.

## API Overview

LogDNA uses a REST API at `https://api.logdna.com`.

### Core Helper Function

```bash
#!/bin/bash

logdna_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    if [ -n "$data" ]; then
        curl -s -X "$method" "https://api.logdna.com/v1/${endpoint}" \
            -u "${LOGDNA_SERVICE_KEY}:" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "https://api.logdna.com/v1/${endpoint}" \
            -u "${LOGDNA_SERVICE_KEY}:"
    fi
}

logdna_v2() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    if [ -n "$data" ]; then
        curl -s -X "$method" "https://api.logdna.com/v2/${endpoint}" \
            -H "Authorization: Bearer $LOGDNA_SERVICE_KEY" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "https://api.logdna.com/v2/${endpoint}" \
            -H "Authorization: Bearer $LOGDNA_SERVICE_KEY"
    fi
}
```

## MANDATORY: Discovery-First Pattern

**Always discover available apps, hosts, and log levels before querying.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Usage Info ==="
logdna_api GET "usage/host" | jq -r '.[] | "\(.name)\t\(.lines) lines"' | sort -t$'\t' -k2 -rn | head -20

echo ""
echo "=== Available Apps ==="
logdna_api GET "usage/app" | jq -r '.[] | "\(.name)\t\(.lines) lines"' | sort -t$'\t' -k2 -rn | head -20

echo ""
echo "=== Views ==="
logdna_api GET "config/view" | jq -r '.[] | "\(.name)\t\(.query // "no query")"' | head -15

echo ""
echo "=== Alerts ==="
logdna_api GET "config/alert" | jq -r '.[] | "\(.name)\t\(.channels[0].type // "unknown")"' | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash
QUERY="${1:-level:error}"
FROM="${2:-$(date -d '1 hour ago' +%s)}"
TO="${3:-$(date +%s)}"

echo "=== Log Search: ${QUERY} ==="
logdna_api GET "export?query=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${QUERY}'))")&from=${FROM}&to=${TO}&size=50" \
    | jq -r '.lines[] | "\(._ts[0:19])\t\(._app)\t\(._line[0:80])"' | head -20

echo ""
echo "=== Log Volume by Host ==="
logdna_api GET "usage/host" | jq -r '.[] | "\(.name)\t\(.lines)"' | sort -t$'\t' -k2 -rn | head -15

echo ""
echo "=== Log Volume by Level ==="
logdna_api GET "usage/level" | jq -r '.[] | "\(.name)\t\(.lines)"' | sort -t$'\t' -k2 -rn | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines — use `size` parameter and `head` in output
- Filter at API level with `query` parameter before post-processing
- Use usage endpoints for volume analysis instead of counting raw log lines
