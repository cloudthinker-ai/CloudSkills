---
name: managing-apache-airflow-deep
description: |
  Apache Airflow deep management covering DAG inventory, task instance monitoring, scheduler health, executor status, pool and variable management, connection auditing, and SLA miss tracking. Use when investigating DAG failures, analyzing task duration trends, monitoring scheduler performance, or auditing Airflow configurations.
connection_type: airflow
preload: false
---

# Apache Airflow Deep Management Skill

Manage and monitor Apache Airflow DAGs, task instances, scheduler, and infrastructure health.

## MANDATORY: Discovery-First Pattern

**Always list DAGs and check scheduler health before querying specific task instances.**

### Phase 1: Discovery

```bash
#!/bin/bash

AIRFLOW_API="${AIRFLOW_BASE_URL}/api/v1"

airflow_api() {
    curl -s -u "$AIRFLOW_USERNAME:$AIRFLOW_PASSWORD" \
         -H "Content-Type: application/json" \
         "${AIRFLOW_API}/${1}"
}

echo "=== Airflow Health ==="
airflow_api "health" | jq '{
    metadatabase: .metadatabase.status,
    scheduler: .scheduler.status,
    scheduler_heartbeat: .scheduler.latest_scheduler_heartbeat
}'

echo ""
echo "=== DAGs Summary ==="
airflow_api "dags?limit=50" | jq -r '
    .dags[] |
    "\(.dag_id)\t\(.is_paused)\t\(.schedule_interval // "None")\t\(.owners | join(","))"
' | column -t | head -30

echo ""
echo "=== Pools ==="
airflow_api "pools" | jq -r '
    .pools[] |
    "\(.name)\t\(.slots)\tqueued=\(.queued_slots)\trunning=\(.running_slots)\topen=\(.open_slots)"
' | column -t
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Failed DAG Runs (last 24h) ==="
YESTERDAY=$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-24H +%Y-%m-%dT%H:%M:%SZ)
airflow_api "dags/~/dagRuns?start_date_gte=${YESTERDAY}&state=failed&limit=20" | jq -r '
    .dag_runs[] |
    "\(.dag_id)\t\(.dag_run_id)\t\(.state)\t\(.end_date // "running")"
' | column -t | head -20

echo ""
echo "=== Failed Task Instances (last 24h) ==="
airflow_api "dags/~/dagRuns/~/taskInstances?start_date_gte=${YESTERDAY}&state=failed&limit=20" | jq -r '
    .task_instances[] |
    "\(.dag_id)\t\(.task_id)\t\(.state)\t\(.try_number) tries\t\(.duration // 0)s"
' | column -t | head -20

echo ""
echo "=== SLA Misses ==="
airflow_api "dags/~/dagRuns/~/taskInstances?state=sla_miss&limit=10" 2>/dev/null | jq -r '
    .task_instances[]? |
    "\(.dag_id)\t\(.task_id)\t\(.execution_date)"
' | column -t

echo ""
echo "=== Variables (names only) ==="
airflow_api "variables?limit=50" | jq -r '.variables[].key' | head -20

echo ""
echo "=== Connections Summary ==="
airflow_api "connections?limit=50" | jq -r '
    .connections[] |
    "\(.connection_id)\t\(.conn_type)\t\(.host // "n/a")"
' | column -t | head -20
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use date filters to scope DAG runs and task instances
- Never dump full DAG source code or XCom values -- extract key metadata

## Common Pitfalls

- **Scheduler lag**: If scheduler heartbeat is stale, tasks will not be scheduled -- check scheduler process
- **Pool exhaustion**: All pool slots occupied means tasks queue indefinitely -- monitor open_slots
- **Zombie tasks**: Tasks marked running but scheduler lost contact -- check for zombie detection in logs
- **DAG parsing errors**: Import errors prevent DAGs from loading -- check import_errors endpoint
- **XCom size**: Large XCom values degrade database performance -- monitor XCom table size
- **Executor capacity**: Celery/Kubernetes executor has worker limits -- check worker availability
- **Database connections**: Metadata DB connection pool exhaustion causes widespread failures
- **Catchup**: DAGs with catchup=True can spawn hundreds of backfill runs when unpaused
