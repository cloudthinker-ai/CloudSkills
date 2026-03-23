---
name: managing-webex
description: |
  Use when working with Webex — cisco Webex management covering meetings, rooms,
  memberships, messages, and usage analytics. Use when auditing Webex usage,
  managing spaces and meetings, retrieving message history, or analyzing
  collaboration patterns across a Webex organization.
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

