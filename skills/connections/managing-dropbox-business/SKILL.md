---
name: managing-dropbox-business
description: |
  Dropbox Business file storage and collaboration platform management covering files, folders, team members, sharing, and usage analytics. Use when monitoring storage usage, analyzing file activity, reviewing team member health, managing sharing permissions, or troubleshooting Dropbox Business sync and storage issues.
connection_type: dropbox-business
preload: false
---

# Dropbox Business Management Skill

Manage and analyze Dropbox Business resources including files, team members, sharing, and storage.

## API Conventions

### Authentication
All API calls use Bearer OAuth 2.0 token, injected automatically.

### Base URL
`https://api.dropboxapi.com/2`

### Core Helper Function

```bash
#!/bin/bash

dropbox_api() {
    local endpoint="$1"
    local data="${2:-}"

    curl -s -X POST \
        -H "Authorization: Bearer $DROPBOX_ACCESS_TOKEN" \
        -H "Content-Type: application/json" \
        "https://api.dropboxapi.com/2${endpoint}" \
        -d "${data:-null}"
}
```

## Output Rules
- Target ≤50 lines per script output
- Use `jq` to extract only needed fields
- Never dump full API responses

## Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Team Info ==="
dropbox_api "/team/get_info" '{}' \
    | jq '{name: .name, num_licensed_users: .num_licensed_users, num_provisioned_users: .num_provisioned_users}'

echo ""
echo "=== Team Members ==="
dropbox_api "/team/members/list_v2" '{"limit": 20}' \
    | jq -r '.members[] | "\(.profile.account_id[0:16])\t\(.profile.email)\t\(.profile.status[".tag"])\t\(.role[".tag"])"' \
    | column -t | head -20

echo ""
echo "=== Storage Usage ==="
dropbox_api "/team/get_info" '{}' \
    | jq '{
        team_name: .name,
        licensed: .num_licensed_users,
        provisioned: .num_provisioned_users
    }'

echo ""
echo "=== Root Namespace ==="
dropbox_api "/files/list_folder" '{"path": "", "limit": 20}' \
    | jq -r '.entries[] | "\(.[".tag"])\t\(.name[0:30])\t\(.size // "-")\t\(.server_modified[0:10] // "")"' \
    | column -t | head -15
```

## Phase 2: Analysis

### Team Health

```bash
#!/bin/bash
echo "=== Member Status Breakdown ==="
dropbox_api "/team/members/list_v2" '{"limit": 200}' \
    | jq -r '.members[] | .profile.status[".tag"]' | sort | uniq -c | sort -rn

echo ""
echo "=== Members by Role ==="
dropbox_api "/team/members/list_v2" '{"limit": 200}' \
    | jq -r '.members[] | .role[".tag"]' | sort | uniq -c | sort -rn

echo ""
echo "=== Suspended Members ==="
dropbox_api "/team/members/list_v2" '{"limit": 50}' \
    | jq -r '.members[] | select(.profile.status[".tag"] == "suspended") | "\(.profile.email)\t\(.profile.name.display_name)"' \
    | head -10

echo ""
echo "=== Invited (Pending) Members ==="
dropbox_api "/team/members/list_v2" '{"limit": 50}' \
    | jq -r '.members[] | select(.profile.status[".tag"] == "invited") | "\(.profile.email)"' | head -10
```

### Sharing & Activity

```bash
#!/bin/bash
echo "=== Shared Folders ==="
dropbox_api "/sharing/list_folders" '{"limit": 20}' \
    | jq -r '.entries[] | "\(.shared_folder_id)\t\(.name[0:30])\t\(.access_type[".tag"])\t\(.policy.acl_update_policy[".tag"])"' \
    | column -t | head -15

echo ""
echo "=== Team Activity (recent events) ==="
dropbox_api "/team_log/get_events" '{"limit": 20, "category": "file_operations"}' \
    | jq -r '.events[] | "\(.timestamp[0:16])\t\(.event_type[".tag"][0:25])\t\(.actor.user.email // "system")"' \
    | head -15

echo ""
echo "=== External Sharing ==="
dropbox_api "/sharing/list_shared_links" '{"direct_only": true}' \
    | jq -r '.links[] | "\(.name[0:25])\t\(.link_permissions.resolved_visibility[".tag"])\t\(.url[0:40])"' \
    | head -10
```

## Output Format

```
=== Team: <name> ===
Licensed: <n>  Provisioned: <n>

--- Members ---
Active: <n>  Suspended: <n>  Invited: <n>
Admins: <n>  Members: <n>

--- Sharing ---
Shared Folders: <n>  External Links: <n>

--- Activity (recent) ---
<timestamp>  <event_type>  <actor>
```

## Common Pitfalls
- **All POST**: Dropbox API uses POST for all endpoints, even reads
- **Tag format**: Enum values use `{".tag": "value"}` format in responses
- **Pagination**: Use `cursor` from response with `*_continue` endpoints; check `has_more`
- **Rate limits**: 1000 calls/5 minutes for team endpoints; check `Retry-After` header
- **Path format**: Use empty string `""` for root, or `/folder/subfolder` format
