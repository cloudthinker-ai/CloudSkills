---
name: managing-rancher
description: |
  Use when working with Rancher — rancher multi-cluster Kubernetes management.
  Covers cluster provisioning, project/namespace management, catalog apps,
  workload monitoring, RBAC, and fleet management. Use when managing Rancher
  clusters, deploying catalog applications, configuring projects, or monitoring
  multi-cluster workloads.
connection_type: rancher
preload: false
---

# Rancher Management Skill

Manage Rancher multi-cluster Kubernetes environments, projects, catalogs, and monitoring.

## Core Helper Functions

```bash
#!/bin/bash

# Rancher API helper
rancher_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"
    local url="${RANCHER_URL:?RANCHER_URL required}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $RANCHER_TOKEN" \
            -H "Content-Type: application/json" \
            "${url}/v3/${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $RANCHER_TOKEN" \
            "${url}/v3/${endpoint}"
    fi
}

# Rancher kubectl context helper
rancher_kubectl() {
    local cluster_id="$1"
    shift
    curl -s -H "Authorization: Bearer $RANCHER_TOKEN" \
        "${RANCHER_URL}/k8s/clusters/${cluster_id}/api/v1/$*"
}
```

## MANDATORY: Discovery-First Pattern

**Always list clusters and projects before operating on specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Rancher Server Info ==="
rancher_api GET "settings/server-version" | jq -r '.value'

echo ""
echo "=== Managed Clusters ==="
rancher_api GET "clusters" | jq -r '
    .data[] | "\(.id)\t\(.name)\t\(.state)\t\(.provider)\t\(.nodeCount // 0) nodes\t\(.version.gitVersion // "N/A")"
' | column -t | head -20

echo ""
echo "=== Cluster Health ==="
rancher_api GET "clusters" | jq -r '
    .data[] | "\(.name)\t\(.state)\t\(.componentStatuses // [] | map(.conditions[0].status) | join(","))"
' | column -t

echo ""
echo "=== Projects ==="
rancher_api GET "projects" | jq -r '
    .data[] | "\(.id)\t\(.name)\t\(.clusterId)\t\(.state)"
' | column -t | head -20
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use Rancher API v3 with jq filtering
- Never dump full cluster specs -- extract key fields

## Common Operations

### Cluster Health Dashboard

```bash
#!/bin/bash
echo "=== Cluster Resource Summary ==="
rancher_api GET "clusters" | jq '
    .data[] | {
        name: .name,
        state: .state,
        nodes: .nodeCount,
        cpu: .allocatable.cpu,
        memory: .allocatable.memory,
        pods: .allocatable.pods,
        k8s_version: .version.gitVersion
    }' | head -40

echo ""
echo "=== Node Status per Cluster ==="
for cluster_id in $(rancher_api GET "clusters" | jq -r '.data[].id' | head -5); do
    CNAME=$(rancher_api GET "clusters/$cluster_id" | jq -r '.name')
    echo "--- $CNAME ---"
    rancher_api GET "clusters/${cluster_id}/nodes" | jq -r '
        .data[] | "\(.hostname)\t\(.state)\t\(.info.os.operatingSystem // "N/A")\t\(.allocatable.cpu) cpu\t\(.allocatable.memory) mem"
    ' | column -t | head -10
done

echo ""
echo "=== Cluster Events (warnings) ==="
rancher_api GET "clusters" | jq -r '.data[] | select(.state != "active") | "\(.name)\t\(.state)\t\(.transitioningMessage[0:60])"' | column -t
```

### Project & Namespace Management

```bash
#!/bin/bash
CLUSTER_ID="${1:?Cluster ID required}"

echo "=== Projects in Cluster ==="
rancher_api GET "clusters/${CLUSTER_ID}/projects" | jq -r '
    .data[] | "\(.id)\t\(.name)\t\(.state)\t\(.description[0:40])"
' | column -t

echo ""
echo "=== Namespaces per Project ==="
for proj_id in $(rancher_api GET "clusters/${CLUSTER_ID}/projects" | jq -r '.data[].id' | head -10); do
    PNAME=$(rancher_api GET "projects/$proj_id" | jq -r '.name')
    echo "--- $PNAME ---"
    rancher_api GET "projects/${proj_id}/namespaces" | jq -r '
        .data[] | "\(.id)\t\(.name)\t\(.state)"
    ' | column -t | head -10
done

echo ""
echo "=== Resource Quotas ==="
rancher_api GET "clusters/${CLUSTER_ID}/projects" | jq '
    .data[] | select(.resourceQuota != null) | {
        project: .name,
        quota: .resourceQuota
    }' | head -20
```

