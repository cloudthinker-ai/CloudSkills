---
name: managing-sealed-secrets
description: |
  Bitnami Sealed Secrets management for Kubernetes, certificate rotation, secret encryption, and controller health. Covers encrypting secrets for Git storage, certificate lifecycle management, namespace-scoped vs cluster-wide secrets, and controller diagnostics. Use when encrypting Kubernetes secrets for GitOps, rotating sealing keys, auditing sealed secrets, or troubleshooting the sealed-secrets controller.
connection_type: sealed-secrets
preload: false
---

# Sealed Secrets Management Skill

Manage and analyze Bitnami Sealed Secrets, certificates, and controller health in Kubernetes.

## Tool Conventions

### Prerequisites
`kubeseal` CLI and `kubectl` must be installed. The sealed-secrets controller must be running in the cluster.

### Core Helper Function

```bash
#!/bin/bash

sealed_secrets_ns="${SEALED_SECRETS_NAMESPACE:-kube-system}"
sealed_secrets_controller="${SEALED_SECRETS_CONTROLLER:-sealed-secrets-controller}"
```

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields
- Target <=50 lines per script output
- **NEVER** output decrypted secret values -- only output secret names and metadata
- Never dump full secret data

## Discovery Phase

### Controller Health

```bash
#!/bin/bash
echo "=== Sealed Secrets Controller ==="
kubectl get deployment "${sealed_secrets_controller}" -n "${sealed_secrets_ns}" -o json \
    | jq '{name: .metadata.name, namespace: .metadata.namespace, replicas: .status.readyReplicas, available: .status.availableReplicas, image: .spec.template.spec.containers[0].image}'

echo ""
echo "=== Controller Pod Status ==="
kubectl get pods -n "${sealed_secrets_ns}" -l "app.kubernetes.io/name=sealed-secrets" -o json \
    | jq -r '.items[] | "\(.metadata.name)\t\(.status.phase)\t\(.status.containerStatuses[0].restartCount) restarts"' | column -t

echo ""
echo "=== Active Sealing Key ==="
kubeseal --fetch-cert --controller-name="${sealed_secrets_controller}" --controller-namespace="${sealed_secrets_ns}" 2>/dev/null \
    | openssl x509 -noout -dates 2>/dev/null || echo "Could not fetch certificate"
```

### List Sealed Secrets

```bash
#!/bin/bash
NAMESPACE="${1:-}"

echo "=== Sealed Secrets ==="
if [ -n "$NAMESPACE" ]; then
    kubectl get sealedsecrets -n "$NAMESPACE" -o json
else
    kubectl get sealedsecrets --all-namespaces -o json
fi | jq -r '.items[] | "\(.metadata.namespace)\t\(.metadata.name)\t\(.metadata.creationTimestamp[0:16])"' \
    | column -t | head -25
```

## Analysis Phase

### Certificate Lifecycle

```bash
#!/bin/bash
echo "=== Sealing Keys ==="
kubectl get secrets -n "${sealed_secrets_ns}" -l "sealedsecrets.bitnami.com/sealed-secrets-key=active" -o json \
    | jq -r '.items[] | "\(.metadata.name)\t\(.metadata.creationTimestamp[0:16])\tactive"' | column -t

echo ""
echo "=== Certificate Expiry ==="
kubeseal --fetch-cert --controller-name="${sealed_secrets_controller}" --controller-namespace="${sealed_secrets_ns}" 2>/dev/null \
    | openssl x509 -noout -subject -dates 2>/dev/null

echo ""
echo "=== Key Rotation History ==="
kubectl get secrets -n "${sealed_secrets_ns}" -l "sealedsecrets.bitnami.com/sealed-secrets-key" -o json \
    | jq -r '.items | sort_by(.metadata.creationTimestamp) | .[] | "\(.metadata.name)\t\(.metadata.creationTimestamp[0:16])"' | column -t
```

### Audit Sealed Secrets

```bash
#!/bin/bash
echo "=== Sealed Secrets by Namespace ==="
kubectl get sealedsecrets --all-namespaces -o json \
    | jq -r '.items[] | .metadata.namespace' | sort | uniq -c | sort -rn | head -15

echo ""
echo "=== Recently Modified ==="
kubectl get sealedsecrets --all-namespaces -o json \
    | jq -r '.items | sort_by(.metadata.creationTimestamp) | reverse | .[0:10][] | "\(.metadata.namespace)\t\(.metadata.name)\t\(.metadata.creationTimestamp[0:16])"' \
    | column -t
```

## Output Format
- Use tab-separated columns with `column -t`
- Limit lists to 15-25 items
- NEVER display secret values -- only names and metadata
- Show summaries before details

## Common Pitfalls
- **Never expose values**: Only display sealed secret names, never decrypted data
- **Namespace scope**: By default, sealed secrets are scoped to a specific namespace -- use `--scope` flag to change
- **Certificate rotation**: Sealed secrets controller rotates keys every 30 days by default -- old keys are kept for decryption
- **Re-encryption**: After key rotation, existing sealed secrets still work but should be re-encrypted with new key
- **Controller namespace**: Default is `kube-system` but may vary -- check `SEALED_SECRETS_NAMESPACE`
- **Scope modes**: `strict` (default, namespace+name bound), `namespace-wide`, `cluster-wide`
