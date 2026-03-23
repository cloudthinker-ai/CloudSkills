---
name: managing-pandadoc
description: |
  Use when working with Pandadoc — pandaDoc document automation platform
  management covering documents, templates, contacts, workspaces, and analytics.
  Use when monitoring document status, analyzing completion rates, reviewing
  template performance, managing PandaDoc documents and contacts, or tracking
  document workflow health.
connection_type: pandadoc
preload: false
---

# PandaDoc Management Skill

Manage and analyze PandaDoc document automation resources including documents, templates, and contacts.

## API Conventions

### Authentication
All API calls use Bearer API key or OAuth token, injected automatically.

### Base URL
`https://api.pandadoc.com/public/v1`

### Core Helper Function

```bash
#!/bin/bash

pandadoc_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: API-Key $PANDADOC_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.pandadoc.com/public/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: API-Key $PANDADOC_API_KEY" \
            "https://api.pandadoc.com/public/v1${endpoint}"
    fi
}
```

## Output Rules
- Target ≤50 lines per script output
- Use `jq` to extract only needed fields
- Never dump full API responses

## Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Recent Documents ==="
pandadoc_api GET "/documents?count=20&order_by=-date_modified" \
    | jq -r '.results[] | "\(.id[0:12])\t\(.status)\t\(.name[0:40])\t\(.date_modified[0:10])"' \
    | column -t | head -20

echo ""
echo "=== Templates ==="
pandadoc_api GET "/templates?count=20" \
    | jq -r '.results[] | "\(.id[0:12])\t\(.name[0:40])\t\(.date_modified[0:10])"' \
    | column -t | head -15

echo ""
echo "=== Contacts ==="
pandadoc_api GET "/contacts?count=15" \
    | jq -r '.results[] | "\(.id[0:12])\t\(.email)\t\(.first_name) \(.last_name)\t\(.company // "")"' \
    | column -t | head -15
```

## Phase 2: Analysis

### Document Health

```bash
#!/bin/bash
echo "=== Document Status Summary ==="
pandadoc_api GET "/documents?count=100" \
    | jq -r '.results[] | .status' | sort | uniq -c | sort -rn

echo ""
echo "=== Documents Awaiting Signature ==="
pandadoc_api GET "/documents?status=sent&count=20" \
    | jq -r '.results[] | "\(.id[0:12])\t\(.name[0:40])\t\(.date_created[0:10])\t\(.recipients | length) recipients"' \
    | head -15

echo ""
echo "=== Expired/Declined Documents ==="
pandadoc_api GET "/documents?status=declined&count=20" \
    | jq -r '.results[] | "\(.id[0:12])\t\(.name[0:40])\t\(.date_modified[0:10])"' \
    | head -10
```

### Workflow Analytics

```bash
#!/bin/bash
echo "=== Completion Rate ==="
TOTAL=$(pandadoc_api GET "/documents?count=1" | jq '.count // 0')
COMPLETED=$(pandadoc_api GET "/documents?status=completed&count=1" | jq '.count // 0')
echo "Total: $TOTAL  Completed: $COMPLETED  Rate: $(echo "scale=1; $COMPLETED * 100 / $TOTAL" | bc)%"

echo ""
echo "=== Documents Per Day (last 7 days) ==="
pandadoc_api GET "/documents?count=100&order_by=-date_created" \
    | jq -r '.results[] | .date_created[0:10]' | sort | uniq -c | sort -k2 | tail -7

echo ""
echo "=== Template Usage ==="
pandadoc_api GET "/documents?count=100" \
    | jq -r '.results[] | .template.name // "no-template"' | sort | uniq -c | sort -rn | head -10
```

## Output Format

```
=== PandaDoc Workspace ===

--- Document Summary ---
draft: <n>  sent: <n>  completed: <n>  declined: <n>
Completion Rate: <n>%

--- Awaiting Signature ---
<name>  <date>  <recipients> recipients

--- Templates ---
Total: <n>  Most Used: <template_name>
```

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
- **Status values**: `document.draft`, `document.sent`, `document.completed`, `document.viewed`, `document.waiting_approval`, `document.declined`
- **Pagination**: Use `count` and `page` parameters; check response `count` for total
- **Rate limits**: 300 requests/minute; use batch endpoints where available
- **Date format**: ISO 8601 in responses; use date range params for filtering
