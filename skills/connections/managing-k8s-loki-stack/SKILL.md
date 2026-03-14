---
name: managing-k8s-loki-stack
description: |
  Loki stack management for Kubernetes log aggregation. Covers Loki deployment health, Promtail/log agent status, log stream ingestion, storage backend configuration, retention policies, and query performance. Use when debugging log ingestion issues, auditing logging coverage, reviewing Loki storage, or troubleshooting Promtail scrape configs.
connection_type: k8s
preload: false
---

# Loki Stack Management Skill

Manage and analyze Loki log aggregation stack including Loki, Promtail, and related components.

## MANDATORY: Discovery-First Pattern

**Always check Loki and log agent health before querying log streams.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Loki Deployment ==="
kubectl get statefulset,deployment -l app.kubernetes.io/name=loki --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,KIND:.kind,NAME:.metadata.name,READY:.status.readyReplicas,REPLICAS:.spec.replicas' 2>/dev/null

echo ""
echo "=== Loki Pods ==="
kubectl get pods -l app.kubernetes.io/name=loki --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,RESTARTS:.status.containerStatuses[0].restartCount,NODE:.spec.nodeName' 2>/dev/null

echo ""
echo "=== Promtail DaemonSet ==="
kubectl get daemonset -l app.kubernetes.io/name=promtail --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,DESIRED:.status.desiredNumberScheduled,CURRENT:.status.currentNumberScheduled,READY:.status.numberReady' 2>/dev/null

echo ""
echo "=== Log Agents (Promtail/Alloy/FluentBit) ==="
kubectl get pods -l app.kubernetes.io/name=promtail --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,NODE:.spec.nodeName' 2>/dev/null | head -15
kubectl get pods -l app.kubernetes.io/name=alloy --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase' 2>/dev/null | head -10

echo ""
echo "=== Loki Services ==="
kubectl get svc -l app.kubernetes.io/name=loki --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,TYPE:.spec.type,PORTS:.spec.ports[*].port' 2>/dev/null
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Loki Ring Health ==="
LOKI_NS=$(kubectl get pods -l app.kubernetes.io/name=loki --all-namespaces -o jsonpath='{.items[0].metadata.namespace}' 2>/dev/null)
LOKI_POD=$(kubectl get pods -l app.kubernetes.io/name=loki -n "$LOKI_NS" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
kubectl exec -n "$LOKI_NS" "$LOKI_POD" -- wget -qO- http://localhost:3100/ready 2>/dev/null
echo ""

echo ""
echo "=== Loki Ingester Status ==="
kubectl exec -n "$LOKI_NS" "$LOKI_POD" -- wget -qO- http://localhost:3100/metrics 2>/dev/null | grep -E "loki_ingester_streams_created_total|loki_distributor_lines_received_total" | head -5

echo ""
echo "=== Promtail Logs (errors) ==="
PROMTAIL_NS=$(kubectl get daemonset -l app.kubernetes.io/name=promtail --all-namespaces -o jsonpath='{.items[0].metadata.namespace}' 2>/dev/null)
kubectl logs daemonset/promtail -n "$PROMTAIL_NS" --tail=20 2>/dev/null | grep -i "error\|fail\|drop" | head -10

echo ""
echo "=== Loki Logs (errors) ==="
kubectl logs -l app.kubernetes.io/name=loki -n "$LOKI_NS" --tail=20 2>/dev/null | grep -i "error\|fail\|warn" | head -10

echo ""
echo "=== Storage Configuration ==="
kubectl get pvc -l app.kubernetes.io/name=loki --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,CAPACITY:.status.capacity.storage,STORAGECLASS:.spec.storageClassName' 2>/dev/null

echo ""
echo "=== Promtail Nodes Not Running ==="
PROMTAIL_DESIRED=$(kubectl get daemonset -l app.kubernetes.io/name=promtail --all-namespaces -o jsonpath='{.items[0].status.desiredNumberScheduled}' 2>/dev/null)
PROMTAIL_READY=$(kubectl get daemonset -l app.kubernetes.io/name=promtail --all-namespaces -o jsonpath='{.items[0].status.numberReady}' 2>/dev/null)
echo "Desired: $PROMTAIL_DESIRED Ready: $PROMTAIL_READY Missing: $((${PROMTAIL_DESIRED:-0} - ${PROMTAIL_READY:-0}))"
```

## Output Format

- Target ≤50 lines per output
- Use `-o custom-columns` for resource listings
- Show DaemonSet coverage (desired vs ready) for log agents
- Aggregate log volume metrics when available
- Never dump full Loki configs -- show storage backend and retention only

## Common Pitfalls

- **Deployment modes**: Loki runs as monolithic, simple-scalable, or microservices -- check architecture before debugging
- **Promtail coverage**: DaemonSet must run on all nodes -- check tolerations for control-plane nodes
- **Storage backend**: filesystem (single instance), S3/GCS/Azure (scalable) -- check `storage_config` in ConfigMap
- **Retention**: Set via `compactor.retention_enabled` and `limits_config.retention_period` -- not enabled by default
- **Rate limiting**: Loki enforces per-tenant rate limits -- check for `rate limit` errors in distributor logs
- **Chunk encoding**: snappy is default -- gzip saves space but uses more CPU
- **Label cardinality**: High-cardinality labels cause performance issues -- avoid dynamic labels like pod names
- **Log level**: Promtail pipeline stages can filter/transform logs -- check `pipelineStages` in config
