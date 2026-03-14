---
name: managing-cloud-custodian
description: |
  Cloud Custodian policy engine management. Covers policy authoring, dry-run execution, resource filtering, action enforcement, multi-cloud support (AWS/Azure/GCP), Lambda deployment, compliance reporting, and policy organization. Use when managing Cloud Custodian policies, auditing cloud resources, enforcing compliance rules, or reviewing policy execution results.
connection_type: cloud-custodian
preload: false
---

# Cloud Custodian Management Skill

Manage and inspect Cloud Custodian policies, resource filters, actions, and compliance reports.

## MANDATORY: Discovery-First Pattern

**Always run policies in dry-run mode before enforcing actions.**

### Phase 1: Discovery

```bash
#!/bin/bash
export AWS_PAGER=""

echo "=== Custodian Version ==="
custodian version 2>/dev/null

echo ""
echo "=== Policy Files ==="
find . -name "*.yml" -o -name "*.yaml" 2>/dev/null | while read f; do
    POLICIES=$(grep -c "^  - name:" "$f" 2>/dev/null || grep -c "^- name:" "$f" 2>/dev/null)
    [ "$POLICIES" -gt 0 ] && echo "$f: $POLICIES policies"
done | head -15

echo ""
echo "=== Policy Summary ==="
for f in $(find . -name "*.yml" -o -name "*.yaml" 2>/dev/null | head -5); do
    grep -E "^\s+- name:|^\s+resource:" "$f" 2>/dev/null | paste - - | head -10
done | head -20

echo ""
echo "=== Output Directory ==="
ls -la output/ 2>/dev/null | head -10 || echo "No output directory found"
```

### Phase 2: Analysis

```bash
#!/bin/bash
export AWS_PAGER=""

POLICY_FILE="${1:?Policy file required}"

echo "=== Validate Policies ==="
custodian validate "$POLICY_FILE" 2>&1 | tail -10

echo ""
echo "=== Dry Run ==="
custodian run --dryrun -s output/ "$POLICY_FILE" 2>&1 | tail -20

echo ""
echo "=== Resources Found ==="
for dir in output/*/; do
    POLICY_NAME=$(basename "$dir")
    COUNT=$(cat "$dir/resources.json" 2>/dev/null | jq 'length' 2>/dev/null || echo "0")
    echo "$POLICY_NAME: $COUNT resources matched"
done | head -15

echo ""
echo "=== Sample Matches ==="
for dir in output/*/; do
    POLICY_NAME=$(basename "$dir")
    echo "--- $POLICY_NAME ---"
    cat "$dir/resources.json" 2>/dev/null | jq '.[0:3][] | {id: (.ResourceId // .InstanceId // .BucketName // .Name // .id), type: (.ResourceType // .InstanceType // "N/A")}' 2>/dev/null | head -10
done | head -25
```

## Output Format

```
CLOUD CUSTODIAN STATUS: <policy-file>
Policies: <count> | Resource Types: <unique types>
Validation: <passed|failed>
Dry Run Results:
  <policy-name>: <count> resources matched
  <policy-name>: <count> resources matched
Actions: <list of actions configured>
Issues: <any validation errors, empty matches, or action warnings>
```

## Safety Rules

- **NEVER run policies without `--dryrun` first** -- always preview matched resources
- **NEVER use destructive actions** (terminate, delete) without explicit user confirmation
- **Always validate policy files** before running -- `custodian validate`
- **Review matched resources** from dry-run output before enabling enforcement
- **Test policies on non-production accounts** before deploying to production

## Common Pitfalls

- **Filter specificity**: Overly broad filters can match unintended resources -- always dry-run first
- **Action ordering**: Actions execute in order -- ensure dependent actions are sequenced correctly
- **Lambda deployment**: Deployed Lambda policies run on schedule -- ensure they have correct IAM permissions
- **Cross-account access**: Multi-account policies require assumed roles in target accounts
- **Output storage**: Output directories grow over time -- configure S3 output for long-term storage
- **Rate limiting**: Policies querying many resources can hit API rate limits -- use `max-resources` safety
- **Mode configuration**: Pull mode runs once; Lambda/periodic modes run continuously -- understand the difference
