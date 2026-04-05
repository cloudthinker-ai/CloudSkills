#!/usr/bin/env bash
set -euo pipefail
export AWS_PAGER=""

###############################################################################
# AWS Billing Helper Functions
# Source this file, then call functions individually. Do not execute directly.
#
# All functions use NetUnblendedCost by default, enforce 420-day lookback,
# and follow CE half-open date interval conventions.
###############################################################################

# ── Constants ────────────────────────────────────────────────────────────────
_AWS_DEFAULT_METRIC="NetUnblendedCost"
_AWS_FORECAST_METRIC="NET_UNBLENDED_COST"
_AWS_MAX_LOOKBACK_DAYS=420
_AWS_DEFAULT_DAYS=30

# ── Internal helpers ─────────────────────────────────────────────────────────

# Parse --account, --days, --daily flags from arguments
_aws_billing_parse_args() {
  _ACCOUNT=""
  _DAYS="$_AWS_DEFAULT_DAYS"
  _DAILY=false
  _REGION_FLAG=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --account) _ACCOUNT="$2"; shift 2 ;;
      --days)    _DAYS="$2"; shift 2 ;;
      --daily)   _DAILY=true; shift ;;
      --region)  _REGION_FLAG=(--region "$2"); shift 2 ;;
      *) shift ;;
    esac
  done
}

# Validate and cap days to max lookback
_aws_parse_days() {
  local days="$1"
  if [[ "$days" -gt "$_AWS_MAX_LOOKBACK_DAYS" ]]; then
    echo "ERROR: Requested ${days} days exceeds max lookback of ${_AWS_MAX_LOOKBACK_DAYS} days." >&2
    return 1
  fi
  if [[ "$days" -lt 1 ]]; then
    echo "ERROR: Days must be >= 1." >&2
    return 1
  fi
  echo "$days"
}

# Compute start date (N days ago) in YYYY-MM-DD
_aws_date_start() {
  local days="$1"
  if [[ "$(uname)" == "Darwin" ]]; then
    date -u -v-"${days}"d '+%Y-%m-%d'
  else
    date -u -d "${days} days ago" '+%Y-%m-%d'
  fi
}

# Compute end date (today, exclusive per CE convention)
_aws_date_end() {
  date -u '+%Y-%m-%d'
}

# Compute a future date (N days from today)
_aws_date_end_future() {
  local days="${1:-30}"
  if [[ "$(uname)" == "Darwin" ]]; then
    date -u -v+"${days}"d '+%Y-%m-%d'
  else
    date -u -d "${days} days" '+%Y-%m-%d'
  fi
}

# Build account filter JSON fragment
_aws_account_filter() {
  local account="$1"
  if [[ -n "$account" ]]; then
    echo "{\"Dimensions\":{\"Key\":\"LINKED_ACCOUNT\",\"Values\":[\"${account}\"]}}"
  fi
}

# Build filter combining account + RecordType=Usage (excludes credits/refunds)
_aws_build_filter() {
  local account="$1"
  local usage_filter='{"Dimensions":{"Key":"RECORD_TYPE","Values":["Usage"]}}'
  if [[ -n "$account" ]]; then
    local acct_filter
    acct_filter=$(_aws_account_filter "$account")
    echo "{\"And\":[${acct_filter},${usage_filter}]}"
  else
    echo "$usage_filter"
  fi
}

# ── Public Functions ─────────────────────────────────────────────────────────

# Detect caller identity, currency, and linked accounts (MANDATORY first call)
aws_billing_account() {
  _aws_billing_parse_args "$@"
  local days
  days=$(_aws_parse_days "${_DAYS}") || return 1

  echo "=== AWS Billing Account Context ==="

  # Caller identity
  echo "--- Caller Identity ---"
  aws sts get-caller-identity "${_REGION_FLAG[@]+"${_REGION_FLAG[@]}"}" --output table

  # Detect currency and linked accounts from a small CE query
  local start end
  start=$(_aws_date_start "$days")
  end=$(_aws_date_end)

  echo ""
  echo "--- Currency & Linked Accounts (last ${days} days) ---"
  aws ce get-cost-and-usage \
    --time-period "Start=${start},End=${end}" \
    --granularity MONTHLY \
    --metrics "${_AWS_DEFAULT_METRIC}" \
    --group-by Type=DIMENSION,Key=LINKED_ACCOUNT \
    --output text \
    --query 'ResultsByTime[].Groups[].{Account:Keys[0],Amount:Metrics.NetUnblendedCost.Amount,Unit:Metrics.NetUnblendedCost.Unit}' \
    | sort -t$'\t' -k2 -rn | head -20

  echo ""
  echo "--- Organization Accounts ---"
  aws organizations list-accounts \
    --output text \
    --query 'Accounts[?Status==`ACTIVE`].[Id,Name,Email]' 2>/dev/null \
    | head -30 || echo "(Not a management account or Organizations API unavailable)"
}

