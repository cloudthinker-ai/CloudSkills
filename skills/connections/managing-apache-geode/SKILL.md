---
name: managing-apache-geode
description: |
  Apache Geode distributed cache management, region inspection, member health monitoring, and WAN gateway analysis. Covers locator status, server groups, partition distribution, persistent disk store health, and continuous query diagnostics. Read this skill before any Geode operations.
connection_type: geode
preload: false
---

# Apache Geode Management Skill

Monitor, analyze, and optimize Apache Geode clusters safely.

## MANDATORY: Discovery-First Pattern

**Always check cluster status and list regions before any data operations. Never assume region names or partition configurations.**

### Phase 1: Discovery

```bash
#!/bin/bash

GEODE_LOCATOR="${GEODE_LOCATOR:-localhost[10334]}"

echo "=== Cluster Status ==="
gfsh -e "connect --locator=$GEODE_LOCATOR" -e "list members" 2>/dev/null

echo ""
echo "=== Regions ==="
gfsh -e "connect --locator=$GEODE_LOCATOR" -e "list regions" 2>/dev/null

echo ""
echo "=== Disk Stores ==="
gfsh -e "connect --locator=$GEODE_LOCATOR" -e "list disk-stores" 2>/dev/null

echo ""
echo "=== Deployed JARs ==="
gfsh -e "connect --locator=$GEODE_LOCATOR" -e "list deployed" 2>/dev/null

echo ""
echo "=== Management REST API ==="
GEODE_REST="${GEODE_REST_URL:-http://localhost:7070}"
curl -s "$GEODE_REST/management/v1/members" 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
for m in data.get('memberStatuses', data.get('result', [])):
    print(f\"  {m.get('id','?')}: host={m.get('host','?')} status={m.get('status','?')}\")
" 2>/dev/null || echo "Management REST not available"
```

**Phase 1 outputs:** Member list, region inventory, disk stores, deployed JARs.

### Phase 2: Analysis

```bash
#!/bin/bash

GEODE_LOCATOR="${GEODE_LOCATOR:-localhost[10334]}"
REGION="${1:-my_region}"

echo "=== Region Details ==="
gfsh -e "connect --locator=$GEODE_LOCATOR" -e "describe region --name=$REGION" 2>/dev/null

echo ""
echo "=== Member Details ==="
gfsh -e "connect --locator=$GEODE_LOCATOR" -e "describe member --name=$(gfsh -e 'connect --locator=$GEODE_LOCATOR' -e 'list members' 2>/dev/null | grep -v "^$\|Name\|---" | head -1 | awk '{print $1}')" 2>/dev/null | head -25

echo ""
echo "=== Disk Store Details ==="
gfsh -e "connect --locator=$GEODE_LOCATOR" -e "describe disk-store --name=DEFAULT --member=$(gfsh -e 'connect --locator=$GEODE_LOCATOR' -e 'list members' 2>/dev/null | grep -v '^$\|Name\|---' | head -1 | awk '{print $1}')" 2>/dev/null | head -15

echo ""
echo "=== Gateway Senders ==="
gfsh -e "connect --locator=$GEODE_LOCATOR" -e "list gateways" 2>/dev/null || echo "No WAN gateways configured"

echo ""
echo "=== Indexes ==="
gfsh -e "connect --locator=$GEODE_LOCATOR" -e "list indexes" 2>/dev/null
```

## Output Format

```
GEODE ANALYSIS
==============
Members: [count] | Locators: [count] | Servers: [count]
Regions: [count] | Disk Stores: [count]

ISSUES FOUND:
- [issue with affected region/member]

RECOMMENDATIONS:
- [actionable recommendation]
```
