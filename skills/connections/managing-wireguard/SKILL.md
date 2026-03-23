---
name: managing-wireguard
description: |
  Use when working with Wireguard — wireGuard VPN tunnel management, peer
  configuration, handshake timing analysis, transfer statistics, and interface
  monitoring. Covers tunnel status inspection, key management, endpoint
  tracking, and routing table analysis. Read this skill before any WireGuard
  operations — it enforces discovery-first patterns, anti-hallucination rules,
  and safety constraints.
connection_type: wireguard
preload: false
---

# WireGuard Management Skill

Monitor, analyze, and manage WireGuard VPN tunnels safely.

## MANDATORY: Discovery-First Pattern

**Always run `wg show` to inspect active interfaces before making changes. Never guess peer public keys or endpoints.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== WireGuard Interfaces ==="
${WG_SUDO:+sudo} wg show interfaces 2>/dev/null || echo "No active WireGuard interfaces (or insufficient permissions)"

echo ""
echo "=== Interface Details ==="
${WG_SUDO:+sudo} wg show all

echo ""
echo "=== Network Interfaces ==="
ip addr show type wireguard 2>/dev/null || ifconfig | grep -A5 'wg\|utun'

echo ""
echo "=== Routing Table (WireGuard-related) ==="
ip route show | grep -i wg 2>/dev/null || netstat -rn | grep -i utun 2>/dev/null

