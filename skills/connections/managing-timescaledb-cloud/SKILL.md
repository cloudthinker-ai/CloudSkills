---
name: managing-timescaledb-cloud
description: |
  Use when working with Timescaledb Cloud — timescaleDB Cloud management —
  monitor services, hypertables, continuous aggregates, compression, retention
  policies, and query performance. Use when inspecting chunk distribution,
  debugging slow queries, reviewing compression ratios, or auditing data
  retention.
connection_type: timescaledb-cloud
preload: false
---

# Managing TimescaleDB Cloud

Manage and monitor TimescaleDB Cloud — services, hypertables, continuous aggregates, compression, and retention.

## Discovery Phase

```bash
#!/bin/bash

ts_cmd() {
    psql "$TIMESCALEDB_URL" --no-psqlrc -t -A -F $'\t' -c "$1" 2>/dev/null
}

echo "=== TimescaleDB Version ==="
ts_cmd "SELECT extversion FROM pg_extension WHERE extname = 'timescaledb';"

echo ""
echo "=== Databases ==="
ts_cmd "SELECT datname, pg_size_pretty(pg_database_size(datname))
        FROM pg_database
        WHERE datistemplate = false
        ORDER BY pg_database_size(datname) DESC;" | column -t

echo ""
echo "=== Hypertables ==="
ts_cmd "SELECT hypertable_schema, hypertable_name, num_dimensions, num_chunks,
               pg_size_pretty(hypertable_size(format('%I.%I', hypertable_schema, hypertable_name)::regclass)) AS total_size
        FROM timescaledb_information.hypertables
        ORDER BY hypertable_size(format('%I.%I', hypertable_schema, hypertable_name)::regclass) DESC
        LIMIT 15;" | column -t

echo ""
echo "=== Continuous Aggregates ==="
ts_cmd "SELECT view_schema, view_name, materialization_hypertable_schema,
               materialization_hypertable_name, view_definition
        FROM timescaledb_information.continuous_aggregates
        LIMIT 10;" | column -t

echo ""
echo "=== Compression Settings ==="
ts_cmd "SELECT hypertable_schema, hypertable_name, attname, segmentby_column_index, orderby_column_index
        FROM timescaledb_information.compression_settings
        LIMIT 15;" | column -t
```

## Analysis Phase

```bash
#!/bin/bash

ts_cmd() {
    psql "$TIMESCALEDB_URL" --no-psqlrc -t -A -F $'\t' -c "$1" 2>/dev/null
}

echo "=== Chunk Distribution ==="
ts_cmd "SELECT hypertable_schema, hypertable_name,
               chunk_schema, chunk_name,
               range_start, range_end,
               is_compressed,
               pg_size_pretty(pg_total_relation_size(format('%I.%I', chunk_schema, chunk_name)::regclass)) AS size
        FROM timescaledb_information.chunks
        ORDER BY range_end DESC
        LIMIT 15;" | column -t

echo ""
echo "=== Compression Stats ==="
ts_cmd "SELECT hypertable_schema, hypertable_name,
               number_compressed_chunks, number_uncompressed_chunks,
               pg_size_pretty(before_compression_total_bytes) AS before,
               pg_size_pretty(after_compression_total_bytes) AS after,
               ROUND((1 - after_compression_total_bytes::numeric / NULLIF(before_compression_total_bytes, 0)) * 100, 1) AS compression_pct
        FROM hypertable_compression_stats(NULL)
        LIMIT 10;" | column -t

echo ""
echo "=== Retention Policies ==="
ts_cmd "SELECT hypertable_schema, hypertable_name, schedule_interval, config
        FROM timescaledb_information.jobs
        WHERE proc_name = 'policy_retention'
        LIMIT 10;" | column -t

echo ""
echo "=== Job Status ==="
ts_cmd "SELECT job_id, application_name, schedule_interval,
               last_run_status, last_run_started_at, last_run_duration,
               next_start, total_runs, total_failures
        FROM timescaledb_information.job_stats
        ORDER BY last_run_started_at DESC
        LIMIT 10;" | column -t

echo ""
echo "=== Slow Queries ==="
ts_cmd "SELECT LEFT(query, 80) AS query_preview,
               calls, mean_exec_time::int AS avg_ms,
               total_exec_time::int AS total_ms, rows
        FROM pg_stat_statements
        WHERE query NOT LIKE '%pg_stat%'
        ORDER BY mean_exec_time DESC
        LIMIT 10;" | column -t

echo ""
echo "=== Data Freshness ==="
ts_cmd "SELECT hypertable_name, MAX(range_end) AS latest_chunk_end
        FROM timescaledb_information.chunks c
        JOIN timescaledb_information.hypertables h
          ON c.hypertable_name = h.hypertable_name
        GROUP BY hypertable_name
        ORDER BY latest_chunk_end DESC
        LIMIT 10;" | column -t
```

## Output Format

```
HYPERTABLES
Schema     Name             Dimensions   Chunks   Total Size
<schema>   <hypertable>     <n>          <n>      <size>

CONTINUOUS AGGREGATES
Schema     View Name        Source Hypertable
<schema>   <cagg-name>      <hypertable>

COMPRESSION STATS
Hypertable       Compressed   Uncompressed   Before     After      Ratio
<hypertable>     <n>          <n>            <size>     <size>     <pct>%

JOB STATUS
Job ID   Application        Interval    Last Status   Last Run        Failures
<id>     <app-name>         <interval>  Success       <timestamp>     <n>

RETENTION POLICIES
Hypertable       Schedule Interval   Config
<hypertable>     <interval>          <config>
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

