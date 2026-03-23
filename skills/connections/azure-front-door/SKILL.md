---
name: azure-front-door
description: |
  Use when working with Azure Front Door — azure Front Door routing rules, WAF
  policy management, health probe configuration, cache management, and CDN
  analytics via Azure CLI.
connection_type: azure
preload: false
---

# Azure Front Door Skill

Manage and analyze Azure Front Door using `az afd` (Standard/Premium) and `az network front-door` (Classic) commands.

## Discovery-First Rule

**ALWAYS discover before acting.** Never assume profile names, endpoint names, origin group names, or WAF policy names.

```bash
# Discover Front Door Standard/Premium profiles
az afd profile list --output json \
  --query "[].{name:name, rg:resourceGroup, sku:sku.name, provisioningState:provisioningState, enabledState:enabledState}"

# Discover Classic Front Doors
az network front-door list --output json \
  --query "[].{name:name, rg:resourceGroup, enabledState:enabledState, frontendEndpoints:frontendEndpoints[].hostName}"
```

## Parallel Execution Requirement

**ALL independent operations MUST run in parallel using background jobs (&) and wait.**

```bash
for profile in $(echo "$profiles" | jq -c '.[]'); do
  {
    name=$(echo "$profile" | jq -r '.name')
    rg=$(echo "$profile" | jq -r '.rg')
    az afd endpoint list --profile-name "$name" --resource-group "$rg" --output json
  } &
done
wait
```

## Helper Functions

```bash
# List endpoints for a profile
list_endpoints() {
  local profile="$1" rg="$2"
  az afd endpoint list --profile-name "$profile" --resource-group "$rg" --output json \
    --query "[].{name:name, hostName:hostName, enabledState:enabledState, provisioningState:provisioningState}"
}

# List origin groups
list_origin_groups() {
  local profile="$1" rg="$2"
  az afd origin-group list --profile-name "$profile" --resource-group "$rg" --output json \
    --query "[].{name:name, healthProbe:healthProbeSettings, loadBalancing:loadBalancingSettings, sessionAffinity:sessionAffinityState}"
}

# List routes
list_routes() {
  local profile="$1" rg="$2" endpoint="$3"
  az afd route list --profile-name "$profile" --resource-group "$rg" --endpoint-name "$endpoint" --output json \
    --query "[].{name:name, patternsToMatch:patternsToMatch, originGroup:originGroup.id, enabledState:enabledState, forwardingProtocol:forwardingProtocol, httpsRedirect:httpsRedirect, cacheConfiguration:cacheConfiguration}"
}

# Get WAF policy
get_waf_policy() {
  local name="$1" rg="$2"
  az network front-door waf-policy show --name "$name" --resource-group "$rg" --output json \
    --query "{name:name, sku:sku.name, policySettings:policySettings, managedRules:managedRules.managedRuleSets[].{type:ruleSetType, version:ruleSetVersion}, customRules:customRules.rules[].{name:name, priority:priority, action:action, matchConditions:matchConditions}}"
}
```

## Common Operations

### 1. Front Door Overview

```bash
profiles=$(az afd profile list --output json --query "[].{name:name, rg:resourceGroup}")
for p in $(echo "$profiles" | jq -c '.[]'); do
  {
    name=$(echo "$p" | jq -r '.name')
    rg=$(echo "$p" | jq -r '.rg')
    echo "=== Profile: $name ==="
    list_endpoints "$name" "$rg"
    list_origin_groups "$name" "$rg"
  } &
done
wait
```

### 2. Routing Rules Analysis

```bash
endpoints=$(list_endpoints "$PROFILE" "$RG")
for ep in $(echo "$endpoints" | jq -c '.[]'); do
  {
    ep_name=$(echo "$ep" | jq -r '.name')
    list_routes "$PROFILE" "$RG" "$ep_name"
  } &
done
wait
```

### 3. WAF Policy Review

```bash
# List WAF policies
az network front-door waf-policy list --resource-group "$RG" --output json \
  --query "[].{name:name, policyMode:policySettings.mode, enabledState:policySettings.enabledState, redirectUrl:policySettings.redirectUrl}"

# Get detailed rule configuration
get_waf_policy "$WAF_POLICY" "$RG"

# Check managed rule overrides
az network front-door waf-policy show --name "$WAF_POLICY" --resource-group "$RG" --output json \
  --query "managedRules.managedRuleSets[].ruleGroupOverrides[].{group:ruleGroupName, rules:rules[].{id:ruleId, action:action, enabledState:enabledState}}"
```

### 4. Health Probe Configuration

```bash
# Check origin group health probes
az afd origin-group list --profile-name "$PROFILE" --resource-group "$RG" --output json \
  --query "[].{name:name, probePath:healthProbeSettings.probePath, probeProtocol:healthProbeSettings.probeProtocol, probeIntervalSec:healthProbeSettings.probeIntervalInSeconds, probeMethod:healthProbeSettings.probeRequestType}"

# List origins with health status
for og in $(az afd origin-group list --profile-name "$PROFILE" --resource-group "$RG" --query "[].name" -o tsv); do
  {
    az afd origin list --profile-name "$PROFILE" --resource-group "$RG" --origin-group-name "$og" --output json \
      --query "[].{name:name, hostName:hostName, httpPort:httpPort, httpsPort:httpsPort, priority:priority, weight:weight, enabledState:enabledState}"
  } &
done
wait
```

### 5. Cache Configuration

```bash
# Check caching rules per route
endpoints=$(list_endpoints "$PROFILE" "$RG")
for ep in $(echo "$endpoints" | jq -c '.[]'); do
  {
    ep_name=$(echo "$ep" | jq -r '.name')
    az afd route list --profile-name "$PROFILE" --resource-group "$RG" --endpoint-name "$ep_name" --output json \
      --query "[].{route:name, cacheEnabled:cacheConfiguration.isCompressionEnabled, queryStringCaching:cacheConfiguration.queryStringCachingBehavior, cacheDuration:cacheConfiguration.cacheDuration}"
  } &
done
wait
```

## Output Format

Present results as a structured report:
```
Azure Front Door Report
═══════════════════════
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

1. **Classic vs Standard/Premium**: Classic uses `az network front-door`, Standard/Premium uses `az afd`. Commands are not interchangeable.
2. **WAF mode**: Detection mode logs but does not block. Prevention mode blocks. Check `policySettings.mode` before assuming protection is active.
3. **Health probe overhead**: HEAD probes are more efficient than GET. Frequent probes (every 5s) to slow backends can cause load. Check probe interval.
4. **Custom domains**: Custom domains require CNAME validation and certificate binding. Check domain validation state before troubleshooting routing.
5. **Cache purge scope**: Purging by URL pattern affects all edge nodes globally. Wildcard purge (`/*`) clears the entire cache -- use specific paths when possible.
