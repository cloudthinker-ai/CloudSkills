---
name: managing-trello
description: |
  Use when working with Trello — trello board management covering boards, lists,
  cards, members, labels, and activity analytics. Use when auditing Trello
  usage, managing boards and cards, analyzing workflow bottlenecks, or reviewing
  team activity across Trello workspaces.
connection_type: trello
preload: false
---

# Managing Trello

Trello board management and analytics via the Trello REST API.

## Discovery Phase

```bash
#!/bin/bash
TRELLO_BASE="https://api.trello.com/1"
AUTH="key=$TRELLO_KEY&token=$TRELLO_TOKEN"

echo "=== Current User ==="
curl -s "$TRELLO_BASE/members/me?$AUTH" \
  | jq '{id, username, fullName, email}'

echo ""
echo "=== Organizations ==="
curl -s "$TRELLO_BASE/members/me/organizations?$AUTH" \
  | jq -r '.[] | "\(.id)\t\(.displayName)\t\(.name)"' | column -t

echo ""
echo "=== Boards ==="
curl -s "$TRELLO_BASE/members/me/boards?$AUTH&filter=open&fields=name,dateLastActivity,idOrganization" \
  | jq -r '.[] | "\(.id)\t\(.name[0:30])\t\(.dateLastActivity[0:10])"' | column -t

echo ""
BOARD_ID="${1:?Board ID required}"
echo "=== Lists ==="
curl -s "$TRELLO_BASE/boards/$BOARD_ID/lists?$AUTH&fields=name,pos" \
  | jq -r '.[] | "\(.id)\t\(.name)"' | column -t

echo ""
echo "=== Labels ==="
curl -s "$TRELLO_BASE/boards/$BOARD_ID/labels?$AUTH" \
  | jq -r '.[] | "\(.id)\t\(.name // "unnamed")\t\(.color)"' | column -t

echo ""
echo "=== Members ==="
curl -s "$TRELLO_BASE/boards/$BOARD_ID/members?$AUTH" \
  | jq -r '.[] | "\(.id)\t\(.fullName)\t\(.username)"' | column -t
```

## Analysis Phase

```bash
#!/bin/bash
TRELLO_BASE="https://api.trello.com/1"
AUTH="key=$TRELLO_KEY&token=$TRELLO_TOKEN"
BOARD_ID="${1:?Board ID required}"

echo "=== Cards per List ==="
curl -s "$TRELLO_BASE/boards/$BOARD_ID/lists?$AUTH&cards=open&card_fields=name,due,idMembers,labels" \
  | jq -r '.[] | "\(.name)\t\(.cards | length) cards"' | column -t

echo ""
echo "=== Overdue Cards ==="
TODAY=$(date +%Y-%m-%dT00:00:00.000Z)
curl -s "$TRELLO_BASE/boards/$BOARD_ID/cards?$AUTH&fields=name,due,dueComplete,idList&filter=open" \
  | jq -r --arg today "$TODAY" '.[] | select(.due != null and .due < $today and .dueComplete == false) | "\(.name[0:40])\tdue=\(.due[0:10])\tOVERDUE"' | column -t

echo ""
echo "=== Unassigned Cards ==="
curl -s "$TRELLO_BASE/boards/$BOARD_ID/cards?$AUTH&fields=name,idMembers,idList&filter=open" \
  | jq '[.[] | select(.idMembers | length == 0)] | {unassigned: length, cards: [.[:5][] | .name[0:40]]}'

echo ""
echo "=== Cards by Label ==="
curl -s "$TRELLO_BASE/boards/$BOARD_ID/cards?$AUTH&fields=name,labels&filter=open" \
  | jq '[.[].labels[].name // "unlabeled"] | group_by(.) | map({label: .[0], count: length}) | sort_by(-.count)[]'

echo ""
echo "=== Recent Activity ==="
curl -s "$TRELLO_BASE/boards/$BOARD_ID/actions?$AUTH&filter=createCard,updateCard,commentCard&limit=10" \
  | jq -r '.[] | "\(.date[0:16])\t\(.memberCreator.username)\t\(.type)\t\(.data.card.name[0:30] // "")"' | column -t
```

## Output Format

```
TRELLO BOARD HEALTH: [board_name]
Total Cards:     [count]
Total Lists:     [count]
Members:         [count]
Labels:          [count]

LIST DISTRIBUTION
List             Cards  Pct
Backlog          [n]    [pct]%
In Progress      [n]    [pct]%
Done             [n]    [pct]%

HEALTH INDICATORS
Overdue Cards:   [count]
Unassigned:      [count]
No Labels:       [count]

RECENT ACTIVITY
Date         User        Action      Card
[datetime]   [username]  [type]      [name]
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

