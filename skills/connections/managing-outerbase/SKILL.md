---
name: managing-outerbase
description: |
  Use when working with Outerbase — outerbase database interface management
  covering workspace inventory, connected database sources, table schemas, query
  history, saved queries, API endpoint generation, dashboard configurations, and
  user access controls. Use for managing Outerbase-connected database
  environments.
connection_type: outerbase
preload: false
---

# Outerbase Management

Analyze Outerbase workspaces, database connections, schemas, and API configurations.

## Phase 1: Discovery

```bash
#!/bin/bash
TOKEN="${OUTERBASE_API_TOKEN}"
BASE="https://app.outerbase.com/api/v1"
AUTH=(-H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json")

echo "=== Workspaces ==="
curl -s "${BASE}/workspaces" "${AUTH[@]}" \
  | jq -r '.data[] | "\(.id)\t\(.name)\t\(.created_at)"' \
  | column -t | head -10

echo ""
echo "=== Database Sources ==="
for WS_ID in $(curl -s "${BASE}/workspaces" "${AUTH[@]}" | jq -r '.data[].id'); do
  curl -s "${BASE}/workspaces/${WS_ID}/sources" "${AUTH[@]}" \
    | jq -r ".data[] | \"${WS_ID}\t\(.id)\t\(.name)\t\(.type)\t\(.status // \"connected\")\"" 2>/dev/null
done | column -t | head -20

echo ""
echo "=== Tables per Source ==="
for WS_ID in $(curl -s "${BASE}/workspaces" "${AUTH[@]}" | jq -r '.data[].id'); do
  for SRC_ID in $(curl -s "${BASE}/workspaces/${WS_ID}/sources" "${AUTH[@]}" | jq -r '.data[].id' 2>/dev/null); do
    SRC_NAME=$(curl -s "${BASE}/workspaces/${WS_ID}/sources/${SRC_ID}" "${AUTH[@]}" | jq -r '.data.name' 2>/dev/null)
    curl -s "${BASE}/workspaces/${WS_ID}/sources/${SRC_ID}/tables" "${AUTH[@]}" \
      | jq -r ".data[]? | \"${SRC_NAME}\t\(.name)\t\(.row_count // \"N/A\") rows\"" 2>/dev/null
  done
done | column -t | head -30

echo ""
echo "=== Workspace Members ==="
for WS_ID in $(curl -s "${BASE}/workspaces" "${AUTH[@]}" | jq -r '.data[].id'); do
  curl -s "${BASE}/workspaces/${WS_ID}/members" "${AUTH[@]}" \
    | jq -r ".data[] | \"${WS_ID}\t\(.email)\t\(.role)\"" 2>/dev/null
done | column -t | head -15
```

## Phase 2: Analysis

```bash
#!/bin/bash
TOKEN="${OUTERBASE_API_TOKEN}"
BASE="https://app.outerbase.com/api/v1"
AUTH=(-H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json")

echo "=== Saved Queries ==="
for WS_ID in $(curl -s "${BASE}/workspaces" "${AUTH[@]}" | jq -r '.data[].id'); do
  curl -s "${BASE}/workspaces/${WS_ID}/queries" "${AUTH[@]}" \
    | jq -r ".data[]? | \"${WS_ID}\t\(.name)\t\(.created_by // \"unknown\")\t\(.updated_at)\"" 2>/dev/null
done | column -t | head -20

echo ""
echo "=== API Endpoints ==="
for WS_ID in $(curl -s "${BASE}/workspaces" "${AUTH[@]}" | jq -r '.data[].id'); do
  curl -s "${BASE}/workspaces/${WS_ID}/apis" "${AUTH[@]}" \
    | jq -r ".data[]? | \"${WS_ID}\t\(.name)\t\(.method)\t\(.path)\t\(.is_active)\"" 2>/dev/null
done | column -t | head -20

echo ""
echo "=== Dashboards ==="
for WS_ID in $(curl -s "${BASE}/workspaces" "${AUTH[@]}" | jq -r '.data[].id'); do
  curl -s "${BASE}/workspaces/${WS_ID}/dashboards" "${AUTH[@]}" \
    | jq -r ".data[]? | \"${WS_ID}\t\(.name)\t\(.widgets | length) widgets\t\(.updated_at)\"" 2>/dev/null
done | column -t | head -15

echo ""
echo "=== Connection Health ==="
for WS_ID in $(curl -s "${BASE}/workspaces" "${AUTH[@]}" | jq -r '.data[].id'); do
  for SRC_ID in $(curl -s "${BASE}/workspaces/${WS_ID}/sources" "${AUTH[@]}" | jq -r '.data[].id' 2>/dev/null); do
    SRC_NAME=$(curl -s "${BASE}/workspaces/${WS_ID}/sources/${SRC_ID}" "${AUTH[@]}" | jq -r '.data.name' 2>/dev/null)
    STATUS=$(curl -s "${BASE}/workspaces/${WS_ID}/sources/${SRC_ID}/test" "${AUTH[@]}" | jq -r '.success // "unknown"' 2>/dev/null)
    echo "${SRC_NAME}: ${STATUS}"
  done
done
```

## Output Format

```
OUTERBASE ANALYSIS
===================
Workspace        Sources  Tables  Queries  APIs   Dashboards  Members
──────────────────────────────────────────────────────────────────────
production       2        45      12       5      3           4
staging          1        30      8        2      1           2

Database Types: postgres(2) mysql(1)
Connection Health: 3/3 connected | API Endpoints: 7 active
```

## Safety Rules

- **Read-only**: Only use GET endpoints against the Outerbase API
- **Never execute queries** or modify schemas without explicit confirmation
- **Connection strings**: Never output database credentials or connection strings
- **Access control**: Verify API token scope matches intended workspace access

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

