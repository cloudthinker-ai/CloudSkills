---
name: managing-veracode
description: |
  Use when working with Veracode — veracode application security testing
  platform for SAST, DAST, SCA, and manual penetration testing. Covers
  application profiles, scan results, flaw management, policy compliance, and
  sandbox testing. Use when reviewing application scan results, analyzing
  security flaws, tracking remediation progress, or managing Veracode
  application profiles and policies.
connection_type: veracode
preload: false
---

# Veracode Management Skill

Manage and analyze Veracode application scans, flaws, policy compliance, and SCA findings.

## API Conventions

### Authentication
All API calls use HMAC-based authentication via Veracode API credentials -- injected automatically. Never hardcode credentials.

### Base URL
`https://api.veracode.com`

### Core Helper Function

```bash
#!/bin/bash

veracode_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: $VERACODE_HMAC_HEADER" \
            -H "Content-Type: application/json" \
            "https://api.veracode.com${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: $VERACODE_HMAC_HEADER" \
            -H "Content-Type: application/json" \
            "https://api.veracode.com${endpoint}"
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
echo "=== Application Profiles ==="
veracode_api GET "/appsec/v1/applications?size=100" \
    | jq '{total_apps: (.page.total_elements), profiles: [.embedded.applications[:10][] | {name: .profile.name, policy: .profile.policies[0].name}]}'

echo ""
echo "=== Recent Scans ==="
veracode_api GET "/appsec/v2/builds?size=10" \
    | jq -r '.embedded.builds[] | "\(.created[0:16])\t\(.scan_type)\t\(.status)\t\(.application_name[0:30])"' | column -t
```

## Analysis Phase

### Flaw Overview

```bash
#!/bin/bash
APP_GUID="${1:-}"

echo "=== Flaw Summary ==="
if [ -n "$APP_GUID" ]; then
    veracode_api GET "/appsec/v2/applications/${APP_GUID}/findings?size=1" \
        | jq '"Total findings: \(.page.total_elements)"' -r

    echo ""
    echo "=== Findings by Severity ==="
    for sev in 5 4 3 2 1; do
        COUNT=$(veracode_api GET "/appsec/v2/applications/${APP_GUID}/findings?size=1&severity=${sev}" | jq '.page.total_elements')
        echo "Severity $sev: $COUNT"
    done
else
    echo "=== Portfolio Summary ==="
    veracode_api GET "/appsec/v1/applications?size=20" \
        | jq -r '._embedded.applications[] | "\(.profile.name[0:30])\tpolicy:\(.profile.policies[0].policy_compliance_status)\tflaws:\(.findings_count // "N/A")"' \
        | column -t | head -20
fi
```

### Critical Findings

```bash
#!/bin/bash
APP_GUID="${1:?Application GUID required}"

echo "=== Critical/Very High Findings ==="
veracode_api GET "/appsec/v2/applications/${APP_GUID}/findings?size=20&severity%5B%5D=5&severity%5B%5D=4&violates_policy=true" \
    | jq -r '._embedded.findings[] | "\(.finding_details.severity)\t\(.finding_details.finding_category.name[0:25])\t\(.finding_details.cwe.name[0:40])\t\(.finding_status.status)"' \
    | column -t | head -20

echo ""
echo "=== Open Flaws by CWE ==="
veracode_api GET "/appsec/v2/applications/${APP_GUID}/findings?size=200&finding_status=OPEN" \
    | jq -r '[._embedded.findings[].finding_details.cwe.name] | group_by(.) | map({cwe: .[0][0:40], count: length}) | sort_by(.count) | reverse | .[:10][] | "\(.count)\t\(.cwe)"' | column -t
```

### Policy Compliance

```bash
#!/bin/bash
echo "=== Policy Compliance Status ==="
veracode_api GET "/appsec/v1/applications?size=50" \
    | jq -r '._embedded.applications[] | "\(.profile.policies[0].policy_compliance_status)\t\(.profile.name[0:40])\t\(.profile.policies[0].name[0:25])"' \
    | sort | column -t | head -20

echo ""
echo "=== Non-Compliant Applications ==="
veracode_api GET "/appsec/v1/applications?size=50" \
    | jq -r '[._embedded.applications[] | select(.profile.policies[0].policy_compliance_status != "PASSED")] | length | "Non-compliant apps: \(.)"'
```

### SCA Findings

```bash
#!/bin/bash
APP_GUID="${1:?Application GUID required}"

echo "=== SCA Vulnerability Summary ==="
veracode_api GET "/appsec/v2/applications/${APP_GUID}/findings?size=20&scan_type=SCA&severity%5B%5D=5&severity%5B%5D=4" \
    | jq -r '._embedded.findings[] | "\(.finding_details.severity)\t\(.finding_details.component_filename[0:30])\tv\(.finding_details.component_version // "N/A")\t\(.finding_details.cve.name // "N/A")"' \
    | column -t | head -15
```

## Output Format

Present results as a structured report:
```
Managing Veracode Report
════════════════════════
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

- **HMAC authentication**: Uses custom HMAC scheme -- cannot use simple Bearer tokens
- **GUID vs legacy ID**: REST API uses GUIDs, XML API uses legacy numeric IDs
- **XML vs REST API**: Legacy XML API at `/api/5.0/` still used for some operations -- prefer REST API
- **Severity scale**: 5 = Very High, 4 = High, 3 = Medium, 2 = Low, 1 = Very Low
- **Scan types**: STATIC, DYNAMIC, SCA, MANUAL -- filter by `scan_type` parameter
- **Rate limits**: 500 requests/minute -- check `X-Rate-Limit-Remaining` header
