---
name: managing-wing
description: |
  Wing cloud-oriented programming language management. Covers compilation, testing, simulation, deployment to cloud targets, resource inspection, and console usage. Use when developing Wing applications, running local simulations, deploying to AWS/Azure/GCP, or debugging preflight and inflight code.
connection_type: wing
preload: false
---

# Wing Management Skill

Manage Wing applications, simulate locally, compile to cloud targets, and deploy infrastructure.

## MANDATORY: Discovery-First Pattern

**Always inspect Wing project structure and compile before deploying.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Wing Version ==="
wing --version 2>/dev/null

echo ""
echo "=== Project Structure ==="
ls *.w 2>/dev/null | head -10
cat package.json 2>/dev/null | jq '{name, wingCompiler: .wing}' 2>/dev/null

echo ""
echo "=== Main Entry ==="
if [ -f main.w ]; then
  head -30 main.w
fi

echo ""
echo "=== Wing Libraries ==="
cat package.json 2>/dev/null | jq '.dependencies // {}' | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash
TARGET="${1:-sim}"

echo "=== Compile (target=$TARGET) ==="
wing compile --target "$TARGET" 2>&1 | tail -15

echo ""
echo "=== Test Results ==="
wing test 2>&1 | tail -20

echo ""
echo "=== Generated Resources ==="
if [ -d "target/$TARGET" ]; then
  find "target/$TARGET" -name "*.tf.json" -exec jq '.resource | keys' {} \; 2>/dev/null | head -15 || \
  ls "target/$TARGET/" | head -15
fi

echo ""
echo "=== Simulation ==="
if [ "$TARGET" = "sim" ]; then
  echo "Run 'wing it' to start the Wing Console simulator"
fi
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Show compiled resource summaries, not full generated templates
- Summarize test results with pass/fail counts
- Use simulation target for local validation

## Safety Rules
- **NEVER deploy without compiling and testing first**
- **Use `wing test`** to validate before deployment
- **Start with `--target sim`** for local testing
- **Review generated Terraform** before applying to cloud targets
- **Check cloud target permissions** before deployment
