---
name: managing-smartsheet
description: |
  Use when working with Smartsheet — smartsheet workspace management covering
  sheets, reports, dashboards, rows, and collaboration analytics. Use when
  auditing Smartsheet usage, managing sheets and rows, analyzing project
  timelines, or reviewing workspace health across a Smartsheet account.
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

