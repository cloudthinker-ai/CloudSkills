---
name: managing-unreal-cloud
description: |
  Use when working with Unreal Cloud — unreal Engine cloud services management
  including Epic Online Services (EOS), matchmaking, lobbies, player data
  storage, analytics, and anti-cheat. Covers deployment health, player session
  metrics, title storage, and service configuration review.
connection_type: unreal-cloud
preload: false
---

# Unreal Cloud Management Skill

Monitor and manage Epic Online Services (EOS) and Unreal Engine cloud deployments.

## MANDATORY: Discovery-First Pattern

**Always discover deployments and enabled features before querying metrics.**

### Phase 1: Discovery

```bash
#!/bin/bash
EOS_API="https://api.epicgames.dev"
AUTH="Authorization: Bearer ${EOS_ACCESS_TOKEN}"

echo "=== Organization Info ==="
curl -s -H "$AUTH" "$EOS_API/v1/organizations/${EOS_ORG_ID}" | \
  jq -r '"Org: \(.name) | ID: \(.id)"'

echo ""
echo "=== Products ==="
curl -s -H "$AUTH" "$EOS_API/v1/organizations/${EOS_ORG_ID}/products" | \
  jq -r '.[] | "\(.name) | ID: \(.id) | Sandbox: \(.sandboxId)"'

echo ""
echo "=== Deployments ==="
curl -s -H "$AUTH" \
  "$EOS_API/v1/organizations/${EOS_ORG_ID}/products/${EOS_PRODUCT_ID}/deployments" | \
  jq -r '.[] | "\(.name) | ID: \(.id) | Status: \(.status)"'

echo ""
echo "=== Enabled Features ==="
curl -s -H "$AUTH" \
  "$EOS_API/v1/products/${EOS_PRODUCT_ID}/features" | \
  jq -r '.[] | "\(.feature): \(.enabled)"'
```

**Phase 1 outputs:** Organization, products, deployments, enabled features

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Active Sessions ==="
curl -s -H "$AUTH" \
  "$EOS_API/v1/deployments/${EOS_DEPLOYMENT_ID}/sessions?status=active" | \
  jq -r '"Active Sessions: \(.total)\nPeak Today: \(.peak_today)"'

echo ""
echo "=== Matchmaking Queue Status ==="
curl -s -H "$AUTH" \
  "$EOS_API/v1/deployments/${EOS_DEPLOYMENT_ID}/matchmaking/stats" | \
  jq -r '.queues[] | "\(.name) | Waiting: \(.playersWaiting) | Avg Wait: \(.avgWaitSeconds)s"'

echo ""
echo "=== Anti-Cheat Reports (24h) ==="
curl -s -H "$AUTH" \
  "$EOS_API/v1/deployments/${EOS_DEPLOYMENT_ID}/anticheat/reports?hours=24" | \
  jq -r '"Violations: \(.total_violations)\nBanned: \(.banned_count)"'

echo ""
echo "=== Title Storage Usage ==="
curl -s -H "$AUTH" \
  "$EOS_API/v1/deployments/${EOS_DEPLOYMENT_ID}/titlestorage/stats" | \
  jq -r '"Files: \(.file_count) | Size: \(.total_size_mb)MB"'
```

## Output Format

```
UNREAL CLOUD (EOS) STATUS
=========================
Product: {product_name}
Deployment: {deployment_name} ({status})
Active Sessions: {count}
Matchmaking Queues: {count} (avg wait: {time}s)
Anti-Cheat Violations (24h): {count}
Title Storage: {size}MB across {files} files
Issues: {list_of_warnings}
```

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

- **Sandbox vs Deployment**: Sandboxes contain deployments — query the right level
- **OAuth token scopes**: EOS uses client credentials — ensure correct policy attached
- **Rate limits**: 100 requests/minute per deployment — use bulk endpoints where available
- **Session vs Lobby**: Sessions are server-managed; lobbies are peer-managed — different APIs
