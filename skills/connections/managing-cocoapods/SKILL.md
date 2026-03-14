---
name: managing-cocoapods
description: |
  CocoaPods dependency management for iOS/macOS. Covers Podfile configuration, pod publishing, dependency resolution, spec repositories, and pod analysis. Use when managing CocoaPods dependencies, publishing pod specs, resolving version conflicts, or analyzing pod dependency trees.
connection_type: cocoapods
preload: false
---

# CocoaPods Management Skill

Manage and analyze CocoaPods dependencies, pod specs, and iOS/macOS project configuration.

## MANDATORY: Discovery-First Pattern

**Always check current Podfile and pod configuration before modifying dependencies.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Podfile ==="
cat Podfile 2>/dev/null | head -25

echo ""
echo "=== Pod Version ==="
pod --version 2>/dev/null

echo ""
echo "=== Podspec ==="
cat *.podspec 2>/dev/null | head -20
ls *.podspec.json 2>/dev/null

echo ""
echo "=== Installed Pods ==="
cat Podfile.lock 2>/dev/null | grep '^  - ' | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Pod Dependencies ==="
cat Podfile.lock 2>/dev/null | grep -E '^\s{2}- ' | wc -l | xargs -I{} echo "Total pods: {}"

echo ""
echo "=== Outdated Pods ==="
pod outdated 2>/dev/null | head -15

echo ""
echo "=== Spec Repos ==="
pod repo list 2>/dev/null | head -10

echo ""
echo "=== Pod Sources ==="
grep 'source ' Podfile 2>/dev/null
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- List pods with version constraints
- Summarize dependency tree depth
- Report outdated pods with available versions

## Common Operations

### Pod Lookup

```bash
#!/bin/bash
POD="${1:?Pod name required}"
echo "=== Pod Info: $POD ==="
pod spec cat "$POD" --verbose 2>/dev/null | head -20
```

### Validate Podspec

```bash
#!/bin/bash
echo "=== Lint Podspec ==="
pod spec lint *.podspec 2>&1 | tail -15

echo ""
echo "=== Lib Lint ==="
pod lib lint 2>&1 | tail -10
```

## Safety Rules

- **Run `pod lib lint`** before publishing pod specs
- **Commit Podfile.lock** for reproducible builds
- **Never force-push trunk** without verifying podspec validity
- **Review dependency tree** changes after `pod update` for unexpected upgrades
