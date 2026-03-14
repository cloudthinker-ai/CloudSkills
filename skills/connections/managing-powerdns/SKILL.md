---
name: managing-powerdns
description: |
  PowerDNS authoritative and recursor management covering zones, records, server statistics, DNSSEC, TSIG keys, and zone metadata. Use when managing PowerDNS servers, configuring DNS zones and records, enabling DNSSEC, monitoring server performance, or troubleshooting DNS resolution.
connection_type: powerdns
preload: false
---

# PowerDNS Skill

Manage PowerDNS authoritative server zones, records, DNSSEC, and server statistics.

## Core Helper Functions

```bash
#!/bin/bash

PDNS_API="http://$POWERDNS_HOST:8081/api/v1"
PDNS_SERVER="${POWERDNS_SERVER_ID:-localhost}"

pdns_api() {
    local endpoint="$1"
    shift
    curl -s -H "X-API-Key: $POWERDNS_API_KEY" \
         -H "Content-Type: application/json" \
         "$PDNS_API/servers/$PDNS_SERVER/$endpoint" "$@"
}
```

## MANDATORY: Discovery-First Pattern

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Server Info ==="
curl -s -H "X-API-Key: $POWERDNS_API_KEY" "$PDNS_API/servers/$PDNS_SERVER" | jq '{
    id, daemon_type, version, config_url, zones_url
}'

echo ""
echo "=== Zones ==="
pdns_api "zones" | jq -r '
    .[] | "\(.id)\t\(.kind)\t\(.serial)\t\(.dnssec)\t\(.last_check // 0)"
' | column -t | head -20

echo ""
echo "=== Server Statistics ==="
pdns_api "statistics" | jq -r '
    .[] | select(.name | test("query-cache|packet-cache|queries|answers")) |
    "\(.name)\t\(.value)"
' | column -t | head -15

echo ""
echo "=== TSIG Keys ==="
pdns_api "tsigkeys" | jq -r '
    .[] | "\(.id)\t\(.name)\t\(.algorithm)"
' | column -t | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash
ZONE="${1:?Zone name required (e.g., example.com.)}"

echo "=== Zone Details ==="
pdns_api "zones/$ZONE" | jq '{
    name: .name, kind: .kind, serial: .serial,
    dnssec: .dnssec, nsec3param: .nsec3param,
    soa_edit: .soa_edit, soa_edit_api: .soa_edit_api,
    masters: .masters, account: .account,
    rrset_count: (.rrsets | length)
}'

echo ""
echo "=== Record Sets ==="
pdns_api "zones/$ZONE" | jq -r '
    .rrsets[] | "\(.type)\t\(.name)\t\(.ttl)s\t\(.records[0].content[:60])\t\(.records | length) records"
' | sort | column -t | head -30

echo ""
echo "=== DNSSEC Keys ==="
pdns_api "zones/$ZONE/cryptokeys" | jq -r '
    .[] | "\(.id)\t\(.keytype)\t\(.algorithm)\t\(.bits)\t\(.active)"
' | column -t | head -10

echo ""
echo "=== Zone Metadata ==="
pdns_api "zones/$ZONE/metadata" | jq -r '
    .[] | "\(.kind)\t\(.metadata | join(", "))"
' | column -t | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use jq to parse PowerDNS API JSON responses
- Zone names must end with a dot (e.g., `example.com.`)

## Safety Rules
- **Read-only by default**: Use GET endpoints for inspection
- **Never delete zones or records** without explicit confirmation
- **DNSSEC key rotation** must follow proper rollover procedures
- **Serial number management**: Use SOA-EDIT-API for automatic serial increments

## Common Pitfalls
- **Trailing dot**: Zone and record names require trailing dot in the API
- **Zone kinds**: Native, Master, Slave have different replication behaviors
- **DNSSEC activation**: Enabling DNSSEC requires DS record at parent zone
- **API port**: Default API port is 8081; often behind a reverse proxy in production
- **RRset replacement**: PATCH with changetype REPLACE replaces entire RRset; DELETE removes it
