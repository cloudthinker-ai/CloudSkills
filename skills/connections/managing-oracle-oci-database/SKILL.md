---
name: managing-oracle-oci-database
description: |
  Oracle OCI Database deep-dive management via the OCI CLI. Covers DB Systems, Autonomous Databases, backups, Data Guard, patching, and performance metrics. Use for detailed OCI database analysis.
connection_type: oracle-oci-database
preload: false
---

# Managing Oracle OCI Database (Deep Dive)

Deep-dive Oracle OCI Database management using the `oci db` CLI commands.

## MANDATORY: Discovery-First Pattern

**Always discover available resources before performing analysis.**

### Phase 1: Discovery

```bash
#!/bin/bash

COMPARTMENT_ID="${OCI_COMPARTMENT_ID:?Set OCI_COMPARTMENT_ID}"

echo "=== DB Systems ==="
oci db system list --compartment-id "$COMPARTMENT_ID" \
    --query 'data[*].{id:id,name:"display-name",shape:shape,state:"lifecycle-state",edition:"database-edition",version:version,nodes:"node-count",storage:"data-storage-size-in-gbs"}' \
    --output table 2>/dev/null | head -20

echo ""
echo "=== Autonomous Databases ==="
oci db autonomous-database list --compartment-id "$COMPARTMENT_ID" \
    --query 'data[*].{id:id,name:"display-name",cpus:"cpu-core-count",storage_tb:"data-storage-size-in-tbs",state:"lifecycle-state",workload:"db-workload",version:"db-version",free_tier:"is-free-tier"}' \
    --output table 2>/dev/null | head -20

echo ""
echo "=== Exadata Infrastructure ==="
oci db exadata-infrastructure list --compartment-id "$COMPARTMENT_ID" \
    --query 'data[*].{id:id,name:"display-name",shape:shape,state:"lifecycle-state",compute:"compute-count",storage:"storage-count"}' \
    --output table 2>/dev/null | head -10

echo ""
echo "=== DB Homes ==="
oci db db-home list --compartment-id "$COMPARTMENT_ID" \
    --query 'data[*].{id:id,name:"display-name",version:"db-version",state:"lifecycle-state"}' \
    --output table 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

COMPARTMENT_ID="${OCI_COMPARTMENT_ID:?Set OCI_COMPARTMENT_ID}"

echo "=== Autonomous Database Details ==="
ADB_ID="${1:?Autonomous Database OCID required}"
oci db autonomous-database get --autonomous-database-id "$ADB_ID" \
    --query 'data.{name:"display-name",state:"lifecycle-state",cpus:"cpu-core-count",storage_tb:"data-storage-size-in-tbs",workload:"db-workload",version:"db-version",auto_scaling:"is-auto-scaling-enabled",mtls:"is-mtls-connection-required",free_tier:"is-free-tier",created:"time-created",backup_retention:"backup-retention-period-in-days",data_guard:"is-data-guard-enabled"}' \
    --output table 2>/dev/null

echo ""
echo "=== Backups ==="
oci db autonomous-database-backup list --compartment-id "$COMPARTMENT_ID" --autonomous-database-id "$ADB_ID" \
    --query 'data[*].{id:id,name:"display-name",type:type,state:"lifecycle-state",size_tb:"database-size-in-tbs",created:"time-started"}' \
    --output table 2>/dev/null | head -10

echo ""
echo "=== Connection Strings ==="
oci db autonomous-database get --autonomous-database-id "$ADB_ID" \
    --query 'data."connection-strings".profiles[*].{consumer_group:"consumer-group",protocol:protocol,tls:"tls-authentication",value:value}' \
    --output table 2>/dev/null | head -10

echo ""
echo "=== Performance Metrics ==="
oci monitoring metric-data summarize-metrics-data --compartment-id "$COMPARTMENT_ID" \
    --namespace oci_autonomous_database \
    --query-text "CpuUtilization[1h]{resourceId = \"$ADB_ID\"}.mean()" \
    --query 'data[0]."aggregated-datapoints"[-5:]' \
    --output table 2>/dev/null | head -10

echo ""
echo "=== Storage Utilization ==="
oci monitoring metric-data summarize-metrics-data --compartment-id "$COMPARTMENT_ID" \
    --namespace oci_autonomous_database \
    --query-text "StorageUtilization[1h]{resourceId = \"$ADB_ID\"}.mean()" \
    --query 'data[0]."aggregated-datapoints"[-3:]' \
    --output table 2>/dev/null | head -5

echo ""
echo "=== Data Guard Status ==="
oci db autonomous-database get --autonomous-database-id "$ADB_ID" \
    --query 'data.{"data_guard_enabled":"is-data-guard-enabled","standby_db":"standby-db","role":role,"peer_db_ids":"peer-db-ids"}' \
    --output table 2>/dev/null

echo ""
echo "=== Applicable Patches ==="
oci db autonomous-database list --compartment-id "$COMPARTMENT_ID" --autonomous-database-id "$ADB_ID" \
    --query 'data[*].{version:"db-version",state:"lifecycle-state"}' \
    --output table 2>/dev/null | head -5
```

## Output Format

```
ADB_OCID                              NAME        STATE     CPUS  STORAGE  WORKLOAD
ocid1.autonomousdatabase.oc1.abc123   prod-atp    AVAILABLE 4     2TB      OLTP
ocid1.autonomousdatabase.oc1.def456   analytics   AVAILABLE 2     1TB      DW
```

## Safety Rules
- Use read-only commands: `list`, `get`, `summarize-metrics-data`
- Never run `terminate`, `stop`, `update`, `delete` without explicit user confirmation
- Always pass `--compartment-id` for resource listing
- Use `--query` and `--output table` for clean output
- Limit output with `| head -N` to stay under 50 lines
