---
name: managing-heroku
description: |
  Heroku platform management covering app inventory, dyno formation and scaling, add-on usage, release history, config var auditing, domain and SSL status, log drain configuration, and metrics analysis. Use for comprehensive Heroku app health and cost assessment.
connection_type: heroku
preload: false
---

# Heroku Management

Analyze Heroku apps, dynos, add-ons, and platform health.

## Phase 1: Discovery

```bash
#!/bin/bash
TOKEN="${HEROKU_API_KEY}"
BASE="https://api.heroku.com"
AUTH=(-H "Authorization: Bearer ${TOKEN}" -H "Accept: application/vnd.heroku+json; version=3")

echo "=== Apps Inventory ==="
curl -s "${BASE}/apps" "${AUTH[@]}" \
  | jq -r '.[] | "\(.name)\t\(.region.name)\t\(.stack.name)\t\(.web_url)\t\(.updated_at)"' \
  | column -t | head -20

echo ""
echo "=== Dyno Formation ==="
for APP in $(curl -s "${BASE}/apps" "${AUTH[@]}" | jq -r '.[].name'); do
  curl -s "${BASE}/apps/${APP}/formation" "${AUTH[@]}" \
    | jq -r ".[] | \"${APP}\t\(.type)\t\(.size)\t\(.quantity)\t\(.command[0:60])\"" 2>/dev/null
done | column -t | head -20

echo ""
echo "=== Add-ons ==="
for APP in $(curl -s "${BASE}/apps" "${AUTH[@]}" | jq -r '.[].name'); do
  curl -s "${BASE}/apps/${APP}/addons" "${AUTH[@]}" \
    | jq -r ".[] | \"${APP}\t\(.plan.name)\t\(.state)\t\(.billing_entity.name // \"N/A\")\"" 2>/dev/null
done | column -t | head -20

echo ""
echo "=== Custom Domains ==="
for APP in $(curl -s "${BASE}/apps" "${AUTH[@]}" | jq -r '.[].name'); do
  curl -s "${BASE}/apps/${APP}/domains" "${AUTH[@]}" \
    | jq -r ".[] | \"${APP}\t\(.hostname)\t\(.kind)\t\(.acm_status // \"N/A\")\"" 2>/dev/null
done | column -t | head -20
```

## Phase 2: Analysis

```bash
#!/bin/bash
TOKEN="${HEROKU_API_KEY}"
BASE="https://api.heroku.com"
AUTH=(-H "Authorization: Bearer ${TOKEN}" -H "Accept: application/vnd.heroku+json; version=3")

echo "=== Recent Releases ==="
for APP in $(curl -s "${BASE}/apps" "${AUTH[@]}" | jq -r '.[].name'); do
  curl -s "${BASE}/apps/${APP}/releases?range=version;order=desc" "${AUTH[@]}" \
    | jq -r ".[:3][] | \"${APP}\tv\(.version)\t\(.status)\t\(.description[0:50])\t\(.created_at)\"" 2>/dev/null
done | column -t | head -20

echo ""
echo "=== Dyno Health ==="
for APP in $(curl -s "${BASE}/apps" "${AUTH[@]}" | jq -r '.[].name'); do
  curl -s "${BASE}/apps/${APP}/dynos" "${AUTH[@]}" \
    | jq -r ".[] | \"${APP}\t\(.name)\t\(.state)\t\(.type)\t\(.size)\t\(.updated_at)\"" 2>/dev/null
done | column -t | head -20

echo ""
echo "=== Config Vars (count only) ==="
for APP in $(curl -s "${BASE}/apps" "${AUTH[@]}" | jq -r '.[].name'); do
  COUNT=$(curl -s "${BASE}/apps/${APP}/config-vars" "${AUTH[@]}" | jq 'keys | length' 2>/dev/null)
  echo "${APP}: ${COUNT:-0} config vars"
done

echo ""
echo "=== Log Drains ==="
for APP in $(curl -s "${BASE}/apps" "${AUTH[@]}" | jq -r '.[].name'); do
  curl -s "${BASE}/apps/${APP}/log-drains" "${AUTH[@]}" \
    | jq -r ".[] | \"${APP}\t\(.url[0:50])\t\(.addon.name // \"custom\")\"" 2>/dev/null
done | column -t

echo ""
echo "=== SSL Certificates ==="
for APP in $(curl -s "${BASE}/apps" "${AUTH[@]}" | jq -r '.[].name'); do
  curl -s "${BASE}/apps/${APP}/sni-endpoints" "${AUTH[@]}" \
    | jq -r ".[] | \"${APP}\t\(.name)\t\(.ssl_cert.cert_domains | join(\",\"))\t\(.ssl_cert.expires_at)\"" 2>/dev/null
done | column -t

echo ""
echo "=== Stack & Buildpack Info ==="
for APP in $(curl -s "${BASE}/apps" "${AUTH[@]}" | jq -r '.[].name'); do
  BUILDPACKS=$(curl -s "${BASE}/apps/${APP}/buildpack-installations" "${AUTH[@]}" | jq -r '.[].buildpack.name // .[].buildpack.url' 2>/dev/null | tr '\n' ',')
  STACK=$(curl -s "${BASE}/apps/${APP}" "${AUTH[@]}" | jq -r '.stack.name' 2>/dev/null)
  echo "${APP}: stack=${STACK} buildpacks=${BUILDPACKS}"
done
```

## Output Format

```
HEROKU ANALYSIS
================
App              Region  Stack     Dynos        Add-ons  Domains  Last Release
──────────────────────────────────────────────────────────────────────────────
my-app           us      heroku-24 web:2xStd1x  3        2        2h ago v145
worker-app       eu      heroku-22 worker:1xPrf 1        0        1d ago v89
api-gateway      us      heroku-24 web:3xStd2x  5        3        30m ago v210

Dynos: 6 running | Add-ons: 9 total | Config Vars: 45 across 3 apps
Drains: 2 configured | SSL: 3 certs (1 expiring in 30d)
```

## Safety Rules

- **Read-only**: Only use GET endpoints against the Heroku API
- **Never scale dynos**, restart, or modify config vars without confirmation
- **Config vars**: Never output config variable values, only counts
- **Rate limits**: Heroku API allows 4500 requests per hour per token
