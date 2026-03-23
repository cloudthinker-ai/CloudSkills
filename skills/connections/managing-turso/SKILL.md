---
name: managing-turso
description: |
  Use when working with Turso — turso edge database management via the turso
  CLI. Covers databases, groups, locations, replicas, tokens, and usage
  statistics. Use when managing Turso/libSQL databases or reviewing edge
  replication.
connection_type: turso
preload: false
---

# Managing Turso

Manage Turso edge databases using the `turso` CLI.

## MANDATORY: Discovery-First Pattern

**Always discover available resources before performing analysis.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Account Info ==="
turso auth whoami 2>/dev/null

echo ""
echo "=== Organizations ==="
turso org list 2>/dev/null | head -10

echo ""
echo "=== Databases ==="
turso db list 2>/dev/null | head -20

echo ""
echo "=== Groups ==="
turso group list 2>/dev/null | head -10

echo ""
echo "=== Available Locations ==="
turso db locations 2>/dev/null | head -20

echo ""
echo "=== Plan & Usage ==="
turso plan show 2>/dev/null
turso account show 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

DB_NAME="${1:?Database name required}"

echo "=== Database Details ==="
turso db show "$DB_NAME" 2>/dev/null

echo ""
echo "=== Database URL ==="
turso db show "$DB_NAME" --url 2>/dev/null

echo ""
echo "=== Database Instances ==="
turso db show "$DB_NAME" --instance-urls 2>/dev/null | head -10

echo ""
echo "=== Database Usage ==="
turso db inspect "$DB_NAME" 2>/dev/null

echo ""
echo "=== Database Tokens ==="
turso db tokens list "$DB_NAME" 2>/dev/null | head -5

echo ""
echo "=== Group Details ==="
GROUP=$(turso db show "$DB_NAME" 2>/dev/null | grep -i group | awk '{print $NF}')
if [ -n "$GROUP" ]; then
    turso group show "$GROUP" 2>/dev/null
    echo ""
    echo "=== Group Locations ==="
    turso group locations list "$GROUP" 2>/dev/null | head -10
fi

echo ""
echo "=== Shell Query (table list) ==="
turso db shell "$DB_NAME" "SELECT name, type FROM sqlite_master WHERE type='table' ORDER BY name;" 2>/dev/null | head -20
```

## Output Format

```
DATABASE    GROUP      LOCATIONS        STATUS    SIZE
my-app-db   default    ord,lax,ams      healthy   45MB
analytics   default    ord              healthy   120MB
```

## Safety Rules
- Use read-only commands: `list`, `show`, `inspect`, `locations`
- Never run `destroy`, `delete`, `drop` without explicit user confirmation
- Shell queries should be read-only SELECT statements
- Limit output with `| head -N` to stay under 50 lines

## Anti-Hallucination Rules

1. **NEVER assume resource names** — always discover via CLI/API in Phase 1 before referencing in Phase 2.
2. **NEVER fabricate metric names or dimensions** — verify against the service documentation or `--help` output.
3. **NEVER mix CLI commands between service versions** — confirm which version/API you are targeting.
4. **ALWAYS use the discovery → verify → analyze chain** — every resource referenced must have been discovered first.
5. **ALWAYS handle empty results gracefully** — an empty response is valid data, not an error to retry.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

