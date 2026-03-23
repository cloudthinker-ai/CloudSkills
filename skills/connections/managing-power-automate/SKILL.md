---
name: managing-power-automate
description: |
  Use when working with Power Automate — microsoft Power Automate flow
  management covering flow inventory, run history, connection health, connector
  usage, and environment monitoring. Use when auditing cloud or desktop flows,
  investigating run failures, monitoring API call quotas, or reviewing connector
  and gateway configurations.
connection_type: power-automate
preload: false
---

# Power Automate Management Skill

Manage and monitor Microsoft Power Automate flows, connections, and run history.

## MANDATORY: Discovery-First Pattern

**Always list flows and environments before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash

PA_API="https://api.flow.microsoft.com"

pa_api() {
    curl -s -H "Authorization: Bearer $POWER_AUTOMATE_TOKEN" \
         -H "Content-Type: application/json" \
         "${PA_API}/providers/Microsoft.ProcessSimple/${1}?api-version=2016-11-01"
}

echo "=== Environments ==="
pa_api "environments" | jq -r '
    .value[] |
    "\(.name)\t\(.properties.displayName)\t\(.properties.environmentSku)"
' | column -t

echo ""
echo "=== Flows Summary ==="
ENV_ID=$(pa_api "environments" | jq -r '.value[0].name')
pa_api "environments/${ENV_ID}/flows" | jq -r '
    .value[] |
    "\(.name)\t\(.properties.displayName)\t\(.properties.state)\t\(.properties.flowTriggerUri != null)"
' | column -t | head -30

echo ""
echo "=== Connections ==="
pa_api "environments/${ENV_ID}/connections" | jq -r '
    .value[] |
    "\(.name)\t\(.properties.displayName)\t\(.properties.apiId | split("/") | last)\t\(.properties.statuses[0].status)"
' | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

ENV_ID=$(pa_api "environments" | jq -r '.value[0].name')

echo "=== Failed Runs (recent) ==="
pa_api "environments/${ENV_ID}/flows" | jq -r '.value[].name' | head -15 | while read fid; do
    pa_api "environments/${ENV_ID}/flows/${fid}/runs?\$filter=status eq 'Failed'&\$top=3" | jq -r --arg fid "$fid" '
        .value[]? |
        "\($fid)\t\(.name)\t\(.properties.status)\t\(.properties.endTime)"
    '
done | column -t | head -20

echo ""
echo "=== Flow Status Summary ==="
pa_api "environments/${ENV_ID}/flows" | jq '{
    total: (.value | length),
    started: [.value[] | select(.properties.state == "Started")] | length,
    stopped: [.value[] | select(.properties.state == "Stopped")] | length,
    suspended: [.value[] | select(.properties.state == "Suspended")] | length
}'

echo ""
echo "=== Suspended Flows ==="
pa_api "environments/${ENV_ID}/flows" | jq -r '
    .value[] |
    select(.properties.state == "Suspended") |
    "\(.properties.displayName)\tSUSPENDED\t\(.properties.flowFailureAlertSubscribed)"
' | column -t
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Filter flows by environment and state
- Never dump full flow definitions -- extract trigger and action connector names

## Output Format

Present results as a structured report:
```
Managing Power Automate Report
══════════════════════════════
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

- **API call limits**: Power Platform enforces per-user and per-flow API call limits per 24h
- **Connection consent**: Connections require interactive consent -- cannot be created via API alone
- **DLP policies**: Data Loss Prevention policies block certain connector combinations
- **Suspended flows**: Flows suspend after repeated failures -- must be manually restarted
- **Premium connectors**: Premium/custom connectors require paid licenses per user
- **Desktop flows**: Desktop flows require on-premises gateway -- check gateway status
- **Environment isolation**: Flows in different environments cannot share connections
