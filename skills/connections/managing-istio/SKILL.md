---
name: managing-istio
description: |
  Istio service mesh management for Kubernetes. Covers virtual services, destination rules, gateway configuration, traffic management, mTLS policies, sidecar injection, telemetry, and fault injection. Use when managing service mesh traffic routing, debugging connectivity issues, reviewing mTLS status, or configuring Istio policies.
connection_type: istio
preload: false
---

# Istio Service Mesh Skill

Manage Istio service mesh configuration, traffic routing, security policies, and observability.

## Core Helper Functions

```bash
#!/bin/bash

# Istioctl wrapper
istio_cmd() {
    istioctl "$@" 2>/dev/null
}

# Get Istio CRDs via kubectl
istio_get() {
    local resource="$1"
    local ns="${2:---all-namespaces}"
    if [ "$ns" = "--all-namespaces" ]; then
        kubectl get "$resource" -A -o json 2>/dev/null
    else
        kubectl get "$resource" -n "$ns" -o json 2>/dev/null
    fi
}

# Analyze mesh configuration
istio_analyze() {
    local ns="${1:---all-namespaces}"
    istioctl analyze "$ns" 2>/dev/null
}
```

## MANDATORY: Discovery-First Pattern

**Always discover mesh status and resources before modifying configurations.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Istio Version ==="
istioctl version --short 2>/dev/null

echo ""
echo "=== Istio Control Plane Status ==="
kubectl get pods -n istio-system -o json 2>/dev/null | jq -r '
    .items[] | "\(.metadata.name)\t\(.status.phase)\t\(.status.containerStatuses[0].restartCount // 0) restarts"
' | column -t

echo ""
echo "=== Mesh Overview ==="
istioctl proxy-status 2>/dev/null | head -30

echo ""
echo "=== Injected Namespaces ==="
kubectl get namespaces -l istio-injection=enabled -o json 2>/dev/null | jq -r '.items[].metadata.name'

echo ""
echo "=== Istio Resources Summary ==="
for res in virtualservices destinationrules gateways serviceentries sidecars peerauthentications; do
    COUNT=$(kubectl get "$res" -A --no-headers 2>/dev/null | wc -l | tr -d ' ')
    echo "$res: $COUNT"
done
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `-o json` with jq for kubectl and `--output json` for istioctl
- Never dump full Envoy configs -- extract relevant listeners/routes

## Common Operations

### Traffic Management Overview

```bash
#!/bin/bash
NS="${1:---all-namespaces}"

echo "=== Virtual Services ==="
istio_get virtualservices "$NS" | jq -r '
    .items[] | "\(.metadata.name)\t\(.metadata.namespace)\t\(.spec.hosts | join(","))\t\(.spec.http | length) routes"
' | column -t | head -20

echo ""
echo "=== Destination Rules ==="
istio_get destinationrules "$NS" | jq -r '
    .items[] | "\(.metadata.name)\t\(.metadata.namespace)\t\(.spec.host)\t\(.spec.trafficPolicy.connectionPool // "default")"
' | column -t | head -20

echo ""
echo "=== Gateways ==="
istio_get gateways "$NS" | jq -r '
    .items[] | "\(.metadata.name)\t\(.metadata.namespace)\t\(.spec.servers[] | "\(.port.number)/\(.port.protocol)\t\(.hosts | join(","))")"
' | column -t | head -15
```

### mTLS Status & Security

```bash
#!/bin/bash
echo "=== mTLS Mesh-Wide Policy ==="
kubectl get peerauthentication -A -o json 2>/dev/null | jq -r '
    .items[] | "\(.metadata.name)\t\(.metadata.namespace)\t\(.spec.mtls.mode // "UNSET")"
' | column -t

echo ""
echo "=== Authorization Policies ==="
kubectl get authorizationpolicies -A -o json 2>/dev/null | jq -r '
    .items[] | "\(.metadata.name)\t\(.metadata.namespace)\t\(.spec.action // "ALLOW")\t\(.spec.rules | length) rules"
' | column -t | head -15

echo ""
echo "=== TLS Status per Service ==="
istioctl proxy-config listeners -n istio-system deploy/istio-ingressgateway 2>/dev/null \
    | grep -E "ADDR|0.0.0.0" | head -15

echo ""
echo "=== Mesh Analysis Warnings ==="
istioctl analyze -A 2>/dev/null | head -20
```

