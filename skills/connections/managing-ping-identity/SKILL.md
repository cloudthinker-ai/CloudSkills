---
name: managing-ping-identity
description: |
  Use when working with Ping Identity — ping Identity platform management for
  SSO configuration, MFA policy review, directory bridge monitoring, session
  management, and environment health checks. Covers PingOne, PingFederate, and
  PingAccess administration. Read this skill before any Ping Identity operations
  — it enforces discovery-first patterns and strict read-only safety rules.
connection_type: ping-identity
preload: false
---

# Ping Identity Management Skill

Safely read and audit Ping Identity — the enterprise identity security platform.

## MANDATORY: Discovery-First Pattern

**Always discover environments, populations, and applications before performing targeted queries. Never guess environment IDs or application IDs.**

### Phase 1: Discovery

```bash
#!/bin/bash

ping_api() {
    local endpoint="$1"
    local method="${2:-GET}"
    curl -s -X "$method" \
         -H "Authorization: Bearer $PING_ACCESS_TOKEN" \
         -H "Content-Type: application/json" \
         "https://api.pingone.com/v1/${endpoint}"
}

echo "=== Environments ==="
ping_api "environments" | jq -r '.embedded.environments[] | "\(.id)\t\(.name)\t\(.type)\t\(.region)"' | column -t

echo ""
echo "=== Current Environment ==="
ping_api "environments/${PING_ENV_ID}" | jq '{
    id: .id,
    name: .name,
    type: .type,
    region: .region,
    organization: .organization.id,
    created: .createdAt,
    updated: .updatedAt
}'

echo ""
echo "=== Populations ==="
ping_api "environments/${PING_ENV_ID}/populations" | jq -r '.embedded.populations[] | "\(.id)\t\(.name)\t\(.userCount // "N/A")\t\(.description // "N/A")"' | column -t

echo ""
echo "=== Applications ==="
ping_api "environments/${PING_ENV_ID}/applications" | jq -r '.embedded.applications[] | "\(.id)\t\(.name)\t\(.type)\t\(.enabled)"' | column -t

echo ""
echo "=== Identity Providers ==="
ping_api "environments/${PING_ENV_ID}/identityProviders" | jq -r '.embedded.identityProviders[]? | "\(.id)\t\(.name)\t\(.type)\t\(.enabled)"' | column -t
```

**Phase 1 outputs:** Environment list, populations, applications, identity providers — only reference these in subsequent operations.

## Anti-Hallucination Rules

- **NEVER guess environment or application IDs** — always discover in Phase 1
- **NEVER assume population names** — always list populations first
- **NEVER fabricate policy names** — always list policies before querying
- **ONLY read and list** — never create, update, or delete without explicit request

## Safety Rules

- **READ-ONLY by default**: GET requests only — environments, applications, users, policies, audit events
- **MASK sensitive data**: Redact client secrets, signing keys, and user credentials
- **FORBIDDEN without explicit request**: POST/PUT/DELETE to applications, users, policies; secret rotation
- **NEVER print secrets**: Always use `*** REDACTED ***` for client secrets and signing keys

## Core Helper Functions

```bash
#!/bin/bash

ping_api() {
    local endpoint="$1"
    local method="${2:-GET}"
    curl -s -X "$method" \
         -H "Authorization: Bearer $PING_ACCESS_TOKEN" \
         -H "Content-Type: application/json" \
         "https://api.pingone.com/v1/${endpoint}"
}

# Paginated fetch using HAL _embedded pattern
ping_paginated() {
    local endpoint="$1"
    local max_pages="${2:-5}"
    local page=0
    local cursor=""

    while [ $page -lt $max_pages ]; do
        local sep="?"
        [[ "$endpoint" == *"?"* ]] && sep="&"
        local url="${endpoint}"
        [ -n "$cursor" ] && url="${endpoint}${sep}cursor=${cursor}"
        result=$(ping_api "$url")
        echo "$result" | jq '.embedded // .data // .' 2>/dev/null
        cursor=$(echo "$result" | jq -r '._links.next.href // empty' | grep -o 'cursor=[^&]*' | cut -d= -f2)
        [ -z "$cursor" ] && break
        page=$((page + 1))
    done
}
```

## Common Operations

### SSO Configuration Review

```bash
#!/bin/bash
APP_ID="${1:?Application ID required — discover via Phase 1}"

echo "=== Application Details ==="
ping_api "environments/${PING_ENV_ID}/applications/${APP_ID}" | jq '{
    id: .id,
    name: .name,
    description: .description,
    type: .type,
    enabled: .enabled,
    protocol: .protocol,
    home_page_url: .homePageUrl,
    login_page_url: .loginPageUrl,
    created: .createdAt
}'

echo ""
echo "=== Application Grant (Scopes) ==="
ping_api "environments/${PING_ENV_ID}/applications/${APP_ID}/grants" | jq -r '.embedded.grants[]? | "\(.id)\t\(.resource.name)\t\(.scopes | map(.id) | join(","))"' | column -t

echo ""
echo "=== Application Sign-On Policy ==="
ping_api "environments/${PING_ENV_ID}/applications/${APP_ID}/signOnPolicyAssignments" | jq -r '.embedded.signOnPolicyAssignments[]? | {
    id: .id,
    sign_on_policy: .signOnPolicy.id,
    priority: .priority
}'

echo ""
echo "=== OIDC/SAML Settings ==="
ping_api "environments/${PING_ENV_ID}/applications/${APP_ID}" | jq '{
    redirect_uris: .redirectUris,
    post_logout_redirect_uris: .postLogoutRedirectUris,
    response_types: .responseTypes,
    grant_types: .grantTypes,
    token_endpoint_auth_method: .tokenEndpointAuthMethod,
    pkce_enforcement: .pkceEnforcement
}'
```

