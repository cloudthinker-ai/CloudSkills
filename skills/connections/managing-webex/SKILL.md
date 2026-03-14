---
name: managing-webex
description: |
  Cisco Webex management covering meetings, rooms, memberships, messages, and usage analytics. Use when auditing Webex usage, managing spaces and meetings, retrieving message history, or analyzing collaboration patterns across a Webex organization.
connection_type: webex
preload: false
---

# Managing Webex

Comprehensive Webex management and analytics via the Webex REST API.

## Discovery Phase

```bash
#!/bin/bash
WEBEX_BASE="https://webexapis.com/v1"

echo "=== Current User ==="
curl -s -H "Authorization: Bearer $WEBEX_TOKEN" \
  "$WEBEX_BASE/people/me" | jq '{id, displayName, emails, orgId, type}'

echo ""
echo "=== Rooms (Spaces) ==="
curl -s -H "Authorization: Bearer $WEBEX_TOKEN" \
  "$WEBEX_BASE/rooms?max=30&sortBy=lastactivity" \
  | jq -r '.items[] | "\(.id[0:20])\t\(.title[0:40])\t\(.type)\t\(.lastActivity[0:10])"' | column -t

echo ""
echo "=== Upcoming Meetings ==="
FROM=$(date -u +%Y-%m-%dT%H:%M:%SZ)
curl -s -H "Authorization: Bearer $WEBEX_TOKEN" \
  "$WEBEX_BASE/meetings?meetingType=scheduledMeeting&from=$FROM&max=15" \
  | jq -r '.items[]? | "\(.id[0:20])\t\(.title[0:40])\t\(.start[0:16])\t\(.duration // "N/A")"' | column -t

echo ""
echo "=== Teams ==="
curl -s -H "Authorization: Bearer $WEBEX_TOKEN" \
  "$WEBEX_BASE/teams?max=20" \
  | jq -r '.items[]? | "\(.id[0:20])\t\(.name)\t\(.createdAt[0:10])"' | column -t
```

## Analysis Phase

```bash
#!/bin/bash
WEBEX_BASE="https://webexapis.com/v1"
ROOM_ID="${1:?Room/Space ID required}"

echo "=== Room Details ==="
curl -s -H "Authorization: Bearer $WEBEX_TOKEN" \
  "$WEBEX_BASE/rooms/$ROOM_ID" \
  | jq '{title, type, isLocked, lastActivity, creatorId, teamId}'

echo ""
echo "=== Room Members ==="
curl -s -H "Authorization: Bearer $WEBEX_TOKEN" \
  "$WEBEX_BASE/memberships?roomId=$ROOM_ID&max=30" \
  | jq -r '.items[] | "\(.personDisplayName)\t\(if .isModerator then "moderator" else "member" end)\t\(.created[0:10])"' | column -t

echo ""
echo "=== Recent Messages ==="
curl -s -H "Authorization: Bearer $WEBEX_TOKEN" \
  "$WEBEX_BASE/messages?roomId=$ROOM_ID&max=15" \
  | jq -r '.items[] | "\(.created[0:19])\t\(.personEmail)\t\(.text[0:60] // "[attachment]")"' | column -t
```

## Output Format

```
WEBEX WORKSPACE HEALTH
User:          [displayName] ([email])
Total Rooms:   [count] (direct: [n], group: [n])
Total Teams:   [count]

ACTIVE SPACES
Space                   Type    Last Activity  Members
[title]                 group   [date]         [n]

UPCOMING MEETINGS
Meeting                 Start            Duration
[title]                 [datetime]       [minutes]min
```