# Detect credits and discount programs (MANDATORY second call)
aws_billing_credits() {
  _aws_billing_parse_args "$@"
  local days
  days=$(_aws_parse_days "${_DAYS}") || return 1

  local start end
  start=$(_aws_date_start "$days")
  end=$(_aws_date_end)

  local filter_args=()
  if [[ -n "$_ACCOUNT" ]]; then
    filter_args=(--filter "$(_aws_account_filter "$_ACCOUNT")")
  fi

  echo "=== Credit & Discount Detection (last ${days} days) ==="

  # Query both Unblended, NetUnblended, and Amortized to compute discount_ratio
  echo "--- Cost Metric Comparison ---"
  aws ce get-cost-and-usage \
    --time-period "Start=${start},End=${end}" \
    --granularity MONTHLY \
    --metrics "UnblendedCost" "NetUnblendedCost" "AmortizedCost" \
    "${filter_args[@]+"${filter_args[@]}"}" \
    --output json \
    --query 'ResultsByTime[].{Period:TimePeriod.Start,Unblended:Metrics.UnblendedCost.Amount,Net:Metrics.NetUnblendedCost.Amount,Amortized:Metrics.AmortizedCost.Amount}' \
    | python3 -c "
import json, sys
data = json.load(sys.stdin)
total_unblended = 0.0
total_net = 0.0
total_amortized = 0.0
for row in data:
    ub = float(row['Unblended'])
    net = float(row['Net'])
    am = float(row['Amortized'])
    total_unblended += ub
    total_net += net
    total_amortized += am
    print(f'{row[\"Period\"]}  Unblended: \${ub:,.2f}  Net: \${net:,.2f}  Amortized: \${am:,.2f}')

print()
if total_unblended > 0:
    discount_ratio = (total_unblended - total_net) / total_unblended
    ri_sp_effect = total_amortized - total_unblended
    print(f'Totals:  Unblended: \${total_unblended:,.2f}  Net: \${total_net:,.2f}  Amortized: \${total_amortized:,.2f}')
    print(f'discount_ratio: {discount_ratio:.4f}  (> 0.5 = heavily discounted)')
    print(f'ri_sp_amortization_effect: \${ri_sp_effect:,.2f}')
    if discount_ratio > 0.5:
        print('INTERPRETATION: Heavy credit/discount coverage (RI/SP/EDP/credits)')
    elif discount_ratio > 0.1:
        print('INTERPRETATION: Moderate discounts (typical for RI/SP usage)')
    else:
        print('INTERPRETATION: Minimal discounts -- mostly on-demand pricing')
else:
    print('No billing data found for the requested period.')
"
}

# Top 15 services by net cost
aws_billing_summary() {
  _aws_billing_parse_args "$@"
  local days
  days=$(_aws_parse_days "${_DAYS}") || return 1

  local start end
  start=$(_aws_date_start "$days")
  end=$(_aws_date_end)

  local filter
  filter=$(_aws_build_filter "$_ACCOUNT")

  echo "=== Top Services by Net Cost (last ${days} days) ==="
  aws ce get-cost-and-usage \
    --time-period "Start=${start},End=${end}" \
    --granularity MONTHLY \
    --metrics "${_AWS_DEFAULT_METRIC}" \
    --group-by Type=DIMENSION,Key=SERVICE \
    --filter "$filter" \
    --output text \
    --query 'ResultsByTime[].Groups[].[Keys[0],Metrics.NetUnblendedCost.Amount]' \
    | awk '{svc=$1; for(i=2;i<NF;i++) svc=svc" "$i; cost=$NF; a[svc]+=cost} END{for(s in a) printf "%12.2f USD  %s\n", a[s], s}' \
    | sort -rn | head -15
}

