---
name: managing-wasabi
description: |
  Wasabi cloud storage management via the AWS CLI (S3-compatible). Covers buckets, objects, versioning, lifecycle policies, and access control. Use when managing Wasabi storage or reviewing bucket configurations.
connection_type: wasabi
preload: false
---

# Managing Wasabi

Manage Wasabi cloud storage using the AWS CLI with Wasabi-compatible endpoints.

## MANDATORY: Discovery-First Pattern

**Always discover available resources before performing analysis.**

### Phase 1: Discovery

```bash
#!/bin/bash
export AWS_PAGER=""

WASABI_ENDPOINT="${WASABI_ENDPOINT:-https://s3.wasabisys.com}"

echo "=== Buckets ==="
aws s3api list-buckets --endpoint-url "$WASABI_ENDPOINT" \
    --query 'Buckets[*].[Name,CreationDate]' --output text | head -30

echo ""
echo "=== Bucket Regions ==="
for bucket in $(aws s3api list-buckets --endpoint-url "$WASABI_ENDPOINT" --query 'Buckets[*].Name' --output text); do
    region=$(aws s3api get-bucket-location --bucket "$bucket" --endpoint-url "$WASABI_ENDPOINT" --query 'LocationConstraint' --output text 2>/dev/null)
    echo "$bucket	$region"
done | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash
export AWS_PAGER=""

WASABI_ENDPOINT="${WASABI_ENDPOINT:-https://s3.wasabisys.com}"
BUCKET_NAME="${1:?Bucket name required}"

echo "=== Bucket Objects (sample) ==="
aws s3api list-objects-v2 --bucket "$BUCKET_NAME" --max-items 20 \
    --endpoint-url "$WASABI_ENDPOINT" \
    --query 'Contents[*].[Key,Size,LastModified,StorageClass]' --output text | head -20

echo ""
echo "=== Bucket Size Summary ==="
aws s3 ls "s3://$BUCKET_NAME" --summarize --recursive --endpoint-url "$WASABI_ENDPOINT" 2>/dev/null | tail -3

echo ""
echo "=== Versioning ==="
aws s3api get-bucket-versioning --bucket "$BUCKET_NAME" \
    --endpoint-url "$WASABI_ENDPOINT" --output text

echo ""
echo "=== Lifecycle Rules ==="
aws s3api get-bucket-lifecycle-configuration --bucket "$BUCKET_NAME" \
    --endpoint-url "$WASABI_ENDPOINT" \
    --query 'Rules[*].[ID,Status,Prefix]' --output text 2>/dev/null || echo "No lifecycle rules"

echo ""
echo "=== Bucket Policy ==="
aws s3api get-bucket-policy --bucket "$BUCKET_NAME" \
    --endpoint-url "$WASABI_ENDPOINT" --output text 2>/dev/null | jq '.' | head -15 || echo "No bucket policy"

echo ""
echo "=== CORS Configuration ==="
aws s3api get-bucket-cors --bucket "$BUCKET_NAME" \
    --endpoint-url "$WASABI_ENDPOINT" \
    --query 'CORSRules[*]' --output text 2>/dev/null || echo "No CORS configuration"

echo ""
echo "=== Bucket ACL ==="
aws s3api get-bucket-acl --bucket "$BUCKET_NAME" \
    --endpoint-url "$WASABI_ENDPOINT" \
    --query 'Grants[*].[Grantee.Type,Permission]' --output text
```

## Output Format

```
BUCKET           REGION        OBJECTS    TOTAL_SIZE
my-backups       us-east-1     12450      2.5TB
media-assets     eu-central-1  89340      500GB
```

## Safety Rules
- Use read-only commands: `list-*`, `get-*`, `ls`
- Never run `delete-*`, `put-*`, `rm` without explicit user confirmation
- Always include `--endpoint-url` for Wasabi endpoints
- Include `export AWS_PAGER=""` at script start
- Limit output with `| head -N` to stay under 50 lines
