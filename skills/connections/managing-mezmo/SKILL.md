---
name: managing-mezmo
description: |
  Mezmo (formerly LogDNA) observability pipeline and log management platform for log ingestion, routing, processing, and analysis. Covers log querying, pipeline management, view configuration, alerting, and usage analytics. Use when searching Mezmo logs, managing log pipelines, configuring alert rules, or analyzing ingestion patterns.
connection_type: mezmo
preload: false
---

# Mezmo Monitoring Skill

Query, analyze, and manage Mezmo log data and pipelines using the Mezmo API.

## API Overview

Mezmo uses REST APIs at `https://api.mezmo.com` for log management and `https://pipeline.mezmo.com` for pipeline operations.

### Core Helper Function

```bash
#!/bin/bash

mezmo_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    if [ -n "$data" ]; then
        curl -s -X "$method" "https://api.mezmo.com/v2/${endpoint}" \
            -H "Authorization: Bearer $MEZMO_SERVICE_KEY" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "https://api.mezmo.com/v2/${endpoint}" \
            -H "Authorization: Bearer $MEZMO_SERVICE_KEY"
    fi
}

mezmo_pipeline() {
    local method="$1"
    local endpoint="$2"
    curl -s -X "$method" "https://pipeline.mezmo.com/v1/${endpoint}" \
        -H "Authorization: Bearer $MEZMO_PIPELINE_KEY" \
        -H "Content-Type: application/json"
}
```

## MANDATORY: Discovery-First Pattern

**Always discover available sources, apps, and pipelines before querying.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Usage by App ==="
mezmo_api GET "usage/app" | jq -r '.[] | "\(.name)\t\(.lines) lines"' | sort -t$'\t' -k2 -rn | head -20

echo ""
echo "=== Usage by Host ==="
mezmo_api GET "usage/host" | jq -r '.[] | "\(.name)\t\(.lines) lines"' | sort -t$'\t' -k2 -rn | head -20

echo ""
echo "=== Views ==="
mezmo_api GET "config/view" | jq -r '.[] | "\(.name)\t\(.query // "no filter")"' | head -15

echo ""
echo "=== Pipelines ==="
mezmo_pipeline GET "pipelines" | jq -r '.data[] | "\(.id)\t\(.title)\t\(.status)"' | head -15

echo ""
echo "=== Alerts ==="
mezmo_api GET "config/alert" | jq -r '.[] | "\(.name)\t\(.active)"' | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Recent Error Logs ==="
mezmo_api GET "export?query=level%3Aerror&size=30" \
    | jq -r '.lines[] | "\(._ts[0:19])\t\(._app)\t\(._line[0:80])"' | head -20

echo ""
echo "=== Log Volume by Level ==="
mezmo_api GET "usage/level" | jq -r '.[] | "\(.name)\t\(.lines)"' | sort -t$'\t' -k2 -rn | head -10

echo ""
echo "=== Pipeline Health ==="
mezmo_pipeline GET "pipelines" \
    | jq -r '.data[] | "\(.title)\tstatus:\(.status)\tnodes:\(.nodes | length)"' | head -15

echo ""
echo "=== Top Ingestion Sources ==="
mezmo_api GET "usage/tag" | jq -r '.[] | "\(.name)\t\(.lines) lines"' | sort -t$'\t' -k2 -rn | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines — use `size` parameter and `head` in output
- Use usage endpoints for aggregated volume data
- Filter at query level before post-processing with jq
