---
name: managing-sonatype-nexus-iq
description: |
  Sonatype Nexus IQ software composition analysis for open-source vulnerability detection, license compliance, and policy management. Covers application scanning, component analysis, policy violations, waivers, and vulnerability tracking across the software supply chain. Use when reviewing SCA scan results, analyzing dependency vulnerabilities, managing policy violations, or tracking component risk across applications.
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

## Common Pitfalls

- **Two-step report access**: Get report URL from `/reports/applications/{id}`, then fetch the report data
- **Application ID vs public ID**: Internal ID (UUID) differs from public ID -- look up via `/applications`
- **Stage filtering**: Scans happen at different stages (build, stage-release, release) -- filter accordingly
- **Rate limits**: No published limits but large queries can timeout -- paginate where possible
- **Report data**: Full report JSON can be very large -- always filter with jq
