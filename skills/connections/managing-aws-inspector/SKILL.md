---
name: managing-aws-inspector
description: |
  AWS Inspector vulnerability management and finding analysis. Covers Inspector v2 coverage, vulnerability findings, finding summaries, scan configurations, suppression rules, and coverage statistics. Use when auditing vulnerability posture, reviewing Inspector findings, checking scan coverage, or analyzing security vulnerabilities across EC2, ECR, and Lambda resources.
connection_type: aws
preload: false
---

# AWS Inspector Management Skill

Analyze and manage AWS Inspector v2 vulnerability scanning, findings, and coverage.

## MANDATORY: Discovery-First Pattern

**Always check coverage and account status before querying findings.**

### Phase 1: Discovery

```bash
#!/bin/bash
export AWS_PAGER=""

echo "=== Inspector Account Status ==="
aws inspector2 batch-get-account-status --output text \
  --query 'accounts[].[accountId,state.status,resourceState.ec2.status,resourceState.ecr.status,resourceState.lambda.status]' 2>/dev/null

echo ""
echo "=== Coverage Summary ==="
aws inspector2 list-coverage-statistics --output text \
  --query 'countsByGroup[].[groupKey,counts]' 2>/dev/null

echo ""
echo "=== Coverage Details ==="
aws inspector2 list-coverage --output text \
  --query 'coveredResources[].[resourceType,resourceId,scanStatus.statusCode,scanType]' 2>/dev/null | head -20

echo ""
echo "=== Finding Counts by Severity ==="
aws inspector2 list-finding-aggregations --aggregation-type SEVERITY --output text \
  --query 'responses[].[severityCounts]' 2>/dev/null
```

### Phase 2: Analysis

```bash
#!/bin/bash
export AWS_PAGER=""

echo "=== Critical Findings ==="
aws inspector2 list-findings \
  --filter-criteria '{"severity":[{"comparison":"EQUALS","value":"CRITICAL"}]}' \
  --max-results 10 --output text \
  --query 'findings[].[title,severity,status,type,resourceType]' 2>/dev/null | head -15

echo ""
echo "=== High Severity Findings ==="
aws inspector2 list-findings \
  --filter-criteria '{"severity":[{"comparison":"EQUALS","value":"HIGH"}]}' \
  --max-results 10 --output text \
  --query 'findings[].[title,severity,resourceType,firstObservedAt]' 2>/dev/null | head -15

echo ""
echo "=== Findings by Resource Type ==="
aws inspector2 list-finding-aggregations --aggregation-type RESOURCE_TYPE --output text \
  --query 'responses[]' 2>/dev/null | head -10

echo ""
echo "=== Findings by Package ==="
aws inspector2 list-finding-aggregations --aggregation-type PACKAGE --output text \
  --query 'responses[:10]' 2>/dev/null

echo ""
echo "=== ECR Image Findings ==="
aws inspector2 list-finding-aggregations --aggregation-type IMAGE_LAYER --output text \
  --query 'responses[:10]' 2>/dev/null

echo ""
echo "=== Suppression Rules ==="
aws inspector2 list-filters --output text \
  --query 'filters[].[name,arn,action,description]' 2>/dev/null | head -10

echo ""
echo "=== Delegated Admin ==="
aws inspector2 list-delegated-admin-accounts --output text \
  --query 'delegatedAdminAccounts[].[accountId,status]' 2>/dev/null

echo ""
echo "=== Members ==="
aws inspector2 list-members --output text \
  --query 'members[].[accountId,relationshipStatus]' 2>/dev/null | head -10
```

## Output Format

- Target ≤50 lines per output
- Use `--output text --query` for all commands
- Tab-delimited fields: Severity, Title, ResourceType, Status
- Aggregate findings by severity and resource type
- Never dump full vulnerability descriptions -- show title and severity only

## Common Pitfalls

- **Inspector v2 vs v1**: This skill covers Inspector v2 (inspector2 API) -- v1 (inspector API) is legacy
- **Coverage gaps**: Resources without SSM agent or ECR scan config won't be scanned -- check coverage API
- **Scan types**: EC2 (SSM-based), ECR (image scanning), Lambda (code scanning) -- each enabled separately
- **Finding status**: ACTIVE, SUPPRESSED, CLOSED -- suppressed findings still exist but are filtered
- **Filter criteria JSON**: Must use specific JSON format for filter-criteria -- check API docs for structure
- **Multi-account**: Delegated admin can manage findings across organization -- check delegation status
- **SBOM export**: Use `create-sbom-export` for software bill of materials -- async operation
- **Scan frequency**: ECR scans on push and periodically -- EC2 scans when new CVEs are published or packages change
