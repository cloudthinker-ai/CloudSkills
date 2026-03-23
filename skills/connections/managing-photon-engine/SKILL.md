---
name: managing-photon-engine
description: |
  Use when working with Photon Engine — photon Engine real-time multiplayer
  services management including Photon Realtime, PUN, Fusion, Quantum, Chat, and
  Voice. Covers CCU monitoring, room statistics, region health, bandwidth usage,
  and application configuration review.
connection_type: photon-engine
preload: false
---

# Photon Engine Management Skill

Monitor and manage Photon multiplayer networking services.

## MANDATORY: Discovery-First Pattern

**Always discover applications and their types before querying usage metrics.**

### Phase 1: Discovery

```bash
#!/bin/bash
PHOTON_API="https://dashboard.photonengine.com/api"
AUTH="Authorization: Bearer ${PHOTON_API_TOKEN}"

echo "=== Photon Applications ==="
curl -s -H "$AUTH" "$PHOTON_API/applications" | \
  jq -r '.[] | "\(.name) | AppID: \(.appId) | Type: \(.type) | Created: \(.createdAt)"'

echo ""
echo "=== Subscription Info ==="
curl -s -H "$AUTH" "$PHOTON_API/account/subscription" | \
  jq -r '"Plan: \(.planName)\nCCU Limit: \(.ccuLimit)\nTraffic Limit: \(.trafficLimitGB)GB\nExpires: \(.expirationDate)"'

echo ""
echo "=== Available Regions ==="
curl -s -H "$AUTH" "$PHOTON_API/applications/${PHOTON_APP_ID}/regions" | \
  jq -r '.[] | "\(.region) | Status: \(.status) | Ping: \(.avgPingMs)ms"'

echo ""
echo "=== Application Config ==="
curl -s -H "$AUTH" "$PHOTON_API/applications/${PHOTON_APP_ID}/settings" | \
  jq -r '"MaxPlayers/Room: \(.maxPlayersPerRoom)\nCustomAuth: \(.customAuthEnabled)\nWebhooks: \(.webhooksEnabled)"'
```

**Phase 1 outputs:** App list, subscription tier, regions, app config

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Current CCU ==="
curl -s -H "$AUTH" "$PHOTON_API/applications/${PHOTON_APP_ID}/stats/ccu" | \
  jq -r '"Current CCU: \(.current)\nPeak Today: \(.peakToday)\nPeak Month: \(.peakMonth)\nCCU Limit: \(.limit)"'

echo ""
echo "=== CCU by Region ==="
curl -s -H "$AUTH" "$PHOTON_API/applications/${PHOTON_APP_ID}/stats/ccu/regions" | \
  jq -r '.[] | "\(.region): \(.ccu) CCU (\(.rooms) rooms)"'

echo ""
echo "=== Bandwidth Usage (current month) ==="
curl -s -H "$AUTH" "$PHOTON_API/applications/${PHOTON_APP_ID}/stats/traffic" | \
  jq -r '"Used: \(.usedGB)GB / \(.limitGB)GB\nMessages/sec: \(.messagesPerSecond)"'

echo ""
echo "=== Room Statistics ==="
curl -s -H "$AUTH" "$PHOTON_API/applications/${PHOTON_APP_ID}/stats/rooms" | \
  jq -r '"Active Rooms: \(.activeRooms)\nAvg Players/Room: \(.avgPlayersPerRoom)\nEmpty Rooms: \(.emptyRooms)"'
```

## Output Format

```
PHOTON ENGINE STATUS
====================
App: {app_name} ({type})
Plan: {plan} | CCU Limit: {limit}
Current CCU: {ccu} | Peak: {peak}
Active Rooms: {rooms} | Avg Players: {avg}
Bandwidth: {used}GB / {limit}GB
Regions: {count} active
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

- **Photon Realtime vs PUN vs Fusion**: Different SDKs but same backend — AppID determines type
- **CCU = Concurrent Users**: Not total users — plan limits are based on peak CCU
- **Region pinning**: Clients auto-select best region — server-side stats show distribution
- **Traffic spikes**: Photon throttles above plan limits — monitor bandwidth closely
