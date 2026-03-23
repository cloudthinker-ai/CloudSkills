---
name: managing-terraform
description: |
  Use when working with Terraform — terraform infrastructure-as-code management.
  Covers state management, plan/apply workflows, module inspection, drift
  detection, workspace management, import operations, and provider debugging.
  Use when managing infrastructure state, investigating plan failures, detecting
  configuration drift, or auditing Terraform resources.
connection_type: terraform
preload: false
---

# Terraform Management Skill

Manage and inspect Terraform infrastructure, state, workspaces, and modules.

## MANDATORY: Discovery-First Pattern

**Always inspect state and workspaces before modifying infrastructure.**

### Phase 1: Discovery

```bash
#!/bin/bash

tf_cmd() {
    terraform "$@" 2>/dev/null
}

echo "=== Terraform Version ==="
tf_cmd version -json | jq '{terraform: .terraform_version, providers: [.provider_selections | to_entries[] | "\(.key)@\(.value)"]}'

echo ""
echo "=== Workspaces ==="
tf_cmd workspace list

echo ""
echo "=== Current Workspace ==="
tf_cmd workspace show

echo ""
echo "=== State Summary ==="
tf_cmd state list 2>/dev/null | wc -l | xargs -I{} echo "{} resources in state"

echo ""
echo "=== Backend Configuration ==="
grep -A 10 'backend' *.tf 2>/dev/null | head -15
```

## Core Helper Functions

```bash
#!/bin/bash

# Terraform wrapper with error handling
tf_run() {
    local cmd="$1"
    shift
    terraform "$cmd" "$@" 2>&1
}

# Safe state inspection
tf_state_show() {
    local resource="$1"
    terraform state show "$resource" 2>/dev/null | head -50
}

# Parse plan output to JSON
tf_plan_json() {
    terraform plan -out=tfplan -no-color 2>&1 && \
    terraform show -json tfplan 2>/dev/null
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `-json` output with jq filtering where available
- Never dump full state files -- extract key fields
- Always use `-no-color` for parseable output

## Common Operations

### State Inspection and Resource Listing

```bash
#!/bin/bash
echo "=== Resources by Type ==="
terraform state list 2>/dev/null | sed 's/\[.*//;s/\..*$//' | sort | uniq -c | sort -rn | head -20

echo ""
echo "=== Resource Details ==="
RESOURCE="${1:?Resource address required}"
terraform state show "$RESOURCE" 2>/dev/null | head -40

echo ""
echo "=== Module Structure ==="
terraform state list 2>/dev/null | grep '^module\.' | sed 's/\..*$//' | sort -u
```

### Plan and Drift Detection

```bash
#!/bin/bash
echo "=== Running Plan ==="
terraform plan -no-color -detailed-exitcode -out=tfplan 2>&1 | tail -20
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "No changes detected -- infrastructure matches configuration."
elif [ $EXIT_CODE -eq 2 ]; then
    echo ""
    echo "=== Changes Detected ==="
    terraform show -json tfplan 2>/dev/null | jq '
        .resource_changes[] |
        select(.change.actions != ["no-op"]) |
        {
            address: .address,
            actions: .change.actions,
            type: .type,
            provider: .provider_name
        }
    '

    echo ""
    echo "=== Change Summary ==="
    terraform show -json tfplan 2>/dev/null | jq '{
        create: [.resource_changes[] | select(.change.actions | contains(["create"]))] | length,
        update: [.resource_changes[] | select(.change.actions | contains(["update"]))] | length,
        delete: [.resource_changes[] | select(.change.actions | contains(["delete"]))] | length,
        replace: [.resource_changes[] | select(.change.actions | contains(["delete","create"]))] | length
    }'
else
    echo "Plan failed -- check errors above."
fi
```

### Workspace Management

```bash
#!/bin/bash
echo "=== All Workspaces ==="
terraform workspace list

echo ""
echo "=== Current Workspace State Count ==="
terraform state list 2>/dev/null | wc -l

echo ""
echo "=== Workspace Resource Comparison ==="
CURRENT=$(terraform workspace show)
for ws in $(terraform workspace list | tr -d '* '); do
    terraform workspace select "$ws" 2>/dev/null
    COUNT=$(terraform state list 2>/dev/null | wc -l | tr -d ' ')
    echo "$ws: $COUNT resources"
done
terraform workspace select "$CURRENT" 2>/dev/null
```

### Module Inspection

```bash
#!/bin/bash
echo "=== Installed Modules ==="
find .terraform/modules -name "*.tf" -maxdepth 3 2>/dev/null | \
    sed 's|.terraform/modules/||;s|/[^/]*$||' | sort -u

echo ""
echo "=== Module Sources ==="
grep -r 'source\s*=' *.tf modules/ 2>/dev/null | grep -v '.terraform' | head -20

echo ""
echo "=== Module Outputs ==="
terraform output -json 2>/dev/null | jq 'to_entries[] | {name: .key, value: .value.value, type: .value.type}'
```

### State Operations (Move/Import/Remove)

```bash
#!/bin/bash
ACTION="${1:?Action required: show|mv|rm|import}"
SOURCE="${2:?Resource address required}"
TARGET="${3:-}"

case "$ACTION" in
    show)
        echo "=== Resource State ==="
        terraform state show "$SOURCE" 2>/dev/null | head -50
        ;;
    mv)
        echo "=== DRY RUN: State Move ==="
        echo "Would move: $SOURCE -> $TARGET"
        echo "Run: terraform state mv '$SOURCE' '$TARGET'"
        ;;
    rm)
        echo "=== DRY RUN: State Remove ==="
        echo "Would remove from state (not destroy): $SOURCE"
        echo "Run: terraform state rm '$SOURCE'"
        ;;
    import)
        echo "=== DRY RUN: Import ==="
        echo "Would import: $TARGET as $SOURCE"
        echo "Run: terraform import '$SOURCE' '$TARGET'"
        ;;
esac
```

## Safety Rules

- **NEVER run `terraform apply` without explicit user confirmation** -- always plan first
- **NEVER run `terraform destroy`** unless explicitly requested with confirmation
- **Always use `-out=tfplan`** to ensure the applied plan matches what was reviewed
- **State operations (`state rm`, `state mv`) are irreversible** -- confirm before executing
- **Lock state** during operations in team environments -- check for lock conflicts

## Output Format

Present results as a structured report:
```
Managing Terraform Report
═════════════════════════
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

- **State lock conflicts**: Another user or CI pipeline may hold the state lock -- use `terraform force-unlock` only as last resort
- **Provider version mismatches**: Pin provider versions in `required_providers` to avoid unexpected upgrades
- **Workspace confusion**: Always verify active workspace before plan/apply -- wrong workspace can modify production
- **Partial applies**: If apply is interrupted, state may be partially updated -- run plan again to assess
- **Import drift**: Imported resources may not match config exactly -- always plan after import
- **Backend migration**: Changing backend config requires `terraform init -migrate-state` -- backup state first
- **Sensitive outputs**: Use `sensitive = true` on outputs containing secrets -- they still appear in state files
- **Module version pins**: Unpinned module sources can introduce breaking changes silently
