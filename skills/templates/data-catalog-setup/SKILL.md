---
name: data-catalog-setup
enabled: true
description: |
  Guides the setup and implementation of a data catalog to enable data discovery, documentation, lineage tracking, and governance. Covers tool selection, metadata extraction, automated cataloging, ownership assignment, and adoption strategies for driving self-service data access.
required_connections:
  - prefix: data-catalog
    label: "Data Catalog Platform"
  - prefix: data-platform
    label: "Data Platform"
config_fields:
  - key: catalog_tool
    label: "Data Catalog Tool"
    required: true
    placeholder: "e.g., DataHub, Atlan, Collibra, Unity Catalog, Alation"
  - key: data_sources
    label: "Data Sources to Catalog"
    required: true
    placeholder: "e.g., Snowflake, PostgreSQL, S3, Kafka, dbt"
  - key: team_count
    label: "Number of Data Consumer Teams"
    required: false
    placeholder: "e.g., 15"
features:
  - DATA
  - CATALOG
  - GOVERNANCE
---

# Data Catalog Setup

## Phase 1: Requirements & Tool Setup
1. Define catalog requirements
   - [ ] Automated metadata extraction from data sources
   - [ ] Column-level lineage tracking
   - [ ] Business glossary and term management
   - [ ] Data quality scores integration
   - [ ] Access request workflow
   - [ ] Search and discovery interface
   - [ ] API access for programmatic integration
   - [ ] Classification and tagging support
2. Configure catalog tool and integrations
3. Set up authentication and access controls

### Data Source Integration Plan

| Source | Type | Connector | Metadata Scope | Lineage | Priority |
|--------|------|-----------|---------------|---------|----------|
|        | DB/Lake/Stream/API | Native/Custom | Schema/Stats/Quality | Yes/No | 1-5 |

## Phase 2: Automated Metadata Extraction
1. Configure metadata extraction
   - [ ] Schema metadata (tables, columns, types)
   - [ ] Usage statistics (query frequency, popular tables)
   - [ ] Data freshness and update timestamps
   - [ ] Column-level statistics (null rate, cardinality)
   - [ ] Lineage from transformation tools (dbt, Spark, Airflow)
2. Set extraction schedules (hourly, daily)
3. Validate extracted metadata accuracy
4. Handle schema evolution gracefully

## Phase 3: Business Context Enrichment
1. Add business context to technical metadata
   - [ ] Business descriptions for tables and columns
   - [ ] Business glossary terms and definitions
   - [ ] Data domain classification
   - [ ] Data sensitivity/classification labels
   - [ ] Data owners and stewards
   - [ ] Related documentation and wiki links
   - [ ] Certified/endorsed dataset badges
2. Prioritize enrichment for most-used datasets
3. Assign enrichment owners per domain

### Enrichment Progress

| Domain | Datasets | Descriptions | Owners Assigned | Classified | Certified | Progress |
|--------|---------|-------------|----------------|-----------|----------|----------|
|        |         | /total      | /total         | /total    | /total   | %        |

## Phase 4: Lineage & Impact Analysis
1. Implement data lineage tracking
   - [ ] Column-level lineage from ETL/ELT tools
   - [ ] Dashboard-to-dataset lineage (BI tools)
   - [ ] API-to-dataset lineage
   - [ ] Cross-system lineage (operational DB to warehouse)
2. Enable impact analysis
   - [ ] Identify downstream consumers of any dataset
   - [ ] Assess impact before schema changes
   - [ ] Alert consumers of upstream changes

## Phase 5: Access & Governance Integration
1. Integrate access management
   - [ ] Self-service data access requests
   - [ ] Approval workflow for sensitive data
   - [ ] Access audit trail
   - [ ] Data classification drives access policies
   - [ ] Time-bound access grants
2. Integrate data quality metrics
3. Link governance policies to catalog entries

## Phase 6: Adoption & Training
1. Drive catalog adoption
   - [ ] Onboarding sessions for data consumers
   - [ ] Integrate catalog into daily workflows (Slack, IDE)
   - [ ] Measure adoption metrics (searches, views, contributions)
   - [ ] Gamify contributions (leaderboard for documentation)
   - [ ] Embed catalog links in BI tools and notebooks
2. Track adoption metrics

### Adoption Metrics

| Metric | Month 1 | Month 3 | Month 6 | Target |
|--------|---------|---------|---------|--------|
| Weekly active users | | | | > 50% of data users |
| Searches per week | | | | |
| Datasets documented | % | % | % | > 80% |
| Access requests via catalog | | | | > 90% |

## Output Format
- **Integration Plan**: Data sources and connector configuration
- **Enrichment Guide**: Standards for business metadata
- **Lineage Map**: Cross-system data lineage visualization
- **Adoption Dashboard**: Usage metrics and trends
- **Governance Integration**: Access policies and workflows

## Action Items
- [ ] Configure catalog tool and data source connectors
- [ ] Run initial automated metadata extraction
- [ ] Enrich top 20% most-used datasets with business context
- [ ] Implement lineage tracking from transformation tools
- [ ] Set up access request workflow
- [ ] Conduct onboarding sessions for data teams
- [ ] Track adoption metrics monthly
