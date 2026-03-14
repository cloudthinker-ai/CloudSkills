---
name: managing-azure-cdn
description: |
  Azure CDN management covering profiles, endpoints, custom domains, caching rules, origin groups, and performance analytics. Supports Microsoft, Verizon, and Akamai CDN providers within Azure. Use when managing Azure CDN endpoints, analyzing cache performance, configuring delivery rules, or troubleshooting content delivery.
connection_type: azure
preload: false
---

# Azure CDN Skill

Manage Azure CDN profiles, endpoints, caching rules, custom domains, and delivery optimization.

## Core Helper Functions

```bash
#!/bin/bash

# List CDN profiles
az_cdn_profiles() {
    az cdn profile list --output json 2>/dev/null
}

# List endpoints for a profile
az_cdn_endpoints() {
    local rg="$1" profile="$2"
    az cdn endpoint list --resource-group "$rg" --profile-name "$profile" --output json 2>/dev/null
}

# Get endpoint details
az_cdn_endpoint() {
    local rg="$1" profile="$2" endpoint="$3"
    az cdn endpoint show --resource-group "$rg" --profile-name "$profile" --name "$endpoint" --output json 2>/dev/null
}
```

## MANDATORY: Discovery-First Pattern

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== CDN Profiles ==="
az cdn profile list --output json 2>/dev/null | jq -r '
    .[] | "\(.name)\t\(.resourceGroup)\t\(.sku.name)\t\(.provisioningState)"
' | column -t | head -15

echo ""
echo "=== CDN Endpoints ==="
for profile in $(az cdn profile list --query '[].{n:name,rg:resourceGroup}' -o tsv 2>/dev/null); do
    NAME=$(echo "$profile" | cut -f1)
    RG=$(echo "$profile" | cut -f2)
    az cdn endpoint list --resource-group "$RG" --profile-name "$NAME" -o json 2>/dev/null | jq -r --arg p "$NAME" '
        .[] | "\($p)\t\(.name)\t\(.hostName)\t\(.isHttpAllowed)/\(.isHttpsAllowed)\t\(.provisioningState)"
    '
done | column -t | head -20

echo ""
echo "=== Custom Domains ==="
for profile in $(az cdn profile list --query '[].{n:name,rg:resourceGroup}' -o tsv 2>/dev/null); do
    NAME=$(echo "$profile" | cut -f1)
    RG=$(echo "$profile" | cut -f2)
    for ep in $(az cdn endpoint list --resource-group "$RG" --profile-name "$NAME" --query '[].name' -o tsv 2>/dev/null); do
        az cdn custom-domain list --resource-group "$RG" --profile-name "$NAME" --endpoint-name "$ep" -o json 2>/dev/null | jq -r --arg ep "$ep" '
            .[] | "\($ep)\t\(.name)\t\(.hostName)\t\(.customHttpsProvisioningState // "n/a")"
        '
    done
done | column -t | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash
RG="${1:?Resource group required}"
PROFILE="${2:?Profile name required}"
ENDPOINT="${3:?Endpoint name required}"

echo "=== Endpoint Configuration ==="
az cdn endpoint show --resource-group "$RG" --profile-name "$PROFILE" --name "$ENDPOINT" -o json 2>/dev/null | jq '{
    hostName, isHttpAllowed, isHttpsAllowed, isCompressionEnabled,
    contentTypesToCompress: (.contentTypesToCompress | length),
    origins: [.origins[] | {name, hostName, enabled}],
    queryStringCachingBehavior, optimizationType
}'

echo ""
echo "=== Delivery Rules ==="
az cdn endpoint show --resource-group "$RG" --profile-name "$PROFILE" --name "$ENDPOINT" -o json 2>/dev/null | jq '
    .deliveryPolicy.rules[]? | {order, name, conditions: [.conditions[].name], actions: [.actions[].name]}
' | head -25

echo ""
echo "=== Origin Groups ==="
az cdn origin-group list --resource-group "$RG" --profile-name "$PROFILE" --endpoint-name "$ENDPOINT" -o json 2>/dev/null | jq -r '
    .[] | "\(.name)\t\(.healthProbeSettings.probePath // "none")\t\(.healthProbeSettings.probeIntervalInSeconds // 0)s"
' | column -t | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `az` CLI with `--output json` and jq for parsing
- Always specify resource group and profile name for context

## Safety Rules
- **Read-only by default**: Use list/show commands for inspection
- **Never purge endpoints** without explicit user confirmation
- **Custom domain HTTPS** provisioning can take up to 8 hours
- **Delivery rule order matters**: Rules are evaluated in order of priority

## Common Pitfalls
- **SKU determines features**: Standard Microsoft, Verizon, and Akamai have different rule engines
- **Propagation delay**: Changes can take up to 10 minutes to propagate to all POPs
- **Compression**: Must explicitly list content types to compress
- **Query string caching**: Default behavior varies by SKU -- verify before assuming
- **Custom domain validation**: CNAME or TXT record must be in place before adding custom domains
