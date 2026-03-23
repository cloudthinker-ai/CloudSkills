---
name: managing-selenium-deep
description: |
  Use when working with Selenium Deep — selenium WebDriver testing management
  and grid monitoring. Covers Selenium Grid node health, session management,
  browser capability analysis, test result parsing, hub configuration review,
  and WebDriver compatibility checks. Use when managing Selenium Grid
  infrastructure, investigating test failures, or reviewing browser automation
  suites.
connection_type: selenium
preload: false
---

# Selenium WebDriver Testing Management Skill

Manage Selenium Grid infrastructure and analyze WebDriver test suites.

## Core Helper Functions

```bash
#!/bin/bash

# Selenium Grid API helper
selenium_api() {
    local endpoint="$1"
    curl -s "${SELENIUM_GRID_URL:-http://localhost:4444}/${endpoint}"
}

# Grid status shorthand
grid_status() {
    selenium_api "status"
}
```

## MANDATORY: Discovery-First Pattern

**Always discover Grid topology and node status before querying specifics.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Selenium Grid Status ==="
grid_status | jq '{
    ready: .value.ready,
    message: .value.message,
    node_count: (.value.nodes | length)
}'

echo ""
echo "=== Grid Nodes ==="
grid_status | jq -r '
    .value.nodes[] |
    "\(.uri)\t\(.availability)\tslots=\(.maxSessions)\tused=\(.sessionCount // 0)"
' | column -t

echo ""
echo "=== Available Browser Capabilities ==="
grid_status | jq -r '
    [.value.nodes[].slots[].stereotype] | group_by(.browserName) |
    .[] | "\(.[0].browserName)\tv\(.[0].browserVersion // "any")\tcount=\(length)"
' | column -t

echo ""
echo "=== Active Sessions ==="
selenium_api "se/grid/newsessionqueue/queue" | jq -r '
    if type == "array" then .[:10][] | "\(.capabilities.browserName)\t\(.capabilities.browserVersion // "any")"
    else "No queued sessions" end
' | column -t
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Node Health Check ==="
grid_status | jq -r '
    .value.nodes[] |
    "\(.uri)\t\(.availability)\tosInfo=\(.osInfo.name // "unknown")\tarch=\(.osInfo.arch // "unknown")"
' | column -t

echo ""
echo "=== Session Distribution ==="
grid_status | jq '
    .value.nodes | {
        total_nodes: length,
        available: [.[] | select(.availability == "UP")] | length,
        draining: [.[] | select(.availability == "DRAINING")] | length,
        down: [.[] | select(.availability == "DOWN")] | length,
        total_slots: [.[].maxSessions] | add,
        used_slots: [.[].sessionCount // 0] | add
    }'

echo ""
echo "=== Grid Configuration ==="
selenium_api "grid/api/hub" 2>/dev/null | jq '.' | head -15
```

## Output Rules
- **TOKEN EFFICIENCY**: Target 50 lines per output
- Use Grid 4.x GraphQL or REST endpoints for structured data
- Never dump full test logs — extract relevant error sections

## Anti-Hallucination Rules
- NEVER guess node URLs — always discover via Grid status API
- NEVER fabricate session IDs — query active sessions from the hub
- NEVER assume Grid version — Grid 3.x and 4.x have different APIs

## Safety Rules
- NEVER terminate sessions without explicit user confirmation
- NEVER drain or remove nodes without user approval
- NEVER modify Grid configuration without user consent

## Output Format

Present results as a structured report:
```
Managing Selenium Deep Report
═════════════════════════════
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

