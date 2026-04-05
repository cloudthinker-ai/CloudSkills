#!/usr/bin/env bash
# Bedrock Cost Analysis Script
# Usage: bash analyze.sh [--days N]
# Default: 90 days

set -euo pipefail

# Parse args
DAYS=90
while [[ $# -gt 0 ]]; do
  case $1 in
    --days) DAYS="$2"; shift 2 ;;
    *) echo "Usage: $0 [--days N]"; exit 1 ;;
  esac
done

# Date range
END_DATE=$(date -u +%Y-%m-%d)
START_DATE=$(date -u -d "${DAYS} days ago" +%Y-%m-%d 2>/dev/null || date -u -v-${DAYS}d +%Y-%m-%d)

echo "=== Bedrock Cost Analysis ==="
echo "Period: ${START_DATE} to ${END_DATE}"
echo "Filter: RecordType=Usage (excluding credits)"
echo ""

# Bedrock service list
BEDROCK_SERVICES='["Claude Sonnet 4.5 (Amazon Bedrock Edition)","Claude Opus 4.5 (Amazon Bedrock Edition)","Claude Haiku 4.5 (Amazon Bedrock Edition)","Claude Sonnet 4.6 (Amazon Bedrock Edition)","Claude Opus 4.6 (Amazon Bedrock Edition)","Claude 3.5 Haiku (Amazon Bedrock Edition)","Amazon Bedrock","Cohere Embed Model 3 - Multilingual (Amazon Bedrock Edition)","Cohere Rerank v3.5 (Amazon Bedrock Edition)","Cohere Embed 4 Model (Amazon Bedrock Edition)"]'

FILTER="{\"And\":[{\"Dimensions\":{\"Key\":\"RECORD_TYPE\",\"Values\":[\"Usage\"]}},{\"Dimensions\":{\"Key\":\"SERVICE\",\"Values\":${BEDROCK_SERVICES}}}]}"

# --- Section 1: Model Cost Breakdown ---
echo "=== 1. MODEL COST BREAKDOWN (Monthly) ==="
aws ce get-cost-and-usage \
  --time-period Start=${START_DATE},End=${END_DATE} \
  --granularity MONTHLY \
  --metrics NetUnblendedCost \
  --filter "${FILTER}" \
  --group-by Type=DIMENSION,Key=SERVICE \
  --output json | jq -r '
  .ResultsByTime[] |
  .TimePeriod.Start as $month |
  .Groups[] |
  select((.Metrics.NetUnblendedCost.Amount | tonumber) > 0.001) |
  [$month, .Keys[0], (.Metrics.NetUnblendedCost.Amount | tonumber | . * 100 | round / 100 | tostring)] | @tsv'

echo ""

# --- Section 2: Token Usage Type Breakdown ---
echo "=== 2. TOKEN USAGE TYPE BREAKDOWN (Monthly) ==="
TOKEN_DATA=$(aws ce get-cost-and-usage \
  --time-period Start=${START_DATE},End=${END_DATE} \
  --granularity MONTHLY \
  --metrics NetUnblendedCost UsageQuantity \
  --filter "${FILTER}" \
  --group-by Type=DIMENSION,Key=USAGE_TYPE \
  --output json)

echo "${TOKEN_DATA}" | jq -r '
  .ResultsByTime[] |
  .TimePeriod.Start as $month |
  .Groups[] |
  select((.Metrics.NetUnblendedCost.Amount | tonumber) > 0.001) |
  [$month, .Keys[0],
   (.Metrics.UsageQuantity.Amount | tonumber | . * 100 | round / 100 | tostring),
   (.Metrics.NetUnblendedCost.Amount | tonumber | . * 100 | round / 100 | tostring)] | @tsv'

echo ""

