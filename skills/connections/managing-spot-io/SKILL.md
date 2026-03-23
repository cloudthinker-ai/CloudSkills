---
name: managing-spot-io
description: |
  Use when working with Spot Io — spot.io and Ocean cluster cost optimization
  for Kubernetes and cloud workloads. Covers cluster cost optimization, workload
  right-sizing, savings analysis, spot instance management, and infrastructure
  scaling. Use when optimizing cloud spend through spot instances, analyzing
  cluster efficiency, or managing Ocean clusters.
connection_type: spot-io
preload: false
---

# Spot.io / Ocean Management Skill

Manage and optimize cloud infrastructure costs with Spot.io and Ocean for Kubernetes.

## MANDATORY: Discovery-First Pattern

**Always list accounts and clusters before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash

spot_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"
    local base_url="https://api.spotinst.io"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $SPOT_TOKEN" \
            -H "Content-Type: application/json" \
            "${base_url}/${endpoint}" -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $SPOT_TOKEN" \
            "${base_url}/${endpoint}"
    fi
}

echo "=== Spot.io Account Info ==="
spot_api GET "setup/account" | jq -r '.response.items[] | "\(.accountId)\t\(.name)"' | column -t

echo ""
echo "=== Ocean Clusters ==="
spot_api GET "ocean/aws/k8s/cluster" | jq -r '
    .response.items[] | "\(.id)\t\(.name)\t\(.controllerClusterId)\t\(.region)"
' | column -t

echo ""
echo "=== Elastigroup Summary ==="
spot_api GET "aws/ec2/group" | jq -r '
    .response.items[] | "\(.id)\t\(.name)\t\(.capacity.target) instances\t\(.strategy.risk)% spot"
' | column -t | head -20
```

## Core Helper Functions

```bash
#!/bin/bash

spot_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"
    if [ -n "$data" ]; then
        curl -s -X "$method" -H "Authorization: Bearer $SPOT_TOKEN" \
            -H "Content-Type: application/json" \
            "https://api.spotinst.io/${endpoint}" -d "$data"
    else
        curl -s -X "$method" -H "Authorization: Bearer $SPOT_TOKEN" \
            "https://api.spotinst.io/${endpoint}"
    fi
}

