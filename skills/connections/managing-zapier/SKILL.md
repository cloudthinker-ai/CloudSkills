---
name: managing-zapier
description: |
  Use when working with Zapier — zapier workflow automation management covering
  Zap inventory, task usage tracking, connection health, error monitoring, and
  folder organization. Use when auditing Zap configurations, investigating
  failed tasks, monitoring usage quotas, or reviewing connected app
  integrations.
connection_type: zapier
preload: false
---

# Zapier Management Skill

Manage and monitor Zapier workflow automations, task usage, and connected applications.

## MANDATORY: Discovery-First Pattern

**Always list Zaps and connections before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash

ZAPIER_API="https://api.zapier.com/v1"

zapier_api() {
    curl -s -H "Authorization: Bearer $ZAPIER_API_KEY" \
         -H "Content-Type: application/json" \
         "${ZAPIER_API}/${1}"
}

echo "=== Zapier Account Overview ==="
zapier_api "profile" | jq '{email: .email, plan: .plan, role: .role}'

echo ""
echo "=== Zaps Summary ==="
zapier_api "zaps" | jq -r '
    .results[] |
    "\(.id)\t\(.title // "Untitled")\t\(.status)\t\(.steps | length) steps"
' | column -t | head -30

echo ""
echo "=== Connected Apps ==="
zapier_api "apps" | jq -r '.results[] | "\(.title)\t\(.status)"' | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Zap Error Summary ==="
zapier_api "zaps" | jq -r '
    .results[] |
    select(.status == "off" or .last_run_status == "error") |
    "\(.id)\t\(.title)\t\(.status)\t\(.last_run_status // "unknown")"
' | column -t

echo ""
echo "=== Task Usage ==="
zapier_api "profile" | jq '{
    tasks_used: .usage.tasks_used,
    tasks_limit: .usage.tasks_limit,
    usage_pct: ((.usage.tasks_used / .usage.tasks_limit) * 100 | floor)
}'

echo ""
echo "=== Zaps by Status ==="
zapier_api "zaps" | jq '{
    total: (.results | length),
    on: [.results[] | select(.status == "on")] | length,
    off: [.results[] | select(.status == "off")] | length,
    draft: [.results[] | select(.status == "draft")] | length
}'
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Filter Zaps by status or folder to reduce noise
- Never dump full Zap step configurations -- extract key fields

## Output Format

Present results as a structured report:
```
Managing Zapier Report
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

- **Task limits**: Zapier plans have monthly task caps -- monitor usage to avoid workflow pauses
- **Connection auth**: App connections expire -- check connection health when Zaps fail
- **Multi-step Zaps**: Each step in a multi-step Zap consumes a task -- high-step Zaps consume quotas quickly
- **Error holds**: Zaps auto-disable after repeated errors -- check held Zaps regularly
- **Webhook triggers**: Webhook-triggered Zaps can be invoked externally -- audit for security
