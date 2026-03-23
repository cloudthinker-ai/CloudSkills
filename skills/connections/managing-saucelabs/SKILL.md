---
name: managing-saucelabs
description: |
  Use when working with Saucelabs — sauce Labs cloud testing platform monitoring
  and analysis. Covers test job management, tunnel monitoring, real device
  testing, build tracking, concurrency analysis, and usage metrics. Use when
  managing Sauce Labs test sessions, reviewing cross-browser/device results, or
  monitoring cloud testing infrastructure and tunnels.
connection_type: saucelabs
preload: false
---

# Sauce Labs Cloud Testing Management Skill

Manage and analyze Sauce Labs test jobs, tunnels, builds, and device pools.

## Core Helper Functions

```bash
#!/bin/bash

# Sauce Labs API helper
sauce_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"
    local dc="${SAUCE_DATA_CENTER:-us-west-1}"
    local base_url="https://api.${dc}.saucelabs.com"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -u "${SAUCE_USERNAME}:${SAUCE_ACCESS_KEY}" \
            -H "Content-Type: application/json" \
            "${base_url}/${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -u "${SAUCE_USERNAME}:${SAUCE_ACCESS_KEY}" \
            "${base_url}/${endpoint}"
    fi
}
```

## MANDATORY: Discovery-First Pattern

**Always discover account info and active resources before querying specifics.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Sauce Labs Account ==="
sauce_api GET "rest/v1/users/${SAUCE_USERNAME}" | jq '{
    username: .username,
    concurrency: .concurrency_limit,
    minutes_remaining: .minutes
}'

echo ""
echo "=== Active Tunnels ==="
sauce_api GET "rest/v1/${SAUCE_USERNAME}/tunnels" | jq -r '.[]' | while read tid; do
    sauce_api GET "rest/v1/${SAUCE_USERNAME}/tunnels/${tid}" | jq -r '"\(.id)\tstatus=\(.status)\thost=\(.tunnel_identifier // "default")"'
done | column -t | head -10

echo ""
echo "=== Recent Jobs ==="
sauce_api GET "rest/v1/${SAUCE_USERNAME}/jobs?limit=10" | jq -r '
    .[] | "\(.id)\t\(.name // "unnamed")\tstatus=\(.status)\tbrowser=\(.browser)\tos=\(.os)"
' | column -t

echo ""
echo "=== Concurrency ==="
sauce_api GET "rest/v1.1/users/${SAUCE_USERNAME}/concurrency" | jq '{
    current: .concurrency.organization.current,
    allowed: .concurrency.organization.allowed
}'
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Job Details ==="
JOB_ID="${1:-}"
if [ -n "$JOB_ID" ]; then
    sauce_api GET "rest/v1/${SAUCE_USERNAME}/jobs/${JOB_ID}" | jq '{
        name: .name,
        status: .status,
        passed: .passed,
        browser: .browser,
        browser_version: .browser_version,
        os: .os,
        duration: .end_time - .start_time,
        error: .error
    }'
fi

echo ""
echo "=== Build Summary ==="
BUILD_NAME="${2:-}"
if [ -n "$BUILD_NAME" ]; then
    sauce_api GET "rest/v1/${SAUCE_USERNAME}/jobs?limit=50&full=false" | jq --arg build "$BUILD_NAME" '
        [.[] | select(.build == $build)] | {
            total: length,
            passed: [.[] | select(.passed == true)] | length,
            failed: [.[] | select(.passed == false)] | length,
            errors: [.[] | select(.error != null)] | length,
            browsers: [.[].browser] | unique
        }'
fi

echo ""
echo "=== Real Device Jobs ==="
sauce_api GET "v1/rdc/jobs?limit=5" | jq -r '
    .entities[] | "\(.id)\t\(.name // "unnamed")\tstatus=\(.status)\tdevice=\(.device_name)"
' | column -t 2>/dev/null || echo "No real device jobs found"
```

## Output Rules
- **TOKEN EFFICIENCY**: Target 50 lines per output
- Use limit parameter for pagination
- Never include job logs inline — reference log URLs instead

## Anti-Hallucination Rules
- NEVER guess job or tunnel IDs — always discover via API
- NEVER fabricate job results — query actual Sauce Labs data
- NEVER assume data center — check SAUCE_DATA_CENTER setting

## Safety Rules
- NEVER terminate running jobs without explicit user confirmation
- NEVER delete tunnels without user approval
- NEVER upload apps without user consent
- Monitor concurrency before starting new sessions

## Output Format

Present results as a structured report:
```
Managing Saucelabs Report
═════════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

