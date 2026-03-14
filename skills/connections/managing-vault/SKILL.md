---
name: managing-vault
description: |
  HashiCorp Vault secrets management for reading secrets, auditing access policies, checking seal status, managing leases, reviewing audit logs, and inspecting auth methods. Covers KV secrets engine, dynamic credentials, PKI, and Vault Enterprise namespaces. Read this skill before any Vault operations — it enforces discovery-first patterns and strict read-only safety rules.
connection_type: vault
preload: false
---

# HashiCorp Vault Management Skill

Safely read and audit HashiCorp Vault — the secrets management platform.

## MANDATORY: Discovery-First Pattern

**Always discover mount points and enabled engines before accessing any paths. Never guess secret paths.**

### Phase 1: Discovery

```bash
#!/bin/bash

vault_cmd() {
    VAULT_ADDR="${VAULT_ADDR:-https://vault.example.com}" \
    VAULT_TOKEN="$VAULT_TOKEN" \
    vault "$@"
}

vault_api() {
    curl -s -H "X-Vault-Token: $VAULT_TOKEN" \
         "${VAULT_ADDR:-https://vault.example.com}/v1/$1"
}

echo "=== Vault Status ==="
vault_cmd status 2>/dev/null || vault_api "sys/health" | jq '{
    initialized: .initialized,
    sealed: .sealed,
    standby: .standby,
    version: .version,
    cluster: .cluster_name
}'

echo ""
echo "=== Enabled Secret Engines ==="
vault_cmd secrets list -format=json 2>/dev/null | jq -r 'to_entries[] | "\(.key)\t\(.value.type)\t\(.value.description)"' | column -t

echo ""
echo "=== Enabled Auth Methods ==="
vault_cmd auth list -format=json 2>/dev/null | jq -r 'to_entries[] | "\(.key)\t\(.value.type)\t\(.value.description)"' | column -t

echo ""
echo "=== Policies ==="
vault_cmd policy list 2>/dev/null | head -20
```

**Phase 1 outputs:** Available mount paths, engines, auth methods — only reference these in subsequent operations.

## Anti-Hallucination Rules

- **NEVER guess secret paths** — always list (`vault kv list`) before reading
- **NEVER assume engine types** — always check mount list in Phase 1
- **NEVER read credentials for display** — mask sensitive values in output
- **ONLY list and describe** — never delete, update, or create secrets without explicit request

## Safety Rules

- **READ-ONLY by default**: `vault kv get`, `vault kv list`, `vault policy read`, `vault auth list`, `vault secrets list`
- **MASK secret values**: When displaying secrets, use `*** REDACTED ***` for sensitive fields
- **FORBIDDEN without explicit request**: `vault kv put`, `vault kv delete`, `vault secrets disable`, token revocation
- **NEVER print tokens**: If reading token details, mask the token value itself

## Core Helper Functions

```bash
#!/bin/bash

vault_cmd() {
    VAULT_ADDR="${VAULT_ADDR}" VAULT_TOKEN="$VAULT_TOKEN" \
    VAULT_NAMESPACE="${VAULT_NAMESPACE:-}" vault "$@"
}

vault_api() {
    local endpoint="$1"
    local ns_header=""
    [ -n "$VAULT_NAMESPACE" ] && ns_header="-H X-Vault-Namespace: $VAULT_NAMESPACE"
    curl -s $ns_header \
         -H "X-Vault-Token: $VAULT_TOKEN" \
         "${VAULT_ADDR}/v1/${endpoint}"
}

# Safe secret reader — masks values by default
read_secret_safe() {
    local path="$1"
    local show_values="${2:-false}"  # Default: mask values

    local result=$(vault_cmd kv get -format=json "$path" 2>/dev/null)
    if [ -z "$result" ]; then
        echo "ERROR: Could not read $path — path may not exist or insufficient permissions"
        return 1
    fi

    echo "Path: $path"
    echo "Version: $(echo "$result" | jq -r '.data.metadata.version // "N/A"')"
    echo "Created: $(echo "$result" | jq -r '.data.metadata.created_time // "N/A"')"
    echo "Fields:"

    if [ "$show_values" = "true" ]; then
        echo "$result" | jq -r '.data.data | to_entries[] | "  \(.key): \(.value)"'
    else
        echo "$result" | jq -r '.data.data | keys[] | "  \(.): *** REDACTED ***"'
    fi
}
```

## Common Operations

### Vault Health & Status

```bash
#!/bin/bash
echo "=== Vault Cluster Status ==="
vault_cmd status -format=json 2>/dev/null | jq '{
    sealed: .sealed,
    initialized: .initialized,
    ha_enabled: .ha_enabled,
    active_node: (if .standby then "standby" else "active" end),
    version: .version,
    storage_type: .storage_type,
    migration: .migration
}'

echo ""
echo "=== HA Cluster Peers ==="
vault_api "sys/ha-status" | jq -r '.data.peers[]? | "\(.hostname)\t\(.active_node)\t\(.api_address)"' \
    | column -t 2>/dev/null || echo "HA not configured or insufficient permissions"

echo ""
echo "=== Performance Replication Status ==="
vault_api "sys/replication/status" | jq '.data // "Not Enterprise"' 2>/dev/null | head -10
```

### Secret Discovery & Listing

```bash
#!/bin/bash
MOUNT="${1:-secret}"

echo "=== Secret Paths at $MOUNT/ ==="
vault_cmd kv list "$MOUNT/" 2>/dev/null | head -30 || echo "No access or empty"

echo ""
echo "=== Recursive List (depth 2) ==="
vault_cmd kv list "$MOUNT/" 2>/dev/null | while read path; do
    if [[ "$path" == */ ]]; then
        echo "$path"
        vault_cmd kv list "$MOUNT/$path" 2>/dev/null | while read subpath; do
            echo "  $path$subpath"
        done
    else
        echo "$path"
    fi
done | head -50
```

