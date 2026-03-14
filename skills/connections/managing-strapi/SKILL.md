---
name: managing-strapi
description: |
  Strapi headless CMS management covering content type inventory, entry counts, media library analysis, role and permission auditing, webhook monitoring, and plugin status. Use when reviewing content models, investigating API access issues, monitoring content publishing, or auditing user permissions.
connection_type: strapi
preload: false
---

# Strapi Management Skill

Manage and monitor Strapi content types, entries, media, permissions, and plugins.

## MANDATORY: Discovery-First Pattern

**Always list content types and roles before querying specific entries.**

### Phase 1: Discovery

```bash
#!/bin/bash

STRAPI_API="${STRAPI_URL}/api"
STRAPI_ADMIN="${STRAPI_URL}/admin/api"

strapi_api() {
    curl -s -H "Authorization: Bearer $STRAPI_API_TOKEN" \
         -H "Content-Type: application/json" \
         "${STRAPI_API}/${1}"
}

strapi_admin() {
    curl -s -H "Authorization: Bearer $STRAPI_ADMIN_TOKEN" \
         -H "Content-Type: application/json" \
         "${STRAPI_ADMIN}/${1}"
}

echo "=== Content Types ==="
strapi_api "content-type-builder/content-types" | jq -r '
    .data[] |
    select(.uid | startswith("api::")) |
    "\(.uid)\t\(.schema.displayName)\t\(.schema.kind)\t\(.schema.attributes | keys | length) fields"
' | column -t | head -30

echo ""
echo "=== Admin Roles ==="
strapi_admin "roles" | jq -r '
    .data[] |
    "\(.id)\t\(.name)\t\(.usersCount) users"
' | column -t

echo ""
echo "=== Admin Users ==="
strapi_admin "users?pageSize=30" | jq -r '
    .data.results[] |
    "\(.email)\t\(.roles[0].name // "none")\t\(.isActive)\t\(.blocked)"
' | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Content Entry Counts ==="
strapi_api "content-type-builder/content-types" | jq -r '
    .data[] | select(.uid | startswith("api::")) | .uid
' | while read uid; do
    PLURAL=$(echo "$uid" | sed 's/api::\(.*\)\..*/\1s/')
    COUNT=$(strapi_api "${PLURAL}?pagination[pageSize]=1" | jq '.meta.pagination.total // 0')
    echo -e "${uid}\t${COUNT} entries"
done | column -t | head -20

echo ""
echo "=== Webhooks ==="
strapi_admin "webhooks" | jq -r '
    .data[] |
    "\(.id)\t\(.name)\t\(.isEnabled)\t\(.events | join(","))"
' | column -t

echo ""
echo "=== Media Library Stats ==="
strapi_api "upload/files?pagination[pageSize]=1" | jq '{
    total_files: .meta.pagination.total
}'
strapi_api "upload/files?sort=createdAt:desc&pagination[pageSize]=5" | jq -r '
    .results[] |
    "\(.name)\t\(.size)KB\t\(.mime)\t\(.createdAt[:10])"
' | column -t

echo ""
echo "=== Installed Plugins ==="
strapi_admin "plugins" | jq -r 'to_entries[] | "\(.key)\t\(.value.name)\t\(.value.enabled)"' | column -t
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Filter content types to exclude internal (strapi::, plugin::) types
- Never dump full entry content -- extract counts and schema metadata

## Common Pitfalls

- **Draft/publish**: Entries can be in draft state and not visible via public API -- check publishedAt
- **API token scopes**: API tokens have specific content-type permissions -- check token access
- **Webhook retries**: Strapi does not retry failed webhook deliveries by default
- **Media uploads**: Large media files consume storage -- monitor upload directory size
- **Locale variants**: Internationalized content creates separate entries per locale
- **Component reuse**: Shared components used across content types -- changes affect all users
- **Admin vs API tokens**: Admin tokens access admin panel; API tokens access content API -- different scopes
