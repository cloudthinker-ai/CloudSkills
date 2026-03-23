---
name: managing-sendinblue
description: |
  Use when working with Sendinblue — brevo (formerly Sendinblue) marketing
  platform management including transactional email, SMS campaigns, contact
  management, automation workflows, and landing pages. Covers sending quotas,
  deliverability metrics, contact list health, and campaign performance
  analysis.
connection_type: sendinblue
preload: false
---

# Brevo (Sendinblue) Management Skill

Monitor and manage Brevo email, SMS, and marketing automation services.

## MANDATORY: Discovery-First Pattern

**Always discover account limits and contact lists before querying campaign data.**

### Phase 1: Discovery

```bash
#!/bin/bash
BREVO_API="https://api.brevo.com/v3"
AUTH="api-key: ${BREVO_API_KEY}"

echo "=== Account Info ==="
curl -s -H "$AUTH" "$BREVO_API/account" | \
  jq -r '"Company: \(.companyName)\nPlan: \(.plan[0].type) (\(.plan[0].planType))\nCredits: \(.plan[0].credits)\nEmail Limit: \(.plan[0].creditsType)"'

echo ""
echo "=== Sending Quota ==="
curl -s -H "$AUTH" "$BREVO_API/account" | \
  jq -r '.relay | "Remaining Today: \(.remaining)\nDaily Limit: \(.dailyLimit)"'

echo ""
echo "=== Contact Lists ==="
curl -s -H "$AUTH" "$BREVO_API/contacts/lists?limit=20&offset=0" | \
  jq -r '.lists[] | "\(.name) | ID: \(.id) | Contacts: \(.totalSubscribers) | Folder: \(.folderId)"'

echo ""
echo "=== Senders ==="
curl -s -H "$AUTH" "$BREVO_API/senders" | \
  jq -r '.senders[] | "\(.name) <\(.email)> | Active: \(.active) | IPs: \(.ips | length)"'
```

**Phase 1 outputs:** Account plan, quotas, contact lists, senders

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Email Campaign Stats (last 10) ==="
curl -s -H "$AUTH" "$BREVO_API/emailCampaigns?limit=10&sort=desc" | \
  jq -r '.campaigns[] | "\(.name) | Status: \(.status) | Sent: \(.statistics.globalStats.sent // 0) | Opens: \(.statistics.globalStats.uniqueOpens // 0) | Clicks: \(.statistics.globalStats.uniqueClicks // 0)"'

echo ""
echo "=== Transactional Email Stats ==="
curl -s -H "$AUTH" "$BREVO_API/smtp/statistics/aggregatedReport?days=7" | \
  jq -r '"7-Day: Requests=\(.requests) Delivered=\(.delivered) Bounces=\(.hardBounces + .softBounces) Blocked=\(.blocked)\nOpen Rate: \(if .delivered > 0 then (.uniqueOpens * 100 / .delivered | floor) else 0 end)%"'

echo ""
echo "=== SMS Campaign Stats ==="
curl -s -H "$AUTH" "$BREVO_API/smsCampaigns?limit=5&sort=desc" | \
  jq -r '.campaigns[] | "\(.name) | Sent: \(.statistics.sent) | Delivered: \(.statistics.delivered)"'

echo ""
echo "=== Automation Workflows ==="
curl -s -H "$AUTH" "$BREVO_API/workflows?limit=20" | \
  jq -r '.workflows[] | "\(.name) | Status: \(.status) | Type: \(.type)"'
```

## Output Format

```
BREVO STATUS
============
Plan: {plan} | Daily Quota: {remaining}/{limit}
Contact Lists: {count} | Total Contacts: {total}
7-Day Email: Sent={count} Delivered={count} Bounced={count}
Delivery Rate: {percent}% | Open Rate: {percent}%
Active Campaigns: {count}
Workflows: {active}/{total} active
Issues: {list_of_warnings}
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

## Common Pitfalls

- **Brevo vs Sendinblue**: API endpoint is api.brevo.com — old sendinblue.com still redirects
- **Credits vs Quota**: Free plan has daily send limits; paid has monthly credits
- **Transactional vs Marketing**: Separate stats and separate sending infrastructure
- **Rate limits**: 400 req/min for most endpoints — lower for contact imports