# Cost trend (monthly or daily)
aws_billing_trend() {
  _aws_billing_parse_args "$@"
  local days
  days=$(_aws_parse_days "${_DAYS}") || return 1

  local start end granularity
  start=$(_aws_date_start "$days")
  end=$(_aws_date_end)

  if [[ "$_DAILY" == true ]]; then
    granularity="DAILY"
  else
    granularity="MONTHLY"
  fi

  local filter_args=()
  if [[ -n "$_ACCOUNT" ]]; then
    filter_args=(--filter "$(_aws_account_filter "$_ACCOUNT")")
  fi

  echo "=== Cost Trend (${granularity}, last ${days} days) ==="
  aws ce get-cost-and-usage \
    --time-period "Start=${start},End=${end}" \
    --granularity "$granularity" \
    --metrics "${_AWS_DEFAULT_METRIC}" \
    "${filter_args[@]+"${filter_args[@]}"}" \
    --output text \
    --query 'ResultsByTime[].[TimePeriod.Start,Metrics.NetUnblendedCost.Amount,Metrics.NetUnblendedCost.Unit]' \
    | awk '{printf "%s  %12.2f %s\n", $1, $2, $3}'
}

# Z-score anomaly detection on net cost (45-day lookback, daily)
aws_billing_anomalies() {
  _aws_billing_parse_args "$@"

  local start end
  start=$(_aws_date_start 45)
  end=$(_aws_date_end)

  local filter_args=()
  if [[ -n "$_ACCOUNT" ]]; then
    filter_args=(--filter "$(_aws_account_filter "$_ACCOUNT")")
  fi

  echo "=== Cost Anomaly Detection (45-day daily, NetUnblendedCost) ==="
  aws ce get-cost-and-usage \
    --time-period "Start=${start},End=${end}" \
    --granularity DAILY \
    --metrics "${_AWS_DEFAULT_METRIC}" \
    "${filter_args[@]+"${filter_args[@]}"}" \
    --output json \
    --query 'ResultsByTime[].{Date:TimePeriod.Start,Cost:Metrics.NetUnblendedCost.Amount}' \
    | python3 -c "
import json, sys, math
data = json.load(sys.stdin)
costs = [(d['Date'], float(d['Cost'])) for d in data]
if len(costs) < 7:
    print('ERROR: Need at least 7 days of data for anomaly detection')
    sys.exit(0)

values = [c for _, c in costs]
mean = sum(values) / len(values)
variance = sum((v - mean) ** 2 for v in values) / len(values)
std = math.sqrt(variance) if variance > 0 else 0.01

print(f'Mean daily cost: \${mean:,.2f}  Std dev: \${std:,.2f}')
print()
anomalies = []
for date, cost in costs:
    z = (cost - mean) / std if std > 0 else 0
    if abs(z) > 2.0:
        direction = 'SPIKE' if z > 0 else 'DROP'
        anomalies.append((date, cost, z, direction))

if anomalies:
    print(f'Anomalies detected (|z-score| > 2.0):')
    for date, cost, z, direction in anomalies:
        print(f'  {date}  \${cost:,.2f}  z={z:+.2f}  {direction}')
else:
    print('No anomalies detected.')
"
}

# Top 20 usage types by net cost
aws_billing_by_usage_type() {
  _aws_billing_parse_args "$@"
  local days
  days=$(_aws_parse_days "${_DAYS}") || return 1

  local start end
  start=$(_aws_date_start "$days")
  end=$(_aws_date_end)

  local filter
  filter=$(_aws_build_filter "$_ACCOUNT")

  echo "=== Top Usage Types by Net Cost (last ${days} days) ==="
  aws ce get-cost-and-usage \
    --time-period "Start=${start},End=${end}" \
    --granularity MONTHLY \
    --metrics "${_AWS_DEFAULT_METRIC}" \
    --group-by Type=DIMENSION,Key=USAGE_TYPE \
    --filter "$filter" \
    --output text \
    --query 'ResultsByTime[].Groups[].[Keys[0],Metrics.NetUnblendedCost.Amount]' \
    | awk '{type=$1; for(i=2;i<NF;i++) type=type" "$i; cost=$NF; a[type]+=cost} END{for(t in a) printf "%12.2f USD  %s\n", a[t], t}' \
    | sort -rn | head -20
}

