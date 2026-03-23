---
name: data-pipeline-quality-check
enabled: true
description: |
  Use when performing data pipeline quality check — template for assessing data
  pipeline quality, reliability, and data integrity. Covers schema validation,
  data freshness monitoring, completeness checks, anomaly detection, lineage
  tracking, and SLA compliance to ensure trustworthy data flows from source to
  consumption.
required_connections:
  - prefix: aws
    label: "AWS (or cloud provider)"
config_fields:
  - key: pipeline_name
    label: "Pipeline Name"
    required: true
    placeholder: "e.g., clickstream-to-warehouse"
  - key: source_system
    label: "Source System"
    required: true
    placeholder: "e.g., production Kafka, S3 events"
  - key: target_system
    label: "Target System"
    required: true
    placeholder: "e.g., Snowflake, BigQuery, Redshift"
features:
  - ENGINEERING
  - DATA
---

# Data Pipeline Quality Check Skill

Assess data quality for pipeline **{{ pipeline_name }}** ({{ source_system }} -> {{ target_system }}).

## Workflow

### Phase 1 — Pipeline Overview

```
PIPELINE INVENTORY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Pipeline: {{ pipeline_name }}
[ ] Source: {{ source_system }}
[ ] Target: {{ target_system }}
[ ] Schedule: [ ] Real-time  [ ] Micro-batch (___ min)  [ ] Batch (___ daily)
[ ] Daily data volume: ___ GB / ___ records
[ ] Pipeline technology: ___
[ ] Last successful run: ___
[ ] SLA: data available within ___ of source event
```

### Phase 2 — Data Completeness

```
COMPLETENESS CHECKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Record count reconciliation:
    - Source records (24h): ___
    - Target records (24h): ___
    - Delta: ___ (___ %)
    - Acceptable threshold: ___ %
[ ] Partition completeness:
    - All expected partitions present: [ ] YES  [ ] NO
    - Missing partitions: ___
[ ] Late-arriving data handling:
    - Strategy: [ ] Reprocess  [ ] Append  [ ] Ignore
    - Late data window: ___
[ ] Null analysis:
    - Required fields with nulls: ___
    - Null rate per field within threshold: [ ] YES  [ ] NO
```

### Phase 3 — Data Accuracy

```
ACCURACY VALIDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Schema validation:
    - Schema matches expected definition: [ ] YES  [ ] NO
    - Schema drift detected: [ ] YES  [ ] NO
    - New columns: ___
    - Removed columns: ___
    - Type changes: ___
[ ] Value range checks:
    - Numeric fields within expected bounds: [ ] YES
    - Date fields within valid ranges: [ ] YES
    - Enum fields contain valid values: [ ] YES
[ ] Referential integrity:
    - Foreign key relationships valid: [ ] YES  [ ] NO
    - Orphaned records: ___
[ ] Duplicate detection:
    - Duplicate records found: ___
    - Deduplication strategy: ___
```

### Phase 4 — Data Freshness

```
FRESHNESS MONITORING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] End-to-end latency:
    - Source event timestamp to target availability
    - P50: ___
    - P95: ___
    - P99: ___
    - SLA target: ___
    - SLA met: [ ] YES  [ ] NO
[ ] Staleness check:
    - Most recent record timestamp: ___
    - Expected freshness: ___
    - Freshness gap: ___
[ ] Processing time:
    - Average run duration: ___
    - Last run duration: ___
```

### Phase 5 — Anomaly Detection

```
ANOMALY ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Volume anomalies:
    - Record count vs 7-day average: ___% deviation
    - Volume spike/drop detected: [ ] YES  [ ] NO
[ ] Distribution anomalies:
    - Key metric distributions within normal range: [ ] YES
    - Outliers identified: ___
[ ] Pattern anomalies:
    - Unexpected null patterns: [ ] YES  [ ] NO
    - Unexpected value distributions: [ ] YES  [ ] NO
```

### Phase 6 — Lineage and Documentation

```
DATA LINEAGE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Source-to-target field mapping documented
[ ] Transformation logic documented
[ ] Data lineage tracked in catalog: [ ] YES  [ ] NO
[ ] Downstream consumers identified:
    - ___
    - ___
[ ] Data ownership:
    - Producer team: ___
    - Pipeline team: ___
    - Consumer team(s): ___
[ ] Data quality SLA documented: [ ] YES  [ ] NO
```

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

Produce a data pipeline quality report with:
1. **Pipeline summary** (source, target, schedule, volume)
2. **Quality scorecard** (completeness, accuracy, freshness scores)
3. **Issues found** (anomalies, schema drift, data loss)
4. **SLA compliance** (freshness and completeness vs targets)
5. **Recommendations** (monitoring improvements, quality gates, alerting)
