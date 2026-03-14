---
name: managing-smartsheet
description: |
  Smartsheet workspace management covering sheets, reports, dashboards, rows, and collaboration analytics. Use when auditing Smartsheet usage, managing sheets and rows, analyzing project timelines, or reviewing workspace health across a Smartsheet account.
connection_type: smartsheet
preload: false
---

# Managing Smartsheet

Smartsheet workspace management and analytics via the Smartsheet REST API.

## Discovery Phase

```bash
#!/bin/bash
SS_BASE="https://api.smartsheet.com/2.0"

echo "=== Current User ==="
curl -s -H "Authorization: Bearer $SMARTSHEET_TOKEN" \
  "$SS_BASE/users/me" | jq '{id, email, firstName, lastName, admin, licensedSheetCreator}'

echo ""
echo "=== Sheets ==="
curl -s -H "Authorization: Bearer $SMARTSHEET_TOKEN" \
  "$SS_BASE/sheets?pageSize=25&includeOwnerInfo=true" \
  | jq -r '.data[] | "\(.id)\t\(.name[0:30])\t\(.accessLevel)\t\(.modifiedAt[0:10])\t\(.owner // "N/A")"' | column -t

echo ""
echo "=== Workspaces ==="
curl -s -H "Authorization: Bearer $SMARTSHEET_TOKEN" \
  "$SS_BASE/workspaces" \
  | jq -r '.data[]? | "\(.id)\t\(.name[0:30])\t\(.accessLevel)"' | column -t

echo ""
echo "=== Reports ==="
curl -s -H "Authorization: Bearer $SMARTSHEET_TOKEN" \
  "$SS_BASE/reports?pageSize=10" \
  | jq -r '.data[]? | "\(.id)\t\(.name[0:30])\t\(.modifiedAt[0:10])"' | column -t

echo ""
echo "=== Dashboards ==="
curl -s -H "Authorization: Bearer $SMARTSHEET_TOKEN" \
  "$SS_BASE/sights?pageSize=10" \
  | jq -r '.data[]? | "\(.id)\t\(.name[0:30])\t\(.modifiedAt[0:10])"' | column -t
```

## Analysis Phase

```bash
#!/bin/bash
SS_BASE="https://api.smartsheet.com/2.0"
SHEET_ID="${1:?Sheet ID required}"

echo "=== Sheet Details ==="
curl -s -H "Authorization: Bearer $SMARTSHEET_TOKEN" \
  "$SS_BASE/sheets/$SHEET_ID?pageSize=0" \
  | jq '{name, totalRowCount, accessLevel, createdAt, modifiedAt, columns: [.columns[] | {title, type, index}]}'

echo ""
echo "=== Rows (first 25) ==="
curl -s -H "Authorization: Bearer $SMARTSHEET_TOKEN" \
  "$SS_BASE/sheets/$SHEET_ID?pageSize=25" \
  | jq -r '.rows[:25][] | "\(.id)\t\(.rowNumber)\t\([.cells[:4][] | .displayValue // .value // ""] | join("\t"))"' | column -t

echo ""
echo "=== Sheet Summary ==="
curl -s -H "Authorization: Bearer $SMARTSHEET_TOKEN" \
  "$SS_BASE/sheets/$SHEET_ID/summary" \
  | jq -r '.fields[]? | "\(.title)\t\(.objectValue // .value // "empty")"' | column -t

echo ""
echo "=== Discussions ==="
curl -s -H "Authorization: Bearer $SMARTSHEET_TOKEN" \
  "$SS_BASE/sheets/$SHEET_ID/discussions?pageSize=10" \
  | jq -r '.data[]? | "\(.id)\t\(.title[0:30])\t\(.commentCount) comments\t\(.lastCommentedAt[0:10] // "N/A")"' | column -t

echo ""
echo "=== Sharing ==="
curl -s -H "Authorization: Bearer $SMARTSHEET_TOKEN" \
  "$SS_BASE/sheets/$SHEET_ID/shares" \
  | jq -r '.data[]? | "\(.email // .name)\t\(.accessLevel)\t\(.type)"' | column -t
```

## Output Format

```
SMARTSHEET WORKSPACE HEALTH
User:           [name] ([email])
Total Sheets:   [count]
Workspaces:     [count]
Reports:        [count]

SHEET HEALTH: [sheet_name]
Total Rows:     [count]
Columns:        [count]
Shared With:    [count] users
Last Modified:  [date]

SHEET SUMMARY
Field            Value
[title]          [value]
```
