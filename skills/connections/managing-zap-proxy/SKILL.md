---
name: managing-zap-proxy
description: |
  Use when working with Zap Proxy — oWASP ZAP (Zed Attack Proxy) for automated
  dynamic application security testing and web vulnerability scanning. Covers
  active/passive scanning, spider crawling, alert management, scan policies, and
  authentication configuration. Use when running web application security scans,
  reviewing discovered vulnerabilities, managing scan policies, or analyzing ZAP
  alerts and scan progress.
connection_type: zap-proxy
preload: false
---

# OWASP ZAP Management Skill

Manage and analyze OWASP ZAP scans, alerts, spider results, and scan policies.

## API Conventions

### Authentication
All API calls use `X-ZAP-API-Key: $ZAP_API_KEY` as a query parameter or header -- injected automatically. Never hardcode keys.

### Base URL
`http://$ZAP_HOST:$ZAP_PORT`

### Core Helper Function

```bash
#!/bin/bash

zap_api() {
    local endpoint="$1"
    local params="${2:-}"

    curl -s "http://${ZAP_HOST}:${ZAP_PORT}${endpoint}?apikey=${ZAP_API_KEY}&${params}" \
        -H "Accept: application/json"
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target <=50 lines per script output
- Never dump full API responses

## Discovery Phase

```bash
#!/bin/bash
echo "=== ZAP Version ==="
zap_api "/JSON/core/view/version/" | jq -r '.version'

echo ""
echo "=== Active Scans ==="
zap_api "/JSON/ascan/view/scans/" \
    | jq -r '.scans[] | "\(.id)\t\(.state)\tprogress:\(.progress)%\t\(.reqCount) requests"' | column -t

echo ""
echo "=== Sites in Scope ==="
zap_api "/JSON/core/view/sites/" \
    | jq -r '.sites[]' | head -10

echo ""
echo "=== Alert Summary ==="
zap_api "/JSON/alert/view/alertsSummary/" \
    | jq '.'
```

## Analysis Phase

### Alert Overview

```bash
#!/bin/bash
echo "=== Alerts by Risk Level ==="
zap_api "/JSON/alert/view/alertsSummary/" \
    | jq '{High: .alertsSummary.High, Medium: .alertsSummary.Medium, Low: .alertsSummary.Low, Informational: .alertsSummary.Informational}'

echo ""
echo "=== High Risk Alerts ==="
zap_api "/JSON/alert/view/alertsByRisk/" "riskId=3" \
    | jq -r '.alertsByRisk[].alertsByRisk[]? | "\(.alert[0:40])\tcount:\(.count)\trisk:\(.riskcode)"' \
    | column -t | head -15

echo ""
echo "=== Recent Alerts ==="
zap_api "/JSON/core/view/alerts/" "start=0&count=20" \
    | jq -r '.alerts[] | "\(.risk)\t\(.confidence)\t\(.alert[0:35])\t\(.url[0:40])"' \
    | column -t | head -20
```

### Scan Progress

```bash
#!/bin/bash
SCAN_ID="${1:-0}"

echo "=== Active Scan Status ==="
zap_api "/JSON/ascan/view/status/" "scanId=${SCAN_ID}" \
    | jq '"Scan progress: \(.status)%"' -r

echo ""
echo "=== Scan Messages Count ==="
zap_api "/JSON/ascan/view/messagesIds/" "scanId=${SCAN_ID}" \
    | jq '"Total messages: \(.messagesIds | length)"' -r

echo ""
echo "=== Spider Status ==="
zap_api "/JSON/spider/view/status/" \
    | jq '"Spider progress: \(.status)%"' -r

echo ""
echo "=== URLs Found ==="
zap_api "/JSON/spider/view/allUrls/" \
    | jq '.allUrls | length | "Total URLs discovered: \(.)"' -r
```

### Alert Details

```bash
#!/bin/bash
echo "=== Alert Types ==="
zap_api "/JSON/core/view/alerts/" "start=0&count=200" \
    | jq -r '[.alerts[].alert] | group_by(.) | map({alert: .[0][0:50], count: length}) | sort_by(.count) | reverse | .[:15][] | "\(.count)\t\(.alert)"' \
    | column -t

echo ""
echo "=== Unique Vulnerable URLs ==="
zap_api "/JSON/core/view/alerts/" "start=0&count=200&riskId=3" \
    | jq -r '[.alerts[].url] | unique | .[:10][]'
```

## Output Format

Present results as a structured report:
```
Managing Zap Proxy Report
═════════════════════════
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

- **API key in query string**: ZAP uses `apikey` query parameter, not Authorization header
- **Scan IDs**: Active scan and spider scan have separate ID namespaces
- **Risk levels**: 3 = High, 2 = Medium, 1 = Low, 0 = Informational
- **Confidence levels**: 3 = High, 2 = Medium, 1 = Low, 0 = False Positive
- **Local proxy**: ZAP typically runs locally -- ensure `ZAP_HOST` is reachable
- **Daemon mode**: API only available when ZAP runs in daemon mode (`-daemon` flag)
