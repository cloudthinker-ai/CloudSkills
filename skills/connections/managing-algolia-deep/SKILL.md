---
name: managing-algolia-deep
description: |
  Advanced Algolia search platform management including indices, search analytics, A/B tests, query rules, synonyms, API key audit, and infrastructure monitoring. Covers search performance metrics, relevance tuning, click-through analysis, indexing health, and usage quota tracking.
connection_type: algolia-deep
preload: false
---

# Algolia Deep Management Skill

Advanced monitoring and management of Algolia search infrastructure.

## MANDATORY: Discovery-First Pattern

**Always discover indices and application settings before querying analytics.**

### Phase 1: Discovery

```bash
#!/bin/bash
ALGOLIA_API="https://${ALGOLIA_APP_ID}-dsn.algolia.net"
AUTH_HEADERS="-H 'X-Algolia-API-Key: ${ALGOLIA_ADMIN_KEY}' -H 'X-Algolia-Application-Id: ${ALGOLIA_APP_ID}'"

echo "=== Indices ==="
curl -s -H "X-Algolia-API-Key: ${ALGOLIA_ADMIN_KEY}" \
  -H "X-Algolia-Application-Id: ${ALGOLIA_APP_ID}" \
  "$ALGOLIA_API/1/indexes" | \
  jq -r '.items[] | "\(.name) | Records: \(.entries) | Size: \(.dataSize) | Updated: \(.updatedAt)"'

echo ""
echo "=== API Keys Audit ==="
curl -s -H "X-Algolia-API-Key: ${ALGOLIA_ADMIN_KEY}" \
  -H "X-Algolia-Application-Id: ${ALGOLIA_APP_ID}" \
  "$ALGOLIA_API/1/keys" | \
  jq -r '.keys[] | "\(.value[:8])... | ACL: \(.acl | join(",")) | Indices: \(.indexes // ["all"] | join(",")) | Valid: \(.validity)"' | head -10

echo ""
echo "=== Synonyms (first index) ==="
INDEX=$(curl -s -H "X-Algolia-API-Key: ${ALGOLIA_ADMIN_KEY}" \
  -H "X-Algolia-Application-Id: ${ALGOLIA_APP_ID}" \
  "$ALGOLIA_API/1/indexes" | jq -r '.items[0].name')
curl -s -H "X-Algolia-API-Key: ${ALGOLIA_ADMIN_KEY}" \
  -H "X-Algolia-Application-Id: ${ALGOLIA_APP_ID}" \
  "$ALGOLIA_API/1/indexes/$INDEX/synonyms/search" \
  -d '{"query":"","hitsPerPage":5}' | \
  jq -r '"Synonyms in $INDEX: \(.nbHits)"'

echo ""
echo "=== Query Rules ==="
curl -s -H "X-Algolia-API-Key: ${ALGOLIA_ADMIN_KEY}" \
  -H "X-Algolia-Application-Id: ${ALGOLIA_APP_ID}" \
  "$ALGOLIA_API/1/indexes/$INDEX/rules/search" \
  -d '{"query":"","hitsPerPage":1}' | \
  jq -r '"Rules in $INDEX: \(.nbHits)"'
```

**Phase 1 outputs:** Indices, API keys, synonyms, query rules

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Search Analytics (last 7 days) ==="
curl -s -H "X-Algolia-API-Key: ${ALGOLIA_ADMIN_KEY}" \
  -H "X-Algolia-Application-Id: ${ALGOLIA_APP_ID}" \
  "https://analytics.algolia.com/2/searches?index=${ALGOLIA_INDEX}&startDate=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d)&endDate=$(date +%Y-%m-%d)" | \
  jq -r '"Total Searches: \(.count)\nNo Results Rate: \(.noResultRate // "N/A")"' 2>/dev/null

echo ""
echo "=== Top Searches ==="
curl -s -H "X-Algolia-API-Key: ${ALGOLIA_ADMIN_KEY}" \
  -H "X-Algolia-Application-Id: ${ALGOLIA_APP_ID}" \
  "https://analytics.algolia.com/2/searches?index=${ALGOLIA_INDEX}&limit=10&orderBy=searchCount" | \
  jq -r '.searches[:5] | .[] | "\(.search) | Count: \(.count) | No Results: \(.noResultCount)"' 2>/dev/null

echo ""
echo "=== Click-Through Rate ==="
curl -s -H "X-Algolia-API-Key: ${ALGOLIA_ADMIN_KEY}" \
  -H "X-Algolia-Application-Id: ${ALGOLIA_APP_ID}" \
  "https://analytics.algolia.com/2/clicks?index=${ALGOLIA_INDEX}&startDate=$(date -v-7d +%Y-%m-%d 2>/dev/null || date -d '7 days ago' +%Y-%m-%d)" | \
  jq -r '"Click Rate: \(.rate // "N/A")\nTracked Searches: \(.trackedSearchCount // "N/A")"' 2>/dev/null

echo ""
echo "=== A/B Tests ==="
curl -s -H "X-Algolia-API-Key: ${ALGOLIA_ADMIN_KEY}" \
  -H "X-Algolia-Application-Id: ${ALGOLIA_APP_ID}" \
  "https://analytics.algolia.com/2/abtests" | \
  jq -r '.abtests[] | "\(.name) | Status: \(.status) | Index: \(.variants[0].index)"' 2>/dev/null || echo "No A/B tests"

echo ""
echo "=== Index Settings Audit ==="
curl -s -H "X-Algolia-API-Key: ${ALGOLIA_ADMIN_KEY}" \
  -H "X-Algolia-Application-Id: ${ALGOLIA_APP_ID}" \
  "$ALGOLIA_API/1/indexes/${ALGOLIA_INDEX}/settings" | \
  jq -r '"Searchable Attrs: \(.searchableAttributes | length)\nCustom Ranking: \(.customRanking | length)\nReplicas: \(.replicas // [] | length)"'
```

## Output Format

```
ALGOLIA DEEP STATUS
===================
App: {app_id}
Indices: {count} | Total Records: {sum}
7-Day Searches: {count}
No Results Rate: {percent}%
Click-Through Rate: {percent}%
Top No-Result Query: {query}
A/B Tests: {active}/{total}
API Keys: {count} ({unrestricted} unrestricted)
Issues: {list_of_warnings}
```

## Common Pitfalls

- **Admin vs Search key**: Never expose admin key client-side — use scoped search keys
- **Analytics latency**: Search analytics have ~4 hour delay — not real-time
- **Replica indices**: Replicas count toward index limits — monitor total
- **Rate limits**: Admin API is 5000 req/min — search API depends on plan
