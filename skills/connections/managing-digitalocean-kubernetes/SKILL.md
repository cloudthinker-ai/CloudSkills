---
name: managing-digitalocean-kubernetes
description: |
  DigitalOcean Kubernetes (DOKS) management via the doctl CLI. Covers clusters, node pools, upgrades, kubeconfig, and cluster health. Use when managing DOKS clusters or checking Kubernetes infrastructure on DigitalOcean.
connection_type: digitalocean-kubernetes
preload: false
---

# Managing DigitalOcean Kubernetes (DOKS)

Manage DigitalOcean Kubernetes using the `doctl kubernetes` CLI.

## MANDATORY: Discovery-First Pattern

**Always discover available resources before performing analysis.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Kubernetes Clusters ==="
doctl kubernetes cluster list --format ID,Name,Region,VersionSlug,Status,NodePools.Count,Endpoint,CreatedAt --no-header 2>/dev/null | head -20

echo ""
echo "=== Available Versions ==="
doctl kubernetes options versions --format Slug,KubernetesVersion --no-header 2>/dev/null | head -10

echo ""
echo "=== Available Sizes ==="
doctl kubernetes options sizes --format Name,Slug --no-header 2>/dev/null | head -10

echo ""
echo "=== Available Regions ==="
doctl kubernetes options regions --format Name,Slug --no-header 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

CLUSTER_ID="${1:?Cluster ID required}"

echo "=== Cluster Details ==="
doctl kubernetes cluster get "$CLUSTER_ID" --format ID,Name,Region,VersionSlug,Status,Endpoint,AutoUpgrade,SurgeUpgrade,HA,CreatedAt --no-header 2>/dev/null

echo ""
echo "=== Node Pools ==="
doctl kubernetes cluster node-pool list "$CLUSTER_ID" --format ID,Name,Size,Count,AutoScale,MinNodes,MaxNodes --no-header 2>/dev/null | head -10

echo ""
echo "=== Nodes ==="
doctl kubernetes cluster node-pool list "$CLUSTER_ID" -o json 2>/dev/null | jq -r '.[].nodes[] | "\(.id)\t\(.name)\t\(.status.state)\t\(.droplet_id)\t\(.created_at)"' | head -20

echo ""
echo "=== Available Upgrades ==="
doctl kubernetes cluster get-upgrades "$CLUSTER_ID" --format Slug,KubernetesVersion --no-header 2>/dev/null | head -5

echo ""
echo "=== Cluster Kubeconfig Check ==="
doctl kubernetes cluster kubeconfig show "$CLUSTER_ID" 2>/dev/null | grep -c "clusters:" && echo "Kubeconfig: available" || echo "Kubeconfig: not accessible"

echo ""
echo "=== Associated LBs ==="
doctl compute load-balancer list --format ID,Name,Region,Status,IP --no-header 2>/dev/null | head -5

echo ""
echo "=== Associated Volumes ==="
doctl compute volume list --format ID,Name,Region,Size,DropletIDs --no-header 2>/dev/null | head -10

echo ""
echo "=== Container Registry ==="
doctl registry get --format Name,Endpoint,Region,StorageUsageBytes,CreatedAt --no-header 2>/dev/null | head -3
```

## Output Format

```
CLUSTER_ID                            NAME       REGION  VERSION  STATUS   NODES
abc123-def456-ghi789                  prod-k8s   nyc1    1.29.1   running  6
def456-ghi789-jkl012                  dev-k8s    sfo3    1.29.1   running  3
```

## Safety Rules
- Use read-only commands: `list`, `get`, `get-upgrades`, `show`
- Never run `delete`, `update`, `remove-node` without explicit user confirmation
- Use `--format` and `--no-header` for clean output
- Limit output with `| head -N` to stay under 50 lines
