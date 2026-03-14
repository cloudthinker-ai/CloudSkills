---
name: managing-pulumi-cloud
description: |
  Pulumi Cloud stack and deployment management. Covers stack operations, resource inspection, configuration and secrets, deployment history, policy packs (CrossGuard), and team access controls. Use when managing Pulumi stacks, reviewing deployment history, inspecting resource state, or auditing organization policies.
connection_type: pulumi-cloud
preload: false
---

# Pulumi Cloud Management Skill

Manage Pulumi Cloud stacks, deployments, policies, and organization settings.

## MANDATORY: Discovery-First Pattern

**Always inspect organization and stack state before taking action.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Pulumi Version ==="
pulumi version 2>/dev/null

echo ""
echo "=== Current User ==="
pulumi whoami -v 2>/dev/null

echo ""
echo "=== Organization Stacks ==="
pulumi stack ls --all 2>/dev/null | head -20

echo ""
echo "=== Current Stack ==="
pulumi stack 2>/dev/null
```

### Phase 2: Analysis

```bash
#!/bin/bash
STACK="${1:?Stack name required}"

echo "=== Stack Details ==="
pulumi stack -s "$STACK" 2>/dev/null

echo ""
echo "=== Stack Outputs ==="
pulumi stack output -s "$STACK" --json 2>/dev/null | jq '.' | head -20

echo ""
echo "=== Resource Count ==="
pulumi stack -s "$STACK" 2>/dev/null | grep -c "Type\|pulumi:" || echo "0"

echo ""
echo "=== Stack Config ==="
pulumi config -s "$STACK" 2>/dev/null | head -15

echo ""
echo "=== Recent History ==="
pulumi stack history -s "$STACK" --show-secrets=false 2>/dev/null | head -15

echo ""
echo "=== Policy Packs ==="
pulumi policy ls 2>/dev/null | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Never expose secret config values -- use `--show-secrets=false`
- Summarize resource counts rather than listing all resources
- Use `--json` output for structured data when filtering

## Safety Rules
- **NEVER run `pulumi up` without `--preview-only` first**
- **NEVER run `pulumi destroy`** without explicit confirmation
- **Protect production stacks** with stack policies
- **Check policy pack results** before recommending deployment
- **Review diff carefully** before confirming updates
