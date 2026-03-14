---
name: managing-pypi
description: |
  PyPI package registry management. Covers package publishing, version management, distribution builds, dependency resolution, index configuration, and package metadata. Use when managing Python packages on PyPI, configuring private indexes, building distributions, or analyzing package health.
connection_type: pypi
preload: false
---

# PyPI Package Registry Management Skill

Manage and analyze Python packages, PyPI publishing, and distribution builds.

## MANDATORY: Discovery-First Pattern

**Always check current package configuration and index settings before publishing.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Package Configuration ==="
cat pyproject.toml 2>/dev/null | head -25
cat setup.py 2>/dev/null | head -20
cat setup.cfg 2>/dev/null | head -20

echo ""
echo "=== pip Configuration ==="
pip config list 2>/dev/null | head -10

echo ""
echo "=== Index Settings ==="
cat pip.conf 2>/dev/null || cat ~/.pip/pip.conf 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Installed Packages ==="
pip list --format=json 2>/dev/null | jq 'length' 2>/dev/null | xargs -I{} echo "Total installed: {}"

echo ""
echo "=== Outdated Packages ==="
pip list --outdated --format=json 2>/dev/null | jq '[.[:10][] | {
  name: .name,
  current: .version,
  latest: .latest_version,
  type: .latest_filetype
}]' 2>/dev/null

echo ""
echo "=== Package Info ==="
PACKAGE=$(cat pyproject.toml 2>/dev/null | grep '^name' | head -1 | sed 's/.*= *"//;s/"//')
curl -s "https://pypi.org/pypi/${PACKAGE}/json" 2>/dev/null | jq '{
  name: .info.name,
  version: .info.version,
  downloads: .info.downloads,
  requires_python: .info.requires_python
}' 2>/dev/null
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Summarize package metadata concisely
- List outdated dependencies with version gaps
- Never expose PyPI tokens in output

## Common Operations

### Build and Check Distribution

```bash
#!/bin/bash
echo "=== Build Distribution ==="
python -m build --sdist --wheel 2>&1 | tail -10

echo ""
echo "=== Check Distribution ==="
twine check dist/* 2>/dev/null | head -10
```

### Package Lookup

```bash
#!/bin/bash
PACKAGE="${1:?Package name required}"
echo "=== PyPI Package: $PACKAGE ==="
curl -s "https://pypi.org/pypi/${PACKAGE}/json" | jq '{
  name: .info.name,
  version: .info.version,
  summary: .info.summary,
  license: .info.license,
  requires_python: .info.requires_python,
  releases: (.releases | keys | length)
}' 2>/dev/null
```

## Safety Rules

- **Never expose PyPI API tokens** in configuration files or logs
- **Use `twine check`** before uploading to verify package metadata
- **Test on TestPyPI first** before publishing to production PyPI
- **Pin dependencies** in requirements.txt for reproducible builds
