---
name: managing-highlight-io
description: |
  Highlight.io full-stack observability platform for session replay, error monitoring, log management, and tracing. Covers error tracking, log querying, session analysis, trace investigation, and alert management. Use when investigating frontend errors, analyzing user sessions, searching application logs, or managing Highlight.io alert configurations.
connection_type: highlight-io
preload: false
---

# Highlight.io Monitoring Skill

Query, analyze, and manage Highlight.io observability data using the Highlight.io GraphQL API.

## API Overview

Highlight.io uses a GraphQL API at `https://pri.highlight.io`.

### Core Helper Function

```bash
#!/bin/bash

hl_gql() {
    local query="$1"
    curl -s -X POST "https://pri.highlight.io" \
        -H "Authorization: Bearer $HIGHLIGHT_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"query\": $(echo "$query" | jq -Rs .)}"
}
```

## MANDATORY: Discovery-First Pattern

**Always discover projects and resource types before querying.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Projects ==="
hl_gql '{
    projects {
        id name
    }
}' | jq -r '.data.projects[] | "\(.id)\t\(.name)"' | head -15

echo ""
echo "=== Error Groups (Recent) ==="
hl_gql '{
    error_groups(project_id: "'"$HIGHLIGHT_PROJECT_ID"'", count: 20, params: {date_range: {start_date: "'"$(date -d '24 hours ago' -Iseconds)"'", end_date: "'"$(date -Iseconds)"'"}}) {
        error_groups {
            id type event state
            structured_stack_trace { fileName lineNumber }
        }
        totalCount
    }
}' | jq -r '"Total errors: \(.data.error_groups.totalCount)\n" + (.data.error_groups.error_groups[] | "\(.id)\t\(.state)\t\(.event[0:60])")' | head -20

echo ""
echo "=== Alerts ==="
hl_gql '{
    alerts(project_id: "'"$HIGHLIGHT_PROJECT_ID"'") {
        id name type disabled
    }
}' | jq -r '.data.alerts[] | "\(.id)\t\(.disabled)\t\(.type)\t\(.name)"' | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Error Frequency (last 24h) ==="
hl_gql '{
    error_groups(project_id: "'"$HIGHLIGHT_PROJECT_ID"'", count: 15, params: {date_range: {start_date: "'"$(date -d '24 hours ago' -Iseconds)"'", end_date: "'"$(date -Iseconds)"'"}}) {
        error_groups { id event environments frequency }
    }
}' | jq -r '.data.error_groups.error_groups[] | "\(.frequency)\t\(.environments[0] // "unknown")\t\(.event[0:70])"' | sort -rn | head -15

echo ""
echo "=== Recent Logs ==="
hl_gql '{
    logs(project_id: "'"$HIGHLIGHT_PROJECT_ID"'", params: {date_range: {start_date: "'"$(date -d '1 hour ago' -Iseconds)"'", end_date: "'"$(date -Iseconds)"'"}, query: "level:error"}, count: 15) {
        edges {
            node { timestamp message level serviceName }
        }
    }
}' | jq -r '.data.logs.edges[] | "\(.node.timestamp[0:19])\t\(.node.level)\t\(.node.serviceName // "unknown")\t\(.node.message[0:60])"' | head -15

echo ""
echo "=== Session Count ==="
hl_gql '{
    sessions_count(project_id: "'"$HIGHLIGHT_PROJECT_ID"'", params: {date_range: {start_date: "'"$(date -d '24 hours ago' -Iseconds)"'", end_date: "'"$(date -Iseconds)"'"}})
}' | jq -r '"Sessions (24h): \(.data.sessions_count)"'
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines — use `count` parameter in queries and `head` in output
- Use error_groups for aggregated error views before drilling into individual errors
- Filter logs with query parameter at API level
