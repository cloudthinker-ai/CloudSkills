---
name: managing-salesforce-deep
description: |
  Use when working with Salesforce Deep — advanced Salesforce CRM management
  including objects, SOQL queries, reports, dashboards, flows, Apex triggers,
  API usage, org limits, deployment status, and user management. Covers org
  health monitoring, governor limit tracking, metadata analysis, and integration
  audit.
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

## Anti-Hallucination Rules

1. **NEVER assume resource names** — always discover via CLI/API in Phase 1 before referencing in Phase 2.
2. **NEVER fabricate metric names or dimensions** — verify against the service documentation or `--help` output.
3. **NEVER mix CLI commands between service versions** — confirm which version/API you are targeting.
4. **ALWAYS use the discovery → verify → analyze chain** — every resource referenced must have been discovered first.
5. **ALWAYS handle empty results gracefully** — an empty response is valid data, not an error to retry.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

## Common Pitfalls

- **Governor limits**: Always check limits before bulk operations — org can be locked out
- **SOQL injection**: Parameterize queries — never concatenate user input
- **API version**: Different versions expose different fields — pin to a known version
- **Sandbox vs Production**: URLs differ — always verify instance URL
- **Bulk API**: Use Bulk 2.0 for large data operations — REST has 2000 record limit per query