# --- Section 3: Cache Hit Ratio & Savings ---
echo "=== 3. CACHE METRICS (Per Month) ==="
echo "${TOKEN_DATA}" | jq -r '
  .ResultsByTime[] |
  .TimePeriod.Start as $month |
  {month: $month, groups: [.Groups[] | {
    type: .Keys[0],
    qty: (.Metrics.UsageQuantity.Amount | tonumber),
    cost: (.Metrics.NetUnblendedCost.Amount | tonumber)
  }]} |
  {
    month: .month,
    cache_read_qty: ([.groups[] | select(.type | test("CacheReadInputTokenCount")) | .qty] | add // 0),
    cache_write_qty: ([.groups[] | select(.type | test("CacheWriteInputTokenCount")) | .qty] | add // 0),
    input_qty: ([.groups[] | select(.type | test("InputTokenCount")) | select(.type | test("Cache") | not) | .qty] | add // 0),
    output_qty: ([.groups[] | select(.type | test("OutputTokenCount")) | .qty] | add // 0),
    cache_read_cost: ([.groups[] | select(.type | test("CacheReadInputTokenCount")) | .cost] | add // 0),
    cache_write_cost: ([.groups[] | select(.type | test("CacheWriteInputTokenCount")) | .cost] | add // 0),
    input_cost: ([.groups[] | select(.type | test("InputTokenCount")) | select(.type | test("Cache") | not) | .cost] | add // 0),
    output_cost: ([.groups[] | select(.type | test("OutputTokenCount")) | .cost] | add // 0)
  } |
  . + {
    total_input_qty: (.cache_read_qty + .cache_write_qty + .input_qty),
    total_cost: (.cache_read_cost + .cache_write_cost + .input_cost + .output_cost)
  } |
  . + {
    hit_ratio: (if .total_input_qty > 0 then (.cache_read_qty / .total_input_qty * 100 | . * 10 | round / 10) else 0 end),
    reuse_ratio: (if .cache_write_qty > 0 then (.cache_read_qty / .cache_write_qty | . * 100 | round / 100) else 0 end),
    regular_rate: (if .cache_write_qty > 0 then (.cache_write_cost / .cache_write_qty / 1.25) else 0 end)
  } |
  . + {
    no_cache_cost: (.total_input_qty * .regular_rate),
    with_cache_cost: (.cache_read_cost + .cache_write_cost + .input_cost)
  } |
  . + {
    savings: (.no_cache_cost - .with_cache_cost),
    savings_pct: (if .no_cache_cost > 0 then ((.no_cache_cost - .with_cache_cost) / .no_cache_cost * 100 | . * 10 | round / 10) else 0 end)
  } |
  "Month: \(.month)",
  "  Cache Hit Ratio: \(.hit_ratio)%",
  "  Cache Reuse Ratio: \(.reuse_ratio)x",
  "  CacheRead: \(.cache_read_qty | . * 100 | round / 100)M tokens ($\(.cache_read_cost | . * 100 | round / 100))",
  "  CacheWrite: \(.cache_write_qty | . * 100 | round / 100)M tokens ($\(.cache_write_cost | . * 100 | round / 100))",
  "  Input (non-cache): \(.input_qty | . * 100 | round / 100)M tokens ($\(.input_cost | . * 100 | round / 100))",
  "  Output: \(.output_qty | . * 100 | round / 100)M tokens ($\(.output_cost | . * 100 | round / 100))",
  "  Total Cost: $\(.total_cost | . * 100 | round / 100)",
  "  No-Cache Baseline: $\(.no_cache_cost | . * 100 | round / 100)",
  "  Cache Savings: $\(.savings | . * 100 | round / 100) (\(.savings_pct)%)",
  ""'

echo ""

# --- Section 4: Aggregated Totals ---
echo "=== 4. QUARTERLY TOTALS ==="
echo "${TOKEN_DATA}" | jq -r '
  [.ResultsByTime[].Groups[] | {
    type: .Keys[0],
    qty: (.Metrics.UsageQuantity.Amount | tonumber),
    cost: (.Metrics.NetUnblendedCost.Amount | tonumber)
  }] |
  {
    cache_read_qty: ([.[] | select(.type | test("CacheReadInputTokenCount")) | .qty] | add // 0),
    cache_write_qty: ([.[] | select(.type | test("CacheWriteInputTokenCount")) | .qty] | add // 0),
    input_qty: ([.[] | select(.type | test("InputTokenCount")) | select(.type | test("Cache") | not) | .qty] | add // 0),
    output_qty: ([.[] | select(.type | test("OutputTokenCount")) | .qty] | add // 0),
    cache_read_cost: ([.[] | select(.type | test("CacheReadInputTokenCount")) | .cost] | add // 0),
    cache_write_cost: ([.[] | select(.type | test("CacheWriteInputTokenCount")) | .cost] | add // 0),
    input_cost: ([.[] | select(.type | test("InputTokenCount")) | select(.type | test("Cache") | not) | .cost] | add // 0),
    output_cost: ([.[] | select(.type | test("OutputTokenCount")) | .cost] | add // 0),
    search_cost: ([.[] | select(.type | test("search_units")) | .cost] | add // 0),
    other_cost: ([.[] | select(.type | test("TokenCount|search_units") | not) | .cost] | add // 0)
  } |
  . + {
    total_input_qty: (.cache_read_qty + .cache_write_qty + .input_qty),
    total_cost: (.cache_read_cost + .cache_write_cost + .input_cost + .output_cost + .search_cost + .other_cost)
  } |
  . + {
    hit_ratio: (if .total_input_qty > 0 then (.cache_read_qty / .total_input_qty * 100 | . * 10 | round / 10) else 0 end),
    reuse_ratio: (if .cache_write_qty > 0 then (.cache_read_qty / .cache_write_qty | . * 100 | round / 100) else 0 end),
    regular_rate: (if .cache_write_qty > 0 then (.cache_write_cost / .cache_write_qty / 1.25) else 0 end)
  } |
  . + {
    no_cache_cost: (.total_input_qty * .regular_rate),
    with_cache_cost: (.cache_read_cost + .cache_write_cost + .input_cost)
  } |
  . + {
    savings: (.no_cache_cost - .with_cache_cost),
    savings_pct: (if .no_cache_cost > 0 then ((.no_cache_cost - .with_cache_cost) / .no_cache_cost * 100 | . * 10 | round / 10) else 0 end)
  } |
  "Total Bedrock Spend: $\(.total_cost | . * 100 | round / 100)",
  "  CacheWrite: $\(.cache_write_cost | . * 100 | round / 100) (\(.cache_write_cost / .total_cost * 100 | . * 10 | round / 10)% of total)",
  "  CacheRead: $\(.cache_read_cost | . * 100 | round / 100) (\(.cache_read_cost / .total_cost * 100 | . * 10 | round / 10)% of total)",
  "  Input: $\(.input_cost | . * 100 | round / 100) (\(.input_cost / .total_cost * 100 | . * 10 | round / 10)% of total)",
  "  Output: $\(.output_cost | . * 100 | round / 100) (\(.output_cost / .total_cost * 100 | . * 10 | round / 10)% of total)",
  "  Other: $\(.other_cost | . * 100 | round / 100)",
  "",
  "Cache Hit Ratio: \(.hit_ratio)%",
  "Cache Reuse Ratio: \(.reuse_ratio)x",
  "Cache Savings: $\(.savings | . * 100 | round / 100) (\(.savings_pct)% vs no-cache)",
  "Annualized Savings: $\(.savings * 4 | . * 100 | round / 100)"'

echo ""
echo "=== Analysis Complete ==="
