---
name: managing-sourcegraph
description: |
  Use when working with Sourcegraph — sourcegraph code intelligence platform
  management covering repository indexing status, code search capabilities,
  batch change tracking, code insights monitoring, precise code intelligence
  status, and user access auditing. Use when investigating search indexing
  issues, monitoring batch change progress, reviewing code intelligence
  coverage, or auditing instance configuration.
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

## Output Format

Present results as a structured report:
```
Managing Sourcegraph Report
═══════════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

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

- **Index lag**: New repositories take time to index -- check cloning and indexing queue
- **External service sync**: Sync errors prevent repository discovery -- fix external service config
- **Precise code intel**: Requires LSIF/SCIP uploads -- check indexer configuration per language
- **Batch change permissions**: Users need write access to target repos for changesets
- **Search contexts**: Search contexts scope queries -- wrong context returns incomplete results
- **Rate limiting**: Code host rate limits affect syncing -- monitor external service sync intervals
- **Storage growth**: Search indexes and precise code intel data grow with repo count
