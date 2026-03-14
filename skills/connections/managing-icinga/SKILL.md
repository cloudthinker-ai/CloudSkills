---
name: managing-icinga
description: |
  Icinga infrastructure monitoring platform for host and service monitoring, cluster management, alerting, and performance data analysis. Covers host/service status, check result review, notification management, downtime scheduling, and configuration object management via Icinga 2 API. Use when checking monitoring status, investigating alerts, managing downtimes, or querying Icinga objects.
connection_type: icinga
preload: false
---

# Icinga Monitoring Skill

Query, analyze, and manage Icinga monitoring data using the Icinga 2 API.

## API Overview

Icinga 2 uses a REST API at `https://<ICINGA_HOST>:5665/v1`.

### Core Helper Function

```bash
#!/bin/bash

icinga_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    if [ -n "$data" ]; then
        curl -s -k -X "$method" "https://${ICINGA_HOST}:5665/v1/${endpoint}" \
            -H "Authorization: Basic $(echo -n "${ICINGA_USER}:${ICINGA_PASS}" | base64)" \
            -H "Accept: application/json" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -k -X "$method" "https://${ICINGA_HOST}:5665/v1/${endpoint}" \
            -H "Authorization: Basic $(echo -n "${ICINGA_USER}:${ICINGA_PASS}" | base64)" \
            -H "Accept: application/json"
    fi
}
```

## MANDATORY: Discovery-First Pattern

**Always discover hosts, host groups, and services before querying.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Icinga Status ==="
icinga_api GET "status/IcingaApplication" | jq -r '.results[0].status.icingaapplication.app | "Version: \(.version)\nNode: \(.node_name)"'

echo ""
echo "=== Host Groups ==="
icinga_api GET "objects/hostgroups" | jq -r '.results[] | "\(.name)\t\(.attrs.display_name)"' | head -15

echo ""
echo "=== Hosts ==="
icinga_api GET "objects/hosts" | jq -r '.results[] | "\(.name)\t\(.attrs.state | if . == 0 then "UP" elif . == 1 then "DOWN" else "UNREACHABLE" end)\t\(.attrs.address)"' | head -25

echo ""
echo "=== Service Groups ==="
icinga_api GET "objects/servicegroups" | jq -r '.results[] | "\(.name)"' | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Host Problems ==="
icinga_api POST "objects/hosts" '{"filter": "host.state != 0"}' \
    | jq -r '.results[] | "\(if .attrs.state == 1 then "DOWN" else "UNREACHABLE" end)\t\(.name)\t\(.attrs.last_check_result.output[0:60])"' | head -15

echo ""
echo "=== Service Problems ==="
icinga_api POST "objects/services" '{"filter": "service.state != 0"}' \
    | jq -r '.results[] | "\(if .attrs.state == 1 then "WARNING" elif .attrs.state == 2 then "CRITICAL" else "UNKNOWN" end)\t\(.name)\t\(.attrs.last_check_result.output[0:50])"' | head -20

echo ""
echo "=== Status Summary ==="
echo "Hosts:"
icinga_api GET "status/CIB" | jq -r '.results[0].status | "  UP: \(.num_hosts_up)  DOWN: \(.num_hosts_down)  UNREACHABLE: \(.num_hosts_unreachable)"'
echo "Services:"
icinga_api GET "status/CIB" | jq -r '.results[0].status | "  OK: \(.num_services_ok)  WARN: \(.num_services_warning)  CRIT: \(.num_services_critical)  UNKNOWN: \(.num_services_unknown)"'

echo ""
echo "=== Active Downtimes ==="
icinga_api GET "objects/downtimes" | jq -r '.results[] | "\(.attrs.host_name)\t\(.attrs.service_name // "HOST")\t\(.attrs.author)\t\(.attrs.comment)"' | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines — use API filters and `head` in output
- Host states: 0=UP, 1=DOWN, 2=UNREACHABLE
- Service states: 0=OK, 1=WARNING, 2=CRITICAL, 3=UNKNOWN
- Use `filter` parameter in POST body for server-side filtering
