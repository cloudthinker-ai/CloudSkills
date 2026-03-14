---
name: managing-backblaze-b2
description: |
  Backblaze B2 cloud storage management via the b2 CLI. Covers buckets, files, lifecycle rules, keys, and usage statistics. Use when managing B2 storage or reviewing bucket configurations and costs.
connection_type: backblaze-b2
preload: false
---

# Managing Backblaze B2

Manage Backblaze B2 cloud storage using the `b2` CLI.

## MANDATORY: Discovery-First Pattern

**Always discover available resources before performing analysis.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Account Info ==="
b2 get-account-info 2>/dev/null | jq '{accountId, allowed: .allowed}' || echo "Run: b2 authorize-account"

echo ""
echo "=== Buckets ==="
b2 list-buckets --json 2>/dev/null | jq -r '.[] | "\(.bucketId)\t\(.bucketName)\t\(.bucketType)\t\(.revision)"' | head -20

echo ""
echo "=== Keys ==="
b2 list-keys 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

BUCKET_NAME="${1:?Bucket name required}"

echo "=== Bucket Details ==="
b2 get-bucket --show-size "$BUCKET_NAME" 2>/dev/null | jq '{
    bucketId, bucketName, bucketType, revision,
    options, defaultServerSideEncryption,
    fileLockConfiguration,
    totalSize: .totalSize,
    fileCount: .fileCount
}' | head -20

echo ""
echo "=== Recent Files ==="
b2 ls --long --recursive "$BUCKET_NAME" 2>/dev/null | head -30

echo ""
echo "=== Lifecycle Rules ==="
b2 get-bucket "$BUCKET_NAME" 2>/dev/null | jq '.lifecycleRules' | head -15

echo ""
echo "=== CORS Rules ==="
b2 get-bucket "$BUCKET_NAME" 2>/dev/null | jq '.corsRules' | head -15

echo ""
echo "=== Bucket Notification Rules ==="
b2 get-bucket "$BUCKET_NAME" 2>/dev/null | jq '.eventNotificationRules // []' | head -10

echo ""
echo "=== Large Unfinished Uploads ==="
b2 list-unfinished-large-files "$BUCKET_NAME" 2>/dev/null | head -10
```

## Output Format

```
BUCKET_ID                   BUCKET_NAME    TYPE       FILES    SIZE
abc123def456789             assets         allPublic  12450    45GB
ghi789jkl012345             backups        allPrivate 890      120GB
```

## Safety Rules
- Use read-only commands: `list-buckets`, `ls`, `get-bucket`, `get-account-info`
- Never run `delete-*`, `create-*`, `update-*` without explicit user confirmation
- Use `--json` with jq for structured output parsing
- Limit output with `| head -N` to stay under 50 lines
