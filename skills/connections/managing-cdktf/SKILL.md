---
name: managing-cdktf
description: |
  CDK for Terraform (CDKTF) project and stack management. Covers project synthesis, provider generation, stack deployment, output inspection, and diff analysis using TypeScript, Python, Go, Java, or C#. Use when working with CDKTF projects, synthesizing Terraform configurations, deploying stacks, or debugging provider bindings.
connection_type: cdktf
preload: false
---

# CDKTF Management Skill

Manage CDK for Terraform projects, synthesize HCL, deploy stacks, and inspect outputs.

## MANDATORY: Discovery-First Pattern

**Always inspect the CDKTF project structure and synthesized output before deploying.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== CDKTF Version ==="
cdktf --version 2>/dev/null

echo ""
echo "=== Project Structure ==="
cat cdktf.json 2>/dev/null | jq '{language, app, terraformProviders: (.terraformProviders // [] | length), terraformModules: (.terraformModules // [] | length)}'

echo ""
echo "=== Stacks ==="
cdktf list 2>/dev/null | head -15

echo ""
echo "=== Generated Providers ==="
ls .gen/providers/ 2>/dev/null | head -10 || echo "No generated providers found"

echo ""
echo "=== Dependencies ==="
if [ -f package.json ]; then
  jq '.dependencies // {} | keys' package.json 2>/dev/null | head -15
elif [ -f requirements.txt ]; then
  head -15 requirements.txt
fi
```

### Phase 2: Analysis

```bash
#!/bin/bash
STACK="${1:-}"

echo "=== Synth Output ==="
cdktf synth 2>&1 | tail -10

echo ""
echo "=== Synthesized Stacks ==="
ls cdktf.out/stacks/ 2>/dev/null

echo ""
if [ -n "$STACK" ]; then
  echo "=== Stack Plan ($STACK) ==="
  cdktf diff "$STACK" 2>&1 | tail -30
else
  echo "=== Default Stack Plan ==="
  cdktf diff 2>&1 | tail -30
fi
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Always synth before diff or deploy
- Show resource counts from synthesized output, not full HCL
- Summarize provider versions rather than listing all bindings

## Safety Rules
- **NEVER run `cdktf deploy` without `cdktf diff` first**
- **Always run `cdktf synth`** to validate before deployment
- **Review generated Terraform** in `cdktf.out/` before applying
- **Pin provider versions** in `cdktf.json` for reproducibility
- **Use `--auto-approve` only** when explicitly confirmed
