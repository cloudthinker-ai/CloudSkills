---
name: managing-statsig
description: |
  Statsig feature gate management, dynamic configs, experiment analysis, and metric tracking. Covers gate configuration, rule-based targeting, holdout groups, A/B test results, pulse metrics, and layer management. Use when managing feature gates, reviewing experiment results, analyzing metric lifts, or configuring dynamic configs in Statsig.
connection_type: statsig
preload: false
---

# Statsig Management Skill

Manage and analyze feature gates, experiments, dynamic configs, and metrics in Statsig.

## API Conventions

### Authentication
All API calls use the `statsig-api-key: $STATSIG_CONSOLE_API_KEY` header (Console API key). Never hardcode tokens.

### Base URL
`https://statsigapi.net/console/v1`

### Core Helper Function

```bash
#!/bin/bash

statsig_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "statsig-api-key: $STATSIG_CONSOLE_API_KEY" \
            -H "Content-Type: application/json" \
            "https://statsigapi.net/console/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "statsig-api-key: $STATSIG_CONSOLE_API_KEY" \
            -H "Content-Type: application/json" \
            "https://statsigapi.net/console/v1${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target <=50 lines per script output
- Never dump full API responses

## Discovery Phase

### List Gates and Configs

```bash
#!/bin/bash
echo "=== Feature Gates ==="
statsig_api GET "/gates" \
    | jq -r '.data[] | "\(.isEnabled)\t\(.name)\t\(.rules | length) rules"' | column -t | head -25

echo ""
echo "=== Dynamic Configs ==="
statsig_api GET "/dynamic_configs" \
    | jq -r '.data[] | "\(.isEnabled)\t\(.name)"' | column -t | head -15
```

### List Experiments

```bash
#!/bin/bash
echo "=== Experiments ==="
statsig_api GET "/experiments" \
    | jq -r '.data[] | "\(.status)\t\(.name[0:40])\t\(.groups | length) groups"' | column -t | head -20

echo ""
echo "=== Experiment Status Summary ==="
statsig_api GET "/experiments" \
    | jq -r '.data[] | .status' | sort | uniq -c | sort -rn
```

## Analysis Phase

### Gate Details

```bash
#!/bin/bash
GATE_NAME="${1:?Gate name required}"

echo "=== Gate Details ==="
statsig_api GET "/gates/${GATE_NAME}" \
    | jq '.data | {name, isEnabled, description: .description[0:100], rules: [.rules[] | {name, passPercentage, conditions: (.conditions | length)}]}'
```

### Experiment Results

```bash
#!/bin/bash
EXPERIMENT_NAME="${1:?Experiment name required}"

echo "=== Experiment Details ==="
statsig_api GET "/experiments/${EXPERIMENT_NAME}" \
    | jq '.data | {name, status, hypothesis: .hypothesis[0:100], groups: [.groups[].name], primaryMetrics: .primaryMetrics}'

echo ""
echo "=== Pulse Results ==="
statsig_api GET "/experiments/${EXPERIMENT_NAME}/pulse" \
    | jq -r '.data.results[0:10][] | "\(.metric_name[0:30])\t\(.test_group)\tlifted:\(.lift // "pending")\tp:\(.p_value // "pending")"' \
    | column -t 2>/dev/null || echo "Results not yet available"
```

### Layers

```bash
#!/bin/bash
echo "=== Layers ==="
statsig_api GET "/layers" \
    | jq -r '.data[] | "\(.name)\t\(.experiments | length) experiments"' | column -t | head -15

echo ""
echo "=== Holdout Groups ==="
statsig_api GET "/holdouts" \
    | jq -r '.data[] | "\(.isEnabled)\t\(.name)\t\(.holdoutPercentage)%"' | column -t
```

## Output Format
- Use tab-separated columns with `column -t`
- Limit lists to 15-25 items
- Show summaries before details

## Common Pitfalls
- **Console vs server API**: Console API (`statsig-api-key` header) for management; Server API for evaluation
- **Gate rules**: Rules are evaluated top-to-bottom, first matching rule wins
- **Layers**: Layers allow mutually exclusive experiments -- users assigned to one experiment per layer
- **Holdouts**: Holdout groups exclude users from all experiments for measurement
- **Pulse**: Experiment results are in the pulse endpoint -- may take time to compute
- **Rate limits**: Console API has rate limits -- check response headers
