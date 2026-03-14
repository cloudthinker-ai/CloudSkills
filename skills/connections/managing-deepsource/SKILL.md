---
name: managing-deepsource
description: |
  DeepSource code analysis management. Covers automated code reviews, issue detection, antipattern analysis, coverage tracking, and analyzer configuration. Use when managing DeepSource projects, reviewing detected issues, configuring analyzers, or tracking code health metrics.
connection_type: deepsource
preload: false
---

# DeepSource Code Analysis Management Skill

Manage and analyze DeepSource issues, analyzers, and code health metrics.

## MANDATORY: Discovery-First Pattern

**Always check current DeepSource configuration before modifying analyzer settings.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== DeepSource Configuration ==="
cat .deepsource.toml 2>/dev/null || echo "No .deepsource.toml found"

echo ""
echo "=== Enabled Analyzers ==="
grep -A5 '\[\[analyzers\]\]' .deepsource.toml 2>/dev/null | head -20

echo ""
echo "=== Transformers ==="
grep -A3 '\[\[transformers\]\]' .deepsource.toml 2>/dev/null | head -10

echo ""
echo "=== Exclude Patterns ==="
grep 'exclude_patterns' .deepsource.toml 2>/dev/null
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Project Issues (via API) ==="
curl -s -H "Authorization: Bearer ${DEEPSOURCE_TOKEN}" \
  "https://api.deepsource.com/v1/repos/${DEEPSOURCE_REPO}/issues/?status=open&limit=10" 2>/dev/null | jq '{
  total: .count,
  issues: [.results[:10][] | {
    title: .title,
    category: .category,
    severity: .severity,
    occurrences: .occurrences_count
  }]
}' 2>/dev/null

echo ""
echo "=== Analyzer Status ==="
grep -E 'name|enabled' .deepsource.toml 2>/dev/null | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Group issues by category (bug risk, antipattern, performance, security)
- Report occurrence counts per issue type
- Never expose API tokens in output

## Common Operations

### Issue Categories

```bash
#!/bin/bash
echo "=== Issues by Category ==="
curl -s -H "Authorization: Bearer ${DEEPSOURCE_TOKEN}" \
  "https://api.deepsource.com/v1/repos/${DEEPSOURCE_REPO}/issues/?status=open" 2>/dev/null | jq '{
  by_category: (.results | group_by(.category) | map({
    category: .[0].category,
    count: length
  }))
}' 2>/dev/null
```

### Configuration Validation

```bash
#!/bin/bash
echo "=== Config Validation ==="
cat .deepsource.toml 2>/dev/null
echo ""
echo "=== Supported Analyzers ==="
echo "python, go, javascript, ruby, java, rust, sql, docker, terraform, shell"
```

## Safety Rules

- **Review analyzer configurations** before enabling new analyzers on active repos
- **DeepSource tokens** must be stored in CI secrets
- **Do not suppress issues globally** -- use inline comments for justified cases only
- **Monitor false positive rates** and adjust analyzer settings accordingly
