---
name: managing-manageengine-opmanager
description: |
  ManageEngine OpManager network monitoring platform for routers, switches, firewalls, servers, and virtual infrastructure. Covers device discovery, interface monitoring, alert management, performance dashboards, and report generation. Use when monitoring network device health, investigating interface utilization, reviewing alarms, or managing OpManager device inventory.
connection_type: manageengine-opmanager
preload: false
---

# ManageEngine OpManager Monitoring Skill

Query, analyze, and manage OpManager monitoring data using the OpManager REST API.

## API Overview

OpManager uses a REST API at `https://<OPMANAGER_HOST>/api/json`.

### Core Helper Function

```bash
#!/bin/bash

opm_api() {
    local endpoint="$1"
    local params="${2:-}"
    curl -s "${OPMANAGER_URL}/api/json/${endpoint}?apiKey=${OPMANAGER_API_KEY}&${params}"
}
```

## MANDATORY: Discovery-First Pattern

**Always discover devices, categories, and alarm profiles before querying.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Device Summary ==="
opm_api "device/listDevices" | jq -r '.data[] | "\(.deviceId)\t\(.deviceName)\t\(.ipAddress)\t\(.status)"' | head -25

echo ""
echo "=== Device Categories ==="
opm_api "device/getCategories" | jq -r '.data[] | "\(.categoryId)\t\(.categoryName)\tdevices:\(.deviceCount // 0)"' | head -15

echo ""
echo "=== Business Views ==="
opm_api "businessview/listBusinessViews" | jq -r '.data[] | "\(.bvId)\t\(.bvName)"' | head -15

echo ""
echo "=== Alarm Profiles ==="
opm_api "alarm/listAlarmProfiles" | jq -r '.data[] | "\(.profileId)\t\(.profileName)\t\(.severity)"' | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Active Alarms ==="
opm_api "alarm/listAlarms" "severity=critical&status=active" \
    | jq -r '.data[] | "\(.severity)\t\(.deviceName)\t\(.message[0:60])\t\(.modTime)"' | head -15

echo ""
echo "=== Down Devices ==="
opm_api "device/listDevices" "status=down" \
    | jq -r '.data[] | "\(.deviceName)\t\(.ipAddress)\t\(.category)\t\(.lastPollTime)"' | head -15

echo ""
echo "=== Interface Utilization (Top) ==="
opm_api "interface/listInterfaces" "sortBy=utilization&sortOrder=desc&limit=15" \
    | jq -r '.data[] | "\(.deviceName)\t\(.ifName)\tin:\(.rxUtil // 0)%\tout:\(.txUtil // 0)%"' | head -15

echo ""
echo "=== Alarm Summary ==="
opm_api "alarm/getAlarmSummary" | jq -r '"Critical: \(.critical // 0)\nWarning: \(.warning // 0)\nInfo: \(.info // 0)\nCleared: \(.cleared // 0)"'

echo ""
echo "=== Device Health (CPU/Memory) ==="
opm_api "device/getDeviceHealth" "limit=15" \
    | jq -r '.data[] | "\(.deviceName)\tcpu:\(.cpuUtil // "N/A")%\tmem:\(.memUtil // "N/A")%\tdisk:\(.diskUtil // "N/A")%"' | head -15
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines — use `status`, `severity`, and `limit` parameters
- Alarm severity: critical, warning, info, clear
- Device status: up, down, unknown, maintenance
- Use alarm summary endpoint for quick overview before drilling into individual alarms
