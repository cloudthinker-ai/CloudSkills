---
name: managing-vercel-deep
description: |
  Use when working with Vercel Deep — deep Vercel platform analysis covering
  project inventory, deployment history, serverless and edge function metrics,
  domain configurations, environment variable auditing, build performance,
  bandwidth usage, and integration status. Use for comprehensive Vercel platform
  health checks.
connection_type: vercel
preload: false
---

# Vercel Deep Management

Comprehensive analysis of Vercel projects, deployments, serverless functions, and edge network.

## Phase 1: Discovery

```bash
#!/bin/bash
TOKEN="${VERCEL_TOKEN}"
TEAM="${VERCEL_TEAM_ID}"
BASE="https://api.vercel.com"
AUTH=(-H "Authorization: Bearer ${TOKEN}")
TEAM_Q=$( [ -n "$TEAM" ] && echo "?teamId=${TEAM}" || echo "")

echo "=== Projects Inventory ==="
curl -s "${BASE}/v9/projects${TEAM_Q}" "${AUTH[@]}" \
  | jq -r '.projects[] | "\(.id)\t\(.name)\t\(.framework // "other")\t\(.targets.production.url // "no-deploy")\t\(.updatedAt / 1000 | strftime("%Y-%m-%d"))"' \
  | column -t | head -20

echo ""
echo "=== Project Frameworks ==="
curl -s "${BASE}/v9/projects${TEAM_Q}" "${AUTH[@]}" \
  | jq -r '.projects[].framework // "custom"' | sort | uniq -c | sort -rn

echo ""
echo "=== Custom Domains ==="
for PROJ in $(curl -s "${BASE}/v9/projects${TEAM_Q}" "${AUTH[@]}" | jq -r '.projects[].name'); do
  curl -s "${BASE}/v9/projects/${PROJ}/domains${TEAM_Q}" "${AUTH[@]}" \
    | jq -r ".domains[] | \"${PROJ}\t\(.name)\t\(.verified)\t\(.redirect // \"none\")\"" 2>/dev/null
done | column -t | head -20

echo ""
echo "=== Environment Variables (counts only) ==="
for PROJ in $(curl -s "${BASE}/v9/projects${TEAM_Q}" "${AUTH[@]}" | jq -r '.projects[].name'); do
  COUNT=$(curl -s "${BASE}/v9/projects/${PROJ}/env${TEAM_Q}" "${AUTH[@]}" | jq '.envs | length' 2>/dev/null)
  echo "${PROJ}: ${COUNT:-0} env vars"
done
```

## Phase 2: Analysis

```bash
#!/bin/bash
TOKEN="${VERCEL_TOKEN}"
TEAM="${VERCEL_TEAM_ID}"
BASE="https://api.vercel.com"
AUTH=(-H "Authorization: Bearer ${TOKEN}")
TEAM_Q=$( [ -n "$TEAM" ] && echo "?teamId=${TEAM}" || echo "")
TEAM_AMP=$( [ -n "$TEAM" ] && echo "&teamId=${TEAM}" || echo "")

echo "=== Recent Deployments ==="
curl -s "${BASE}/v6/deployments${TEAM_Q}&limit=20" "${AUTH[@]}" \
  | jq -r '.deployments[] | "\(.name)\t\(.uid[0:8])\t\(.state)\t\(.ready // "pending" | if type == "number" then (. / 1000 | strftime("%Y-%m-%d %H:%M")) else . end)\t\(.target // "preview")"' \
  | column -t | head -20

echo ""
echo "=== Build Performance (last 10 deploys per project) ==="
for PROJ in $(curl -s "${BASE}/v9/projects${TEAM_Q}" "${AUTH[@]}" | jq -r '.projects[].name' | head -5); do
  curl -s "${BASE}/v6/deployments?projectId=${PROJ}&limit=10${TEAM_AMP}" "${AUTH[@]}" \
    | jq "[.deployments[] | select(.buildingAt != null and .ready != null) | (.ready - .buildingAt) / 1000] | if length > 0 then {project: \"${PROJ}\", avg_build_s: (add / length | floor), min_s: min, max_s: max} else empty end" 2>/dev/null
done

echo ""
echo "=== Serverless Function Regions ==="
for PROJ in $(curl -s "${BASE}/v9/projects${TEAM_Q}" "${AUTH[@]}" | jq -r '.projects[].name' | head -5); do
  curl -s "${BASE}/v9/projects/${PROJ}${TEAM_Q}" "${AUTH[@]}" \
    | jq "{name, serverlessFunctionRegion: .serverlessFunctionRegion, nodeVersion: .nodeVersion}" 2>/dev/null
done

echo ""
echo "=== Deploy Failure Rate ==="
DEPLOYS=$(curl -s "${BASE}/v6/deployments${TEAM_Q}&limit=50" "${AUTH[@]}")
TOTAL=$(echo "$DEPLOYS" | jq '.deployments | length')
ERRORS=$(echo "$DEPLOYS" | jq '[.deployments[] | select(.state=="ERROR")] | length')
echo "Last 50 deploys: ${ERRORS} failed ($(echo "scale=1; ${ERRORS}*100/${TOTAL}" | bc)% failure rate)"

echo ""
echo "=== Usage & Bandwidth ==="
curl -s "${BASE}/v2/usage${TEAM_Q}" "${AUTH[@]}" \
  | jq '{bandwidth: .bandwidth, builds: .builds, serverlessFunctionExecutions: .serverlessFunctionExecutions}' 2>/dev/null
```

## Output Format

```
VERCEL DEEP ANALYSIS
======================
Project          Framework  Region  Domains  Env-Vars  Avg-Build  Last Deploy
──────────────────────────────────────────────────────────────────────────────
my-app           nextjs     iad1    2        12        45s        2h ago
docs             astro      iad1    1        4         30s        1d ago
api-service      none       sfo1    1        8         15s        30m ago

Deploy Success: 96% (48/50) | Frameworks: nextjs(3) astro(1) custom(1)
Bandwidth: 45.2 GB used this period
```

## Safety Rules

- **Read-only**: Only use GET endpoints against the Vercel API
- **Never trigger deployments** or modify projects without explicit confirmation
- **Env vars**: Never output environment variable values, only counts
- **Rate limits**: Vercel API limit is 100 requests per 60 seconds

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

