---
name: managing-portainer
description: |
  Use when working with Portainer — portainer container management platform
  analysis covering environment endpoints, stack inventory, container status,
  image management, volume and network inspection, user and team access, and
  resource utilization across Docker and Kubernetes environments. Use for
  centralized container infrastructure oversight.
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

## Anti-Hallucination Rules

1. **NEVER assume resource names** — always discover via CLI/API in Phase 1 before referencing in Phase 2.
2. **NEVER fabricate metric names or dimensions** — verify against the service documentation or `--help` output.
3. **NEVER mix CLI commands between service versions** — confirm which version/API you are targeting.
4. **ALWAYS use the discovery → verify → analyze chain** — every resource referenced must have been discovered first.
5. **ALWAYS handle empty results gracefully** — an empty response is valid data, not an error to retry.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

