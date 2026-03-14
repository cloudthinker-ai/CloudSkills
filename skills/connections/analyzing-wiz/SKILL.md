---
name: analyzing-wiz
description: |
  Wiz cloud security posture management. Covers cloud security posture analysis, vulnerability prioritization, attack path analysis, compliance assessment, container security, and resource inventory. Use when assessing cloud security posture, investigating attack paths, prioritizing vulnerabilities, or auditing cloud compliance.
connection_type: wiz
preload: false
---

# Wiz Cloud Security Analysis Skill

Analyze cloud security posture, vulnerabilities, and attack paths using Wiz.

## MANDATORY: Discovery-First Pattern

**Always check API connectivity and project scope before running queries.**

### Phase 1: Discovery

```bash
#!/bin/bash

wiz_api() {
    local query="$1"
    curl -s -X POST \
        -H "Authorization: Bearer $WIZ_API_TOKEN" \
        -H "Content-Type: application/json" \
        "${WIZ_API_URL}/graphql" \
        -d "{\"query\": \"$query\"}"
}

echo "=== Wiz Projects ==="
wiz_api '{ projects { nodes { id name businessUnit riskProfile { businessImpact } } } }' | jq '.data.projects.nodes[:10]'

echo ""
echo "=== Cloud Accounts ==="
wiz_api '{ cloudAccounts(first: 10) { nodes { id name cloudProvider status externalId } } }' | jq '.data.cloudAccounts.nodes'

echo ""
echo "=== Issue Summary ==="
wiz_api '{ issueAnalytics { summary { severity count } } }' | jq '.data.issueAnalytics.summary'
```

## Core Helper Functions

```bash
#!/bin/bash

# Wiz GraphQL API wrapper
wiz_api() {
    local query="$1"
    local variables="${2:-{}}"
    curl -s -X POST \
        -H "Authorization: Bearer $WIZ_API_TOKEN" \
        -H "Content-Type: application/json" \
        "${WIZ_API_URL}/graphql" \
        -d "{\"query\": $(echo "$query" | jq -Rs .), \"variables\": $variables}"
}

# Wiz CLI wrapper (if installed)
wiz_cmd() {
    wiz "$@" --output json 2>/dev/null
}

# Get auth token
wiz_auth() {
    curl -s -X POST "https://auth.app.wiz.io/oauth/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "grant_type=client_credentials&client_id=${WIZ_CLIENT_ID}&client_secret=${WIZ_CLIENT_SECRET}&audience=wiz-api" | jq -r '.access_token'
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use GraphQL queries with field selection for efficient data retrieval
- Summarize by severity and category
- Never dump full resource inventories -- use filters and pagination

## Common Operations

### Security Posture Dashboard

```bash
#!/bin/bash
echo "=== Security Posture Summary ==="
wiz_api '{
    issueAnalytics {
        summary { severity count }
        issuesByCategory { category count }
    }
}' | jq '.data.issueAnalytics | {
    by_severity: .summary,
    by_category: .issuesByCategory[:10]
}'

