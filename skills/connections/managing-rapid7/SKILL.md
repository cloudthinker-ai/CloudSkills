---
name: managing-rapid7
description: |
  Rapid7 InsightVM vulnerability management, asset discovery, risk scoring, and remediation tracking. Covers vulnerability scanning, asset inventory, risk prioritization, scan scheduling, and compliance reporting. Use when reviewing vulnerability scan results, analyzing asset risk posture, tracking remediation progress, or managing Rapid7 InsightVM scan configurations.
connection_type: rapid7
preload: false
---

# Rapid7 InsightVM Management Skill

Manage and analyze Rapid7 InsightVM vulnerabilities, assets, scans, and risk scores.

## API Conventions

### Authentication
All API calls use Basic Auth via `Authorization: Basic $RAPID7_AUTH` -- injected automatically. Never hardcode credentials.

### Base URL
`https://$RAPID7_HOST:3780/api/3`

### Core Helper Function

```bash
#!/bin/bash

r7_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Basic $RAPID7_AUTH" \
            -H "Content-Type: application/json" \
            "https://${RAPID7_HOST}:3780/api/3${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Basic $RAPID7_AUTH" \
            -H "Content-Type: application/json" \
            "https://${RAPID7_HOST}:3780/api/3${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target <=50 lines per script output
- Always filter by relevant time range to avoid huge response sets
- Never dump full API responses

## Discovery Phase

```bash
#!/bin/bash
echo "=== Asset Summary ==="
r7_api GET "/assets?size=1" | jq '"Total assets: \(.page.totalResources)"' -r

echo ""
echo "=== Vulnerability Summary ==="
r7_api GET "/vulnerabilities?size=1" | jq '"Total known vulns: \(.page.totalResources)"' -r

echo ""
echo "=== Scan Engines ==="
r7_api GET "/scan_engines" | jq -r '.resources[] | "\(.name)\t\(.status)\t\(.address)"' | column -t

echo ""
echo "=== Sites ==="
r7_api GET "/sites?size=50" | jq -r '.resources[] | "\(.id)\t\(.name)\t\(.riskScore)"' | column -t | head -15
```

## Analysis Phase

### Vulnerability Overview

```bash
#!/bin/bash
echo "=== Critical Vulnerabilities ==="
r7_api GET "/vulnerabilities?size=20&sort=severity,DESC&page=0" \
    | jq -r '.resources[] | select(.severity == "Critical") | "\(.id)\t\(.severity)\tCVSS:\(.cvss.v3 // .cvss.v2 // "N/A")\t\(.title[0:60])"' \
    | column -t | head -15

echo ""
echo "=== Vulnerability Count by Severity ==="
for sev in Critical Severe Moderate; do
    COUNT=$(r7_api GET "/vulnerabilities?size=1&filter=severity=$sev" | jq '.page.totalResources')
    echo "$sev: $COUNT"
done

echo ""
echo "=== Exploitable Vulnerabilities ==="
r7_api GET "/vulnerabilities?size=10&sort=severity,DESC&filter=exploits%3E0" \
    | jq -r '.resources[] | "\(.severity)\texploits:\(.exploits)\t\(.title[0:60])"' | column -t
```

### Asset Risk Analysis

```bash
#!/bin/bash
echo "=== Highest Risk Assets ==="
r7_api GET "/assets?size=15&sort=riskScore,DESC" \
    | jq -r '.resources[] | "\(.riskScore)\t\(.ip)\t\(.hostName // "N/A")\t\(.os // "Unknown" | .[0:30])"' \
    | column -t

echo ""
echo "=== Assets by OS ==="
r7_api GET "/assets?size=500" \
    | jq -r '[.resources[].osFingerprint.description // "Unknown"] | group_by(.) | map({os: .[0][0:40], count: length}) | sort_by(.count) | reverse | .[:10][] | "\(.count)\t\(.os)"' \
    | column -t
```

### Scan Status

```bash
#!/bin/bash
echo "=== Recent Scans ==="
r7_api GET "/scans?size=15&sort=endTime,DESC&active=false" \
    | jq -r '.resources[] | "\(.endTime[0:16])\t\(.status)\t\(.assets)\t\(.vulnerabilities.total)\t\(.scanName[0:40])"' \
    | column -t

echo ""
echo "=== Active Scans ==="
r7_api GET "/scans?active=true" \
    | jq -r '.resources[] | "\(.startTime[0:16])\t\(.status)\t\(.scanName[0:40])"' | column -t
```

## Common Pitfalls

- **Pagination**: Uses `page` (0-indexed) and `size` parameters -- check `page.totalPages`
- **Filter syntax**: URL-encode filters -- use `%3E` for `>`, `%3D` for `=`
- **Self-signed certs**: On-prem installs often use self-signed certs -- add `-k` to curl if needed
- **Rate limits**: Console API has no published rate limits but throttles under heavy load
- **Asset vs vulnerability**: Assets have vulns linked -- query `/assets/{id}/vulnerabilities` for per-asset detail
