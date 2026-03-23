---
name: managing-teamwork
description: |
  Use when working with Teamwork — teamwork project management covering
  projects, task lists, milestones, time tracking, and team workload. Use when
  auditing Teamwork usage, managing tasks and milestones, analyzing time
  entries, or reviewing project health across a Teamwork instance.
connection_type: teamwork
preload: false
---

# Managing Teamwork

Teamwork project management analysis via the Teamwork REST API.

## Discovery Phase

```bash
#!/bin/bash
TW_BASE="https://$TEAMWORK_DOMAIN.teamwork.com"

echo "=== Current User ==="
curl -s -u "$TEAMWORK_API_KEY:x" \
  "$TW_BASE/me.json" | jq '.person | {id, "first-name", "last-name", "email-address", administrator}'

echo ""
echo "=== Projects ==="
curl -s -u "$TEAMWORK_API_KEY:x" \
  "$TW_BASE/projects.json?status=active&pageSize=25" \
  | jq -r '.projects[] | "\(.id)\t\(.name[0:30])\t\(.status)\t\(.company.name // "N/A")\t\(.last-changed-on[0:10])"' | column -t

echo ""
echo "=== Companies ==="
curl -s -u "$TEAMWORK_API_KEY:x" \
  "$TW_BASE/companies.json" \
  | jq -r '.companies[] | "\(.id)\t\(.name)\t\(.people-count // 0) people"' | column -t

echo ""
echo "=== People ==="
curl -s -u "$TEAMWORK_API_KEY:x" \
  "$TW_BASE/people.json?pageSize=20" \
  | jq -r '.people[] | "\(.id)\t\(."first-name") \(."last-name")\t\(."email-address")\t\(.administrator)"' | column -t
```

## Analysis Phase

```bash
#!/bin/bash
TW_BASE="https://$TEAMWORK_DOMAIN.teamwork.com"
PROJECT_ID="${1:?Project ID required}"

echo "=== Task Lists ==="
curl -s -u "$TEAMWORK_API_KEY:x" \
  "$TW_BASE/projects/$PROJECT_ID/tasklists.json" \
  | jq -r '.tasklists[] | "\(.id)\t\(.name[0:30])\tcomplete=\(."complete-count")\tuncomplete=\(."uncomplete-count")"' | column -t

echo ""
echo "=== Milestones ==="
curl -s -u "$TEAMWORK_API_KEY:x" \
  "$TW_BASE/projects/$PROJECT_ID/milestones.json" \
  | jq -r '.milestones[]? | "\(.id)\t\(.title[0:30])\t\(.deadline)\t\(.completed)"' | column -t

echo ""
echo "=== Late Tasks ==="
curl -s -u "$TEAMWORK_API_KEY:x" \
  "$TW_BASE/tasks.json?filter=late&projectIds=$PROJECT_ID&pageSize=10" \
  | jq -r '.["todo-items"][]? | "\(.id)\t\(.content[0:40])\tdue=\(."due-date")\t\(."responsible-party-names" // "unassigned")"' | column -t

echo ""
echo "=== Time Entries (last 7 days) ==="
FROM=$(date -v-7d +%Y%m%d 2>/dev/null || date -d "-7 days" +%Y%m%d)
curl -s -u "$TEAMWORK_API_KEY:x" \
  "$TW_BASE/projects/$PROJECT_ID/time_entries.json?fromdate=$FROM&pageSize=15" \
  | jq -r '.["time-entries"][]? | "\(.date)\t\(."person-first-name") \(."person-last-name")\t\(.hours)h\(.minutes)m\t\(.description[0:30])"' | column -t

echo ""
echo "=== Risks ==="
curl -s -u "$TEAMWORK_API_KEY:x" \
  "$TW_BASE/projects/$PROJECT_ID/risks.json" \
  | jq -r '.risks[]? | "\(.id)\t\(.source[0:30])\t\(.probability)\t\(.impact)"' | column -t
```

## Output Format

```
TEAMWORK PROJECT HEALTH: [project_name]
Status:         [status]
Task Lists:     [count]
Milestones:     [count]

TASK STATUS
List                Complete  Incomplete  Late
[name]              [n]       [n]         [n]

TIME TRACKING (Last 7 Days)
Person           Hours   Tasks
[name]           [h]     [count]

MILESTONES
Milestone        Deadline    Status
[title]          [date]      [completed]
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