echo ""
echo "=== Configuration Files ==="
ls -la /etc/wireguard/*.conf 2>/dev/null || echo "No config files in /etc/wireguard/"
```

**Phase 1 outputs:** Interface names, peer public keys, endpoints, allowed IPs, last handshake times

### Phase 2: Analysis

Only manage interfaces and peers confirmed in Phase 1 output.

## Anti-Hallucination Rules

- **NEVER assume peer public keys** — always extract from `wg show`
- **NEVER guess endpoints** — parse from active interface output
- **NEVER assume AllowedIPs** — verify from running configuration
- **NEVER assume interface names** — check `wg show interfaces`
- **ALWAYS use `wg show`** for live state rather than config files alone

## Safety Rules

- **READ-ONLY by default**: Use `wg show`, `wg showconf`, routing table inspection
- **FORBIDDEN without explicit request**: `wg-quick down`, `wg set` peer removal, private key operations
- **Private key security**: NEVER display or log private keys — use `wg show` which redacts them
- **Peer removal is instant**: `wg set IFACE peer KEY remove` takes effect immediately with no confirmation
- **Config file permissions**: WireGuard configs contain private keys — must be 600 or 640

## Core Helper Functions

```bash
#!/bin/bash

WG_CMD="${WG_SUDO:+sudo} wg"

# List all interfaces
list_interfaces() {
    $WG_CMD show interfaces 2>/dev/null | tr ' ' '\n'
}

# Get peer info for an interface
list_peers() {
    local iface="$1"
    $WG_CMD show "$iface" dump | tail -n +2 | awk -F'\t' '{
        printf "pubkey=%s endpoint=%s allowed=%s handshake=%s rx=%s tx=%s\n",
            $1, $3, $4, $5, $6, $7
    }'
}

# Check peer handshake freshness
check_handshakes() {
    local iface="$1"
    local now=$(date +%s)
    $WG_CMD show "$iface" dump | tail -n +2 | awk -F'\t' -v now="$now" '{
        age = now - $5
        status = (age < 180) ? "OK" : (age < 300) ? "STALE" : "DOWN"
        printf "%-44s %s (last: %ds ago)\n", $1, status, age
    }'
}
```

## Common Operations

### Peer Management

```bash
#!/bin/bash
echo "=== All Peers by Interface ==="
for iface in $(${WG_SUDO:+sudo} wg show interfaces 2>/dev/null); do
    echo "--- Interface: $iface ---"
    ${WG_SUDO:+sudo} wg show "$iface" | awk '
        /^peer:/ { peer=$2 }
        /endpoint:/ { endpoint=$2 }
        /allowed ips:/ { allowed=$3 }
        /latest handshake:/ {
            $1=""; $2=""; handshake=$0
            printf "  Peer: %.16s... endpoint=%-22s allowed=%-18s handshake=%s\n",
                peer, endpoint, allowed, handshake
        }
    '
    echo ""
done
```

### Tunnel Status

```bash
#!/bin/bash
echo "=== Tunnel Health ==="
for iface in $(${WG_SUDO:+sudo} wg show interfaces 2>/dev/null); do
    echo "--- $iface ---"
    ${WG_SUDO:+sudo} wg show "$iface" dump | tail -n +2 | while IFS=$'\t' read pubkey psk endpoint allowed handshake rx tx keepalive; do
        now=$(date +%s)
        age=$((now - handshake))
        if [ "$handshake" -eq 0 ] 2>/dev/null; then
            status="NEVER_CONNECTED"
        elif [ "$age" -lt 180 ]; then
            status="ACTIVE"
        elif [ "$age" -lt 300 ]; then
            status="STALE"
        else
            status="INACTIVE"
        fi
        printf "  %-44s %s (handshake %ds ago)\n" "${pubkey:0:16}..." "$status" "$age"
    done
done

echo ""
echo "=== Interface IP Addresses ==="
for iface in $(${WG_SUDO:+sudo} wg show interfaces 2>/dev/null); do
    ip addr show "$iface" 2>/dev/null | grep inet | awk -v i="$iface" '{print i ": " $2}'
done
```

### Handshake Timing Analysis

```bash
#!/bin/bash
echo "=== Handshake Freshness Report ==="
NOW=$(date +%s)
${WG_SUDO:+sudo} wg show all dump | tail -n +2 | awk -F'\t' -v now="$NOW" '{
    iface=$1; pubkey=$2; endpoint=$4; handshake=$6
    age = now - handshake
    if (handshake == 0) status = "NEVER"
    else if (age < 135) status = "FRESH"
    else if (age < 180) status = "OK"
    else if (age < 300) status = "WARNING"
    else status = "CRITICAL"
    printf "%-10s %-20s %-25s %-10s %ds\n", iface, substr(pubkey,1,16)"...", endpoint, status, age
}'

echo ""
echo "=== Peers Needing Attention ==="
${WG_SUDO:+sudo} wg show all dump | tail -n +2 | awk -F'\t' -v now="$NOW" '{
    age = now - $6
    if ($6 == 0 || age > 300) {
        printf "ALERT: %s peer %s — no handshake in %ds\n", $1, substr($2,1,16)"...", age
    }
}'
```

### Transfer Statistics

```bash
#!/bin/bash
echo "=== Transfer Stats per Peer ==="
${WG_SUDO:+sudo} wg show all dump | tail -n +2 | awk -F'\t' '{
    iface=$1; pubkey=$2; endpoint=$4; rx=$7; tx=$8
    rx_mb = rx / 1048576
    tx_mb = tx / 1048576
    printf "%-10s %-20s %-25s rx=%.1fMB tx=%.1fMB\n", iface, substr(pubkey,1,16)"...", endpoint, rx_mb, tx_mb
}'

echo ""
echo "=== Total Transfer per Interface ==="
for iface in $(${WG_SUDO:+sudo} wg show interfaces 2>/dev/null); do
    ${WG_SUDO:+sudo} wg show "$iface" dump | tail -n +2 | awk -F'\t' -v i="$iface" '{
        rx+=$7; tx+=$8
    } END {
        printf "%s: total_rx=%.1fMB total_tx=%.1fMB\n", i, rx/1048576, tx/1048576
    }'
done
```

## Output Format

Present results as a structured report:
```
Managing Wireguard Report
═════════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

## Common Pitfalls

- **Handshake timeout**: No handshake for >180s means the tunnel may be broken — check endpoint reachability
- **AllowedIPs overlap**: Two peers with overlapping AllowedIPs cause routing conflicts — WireGuard uses most specific match
- **`0.0.0.0/0` AllowedIPs**: Routes ALL traffic through the peer — this is a full tunnel, not split tunnel
- **PersistentKeepalive**: Required for peers behind NAT — without it, NAT mapping expires and tunnel drops
- **MTU issues**: Default MTU may cause fragmentation — set to 1420 for IPv4 or 1400 for IPv6-over-IPv4
- **`wg-quick` vs `wg`**: `wg-quick` manages routes and DNS; `wg` only manages the interface itself
- **DNS leaks**: WireGuard does not manage DNS by default — configure `DNS =` in `wg-quick` config or handle separately
- **Config file permissions**: Private keys in config must have restrictive permissions (chmod 600)
