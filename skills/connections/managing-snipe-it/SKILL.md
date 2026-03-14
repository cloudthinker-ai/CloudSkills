---
name: managing-snipe-it
description: |
  Snipe-IT asset management covering hardware asset tracking, software license management, and check-in/check-out workflows. Use when cataloging IT hardware with serial numbers and custom fields, managing software license counts and assignments, processing asset check-outs to employees, handling returns and transfers, or auditing asset locations and maintenance schedules.
connection_type: snipe-it
preload: false
---

# Snipe-IT Asset Management Skill

Manage and analyze Snipe-IT hardware assets, software licenses, and check-in/check-out workflows.

## API Conventions

### Authentication
All API calls use Bearer token — injected automatically.

### Base URL
`https://{{instance}}/api/v1`

### Core Helper Function

```bash
#!/bin/bash

snipeit_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $SNIPEIT_TOKEN" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            "${SNIPEIT_URL}/api/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $SNIPEIT_TOKEN" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            "${SNIPEIT_URL}/api/v1${endpoint}"
    fi
}
```

## Common Operations

### Hardware Asset Management

```bash
#!/bin/bash
echo "=== Hardware Assets Summary ==="
snipeit_api GET "/hardware?limit=1&offset=0" | jq '.total'
echo ""

echo "=== Assets by Status ==="
snipeit_api GET "/statuslabels" \
    | jq -r '.rows[] | "\(.id)\t\(.assets_count) assets\t\(.name)\t\(.type)"' \
    | column -t

echo ""
echo "=== Recently Added Hardware ==="
snipeit_api GET "/hardware?order=created_at&sort=desc&limit=15" \
    | jq -r '.rows[] | "\(.asset_tag)\t\(.model.name // "-")\t\(.status_label.name)\t\(.created_at.formatted)"' \
    | column -t

echo ""
echo "=== Assets Due for Audit ==="
snipeit_api GET "/hardware?audit_due=true&limit=15" \
    | jq -r '.rows[] | "\(.asset_tag)\t\(.model.name // "-")\t\(.next_audit_date // "-")"' \
    | column -t
```

### Software License Management

```bash
#!/bin/bash
echo "=== Software Licenses ==="
snipeit_api GET "/licenses?limit=25&order=name&sort=asc" \
    | jq -r '.rows[] | "\(.id)\t\(.seats - .free_seats_count)/\(.seats)\t\(.name)\t\(.expiration_date.formatted // "No expiry")"' \
    | column -t

echo ""
echo "=== Over-allocated Licenses ==="
snipeit_api GET "/licenses?limit=100" \
    | jq -r '[.rows[] | select(.free_seats_count < 0)] | .[] | "WARNING: \(.name) — \(.free_seats_count) seats over-allocated"'

echo ""
echo "=== Expiring Licenses (next 90 days) ==="
snipeit_api GET "/licenses?limit=50&order=expiration_date&sort=asc" \
    | jq -r '[.rows[] | select(.expiration_date.date != null)] | .[:15] | .[] | "\(.name)\tExpires: \(.expiration_date.formatted)\tSeats: \(.seats)"'
```

### Check-in / Check-out

```bash
#!/bin/bash
echo "=== Check Out Asset ==="
ASSET_ID="${1:?Asset ID required}"
USER_ID="${2:?User ID required}"
snipeit_api POST "/hardware/${ASSET_ID}/checkout" "{
    \"checkout_to_type\": \"user\",
    \"assigned_user\": ${USER_ID},
    \"note\": \"${3:-Checked out via API}\"
}" | jq '{status: .status, messages: .messages}'

echo ""
echo "=== Check In Asset ==="
# ASSET_ID="${1:?Asset ID required}"
# snipeit_api POST "/hardware/${ASSET_ID}/checkin" "{
#     \"note\": \"Returned\"
# }" | jq '{status: .status, messages: .messages}'
```

## Common Pitfalls

- **Pagination**: Use `limit` and `offset` — response includes `total` for calculating pages
- **Sort order**: Use `order` (field name) and `sort` (`asc`/`desc`) as separate parameters
- **Asset tag vs ID**: Asset tags are human-readable strings, IDs are internal integers — most endpoints use ID
- **Checkout types**: `checkout_to_type` must be `user`, `asset`, or `location`
- **Status labels**: Asset statuses are customizable — query `/statuslabels` for available options
- **Rate limits**: Self-hosted — depends on server configuration, typically no built-in rate limiting
- **Custom fields**: Custom fields are returned in the response — fieldset configuration determines available fields
- **Image uploads**: Hardware images use multipart form data — not JSON
