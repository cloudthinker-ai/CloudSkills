---
name: data-retention-policy
enabled: true
description: |
  Template for defining and implementing data retention policies across systems. Covers data classification, regulatory requirements mapping, retention period definition, automated lifecycle management, deletion verification, and audit trail maintenance to ensure compliance and efficient storage use.
required_connections:
  - prefix: aws
    label: "AWS (or cloud provider)"
config_fields:
  - key: system_name
    label: "System/Service Name"
    required: true
    placeholder: "e.g., customer-platform"
  - key: data_jurisdiction
    label: "Primary Data Jurisdiction"
    required: true
    placeholder: "e.g., EU (GDPR), US (CCPA), global"
  - key: review_cycle
    label: "Policy Review Cycle"
    required: false
    placeholder: "e.g., annual, semi-annual"
features:
  - COMPLIANCE
  - DATA_GOVERNANCE
---

# Data Retention Policy Skill

Define data retention policy for **{{ system_name }}** under **{{ data_jurisdiction }}** jurisdiction.

## Workflow

### Phase 1 — Data Inventory

```
DATA CATALOG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Data stores identified:
    Store              | Type      | Size   | Contains PII
    ___________________|___________|________|_____________
                       |           |        |
                       |           |        |
                       |           |        |

[ ] Data categories:
    [ ] Customer personal data (PII)
    [ ] Financial/transaction data
    [ ] Authentication/access logs
    [ ] Application logs
    [ ] Analytics/telemetry data
    [ ] User-generated content
    [ ] Backup/archive data
    [ ] Temporary/cache data
```

### Phase 2 — Regulatory Requirements

```
REGULATORY MAPPING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Jurisdiction: {{ data_jurisdiction }}

Regulation          | Data Type          | Min Retention | Max Retention
____________________|____________________|_______________|______________
GDPR (Art. 5(1)(e))| Personal data      | N/A           | Purpose-limited
GDPR (Art. 17)     | Subject to erasure | N/A           | Upon request
CCPA                | Consumer data      | N/A           | Purpose-limited
PCI DSS             | Cardholder data    | N/A           | Business need
SOX                 | Financial records  | 7 years       | N/A
HIPAA               | Health records     | 6 years       | N/A
Tax regulations     | Tax records        | ___ years     | N/A

[ ] Legal review completed: [ ] YES — date: ___
[ ] Conflicts between regulations resolved: [ ] YES
```

### Phase 3 — Retention Schedule

```
RETENTION PERIODS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Data Category           | Active  | Archive | Delete After | Legal Hold
________________________|_________|_________|______________|___________
Customer PII            |         |         |              |
Transaction records     |         |         |              |
Access/auth logs        |         |         |              |
Application logs        |         |         |              |
Analytics data          |         |         |              |
User content            |         |         |              |
Backups                 |         |         |              |
Temp/cache              |         |         |              |

LIFECYCLE STAGES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Active:    Hot storage, full access
Archive:   Cold storage, restricted access, compressed
Delete:    Permanent removal, verified destruction
Legal Hold: Suspended deletion, preserved for litigation
```

### Phase 4 — Implementation

```
AUTOMATION SETUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Automated lifecycle policies configured:
    [ ] S3 lifecycle rules
    [ ] Database TTL / partitioned deletion
    [ ] Log management retention policies
    [ ] Backup rotation policies
[ ] Deletion mechanism:
    [ ] Soft delete (tombstone, recoverable for ___ days)
    [ ] Hard delete (permanent, verified)
    [ ] Crypto-shredding (for encrypted data)
[ ] Deletion verification:
    [ ] Deletion logs maintained
    [ ] Spot checks scheduled
    [ ] Audit trail preserved (metadata only, not content)
```

### Phase 5 — Policy Documentation and Review

```
GOVERNANCE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Policy document published
[ ] Data owners acknowledged policy
[ ] Exception process defined:
    - Request template available
    - Approval chain: ___
[ ] Legal hold process documented
[ ] Data subject request (DSR) process integrated
[ ] Review cycle: {{ review_cycle }}
[ ] Next review date: ___
[ ] Policy version: ___
```

## Output Format

Produce a data retention policy document with:
1. **Data inventory** (categories, stores, classifications)
2. **Regulatory requirements** (applicable regulations, retention mandates)
3. **Retention schedule** (periods by data category with lifecycle stages)
4. **Implementation plan** (automation, deletion mechanisms, verification)
5. **Governance** (review cycle, exceptions, legal hold procedures)
