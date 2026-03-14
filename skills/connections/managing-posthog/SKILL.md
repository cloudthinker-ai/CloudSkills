---
name: managing-posthog
description: |
  PostHog analytics management — monitor events, feature flags, experiments, session recordings, and ingestion health. Use when reviewing event volumes, managing feature flags, debugging tracking, or inspecting experiment results.
connection_type: posthog
preload: false
---

# Managing PostHog

Manage and monitor PostHog product analytics — events, feature flags, experiments, and session recordings.

## Discovery Phase

```bash
#!/bin/bash

POSTHOG_API="${POSTHOG_HOST:-https://app.posthog.com}/api"
AUTH="Authorization: Bearer $POSTHOG_API_KEY"

echo "=== Project Info ==="
curl -s -H "$AUTH" "$POSTHOG_API/projects/@current" \
  | jq '{id: .id, name: .name, timezone: .timezone, completed_snippet_onboarding: .completed_snippet_onboarding}'

echo ""
echo "=== Event Definitions ==="
curl -s -H "$AUTH" "$POSTHOG_API/projects/@current/event_definitions?limit=20" \
  | jq -r '.results[] | [.name, .volume_30_day // 0, .query_usage_30_day // 0] | @tsv' | column -t

echo ""
echo "=== Feature Flags ==="
curl -s -H "$AUTH" "$POSTHOG_API/projects/@current/feature_flags?limit=15" \
  | jq -r '.results[] | [.id, .key, .active, .rollout_percentage // "filters"] | @tsv' | column -t

echo ""
echo "=== Experiments ==="
curl -s -H "$AUTH" "$POSTHOG_API/projects/@current/experiments?limit=10" \
  | jq -r '.results[] | [.id, .name, .start_date, .end_date // "running"] | @tsv' | column -t
```

## Analysis Phase

```bash
#!/bin/bash

POSTHOG_API="${POSTHOG_HOST:-https://app.posthog.com}/api"
AUTH="Authorization: Bearer $POSTHOG_API_KEY"

echo "=== Event Volume (Last 7 Days) ==="
curl -s -H "$AUTH" -X POST "$POSTHOG_API/projects/@current/insights/trend/" \
  -H "Content-Type: application/json" \
  -d '{"events":[{"id":"$pageview","type":"events"}],"date_from":"-7d","interval":"day"}' \
  | jq -r '.result[0].data | to_entries[] | [.key, .value] | @tsv' | column -t

echo ""
echo "=== Top Events by Volume ==="
curl -s -H "$AUTH" "$POSTHOG_API/projects/@current/event_definitions?limit=10&ordering=-volume_30_day" \
  | jq -r '.results[] | [.name, .volume_30_day] | @tsv' | column -t

echo ""
echo "=== Feature Flag Usage ==="
curl -s -H "$AUTH" "$POSTHOG_API/projects/@current/feature_flags?active=true&limit=10" \
  | jq -r '.results[] | [.key, .active, .rollout_percentage // "complex", .ensure_experience_continuity] | @tsv' | column -t

echo ""
echo "=== Session Recordings Stats ==="
curl -s -H "$AUTH" "$POSTHOG_API/projects/@current/session_recordings?limit=5&date_from=-1d" \
  | jq '{total_count: .count, recordings: [.results[:5][] | {id: .id, duration: .recording_duration, activity: .activity_score}]}'

echo ""
echo "=== Ingestion Warnings ==="
curl -s -H "$AUTH" "$POSTHOG_API/projects/@current/ingestion_warnings?limit=10" \
  | jq -r '.results[:10][] | [.type, .count, .last_seen] | @tsv' | column -t
```

## Output Format

```
PROJECT
Name:       <project-name>
Timezone:   <timezone>

TOP EVENTS (30d)
Event Name           Volume
<event-name>         <count>

FEATURE FLAGS
Key              Active  Rollout
<flag-key>       true    <percentage>

EXPERIMENTS
Name             Start        End
<exp-name>       <date>       <date|running>

INGESTION WARNINGS
Type             Count    Last Seen
<warning-type>   <n>      <timestamp>
```
