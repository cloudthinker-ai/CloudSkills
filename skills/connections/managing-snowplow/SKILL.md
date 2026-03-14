---
name: managing-snowplow
description: |
  Snowplow behavioral data pipeline management — monitor collector endpoints, enrichment processes, pipeline health, schema registry, failed events, and data quality. Use when diagnosing event delivery issues, inspecting enrichment configurations, or auditing data collection pipelines.
connection_type: snowplow
preload: false
---

# Managing Snowplow

Manage and monitor Snowplow behavioral data pipelines — collectors, enrichments, schemas, and event quality.

## Discovery Phase

```bash
#!/bin/bash

SNOWPLOW_API="${SNOWPLOW_API_URL:-https://console.snowplowanalytics.com/api}"
AUTH="Authorization: Bearer $SNOWPLOW_API_TOKEN"

echo "=== Pipeline Status ==="
curl -s -H "$AUTH" "$SNOWPLOW_API/msc/v1/organizations/$SNOWPLOW_ORG_ID/pipelines" \
  | jq -r '.[] | [.id, .name, .status, .cloudProvider] | @tsv' | column -t | head -10

echo ""
echo "=== Schema Registry ==="
curl -s -H "$AUTH" "$SNOWPLOW_API/msc/v1/organizations/$SNOWPLOW_ORG_ID/registry/schemas" \
  | jq -r '.[] | [.vendor, .name, .version, .format] | @tsv' | column -t | head -15

echo ""
echo "=== Enrichments ==="
curl -s -H "$AUTH" "$SNOWPLOW_API/msc/v1/organizations/$SNOWPLOW_ORG_ID/enrichments" \
  | jq -r '.[] | [.name, .enabled, .kind] | @tsv' | column -t | head -10
```

## Analysis Phase

```bash
#!/bin/bash

SNOWPLOW_API="${SNOWPLOW_API_URL:-https://console.snowplowanalytics.com/api}"
AUTH="Authorization: Bearer $SNOWPLOW_API_TOKEN"

echo "=== Failed Events (Last 24h) ==="
curl -s -H "$AUTH" "$SNOWPLOW_API/msc/v1/organizations/$SNOWPLOW_ORG_ID/pipelines/$SNOWPLOW_PIPELINE_ID/failed-events/summary" \
  | jq -r '.failedEvents[] | [.errorType, .count, .lastSeen] | @tsv' | column -t | head -10

echo ""
echo "=== Pipeline Metrics ==="
curl -s -H "$AUTH" "$SNOWPLOW_API/msc/v1/organizations/$SNOWPLOW_ORG_ID/pipelines/$SNOWPLOW_PIPELINE_ID/metrics" \
  | jq '{eventsPerSecond: .eventsPerSecond, enrichedEvents: .enrichedEvents, failedEvents: .failedEvents}'

echo ""
echo "=== Collector Health ==="
curl -s -o /dev/null -w "HTTP Status: %{http_code}\nResponse Time: %{time_total}s\n" \
  "$SNOWPLOW_COLLECTOR_URL/health"

echo ""
echo "=== Schema Validation Errors ==="
curl -s -H "$AUTH" "$SNOWPLOW_API/msc/v1/organizations/$SNOWPLOW_ORG_ID/pipelines/$SNOWPLOW_PIPELINE_ID/failed-events?reason=SchemaViolation" \
  | jq -r '.events[:5][] | [.schema, .error, .timestamp] | @tsv' | column -t
```

## Output Format

```
PIPELINE HEALTH
Pipeline:        <name> (<status>)
Events/sec:      <rate>
Enriched (24h):  <count>
Failed (24h):    <count>

FAILED EVENTS
Error Type       Count    Last Seen
SchemaViolation  <n>      <timestamp>
EnrichmentFail   <n>      <timestamp>

SCHEMAS
Vendor           Name             Version
<vendor>         <schema-name>    <version>

ENRICHMENTS
Name             Enabled  Kind
<enrichment>     true     <type>
```
