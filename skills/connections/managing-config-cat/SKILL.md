---
name: managing-config-cat
description: |
  ConfigCat feature flag management, remote configuration, A/B testing, targeting rules, and percentage-based rollouts. Covers flag listing, targeting rule management, environment overrides, audit log review, and SDK integration status. Use when managing feature flags, reviewing targeting rules, analyzing flag usage, or auditing configuration changes in ConfigCat.
connection_type: config-cat
preload: false
---

# ConfigCat Management Skill

Manage and analyze feature flags, configurations, targeting rules, and environments in ConfigCat.

## API Conventions

### Authentication
All API calls use Basic Auth with `$CONFIGCAT_USERNAME:$CONFIGCAT_PASSWORD` (Management API credentials). Never hardcode tokens.

### Base URL
`https://api.configcat.com/v1`

### Core Helper Function

```bash
#!/bin/bash

cc_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -u "${CONFIGCAT_USERNAME}:${CONFIGCAT_PASSWORD}" \
            -H "Content-Type: application/json" \
            "https://api.configcat.com/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -u "${CONFIGCAT_USERNAME}:${CONFIGCAT_PASSWORD}" \
            -H "Content-Type: application/json" \
            "https://api.configcat.com/v1${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target <=50 lines per script output
- Never dump full API responses

## Discovery Phase

### List Products and Configs

```bash
#!/bin/bash
echo "=== Products ==="
cc_api GET "/products" \
    | jq -r '.[] | "\(.productId[0:12])\t\(.name)"' | column -t

echo ""
PRODUCT_ID="${1:?Product ID required}"
echo "=== Configs ==="
cc_api GET "/products/${PRODUCT_ID}/configs" \
    | jq -r '.[] | "\(.configId[0:12])\t\(.name)"' | column -t

echo ""
echo "=== Environments ==="
cc_api GET "/products/${PRODUCT_ID}/environments" \
    | jq -r '.[] | "\(.environmentId[0:12])\t\(.name)"' | column -t
```

### List Feature Flags

```bash
#!/bin/bash
CONFIG_ID="${1:?Config ID required}"

echo "=== Feature Flags ==="
cc_api GET "/configs/${CONFIG_ID}/settings" \
    | jq -r '.[] | "\(.settingType)\t\(.key)\t\(.name[0:40])"' | column -t | head -25
```

## Analysis Phase

### Flag Values by Environment

```bash
#!/bin/bash
CONFIG_ID="${1:?Config ID required}"
ENVIRONMENT_ID="${2:?Environment ID required}"

echo "=== Flag Values ==="
cc_api GET "/configs/${CONFIG_ID}/environments/${ENVIRONMENT_ID}/values" \
    | jq -r '.[] | "\(.setting.key)\t\(.defaultValue.value)\t\(.rolloutRules | length) rules\t\(.percentageRules | length) %rules"' \
    | column -t | head -25
```

### Audit Log

```bash
#!/bin/bash
PRODUCT_ID="${1:?Product ID required}"

echo "=== Recent Changes ==="
cc_api GET "/products/${PRODUCT_ID}/auditlogs?count=20" \
    | jq -r '.items[] | "\(.auditLogDateTime[0:16])\t\(.userName)\t\(.actionTarget)\t\(.details[0:40])"' \
    | column -t

echo ""
echo "=== Flag Change Summary ==="
cc_api GET "/products/${PRODUCT_ID}/auditlogs?count=50" \
    | jq -r '.items[] | .actionTarget' | sort | uniq -c | sort -rn | head -10
```

## Output Format
- Use tab-separated columns with `column -t`
- Limit lists to 15-25 items
- Show summaries before details

## Common Pitfalls
- **Basic Auth**: Management API uses Basic Auth, not Bearer tokens
- **Setting types**: `boolean`, `string`, `int`, `double` -- type determines value format
- **Targeting rules**: Rules are evaluated top-to-bottom, first match wins
- **Percentage rollouts**: Percentages must sum to 100 -- validation is client-side
- **Config vs environment**: Flags are defined in configs, values are set per environment
- **Rate limits**: 5 management API requests per second
