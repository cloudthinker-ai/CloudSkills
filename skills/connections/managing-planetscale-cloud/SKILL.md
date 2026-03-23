---
name: managing-planetscale-cloud
description: |
  Use when working with Planetscale Cloud — planetScale managed database
  platform management via the pscale CLI. Covers databases, branches, deploy
  requests, connection strings, and schema management. Use when managing
  PlanetScale databases or reviewing branch workflows.
connection_type: planetscale
preload: false
---

# Managing PlanetScale (Managed)

Manage PlanetScale databases using the `pscale` CLI.

## MANDATORY: Discovery-First Pattern

**Always discover available resources before performing analysis.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Organization ==="
pscale org list --format json 2>/dev/null | jq -r '.[] | "\(.id)\t\(.name)\t\(.plan)\t\(.created_at)"' | head -5

echo ""
echo "=== Databases ==="
pscale database list --format json 2>/dev/null | jq -r '.[] | "\(.id)\t\(.name)\t\(.region.slug)\t\(.state)\t\(.created_at)"' | head -20

echo ""
echo "=== Branches (per database) ==="
for db in $(pscale database list --format json 2>/dev/null | jq -r '.[].name'); do
    echo "--- $db ---"
    pscale branch list "$db" --format json 2>/dev/null | jq -r '.[] | "\(.name)\t\(.production)\t\(.ready)\t\(.created_at)"' | head -10
done

echo ""
echo "=== Deploy Requests ==="
for db in $(pscale database list --format json 2>/dev/null | jq -r '.[].name'); do
    echo "--- $db ---"
    pscale deploy-request list "$db" --format json 2>/dev/null | jq -r '.[] | "\(.number)\t\(.branch)\t\(.state)\t\(.created_at)"' | head -5
done
```

### Phase 2: Analysis

```bash
#!/bin/bash

DB_NAME="${1:?Database name required}"

echo "=== Database Details ==="
pscale database show "$DB_NAME" --format json 2>/dev/null | jq '{
    name, state, plan,
    region: .region.slug,
    production_branch: .default_branch,
    created_at, updated_at,
    insights_enabled: .insights_raw_queries
}'

echo ""
echo "=== Branch Status ==="
pscale branch list "$DB_NAME" --format json 2>/dev/null | jq -r '.[] | "\(.name)\t\(.production)\t\(.schema_last_updated_at)\t\(.ready)"' | head -10

echo ""
echo "=== Branch Schema ==="
BRANCH="${2:-main}"
pscale branch schema "$DB_NAME" "$BRANCH" --format json 2>/dev/null | jq -r '.[] | "\(.name)\t\(.raw)"' | head -20

echo ""
echo "=== Open Deploy Requests ==="
pscale deploy-request list "$DB_NAME" --format json 2>/dev/null | jq -r '[.[] | select(.state == "open")] | .[] | "\(.number)\t\(.branch)\t\(.into_branch)\t\(.created_at)"' | head -10

echo ""
echo "=== Audit Log ==="
pscale audit-log list --format json 2>/dev/null | jq -r '.[] | "\(.created_at)\t\(.actor_display_name)\t\(.action)\t\(.auditable_display_name)"' | head -10
```

## Output Format

```
DATABASE   REGION    STATE    PLAN         CREATED
my-app-db  us-east   ready    scaler_pro   2024-01-15
```

## Safety Rules
- Use read-only commands: `list`, `show`, `schema`
- Never run `delete`, `close`, `revert` without explicit user confirmation
- Use `--format json` with jq for structured output parsing
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

