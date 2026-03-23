---
name: managing-playfab
description: |
  Use when working with Playfab — playFab backend services management including
  player data, title configuration, economy, matchmaking, multiplayer servers,
  and LiveOps. Covers player analytics, server fleet health, economy balance
  monitoring, and event pipeline status.
connection_type: playfab
preload: false
---

# PlayFab Management Skill

Monitor and manage PlayFab game backend services and multiplayer infrastructure.

## MANDATORY: Discovery-First Pattern

**Always discover title info and enabled features before querying player or economy data.**

### Phase 1: Discovery

```bash
#!/bin/bash
PF_API="https://${PLAYFAB_TITLE_ID}.playfabapi.com"
PF_ADMIN="X-SecretKey: ${PLAYFAB_SECRET_KEY}"

echo "=== Title Info ==="
curl -s -X POST "$PF_API/Admin/GetTitleInternalData" \
  -H "$PF_ADMIN" -H "Content-Type: application/json" \
  -d '{"Keys": null}' | jq -r '.data.Data // "No internal data"'

echo ""
echo "=== Player Count Stats ==="
curl -s -X POST "$PF_API/Admin/GetPlayerStatisticDefinitions" \
  -H "$PF_ADMIN" -H "Content-Type: application/json" \
  -d '{}' | jq -r '.data.Statistics[] | "\(.StatisticName) | Version: \(.CurrentVersion)"'

echo ""
echo "=== Catalog Items ==="
curl -s -X POST "$PF_API/Admin/GetCatalogItems" \
  -H "$PF_ADMIN" -H "Content-Type: application/json" \
  -d '{"CatalogVersion": "main"}' | \
  jq -r '.data.Catalog | length | "Total catalog items: \(.)"'

echo ""
echo "=== Multiplayer Server Builds ==="
curl -s -X POST "$PF_API/MultiplayerServer/ListBuildSummariesV2" \
  -H "$PF_ADMIN" -H "Content-Type: application/json" \
  -d '{}' | jq -r '.data.BuildSummaries[] | "\(.BuildName) | Status: \(.BuildStatus) | Regions: \(.RegionConfigurations | length)"'
```

**Phase 1 outputs:** Title config, statistics, catalog size, server builds

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Player Segment Counts ==="
curl -s -X POST "$PF_API/Admin/GetPlayerSegments" \
  -H "$PF_ADMIN" -H "Content-Type: application/json" \
  -d '{}' | jq -r '.data.Segments[] | "\(.Name): \(.PlayerCount // "N/A") players"'

echo ""
echo "=== Multiplayer Server Quotas ==="
curl -s -X POST "$PF_API/MultiplayerServer/GetTitleMultiplayerServersQuotas" \
  -H "$PF_ADMIN" -H "Content-Type: application/json" \
  -d '{}' | jq -r '.data.Quotas.CoreCapacities[] | "\(.Region) | VM: \(.VmFamily) | Used: \(.UsedCoreCount)/\(.TotalCoreCount)"'

echo ""
echo "=== Recent Title Events ==="
curl -s -X POST "$PF_API/Admin/GetTitleData" \
  -H "$PF_ADMIN" -H "Content-Type: application/json" \
  -d '{"Keys": null}' | jq -r '.data.Data | to_entries[:10] | .[] | "\(.key): \(.value[:60])"'

echo ""
echo "=== Economy Virtual Currency ==="
curl -s -X POST "$PF_API/Admin/GetStoreItems" \
  -H "$PF_ADMIN" -H "Content-Type: application/json" \
  -d '{"StoreId": "default", "CatalogVersion": "main"}' | \
  jq -r '.data.Store[:10] | .[] | "\(.ItemId) | Price: \(.VirtualCurrencyPrices)"'
```

## Output Format

```
PLAYFAB STATUS
==============
Title ID: {title_id}
Catalog Items: {count}
Statistics Defined: {count}
Player Segments: {count}
Server Builds: {count} (Active: {active})
Core Utilization: {used}/{total} across {regions} regions
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

- **Admin vs Server vs Client API**: Use Admin API for management — never expose secret keys
- **Rate limits**: 1000 API calls per minute per title — batch where possible
- **Entity model**: New API uses entities — legacy uses player IDs — do not mix
- **Multiplayer Server regions**: Quotas are per-region — check each region separately