### Proxy Debugging

```bash
#!/bin/bash
POD="${1:?Pod name required}"
NS="${2:-default}"

echo "=== Proxy Status: $POD ==="
istioctl proxy-status "$POD.$NS" 2>/dev/null

echo ""
echo "=== Proxy Config Summary ==="
istioctl proxy-config cluster "$POD" -n "$NS" 2>/dev/null | head -20

echo ""
echo "=== Active Routes ==="
istioctl proxy-config routes "$POD" -n "$NS" 2>/dev/null | head -20

echo ""
echo "=== Listeners ==="
istioctl proxy-config listeners "$POD" -n "$NS" 2>/dev/null | head -15

echo ""
echo "=== Config Sync Issues ==="
istioctl proxy-config bootstrap "$POD" -n "$NS" -o json 2>/dev/null | jq '.bootstrap.node.id'
```

### Traffic Shifting & Canary

```bash
#!/bin/bash
SERVICE="${1:?Service name required}"
NS="${2:-default}"

echo "=== Current Routing for $SERVICE ==="
kubectl get virtualservice -n "$NS" -o json 2>/dev/null | jq --arg svc "$SERVICE" '
    .items[] | select(.spec.hosts[] | contains($svc)) | {
        name: .metadata.name,
        hosts: .spec.hosts,
        routes: [.spec.http[]?.route[]? | {destination: .destination.host, subset: .destination.subset, weight: .weight}]
    }'

echo ""
echo "=== Destination Subsets ==="
kubectl get destinationrule -n "$NS" -o json 2>/dev/null | jq --arg svc "$SERVICE" '
    .items[] | select(.spec.host | contains($svc)) | {
        host: .spec.host,
        subsets: [.spec.subsets[]? | {name: .name, labels: .labels}],
        traffic_policy: .spec.trafficPolicy
    }'

echo ""
echo "=== Active Endpoints ==="
istioctl proxy-config endpoints deploy/"$SERVICE" -n "$NS" 2>/dev/null | grep HEALTHY | head -15
```

### Service Entry & External Traffic

```bash
#!/bin/bash
echo "=== Service Entries ==="
kubectl get serviceentries -A -o json 2>/dev/null | jq -r '
    .items[] | "\(.metadata.name)\t\(.metadata.namespace)\t\(.spec.hosts | join(","))\t\(.spec.location // "MESH_EXTERNAL")\t\(.spec.resolution)"
' | column -t | head -20

echo ""
echo "=== Egress Configuration ==="
kubectl get sidecar -A -o json 2>/dev/null | jq -r '
    .items[] | "\(.metadata.name)\t\(.metadata.namespace)\t\(.spec.egress[0].hosts | join(","))"
' | column -t | head -15
```

## Safety Rules
- **Read-only by default**: Use `istioctl analyze`, `proxy-config`, `proxy-status` for inspection
- **Never modify** VirtualServices or DestinationRules without explicit user request
- **Canary caution**: Weight-based routing changes affect live traffic immediately
- **mTLS changes**: Switching mTLS mode can break service communication -- always validate first

## Common Pitfalls
- **Sidecar not injected**: Check namespace label `istio-injection=enabled` and pod annotation
- **VirtualService host mismatch**: Host must match the Kubernetes service name exactly
- **Gateway selector**: Gateway must select the correct ingress gateway pod via label selectors
- **DestinationRule before VirtualService**: DR subsets must exist before VS references them
- **503 errors**: Often caused by missing DestinationRule or mTLS mismatch between services
