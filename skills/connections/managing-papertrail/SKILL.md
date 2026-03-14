---
name: managing-papertrail
description: |
  Papertrail cloud-hosted log management for log aggregation, search, tail, alerting, and archiving. Covers log searching, system and group management, saved search alerts, and log volume analysis. Use when searching Papertrail logs, investigating incidents via log data, managing log groups and systems, or configuring log-based alerts.
connection_type: papertrail
preload: false
---

# Papertrail Monitoring Skill

Query, analyze, and manage Papertrail log data using the Papertrail API.

## API Overview

Papertrail uses a REST API at `https://papertrailapp.com/api/v1`.

### Core Helper Function

```bash
#!/bin/bash

pt_api() {
    local method="$1"
    local endpoint="$2"
    curl -s -X "$method" "https://papertrailapp.com/api/v1/${endpoint}" \
        -H "X-Papertrail-Token: $PAPERTRAIL_API_TOKEN"
}

pt_search() {
    local query="$1"
    local group_id="${2:-}"
    local params="q=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${query}'))")"
    [ -n "$group_id" ] && params="${params}&group_id=${group_id}"
    pt_api GET "events/search.json?${params}"
}
```

## MANDATORY: Discovery-First Pattern

**Always discover systems, groups, and saved searches before querying.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Systems ==="
pt_api GET "systems.json" | jq -r '.[] | "\(.id)\t\(.name)\t\(.hostname)\t\(.ip_address)"' | head -20

echo ""
echo "=== Groups ==="
pt_api GET "groups.json" | jq -r '.[] | "\(.id)\t\(.name)\tsystems:\(.system_count)"' | head -15

echo ""
echo "=== Saved Searches ==="
pt_api GET "searches.json" | jq -r '.[] | "\(.id)\t\(.name)\t\(.query)"' | head -15

echo ""
echo "=== Log Destinations ==="
pt_api GET "destinations.json" | jq -r '.[] | "\(.id)\t\(.type)\t\(.description // "N/A")"' | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash
QUERY="${1:-error}"

echo "=== Log Search: ${QUERY} ==="
pt_search "$QUERY" | jq -r '.events[] | "\(.received_at[0:19])\t\(.source_name)\t\(.message[0:80])"' | head -20

echo ""
echo "=== System Activity (recent logs) ==="
pt_api GET "systems.json" \
    | jq -r '.[] | "\(.name)\t\(.last_event_at // "never")"' \
    | sort -t$'\t' -k2 -r | head -15

echo ""
echo "=== Search Alerts ==="
pt_api GET "searches.json" \
    | jq -r '.[] | select(.alerts | length > 0) | "\(.name)\t\(.query)\talerts:\(.alerts | length)"' | head -10

echo ""
echo "=== Account Usage ==="
pt_api GET "accounts.json" | jq -r '"Plan: \(.plan.name)\nLog data rate: \(.log_data_transfer_used_percent // 0)%"'
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines — limit search results and use `head` in output
- Use system/group filtering to narrow log searches
- Prefer saved searches for recurring investigations
