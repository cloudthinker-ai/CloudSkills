---
name: monitoring-splunk
description: |
  Splunk platform for log analytics, SPL queries, index management, saved searches, alerts, and dashboard analysis. Covers search job management, data model acceleration, KV store lookups, and forwarder health. Use when running SPL queries, investigating alerts, analyzing indexes, or managing Splunk resources via REST API.
connection_type: splunk
preload: false
---

# Splunk Monitoring Skill

Query, analyze, and manage Splunk resources using the Splunk REST API.

## MANDATORY: Read Before Any Splunk Operation

You MUST follow this skill before executing any Splunk API calls. It contains mandatory anti-hallucination rules, parallel execution patterns, and API conventions that prevent common errors.

## API Conventions

### Authentication
All Splunk API calls use Bearer token or Basic auth — injected automatically by the connection. Never hardcode credentials.

### Base URL
- Default: `https://<host>:8089`
- Use the connection-injected `SPLUNK_BASE_URL`. Always verify with the connection config.

### Output Rules
- **TOKEN EFFICIENCY**: Output must be minimal and aggregated — target <=50 lines
- Use `output_mode=json` on all API calls for consistent parsing
- Use `jq` to extract only needed fields from JSON responses
- NEVER dump full API responses — always extract specific fields

## Core Helper Function

```bash
#!/bin/bash

splunk_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -k -X "$method" \
            -H "Authorization: Bearer $SPLUNK_TOKEN" \
            "${SPLUNK_BASE_URL}${endpoint}?output_mode=json" \
            -d "$data"
    else
        curl -s -k -X "$method" \
            -H "Authorization: Bearer $SPLUNK_TOKEN" \
            "${SPLUNK_BASE_URL}${endpoint}?output_mode=json"
    fi
}

splunk_search() {
    local spl="$1"
    local earliest="${2:--1h}"
    local latest="${3:-now}"

    # Create search job
    local sid=$(splunk_api POST "/services/search/jobs" \
        "search=$(python3 -c "import urllib.parse; print(urllib.parse.quote('search ${spl}'))")&earliest_time=${earliest}&latest_time=${latest}" \
        | jq -r '.sid')

    # Wait for completion
    while true; do
        local state=$(splunk_api GET "/services/search/jobs/${sid}" | jq -r '.entry[0].content.dispatchState')
        [ "$state" = "DONE" ] && break
        sleep 1
    done

    # Get results
    splunk_api GET "/services/search/jobs/${sid}/results&count=100"
}
```

## Parallel Execution Requirement

ALL independent Splunk API calls MUST run in parallel using background jobs (&) and wait.

```bash
# CORRECT: Parallel index and saved search fetches
{
    splunk_api GET "/services/data/indexes" | jq '.entry[].name' &
    splunk_api GET "/services/saved/searches" | jq '.entry[].name' &
    splunk_api GET "/services/alerts/fired_alerts" | jq '.entry[].name' &
}
wait
```

## Anti-Hallucination Rules

**NEVER assume index names, sourcetypes, field names, or saved search names exist. ALWAYS discover first.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Available Indexes ==="
splunk_api GET "/services/data/indexes" \
    | jq -r '.entry[] | select(.content.totalEventCount != "0") | "\(.name)\t\(.content.totalEventCount) events\t\(.content.currentDBSizeMB)MB"' \
    | sort -t$'\t' -k2 -rn | head -20

echo "=== Sourcetypes ==="
splunk_search "| metadata type=sourcetypes | table sourcetype totalCount" "-24h" \
    | jq -r '.results[] | "\(.sourcetype)\t\(.totalCount)"' | sort -t$'\t' -k2 -rn | head -20

echo "=== Saved Searches ==="
splunk_api GET "/services/saved/searches" \
    | jq -r '.entry[] | "\(.name)\t\(.content.disabled)"' | head -20
