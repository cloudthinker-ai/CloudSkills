---
name: managing-sigma
description: |
  Sigma Computing management — monitor workbooks, datasets, connections, materialization schedules, and user activity. Use when reviewing workbook health, inspecting data connections, auditing permissions, or checking materialization job status.
connection_type: sigma
preload: false
---

# Managing Sigma

Manage and monitor Sigma Computing — workbooks, datasets, connections, and materializations.

## Discovery Phase

```bash
#!/bin/bash

SIGMA_API="https://aws-api.sigmacomputing.com/v2"
AUTH="Authorization: Bearer $SIGMA_API_TOKEN"

echo "=== Connections ==="
curl -s -H "$AUTH" "$SIGMA_API/connections" \
  | jq -r '.entries[] | [.connectionId, .name, .type, .lastUsedAt] | @tsv' | column -t | head -10

echo ""
echo "=== Workbooks ==="
curl -s -H "$AUTH" "$SIGMA_API/workbooks?limit=15" \
  | jq -r '.entries[] | [.workbookId, .name, .updatedAt, .ownerId] | @tsv' | column -t

echo ""
echo "=== Datasets ==="
curl -s -H "$AUTH" "$SIGMA_API/datasets?limit=15" \
  | jq -r '.entries[] | [.datasetId, .name, .createdAt] | @tsv' | column -t

echo ""
echo "=== Members ==="
curl -s -H "$AUTH" "$SIGMA_API/members?limit=10" \
  | jq -r '.entries[] | [.memberId, .email, .memberType, .lastLoginAt] | @tsv' | column -t
```

## Analysis Phase

```bash
#!/bin/bash

SIGMA_API="https://aws-api.sigmacomputing.com/v2"
AUTH="Authorization: Bearer $SIGMA_API_TOKEN"

echo "=== Materialization Schedules ==="
curl -s -H "$AUTH" "$SIGMA_API/materializations" \
  | jq -r '.entries[] | [.materializationId, .workbookId, .cronExpression, .enabled, .lastRunAt] | @tsv' | column -t | head -10

echo ""
echo "=== Materialization Run History ==="
curl -s -H "$AUTH" "$SIGMA_API/materializations/runs?limit=10" \
  | jq -r '.entries[] | [.runId, .materializationId, .status, .startedAt, .duration] | @tsv' | column -t

echo ""
echo "=== Failed Materializations ==="
curl -s -H "$AUTH" "$SIGMA_API/materializations/runs?status=failed&limit=10" \
  | jq -r '.entries[] | [.runId, .materializationId, .startedAt, .errorMessage[:60]] | @tsv' | column -t

echo ""
echo "=== Connection Health ==="
for CONN_ID in $(curl -s -H "$AUTH" "$SIGMA_API/connections" | jq -r '.entries[:5][].connectionId'); do
  CONN_NAME=$(curl -s -H "$AUTH" "$SIGMA_API/connections/$CONN_ID" | jq -r '.name')
  STATUS=$(curl -s -H "$AUTH" "$SIGMA_API/connections/$CONN_ID/test" | jq -r '.status // "unknown"')
  echo "$CONN_NAME: $STATUS"
done

echo ""
echo "=== Workbook Shares ==="
curl -s -H "$AUTH" "$SIGMA_API/workbooks/$SIGMA_WORKBOOK_ID/grants" \
  | jq -r '.entries[] | [.granteeId, .granteeType, .permission] | @tsv' | column -t | head -10
```

## Output Format

```
CONNECTIONS
ID       Name             Type       Last Used
<id>     <conn-name>      <type>     <timestamp>

WORKBOOKS
ID       Name             Updated        Owner
<id>     <workbook-name>  <timestamp>    <owner>

MATERIALIZATION STATUS
ID       Workbook     Cron          Enabled  Last Run
<id>     <wb-id>      <cron>        true     <timestamp>

FAILED MATERIALIZATIONS
Run ID   Mat ID       Started         Error
<id>     <mat-id>     <timestamp>     <message>
```
