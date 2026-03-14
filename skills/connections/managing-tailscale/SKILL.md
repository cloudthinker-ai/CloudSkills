---
name: managing-tailscale
description: |
  Tailscale mesh VPN management, device status monitoring, ACL policy analysis, DNS configuration, and exit node management. Covers network topology inspection, key expiry tracking, MagicDNS status, and subnet routing. Read this skill before any Tailscale operations — it enforces discovery-first patterns, anti-hallucination rules, and safety constraints.
connection_type: tailscale
preload: false
---

# Tailscale Management Skill

Monitor, analyze, and manage Tailscale networks safely.

## MANDATORY: Discovery-First Pattern

**Always run `tailscale status` and check the current network state before making changes. Never guess device names or IP addresses.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Tailscale Status ==="
tailscale status

echo ""
echo "=== Current Node Info ==="
tailscale status --json | python3 -c "
import json, sys
data = json.load(sys.stdin)
self_node = data.get('Self', {})
print(f'Hostname: {self_node.get(\"HostName\", \"unknown\")}')
print(f'DNS Name: {self_node.get(\"DNSName\", \"unknown\")}')
print(f'Tailscale IPs: {self_node.get(\"TailscaleIPs\", [])}')
print(f'OS: {self_node.get(\"OS\", \"unknown\")}')
print(f'Online: {self_node.get(\"Online\", False)}')
print(f'Exit Node: {self_node.get(\"ExitNode\", False)}')
print(f'Key Expiry: {self_node.get(\"KeyExpiry\", \"none\")}')
" 2>/dev/null

echo ""
echo "=== Network Info ==="
tailscale status --json | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(f'MagicDNS Suffix: {data.get(\"MagicDNSSuffix\", \"unknown\")}')
print(f'Current Tailnet: {data.get(\"CurrentTailnet\", {}).get(\"Name\", \"unknown\")}')
" 2>/dev/null

echo ""
echo "=== Tailscale Version ==="
tailscale version
```

**Phase 1 outputs:** Device list, IP addresses, online status, network name, MagicDNS suffix

### Phase 2: Analysis

Only manage devices and networks confirmed in Phase 1 output.

## Anti-Hallucination Rules

- **NEVER assume device names** — always extract from `tailscale status`
- **NEVER guess Tailscale IPs** — parse from status output
- **NEVER assume ACL rules** — verify via admin console or API
- **NEVER assume subnet routes** — check `tailscale status --json` for advertised routes
- **ALWAYS verify online status** before attempting connections

## Safety Rules

- **READ-ONLY by default**: Use `tailscale status`, `tailscale ping`, `tailscale netcheck`
- **FORBIDDEN without explicit request**: `tailscale down`, `tailscale logout`, ACL policy changes
- **Key management**: Never expose auth keys — they grant network access
- **Exit node changes**: Routing all traffic through exit node affects connectivity — confirm intent
- **Subnet routes**: Advertising new routes affects network routing for all peers

## Core Helper Functions

```bash
#!/bin/bash

# List all devices with status
list_devices() {
    tailscale status --json | python3 -c "
import json, sys
data = json.load(sys.stdin)
peers = data.get('Peer', {})
for key, peer in peers.items():
    status = 'online' if peer.get('Online') else 'offline'
    ips = ', '.join(peer.get('TailscaleIPs', []))
    print(f'{peer[\"HostName\"]:<25} {status:<10} {ips}')
"
}

# Check connectivity to a peer
check_peer() {
    local peer="$1"
    tailscale ping --c 3 "$peer" 2>&1
}

# Get device details
device_info() {
    local hostname="$1"
    tailscale status --json | python3 -c "
import json, sys
data = json.load(sys.stdin)
for key, peer in data.get('Peer', {}).items():
    if peer.get('HostName') == '$hostname':
        for k, v in peer.items():
            print(f'{k}: {v}')
"
}
```

## Common Operations

### Device Management

```bash
#!/bin/bash
echo "=== All Devices ==="
tailscale status --json | python3 -c "
import json, sys
data = json.load(sys.stdin)
self_node = data.get('Self', {})
print(f'{'Hostname':<25} {'Status':<10} {'OS':<10} {'IPs':<30} {'Last Seen'}')
print('-' * 100)
print(f'{self_node[\"HostName\"]:<25} {\"online\":<10} {self_node.get(\"OS\",\"\"):<10} {\", \".join(self_node.get(\"TailscaleIPs\",[])):<30} self')
for key, peer in data.get('Peer', {}).items():
    status = 'online' if peer.get('Online') else 'offline'
    ips = ', '.join(peer.get('TailscaleIPs', []))
    last = peer.get('LastSeen', 'unknown')
    print(f'{peer[\"HostName\"]:<25} {status:<10} {peer.get(\"OS\",\"\"):<10} {ips:<30} {last[:19]}')
