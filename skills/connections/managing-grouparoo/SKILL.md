---
name: managing-grouparoo
description: |
  Grouparoo reverse ETL management — monitor apps, sources, destinations, groups, properties, and sync runs. Use when debugging data sync issues, inspecting group membership, auditing property mappings, or reviewing run status.
connection_type: grouparoo
preload: false
---

# Managing Grouparoo

Manage and monitor Grouparoo reverse ETL — apps, sources, destinations, groups, and sync runs.

## Discovery Phase

```bash
#!/bin/bash

GROUPAROO_API="${GROUPAROO_URL:-http://localhost:3000}/api/v1"
AUTH="apiKey=$GROUPAROO_API_KEY"

echo "=== Status ==="
curl -s "$GROUPAROO_API/status?$AUTH" \
  | jq '{version: .version, uptime: .uptime, workers: .workers}'

echo ""
echo "=== Apps (Connections) ==="
curl -s "$GROUPAROO_API/apps?$AUTH" \
  | jq -r '.apps[] | [.id, .name, .type, .state] | @tsv' | column -t | head -10

echo ""
echo "=== Sources ==="
curl -s "$GROUPAROO_API/sources?$AUTH" \
  | jq -r '.sources[] | [.id, .name, .type, .appId, .state] | @tsv' | column -t | head -10

echo ""
echo "=== Destinations ==="
curl -s "$GROUPAROO_API/destinations?$AUTH" \
  | jq -r '.destinations[] | [.id, .name, .type, .appId, .state] | @tsv' | column -t | head -10

echo ""
echo "=== Groups ==="
curl -s "$GROUPAROO_API/groups?$AUTH" \
  | jq -r '.groups[] | [.id, .name, .type, .matchType, .calculatedMembersCount] | @tsv' | column -t | head -10
```

## Analysis Phase

```bash
#!/bin/bash

GROUPAROO_API="${GROUPAROO_URL:-http://localhost:3000}/api/v1"
AUTH="apiKey=$GROUPAROO_API_KEY"

echo "=== Recent Runs ==="
curl -s "$GROUPAROO_API/runs?$AUTH&limit=15&order=desc" \
  | jq -r '.runs[] | [.id, .creatorType, .state, .importsCreated, .profilesCreated, .completedAt] | @tsv' | column -t

echo ""
echo "=== Failed Runs ==="
curl -s "$GROUPAROO_API/runs?$AUTH&state=failed&limit=10" \
  | jq -r '.runs[] | [.id, .creatorType, .createdAt, .error[:60]] | @tsv' | column -t

echo ""
echo "=== Properties ==="
curl -s "$GROUPAROO_API/properties?$AUTH" \
  | jq -r '.properties[] | [.id, .key, .type, .sourceId, .state] | @tsv' | column -t | head -15

echo ""
echo "=== Exports (Recent) ==="
curl -s "$GROUPAROO_API/exports?$AUTH&limit=10&order=desc" \
  | jq -r '.exports[] | [.id, .destinationId, .state, .completedAt, .errorMessage // ""] | @tsv' | column -t

echo ""
echo "=== Profile Stats ==="
curl -s "$GROUPAROO_API/profiles?$AUTH&limit=1" \
  | jq '{totalProfiles: .total}'

echo ""
echo "=== Schedules ==="
curl -s "$GROUPAROO_API/schedules?$AUTH" \
  | jq -r '.schedules[] | [.id, .sourceId, .recurring, .recurringFrequency, .state] | @tsv' | column -t | head -10
```

## Output Format

```
STATUS
Version:     <version>
Workers:     <n>

APPS
ID       Name         Type       State
<id>     <app-name>   <type>     ready

SOURCES / DESTINATIONS
ID       Name         Type       App      State
<id>     <name>       <type>     <app>    ready

GROUPS
ID       Name         Type       Match    Members
<id>     <group>      <type>     <match>  <count>

RECENT RUNS
ID       Creator      State      Imports  Profiles  Completed
<id>     <type>       complete   <n>      <n>       <timestamp>
```
