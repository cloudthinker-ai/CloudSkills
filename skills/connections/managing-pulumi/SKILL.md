---
name: managing-pulumi
description: |
  Pulumi infrastructure-as-code management. Covers stack management, preview/update workflows, configuration and secrets, state inspection, resource history, and policy packs. Use when managing Pulumi stacks, investigating deployment failures, managing secrets, or auditing infrastructure resources.
connection_type: pulumi
preload: false
---

# Pulumi Management Skill

Manage and inspect Pulumi stacks, configurations, secrets, and deployments.

## MANDATORY: Discovery-First Pattern

**Always list stacks and check current stack before modifying infrastructure.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Pulumi Version ==="
pulumi version 2>/dev/null

echo ""
echo "=== Available Stacks ==="
pulumi stack ls --json 2>/dev/null | jq -r '.[] | "\(.name)\t\(.current // false)\t\(.resourceCount // 0) resources\t\(.lastUpdate // "never")"' | column -t

echo ""
echo "=== Current Stack ==="
pulumi stack --json 2>/dev/null | jq '{name: .current, url: .url}'

echo ""
echo "=== Stack Outputs ==="
pulumi stack output --json 2>/dev/null | jq 'to_entries[] | {key: .key, value: .value}' | head -30
```

## Core Helper Functions

```bash
#!/bin/bash

# Pulumi wrapper with stack selection
pu_cmd() {
    pulumi "$@" --non-interactive 2>/dev/null
}

# Safe stack selection
pu_select_stack() {
    local stack="$1"
    pulumi stack select "$stack" --non-interactive 2>/dev/null
}

# Pulumi API call (for Pulumi Cloud)
pu_api() {
    local endpoint="$1"
    curl -s -H "Authorization: token $PULUMI_ACCESS_TOKEN" \
        "https://api.pulumi.com/api/$endpoint"
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `--json` output with jq filtering
- Never dump full stack exports -- extract key fields
- Use `--non-interactive` to prevent prompts

## Common Operations

### Stack Resource Inspection

```bash
#!/bin/bash
STACK="${1:-$(pulumi stack --show-name 2>/dev/null)}"
echo "=== Stack Resources: $STACK ==="
pulumi stack export --stack "$STACK" 2>/dev/null | jq '
    .deployment.resources[] |
    select(.type != "pulumi:pulumi:Stack") |
    {type: .type, urn: .urn | split("::") | last, provider: .provider | split("::")[2]}
' | head -50

echo ""
echo "=== Resource Type Summary ==="
pulumi stack export --stack "$STACK" 2>/dev/null | jq -r '
    [.deployment.resources[] | .type] | group_by(.) | map({type: .[0], count: length}) | sort_by(-.count)[] | "\(.count)\t\(.type)"
' | head -20
```

### Preview Changes

```bash
#!/bin/bash
echo "=== Preview Changes ==="
pulumi preview --json --non-interactive 2>/dev/null | jq '{
    steps: [.steps[]? | {
        op: .op,
        urn: .urn | split("::") | last,
        type: .type
    }],
    summary: {
        create: [.steps[]? | select(.op == "create")] | length,
        update: [.steps[]? | select(.op == "update")] | length,
        delete: [.steps[]? | select(.op == "delete")] | length,
        same: [.steps[]? | select(.op == "same")] | length
    }
}'
```

### Configuration and Secrets Management

```bash
#!/bin/bash
echo "=== Stack Configuration ==="
pulumi config --json 2>/dev/null | jq 'to_entries[] | {
    key: .key,
    secret: .value.secret,
    value: (if .value.secret then "***" else .value.value end)
}'

echo ""
echo "=== Environment Variables ==="
pulumi config env --json 2>/dev/null | jq '.' 2>/dev/null || echo "No environment configuration found"
```

### Stack History and Rollback

```bash
#!/bin/bash
echo "=== Update History ==="
pulumi stack history --json 2>/dev/null | jq '.[0:10][] | {
    version: .version,
    kind: .kind,
    result: .result,
    timestamp: .startTime,
    resourceChanges: .resourceChanges
}'

echo ""
echo "=== Last Failed Update ==="
pulumi stack history --json 2>/dev/null | jq '
    [.[] | select(.result == "failed")] | first // "No failures found"
'
```

### Cross-Stack References

```bash
#!/bin/bash
echo "=== Stack References ==="
pulumi stack export 2>/dev/null | jq -r '
    .deployment.resources[] |
    select(.type == "pulumi:pulumi:StackReference") |
    {name: (.urn | split("::") | last), target: .inputs.name}
'

echo ""
echo "=== All Stack Outputs ==="
for stack in $(pulumi stack ls --json 2>/dev/null | jq -r '.[].name'); do
    echo "--- $stack ---"
    pulumi stack output --stack "$stack" --json 2>/dev/null | jq 'keys' 2>/dev/null
done
```

## Safety Rules

- **NEVER run `pulumi up` without explicit user confirmation** -- always preview first
- **NEVER run `pulumi destroy`** unless explicitly requested with confirmation
- **Always use `--non-interactive`** to prevent prompts that hang automation
- **Secrets are encrypted** in state -- never use `pulumi config set` without `--secret` for sensitive values
- **Stack exports contain secrets** in plaintext -- handle with care

## Common Pitfalls

- **Pending operations**: If a previous update was interrupted, stack may have pending operations -- use `pulumi cancel` or `pulumi stack export/import` to fix
- **Secret provider mismatch**: Changing secrets provider requires re-encrypting all secrets -- backup first
- **Stack references**: Deleting a stack that other stacks reference will break those references
- **Language runtime**: Pulumi requires the correct language runtime (Node.js, Python, Go, etc.) installed
- **State corruption**: Never manually edit exported state -- use `pulumi state delete` or `pulumi state unprotect`
- **Provider version drift**: Different stacks may use different provider versions -- pin in package files
- **Refresh vs preview**: `pulumi refresh` updates state from cloud; `pulumi preview` shows config-vs-state diff
- **Protected resources**: Resources with `protect: true` cannot be deleted -- unprotect first with `pulumi state unprotect`
