---
name: managing-site24x7
description: |
  Use when working with Site24X7 — site24x7 cloud monitoring platform for
  websites, servers, networks, applications, and cloud infrastructure. Covers
  monitor status, alert management, performance metrics, SLA reporting, and
  threshold configuration. Use when checking Site24x7 monitor status,
  investigating downtime, reviewing performance metrics, or managing monitor
  configurations and alert rules.
connection_type: site24x7
preload: false
---

# Site24x7 Monitoring Skill

Query, analyze, and manage Site24x7 monitoring data using the Site24x7 API.

## API Overview

Site24x7 uses a REST API at `https://www.site24x7.com/api`.

### Core Helper Function

```bash
#!/bin/bash

s24_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    if [ -n "$data" ]; then
        curl -s -X "$method" "https://www.site24x7.com/api/${endpoint}" \
            -H "Authorization: Zoho-oauthtoken $SITE24X7_ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$data"
    else
        curl -s -X "$method" "https://www.site24x7.com/api/${endpoint}" \
            -H "Authorization: Zoho-oauthtoken $SITE24X7_ACCESS_TOKEN"
    fi
}
```

## MANDATORY: Discovery-First Pattern

**Always discover monitors, monitor groups, and alert profiles before querying.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Monitor Groups ==="
s24_api GET "monitor_groups" | jq -r '.data[] | "\(.group_id)\t\(.display_name)\tmonitors:\(.monitors | length)"' | head -15

echo ""
echo "=== Monitors ==="
s24_api GET "monitors" | jq -r '.data[] | "\(.monitor_id)\t\(.display_name)\t\(.type)\t\(.status | if . == 1 then "UP" elif . == 0 then "DOWN" else "TROUBLE" end)"' | head -25

echo ""
echo "=== Alert Profiles ==="
s24_api GET "notification_profiles" | jq -r '.data[] | "\(.profile_id)\t\(.profile_name)"' | head -10

echo ""
echo "=== Threshold Profiles ==="
s24_api GET "threshold_profiles" | jq -r '.data[] | "\(.profile_id)\t\(.profile_name)\t\(.type)"' | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Current Status Overview ==="
s24_api GET "current_status" | jq -r '.data.monitors[] | "\(.status | if . == 1 then "UP" elif . == 0 then "DOWN" elif . == 2 then "TROUBLE" elif . == 5 then "MAINT" else "UNKNOWN" end)\t\(.name)\t\(.attribute_value // "N/A")"' | head -20

echo ""
echo "=== Down Monitors ==="
s24_api GET "current_status?status=0" | jq -r '.data.monitors[] | "\(.name)\t\(.down_reason // "unknown")\tsince:\(.last_polled_time)"' | head -15

echo ""
echo "=== Performance (Avg Response Time) ==="
s24_api GET "reports/performance?period=3" | jq -r '.data[] | "\(.display_name)\tavg:\(.average_response_time // "N/A")ms\tavail:\(.availability_percentage // "N/A")%"' | head -15

echo ""
echo "=== Recent Alerts ==="
s24_api GET "alerts?status=1" | jq -r '.data[] | "\(.monitor_display_name)\t\(.alert_type)\t\(.msg[0:50])\t\(.sent_time)"' | head -15

echo ""
echo "=== SLA Report ==="
s24_api GET "reports/sla_reports?period=3" | jq -r '.data[] | "\(.display_name)\tSLA:\(.sla_percentage // "N/A")%\tdowntime:\(.total_down_duration // "0")"' | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines — use status filters and `head` in output
- Monitor status: 0=DOWN, 1=UP, 2=TROUBLE, 5=MAINTENANCE, 7=SUSPENDED
- Period values: 1=last 1h, 2=last 24h, 3=last 7d, 4=last 30d
- Use `current_status` for real-time overview before querying individual monitors

## Output Format

Present results as a structured report:
```
Managing Site24X7 Report
════════════════════════
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

