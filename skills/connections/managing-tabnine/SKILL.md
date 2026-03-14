---
name: managing-tabnine
description: |
  Tabnine AI coding assistant management and analytics. Covers team seat management, usage tracking, model configuration, privacy settings, code completions analytics, and enterprise deployment monitoring. Use when managing Tabnine licenses, reviewing team adoption metrics, configuring AI models, or analyzing code completion effectiveness.
connection_type: tabnine
preload: false
---

# Tabnine AI Coding Assistant Management Skill

Manage Tabnine team settings, seats, usage analytics, and privacy controls.

## Core Helper Functions

```bash
#!/bin/bash

# Tabnine API helper
tabnine_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer ${TABNINE_API_KEY}" \
            -H "Content-Type: application/json" \
            "https://api.tabnine.com/v1/${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer ${TABNINE_API_KEY}" \
            "https://api.tabnine.com/v1/${endpoint}"
    fi
}
```

## MANDATORY: Discovery-First Pattern

**Always discover team and subscription info before querying specifics.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Tabnine Team Info ==="
tabnine_api GET "team" | jq '{
    team_name: .name,
    plan: .plan,
    member_count: .member_count,
    seat_limit: .seat_limit
}'

echo ""
echo "=== Team Members ==="
tabnine_api GET "team/members?limit=30" | jq -r '
    .members[] | "\(.email)\trole=\(.role)\tstatus=\(.status)\tlast_active=\(.last_active // "never")"
' | column -t | head -20

echo ""
echo "=== Subscription ==="
tabnine_api GET "team/subscription" | jq '{
    plan: .plan,
    status: .status,
    seats_used: .seats_used,
    seats_total: .seats_total,
    billing_cycle: .billing_cycle
}'

echo ""
echo "=== Model Configuration ==="
tabnine_api GET "team/models" | jq -r '
    .models[] | "\(.name)\tstatus=\(.status)\ttype=\(.type)"
' | column -t 2>/dev/null || echo "Default model configuration"
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Usage Analytics (Last 30 Days) ==="
tabnine_api GET "team/analytics?period=30d" | jq '{
    total_completions: .total_completions,
    total_acceptances: .total_acceptances,
    acceptance_rate_pct: .acceptance_rate,
    active_users: .active_users,
    lines_of_code_generated: .lines_generated
}'

echo ""
echo "=== Language Usage ==="
tabnine_api GET "team/analytics/languages?period=30d" | jq -r '
    .[:10][] | "\(.language)\tcompletions=\(.completions)\taccepted=\(.acceptances)\trate=\(.acceptance_rate)%"
' | column -t

echo ""
echo "=== IDE Distribution ==="
tabnine_api GET "team/analytics/editors?period=30d" | jq -r '
    .[] | "\(.editor)\tusers=\(.user_count)\tcompletions=\(.completions)"
' | column -t

echo ""
echo "=== Privacy Settings ==="
tabnine_api GET "team/privacy" | jq '{
    code_storage: .code_storage_policy,
    training_opt_out: .training_opt_out,
    allowed_repos: (.allowed_repos | length),
    blocked_patterns: (.blocked_patterns | length)
}'

echo ""
echo "=== Inactive Users ==="
tabnine_api GET "team/members?limit=100" | jq '[.members[] | select(.status == "inactive" or .last_active == null)] | length' | xargs echo "Inactive/never-used seats:"
```

## Output Rules
- **TOKEN EFFICIENCY**: Target 50 lines per output
- Aggregate usage by time period, not per-completion
- Never expose individual developer ranking data

## Anti-Hallucination Rules
- NEVER guess team or member details — always query API
- NEVER fabricate usage metrics — query actual analytics
- NEVER assume model availability — check team/models endpoint

## Safety Rules
- NEVER add or remove members without explicit user confirmation
- NEVER change privacy settings without user approval
- NEVER modify model configuration without user consent
- Usage analytics are sensitive — handle with care
