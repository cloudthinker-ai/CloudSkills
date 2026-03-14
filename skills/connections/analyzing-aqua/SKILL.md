---
name: analyzing-aqua
description: |
  Aqua Security platform analysis. Covers container runtime protection, image assurance policies, compliance frameworks, vulnerability management, workload protection, and registry scanning. Use when analyzing container security posture, reviewing image compliance, investigating runtime alerts, or auditing security policies.
connection_type: aqua
preload: false
---

# Aqua Security Analysis Skill

Analyze and manage Aqua Security container protection, image assurance, and compliance.

## MANDATORY: Discovery-First Pattern

**Always check server connectivity and scan status before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash

aqua_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"
    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $AQUA_TOKEN" \
            -H "Content-Type: application/json" \
            "${AQUA_URL}/api/v2/${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $AQUA_TOKEN" \
            "${AQUA_URL}/api/v2/${endpoint}"
    fi
}

echo "=== Aqua Server Status ==="
aqua_api GET "settings" | jq '{version: .version, license: .license_type}' 2>/dev/null

echo ""
echo "=== Dashboard Summary ==="
aqua_api GET "dashboard" | jq '{
    images: .images,
    containers: .running_containers,
    hosts: .hosts,
    vulnerabilities: .vulnerabilities
}' 2>/dev/null

echo ""
echo "=== Registered Registries ==="
aqua_api GET "registries" | jq -r '.result[]? | "\(.name)\t\(.type)\t\(.lastupdate)"' | column -t | head -10
```

## Core Helper Functions

```bash
#!/bin/bash

# Aqua API wrapper
aqua_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"
    local url="${AQUA_URL}/api/v2/${endpoint}"

    if [ -n "$data" ]; then
        curl -s -X "$method" -H "Authorization: Bearer $AQUA_TOKEN" \
            -H "Content-Type: application/json" "$url" -d "$data"
    else
        curl -s -X "$method" -H "Authorization: Bearer $AQUA_TOKEN" "$url"
    fi
}

# Get auth token
aqua_login() {
    curl -s -X POST "${AQUA_URL}/api/v1/login" \
        -H "Content-Type: application/json" \
        -d "{\"id\":\"$AQUA_USER\",\"password\":\"$AQUA_PASSWORD\"}" | jq -r '.token'
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use API with jq for structured output
- Summarize vulnerability counts by severity
- Never dump full image scan results -- extract top findings

## Common Operations

### Image Vulnerability Analysis

```bash
#!/bin/bash
IMAGE="${1:?Image name required}"

echo "=== Image Scan Results: $IMAGE ==="
aqua_api GET "images/${IMAGE}" | jq '{
    name: .name,
    registry: .registry,
    tag: .tag,
    scan_status: .scan_status,
    disallowed: .disallowed,
    vulnerability_summary: {
        total: .vulnerabilities_count,
        critical: .critical_vulnerabilities,
        high: .high_vulnerabilities,
        medium: .medium_vulnerabilities,
        low: .low_vulnerabilities,
        negligible: .negligible_vulnerabilities
    },
    malware: .malware_count,
    sensitive_data: .sensitive_data_count
}' 2>/dev/null

echo ""
echo "=== Top Vulnerabilities ==="
aqua_api GET "images/${IMAGE}/vulnerabilities?pagesize=10&order_by=-aqua_severity" | jq '
    .result[:10][] | {
        name: .name,
        severity: .aqua_severity,
        package: .resource.name,
        version: .resource.version,
        fix_version: .fix_version,
        description: (.description[:80])
    }
' 2>/dev/null
```

### Runtime Protection Status

```bash
#!/bin/bash
echo "=== Runtime Policies ==="
aqua_api GET "runtime_policies" | jq -r '
    .result[]? | "\(.name)\t\(.enabled)\t\(.scope.expression // "all")"
' | column -t | head -15

echo ""
echo "=== Running Containers ==="
aqua_api GET "containers?pagesize=20&order_by=-risk" | jq '
    .result[:10][] | {
        name: .name,
        image: .image_name,
        host: .host_name,
        risk: .risk,
        compliant: .is_compliant
    }
' 2>/dev/null
```

### Image Assurance Policies

```bash
#!/bin/bash
echo "=== Assurance Policies ==="
aqua_api GET "assurance_policy" | jq -r '
    .result[]? | "\(.id)\t\(.name)\t\(.application_scopes | join(","))\t\(.enabled)"
' | column -t | head -15

echo ""
echo "=== Non-Compliant Images ==="
aqua_api GET "images?scope=non_compliant&pagesize=20" | jq -r '
    .result[]? | "\(.name):\(.tag)\t\(.registry)\t\(.disallowed_reason // "policy violation")"
' | column -t | head -15
```

### Compliance Reports

```bash
#!/bin/bash
echo "=== Compliance Frameworks ==="
aqua_api GET "compliance/frameworks" | jq -r '
    .result[]? | "\(.name)\t\(.type)\t\(.controls_count) controls"
' | column -t | head -10

echo ""
FRAMEWORK="${1:-}"
if [ -n "$FRAMEWORK" ]; then
    echo "=== Compliance Status: $FRAMEWORK ==="
    aqua_api GET "compliance/frameworks/${FRAMEWORK}/status" | jq '{
        passing: .passing_controls,
        failing: .failing_controls,
        total: .total_controls,
        compliance_pct: (.passing_controls / .total_controls * 100 | floor)
    }' 2>/dev/null
fi
```

### Host and Enforcer Status

```bash
#!/bin/bash
echo "=== Enforcers ==="
aqua_api GET "enforcers" | jq -r '
    .result[:15][] | "\(.id)\t\(.hostname)\t\(.status)\t\(.type)\t\(.version)"
' | column -t

echo ""
echo "=== Enforcer Health ==="
aqua_api GET "enforcers" | jq '{
    total: (.result | length),
    connected: ([.result[] | select(.status == "connect")] | length),
    disconnected: ([.result[] | select(.status == "disconnect")] | length)
}' 2>/dev/null
```

## Safety Rules

- **Runtime policies can block containers** -- always test in audit mode before enforce mode
- **Image assurance can prevent deployments** -- review scope before enabling new policies
- **Never disable enforcers on production hosts** without a maintenance window
- **Compliance framework changes** affect all scoped resources -- review scope before modifying
- **API tokens should have minimum required permissions** -- do not use admin tokens for read-only tasks

## Common Pitfalls

- **Token expiration**: Aqua API tokens expire -- re-authenticate if receiving 401 errors
- **Image naming**: Image names must match registry format -- include registry prefix for non-Docker Hub images
- **Scan queue**: Large registries can overwhelm scan workers -- check scan queue depth
- **Runtime policy conflicts**: Multiple policies can apply to same workload -- check effective policies
- **Enforcer connectivity**: Network issues between enforcer and server cause policy sync failures
- **Scope expressions**: Complex scope expressions can accidentally include or exclude resources
- **Vulnerability database lag**: Newly disclosed CVEs take time to appear in scan results
- **Drift prevention**: Drift prevention policies block runtime changes -- can break legitimate container operations
