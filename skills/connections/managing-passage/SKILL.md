---
name: managing-passage
description: |
  Use when working with Passage — passage by 1Password passwordless
  authentication management covering users, devices, WebAuthn credentials, and
  app configuration. Use when analyzing passkey adoption, monitoring user
  authentication health, reviewing device registrations, managing Passage users,
  or auditing passwordless login activity.
connection_type: passage
preload: false
---

# Passage Management Skill

Manage and analyze Passage passwordless authentication resources including users, devices, and passkeys.

## API Conventions

### Authentication
All API calls use Bearer API key with app ID, injected automatically.

### Base URL
`https://api.passage.id/v1/apps/$PASSAGE_APP_ID`

### Core Helper Function

```bash
#!/bin/bash

passage_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $PASSAGE_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.passage.id/v1/apps/${PASSAGE_APP_ID}${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $PASSAGE_API_KEY" \
            "https://api.passage.id/v1/apps/${PASSAGE_APP_ID}${endpoint}"
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
echo "=== App Configuration ==="
passage_api GET "" \
    | jq '{name: .app.name, id: .app.id, auth_origin: .app.auth_origin, login_url: .app.login_url, auth_methods: .app.auth_methods}'

echo ""
echo "=== Recent Users ==="
passage_api GET "/users?limit=20&order_by=-created_at" \
    | jq -r '.users[] | "\(.id[0:16])\t\(.email // .phone // "no-contact")\t\(.status)\t\(.created_at[0:10])"' \
    | column -t | head -20

echo ""
echo "=== User Count ==="
passage_api GET "/users?limit=1" | jq '{total: .total_users}'
```

## Phase 2: Analysis

### Passkey Adoption

```bash
#!/bin/bash
echo "=== Device/Credential Summary ==="
passage_api GET "/users?limit=100" \
    | jq '{
        total_users: (.users | length),
        with_passkey: [.users[] | select(.webauthn_devices | length > 0)] | length,
        without_passkey: [.users[] | select(.webauthn_devices | length == 0)] | length,
        avg_devices: (.users | map(.webauthn_devices | length) | if length > 0 then add / length else 0 end)
    }'

echo ""
echo "=== Users Without Passkeys ==="
passage_api GET "/users?limit=50" \
    | jq -r '.users[] | select(.webauthn_devices | length == 0) | "\(.id[0:16])\t\(.email // "no-email")\t\(.created_at[0:10])"' \
    | head -15

echo ""
echo "=== User Status Breakdown ==="
passage_api GET "/users?limit=200" \
    | jq -r '.users[] | .status' | sort | uniq -c | sort -rn
```

### Authentication Health

```bash
#!/bin/bash
echo "=== Recently Active Users ==="
passage_api GET "/users?limit=50&order_by=-last_login_at" \
    | jq -r '.users[] | select(.last_login_at != null) | "\(.id[0:16])\t\(.email // "no-email")\t\(.last_login_at[0:16])"' \
    | head -15

echo ""
echo "=== Inactive Users (no login in 30d) ==="
CUTOFF=$(date -d '30 days ago' +%Y-%m-%dT%H:%M:%SZ)
passage_api GET "/users?limit=100" \
    | jq -r --arg cutoff "$CUTOFF" '.users[] | select(.last_login_at == null or .last_login_at < $cutoff) | "\(.id[0:16])\t\(.email // "no-email")\t\(.last_login_at // "never")"' \
    | head -15
```

## Output Format

```
=== App: <name> (ID: <id>) ===
Total Users: <n>  Auth Origin: <url>

--- Passkey Adoption ---
With Passkey: <n>  Without: <n>  Avg Devices: <n>

--- User Status ---
active: <n>  inactive: <n>  pending: <n>

--- Activity ---
Active (7d): <n>  Inactive (30d+): <n>
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
- **App ID required**: All endpoints are scoped to an app ID in the URL path
- **Pagination**: Use `limit` and `page` parameters; check `total_users` for total count
- **Rate limits**: Varies by plan; check response headers for limit info
- **WebAuthn devices**: Each user can have multiple passkey credentials registered
