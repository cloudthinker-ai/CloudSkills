---
name: managing-digitalocean
description: |
  DigitalOcean infrastructure management via the doctl CLI. Covers Droplets, databases, load balancers, firewalls, domains, and account billing. Use when managing DigitalOcean resources, checking Droplet health, or reviewing infrastructure costs.
connection_type: digitalocean
preload: false
---

# Managing DigitalOcean

Manage DigitalOcean infrastructure using the `doctl` CLI.

## MANDATORY: Discovery-First Pattern

**Always discover available resources before performing analysis.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Account Info ==="
doctl account get --format Email,DropletLimit,Status --no-header

echo ""
echo "=== Droplets ==="
doctl compute droplet list --format ID,Name,Region,Size,VCPUs,Memory,Disk,Status,PublicIPv4 --no-header | head -30

echo ""
echo "=== Databases ==="
doctl databases list --format ID,Name,Engine,Version,Region,Status,Size,NumNodes --no-header | head -20

echo ""
echo "=== Load Balancers ==="
doctl compute load-balancer list --format ID,Name,Region,Status,IP --no-header | head -10

echo ""
echo "=== Volumes ==="
doctl compute volume list --format ID,Name,Region,Size,DropletIDs --no-header | head -20

echo ""
echo "=== Firewalls ==="
doctl compute firewall list --format ID,Name,Status --no-header | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Droplet Details ==="
DROPLET_ID="${1:?Droplet ID required}"
doctl compute droplet get "$DROPLET_ID" --format ID,Name,Region,Size,VCPUs,Memory,Disk,Status,PublicIPv4,Created

echo ""
echo "=== Droplet Bandwidth (Recent) ==="
doctl monitoring droplet bandwidth get "$DROPLET_ID" --start "$(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)" --end "$(date -u +%Y-%m-%dT%H:%M:%SZ)" 2>/dev/null || echo "Bandwidth metrics not available"

echo ""
echo "=== Droplet CPU (Recent) ==="
doctl monitoring droplet cpu get "$DROPLET_ID" --start "$(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)" --end "$(date -u +%Y-%m-%dT%H:%M:%SZ)" 2>/dev/null || echo "CPU metrics not available"

echo ""
echo "=== Balance & Billing ==="
doctl balance get --format MonthToDateBalance,AccountBalance,MonthToDateUsage --no-header
```

## Output Format

```
RESOURCE_TYPE  ID          NAME        REGION  STATUS
droplet        12345678    web-01      nyc1    active
droplet        12345679    web-02      nyc1    active
database       abc-123     pg-main     nyc1    online
```

## Safety Rules
- Use read-only commands: `list`, `get`
- Never run `delete`, `destroy`, `remove` without explicit user confirmation
- Always use `--no-header` and `--format` for clean output
- Limit output with `| head -N` to stay under 50 lines
