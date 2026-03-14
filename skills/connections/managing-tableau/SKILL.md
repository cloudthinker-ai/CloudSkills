---
name: managing-tableau
description: |
  Tableau Server/Cloud management — monitor sites, workbooks, data sources, extract refresh jobs, and user activity. Use when reviewing dashboard health, inspecting failed extracts, auditing permissions, or checking server utilization.
connection_type: tableau
preload: false
---

# Managing Tableau

Manage and monitor Tableau Server/Cloud — workbooks, data sources, extract refreshes, and site administration.

## Discovery Phase

```bash
#!/bin/bash

TABLEAU_API="$TABLEAU_SERVER_URL/api/3.21"

# Authenticate
TOKEN=$(curl -s -X POST "$TABLEAU_API/auth/signin" \
  -H "Content-Type: application/json" \
  -d "{\"credentials\":{\"personalAccessTokenName\":\"$TABLEAU_TOKEN_NAME\",\"personalAccessTokenSecret\":\"$TABLEAU_TOKEN_SECRET\",\"site\":{\"contentUrl\":\"$TABLEAU_SITE_ID\"}}}" \
  | jq -r '.credentials.token')
SITE_ID=$(curl -s -X POST "$TABLEAU_API/auth/signin" \
  -H "Content-Type: application/json" \
  -d "{\"credentials\":{\"personalAccessTokenName\":\"$TABLEAU_TOKEN_NAME\",\"personalAccessTokenSecret\":\"$TABLEAU_TOKEN_SECRET\",\"site\":{\"contentUrl\":\"$TABLEAU_SITE_ID\"}}}" \
  | jq -r '.credentials.site.id')
AUTH="X-Tableau-Auth: $TOKEN"

echo "=== Site Info ==="
curl -s -H "$AUTH" "$TABLEAU_API/sites/$SITE_ID" \
  | jq '{name: .site.name, state: .site.state, contentUrl: .site.contentUrl}'

echo ""
echo "=== Workbooks ==="
curl -s -H "$AUTH" "$TABLEAU_API/sites/$SITE_ID/workbooks?pageSize=15" \
  | jq -r '.workbooks.workbook[] | [.id, .name, .project.name, .updatedAt] | @tsv' | column -t

echo ""
echo "=== Data Sources ==="
curl -s -H "$AUTH" "$TABLEAU_API/sites/$SITE_ID/datasources?pageSize=15" \
  | jq -r '.datasources.datasource[] | [.id, .name, .type, .updatedAt] | @tsv' | column -t

echo ""
echo "=== Projects ==="
curl -s -H "$AUTH" "$TABLEAU_API/sites/$SITE_ID/projects?pageSize=15" \
  | jq -r '.projects.project[] | [.id, .name, .contentPermissions] | @tsv' | column -t
```

## Analysis Phase

```bash
#!/bin/bash

TABLEAU_API="$TABLEAU_SERVER_URL/api/3.21"
# Re-use TOKEN and SITE_ID from discovery
AUTH="X-Tableau-Auth: $TOKEN"

echo "=== Extract Refresh Tasks ==="
curl -s -H "$AUTH" "$TABLEAU_API/sites/$SITE_ID/tasks/extractRefreshes?pageSize=15" \
  | jq -r '.tasks.task[] | [.extractRefresh.id, .extractRefresh.type, .extractRefresh.datasource.name // .extractRefresh.workbook.name, .schedule.name] | @tsv' | column -t

echo ""
echo "=== Recent Jobs (last 24h) ==="
curl -s -H "$AUTH" "$TABLEAU_API/sites/$SITE_ID/jobs?pageSize=15" \
  | jq -r '.backgroundJobs.backgroundJob[] | [.id, .jobType, .status, .completedAt // "running", .progress] | @tsv' | column -t | head -15

echo ""
echo "=== Failed Jobs ==="
curl -s -H "$AUTH" "$TABLEAU_API/sites/$SITE_ID/jobs?filter=status:eq:Failed&pageSize=10" \
  | jq -r '.backgroundJobs.backgroundJob[] | [.id, .jobType, .createdAt, .statusNotes[:60]] | @tsv' | column -t

echo ""
echo "=== Users ==="
curl -s -H "$AUTH" "$TABLEAU_API/sites/$SITE_ID/users?pageSize=15" \
  | jq -r '.users.user[] | [.id, .name, .siteRole, .lastLogin] | @tsv' | column -t

echo ""
echo "=== Schedules ==="
curl -s -H "$AUTH" "$TABLEAU_API/sites/$SITE_ID/schedules?pageSize=10" \
  | jq -r '.schedules.schedule[] | [.name, .type, .frequency, .state, .nextRunAt] | @tsv' | column -t
```

## Output Format

```
SITE
Name:       <site-name>
State:      <state>

WORKBOOKS
ID       Name             Project         Updated
<id>     <workbook-name>  <project-name>  <timestamp>

DATA SOURCES
ID       Name             Type       Updated
<id>     <ds-name>        <type>     <timestamp>

FAILED JOBS
ID       Job Type         Created         Error
<id>     <type>           <timestamp>     <message>

EXTRACT REFRESHES
ID       Type      Source           Schedule
<id>     <type>    <source-name>    <schedule>
```
