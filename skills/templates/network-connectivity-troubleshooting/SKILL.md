---
name: network-connectivity-troubleshooting
enabled: true
description: |
  Use when performing network connectivity troubleshooting — network issue
  diagnosis decision tree covering WiFi connectivity, wired LAN problems, DNS
  resolution failures, DHCP issues, and general internet access troubleshooting.
  Guides helpdesk agents through systematic network diagnosis from physical
  layer up through application layer to identify and resolve connectivity
  issues.
required_connections:
  - prefix: itsm
    label: "ITSM Tool (ServiceNow, Freshservice, etc.)"
config_fields:
  - key: user_name
    label: "Affected User Name"
    required: true
    placeholder: "e.g., Jane Smith"
  - key: connection_type
    label: "Connection Type"
    required: true
    placeholder: "e.g., WiFi, Ethernet, both"
  - key: symptom
    label: "Primary Symptom"
    required: true
    placeholder: "e.g., no internet, slow speeds, intermittent drops, cannot reach internal site"
  - key: location
    label: "User Location"
    required: false
    placeholder: "e.g., 3rd Floor East, Home Office, Conference Room B"
features:
  - HELPDESK
---

# Network Connectivity Troubleshooting

Troubleshooting network issue for **{{ user_name }}**
Connection: **{{ connection_type }}** | Location: {{ location }}
Symptom: **{{ symptom }}**

## Decision Tree

```
START: Can user access ANYTHING on the network?
│
├─ NO — Complete loss of connectivity
│  ├─ Physical layer checks
│  │  ├─ WiFi: Is WiFi enabled? Connected to correct SSID?
│  │  └─ Ethernet: Cable plugged in? Link light on?
│  ├─ IP configuration
│  │  ├─ Has valid IP? (not 169.254.x.x / APIPA)
│  │  │  ├─ No → DHCP issue (see below)
│  │  │  └─ Yes → Continue
│  │  ├─ Can ping default gateway?
│  │  │  ├─ No → Local network issue
│  │  │  └─ Yes → Continue
│  │  └─ Can ping 8.8.8.8?
│  │     ├─ No → Routing / firewall issue
│  │     └─ Yes → DNS issue (see below)
│  └─ Multiple users affected?
│     ├─ Yes → Infrastructure issue, escalate
│     └─ No → Device-specific issue
│
├─ PARTIAL — Some sites/services work, others don't
│  ├─ Internal only fails → VPN or DNS (internal zones) issue
│  ├─ External only fails → Proxy or firewall issue
│  └─ Specific site fails → DNS, firewall rule, or site-specific block
│
└─ SLOW — Connectivity works but is degraded
   ├─ Run speed test → Compare to expected bandwidth
   ├─ WiFi signal strength → Check distance from AP
   ├─ Bandwidth saturation → Check for large downloads/backups
   └─ High latency → Check for network congestion, packet loss
```

## Step-by-Step Troubleshooting

### Layer 1 — Physical Connectivity

**WiFi:**
- [ ] WiFi adapter enabled (not in airplane mode)
- [ ] Connected to correct corporate SSID (not guest network)
- [ ] Signal strength adequate (at least 2 bars / -70 dBm)
- [ ] Try "forget network" and reconnect
- [ ] Try connecting to a different WiFi access point

**Ethernet:**
- [ ] Cable securely connected at both ends
- [ ] Link light active on network port and device
- [ ] Try a different cable
- [ ] Try a different network port

### Layer 2/3 — IP Configuration

```bash
# Windows
ipconfig /all
# macOS / Linux
ifconfig    # or: ip addr show

# Check for:
# - Valid IP address (not 169.254.x.x)
# - Correct subnet mask
# - Default gateway present
# - DNS servers configured
```

- [ ] If APIPA address (169.254.x.x): DHCP not working
  - Release and renew: `ipconfig /release && ipconfig /renew` (Windows)
  - Or: `sudo dhclient -r && sudo dhclient` (Linux)
- [ ] If static IP configured: verify correct settings for {{ location }}

### Layer 3 — Connectivity Tests

```bash
# Test gateway connectivity
ping [default-gateway-ip]

# Test internet connectivity (bypasses DNS)
ping 8.8.8.8

# Test DNS resolution
nslookup google.com
nslookup internal-server.company.com
```

- [ ] Gateway ping fails: local network / switch / VLAN issue
- [ ] 8.8.8.8 ping fails but gateway works: routing or firewall issue
- [ ] DNS fails but ping works: DNS server issue

### DNS Troubleshooting

- [ ] Check configured DNS servers: are they correct?
- [ ] Try alternative DNS temporarily: `nslookup google.com 8.8.8.8`
- [ ] Flush DNS cache: `ipconfig /flushdns` (Windows) or `sudo dscacheutil -flushcache` (macOS)
- [ ] If internal DNS only fails: check internal DNS server health

### WiFi-Specific Issues

- [ ] Check for WiFi channel congestion (many APs on same channel)
- [ ] Verify 802.1X authentication (if enterprise WiFi) — certificate valid?
- [ ] Check if MAC address filtering is blocking the device
- [ ] Test with 2.4 GHz vs 5 GHz band
- [ ] Disable VPN temporarily to rule out VPN-related WiFi issues

## Escalation Criteria

Escalate to network team if:
- Multiple users in {{ location }} affected simultaneously
- Switch, access point, or router failure suspected
- DHCP server not responding
- DNS server not responding
- VLAN or firewall configuration change needed
- Infrastructure hardware issue

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

Generate a diagnostic report with:
1. **Issue summary** (user, location, connection type, symptom)
2. **Layer-by-layer diagnostic results**
3. **Root cause** identified
4. **Resolution** applied or **escalation** details
