---
name: managing-google-workspace
description: |
  Use when working with Google Workspace — google Workspace administration for
  user provisioning, group management, organizational unit structure, security
  settings review, and audit log analysis. Covers Google Admin SDK Directory
  API, Reports API, and security investigation. Read this skill before any
  Google Workspace operations — it enforces discovery-first patterns and strict
  read-only safety rules.
connection_type: google-workspace
preload: false
---

# Google Workspace Management Skill

Safely read and audit Google Workspace — Google's cloud-based productivity and collaboration platform.

## MANDATORY: Discovery-First Pattern

**Always discover the domain, organizational units, and available services before performing targeted queries. Never guess user emails or group addresses.**

### Phase 1: Discovery

```bash
#!/bin/bash

gw_api() {
    local endpoint="$1"
    curl -s -H "Authorization: Bearer $GWORKSPACE_ACCESS_TOKEN" \
         -H "Content-Type: application/json" \
         "https://admin.googleapis.com/admin/directory/v1/${endpoint}"
}

gw_reports() {
    local endpoint="$1"
    curl -s -H "Authorization: Bearer $GWORKSPACE_ACCESS_TOKEN" \
         "https://admin.googleapis.com/admin/reports/v1/${endpoint}"
}

echo "=== Customer Info ==="
gw_api "customers/my_customer" | jq '{
    id: .id,
    domain: .customerDomain,
    creation_time: .customerCreationTime,
    language: .language,
    postal_address: .postalAddress
}'

echo ""
echo "=== Organizational Units ==="
gw_api "customer/my_customer/orgunits?type=all" | jq -r '.organizationUnits[]? | "\(.orgUnitPath)\t\(.name)\t\(.description // "N/A")"' | column -t

echo ""
echo "=== Domains ==="
gw_api "customer/my_customer/domains" | jq -r '.domains[] | "\(.domainName)\t\(.isPrimary)\t\(.verified)\t\(.status)"' | column -t

echo ""
echo "=== User Count by OU ==="
gw_api "users?customer=my_customer&maxResults=1&projection=basic" | jq '.totalResults'
```

**Phase 1 outputs:** Domain info, OU structure, domain list — only reference these in subsequent operations.

## Anti-Hallucination Rules

- **NEVER guess user email addresses** — always search via `users?query=`
- **NEVER assume group addresses** — always list groups first
- **NEVER fabricate OU paths** — always list OUs in Phase 1
- **ONLY read and list** — never create, update, or delete without explicit request

## Safety Rules

- **READ-ONLY by default**: GET requests only — `users`, `groups`, `orgunits`, `tokens`, `activities`
- **MASK sensitive data**: Redact recovery emails, phone numbers, and customer-specific identifiers
- **FORBIDDEN without explicit request**: POST/PUT/PATCH/DELETE to users, groups, OUs; password resets; suspension
- **NEVER display recovery info**: Redact recovery email and phone in user details

## Core Helper Functions

```bash
#!/bin/bash

gw_api() {
    local endpoint="$1"
    curl -s -H "Authorization: Bearer $GWORKSPACE_ACCESS_TOKEN" \
         -H "Content-Type: application/json" \
         "https://admin.googleapis.com/admin/directory/v1/${endpoint}"
}

gw_reports() {
    local endpoint="$1"
    curl -s -H "Authorization: Bearer $GWORKSPACE_ACCESS_TOKEN" \
         "https://admin.googleapis.com/admin/reports/v1/${endpoint}"
}

# Paginated fetch following nextPageToken
gw_paginated() {
    local endpoint="$1"
    local max_pages="${2:-5}"
    local page=0
    local token=""

    while [ $page -lt $max_pages ]; do
        local sep="?"
        [[ "$endpoint" == *"?"* ]] && sep="&"
        local url="${endpoint}"
        [ -n "$token" ] && url="${endpoint}${sep}pageToken=${token}"
        result=$(gw_api "$url")
        echo "$result" | jq '.users // .groups // .members // []' 2>/dev/null
        token=$(echo "$result" | jq -r '.nextPageToken // empty')
        [ -z "$token" ] && break
        page=$((page + 1))
    done
}
```

## Common Operations

### User Provisioning & Status

```bash
#!/bin/bash
SEARCH="${1:?Search term required (email or name)}"

echo "=== User Search: $SEARCH ==="
gw_api "users?customer=my_customer&query=email:${SEARCH}*&maxResults=20&projection=full" | jq -r '.users[]? | {
    id: .id,
    email: .primaryEmail,
    name: "\(.name.givenName) \(.name.familyName)",
    suspended: .suspended,
    archived: .isArchived,
    admin: .isAdmin,
    delegated_admin: .isDelegatedAdmin,
    two_factor: .isEnrolledIn2Sv,
    two_factor_enforced: .isEnforcedIn2Sv,
    last_login: .lastLoginTime,
    creation_time: .creationTime,
    org_unit: .orgUnitPath,
    recovery_email: "*** REDACTED ***",
    recovery_phone: "*** REDACTED ***"
}'

echo ""
echo "=== Recently Created Users (last 30 days) ==="
SINCE=$(date -u -v-30d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '30 days ago' +%Y-%m-%dT%H:%M:%SZ)
gw_api "users?customer=my_customer&orderBy=email&sortOrder=DESCENDING&maxResults=20&projection=basic" | jq -r '.users[]? | select(.creationTime > "'"$SINCE"'") | "\(.primaryEmail)\t\(.creationTime)\t\(.orgUnitPath)"' | column -t
```

