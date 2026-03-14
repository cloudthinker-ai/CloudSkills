---
name: managing-nuclei
description: |
  ProjectDiscovery Nuclei vulnerability scanner for template-based scanning of web applications, networks, and cloud services. Covers scan execution, template management, result analysis, severity tracking, and integration with ProjectDiscovery Cloud. Use when running vulnerability scans, reviewing scan findings, managing nuclei templates, or analyzing scan results across targets.
connection_type: nuclei
preload: false
---

# Nuclei Management Skill

Manage and analyze Nuclei vulnerability scans, templates, findings, and scan configurations.

## CLI Conventions

### Authentication
For ProjectDiscovery Cloud Platform, use `Authorization: $PDCP_API_KEY`. For local CLI, no authentication needed.

### CLI Tool
`nuclei` (local) or ProjectDiscovery Cloud API at `https://cloud.projectdiscovery.io/api/v1`

### Core Helper Functions

```bash
#!/bin/bash

# Local nuclei scan
nuclei_scan() {
    local target="$1"
    local extra_args="${2:-}"
    nuclei -target "$target" -json -silent $extra_args 2>/dev/null
}

# ProjectDiscovery Cloud API
pdcp_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    local base="https://cloud.projectdiscovery.io/api/v1"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: $PDCP_API_KEY" \
            -H "Content-Type: application/json" \
            "${base}${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: $PDCP_API_KEY" \
            -H "Content-Type: application/json" \
            "${base}${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target <=50 lines per script output
- Never dump full scan output

## Discovery Phase

```bash
#!/bin/bash
echo "=== Nuclei Version ==="
nuclei -version 2>&1 | head -1

echo ""
echo "=== Template Stats ==="
nuclei -tl -silent 2>/dev/null | wc -l | xargs -I{} echo "Total templates: {}"

echo ""
echo "=== Templates by Severity ==="
for sev in critical high medium low info; do
    COUNT=$(nuclei -tl -silent -severity $sev 2>/dev/null | wc -l)
    echo "$sev: $COUNT"
done

echo ""
echo "=== Recent Scan Results (Cloud) ==="
pdcp_api GET "/scans?limit=5" \
    | jq -r '.data[]? | "\(.created_at[0:16])\t\(.status)\t\(.target_count) targets\t\(.finding_count) findings"' | column -t 2>/dev/null
```

## Analysis Phase

### Scan Results

```bash
#!/bin/bash
TARGET="${1:?Target URL or file required}"

echo "=== Running Targeted Scan ==="
nuclei -target "$TARGET" -json -silent -severity critical,high 2>/dev/null \
    | jq -r '"\(.info.severity)\t\(.template-id)\t\(.matched-at[0:50])\t\(.info.name[0:40])"' \
    | column -t | head -20

echo ""
echo "=== Finding Summary ==="
nuclei -target "$TARGET" -json -silent 2>/dev/null \
    | jq -r '.info.severity' | sort | uniq -c | sort -rn
```

### Template Management

```bash
#!/bin/bash
echo "=== Templates by Type ==="
for type in http dns file network; do
    COUNT=$(nuclei -tl -silent -type $type 2>/dev/null | wc -l)
    echo "$type: $COUNT"
done

echo ""
echo "=== CVE Templates (recent) ==="
nuclei -tl -silent -tags cve 2>/dev/null | tail -15

echo ""
echo "=== Template Update ==="
nuclei -update-templates 2>&1 | tail -5
```

### Cloud Platform Results

```bash
#!/bin/bash
echo "=== Scan History ==="
pdcp_api GET "/scans?limit=10" \
    | jq -r '.data[]? | "\(.created_at[0:16])\t\(.status)\ttargets:\(.target_count)\tfindings:\(.finding_count)"' | column -t

echo ""
echo "=== Findings by Severity ==="
pdcp_api GET "/findings?limit=1" \
    | jq '{total: .total}' 2>/dev/null

for sev in critical high medium low; do
    COUNT=$(pdcp_api GET "/findings?severity=${sev}&limit=1" | jq '.total // 0')
    echo "$sev: $COUNT"
done

echo ""
echo "=== Top Findings ==="
pdcp_api GET "/findings?severity=critical,high&limit=15" \
    | jq -r '.data[]? | "\(.severity)\t\(.template_id)\t\(.host[0:40])"' | column -t
```

## Common Pitfalls

- **Rate limiting targets**: Always use `-rate-limit` flag to avoid overwhelming targets
- **Template updates**: Run `nuclei -update-templates` regularly for latest CVE checks
- **JSON output**: Use `-json` flag for parseable output, `-silent` to suppress banner
- **Severity filtering**: Use `-severity critical,high` to focus on important findings
- **Scan scope**: Nuclei can be aggressive -- always get authorization before scanning
- **Output size**: Full scans generate massive output -- always filter by severity
