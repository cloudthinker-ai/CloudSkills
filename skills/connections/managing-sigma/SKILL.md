---
name: managing-sigma
description: |
  Use when working with Sigma — sigma Computing management — monitor workbooks,
  datasets, connections, materialization schedules, and user activity. Use when
  reviewing workbook health, inspecting data connections, auditing permissions,
  or checking materialization job status.
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

## Anti-Hallucination Rules

1. **NEVER assume resource names** — always discover via CLI/API in Phase 1 before referencing in Phase 2.
2. **NEVER fabricate metric names or dimensions** — verify against the service documentation or `--help` output.
3. **NEVER mix CLI commands between service versions** — confirm which version/API you are targeting.
4. **ALWAYS use the discovery → verify → analyze chain** — every resource referenced must have been discovered first.
5. **ALWAYS handle empty results gracefully** — an empty response is valid data, not an error to retry.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

