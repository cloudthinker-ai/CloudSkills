---
name: azure-cost-management
description: |
  Azure Cost Management cost analysis, budget tracking, Advisor cost recommendations, export management, and spending trend analysis via Azure CLI.
connection_type: azure
preload: false
---

# Azure Cost Management Skill

Analyze Azure costs and budgets using `az costmanagement` and `az consumption` commands.

## Discovery-First Rule

**ALWAYS discover before acting.** Never assume budget names, subscription IDs, or resource group names. Always verify the scope and time range before querying costs.

```bash
# Get current subscription context
az account show --output json --query "{name:name, id:id, tenantId:tenantId}"

# List resource groups (common cost grouping)
az group list --output json --query "[].{name:name, location:location}"
```

## Parallel Execution Requirement

**ALL independent operations MUST run in parallel using background jobs (&) and wait.**

```bash
for rg in $(az group list --query "[].name" -o tsv); do
  {
    az costmanagement query --type ActualCost --scope "subscriptions/$SUB_ID/resourceGroups/$rg" \
      --timeframe MonthToDate --output json 2>/dev/null
  } &
done
wait
```

## Helper Functions

```bash
# Query costs by dimension
query_costs() {
  local scope="$1" timeframe="$2" grouping="$3"
  az costmanagement query --type ActualCost --scope "$scope" \
    --timeframe "$timeframe" \
    --dataset-grouping name="$grouping" type=Dimension \
    --output json
}

# Get cost for a specific time range
query_cost_range() {
  local scope="$1" from="$2" to="$3" grouping="$4"
  az costmanagement query --type ActualCost --scope "$scope" \
    --timeframe Custom --time-period from="$from" to="$to" \
    --dataset-grouping name="$grouping" type=Dimension \
    --output json
}

# List budgets
list_budgets() {
  local scope="$1"
  az consumption budget list --output json \
    --query "[].{name:name, amount:amount, timeGrain:timeGrain, currentSpend:currentSpend.amount, currency:currentSpend.unit, notifications:notifications}"
}

# Get Advisor cost recommendations
get_cost_recommendations() {
  az advisor recommendation list --category Cost --output json \
    --query "[].{impact:impact, category:category, problem:shortDescription.problem, solution:shortDescription.solution, resourceId:resourceMetadata.resourceId, savingsAmount:extendedProperties.savingsAmount, savingsCurrency:extendedProperties.savingsCurrency}"
}
```

## Common Operations

### 1. Cost Breakdown by Service

```bash
sub_id=$(az account show --query "id" -o tsv)
scope="subscriptions/$sub_id"

# Current month costs by service
query_costs "$scope" "MonthToDate" "ServiceName"

# Current month costs by resource group
query_costs "$scope" "MonthToDate" "ResourceGroup"

# Last month total
query_costs "$scope" "TheLastMonth" "ServiceName"
```

### 2. Budget Tracking

```bash
# List all budgets with current spend
list_budgets "subscriptions/$sub_id"

# Check budget alerts
az consumption budget list --output json \
  --query "[].{name:name, amount:amount, currentSpend:currentSpend.amount, percentUsed:currentSpend.amount / amount * 100, notifications:notifications | keys(@)}"
```

### 3. Cost Trend Analysis

```bash
# Daily cost trend for the last 30 days
end_date=$(date +%Y-%m-%d)
start_date=$(date -v-30d +%Y-%m-%d 2>/dev/null || date -d '30 days ago' +%Y-%m-%d)
az costmanagement query --type ActualCost --scope "subscriptions/$sub_id" \
  --timeframe Custom --time-period from="$start_date" to="$end_date" \
  --dataset-aggregation "{totalCost:{name:Cost,function:Sum}}" \
  --dataset-grouping name=ServiceName type=Dimension \
  --output json

# Compare current month to last month
query_costs "subscriptions/$sub_id" "MonthToDate" "ServiceName"
query_costs "subscriptions/$sub_id" "TheLastMonth" "ServiceName"
```

### 4. Advisor Cost Recommendations

```bash
# Get all cost saving recommendations
get_cost_recommendations

# Filter high-impact recommendations
az advisor recommendation list --category Cost --output json \
  --query "[?impact=='High'].{problem:shortDescription.problem, solution:shortDescription.solution, savings:extendedProperties.savingsAmount, resource:resourceMetadata.resourceId}"
```

### 5. Cost Export Management

```bash
# List scheduled exports
az costmanagement export list --scope "subscriptions/$sub_id" --output json \
  --query "[].{name:name, status:deliveryInfo.destination, schedule:schedule.recurrence, format:format, timeframe:definition.timeframe}"

# Check last export execution
for export_name in $(az costmanagement export list --scope "subscriptions/$sub_id" --query "[].name" -o tsv); do
  {
    az costmanagement export show --scope "subscriptions/$sub_id" --name "$export_name" --output json
  } &
done
wait
```

## Common Pitfalls

1. **Cost data delay**: Azure cost data has a 24-48 hour ingestion delay. Do not expect real-time cost data for today.
2. **Amortized vs actual**: Actual costs show billed amounts; amortized costs spread reservation purchases over the term. Use the right type for your analysis.
3. **Subscription scope**: Cost queries at subscription level do not include management group rollups. For multi-subscription analysis, query each subscription in parallel.
4. **Currency**: Always check the currency in responses. Multi-currency environments require separate handling.
5. **Marketplace costs**: Third-party marketplace charges may not appear in standard cost queries. Use `az consumption marketplace list` for marketplace-specific costs.
