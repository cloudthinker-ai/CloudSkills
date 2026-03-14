---
name: managing-k8s-network-policies
description: |
  Kubernetes NetworkPolicy management and network segmentation analysis. Covers NetworkPolicy inventory, ingress and egress rules, pod selector coverage, namespace isolation, default deny policies, and policy gap detection. Use when auditing network security, debugging connectivity issues, reviewing network segmentation, or identifying unprotected workloads.
connection_type: k8s
preload: false
---

# Kubernetes NetworkPolicy Skill

Manage and analyze NetworkPolicies for network segmentation and security.

## MANDATORY: Discovery-First Pattern

**Always list NetworkPolicies and check CNI support before analyzing coverage.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== NetworkPolicies (all namespaces) ==="
kubectl get networkpolicies --all-namespaces -o custom-columns='NAMESPACE:.metadata.namespace,NAME:.metadata.name,POD-SELECTOR:.spec.podSelector.matchLabels,POLICY-TYPES:.spec.policyTypes[*]' 2>/dev/null | head -20

echo ""
echo "=== Policy Count Per Namespace ==="
kubectl get networkpolicies --all-namespaces -o json 2>/dev/null | jq -r '
  [.items[] | .metadata.namespace] |
  group_by(.) | map({ns: .[0], count: length}) |
  sort_by(-.count)[] |
  "\(.ns)\t\(.count) policies"
' | head -15

echo ""
echo "=== CNI Plugin ==="
kubectl get pods -n kube-system -o custom-columns='NAME:.metadata.name' 2>/dev/null | grep -iE "calico|cilium|weave|flannel|antrea" | head -5
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Default Deny Policies ==="
kubectl get networkpolicies --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  select(.spec.podSelector == {} or .spec.podSelector.matchLabels == null) |
  select((.spec.ingress == null or .spec.ingress == []) and (.spec.policyTypes // [] | contains(["Ingress"]))) |
  "\(.metadata.namespace)/\(.metadata.name)\tDefault-Deny-Ingress"
'
kubectl get networkpolicies --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  select(.spec.podSelector == {} or .spec.podSelector.matchLabels == null) |
  select((.spec.egress == null or .spec.egress == []) and (.spec.policyTypes // [] | contains(["Egress"]))) |
  "\(.metadata.namespace)/\(.metadata.name)\tDefault-Deny-Egress"
'

echo ""
echo "=== Namespaces Without Any NetworkPolicy ==="
POLICY_NS=$(kubectl get networkpolicies --all-namespaces -o jsonpath='{.items[*].metadata.namespace}' 2>/dev/null | tr ' ' '\n' | sort -u)
ALL_NS=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' 2>/dev/null | tr ' ' '\n' | sort)
comm -23 <(echo "$ALL_NS") <(echo "$POLICY_NS") | grep -v "^kube-" | head -15

echo ""
echo "=== Ingress Rules Summary ==="
kubectl get networkpolicies --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  select(.spec.ingress != null) |
  "\(.metadata.namespace)/\(.metadata.name)\tIngress-Rules:\(.spec.ingress | length)\tFrom:" +
  ([.spec.ingress[].from[]? |
    if .namespaceSelector then "ns-selector"
    elif .podSelector then "pod-selector"
    elif .ipBlock then "ip:\(.ipBlock.cidr)"
    else "unknown" end
  ] | unique | join(","))
' | head -15

echo ""
echo "=== Egress Rules Summary ==="
kubectl get networkpolicies --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  select(.spec.egress != null) |
  "\(.metadata.namespace)/\(.metadata.name)\tEgress-Rules:\(.spec.egress | length)\tTo:" +
  ([.spec.egress[].to[]? |
    if .namespaceSelector then "ns-selector"
    elif .podSelector then "pod-selector"
    elif .ipBlock then "ip:\(.ipBlock.cidr)"
    else "unknown" end
  ] | unique | join(","))
' | head -15

echo ""
echo "=== Wide-Open Policies (allow all) ==="
kubectl get networkpolicies --all-namespaces -o json 2>/dev/null | jq -r '
  .items[] |
  select(
    (.spec.ingress[]? | select(.from == null or .from == [])) or
    (.spec.egress[]? | select(.to == null or .to == []))
  ) |
  "\(.metadata.namespace)/\(.metadata.name)\tWARN: allows all traffic"
' | head -10
```

## Output Format

- Target ≤50 lines per output
- Use jq for NetworkPolicy rule analysis
- Summarize ingress/egress rules by type (podSelector, namespaceSelector, ipBlock)
- Flag namespaces without default deny policies
- Never dump full policy YAML -- show rule summaries

## Common Pitfalls

- **CNI requirement**: NetworkPolicies require a CNI that enforces them (Calico, Cilium, Antrea) -- Flannel does NOT enforce
- **Default behavior**: Without any NetworkPolicy, all traffic is allowed -- NetworkPolicies are additive (union)
- **Empty podSelector**: `podSelector: {}` selects ALL pods in the namespace -- used for default deny
- **Ingress vs Egress**: policyTypes must include "Egress" for egress rules to take effect -- omitting policyTypes defaults to Ingress only (unless egress rules exist)
- **DNS egress**: Default deny egress blocks DNS -- always allow egress to kube-dns on port 53
- **Namespace labels**: namespaceSelector matches on namespace labels -- ensure namespaces are labeled
- **AND vs OR**: Within a single `from`/`to` entry, selectors are AND; between entries, they are OR
- **CIDR exceptions**: `ipBlock.except` excludes specific IPs from a CIDR range -- commonly used for cluster IPs
