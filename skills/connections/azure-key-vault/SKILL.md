---
name: azure-key-vault
description: |
  Azure Key Vault secret, key, and certificate management, access policy auditing, rotation status, and security configuration via Azure CLI.
connection_type: azure
preload: false
---

# Azure Key Vault Skill

Manage and analyze Azure Key Vault using `az keyvault` commands.

## Discovery-First Rule

**ALWAYS discover before acting.** Never assume vault names, secret names, key names, or certificate names.

```bash
# Discover Key Vaults
az keyvault list --output json \
  --query "[].{name:name, rg:resourceGroup, location:location, sku:properties.sku.name, enableRbacAuthorization:properties.enableRbacAuthorization, enableSoftDelete:properties.enableSoftDelete, softDeleteRetentionInDays:properties.softDeleteRetentionInDays}"
```

## Parallel Execution Requirement

**ALL independent operations MUST run in parallel using background jobs (&) and wait.**

```bash
for vault in $(echo "$vaults" | jq -c '.[]'); do
  {
    name=$(echo "$vault" | jq -r '.name')
    az keyvault secret list --vault-name "$name" --output json --query "[].{name:name, enabled:attributes.enabled, expires:attributes.expires}"
  } &
done
wait
```

## Helper Functions

```bash
# List secrets (metadata only, NEVER values)
list_secrets() {
  local vault="$1"
  az keyvault secret list --vault-name "$vault" --output json \
    --query "[].{name:id, enabled:attributes.enabled, expires:attributes.expires, created:attributes.created, updated:attributes.updated, contentType:contentType}"
}

# List keys
list_keys() {
  local vault="$1"
  az keyvault key list --vault-name "$vault" --output json \
    --query "[].{name:name, enabled:attributes.enabled, expires:attributes.expires, keyType:kty, keySize:keySize, operations:keyOps}"
}

# List certificates
list_certificates() {
  local vault="$1"
  az keyvault certificate list --vault-name "$vault" --output json \
    --query "[].{name:name, enabled:attributes.enabled, expires:attributes.expires, created:attributes.created}"
}

# Get access policies
get_access_policies() {
  local vault="$1" rg="$2"
  az keyvault show --name "$vault" --resource-group "$rg" --output json \
    --query "properties.accessPolicies[].{tenantId:tenantId, objectId:objectId, permissions:{keys:permissions.keys, secrets:permissions.secrets, certificates:permissions.certificates}}"
}
```

## Common Operations

### 1. Vault Security Overview

```bash
vaults=$(az keyvault list --output json --query "[].{name:name, rg:resourceGroup}")
for v in $(echo "$vaults" | jq -c '.[]'); do
  {
    name=$(echo "$v" | jq -r '.name')
    rg=$(echo "$v" | jq -r '.rg')
    az keyvault show --name "$name" --resource-group "$rg" --output json \
      --query "{name:name, sku:properties.sku.name, rbacEnabled:properties.enableRbacAuthorization, softDelete:properties.enableSoftDelete, purgeProtection:properties.enablePurgeProtection, networkAcls:properties.networkAcls.defaultAction, privateEndpoints:properties.privateEndpointConnections[].{name:name, state:properties.privateLinkServiceConnectionState.status}}"
  } &
done
wait
```

### 2. Secret Rotation Status

```bash
# Check secrets nearing expiry or already expired
secrets=$(az keyvault secret list --vault-name "$VAULT" --output json)
echo "$secrets" | jq '[.[] | {name: .id | split("/") | last, enabled: .attributes.enabled, expires: .attributes.expires, updated: .attributes.updated}] | sort_by(.expires)'

# Find secrets without expiry set (security risk)
echo "$secrets" | jq '[.[] | select(.attributes.expires == null)] | length'
```

### 3. Access Policy Audit

```bash
# RBAC-based vaults
az role assignment list --scope "$VAULT_ID" --output json \
  --query "[].{principal:principalName, role:roleDefinitionName, scope:scope}"

# Policy-based vaults
get_access_policies "$VAULT" "$RG"

# Check for overly permissive policies (all permissions)
az keyvault show --name "$VAULT" --resource-group "$RG" --output json \
  --query "properties.accessPolicies[?contains(permissions.secrets, 'all') || contains(permissions.keys, 'all')].objectId"
```

### 4. Key and Certificate Management

```bash
# Keys with expiry status
list_keys "$VAULT"

# Certificate expiry check
certs=$(list_certificates "$VAULT")
echo "$certs" | jq '[.[] | select(.expires != null and .expires < (now | strftime("%Y-%m-%dT%H:%M:%SZ")))] | {expired: length}'

# Certificate policy details
for cert in $(echo "$certs" | jq -r '.[].name'); do
  {
    az keyvault certificate show --vault-name "$VAULT" --name "$cert" --output json \
      --query "{name:name, issuer:policy.issuerParameters.name, subject:policy.x509CertificateProperties.subject, validityMonths:policy.x509CertificateProperties.validityInMonths, autoRenew:policy.lifetimeActions}"
  } &
done
wait
```

### 5. Diagnostic and Audit Logging

```bash
# Check if diagnostic settings are enabled
vault_id=$(az keyvault show --name "$VAULT" --resource-group "$RG" --query "id" -o tsv)
az monitor diagnostic-settings list --resource "$vault_id" --output json \
  --query "[].{name:name, logs:logs[].{category:category, enabled:enabled}, metrics:metrics[].{category:category, enabled:enabled}}"
```

## Common Pitfalls

1. **NEVER output secret values**: Always use metadata queries. Never run `az keyvault secret show --vault-name X --name Y` and display the `value` field.
2. **RBAC vs access policies**: Vaults use either RBAC or access policies, not both. Check `enableRbacAuthorization` first to know which model applies.
3. **Soft delete recovery**: Soft-deleted vaults and secrets occupy the name for the retention period. Use `az keyvault list-deleted` to find them.
4. **Network restrictions**: Vaults with `networkAcls.defaultAction=Deny` require IP allowlisting or private endpoint access. CLI calls may fail without access.
5. **Certificate auto-renewal**: Auto-renewal only works with integrated CAs (DigiCert, GlobalSign). Self-signed certificates auto-renew by default but external CA certificates do not.
