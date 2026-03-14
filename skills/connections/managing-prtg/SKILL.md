---
name: managing-prtg
description: |
  PRTG Network Monitor platform for network devices, bandwidth, servers, applications, and cloud services monitoring. Covers sensor status, device tree management, alert review, historic data analysis, and notification management. Use when monitoring PRTG sensors, investigating device issues, reviewing alarms, or analyzing bandwidth and performance data.
connection_type: prtg
preload: false
---

# PRTG Monitoring Skill

Query, analyze, and manage PRTG monitoring data using the PRTG HTTP API.

## API Overview

PRTG uses an HTTP API at `https://<PRTG_HOST>/api`.

### Core Helper Function

```bash
#!/bin/bash

prtg_api() {
    local endpoint="$1"
    local params="${2:-}"
    curl -s "${PRTG_URL}/api/${endpoint}?username=${PRTG_USER}&passhash=${PRTG_PASSHASH}&${params}&output=json"
}

prtg_table() {
    local content="$1"
    local columns="${2:-objid,name,status}"
    local count="${3:-50}"
    local filter="${4:-}"
    prtg_api "table.json" "content=${content}&columns=${columns}&count=${count}&${filter}"
}
```

## MANDATORY: Discovery-First Pattern

**Always discover groups, devices, and sensors before querying.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Server Status ==="
prtg_api "status.json" | jq -r '"Version: \(.Version)\nSensors: \(.Sensors)\nAlarms: \(.Alarms)\nUp: \(.UpSens) Down: \(.DownSens) Warning: \(.WarnSens)"'

echo ""
echo "=== Groups ==="
prtg_table "groups" "objid,name,active,totalsens" 20 \
    | jq -r '.groups[] | "\(.objid)\t\(.name)\tsensors:\(.totalsens)\t\(.active)"' | head -20

echo ""
echo "=== Devices ==="
prtg_table "devices" "objid,device,host,active,status" 25 \
    | jq -r '.devices[] | "\(.objid)\t\(.device)\t\(.host)\t\(.status)"' | head -25

echo ""
echo "=== Sensor Types ==="
prtg_table "sensors" "objid,name,sensor,status" 50 \
    | jq -r '[.sensors[].sensor] | group_by(.) | map({type: .[0], count: length}) | sort_by(-.count)[] | "\(.type)\t\(.count)"' | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Down Sensors ==="
prtg_table "sensors" "objid,name,device,status,message" 30 "filter_status=5" \
    | jq -r '.sensors[] | "\(.device)\t\(.name)\t\(.message[0:50])"' | head -15

echo ""
echo "=== Warning Sensors ==="
prtg_table "sensors" "objid,name,device,status,lastvalue" 20 "filter_status=4" \
    | jq -r '.sensors[] | "\(.device)\t\(.name)\t\(.lastvalue)"' | head -15

echo ""
echo "=== Alarms ==="
prtg_table "sensors" "objid,name,device,status,message,lastdown" 20 "filter_status=5&filter_status=4" \
    | jq -r '.sensors[] | "\(.status)\t\(.device)/\(.name)\t\(.message[0:50])"' | head -15

echo ""
echo "=== Top Bandwidth Sensors ==="
prtg_table "sensors" "objid,name,device,lastvalue" 15 "filter_type=snmptraffic" \
    | jq -r '.sensors[] | "\(.device)\t\(.name)\t\(.lastvalue)"' | head -15

echo ""
echo "=== System Health ==="
prtg_api "status.json" | jq -r '"Acknowledged: \(.AckAlarms)\nPartial Down: \(.PartialDownSens)\nPaused: \(.PausedSens)\nUnusual: \(.UnusualSens)"'
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines — use `count` and `filter_status` parameters
- Sensor status codes: 1=Unknown, 2=Scanning, 3=Up, 4=Warning, 5=Down, 7=NotUp, 8=Paused
- Use `filter_status` for server-side filtering of sensor states
- Use `columns` parameter to limit returned fields
