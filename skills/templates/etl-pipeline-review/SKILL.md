---
name: etl-pipeline-review
enabled: true
description: |
  Reviews ETL/ELT pipeline architecture for reliability, performance, data quality, and maintainability. Covers pipeline design patterns, error handling, idempotency, monitoring, testing strategies, and optimization opportunities for batch and streaming data pipelines.
required_connections:
  - prefix: data-platform
    label: "Data Platform"
  - prefix: orchestrator
    label: "Pipeline Orchestrator"
config_fields:
  - key: pipeline_tool
    label: "Pipeline Tool/Framework"
    required: true
    placeholder: "e.g., Airflow, dbt, Spark, Fivetran, Glue, Dataflow"
  - key: pipeline_name
    label: "Pipeline Name or Domain"
    required: true
    placeholder: "e.g., orders-to-warehouse, customer-360"
  - key: pipeline_type
    label: "Pipeline Type"
    required: false
    placeholder: "e.g., batch ETL, streaming, ELT, CDC"
features:
  - DATA
  - ETL
  - PIPELINE
---

# ETL Pipeline Review

## Phase 1: Architecture Assessment
1. Map the pipeline architecture
   - [ ] Data sources and ingestion methods
   - [ ] Transformation layers and logic
   - [ ] Target data stores and schemas
   - [ ] Orchestration and scheduling
   - [ ] Dependencies between pipelines
   - [ ] Data volume and processing time
2. Document pipeline SLAs and requirements
3. Identify single points of failure

### Pipeline Architecture Summary

| Component | Technology | Input | Output | Volume | SLA |
|-----------|-----------|-------|--------|--------|-----|
| Ingestion | | source | raw | GB/day | |
| Transform | | raw | cleaned | GB/day | |
| Load | | cleaned | warehouse | GB/day | |
| Orchestration | | N/A | N/A | N/A | |

## Phase 2: Reliability Review
1. Assess pipeline reliability
   - [ ] Idempotency: re-runs produce same result
   - [ ] Exactly-once or at-least-once semantics
   - [ ] Error handling and retry logic
   - [ ] Dead letter queues for failed records
   - [ ] Graceful handling of schema evolution
   - [ ] Backfill capability for historical data
   - [ ] Pipeline timeout configuration
   - [ ] Alerting on pipeline failures
2. Review failure history and patterns

### Reliability Checklist

| Property | Implemented | Tested | Evidence |
|----------|-------------|--------|----------|
| Idempotent re-runs | [ ] | [ ] | |
| Retry with backoff | [ ] | [ ] | |
| Dead letter handling | [ ] | [ ] | |
| Schema evolution | [ ] | [ ] | |
| Backfill support | [ ] | [ ] | |
| Timeout handling | [ ] | [ ] | |
| Partial failure recovery | [ ] | [ ] | |

## Phase 3: Performance Review
1. Assess pipeline performance
   - [ ] Processing time vs. SLA
   - [ ] Resource utilization (CPU, memory, I/O)
   - [ ] Partitioning strategy for parallelism
   - [ ] Incremental processing (vs. full reload)
   - [ ] Pushdown optimization (filter/aggregate at source)
   - [ ] Data serialization format efficiency
   - [ ] Shuffle and data skew issues (Spark)
   - [ ] Connection pooling and resource management
2. Identify performance bottlenecks

### Performance Metrics

| Stage | Avg Duration | P95 Duration | SLA | Data Volume | Bottleneck |
|-------|-------------|-------------|-----|-------------|-----------|
|       | min         | min         | min | GB          | CPU/IO/Network/Skew |

## Phase 4: Data Quality Integration
1. Assess data quality checks in pipeline
   - [ ] Input validation (schema, null checks, ranges)
   - [ ] Row count reconciliation (source vs. target)
   - [ ] Business rule validation
   - [ ] Duplicate detection
   - [ ] Freshness checks
   - [ ] Quality gates that halt pipeline on failure
   - [ ] Data quality test framework (dbt tests, Great Expectations)
2. Review data quality incident history

## Phase 5: Testing & Maintainability
1. Assess testing practices
   - [ ] Unit tests for transformation logic
   - [ ] Integration tests with test datasets
   - [ ] End-to-end validation tests
   - [ ] Test data management strategy
   - [ ] CI/CD for pipeline code changes
2. Assess maintainability
   - [ ] Code organized and modular
   - [ ] Documentation up to date
   - [ ] Naming conventions consistent
   - [ ] Configuration externalized (not hardcoded)
   - [ ] Version control for all pipeline code
   - [ ] Lineage tracking and metadata management

## Phase 6: Recommendations
1. Prioritize improvements by impact and effort
2. Address reliability gaps first
3. Optimize performance bottlenecks
4. Enhance data quality checks
5. Improve testing coverage

### Review Summary

| Area | Score (1-5) | Key Finding | Recommendation | Priority |
|------|-----------|-------------|----------------|----------|
| Architecture | | | | |
| Reliability | | | | |
| Performance | | | | |
| Data Quality | | | | |
| Testing | | | | |
| Maintainability | | | | |

## Output Format
- **Architecture Diagram**: Pipeline flow with components and data stores
- **Reliability Assessment**: Failure modes and mitigation status
- **Performance Report**: Timing, bottlenecks, and optimization plan
- **Quality Check Inventory**: Current checks and gaps
- **Improvement Plan**: Prioritized recommendations

## Action Items
- [ ] Document pipeline architecture and dependencies
- [ ] Implement missing reliability controls (idempotency, retries)
- [ ] Optimize top performance bottlenecks
- [ ] Add data quality checks at each pipeline stage
- [ ] Improve test coverage for transformations
- [ ] Set up pipeline monitoring and alerting
- [ ] Schedule quarterly pipeline review
