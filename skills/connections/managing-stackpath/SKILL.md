---
name: managing-stackpath
description: |
  Use when working with Stackpath — stackPath CDN management covering sites, CDN
  scopes, edge rules, WAF configuration, SSL certificates, and analytics. Use
  when managing StackPath CDN delivery, analyzing cache performance and
  bandwidth, configuring edge rules, managing WAF policies, or troubleshooting
  content delivery issues.
connection_type: stackpath
preload: false
---

# StackPath CDN Skill

Manage StackPath CDN sites, edge rules, WAF, SSL, and delivery analytics.

## Core Helper Functions

```bash
#!/bin/bash

SP_API="https://gateway.stackpath.com"

# Get OAuth token
sp_token() {
    curl -s -X POST "$SP_API/identity/v1/oauth2/token" \
        -H "Content-Type: application/json" \
        -d "{\"client_id\":\"$STACKPATH_CLIENT_ID\",\"client_secret\":\"$STACKPATH_CLIENT_SECRET\",\"grant_type\":\"client_credentials\"}" \
        | jq -r '.access_token'
}

# StackPath API wrapper
sp_api() {
    local endpoint="$1"
    shift
    curl -s -H "Authorization: Bearer $(sp_token)" \
         -H "Content-Type: application/json" \
         "$SP_API/$endpoint" "$@"
}
```

## MANDATORY: Discovery-First Pattern

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Stacks ==="
sp_api "stack/v1/stacks" | jq -r '
    .results[] | "\(.id)\t\(.name)\t\(.status)\t\(.accountId)"
' | column -t | head -15

STACK_ID=$(sp_api "stack/v1/stacks" | jq -r '.results[0].id')

echo ""
echo "=== CDN Sites ==="
sp_api "cdn/v1/stacks/$STACK_ID/sites" | jq -r '
    .results[] | "\(.id)\t\(.label)\t\(.status)\t\(.features | join(","))"
' | column -t | head -20

echo ""
echo "=== SSL Certificates ==="
sp_api "ssl/v1/stacks/$STACK_ID/certificates" | jq -r '
    .results[] | "\(.id[:12])\t\(.commonName)\t\(.status)\t\(.expiresAt[:10])"
' | column -t | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash
STACK_ID="${1:?Stack ID required}"
SITE_ID="${2:?Site ID required}"

echo "=== Site Configuration ==="
sp_api "cdn/v1/stacks/$STACK_ID/sites/$SITE_ID" | jq '{
    label, status, features,
    origin: .origin,
    cachePolicy: .configuration.cachePolicy,
    dynamicCaching: .configuration.dynamicCaching
}'

echo ""
echo "=== Edge Rules ==="
sp_api "cdn/v1/stacks/$STACK_ID/sites/$SITE_ID/rules" | jq -r '
    .results[] | "\(.id[:12])\t\(.name)\t\(.enabled)\t\(.matchType)\t\(.actions | length) actions"
' | column -t | head -15

echo ""
echo "=== WAF Policies ==="
sp_api "waf/v1/stacks/$STACK_ID/sites/$SITE_ID/policies" | jq -r '
    .results[]? | "\(.id[:12])\t\(.name)\t\(.enabled)\t\(.action)"
' | column -t | head -10

echo ""
echo "=== Traffic Metrics ==="
sp_api "cdn/v1/stacks/$STACK_ID/sites/$SITE_ID/metrics?start_date=$(date -u -d '7 days ago' +%Y-%m-%d 2>/dev/null || date -u -v-7d +%Y-%m-%d)&granularity=P1D" | jq -r '
    .series[]? | "\(.key)\t\(.values | map(tonumber) | add | round)"
' | column -t | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use jq to parse StackPath API JSON responses
- OAuth token must be refreshed -- cache when possible

## Safety Rules
- **Read-only by default**: Use GET endpoints for inspection
- **Never purge CDN cache** without explicit confirmation
- **WAF rule changes** take effect immediately at the edge
- **Edge rules** are evaluated in order -- changing order affects behavior

## Output Format

Present results as a structured report:
```
Managing Stackpath Report
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
- **OAuth tokens expire**: Tokens are valid for 1 hour; refresh before long operations
- **Stack vs Site**: Resources are scoped to stacks, then sites within stacks
- **WAF false positives**: Review WAF event logs before enabling strict policies
- **CDN features vary by plan**: Some features require higher-tier plans
- **Purge propagation**: Takes up to 60 seconds across all POPs
