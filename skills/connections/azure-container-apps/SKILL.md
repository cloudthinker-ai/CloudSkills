---
name: azure-container-apps
description: |
  Use when working with Azure Container Apps — azure Container Apps revision
  management, scaling rules, Dapr integration, ingress configuration, and
  environment health via Azure CLI.
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

## Output Format

Present results as a structured report:
```
Azure Container Apps Report
═══════════════════════════
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

1. **Revision mode**: Single-revision mode automatically deactivates old revisions on deploy. Multi-revision mode keeps them active. Check `configuration.activeRevisionsMode`.
2. **Scale to zero**: Min replicas of 0 means the app can scale to zero with cold start latency. HTTP triggers wake it up but queue/event triggers may not.
3. **Dapr component scopes**: Dapr components without scopes are available to all apps in the environment. Use scopes to restrict access.
4. **CPU/memory limits**: Container Apps have specific CPU/memory combinations (e.g., 0.25 vCPU / 0.5 Gi). Invalid combinations cause deployment failures.
5. **Init containers**: Init containers run before app containers and share the same resource allocation. They can cause startup delays if slow.
