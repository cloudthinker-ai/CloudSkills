---
name: managing-sourcegraph
description: |
  Sourcegraph code intelligence platform management covering repository indexing status, code search capabilities, batch change tracking, code insights monitoring, precise code intelligence status, and user access auditing. Use when investigating search indexing issues, monitoring batch change progress, reviewing code intelligence coverage, or auditing instance configuration.
connection_type: sourcegraph
preload: false
---

# Sourcegraph Management Skill

Manage and monitor Sourcegraph repositories, search indexes, batch changes, and code intelligence.

## MANDATORY: Discovery-First Pattern

**Always check instance health and repository status before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash

SG_API="${SOURCEGRAPH_URL}/.api"

sg_gql() {
    curl -s -H "Authorization: token $SOURCEGRAPH_TOKEN" \
         -H "Content-Type: application/json" \
         "${SG_API}/graphql" \
         -d "{\"query\": \"$1\"}"
}

sg_api() {
    curl -s -H "Authorization: token $SOURCEGRAPH_TOKEN" \
         "${SG_API}/${1}"
}

echo "=== Sourcegraph Instance ==="
sg_gql "{ site { productVersion configuration { effectiveContents } } }" | jq '{
    version: .data.site.productVersion
}'

echo ""
echo "=== External Services ==="
sg_gql "{ externalServices(first: 20) { nodes { displayName kind lastSyncAt lastSyncError } } }" | jq -r '
    .data.externalServices.nodes[] |
    "\(.displayName)\t\(.kind)\t\(.lastSyncAt[:16] // "never")\t\(.lastSyncError // "ok" | .[0:30])"
' | column -t

echo ""
echo "=== Repositories (indexed) ==="
sg_gql "{ repositories(first: 30, indexed: true, orderBy: REPOSITORY_NAME) { totalCount nodes { name } } }" | jq -r '
    "Total indexed: \(.data.repositories.totalCount)",
    (.data.repositories.nodes[] | .name)
' | head -20

echo ""
echo "=== Users ==="
sg_gql "{ users(first: 20) { totalCount nodes { username emails { email } siteAdmin createdAt } } }" | jq -r '
    .data.users.nodes[] |
    "\(.username)\t\(.emails[0].email // "")\tadmin=\(.siteAdmin)\t\(.createdAt[:10])"
' | column -t | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Index Status ==="
sg_gql "{ repositories(first: 10, indexed: false) { totalCount nodes { name } } }" | jq -r '
    "Unindexed repos: \(.data.repositories.totalCount)",
    (.data.repositories.nodes[] | "\(.name)\tNOT INDEXED")
' | head -15

echo ""
echo "=== Batch Changes ==="
sg_gql "{ batchChanges(first: 15) { nodes { name state createdAt namespace { namespaceName } changesetsStats { total open merged closed failed } } } }" | jq -r '
    .data.batchChanges.nodes[] |
    "\(.name)\t\(.state)\topen=\(.changesetsStats.open)\tmerged=\(.changesetsStats.merged)\tfailed=\(.changesetsStats.failed)"
' | column -t | head -15

echo ""
echo "=== Code Insights ==="
sg_gql "{ insightViews(first: 10) { nodes { id title } } }" 2>/dev/null | jq -r '
    .data.insightViews.nodes[]? |
    "\(.id)\t\(.title)"
' | column -t | head -10

echo ""
echo "=== External Service Errors ==="
sg_gql "{ externalServices(first: 20) { nodes { displayName lastSyncError } } }" | jq -r '
    .data.externalServices.nodes[] |
    select(.lastSyncError != null and .lastSyncError != "") |
    "\(.displayName)\tERROR: \(.lastSyncError[:60])"
' | column -t
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use GraphQL field selection to minimize response size
- Never dump full file contents or large search results -- extract counts and status

## Common Pitfalls

- **Index lag**: New repositories take time to index -- check cloning and indexing queue
- **External service sync**: Sync errors prevent repository discovery -- fix external service config
- **Precise code intel**: Requires LSIF/SCIP uploads -- check indexer configuration per language
- **Batch change permissions**: Users need write access to target repos for changesets
- **Search contexts**: Search contexts scope queries -- wrong context returns incomplete results
- **Rate limiting**: Code host rate limits affect syncing -- monitor external service sync intervals
- **Storage growth**: Search indexes and precise code intel data grow with repo count
