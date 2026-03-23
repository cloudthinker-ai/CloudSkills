---
name: managing-tooljet
description: |
  Use when working with Tooljet — toolJet low-code platform management covering
  application inventory, datasource health, workspace organization, user
  management, and environment configuration. Use when reviewing internal tool
  setups, investigating data query failures, monitoring application versions, or
  auditing workspace access controls.
connection_type: tooljet
preload: false
---

# ToolJet Management Skill

Manage and monitor ToolJet applications, datasources, workspaces, and user access.

## MANDATORY: Discovery-First Pattern

**Always list workspaces and applications before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash

TOOLJET_API="${TOOLJET_URL}/api"

tooljet_api() {
    curl -s -H "Authorization: Bearer $TOOLJET_API_TOKEN" \
         -H "Content-Type: application/json" \
         "${TOOLJET_API}/${1}"
}

echo "=== ToolJet Organization ==="
tooljet_api "organizations" | jq -r '
    .[] |
    "\(.id)\t\(.name)\t\(.status)"
' | column -t

echo ""
echo "=== Applications ==="
tooljet_api "apps" | jq -r '
    .apps[] |
    "\(.id)\t\(.name)\t\(.is_public)\t\(.created_at[:10])"
' | column -t | head -30

echo ""
echo "=== Data Sources ==="
tooljet_api "data_sources" | jq -r '
    .data_sources[] |
    "\(.id)\t\(.name)\t\(.kind)\t\(.created_at[:10])"
' | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Application Versions ==="
tooljet_api "apps" | jq -r '.apps[].id' | head -10 | while read aid; do
    tooljet_api "apps/${aid}/versions" | jq -r --arg aid "$aid" '
        .versions[]? |
        "\($aid)\t\(.id)\t\(.name)\t\(.created_at[:10])"
    '
done | column -t | head -20

echo ""
echo "=== Users & Permissions ==="
tooljet_api "users" | jq -r '
    .users[] |
    "\(.email)\t\(.role)\t\(.status)\t\(.created_at[:10])"
' | column -t | head -20

echo ""
echo "=== Data Source Health ==="
tooljet_api "data_sources" | jq '{
    total: (.data_sources | length),
    by_type: (.data_sources | group_by(.kind) | map({type: .[0].kind, count: length}))
}'

echo ""
echo "=== Public Apps (security review) ==="
tooljet_api "apps" | jq -r '
    .apps[] |
    select(.is_public == true) |
    "\(.id)\t\(.name)\tPUBLIC"
' | column -t
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Filter apps by workspace or public/private status
- Never dump full application definitions -- extract component and query names

## Output Format

Present results as a structured report:
```
Managing Tooljet Report
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

- **Version management**: App versions must be explicitly released -- draft versions are not live
- **Data source credentials**: Credentials are encrypted -- test connectivity after changes
- **Public apps**: Public apps are accessible without login -- audit regularly for data exposure
- **Query timeouts**: Long-running data queries timeout -- check query performance
- **Environment variables**: Server-side env vars differ from workspace variables
- **Multi-workspace**: Users can belong to multiple workspaces with different roles
