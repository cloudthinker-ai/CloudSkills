---
name: slack-deployment-notification
enabled: true
description: |
  Use when performing slack deployment notification — post structured deployment
  notifications to Slack channels. Formats release details into a clean Slack
  message with service name, version, environment, deployer, key changes, and
  rollback instructions. Use after completing a deployment or to announce an
  upcoming deployment window.
required_connections:
  - prefix: slack
    label: "Slack"
config_fields:
  - key: channel_name
    label: "Slack Channel"
    required: true
    placeholder: "e.g., #deployments, #eng-releases"
  - key: service_name
    label: "Service Name"
    required: true
    placeholder: "e.g., payment-api"
  - key: version
    label: "Version / Tag"
    required: true
    placeholder: "e.g., v2.4.1"
  - key: environment
    label: "Environment"
    required: true
    placeholder: "e.g., production, staging"
  - key: notification_type
    label: "Notification Type"
    required: false
    placeholder: "e.g., started, completed, failed, rollback"
features:
  - DEPLOYMENT
---

# Slack Deployment Notification Skill

Post a deployment notification for **{{ service_name }} {{ version }}** to **{{ channel_name }}**.

## Workflow

### Step 1 — Gather Deployment Information

Collect the following details to compose the notification:

1. **Deployer name** — who triggered the deployment
2. **Changelog** — key changes in this release (3-5 bullet points max)
3. **Deployment type** — rolling / blue-green / canary / full-replace
4. **Estimated duration** — how long the deployment is expected to take
5. **Rollback version** — previous version (for rollback instructions)
6. **PR/release link** — link to PR, release notes, or deployment job

### Step 2 — Select Message Format

Choose the message format based on `{{ notification_type | "completed" }}`:

**started** — deployment is beginning:
```json
{
  "channel": "{{ channel_name }}",
  "blocks": [
    {
      "type": "header",
      "text": { "type": "plain_text", "text": "🚀 Deployment Started" }
    },
    {
      "type": "section",
      "fields": [
        { "type": "mrkdwn", "text": "*Service:*\n{{ service_name }}" },
        { "type": "mrkdwn", "text": "*Version:*\n{{ version }}" },
        { "type": "mrkdwn", "text": "*Environment:*\n{{ environment }}" },
        { "type": "mrkdwn", "text": "*Deployer:*\n[deployer name]" }
      ]
    },
    {
      "type": "section",
      "text": { "type": "mrkdwn", "text": "*Changes:*\n[bullet list of changes]" }
    },
    {
      "type": "context",
      "elements": [
        { "type": "mrkdwn", "text": "Strategy: [deployment type] | ETA: [duration] | <[link]|Release Notes>" }
      ]
    }
  ]
}
```

**completed** — deployment succeeded:
```json
{
  "channel": "{{ channel_name }}",
  "blocks": [
    {
      "type": "header",
      "text": { "type": "plain_text", "text": "✅ Deployment Completed" }
    },
    {
      "type": "section",
      "fields": [
        { "type": "mrkdwn", "text": "*Service:*\n{{ service_name }}" },
        { "type": "mrkdwn", "text": "*Version:*\n{{ version }}" },
        { "type": "mrkdwn", "text": "*Environment:*\n{{ environment }}" },
        { "type": "mrkdwn", "text": "*Duration:*\n[actual duration]" }
      ]
    },
    {
      "type": "section",
      "text": { "type": "mrkdwn", "text": "*Deployed by:* [deployer name]\n*Changes:*\n[bullet list of changes]" }
    },
    {
      "type": "context",
      "elements": [
        { "type": "mrkdwn", "text": "<[link]|Release Notes> | Rollback: `[rollback command or version]`" }
      ]
    }
  ]
}
```

**failed** — deployment failed:
```json
{
  "channel": "{{ channel_name }}",
  "blocks": [
    {
      "type": "header",
      "text": { "type": "plain_text", "text": "❌ Deployment Failed" }
    },
    {
      "type": "section",
      "fields": [
        { "type": "mrkdwn", "text": "*Service:*\n{{ service_name }}" },
        { "type": "mrkdwn", "text": "*Version:*\n{{ version }}" },
        { "type": "mrkdwn", "text": "*Environment:*\n{{ environment }}" },
        { "type": "mrkdwn", "text": "*Failed at:*\n[step that failed]" }
      ]
    },
    {
      "type": "section",
      "text": { "type": "mrkdwn", "text": "*Error:*\n[error description]\n\n*Rollback status:* [automatic/manual rollback status]" }
    },
    {
      "type": "context",
      "elements": [
        { "type": "mrkdwn", "text": "<[deployment log link]|View Logs> | Deployed by: [deployer]" }
      ]
    }
  ]
}
```

**rollback** — rollback in progress or completed:
```json
{
  "channel": "{{ channel_name }}",
  "blocks": [
    {
      "type": "header",
      "text": { "type": "plain_text", "text": "⏪ Rollback Initiated" }
    },
    {
      "type": "section",
      "fields": [
        { "type": "mrkdwn", "text": "*Service:*\n{{ service_name }}" },
        { "type": "mrkdwn", "text": "*Rolling back to:*\n[previous version]" },
        { "type": "mrkdwn", "text": "*Environment:*\n{{ environment }}" },
        { "type": "mrkdwn", "text": "*Reason:*\n[reason for rollback]" }
      ]
    },
    {
      "type": "context",
      "elements": [
        { "type": "mrkdwn", "text": "Initiated by: [name] | <[incident link]|Incident>" }
      ]
    }
  ]
}
```

### Step 3 — Post to Slack

```bash
#!/bin/bash

# Send the notification using the Slack connection
PAYLOAD='[formatted JSON block from Step 2]'

curl -s -X POST "${SLACK_WEBHOOK_URL}" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" | jq -r 'if . == "ok" then "✅ Posted to {{ channel_name }}" else "❌ Error: \(.)" end'
```

Or using Slack API (with bot token):
```bash
curl -s -X POST "https://slack.com/api/chat.postMessage" \
    -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" | jq '{ok: .ok, ts: .ts, error: .error}'
```

### Step 4 — Confirm Delivery

After posting, confirm:
1. Message was delivered successfully (API returned `"ok": true`)
2. Message timestamp for threading future updates
3. Share the message link with the user

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

Produce:
1. **Preview of the Slack message** content (what will be posted)
2. **Confirmation** of successful delivery with channel and timestamp
3. **Message link** for referencing in future communications

## Best Practices

- Keep changelogs to 3-5 bullet points — link to full release notes for details
- Always include rollback information so responders can act fast if issues arise
- Use threads for follow-up status updates (monitoring windows, post-deploy checks)
- For {{ environment }} = production: ping `@here` or `@channel` in the message for visibility
- For staging/dev environments: no pinging, just informational message
