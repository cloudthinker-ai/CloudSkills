---
name: managing-klotho
description: |
  Klotho cloud compiler and infrastructure generation. Covers application compilation, cloud target configuration, generated infrastructure inspection, deployment orchestration, and topology visualization. Use when using Klotho to compile applications to cloud infrastructure, reviewing generated IaC, or deploying to AWS.
connection_type: klotho
preload: false
---

# Klotho Management Skill

Manage Klotho-compiled applications, inspect generated infrastructure, and deploy to cloud targets.

## MANDATORY: Discovery-First Pattern

**Always inspect Klotho annotations and compilation output before deploying.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Klotho Version ==="
klotho --version 2>/dev/null

echo ""
echo "=== Project Config ==="
cat klotho.yaml 2>/dev/null || cat .klotho/config.yaml 2>/dev/null | head -20

echo ""
echo "=== Klotho Annotations ==="
grep -rn "@klotho" --include="*.ts" --include="*.py" --include="*.go" . 2>/dev/null | head -15

echo ""
echo "=== Application Structure ==="
ls -la 2>/dev/null | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Compile ==="
klotho . --app "${1:-myapp}" --provider aws 2>&1 | tail -15

echo ""
echo "=== Generated Infrastructure ==="
ls compiled/ 2>/dev/null | head -10 || ls .klotho/output/ 2>/dev/null | head -10

echo ""
echo "=== Resource Topology ==="
cat compiled/topology.json 2>/dev/null | jq '.resources[] | {type, name}' 2>/dev/null | head -20 || \
cat .klotho/output/topology.json 2>/dev/null | jq '.resources[] | {type, name}' 2>/dev/null | head -20

echo ""
echo "=== Generated Pulumi/Terraform ==="
find compiled/ -name "*.ts" -o -name "*.tf" 2>/dev/null | head -10 || \
find .klotho/output/ -name "*.ts" -o -name "*.tf" 2>/dev/null | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Show topology summaries, not full generated code
- Summarize resource types and connections
- Display annotation usage patterns concisely

## Safety Rules
- **NEVER deploy without reviewing generated infrastructure**
- **Validate annotations** before compilation
- **Review generated IaC** in compiled output directory
- **Test with dry-run** before actual deployment
- **Check cloud permissions** match generated resource requirements
