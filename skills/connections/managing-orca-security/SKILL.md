---
name: managing-orca-security
description: |
  Use when working with Orca Security — orca Security cloud-native application
  protection platform for agentless vulnerability scanning, compliance
  monitoring, and threat detection across cloud environments. Covers alert
  management, asset inventory, vulnerability prioritization, compliance
  frameworks, and attack path analysis. Use when investigating cloud security
  alerts, reviewing asset vulnerabilities, analyzing compliance posture, or
  managing Orca Security configurations.
connection_type: orca-security
preload: false
---

# Orca Security Management Skill

Manage and analyze Orca Security alerts, assets, vulnerabilities, and compliance posture.

## API Conventions

### Authentication
All API calls use `Authorization: Token $ORCA_API_TOKEN` -- injected automatically. Never hardcode tokens.

### Base URL
`https://app.orcasecurity.io/api`

### Core Helper Function

```bash
#!/bin/bash

orca_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Token $ORCA_API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://app.orcasecurity.io/api${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Token $ORCA_API_TOKEN" \
            -H "Content-Type: application/json" \
            "https://app.orcasecurity.io/api${endpoint}"
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
echo "=== Alert Summary ==="
orca_api GET "/alerts/query/summary" \
    | jq '{total: .total_alerts, critical: .critical, high: .high, medium: .medium, low: .low}'

echo ""
echo "=== Cloud Accounts ==="
orca_api GET "/cloud_accounts" \
    | jq -r '.data[] | "\(.cloud_provider)\t\(.account_name)\t\(.status)"' | column -t | head -10

echo ""
echo "=== Asset Count ==="
orca_api GET "/assets?limit=1" \
    | jq '"Total assets: \(.total_items)"' -r
```

## Analysis Phase

### Alert Investigation

```bash
#!/bin/bash
echo "=== Critical/High Alerts ==="
orca_api POST "/alerts/query" '{"filters":{"severity":["hazardous","critical","high"]},"limit":20,"order_by":"score","order":"desc"}' \
    | jq -r '.data[] | "\(.create_time[0:16])\t\(.severity)\t\(.alert_type)\t\(.description[0:50])"' \
    | column -t | head -20

echo ""
echo "=== Alerts by Category ==="
orca_api POST "/alerts/query" '{"filters":{},"group_by":"category","limit":100}' \
    | jq -r '.data[] | "\(.count)\t\(.category)"' | sort -rn | head -10 | column -t
```

### Asset Vulnerabilities

```bash
#!/bin/bash
echo "=== Most Vulnerable Assets ==="
orca_api POST "/assets/query" '{"filters":{"has_vulnerabilities":true},"order_by":"risk_score","order":"desc","limit":15}' \
    | jq -r '.data[] | "\(.risk_score)\t\(.asset_type)\t\(.asset_name[0:30])\t\(.cloud_provider)\tcrit:\(.vulnerability_summary.critical // 0)"' \
    | column -t

echo ""
echo "=== Vulnerability Summary by Severity ==="
orca_api GET "/vulnerabilities/summary" \
    | jq '{critical: .critical, high: .high, medium: .medium, low: .low, total: .total}'
```

### Compliance Overview

```bash
#!/bin/bash
echo "=== Compliance Frameworks ==="
orca_api GET "/compliance/frameworks" \
    | jq -r '.data[] | "\(.name[0:30])\tpassed:\(.passed_checks)\tfailed:\(.failed_checks)\tscore:\(.compliance_score)%"' \
    | column -t | head -15

echo ""
echo "=== Failed Compliance Checks (Critical) ==="
orca_api POST "/compliance/query" '{"filters":{"status":"failed","severity":"critical"},"limit":15}' \
    | jq -r '.data[] | "\(.severity)\t\(.framework[0:15])\t\(.title[0:50])\t\(.affected_assets) assets"' \
    | column -t | head -15
```

## Output Format

Present results as a structured report:
```
Managing Orca Security Report
═════════════════════════════
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

- **Agentless model**: Orca uses SideScanning -- no agent deployment required but needs cloud account access
- **Score vs severity**: Risk scores are numeric (0-100), severity is categorical
- **Pagination**: Use `limit` and `offset` parameters -- default limit is typically 20
- **Rate limits**: API rate limits apply -- check `X-RateLimit-Remaining` header
- **Multi-cloud**: Assets span AWS, Azure, GCP -- filter by `cloud_provider` when needed
