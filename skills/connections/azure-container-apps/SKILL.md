---
name: azure-container-apps
description: |
  Azure Container Apps revision management, scaling rules, Dapr integration, ingress configuration, and environment health via Azure CLI.
connection_type: azure
preload: false
---

# Azure Container Apps Skill

Manage and analyze Azure Container Apps using `az containerapp` commands.

## Discovery-First Rule

**ALWAYS discover before acting.** Never assume container app names, environments, or revision names.

```bash
# Discover Container App environments
az containerapp env list --output json \
  --query "[].{name:name, rg:resourceGroup, provisioningState:provisioningState, defaultDomain:defaultDomain, zoneRedundant:zoneRedundant}"

# Discover Container Apps
az containerapp list --output json \
  --query "[].{name:name, rg:resourceGroup, envName:managedEnvironmentId, latestRevision:latestRevisionName, trafficWeight:configuration.ingress.traffic}"
```

## Parallel Execution Requirement

**ALL independent operations MUST run in parallel using background jobs (&) and wait.**

```bash
for app in $(echo "$apps" | jq -c '.[]'); do
  {
    name=$(echo "$app" | jq -r '.name')
    rg=$(echo "$app" | jq -r '.rg')
    az containerapp show --name "$name" --resource-group "$rg" --output json
  } &
done
wait
```

## Helper Functions

```bash
# Get app details with scaling config
get_app_details() {
  local name="$1" rg="$2"
  az containerapp show --name "$name" --resource-group "$rg" --output json \
    --query "{name:name, latestRevision:latestRevisionName, ingress:configuration.ingress, scaling:template.scale, containers:template.containers[].{name:name, image:image, cpu:resources.cpu, memory:resources.memory}, dapr:configuration.dapr}"
}

# List revisions
list_revisions() {
  local name="$1" rg="$2"
  az containerapp revision list --name "$name" --resource-group "$rg" --output json \
    --query "[].{name:name, active:properties.active, replicas:properties.replicas, createdTime:properties.createdTime, trafficWeight:properties.trafficWeight, healthState:properties.healthState}"
}

# Get replica status
get_replicas() {
  local name="$1" rg="$2" revision="$3"
  az containerapp replica list --name "$name" --resource-group "$rg" --revision "$revision" --output json
}

# Get environment details
get_env_details() {
  local name="$1" rg="$2"
  az containerapp env show --name "$name" --resource-group "$rg" --output json \
    --query "{name:name, provisioningState:provisioningState, defaultDomain:defaultDomain, staticIp:staticIp, infrastructureSubnetId:infrastructureSubnetId, logAnalyticsWorkspace:appLogsConfiguration.logAnalyticsConfiguration.customerId, zoneRedundant:zoneRedundant}"
}
```

## Common Operations

### 1. Container App Health Overview

```bash
apps=$(az containerapp list --output json --query "[].{name:name, rg:resourceGroup}")
for app in $(echo "$apps" | jq -c '.[]'); do
  {
    name=$(echo "$app" | jq -r '.name')
    rg=$(echo "$app" | jq -r '.rg')
    get_app_details "$name" "$rg"
    list_revisions "$name" "$rg"
  } &
done
wait
```

### 2. Revision Management

```bash
# Active revisions and traffic split
az containerapp ingress traffic show --name "$APP" --resource-group "$RG" --output json

# List all revisions with status
az containerapp revision list --name "$APP" --resource-group "$RG" --output json \
  --query "[].{name:name, active:properties.active, replicas:properties.replicas, createdTime:properties.createdTime, healthState:properties.healthState, provisioningState:properties.provisioningState}"

# Get logs from a specific revision
az containerapp logs show --name "$APP" --resource-group "$RG" --revision "$REVISION" --output json
```

### 3. Scaling Rules Analysis

```bash
# Current scaling configuration
az containerapp show --name "$APP" --resource-group "$RG" --output json \
  --query "{minReplicas:template.scale.minReplicas, maxReplicas:template.scale.maxReplicas, rules:template.scale.rules[].{name:name, httpConcurrency:http.metadata.concurrentRequests, queueLength:azureQueue.metadata.queueLength, customType:custom.type}}"

# Current replica count per revision
for rev in $(az containerapp revision list --name "$APP" --resource-group "$RG" --query "[?properties.active].name" -o tsv); do
  {
    echo "Revision: $rev"
    az containerapp replica list --name "$APP" --resource-group "$RG" --revision "$rev" --output json \
      --query "[].{name:name, createdTime:properties.createdTime, runningState:properties.runningState}"
  } &
done
wait
```

### 4. Dapr Integration

```bash
# Check Dapr configuration
az containerapp show --name "$APP" --resource-group "$RG" --output json \
  --query "{daprEnabled:configuration.dapr.enabled, appId:configuration.dapr.appId, appPort:configuration.dapr.appPort, appProtocol:configuration.dapr.appProtocol, enableApiLogging:configuration.dapr.enableApiLogging}"

# List Dapr components in environment
az containerapp env dapr-component list --name "$ENV" --resource-group "$RG" --output json \
  --query "[].{name:name, type:properties.componentType, version:properties.version, scopes:properties.scopes}"
```

### 5. Ingress and Networking

```bash
az containerapp show --name "$APP" --resource-group "$RG" --output json \
  --query "{ingress:configuration.ingress.{external:external, targetPort:targetPort, transport:transport, corsPolicy:corsPolicy, ipRestrictions:ipSecurityRestrictions, stickySessions:stickySessions}, fqdn:configuration.ingress.fqdn, customDomains:configuration.ingress.customDomains}"
```

## Common Pitfalls

1. **Revision mode**: Single-revision mode automatically deactivates old revisions on deploy. Multi-revision mode keeps them active. Check `configuration.activeRevisionsMode`.
2. **Scale to zero**: Min replicas of 0 means the app can scale to zero with cold start latency. HTTP triggers wake it up but queue/event triggers may not.
3. **Dapr component scopes**: Dapr components without scopes are available to all apps in the environment. Use scopes to restrict access.
4. **CPU/memory limits**: Container Apps have specific CPU/memory combinations (e.g., 0.25 vCPU / 0.5 Gi). Invalid combinations cause deployment failures.
5. **Init containers**: Init containers run before app containers and share the same resource allocation. They can cause startup delays if slow.
