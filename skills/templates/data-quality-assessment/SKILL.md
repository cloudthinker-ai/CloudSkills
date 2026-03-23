---
name: data-quality-assessment
enabled: true
description: |
  Use when performing data quality assessment — conducts a systematic assessment
  of data quality across key dimensions including completeness, accuracy,
  consistency, timeliness, uniqueness, and validity. Identifies data quality
  issues, quantifies their business impact, and produces a remediation plan with
  automated quality monitoring.
required_connections:
  - prefix: data-platform
    label: "Data Platform"
config_fields:
  - key: data_domain
    label: "Data Domain to Assess"
    required: true
    placeholder: "e.g., Customer, Product, Orders, Financial"
  - key: primary_data_store
    label: "Primary Data Store"
    required: true
    placeholder: "e.g., Snowflake, BigQuery, PostgreSQL, S3"
  - key: business_impact
    label: "Business Context for Data Quality"
    required: false
    placeholder: "e.g., analytics accuracy, ML model training, regulatory reporting"
features:
  - DATA
  - QUALITY
  - ASSESSMENT
---

# Data Quality Assessment

## Phase 1: Scope & Profiling
1. Define assessment scope
   - [ ] Tables/datasets to assess
   - [ ] Critical fields per dataset
   - [ ] Business rules and constraints
   - [ ] Expected data volumes and update frequency
   - [ ] Downstream consumers and their requirements
2. Run data profiling
   - [ ] Row counts and growth trends
   - [ ] Column-level statistics (null rate, distinct values, min/max)
   - [ ] Data type distribution
   - [ ] Value frequency analysis for categorical fields
   - [ ] Pattern analysis for text fields

### Data Profile Summary

| Table | Rows | Columns | Null Rate (avg) | Last Updated | Update Frequency |
|-------|------|---------|----------------|-------------|-----------------|
|       |      |         | %              |             | hourly/daily/etc |

## Phase 2: Quality Dimension Assessment

### Completeness (required fields populated)
| Table | Field | Expected | Actual | Null Rate | Score |
|-------|-------|----------|--------|-----------|-------|
|       |       | 100%     |        | %         | /100  |

### Accuracy (values reflect reality)
| Table | Field | Validation Rule | Pass Rate | Sample Failures | Score |
|-------|-------|----------------|----------|----------------|-------|
|       |       |                | %        |                | /100  |

### Consistency (data matches across systems)
| Field | Source A | Source B | Match Rate | Discrepancy Count | Score |
|-------|---------|---------|-----------|-------------------|-------|
|       |         |         | %         |                   | /100  |

### Timeliness (data available when needed)
| Dataset | Expected Freshness | Actual Freshness | SLA Met | Score |
|---------|-------------------|-----------------|---------|-------|
|         | < hours           | hours           | Yes/No  | /100  |

### Uniqueness (no unintended duplicates)
| Table | Key Fields | Total Rows | Duplicate Rows | Duplicate Rate | Score |
|-------|-----------|-----------|---------------|---------------|-------|
|       |           |           |               | %             | /100  |

### Validity (values conform to rules)
| Table | Field | Rule | Valid Rate | Invalid Examples | Score |
|-------|-------|------|----------|-----------------|-------|
|       |       | format/range/enum |  %  |                 | /100  |

## Phase 3: Issue Prioritization
1. Quantify business impact per issue
   - [ ] Revenue impact (incorrect pricing, missed orders)
   - [ ] Operational impact (failed processes, manual workarounds)
   - [ ] Compliance risk (regulatory data requirements)
   - [ ] Analytics impact (incorrect insights, poor ML models)
   - [ ] Customer impact (wrong communications, data errors)
2. Prioritize by impact and fixability

### Issue Priority Matrix

| Issue | Dimension | Affected Records | Business Impact | Root Cause | Fix Effort | Priority |
|-------|-----------|-----------------|----------------|-----------|-----------|----------|
|       |           |                 | High/Med/Low   |           | Low/Med/High | 1-5   |

## Phase 4: Root Cause Analysis
1. Investigate top quality issues
   - [ ] Source system data entry errors
   - [ ] ETL transformation bugs
   - [ ] Missing validation rules at ingestion
   - [ ] Schema evolution without migration
   - [ ] Integration failures dropping or corrupting data
   - [ ] Stale reference data
2. Document root cause per issue

## Phase 5: Remediation Plan
1. Fix existing data quality issues
2. Implement preventive controls
   - [ ] Input validation at source
   - [ ] Schema enforcement in pipelines
   - [ ] Data contracts between producers and consumers
   - [ ] Automated quality checks in ETL/ELT pipelines
   - [ ] Referential integrity enforcement
3. Set up data quality monitoring

## Phase 6: Automated Quality Monitoring
1. Implement continuous quality checks
   - [ ] Automated quality tests in data pipelines (dbt tests, Great Expectations)
   - [ ] Quality score dashboards per domain
   - [ ] Anomaly detection for quality metrics
   - [ ] Alerting when quality drops below threshold
   - [ ] Quality trend reporting (weekly/monthly)
2. Define quality SLAs per domain

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Data Profile Report**: Statistical profile of all assessed datasets
- **Quality Scorecard**: Score per dimension per dataset
- **Issue Inventory**: All issues with severity and root cause
- **Remediation Plan**: Fixes and preventive controls with timelines
- **Monitoring Configuration**: Automated quality checks and alerts

## Action Items
- [ ] Run data profiling on all in-scope datasets
- [ ] Assess quality across all six dimensions
- [ ] Prioritize issues by business impact
- [ ] Investigate and document root causes
- [ ] Implement data fixes and preventive controls
- [ ] Deploy automated quality monitoring
- [ ] Establish monthly quality review cadence