### Secret Metadata (without values)

```bash
#!/bin/bash
SECRET_PATH="${1:?Secret path required}"

echo "=== Secret Metadata (no values shown): $SECRET_PATH ==="
vault_cmd kv metadata get "$SECRET_PATH" -format=json 2>/dev/null | jq '{
    current_version: .data.current_version,
    oldest_version: .data.oldest_version,
    created_time: .data.created_time,
    updated_time: .data.updated_time,
    max_versions: .data.max_versions,
    delete_version_after: .data.delete_version_after,
    field_count: (.data.versions | length),
    versions: (.data.versions | to_entries | map({version: .key, created: .value.created_time, destroyed: .value.destroyed, deleted: .value.deletion_time != "0001-01-01T00:00:00Z"}))
}'
```

### Policy Audit

```bash
#!/bin/bash
echo "=== All Policies ==="
vault_cmd policy list 2>/dev/null

echo ""
echo "=== Root/Admin Policy Review ==="
for policy in root default; do
    echo "--- Policy: $policy ---"
    vault_cmd policy read "$policy" 2>/dev/null | head -20
    echo ""
done

echo "=== Policies with Wide Access ==="
vault_cmd policy list 2>/dev/null | while read policy; do
    content=$(vault_cmd policy read "$policy" 2>/dev/null)
    # Flag policies with path "*" or with "sudo" capability
    if echo "$content" | grep -qE 'path "\*"|capabilities.*sudo'; then
        echo "WARNING: $policy has broad/sudo access"
    fi
done | head -10
```

### Token Analysis

```bash
#!/bin/bash
echo "=== Current Token Info ==="
vault_cmd token lookup -format=json 2>/dev/null | jq '{
    id: "*** REDACTED ***",
    display_name: .data.display_name,
    policies: .data.policies,
    ttl: .data.ttl,
    expire_time: .data.expire_time,
    renewable: .data.renewable,
    type: .data.type,
    path: .data.path
}'

echo ""
echo "=== Token Accessor List (count only) ==="
vault_api "auth/token/accessors" 2>/dev/null | jq '.keys | length | "Total tokens: \(.)"' -r || echo "Insufficient permissions to list accessors"
```

### Auth Method Review

```bash
#!/bin/bash
echo "=== Auth Method Details ==="
vault_cmd auth list -format=json 2>/dev/null | jq -r '
    to_entries[] |
    "\(.key)\t\(.value.type)\t\(.value.accessor)\tTTL:\(.value.config.default_lease_ttl)"
' | column -t

echo ""
echo "=== Kubernetes Auth Config ==="
vault_api "auth/kubernetes/config" 2>/dev/null | jq '.data | {
    kubernetes_host: .kubernetes_host,
    disable_iss_validation: .disable_iss_validation
}' || echo "Kubernetes auth not configured"

echo ""
echo "=== AWS Auth Config ==="
vault_api "auth/aws/config/client" 2>/dev/null | jq '.data | {
    iam_server_id_header_value: .iam_server_id_header_value,
    sts_endpoint: .sts_endpoint
}' || echo "AWS auth not configured"
```

### Lease Management

```bash
#!/bin/bash
echo "=== Active Lease Count by Mount ==="
vault_api "sys/leases/count" 2>/dev/null | jq -r '
    .data |
    "Total leases: \(.lease_count)\n" +
    (.leases | to_entries[] | "\(.key): \(.value)")
' 2>/dev/null || echo "Insufficient permissions"

echo ""
echo "=== Expiring Leases (next 24h) ==="
# List leases that expire soon — identify before they cause auth failures
vault_api "sys/leases/lookup" 2>/dev/null | head -5 || echo "Use 'vault lease lookup <lease_id>' for specific leases"
```

### PKI Certificate Status

```bash
#!/bin/bash
PKI_MOUNT="${1:-pki}"

echo "=== PKI Certificates (${PKI_MOUNT}/) ==="
vault_cmd list "${PKI_MOUNT}/certs" 2>/dev/null | head -20 || echo "No PKI mount at $PKI_MOUNT"

echo ""
echo "=== PKI Roles ==="
vault_cmd list "${PKI_MOUNT}/roles" 2>/dev/null | head -10

echo ""
echo "=== CA Certificate Info ==="
vault_api "${PKI_MOUNT}/ca/pem" 2>/dev/null | openssl x509 -noout -text 2>/dev/null | \
    grep -E 'Issuer:|Subject:|Not Before|Not After|Serial Number' | head -10 || \
    echo "openssl not available — cannot parse CA cert"
```

## Common Pitfalls

- **Token vs AppRole**: Token-based auth is common in dev; production uses AppRole, Kubernetes, or AWS IAM — check auth method in Phase 1
- **Namespace for Vault Enterprise**: Self-hosted Vault Enterprise uses namespaces — set `VAULT_NAMESPACE` or add `-H X-Vault-Namespace: <ns>` header
- **KV v1 vs KV v2**: KV v2 has versioning and uses `data/` prefix internally; CLI `vault kv` handles both but paths differ
- **Seal status**: If Vault is sealed, all reads fail — check `sys/health` first
- **`vault kv list` vs `vault list`**: For KV v2, `vault kv list` is preferred; `vault list` works on raw paths
- **Token TTL**: Vault tokens expire — if getting 403, token may have expired (check `vault token lookup`)
- **Audit logs**: Audit log paths are controlled by operator — don't assume location; use `sys/audit`
- **Dynamic secret leases**: AWS/database credentials have leases and expire — always check lease TTL
- **Never log values**: When writing analysis scripts, always pipe sensitive output through masking
