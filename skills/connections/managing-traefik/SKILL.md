---
name: managing-traefik
description: |
  Use when working with Traefik — traefik reverse proxy and load balancer
  management. Covers entrypoint configuration, router rules, middleware chains,
  provider discovery, TLS management, dashboard access, and metrics monitoring.
  Use when managing Traefik routing, debugging middleware chains, configuring
  TLS, or monitoring proxy health via the dashboard API.
connection_type: traefik
preload: false
---

# Traefik Management Skill

Manage Traefik entrypoints, routers, middlewares, providers, TLS, and dashboard.

## Core Helper Functions

```bash
#!/bin/bash

# Traefik API helper
traefik_api() {
    local endpoint="$1"
    local api_url="${TRAEFIK_API_URL:-http://localhost:8080}"
    curl -s "${api_url}/api${endpoint}"
}

# Traefik Kubernetes CRDs
traefik_k8s() {
    local resource="$1"
    local ns="${2:---all-namespaces}"
    if [ "$ns" = "--all-namespaces" ]; then
        kubectl get "$resource" -A -o json 2>/dev/null
    else
        kubectl get "$resource" -n "$ns" -o json 2>/dev/null
    fi
}
```

## MANDATORY: Discovery-First Pattern

**Always check Traefik version, entrypoints, and providers before inspecting specific routes.**

### Phase 1: Discovery

```bash
#!/bin/bash
API_URL="${TRAEFIK_API_URL:-http://localhost:8080}"

echo "=== Traefik Version ==="
traefik_api "/version" | jq '.' 2>/dev/null

echo ""
echo "=== Entrypoints ==="
traefik_api "/entrypoints" | jq -r '
    .[] | "\(.name)\t\(.address)\t\(.transport.respondingTimeouts // "default")"
' 2>/dev/null | column -t

echo ""
echo "=== Overview ==="
traefik_api "/overview" | jq '{
    http: .http,
    tcp: .tcp,
    udp: .udp,
    features: .features,
    providers: .providers
}' 2>/dev/null

echo ""
echo "=== Kubernetes CRDs (if on K8s) ==="
echo "IngressRoutes:"
kubectl get ingressroutes -A --no-headers 2>/dev/null | wc -l | tr -d ' '
echo "Middlewares:"
kubectl get middlewares.traefik.io -A --no-headers 2>/dev/null | wc -l | tr -d ' '
echo "TLSOptions:"
kubectl get tlsoptions.traefik.io -A --no-headers 2>/dev/null | wc -l | tr -d ' '
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use Traefik API with jq for structured output
- Use kubectl for Kubernetes CRD-based Traefik configs

## Common Operations

### Router Configuration Dashboard

```bash
#!/bin/bash
echo "=== HTTP Routers ==="
traefik_api "/http/routers" | jq -r '
    .[] | "\(.name)\t\(.status)\t\(.entryPoints | join(","))\t\(.rule | .[0:60])\t\(.service)"
' 2>/dev/null | column -t | head -20

echo ""
echo "=== TCP Routers ==="
traefik_api "/tcp/routers" | jq -r '
    .[]? | "\(.name)\t\(.status)\t\(.entryPoints | join(","))\t\(.rule | .[0:40])"
' 2>/dev/null | column -t | head -10

echo ""
echo "=== Router Errors ==="
traefik_api "/http/routers" | jq -r '
    .[] | select(.status != "enabled") | "\(.name)\t\(.status)\t\(.rule | .[0:50])"
' 2>/dev/null | column -t | head -10

echo ""
echo "=== Kubernetes IngressRoutes ==="
kubectl get ingressroutes -A -o json 2>/dev/null | jq -r '
    .items[] | "\(.metadata.name)\t\(.metadata.namespace)\t\(.spec.entryPoints | join(","))\t\(.spec.routes | length) routes"
' | column -t | head -15
```

### Middleware Analysis

```bash
#!/bin/bash
echo "=== HTTP Middlewares ==="
traefik_api "/http/middlewares" | jq -r '
    .[] | "\(.name)\t\(.status)\t\(.type)\t\(.provider)"
' 2>/dev/null | column -t | head -20

