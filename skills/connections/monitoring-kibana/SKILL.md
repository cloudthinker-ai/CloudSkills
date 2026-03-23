---
name: monitoring-kibana
description: |
  Use when working with Kibana — kibana visualization platform with space
  management, saved objects, index patterns, dashboard export, and lens
  analysis. Covers dashboard management, visualization listing, data view
  configuration, alerting rules, and reporting. Use when managing Kibana spaces,
  exporting dashboards, reviewing index patterns, or analyzing saved objects via
  API.
connection_type: kibana
preload: false
---

# Kibana Monitoring Skill

Manage and analyze Kibana dashboards, saved objects, spaces, and index patterns.

## API Conventions

### Authentication
Kibana API uses Basic auth or API key — injected by connection. Requires `kbn-xsrf: true` header for mutations.

### Base URL
- Kibana API: `http://<host>:5601/api/`
- Use connection-injected `KIBANA_BASE_URL`.

### Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `jq` to extract only needed saved object attributes
- NEVER dump full saved object payloads — extract titles and metadata

### Core Helper Function

```bash
#!/bin/bash

kibana_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "kbn-xsrf: true" \
            -H "Content-Type: application/json" \
            -u "${KIBANA_USER}:${KIBANA_PASS}" \
            "${KIBANA_BASE_URL}/api${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "kbn-xsrf: true" \
            -u "${KIBANA_USER}:${KIBANA_PASS}" \
            "${KIBANA_BASE_URL}/api${endpoint}"
    fi
}

kibana_saved_objects() {
    local type="$1"
    local per_page="${2:-20}"
    kibana_api GET "/saved_objects/_find?type=${type}&per_page=${per_page}"
}
```

## Parallel Execution

```bash
{
    kibana_api GET "/spaces/space" &
    kibana_api GET "/status" &
    kibana_saved_objects "index-pattern" 50 &
}
wait
```

## Anti-Hallucination Rules

**NEVER assume space IDs, dashboard IDs, or index pattern names. ALWAYS discover first.**

### Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Kibana Status ==="
kibana_api GET "/status" | jq '{name: .name, version: .version.number, status: .status.overall.state}'

echo ""
echo "=== Spaces ==="
kibana_api GET "/spaces/space" | jq -r '.[] | "\(.id)\t\(.name)\t\(.disabledFeatures | length) disabled features"'

echo ""
echo "=== Index Patterns (Data Views) ==="
kibana_saved_objects "index-pattern" 50 \
    | jq -r '.saved_objects[] | "\(.id)\t\(.attributes.title)"' | head -20

echo ""
echo "=== Saved Object Counts by Type ==="
for type in dashboard visualization lens search index-pattern; do
    count=$(kibana_saved_objects "$type" 1 | jq '.total')
    echo "$type: $count"
done
```

## Common Operations

### Space Management

```bash
#!/bin/bash
echo "=== All Spaces ==="
kibana_api GET "/spaces/space" | jq -r '.[] | "\(.id)\t\(.name)\t\(.description // "no description")"'

echo ""
echo "=== Space Feature Config ==="
kibana_api GET "/spaces/space" | jq -r '.[] | "\(.id)\tdisabled:\(.disabledFeatures | join(",") // "none")"'
```

### Dashboard Management

```bash
#!/bin/bash
SPACE="${1:-default}"
echo "=== Dashboards in Space: ${SPACE} ==="
kibana_saved_objects "dashboard" 50 \
    | jq -r '.saved_objects[] | "\(.id)\t\(.attributes.title)\t\(.updated_at[0:10])"' \
    | sort -t$'\t' -k3 -r | head -20

echo ""
echo "=== Dashboard Panel Counts ==="
kibana_saved_objects "dashboard" 20 \
    | jq -r '.saved_objects[] | "\(.attributes.title)\t\(.attributes.panelsJSON | fromjson | length) panels"' | head -15
```

### Saved Object Export

```bash
#!/bin/bash
DASHBOARD_ID="${1:?Dashboard ID required}"

echo "=== Exporting Dashboard ==="
kibana_api POST "/saved_objects/_export" \
    "{\"objects\":[{\"type\":\"dashboard\",\"id\":\"${DASHBOARD_ID}\"}],\"includeReferencesDeep\":true}" \
    | jq -r 'select(.type != null) | "\(.type)\t\(.id)\t\(.attributes.title // .attributes.name // "unnamed")"' \
    | head -20

echo ""
echo "=== Dashboard References ==="
kibana_api GET "/saved_objects/dashboard/${DASHBOARD_ID}" \
    | jq -r '.references[] | "\(.type)\t\(.id)\t\(.name)"' | head -15
```

### Index Pattern (Data View) Analysis

```bash
#!/bin/bash
echo "=== Data Views ==="
kibana_saved_objects "index-pattern" 50 \
    | jq -r '.saved_objects[] | "\(.id)\t\(.attributes.title)\ttime_field:\(.attributes.timeFieldName // "none")"'

echo ""
echo "=== Data View Field Counts ==="
kibana_saved_objects "index-pattern" 20 \
    | jq -r '.saved_objects[] | "\(.attributes.title)\t\(.attributes.fields | fromjson | length) fields"' | head -15

echo ""
echo "=== Scripted Fields ==="
kibana_saved_objects "index-pattern" 20 \
    | jq -r '.saved_objects[] | .attributes.fields | fromjson | map(select(.scripted == true)) | .[] | "\(.name)\t\(.type)\t\(.script[0:60])"' | head -10
```

### Alerting Rules

```bash
#!/bin/bash
echo "=== Alert Rules ==="
kibana_api GET "/alerting/rules/_find?per_page=50" \
    | jq -r '.data[] | "\(.id)\t\(.name)\t\(.enabled)\t\(.rule_type_id)\t\(.execution_status.status)"' | head -20

echo ""
echo "=== Failed Alert Rules ==="
kibana_api GET "/alerting/rules/_find?per_page=50" \
    | jq -r '.data[] | select(.execution_status.status == "error") | "\(.name)\t\(.execution_status.error.message[0:80])"' | head -10

echo ""
echo "=== Alert Rule Types ==="
kibana_api GET "/alerting/rules/_find?per_page=100" \
    | jq -r '[.data[].rule_type_id] | group_by(.) | map("\(.[0]): \(length)") | .[]'
```

## Output Format

Present results as a structured report:
```
Monitoring Kibana Report
════════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

## Common Pitfalls

- **kbn-xsrf header**: Required for all POST/PUT/DELETE — `kbn-xsrf: true` (any value works)
- **Space-aware URLs**: Prefix with `/s/{space-id}` for non-default spaces — e.g., `/s/production/api/...`
- **Saved object IDs**: UUIDs, not human-readable — always discover via `_find` first
- **Export format**: `_export` returns NDJSON (one JSON per line) — not a single JSON array
- **Data views vs index patterns**: Kibana 8.x uses "data views" — same API endpoint (`index-pattern`)
- **Pagination**: Use `page` and `per_page` parameters — default is 20 items per page
- **Version compatibility**: API endpoints vary between Kibana 7.x and 8.x — check version first
- **References**: Dashboards reference visualizations which reference index patterns — export with `includeReferencesDeep`
