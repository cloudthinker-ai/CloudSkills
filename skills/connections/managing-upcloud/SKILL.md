---
name: managing-upcloud
description: |
  Use when working with Upcloud — upCloud infrastructure management via the
  upctl CLI and UpCloud API. Covers servers, storage, networks, load balancers,
  managed databases, and Kubernetes. Use when managing UpCloud resources or
  checking server health.
connection_type: upcloud
preload: false
---

# Managing UpCloud

Manage UpCloud infrastructure using the `upctl` CLI or UpCloud API.

## MANDATORY: Discovery-First Pattern

**Always discover available resources before performing analysis.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Account Info ==="
upctl account show -o json 2>/dev/null | jq '{username, credits, resource_limits}' || \
curl -s -u "$UPCLOUD_USERNAME:$UPCLOUD_PASSWORD" "https://api.upcloud.com/1.3/account" | jq '.account'

echo ""
echo "=== Servers ==="
upctl server list -o json 2>/dev/null | jq -r '.[] | "\(.uuid)\t\(.title)\t\(.zone)\t\(.plan)\t\(.state)\t\(.hostname)"' | head -30 || \
curl -s -u "$UPCLOUD_USERNAME:$UPCLOUD_PASSWORD" "https://api.upcloud.com/1.3/server" | jq -r '.servers.server[] | "\(.uuid)\t\(.title)\t\(.zone)\t\(.plan)\t\(.state)"' | head -30

echo ""
echo "=== Storage ==="
upctl storage list -o json 2>/dev/null | jq -r '.[] | "\(.uuid)\t\(.title)\t\(.size)GB\t\(.type)\t\(.state)\t\(.zone)"' | head -20

echo ""
echo "=== Networks ==="
upctl network list -o json 2>/dev/null | jq -r '.[] | "\(.uuid)\t\(.name)\t\(.type)\t\(.zone)\t\(.ip_networks[0].address // "N/A")"' | head -10

echo ""
echo "=== Managed Databases ==="
upctl database list -o json 2>/dev/null | jq -r '.[] | "\(.uuid)\t\(.title)\t\(.type)\t\(.plan)\t\(.state)\t\(.zone)"' | head -10

echo ""
echo "=== Load Balancers ==="
upctl loadbalancer list -o json 2>/dev/null | jq -r '.[] | "\(.uuid)\t\(.name)\t\(.plan)\t\(.zone)\t\(.operational_state)"' | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

SERVER_UUID="${1:?Server UUID required}"

echo "=== Server Details ==="
upctl server show "$SERVER_UUID" -o json 2>/dev/null | jq '{
    uuid, title, state, hostname, zone, plan,
    core_number, memory_amount,
    ip_addresses: [.networking.interfaces[].ip_addresses[] | {address, family, access}]
}' || \
curl -s -u "$UPCLOUD_USERNAME:$UPCLOUD_PASSWORD" "https://api.upcloud.com/1.3/server/$SERVER_UUID" | jq '.server | {uuid, title, state, hostname, zone, plan, core_number, memory_amount}'

echo ""
echo "=== Server Storage ==="
upctl server show "$SERVER_UUID" -o json 2>/dev/null | jq '[.storage_devices[] | {uuid: .storage, title: .storage_title, size: .storage_size, type: .type}]'

echo ""
echo "=== Kubernetes Clusters ==="
upctl kubernetes list -o json 2>/dev/null | jq -r '.[] | "\(.uuid)\t\(.name)\t\(.zone)\t\(.version)\t\(.state)"' | head -10

echo ""
echo "=== Firewall Rules ==="
upctl server firewall-rules show "$SERVER_UUID" -o json 2>/dev/null | jq -r '.[] | "\(.position)\t\(.action)\t\(.direction)\t\(.protocol)\t\(.destination_port_start)-\(.destination_port_end)"' | head -10
```

## Output Format

```
UUID                                  TITLE    ZONE       PLAN       STATE    HOSTNAME
abc123-def456-ghi789                  web-01   fi-hel1    2xCPU-4GB  started  web-01.example.com
```

## Safety Rules
- Use read-only commands: `list`, `show`
- Never run `delete`, `stop`, `destroy` without explicit user confirmation
- Use `-o json` with jq for structured output parsing
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

