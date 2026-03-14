---
name: managing-nuget
description: |
  NuGet package registry management. Covers package publishing, version management, dependency resolution, package source configuration, vulnerability scanning, and .NET project analysis. Use when managing NuGet packages, configuring package sources, resolving version conflicts, or auditing package security.
connection_type: nuget
preload: false
---

# NuGet Registry Management Skill

Manage and analyze NuGet packages, sources, dependencies, and .NET project configurations.

## MANDATORY: Discovery-First Pattern

**Always check current project and NuGet configuration before modifying packages.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== NuGet Sources ==="
dotnet nuget list source 2>/dev/null

echo ""
echo "=== Project Files ==="
find . -name "*.csproj" -o -name "*.fsproj" -o -name "*.vbproj" 2>/dev/null | head -10

echo ""
echo "=== NuGet Config ==="
cat nuget.config 2>/dev/null || cat NuGet.Config 2>/dev/null | head -15

echo ""
echo "=== .NET Version ==="
dotnet --version 2>/dev/null
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Package References ==="
grep -rh 'PackageReference' *.csproj 2>/dev/null | sed 's/.*Include="/  /;s/" Version="/  v/;s/".*//' | head -15

echo ""
echo "=== Outdated Packages ==="
dotnet list package --outdated 2>/dev/null | head -20

echo ""
echo "=== Vulnerable Packages ==="
dotnet list package --vulnerable 2>/dev/null | head -15
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- List packages with current and latest versions
- Report vulnerabilities by severity
- Never expose NuGet API keys in output

## Common Operations

### Package Lookup

```bash
#!/bin/bash
PACKAGE="${1:?Package name required}"
echo "=== Package: $PACKAGE ==="
curl -s "https://api.nuget.org/v3/registration5-gz-semver2/${PACKAGE,,}/index.json" | jq '{
  id: .items[0].items[-1].catalogEntry.id,
  version: .items[0].items[-1].catalogEntry.version,
  description: .items[0].items[-1].catalogEntry.description,
  authors: .items[0].items[-1].catalogEntry.authors
}' 2>/dev/null
```

### Pack and Publish Preview

```bash
#!/bin/bash
echo "=== Pack Preview ==="
dotnet pack --no-build 2>&1 | tail -10
ls -la bin/Release/*.nupkg 2>/dev/null
```

## Safety Rules

- **Never expose NuGet API keys** in configuration or logs
- **Use `dotnet pack` dry runs** before publishing
- **Review vulnerability reports** before deploying to production
- **Lock package versions** in production projects to avoid unexpected updates
