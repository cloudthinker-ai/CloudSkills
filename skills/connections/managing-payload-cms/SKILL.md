---
name: managing-payload-cms
description: |
  Payload CMS management covering collection inventory, global configuration, access control analysis, media library monitoring, version and draft tracking, and webhook status. Use when reviewing content schemas, investigating access control issues, monitoring content publishing workflows, or auditing collection configurations.
connection_type: payload-cms
preload: false
---

# Payload CMS Management Skill

Manage and monitor Payload CMS collections, globals, access control, and content workflows.

## MANDATORY: Discovery-First Pattern

**Always list collections and globals before querying specific documents.**

### Phase 1: Discovery

```bash
#!/bin/bash

PAYLOAD_API="${PAYLOAD_URL}/api"

payload_api() {
    curl -s -H "Authorization: JWT $PAYLOAD_API_TOKEN" \
         -H "Content-Type: application/json" \
         "${PAYLOAD_API}/${1}"
}

echo "=== Payload Server ==="
payload_api "" | jq '{initialized: .initialized}'

echo ""
echo "=== Collections ==="
# Collections are defined in config -- query each known endpoint
for collection in users media pages posts; do
    RESULT=$(payload_api "${collection}?limit=0" 2>/dev/null)
    TOTAL=$(echo "$RESULT" | jq '.totalDocs // 0' 2>/dev/null)
    if [ "$TOTAL" != "0" ] || [ "$TOTAL" != "" ]; then
        echo -e "${collection}\t${TOTAL} docs"
    fi
done | column -t

echo ""
echo "=== Users ==="
payload_api "users?limit=30" | jq -r '
    .docs[] |
    "\(.id)\t\(.email)\t\(.role // "user")\t\(.createdAt[:10])"
' | column -t | head -20

echo ""
echo "=== Globals ==="
for global in site-settings navigation footer; do
    RESULT=$(payload_api "globals/${global}" 2>/dev/null)
    if echo "$RESULT" | jq -e '.id' >/dev/null 2>&1; then
        echo -e "${global}\tupdated: $(echo $RESULT | jq -r '.updatedAt[:10] // "unknown"')"
    fi
done | column -t
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Recent Content Activity ==="
for collection in pages posts; do
    payload_api "${collection}?limit=5&sort=-updatedAt" | jq -r --arg col "$collection" '
        .docs[]? |
        "\($col)\t\(.id)\t\(._status // "published")\t\(.updatedAt[:10])"
    '
done | column -t | head -20

echo ""
echo "=== Draft Content ==="
for collection in pages posts; do
    payload_api "${collection}?where[_status][equals]=draft&limit=10" | jq -r --arg col "$collection" '
        .docs[]? |
        "\($col)\t\(.id)\t\(.title // .name // "untitled")\tDRAFT"
    '
done | column -t | head -15

echo ""
echo "=== Media Library ==="
payload_api "media?limit=1" | jq '{total_files: .totalDocs}'
payload_api "media?limit=5&sort=-createdAt" | jq -r '
    .docs[] |
    "\(.filename)\t\(.filesize // 0)\t\(.mimeType)\t\(.createdAt[:10])"
' | column -t

echo ""
echo "=== Version History (latest) ==="
for collection in pages posts; do
    payload_api "${collection}?limit=3&sort=-updatedAt&draft=true" | jq -r --arg col "$collection" '
        .docs[]? |
        "\($col)\t\(.id)\tv\(._version // "?")\t\(._status // "published")"
    '
done | column -t | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Collection slugs must be known in advance -- Payload has no collection discovery endpoint
- Never dump full document content -- extract status, dates, and metadata

## Common Pitfalls

- **No collection discovery API**: Payload does not expose a list of collections via API -- refer to config
- **Draft system**: Collections with drafts enabled have _status field -- unpublished content is hidden from default queries
- **Access control**: Field-level and collection-level access control can restrict API responses silently
- **Hooks**: Before/after hooks run server-side and can modify data -- not visible via API
- **Upload collections**: Media collections require file upload handling -- check storage adapter config
- **Versions**: Version history can grow large -- consider auto-pruning old versions
