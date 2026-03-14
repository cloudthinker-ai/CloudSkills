---
name: managing-coolify
description: |
  Coolify self-hosted PaaS management covering application inventory, service status, deployment history, server resource utilization, database instances, S3 storage configurations, webhook settings, and team management. Use for managing Coolify-based infrastructure.
connection_type: coolify
preload: false
---

# Coolify Management

Analyze Coolify applications, services, deployments, and server health.

## Phase 1: Discovery

```bash
#!/bin/bash
TOKEN="${COOLIFY_API_TOKEN}"
BASE="${COOLIFY_BASE_URL:-https://app.coolify.io}/api/v1"
AUTH=(-H "Authorization: Bearer ${TOKEN}" -H "Accept: application/json")

echo "=== Servers ==="
curl -s "${BASE}/servers" "${AUTH[@]}" \
  | jq -r '.[] | "\(.id)\t\(.name)\t\(.ip)\t\(.settings.is_reachable)\t\(.settings.is_usable)"' \
  | column -t | head -10

echo ""
echo "=== Applications ==="
curl -s "${BASE}/applications" "${AUTH[@]}" \
  | jq -r '.[] | "\(.uuid)\t\(.name)\t\(.status)\t\(.fqdn // "no-domain")\t\(.build_pack)\t\(.git_repository // "dockerimage")"' \
  | column -t | head -20

echo ""
echo "=== Services ==="
curl -s "${BASE}/services" "${AUTH[@]}" \
  | jq -r '.[] | "\(.uuid)\t\(.name)\t\(.status)\t\(.type)"' \
  | column -t | head -20

echo ""
echo "=== Databases ==="
curl -s "${BASE}/databases" "${AUTH[@]}" \
  | jq -r '.[] | "\(.uuid)\t\(.name)\t\(.type)\t\(.status)\t\(.is_public)"' \
  | column -t | head -20

echo ""
echo "=== Teams ==="
curl -s "${BASE}/teams" "${AUTH[@]}" \
  | jq -r '.[] | "\(.id)\t\(.name)\t\(.members | length) members"' \
  | column -t
```

## Phase 2: Analysis

```bash
#!/bin/bash
TOKEN="${COOLIFY_API_TOKEN}"
BASE="${COOLIFY_BASE_URL:-https://app.coolify.io}/api/v1"
AUTH=(-H "Authorization: Bearer ${TOKEN}" -H "Accept: application/json")

echo "=== Application Details ==="
for APP_UUID in $(curl -s "${BASE}/applications" "${AUTH[@]}" | jq -r '.[].uuid'); do
  curl -s "${BASE}/applications/${APP_UUID}" "${AUTH[@]}" \
    | jq '{name, status, fqdn, build_pack, git_repository, git_branch, docker_compose_location, health_check_path, health_check_enabled, limits_memory, limits_cpus}' 2>/dev/null
done | head -30

echo ""
echo "=== Recent Deployments ==="
for APP_UUID in $(curl -s "${BASE}/applications" "${AUTH[@]}" | jq -r '.[].uuid'); do
  APP_NAME=$(curl -s "${BASE}/applications/${APP_UUID}" "${AUTH[@]}" | jq -r '.name')
  curl -s "${BASE}/applications/${APP_UUID}/deployments" "${AUTH[@]}" \
    | jq -r ".[:3][] | \"${APP_NAME}\t\(.status)\t\(.created_at)\t\(.deployment_uuid[0:8])\"" 2>/dev/null
done | column -t | head -20

echo ""
echo "=== Server Resources ==="
for SERVER_ID in $(curl -s "${BASE}/servers" "${AUTH[@]}" | jq -r '.[].id'); do
  curl -s "${BASE}/servers/${SERVER_ID}/resources" "${AUTH[@]}" \
    | jq '{server_id: "'${SERVER_ID}'", applications: (.applications | length), databases: (.databases | length), services: (.services | length)}' 2>/dev/null
done

echo ""
echo "=== Environment Variables (counts) ==="
for APP_UUID in $(curl -s "${BASE}/applications" "${AUTH[@]}" | jq -r '.[].uuid'); do
  APP_NAME=$(curl -s "${BASE}/applications/${APP_UUID}" "${AUTH[@]}" | jq -r '.name')
  COUNT=$(curl -s "${BASE}/applications/${APP_UUID}/envs" "${AUTH[@]}" | jq 'length' 2>/dev/null)
  echo "${APP_NAME}: ${COUNT:-0} env vars"
done

echo ""
echo "=== S3 Storage Configs ==="
curl -s "${BASE}/s3" "${AUTH[@]}" \
  | jq -r '.[] | "\(.name)\t\(.endpoint)\t\(.bucket)\t\(.is_usable)"' \
  | column -t
```

## Output Format

```
COOLIFY ANALYSIS
=================
App              Status   Build-Pack  Domain              Last Deploy  Health
──────────────────────────────────────────────────────────────────────────────
web-frontend     running  nixpacks    app.example.com     2h ago       enabled
api-backend      running  dockerfile  api.example.com     1d ago       enabled
worker           running  docker      none                3h ago       disabled

Servers: 2 reachable | Databases: 3 | Services: 2
Deployments: 15 recent (13 success, 2 failed)
```

## Safety Rules

- **Read-only**: Only use GET endpoints against the Coolify API
- **Never deploy, restart, or delete** applications without confirmation
- **Env vars**: Never output environment variable values, only counts
- **Self-hosted**: Ensure base URL points to the correct Coolify instance
