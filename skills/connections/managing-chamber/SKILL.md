---
name: managing-chamber
description: |
  Chamber secrets management using AWS Systems Manager Parameter Store, service-scoped secret organization, environment variable export, and parameter auditing. Covers reading and writing secrets by service, comparing environments, listing services, version tracking, and IAM permission validation. Use when managing AWS SSM-based secrets with Chamber, auditing parameter changes, or comparing configs across services.
connection_type: chamber
preload: false
---

# Chamber Management Skill

Manage and analyze secrets stored in AWS SSM Parameter Store using Chamber.

## Tool Conventions

### Prerequisites
`chamber` CLI must be installed and AWS credentials must be configured with appropriate SSM permissions.

### Core Commands
- `chamber list <service>` -- list secret keys for a service
- `chamber read <service> <key>` -- read a specific secret
- `chamber write <service> <key> <value>` -- write a secret
- `chamber export <service>` -- export all secrets as JSON

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields
- Target <=50 lines per script output
- **NEVER** output secret values -- only output key names and metadata
- Never dump full secret exports

## Discovery Phase

### List Services and Keys

```bash
#!/bin/bash
echo "=== Services (SSM Parameter Prefixes) ==="
aws ssm get-parameters-by-path --path "/" --recursive --query "Parameters[].Name" --output text \
    | tr '\t' '\n' | sed 's|^/||' | cut -d'/' -f1 | sort -u | head -25

echo ""
SERVICE="${1:?Service name required}"
echo "=== Secret Keys for ${SERVICE} ==="
chamber list "${SERVICE}" 2>/dev/null | head -25
```

### List Parameters with Metadata

```bash
#!/bin/bash
SERVICE="${1:?Service name required}"

echo "=== Parameters for ${SERVICE} ==="
chamber list -e "${SERVICE}" 2>/dev/null \
    | awk 'NR>1 {print $1"\t"$2"\t"$3}' | column -t | head -25

echo ""
echo "=== Parameter Count ==="
count=$(chamber list "${SERVICE}" 2>/dev/null | wc -l)
echo "${SERVICE}: $((count - 1)) parameters"
```

## Analysis Phase

### Compare Services

```bash
#!/bin/bash
SERVICE1="${1:?First service required}"
SERVICE2="${2:?Second service required}"

echo "=== Key Comparison ==="
KEYS1=$(chamber list "${SERVICE1}" 2>/dev/null | awk 'NR>1 {print $1}' | sort)
KEYS2=$(chamber list "${SERVICE2}" 2>/dev/null | awk 'NR>1 {print $1}' | sort)

echo "Keys in ${SERVICE1} only:"
comm -23 <(echo "$KEYS1") <(echo "$KEYS2") | head -10

echo ""
echo "Keys in ${SERVICE2} only:"
comm -13 <(echo "$KEYS1") <(echo "$KEYS2") | head -10

echo ""
echo "Common keys: $(comm -12 <(echo "$KEYS1") <(echo "$KEYS2") | wc -l)"
```

### Parameter History

```bash
#!/bin/bash
SERVICE="${1:?Service name required}"
KEY="${2:?Key name required}"

echo "=== Parameter Version History ==="
aws ssm get-parameter-history \
    --name "/${SERVICE}/${KEY}" \
    --query "Parameters[].{Version:Version,LastModified:LastModifiedDate,ModifiedBy:LastModifiedUser}" \
    --output table 2>/dev/null | head -20

echo ""
echo "=== Recent SSM Activity ==="
aws ssm describe-parameters \
    --parameter-filters "Key=Path,Option=Recursive,Values=/${SERVICE}" \
    --query "Parameters[].{Name:Name,Type:Type,Version:Version,Modified:LastModifiedDate}" \
    --output table 2>/dev/null | head -20
```

## Output Format
- Use tab-separated columns with `column -t`
- Limit lists to 15-25 items
- NEVER display secret values -- only key names and metadata
- Show summaries before details

## Common Pitfalls
- **Never expose values**: Only display parameter names and metadata, never values
- **Service = path prefix**: Chamber uses `/service/key` paths in SSM Parameter Store
- **IAM permissions**: Requires `ssm:GetParametersByPath`, `ssm:PutParameter`, `ssm:GetParameter` permissions
- **KMS encryption**: SecureString parameters require KMS decrypt permissions
- **Case sensitivity**: Chamber lowercases all key names
- **Rate limits**: AWS SSM has API rate limits -- avoid rapid bulk operations