```

### Phase 2: Query — Only after Phase 1 confirms resources exist

## Common Operations

### Index Health & Management

```bash
#!/bin/bash
echo "=== Index Summary ==="
{
    splunk_api GET "/services/data/indexes" \
        | jq -r '.entry[] | select(.content.totalEventCount != "0") | "\(.name)\t\(.content.totalEventCount)\t\(.content.currentDBSizeMB)MB\t\(.content.maxTotalDataSizeMB)MB max"' \
        | sort -t$'\t' -k3 -rn | head -15 &

    echo "=== Index Retention Settings ==="
    splunk_api GET "/services/data/indexes" \
        | jq -r '.entry[] | select(.content.totalEventCount != "0") | "\(.name)\t\(.content.frozenTimePeriodInSecs / 86400 | floor)d retention"' \
        | head -15 &
}
wait
```

### SPL Search & Log Analysis

```bash
#!/bin/bash
echo "=== Error Events (last 1h) ==="
splunk_search "index=* level=ERROR | stats count by index, sourcetype, host | sort -count" "-1h" \
    | jq -r '.results[] | "\(.index)\t\(.sourcetype)\t\(.host)\t\(.count)"' | head -20

echo ""
echo "=== Top Error Messages ==="
splunk_search "index=* level=ERROR | stats count by message | sort -count | head 10" "-1h" \
    | jq -r '.results[] | "\(.count)\t\(.message[0:80])"'
```

### Alert & Saved Search Management

```bash
#!/bin/bash
echo "=== Fired Alerts ==="
splunk_api GET "/services/alerts/fired_alerts" \
    | jq -r '.entry[] | "\(.name)\t\(.content.triggered_alert_count) fires"' | head -15

echo ""
echo "=== Scheduled Saved Searches ==="
splunk_api GET "/services/saved/searches" \
    | jq -r '.entry[] | select(.content.is_scheduled == "1") | "\(.name)\t\(.content.cron_schedule)\t\(.content.disabled)"' | head -20

echo ""
echo "=== Recently Triggered Alerts ==="
splunk_search "index=_audit action=alert_fired | stats count by ss_name, trigger_time | sort -trigger_time" "-24h" \
    | jq -r '.results[] | "\(.ss_name)\t\(.count)\t\(.trigger_time)"' | head -10
```

### Dashboard Analysis

```bash
#!/bin/bash
echo "=== Dashboards ==="
splunk_api GET "/servicesNS/-/-/data/ui/views" \
    | jq -r '.entry[] | "\(.name)\t\(.author)\t\(.updated)"' | head -20

echo ""
echo "=== Dashboard Search Panels ==="
DASHBOARD="${1:?Dashboard name required}"
splunk_api GET "/servicesNS/-/-/data/ui/views/${DASHBOARD}" \
    | jq -r '.entry[0].content["eai:data"]' | grep -oP '<query>[^<]+</query>' | head -10
```

### Forwarder & Input Health

```bash
#!/bin/bash
echo "=== Data Inputs ==="
{
    splunk_api GET "/services/data/inputs/monitor" \
        | jq -r '.entry[] | "\(.name)\t\(.content.disabled)"' | head -10 &

    echo "=== Forwarder Connections ==="
    splunk_search "index=_internal sourcetype=splunkd group=tcpin_connections | stats dc(hostname) as forwarders, sum(kb) as total_kb" "-1h" \
        | jq -r '.results[] | "Active forwarders: \(.forwarders), Data received: \(.total_kb)KB"' &
}
wait
```

## Common Pitfalls

- **Search prefix**: SPL queries via REST API must be prefixed with `search ` — the helper handles this
- **Async search jobs**: Searches are async — always poll `dispatchState` until `DONE` before fetching results
- **SSL verification**: Splunk uses self-signed certs by default — use `-k` flag with curl
- **Output mode**: Always add `output_mode=json` — default is XML which is harder to parse
- **Index permissions**: Users may not see all indexes — discovery phase catches permission gaps
- **Time format**: Use Splunk relative time (`-1h`, `-24h@h`) not Unix timestamps for search time ranges
- **Rate limits**: Limit concurrent search jobs to 5-10 to avoid scheduler congestion
- **KV Store**: Access via `/servicesNS/-/-/storage/collections/data/{collection}` — different endpoint pattern
