---
name: managing-maven
description: |
  Maven build system management. Covers POM analysis, dependency management, plugin configuration, multi-module builds, repository settings, and lifecycle phases. Use when managing Maven projects, resolving dependency conflicts, analyzing build lifecycles, or configuring repository mirrors.
connection_type: maven
preload: false
---

# Maven Build System Management Skill

Manage and analyze Maven projects, dependencies, plugins, and build lifecycles.

## MANDATORY: Discovery-First Pattern

**Always check current POM configuration and project structure before modifying builds.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Maven Version ==="
mvn --version 2>/dev/null | head -3

echo ""
echo "=== Project Info ==="
mvn help:evaluate -Dexpression=project.groupId -q -DforceStdout 2>/dev/null
mvn help:evaluate -Dexpression=project.artifactId -q -DforceStdout 2>/dev/null
mvn help:evaluate -Dexpression=project.version -q -DforceStdout 2>/dev/null

echo ""
echo "=== Module Structure ==="
grep -E '<module>' pom.xml 2>/dev/null | head -15

echo ""
echo "=== Active Profiles ==="
mvn help:active-profiles 2>/dev/null | grep -v '^\[' | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Dependency Tree ==="
mvn dependency:tree -DoutputType=text 2>/dev/null | head -30

echo ""
echo "=== Dependency Conflicts ==="
mvn dependency:tree -Dverbose 2>/dev/null | grep 'omitted for conflict' | head -10

echo ""
echo "=== Plugin List ==="
mvn help:effective-pom 2>/dev/null | grep '<artifactId>' | sort -u | head -15
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Summarize dependency trees to direct dependencies
- Highlight version conflicts and overrides
- Report effective POM settings concisely

## Common Operations

### Dependency Analysis

```bash
#!/bin/bash
echo "=== Unused Dependencies ==="
mvn dependency:analyze 2>/dev/null | grep -E 'Used undeclared|Unused declared' | head -10
```

### Build Lifecycle

```bash
#!/bin/bash
echo "=== Effective POM Settings ==="
mvn help:effective-settings 2>/dev/null | grep -A5 '<server>\|<mirror>' | head -20

echo ""
echo "=== Repository Configuration ==="
mvn help:effective-pom 2>/dev/null | grep -A3 '<repository>' | head -15
```

## Safety Rules

- **Never deploy snapshots to release repositories** -- verify version before `mvn deploy`
- **Review dependency:analyze** output before removing dependencies
- **Repository credentials** must be in settings.xml, never in pom.xml
- **Lock dependency versions** in dependencyManagement to avoid transitive surprises
