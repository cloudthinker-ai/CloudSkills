---
name: managing-runpod
description: |
  Use when working with Runpod — runPod GPU cloud management covering pod
  inventory, serverless endpoint status, GPU type allocation, template
  configuration, volume management, spending analysis, and performance metrics.
  Use for comprehensive RunPod workspace assessment and GPU compute
  optimization.
connection_type: runpod
preload: false
---

# RunPod Management

Analyze RunPod pods, serverless endpoints, GPU allocation, and compute spend.

## Phase 1: Discovery

```bash
#!/bin/bash
TOKEN="${RUNPOD_API_KEY}"
BASE="https://api.runpod.io/graphql"

query() {
  curl -s "${BASE}?api_key=${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"query\": \"$1\"}"
}

echo "=== Pods Inventory ==="
query "{ myself { pods { id name runtime { uptimeInSeconds gpus { id gpuDisplayName gpuUtilPercent memoryUtilPercent } } desiredStatus imageName machineId machine { gpuDisplayName } costPerHr } } }" \
  | jq -r '.data.myself.pods[] | "\(.name)\t\(.id[0:12])\t\(.desiredStatus)\t\(.machine.gpuDisplayName // "N/A")\t$\(.costPerHr)/hr"' \
  | column -t | head -20

echo ""
echo "=== Serverless Endpoints ==="
query "{ myself { serverlessDiscount endpoints { id name gpuIds idleTimeout workersMax workersMin templateId } } }" \
  | jq -r '.data.myself.endpoints[]? | "\(.name)\t\(.id[0:12])\t\(.gpuIds | join(","))\tmin:\(.workersMin) max:\(.workersMax)\tidle:\(.idleTimeout)s"' \
  | column -t | head -20

echo ""
echo "=== Templates ==="
query "{ myself { podTemplates { id name imageName isPublic containerDiskInGb volumeInGb } } }" \
  | jq -r '.data.myself.podTemplates[]? | "\(.name)\t\(.id[0:12])\t\(.imageName[0:40])\tdisk:\(.containerDiskInGb)GB\tvol:\(.volumeInGb)GB"' \
  | column -t | head -15

echo ""
echo "=== Network Volumes ==="
query "{ myself { networkVolumes { id name size dataCenterId } } }" \
  | jq -r '.data.myself.networkVolumes[]? | "\(.name)\t\(.id[0:12])\t\(.size)GB\tdc:\(.dataCenterId)"' \
  | column -t | head -15
```

## Phase 2: Analysis

```bash
#!/bin/bash
TOKEN="${RUNPOD_API_KEY}"
BASE="https://api.runpod.io/graphql"

query() {
  curl -s "${BASE}?api_key=${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"query\": \"$1\"}"
}

echo "=== GPU Utilization ==="
query "{ myself { pods { name runtime { gpus { gpuDisplayName gpuUtilPercent memoryUtilPercent temperatureCelsius } } } } }" \
  | jq -r '.data.myself.pods[] | .name as $n | .runtime.gpus[]? | "\($n)\t\(.gpuDisplayName)\tutil:\(.gpuUtilPercent)%\tmem:\(.memoryUtilPercent)%\ttemp:\(.temperatureCelsius)C"' \
  | column -t | head -20

echo ""
echo "=== Pod Uptime ==="
query "{ myself { pods { name desiredStatus runtime { uptimeInSeconds } costPerHr } } }" \
  | jq -r '.data.myself.pods[] | "\(.name)\t\(.desiredStatus)\t\(.runtime.uptimeInSeconds // 0 | . / 3600 | floor)h uptime\t$\(.costPerHr)/hr"' \
  | column -t | head -15

echo ""
echo "=== Spending Estimate ==="
query "{ myself { pods { name costPerHr desiredStatus runtime { uptimeInSeconds } } } }" \
  | jq '{
    pods: [.data.myself.pods[] | {name, status: .desiredStatus, cost_hr: .costPerHr, uptime_hrs: ((.runtime.uptimeInSeconds // 0) / 3600 | round)}],
    total_hourly: [.data.myself.pods[] | select(.desiredStatus == "RUNNING") | .costPerHr] | add,
    total_daily_est: ([.data.myself.pods[] | select(.desiredStatus == "RUNNING") | .costPerHr] | add) * 24
  }'

echo ""
echo "=== Serverless Endpoint Workers ==="
query "{ myself { endpoints { name workersMin workersMax activeWorkers } } }" \
  | jq -r '.data.myself.endpoints[]? | "\(.name)\tactive:\(.activeWorkers // 0)\tmin:\(.workersMin)\tmax:\(.workersMax)"' \
  | column -t | head -10

echo ""
echo "=== Resource Summary ==="
query "{ myself { pods { id } endpoints { id } networkVolumes { id } podTemplates { id } } }" \
  | jq '{pods: (.data.myself.pods | length), endpoints: (.data.myself.endpoints | length), volumes: (.data.myself.networkVolumes | length), templates: (.data.myself.podTemplates | length)}'
```

## Output Format

```
RUNPOD ANALYSIS
=================
Pod              GPU          Util%  Mem%   Uptime   Cost/hr   Status
──────────────────────────────────────────────────────────────────────
ml-training      A100-80GB    87%    72%    48h      $2.49     RUNNING
inference-1      RTX-4090     45%    38%    12h      $0.69     RUNNING
dev-sandbox      RTX-3090     0%     0%     0h       $0.44     EXITED

Pods: 3 (2 running) | Endpoints: 2 serverless | Volumes: 2
Hourly Cost: $3.18 | Daily Est: $76.32
Templates: 4 | GPUs: A100(1) 4090(1) 3090(1)
```

## Safety Rules

- **Read-only**: Only use query operations, never mutations
- **Never start, stop, or terminate** pods without confirmation
- **API keys**: Never output API key values
- **Cost awareness**: Always highlight running cost estimates

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

