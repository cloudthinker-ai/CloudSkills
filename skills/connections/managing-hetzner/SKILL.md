---
name: managing-hetzner
description: |
  Hetzner Cloud and dedicated server management via the hcloud CLI and Hetzner API. Covers servers, volumes, networks, firewalls, load balancers, and snapshots. Use when managing Hetzner infrastructure or checking server health.
connection_type: hetzner
preload: false
---

# Managing Hetzner

Manage Hetzner infrastructure using the `hcloud` CLI and Hetzner Robot API.

## MANDATORY: Discovery-First Pattern

**Always discover available resources before performing analysis.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Hetzner Cloud Servers ==="
hcloud server list -o columns=id,name,status,server_type,datacenter,ipv4,created 2>/dev/null | head -30

echo ""
echo "=== Volumes ==="
hcloud volume list -o columns=id,name,size,server,location,created 2>/dev/null | head -20

echo ""
echo "=== Networks ==="
hcloud network list -o columns=id,name,ip_range,servers 2>/dev/null | head -10

echo ""
echo "=== Firewalls ==="
hcloud firewall list -o columns=id,name,rules_count,applied_to_count 2>/dev/null | head -10

echo ""
echo "=== Load Balancers ==="
hcloud load-balancer list -o columns=id,name,type,location,ipv4 2>/dev/null | head -10

echo ""
echo "=== SSH Keys ==="
hcloud ssh-key list -o columns=id,name,fingerprint 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash

SERVER_ID="${1:?Server ID required}"

echo "=== Server Details ==="
hcloud server describe "$SERVER_ID" 2>/dev/null

echo ""
echo "=== Server Metrics (CPU, Disk, Network) ==="
hcloud server metrics "$SERVER_ID" --type cpu,disk,network --start "$(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)" --end "$(date -u +%Y-%m-%dT%H:%M:%SZ)" 2>/dev/null | head -30

echo ""
echo "=== Snapshots ==="
hcloud image list --type snapshot -o columns=id,description,created,image_size,disk_size 2>/dev/null | head -10

echo ""
echo "=== Floating IPs ==="
hcloud floating-ip list -o columns=id,type,ip,server,home_location 2>/dev/null | head -10
```

## Output Format

```
ID       NAME       STATUS    TYPE     DATACENTER  IP
123456   web-01     running   cx21     fsn1-dc14   1.2.3.4
123457   db-01      running   cx31     nbg1-dc3    5.6.7.8
```

## Safety Rules
- Use read-only commands: `list`, `describe`, `metrics`
- Never run `delete`, `shutdown`, `reset` without explicit user confirmation
- Use `-o columns=` for clean, targeted output
- Limit output with `| head -N` to stay under 50 lines
