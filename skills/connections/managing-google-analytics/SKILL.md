---
name: managing-google-analytics
description: |
  Google Analytics 4 management — monitor property configuration, event streams, user metrics, conversions, and audience data. Use when reviewing traffic trends, inspecting event setup, auditing conversion goals, or analyzing user acquisition.
connection_type: google-analytics
preload: false
---

# Managing Google Analytics

Manage and monitor Google Analytics 4 — properties, data streams, events, conversions, and user metrics.

## Discovery Phase

```bash
#!/bin/bash

GA_API="https://analyticsadmin.googleapis.com/v1beta"
GA_DATA="https://analyticsdata.googleapis.com/v1beta"
AUTH="Authorization: Bearer $(gcloud auth print-access-token)"

echo "=== Account Summary ==="
curl -s -H "$AUTH" "$GA_API/accountSummaries" \
  | jq -r '.accountSummaries[] | .propertySummaries[] | [.property, .displayName] | @tsv' | column -t | head -10

echo ""
echo "=== Property Details ==="
curl -s -H "$AUTH" "$GA_API/properties/$GA_PROPERTY_ID" \
  | jq '{displayName: .displayName, timeZone: .timeZone, currencyCode: .currencyCode, industryCategory: .industryCategory}'

echo ""
echo "=== Data Streams ==="
curl -s -H "$AUTH" "$GA_API/properties/$GA_PROPERTY_ID/dataStreams" \
  | jq -r '.dataStreams[] | [.name, .type, .displayName, .webStreamData.defaultUri // .androidAppStreamData.packageName // "N/A"] | @tsv' | column -t | head -10

echo ""
echo "=== Conversion Events ==="
curl -s -H "$AUTH" "$GA_API/properties/$GA_PROPERTY_ID/conversionEvents" \
  | jq -r '.conversionEvents[] | [.eventName, .createTime, .deletable] | @tsv' | column -t | head -10
```

## Analysis Phase

```bash
#!/bin/bash

GA_DATA="https://analyticsdata.googleapis.com/v1beta"
AUTH="Authorization: Bearer $(gcloud auth print-access-token)"

echo "=== Active Users & Sessions (7 days) ==="
curl -s -H "$AUTH" -X POST "$GA_DATA/properties/$GA_PROPERTY_ID:runReport" \
  -H "Content-Type: application/json" \
  -d '{
    "dateRanges": [{"startDate": "7daysAgo", "endDate": "today"}],
    "dimensions": [{"name": "date"}],
    "metrics": [{"name": "activeUsers"}, {"name": "sessions"}, {"name": "screenPageViews"}],
    "orderBys": [{"dimension": {"dimensionName": "date"}}]
  }' | jq -r '.rows[] | [.dimensionValues[0].value, .metricValues[0].value, .metricValues[1].value, .metricValues[2].value] | @tsv' | column -t

echo ""
echo "=== Top Pages (30 days) ==="
curl -s -H "$AUTH" -X POST "$GA_DATA/properties/$GA_PROPERTY_ID:runReport" \
  -H "Content-Type: application/json" \
  -d '{
    "dateRanges": [{"startDate": "30daysAgo", "endDate": "today"}],
    "dimensions": [{"name": "pagePath"}],
    "metrics": [{"name": "screenPageViews"}, {"name": "activeUsers"}],
    "orderBys": [{"metric": {"metricName": "screenPageViews"}, "desc": true}],
    "limit": 10
  }' | jq -r '.rows[] | [.dimensionValues[0].value, .metricValues[0].value, .metricValues[1].value] | @tsv' | column -t

echo ""
echo "=== Traffic Sources ==="
curl -s -H "$AUTH" -X POST "$GA_DATA/properties/$GA_PROPERTY_ID:runReport" \
  -H "Content-Type: application/json" \
  -d '{
    "dateRanges": [{"startDate": "30daysAgo", "endDate": "today"}],
    "dimensions": [{"name": "sessionSource"}],
    "metrics": [{"name": "sessions"}, {"name": "activeUsers"}, {"name": "bounceRate"}],
    "orderBys": [{"metric": {"metricName": "sessions"}, "desc": true}],
    "limit": 10
  }' | jq -r '.rows[] | [.dimensionValues[0].value, .metricValues[0].value, .metricValues[1].value, .metricValues[2].value] | @tsv' | column -t

echo ""
echo "=== Realtime ==="
curl -s -H "$AUTH" -X POST "$GA_DATA/properties/$GA_PROPERTY_ID:runRealtimeReport" \
  -H "Content-Type: application/json" \
  -d '{"metrics": [{"name": "activeUsers"}]}' \
  | jq '{activeUsersNow: .rows[0].metricValues[0].value}'
```

## Output Format

```
PROPERTY
Name:       <property-name>
Timezone:   <timezone>
Currency:   <currency>

DAILY METRICS (7d)
Date          Users    Sessions   Pageviews
<date>        <n>      <n>        <n>

TOP PAGES (30d)
Page Path            Pageviews   Users
<path>               <n>         <n>

TRAFFIC SOURCES (30d)
Source               Sessions   Users    Bounce Rate
<source>             <n>        <n>      <pct>

REALTIME
Active Users Now:    <n>
```
