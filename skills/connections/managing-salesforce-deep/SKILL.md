---
name: managing-salesforce-deep
description: |
  Advanced Salesforce CRM management including objects, SOQL queries, reports, dashboards, flows, Apex triggers, API usage, org limits, deployment status, and user management. Covers org health monitoring, governor limit tracking, metadata analysis, and integration audit.
connection_type: salesforce-deep
preload: false
---

# Salesforce Deep Management Skill

Advanced monitoring and management of Salesforce orgs and CRM operations.

## MANDATORY: Discovery-First Pattern

**Always discover org limits and object schema before running SOQL queries.**

### Phase 1: Discovery

```bash
#!/bin/bash
SF_API="${SALESFORCE_INSTANCE_URL}/services/data/v60.0"
AUTH="Authorization: Bearer ${SALESFORCE_ACCESS_TOKEN}"

echo "=== Org Info ==="
curl -s -H "$AUTH" "${SALESFORCE_INSTANCE_URL}/services/data/" | \
  jq -r '.[-1] | "API Version: \(.version) | URL: \(.url)"'

echo ""
echo "=== Org Limits ==="
curl -s -H "$AUTH" "$SF_API/limits/" | \
  jq -r 'to_entries | map(select(.value.Remaining < (.value.Max * 0.2) and .value.Max > 0)) | .[] | "\(.key): \(.value.Remaining)/\(.value.Max) remaining"' | head -15

echo ""
echo "=== Key Object Counts ==="
for obj in Account Contact Opportunity Lead Case; do
  count=$(curl -s -H "$AUTH" "$SF_API/query/?q=SELECT+COUNT()+FROM+$obj" | jq '.totalSize')
  echo "$obj: $count"
done

echo ""
echo "=== Custom Objects ==="
curl -s -H "$AUTH" "$SF_API/sobjects/" | \
  jq -r '[.sobjects[] | select(.custom==true and .queryable==true)] | length | "Custom Objects: \(.)"'

echo ""
echo "=== Active Flows ==="
curl -s -H "$AUTH" "$SF_API/query/?q=SELECT+MasterLabel,ProcessType,Status+FROM+FlowDefinitionView+WHERE+IsActive=true+LIMIT+20" | \
  jq -r '.records[] | "\(.MasterLabel) | Type: \(.ProcessType) | Status: \(.Status)"'
```

**Phase 1 outputs:** API version, org limits, object counts, custom objects, active flows

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== API Usage (24h) ==="
curl -s -H "$AUTH" "$SF_API/limits/" | \
  jq -r '"Daily API Requests: \(.DailyApiRequests.Remaining)/\(.DailyApiRequests.Max)\nDaily Bulk API: \(.DailyBulkV2QueryJobs.Remaining)/\(.DailyBulkV2QueryJobs.Max)\nDaily Async Apex: \(.DailyAsyncApexExecutions.Remaining)/\(.DailyAsyncApexExecutions.Max)\nData Storage MB: \(.DataStorageMB.Remaining)/\(.DataStorageMB.Max)\nFile Storage MB: \(.FileStorageMB.Remaining)/\(.FileStorageMB.Max)"'

echo ""
echo "=== Pipeline Summary ==="
curl -s -H "$AUTH" "$SF_API/query/?q=SELECT+StageName,COUNT(Id),SUM(Amount)+FROM+Opportunity+WHERE+IsClosed=false+GROUP+BY+StageName" | \
  jq -r '.records[] | "\(.StageName): \(.expr0) deals, \(.expr1 // 0) total"'

echo ""
echo "=== Recent Deployments ==="
curl -s -H "$AUTH" "$SF_API/query/?q=SELECT+CreatedById,CreatedDate,Status,CompletedDate+FROM+DeployRequest+ORDER+BY+CreatedDate+DESC+LIMIT+5" | \
  jq -r '.records[] | "\(.Status) | Created: \(.CreatedDate) | Completed: \(.CompletedDate // "in progress")"'

echo ""
echo "=== Apex Test Results (recent) ==="
curl -s -H "$AUTH" "$SF_API/query/?q=SELECT+ApexClass.Name,Outcome,MethodName+FROM+ApexTestResult+ORDER+BY+SystemModstamp+DESC+LIMIT+10" | \
  jq -r '.records[] | "\(.ApexClass.Name).\(.MethodName): \(.Outcome)"'

echo ""
echo "=== Users Summary ==="
curl -s -H "$AUTH" "$SF_API/query/?q=SELECT+COUNT(Id)+FROM+User+WHERE+IsActive=true" | \
  jq -r '"Active Users: \(.records[0].expr0)"'
```

## Output Format

```
SALESFORCE DEEP STATUS
======================
Org: {instance} | API: v{version}
Active Users: {count}
API Requests: {remaining}/{max} remaining
Storage: Data={used}MB File={used}MB
Pipeline: {deals} open deals ({amount})
Limits at Risk: {list}
Recent Deployments: {count} ({status})
Active Flows: {count}
Issues: {list_of_warnings}
```

## Common Pitfalls

- **Governor limits**: Always check limits before bulk operations — org can be locked out
- **SOQL injection**: Parameterize queries — never concatenate user input
- **API version**: Different versions expose different fields — pin to a known version
- **Sandbox vs Production**: URLs differ — always verify instance URL
- **Bulk API**: Use Bulk 2.0 for large data operations — REST has 2000 record limit per query
