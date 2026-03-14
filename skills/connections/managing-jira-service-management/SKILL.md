---
name: managing-jira-service-management
description: |
  Jira Service Management (JSM) for IT service desk operations including request queues, SLA management, automation rules, knowledge base integration, and customer portal management. Use when managing service desk queues, configuring SLA targets, building automation rules, publishing help center articles, or analyzing service desk performance metrics.
connection_type: jira-service-management
preload: false
---

# Jira Service Management Skill

Manage and analyze JSM queues, SLAs, automation rules, knowledge base, and service desk metrics.

## API Conventions

### Authentication
All API calls use Basic Auth (email + API token) or OAuth. Injected automatically.

### Base URL
`https://{{domain}}.atlassian.net/rest/servicedeskapi`

### Core Helper Function

```bash
#!/bin/bash

jsm_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    local base_url="${JIRA_URL}/rest/servicedeskapi"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -H "X-ExperimentalApi: opt-in" \
            "${base_url}${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -H "X-ExperimentalApi: opt-in" \
            "${base_url}${endpoint}"
    fi
}

jira_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
            -H "Content-Type: application/json" \
            "${JIRA_URL}/rest/api/3${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
            -H "Content-Type: application/json" \
            "${JIRA_URL}/rest/api/3${endpoint}"
    fi
}
```

## Common Operations

### Queue Management

```bash
#!/bin/bash
echo "=== Service Desks ==="
jsm_api GET "/servicedesk" \
    | jq -r '.values[] | "\(.id)\t\(.projectKey)\t\(.projectName)"' \
    | column -t

echo ""
SERVICE_DESK_ID="${1:-1}"
echo "=== Queues for Service Desk ${SERVICE_DESK_ID} ==="
jsm_api GET "/servicedesk/${SERVICE_DESK_ID}/queue" \
    | jq -r '.values[] | "\(.id)\t\(.issueCount) issues\t\(.name)"' \
    | column -t
```

### SLA Monitoring

```bash
#!/bin/bash
ISSUE_KEY="${1:?Issue key required}"
echo "=== SLA Status for ${ISSUE_KEY} ==="
jsm_api GET "/request/${ISSUE_KEY}/sla" \
    | jq -r '.values[] | "\(.name)\t\(.completedCycles[0].breached // .ongoingCycle.breached)\tremaining: \(.ongoingCycle.remainingTime.friendly // "completed")"'

echo ""
echo "=== Issues Breaching SLA ==="
jira_api GET "/search?jql=project=SD AND statusCategory!=Done AND 'Time to resolution' = breached()&maxResults=20&fields=key,summary,priority,status" \
    | jq -r '.issues[] | "\(.key)\t\(.fields.priority.name)\t\(.fields.status.name)\t\(.fields.summary[0:50])"' \
    | column -t
```

### Knowledge Base

```bash
#!/bin/bash
SERVICE_DESK_ID="${1:-1}"
echo "=== Knowledge Base Articles ==="
jsm_api GET "/servicedesk/${SERVICE_DESK_ID}/knowledgebase/article?limit=20" \
    | jq -r '.values[] | "\(.title[0:60])\t\(.source.type)"' \
    | column -t
```

### Service Desk Metrics

```bash
#!/bin/bash
echo "=== Request Types ==="
SERVICE_DESK_ID="${1:-1}"
jsm_api GET "/servicedesk/${SERVICE_DESK_ID}/requesttype" \
    | jq -r '.values[] | "\(.id)\t\(.name)\t\(.description[0:40])"' \
    | column -t

echo ""
echo "=== Open Requests by Status ==="
jira_api GET "/search?jql=project=SD AND statusCategory!=Done&maxResults=0" \
    | jq '.total'
```

## Common Pitfalls

- **Experimental API**: Many JSM endpoints require `X-ExperimentalApi: opt-in` header
- **Service Desk ID vs Project Key**: Queue operations use service desk ID, not project key
- **SLA JQL functions**: Use `breached()`, `paused()`, `running()`, `withinCalendarHours()` for SLA queries
- **Rate limits**: Atlassian Cloud enforces per-user and per-app rate limits — check `X-RateLimit-Remaining`
- **Pagination**: Use `start` and `limit` parameters — default page size varies by endpoint
- **Customer vs Agent API**: Some endpoints have separate customer-facing and agent-facing versions
- **Knowledge base**: Articles are stored in Confluence — JSM provides a proxy API
