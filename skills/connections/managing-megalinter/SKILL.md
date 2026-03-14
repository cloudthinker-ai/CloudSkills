---
name: managing-megalinter
description: |
  MegaLinter multi-language linting management. Covers linter configuration, flavor selection, reporter setup, CI integration, and fix mode management. Use when managing MegaLinter configurations, enabling or disabling linters, debugging linter failures, or optimizing linting performance.
connection_type: megalinter
preload: false
---

# MegaLinter Multi-Language Linting Management Skill

Manage and analyze MegaLinter configurations, linter results, and CI integration.

## MANDATORY: Discovery-First Pattern

**Always check current MegaLinter configuration before modifying linter settings.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== MegaLinter Configuration ==="
cat .mega-linter.yml 2>/dev/null || cat .megalinter.yml 2>/dev/null || echo "No MegaLinter config found"

echo ""
echo "=== CI Integration ==="
grep -r 'mega-linter\|megalinter' .github/workflows/ 2>/dev/null | head -10

echo ""
echo "=== Flavor ==="
grep -E 'FLAVOR|image.*megalinter' .github/workflows/*.yml 2>/dev/null | head -5

echo ""
echo "=== Enabled/Disabled Linters ==="
grep -E 'ENABLE|DISABLE' .mega-linter.yml .megalinter.yml 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Linter Configuration ==="
cat .mega-linter.yml 2>/dev/null | head -30

echo ""
echo "=== Reports ==="
ls -la megalinter-reports/ 2>/dev/null | head -10

echo ""
echo "=== Latest Results ==="
cat megalinter-reports/megalinter-report.json 2>/dev/null | jq '{
  total_linters: (.linters | length),
  success: [.linters[] | select(.status == "success")] | length,
  error: [.linters[] | select(.status == "error")] | length,
  errors_by_linter: [.linters[] | select(.status == "error") | .linter_name]
}' 2>/dev/null
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Summarize linter results with pass/fail counts
- List failing linters with error counts
- Report flavor and active linter list

## Common Operations

### Run Locally

```bash
#!/bin/bash
echo "=== Local MegaLinter Run ==="
npx mega-linter-runner --fix 2>&1 | tail -20
```

### Linter Status

```bash
#!/bin/bash
echo "=== Available Linters ==="
cat megalinter-reports/megalinter-report.json 2>/dev/null | jq '[.linters[] | {
  name: .linter_name,
  language: .language,
  status: .status,
  files_count: .files_count
}] | sort_by(.status)' 2>/dev/null | head -30
```

## Safety Rules

- **Start with a curated flavor** rather than the full image to reduce CI time
- **Enable fix mode cautiously** -- auto-fixes can introduce unintended changes
- **Review linter disable lists** periodically for outdated exclusions
- **Test configuration changes** locally with `mega-linter-runner` before CI deployment
