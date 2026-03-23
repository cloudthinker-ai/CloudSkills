---
name: managing-pipedrive
description: |
  Use when working with Pipedrive — pipedrive CRM management including deals,
  persons, organizations, pipelines, activities, products, and email
  integration. Covers pipeline health, deal velocity, activity completion rates,
  revenue forecasting, and sales team performance.
connection_type: pipedrive
preload: false
---

# Pipedrive Management Skill

Monitor and manage Pipedrive sales CRM and pipeline operations.

## MANDATORY: Discovery-First Pattern

**Always discover pipelines and users before querying deals or activities.**

### Phase 1: Discovery

```bash
#!/bin/bash
PD_API="https://api.pipedrive.com/v1"
TOKEN="api_token=${PIPEDRIVE_API_TOKEN}"

echo "=== Organization Info ==="
curl -s "$PD_API/users/me?$TOKEN" | \
  jq -r '.data | "User: \(.name)\nCompany: \(.company_name)\nRole: \(.role_key)\nTimezone: \(.timezone_name)"'

echo ""
echo "=== Pipelines ==="
curl -s "$PD_API/pipelines?$TOKEN" | \
  jq -r '.data[] | "\(.name) | ID: \(.id) | Active: \(.active) | Stages: \(.stages_count // "N/A") | Deals: \(.deals_count // "N/A")"'

echo ""
echo "=== Stages ==="
curl -s "$PD_API/stages?$TOKEN" | \
  jq -r '.data[] | "\(.name) | Pipeline: \(.pipeline_name) | Order: \(.order_nr) | Rotten Days: \(.rotten_days)"'

echo ""
echo "=== Users (Sales Team) ==="
curl -s "$PD_API/users?$TOKEN" | \
  jq -r '.data[] | "\(.name) | Email: \(.email) | Active: \(.active_flag) | Role: \(.role_key)"'

echo ""
echo "=== Custom Fields ==="
curl -s "$PD_API/dealFields?$TOKEN" | \
  jq -r '[.data[] | select(.is_subfield==false and .edit_flag==true)] | length | "Custom Deal Fields: \(.)"'
```

**Phase 1 outputs:** Company info, pipelines, stages, team, custom fields

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Deal Summary ==="
curl -s "$PD_API/deals/summary?$TOKEN&status=open" | \
  jq -r '.data | "Open Deals: \(.total_count)\nTotal Value: \(.total_currency_converted_value)\nAvg Value: \(.average_currency_converted_value)\nWeighted Value: \(.total_weighted_currency_converted_value)"'

echo ""
echo "=== Pipeline Distribution ==="
for pipeline_id in $(curl -s "$PD_API/pipelines?$TOKEN" | jq -r '.data[].id'); do
  name=$(curl -s "$PD_API/pipelines/$pipeline_id?$TOKEN" | jq -r '.data.name')
  summary=$(curl -s "$PD_API/deals/summary?$TOKEN&status=open&pipeline_id=$pipeline_id" | \
    jq -r '.data | "\(.total_count) deals, \(.total_currency_converted_value) value"')
  echo "$name: $summary"
done

echo ""
echo "=== Activities Due ==="
curl -s "$PD_API/activities?$TOKEN&type=all&done=0&limit=5" | \
  jq -r '.data[] | "\(.type) | \(.subject) | Due: \(.due_date) | Owner: \(.owner_name)"'

echo ""
echo "=== Won/Lost Ratio (last 30 days) ==="
won=$(curl -s "$PD_API/deals/summary?$TOKEN&status=won&start_date=$(date -v-30d +%Y-%m-%d 2>/dev/null || date -d '30 days ago' +%Y-%m-%d)" | jq '.data.total_count')
lost=$(curl -s "$PD_API/deals/summary?$TOKEN&status=lost&start_date=$(date -v-30d +%Y-%m-%d 2>/dev/null || date -d '30 days ago' +%Y-%m-%d)" | jq '.data.total_count')
echo "Won: $won | Lost: $lost | Win Rate: $(( won * 100 / (won + lost + 1) ))%"
```

## Output Format

```
PIPEDRIVE STATUS
================
Company: {name}
Pipelines: {count} | Users: {count}
Open Deals: {count} ({value})
30-Day Win Rate: {percent}%
Overdue Activities: {count}
Avg Deal Value: {amount}
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

- **API token in URL**: Pipedrive uses query param auth — ensure HTTPS always
- **Rate limits**: 100 requests per 10 seconds — batch where possible
- **Currency conversion**: Multi-currency orgs need converted values — use summary endpoints
- **Rotten deals**: Deals past rotten_days threshold are flagged — monitor stage aging
