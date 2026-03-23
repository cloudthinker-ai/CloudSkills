---
name: managing-plausible
description: |
  Use when working with Plausible — plausible Analytics management — monitor
  site traffic, page views, referral sources, goals, and visitor metrics. Use
  when reviewing website analytics, inspecting traffic sources, checking goal
  conversions, or comparing time periods.
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

