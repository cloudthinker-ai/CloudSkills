---
name: database-performance-tuning
enabled: true
description: |
  Provides a systematic approach to diagnosing and resolving database performance issues. Covers query analysis, index optimization, schema review, configuration tuning, connection management, and capacity planning for relational and NoSQL databases.
required_connections:
  - prefix: database
    label: "Database Instance"
  - prefix: monitoring
    label: "Monitoring Platform"
config_fields:
  - key: db_engine
    label: "Database Engine"
    required: true
    placeholder: "e.g., PostgreSQL, MySQL, MongoDB, SQL Server"
  - key: primary_symptom
    label: "Primary Performance Symptom"
    required: true
    placeholder: "e.g., slow queries, high CPU, lock contention, connection exhaustion"
  - key: db_size_gb
    label: "Database Size (GB)"
    required: false
    placeholder: "e.g., 200"
features:
  - PERFORMANCE
  - DATABASE
  - OPTIMIZATION
---

# Database Performance Tuning

## Phase 1: Performance Baseline
1. Collect current performance metrics
   - [ ] CPU utilization (average and peak)
   - [ ] Memory utilization and buffer cache hit ratio
   - [ ] Disk I/O (IOPS, throughput, latency)
   - [ ] Active connections and connection wait times
   - [ ] Transactions per second
   - [ ] Replication lag (if applicable)
2. Identify top resource-consuming queries
3. Review slow query log
4. Document current database configuration parameters

### Performance Baseline

| Metric | Current Value | Healthy Range | Status |
|--------|-------------|---------------|--------|
| CPU utilization | % | < 70% | OK/Warning/Critical |
| Buffer cache hit ratio | % | > 99% | |
| Disk IOPS | | < max provisioned | |
| Active connections | | < max_connections * 80% | |
| Avg query time | ms | < target ms | |
| Deadlocks/hour | | 0 | |

## Phase 2: Query Analysis
1. Identify problematic queries
   - [ ] Queries with full table scans
   - [ ] Queries with high execution time
   - [ ] Queries with high execution frequency
   - [ ] Queries causing lock contention
   - [ ] N+1 query patterns
2. Review execution plans for top queries
3. Identify missing indexes from query patterns
4. Check for parameter sniffing issues

### Top Queries by Impact

| Query | Avg Time | Calls/min | Total Time % | Full Scans | Action |
|-------|----------|----------|-------------|------------|--------|
|       | ms       |          | %           | Yes/No     | Index/Rewrite/Cache |

## Phase 3: Index Optimization
1. Analyze current indexes
   - [ ] Identify unused indexes (consuming write overhead)
   - [ ] Identify duplicate or overlapping indexes
   - [ ] Find missing indexes for frequent query patterns
   - [ ] Review index bloat and fragmentation
   - [ ] Check composite index column ordering
2. Design index changes

### Index Recommendations

| Table | Recommendation | Type | Affected Queries | Write Impact | Priority |
|-------|---------------|------|-----------------|-------------|----------|
|       | Add/Remove/Modify | B-tree/Hash/GIN | | Low/Med/High | 1-5 |

## Phase 4: Schema & Data Model Review
1. Review schema design
   - [ ] Identify tables with excessive columns
   - [ ] Check for denormalization opportunities
   - [ ] Review data types (oversized columns)
   - [ ] Assess partitioning candidates (large tables)
   - [ ] Evaluate archival strategy for historical data
2. Check for schema-level performance issues

## Phase 5: Configuration Tuning
1. Review and optimize database configuration
   - [ ] Memory allocation (shared buffers, work memory)
   - [ ] Connection limits and pooling
   - [ ] WAL / transaction log settings
   - [ ] Checkpoint frequency and timing
   - [ ] Autovacuum settings (PostgreSQL) or table maintenance
   - [ ] Query cache settings
   - [ ] Parallel query configuration
2. Apply changes incrementally and measure impact

### Configuration Changes

| Parameter | Current | Recommended | Impact | Risk |
|-----------|---------|-------------|--------|------|
|           |         |             |        | Low/Med/High |

## Phase 6: Monitoring & Ongoing Optimization
1. Set up performance monitoring dashboards
2. Configure alerts for key metrics degradation
3. Implement query performance regression detection
4. Schedule regular index maintenance
5. Plan capacity based on growth trends

## Output Format
- **Baseline Report**: Current performance metrics snapshot
- **Query Analysis**: Top problematic queries with solutions
- **Index Recommendations**: Changes with expected impact
- **Configuration Changes**: Parameter adjustments with rationale
- **Monitoring Setup**: Dashboards and alerts configuration

## Action Items
- [ ] Collect performance baseline metrics
- [ ] Analyze and optimize top problematic queries
- [ ] Implement index changes (test in staging first)
- [ ] Apply configuration tuning incrementally
- [ ] Set up ongoing performance monitoring
- [ ] Schedule monthly query performance review
