---
name: managing-slack-deep
description: |
  Deep Slack workspace management covering channels, messages, users, reactions, and workspace analytics. Use when auditing Slack usage, analyzing communication patterns, managing channels, or retrieving message history and user activity across a Slack workspace.
connection_type: slack
preload: false
---

# Managing Slack (Deep)

Comprehensive Slack workspace analysis and management via the Slack Web API.

## Discovery Phase

```bash
#!/bin/bash
SLACK_BASE="https://slack.com/api"

echo "=== Workspace Info ==="
curl -s -H "Authorization: Bearer $SLACK_TOKEN" \
  "$SLACK_BASE/team.info" | jq '.team | {id, name, domain, email_domain}'

echo ""
echo "=== Channels (top 50) ==="
curl -s -H "Authorization: Bearer $SLACK_TOKEN" \
  "$SLACK_BASE/conversations.list?types=public_channel,private_channel&limit=50" \
  | jq -r '.channels[] | "\(.id)\t\(.name)\t\(.num_members)\tmembers\t\(if .is_archived then "archived" else "active" end)"' \
  | sort -t$'\t' -k3 -rn | column -t

echo ""
echo "=== Active Users ==="
curl -s -H "Authorization: Bearer $SLACK_TOKEN" \
  "$SLACK_BASE/users.list?limit=50" \
  | jq -r '.members[] | select(.deleted == false and .is_bot == false) | "\(.id)\t\(.real_name)\t\(.tz // "unknown")"' \
  | column -t | head -30

echo ""
echo "=== Bot User Identity ==="
curl -s -H "Authorization: Bearer $SLACK_TOKEN" \
  "$SLACK_BASE/auth.test" | jq '{user, user_id, team, team_id}'
```

## Analysis Phase

```bash
#!/bin/bash
SLACK_BASE="https://slack.com/api"
CHANNEL_ID="${1:?Channel ID required}"

echo "=== Channel Info ==="
curl -s -H "Authorization: Bearer $SLACK_TOKEN" \
  "$SLACK_BASE/conversations.info?channel=$CHANNEL_ID" \
  | jq '.channel | {name, purpose: .purpose.value, topic: .topic.value, num_members, created: (.created | todate)}'

echo ""
echo "=== Recent Messages (last 20) ==="
curl -s -H "Authorization: Bearer $SLACK_TOKEN" \
  "$SLACK_BASE/conversations.history?channel=$CHANNEL_ID&limit=20" \
  | jq -r '.messages[] | "\(.ts)\t\(.user // "bot")\t\(.text[0:80])"' | column -t

echo ""
echo "=== Channel Members ==="
curl -s -H "Authorization: Bearer $SLACK_TOKEN" \
  "$SLACK_BASE/conversations.members?channel=$CHANNEL_ID&limit=100" \
  | jq '{total_members: (.members | length), member_ids: .members[:10]}'
```

## Output Format

```
SLACK WORKSPACE HEALTH
Workspace:     [name] ([domain].slack.com)
Total Channels: [count] ([active] active / [archived] archived)
Total Users:    [count] ([active] active / [bots] bots)

TOP CHANNELS BY MEMBERSHIP
Channel          Members  Status
#general         [n]      active
#engineering     [n]      active

RECENT ACTIVITY
Channel          Last Message    Messages/Day
#general         [timestamp]     [avg]
```
