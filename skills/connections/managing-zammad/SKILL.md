---
name: managing-zammad
description: |
  Use when working with Zammad — zammad helpdesk platform management covering
  ticket operations, knowledge base article publishing, and reporting
  dashboards. Use when creating and managing support tickets with tags and
  custom attributes, building and organizing knowledge base content for end-user
  self-service, or analyzing ticket metrics including first response times,
  resolution rates, and agent workload.
connection_type: zammad
preload: false
---

# Zammad Helpdesk Management Skill

Manage and analyze Zammad tickets, knowledge base, and reporting.

## API Conventions

### Authentication
All API calls use Bearer token or token-based auth — injected automatically.

### Base URL
`https://{{instance}}.zammad.com/api/v1`

### Core Helper Function

```bash
#!/bin/bash

zammad_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $ZAMMAD_TOKEN" \
            -H "Content-Type: application/json" \
            "${ZAMMAD_URL}/api/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $ZAMMAD_TOKEN" \
            -H "Content-Type: application/json" \
            "${ZAMMAD_URL}/api/v1${endpoint}"
    fi
}
```

## Common Operations

### Ticket Management

```bash
#!/bin/bash
echo "=== Open Tickets ==="
zammad_api GET "/tickets/search?query=state:(new OR open)&limit=25&sort_by=priority_id&order_by=asc" \
    | jq -r '.[] | "\(.number)\tP\(.priority_id)\t\(.state)\t\(.title[0:60])"' \
    | column -t

echo ""
echo "=== Ticket Stats by Group ==="
zammad_api GET "/tickets/search?query=state:(new OR open)&limit=200" \
    | jq -r '[.[].group] | group_by(.) | map({group: .[0], count: length}) | sort_by(.count) | reverse | .[] | "\(.group): \(.count)"'

echo ""
echo "=== Recently Updated ==="
zammad_api GET "/tickets/search?query=state:(new OR open)&sort_by=updated_at&order_by=desc&limit=15" \
    | jq -r '.[] | "\(.number)\t\(.updated_at[0:16])\t\(.title[0:50])"' \
    | column -t
```

### Knowledge Base

```bash
#!/bin/bash
echo "=== Knowledge Base Categories ==="
zammad_api GET "/knowledge_bases/1/categories" \
    | jq -r '.[] | "\(.id)\t\(.translation_ids | length) articles\t\(.translations[0].title // .id)"'

echo ""
echo "=== Recent KB Articles ==="
zammad_api GET "/knowledge_bases/1/answers?limit=20&sort_by=updated_at&order_by=desc" \
    | jq -r '.[] | "\(.id)\t\(.updated_at[0:10])\t\(.translations[0].title[0:60] // "-")"' \
    | column -t
```

### Reporting

```bash
#!/bin/bash
echo "=== Ticket Overview ==="
zammad_api GET "/ticket_overview" \
    | jq -r '.[] | "\(.name)\t\(.count // 0) tickets\t\(.view)"'

echo ""
echo "=== Agent Workload ==="
zammad_api GET "/tickets/search?query=state:(new OR open)&limit=200" \
    | jq -r '[.[].owner_id] | group_by(.) | map({owner_id: .[0], count: length}) | sort_by(.count) | reverse | .[:10] | .[] | "Agent \(.owner_id): \(.count) tickets"'
```

## Output Format

Present results as a structured report:
```
Managing Zammad Report
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

- **Search syntax**: Uses Elasticsearch query syntax — `state:(new OR open)`, `group.name:"IT Support"`
- **Translations**: Knowledge base content uses translation layer — access via `.translations[0]` for default language
- **Pagination**: Use `page` and `per_page` parameters — max 500 per page
- **Rate limits**: No built-in rate limiting by default — but reverse proxy may enforce limits
- **Token types**: API tokens and OAuth tokens have different scopes — ensure correct token type
- **Ticket states**: States include `new`, `open`, `pending reminder`, `pending close`, `closed` — use exact names
- **Assets endpoint**: Bulk ticket responses include `assets` object with related users, groups, organizations
