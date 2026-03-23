---
name: monitoring-grafana
description: Grafana monitoring, visualization, and alerting. Use when working with Grafana datasources, Prometheus metrics, Loki logs, dashboards, or alerts.
connection_type: grafana
preload: false
---

# Monitoring Grafana

## Discovery

<critical>
**If no `[cached_from_skill:monitoring-grafana:discover]` context exists, run discovery first:**
```bash
bun run ./_skills/connections/grafana/monitoring-grafana/scripts/discover.ts
bun run ./_skills/connections/grafana/monitoring-grafana/scripts/discover.ts --max-datasources 5 --max-dashboards 10
```
Output is auto-cached.
</critical>

**What discovery provides:**
- `datasources`: All datasources with `uid`, `name`, `type`, `isDefault` (grouped by type)
- `dashboards`: Available dashboards with `uid`, `title`, `folderTitle`, `tags`
- `folders`: Dashboard folders with `uid`, `title`
- `alerts`: Alert rules with total count, state breakdown, and `firing` alerts list
- `incidents`: Active incidents with `id`, `title`, `status`
- `prometheus`: Per-datasource label discovery (`labelNames`, `keyLabels` for job/namespace/instance)
- `loki`: Per-datasource label discovery (`labelNames`, `keyLabels` for app/namespace/pod)
- `capabilities`: `siftAvailable` - whether Sift plugin is installed (for `find_error_pattern_logs`)
- `hints.loki`: Query limits, forbidden regex patterns, and safe alternatives

**Why run discovery:**
- Get `datasourceUid` required for all Prometheus/Loki queries
- Know available labels before building queries
- Check if Sift plugin is available (determines if `find_error_pattern_logs` will work)
- See firing alerts that need immediate attention

## Smart Query Rules

<critical>
**Prometheus**: Start `queryType: "instant"` + aggregation → then `"range"` if needed
**Loki**: Start `query_loki_stats()` or `find_error_pattern_logs()` → then `query_loki_logs()` with `limit: 20-50`
**Time**: Default `now-15m` (not `now-1h` or `now-24h`)
</critical>

<critical>
**NEVER USE EMPTY LOGQL SELECTORS.** `logql: '{}'` is invalid and Loki will reject it with `parse error: unexpected }, expecting IDENTIFIER`. You MUST always include at least one label matcher.
```typescript
// ❌ WRONG - empty selector, Loki rejects this
await query_loki_logs({ datasourceUid, logql: '{}', limit: 50 });
await query_loki_stats({ datasourceUid, logql: '{}' });

// ✅ CORRECT - always specify at least one label
await query_loki_logs({ datasourceUid, logql: '{app="backend"}', limit: 50 });
await query_loki_stats({ datasourceUid, logql: '{namespace="prod"}' });
```
Use discovery (`list_loki_label_values`) to find valid label values if you don't know them.
</critical>

| Bad ❌ | Good ✅ | Why |
|--------|---------|-----|
| `expr: 'node_cpu_total'` | `expr: 'avg(rate(node_cpu_total[5m]))'` | Aggregation reduces 100+ series to 1 |
| `queryType: "range"` for current value | `queryType: "instant"` | Single point vs 60+ points |
| `limit: 1000` | `limit: 20-50` first | Sample before fetching all |
| `startTime: "now-24h"` | `startTime: "now-15m"` | Recent data sufficient for troubleshooting |
| `query_loki_logs()` first | `find_error_pattern_logs()` first | Patterns before raw logs |

**Query progression**: Aggregated summary → Filter to problem area → Small sample → (rarely) Full data

## Tools

**Datasources:** `list_datasources(type?)`, `get_datasource(uid?, name?)`

**Dashboards:** `search_dashboards(query?)`, `get_dashboard_by_uid(uid)`, `get_dashboard_summary(uid)`, `get_dashboard_panel_queries(uid, panelId)`, `get_dashboard_property(uid, jsonPath)`, `update_dashboard(dashboard?, uid?, operations?, folderUid?, message?, overwrite?)`, `run_panel_query(dashboardUid, panelIds, queryIndex?, start?, end?, variables?)`, `search_folders(query?)`, `create_folder(title, uid?, parentUid?)`

**Prometheus:** `query_prometheus(datasourceUid, expr, startTime, queryType?, endTime?, stepSeconds?)`, `query_prometheus_histogram(datasourceUid, metric, percentile, labels?, rateInterval?, startTime?, endTime?, stepSeconds?)`, `list_prometheus_metric_names(datasourceUid)`, `list_prometheus_label_names(datasourceUid, match?)`, `list_prometheus_label_values(datasourceUid, labelName, match?)`, `list_prometheus_metric_metadata(datasourceUid)`

