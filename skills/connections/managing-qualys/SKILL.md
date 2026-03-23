---
name: managing-qualys
description: |
  Use when working with Qualys — qualys vulnerability management, asset
  inventory, compliance scanning, and security posture assessment. Covers
  vulnerability scan results, host detection queries, VMDR dashboard metrics,
  patch prioritization, and compliance policy checks. Use when reviewing
  vulnerability scan findings, analyzing host security posture, tracking
  remediation progress, or managing Qualys scan schedules.
connection_type: qualys
preload: false
---

# Qualys Management Skill

Manage and analyze Qualys vulnerabilities, host detections, compliance scans, and asset inventory.

## API Conventions

### Authentication
All API calls use Basic Auth via `Authorization: Basic $QUALYS_AUTH` -- injected automatically. Never hardcode credentials.

### Base URL
`https://qualysapi.$QUALYS_PLATFORM.qualys.com/api/2.0/fo`

### Core Helper Function

```bash
#!/bin/bash

qualys_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    local base="https://qualysapi.${QUALYS_PLATFORM}.qualys.com/api/2.0/fo"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Basic $QUALYS_AUTH" \
            -H "X-Requested-With: curl" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            "${base}${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Basic $QUALYS_AUTH" \
            -H "X-Requested-With: curl" \
            "${base}${endpoint}"
    fi
}

qualys_api_v2() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    local base="https://qualysapi.${QUALYS_PLATFORM}.qualys.com/qps/rest/2.0"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Basic $QUALYS_AUTH" \
            -H "Content-Type: application/json" \
            "${base}${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Basic $QUALYS_AUTH" \
            -H "Content-Type: application/json" \
            "${base}${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq` or XML parsers
- Target <=50 lines per script output
- Always filter by relevant time range to avoid huge response sets
- Never dump full API responses

## Discovery Phase

```bash
#!/bin/bash
echo "=== Host Asset Count ==="
qualys_api_v2 POST "/count/am/hostasset" '{}' \
    | jq '"Total hosts: \(.count)"' -r

echo ""
echo "=== Scan List (recent) ==="
qualys_api GET "/scan/?action=list&state=Finished&launched_after_datetime=$(date -u -v-30d +%Y-%m-%dT%H:%M:%SZ)" \
    | xmllint --xpath '//SCAN/TITLE/text() | //SCAN/STATUS/STATE/text()' - 2>/dev/null | head -10

echo ""
echo "=== Scanner Appliances ==="
qualys_api GET "/appliance/?action=list" \
    | xmllint --xpath '//APPLIANCE/NAME/text()' - 2>/dev/null | head -10
```

## Analysis Phase

### Vulnerability Dashboard

```bash
#!/bin/bash
echo "=== Vulnerability Summary by Severity ==="
qualys_api_v2 POST "/search/am/hostasset" '{
    "ServiceRequest": {
        "filters": {"Criteria": [{"field": "vulnerabilityCount", "operator": "GREATER", "value": "0"}]},
        "preferences": {"limitResults": 10}
    }
}' | jq -r '.ServiceResponse.data[]?.HostAsset | "\(.id)\t\(.name // .address)\tVulns: \(.vulnerabilityCount)"' | column -t | head -15

echo ""
echo "=== Critical QIDs (last 30 days) ==="
qualys_api GET "/knowledge_base/vuln/?action=list&details=Basic&severity_level=5&published_after=$(date -u -v-30d +%Y-%m-%d)" \
    | xmllint --xpath '//VULN/QID/text() | //VULN/TITLE/text()' - 2>/dev/null | paste - - | head -15
```

### Host Detection Analysis

```bash
#!/bin/bash
echo "=== Hosts with Critical Detections ==="
qualys_api GET "/asset/host/vm/detection/?action=list&severities=5&status=New,Active,Re-Opened&truncation_limit=20" \
    | xmllint --xpath '//HOST/IP/text() | //HOST/DNS/text()' - 2>/dev/null | paste - - | head -15

echo ""
echo "=== Detection Counts by Status ==="
for status in New Active "Re-Opened" Fixed; do
    echo -n "$status: "
    qualys_api GET "/asset/host/vm/detection/?action=list&status=${status}&truncation_limit=1" \
        | xmllint --xpath '//WARNING/TEXT/text()' - 2>/dev/null || echo "0"
done
```

### Scan Schedule Review

```bash
#!/bin/bash
echo "=== Scheduled Scans ==="
qualys_api GET "/schedule/scan/?action=list" \
    | xmllint --xpath '//SCHEDULE_SCAN/TITLE/text() | //SCHEDULE_SCAN/ACTIVE/text()' - 2>/dev/null | paste - - | head -15

echo ""
echo "=== Recent Scan Results ==="
qualys_api GET "/scan/?action=list&state=Finished&launched_after_datetime=$(date -u -v-7d +%Y-%m-%dT%H:%M:%SZ)&show_last=10" \
    | xmllint --xpath '//SCAN/TITLE/text() | //SCAN/PROCESSED/text() | //SCAN/STATUS/STATE/text()' - 2>/dev/null | paste - - - | head -10
```

## Output Format

Present results as a structured report:
```
Managing Qualys Report
══════════════════════
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

- **XML vs JSON**: Older API (v1/v2) returns XML; QPS REST API (v2.0) returns JSON
- **X-Requested-With header**: Required for all API calls -- omitting causes 403
- **Platform URL**: API URL varies by platform (US1, US2, US3, EU1, etc.)
- **Truncation**: Large result sets are truncated -- check WARNING element for truncation info
- **Rate limits**: 300 calls/hour for most endpoints -- use `X-RateLimit-Remaining` header
- **Concurrency**: Maximum 2 concurrent API calls per user