### MFA Policy Review

```bash
#!/bin/bash
echo "=== MFA Policies ==="
ping_api "environments/${PING_ENV_ID}/mfaPolicies" | jq -r '.embedded.mfaPolicies[]? | {
    id: .id,
    name: .name,
    default: .default,
    sms: .sms.enabled,
    email: .email.enabled,
    totp: .totp.enabled,
    fido2: .fido2.enabled,
    mobile: .mobile.enabled
}'

echo ""
echo "=== Sign-On Policies ==="
ping_api "environments/${PING_ENV_ID}/signOnPolicies" | jq -r '.embedded.signOnPolicies[]? | "\(.id)\t\(.name)\t\(.default)"' | column -t

echo ""
echo "=== Sign-On Policy Actions (first policy) ==="
POLICY_ID=$(ping_api "environments/${PING_ENV_ID}/signOnPolicies" | jq -r '.embedded.signOnPolicies[0].id')
ping_api "environments/${PING_ENV_ID}/signOnPolicies/${POLICY_ID}/actions" | jq -r '.embedded.actions[]? | {
    id: .id,
    type: .type,
    priority: .priority,
    conditions: .condition,
    mfa: .mfa
}'
```

### Directory Bridge & User Federation

```bash
#!/bin/bash
echo "=== Gateway Instances ==="
ping_api "environments/${PING_ENV_ID}/gateways" | jq -r '.embedded.gateways[]? | {
    id: .id,
    name: .name,
    type: .type,
    enabled: .enabled,
    created: .createdAt
}'

echo ""
echo "=== Gateway Credentials ==="
GATEWAY_ID="${1:-}"
if [ -n "$GATEWAY_ID" ]; then
    ping_api "environments/${PING_ENV_ID}/gateways/${GATEWAY_ID}/instances" | jq -r '.embedded.instances[]? | {
        id: .id,
        hostname: .hostname,
        status: .currentStatus,
        last_reported: .lastReportedAt,
        version: .version,
        health_status: .healthStatus
    }'
fi

echo ""
echo "=== User Populations ==="
ping_api "environments/${PING_ENV_ID}/populations" | jq -r '.embedded.populations[] | {
    id: .id,
    name: .name,
    description: .description,
    user_count: .userCount,
    default: .default
}'
```

### Session Management

```bash
#!/bin/bash
echo "=== Active Sessions Summary ==="
ping_api "environments/${PING_ENV_ID}/sessions" 2>/dev/null | jq '{
    total: .count,
    sessions: [.embedded.sessions[:10][]? | {
        id: .id,
        user_id: .user.id,
        created: .createdAt,
        expires: .expiresAt,
        status: .status
    }]
}' || echo "Session listing may require elevated permissions"

echo ""
echo "=== Recent Authentication Events ==="
ping_api "environments/${PING_ENV_ID}/activities?filter=eventType eq 'AUTHENTICATION'&limit=20" | jq -r '.embedded.activities[]? | {
    time: .recordedAt,
    event: .eventType,
    result: .result.status,
    user: .actors.user.name,
    application: .resources.application.name,
    ip: .session.ip
}' 2>/dev/null || echo "Activities API may vary by PingOne tier"

echo ""
echo "=== Audit Events ==="
ping_api "environments/${PING_ENV_ID}/activities?limit=20" | jq -r '.embedded.activities[]? | "\(.recordedAt)\t\(.eventType)\t\(.result.status)\t\(.actors.user.name // "system")"' | column -t
```

### Resource & Scope Management

```bash
#!/bin/bash
echo "=== API Resources ==="
ping_api "environments/${PING_ENV_ID}/resources" | jq -r '.embedded.resources[]? | "\(.id)\t\(.name)\t\(.type)\t\(.audience // "N/A")"' | column -t

echo ""
RESOURCE_ID="${1:-}"
if [ -n "$RESOURCE_ID" ]; then
    echo "=== Scopes for Resource: $RESOURCE_ID ==="
    ping_api "environments/${PING_ENV_ID}/resources/${RESOURCE_ID}/scopes" | jq -r '.embedded.scopes[]? | "\(.id)\t\(.name)\t\(.description // "N/A")"' | column -t
fi
```

## Output Format

Present results as a structured report:
```
Managing Ping Identity Report
═════════════════════════════
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

- **Environment types**: SANDBOX vs PRODUCTION environments have different rate limits and feature availability
- **Token scopes**: PingOne API tokens need specific scopes per endpoint — 403 means missing scope assignment
- **HAL format**: PingOne uses HAL+JSON with `_embedded` and `_links` — data is nested inside `.embedded`
- **PingOne vs PingFederate**: PingOne is cloud-native; PingFederate is on-premise — API endpoints and auth are completely different
- **Region-specific URLs**: API base URL differs by region (`api.pingone.com`, `api.pingone.eu`, `api.pingone.ca`, `api.pingone.asia`)
- **Sign-on policy chaining**: Multiple sign-on policies can be assigned to an app with priority — evaluate in priority order
- **Gateway health**: Gateway instances can show as connected but unhealthy — check both `currentStatus` and `healthStatus`
- **MFA device pairing**: MFA device enrollment status is per-user per-device — aggregate counts require iterating users