**Loki:** `query_loki_logs(datasourceUid, logql, startRfc3339?, endRfc3339?, limit?, direction?)`, `query_loki_stats(datasourceUid, logql, startRfc3339?, endRfc3339?)`, `list_loki_label_names(datasourceUid, startRfc3339?, endRfc3339?)`, `list_loki_label_values(datasourceUid, labelName, startRfc3339?, endRfc3339?)`, `find_error_pattern_logs(name, labels, start?, end?)`, `find_slow_requests(name, labels, start?, end?)`, `query_loki_patterns(datasourceUid, logql, startRfc3339?, endRfc3339?, step?)`

**Alerting:** `alerting_manage_rules(operation: "list"|"get"|"create"|"update"|"delete", rule_uid?, ...)`, `list_alert_groups(...)`, `alerting_manage_routing(operation: "get_notification_policies"|"get_contact_points"|..., ...)`

**Annotations:** `get_annotations(...)`, `create_annotation(...)`, `update_annotation(...)`, `get_annotation_tags(...)`

**Incidents:** `list_incidents(...)`, `get_incident(incidentId)`, `create_incident(...)`, `add_activity_to_incident(incidentId, body, eventTime?)`, `list_oncall_schedules(...)`, `get_current_oncall_users(scheduleId)`

**Search:** `search_logs(datasourceUid, pattern, table?, start?, end?, limit?)`

**Elasticsearch:** `query_elasticsearch(datasourceUid, query, start?, end?, limit?)`

**CloudWatch:** `query_cloudwatch(datasourceUid, namespace, metricName, dimensions?, statistic?, period?, start?, end?, region, accountId?)`

**ClickHouse:** `query_clickhouse(datasourceUid, query, start?, end?, variables?, limit?)`, `list_clickhouse_tables(datasourceUid)`

**Pyroscope:** `list_pyroscope_label_names(data_source_uid, ...)`, `list_pyroscope_label_values(...)`, `list_pyroscope_profile_types(data_source_uid)`, `fetch_pyroscope_profile(...)`

**Rendering:** `get_panel_image(dashboardUid, panelId?, width?, height?, timeRange?, variables?, theme?, scale?)`

**Navigation:** `generate_deeplink(resourceType, dashboardUid?, datasourceUid?, panelId?, queryParams?, timeRange?)`

**Admin:** `list_teams(query?)`, `list_users_by_org()`, `list_all_roles(delegatableOnly?)`, `get_role_details(roleUID)`

**Examples:** `get_query_examples(datasourceType)`

**Sift:** `start_sift_investigation(...)`, `get_sift_investigation_status(...)`, `list_sift_investigations(...)`

**Asserts:** `get_assertions(startTime, endTime, entityType, entityName, ...)`

## Quick Patterns

**Discover:**
```typescript
const datasources = await list_datasources({ type: "prometheus" });
const labels = await list_prometheus_label_names({ datasourceUid: "ds-uid" });
const apps = await list_loki_label_values({ datasourceUid: "ds-uid", labelName: "app" });
```

**LogQL:** `{label="value"} |= "filter"` - Examples: `{app="backend"}`, `{app="backend"} |= "error"`, `{app="backend"} | json | status >= 500`

```typescript
import type { QueryLokiLogsResult, QueryLokiStatsResult } from "./_skills/connections/grafana/monitoring-grafana/schemas";

// Stats query (label matchers only, no line filters)
const stats = await query_loki_stats({
  datasourceUid, logql: '{app="backend", namespace="prod"}'
}) as QueryLokiStatsResult;

// Log query with line filter
const response = await query_loki_logs({
  datasourceUid, logql: '{app="backend"} |= "error"', limit: 100, direction: "backward"
}) as QueryLokiLogsResult;
const logs = response.data;
// Strip JSON quotes bug: timestamp.replace(/^"|"$/g, '') then new Date(Number(ts) / 1e6)
```

<critical>
**REGEX LIMITS:** Loki rejects `\w`, `\d`, `\s`, `\b`, `(?i)` - use `[A-Za-z0-9_]`, `[0-9]`, `[ \t]`, alternation `[Ee]rror|[Ww]arn`
</critical>

<critical>
**LOGQL OR SYNTAX:** Cannot chain `|=` with `or`. Use regex alternation instead.
```typescript
// ❌ WRONG - "or" cannot chain line filters
'{namespace="prod"} |= "error" or |= "ERROR" or |= "Exception"'

// ✅ CORRECT - regex alternation
'{namespace="prod"} |~ "error|ERROR|Exception|FATAL"'

// ✅ BEST - broad query + TypeScript filtering
const response = await query_loki_logs({...logql: '{namespace="prod"}', limit: 100}) as QueryLokiLogsResult;
const errors = response.data.filter(l => /error|exception|fatal/i.test(l.line));
```
</critical>

<critical>
**RATE LIMITS:** Max 2-3 concurrent queries (429 error otherwise). **Prefer single broad query + TypeScript filtering** over parallel queries.
```typescript
const response = await query_loki_logs({datasourceUid, logql: '{namespace="prod"}', limit: 100}) as QueryLokiLogsResult;
const errors = response.data.filter(l => /error/i.test(l.line)); // Filter in code
```
</critical>

