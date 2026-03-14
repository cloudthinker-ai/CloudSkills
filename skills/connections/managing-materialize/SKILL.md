---
name: managing-materialize
description: |
  Materialize streaming database management — monitor clusters, sources, sinks, materialized views, indexes, and dataflow health. Use when debugging ingestion lag, inspecting view dependencies, auditing cluster utilization, or reviewing error logs.
connection_type: materialize
preload: false
---

# Managing Materialize

Manage and monitor Materialize streaming database — clusters, sources, sinks, materialized views, and dataflow health.

## Discovery Phase

```bash
#!/bin/bash

mz_cmd() {
    psql "$MATERIALIZE_URL" --no-psqlrc -t -A -F $'\t' -c "$1" 2>/dev/null
}

echo "=== Clusters ==="
mz_cmd "SELECT id, name, managed, size, replication_factor
        FROM mz_clusters
        ORDER BY name
        LIMIT 10;" | column -t

echo ""
echo "=== Sources ==="
mz_cmd "SELECT id, name, type, size, cluster_id
        FROM mz_sources
        WHERE id LIKE 'u%'
        ORDER BY name
        LIMIT 15;" | column -t

echo ""
echo "=== Materialized Views ==="
mz_cmd "SELECT id, name, cluster_id
        FROM mz_materialized_views
        WHERE id LIKE 'u%'
        ORDER BY name
        LIMIT 15;" | column -t

echo ""
echo "=== Sinks ==="
mz_cmd "SELECT id, name, type, cluster_id
        FROM mz_sinks
        WHERE id LIKE 'u%'
        ORDER BY name
        LIMIT 10;" | column -t

echo ""
echo "=== Schemas ==="
mz_cmd "SELECT s.name AS schema, d.name AS database
        FROM mz_schemas s JOIN mz_databases d ON s.database_id = d.id
        ORDER BY d.name, s.name
        LIMIT 15;" | column -t
```

## Analysis Phase

```bash
#!/bin/bash

mz_cmd() {
    psql "$MATERIALIZE_URL" --no-psqlrc -t -A -F $'\t' -c "$1" 2>/dev/null
}

echo "=== Source Ingestion Status ==="
mz_cmd "SELECT s.name, ss.status, ss.error, ss.updated_at
        FROM mz_source_statuses ss
        JOIN mz_sources s ON ss.id = s.id
        ORDER BY ss.updated_at DESC
        LIMIT 10;" | column -t

echo ""
echo "=== Sink Status ==="
mz_cmd "SELECT s.name, ss.status, ss.error, ss.updated_at
        FROM mz_sink_statuses ss
        JOIN mz_sinks s ON ss.id = s.id
        ORDER BY ss.updated_at DESC
        LIMIT 10;" | column -t

echo ""
echo "=== Cluster Replica Status ==="
mz_cmd "SELECT c.name AS cluster, cr.name AS replica, crs.status, crs.updated_at
        FROM mz_cluster_replica_statuses crs
        JOIN mz_cluster_replicas cr ON crs.replica_id = cr.id
        JOIN mz_clusters c ON cr.cluster_id = c.id
        LIMIT 10;" | column -t

echo ""
echo "=== Materialized View Freshness ==="
mz_cmd "SELECT mv.name,
               EXTRACT(EPOCH FROM mz_now() - write_frontier)::int AS lag_seconds
        FROM mz_materialized_views mv
        JOIN mz_frontiers f ON mv.id = f.object_id
        WHERE mv.id LIKE 'u%'
        ORDER BY lag_seconds DESC
        LIMIT 10;" | column -t

echo ""
echo "=== Recent Errors ==="
mz_cmd "SELECT source_name, error, count, last_occurred
        FROM mz_source_status_history
        WHERE error IS NOT NULL
        ORDER BY last_occurred DESC
        LIMIT 10;" | column -t
```

## Output Format

```
CLUSTERS
ID       Name           Managed  Size     Replication
<id>     <cluster>      true     <size>   <n>

SOURCES
ID       Name           Type     Size     Cluster
<id>     <source>       <type>   <size>   <cluster-id>

SOURCE STATUS
Name           Status     Error    Updated
<source>       running    <null>   <timestamp>

MV FRESHNESS
Name             Lag (seconds)
<mv-name>        <n>

CLUSTER REPLICAS
Cluster      Replica    Status     Updated
<cluster>    <replica>  ready      <timestamp>
```
