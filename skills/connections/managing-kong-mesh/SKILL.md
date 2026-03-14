---
name: managing-kong-mesh
description: |
  Kong Mesh service mesh management covering meshes, dataplanes, traffic policies, mesh gateways, mTLS configuration, and observability. Built on Kuma with enterprise features. Use when managing Kong Mesh instances, configuring service-to-service policies, debugging dataplane proxies, or setting up multi-zone mesh deployments.
connection_type: kong-mesh
preload: false
---

# Kong Mesh Skill

Manage Kong Mesh service mesh, dataplanes, traffic policies, gateways, and multi-zone configuration.

## Core Helper Functions

```bash
#!/bin/bash

KONG_MESH_API="${KONG_MESH_API_URL:-http://localhost:5681}"

km_api() {
    local endpoint="$1"
    shift
    curl -s "$KONG_MESH_API/$endpoint" "$@"
}
```

## MANDATORY: Discovery-First Pattern

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Kong Mesh Version ==="
km_api "" | jq '{version, hostname, tagline, environment}'

echo ""
echo "=== Meshes ==="
km_api "meshes" | jq -r '
    .items[] | "\(.name)\tmTLS: \(.mtls.enabledBackend // "disabled")\tLogging: \(.logging.backends | length // 0) backends"
' | column -t | head -10

echo ""
echo "=== Dataplanes Overview ==="
km_api "mesh-insights" | jq -r '
    .items[] | "\(.name)\tOnline: \(.dataplanesByType.standard.online // 0)\tGateway: \(.dataplanesByType.gateway.online // 0)\tTotal: \(.dataplanesByType.standard.total // 0)"
' | column -t | head -10

echo ""
echo "=== Zones ==="
km_api "zones" | jq -r '
    .items[]? | "\(.name)\tEnabled: \(.enabled)"
' | column -t | head -10

echo ""
echo "=== Global Policies ==="
for policy in trafficpermissions trafficlogs traffictraces trafficroutes timeouts circuitbreakers healthchecks faultinjections retries ratelimits meshgateways meshgatewayroutes; do
    COUNT=$(km_api "$policy" 2>/dev/null | jq '.total // 0')
    [ "$COUNT" -gt 0 ] && echo "$policy: $COUNT"
done

echo ""
echo "=== OPA Policies (Enterprise) ==="
km_api "opapolicies" | jq -r '
    .items[]? | "\(.name)\t\(.mesh)\tEnabled: \(.enabled // true)"
' | column -t 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash
MESH="${1:-default}"

echo "=== Mesh Configuration ==="
km_api "meshes/$MESH" | jq '{name, mtls, tracing, logging, metrics, routing}'

echo ""
echo "=== Dataplanes in Mesh ==="
km_api "meshes/$MESH/dataplanes" | jq -r '
    .items[] | "\(.name)\t\(.networking.address)\tService: \(.networking.inbound[0].tags["kuma.io/service"] // "n/a")"
' | column -t | head -15

echo ""
echo "=== Traffic Permissions ==="
km_api "meshes/$MESH/trafficpermissions" | jq -r '
    .items[] | "\(.name)\tSrc: \(.sources[0].match["kuma.io/service"] // "*")\tDst: \(.destinations[0].match["kuma.io/service"] // "*")"
' | column -t | head -15

echo ""
echo "=== Rate Limits ==="
km_api "meshes/$MESH/ratelimits" | jq '
    .items[]? | {name, sources: .sources[0].match, destinations: .destinations[0].match, conf: .conf}
' | head -15

echo ""
echo "=== Mesh Gateways ==="
km_api "meshes/$MESH/meshgateways" | jq '
    .items[]? | {name, selectors: .selectors, conf: .conf}
' | head -15
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use jq to parse Kong Mesh API responses
- Specify mesh context for all policy queries

## Safety Rules
- **Read-only by default**: Use GET endpoints for inspection
- **Traffic permission changes** affect authorization immediately
- **mTLS backend changes** can disrupt all mesh communication
- **Multi-zone policy propagation** affects all connected zones

## Common Pitfalls
- **Kong Mesh vs Kuma**: Kong Mesh is commercial Kuma; API is compatible but has extra enterprise resources
- **OPA policies**: Enterprise feature; requires OPA sidecar configuration
- **Default deny**: Without traffic permissions, mesh defaults to deny all
- **Zone CP vs Global CP**: Policies are managed at global CP and synced to zone CPs
- **Gateway vs Gateway builtin**: MeshGateway is built-in; differs from Kong Gateway integration