<critical>
**`query_loki_stats` ONLY SUPPORTS LABEL MATCHERS** - No line filters (`|=`, `|~`), no parser (`| json`), no label filters.
```typescript
// ❌ WRONG - will fail with "only label matchers is supported"
await query_loki_stats({datasourceUid, logql: '{app="backend"} |= "error"', ...});

// ✅ CORRECT - label matchers only
await query_loki_stats({datasourceUid, logql: '{app="backend", namespace="prod"}', ...});

// Then filter with query_loki_logs if needed
const logs = await query_loki_logs({datasourceUid, logql: '{app="backend"} |= "error"', limit: 100});
```
</critical>

<critical>
**SIFT PLUGIN:** `find_error_pattern_logs()` / `find_slow_requests()` may return 404. Always use try-catch with manual fallback:
```typescript
try {
  patterns = await find_error_pattern_logs({name: "error-analysis", labels: {namespace: "prod"}});
} catch (e: any) {
  if (e.message?.includes('404')) {
    const patternMap = new Map<string, number>();
    logs.forEach(log => {
      const p = log.line.substring(0, 100).trim();
      patternMap.set(p, (patternMap.get(p) || 0) + 1);
    });
    patterns = Array.from(patternMap.entries()).sort((a, b) => b[1] - a[1]).slice(0, 10);
  } else throw e;
}
```
</critical>

**Best Workflow:** Single broad query → TypeScript categorization → pattern detection
```typescript
const response = await query_loki_logs({datasourceUid, logql: '{namespace="prod"}', limit: 100, direction: 'backward'}) as QueryLokiLogsResult;
const logs = response.data;
const errors = logs.filter(l => /error/i.test(l.line));
const patternMap = new Map<string, number>();
errors.forEach(log => {
  const p = log.line.substring(0, 100).trim();
  patternMap.set(p, (patternMap.get(p) || 0) + 1);
});
const top5 = Array.from(patternMap.entries()).sort((a, b) => b[1] - a[1]).slice(0, 5);
```

**PromQL**: `avg(rate(...[5m])) by (label)`, `topk(5, ...)`, `histogram_quantile(0.95, ...)`
```typescript
// Current state (instant query)
const p95 = await query_prometheus({datasourceUid, expr: 'histogram_quantile(0.95, rate(http_duration_bucket[5m]))', startTime: "now", queryType: "instant"});
// Trend (short range)
const trend = await query_prometheus({datasourceUid, expr: 'avg(rate(http_requests[5m])) by (status)', startTime: "now-15m", queryType: "range", stepSeconds: 60});
```

**Dashboards:** `search_dashboards({query})`, `get_dashboard_summary({uid})`, `get_dashboard_panel_queries({uid, panelId})`

**Alerts:** `alerting_manage_rules({operation: "list"})`, `alerting_manage_rules({operation: "get", rule_uid: uid})`

## Workflows

**Errors**: `find_error_pattern_logs({name: "...", labels: {...}})` → `query_loki_logs(limit:20)` for top pattern
**Performance**: `query_prometheus(instant)` P95 → if high, `query_prometheus(range, now-15m)` trend
**Alerts**: `alerting_manage_rules({operation: "list"})` filter `state:"firing"` → `query_prometheus(now-15m)` for alert metric

## Time & Errors

**Time:** Prometheus: `now-1h`, Loki: RFC3339 `2024-01-07T00:00:00Z`

**Common Errors:**
- Empty selector `{}` → Loki rejects `logql: '{}'` with `parse error: unexpected }, expecting IDENTIFIER`. Always include at least one label matcher (e.g., `{app="backend"}`, `{namespace="prod"}`). Use `list_loki_label_values()` to discover available labels.
- Timestamp quotes → Strip: `ts.replace(/^"|"$/g, '')` then `new Date(Number(ts)/1e6)`
- Escape sequences `\w` → Use `[A-Za-z0-9_]`
- 429 rate limit → Single query + code filtering
- 404 Plugin → Use manual fallback
- **`query_loki_stats` with filters** → Stats only supports label matchers, no line filters (`|=`, `|~`, `| json`)

## Critical Anti-Patterns

**Raw metrics first**: Use aggregation (`sum`, `avg`, `rate`, `topk`) before fetching series
**Range for current state**: Use `queryType: "instant"` not `"range"`
**Long time windows**: Start `now-15m` not `now-1h` or `now-24h`
**High log limits**: Use `limit: 20-50` not `500+` for exploration
**Logs before patterns**: Use `find_error_pattern_logs()` or `query_loki_stats()` first
**Complex regex**: Use `[A-Za-z0-9_]` not `\w`, or filter in TypeScript
**3+ parallel queries**: Rate limit 2-3 max, prefer single query + code filter
**Assuming Sift**: Always try-catch with manual fallback (404 error)

## Output Format

Present results as a structured report:
```
Monitoring Grafana Report
═════════════════════════
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

