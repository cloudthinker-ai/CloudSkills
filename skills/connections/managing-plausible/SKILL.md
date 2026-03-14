---
name: managing-plausible
description: |
  Plausible Analytics management — monitor site traffic, page views, referral sources, goals, and visitor metrics. Use when reviewing website analytics, inspecting traffic sources, checking goal conversions, or comparing time periods.
connection_type: plausible
preload: false
---

# Managing Plausible

Manage and monitor Plausible Analytics — site traffic, pages, referrers, goals, and visitor metrics.

## Discovery Phase

```bash
#!/bin/bash

PLAUSIBLE_API="${PLAUSIBLE_HOST:-https://plausible.io}/api/v1"
AUTH="Authorization: Bearer $PLAUSIBLE_API_KEY"

echo "=== Sites ==="
curl -s -H "$AUTH" "$PLAUSIBLE_API/sites" \
  | jq -r '.sites[] | [.domain, .timezone] | @tsv' | column -t | head -10

echo ""
echo "=== Site Info ==="
curl -s -H "$AUTH" "$PLAUSIBLE_API/sites/$PLAUSIBLE_SITE_ID" \
  | jq '{domain: .domain, timezone: .timezone}'

echo ""
echo "=== Goals ==="
curl -s -H "$AUTH" "$PLAUSIBLE_API/sites/goals?site_id=$PLAUSIBLE_SITE_ID" \
  | jq -r '.goals[] | [.id, .goal_type, .event_name // .page_path] | @tsv' | column -t | head -10

echo ""
echo "=== Realtime Visitors ==="
curl -s -H "$AUTH" "$PLAUSIBLE_API/stats/realtime/visitors?site_id=$PLAUSIBLE_SITE_ID"
```

## Analysis Phase

```bash
#!/bin/bash

PLAUSIBLE_API="${PLAUSIBLE_HOST:-https://plausible.io}/api/v1"
AUTH="Authorization: Bearer $PLAUSIBLE_API_KEY"
SITE="site_id=$PLAUSIBLE_SITE_ID"

echo "=== Aggregate Stats (30 days) ==="
curl -s -H "$AUTH" "$PLAUSIBLE_API/stats/aggregate?$SITE&period=30d&metrics=visitors,pageviews,bounce_rate,visit_duration,visits" \
  | jq '.results | {visitors: .visitors.value, pageviews: .pageviews.value, bounce_rate: .bounce_rate.value, avg_visit_duration: .visit_duration.value, visits: .visits.value}'

echo ""
echo "=== Top Pages (30 days) ==="
curl -s -H "$AUTH" "$PLAUSIBLE_API/stats/breakdown?$SITE&period=30d&property=event:page&limit=10&metrics=visitors,pageviews" \
  | jq -r '.results[] | [.page, .visitors, .pageviews] | @tsv' | column -t

echo ""
echo "=== Top Sources (30 days) ==="
curl -s -H "$AUTH" "$PLAUSIBLE_API/stats/breakdown?$SITE&period=30d&property=visit:source&limit=10&metrics=visitors,bounce_rate" \
  | jq -r '.results[] | [.source, .visitors, .bounce_rate] | @tsv' | column -t

echo ""
echo "=== Goal Conversions ==="
curl -s -H "$AUTH" "$PLAUSIBLE_API/stats/breakdown?$SITE&period=30d&property=event:goal&metrics=visitors,events" \
  | jq -r '.results[] | [.goal, .visitors, .events] | @tsv' | column -t | head -10

echo ""
echo "=== Traffic by Country ==="
curl -s -H "$AUTH" "$PLAUSIBLE_API/stats/breakdown?$SITE&period=30d&property=visit:country&limit=10&metrics=visitors" \
  | jq -r '.results[] | [.country, .visitors] | @tsv' | column -t
```

## Output Format

```
AGGREGATE (30d)
Visitors:           <n>
Pageviews:          <n>
Bounce Rate:        <pct>%
Avg Visit Duration: <seconds>s

TOP PAGES
Page                 Visitors    Pageviews
<path>               <n>         <n>

TOP SOURCES
Source               Visitors    Bounce Rate
<source>             <n>         <pct>%

GOAL CONVERSIONS
Goal                 Visitors    Events
<goal>               <n>         <n>
```
