---
name: managing-tenable
description: |
  Tenable.io vulnerability management, asset discovery, scan orchestration, and risk-based prioritization. Covers vulnerability exports, asset inventory, VPR scoring, plugin analysis, scan scheduling, and compliance auditing. Use when reviewing vulnerability findings, analyzing asset exposure, prioritizing remediation efforts, or managing Tenable scan configurations.
connection_type: tenable
preload: false
---

# Tenable.io Management Skill

Manage and analyze Tenable.io vulnerabilities, assets, scans, and risk prioritization.

## API Conventions

### Authentication
All API calls use `X-ApiKeys: accessKey=$TENABLE_ACCESS_KEY;secretKey=$TENABLE_SECRET_KEY` -- injected automatically. Never hardcode keys.

### Base URL
`https://cloud.tenable.com`

### Core Helper Function

```bash
#!/bin/bash

tenable_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "X-ApiKeys: accessKey=$TENABLE_ACCESS_KEY;secretKey=$TENABLE_SECRET_KEY" \
            -H "Content-Type: application/json" \
            "https://cloud.tenable.com${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "X-ApiKeys: accessKey=$TENABLE_ACCESS_KEY;secretKey=$TENABLE_SECRET_KEY" \
            -H "Content-Type: application/json" \
            "https://cloud.tenable.com${endpoint}"
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
echo "=== Asset Count ==="
tenable_api GET "/assets" | jq '"Total assets: \(.assets | length)"' -r

echo ""
echo "=== Scan Summary ==="
tenable_api GET "/scans" | jq '{total_scans: (.scans | length), running: ([.scans[] | select(.status == "running")] | length)}'

echo ""
echo "=== Scanner Status ==="
tenable_api GET "/scanners" | jq -r '.scanners[] | "\(.name)\t\(.status)\t\(.type)"' | column -t | head -10
```

## Analysis Phase

### Vulnerability Overview

```bash
#!/bin/bash
echo "=== Vulnerability Counts by Severity ==="
tenable_api GET "/workbenches/vulnerabilities?date_range=30&filter.0.filter=severity&filter.0.quality=eq&filter.0.value=Critical" \
    | jq '"Critical: \(.total_vulnerability_count)"' -r
tenable_api GET "/workbenches/vulnerabilities?date_range=30&filter.0.filter=severity&filter.0.quality=eq&filter.0.value=High" \
    | jq '"High: \(.total_vulnerability_count)"' -r

echo ""
echo "=== Top Vulnerabilities by VPR ==="
tenable_api GET "/workbenches/vulnerabilities?date_range=30&sort=vpr_score:desc&limit=15" \
    | jq -r '.vulnerabilities[:15][] | "\(.vpr_score // "N/A")\t\(.severity_index)\t\(.plugin_name[0:60])"' \
    | column -t

echo ""
echo "=== Exploitable Vulnerabilities ==="
tenable_api GET "/workbenches/vulnerabilities?date_range=30&filter.0.filter=exploit_available&filter.0.quality=eq&filter.0.value=true&limit=10" \
    | jq -r '.vulnerabilities[:10][] | "\(.severity_index)\tVPR:\(.vpr_score // "N/A")\t\(.plugin_name[0:60])"' | column -t
```

### Asset Risk Analysis

```bash
#!/bin/bash
echo "=== Highest Risk Assets (by ACR) ==="
tenable_api GET "/assets?limit=15&sort=acr_score:desc" \
    | jq -r '.assets[:15][] | "\(.acr_score // "N/A")\t\(.ipv4 // [] | join(","))\t\(.fqdn // [] | .[0] // "N/A")\t\(.operating_system // [] | .[0] // "Unknown" | .[0:30])"' \
    | column -t

echo ""
echo "=== Assets Not Scanned (>30 days) ==="
CUTOFF=$(date -u -v-30d +%Y-%m-%d)
tenable_api GET "/assets?limit=500" \
    | jq -r --arg cutoff "$CUTOFF" '[.assets[] | select(.last_authenticated_scan_date != null and .last_authenticated_scan_date < $cutoff)] | length | "Assets stale >30 days: \(.)"'
```

### Scan Management

```bash
#!/bin/bash
echo "=== Recent Scan Results ==="
tenable_api GET "/scans" \
    | jq -r '.scans[] | select(.status == "completed") | "\(.last_modification_date | todate[0:16])\t\(.name[0:40])\thosts:\(.hostcount)"' \
    | sort -r | head -15 | column -t

echo ""
echo "=== Running Scans ==="
tenable_api GET "/scans" \
    | jq -r '.scans[] | select(.status == "running") | "\(.name[0:40])\t\(.status)\thosts:\(.hostcount)"' | column -t
```

## Common Pitfalls

- **Export API for large datasets**: Use `/vulns/export` and `/assets/export` for bulk data -- workbench APIs are for summaries
- **VPR vs CVSS**: Tenable prioritizes by VPR (Vulnerability Priority Rating) over CVSS
- **Rate limits**: 40 requests/second burst, sustained varies by license
- **Date formats**: Epoch timestamps in many responses -- convert with `todate` in jq
- **ACR/AES scores**: Asset Criticality Rating and Asset Exposure Score require Lumin license
