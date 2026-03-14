---
name: managing-neon
description: |
  Neon serverless Postgres management via the neonctl CLI and Neon API. Covers projects, branches, databases, roles, endpoints, and compute scaling. Use when managing Neon databases or reviewing branch workflows.
connection_type: neon
preload: false
---

# Managing Neon

Manage Neon serverless Postgres using the `neonctl` CLI or Neon API.

## MANDATORY: Discovery-First Pattern

**Always discover available resources before performing analysis.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Projects ==="
neonctl projects list --output json 2>/dev/null | jq -r '.[] | "\(.id)\t\(.name)\t\(.region_id)\t\(.pg_version)\t\(.created_at)"' | head -20

echo ""
echo "=== Branches ==="
for proj in $(neonctl projects list --output json 2>/dev/null | jq -r '.[].id'); do
    echo "--- Project: $proj ---"
    neonctl branches list --project-id "$proj" --output json 2>/dev/null | jq -r '.[] | "\(.id)\t\(.name)\t\(.primary)\t\(.current_state)\t\(.created_at)"' | head -10
done

echo ""
echo "=== Endpoints ==="
for proj in $(neonctl projects list --output json 2>/dev/null | jq -r '.[].id'); do
    echo "--- Project: $proj ---"
    neonctl endpoints list --project-id "$proj" --output json 2>/dev/null | jq -r '.[] | "\(.id)\t\(.branch_id)\t\(.type)\t\(.current_state)\t\(.host)"' | head -10
done

echo ""
echo "=== Databases ==="
for proj in $(neonctl projects list --output json 2>/dev/null | jq -r '.[].id'); do
    BRANCH=$(neonctl branches list --project-id "$proj" --output json 2>/dev/null | jq -r '.[0].id')
    echo "--- Project: $proj ---"
    neonctl databases list --project-id "$proj" --branch-id "$BRANCH" --output json 2>/dev/null | jq -r '.[] | "\(.name)\t\(.owner_name)"' | head -10
done
```

### Phase 2: Analysis

```bash
#!/bin/bash

PROJECT_ID="${1:?Project ID required}"

echo "=== Project Details ==="
neonctl projects get "$PROJECT_ID" --output json 2>/dev/null | jq '{
    id, name, region_id, pg_version,
    store_passwords, history_retention_seconds,
    compute_last_active_at, created_at, updated_at
}'

echo ""
echo "=== Branch Details ==="
neonctl branches list --project-id "$PROJECT_ID" --output json 2>/dev/null | jq '.[] | {
    id, name, primary, current_state,
    logical_size, data_transfer_bytes,
    created_at, updated_at
}' | head -30

echo ""
echo "=== Endpoint Compute ==="
neonctl endpoints list --project-id "$PROJECT_ID" --output json 2>/dev/null | jq '.[] | {
    id, type, current_state, host,
    autoscaling_limit_min_cu, autoscaling_limit_max_cu,
    suspend_timeout_seconds
}' | head -20

echo ""
echo "=== Roles ==="
BRANCH=$(neonctl branches list --project-id "$PROJECT_ID" --output json 2>/dev/null | jq -r '.[0].id')
neonctl roles list --project-id "$PROJECT_ID" --branch-id "$BRANCH" --output json 2>/dev/null | jq -r '.[] | "\(.name)\t\(.protected)\t\(.created_at)"' | head -10

echo ""
echo "=== Operations (Recent) ==="
neonctl operations list --project-id "$PROJECT_ID" --output json 2>/dev/null | jq -r '.[] | "\(.id)\t\(.action)\t\(.status)\t\(.created_at)\t\(.updated_at)"' | head -10
```

## Output Format

```
PROJECT_ID       NAME        REGION     PG_VERSION  CREATED
abc123def456     my-app-db   us-east-2  16          2024-01-15T10:00:00Z
```

## Safety Rules
- Use read-only commands: `list`, `get`
- Never run `delete`, `suspend`, `reset` without explicit user confirmation
- Use `--output json` with jq for structured output parsing
- Limit output with `| head -N` to stay under 50 lines
