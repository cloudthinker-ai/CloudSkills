---
name: optimizing-bedrock-costs
description: >-
  Generate actionable Bedrock cost optimization recommendations with estimated savings.
  Use when user asks to optimize Bedrock spending, reduce LLM costs, find Bedrock savings,
  improve prompt caching efficiency, evaluate model tiering, or review AI inference costs.
  Covers model downgrade opportunities (Opus to Sonnet/Haiku), cache efficiency tuning,
  batch inference candidates, cross-region cost arbitrage, token efficiency analysis,
  and prioritized recommendations with USD savings estimates.
connection_type: aws
preload: false
---

# Optimizing Bedrock Costs

Generate prioritized, actionable Bedrock cost optimization recommendations backed by real Cost Explorer data.

<critical>
- ALWAYS source aws-billing helper first: `source ./_skills/connections/aws/aws-billing/scripts/get_billing_aws.sh`
- ALWAYS run `aws_billing_account` before any CE queries.
- ALWAYS filter by `RecordType=Usage` to exclude credits.
- All cost/savings figures MUST include currency unit (USD).
- This skill complements `analyzing-bedrock-costs` — use that skill for raw cost/cache reporting, use THIS skill for optimization recommendations.
</critical>

## Quick Start

Run the full optimization analysis:

```bash
bash ./_skills/custom/optimizing-bedrock-costs/scripts/optimize.sh [--days N]
```

Default: 90 days. Outputs TSV sections for each optimization area.

## Optimization Areas

### 1. Model Tiering (Opus to Sonnet/Haiku Downgrade)

Opus models cost 5x more than Sonnet per token. Many workloads can run on Sonnet with equivalent quality.

**Detection**: Compare Opus vs Sonnet spend per region. If Opus > 30% of total model spend, flag for review.

**Savings estimate**:
```
Potential savings = Opus_cost * 0.80  (assuming 80% of Opus tasks can move to Sonnet)
Conservative savings = Opus_cost * 0.50
```

**Pricing reference (USD per 1M tokens)**:

| Model | Input | Cache Write | Cache Read | Output |
|-------|-------|-------------|------------|--------|
| Opus 4.5/4.6 | $15.00 | $18.75 | $1.50 | $75.00 |
| Sonnet 4.5/4.6 | $3.00 | $3.75 | $0.30 | $15.00 |
| Haiku 4.5 | $0.80 | $1.00 | $0.08 | $4.00 |

### 2. Cache Efficiency

Target: >60% hit ratio, >4x reuse ratio.

**Detection**: Pull token-level usage types, compute hit ratio and reuse ratio per month.

**Recommendations by finding**:

| Finding | Action | Priority |
|---------|--------|----------|
| Hit ratio < 40% | Restructure prompts: static prefix first, dynamic content last | P0 |
| Hit ratio 40-60% | Add cachePoint blocks at instruction boundaries | P1 |
| Reuse ratio < 2x | Prompts changing too frequently — stabilize system prompts | P0 |
| CacheWrite > 40% of input cost | Increase cache TTL, reduce prompt variation | P1 |

**Savings estimate**:
```
If hit_ratio improves from X% to 70%:
  Additional cached tokens = total_input_qty * (0.70 - X/100)
  Savings = additional_cached_tokens * (regular_rate - cache_read_rate)
```

### 3. Batch Inference Opportunities

Batch inference costs 50% less than on-demand for supported models.

**Detection**: Identify high-volume, non-real-time workloads by looking at:
- Cohere Embed/Rerank usage (typically batch-friendly)
- High token volumes in off-peak hours (requires CloudWatch if available)

**Savings estimate**: `batch_eligible_cost * 0.50`

### 4. Cross-Region Cost Arbitrage

Bedrock pricing varies by region. Compare per-model costs across active regions.

**Detection**: Group costs by REGION + SERVICE. Flag if same model is used in a more expensive region when a cheaper region is available.

### 5. Output Token Efficiency

Output tokens cost 5x input tokens. Reducing verbose outputs saves significantly.

**Detection**: Compare output token cost as % of total. If output > 40% of total token cost, flag for review.

**Recommendations**:
- Set `max_tokens` limits on API calls
- Use structured JSON output instead of verbose prose
- Implement response compression for downstream consumers

### 6. Unused/Low-Value Model Spend

Detect models with minimal usage that may be experimental or abandoned.

**Detection**: Any model with < $5/month spend across all regions.

## Output Format

The script outputs 6 sections. Section 6 ("UNIFIED SAVINGS SUMMARY") is the single source of truth for all savings figures.

<critical>
When building dashboards or reports from this script's output:
- ALWAYS use Section 6 values for KPI cards, table rows, and summary totals.
- NEVER compute savings independently in the dashboard — all figures must trace back to Section 6.
- The KPI "Est. Total Savings" MUST equal the TOTAL row from Section 6.
- The opportunities table summary row MUST equal the TOTAL row from Section 6.
- This prevents KPI vs table mismatch caused by independent calculations.
</critical>

### Section 6 Output Contract

```
area    priority    conservative    aggressive
Model Tiering    P0    {opus*0.50}    {opus*0.80}
Cache to 80%    P1    {cache_savings}    {cache_savings}
Batch Inference    P2    {search*0.50}    {search*0.50}
Output Tokens    P2    {output*0.10}    {output*0.20}
TOTAL    -    {sum of above}    {sum of above}
TOTAL_PCT    -    {conservative/total*100}%    {aggressive/total*100}%
TOTAL_SPEND    -    {total_spend}    {total_spend}
```

Dashboard mapping:
- KPI value: `$TOTAL_conservative - $TOTAL_aggressive USD`
- KPI trend: `+TOTAL_PCT_conservative-TOTAL_PCT_aggressive% of spend`
- Table rows: one per area line
- Table summaryRow: TOTAL line

Present as a dashboard artifact with:
- KPI row: Total spend, estimated savings (from TOTAL), savings % (from TOTAL_PCT), top opportunity
- Optimization opportunities table (rows from Section 6 areas)
- Model tiering analysis (Opus vs Sonnet vs Haiku spend breakdown)
- Cache efficiency gauges (hit ratio, reuse ratio vs targets)
- Monthly savings projection chart
- Prioritized recommendations callout

## Integration with analyzing-bedrock-costs

This skill builds on data from `analyzing-bedrock-costs`. The workflow:
1. Run `analyzing-bedrock-costs` for raw cost/cache data
2. Run this skill's `optimize.sh` for optimization-specific analysis
3. Use Section 6 output as the single source for all savings in dashboards
