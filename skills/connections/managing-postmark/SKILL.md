---
name: managing-postmark
description: |
  Postmark transactional email service management including server configuration, message streams, delivery statistics, bounce tracking, template management, and sender signature verification. Covers delivery rates, latency metrics, and suppression list monitoring.
connection_type: postmark
preload: false
---

# Postmark Management Skill

Monitor and manage Postmark transactional email delivery.

## MANDATORY: Discovery-First Pattern

**Always discover servers and message streams before querying delivery stats.**

### Phase 1: Discovery

```bash
#!/bin/bash
PM_API="https://api.postmarkapp.com"
ACCT_HDR="X-Postmark-Account-Token: ${POSTMARK_ACCOUNT_TOKEN}"
SRV_HDR="X-Postmark-Server-Token: ${POSTMARK_SERVER_TOKEN}"

echo "=== Servers ==="
curl -s -H "$ACCT_HDR" "$PM_API/servers?count=50&offset=0" | \
  jq -r '.Servers[] | "\(.Name) | ID: \(.ID) | Color: \(.Color) | SMTP: \(.SmtpApiActivated)"'

echo ""
echo "=== Message Streams ==="
curl -s -H "$SRV_HDR" "$PM_API/message-streams" | \
  jq -r '.MessageStreams[] | "\(.ID) | Name: \(.Name) | Type: \(.MessageStreamType)"'

echo ""
echo "=== Sender Signatures ==="
curl -s -H "$ACCT_HDR" "$PM_API/senders?count=50&offset=0" | \
  jq -r '.SenderSignatures[] | "\(.EmailAddress) | Confirmed: \(.Confirmed) | SPF: \(.SPFVerified) | DKIM: \(.DKIMVerified)"'

echo ""
echo "=== Templates ==="
curl -s -H "$SRV_HDR" "$PM_API/templates?count=50&offset=0" | \
  jq -r '"Total Templates: \(.TotalCount)"'
```

**Phase 1 outputs:** Servers, message streams, sender verification, template count

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Delivery Stats (30 days) ==="
curl -s -H "$SRV_HDR" "$PM_API/stats/outbound?fromdate=$(date -v-30d +%Y-%m-%d 2>/dev/null || date -d '30 days ago' +%Y-%m-%d)&todate=$(date +%Y-%m-%d)" | \
  jq -r '"Sent: \(.Sent)\nBounced: \(.Bounced) (\(.BounceRate)%)\nSpam Complaints: \(.SpamComplaints) (\(.SpamComplaintsRate)%)\nTracked Opens: \(.Opens)\nUnique Opens: \(.UniqueOpens)"'

echo ""
echo "=== Bounce Summary ==="
curl -s -H "$SRV_HDR" "$PM_API/bounces?count=10&offset=0" | \
  jq -r '.Bounces[:5] | .[] | "\(.Email) | Type: \(.Type) | \(.Name) | \(.BouncedAt)"'

echo ""
echo "=== Bounce Types ==="
curl -s -H "$SRV_HDR" "$PM_API/deliverystats" | \
  jq -r '.Bounces[] | "\(.Type): \(.Count)"'

echo ""
echo "=== Suppression List ==="
curl -s -H "$SRV_HDR" "$PM_API/message-streams/outbound/suppressions/dump" | \
  jq -r '"Suppressed addresses: \(.Suppressions | length)"'
```

## Output Format

```
POSTMARK STATUS
===============
Server: {name}
Streams: {count} ({types})
Senders: {verified}/{total} verified
30-Day: Sent={count} Bounced={count} ({rate}%)
Spam Complaints: {count} ({rate}%)
Open Rate: {percent}%
Suppressions: {count}
Issues: {list_of_warnings}
```

## Common Pitfalls

- **Account vs Server token**: Account token manages servers; server token manages messages
- **Message streams**: Transactional and broadcast are separate streams — stats differ
- **Suppression management**: Postmark auto-suppresses hard bounces and spam complaints
- **Rate limits**: 50 API calls per second — implement backoff for bulk operations
