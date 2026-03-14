---
name: managing-grype
description: |
  Anchore Grype vulnerability scanner for container images, filesystems, and SBOMs. Covers image scanning, SBOM-based vulnerability matching, severity filtering, fix tracking, and database management. Use when scanning container images for vulnerabilities, analyzing SBOM security, reviewing vulnerability findings, or managing Grype database updates and scan configurations.
connection_type: grype
preload: false
---

# Grype Management Skill

Manage and analyze Grype vulnerability scans for container images, filesystems, and SBOMs.

## CLI Conventions

### Authentication
No authentication required for local CLI. For private registries, use standard Docker credentials.

### CLI Tool
`grype` for local scanning with JSON output

### Core Helper Function

```bash
#!/bin/bash

grype_scan() {
    local target="$1"
    local extra_args="${2:-}"
    grype "$target" -o json $extra_args 2>/dev/null
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target <=50 lines per script output
- Never dump full scan output

## Discovery Phase

```bash
#!/bin/bash
echo "=== Grype Version ==="
grype version 2>&1 | head -3

echo ""
echo "=== Database Status ==="
grype db status 2>&1

echo ""
echo "=== Supported Sources ==="
echo "Container images (Docker, OCI)"
echo "Filesystem directories"
echo "SBOM files (CycloneDX, SPDX, Syft JSON)"
echo "Archive files (tar, jar, war, zip)"
```

## Analysis Phase

### Image Vulnerability Scan

```bash
#!/bin/bash
IMAGE="${1:?Container image required (e.g., nginx:latest)}"

echo "=== Scanning: $IMAGE ==="
RESULTS=$(grype_scan "$IMAGE")

echo "$RESULTS" | jq '{
    total: (.matches | length),
    critical: ([.matches[] | select(.vulnerability.severity == "Critical")] | length),
    high: ([.matches[] | select(.vulnerability.severity == "High")] | length),
    medium: ([.matches[] | select(.vulnerability.severity == "Medium")] | length),
    low: ([.matches[] | select(.vulnerability.severity == "Low")] | length),
    fixable: ([.matches[] | select(.vulnerability.fix.state == "fixed")] | length)
}'

echo ""
echo "=== Critical/High Vulnerabilities ==="
echo "$RESULTS" | jq -r '.matches[] | select(.vulnerability.severity == "Critical" or .vulnerability.severity == "High") | "\(.vulnerability.severity)\t\(.vulnerability.id)\t\(.artifact.name[0:25])\tv\(.artifact.version)\tfix:\(.vulnerability.fix.versions[0] // "none")"' \
    | column -t | head -20
```

### Fix Prioritization

```bash
#!/bin/bash
IMAGE="${1:?Container image required}"

echo "=== Fixable Vulnerabilities ==="
grype_scan "$IMAGE" \
    | jq -r '.matches[] | select(.vulnerability.fix.state == "fixed") | "\(.vulnerability.severity)\t\(.vulnerability.id)\t\(.artifact.name[0:25])\tv\(.artifact.version) -> \(.vulnerability.fix.versions[0])"' \
    | sort | column -t | head -20

echo ""
echo "=== Unfixed Critical/High ==="
grype_scan "$IMAGE" \
    | jq -r '.matches[] | select(.vulnerability.fix.state != "fixed" and (.vulnerability.severity == "Critical" or .vulnerability.severity == "High")) | "\(.vulnerability.severity)\t\(.vulnerability.id)\t\(.artifact.name[0:25])\tv\(.artifact.version)"' \
    | column -t | head -15
```

### Multi-Image Comparison

```bash
#!/bin/bash
echo "=== Multi-Image Vulnerability Comparison ==="
for IMAGE in "$@"; do
    RESULTS=$(grype_scan "$IMAGE" 2>/dev/null)
    CRITICAL=$(echo "$RESULTS" | jq '[.matches[] | select(.vulnerability.severity == "Critical")] | length')
    HIGH=$(echo "$RESULTS" | jq '[.matches[] | select(.vulnerability.severity == "High")] | length')
    TOTAL=$(echo "$RESULTS" | jq '.matches | length')
    FIXABLE=$(echo "$RESULTS" | jq '[.matches[] | select(.vulnerability.fix.state == "fixed")] | length')
    echo "$IMAGE\ttotal:${TOTAL}\tcritical:${CRITICAL}\thigh:${HIGH}\tfixable:${FIXABLE}"
done | column -t
```

### SBOM Scanning

```bash
#!/bin/bash
SBOM_FILE="${1:?SBOM file path required}"

echo "=== SBOM Vulnerability Scan ==="
RESULTS=$(grype "sbom:${SBOM_FILE}" -o json 2>/dev/null)

echo "$RESULTS" | jq '{
    total_vulns: (.matches | length),
    by_severity: (.matches | group_by(.vulnerability.severity) | map({severity: .[0].vulnerability.severity, count: length}) | sort_by(.count) | reverse)
}'

echo ""
echo "=== Top Vulnerable Components ==="
echo "$RESULTS" | jq -r '[.matches[] | {name: .artifact.name, severity: .vulnerability.severity}] | group_by(.name) | map({name: .[0].name, count: length, worst: ([.[].severity] | if any(. == "Critical") then "Critical" elif any(. == "High") then "High" else "Medium" end)}) | sort_by(.count) | reverse | .[:10][] | "\(.count)\t\(.worst)\t\(.name)"' \
    | column -t
```

## Common Pitfalls

- **Database freshness**: Run `grype db update` regularly -- stale DB misses recent CVEs
- **Image pull**: Grype pulls images from registry -- ensure registry credentials are configured
- **Output formats**: Use `-o json` for parsing, `-o table` for display, `-o cyclonedx` for SBOM
- **Severity filtering**: Use `--only-fixed` to show only fixable vulns, `--fail-on critical` for CI/CD
- **Distroless images**: May have limited OS-level detection -- rely on language-specific matchers
- **SBOM prefix**: Use `sbom:` prefix for SBOM file input, `dir:` for filesystem scanning
