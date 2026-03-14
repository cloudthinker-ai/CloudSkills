---
name: managing-linkerd-deep
description: |
  Advanced Linkerd service mesh management covering proxy diagnostics, multi-cluster linking, policy resources, HTTPRoute configuration, server authorization, retry budgets, and advanced observability. Use for deep Linkerd troubleshooting, multi-cluster traffic management, policy-based authorization, or advanced proxy debugging.
connection_type: linkerd
preload: false
---

# Linkerd Deep Skill

Advanced Linkerd management including proxy diagnostics, multi-cluster, policy resources, and HTTPRoute configuration.

## Core Helper Functions

```bash
#!/bin/bash

linkerd_cmd() {
    linkerd "$@" 2>/dev/null
}

linkerd_get() {
    local resource="$1" ns="${2:---all-namespaces}"
    if [ "$ns" = "--all-namespaces" ]; then
        kubectl get "$resource" -A -o json 2>/dev/null
    else
        kubectl get "$resource" -n "$ns" -o json 2>/dev/null
    fi
}
```

## MANDATORY: Discovery-First Pattern

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Linkerd Version & Channel ==="
linkerd version 2>/dev/null
linkerd check --pre 2>/dev/null | grep -E "linkerd-version" | head -3

echo ""
echo "=== Control Plane Components ==="
kubectl get pods -n linkerd -o json 2>/dev/null | jq -r '
    .items[] | "\(.metadata.name)\t\(.status.phase)\tRestarts: \(.status.containerStatuses[0].restartCount // 0)\tImage: \(.spec.containers[0].image | split(":") | last)"
' | column -t

echo ""
echo "=== Extensions Installed ==="
kubectl get namespaces -o json 2>/dev/null | jq -r '
    .items[] | select(.metadata.name | startswith("linkerd-")) | .metadata.name
'
kubectl get pods -n linkerd-viz -o json 2>/dev/null | jq -r '.items[].metadata.name' | head -5
kubectl get pods -n linkerd-multicluster -o json 2>/dev/null | jq -r '.items[].metadata.name' | head -5

echo ""
echo "=== Policy Resources ==="
for res in servers serverauthorizations httproutes authorizationpolicies meshtlsauthentications networkauthentications; do
    COUNT=$(kubectl get "$res" -A --no-headers 2>/dev/null | wc -l | tr -d ' ')
    [ "$COUNT" -gt 0 ] && echo "$res: $COUNT"
done

echo ""
echo "=== Multi-Cluster Links ==="
kubectl get links -A -o json 2>/dev/null | jq -r '
    .items[]? | "\(.metadata.name)\t\(.metadata.namespace)\t\(.spec.targetClusterName)\t\(.status.conditions[0].status // "unknown")"
' | column -t | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash
NS="${1:-default}"

echo "=== Proxy Diagnostics ==="
for pod in $(kubectl get pods -n "$NS" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | tr ' ' '\n' | head -5); do
    PROXY_VER=$(kubectl get pod "$pod" -n "$NS" -o json 2>/dev/null | jq -r '.spec.containers[] | select(.name == "linkerd-proxy") | .image | split(":") | last')
    if [ -n "$PROXY_VER" ] && [ "$PROXY_VER" != "null" ]; then
        echo "$pod: proxy=$PROXY_VER"
    fi
done

echo ""
echo "=== Server Resources ==="
linkerd_get servers "$NS" | jq '
    .items[]? | {
        name: .metadata.name, port: .spec.port,
        proxyProtocol: .spec.proxyProtocol,
        podSelector: .spec.podSelector
    }' | head -20

echo ""
echo "=== Authorization Policies ==="
linkerd_get authorizationpolicies "$NS" | jq '
    .items[]? | {
        name: .metadata.name,
        targetRef: .spec.targetRef,
        requiredAuthenticationRefs: .spec.requiredAuthenticationRefs
    }' | head -20

echo ""
echo "=== HTTPRoutes ==="
linkerd_get httproutes "$NS" | jq '
    .items[]? | {
        name: .metadata.name,
        hostnames: .spec.hostnames,
        rules: [.spec.rules[]? | {matches: .matches, filters: .filters}]
    }' | head -20

echo ""
echo "=== Per-Route Metrics ==="
linkerd routes deploy -n "$NS" 2>/dev/null | head -20
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `linkerd diagnostics` for advanced proxy inspection
- Show policy resource relationships clearly

## Safety Rules
- **Read-only by default**: Use check, stat, diagnostics for inspection
- **Policy changes** can break authorization immediately -- test in permissive mode first
- **Multi-cluster link changes** affect cross-cluster traffic routing
- **Never remove proxy injection** from production namespaces without confirmation

## Common Pitfalls
- **Policy vs default**: Without Server resources, traffic is allowed by default; adding a Server makes it deny-by-default
- **HTTPRoute vs ServiceProfile**: HTTPRoute is the newer API; ServiceProfile is legacy
- **Multi-cluster mirroring**: Mirrored services must have matching ports and protocols
- **Proxy version skew**: Control plane and proxy versions should match within one minor version
- **Opaque ports**: Protocols that can't be detected need explicit opaque port annotation
