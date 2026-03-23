---
name: managing-replicate
description: |
  Use when working with Replicate — replicate ML platform management covering
  model inventory, prediction history, deployment status, webhook configuration,
  training job analysis, hardware utilization, and billing metrics. Use for
  comprehensive Replicate workspace assessment and ML inference optimization.
connection_type: replicate
preload: false
---

# Replicate Management

Analyze Replicate models, predictions, deployments, and training jobs.

## Phase 1: Discovery

```bash
#!/bin/bash
TOKEN="${REPLICATE_API_TOKEN}"
BASE="https://api.replicate.com/v1"
AUTH=(-H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json")

echo "=== My Models ==="
curl -s "${BASE}/models" "${AUTH[@]}" \
  | jq -r '.results[] | "\(.owner)/\(.name)\t\(.visibility)\t\(.run_count)\t\(.latest_version.id[0:12] // "no-version")"' \
  | column -t | head -20

echo ""
echo "=== Deployments ==="
curl -s "${BASE}/deployments" "${AUTH[@]}" \
  | jq -r '.results[] | "\(.owner)/\(.name)\t\(.current_release.model)\t\(.current_release.version[0:12])\t\(.current_release.hardware)\t\(.min_instances)-\(.max_instances)"' \
  | column -t | head -15

echo ""
echo "=== Recent Predictions ==="
curl -s "${BASE}/predictions?limit=20" "${AUTH[@]}" \
  | jq -r '.results[] | "\(.model // .version[0:12])\t\(.status)\t\(.hardware // "default")\t\(.created_at[0:19])\t\(.metrics.predict_time // "N/A")s"' \
  | column -t | head -20

echo ""
echo "=== Collections ==="
curl -s "${BASE}/collections" "${AUTH[@]}" \
  | jq -r '.results[]? | "\(.slug)\t\(.name)\t\(.description[0:50])"' \
  | column -t | head -10
```

## Phase 2: Analysis

```bash
#!/bin/bash
TOKEN="${REPLICATE_API_TOKEN}"
BASE="https://api.replicate.com/v1"
AUTH=(-H "Authorization: Bearer ${TOKEN}" -H "Content-Type: application/json")

echo "=== Prediction Status Summary ==="
curl -s "${BASE}/predictions?limit=100" "${AUTH[@]}" \
  | jq -r '.results | group_by(.status) | .[] | "\(.[0].status): \(length)"'

echo ""
echo "=== Training Jobs ==="
curl -s "${BASE}/trainings?limit=10" "${AUTH[@]}" \
  | jq -r '.results[]? | "\(.model // "custom")\t\(.status)\t\(.hardware // "default")\t\(.created_at[0:19])\t\(.metrics.predict_time // "N/A")"' \
  | column -t | head -15

echo ""
echo "=== Hardware Usage ==="
curl -s "${BASE}/predictions?limit=100" "${AUTH[@]}" \
  | jq -r '.results | group_by(.hardware // "default") | .[] | "\(.[0].hardware // "default"): \(length) predictions"'

echo ""
echo "=== Failed Predictions ==="
curl -s "${BASE}/predictions?limit=50" "${AUTH[@]}" \
  | jq -r '.results[] | select(.status == "failed") | "\(.model // .version[0:12])\t\(.error[0:60])\t\(.created_at[0:19])"' \
  | column -t | head -10

echo ""
echo "=== Webhook Deliveries ==="
curl -s "${BASE}/predictions?limit=50" "${AUTH[@]}" \
  | jq -r '[.results[] | select(.webhook != null)] | length' \
  | xargs -I{} echo "Predictions with webhooks: {}"

echo ""
echo "=== Average Predict Time ==="
curl -s "${BASE}/predictions?limit=50" "${AUTH[@]}" \
  | jq '[.results[] | select(.metrics.predict_time != null) | .metrics.predict_time] | if length > 0 then "Avg: \(add / length | . * 100 | round / 100)s over \(length) predictions" else "No timing data" end'
```

## Output Format

```
REPLICATE ANALYSIS
====================
Model                   Runs     Hardware    Avg Time   Status
──────────────────────────────────────────────────────────────
user/sdxl-fine-tune     1,240    gpu-a40-lg  3.2s       active
user/whisper-custom     890      gpu-t4      12.5s      active
user/llama-ft           45       gpu-a100    8.1s       active

Predictions: 2,175 total (2,100 succeeded, 50 failed, 25 canceled)
Deployments: 2 active (min:1 max:5) | Trainings: 3 completed
Hardware: A40(60%) T4(30%) A100(10%)
```

## Safety Rules

- **Read-only**: Only use GET endpoints against the Replicate API
- **Never create predictions**, trainings, or deployments without confirmation
- **Webhooks**: Only report if configured, never expose webhook URLs
- **Rate limits**: Respect Replicate API rate limits

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

