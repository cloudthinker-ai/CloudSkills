---
name: managing-box
description: |
  Box cloud content management platform covering files, folders, users, collaborations, metadata, and usage analytics. Use when monitoring storage usage, analyzing file activity, reviewing collaboration health, managing Box users and permissions, or troubleshooting content sharing issues.
connection_type: box
preload: false
---

# Box Management Skill

Manage and analyze Box cloud content resources including files, folders, users, and collaborations.

## API Conventions

### Authentication
All API calls use Bearer OAuth 2.0 token, injected automatically.

### Base URL
`https://api.box.com/2.0`

### Core Helper Function

```bash
#!/bin/bash

box_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $BOX_ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.box.com/2.0${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $BOX_ACCESS_TOKEN" \
            "https://api.box.com/2.0${endpoint}"
    fi
}
```

## Output Rules
- Target ≤50 lines per script output
- Use `jq` to extract only needed fields
- Never dump full API responses

## Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Current User ==="
box_api GET "/users/me" \
    | jq '{id: .id, name: .name, login: .login, space_amount: .space_amount, space_used: .space_used, status: .status}'

echo ""
echo "=== Root Folder Contents ==="
box_api GET "/folders/0/items?limit=20&fields=id,name,type,size,modified_at" \
    | jq -r '.entries[] | "\(.type)\t\(.id)\t\(.name[0:30])\t\(.size // "-")\t\(.modified_at[0:10] // "")"' \
    | column -t | head -20

echo ""
echo "=== Enterprise Users ==="
box_api GET "/users?limit=20&fields=id,name,login,status,space_used" \
    | jq -r '.entries[] | "\(.id)\t\(.name[0:20])\t\(.login)\t\(.status)\t\(.space_used) bytes"' \
    | column -t | head -15
```

## Phase 2: Analysis

### Storage & Usage

```bash
#!/bin/bash
echo "=== Storage Summary ==="
box_api GET "/users/me" \
    | jq '{
        space_used_gb: (.space_used / 1073741824 | . * 10 | floor / 10),
        space_total_gb: (.space_amount / 1073741824 | . * 10 | floor / 10),
        usage_pct: (.space_used / .space_amount * 100 | floor)
    }'

echo ""
echo "=== Enterprise Storage by User ==="
box_api GET "/users?limit=50&fields=name,login,space_used" \
    | jq -r '.entries[] | "\(.name[0:20])\t\(.login)\t\(.space_used / 1073741824 | . * 10 | floor / 10) GB"' \
    | sort -t$'\t' -k3 -rn | head -15

echo ""
echo "=== Recent Events ==="
box_api GET "/events?stream_type=admin_logs&limit=20&event_type=UPLOAD,DELETE,SHARE" \
    | jq -r '.entries[] | "\(.created_at[0:16])\t\(.event_type)\t\(.created_by.login[0:25])\t\(.source.name[0:25] // "?")"' \
    | head -15
```

### Collaboration Health

```bash
#!/bin/bash
echo "=== Shared Links (sample) ==="
box_api GET "/shared_items" 2>/dev/null || echo "Check shared links via folder/file endpoints"

echo ""
echo "=== Groups ==="
box_api GET "/groups?limit=20&fields=id,name,group_type" \
    | jq -r '.entries[] | "\(.id)\t\(.name)\t\(.group_type)"' | head -15

echo ""
echo "=== Recent Collaborations ==="
box_api GET "/folders/0/collaborations?limit=20" \
    | jq -r '.entries[] | "\(.accessible_by.login // "?")\t\(.role)\t\(.status)\t\(.created_at[0:10])"' \
    | head -15

echo ""
echo "=== Retention Policies ==="
box_api GET "/retention_policies?limit=10" \
    | jq -r '.entries[] | "\(.id)\t\(.policy_name[0:30])\t\(.policy_type)\t\(.status)"' | head -10
```

## Output Format

```
=== Box Account: <name> (<login>) ===
Storage: <used>GB / <total>GB (<pct>%)

--- Users ---
Total: <n>  Active: <n>

--- Activity (recent) ---
Uploads: <n>  Deletes: <n>  Shares: <n>

--- Collaborations ---
Groups: <n>  Active Collabs: <n>
```

## Common Pitfalls
- **Folder ID 0**: Root folder always has ID `0`
- **Fields parameter**: Use `fields` query param to select specific fields and avoid large responses
- **Rate limits**: 1000 API calls/minute for enterprise; 10 calls/second per user
- **Pagination**: Use `limit` and `offset`; check `total_count` in response
- **Admin events**: `admin_logs` stream type requires admin privileges
