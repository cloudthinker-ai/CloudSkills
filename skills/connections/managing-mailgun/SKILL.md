---
name: managing-mailgun
description: |
  Mailgun email service management including domain configuration, sending statistics, deliverability monitoring, bounce and complaint tracking, route management, and mailing list administration. Covers domain health, DNS verification, reputation scoring, and event log analysis.
connection_type: mailgun
preload: false
---

# Mailgun Management Skill

Monitor and manage Mailgun email sending infrastructure and deliverability.

## MANDATORY: Discovery-First Pattern

**Always discover domains and their verification status before querying stats.**

### Phase 1: Discovery

```bash
#!/bin/bash
MG_API="https://api.mailgun.net/v3"
AUTH="api:${MAILGUN_API_KEY}"

echo "=== Domains ==="
curl -s -u "$AUTH" "$MG_API/domains" | \
  jq -r '.items[] | "\(.name) | State: \(.state) | Type: \(.type) | Created: \(.created_at)"'

echo ""
echo "=== Domain Verification ==="
for domain in $(curl -s -u "$AUTH" "$MG_API/domains" | jq -r '.items[].name'); do
  status=$(curl -s -u "$AUTH" "$MG_API/domains/$domain" | \
    jq -r '"SPF: \(.sending_dns_records[] | select(.record_type=="TXT" and (.name | contains("spf"))) | .valid // "missing") | DKIM: \(.sending_dns_records[] | select(.record_type=="TXT" and (.name | contains("domainkey"))) | .valid // "missing")"' 2>/dev/null)
  echo "$domain | $status"
done

echo ""
echo "=== IPs ==="
curl -s -u "$AUTH" "$MG_API/ips" | \
  jq -r '.items[] | "\(.ip) | Dedicated: \(.dedicated) | Pool: \(.pool_id)"'

echo ""
echo "=== Routes ==="
curl -s -u "$AUTH" "$MG_API/routes" | \
  jq -r '.items[] | "\(.expression) -> \(.actions[0]) | Priority: \(.priority)"'
```

**Phase 1 outputs:** Domain list, DNS verification, IPs, routes

### Phase 2: Analysis

```bash
#!/bin/bash
DOMAIN="${1:-$MAILGUN_DOMAIN}"

echo "=== Sending Stats (7 days) ==="
curl -s -u "$AUTH" "$MG_API/$DOMAIN/stats/total?event=accepted&event=delivered&event=failed&event=opened&event=clicked&duration=7d" | \
  jq -r '.stats[] | "\(.time): Sent=\(.accepted.total) Del=\(.delivered.total) Fail=\(.failed.total.total) Open=\(.opened.total)"'

echo ""
echo "=== Bounce Rate ==="
curl -s -u "$AUTH" "$MG_API/$DOMAIN/bounces?limit=5" | \
  jq -r '.items[] | "\(.address) | Code: \(.code) | Error: \(.error[:60])"'

echo ""
echo "=== Complaints ==="
curl -s -u "$AUTH" "$MG_API/$DOMAIN/complaints?limit=5" | \
  jq -r '.items[] | "\(.address) | Date: \(.created_at)"'

echo ""
echo "=== Suppressions Summary ==="
bounces=$(curl -s -u "$AUTH" "$MG_API/$DOMAIN/bounces" | jq '.total_count')
complaints=$(curl -s -u "$AUTH" "$MG_API/$DOMAIN/complaints" | jq '.total_count')
unsubs=$(curl -s -u "$AUTH" "$MG_API/$DOMAIN/unsubscribes" | jq '.total_count')
echo "Bounces: $bounces | Complaints: $complaints | Unsubscribes: $unsubs"
```

## Output Format

```
MAILGUN STATUS
==============
Domain: {domain} ({state})
DNS: SPF={status} DKIM={status}
7-Day Stats: Sent={count} Delivered={count} Failed={count}
Delivery Rate: {percent}%
Open Rate: {percent}%
Suppressions: {bounces} bounces, {complaints} complaints
Issues: {list_of_warnings}
```

## Common Pitfalls

- **EU vs US region**: EU domains use api.eu.mailgun.net — check domain settings
- **DNS propagation**: SPF/DKIM changes take up to 48h — verify before flagging
- **Rate limits**: 300 requests/minute for free tier — batch stat queries
- **Suppression lists**: Mailgun auto-suppresses bounced addresses — check before diagnosing delivery failures
