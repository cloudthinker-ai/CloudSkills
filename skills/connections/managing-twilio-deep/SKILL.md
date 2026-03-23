---
name: managing-twilio-deep
description: |
  Use when working with Twilio Deep — deep Twilio management covering voice
  calls, SMS/MMS messaging, SIP trunking, phone number provisioning, usage
  records, and account health. Use when analyzing Twilio call quality, messaging
  delivery rates, troubleshooting failed messages, reviewing usage costs, or
  managing phone number inventory.
connection_type: twilio
preload: false
---

# Twilio Deep Management Skill

Comprehensive management and analysis of Twilio voice, messaging, and telephony resources.

## API Conventions

### Authentication
All API calls use HTTP Basic Auth with Account SID and Auth Token, injected automatically.

### Base URL
`https://api.twilio.com/2010-04-01/Accounts/$TWILIO_ACCOUNT_SID`

### Core Helper Function

```bash
#!/bin/bash

twilio_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -u "$TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN" \
            "https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}${endpoint}.json" \
            -d "$data"
    else
        curl -s -X "$method" \
            -u "$TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN" \
            "https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}${endpoint}.json"
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
echo "=== Account Info ==="
twilio_api GET "" | jq '{sid: .sid, name: .friendly_name, status: .status, type: .type}'

echo ""
echo "=== Phone Number Inventory ==="
twilio_api GET "/IncomingPhoneNumbers?PageSize=50" \
    | jq -r '.incoming_phone_numbers[] | "\(.phone_number)\t\(.friendly_name)\t\(.capabilities | to_entries | map(select(.value==true) | .key) | join(","))"' \
    | column -t | head -20

echo ""
echo "=== Recent Messages (last 24h) ==="
twilio_api GET "/Messages?PageSize=20&DateSent>=$(date -u -d '1 day ago' +%Y-%m-%d)" \
    | jq -r '.messages[] | "\(.date_sent[0:16])\t\(.direction)\t\(.status)\t\(.from)\t\(.to)"' | head -15

echo ""
echo "=== Recent Calls ==="
twilio_api GET "/Calls?PageSize=20&StartTime>=$(date -u -d '1 day ago' +%Y-%m-%d)" \
    | jq -r '.calls[] | "\(.start_time[0:16])\t\(.direction)\t\(.status)\t\(.duration)s\t\(.from)\t\(.to)"' | head -15
```

## Phase 2: Analysis

### Messaging Health

```bash
#!/bin/bash
echo "=== Message Delivery Summary (last 7 days) ==="
twilio_api GET "/Messages?PageSize=1000&DateSent>=$(date -u -d '7 days ago' +%Y-%m-%d)" \
    | jq -r '.messages[] | .status' | sort | uniq -c | sort -rn

echo ""
echo "=== Failed Messages ==="
twilio_api GET "/Messages?Status=failed&PageSize=20" \
    | jq -r '.messages[] | "\(.date_sent[0:16])\t\(.error_code)\t\(.error_message[0:60])\t\(.to)"' | head -15

echo ""
echo "=== Error Code Breakdown ==="
twilio_api GET "/Messages?Status=failed&PageSize=200" \
    | jq -r '.messages[] | "\(.error_code) \(.error_message)"' | sort | uniq -c | sort -rn | head -10
```

### Call Quality & Usage

```bash
#!/bin/bash
echo "=== Call Summary (last 7 days) ==="
twilio_api GET "/Calls?PageSize=500&StartTime>=$(date -u -d '7 days ago' +%Y-%m-%d)" \
    | jq '{
        total: (.calls | length),
        by_status: (.calls | group_by(.status) | map({(.[0].status): length}) | add),
        avg_duration_sec: (.calls | map(.duration | tonumber) | if length > 0 then add / length | floor else 0 end)
    }'

echo ""
echo "=== Usage Records (current month) ==="
twilio_api GET "/Usage/Records/ThisMonth" \
    | jq -r '.usage_records[] | select(.count != "0") | "\(.category)\t\(.count)\t$\(.price)"' \
    | sort -t$'\t' -k3 -rn | head -15
```

## Output Format

```
=== Account: <name> (SID: <sid>) ===
Status: <active|suspended>
Phone Numbers: <count>

--- Messaging Health ---
Delivered: <n>  Failed: <n>  Undelivered: <n>
Top Errors: <error_code>: <count>

--- Call Quality ---
Total Calls: <n>  Avg Duration: <n>s
By Status: completed: <n>, busy: <n>, failed: <n>

--- Monthly Usage ---
<category>  <count>  $<price>
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
- **Date format**: Use `YYYY-MM-DD` for date filters
- **Pagination**: Default page size is 50, max 1000; check `next_page_uri` for more
- **Rate limits**: 100 requests/second concurrency limit
- **Error codes**: Reference https://www.twilio.com/docs/api/errors for error code meanings
