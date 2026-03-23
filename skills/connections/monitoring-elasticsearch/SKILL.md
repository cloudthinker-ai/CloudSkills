---
name: monitoring-elasticsearch
description: Elasticsearch cluster monitoring, log analytics, and search optimization. Use when working with Elasticsearch indices, mappings, DSL queries, ES|QL analytics, or shard health.
connection_type: elasticsearch
preload: false
---

# Monitoring Elasticsearch

## Discovery

<critical>
**If no `[cached_from_skill:monitoring-elasticsearch:discover]` context exists, run discovery first:**
```bash
bun run ./_skills/connections/elasticsearch/monitoring-elasticsearch/scripts/discover.ts
bun run ./_skills/connections/elasticsearch/monitoring-elasticsearch/scripts/discover.ts --max-indices 50 --max-mappings 5
```
Output is auto-cached.
</critical>

**What discovery provides:**
- `clusterHealth`: Derived health (`green`/`yellow`/`red`) from shard states
- `indices`: All indices with `status`, `docs.count`
- `shards`: Total count, unassigned count
- `mappings`: Field names for top indices by document count
- `indexPatterns`: Detected prefix patterns (e.g., `logs-app-*`) for query suggestions

**Why run discovery:**
- Know available indices and their field mappings before building queries
- Detect cluster health issues (unassigned shards) immediately
- Identify index naming patterns for wildcard queries
- Avoid guessing field names — `get_mappings` reveals actual schema

## Smart Query Rules

<critical>
**Response format**: ES MCP returns multi-content responses (`[text_summary, json_data]` as `string[]`). Parse the JSON block before using:
```typescript
function extractData<T>(response: unknown): T {
  if (Array.isArray(response) && typeof response[0] === "string") {
    for (let i = response.length - 1; i >= 0; i--) {
      try { return JSON.parse(response[i]) as T; } catch { continue; }
    }
    return [] as T;
  }
  return (typeof response === "string" ? JSON.parse(response) : response) as T;
}
```
**DSL**: `query_body` must be an object, never a string. Include `size` inside `query_body`.
**ES|QL**: Always include `LIMIT` clause. Use `FROM index` not `FROM index*` unless needed.
**Prep**: Run `get_mappings` before filtering on fields you haven't confirmed exist.
</critical>

| Bad | Good | Why |
|-----|------|-----|
| `query_body: '{"query":...}'` | `query_body: {"query":...}` | Must be object, not JSON string |
| No `size` in `query_body` | `query_body: {..., size: 20}` | Unbounded results cause timeouts |
| Filter on guessed field | `get_mappings` first, then filter | Field may not exist or have different name |
| `FROM logs-*` broadly | `FROM logs-app-2024.01` specifically | Narrow index = faster query |
| ES\|QL without `LIMIT` | `... | LIMIT 100` | Unbounded ES\|QL is expensive |

**Query progression**: Discovery → Mappings → Targeted small query → Expand if needed

## Tools

**Indices:** `list_indices(index_pattern)` — list indices with status and doc count. Returns `IndexInfo[]`
**Mappings:** `get_mappings(index)` — field names and types. Returns `{mappings: {properties: {...}}}`
**Search:** `search(index, query_body, fields?)` — DSL query execution. `size`, `sort`, `_source` go inside `query_body`. Returns `_source` docs as array
**ES|QL:** `esql(query)` — ES|QL analytics. Returns array of objects (column names as keys)
**Shards:** `get_shards(index?)` — shard allocation and state. `index` is optional. Returns `ShardInfo[]`

## Quick Patterns

**List indices:**
```typescript
import type { IndexInfo } from "./_skills/connections/elasticsearch/monitoring-elasticsearch/schemas";
const indices = extractData<IndexInfo[]>(await list_indices({ index_pattern: "*" }));
const sorted = [...indices].sort((a, b) => (b["docs.count"] || 0) - (a["docs.count"] || 0));
```

**Get mappings before querying:**
```typescript
import type { GetMappingsResult } from "./_skills/connections/elasticsearch/monitoring-elasticsearch/schemas";
const mappings = extractData<GetMappingsResult>(await get_mappings({ index: "logs-app-2024.01" }));
const fields = Object.keys(mappings.mappings.properties);
```

**DSL search:**
```typescript
import type { SearchResult } from "./_skills/connections/elasticsearch/monitoring-elasticsearch/schemas";
const docs = extractData<SearchResult>(await search({
  index: "logs-app-*",
  query_body: {
    query: { bool: { must: [{ match: { level: "ERROR" } }, { range: { "@timestamp": { gte: "now-15m" } } }] } },
    size: 20,
    sort: [{ "@timestamp": "desc" }],
  },
}));
```

**ES|QL analytics:**
```typescript
import type { EsqlResult } from "./_skills/connections/elasticsearch/monitoring-elasticsearch/schemas";
const rows = extractData<EsqlResult>(await esql({
  query: 'FROM logs-app-* | WHERE level == "ERROR" | STATS count = COUNT(*) BY service.name | SORT count DESC | LIMIT 10',
}));
```

**Shard health check:**
```typescript
import type { ShardInfo } from "./_skills/connections/elasticsearch/monitoring-elasticsearch/schemas";
const shards = extractData<ShardInfo[]>(await get_shards({}));
const unassigned = shards.filter(s => s.state !== "STARTED");
```

## Workflows

**Error analysis**: `get_mappings(index)` → `search(index, {query: {bool: {must: [{match: {level: "ERROR"}}]}}, size: 50})` → aggregate by error type in code
**Cluster health triage**: `get_shards({})` → filter unassigned → `list_indices({ index_pattern: "*" })` for affected indices
**Index storage analysis**: `list_indices({ index_pattern: "*" })` → sort by `docs.count` → `get_mappings` on largest → `esql` for field cardinality

## Time & Errors

**DSL time filters:** `"gte": "now-15m"`, `"lte": "now"`, `"format": "epoch_millis"` for timestamps
**ES|QL time:** `WHERE @timestamp > NOW() - 15 MINUTES`

**Common Errors:**

| Error | Cause | Fix |
|-------|-------|-----|
| `json_parse_exception` | `query_body` passed as string | Pass as object: `{query: {...}}` |
| `index_not_found_exception` | Wrong index name or pattern | Run `list_indices` first |
| `query_phase_execution_exception` | Field type mismatch | Run `get_mappings` to check field types |
| `too_many_buckets_exception` | Aggregation cardinality too high | Add `size` to aggregation or filter more |
| ES\|QL `parsing_exception` | Missing `LIMIT` or syntax error | Add `LIMIT`, check column names with mappings |
| `missing field` deserialization | Required param missing | `list_indices` requires `index_pattern`, `get_mappings`/`search` require `index` |

## Critical Anti-Patterns

**String query_body**: `query_body` must be a JSON object `{}`, never a stringified JSON `"{}"`
**Guessing field names**: Always run `get_mappings` first — field names vary across indices
**No size limit**: Always include `size` inside `query_body` to avoid fetching all documents
**ES|QL without LIMIT**: Every ES|QL query must include `| LIMIT N`
**Wide index patterns**: Use specific indices (`logs-app-2024.01`) over broad wildcards (`*`) when possible

## Output Format

Present results as a structured report:
```
Monitoring Elasticsearch Report
═══════════════════════════════
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

