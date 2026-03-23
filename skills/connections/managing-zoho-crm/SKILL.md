---
name: managing-zoho-crm
description: |
  Use when working with Zoho Crm — zoho CRM management including leads,
  contacts, accounts, deals, activities, reports, workflows, and blueprints.
  Covers pipeline analytics, lead conversion tracking, activity completion,
  workflow execution monitoring, and API usage limits.
connection_type: zoho-crm
preload: false
---

# Zoho CRM Management Skill

Monitor and manage Zoho CRM operations and sales pipeline.

## MANDATORY: Discovery-First Pattern

**Always discover modules and org info before querying records.**

### Phase 1: Discovery

```bash
#!/bin/bash
ZOHO_API="https://www.zohoapis.com/crm/v6"
AUTH="Authorization: Zoho-oauthtoken ${ZOHO_ACCESS_TOKEN}"

echo "=== Org Info ==="
curl -s -H "$AUTH" "$ZOHO_API/org" | \
  jq -r '.org[] | "Name: \(.company_name)\nCountry: \(.country)\nEdition: \(.edition)\nCurrency: \(.currency_symbol)"'

echo ""
echo "=== Modules ==="
curl -s -H "$AUTH" "$ZOHO_API/settings/modules" | \
  jq -r '.modules[] | select(.api_supported==true) | "\(.api_name) | Plural: \(.plural_label) | Visible: \(.visible)"' | head -15

echo ""
echo "=== Users ==="
curl -s -H "$AUTH" "$ZOHO_API/users?type=ActiveUsers" | \
  jq -r '.users[] | "\(.full_name) | Role: \(.role.name) | Profile: \(.profile.name) | Status: \(.status)"' | head -10

echo ""
echo "=== Active Workflows ==="
curl -s -H "$AUTH" "$ZOHO_API/settings/workflow_rules" | \
  jq -r '.workflow_rules[] | select(.status=="active") | "\(.name) | Module: \(.module.api_name) | Trigger: \(.trigger.type // "N/A")"' | head -10

echo ""
echo "=== API Usage ==="
curl -s -H "$AUTH" "$ZOHO_API/org" | \
  jq -r '.org[] | "API Credits: \(.api_count_info.api_credits // "N/A")"'
```

**Phase 1 outputs:** Org info, modules, users, workflows, API usage

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Record Counts ==="
for module in Leads Contacts Accounts Deals; do
  count=$(curl -s -H "$AUTH" "$ZOHO_API/$module/actions/count" | jq '.count // 0')
  echo "$module: $count"
done

echo ""
echo "=== Pipeline Summary ==="
curl -s -H "$AUTH" "$ZOHO_API/Deals/search?criteria=(Stage:not_equal:Closed Won)&fields=Deal_Name,Stage,Amount&per_page=200" | \
  jq -r '"Open Deals: \(.data | length)\nTotal Value: \([.data[].Amount // 0] | add)"' 2>/dev/null || \
curl -s -H "$AUTH" "$ZOHO_API/Deals?fields=Deal_Name,Stage,Amount&per_page=200" | \
  jq -r '"Deals Retrieved: \(.data | length)\nStages: \([.data[].Stage] | group_by(.) | map({stage:.[0], count:length}) | .[] | "\(.stage): \(.count)")"'

echo ""
echo "=== Lead Conversion (last 30 days) ==="
curl -s -H "$AUTH" "$ZOHO_API/Leads/search?criteria=(Converted_Date:greater_equal:$(date -v-30d +%Y-%m-%d 2>/dev/null || date -d '30 days ago' +%Y-%m-%d))&per_page=200" | \
  jq -r '"Converted Leads (30d): \(.data | length // 0)"' 2>/dev/null || echo "Check lead conversion via reports"

echo ""
echo "=== Overdue Activities ==="
curl -s -H "$AUTH" "$ZOHO_API/Activities?filters=((Due_Date:less_than:$(date +%Y-%m-%d))and(Status:not_equal:Completed))&per_page=10" | \
  jq -r '.data[:5] | .[] | "\(.Subject) | Due: \(.Due_Date) | Owner: \(.Owner.name)"' 2>/dev/null || echo "Check via Tasks and Events modules"
```

## Output Format

```
ZOHO CRM STATUS
===============
Org: {name} ({edition})
Active Users: {count}
Leads: {count} | Contacts: {count} | Deals: {count}
Open Pipeline Value: {amount}
Lead Conversion (30d): {count}
Active Workflows: {count}
Overdue Activities: {count}
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

- **OAuth token refresh**: Access tokens expire in 1 hour — implement refresh token flow
- **Data center URLs**: zohoapis.com (US), zohoapis.eu (EU), zohoapis.in (India) — match to org
- **API limits**: Vary by edition — Free has 5000/day, Enterprise has 25000/day
- **COQL vs Criteria**: Use COQL for complex queries, criteria for simple filters
