---
name: gcp-bigquery-deep
description: |
  Google BigQuery job analysis, slot utilization, storage optimization, materialized views, BI Engine capacity, and query performance diagnostics via bq CLI and gcloud.
connection_type: gcp
preload: false
---

# BigQuery Deep Skill

Manage and analyze Google BigQuery using `bq` and `gcloud` commands.

## Discovery-First Rule

**ALWAYS discover before acting.** Never assume dataset names, table names, job IDs, or reservation names.

```bash
# List datasets
bq ls --format=json | jq '[.[] | {datasetId: .datasetReference.datasetId, location: .location}]'

# List tables in a dataset
bq ls --format=json "$DATASET" | jq '[.[] | {tableId: .tableReference.tableId, type: .type, numRows: .numRows, numBytes: .numBytes}]'
```

## Parallel Execution Requirement

**ALL independent operations MUST run in parallel using background jobs (&) and wait.**

```bash
for dataset in $(bq ls --format=json | jq -r '.[].datasetReference.datasetId'); do
  {
    bq ls --format=json "$dataset"
  } &
done
wait
```

## Helper Functions

```bash
# Get table details
get_table_info() {
  local table="$1"
  bq show --format=json "$table" | jq '{tableId: .tableReference.tableId, type: .type, numRows: .numRows, numBytes: .numBytes, schema: .schema.fields | length, partitioning: .timePartitioning, clustering: .clustering, lastModified: .lastModifiedTime, expirationTime: .expirationTime}'
}

# List recent jobs
list_jobs() {
  local limit="${1:-25}"
  bq ls --jobs --format=json --max_results="$limit" | jq '[.[] | {jobId: .jobReference.jobId, state: .status.state, type: .configuration | keys[0], bytesProcessed: .statistics.totalBytesProcessed, slotMs: .statistics.totalSlotMs, creationTime: .statistics.creationTime}]'
}

# Get job details
get_job_details() {
  local job_id="$1"
  bq show --format=json --job "$job_id" | jq '{jobId: .jobReference.jobId, state: .status.state, errors: .status.errors, bytesProcessed: .statistics.totalBytesProcessed, slotMs: .statistics.totalSlotMs, billingTier: .statistics.query.billingTier, cacheHit: .statistics.query.cacheHit, totalBytesBilled: .statistics.query.totalBytesBilled}'
}

# Estimate query cost
estimate_query() {
  local query="$1"
  bq query --dry_run --use_legacy_sql=false "$query" 2>&1 | grep "processed"
}
```

## Common Operations

### 1. Dataset and Storage Overview

```bash
datasets=$(bq ls --format=json | jq -r '.[].datasetReference.datasetId')
for ds in $datasets; do
  {
    echo "=== Dataset: $ds ==="
    bq ls --format=json "$ds" | jq '[.[] | {table: .tableReference.tableId, type: .type, rows: .numRows, sizeGB: (.numBytes | tonumber / 1073741824 * 100 | round / 100)}]'
  } &
done
wait
```

### 2. Job Analysis and Slot Utilization

```bash
# Recent jobs with performance stats
bq ls --jobs --format=json --max_results=50 | jq '[.[] | select(.status.state=="DONE") | {job: .jobReference.jobId, bytesProcessed: .statistics.totalBytesProcessed, slotMs: .statistics.totalSlotMs, durationMs: (.statistics.endTime | tonumber) - (.statistics.startTime | tonumber), cacheHit: .statistics.query.cacheHit}] | sort_by(-.slotMs) | .[:10]'

# Slot utilization via monitoring
gcloud monitoring time-series list \
  --filter="metric.type=\"bigquery.googleapis.com/slots/total_available\" OR metric.type=\"bigquery.googleapis.com/slots/allocated\"" \
  --interval-start-time="$(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)" \
  --format=json
```

### 3. Storage Optimization

```bash
# Tables without partitioning or clustering (potential optimization)
for ds in $(bq ls --format=json | jq -r '.[].datasetReference.datasetId'); do
  {
    bq ls --format=json "$ds" | jq --arg ds "$ds" '[.[] | select(.type=="TABLE") | {dataset: $ds, table: .tableReference.tableId, sizeGB: (.numBytes | tonumber / 1073741824 * 100 | round / 100), rows: .numRows}] | sort_by(-.sizeGB) | .[:5]'
  } &
done
wait

# Check partitioning and clustering on large tables
bq show --format=json "$DATASET.$TABLE" | jq '{partitioning: .timePartitioning, clustering: .clustering, rangePartitioning: .rangePartitioning, numBytes: .numBytes, numRows: .numRows}'
```

### 4. Materialized Views

```bash
# List materialized views
for ds in $(bq ls --format=json | jq -r '.[].datasetReference.datasetId'); do
  {
    bq ls --format=json "$ds" | jq --arg ds "$ds" '[.[] | select(.type=="MATERIALIZED_VIEW") | {dataset: $ds, view: .tableReference.tableId, lastRefresh: .materializedView.lastRefreshTime}]'
  } &
done
wait
```

### 5. BI Engine and Reservations

```bash
# Check reservations
bq ls --reservation --format=json 2>/dev/null | jq '[.[] | {name: .name, slotCapacity: .slotCapacity, edition: .edition}]'

# Check capacity commitments
bq ls --capacity_commitment --format=json 2>/dev/null | jq '[.[] | {name: .name, slotCount: .slotCount, plan: .plan, state: .state, edition: .edition}]'

# BI Engine reservations
gcloud bq reservations list --format=json 2>/dev/null
```

## Common Pitfalls

1. **On-demand vs flat-rate**: On-demand pricing charges per TB scanned. Flat-rate uses slot reservations. Check pricing model before analyzing costs.
2. **Cache hits**: Cached queries are free but cache invalidates on table changes. `cacheHit=true` in job stats means zero bytes billed.
3. **Partitioning required**: Tables over 1TB without partitioning cause full table scans. Always check `timePartitioning` on large tables.
4. **Dry run for estimation**: Always use `--dry_run` to estimate query cost before running expensive queries.
5. **Streaming buffer**: Recently streamed data sits in a buffer that is not immediately available for DML operations. Check `streamingBuffer` in table metadata.
