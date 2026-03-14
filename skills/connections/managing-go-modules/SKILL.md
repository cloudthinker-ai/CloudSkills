---
name: managing-go-modules
description: |
  Go modules package management. Covers module initialization, dependency resolution, version management, module proxying, vendoring, and vulnerability scanning. Use when managing Go modules, resolving dependency conflicts, analyzing module graphs, or auditing module vulnerabilities.
connection_type: go-modules
preload: false
---

# Go Modules Management Skill

Manage and analyze Go module dependencies, versions, and vulnerability scanning.

## MANDATORY: Discovery-First Pattern

**Always check current go.mod configuration before modifying dependencies.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Module Info ==="
head -5 go.mod 2>/dev/null

echo ""
echo "=== Go Version ==="
go version 2>/dev/null

echo ""
echo "=== Direct Dependencies ==="
grep -v '// indirect' go.mod 2>/dev/null | grep -E '^\t' | head -15

echo ""
echo "=== Go Environment ==="
go env GOPATH GOMODCACHE GOPROXY GONOSUMCHECK 2>/dev/null
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Module Graph Summary ==="
go mod graph 2>/dev/null | wc -l | xargs -I{} echo "Total dependency edges: {}"

echo ""
echo "=== Outdated Modules ==="
go list -u -m all 2>/dev/null | grep '\[' | head -15

echo ""
echo "=== Vulnerability Scan ==="
go install golang.org/x/vuln/cmd/govulncheck@latest 2>/dev/null
govulncheck ./... 2>/dev/null | head -20
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- List direct vs indirect dependencies separately
- Report vulnerability findings concisely
- Show module graph density, not full graph

## Common Operations

### Module Tidying

```bash
#!/bin/bash
echo "=== Tidy Check ==="
cp go.mod go.mod.bak
go mod tidy 2>&1
diff go.mod.bak go.mod 2>/dev/null | head -15
rm go.mod.bak 2>/dev/null
```

### Module Lookup

```bash
#!/bin/bash
MODULE="${1:?Module path required}"
echo "=== Module Info: $MODULE ==="
go list -m -json "$MODULE@latest" 2>/dev/null | jq '{
  Path: .Path,
  Version: .Version,
  Time: .Time
}' 2>/dev/null

echo ""
echo "=== Available Versions ==="
go list -m -versions "$MODULE" 2>/dev/null
```

## Safety Rules

- **Run `go mod tidy`** after adding or removing dependencies
- **Review go.sum changes** before committing -- unexpected changes may indicate supply chain issues
- **Use `govulncheck`** before releases to scan for known vulnerabilities
- **Vendor dependencies** for critical production services with `go mod vendor`
