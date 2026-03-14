---
name: azure-blob-storage
description: |
  Azure Blob Storage container analysis, access tier management, lifecycle policies, replication configuration, and storage account health via Azure CLI.
connection_type: azure
preload: false
---

# Azure Blob Storage Skill

Manage and analyze Azure Blob Storage using `az storage` commands.

## Discovery-First Rule

**ALWAYS discover before acting.** Never assume storage account names, container names, or access tiers.

```bash
# Discover storage accounts
az storage account list --output json \
  --query "[].{name:name, rg:resourceGroup, kind:kind, sku:sku.name, accessTier:accessTier, httpsOnly:enableHttpsTrafficOnly, location:location}"
```

## Parallel Execution Requirement

**ALL independent operations MUST run in parallel using background jobs (&) and wait.**

```bash
for acct in $(echo "$accounts" | jq -c '.[]'); do
  {
    name=$(echo "$acct" | jq -r '.name')
    rg=$(echo "$acct" | jq -r '.rg')
    az storage account show --name "$name" --resource-group "$rg" --output json
  } &
done
wait
```

## Helper Functions

```bash
# Get account key for operations (use --auth-mode login when possible)
get_connection_string() {
  local name="$1" rg="$2"
  az storage account show-connection-string --name "$name" --resource-group "$rg" --output tsv
}

# List containers in account
list_containers() {
  local name="$1"
  az storage container list --account-name "$name" --auth-mode login --output json \
    --query "[].{name:name, publicAccess:properties.publicAccess, leaseState:properties.leaseState, lastModified:properties.lastModified}"
}

# Get blob count and size summary
get_blob_stats() {
  local name="$1" container="$2"
  az storage blob list --account-name "$name" --container-name "$container" --auth-mode login \
    --output json --query "[].{name:name, tier:properties.blobTier, size:properties.contentLength, lastModified:properties.lastModified}" \
    --num-results 100
}

# Check lifecycle management policy
get_lifecycle_policy() {
  local name="$1" rg="$2"
  az storage account management-policy show --account-name "$name" --resource-group "$rg" --output json 2>/dev/null || echo '{"rules": []}'
}
```

## Common Operations

### 1. Storage Account Overview

```bash
accounts=$(az storage account list --output json --query "[].{name:name, rg:resourceGroup}")
for acct in $(echo "$accounts" | jq -c '.[]'); do
  {
    name=$(echo "$acct" | jq -r '.name')
    rg=$(echo "$acct" | jq -r '.rg')
    az storage account show --name "$name" --resource-group "$rg" --output json \
      --query "{name:name, sku:sku.name, kind:kind, accessTier:accessTier, httpsOnly:enableHttpsTrafficOnly, minTlsVersion:minimumTlsVersion, allowBlobPublicAccess:allowBlobPublicAccess, networkRules:networkRuleSet.defaultAction}"
  } &
done
wait
```

### 2. Container Analysis

```bash
# List containers with access levels
az storage container list --account-name "$ACCT" --auth-mode login --output json \
  --query "[].{name:name, publicAccess:properties.publicAccess, leaseState:properties.leaseState, hasImmutability:properties.hasImmutabilityPolicy, hasLegalHold:properties.hasLegalHold}"
```

### 3. Access Tier Optimization

```bash
# Check blob tier distribution
az storage blob list --account-name "$ACCT" --container-name "$CONTAINER" --auth-mode login \
  --output json --query "[].properties.blobTier" | jq 'group_by(.) | map({tier: .[0], count: length})'

# Check storage capacity metrics
resource_id=$(az storage account show --name "$ACCT" --resource-group "$RG" --query "id" -o tsv)
az monitor metrics list --resource "${resource_id}/blobServices/default" \
  --metric "BlobCapacity" "BlobCount" --interval PT1H --aggregation Average \
  --dimension "BlobType" "Tier" --output json
```

### 4. Lifecycle Management

```bash
# Show lifecycle rules
az storage account management-policy show --account-name "$ACCT" --resource-group "$RG" --output json \
  --query "policy.rules[].{name:name, enabled:enabled, type:type, blobTypes:definition.filters.blobTypes, tierToCool:definition.actions.baseBlob.tierToCool.daysAfterModificationGreaterThan, tierToArchive:definition.actions.baseBlob.tierToArchive.daysAfterModificationGreaterThan, delete:definition.actions.baseBlob.delete.daysAfterModificationGreaterThan}"
```

### 5. Replication and Redundancy

```bash
az storage account show --name "$ACCT" --resource-group "$RG" --output json \
  --query "{sku:sku.name, kind:kind, geoReplicationStats:geoReplicationStats, secondaryLocation:secondaryLocation, secondaryEndpoints:secondaryEndpoints, blobRestoreStatus:blobRestoreStatus}"

# Check blob versioning and soft delete
az storage account blob-service-properties show --account-name "$ACCT" --resource-group "$RG" --output json \
  --query "{deleteRetention:deleteRetentionPolicy, containerDeleteRetention:containerDeleteRetentionPolicy, isVersioningEnabled:isVersioningEnabled, changeFeed:changeFeed}"
```

## Common Pitfalls

1. **Auth mode**: Prefer `--auth-mode login` over account keys. Key-based access may be disabled by policy.
2. **Public access**: `allowBlobPublicAccess` at account level overrides container settings. Check both layers.
3. **Tier transition costs**: Moving blobs from Archive to Hot incurs rehydration costs and takes hours. Check blob count before bulk operations.
4. **Lifecycle policy scope**: Rules apply to entire containers or prefix filters. Verify filter scope to avoid unintended deletions.
5. **GRS read access**: RA-GRS and RA-GZRS provide read access to secondary region but with potential staleness. Check `geoReplicationStats.lastSyncTime`.
