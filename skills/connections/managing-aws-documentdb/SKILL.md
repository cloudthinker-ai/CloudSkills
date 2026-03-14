---
name: managing-aws-documentdb
description: |
  AWS DocumentDB cluster management and health analysis. Covers cluster inventory, instance status, parameter groups, subnet groups, snapshots, event subscriptions, and performance metrics. Use when inspecting DocumentDB clusters, debugging connectivity issues, reviewing backup configurations, or analyzing cluster performance.
connection_type: aws
preload: false
---

# AWS DocumentDB Management Skill

Analyze and manage AWS DocumentDB clusters, instances, and configurations.

## MANDATORY: Discovery-First Pattern

**Always list clusters before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash
export AWS_PAGER=""

echo "=== DocumentDB Clusters ==="
aws docdb describe-db-clusters --output text \
  --query 'DBClusters[].[DBClusterIdentifier,Status,Engine,EngineVersion,DBClusterMembers[0].DBInstanceIdentifier]' \
  --filter Name=engine,Values=docdb

echo ""
echo "=== DocumentDB Instances ==="
aws docdb describe-db-instances --output text \
  --query "DBInstances[?Engine=='docdb'].[DBInstanceIdentifier,DBInstanceClass,DBInstanceStatus,AvailabilityZone,DBClusterIdentifier]"

echo ""
echo "=== Cluster Endpoints ==="
aws docdb describe-db-clusters --output text \
  --query 'DBClusters[].[DBClusterIdentifier,Endpoint,ReaderEndpoint,Port]' \
  --filter Name=engine,Values=docdb

echo ""
echo "=== Parameter Groups ==="
aws docdb describe-db-cluster-parameter-groups --output text \
  --query 'DBClusterParameterGroups[].[DBClusterParameterGroupName,DBParameterGroupFamily,Description]'
```

### Phase 2: Analysis

```bash
#!/bin/bash
export AWS_PAGER=""

END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S")
START_TIME=$(date -u -d "7 days ago" +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || date -u -v-7d +"%Y-%m-%dT%H:%M:%S")

echo "=== Cluster Health Metrics ==="
for cluster in $(aws docdb describe-db-clusters --filter Name=engine,Values=docdb --output text --query 'DBClusters[].DBClusterIdentifier'); do
  {
    cpu=$(aws cloudwatch get-metric-statistics --namespace AWS/DocDB --metric-name CPUUtilization \
      --dimensions Name=DBClusterIdentifier,Value="$cluster" \
      --start-time "$START_TIME" --end-time "$END_TIME" --period 604800 --statistics Average \
      --output text --query 'Datapoints[0].Average')
    mem=$(aws cloudwatch get-metric-statistics --namespace AWS/DocDB --metric-name FreeableMemory \
      --dimensions Name=DBClusterIdentifier,Value="$cluster" \
      --start-time "$START_TIME" --end-time "$END_TIME" --period 604800 --statistics Average \
      --output text --query 'Datapoints[0].Average')
    conns=$(aws cloudwatch get-metric-statistics --namespace AWS/DocDB --metric-name DatabaseConnections \
      --dimensions Name=DBClusterIdentifier,Value="$cluster" \
      --start-time "$START_TIME" --end-time "$END_TIME" --period 604800 --statistics Maximum \
      --output text --query 'Datapoints[0].Maximum')
    printf "%s\tCPU:%.1f%%\tFreeMem:%s\tMaxConns:%s\n" "$cluster" "${cpu:-0}" "${mem:-N/A}" "${conns:-0}"
  } &
done
wait

echo ""
echo "=== Snapshots ==="
aws docdb describe-db-cluster-snapshots --output text \
  --query 'DBClusterSnapshots[].[DBClusterSnapshotIdentifier,DBClusterIdentifier,Status,SnapshotCreateTime,SnapshotType]' | head -15

echo ""
echo "=== Pending Maintenance ==="
aws docdb describe-pending-maintenance-actions --output text \
  --query 'PendingMaintenanceActions[].[ResourceIdentifier,PendingMaintenanceActionDetails[0].Action,PendingMaintenanceActionDetails[0].AutoAppliedAfterDate]' 2>/dev/null

echo ""
echo "=== Recent Events ==="
aws docdb describe-events --source-type db-cluster --duration 1440 --output text \
  --query 'Events[].[SourceIdentifier,Message,Date]' | head -10
```

## Output Format

- Target ≤50 lines per output
- Use `--output text --query` for all commands
- Tab-delimited fields: ClusterId, Status, InstanceClass, Metric
- Aggregate metrics into summary lines per cluster
- Never dump full parameter group values -- show group names only

## Common Pitfalls

- **Engine filter**: DocumentDB uses engine `docdb` -- always filter to avoid mixing with RDS results
- **API compatibility**: DocumentDB shares some APIs with RDS (`docdb` commands map to `rds` API) -- use `aws docdb` subcommand
- **Elastic clusters**: Newer elastic clusters use separate API calls (`describe-elastic-clusters`)
- **TLS required**: Default clusters require TLS -- connection failures often relate to missing CA certificate
- **Storage auto-scaling**: Storage scales automatically up to 128 TiB -- no manual provisioning needed
- **Replica lag**: Check `DBInstanceReplicaLag` metric for read replicas -- high lag affects read consistency
- **Backup retention**: Default is 1 day -- check `BackupRetentionPeriod` in cluster configuration
