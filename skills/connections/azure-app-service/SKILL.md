---
name: azure-app-service
description: |
  Use when working with Azure App Service — azure App Service web app health
  monitoring, deployment slot management, scaling configuration, and application
  settings analysis via Azure CLI.
connection_type: azure
preload: false
---

# Azure App Service Skill

Manage and analyze Azure App Service web apps using `az webapp` commands.

## Discovery-First Rule

**ALWAYS discover before acting.** Never assume web app names, resource groups, or plan names.

```bash
# Discover web apps
az webapp list --output json \
  --query "[].{name:name, rg:resourceGroup, state:state, defaultHostName:defaultHostName, kind:kind, httpsOnly:httpsOnly}"
```

## Parallel Execution Requirement

**ALL independent operations MUST run in parallel using background jobs (&) and wait.**

```bash
for app in $(echo "$apps" | jq -c '.[]'); do
  {
    name=$(echo "$app" | jq -r '.name')
    rg=$(echo "$app" | jq -r '.rg')
    az webapp show --name "$name" --resource-group "$rg" --output json
  } &
done
wait
```

## Helper Functions

```bash
# Get web app configuration
get_webapp_config() {
  local name="$1" rg="$2"
  az webapp config show --name "$name" --resource-group "$rg" --output json \
    --query "{alwaysOn:alwaysOn, linuxFxVersion:linuxFxVersion, javaVersion:javaVersion, pythonVersion:pythonVersion, nodeVersion:nodeVersion, phpVersion:phpVersion, ftpsState:ftpsState, http20Enabled:http20Enabled, minTlsVersion:minTlsVersion, webSocketsEnabled:webSocketsEnabled}"
}

# Get app service plan details
get_plan_details() {
  local plan_id="$1"
  az appservice plan show --ids "$plan_id" --output json \
    --query "{name:name, sku:sku.name, tier:sku.tier, workers:numberOfWorkers, maxWorkers:maximumElasticWorkerCount, isLinux:reserved, zoneRedundant:zoneRedundant}"
}

# List deployment slots
list_slots() {
  local name="$1" rg="$2"
  az webapp deployment slot list --name "$name" --resource-group "$rg" --output json \
    --query "[].{name:name, state:state, defaultHostName:defaultHostName}"
}

# Get health check status
get_health_metrics() {
  local resource_id="$1"
  az monitor metrics list --resource "$resource_id" \
    --metric "HealthCheckStatus" "Http5xx" "Http4xx" "AverageResponseTime" "Requests" \
    --interval PT5M --aggregation Average Total --output json
}
```

## Common Operations

### 1. Web App Health Overview

```bash
apps=$(az webapp list --output json --query "[].{name:name, rg:resourceGroup}")
for app in $(echo "$apps" | jq -c '.[]'); do
  {
    name=$(echo "$app" | jq -r '.name')
    rg=$(echo "$app" | jq -r '.rg')
    az webapp show --name "$name" --resource-group "$rg" --output json \
      --query "{name:name, state:state, httpsOnly:httpsOnly, clientCertEnabled:clientCertEnabled, availabilityState:availabilityState, hostNames:hostNames, outboundIpAddresses:outboundIpAddresses}"
    get_webapp_config "$name" "$rg"
  } &
done
wait
```

### 2. Deployment Slot Management

```bash
# List slots with traffic percentages
az webapp traffic-routing show --name "$APP" --resource-group "$RG" --output json

# Show slot differences
az webapp deployment slot list --name "$APP" --resource-group "$RG" --output json
for slot in $(az webapp deployment slot list --name "$APP" --resource-group "$RG" --query "[].name" -o tsv); do
  {
    echo "Slot: $slot"
    az webapp config show --name "$APP" --resource-group "$RG" --slot "$slot" --output json
  } &
done
wait
```

### 3. Scaling Configuration

```bash
# Check current plan and scaling
plan_id=$(az webapp show --name "$APP" --resource-group "$RG" --query "appServicePlanId" -o tsv)
az appservice plan show --ids "$plan_id" --output json \
  --query "{name:name, sku:sku, workers:numberOfWorkers, maxWorkers:maximumElasticWorkerCount}"

# Check autoscale settings
az monitor autoscale list --resource-group "$RG" --output json \
  --query "[?targetResourceUri=='$plan_id'].{name:name, enabled:enabled, profiles:profiles[].{name:name, capacity:capacity, rules:rules[].{metric:metricTrigger.metricName, operator:metricTrigger.operator, threshold:metricTrigger.threshold, direction:scaleAction.direction, cooldown:scaleAction.cooldown}}}"
```

### 4. Application Configuration Audit

```bash
# Security-relevant settings
az webapp show --name "$APP" --resource-group "$RG" --output json \
  --query "{httpsOnly:httpsOnly, clientCertEnabled:clientCertEnabled, clientCertMode:clientCertMode}"
get_webapp_config "$APP" "$RG"

# Connection strings (names only, not values)
az webapp config connection-string list --name "$APP" --resource-group "$RG" --output json \
  --query "[].{name:name, type:type}"

# App settings (names only)
az webapp config appsettings list --name "$APP" --resource-group "$RG" --output json \
  --query "[].{name:name, slotSetting:slotSetting}"
```

### 5. Performance Metrics

```bash
resource_id=$(az webapp show --name "$APP" --resource-group "$RG" --query "id" -o tsv)
az monitor metrics list --resource "$resource_id" \
  --metric "CpuPercentage" "MemoryPercentage" "AverageResponseTime" "Http5xx" "Requests" "HealthCheckStatus" \
  --interval PT1H --aggregation Average Total Max --output json
```

## Output Format

Present results as a structured report:
```
Azure App Service Report
════════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

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

## Common Pitfalls

1. **Slot-sticky settings**: App settings and connection strings marked as `slotSetting=true` do not swap. Verify before slot swap.
2. **Always On**: Free and Shared tiers do not support Always On. The app will idle after inactivity, causing cold starts.
3. **Plan sharing**: Multiple apps can share one App Service Plan. Scaling the plan affects all apps on it.
4. **HTTPS enforcement**: `httpsOnly=true` only redirects HTTP to HTTPS at the App Service level. Check Front Door or Application Gateway if using reverse proxy.
5. **Health check path**: If `healthCheckPath` is set, App Service removes unhealthy instances. Ensure the health endpoint is lightweight and reliable.
