---
name: managing-device42
description: |
  Device42 IT infrastructure management covering data center infrastructure management (DCIM), application dependency mapping, IP address management, and asset lifecycle tracking. Use when documenting data center rack layouts and power chains, mapping application dependencies and communication flows, managing IP address allocation and subnets, or tracking hardware assets from procurement through decommission.
connection_type: device42
preload: false
---

# Device42 IT Infrastructure Management Skill

Manage and analyze Device42 DCIM, dependency mapping, IP management, and assets.

## API Conventions

### Authentication
All API calls use Basic Auth (username:password) — injected automatically.

### Base URL
`https://{{instance}}/api/1.0`

### Core Helper Function

```bash
#!/bin/bash

d42_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -u "$DEVICE42_USER:$DEVICE42_PASS" \
            -H "Content-Type: application/json" \
            "${DEVICE42_URL}/api/1.0${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -u "$DEVICE42_USER:$DEVICE42_PASS" \
            -H "Content-Type: application/json" \
            "${DEVICE42_URL}/api/1.0${endpoint}"
    fi
}
```

## Common Operations

### Data Center & Rack Management

```bash
#!/bin/bash
echo "=== Data Centers ==="
d42_api GET "/buildings/" \
    | jq -r '.buildings[] | "\(.building_id)\t\(.name)\t\(.address // "-")"' \
    | column -t

echo ""
echo "=== Racks ==="
d42_api GET "/racks/?limit=25" \
    | jq -r '.racks[] | "\(.rack_id)\t\(.name)\t\(.building)\t\(.row)\tU:\(.size)"' \
    | column -t

echo ""
echo "=== Rack Utilization ==="
d42_api GET "/racks/?limit=50" \
    | jq -r '.racks[] | "\(.name)\tTotal U: \(.size)\tUsed U: \(.u_used // 0)\tFree: \((.size // 0) - (.u_used // 0))"' \
    | column -t | head -20
```

### Application Dependency Mapping

```bash
#!/bin/bash
echo "=== Application Components ==="
d42_api GET "/appcomps/?limit=25" \
    | jq -r '.appcomps[] | "\(.appcomp_id)\t\(.name)\t\(.device_count // 0) devices"' \
    | column -t

echo ""
echo "=== Dependencies for Application ==="
APP_ID="${1:?App component ID required}"
d42_api GET "/appcomps/${APP_ID}/" \
    | jq -r '.depends_on[] | "\(.name)\t\(.type)"' | head -20
```

### IP Address Management

```bash
#!/bin/bash
echo "=== Subnets ==="
d42_api GET "/subnets/?limit=25" \
    | jq -r '.subnets[] | "\(.subnet_id)\t\(.network)/\(.mask_bits)\t\(.name // "-")\tUsed: \(.used_count // 0)/\(.total_count // 0)"' \
    | column -t

echo ""
echo "=== Available IPs in Subnet ==="
SUBNET_ID="${1:?Subnet ID required}"
d42_api GET "/ips/?subnet_id=${SUBNET_ID}&available=yes&limit=15" \
    | jq -r '.ips[] | "\(.ip)\t\(.label // "-")\t\(.available)"' \
    | column -t
```

### Device Management

```bash
#!/bin/bash
echo "=== Devices Summary ==="
d42_api GET "/devices/?limit=25&sort=last_updated&order=desc" \
    | jq -r '.Devices[] | "\(.device_id)\t\(.name)\t\(.type // "-")\t\(.os_name // "-")\t\(.last_updated[0:10])"' \
    | column -t

echo ""
echo "=== Devices by Type ==="
d42_api GET "/devices/?limit=500" \
    | jq -r '[.Devices[].type] | group_by(.) | map({type: (.[0] // "unknown"), count: length}) | sort_by(.count) | reverse | .[] | "\(.type): \(.count)"'
```

## Common Pitfalls

- **API versioning**: Use `/api/1.0/` prefix — some newer features may use `/api/2.0/`
- **Basic Auth only**: No OAuth support — always use HTTPS to protect credentials
- **Pagination**: Use `limit` and `offset` parameters — default limit varies by endpoint
- **Trailing slashes**: Some endpoints require trailing slashes — include them consistently
- **Custom fields**: Access via separate `/custom_fields/` endpoints — not inline with main object
- **DOQL**: Device42 Object Query Language provides SQL-like queries for complex reporting
- **Rate limits**: Self-hosted — depends on appliance sizing and configuration
- **Bulk operations**: Use batch endpoints for mass updates — individual updates for large datasets will be slow
