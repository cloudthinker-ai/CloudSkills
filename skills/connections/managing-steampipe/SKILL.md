---
name: managing-steampipe
description: |
  Steampipe cloud infrastructure query engine management. Covers plugin installation, mod management, SQL-based resource querying, dashboard inspection, benchmark execution, compliance reporting, and connection configuration. Use when querying cloud resources with SQL, running compliance benchmarks, inspecting multi-cloud infrastructure, or building Steampipe dashboards.
connection_type: steampipe
preload: false
---

# Steampipe Management Skill

Manage and inspect Steampipe plugins, connections, queries, benchmarks, and dashboards.

## MANDATORY: Discovery-First Pattern

**Always check installed plugins and connections before running queries.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Steampipe Version ==="
steampipe --version 2>/dev/null

echo ""
echo "=== Installed Plugins ==="
steampipe plugin list 2>/dev/null | head -15

echo ""
echo "=== Connections ==="
steampipe query "select name, type, plugin from steampipe_connection" --output csv 2>/dev/null | head -15

echo ""
echo "=== Installed Mods ==="
ls -d ~/.steampipe/mods/*/ 2>/dev/null | sed 's|.*mods/||;s|/$||' | head -10
steampipe mod list 2>/dev/null | head -10

echo ""
echo "=== Available Tables ==="
steampipe query ".tables" 2>/dev/null | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

PLUGIN="${1:-aws}"

echo "=== Plugin Tables ==="
steampipe query ".tables $PLUGIN" 2>/dev/null | head -20

echo ""
echo "=== Resource Count Sample ==="
case "$PLUGIN" in
    aws)
        steampipe query "select region, count(*) as count from aws_ec2_instance group by region order by count desc limit 10" --output table 2>/dev/null
        ;;
    azure)
        steampipe query "select resource_group, count(*) as count from azure_compute_virtual_machine group by resource_group order by count desc limit 10" --output table 2>/dev/null
        ;;
    gcp)
        steampipe query "select project, count(*) as count from gcp_compute_instance group by project order by count desc limit 10" --output table 2>/dev/null
        ;;
esac

echo ""
echo "=== Benchmark Check ==="
steampipe check benchmark.cis_v150 --output brief 2>/dev/null | tail -15 || echo "No CIS benchmark mod installed"

echo ""
echo "=== Dashboard Status ==="
steampipe dashboard --status 2>/dev/null | head -10 || echo "Dashboard not running"
```

## Output Format

```
STEAMPIPE STATUS
Version: <version> | Plugins: <count> | Connections: <count>
Tables Available: <count>
Plugin: <name> v<version> | Tables: <count>
Benchmark: <name> - <passed>/<total> controls passing
Dashboard: <running|stopped> on <port>
Issues: <any plugin errors, stale connections, or failed benchmarks>
```

## Safety Rules

- **Steampipe queries are read-only** -- they cannot modify cloud resources
- **Be mindful of API costs** -- some queries can trigger many API calls across all regions
- **Use `limit` clauses** on large tables to avoid excessive API usage
- **Review connection credentials** -- ensure least-privilege access for query connections

## Common Pitfalls

- **Plugin version mismatch**: Update plugins regularly -- old plugins may not support new resource types
- **Connection configuration**: Missing or incorrect credentials cause query errors -- check `~/.steampipe/config/`
- **Query performance**: Cross-region queries on large accounts can be slow -- use `where region =` filters
- **Cache behavior**: Steampipe caches results for 5 minutes by default -- use `STEAMPIPE_CACHE=false` for real-time data
- **Mod dependencies**: Benchmarks require specific plugins -- install required plugins before running mods
- **Rate limiting**: Parallel queries across many accounts can hit cloud provider API rate limits
- **Table schema changes**: Plugin updates can change column names -- review after upgrading
