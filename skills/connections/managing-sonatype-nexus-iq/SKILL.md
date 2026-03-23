---
name: managing-sonatype-nexus-iq
description: |
  Use when working with Sonatype Nexus Iq — sonatype Nexus IQ software
  composition analysis for open-source vulnerability detection, license
  compliance, and policy management. Covers application scanning, component
  analysis, policy violations, waivers, and vulnerability tracking across the
  software supply chain. Use when reviewing SCA scan results, analyzing
  dependency vulnerabilities, managing policy violations, or tracking component
  risk across applications.
connection_type: sonatype-nexus-iq
preload: false
---

# Sonatype Nexus IQ Management Skill

Manage and analyze Sonatype Nexus IQ applications, policy violations, vulnerabilities, and component risks.

## API Conventions

### Authentication
All API calls use Basic Auth via `Authorization: Basic $NEXUS_IQ_AUTH` -- injected automatically. Never hardcode credentials.

### Base URL
`https://$NEXUS_IQ_HOST/api/v2`

### Core Helper Function

```bash
#!/bin/bash

nexus_iq_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Basic $NEXUS_IQ_AUTH" \
            -H "Content-Type: application/json" \
            "https://${NEXUS_IQ_HOST}/api/v2${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Basic $NEXUS_IQ_AUTH" \
            -H "Content-Type: application/json" \
            "https://${NEXUS_IQ_HOST}/api/v2${endpoint}"
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
echo "=== Organizations ==="
nexus_iq_api GET "/organizations" \
    | jq -r '.organizations[] | "\(.id)\t\(.name)"' | column -t | head -10

echo ""
echo "=== Applications ==="
nexus_iq_api GET "/applications" \
    | jq '{total_apps: (.applications | length)}'

echo ""
echo "=== Recent Evaluations ==="
nexus_iq_api GET "/reports/applications" \
    | jq -r '.[] | "\(.applicationId)\t\(.stage)\t\(.reportDataUrl[0:50])"' | head -10 | column -t
```

## Analysis Phase

### Policy Violations Overview

```bash
#!/bin/bash
APP_ID="${1:-}"

echo "=== Policy Violation Summary ==="
if [ -n "$APP_ID" ]; then
    REPORT=$(nexus_iq_api GET "/reports/applications/${APP_ID}" | jq -r '.[0].reportDataUrl')
    nexus_iq_api GET "$REPORT" \
        | jq '{critical: ([.components[].violations[]? | select(.policyThreatLevel >= 9)] | length), severe: ([.components[].violations[]? | select(.policyThreatLevel >= 7 and .policyThreatLevel < 9)] | length), moderate: ([.components[].violations[]? | select(.policyThreatLevel >= 4 and .policyThreatLevel < 7)] | length)}'
else
    nexus_iq_api GET "/policyViolations/crossStage" \
        | jq -r '.applicationViolations[:15][] | "\(.application.name[0:30])\tcrit:\(.criticalPolicyViolationCount)\tsevere:\(.severePolicyViolationCount)\tmod:\(.moderatePolicyViolationCount)"' | column -t
fi
```

### Vulnerable Components

```bash
#!/bin/bash
APP_ID="${1:?Application ID required}"

echo "=== Vulnerable Components ==="
REPORT=$(nexus_iq_api GET "/reports/applications/${APP_ID}" | jq -r '.[0].reportDataUrl')
nexus_iq_api GET "$REPORT" \
    | jq -r '.components[] | select(.violations | length > 0) | "\(.componentIdentifier.coordinates.artifactId // .displayName | .[0:30])\tv\(.componentIdentifier.coordinates.version // "N/A")\tviolations:\(.violations | length)\tmax_threat:\([.violations[].policyThreatLevel] | max)"' \
    | sort -t$'\t' -k4 -rn | column -t | head -20

echo ""
echo "=== License Issues ==="
nexus_iq_api GET "$REPORT" \
    | jq -r '.components[] | select(.licenseData.status == "Overridden" or .licenseData.threatCategory != null) | "\(.displayName[0:30])\t\(.licenseData.declaredLicenses[0].licenseName // "Unknown")\t\(.licenseData.status)"' \
    | head -10 | column -t
```

### Waiver Management

```bash
#!/bin/bash
echo "=== Active Waivers ==="
nexus_iq_api GET "/policyWaivers" \
    | jq -r '.[] | "\(.policyName[0:30])\t\(.componentName[0:25])\t\(.expiryTime[0:10] // "No expiry")\t\(.comment[0:30])"' \
    | column -t | head -15
```

## Output Format

Present results as a structured report:
```
Managing Sonatype Nexus Iq Report
═════════════════════════════════
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

- **Two-step report access**: Get report URL from `/reports/applications/{id}`, then fetch the report data
- **Application ID vs public ID**: Internal ID (UUID) differs from public ID -- look up via `/applications`
- **Stage filtering**: Scans happen at different stages (build, stage-release, release) -- filter accordingly
- **Rate limits**: No published limits but large queries can timeout -- paginate where possible
- **Report data**: Full report JSON can be very large -- always filter with jq
