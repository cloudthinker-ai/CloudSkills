---
name: managing-servicenow-deep
description: |
  ServiceNow ITSM platform management covering incident lifecycle, change request workflows, CMDB configuration items, knowledge base article management, and SLA tracking. Use when creating or updating incidents, querying CMDB relationships, managing change requests through approval workflows, publishing knowledge articles, or monitoring SLA compliance and breach risks.
connection_type: servicenow
preload: false
---

# ServiceNow ITSM Deep Management Skill

Manage and analyze ServiceNow incidents, changes, CMDB, knowledge base, and SLA compliance.

## API Conventions

### Authentication
All API calls use Basic Auth or OAuth token — injected automatically via `Authorization` header. Never hardcode credentials.

### Base URL
`https://{{instance}}.service-now.com/api`

### Core Helper Function

```bash
#!/bin/bash

snow_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $SERVICENOW_TOKEN" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            "${SERVICENOW_INSTANCE_URL}/api${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $SERVICENOW_TOKEN" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            "${SERVICENOW_INSTANCE_URL}/api${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target <=50 lines per script output
- Use `sysparm_fields` to limit returned columns
- Use `sysparm_query` for server-side filtering
- Never dump full API responses

## Common Operations

### Incident Management

```bash
#!/bin/bash
echo "=== Open Incidents by Priority ==="
snow_api GET "/now/table/incident?sysparm_query=active=true^ORDERBYDESCpriority&sysparm_fields=number,short_description,priority,state,assigned_to,sys_created_on&sysparm_limit=25" \
    | jq -r '.result[] | "\(.number)\t\(.priority)\t\(.state)\t\(.short_description[0:60])"' \
    | column -t

echo ""
echo "=== Incident Count by Priority ==="
for p in 1 2 3 4 5; do
    count=$(snow_api GET "/now/stats/incident?sysparm_query=active=true^priority=$p&sysparm_count=true" | jq -r '.result.stats.count')
    echo "P${p}: ${count}"
done

echo ""
echo "=== Unassigned Incidents ==="
snow_api GET "/now/table/incident?sysparm_query=active=true^assigned_toISEMPTY&sysparm_fields=number,short_description,priority,sys_created_on&sysparm_limit=10" \
    | jq -r '.result[] | "\(.number)\t\(.priority)\t\(.sys_created_on)\t\(.short_description[0:50])"' \
    | column -t
```

### Change Request Management

```bash
#!/bin/bash
echo "=== Pending Change Requests ==="
snow_api GET "/now/table/change_request?sysparm_query=approval=requested&sysparm_fields=number,short_description,type,risk,start_date,end_date&sysparm_limit=20" \
    | jq -r '.result[] | "\(.number)\t\(.type)\t\(.risk)\t\(.start_date)\t\(.short_description[0:50])"' \
    | column -t

echo ""
echo "=== Upcoming Scheduled Changes (next 7 days) ==="
snow_api GET "/now/table/change_request?sysparm_query=state=scheduled^start_dateONNext 7 days@javascript:gs.beginningOfNext7Days()@javascript:gs.endOfNext7Days()&sysparm_fields=number,short_description,start_date,end_date,assigned_to&sysparm_limit=20" \
    | jq -r '.result[] | "\(.number)\t\(.start_date)\t\(.short_description[0:50])"' \
    | column -t
```

### CMDB Queries

```bash
#!/bin/bash
echo "=== Configuration Items by Class ==="
snow_api GET "/now/table/cmdb_ci?sysparm_query=ORDERBYsys_class_name&sysparm_fields=sys_class_name&sysparm_limit=500" \
    | jq -r '.result[].sys_class_name' | sort | uniq -c | sort -rn | head -15

echo ""
echo "=== CI Relationships for a Server ==="
CI_SYS_ID="${1:?CI sys_id required}"
snow_api GET "/now/table/cmdb_rel_ci?sysparm_query=parent=${CI_SYS_ID}^ORchild=${CI_SYS_ID}&sysparm_fields=parent,child,type&sysparm_limit=25" \
    | jq -r '.result[] | "\(.type.display_value)\t\(.parent.display_value)\t->\t\(.child.display_value)"' \
    | column -t
```

### Knowledge Base Management

```bash
#!/bin/bash
echo "=== Knowledge Base Articles (recently updated) ==="
snow_api GET "/now/table/kb_knowledge?sysparm_query=workflow_state=published^ORDERBYDESCsys_updated_on&sysparm_fields=number,short_description,kb_category,sys_updated_on,view_count&sysparm_limit=20" \
    | jq -r '.result[] | "\(.number)\t\(.view_count) views\t\(.sys_updated_on[0:10])\t\(.short_description[0:50])"' \
    | column -t

echo ""
echo "=== Draft Articles Pending Review ==="
snow_api GET "/now/table/kb_knowledge?sysparm_query=workflow_state=draft&sysparm_fields=number,short_description,author,sys_created_on&sysparm_limit=15" \
    | jq -r '.result[] | "\(.number)\t\(.sys_created_on[0:10])\t\(.short_description[0:50])"' \
    | column -t
```

### SLA Tracking

```bash
#!/bin/bash
echo "=== SLA Breached or At Risk ==="
snow_api GET "/now/table/task_sla?sysparm_query=has_breached=true^ORstage=in_progress^percentage>=75&sysparm_fields=task,sla,percentage,has_breached,stage,planned_end_time&sysparm_limit=20" \
    | jq -r '.result[] | "\(.task.display_value)\t\(.sla.display_value)\t\(.percentage)%\tbreached:\(.has_breached)\t\(.planned_end_time)"' \
    | column -t

echo ""
echo "=== SLA Compliance Rate (last 30 days) ==="
TOTAL=$(snow_api GET "/now/stats/task_sla?sysparm_query=sys_created_onONLast 30 days@javascript:gs.beginningOfLast30Days()@javascript:gs.endOfLast30Days()&sysparm_count=true" | jq -r '.result.stats.count')
BREACHED=$(snow_api GET "/now/stats/task_sla?sysparm_query=has_breached=true^sys_created_onONLast 30 days@javascript:gs.beginningOfLast30Days()@javascript:gs.endOfLast30Days()&sysparm_count=true" | jq -r '.result.stats.count')
echo "Total SLAs: $TOTAL | Breached: $BREACHED | Compliance: $(echo "scale=1; (($TOTAL - $BREACHED) * 100) / $TOTAL" | bc)%"
```

## Common Pitfalls

- **Encoded queries**: ServiceNow uses encoded query strings with `^` as AND operator — always URL-encode special characters
- **sys_id references**: Related fields return sys_id by default — use `sysparm_display_value=true` to get display names
- **Pagination**: Default limit is 10000 but always set `sysparm_limit` — use `sysparm_offset` for pagination
- **Date format**: ServiceNow uses `yyyy-MM-dd HH:mm:ss` format in UTC — not ISO 8601
- **ACLs**: API results respect user ACLs — missing records may be a permissions issue, not missing data
- **Rate limits**: Respect instance rate limits — stagger bulk operations
- **Table API vs Aggregate API**: Use `/now/stats/` for counts and aggregations instead of fetching all records