echo ""
echo "=== Critical Issues ==="
wiz_api '{
    issues(first: 10, filterBy: { severity: [CRITICAL], status: [OPEN] }) {
        nodes {
            id
            title: sourceRule { name }
            severity
            status
            createdAt
            entitySnapshot { type name cloudPlatform }
        }
    }
}' | jq '.data.issues.nodes[] | {
    id: .id,
    title: .title.name,
    severity: .severity,
    resource_type: .entitySnapshot.type,
    resource: .entitySnapshot.name,
    cloud: .entitySnapshot.cloudPlatform,
    created: .createdAt
}'
```

### Attack Path Analysis

```bash
#!/bin/bash
echo "=== Attack Paths ==="
wiz_api '{
    attackPaths(first: 10, filterBy: { severity: [CRITICAL, HIGH] }) {
        nodes {
            id
            name
            severity
            riskFactors
            sourceResource { type name }
            targetResource { type name }
            steps { description }
        }
    }
}' | jq '.data.attackPaths.nodes[:5][] | {
    name: .name,
    severity: .severity,
    risk_factors: .riskFactors,
    source: "\(.sourceResource.type)/\(.sourceResource.name)",
    target: "\(.targetResource.type)/\(.targetResource.name)",
    steps: [.steps[].description]
}'
```

### Vulnerability Prioritization

```bash
#!/bin/bash
echo "=== Prioritized Vulnerabilities ==="
wiz_api '{
    vulnerabilities(first: 15, filterBy: { exploitAvailable: true, hasFix: true }, orderBy: { field: SCORE, direction: DESC }) {
        nodes {
            name
            score
            severity
            exploitAvailable
            hasFix
            fixedVersion
            affectedResources { totalCount }
            detailedName
        }
    }
}' | jq '.data.vulnerabilities.nodes[] | {
    cve: .name,
    score: .score,
    severity: .severity,
    exploit_available: .exploitAvailable,
    has_fix: .hasFix,
    fixed_version: .fixedVersion,
    affected_resources: .affectedResources.totalCount
}'
```

### Compliance Assessment

```bash
#!/bin/bash
FRAMEWORK="${1:-CIS}"

echo "=== Compliance: $FRAMEWORK ==="
wiz_api '{
    complianceFrameworks {
        nodes {
            id
            name
            passedRulesCount
            failedRulesCount
            totalRulesCount
        }
    }
}' | jq --arg fw "$FRAMEWORK" '.data.complianceFrameworks.nodes[] |
    select(.name | test($fw; "i")) | {
        framework: .name,
        passed: .passedRulesCount,
        failed: .failedRulesCount,
        total: .totalRulesCount,
        compliance_pct: (.passedRulesCount / .totalRulesCount * 100 | floor)
    }
'

echo ""
echo "=== Failed Compliance Rules ==="
wiz_api '{
    complianceRules(first: 10, filterBy: { status: [FAIL] }) {
        nodes {
            name
            description
            severity
            framework { name }
            failedResourceCount
        }
    }
}' | jq '.data.complianceRules.nodes[:10][] | {
    rule: .name,
    severity: .severity,
    framework: .framework.name,
    failed_resources: .failedResourceCount
}'
```

### Resource Inventory and Risk

```bash
#!/bin/bash
echo "=== Resource Inventory ==="
wiz_api '{
    graphSearch(first: 10, query: { type: ["cloud_resource"], where: { riskLevel: { EQUALS: [CRITICAL] } } }) {
        nodes {
            entities {
                type
                name
                cloudPlatform
                tags
            }
        }
    }
}' | jq '.data.graphSearch.nodes[:10]' 2>/dev/null

echo ""
echo "=== Cloud Account Risk ==="
wiz_api '{
    cloudAccounts(first: 10) {
        nodes {
            name
            cloudProvider
            issueAnalytics {
                summary { severity count }
            }
        }
    }
}' | jq '.data.cloudAccounts.nodes[] | {
    account: .name,
    cloud: .cloudProvider,
    issues: .issueAnalytics.summary
}'
```

## Safety Rules

- **Wiz is read-only** -- it scans cloud resources but does not modify them
- **API tokens should have minimum required scopes** -- do not use admin tokens for queries
- **GraphQL queries** can be expensive -- use pagination and field selection
- **Sensitive data** may appear in resource metadata -- handle query results securely
- **Cross-project queries** may expose data across organizational boundaries -- scope appropriately

## Common Pitfalls

- **Token expiration**: Wiz API tokens are short-lived -- implement token refresh logic
- **GraphQL pagination**: Large result sets require cursor-based pagination -- always check `hasNextPage`
- **Scan lag**: Newly deployed resources may take time to appear in Wiz inventory
- **Risk score context**: High risk scores need context -- a critical CVE on an isolated resource may be lower priority
- **Attack path accuracy**: Attack paths are theoretical -- validate with actual network connectivity testing
- **Compliance framework mapping**: Not all rules map to all frameworks -- manual verification may be needed
- **Container image scanning**: Wiz scans running containers -- images not deployed are not scanned
- **Multi-cloud correlation**: Resources across clouds may be related but appear separate in Wiz inventory
