---
name: managing-mixpanel
description: |
  Mixpanel analytics management — monitor event ingestion, user profiles, funnels, retention, and data governance. Use when reviewing event volumes, debugging tracking issues, inspecting user properties, or auditing data definitions.
connection_type: mixpanel
preload: false
---

# Managing Mixpanel

Manage and monitor Mixpanel product analytics — events, user profiles, funnels, and data governance.

## Discovery Phase

```bash
#!/bin/bash

MIXPANEL_API="https://mixpanel.com/api/2.0"
AUTH="Authorization: Basic $(echo -n "$MIXPANEL_SERVICE_ACCOUNT:$MIXPANEL_SECRET" | base64)"
PROJECT="project_id=$MIXPANEL_PROJECT_ID"

echo "=== Project Info ==="
curl -s -H "$AUTH" "https://mixpanel.com/api/app/projects/$MIXPANEL_PROJECT_ID" \
  | jq '{name: .name, id: .id, timezone: .timezone}'

echo ""
echo "=== Event Names (top events) ==="
curl -s -H "$AUTH" "$MIXPANEL_API/events/names?$PROJECT&type=general&limit=20" \
  | jq -r '.[]' | head -20

echo ""
echo "=== Custom Events ==="
curl -s -H "$AUTH" "$MIXPANEL_API/events/names?$PROJECT&type=custom&limit=10" \
  | jq -r '.[]' | head -10

echo ""
echo "=== User Profile Properties ==="
curl -s -H "$AUTH" "$MIXPANEL_API/engage/properties?$PROJECT" \
  | jq -r '.results | keys[:15][]'
```

## Analysis Phase

```bash
#!/bin/bash

MIXPANEL_API="https://mixpanel.com/api/2.0"
AUTH="Authorization: Basic $(echo -n "$MIXPANEL_SERVICE_ACCOUNT:$MIXPANEL_SECRET" | base64)"
PROJECT="project_id=$MIXPANEL_PROJECT_ID"
TODAY=$(date -u +%Y-%m-%d)
WEEK_AGO=$(date -u -v-7d +%Y-%m-%d 2>/dev/null || date -u -d '7 days ago' +%Y-%m-%d)

echo "=== Event Volume (7 days) ==="
curl -s -H "$AUTH" "$MIXPANEL_API/events?$PROJECT&event=%5B%22%24mp_anything%22%5D&type=general&unit=day&from_date=$WEEK_AGO&to_date=$TODAY" \
  | jq -r '.data.values | to_entries[] | .value | to_entries[] | [.key, .value] | @tsv' | column -t | head -10

echo ""
echo "=== Top Events by Volume ==="
curl -s -H "$AUTH" "$MIXPANEL_API/events/top?$PROJECT&type=general&limit=10" \
  | jq -r '.events[] | [.event, .amount] | @tsv' | column -t

echo ""
echo "=== Active Users (DAU/WAU) ==="
curl -s -H "$AUTH" "$MIXPANEL_API/engage/stats?$PROJECT" \
  | jq '{total_profiles: .total, active_last_7d: .active_7d, active_last_30d: .active_30d}' 2>/dev/null

echo ""
echo "=== Data Governance (Lexicon) ==="
curl -s -H "$AUTH" "https://mixpanel.com/api/app/projects/$MIXPANEL_PROJECT_ID/data-definitions/events" \
  | jq -r '.results[:10][] | [.name, .status, .tags // []] | @tsv' | column -t
```

## Output Format

```
PROJECT
Name:       <project-name>
Timezone:   <timezone>

TOP EVENTS (7d)
Event              Volume
<event-name>       <count>

ACTIVE USERS
Total Profiles:    <n>
Active (7d):       <n>
Active (30d):      <n>

DATA GOVERNANCE
Event          Status     Tags
<event-name>   <status>   <tags>
```
