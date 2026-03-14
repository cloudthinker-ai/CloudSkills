---
name: managing-appium
description: |
  Appium mobile testing management and server monitoring. Covers Appium server health, session management, desired capabilities review, device farm integration, test result analysis, and driver configuration. Use when managing mobile test automation, investigating Appium server issues, or reviewing mobile testing configurations.
connection_type: appium
preload: false
---

# Appium Mobile Testing Management Skill

Manage Appium server infrastructure and analyze mobile test automation.

## Core Helper Functions

```bash
#!/bin/bash

# Appium server API helper
appium_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Content-Type: application/json" \
            "${APPIUM_URL:-http://localhost:4723}/${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            "${APPIUM_URL:-http://localhost:4723}/${endpoint}"
    fi
}
```

## MANDATORY: Discovery-First Pattern

**Always discover server status and available devices before querying specifics.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Appium Server Status ==="
appium_api GET "status" | jq '{ready: .value.ready, build: .value.build}'

echo ""
echo "=== Active Sessions ==="
appium_api GET "sessions" | jq -r '
    .value[] | "\(.id)\t\(.capabilities.platformName)\t\(.capabilities.deviceName // "unknown")\t\(.capabilities.browserName // .capabilities.app // "native")"
' | column -t

echo ""
echo "=== Connected Devices (Android) ==="
adb devices -l 2>/dev/null | tail -n +2 | head -10

echo ""
echo "=== Connected Devices (iOS) ==="
xcrun xctrace list devices 2>/dev/null | head -10

echo ""
echo "=== Appium Drivers ==="
appium driver list --installed 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Appium Configuration ==="
if [ -f "appium.conf.json" ]; then
    cat appium.conf.json | jq '.' | head -20
fi

echo ""
echo "=== Desired Capabilities in Tests ==="
grep -rn "desiredCapabilities\|capabilities" --include="*.js" --include="*.ts" --include="*.py" --include="*.java" 2>/dev/null | grep -v node_modules | head -15

echo ""
echo "=== Test Results ==="
REPORT_DIR="${APPIUM_REPORT_DIR:-test-results}"
if [ -d "$REPORT_DIR" ]; then
    find "$REPORT_DIR" -name "*.xml" | while read f; do
        grep -c 'testcase' "$f" | xargs echo "$f: tests="
    done | head -10
    echo ""
    echo "=== Failures ==="
    grep -rn '<failure' "$REPORT_DIR" --include="*.xml" | head -10
fi
```

## Output Rules
- **TOKEN EFFICIENCY**: Target 50 lines per output
- Summarize capabilities and session info, not full payloads
- Never dump full device logs — extract relevant error sections

## Anti-Hallucination Rules
- NEVER guess device names or UDIDs — always discover via adb/xcrun
- NEVER fabricate session IDs — query active sessions from server
- NEVER assume driver availability — check installed drivers first

## Safety Rules
- NEVER terminate sessions without explicit user confirmation
- NEVER install or uninstall apps on devices without user approval
- NEVER modify server configuration without user consent
