---
name: managing-postmark
description: |
  Use when working with Postmark — postmark transactional email service
  management including server configuration, message streams, delivery
  statistics, bounce tracking, template management, and sender signature
  verification. Covers delivery rates, latency metrics, and suppression list
  monitoring.
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

- **Account vs Server token**: Account token manages servers; server token manages messages
- **Message streams**: Transactional and broadcast are separate streams — stats differ
- **Suppression management**: Postmark auto-suppresses hard bounces and spam complaints
- **Rate limits**: 50 API calls per second — implement backoff for bulk operations
