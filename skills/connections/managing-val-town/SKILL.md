---
name: managing-val-town
description: |
  Use when working with Val Town — val Town platform management covering val
  inventory, execution logs, scheduled val status, HTTP endpoint configuration,
  email handler analysis, blob storage usage, and usage metrics. Use for
  comprehensive Val Town workspace assessment and optimization.
connection_type: val-town
preload: false
---

# Val Town Management

Analyze Val Town vals, scheduled runs, HTTP endpoints, and workspace health.

## Phase 1: Discovery

```bash
#!/bin/bash
TOKEN="${VAL_TOWN_API_KEY}"
BASE="https://api.val.town/v1"
AUTH=(-H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json")

echo "=== My Vals ==="
curl -s "${BASE}/me/vals?limit=50" "${AUTH[@]}" \
  | jq -r '.data[] | "\(.name)\t\(.type)\t\(.privacy)\t\(.version)\t\(.createdAt[0:10])"' \
  | column -t | head -20

echo ""
echo "=== HTTP Vals (Endpoints) ==="
curl -s "${BASE}/me/vals?limit=50" "${AUTH[@]}" \
  | jq -r '.data[] | select(.type == "http") | "\(.name)\t\(.privacy)\tv\(.version)\t\(.url // "N/A")"' \
  | column -t | head -20

echo ""
echo "=== Scheduled Vals ==="
curl -s "${BASE}/me/vals?limit=50" "${AUTH[@]}" \
  | jq -r '.data[] | select(.type == "interval") | "\(.name)\t\(.privacy)\tv\(.version)\t\(.createdAt[0:10])"' \
  | column -t | head -20

echo ""
echo "=== Email Vals ==="
curl -s "${BASE}/me/vals?limit=50" "${AUTH[@]}" \
  | jq -r '.data[] | select(.type == "email") | "\(.name)\t\(.privacy)\tv\(.version)"' \
  | column -t | head -10
```

## Phase 2: Analysis

```bash
#!/bin/bash
TOKEN="${VAL_TOWN_API_KEY}"
BASE="https://api.val.town/v1"
AUTH=(-H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json")

echo "=== Recent Runs ==="
for VAL_ID in $(curl -s "${BASE}/me/vals?limit=20" "${AUTH[@]}" | jq -r '.data[]?.id'); do
  NAME=$(curl -s "${BASE}/vals/${VAL_ID}" "${AUTH[@]}" | jq -r '.name' 2>/dev/null)
  curl -s "${BASE}/vals/${VAL_ID}/runs?limit=3" "${AUTH[@]}" \
    | jq -r ".data[]? | \"${NAME}\t\(.id[0:8])\t\(.status // \"unknown\")\t\(.createdAt[0:19])\"" 2>/dev/null
done | column -t | head -20

echo ""
echo "=== Val Type Summary ==="
curl -s "${BASE}/me/vals?limit=100" "${AUTH[@]}" \
  | jq -r '.data | group_by(.type) | .[] | "\(.[0].type): \(length) vals"'

echo ""
echo "=== Blob Storage ==="
curl -s "${BASE}/me/blobs" "${AUTH[@]}" \
  | jq -r '.data[]? | "\(.key)\t\(.size) bytes\t\(.createdAt[0:10])"' \
  | column -t | head -15

echo ""
echo "=== Profile Info ==="
curl -s "${BASE}/me" "${AUTH[@]}" \
  | jq '{username: .username, tier: .tier, email: .email, bio: .bio[0:60]}' 2>/dev/null

echo ""
echo "=== Privacy Audit ==="
curl -s "${BASE}/me/vals?limit=100" "${AUTH[@]}" \
  | jq -r '.data | group_by(.privacy) | .[] | "\(.[0].privacy): \(length) vals"'
```

## Output Format

```
VAL TOWN ANALYSIS
===================
Val              Type       Privacy   Version  Last Run     Status
──────────────────────────────────────────────────────────────────
api-handler      http       public    v12      2h ago       success
daily-scraper    interval   private   v8       6h ago       success
email-parser     email      unlisted  v3       1d ago       success
data-utils       script     public    v15      3d ago       success

Summary: 24 vals (8 http, 5 interval, 3 email, 8 script)
Privacy: 10 public, 8 private, 6 unlisted | Blobs: 5 stored
```

## Safety Rules

- **Read-only**: Only use GET endpoints against the Val Town API
- **Never create, update, or delete** vals without confirmation
- **API keys**: Never output API key or token values
- **Rate limits**: Val Town API allows 100 requests per minute

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