echo ""
echo "=== Middleware Details ==="
traefik_api "/http/middlewares" | jq '
    .[] | {
        name: .name,
        type: .type,
        config: (
            if .stripPrefix != null then .stripPrefix
            elif .headers != null then {custom_headers: (.headers.customRequestHeaders // {} | keys)}
            elif .rateLimit != null then .rateLimit
            elif .basicAuth != null then "configured"
            elif .chain != null then .chain
            elif .redirectScheme != null then .redirectScheme
            else "see full config"
            end
        )
    }' 2>/dev/null | head -30

echo ""
echo "=== Kubernetes Middlewares ==="
kubectl get middlewares.traefik.io -A -o json 2>/dev/null | jq -r '
    .items[] | "\(.metadata.name)\t\(.metadata.namespace)\t\(.spec | keys | join(","))"
' | column -t | head -15
```

### Service & Load Balancer Status

```bash
#!/bin/bash
echo "=== HTTP Services ==="
traefik_api "/http/services" | jq -r '
    .[] | "\(.name)\t\(.status)\t\(.type)\t\(.provider)"
' 2>/dev/null | column -t | head -20

echo ""
echo "=== Service Health ==="
traefik_api "/http/services" | jq '
    .[] | select(.loadBalancer != null) | {
        name: .name,
        status: .status,
        servers: [.loadBalancer.servers[]? | {url: .url, status: "active"}],
        health_check: .loadBalancer.healthCheck
    }' 2>/dev/null | head -30

echo ""
echo "=== Weighted Services ==="
traefik_api "/http/services" | jq '
    .[] | select(.weighted != null) | {
        name: .name,
        services: [.weighted.services[]? | {name: .name, weight: .weight}]
    }' 2>/dev/null | head -15

echo ""
echo "=== Mirroring Services ==="
traefik_api "/http/services" | jq '
    .[] | select(.mirroring != null) | {
        name: .name,
        main: .mirroring.service,
        mirrors: .mirroring.mirrors
    }' 2>/dev/null | head -10
```

### TLS Configuration

```bash
#!/bin/bash
echo "=== TLS Overview ==="
traefik_api "/tls/certificates" 2>/dev/null | jq -r '
    .[]? | "\(.certificate.sans // .certificate.commonName | join(","))\t\(.certificate.notAfter)"
' | column -t | head -15

echo ""
echo "=== TLS Options ==="
kubectl get tlsoptions.traefik.io -A -o json 2>/dev/null | jq -r '
    .items[] | "\(.metadata.name)\t\(.metadata.namespace)\t\(.spec.minVersion // "default")\t\(.spec.cipherSuites // [] | length) ciphers"
' | column -t | head -10

echo ""
echo "=== TLS Stores ==="
kubectl get tlsstores.traefik.io -A -o json 2>/dev/null | jq -r '
    .items[] | "\(.metadata.name)\t\(.metadata.namespace)\t\(.spec.defaultCertificate.secretName // "none")"
' | column -t

echo ""
echo "=== Certificate Resolvers (ACME) ==="
traefik_api "/overview" | jq '.features.traefikCertificates // "not configured"' 2>/dev/null
```

### Provider Discovery & Health

```bash
#!/bin/bash
echo "=== Active Providers ==="
traefik_api "/overview" | jq '.providers' 2>/dev/null

echo ""
echo "=== Provider Raw Config ==="
traefik_api "/rawdata" | jq '{
    http_routers: (.routers | length),
    http_services: (.services | length),
    http_middlewares: (.middlewares | length),
    tcp_routers: (.tcpRouters | length),
    tcp_services: (.tcpServices | length)
}' 2>/dev/null

echo ""
echo "=== Dashboard Status ==="
traefik_api "/overview" | jq '{
    http: {routers: .http.routers, services: .http.services, middlewares: .http.middlewares},
    tcp: {routers: .tcp.routers, services: .tcp.services},
    features: .features
}' 2>/dev/null

echo ""
echo "=== Health Check ==="
curl -s "${TRAEFIK_API_URL:-http://localhost:8080}/ping" 2>/dev/null && echo " OK" || echo " FAILED"

echo ""
echo "=== Traefik Pod Status (K8s) ==="
kubectl get pods -A -l app.kubernetes.io/name=traefik -o json 2>/dev/null | jq -r '
    .items[] | "\(.metadata.name)\t\(.metadata.namespace)\t\(.status.phase)\t\(.status.containerStatuses[0].restartCount) restarts"
' | column -t | head -10
```

## Safety Rules
- **Read-only by default**: Use API GET endpoints and kubectl get for inspection
- **Never modify** routers or middlewares without explicit confirmation -- affects live traffic
- **Dashboard security**: Dashboard/API should not be exposed without authentication
- **TLS changes**: Certificate or TLS option changes can break HTTPS connections

## Output Format

Present results as a structured report:
```
Managing Traefik Report
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
- **Router priority**: When multiple routers match, priority determines which wins -- longer rules get higher default priority
- **Middleware ordering**: Middlewares in a chain execute in order -- authentication should come before rate limiting
- **Provider conflicts**: Multiple providers can define conflicting routers -- use provider prefixes to disambiguate
- **Entrypoint binding**: Routers without explicit entrypoints bind to all entrypoints -- may expose internal routes
- **Certificate renewal**: ACME certificate renewal requires port 80 or DNS challenge access -- check resolver configuration