### Group Management

```bash
#!/bin/bash
echo "=== Groups (first 30) ==="
gw_api "groups?customer=my_customer&maxResults=30" | jq -r '.groups[]? | "\(.email)\t\(.name)\t\(.directMembersCount) members"' | column -t

echo ""
GROUP_EMAIL="${1:-}"
if [ -n "$GROUP_EMAIL" ]; then
    echo "=== Group Details: $GROUP_EMAIL ==="
    gw_api "groups/${GROUP_EMAIL}" | jq '{
        email: .email,
        name: .name,
        description: .description,
        direct_members: .directMembersCount,
        admin_created: .adminCreated
    }'

    echo ""
    echo "=== Group Members ==="
    gw_api "groups/${GROUP_EMAIL}/members?maxResults=50" | jq -r '.members[]? | "\(.email)\t\(.role)\t\(.type)\t\(.status)"' | column -t
fi
```

### Security Settings Review

```bash
#!/bin/bash
echo "=== 2-Step Verification Status ==="
gw_api "users?customer=my_customer&maxResults=100&projection=basic" | jq -r '.users[]? | "\(.primaryEmail)\t2SV_enrolled:\(.isEnrolledIn2Sv)\t2SV_enforced:\(.isEnforcedIn2Sv)"' | column -t | head -30

echo ""
echo "=== Admin Users ==="
gw_api "users?customer=my_customer&query=isAdmin=true&maxResults=50&projection=basic" | jq -r '.users[]? | "\(.primaryEmail)\t\(.isAdmin)\tDelegated:\(.isDelegatedAdmin)\t2SV:\(.isEnrolledIn2Sv)"' | column -t

echo ""
echo "=== OAuth Tokens Issued (sample user) ==="
USER_EMAIL="${1:-}"
if [ -n "$USER_EMAIL" ]; then
    gw_api "users/${USER_EMAIL}/tokens" | jq -r '.items[]? | "\(.clientId)\t\(.displayText)\tScopes:\(.scopes | length)"' | column -t
fi
```

### Audit Log Analysis

```bash
#!/bin/bash
SINCE="${1:-$(date -u -v-7d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)}"

echo "=== Admin Activity (since $SINCE) ==="
gw_reports "activity/users/all/applications/admin?startTime=${SINCE}&maxResults=25" | jq -r '.items[]? | {
    time: .id.time,
    actor: .actor.email,
    event: .events[0].name,
    type: .events[0].type,
    parameters: [.events[0].parameters[]? | "\(.name)=\(.value // .multiValue // "N/A")"] | join("; ")
}'

echo ""
echo "=== Login Activity ==="
gw_reports "activity/users/all/applications/login?startTime=${SINCE}&maxResults=25" | jq -r '.items[]? | "\(.id.time)\t\(.actor.email)\t\(.events[0].name)\t\(.ipAddress // "N/A")"' | column -t

echo ""
echo "=== Suspicious Login Events ==="
gw_reports "activity/users/all/applications/login?startTime=${SINCE}&eventName=login_failure&maxResults=25" | jq -r '.items[]? | "\(.id.time)\t\(.actor.email)\t\(.ipAddress // "N/A")\t\(.events[0].parameters[]? | select(.name=="login_type") | .value)"' | column -t
```

### Mobile Device & App Management

```bash
#!/bin/bash
echo "=== Mobile Devices ==="
gw_api "customer/my_customer/devices/mobile?maxResults=20" | jq -r '.mobiledevices[]? | "\(.email[]?)\t\(.model)\t\(.os)\t\(.status)\t\(.lastSync)"' | column -t

echo ""
echo "=== Chrome Devices ==="
gw_api "customer/my_customer/devices/chromeos?maxResults=20&projection=BASIC" | jq -r '.chromeosdevices[]? | "\(.serialNumber)\t\(.model)\t\(.status)\t\(.lastSync)\t\(.orgUnitPath)"' | column -t | head -20
```

## Output Format

Present results as a structured report:
```
Managing Google Workspace Report
════════════════════════════════
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

- **API scopes**: Different Admin SDK endpoints need different OAuth scopes — 403 errors typically mean missing scope, not wrong credentials
- **Customer vs domain**: Use `my_customer` for customer-level queries; domain-level queries are deprecated
- **Pagination**: Most endpoints return max 200 results — always follow `nextPageToken`
- **Projection levels**: `basic` returns fewer fields and is faster; `full` includes all user fields — use basic for listings
- **Deleted users**: Deleted users go to a trash and are recoverable for 20 days — use `users?showDeleted=true` to find them
- **OU path format**: Always starts with `/` — root is `/`; sub-OUs use `/Parent/Child` format
- **Reports API lag**: Activity reports can be delayed 1-3 hours — do not use for real-time monitoring
- **Super admin protection**: Some operations on super admin accounts require super admin credentials — delegated admin tokens may get 403
