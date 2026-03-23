---
name: managing-sparkpost
description: |
  Use when working with Sparkpost — sparkPost email delivery service management
  including sending domains, IP pools, message events, deliverability metrics,
  templates, webhooks, and suppression lists. Covers bounce classification,
  engagement tracking, and inbox placement analysis.
connection_type: sparkpost
preload: false
---

# SparkPost Management Skill

Monitor and manage SparkPost email delivery and reputation.

## MANDATORY: Discovery-First Pattern

**Always discover sending domains and IP pools before querying delivery metrics.**

### Phase 1: Discovery

```bash
#!/bin/bash
SP_API="https://api.sparkpost.com/api/v1"
AUTH="Authorization: ${SPARKPOST_API_KEY}"

echo "=== Account Info ==="
curl -s -H "$AUTH" "$SP_API/account" | \
  jq -r '.results | "Company: \(.company_name)\nPlan: \(.subscription.name)\nStatus: \(.status)"'

echo ""
echo "=== Sending Domains ==="
curl -s -H "$AUTH" "$SP_API/sending-domains" | \
  jq -r '.results[] | "\(.domain) | Status: \(.status.ownership_verified) | DKIM: \(.status.dkim_status) | SPF: \(.status.spf_status) | Compliance: \(.status.compliance_status)"'

echo ""
echo "=== IP Pools ==="
curl -s -H "$AUTH" "$SP_API/ip-pools" | \
  jq -r '.results[] | "\(.name) | ID: \(.id) | IPs: \(.ips | length)"'

echo ""
echo "=== Webhooks ==="
curl -s -H "$AUTH" "$SP_API/webhooks" | \
  jq -r '.results[] | "\(.name) | Target: \(.target) | Active: \(.active) | Events: \(.events | length)"'
```

**Phase 1 outputs:** Account plan, sending domains, IP pools, webhooks

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Deliverability Metrics (7 days) ==="
curl -s -H "$AUTH" "$SP_API/metrics/deliverability?from=$(date -v-7d +%Y-%m-%dT%H:%M 2>/dev/null || date -d '7 days ago' +%Y-%m-%dT%H:%M)&metrics=count_targeted,count_injected,count_delivered,count_bounce,count_hard_bounce,count_soft_bounce,count_spam_complaint,count_unique_opened,count_unique_clicked" | \
  jq -r '.results[] | "Targeted: \(.count_targeted)\nDelivered: \(.count_delivered)\nBounced: \(.count_bounce) (Hard: \(.count_hard_bounce))\nSpam: \(.count_spam_complaint)\nOpened: \(.count_unique_opened)\nClicked: \(.count_unique_clicked)"'

echo ""
echo "=== Bounce Classification ==="
curl -s -H "$AUTH" "$SP_API/metrics/deliverability/bounce-reason?from=$(date -v-7d +%Y-%m-%dT%H:%M 2>/dev/null || date -d '7 days ago' +%Y-%m-%dT%H:%M)&metrics=count_bounce&limit=10" | \
  jq -r '.results[:5] | .[] | "\(.reason): \(.count_bounce) (\(.bounce_class_name))"'

echo ""
echo "=== Domain Performance ==="
curl -s -H "$AUTH" "$SP_API/metrics/deliverability/sending-domain?from=$(date -v-7d +%Y-%m-%dT%H:%M 2>/dev/null || date -d '7 days ago' +%Y-%m-%dT%H:%M)&metrics=count_delivered,count_bounce" | \
  jq -r '.results[] | "\(.sending_domain) | Delivered: \(.count_delivered) | Bounced: \(.count_bounce)"'

echo ""
echo "=== Suppression List Size ==="
curl -s -H "$AUTH" "$SP_API/suppression-list?limit=1" | \
  jq -r '"Total suppressed: \(.total_count)"'
```

## Output Format

```
SPARKPOST STATUS
================
Plan: {plan} | Status: {status}
Domains: {verified}/{total} verified
7-Day: Targeted={count} Delivered={count} Bounced={count}
Delivery Rate: {percent}% | Bounce Rate: {percent}%
Spam Complaint Rate: {percent}%
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

- **EU vs US**: EU accounts use api.eu.sparkpost.com — check account region
- **Bounce classes**: SparkPost uses 100 bounce categories — group by class for actionable data
- **Subaccounts**: Metrics can be scoped to subaccounts — always specify if using them
- **Rate limits**: Vary by plan — Enterprise has higher limits than free tier
