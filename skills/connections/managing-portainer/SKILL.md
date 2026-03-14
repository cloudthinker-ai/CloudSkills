---
name: managing-portainer
description: |
  Portainer container management platform analysis covering environment endpoints, stack inventory, container status, image management, volume and network inspection, user and team access, and resource utilization across Docker and Kubernetes environments. Use for centralized container infrastructure oversight.
connection_type: portainer
preload: false
---

# Portainer Management

Analyze Portainer-managed environments, stacks, containers, and resource utilization.

## Phase 1: Discovery

```bash
#!/bin/bash
TOKEN="${PORTAINER_API_TOKEN}"
BASE="${PORTAINER_URL}/api"
AUTH=(-H "X-API-Key: ${TOKEN}")

echo "=== Endpoints (Environments) ==="
curl -s "${BASE}/endpoints" "${AUTH[@]}" \
  | jq -r '.[] | "\(.Id)\t\(.Name)\t\(.Type)\t\(.Status == 1 | if . then "up" else "down" end)\t\(.URL)"' \
  | column -t | head -20

echo ""
echo "=== Stacks ==="
curl -s "${BASE}/stacks" "${AUTH[@]}" \
  | jq -r '.[] | "\(.Id)\t\(.Name)\t\(.Type)\t\(.Status)\t\(.EndpointId)\t\(.CreationDate)"' \
  | column -t | head -20

echo ""
echo "=== Containers (per endpoint) ==="
for EP_ID in $(curl -s "${BASE}/endpoints" "${AUTH[@]}" | jq -r '.[].Id'); do
  EP_NAME=$(curl -s "${BASE}/endpoints/${EP_ID}" "${AUTH[@]}" | jq -r '.Name')
  curl -s "${BASE}/endpoints/${EP_ID}/docker/containers/json?all=true" "${AUTH[@]}" \
    | jq -r ".[] | \"${EP_NAME}\t\(.Names[0])\t\(.Image | split(\":\") | first | split(\"/\") | last)\t\(.State)\t\(.Status)\"" 2>/dev/null
done | column -t | head -30

echo ""
echo "=== Images ==="
for EP_ID in $(curl -s "${BASE}/endpoints" "${AUTH[@]}" | jq -r '.[].Id'); do
  EP_NAME=$(curl -s "${BASE}/endpoints/${EP_ID}" "${AUTH[@]}" | jq -r '.Name')
  curl -s "${BASE}/endpoints/${EP_ID}/docker/images/json" "${AUTH[@]}" \
    | jq -r ".[] | \"${EP_NAME}\t\(.RepoTags[0] // \"<none>\")\t\(.Size / 1048576 | floor)MB\"" 2>/dev/null
done | column -t | head -20
```

## Phase 2: Analysis

```bash
#!/bin/bash
TOKEN="${PORTAINER_API_TOKEN}"
BASE="${PORTAINER_URL}/api"
AUTH=(-H "X-API-Key: ${TOKEN}")

echo "=== Container Health ==="
for EP_ID in $(curl -s "${BASE}/endpoints" "${AUTH[@]}" | jq -r '.[].Id'); do
  EP_NAME=$(curl -s "${BASE}/endpoints/${EP_ID}" "${AUTH[@]}" | jq -r '.Name')
  TOTAL=$(curl -s "${BASE}/endpoints/${EP_ID}/docker/containers/json?all=true" "${AUTH[@]}" | jq 'length' 2>/dev/null)
  RUNNING=$(curl -s "${BASE}/endpoints/${EP_ID}/docker/containers/json" "${AUTH[@]}" | jq 'length' 2>/dev/null)
  UNHEALTHY=$(curl -s "${BASE}/endpoints/${EP_ID}/docker/containers/json?all=true&filters={\"health\":[\"unhealthy\"]}" "${AUTH[@]}" | jq 'length' 2>/dev/null)
  echo "${EP_NAME}: ${RUNNING}/${TOTAL} running, ${UNHEALTHY:-0} unhealthy"
done

echo ""
echo "=== Volumes ==="
for EP_ID in $(curl -s "${BASE}/endpoints" "${AUTH[@]}" | jq -r '.[].Id'); do
  EP_NAME=$(curl -s "${BASE}/endpoints/${EP_ID}" "${AUTH[@]}" | jq -r '.Name')
  curl -s "${BASE}/endpoints/${EP_ID}/docker/volumes" "${AUTH[@]}" \
    | jq -r ".Volumes[]? | \"${EP_NAME}\t\(.Name[0:30])\t\(.Driver)\t\(.Mountpoint[0:40])\"" 2>/dev/null
done | column -t | head -20

echo ""
echo "=== Networks ==="
for EP_ID in $(curl -s "${BASE}/endpoints" "${AUTH[@]}" | jq -r '.[].Id'); do
  EP_NAME=$(curl -s "${BASE}/endpoints/${EP_ID}" "${AUTH[@]}" | jq -r '.Name')
  curl -s "${BASE}/endpoints/${EP_ID}/docker/networks" "${AUTH[@]}" \
    | jq -r ".[] | \"${EP_NAME}\t\(.Name)\t\(.Driver)\t\(.Scope)\"" 2>/dev/null
done | column -t | head -20

echo ""
echo "=== Users & Teams ==="
curl -s "${BASE}/users" "${AUTH[@]}" \
  | jq -r '.[] | "\(.Id)\t\(.Username)\t\(.Role | if . == 1 then "admin" else "user" end)"' \
  | column -t
curl -s "${BASE}/teams" "${AUTH[@]}" \
  | jq -r '.[] | "\(.Id)\t\(.Name)"' | column -t

echo ""
echo "=== Resource Summary ==="
curl -s "${BASE}/status" "${AUTH[@]}" \
  | jq '{version: .Version, instanceID: .InstanceID}'
```

## Output Format

```
PORTAINER ANALYSIS
===================
Endpoint        Type    Status  Containers  Running  Unhealthy  Stacks
──────────────────────────────────────────────────────────────────────
prod-docker     docker  up      12          10       0          4
staging-swarm   swarm   up      8           8        1          3
dev-local       docker  up      5           3        0          2

Users: 5 (2 admin) | Teams: 3 | Portainer: v2.19.0
Total: 25 containers, 21 running, 1 unhealthy
```

## Safety Rules

- **Read-only**: Only use GET endpoints against the Portainer API
- **Never start, stop, or remove** containers or stacks without confirmation
- **Access control**: Ensure API token has appropriate scope for the endpoints queried
- **Rate limits**: No published rate limits but use reasonable request rates