### Workload Monitoring

```bash
#!/bin/bash
PROJECT_ID="${1:?Project ID required}"

echo "=== Workloads ==="
rancher_api GET "projects/${PROJECT_ID}/workloads" | jq -r '
    .data[] | "\(.name)\t\(.type)\t\(.state)\t\(.scale // 1) replicas\t\(.containers[0].image)"
' | column -t | head -20

echo ""
echo "=== Unhealthy Workloads ==="
rancher_api GET "projects/${PROJECT_ID}/workloads" | jq -r '
    .data[] | select(.state != "active") | "\(.name)\t\(.state)\t\(.transitioningMessage[0:60])"
' | column -t

echo ""
echo "=== Services ==="
rancher_api GET "projects/${PROJECT_ID}/services" | jq -r '
    .data[] | "\(.name)\t\(.kind)\t\(.state)\t\(.clusterIp // "N/A")"
' | column -t | head -15

echo ""
echo "=== Ingresses ==="
rancher_api GET "projects/${PROJECT_ID}/ingresses" | jq -r '
    .data[] | "\(.name)\t\(.state)\t\(.rules[0].host // "N/A")"
' | column -t | head -10
```

### Catalog & App Management

```bash
#!/bin/bash
echo "=== Global Catalogs ==="
rancher_api GET "catalogs" | jq -r '
    .data[] | "\(.name)\t\(.url)\t\(.state)\t\(.branch // "main")"
' | column -t

echo ""
echo "=== Installed Apps ==="
PROJECT_ID="${1:-}"
if [ -n "$PROJECT_ID" ]; then
    rancher_api GET "projects/${PROJECT_ID}/apps" | jq -r '
        .data[] | "\(.name)\t\(.state)\t\(.externalId)\t\(.version)"
    ' | column -t | head -15
fi

echo ""
echo "=== Available Charts ==="
rancher_api GET "templateVersions" | jq -r '
    .data[:20][] | "\(.externalId)\t\(.version)"
' | column -t | head -15
```

### RBAC & User Management

```bash
#!/bin/bash
echo "=== Global Role Bindings ==="
rancher_api GET "globalRoleBindings" | jq -r '
    .data[] | "\(.userId // .groupPrincipalId)\t\(.globalRoleName)\t\(.name)"
' | column -t | head -20

echo ""
echo "=== Cluster Role Bindings ==="
CLUSTER_ID="${1:-}"
if [ -n "$CLUSTER_ID" ]; then
    rancher_api GET "clusterRoleTemplateBindings?clusterId=$CLUSTER_ID" | jq -r '
        .data[] | "\(.userId // .groupPrincipalId)\t\(.roleTemplateId)\t\(.clusterName)"
    ' | column -t | head -15
fi

echo ""
echo "=== Users ==="
rancher_api GET "users" | jq -r '
    .data[] | "\(.username)\t\(.name)\t\(.state)\t\(.enabled)"
' | column -t | head -15
```

## Safety Rules
- **Read-only by default**: Use GET requests for cluster, project, workload inspection
- **Never delete** clusters or projects without explicit user confirmation
- **Credential safety**: Never expose Rancher API tokens or kubeconfig data
- **Cluster operations**: Scaling or upgrading clusters affects all workloads

## Output Format

Present results as a structured report:
```
Managing Rancher Report
═══════════════════════
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
- **API version**: Rancher v3 API differs significantly from v1 -- check the URL prefix
- **Cluster ID format**: Format is `c-xxxxx` -- use discovery to get correct IDs
- **Project vs namespace**: Projects are Rancher-specific groupings of namespaces -- not native K8s
- **Catalog refresh**: Catalogs can become stale -- refresh before checking available charts
- **Fleet vs legacy**: Rancher 2.6+ uses Fleet for GitOps -- check which deployment method is in use
