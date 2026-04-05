#!/usr/bin/env bash
# Bedrock Cost Optimization Analysis
# Usage: bash optimize.sh [--days N]
# Default: 90 days. Outputs structured optimization findings.

set -euo pipefail

DAYS=90
while [[ $# -gt 0 ]]; do
  case $1 in
    --days) DAYS="$2"; shift 2 ;;
    *) echo "Usage: $0 [--days N]"; exit 1 ;;
  esac
done

END_DATE=$(date -u +%Y-%m-%d)
START_DATE=$(date -u -d "${DAYS} days ago" +%Y-%m-%d 2>/dev/null || date -u -v-${DAYS}d +%Y-%m-%d)

echo "=== Bedrock Cost Optimization Analysis ==="
echo "Period: ${START_DATE} to ${END_DATE}"
echo ""

BEDROCK_SERVICES='["Claude Sonnet 4.5 (Amazon Bedrock Edition)","Claude Opus 4.5 (Amazon Bedrock Edition)","Claude Haiku 4.5 (Amazon Bedrock Edition)","Claude Sonnet 4.6 (Amazon Bedrock Edition)","Claude Opus 4.6 (Amazon Bedrock Edition)","Claude 3.5 Haiku (Amazon Bedrock Edition)","Amazon Bedrock","Cohere Embed Model 3 - Multilingual (Amazon Bedrock Edition)","Cohere Rerank v3.5 (Amazon Bedrock Edition)","Cohere Embed 4 Model (Amazon Bedrock Edition)"]'

FILTER="{\"And\":[{\"Dimensions\":{\"Key\":\"RECORD_TYPE\",\"Values\":[\"Usage\"]}},{\"Dimensions\":{\"Key\":\"SERVICE\",\"Values\":${BEDROCK_SERVICES}}}]}"

# --- Query 1: Model costs by region ---
echo "=== 1. MODEL TIERING ANALYSIS ==="
MODEL_DATA=$(aws ce get-cost-and-usage \
  --time-period Start=${START_DATE},End=${END_DATE} \
  --granularity MONTHLY \
  --metrics NetUnblendedCost \
  --filter "${FILTER}" \
  --group-by Type=DIMENSION,Key=SERVICE Type=DIMENSION,Key=REGION \
  --output json)

echo "${MODEL_DATA}" | jq -r '
  # Aggregate across all months
  [.ResultsByTime[].Groups[] | {
    service: .Keys[0],
    region: .Keys[1],
    cost: (.Metrics.NetUnblendedCost.Amount | tonumber)
  }] | group_by(.service) | map({
    service: .[0].service,
    total: (map(.cost) | add),
    regions: (group_by(.region) | map({region: .[0].region, cost: (map(.cost) | add)}))
  }) | sort_by(-.total) | .[] |
  select(.total > 0.01) |
  "\(.service)\t\(.total | . * 100 | round / 100)\t\(.regions | map("\(.region)=$\(.cost | . * 100 | round / 100)") | join(","))"'

echo ""

