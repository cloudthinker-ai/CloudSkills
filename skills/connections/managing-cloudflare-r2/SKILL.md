---
name: managing-cloudflare-r2
description: |
  Cloudflare R2 object storage management via the wrangler CLI and Cloudflare API. Covers buckets, objects, usage metrics, CORS policies, and lifecycle rules. Use when managing R2 storage or reviewing bucket configurations.
connection_type: cloudflare-r2
preload: false
---

# Managing Cloudflare R2

Manage Cloudflare R2 object storage using `wrangler` CLI or Cloudflare API.

## MANDATORY: Discovery-First Pattern

**Always discover available resources before performing analysis.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== R2 Buckets ==="
wrangler r2 bucket list 2>/dev/null || \
curl -s "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/r2/buckets" \
    -H "Authorization: Bearer $CF_API_TOKEN" | jq -r '.result.buckets[] | "\(.name)\t\(.location)\t\(.creation_date)"' | head -20

echo ""
echo "=== Account R2 Usage ==="
curl -s "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/r2/usage" \
    -H "Authorization: Bearer $CF_API_TOKEN" | jq '{
    storage_bytes: .result.end.payload_size,
    metadata_bytes: .result.end.metadata_size,
    object_count: .result.end.object_count,
    upload_count: .result.end.upload_count
}' 2>/dev/null
```

### Phase 2: Analysis

```bash
#!/bin/bash

BUCKET_NAME="${1:?Bucket name required}"

echo "=== Bucket Objects (Top Level) ==="
wrangler r2 object list "$BUCKET_NAME" --prefix "" --delimiter "/" 2>/dev/null | head -30 || \
curl -s "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/r2/buckets/$BUCKET_NAME/objects" \
    -H "Authorization: Bearer $CF_API_TOKEN" | jq -r '.result.objects[] | "\(.key)\t\(.size)\t\(.last_modified)"' | head -30

echo ""
echo "=== Bucket CORS Policy ==="
curl -s "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/r2/buckets/$BUCKET_NAME/cors" \
    -H "Authorization: Bearer $CF_API_TOKEN" | jq '.result' 2>/dev/null | head -15

echo ""
echo "=== Bucket Lifecycle Rules ==="
curl -s "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/r2/buckets/$BUCKET_NAME/lifecycle" \
    -H "Authorization: Bearer $CF_API_TOKEN" | jq '.result' 2>/dev/null | head -15

echo ""
echo "=== Custom Domains ==="
curl -s "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/r2/buckets/$BUCKET_NAME/custom_domains" \
    -H "Authorization: Bearer $CF_API_TOKEN" | jq -r '.result[] | "\(.domain)\t\(.status)\t\(.enabled)"' 2>/dev/null | head -10

echo ""
echo "=== Sippy (Migration) Status ==="
curl -s "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/r2/buckets/$BUCKET_NAME/sippy" \
    -H "Authorization: Bearer $CF_API_TOKEN" | jq '.result' 2>/dev/null | head -10
```

## Output Format

```
BUCKET         LOCATION   CREATED              OBJECTS    SIZE
assets         APAC       2024-01-15T10:00:00  12450      45GB
backups        WNAM       2024-02-01T08:00:00  890        120GB
```

## Safety Rules
- Use read-only commands: `list`, GET API calls
- Never run `delete`, `put`, DELETE/PUT calls without explicit user confirmation
- Use jq for structured output parsing
- Limit output with `| head -N` to stay under 50 lines
