---
name: managing-k8s-external-dns
description: |
  ExternalDNS management for Kubernetes DNS record automation. Covers ExternalDNS deployment health, DNS record synchronization status, source and provider configurations, domain filters, ownership tracking, and log analysis. Use when debugging DNS record creation failures, auditing DNS configurations, or reviewing ExternalDNS provider setups.
connection_type: k8s
preload: false
---

# ExternalDNS Management Skill

Manage and monitor ExternalDNS for automatic DNS record synchronization from Kubernetes resources.

## MANDATORY: Discovery-First Pattern

**Always check ExternalDNS deployment health and configuration before investigating records.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== ExternalDNS Deployment ==="
kubectl get deployment -l app.kubernetes.io/name=external-dns --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,READY:.status.readyReplicas,IMAGE:.spec.template.spec.containers[0].image' 2>/dev/null
# Fallback: try common label patterns
kubectl get deployment external-dns --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,READY:.status.readyReplicas' 2>/dev/null

echo ""
echo "=== ExternalDNS Pod Status ==="
kubectl get pods -l app.kubernetes.io/name=external-dns --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,RESTARTS:.status.containerStatuses[0].restartCount' 2>/dev/null

echo ""
echo "=== ExternalDNS Configuration ==="
kubectl get deployment -l app.kubernetes.io/name=external-dns --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}: {.spec.template.spec.containers[0].args}{"\n"}{end}' 2>/dev/null

echo ""
echo "=== DNSEndpoint CRDs ==="
kubectl get dnsendpoints --all-namespaces 2>/dev/null | head -15

echo ""
echo "=== Services with External DNS Annotations ==="
kubectl get services --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  select(.metadata.annotations["external-dns.alpha.kubernetes.io/hostname"] // "" != "") |
  "\(.metadata.namespace)/\(.metadata.name)\t\(.metadata.annotations["external-dns.alpha.kubernetes.io/hostname"])\t\(.spec.type)"
' | column -t | head -15

echo ""
echo "=== Ingresses with External DNS Annotations ==="
kubectl get ingress --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  select(.metadata.annotations["external-dns.alpha.kubernetes.io/hostname"] // "" != "" or (.spec.rules // [] | length > 0)) |
  "\(.metadata.namespace)/\(.metadata.name)\t\(.metadata.annotations["external-dns.alpha.kubernetes.io/hostname"] // .spec.rules[0].host)"
' | column -t | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== ExternalDNS Logs (recent activity) ==="
NS=$(kubectl get deployment -l app.kubernetes.io/name=external-dns --all-namespaces -o jsonpath='{.items[0].metadata.namespace}' 2>/dev/null)
NAME=$(kubectl get deployment -l app.kubernetes.io/name=external-dns -n "$NS" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
kubectl logs deployment/"$NAME" -n "$NS" --tail=30 2>/dev/null | grep -E "level=(info|error|warning)" | head -15

echo ""
echo "=== DNS Record Changes (from logs) ==="
kubectl logs deployment/"$NAME" -n "$NS" --tail=100 2>/dev/null | grep -i "create\|update\|delete\|upsert" | head -15

echo ""
echo "=== Errors in ExternalDNS ==="
kubectl logs deployment/"$NAME" -n "$NS" --tail=100 2>/dev/null | grep -i "error\|fail\|denied" | head -10

echo ""
echo "=== TXT Ownership Records ==="
kubectl get dnsendpoints --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  select(.spec.endpoints[]?.recordType == "TXT") |
  "\(.metadata.namespace)/\(.metadata.name)\t\(.spec.endpoints[] | select(.recordType == "TXT") | .dnsName)"
' | head -10
```

## Output Format

- Target ≤50 lines per output
- Use `-o custom-columns` and jq for targeted field extraction
- Show hostname-to-service mappings clearly
- Aggregate DNS records by domain when many exist
- Never dump full deployment specs -- show args and annotations only

## Common Pitfalls

- **Provider credentials**: Most failures are credential issues -- check ServiceAccount, IRSA, or Secret references
- **Domain filters**: ExternalDNS only manages domains matching `--domain-filter` -- unmatched domains are ignored
- **Ownership TXT records**: ExternalDNS uses TXT records for ownership -- deleting them causes orphaned records
- **Policy modes**: `sync` deletes records not in sources; `upsert-only` only creates/updates -- check `--policy` arg
- **Source types**: Can watch Services, Ingresses, Istio VirtualServices, and more -- check `--source` args
- **Annotation override**: `external-dns.alpha.kubernetes.io/hostname` overrides auto-detected hostnames
- **TTL**: Default TTL varies by provider -- use `external-dns.alpha.kubernetes.io/ttl` annotation to control
- **Dry run**: `--dry-run` flag prevents actual DNS changes -- useful for testing
