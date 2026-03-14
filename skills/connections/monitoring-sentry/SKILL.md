---
name: monitoring-sentry
description: |
  Sentry error tracking, performance monitoring, release health, and issue management. Covers error investigation, stack trace analysis, release comparison, performance transaction monitoring, alert rule management, and issue triage workflows. Use when investigating application errors, analyzing crash rates, reviewing release health, or managing Sentry projects.
connection_type: sentry
preload: false
---

# Sentry Monitoring Skill

Investigate errors, monitor performance, and manage issues in Sentry.

## MANDATORY: Discovery-First Pattern

**Always discover organizations, projects, and issue IDs before querying specifics.**

### Phase 1: Discovery

```bash
#!/bin/bash

sentry_api() {
    local endpoint="$1"
    curl -s -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" \
         "https://sentry.io/api/0/${endpoint}"
}

echo "=== Organizations ==="
sentry_api "organizations/" | jq -r '.[] | "\(.slug)\t\(.name)\t\(.features | length) features"' | column -t

echo ""
echo "=== Projects ==="
sentry_api "organizations/${SENTRY_ORG:-your-org}/projects/" \
    | jq -r '.[] | "\(.slug)\t\(.platform // "unknown")\t\(.status)"' | column -t

echo ""
echo "=== Teams ==="
sentry_api "organizations/${SENTRY_ORG:-your-org}/teams/" \
    | jq -r '.[] | "\(.slug)\t\(.name)\t\(.memberCount) members"' | column -t
```

## Core Helper Function

```bash
#!/bin/bash

sentry_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" \
            -H "Content-Type: application/json" \
            "https://sentry.io/api/0/${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" \
            "https://sentry.io/api/0/${endpoint}"
    fi
}

ORG="${SENTRY_ORG}"
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines — use `jq` to extract key fields only
- Always filter by project/time range to scope results
- Truncate stack traces to first 5 frames for agent parsing

## Common Operations

### Error Issue Overview

```bash
#!/bin/bash
ORG="$SENTRY_ORG"
PROJECT="${1:-}"
DAYS="${2:-7}"

QUERY_PARAMS="query=is:unresolved&limit=25&statsPeriod=${DAYS}d&sort=freq"
[ -n "$PROJECT" ] && QUERY_PARAMS="${QUERY_PARAMS}&project=${PROJECT}"

echo "=== Top Unresolved Issues ($DAYS days) ==="
sentry_api GET "organizations/${ORG}/issues/?${QUERY_PARAMS}" \
    | jq -r '.[] | "\(.count)\t\(.level)\t\(.title[0:60])\t\(.project.slug)"' \
    | sort -rn | column -t | head -20

echo ""
echo "=== Issues by Level ==="
sentry_api GET "organizations/${ORG}/issues/?query=is:unresolved&limit=100&statsPeriod=${DAYS}d" \
    | jq -r '.[].level' | sort | uniq -c | sort -rn

echo ""
echo "=== New Issues This Week ==="
sentry_api GET "organizations/${ORG}/issues/?query=is:unresolved age:-7d&limit=20&sort=date" \
    | jq -r '.[] | "\(.firstSeen[0:16])\t\(.level)\t\(.title[0:60])"' | column -t | head -15
```

### Issue Detail Investigation

```bash
#!/bin/bash
ISSUE_ID="${1:?Issue ID required}"

echo "=== Issue Details ==="
sentry_api GET "issues/${ISSUE_ID}/" | jq '{
    id: .id,
    title: .title,
    culprit: .culprit,
    level: .level,
    status: .status,
    count: .count,
    userCount: .userCount,
    firstSeen: .firstSeen,
    lastSeen: .lastSeen,
    project: .project.slug,
    assignee: .assignedTo.name
}'

echo ""
echo "=== Latest Event Stack Trace ==="
sentry_api GET "issues/${ISSUE_ID}/events/latest/" \
    | jq -r '
        .entries[] |
        select(.type == "exception") |
        .data.values[] |
        "\(.type): \(.value)\n" +
        (.stacktrace.frames[-5:] | reverse | .[] | "  \(.filename):\(.lineno) in \(.function)")
    ' 2>/dev/null | head -30

echo ""
echo "=== Affected Users ==="
sentry_api GET "issues/${ISSUE_ID}/tags/user/" \
    | jq -r '.topValues[:10][] | "\(.count)\t\(.name)"' | sort -rn | column -t
```

### Release Health Analysis

```bash
#!/bin/bash
ORG="$SENTRY_ORG"
PROJECT="${1:?Project slug required}"

echo "=== Recent Releases ==="
sentry_api GET "organizations/${ORG}/releases/?project=${PROJECT}&limit=10" \
    | jq -r '.[] | "\(.version[0:20])\t\(.dateCreated[0:16])\t\(.newGroups) new issues\t\(.healthData.stats // "N/A")"' \
    | column -t

echo ""
echo "=== Release Crash Rate Comparison ==="
sentry_api GET "organizations/${ORG}/releases/?project=${PROJECT}&limit=5" \
    | jq -r '
        .[] |
        "\(.version[0:20]): sessions=\(.totalSessions // 0) crashRate=\(.crashFreeRate // "N/A")"
    ' | head -10

