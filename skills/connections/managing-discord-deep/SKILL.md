---
name: managing-discord-deep
description: |
  Deep Discord server management covering guilds, channels, members, roles, and message analytics. Use when auditing Discord server health, analyzing community engagement, managing channels and roles, or retrieving message history across a Discord server.
connection_type: discord
preload: false
---

# Managing Discord (Deep)

Comprehensive Discord server analysis and management via the Discord REST API.

## Discovery Phase

```bash
#!/bin/bash
DISCORD_BASE="https://discord.com/api/v10"

echo "=== Bot User ==="
curl -s -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
  "$DISCORD_BASE/users/@me" | jq '{id, username, discriminator, bot}'

echo ""
echo "=== Guilds (Servers) ==="
curl -s -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
  "$DISCORD_BASE/users/@me/guilds" \
  | jq -r '.[] | "\(.id)\t\(.name)\t\(.owner)"' | column -t

echo ""
GUILD_ID="${1:?Guild ID required}"
echo "=== Channels in Guild ==="
curl -s -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
  "$DISCORD_BASE/guilds/$GUILD_ID/channels" \
  | jq -r '.[] | "\(.id)\t\(.name)\ttype=\(.type)\tposition=\(.position)"' \
  | sort -t$'\t' -k3 | column -t

echo ""
echo "=== Roles ==="
curl -s -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
  "$DISCORD_BASE/guilds/$GUILD_ID/roles" \
  | jq -r '.[] | "\(.id)\t\(.name)\tmembers_hoist=\(.hoist)\tmentionable=\(.mentionable)"' | column -t

echo ""
echo "=== Member Count ==="
curl -s -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
  "$DISCORD_BASE/guilds/$GUILD_ID?with_counts=true" \
  | jq '{name, member_count: .approximate_member_count, online: .approximate_presence_count}'
```

## Analysis Phase

```bash
#!/bin/bash
DISCORD_BASE="https://discord.com/api/v10"
CHANNEL_ID="${1:?Channel ID required}"

echo "=== Channel Info ==="
curl -s -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
  "$DISCORD_BASE/channels/$CHANNEL_ID" \
  | jq '{id, name, type, topic, nsfw, rate_limit_per_user}'

echo ""
echo "=== Recent Messages (last 25) ==="
curl -s -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
  "$DISCORD_BASE/channels/$CHANNEL_ID/messages?limit=25" \
  | jq -r '.[] | "\(.timestamp[0:19])\t\(.author.username)\t\(.content[0:80])"' | column -t

echo ""
echo "=== Pinned Messages ==="
curl -s -H "Authorization: Bot $DISCORD_BOT_TOKEN" \
  "$DISCORD_BASE/channels/$CHANNEL_ID/pins" \
  | jq -r '.[] | "\(.author.username)\t\(.content[0:60])"' | column -t
```

## Output Format

```
DISCORD SERVER HEALTH
Server:        [name] (ID: [id])
Members:       [total] ([online] online)
Channels:      [count] (text: [n], voice: [n], category: [n])
Roles:         [count]

CHANNELS BY CATEGORY
Category          Channel          Type    Position
General           #general         text    0
General           #welcome         text    1
Voice             VC Lounge        voice   2

ENGAGEMENT SUMMARY
Channel          Messages/Day  Pinned  Members
#general         [avg]         [n]     [n]
```
