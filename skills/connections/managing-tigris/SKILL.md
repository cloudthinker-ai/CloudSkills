---
name: managing-tigris
description: |
  Tigris globally distributed object storage management via the AWS CLI (S3-compatible) and Tigris dashboard API. Covers buckets, objects, regions, caching, and shadow buckets. Use when managing Tigris storage or reviewing global distribution.
connection_type: tigris
preload: false
---

# Managing Tigris

Manage Tigris object storage using the AWS CLI with Tigris-compatible endpoints.

## MANDATORY: Discovery-First Pattern

**Always discover available resources before performing analysis.**

### Phase 1: Discovery

```bash
#!/bin/bash
export AWS_PAGER=""

TIGRIS_ENDPOINT="https://fly.storage.tigris.dev"

echo "=== Buckets ==="
aws s3api list-buckets --endpoint-url "$TIGRIS_ENDPOINT" \
    --query 'Buckets[*].[Name,CreationDate]' --output text | head -20

echo ""
echo "=== Bucket Details ==="
for bucket in $(aws s3api list-buckets --endpoint-url "$TIGRIS_ENDPOINT" --query 'Buckets[*].Name' --output text); do
    objects=$(aws s3api list-objects-v2 --bucket "$bucket" --endpoint-url "$TIGRIS_ENDPOINT" --query 'KeyCount' --output text 2>/dev/null)
    echo "$bucket	objects=$objects"
done | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash
export AWS_PAGER=""

TIGRIS_ENDPOINT="https://fly.storage.tigris.dev"
BUCKET_NAME="${1:?Bucket name required}"

echo "=== Bucket Objects (sample) ==="
aws s3api list-objects-v2 --bucket "$BUCKET_NAME" --max-items 20 \
    --endpoint-url "$TIGRIS_ENDPOINT" \
    --query 'Contents[*].[Key,Size,LastModified]' --output text | head -20

echo ""
echo "=== Bucket Size Summary ==="
aws s3 ls "s3://$BUCKET_NAME" --summarize --recursive --endpoint-url "$TIGRIS_ENDPOINT" 2>/dev/null | tail -3

echo ""
echo "=== Versioning ==="
aws s3api get-bucket-versioning --bucket "$BUCKET_NAME" \
    --endpoint-url "$TIGRIS_ENDPOINT" --output text

echo ""
echo "=== Bucket ACL ==="
aws s3api get-bucket-acl --bucket "$BUCKET_NAME" \
    --endpoint-url "$TIGRIS_ENDPOINT" \
    --query 'Grants[*].[Grantee.Type,Permission]' --output text

echo ""
echo "=== CORS Configuration ==="
aws s3api get-bucket-cors --bucket "$BUCKET_NAME" \
    --endpoint-url "$TIGRIS_ENDPOINT" \
    --query 'CORSRules[*]' --output text 2>/dev/null || echo "No CORS configuration"

echo ""
echo "=== Lifecycle Rules ==="
aws s3api get-bucket-lifecycle-configuration --bucket "$BUCKET_NAME" \
    --endpoint-url "$TIGRIS_ENDPOINT" \
    --query 'Rules[*].[ID,Status]' --output text 2>/dev/null || echo "No lifecycle rules"

echo ""
echo "=== Bucket Website Configuration ==="
aws s3api get-bucket-website --bucket "$BUCKET_NAME" \
    --endpoint-url "$TIGRIS_ENDPOINT" --output text 2>/dev/null || echo "No website configuration"
```

## Output Format

```
BUCKET           OBJECTS    TOTAL_SIZE    CREATED
cdn-assets       12450      45GB          2024-01-15
app-uploads      890        12GB          2024-02-01
```

## Safety Rules
- Use read-only commands: `list-*`, `get-*`, `ls`
- Never run `delete-*`, `put-*`, `rm` without explicit user confirmation
- Always include `--endpoint-url` for Tigris endpoints
- Include `export AWS_PAGER=""` at script start
- Limit output with `| head -N` to stay under 50 lines