# Model tier classification and savings
echo "=== MODEL TIER SUMMARY ==="
echo "${MODEL_DATA}" | jq -r '
  [.ResultsByTime[].Groups[] | {
    service: .Keys[0],
    cost: (.Metrics.NetUnblendedCost.Amount | tonumber)
  }] |
  {
    opus: ([.[] | select(.service | test("Opus")) | .cost] | add // 0),
    sonnet: ([.[] | select(.service | test("Sonnet")) | .cost] | add // 0),
    haiku: ([.[] | select(.service | test("Haiku")) | .cost] | add // 0),
    other: ([.[] | select(.service | test("Opus|Sonnet|Haiku") | not) | .cost] | add // 0)
  } |
  . + { total: (.opus + .sonnet + .haiku + .other) } |
  "opus_cost\t\(.opus | . * 100 | round / 100)",
  "sonnet_cost\t\(.sonnet | . * 100 | round / 100)",
  "haiku_cost\t\(.haiku | . * 100 | round / 100)",
  "other_cost\t\(.other | . * 100 | round / 100)",
  "total_cost\t\(.total | . * 100 | round / 100)",
  "opus_pct\t\(if .total > 0 then (.opus / .total * 100 | . * 10 | round / 10) else 0 end)",
  "sonnet_pct\t\(if .total > 0 then (.sonnet / .total * 100 | . * 10 | round / 10) else 0 end)",
  "haiku_pct\t\(if .total > 0 then (.haiku / .total * 100 | . * 10 | round / 10) else 0 end)",
  "opus_to_sonnet_savings\t\(.opus * 0.80 | . * 100 | round / 100)",
  "opus_to_sonnet_conservative\t\(.opus * 0.50 | . * 100 | round / 100)"'

echo ""

# --- Query 2: Token usage types for cache analysis ---
echo "=== 2. CACHE EFFICIENCY ANALYSIS ==="
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
    output_cost_pct: (if .total_cost > 0 then (.output_cost / .total_cost * 100 | . * 10 | round / 10) else 0 end),
    cachewrite_cost_pct: (if .total_cost > 0 then (.cache_write_cost / .total_cost * 100 | . * 10 | round / 10) else 0 end)
  } |
  "\(.month)\thit_ratio=\(.hit_ratio)%\treuse=\(.reuse_ratio)x\toutput_pct=\(.output_cost_pct)%\tcw_pct=\(.cachewrite_cost_pct)%\ttotal=$\(.total_cost | . * 100 | round / 100)"'

echo ""

# --- Aggregated cache savings potential ---
echo "=== 3. CACHE SAVINGS POTENTIAL ==="
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
    cache_read_cost: ([.[] | select(.type | test("CacheReadInputTokenCount")) | .cost] | add // 0),
    cache_write_cost: ([.[] | select(.type | test("CacheWriteInputTokenCount")) | .cost] | add // 0),
    input_cost: ([.[] | select(.type | test("InputTokenCount")) | select(.type | test("Cache") | not) | .cost] | add // 0),
    output_cost: ([.[] | select(.type | test("OutputTokenCount")) | .cost] | add // 0)
  } |
  . + { total_input_qty: (.cache_read_qty + .cache_write_qty + .input_qty) } |
  . + {
    current_hit_ratio: (if .total_input_qty > 0 then (.cache_read_qty / .total_input_qty * 100 | . * 10 | round / 10) else 0 end),
    current_reuse: (if .cache_write_qty > 0 then (.cache_read_qty / .cache_write_qty | . * 100 | round / 100) else 0 end),
    regular_rate: (if .cache_write_qty > 0 then (.cache_write_cost / .cache_write_qty / 1.25) else 0 end),
    cache_read_rate: (if .cache_read_qty > 0 then (.cache_read_cost / .cache_read_qty) else 0 end)
  } |
  . + {
    no_cache_cost: (.total_input_qty * .regular_rate),
    current_input_cost: (.cache_read_cost + .cache_write_cost + .input_cost),
    total_cost: (.cache_read_cost + .cache_write_cost + .input_cost + .output_cost)
  } |
  . + {
    current_savings: (.no_cache_cost - .current_input_cost),
    current_savings_pct: (if .no_cache_cost > 0 then ((.no_cache_cost - .current_input_cost) / .no_cache_cost * 100 | . * 10 | round / 10) else 0 end)
  } |
  # Project savings if hit ratio improved to 80%
  . + {
    target_hit_ratio: 80,
    additional_cacheable: (if .current_hit_ratio < 80 then (.total_input_qty * (0.80 - .current_hit_ratio / 100)) else 0 end)
  } |
  . + {
    additional_savings: (.additional_cacheable * (.regular_rate - .cache_read_rate))
  } |
  "current_hit_ratio\t\(.current_hit_ratio)%",
  "current_reuse_ratio\t\(.current_reuse)x",
  "current_cache_savings\t$\(.current_savings | . * 100 | round / 100)",
  "current_savings_pct\t\(.current_savings_pct)%",
  "total_cost\t$\(.total_cost | . * 100 | round / 100)",
  "no_cache_baseline\t$\(.no_cache_cost | . * 100 | round / 100)",
  "target_hit_ratio\t80%",
  "additional_savings_at_80pct\t$\(.additional_savings | . * 100 | round / 100)",
  "output_cost\t$\(.output_cost | . * 100 | round / 100)",
  "output_cost_pct\t\(if .total_cost > 0 then (.output_cost / .total_cost * 100 | . * 10 | round / 10) else 0 end)%",
  "cachewrite_cost\t$\(.cache_write_cost | . * 100 | round / 100)",
  "cachewrite_pct\t\(if .total_cost > 0 then (.cache_write_cost / .total_cost * 100 | . * 10 | round / 10) else 0 end)%"'

echo ""

# --- Query 3: Regional cost comparison ---
echo "=== 4. CROSS-REGION ANALYSIS ==="
aws ce get-cost-and-usage \
  --time-period Start=${START_DATE},End=${END_DATE} \
  --granularity MONTHLY \
  --metrics NetUnblendedCost \
  --filter "${FILTER}" \
  --group-by Type=DIMENSION,Key=REGION \
  --output json | jq -r '
  .ResultsByTime[] |
  .TimePeriod.Start as $month |
  .Groups[] |
  select((.Metrics.NetUnblendedCost.Amount | tonumber) > 0.001) |
  "\($month)\t\(.Keys[0])\t\(.Metrics.NetUnblendedCost.Amount | tonumber | . * 100 | round / 100)"' | sort -t$'\t' -k1,1 -k3,3rn

echo ""

# --- Query 4: Monthly trend for MoM change ---
echo "=== 5. MONTH-OVER-MONTH TREND ==="
echo "${MODEL_DATA}" | jq -r '
  [.ResultsByTime[] | {
    month: .TimePeriod.Start,
    total: ([.Groups[].Metrics.NetUnblendedCost.Amount | tonumber] | add // 0)
  }] | sort_by(.month) |
  . as $months |
  range(length) | . as $i |
  $months[$i] |
  . + {
    prev: (if $i > 0 then $months[$i-1].total else null end),
    mom_change: (if $i > 0 and $months[$i-1].total > 0 then
      ((.total - $months[$i-1].total) / $months[$i-1].total * 100 | . * 10 | round / 10)
    else null end)
  } |
  "\(.month)\t$\(.total | . * 100 | round / 100)\t\(if .mom_change then "\(.mom_change)%" else "N/A" end)"'

echo ""

# --- Section 6: UNIFIED SAVINGS SUMMARY ---
# Single-source-of-truth: computes all line items and totals in one pass
# to prevent KPI vs table mismatch
echo "=== 6. UNIFIED SAVINGS SUMMARY ==="

# Extract opus_cost from MODEL_DATA
OPUS_COST=$(echo "${MODEL_DATA}" | jq -r '
  [.ResultsByTime[].Groups[] | select(.Keys[0] | test("Opus")) |
   (.Metrics.NetUnblendedCost.Amount | tonumber)] | add // 0')

# Extract total_cost from MODEL_DATA
TOTAL_COST=$(echo "${MODEL_DATA}" | jq -r '
  [.ResultsByTime[].Groups[] |
   (.Metrics.NetUnblendedCost.Amount | tonumber)] | add // 0')

# Extract cache and output metrics from TOKEN_DATA
read CACHE_SAVINGS OUTPUT_COST SEARCH_COST < <(echo "${TOKEN_DATA}" | jq -r '
  [.ResultsByTime[].Groups[] | {
    type: .Keys[0],
    qty: (.Metrics.UsageQuantity.Amount | tonumber),
    cost: (.Metrics.NetUnblendedCost.Amount | tonumber)
  }] |
  {
    cr_qty: ([.[] | select(.type | test("CacheReadInputTokenCount")) | .qty] | add // 0),
    cw_qty: ([.[] | select(.type | test("CacheWriteInputTokenCount")) | .qty] | add // 0),
    in_qty: ([.[] | select(.type | test("InputTokenCount")) | select(.type | test("Cache") | not) | .qty] | add // 0),
    cr_cost: ([.[] | select(.type | test("CacheReadInputTokenCount")) | .cost] | add // 0),
    cw_cost: ([.[] | select(.type | test("CacheWriteInputTokenCount")) | .cost] | add // 0),
    in_cost: ([.[] | select(.type | test("InputTokenCount")) | select(.type | test("Cache") | not) | .cost] | add // 0),
    out_cost: ([.[] | select(.type | test("OutputTokenCount")) | .cost] | add // 0),
    search_cost: ([.[] | select(.type | test("search_units")) | .cost] | add // 0)
  } |
  . + { total_in: (.cr_qty + .cw_qty + .in_qty) } |
  . + {
    hit: (if .total_in > 0 then (.cr_qty / .total_in) else 0 end),
    reg_rate: (if .cw_qty > 0 then (.cw_cost / .cw_qty / 1.25) else 0 end),
    cr_rate: (if .cr_qty > 0 then (.cr_cost / .cr_qty) else 0 end)
  } |
  . + {
    add_cacheable: (if .hit < 0.80 then (.total_in * (0.80 - .hit)) else 0 end)
  } |
  . + {
    cache_savings: (.add_cacheable * (.reg_rate - .cr_rate))
  } |
  "\(.cache_savings) \(.out_cost) \(.search_cost)"')

# Compute all line items from the same source variables
python3 -c "
import json

opus = ${OPUS_COST}
total = ${TOTAL_COST}
cache_savings = ${CACHE_SAVINGS}
output_cost = ${OUTPUT_COST}
search_cost = ${SEARCH_COST}

# Line items
tiering_conservative = round(opus * 0.50, 2)
tiering_aggressive = round(opus * 0.80, 2)
cache_to_80 = round(cache_savings, 2)
batch_conservative = round(search_cost * 0.50, 2)
batch_aggressive = round(search_cost * 0.50, 2)
output_conservative = round(output_cost * 0.10, 2)
output_aggressive = round(output_cost * 0.20, 2)

# Totals derived from line items (single source of truth)
total_conservative = round(tiering_conservative + cache_to_80 + batch_conservative + output_conservative, 2)
total_aggressive = round(tiering_aggressive + cache_to_80 + batch_aggressive + output_aggressive, 2)
total_pct_conservative = round(total_conservative / total * 100, 1) if total > 0 else 0
total_pct_aggressive = round(total_aggressive / total * 100, 1) if total > 0 else 0

items = [
    {'area': 'Model Tiering', 'conservative': tiering_conservative, 'aggressive': tiering_aggressive, 'priority': 'P0'},
    {'area': 'Cache to 80%', 'conservative': cache_to_80, 'aggressive': cache_to_80, 'priority': 'P1'},
    {'area': 'Batch Inference', 'conservative': batch_conservative, 'aggressive': batch_aggressive, 'priority': 'P2'},
    {'area': 'Output Tokens', 'conservative': output_conservative, 'aggressive': output_aggressive, 'priority': 'P2'},
]

print('area\tpriority\tconservative\taggressive')
for i in items:
    print(f\"{i['area']}\t{i['priority']}\t{i['conservative']}\t{i['aggressive']}\")
print(f'TOTAL\t-\t{total_conservative}\t{total_aggressive}')
print(f'TOTAL_PCT\t-\t{total_pct_conservative}%\t{total_pct_aggressive}%')
print(f'TOTAL_SPEND\t-\t{round(total, 2)}\t{round(total, 2)}')
"

echo ""
echo "=== Analysis Complete ==="
