---
name: managing-osv-scanner
description: |
  Use when working with Osv Scanner — google OSV-Scanner for open-source
  vulnerability detection using the OSV database. Covers dependency scanning,
  SBOM analysis, vulnerability lookup, license checking, and guided remediation.
  Use when scanning projects for known vulnerabilities, analyzing dependency
  security, querying the OSV database for CVE details, or generating
  vulnerability reports for open-source components.
connection_type: osv-scanner
preload: false
---

# OSV-Scanner Management Skill

Manage and analyze OSV-Scanner vulnerability findings, dependency scans, and OSV database queries.

## CLI Conventions

### Authentication
OSV API is public and free. For higher rate limits, use `OSV_API_KEY` if available.

### CLI Tool
`osv-scanner` for local scanning, or OSV API at `https://api.osv.dev/v1`

### Core Helper Functions

```bash
#!/bin/bash

# Local osv-scanner
osv_scan() {
    local target="$1"
    local extra_args="${2:-}"
    osv-scanner --format json $extra_args "$target" 2>/dev/null
}

# OSV API
osv_api() {
    local endpoint="$1"
    local data="${2:-}"

    curl -s -X POST \
        -H "Content-Type: application/json" \
        "https://api.osv.dev/v1${endpoint}" \
        -d "$data"
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target <=50 lines per script output
- Never dump full scan output

## Discovery Phase

```bash
#!/bin/bash
echo "=== OSV-Scanner Version ==="
osv-scanner --version 2>&1 | head -1

echo ""
echo "=== Scan Project Directory ==="
osv_scan "--recursive ." \
    | jq '{total_packages: (.results | length), total_vulns: ([.results[].packages[].vulnerabilities[]?] | length)}'

echo ""
echo "=== Lockfiles Detected ==="
osv_scan "--recursive ." \
    | jq -r '.results[] | "\(.source.path)\t\(.source.type)\tpackages:\(.packages | length)"' | column -t
```

## Analysis Phase

### Vulnerability Overview

```bash
#!/bin/bash
SCAN_PATH="${1:-.}"

echo "=== Vulnerability Summary ==="
RESULTS=$(osv_scan "--recursive $SCAN_PATH")

echo "$RESULTS" | jq '{
    total_vulns: ([.results[].packages[].vulnerabilities[]?] | length),
    critical: ([.results[].packages[].vulnerabilities[]? | select(.database_specific.severity == "CRITICAL")] | length),
    high: ([.results[].packages[].vulnerabilities[]? | select(.database_specific.severity == "HIGH")] | length),
    affected_packages: ([.results[].packages[] | select(.vulnerabilities | length > 0)] | length)
}'

echo ""
echo "=== Vulnerable Packages ==="
echo "$RESULTS" | jq -r '.results[].packages[] | select(.vulnerabilities | length > 0) | "\(.package.name)\tv\(.package.version)\tvulns:\(.vulnerabilities | length)\t\(.vulnerabilities[0].id // "N/A")"' \
    | sort -t$'\t' -k3 -rn | column -t | head -20
```

### CVE Lookup

```bash
#!/bin/bash
VULN_ID="${1:?Vulnerability ID required (e.g., CVE-2024-1234 or GHSA-xxxx)}"

echo "=== Vulnerability Details ==="
osv_api "/vulns/${VULN_ID}" \
    | jq '{
        id: .id,
        summary: .summary[0:100],
        severity: .database_specific.severity,
        published: .published[0:10],
        modified: .modified[0:10],
        affected_packages: [.affected[:5][] | {ecosystem: .package.ecosystem, name: .package.name, ranges: .ranges[0].events}],
        references: [.references[:3][].url]
    }'
```

### Batch Query

```bash
#!/bin/bash
PACKAGE="${1:?Package name required}"
VERSION="${2:?Version required}"
ECOSYSTEM="${3:-npm}"

echo "=== Query Package Vulnerabilities ==="
osv_api "/query" "{\"package\":{\"name\":\"${PACKAGE}\",\"ecosystem\":\"${ECOSYSTEM}\"},\"version\":\"${VERSION}\"}" \
    | jq -r '{
        total: (.vulns | length),
        vulnerabilities: [.vulns[:10][] | {id: .id, summary: .summary[0:80], severity: .database_specific.severity, published: .published[0:10]}]
    }'
```

### Guided Remediation

```bash
#!/bin/bash
SCAN_PATH="${1:-.}"

echo "=== Fix Suggestions ==="
osv-scanner fix --strategy=in-place --non-interactive --format json "$SCAN_PATH" 2>/dev/null \
    | jq -r '.fixes[]? | "\(.package.name)\t\(.package.version) -> \(.fixed_version)\tfixes:\(.vulnerabilities | length) vulns"' \
    | column -t | head -15

echo ""
echo "=== Packages with Available Fixes ==="
osv_scan "--recursive $SCAN_PATH" \
    | jq -r '.results[].packages[] | select(.vulnerabilities | length > 0) | .vulnerabilities[] | select(.affected[0].ranges[0].events[] | select(.fixed != null)) | "\(.id)\tfixed_in:\(.affected[0].ranges[0].events[] | select(.fixed != null) | .fixed)"' \
    | sort -u | head -15 | column -t
```

## Output Format

Present results as a structured report:
```
Managing Osv Scanner Report
═══════════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

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

## Common Pitfalls

- **Ecosystems**: OSV covers npm, PyPI, Go, Maven, crates.io, NuGet, and more -- specify correct ecosystem
- **OSV vs CVE IDs**: OSV has its own IDs (GHSA, PYSEC, etc.) -- map to CVE via aliases
- **Lockfile required**: Accurate scanning requires lockfiles (package-lock.json, go.sum, etc.)
- **API rate limits**: Public API has generous limits but batch queries are preferred for many packages
- **SBOM input**: Supports CycloneDX and SPDX SBOM formats via `--sbom` flag
