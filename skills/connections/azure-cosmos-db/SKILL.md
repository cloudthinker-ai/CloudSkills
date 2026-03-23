---
name: azure-cosmos-db
description: |
  Use when working with Azure Cosmos Db — azure Cosmos DB throughput analysis,
  partition key distribution, consistency levels, metrics monitoring, and
  database management via Azure CLI.
connection_type: azure
preload: false
---

# Cosmos DB Skill

Manage and analyze Azure Cosmos DB accounts using `az cosmosdb` commands.

## Discovery-First Rule

**ALWAYS discover before acting.** Never assume account names, database names, container names, or throughput values.

```bash
# Discover Cosmos DB accounts
az cosmosdb list --output json \
  --query "[].{name:name, rg:resourceGroup, kind:kind, apiKind:databaseAccountOfferType, locations:locations[].locationName, consistencyPolicy:consistencyPolicy.defaultConsistencyLevel}"
```

## Parallel Execution Requirement

**ALL independent operations MUST run in parallel using background jobs (&) and wait.**

```bash
for acct in $(echo "$accounts" | jq -c '.[]'); do
  {
    name=$(echo "$acct" | jq -r '.name')
    rg=$(echo "$acct" | jq -r '.rg')
    az cosmosdb sql database list --account-name "$name" --resource-group "$rg" --output json
  } &
done
wait
```

## Helper Functions

```bash
# List SQL databases in an account
list_databases() {
  local acct="$1" rg="$2"
  az cosmosdb sql database list --account-name "$acct" --resource-group "$rg" --output json \
    --query "[].{name:name, throughput:options.throughput, autoscaleMax:options.autoscaleMaxThroughput}"
}

# List containers in a database
list_containers() {
  local acct="$1" rg="$2" db="$3"
  az cosmosdb sql container list --account-name "$acct" --resource-group "$rg" --database-name "$db" --output json \
    --query "[].{name:name, partitionKey:resource.partitionKey.paths[0], indexingMode:resource.indexingPolicy.indexingMode, ttl:resource.defaultTtl}"
}

# Get container throughput
get_throughput() {
  local acct="$1" rg="$2" db="$3" container="$4"
  az cosmosdb sql container throughput show --account-name "$acct" --resource-group "$rg" \
    --database-name "$db" --name "$container" --output json \
    --query "{throughput:resource.throughput, autoscaleMax:resource.autoscaleMaximumThroughput, minimumThroughput:resource.minimumThroughput}"
}

# Get Cosmos DB metrics
get_cosmos_metrics() {
  local resource_id="$1" metric="$2"
  az monitor metrics list --resource "$resource_id" --metric "$metric" \
    --interval PT1H --aggregation Average Total --output json
}
```

## Common Operations

### 1. Account and Database Overview

```bash
accounts=$(az cosmosdb list --output json --query "[].{name:name, rg:resourceGroup}")
for acct in $(echo "$accounts" | jq -c '.[]'); do
  {
    name=$(echo "$acct" | jq -r '.name')
    rg=$(echo "$acct" | jq -r '.rg')
    echo "=== Account: $name ==="
    az cosmosdb show --name "$name" --resource-group "$rg" --output json \
      --query "{consistency:consistencyPolicy.defaultConsistencyLevel, multiWrite:enableMultipleWriteLocations, locations:locations[].{loc:locationName, failoverPriority:failoverPriority}, backupPolicy:backupPolicy.type}"
    list_databases "$name" "$rg"
  } &
done
wait
```

### 2. Throughput Analysis

```bash
# Check RU consumption vs provisioned throughput
resource_id=$(az cosmosdb show --name "$ACCT" --resource-group "$RG" --query "id" -o tsv)
az monitor metrics list --resource "$resource_id" \
  --metric "TotalRequestUnits" "NormalizedRUConsumption" "ProvisionedThroughput" \
  --interval PT1H --aggregation Average Total Max --output json

# Check for 429 (throttled) requests
az monitor metrics list --resource "$resource_id" \
  --metric "TotalRequests" --interval PT1H --aggregation Count \
  --filter "StatusCode eq '429'" --output json
```

### 3. Partition Key Distribution

```bash
# Check partition key ranges and usage
az cosmosdb sql container show --account-name "$ACCT" --resource-group "$RG" \
  --database-name "$DB" --name "$CONTAINER" --output json \
  --query "{partitionKey:resource.partitionKey, conflictResolution:resource.conflictResolutionPolicy}"

# Get partition-level metrics (hot partitions)
az monitor metrics list --resource "$resource_id" \
  --metric "NormalizedRUConsumption" --interval PT5M --aggregation Max \
  --dimension "PartitionKeyRangeId" --output json
```

### 4. Consistency Level Review

```bash
# Check account-level consistency
az cosmosdb show --name "$ACCT" --resource-group "$RG" --output json \
  --query "{defaultConsistency:consistencyPolicy.defaultConsistencyLevel, maxStaleness:consistencyPolicy.maxStalenessPrefix, maxInterval:consistencyPolicy.maxIntervalInSeconds}"
```

### 5. Backup and Replication Status

```bash
az cosmosdb show --name "$ACCT" --resource-group "$RG" --output json \
  --query "{backupPolicy:backupPolicy, locations:locations[].{name:locationName, priority:failoverPriority, isZoneRedundant:isZoneRedundant}, enableAutomaticFailover:enableAutomaticFailover}"
```

## Output Format

Present results as a structured report:
```
Azure Cosmos Db Report
══════════════════════
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

1. **Database vs container throughput**: Throughput can be provisioned at database level (shared) or container level (dedicated). Check both.
2. **Autoscale misread**: `autoscaleMaximumThroughput` is the max -- actual consumption may be much lower. Always check `NormalizedRUConsumption` metric.
3. **Partition hot spots**: High `NormalizedRUConsumption` on a single partition range indicates a hot partition. Check partition key design.
4. **Consistency tradeoffs**: Strong consistency doubles RU cost for reads in multi-region setups. Session is the default and usually sufficient.
5. **Serverless vs provisioned**: Serverless accounts do not have throughput settings. Check `capacityMode` in account properties.
