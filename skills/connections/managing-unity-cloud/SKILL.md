---
name: managing-unity-cloud
description: |
  Use when working with Unity Cloud — unity Cloud services management including
  Unity Gaming Services (UGS), build automation, cloud content delivery,
  multiplayer relay, matchmaking, and player authentication. Covers project
  health monitoring, build pipeline status, player analytics, and service quota
  analysis.
connection_type: unity-cloud
preload: false
---

# Unity Cloud Management Skill

Monitor, analyze, and manage Unity Cloud services and Unity Gaming Services.

## MANDATORY: Discovery-First Pattern

**Always discover project structure and enabled services before querying specific endpoints.**

### Phase 1: Discovery

```bash
#!/bin/bash
UNITY_API="https://services.api.unity.com"
AUTH="Authorization: Basic ${UNITY_API_KEY}"

echo "=== Unity Organization & Projects ==="
curl -s -H "$AUTH" "$UNITY_API/api/orgs" | \
  jq -r '.[] | "\(.name) (ID: \(.id)) | Tier: \(.tier)"'

echo ""
echo "=== Project List ==="
curl -s -H "$AUTH" "$UNITY_API/api/orgs/${UNITY_ORG_ID}/projects" | \
  jq -r '.[] | "\(.name) | ID: \(.id) | Created: \(.created_at)"'

echo ""
echo "=== Enabled Services ==="
curl -s -H "$AUTH" \
  "$UNITY_API/api/orgs/${UNITY_ORG_ID}/projects/${UNITY_PROJECT_ID}/services" | \
  jq -r '.[] | "\(.name): \(.enabled)"'

echo ""
echo "=== Build Targets ==="
curl -s -H "$AUTH" \
  "https://build-api.cloud.unity3d.com/api/v1/orgs/${UNITY_ORG_ID}/projects/${UNITY_PROJECT_ID}/buildtargets" | \
  jq -r '.[] | "\(.name) | Platform: \(.platform) | Enabled: \(.enabled)"'
```

**Phase 1 outputs:** Organization info, project list, enabled services, build targets

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Recent Builds ==="
curl -s -H "$AUTH" \
  "https://build-api.cloud.unity3d.com/api/v1/orgs/${UNITY_ORG_ID}/projects/${UNITY_PROJECT_ID}/buildtargets/_all/builds?per_page=10" | \
  jq -r '.[] | "\(.buildNumber) | \(.buildStatus) | \(.platform) | \(.totalTimeInSeconds)s"'

echo ""
echo "=== Cloud Content Delivery Buckets ==="
curl -s -H "$AUTH" \
  "$UNITY_API/api/ccd/orgs/${UNITY_ORG_ID}/projects/${UNITY_PROJECT_ID}/buckets" | \
  jq -r '.[] | "\(.name) | Entries: \(.entry_count) | Size: \(.content_size)"'

echo ""
echo "=== Multiplayer Relay Allocations ==="
curl -s -H "$AUTH" \
  "$UNITY_API/api/v1/projects/${UNITY_PROJECT_ID}/relay/allocations" | \
  jq -r '."active_allocations" // "No active allocations"'

echo ""
echo "=== Player Authentication Stats ==="
curl -s -H "$AUTH" \
  "$UNITY_API/api/player-identity/v1/projects/${UNITY_PROJECT_ID}/stats" | \
  jq -r '"Total Players: \(.total_players)\nDAU: \(.daily_active_users)\nMAU: \(.monthly_active_users)"'
```

## Output Format

```
UNITY CLOUD STATUS
==================
Organization: {org_name} ({tier})
Project: {project_name}
Services Enabled: {count}
Recent Build Success Rate: {rate}%
Active Relay Sessions: {count}
CCD Buckets: {count} ({total_size})
Player DAU/MAU: {dau}/{mau}
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

- **Build API vs Services API**: Different base URLs — build-api.cloud.unity3d.com vs services.api.unity.com
- **Rate limits**: Unity Cloud API has per-minute rate limits — batch requests carefully
- **Project GUID vs ID**: Some endpoints use GUID, others use short ID — check docs
- **Service enablement**: Services must be enabled in the Unity Dashboard before API access works
