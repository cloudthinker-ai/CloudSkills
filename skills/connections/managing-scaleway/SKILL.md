---
name: managing-scaleway
description: |
  Scaleway cloud infrastructure management via the scw CLI. Covers instances, Kubernetes (Kapsule), managed databases, object storage, serverless containers, and billing. Use when managing Scaleway resources or checking infrastructure health.
connection_type: scaleway
preload: false
---

# Managing Scaleway

Manage Scaleway infrastructure using the `scw` CLI.

## MANDATORY: Discovery-First Pattern

**Always discover available resources before performing analysis.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Account Info ==="
scw account project list -o json 2>/dev/null | jq -r '.[] | "\(.id)\t\(.name)\t\(.created_at)"' | head -10

echo ""
echo "=== Instances ==="
scw instance server list -o json 2>/dev/null | jq -r '.[] | "\(.id)\t\(.name)\t\(.commercial_type)\t\(.state)\t\(.public_ips[0].address // "N/A")\t\(.zone)"' | head -30

echo ""
echo "=== Kubernetes Clusters (Kapsule) ==="
scw k8s cluster list -o json 2>/dev/null | jq -r '.[] | "\(.id)\t\(.name)\t\(.version)\t\(.status)\t\(.region)"' | head -10

echo ""
echo "=== Managed Databases ==="
scw rdb instance list -o json 2>/dev/null | jq -r '.[] | "\(.id)\t\(.name)\t\(.engine)\t\(.node_type)\t\(.status)\t\(.region)"' | head -10

echo ""
echo "=== Object Storage Buckets ==="
scw object bucket list -o json 2>/dev/null | jq -r '.[] | "\(.name)\t\(.region)\t\(.size)"' | head -10

echo ""
echo "=== Serverless Containers ==="
scw container container list -o json 2>/dev/null | jq -r '.[] | "\(.id)\t\(.name)\t\(.status)\t\(.region)"' | head -10

echo ""
echo "=== Load Balancers ==="
scw lb lb list -o json 2>/dev/null | jq -r '.[] | "\(.id)\t\(.name)\t\(.status)\t\(.ip[0].ip_address // "N/A")\t\(.zone)"' | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

SERVER_ID="${1:?Server ID required}"

echo "=== Instance Details ==="
scw instance server get "$SERVER_ID" -o json 2>/dev/null | jq '{
    id, name, state, commercial_type, arch,
    public_ip: .public_ips[0].address,
    private_ip: .private_ip,
    zone, creation_date,
    volumes: [.volumes | to_entries[] | {name: .value.name, size_gb: (.value.size / 1073741824)}]
}'

echo ""
echo "=== Security Groups ==="
scw instance security-group list -o json 2>/dev/null | jq -r '.[] | "\(.id)\t\(.name)\t\(.inbound_default_policy)\t\(.outbound_default_policy)\t\(.stateful)"' | head -10

echo ""
echo "=== Private Networks ==="
scw vpc private-network list -o json 2>/dev/null | jq -r '.[] | "\(.id)\t\(.name)\t\(.subnets[0] // "N/A")\t\(.zone)"' | head -10

echo ""
echo "=== Billing ==="
scw billing consumption list -o json 2>/dev/null | jq '{total_cost, currency, items: [.consumptions[:10][] | {category, description, value}]}' | head -20
```

## Output Format

```
ID                                    NAME     TYPE        STATE    IP          ZONE
abc123-def456                         web-01   DEV1-S      running  1.2.3.4     fr-par-1
abc123-ghi789                         db-01    GP1-S       running  5.6.7.8     fr-par-1
```

## Safety Rules
- Use read-only commands: `list`, `get`
- Never run `delete`, `stop`, `terminate` without explicit user confirmation
- Use `-o json` with jq for structured output parsing
- Limit output with `| head -N` to stay under 50 lines
