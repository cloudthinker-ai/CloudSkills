---
name: managing-balena
description: |
  balena IoT fleet management including applications, devices, releases, services, environment variables, and device diagnostics. Covers fleet deployment status, device connectivity, container health, update progress, and resource utilization across edge devices.
connection_type: balena
preload: false
---

# balena Management Skill

Monitor and manage balena IoT fleet deployments and edge devices.

## MANDATORY: Discovery-First Pattern

**Always discover fleets and devices before querying service or release data.**

### Phase 1: Discovery

```bash
#!/bin/bash
BALENA_API="https://api.balena-cloud.com/v6"
AUTH="Authorization: Bearer ${BALENA_API_TOKEN}"

echo "=== User Info ==="
curl -s -H "$AUTH" "$BALENA_API/user/v1/whoami" | \
  jq -r '"Username: \(.username)\nEmail: \(.email)"' 2>/dev/null || \
curl -s -H "$AUTH" "https://api.balena-cloud.com/user/v1/whoami" | \
  jq -r '"Username: \(.username)"'

echo ""
echo "=== Fleets (Applications) ==="
curl -s -H "$AUTH" "$BALENA_API/application?\$select=app_name,slug,device_type,is_archived&\$filter=is_archived%20eq%20false" | \
  jq -r '.d[] | "\(.app_name) | Slug: \(.slug) | Device Type: \(.device_type) | Archived: \(.is_archived)"'

echo ""
echo "=== Devices ==="
curl -s -H "$AUTH" "$BALENA_API/device?\$select=device_name,uuid,is_online,os_version,supervisor_version,status&\$top=20" | \
  jq -r '.d[] | "\(.device_name) | Online: \(.is_online) | OS: \(.os_version) | Supervisor: \(.supervisor_version) | Status: \(.status)"'

echo ""
echo "=== Device Summary ==="
curl -s -H "$AUTH" "$BALENA_API/device?\$select=is_online" | \
  jq -r '"Total: \(.d | length)\nOnline: \([.d[] | select(.is_online==true)] | length)\nOffline: \([.d[] | select(.is_online==false)] | length)"'
```

**Phase 1 outputs:** User info, fleets, devices, connectivity

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Releases (latest per fleet) ==="
curl -s -H "$AUTH" "$BALENA_API/release?\$select=commit,status,created_at,release_version&\$orderby=created_at%20desc&\$top=10" | \
  jq -r '.d[] | "\(.commit[:8]) | Version: \(.release_version // "N/A") | Status: \(.status) | Created: \(.created_at)"'

echo ""
echo "=== Device OS Versions ==="
curl -s -H "$AUTH" "$BALENA_API/device?\$select=os_version" | \
  jq -r '[.d[].os_version] | group_by(.) | map({version: .[0], count: length}) | sort_by(-.count) | .[] | "\(.version): \(.count) devices"'

echo ""
echo "=== Services per Fleet ==="
curl -s -H "$AUTH" "$BALENA_API/service?\$select=service_name&\$expand=application(\$select=app_name)" | \
  jq -r '.d[] | "\(.application[0].app_name // "N/A") -> \(.service_name)"'

echo ""
echo "=== Device Environment Variables ==="
curl -s -H "$AUTH" "$BALENA_API/device_environment_variable?\$select=name,value&\$top=10" | \
  jq -r '.d[] | "\(.name)=\(.value[:30])"'

echo ""
echo "=== Update Status ==="
curl -s -H "$AUTH" "$BALENA_API/device?\$select=device_name,status,download_progress&\$filter=status%20ne%20%27Idle%27" | \
  jq -r '.d[] | "\(.device_name) | Status: \(.status) | Progress: \(.download_progress // "N/A")%"'
```

## Output Format

```
BALENA STATUS
=============
Fleets: {count}
Devices: {total} (Online: {online}, Offline: {offline})
Latest Release: {commit} ({status})
OS Versions: {unique_count} in fleet
Services: {count}
Updating Devices: {count}
Issues: {list_of_warnings}
```

## Common Pitfalls

- **OData query syntax**: balena API uses OData filters — URL-encode operators
- **Supervisor vs OS**: Supervisor manages containers; OS is the host — update separately
- **Multi-container**: Each fleet can have multiple services — check all containers
- **Offline devices**: Devices need to be online to receive updates — track connectivity