spot_ocean() {
    local endpoint="$1"
    spot_api GET "ocean/aws/k8s/${endpoint}"
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines per output
- Use jq to filter API responses to relevant cost and scaling fields
- Round savings percentages and costs to 2 decimal places

## Common Operations

### Cluster Cost Optimization Report

```bash
#!/bin/bash
CLUSTER_ID="${1:?Ocean cluster ID required}"

echo "=== Ocean Cluster Cost Summary ==="
spot_api GET "ocean/aws/k8s/cluster/${CLUSTER_ID}/aggregatedCosts?startTime=$(date -u -d '7 days ago' +%Y-%m-%d)&endTime=$(date -u +%Y-%m-%d)" | jq '{
    totalCost: .response.items[0].totalCost,
    spotCost: .response.items[0].spotCost,
    onDemandCost: .response.items[0].onDemandCost,
    savings: .response.items[0].savings,
    savingsPercentage: .response.items[0].savingsPercentage
}'

echo ""
echo "=== Cost by Namespace ==="
spot_api GET "ocean/aws/k8s/cluster/${CLUSTER_ID}/aggregatedCosts?startTime=$(date -u -d '7 days ago' +%Y-%m-%d)&endTime=$(date -u +%Y-%m-%d)&groupBy=namespace" | jq -r '
    .response.items[] |
    "\(.namespace)\t$\(.totalCost | . * 100 | round / 100)\tSavings: \(.savingsPercentage | . * 100 | round / 100)%"
' | sort -t'$' -k2 -rn | column -t | head -15
```

### Workload Right-Sizing

```bash
#!/bin/bash
CLUSTER_ID="${1:?Ocean cluster ID required}"

echo "=== Right-Sizing Recommendations ==="
spot_api GET "ocean/aws/k8s/cluster/${CLUSTER_ID}/rightSizing/suggestion" | jq -r '
    .response.items[] |
    "\(.namespace)/\(.workloadName)\tCPU: \(.currentCpu)→\(.suggestedCpu)\tMem: \(.currentMemory)→\(.suggestedMemory)\tSavings: $\(.monthlySavings | . * 100 | round / 100)/mo"
' | sort -t'$' -k4 -rn | column -t | head -20
```

### Savings Analysis

```bash
#!/bin/bash
echo "=== Overall Savings Summary ==="
spot_api GET "ocean/aws/k8s/cluster" | jq -r '.response.items[].id' | while read cid; do
    NAME=$(spot_api GET "ocean/aws/k8s/cluster/${cid}" | jq -r '.response.items[0].name')
    SAVINGS=$(spot_api GET "ocean/aws/k8s/cluster/${cid}/aggregatedCosts?startTime=$(date -u -d '30 days ago' +%Y-%m-%d)&endTime=$(date -u +%Y-%m-%d)" | jq '.response.items[0]')
    echo "$NAME ($cid)"
    echo "$SAVINGS" | jq '"\tTotal: $\(.totalCost | . * 100 | round / 100)\tSaved: $\(.savings | . * 100 | round / 100)\t(\(.savingsPercentage | . * 100 | round / 100)%)"'
done

echo ""
echo "=== Spot Instance Usage ==="
spot_api GET "aws/ec2/group" | jq -r '
    .response.items[] |
    "\(.name)\tTarget: \(.capacity.target)\tSpot: \(.strategy.risk)%\tFallback: \(.strategy.fallbackToOd // false)"
' | column -t | head -15
```

### Node Scaling Events

```bash
#!/bin/bash
CLUSTER_ID="${1:?Ocean cluster ID required}"

echo "=== Recent Scaling Events ==="
spot_api GET "ocean/aws/k8s/cluster/${CLUSTER_ID}/log?fromDate=$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)&limit=30" | jq -r '
    .response.items[] |
    "\(.createdAt[0:16])\t\(.message[0:80])"
' | head -20

echo ""
echo "=== Current Node Pool Status ==="
spot_api GET "ocean/aws/k8s/cluster/${CLUSTER_ID}/nodes" | jq -r '
    .response.items[] |
    "\(.instanceId)\t\(.instanceType)\t\(.lifeCycle)\t\(.availabilityZone)\t\(.nodeStatus)"
' | column -t | head -20
```

### Elastigroup Management

```bash
#!/bin/bash
GROUP_ID="${1:?Elastigroup ID required}"

echo "=== Elastigroup Status ==="
spot_api GET "aws/ec2/group/${GROUP_ID}" | jq '{
    name: .response.items[0].name,
    target: .response.items[0].capacity.target,
    min: .response.items[0].capacity.minimum,
    max: .response.items[0].capacity.maximum,
    spotPercentage: .response.items[0].strategy.risk,
    region: .response.items[0].region
}'

echo ""
echo "=== Active Instances ==="
spot_api GET "aws/ec2/group/${GROUP_ID}/status" | jq -r '
    .response.items[] |
    "\(.instanceId)\t\(.instanceType)\t\(.product)\t\(.availabilityZone)\t\(.privateIp)"
' | column -t | head -15
```

## Safety Rules
- **Read-only queries first**: Always review current state before scaling or modifying groups
- **Fallback to on-demand**: Ensure `fallbackToOd` is enabled before relying on spot instances
- **Capacity minimums**: Never set minimum capacity to 0 for production workloads
- **Gradual changes**: When adjusting spot percentage, change incrementally (10-20% at a time)

## Output Format

Present results as a structured report:
```
Managing Spot Io Report
═══════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

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
- **Token scope**: Spot API tokens are account-scoped -- ensure correct account context
- **Ocean vs Elastigroup**: Ocean is Kubernetes-native; Elastigroup is for generic EC2 -- do not confuse APIs
- **Spot interruptions**: High spot percentage without on-demand fallback risks availability
- **Right-sizing lag**: Recommendations need 3-7 days of data to stabilize
- **Region mismatch**: Ensure cluster region matches when querying aggregated costs
- **Controller connectivity**: Ocean requires the Spot controller running in-cluster -- check controller pod health
