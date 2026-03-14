---
name: managing-directus
description: |
  Directus headless CMS and data platform management covering collection inventory, field configuration, role and permission auditing, flow automation monitoring, webhook management, and file storage analysis. Use when reviewing data models, investigating API access issues, monitoring automation flows, or auditing user permissions.
connection_type: directus
preload: false
---

# Directus Management Skill

Manage and monitor Directus collections, permissions, flows, and data infrastructure.

## MANDATORY: Discovery-First Pattern

**Always list collections and roles before querying specific items or permissions.**

### Phase 1: Discovery

```bash
#!/bin/bash

DIRECTUS_API="${DIRECTUS_URL}"

directus_api() {
    curl -s -H "Authorization: Bearer $DIRECTUS_API_TOKEN" \
         -H "Content-Type: application/json" \
         "${DIRECTUS_API}/${1}"
}

echo "=== Directus Server Info ==="
directus_api "server/info" | jq '{project: .data.project.project_name, version: .data.directus.version}'

echo ""
echo "=== Collections ==="
directus_api "collections" | jq -r '
    .data[] |
    select(.collection | startswith("directus_") | not) |
    "\(.collection)\t\(.schema.comment // "")\t\(.meta.hidden)\t\(.meta.singleton)"
' | column -t | head -30

echo ""
echo "=== Roles ==="
directus_api "roles" | jq -r '
    .data[] |
    "\(.id)\t\(.name)\t\(.admin_access)\t\(.app_access)"
' | column -t

echo ""
echo "=== Users ==="
directus_api "users?limit=30" | jq -r '
    .data[] |
    "\(.email)\t\(.role)\t\(.status)\t\(.last_access // "never")"
' | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Permissions Summary ==="
directus_api "permissions?limit=200" | jq '
    .data | group_by(.role) | map({
        role: .[0].role,
        permissions: length,
        collections: [.[].collection] | unique | length
    })
'

echo ""
echo "=== Flows (Automations) ==="
directus_api "flows" | jq -r '
    .data[] |
    "\(.id)\t\(.name)\t\(.status)\t\(.trigger)"
' | column -t | head -15

echo ""
echo "=== Webhooks ==="
directus_api "webhooks" | jq -r '
    .data[] |
    "\(.id)\t\(.name)\t\(.status)\t\(.actions | join(","))\t\(.collections | join(","))"
' | column -t | head -15

echo ""
echo "=== File Storage ==="
directus_api "files?aggregate[count]=*" | jq '.data[0]'
directus_api "files?limit=5&sort=-uploaded_on" | jq -r '
    .data[] |
    "\(.id)\t\(.filename_download)\t\(.filesize)\t\(.uploaded_on[:10])"
' | column -t
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Filter collections to exclude system (directus_*) collections
- Never dump full item data -- extract schema and permission metadata

## Common Pitfalls

- **Public role**: The public role grants unauthenticated access -- audit its permissions carefully
- **Flow errors**: Failed flow operations are logged but do not surface as API errors
- **Relational fields**: M2M fields create junction collections -- include them in permission audits
- **Token expiry**: Static tokens do not expire but temporary tokens do -- check auth method
- **File permissions**: File access follows collection permissions -- misconfigured roles leak files
- **Singleton collections**: Singleton collections behave like settings -- only one item allowed
