---
name: managing-zabbix
description: |
  Zabbix enterprise monitoring platform for infrastructure, networks, servers, cloud resources, and applications. Covers host management, trigger and problem review, item data querying, template management, and alert configuration. Use when monitoring Zabbix hosts, investigating active problems, reviewing trigger states, or managing monitoring templates and actions.
connection_type: zabbix
preload: false
---

# Zabbix Monitoring Skill

Query, analyze, and manage Zabbix monitoring data using the Zabbix JSON-RPC API.

## API Overview

Zabbix uses a JSON-RPC API at `https://<ZABBIX_HOST>/api_jsonrpc.php`.

### Core Helper Function

```bash
#!/bin/bash

zx_api() {
    local method="$1"
    local params="$2"
    curl -s -X POST "${ZABBIX_URL}/api_jsonrpc.php" \
        -H "Content-Type: application/json" \
        -d "{
            \"jsonrpc\": \"2.0\",
            \"method\": \"${method}\",
            \"params\": ${params},
            \"auth\": \"${ZABBIX_API_TOKEN}\",
            \"id\": 1
        }" | jq -r '.result'
}
```

## MANDATORY: Discovery-First Pattern

**Always discover hosts, host groups, and templates before querying.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Host Groups ==="
zx_api "hostgroup.get" '{"output": ["groupid","name"], "sortfield": "name", "limit": 20}' \
    | jq -r '.[] | "\(.groupid)\t\(.name)"' | head -20

echo ""
echo "=== Monitored Hosts ==="
zx_api "host.get" '{"output": ["hostid","host","name","status"], "selectInterfaces": ["ip"], "limit": 25}' \
    | jq -r '.[] | "\(.hostid)\t\(.host)\t\(.interfaces[0].ip // "N/A")\t\(if .status == "0" then "enabled" else "disabled" end)"' | head -25

echo ""
echo "=== Active Problems ==="
zx_api "problem.get" '{"output": ["eventid","name","severity","clock"], "recent": true, "sortfield": "eventid", "sortorder": "DESC", "limit": 20}' \
    | jq -r '.[] | "\(.severity)\t\(.clock | tonumber | strftime("%Y-%m-%d %H:%M"))\t\(.name[0:60])"' | head -20

echo ""
echo "=== Templates ==="
zx_api "template.get" '{"output": ["templateid","name"], "sortfield": "name", "limit": 20}' \
    | jq -r '.[] | "\(.templateid)\t\(.name)"' | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Problems by Severity ==="
for sev in 5 4 3 2 1; do
    count=$(zx_api "problem.get" "{\"countOutput\": true, \"severities\": [${sev}]}")
    labels=("" "Info" "Warning" "Average" "High" "Disaster")
    echo "${labels[$sev]}: $count"
done

echo ""
echo "=== Top Hosts with Problems ==="
zx_api "problem.get" '{"output": ["name","severity"], "selectHosts": ["host"], "recent": true, "sortfield": "eventid", "sortorder": "DESC", "limit": 50}' \
    | jq -r '[.[] | .hosts[0].host // "unknown"] | group_by(.) | map({host: .[0], count: length}) | sort_by(-.count)[] | "\(.host)\t\(.count) problems"' | head -15

echo ""
echo "=== Host CPU/Memory (latest data) ==="
zx_api "item.get" '{"output": ["name","lastvalue","units"], "hostids": [], "search": {"key_": "system.cpu.util"}, "sortfield": "name", "limit": 15}' \
    | jq -r '.[] | "\(.name)\t\(.lastvalue)\(.units)"' | head -15

echo ""
echo "=== Trigger Status (PROBLEM state) ==="
zx_api "trigger.get" '{"output": ["description","priority","lastchange"], "filter": {"value": 1}, "sortfield": "lastchange", "sortorder": "DESC", "limit": 15}' \
    | jq -r '.[] | "\(.priority)\t\(.lastchange | tonumber | strftime("%Y-%m-%d %H:%M"))\t\(.description[0:60])"' | head -15
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines — use `limit` parameter and `countOutput` for aggregations
- Use problem.get for active issues overview before drilling into specific hosts
- Severity levels: 1=Info, 2=Warning, 3=Average, 4=High, 5=Disaster
