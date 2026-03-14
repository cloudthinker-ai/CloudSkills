---
name: managing-unreal-cloud
description: |
  Unreal Engine cloud services management including Epic Online Services (EOS), matchmaking, lobbies, player data storage, analytics, and anti-cheat. Covers deployment health, player session metrics, title storage, and service configuration review.
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

## Common Pitfalls

- **Sandbox vs Deployment**: Sandboxes contain deployments — query the right level
- **OAuth token scopes**: EOS uses client credentials — ensure correct policy attached
- **Rate limits**: 100 requests/minute per deployment — use bulk endpoints where available
- **Session vs Lobby**: Sessions are server-managed; lobbies are peer-managed — different APIs
