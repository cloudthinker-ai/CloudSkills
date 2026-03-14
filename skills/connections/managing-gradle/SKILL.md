---
name: managing-gradle
description: |
  Gradle build system management. Covers build script analysis, task execution, dependency resolution, build scans, plugin management, and multi-project builds. Use when managing Gradle projects, debugging dependency conflicts, analyzing build performance, or configuring build caching.
connection_type: gradle
preload: false
---

# Gradle Build System Management Skill

Manage and analyze Gradle builds, dependencies, tasks, and multi-project configurations.

## MANDATORY: Discovery-First Pattern

**Always check current Gradle configuration and project structure before modifying builds.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Gradle Version ==="
./gradlew --version 2>/dev/null | head -5

echo ""
echo "=== Project Structure ==="
cat settings.gradle 2>/dev/null || cat settings.gradle.kts 2>/dev/null | head -20

echo ""
echo "=== Build Script ==="
ls build.gradle build.gradle.kts 2>/dev/null
ls */build.gradle */build.gradle.kts 2>/dev/null | head -10

echo ""
echo "=== Gradle Properties ==="
cat gradle.properties 2>/dev/null | grep -v '^#' | grep -v '^$' | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Available Tasks ==="
./gradlew tasks --all 2>/dev/null | grep -E '^\w' | head -20

echo ""
echo "=== Dependencies (compile) ==="
./gradlew dependencies --configuration=compileClasspath 2>/dev/null | head -25

echo ""
echo "=== Build Cache Config ==="
grep -r 'buildCache\|cacheability' build.gradle* gradle.properties 2>/dev/null | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Summarize dependency trees to top-level dependencies
- Group tasks by lifecycle phase
- Report build scan URLs when available

## Common Operations

### Dependency Conflict Resolution

```bash
#!/bin/bash
echo "=== Dependency Insight ==="
DEPENDENCY="${1:?Dependency group:artifact required}"
./gradlew dependencyInsight --dependency "$DEPENDENCY" 2>/dev/null | head -20
```

### Build Performance

```bash
#!/bin/bash
echo "=== Build Scan ==="
./gradlew build --scan 2>&1 | grep -E 'BUILD|https://gradle' | head -5

echo ""
echo "=== Build Cache Stats ==="
ls -la ~/.gradle/caches/ 2>/dev/null | head -10
du -sh ~/.gradle/caches/ 2>/dev/null
```

## Safety Rules

- **Never publish artifacts** without verifying version and credentials
- **Use `--dry-run`** to preview task execution before running destructive tasks
- **Dependency locks** should be committed and reviewed for unexpected changes
- **Build scan data** may contain sensitive info -- review sharing settings