# CE cost forecast with prediction intervals
aws_billing_forecast() {
  _aws_billing_parse_args "$@"
  local days="${_DAYS}"

  # Forecast start = tomorrow, end = N days from tomorrow
  local start end
  start=$(_aws_date_end_future 1)
  end=$(_aws_date_end_future "$((days + 1))")

  local filter_args=()
  if [[ -n "$_ACCOUNT" ]]; then
    filter_args=(--filter "$(_aws_account_filter "$_ACCOUNT")")
  fi

  # Determine granularity: DAILY for <=90 days, MONTHLY otherwise
  local granularity="MONTHLY"
  if [[ "$days" -le 90 ]]; then
    granularity="DAILY"
  fi

  echo "=== Cost Forecast (${granularity}, next ${days} days) ==="
  aws ce get-cost-forecast \
    --time-period "Start=${start},End=${end}" \
    --granularity "$granularity" \
    --metric "${_AWS_FORECAST_METRIC}" \
    "${filter_args[@]+"${filter_args[@]}"}" \
    --output json \
    --query '{Total:Total,ForecastResults:ForecastResultsByTime[].{Period:TimePeriod.Start,Mean:MeanValue,Lower:PredictionIntervalLowerBound,Upper:PredictionIntervalUpperBound}}' \
    | python3 -c "
import json, sys
data = json.load(sys.stdin)
total = data.get('Total', {})
if total:
    amt = float(total.get('Amount', 0))
    unit = total.get('Unit', 'USD')
    print(f'Total forecast: \${amt:,.2f} {unit}')
    print()

results = data.get('ForecastResults', [])
for r in results[:30]:
    mean = float(r.get('Mean', 0))
    lower = r.get('Lower')
    upper = r.get('Upper')
    line = f'{r[\"Period\"]}  Mean: \${mean:,.2f}'
    if lower and upper:
        line += f'  Range: \${float(lower):,.2f} - \${float(upper):,.2f}'
    print(line)
"
}

# RI and Savings Plan utilization
aws_billing_ri_sp() {
  _aws_billing_parse_args "$@"
  local days
  days=$(_aws_parse_days "${_DAYS}") || return 1

  local start end
  start=$(_aws_date_start "$days")
  end=$(_aws_date_end)

  echo "=== RI & Savings Plan Utilization (last ${days} days) ==="

  echo ""
  echo "--- Reserved Instance Utilization ---"
  aws ce get-reservation-utilization \
    --time-period "Start=${start},End=${end}" \
    --granularity MONTHLY \
    --output text \
    --query 'UtilizationsByTime[].{Period:TimePeriod.Start,TotalHours:Total.TotalActualHours,UsedHours:Total.TotalActualUnits,Utilization:Total.UtilizationPercentage}' \
    2>/dev/null || echo "(No RI data available or no active RIs)"

  echo ""
  echo "--- Savings Plan Utilization ---"
  aws ce get-savings-plans-utilization \
    --time-period "Start=${start},End=${end}" \
    --granularity MONTHLY \
    --output text \
    --query 'SavingsPlansUtilizationsByTime[].{Period:TimePeriod.Start,Commitment:Total.TotalCommitment,Used:Total.UsedCommitment,Unused:Total.UnusedCommitment,Utilization:Total.UtilizationPercentage}' \
    2>/dev/null || echo "(No Savings Plan data available or no active SPs)"

  echo ""
  echo "--- Savings Plan Coverage ---"
  aws ce get-savings-plans-coverage \
    --time-period "Start=${start},End=${end}" \
    --granularity MONTHLY \
    --group-by Type=DIMENSION,Key=SERVICE \
    --output text \
    --query 'SavingsPlansCoverages[].{Period:TimePeriod.Start,OnDemand:Coverage.OnDemandCost,SPCost:Coverage.SpendCoveredBySavingsPlans,Coverage:Coverage.CoveragePercentage}' \
    2>/dev/null || echo "(No Savings Plan coverage data available)"
}

# Multi-account cost comparison (no account filter)
aws_billing_compare() {
  _aws_billing_parse_args "$@"
  local days
  days=$(_aws_parse_days "${_DAYS}") || return 1

  local start end
  start=$(_aws_date_start "$days")
  end=$(_aws_date_end)

  echo "=== Multi-Account Cost Comparison (last ${days} days) ==="
  aws ce get-cost-and-usage \
    --time-period "Start=${start},End=${end}" \
    --granularity MONTHLY \
    --metrics "${_AWS_DEFAULT_METRIC}" \
    --group-by Type=DIMENSION,Key=LINKED_ACCOUNT \
    --filter '{"Dimensions":{"Key":"RECORD_TYPE","Values":["Usage"]}}' \
    --output text \
    --query 'ResultsByTime[].Groups[].[Keys[0],Metrics.NetUnblendedCost.Amount]' \
    | awk '{a[$1]+=$2} END{for(acct in a) printf "%12.2f USD  %s\n", a[acct], acct}' \
    | sort -rn | head -30
}
