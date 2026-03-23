---
name: managing-tray-io
description: |
  Use when working with Tray Io — tray.io integration platform management
  covering workflow inventory, execution monitoring, connector health,
  authentication management, and solution instance tracking. Use when auditing
  integration workflows, investigating execution failures, monitoring API usage,
  or reviewing connector configurations.
connection_type: tray-io
preload: false
---

# Tray.io Management Skill

Manage and monitor Tray.io integration workflows, connectors, and execution pipelines.

## MANDATORY: Discovery-First Pattern

**Always list workflows and connectors before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash

TRAY_API="https://api.tray.io/core/v1"

tray_api() {
    curl -s -H "Authorization: Bearer $TRAY_API_TOKEN" \
         -H "Content-Type: application/json" \
         "${TRAY_API}/${1}"
}

echo "=== Tray.io Account ==="
tray_api "users/me" | jq '{name: .name, email: .email, role: .role}'

echo ""
echo "=== Workflows Summary ==="
tray_api "workflows" | jq -r '
    .data[] |
    "\(.id)\t\(.name)\t\(.enabled)\t\(.trigger_type // "manual")"
' | column -t | head -30

echo ""
echo "=== Authentications ==="
tray_api "authentications" | jq -r '
    .data[] |
    "\(.id)\t\(.name)\t\(.service)\t\(.status // "unknown")"
' | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Failed Executions (recent) ==="
tray_api "workflows" | jq -r '.data[].id' | while read wid; do
    tray_api "workflows/${wid}/executions?limit=5" | jq -r --arg wid "$wid" '
        .data[]? |
        select(.status == "failed") |
        "\($wid)\t\(.id)\t\(.status)\t\(.finished_at)"
    '
done | column -t | head -20

echo ""
echo "=== Disabled Workflows ==="
tray_api "workflows" | jq -r '
    .data[] |
    select(.enabled == false) |
    "\(.id)\t\(.name)\tDISABLED"
' | column -t

echo ""
echo "=== Workflow Health Summary ==="
tray_api "workflows" | jq '{
    total: (.data | length),
    enabled: [.data[] | select(.enabled == true)] | length,
    disabled: [.data[] | select(.enabled == false)] | length
}'
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Filter workflows by enabled/disabled status
- Never dump full workflow step definitions -- extract connector names and trigger types

## Output Format

Present results as a structured report:
```
Managing Tray Io Report
═══════════════════════
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

- **Authentication expiry**: OAuth tokens expire and must be re-authenticated in the UI
- **Trigger types**: Manual vs scheduled vs webhook triggers behave differently for monitoring
- **Solution instances**: Embedded solutions create separate workflow instances per customer
- **Rate limits**: Connector-level rate limits can cause cascading failures across workflows
- **Step timeouts**: Long-running steps can timeout silently -- check execution durations
