---
name: azure-logic-apps
description: |
  Azure Logic Apps workflow run analysis, trigger history, connector management, error diagnostics, and workflow definition inspection via Azure CLI.
connection_type: azure
preload: false
---

# Azure Logic Apps Skill

Manage and analyze Azure Logic Apps using `az logic workflow` and `az rest` commands.

## Discovery-First Rule

**ALWAYS discover before acting.** Never assume workflow names, resource groups, or trigger names.

```bash
# Discover Logic Apps
az logic workflow list --output json \
  --query "[].{name:name, rg:resourceGroup, state:state, sku:sku.name, version:version, createdTime:createdTime, changedTime:changedTime}"
```

## Parallel Execution Requirement

**ALL independent operations MUST run in parallel using background jobs (&) and wait.**

```bash
for wf in $(echo "$workflows" | jq -c '.[]'); do
  {
    name=$(echo "$wf" | jq -r '.name')
    rg=$(echo "$wf" | jq -r '.rg')
    az logic workflow show --name "$name" --resource-group "$rg" --output json
  } &
done
wait
```

## Helper Functions

```bash
# Get workflow run history
get_run_history() {
  local name="$1" rg="$2" top="${3:-25}"
  az rest --method GET \
    --url "https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/$rg/providers/Microsoft.Logic/workflows/$name/runs?api-version=2016-06-01&\$top=$top" \
    --output json --query "value[].{name:name, status:properties.status, startTime:properties.startTime, endTime:properties.endTime, trigger:properties.trigger.name, error:properties.error}"
}

# Get trigger history
get_trigger_history() {
  local name="$1" rg="$2" trigger="$3" top="${4:-25}"
  az rest --method GET \
    --url "https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/$rg/providers/Microsoft.Logic/workflows/$name/triggers/$trigger/histories?api-version=2016-06-01&\$top=$top" \
    --output json
}

# Get workflow definition (actions and triggers)
get_workflow_definition() {
  local name="$1" rg="$2"
  az logic workflow show --name "$name" --resource-group "$rg" --output json \
    --query "{triggers:definition.triggers, actions:definition.actions | keys(@), parameters:definition.parameters | keys(@)}"
}

# Get API connections
list_connections() {
  local rg="$1"
  az rest --method GET \
    --url "https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/$rg/providers/Microsoft.Web/connections?api-version=2016-06-01" \
    --output json --query "value[].{name:name, api:properties.api.name, status:properties.statuses[0].status}"
}
```

## Common Operations

### 1. Workflow Health Overview

```bash
workflows=$(az logic workflow list --output json --query "[].{name:name, rg:resourceGroup}")
for wf in $(echo "$workflows" | jq -c '.[]'); do
  {
    name=$(echo "$wf" | jq -r '.name')
    rg=$(echo "$wf" | jq -r '.rg')
    echo "=== $name ==="
    az logic workflow show --name "$name" --resource-group "$rg" --output json \
      --query "{state:state, version:version, sku:sku, accessControl:accessControl}"
    get_run_history "$name" "$rg" 10
  } &
done
wait
```

### 2. Failed Run Analysis

```bash
# Get recent failures
az rest --method GET \
  --url "https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/$RG/providers/Microsoft.Logic/workflows/$WORKFLOW/runs?api-version=2016-06-01&\$filter=status eq 'Failed'&\$top=10" \
  --output json --query "value[].{runId:name, startTime:properties.startTime, error:properties.error}"

# Get actions for a specific failed run
az rest --method GET \
  --url "https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/$RG/providers/Microsoft.Logic/workflows/$WORKFLOW/runs/$RUN_ID/actions?api-version=2016-06-01" \
  --output json --query "value[?properties.status=='Failed'].{action:name, status:properties.status, error:properties.error, startTime:properties.startTime}"
```

### 3. Trigger History and Status

```bash
# List triggers in workflow
triggers=$(az logic workflow show --name "$WORKFLOW" --resource-group "$RG" --output json --query "definition.triggers | keys(@)")

# Get trigger history for each
for trigger in $(echo "$triggers" | jq -r '.[]'); do
  {
    get_trigger_history "$WORKFLOW" "$RG" "$trigger" 10
  } &
done
wait
```

### 4. Connector and Connection Health

```bash
# List all API connections in resource group
list_connections "$RG"

# Check for unhealthy connections
az rest --method GET \
  --url "https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/$RG/providers/Microsoft.Web/connections?api-version=2016-06-01" \
  --output json --query "value[?properties.statuses[0].status!='Connected'].{name:name, api:properties.api.name, status:properties.statuses[0].status, error:properties.statuses[0].error}"
```

### 5. Run Metrics and Performance

```bash
resource_id=$(az logic workflow show --name "$WORKFLOW" --resource-group "$RG" --query "id" -o tsv)
az monitor metrics list --resource "$resource_id" \
  --metric "RunsStarted" "RunsSucceeded" "RunsFailed" "RunLatency" "TriggersFired" "TriggersSucceeded" "TriggersFailed" \
  --interval PT1H --aggregation Total Average --output json
```

## Common Pitfalls

1. **Consumption vs Standard**: Standard Logic Apps use different CLI commands (`az logicapp` instead of `az logic workflow`). Check the SKU first.
2. **Connection authentication expiry**: OAuth-based connections (Office 365, Dynamics) expire and need re-authentication. Check connection status regularly.
3. **Trigger polling costs**: Recurrence triggers on consumption plan incur one action execution per poll, even with no data. Review polling frequency.
4. **Retry policies**: Default retry is 4 times with exponential backoff. Failed runs may have succeeded on retry -- check individual action statuses.
5. **Concurrency limits**: Default concurrency is unlimited for triggers. High-volume triggers can cause throttling on downstream services.
