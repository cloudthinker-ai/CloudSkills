---
name: managing-teams-deep
description: |
  Use when working with Teams Deep — deep Microsoft Teams management covering
  teams, channels, messages, memberships, and activity analytics. Use when
  auditing Teams usage, analyzing collaboration patterns, managing team
  structures, or retrieving conversation history across a Microsoft Teams
  environment.
connection_type: microsoft-teams
preload: false
---

# Managing Microsoft Teams (Deep)

Comprehensive Microsoft Teams analysis and management via the Microsoft Graph API.

## Discovery Phase

```bash
#!/bin/bash
GRAPH_BASE="https://graph.microsoft.com/v1.0"

echo "=== Current User ==="
curl -s -H "Authorization: Bearer $MS_GRAPH_TOKEN" \
  "$GRAPH_BASE/me" | jq '{id, displayName, mail, userPrincipalName}'

echo ""
echo "=== Joined Teams ==="
curl -s -H "Authorization: Bearer $MS_GRAPH_TOKEN" \
  "$GRAPH_BASE/me/joinedTeams" \
  | jq -r '.value[] | "\(.id)\t\(.displayName)\t\(.description // "no description")"' | column -t

echo ""
echo "=== Channels per Team ==="
for TEAM_ID in $(curl -s -H "Authorization: Bearer $MS_GRAPH_TOKEN" \
  "$GRAPH_BASE/me/joinedTeams" | jq -r '.value[].id'); do
  TEAM_NAME=$(curl -s -H "Authorization: Bearer $MS_GRAPH_TOKEN" \
    "$GRAPH_BASE/teams/$TEAM_ID" | jq -r '.displayName')
  echo "--- $TEAM_NAME ---"
  curl -s -H "Authorization: Bearer $MS_GRAPH_TOKEN" \
    "$GRAPH_BASE/teams/$TEAM_ID/channels" \
    | jq -r '.value[] | "\(.id)\t\(.displayName)\t\(.membershipType)"' | column -t
done

echo ""
echo "=== Team Members (first team) ==="
FIRST_TEAM=$(curl -s -H "Authorization: Bearer $MS_GRAPH_TOKEN" \
  "$GRAPH_BASE/me/joinedTeams" | jq -r '.value[0].id')
curl -s -H "Authorization: Bearer $MS_GRAPH_TOKEN" \
  "$GRAPH_BASE/teams/$FIRST_TEAM/members" \
  | jq -r '.value[] | "\(.displayName)\t\(.roles | join(",") // "member")"' | column -t
```

## Analysis Phase

```bash
#!/bin/bash
GRAPH_BASE="https://graph.microsoft.com/v1.0"
TEAM_ID="${1:?Team ID required}"
CHANNEL_ID="${2:?Channel ID required}"

echo "=== Channel Messages (last 20) ==="
curl -s -H "Authorization: Bearer $MS_GRAPH_TOKEN" \
  "$GRAPH_BASE/teams/$TEAM_ID/channels/$CHANNEL_ID/messages?\$top=20" \
  | jq -r '.value[] | "\(.createdDateTime)\t\(.from.user.displayName // "system")\t\(.body.content[0:80])"' \
  | column -t

echo ""
echo "=== Team Analytics ==="
curl -s -H "Authorization: Bearer $MS_GRAPH_TOKEN" \
  "$GRAPH_BASE/teams/$TEAM_ID" \
  | jq '{displayName, description, isArchived, memberSettings, guestSettings}'
```

## Output Format

```
TEAMS WORKSPACE HEALTH
User:          [displayName] ([email])
Total Teams:   [count]
Total Channels:[count]

TEAMS OVERVIEW
Team                 Channels  Members  Archived
Engineering          [n]       [n]      false
Marketing            [n]       [n]      false

CHANNEL ACTIVITY
Channel              Last Message    Type
General              [timestamp]     standard
Announcements        [timestamp]     standard
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

