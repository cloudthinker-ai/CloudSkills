---
name: managing-dnsimple
description: |
  DNSimple DNS and domain management covering domains, DNS records, zone files, certificates, contacts, and domain registration. Use when managing DNSimple hosted zones, configuring DNS records, managing SSL certificates, handling domain registrations, or troubleshooting DNS resolution issues.
connection_type: dnsimple
preload: false
---

# DNSimple Skill

Manage DNSimple domains, DNS records, certificates, and domain registrations.

## Core Helper Functions

```bash
#!/bin/bash

DNSIMPLE_API="https://api.dnsimple.com/v2"

dnsimple_api() {
    local endpoint="$1"
    shift
    curl -s -H "Authorization: Bearer $DNSIMPLE_API_TOKEN" \
         -H "Content-Type: application/json" \
         "$DNSIMPLE_API/$endpoint" "$@"
}

# Get account ID
dnsimple_account_id() {
    dnsimple_api "whoami" | jq -r '.data.account.id // .data.user.id'
}
```

## MANDATORY: Discovery-First Pattern

### Phase 1: Discovery

```bash
#!/bin/bash
ACCOUNT=$(dnsimple_account_id)

echo "=== Domains ==="
dnsimple_api "$ACCOUNT/domains?per_page=100" | jq -r '
    .data[] | "\(.id)\t\(.name)\t\(.state)\t\(.expires_on // "n/a")\t\(.auto_renew)"
' | column -t | head -20

echo ""
echo "=== Domain Registrations ==="
dnsimple_api "$ACCOUNT/registrar/domains?per_page=50" | jq -r '
    .data[]? | "\(.name)\t\(.state)\t\(.registrant_id)\t\(.expires_on[:10])"
' | column -t | head -15

echo ""
echo "=== SSL Certificates ==="
for DOMAIN in $(dnsimple_api "$ACCOUNT/domains?per_page=20" | jq -r '.data[].name'); do
    dnsimple_api "$ACCOUNT/domains/$DOMAIN/certificates" | jq -r --arg d "$DOMAIN" '
        .data[]? | "\($d)\t\(.id)\t\(.common_name)\t\(.state)\t\(.expires_on[:10] // "n/a")"
    '
done | column -t | head -15

echo ""
echo "=== Name Servers ==="
for DOMAIN in $(dnsimple_api "$ACCOUNT/domains?per_page=10" | jq -r '.data[].name'); do
    NS=$(dnsimple_api "$ACCOUNT/registrar/domains/$DOMAIN/delegation" 2>/dev/null | jq -r '.data | join(", ")')
    echo "$DOMAIN: $NS"
done | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash
ACCOUNT=$(dnsimple_account_id)
DOMAIN="${1:?Domain name required}"

echo "=== DNS Records ==="
dnsimple_api "$ACCOUNT/zones/$DOMAIN/records?per_page=500" | jq -r '
    .data[] | "\(.type)\t\(.name // "@")\t\(.content[:60])\t\(.ttl)s\t\(.priority // "")"
' | sort | column -t | head -30

echo ""
echo "=== Zone File ==="
dnsimple_api "$ACCOUNT/zones/$DOMAIN/file" | jq -r '.data.zone' | head -20

echo ""
echo "=== Domain Services ==="
dnsimple_api "$ACCOUNT/domains/$DOMAIN/services" | jq -r '
    .data[]? | "\(.name)\t\(.short_name)\t\(.description[:50])"
' | column -t | head -10

echo ""
echo "=== WHOIS Privacy ==="
dnsimple_api "$ACCOUNT/registrar/domains/$DOMAIN/whois_privacy" | jq '.data | {enabled, expires_on}'
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use jq to parse DNSimple API JSON responses
- Sort DNS records by type for readability

## Safety Rules
- **Read-only by default**: Use GET endpoints for inspection
- **Never delete DNS records** without explicit confirmation
- **Domain transfers** are irreversible once completed
- **Auto-renew changes** can cause domain expiration if disabled accidentally

## Common Pitfalls
- **Account ID required**: All API calls require the account ID in the path
- **Zone vs domain**: Zones hold DNS records; domains are registrations -- they can exist independently
- **Pagination**: Default page size is 30; use per_page=100 for larger zones
- **One-click services**: Adding services creates DNS records automatically; removing deletes them
- **DNSSEC**: Must be enabled via the API; not automatic for all TLDs