"

echo ""
echo "=== Key Expiry Status ==="
tailscale status --json | python3 -c "
import json, sys
from datetime import datetime
data = json.load(sys.stdin)
for key, peer in {**{'self': data.get('Self', {})}, **data.get('Peer', {})}.items():
    expiry = peer.get('KeyExpiry', '')
    hostname = peer.get('HostName', key)
    if expiry:
        print(f'{hostname}: key expires {expiry[:10]}')
    else:
        print(f'{hostname}: no key expiry (pre-auth or disabled)')
"
```

### ACL Policy Analysis

```bash
#!/bin/bash
echo "=== Current ACL Policy (via API) ==="
# Requires TAILSCALE_API_KEY and TAILNET
TAILNET="${TAILNET:-$(tailscale status --json | python3 -c "import json,sys; print(json.load(sys.stdin).get('CurrentTailnet',{}).get('Name',''))" 2>/dev/null)}"

if [ -n "$TAILSCALE_API_KEY" ] && [ -n "$TAILNET" ]; then
    curl -s -H "Authorization: Bearer $TAILSCALE_API_KEY" \
        "https://api.tailscale.com/api/v2/tailnet/$TAILNET/acl" | python3 -m json.tool
else
    echo "Set TAILSCALE_API_KEY and TAILNET to query ACL policy via API"
    echo "Alternatively, check the Tailscale admin console: https://login.tailscale.com/admin/acls"
fi
```

### DNS Configuration

```bash
#!/bin/bash
echo "=== MagicDNS Status ==="
tailscale status --json | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(f'MagicDNS Suffix: {data.get(\"MagicDNSSuffix\", \"not configured\")}')
"

echo ""
echo "=== DNS Preferences ==="
tailscale debug prefs 2>/dev/null | grep -iE 'dns|magic|domain' || echo "Use admin console for DNS settings"

echo ""
echo "=== Resolve Test ==="
tailscale status --json | python3 -c "
import json, sys
data = json.load(sys.stdin)
suffix = data.get('MagicDNSSuffix', '')
for key, peer in data.get('Peer', {}).items():
    dns_name = peer.get('DNSName', '')
    if dns_name:
        print(f'{peer[\"HostName\"]} -> {dns_name}')
" 2>/dev/null
```

### Exit Node Status

```bash
#!/bin/bash
echo "=== Available Exit Nodes ==="
tailscale status --json | python3 -c "
import json, sys
data = json.load(sys.stdin)
for key, peer in data.get('Peer', {}).items():
    if peer.get('ExitNodeOption'):
        status = 'ACTIVE' if peer.get('ExitNode') else 'available'
        print(f'{peer[\"HostName\"]:<25} {status:<10} {peer.get(\"OS\",\"\")} location={peer.get(\"Location\",{}).get(\"Country\",\"unknown\")}')
" 2>/dev/null

echo ""
echo "=== Current Exit Node ==="
tailscale status --json | python3 -c "
import json, sys
data = json.load(sys.stdin)
for key, peer in data.get('Peer', {}).items():
    if peer.get('ExitNode'):
        print(f'Using exit node: {peer[\"HostName\"]} ({peer.get(\"TailscaleIPs\",[])})')
        break
else:
    print('No exit node active')
" 2>/dev/null

echo ""
echo "=== Subnet Routes ==="
tailscale status --json | python3 -c "
import json, sys
data = json.load(sys.stdin)
for key, peer in data.get('Peer', {}).items():
    routes = peer.get('PrimaryRoutes', [])
    if routes:
        print(f'{peer[\"HostName\"]}: {routes}')
" 2>/dev/null
```

## Common Pitfalls

- **Auth key expiry**: Auth keys expire by default — nodes will lose access after key expiry unless set to non-expiring
- **MagicDNS vs split DNS**: MagicDNS overrides system DNS for tailnet domains — can conflict with corporate DNS
- **Exit node routing**: Enabling exit node routes ALL traffic through that node — not just tailnet traffic
- **Subnet route conflicts**: Overlapping subnet routes from multiple nodes cause routing ambiguity
- **ACL deny-by-default**: Tailscale ACLs are deny-by-default — removing a rule blocks access
- **`tailscale down` vs `tailscale logout`**: `down` disconnects but keeps auth; `logout` removes the node entirely
- **Key rotation**: Rotating keys requires re-authentication — schedule during maintenance windows