echo ""
echo "=== Issues Introduced in Latest Release ==="
LATEST=$(sentry_api GET "organizations/${ORG}/releases/?project=${PROJECT}&limit=1" | jq -r '.[0].version')
echo "Release: $LATEST"
sentry_api GET "organizations/${ORG}/issues/?query=is:unresolved firstRelease:${LATEST}&limit=15" \
    | jq -r '.[] | "\(.level)\t\(.count)\t\(.title[0:60])"' | column -t
```

### Performance Monitoring

```bash
#!/bin/bash
ORG="$SENTRY_ORG"
PROJECT="${1:?Project slug required}"

echo "=== Transaction Performance (P95) ==="
sentry_api GET "organizations/${ORG}/events/?project=${PROJECT}&field=transaction&field=p95()&field=count()&sort=-p95()&statsPeriod=24h&per_page=15" \
    | jq -r '.data[] | "\(.transaction[0:50])\t\(."p95()" | . * 10 | round / 10)ms\t\(."count()" | tostring) reqs"' \
    | column -t | head -15

echo ""
echo "=== Slowest Transactions ==="
sentry_api GET "organizations/${ORG}/events/?field=transaction&field=p99()&field=count()&sort=-p99()&statsPeriod=24h&per_page=10" \
    | jq -r '.data[] | "\(.transaction[0:50])\tP99:\(."p99()" | . * 10 | round / 10)ms"' \
    | column -t | head -10

echo ""
echo "=== Throughput Trend ==="
sentry_api GET "organizations/${ORG}/events-stats/?project=${PROJECT}&field=count()&statsPeriod=24h&interval=1h" \
    | jq -r '.data[] | "\(.[0] | strftime("%H:00"))\t\(.[1][0].count)"' | head -24
```

### Alert Rules Management

```bash
#!/bin/bash
ORG="$SENTRY_ORG"
PROJECT="${1:?Project slug required}"

echo "=== Alert Rules ==="
sentry_api GET "projects/${ORG}/${PROJECT}/alert-rules/" \
    | jq -r '.[] | "\(.name)\t\(.status)\t\(.triggers | length) triggers"' | column -t

echo ""
echo "=== Recent Alert Incidents ==="
sentry_api GET "organizations/${ORG}/incidents/?project=${PROJECT}&limit=10" \
    | jq -r '.[] | "\(.dateStarted[0:16])\t\(.status)\t\(.title)"' | column -t | head -10
```

### Issue Assignment & Triage

```bash
#!/bin/bash
ORG="$SENTRY_ORG"

echo "=== Unassigned High-Priority Issues ==="
sentry_api GET "organizations/${ORG}/issues/?query=is:unresolved !has:assignee level:error&limit=20&sort=freq" \
    | jq -r '.[] | "\(.count)\t\(.project.slug)\t\(.title[0:60])"' \
    | sort -rn | column -t | head -15

echo ""
echo "=== Issues Assigned to Me ==="
sentry_api GET "organizations/${ORG}/issues/?query=is:unresolved assigned:me&limit=20" \
    | jq -r '.[] | "\(.status)\t\(.level)\t\(.title[0:60])"' | column -t | head -10

echo ""
echo "=== Regression Issues ==="
sentry_api GET "organizations/${ORG}/issues/?query=is:regression&limit=15&statsPeriod=7d" \
    | jq -r '.[] | "\(.count)\t\(.level)\t\(.title[0:60])"' | sort -rn | column -t | head -10
```

### Error Rate Trending

```bash
#!/bin/bash
ORG="$SENTRY_ORG"
PROJECT="${1:?Project slug required}"

echo "=== Error Rate Trend (last 7 days, hourly) ==="
sentry_api GET "organizations/${ORG}/events-stats/?project=${PROJECT}&query=level:error&statsPeriod=7d&interval=6h" \
    | jq -r '.data[] | "\(.[0] | strftime("%Y-%m-%d %H:%M"))\t\(.[1][0].count)"' | tail -28

echo ""
echo "=== Error Breakdown by Platform ==="
sentry_api GET "organizations/${ORG}/issues/?query=is:unresolved&limit=100&statsPeriod=7d" \
    | jq -r '.[].project.platform // "unknown"' | sort | uniq -c | sort -rn | head -10
```

## Common Pitfalls

- **Issue ID vs Group ID**: Sentry uses numeric IDs for issues — always fetch via `/issues/<id>/` after discovering from list
- **Rate limits**: Sentry API is rate-limited — add `sleep 0.2` between batch requests
- **Project vs Organization scopes**: Some endpoints require `project_slug`, others require `org_slug` — check carefully
- **`statsPeriod` format**: Uses `7d`, `24h`, `1h` format — not ISO dates for most endpoints
- **Pagination**: Use `cursor` header for next page — check `Link` response header
- **Event vs Issue**: Issues aggregate events — use `/issues/<id>/events/` to see individual occurrences
- **Stack trace depth**: Full stack traces can be thousands of lines — always use `[-5:]` to get most recent frames
- **Self-hosted vs Sentry.io**: Self-hosted uses your domain instead of `sentry.io` — adjust base URL accordingly
- **Performance data**: Only available if Sentry Performance is enabled and SDK is instrumented with transactions
