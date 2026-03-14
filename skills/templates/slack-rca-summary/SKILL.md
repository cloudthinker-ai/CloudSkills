---
name: slack-rca-summary
enabled: true
description: Post concise incident RCA summaries to Slack channels. Formats findings into a readable Slack message with severity, root cause, impact, and action items.
required_connections:
  - prefix: slack
    label: "Slack"
config_fields:
  - key: channel_name
    label: "Channel Name"
    required: true
    placeholder: "e.g., #incident-updates"
features:
  - RCA
---

# Slack RCA Summary

Post formatted incident RCA summaries to a Slack channel.

## Prerequisites

Before executing this skill, ensure:
1. The RCA analysis has been completed and findings are available in context
2. The Slack connection is configured and the bot has access to `{{config.channel_name}}`
3. The bot has permission to post messages in the target channel

## Workflow

### Step 1: Resolve the Channel

Look up the channel `{{config.channel_name}}` to get its ID. Strip the `#` prefix if present.

```typescript
const channelName = '{{config.channel_name}}'.replace(/^#/, '');
const channelList = await listConversations({ types: 'public_channel,private_channel', limit: 200 });
const channel = channelList.channels.find(c => c.name === channelName);
const channelId = channel.id;
```

If the channel is not found, report the error and list available channels as suggestions.

### Step 2: Extract RCA Information

From the RCA context, extract:

| Field | Required | Notes |
|-------|----------|-------|
| Incident title | Yes | Brief, descriptive title |
| Severity | Yes | Critical / High / Medium / Low |
| Status | Yes | Resolved / Mitigated / Investigating |
| Duration | Yes | How long the incident lasted |
| Root cause | Yes | 1-2 sentence summary |
| Impact | Yes | User/service impact summary |
| Resolution | Yes | What was done to fix it |
| Action items | Yes | Top 3-5 follow-up items |
| Incident lead | If available | Who managed the incident |
| Timeline highlights | If available | Key moments (detected, mitigated, resolved) |

### Step 3: Format the Slack Message

Build the message using Slack's mrkdwn format. Keep it concise and scannable.

```
:rotating_light: *Incident Report: {incident_title}*

*Severity:* {severity}  |  *Status:* {status}  |  *Duration:* {duration}

---

*Root Cause*
{1-2 sentence root cause explanation}

*Impact*
{scope of impact: users affected, services degraded, SLA implications}

*Resolution*
{what was done to resolve the incident}

---

*Timeline*
- {time_1}: {event_detected}
- {time_2}: {event_mitigated}
- {time_3}: {event_resolved}

*Action Items*
1. {action_item_1} - Owner: {owner_1}
2. {action_item_2} - Owner: {owner_2}
3. {action_item_3} - Owner: {owner_3}

---

:page_facing_up: Full report: {link_to_detailed_report_if_available}
```

### Step 4: Post to Slack

```typescript
await postMessage({
  channel: channelId,
  text: formattedMessage
});
```

### Step 5: Thread Follow-up (Optional)

If there is extensive supporting evidence or detailed technical analysis, post it as a thread reply to keep the main channel clean:

```typescript
const mainMessage = await postMessage({
  channel: channelId,
  text: summaryMessage
});

await postMessage({
  channel: channelId,
  thread_ts: mainMessage.ts,
  text: detailedTechnicalAnalysis
});
```

## Output

After successful posting, report:
1. Confirmation that the message was posted to `{{config.channel_name}}`
2. A brief note on what was included in the summary
3. Any RCA fields that were unavailable and omitted

## Formatting Rules

- Use Slack's mrkdwn syntax: `*bold*`, `_italic_`, `` `code` ``
- Use `---` for horizontal dividers between sections
- Use numbered lists for action items (priority order)
- Use bullet lists for timeline events
- Keep the main message under 3000 characters for readability
- Use emoji sparingly: `:rotating_light:` for header, `:page_facing_up:` for report link
- Do not use `@here` or `@channel` mentions unless explicitly instructed

## Severity Formatting

Apply visual indicators based on severity:

| Severity | Prefix |
|----------|--------|
| Critical | `:red_circle: Critical` |
| High | `:large_orange_circle: High` |
| Medium | `:large_yellow_circle: Medium` |
| Low | `:white_circle: Low` |

## Error Handling

| Scenario | Action |
|----------|--------|
| Channel not found | Report error, suggest checking channel name `{{config.channel_name}}` |
| No permission to post | Report the permission error, suggest inviting the bot |
| Message too long | Split into main summary + thread reply with details |
| Missing RCA data | Post with available data, note incomplete sections |

## Content Guidelines

- Lead with severity and status for immediate context
- Keep root cause explanation non-technical enough for a mixed audience
- Action items should be specific and assigned to owners
- Include a link to the full incident report if one was created (e.g., Confluence page)
- Timestamp all timeline events in UTC
- Do not include raw logs or stack traces in the main message (use thread replies)
