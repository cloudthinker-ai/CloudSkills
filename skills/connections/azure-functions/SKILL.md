---
name: azure-functions
description: |
  Azure Functions app analysis, execution metrics, consumption plan monitoring, scaling configuration, and deployment management via Azure CLI.
connection_type: azure
preload: false
---

# Azure Functions Skill

Manage and analyze Azure Functions apps using `az functionapp` and `az monitor` commands.

## Discovery-First Rule

**ALWAYS discover before acting.** Never assume function app names, resource groups, or plan types.

```bash
# Discover all function apps
az functionapp list --output json \
  --query "[].{name:name, rg:resourceGroup, state:state, runtime:siteConfig.linuxFxVersion, kind:kind, plan:appServicePlanId}"
```

## Parallel Execution Requirement

**ALL independent operations MUST run in parallel using background jobs (&) and wait.**

```bash
for app_info in $(echo "$apps" | jq -c '.[]'); do
  {
    name=$(echo "$app_info" | jq -r '.name')
    rg=$(echo "$app_info" | jq -r '.rg')
    az functionapp show --name "$name" --resource-group "$rg" --output json
  } &
done
wait
```

## Helper Functions

```bash
# Get function app configuration
get_function_config() {
  local name="$1" rg="$2"
  az functionapp config show --name "$name" --resource-group "$rg" --output json
}

# List functions within an app
list_functions() {
  local name="$1" rg="$2"
  az functionapp function list --name "$name" --resource-group "$rg" --output json \
    --query "[].{name:name, trigger:config.bindings[?direction=='in'] | [0].type, isDisabled:isDisabled}"
}

# Get app settings (masks values)
get_app_settings() {
  local name="$1" rg="$2"
  az functionapp config appsettings list --name "$name" --resource-group "$rg" --output json \
    --query "[].{name:name, slotSetting:slotSetting}"
}

# Get execution metrics
get_execution_metrics() {
  local name="$1" rg="$2" timespan="${3:-PT1H}"
  az monitor metrics list --resource "$name" --resource-group "$rg" \
    --resource-type "Microsoft.Web/sites" --metric "FunctionExecutionCount,FunctionExecutionUnits" \
    --interval PT5M --start-time "$(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)" \
    --output json
}
```

## Common Operations

### 1. Function App Health Overview

```bash
apps=$(az functionapp list --output json --query "[].{name:name, rg:resourceGroup}")
for app in $(echo "$apps" | jq -c '.[]'); do
  {
    name=$(echo "$app" | jq -r '.name')
    rg=$(echo "$app" | jq -r '.rg')
    az functionapp show --name "$name" --resource-group "$rg" --output json \
      --query "{name:name, state:state, defaultHostName:defaultHostName, runtime:siteConfig.linuxFxVersion, httpsOnly:httpsOnly, ftpsState:siteConfig.ftpsState}"
    list_functions "$name" "$rg"
  } &
done
wait
```

### 2. Execution Metrics and Performance

```bash
# Get function execution counts and durations
resource_id=$(az functionapp show --name "$APP" --resource-group "$RG" --query "id" -o tsv)
az monitor metrics list --resource "$resource_id" \
  --metric "FunctionExecutionCount" "FunctionExecutionUnits" "Http5xx" "Http4xx" "AverageResponseTime" \
  --interval PT1H --aggregation Total Average --output json
```

### 3. Consumption Plan Analysis

```bash
# Check hosting plan type and limits
plan_id=$(az functionapp show --name "$APP" --resource-group "$RG" --query "appServicePlanId" -o tsv)
az appservice plan show --ids "$plan_id" --output json \
  --query "{name:name, sku:sku, workers:numberOfWorkers, maxWorkers:maximumElasticWorkerCount, kind:kind}"
```

### 4. Scaling Configuration

```bash
# Check scale limits for Premium/Dedicated
az functionapp show --name "$APP" --resource-group "$RG" --output json \
  --query "{siteConfig:{preWarmedInstanceCount:siteConfig.preWarmedInstanceCount, functionAppScaleLimit:siteConfig.functionAppScaleLimit, minimumElasticInstanceCount:siteConfig.minimumElasticInstanceCount}}"

# For consumption plan, check daily usage quota
az functionapp show --name "$APP" --resource-group "$RG" --output json \
  --query "{dailyMemoryTimeQuota:dailyMemoryTimeQuota, usageState:usageState}"
```

### 5. Deployment and Slot Management

```bash
# List deployment slots
az functionapp deployment slot list --name "$APP" --resource-group "$RG" --output json \
  --query "[].{name:name, state:state}"

# Check deployment source
az functionapp deployment source show --name "$APP" --resource-group "$RG" --output json
```

## Common Pitfalls

1. **Consumption vs Premium metrics**: Consumption plan does not expose instance count metrics. Use `FunctionExecutionCount` instead.
2. **Cold starts**: Premium plan `preWarmedInstanceCount` reduces cold starts but incurs always-on cost. Check if it is actually needed.
3. **Runtime version mismatch**: Functions runtime version and language runtime version are separate. Check both `FUNCTIONS_EXTENSION_VERSION` and language-specific settings.
4. **Durable Functions**: Orchestrator and activity functions share the same app but have different scaling behaviors. Check Task Hub configuration.
5. **CORS and auth**: Function-level auth keys are separate from app-level settings. Use `az functionapp keys list` to audit key exposure.
