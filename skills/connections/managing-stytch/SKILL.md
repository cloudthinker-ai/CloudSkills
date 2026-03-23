---
name: managing-stytch
description: |
  Use when working with Stytch — stytch authentication and identity platform
  management covering users, sessions, magic links, OTPs, OAuth, and
  organization management. Use when analyzing user authentication patterns,
  monitoring session health, reviewing MFA adoption, managing Stytch users and
  organizations, or troubleshooting login flows.
connection_type: stytch
preload: false
---

# Stytch Management Skill

Manage and analyze Stytch authentication resources including users, sessions, and auth methods.

## API Conventions

### Authentication
All API calls use Basic Auth with Project ID and Secret, injected automatically.

### Base URL
- Live: `https://api.stytch.com/v1`
- Test: `https://test.stytch.com/v1`

### Core Helper Function

```bash
#!/bin/bash

stytch_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -u "$STYTCH_PROJECT_ID:$STYTCH_SECRET" \
            -H "Content-Type: application/json" \
            "${STYTCH_BASE_URL:-https://api.stytch.com}/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -u "$STYTCH_PROJECT_ID:$STYTCH_SECRET" \
            "${STYTCH_BASE_URL:-https://api.stytch.com}/v1${endpoint}"
    fi
}
```

## Output Rules
- Target ≤50 lines per script output
- Use `jq` to extract only needed fields
- Never dump full API responses

## Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Recent Users ==="
stytch_api POST "/users/search" '{"limit": 20}' \
    | jq -r '.results[] | "\(.user_id[0:16])\t\(.emails[0].email // "no-email")\t\(.status)\t\(.created_at[0:10])"' \
    | column -t | head -20

echo ""
echo "=== User Count ==="
stytch_api POST "/users/search" '{"limit": 1}' \
    | jq '{total_users: .total}'

echo ""
echo "=== Auth Methods in Use ==="
stytch_api POST "/users/search" '{"limit": 100}' \
    | jq -r '[.results[] | {
        has_email: (.emails | length > 0),
        has_phone: (.phone_numbers | length > 0),
        has_totp: (.totps | length > 0),
        has_webauthn: (.webauthn_registrations | length > 0),
        has_oauth: (.providers | length > 0)
    }] | {
        with_email: map(select(.has_email)) | length,
        with_phone: map(select(.has_phone)) | length,
        with_totp: map(select(.has_totp)) | length,
        with_webauthn: map(select(.has_webauthn)) | length,
        with_oauth: map(select(.has_oauth)) | length
    }'
```

## Phase 2: Analysis

### Authentication Health

```bash
#!/bin/bash
echo "=== User Status Breakdown ==="
stytch_api POST "/users/search" '{"limit": 200}' \
    | jq -r '.results[] | .status' | sort | uniq -c | sort -rn

echo ""
echo "=== Users Without MFA ==="
stytch_api POST "/users/search" '{"limit": 100}' \
    | jq -r '.results[] | select((.totps | length == 0) and (.webauthn_registrations | length == 0) and (.phone_numbers | length == 0)) | "\(.user_id[0:16])\t\(.emails[0].email // "no-email")\t\(.created_at[0:10])"' \
    | head -15

echo ""
echo "=== Recently Created Users (7d) ==="
stytch_api POST "/users/search" '{"limit": 50, "query": {"operator": "AND", "operands": [{"filter_name": "created_at_greater_than", "filter_value": "'$(date -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)'"}]}}' \
    | jq '{new_users_7d: (.results | length)}'
```

### Session Analytics

```bash
#!/bin/bash
echo "=== Active Sessions (sample) ==="
stytch_api POST "/users/search" '{"limit": 50}' \
    | jq -r '[.results[] | select(.status == "active")] | length | "Active users: \(.)"'

echo ""
echo "=== OAuth Provider Distribution ==="
stytch_api POST "/users/search" '{"limit": 200}' \
    | jq -r '[.results[].providers[].provider_type] | group_by(.) | map({(.[0]): length}) | add'
```

## Output Format

```
=== Stytch Project: <id> ===
Total Users: <n>  Active: <n>

--- Auth Methods ---
Email: <n>  Phone: <n>  TOTP: <n>  WebAuthn: <n>  OAuth: <n>

--- MFA Coverage ---
Users with MFA: <n>  Without MFA: <n>

--- Recent Activity (7d) ---
New Users: <n>  OAuth Signups: <n>
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
- **Search endpoint is POST**: User search uses POST with JSON body, not GET with query params
- **Test vs Live**: Ensure correct base URL; test environment data is separate
- **Rate limits**: 1000 requests/5 minutes for most endpoints
- **User statuses**: `active`, `pending` — pending means email/phone not yet verified
