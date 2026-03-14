---
name: managing-nhost
description: |
  Nhost backend platform management covering project inventory, database status, authentication configuration, storage usage, serverless function deployments, Hasura GraphQL engine health, and environment variable auditing. Use for comprehensive Nhost project health and resource assessment.
connection_type: nhost
preload: false
---

# Nhost Management

Analyze Nhost projects, database health, auth config, storage, and serverless functions.

## Phase 1: Discovery

```bash
#!/bin/bash
TOKEN="${NHOST_PAT}"
BASE="https://app.nhost.io/api/v1"
AUTH=(-H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json")

echo "=== Projects Inventory ==="
curl -s "${BASE}/projects" "${AUTH[@]}" \
  | jq -r '.[] | "\(.id)\t\(.name)\t\(.region)\t\(.plan)\t\(.createdAt)"' \
  | column -t | head -20

echo ""
echo "=== Database Status ==="
for PROJ in $(curl -s "${BASE}/projects" "${AUTH[@]}" | jq -r '.[].id'); do
  NAME=$(curl -s "${BASE}/projects/${PROJ}" "${AUTH[@]}" | jq -r '.name')
  curl -s "${BASE}/projects/${PROJ}/database" "${AUTH[@]}" \
    | jq -r "\"${NAME}\t\(.status)\t\(.version)\t\(.size // \"N/A\")\"" 2>/dev/null
done | column -t | head -20

echo ""
echo "=== Auth Providers ==="
for PROJ in $(curl -s "${BASE}/projects" "${AUTH[@]}" | jq -r '.[].id'); do
  NAME=$(curl -s "${BASE}/projects/${PROJ}" "${AUTH[@]}" | jq -r '.name')
  curl -s "${BASE}/projects/${PROJ}/auth/providers" "${AUTH[@]}" \
    | jq -r "to_entries[] | \"${NAME}\t\(.key)\t\(.value.enabled)\"" 2>/dev/null
done | column -t | head -20

echo ""
echo "=== Storage Buckets ==="
for PROJ in $(curl -s "${BASE}/projects" "${AUTH[@]}" | jq -r '.[].id'); do
  NAME=$(curl -s "${BASE}/projects/${PROJ}" "${AUTH[@]}" | jq -r '.name')
  curl -s "${BASE}/projects/${PROJ}/storage/buckets" "${AUTH[@]}" \
    | jq -r ".[] | \"${NAME}\t\(.id)\t\(.maxUploadSize // \"default\")\t\(.presignedUrlsEnabled)\"" 2>/dev/null
done | column -t | head -20
```

## Phase 2: Analysis

```bash
#!/bin/bash
TOKEN="${NHOST_PAT}"
BASE="https://app.nhost.io/api/v1"
AUTH=(-H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json")

echo "=== Functions Deployed ==="
for PROJ in $(curl -s "${BASE}/projects" "${AUTH[@]}" | jq -r '.[].id'); do
  NAME=$(curl -s "${BASE}/projects/${PROJ}" "${AUTH[@]}" | jq -r '.name')
  curl -s "${BASE}/projects/${PROJ}/functions" "${AUTH[@]}" \
    | jq -r ".[] | \"${NAME}\t\(.path)\t\(.runtime)\t\(.status)\"" 2>/dev/null
done | column -t | head -20

echo ""
echo "=== Hasura GraphQL Status ==="
for PROJ in $(curl -s "${BASE}/projects" "${AUTH[@]}" | jq -r '.[].id'); do
  NAME=$(curl -s "${BASE}/projects/${PROJ}" "${AUTH[@]}" | jq -r '.name')
  curl -s "${BASE}/projects/${PROJ}/hasura" "${AUTH[@]}" \
    | jq -r "\"${NAME}\t\(.status)\t\(.version)\t\(.adminSecretSet)\"" 2>/dev/null
done | column -t

echo ""
echo "=== Environment Variables (names only) ==="
for PROJ in $(curl -s "${BASE}/projects" "${AUTH[@]}" | jq -r '.[].id'); do
  NAME=$(curl -s "${BASE}/projects/${PROJ}" "${AUTH[@]}" | jq -r '.name')
  COUNT=$(curl -s "${BASE}/projects/${PROJ}/env" "${AUTH[@]}" | jq 'length' 2>/dev/null)
  echo "${NAME}: ${COUNT:-0} env vars"
done

echo ""
echo "=== Deployment History ==="
for PROJ in $(curl -s "${BASE}/projects" "${AUTH[@]}" | jq -r '.[].id'); do
  NAME=$(curl -s "${BASE}/projects/${PROJ}" "${AUTH[@]}" | jq -r '.name')
  curl -s "${BASE}/projects/${PROJ}/deployments?limit=3" "${AUTH[@]}" \
    | jq -r ".[] | \"${NAME}\t\(.id[0:8])\t\(.status)\t\(.createdAt)\"" 2>/dev/null
done | column -t | head -20
```

## Output Format

```
NHOST ANALYSIS
================
Project          Region   Plan    DB Status  Hasura   Functions  Storage Buckets
──────────────────────────────────────────────────────────────────────────────
my-backend       eu-west  pro     running    healthy  4          2
staging-api      us-east  free    running    healthy  2          1

Auth Providers: 3 enabled | Env Vars: 18 across 2 projects
Deployments: 5 recent (all successful) | DB Version: PostgreSQL 15
```

## Safety Rules

- **Read-only**: Only use GET endpoints against the Nhost API
- **Never modify** database, auth config, or deployments without confirmation
- **Environment variables**: Never output values, only counts
- **Secrets**: Never expose admin secrets or API keys
