---
name: managing-whitesource
description: |
  Use when working with Whitesource — mend (formerly WhiteSource) software
  composition analysis for open-source security, license compliance, and
  automated remediation. Covers vulnerability detection, library inventory,
  policy violations, fix recommendations, and project health tracking. Use when
  reviewing open-source vulnerabilities, analyzing dependency risks, managing
  license compliance, or tracking remediation progress across projects.
connection_type: whitesource
preload: false
---

# Mend (WhiteSource) Management Skill

Manage and analyze Mend vulnerability findings, library inventory, license compliance, and policy violations.

## API Conventions

### Authentication
All API calls use the API key in request body or `Authorization: Bearer $MEND_API_TOKEN` -- injected automatically. Never hardcode tokens.

### Base URL
`https://api-$MEND_ENV.mend.io/api/v2.0`

### Core Helper Function

```bash
#!/bin/bash

mend_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"
    local base="https://api-${MEND_ENV}.mend.io/api/v2.0"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $MEND_API_TOKEN" \
            -H "Content-Type: application/json" \
            "${base}${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $MEND_API_TOKEN" \
            -H "Content-Type: application/json" \
            "${base}${endpoint}"
    fi
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields with `jq`
- Target <=50 lines per script output
- Never dump full API responses

## Discovery Phase

```bash
#!/bin/bash
echo "=== Organization Summary ==="
mend_api GET "/orgs" \
    | jq -r '.retVal[] | "\(.uuid)\t\(.name)"' | head -5

echo ""
echo "=== Products ==="
mend_api GET "/orgs/$MEND_ORG_UUID/products" \
    | jq '{total_products: (.retVal | length)}'

echo ""
echo "=== Projects ==="
mend_api GET "/orgs/$MEND_ORG_UUID/projects" \
    | jq '{total_projects: (.retVal | length)}'
```

## Analysis Phase

### Vulnerability Overview

```bash
#!/bin/bash
echo "=== Vulnerability Summary ==="
mend_api GET "/orgs/$MEND_ORG_UUID/vulnerabilities?pageSize=1" \
    | jq '"Total vulnerabilities: \(.additionalData.totalItems)"' -r

echo ""
echo "=== Critical/High Vulnerabilities ==="
mend_api GET "/orgs/$MEND_ORG_UUID/vulnerabilities?pageSize=20&severity=CRITICAL,HIGH&sort=severity,desc" \
    | jq -r '.retVal[] | "\(.severity)\tCVSS:\(.cvss3_score // .cvss_score // "N/A")\t\(.name)\t\(.library.artifactId[0:25])\tv\(.library.version)"' \
    | column -t | head -20

echo ""
echo "=== Vulnerabilities by Severity ==="
for sev in CRITICAL HIGH MEDIUM LOW; do
    COUNT=$(mend_api GET "/orgs/$MEND_ORG_UUID/vulnerabilities?pageSize=1&severity=${sev}" | jq '.additionalData.totalItems')
    echo "$sev: $COUNT"
done
```

### Library Inventory

```bash
#!/bin/bash
echo "=== Library Count ==="
mend_api GET "/orgs/$MEND_ORG_UUID/libraries?pageSize=1" \
    | jq '"Total libraries: \(.additionalData.totalItems)"' -r

echo ""
echo "=== Libraries with Known Vulnerabilities ==="
mend_api GET "/orgs/$MEND_ORG_UUID/libraries?pageSize=15&vulnerabilities=true&sort=vulnerabilities,desc" \
    | jq -r '.retVal[] | "\(.vulnerabilities // 0) vulns\t\(.artifactId[0:30])\tv\(.version)\t\(.type)"' \
    | column -t

echo ""
echo "=== Outdated Libraries ==="
mend_api GET "/orgs/$MEND_ORG_UUID/libraries?pageSize=15&outdated=true" \
    | jq -r '.retVal[] | "\(.artifactId[0:30])\tcurrent:\(.version)\tlatest:\(.newestVersion // "N/A")"' | column -t
```

### Policy Violations

```bash
#!/bin/bash
echo "=== Policy Violations ==="
mend_api GET "/orgs/$MEND_ORG_UUID/policies/violations?pageSize=20" \
    | jq -r '.retVal[] | "\(.policyName[0:25])\t\(.library.artifactId[0:25])\t\(.project.name[0:25])\t\(.status)"' \
    | column -t | head -20

echo ""
echo "=== Violations by Policy ==="
mend_api GET "/orgs/$MEND_ORG_UUID/policies/violations?pageSize=500" \
    | jq -r '[.retVal[].policyName] | group_by(.) | map({policy: .[0][0:40], count: length}) | sort_by(.count) | reverse | .[] | "\(.count)\t\(.policy)"' | head -10 | column -t
```

## Output Format

Present results as a structured report:
```
Managing Whitesource Report
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

- **Environment-specific URL**: API base URL varies by environment (saas, saas-eu, app)
- **Org UUID required**: Most endpoints require the organization UUID in the path
- **Pagination**: Use `pageSize` and `page` parameters -- check `additionalData.totalItems`
- **Rate limits**: Varies by plan -- check response headers for remaining quota
- **Legacy vs v2 API**: Older v1.x API uses POST with `requestType` -- prefer v2.0 REST API
