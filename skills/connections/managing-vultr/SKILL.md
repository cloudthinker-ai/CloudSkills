---
name: managing-vultr
description: |
  Use when working with Vultr — vultr cloud infrastructure management via the
  vultr-cli and Vultr API. Covers instances, bare metal, block storage, load
  balancers, Kubernetes, databases, and billing. Use when managing Vultr
  resources or checking server health.
connection_type: vultr
preload: false
---

# Managing Vultr

Manage Vultr infrastructure using the `vultr-cli` or Vultr API.

## MANDATORY: Discovery-First Pattern

**Always discover available resources before performing analysis.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Account Info ==="
vultr-cli account 2>/dev/null || curl -s "https://api.vultr.com/v2/account" -H "Authorization: Bearer $VULTR_API_KEY" | jq '{name, email, balance, pending_charges}'

echo ""
echo "=== Instances ==="
vultr-cli instance list 2>/dev/null || curl -s "https://api.vultr.com/v2/instances" -H "Authorization: Bearer $VULTR_API_KEY" | jq -r '.instances[] | "\(.id)\t\(.label)\t\(.region)\t\(.plan)\t\(.status)\t\(.main_ip)"' | head -30

echo ""
echo "=== Bare Metal ==="
vultr-cli bare-metal list 2>/dev/null || curl -s "https://api.vultr.com/v2/bare-metals" -H "Authorization: Bearer $VULTR_API_KEY" | jq -r '.bare_metals[] | "\(.id)\t\(.label)\t\(.region)\t\(.plan)\t\(.status)\t\(.main_ip)"' | head -10

echo ""
echo "=== Block Storage ==="
vultr-cli block-storage list 2>/dev/null || curl -s "https://api.vultr.com/v2/blocks" -H "Authorization: Bearer $VULTR_API_KEY" | jq -r '.blocks[] | "\(.id)\t\(.label)\t\(.size_gb)GB\t\(.region)\t\(.status)\t\(.attached_to_instance)"' | head -10

echo ""
echo "=== Kubernetes Clusters ==="
vultr-cli kubernetes list 2>/dev/null || curl -s "https://api.vultr.com/v2/kubernetes/clusters" -H "Authorization: Bearer $VULTR_API_KEY" | jq -r '.vke_clusters[] | "\(.id)\t\(.label)\t\(.region)\t\(.version)\t\(.status)"' | head -10

echo ""
echo "=== Load Balancers ==="
vultr-cli load-balancer list 2>/dev/null || curl -s "https://api.vultr.com/v2/load-balancers" -H "Authorization: Bearer $VULTR_API_KEY" | jq -r '.load_balancers[] | "\(.id)\t\(.label)\t\(.region)\t\(.status)\t\(.ipv4)"' | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

INSTANCE_ID="${1:?Instance ID required}"

echo "=== Instance Details ==="
curl -s "https://api.vultr.com/v2/instances/$INSTANCE_ID" -H "Authorization: Bearer $VULTR_API_KEY" | jq '{
    id, label, status, power_status, region, plan,
    vcpu_count, ram, disk, os, main_ip,
    date_created, allowed_bandwidth, current_bandwidth_gb
}'

echo ""
echo "=== Instance Bandwidth ==="
curl -s "https://api.vultr.com/v2/instances/$INSTANCE_ID/bandwidth" -H "Authorization: Bearer $VULTR_API_KEY" | jq '[.bandwidth | to_entries | sort_by(.key) | .[-7:][] | {date: .key, incoming_bytes: .value.incoming_bytes, outgoing_bytes: .value.outgoing_bytes}]'

echo ""
echo "=== Databases ==="
curl -s "https://api.vultr.com/v2/databases" -H "Authorization: Bearer $VULTR_API_KEY" | jq -r '.dbs[] | "\(.id)\t\(.label)\t\(.database_engine)\t\(.database_engine_version)\t\(.region)\t\(.status)\t\(.plan)"' | head -10

echo ""
echo "=== Billing ==="
curl -s "https://api.vultr.com/v2/billing/invoices?per_page=5" -H "Authorization: Bearer $VULTR_API_KEY" | jq -r '.billing_invoices[] | "\(.id)\t\(.date)\t\(.amount)\t\(.description)"' | head -5
```

## Output Format

```
ID                                    LABEL    REGION  PLAN           STATUS  IP
abc123-def456-ghi789                  web-01   ewr     vc2-1c-1gb     active  1.2.3.4
```

## Safety Rules
- Use read-only commands: `list`, GET API calls
- Never run `delete`, `destroy`, DELETE calls without explicit user confirmation
- Use jq for structured output parsing
- Limit output with `| head -N` to stay under 50 lines

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

