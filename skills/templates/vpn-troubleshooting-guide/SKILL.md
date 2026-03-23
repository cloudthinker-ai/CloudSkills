---
name: vpn-troubleshooting-guide
enabled: true
description: |
  Use when performing vpn troubleshooting guide — vPN connectivity
  troubleshooting decision tree covering common VPN client issues,
  authentication failures, split tunneling problems, performance degradation,
  and DNS resolution failures. Guides helpdesk agents through systematic
  diagnosis of VPN connectivity issues for remote workers.
required_connections:
  - prefix: itsm
    label: "ITSM Tool (ServiceNow, Freshservice, etc.)"
config_fields:
  - key: user_name
    label: "Affected User Name"
    required: true
    placeholder: "e.g., Jane Smith"
  - key: vpn_client
    label: "VPN Client"
    required: true
    placeholder: "e.g., Cisco AnyConnect, GlobalProtect, OpenVPN"
  - key: symptom
    label: "Primary Symptom"
    required: true
    placeholder: "e.g., cannot connect, slow speeds, intermittent disconnects"
  - key: operating_system
    label: "Operating System"
    required: false
    placeholder: "e.g., Windows 11, macOS 14, Ubuntu 22.04"
features:
  - HELPDESK
---

# VPN Troubleshooting Guide

Troubleshooting VPN issue for **{{ user_name }}**
Client: **{{ vpn_client }}** | OS: {{ operating_system }}
Symptom: **{{ symptom }}**

## Decision Tree

```
START: What is the symptom?
│
├─ Cannot Connect at All
│  ├─ Is internet working? (can browse web?)
│  │  ├─ No → Fix internet first (see Network Troubleshooting)
│  │  └─ Yes → Continue
│  ├─ VPN client installed and up to date?
│  │  ├─ No → Install/update VPN client
│  │  └─ Yes → Continue
│  ├─ Correct VPN gateway/profile selected?
│  │  ├─ No → Configure correct gateway
│  │  └─ Yes → Continue
│  ├─ Authentication error?
│  │  ├─ Yes → See Authentication Failures below
│  │  └─ No → Continue
│  └─ Connection times out?
│     ├─ Firewall blocking? (port 443/UDP 4500) → Adjust firewall
│     └─ ISP blocking VPN? → Try different protocol/port
│
├─ Intermittent Disconnects
│  ├─ WiFi signal strength adequate?
│  ├─ Power saving disconnecting adapter?
│  ├─ VPN idle timeout configured?
│  └─ ISP stability issues?
│
├─ Slow Performance
│  ├─ Test speed without VPN vs with VPN
│  ├─ Split tunneling enabled for non-corporate traffic?
│  ├─ VPN gateway overloaded?
│  └─ Geographic distance to VPN gateway?
│
└─ Cannot Access Internal Resources (VPN connected)
   ├─ DNS resolving internal hostnames?
   ├─ Split tunneling routing correct?
   ├─ Firewall rules allowing VPN subnet?
   └─ Resource-specific access permissions?
```

## Step-by-Step Troubleshooting

### Cannot Connect — Authentication Failures
1. Verify {{ user_name }}'s AD/IdP account is not locked or disabled
2. Confirm VPN group membership is assigned
3. Check if MFA token/push is being received
4. Test credentials on another system (webmail, SSO portal)
5. If certificate-based: check certificate expiration date
6. Reset VPN-specific credentials if separate from domain credentials

### Cannot Connect — Connection Timeout
1. Check if user's ISP or network blocks VPN ports
   - Typical ports: TCP 443, UDP 500, UDP 4500, UDP 1194
2. Try connecting from a different network (mobile hotspot)
3. Verify VPN gateway is operational (check status page / monitoring)
4. Check if {{ vpn_client }} needs a profile/configuration update
5. Clear VPN client cache and reconnect

### Intermittent Disconnects
1. Check WiFi signal strength and stability
2. Disable WiFi power saving mode on {{ operating_system }}
3. Check VPN client logs for disconnect reason codes
4. Verify VPN keepalive/DPD settings
5. Test with wired ethernet connection
6. Check for conflicting VPN or firewall software

### Slow VPN Performance
1. Run speed test WITHOUT VPN: record results
2. Run speed test WITH VPN: compare results
3. If >50% speed drop:
   - Check if split tunneling is configured (should be for non-work traffic)
   - Try connecting to a closer VPN gateway
   - Check VPN gateway utilization (server-side)
4. If DNS is slow: configure DNS to use VPN DNS servers only for internal domains

### Connected but Cannot Access Resources
1. Verify VPN shows connected status with assigned IP
2. Test DNS resolution: `nslookup internal-hostname`
3. Test connectivity: `ping internal-server-ip`
4. Check routing table: `route print` (Windows) or `netstat -rn` (macOS/Linux)
5. Verify split tunnel routes include the target network
6. Check if resource requires additional authentication

## Escalation Criteria

Escalate to network/infrastructure team if:
- VPN gateway is down or overloaded
- Multiple users reporting the same issue simultaneously
- Issue persists after all client-side troubleshooting
- Certificate infrastructure issues
- Firewall rule changes needed

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

Generate a troubleshooting report with:
1. **Issue summary** (user, symptom, client, OS)
2. **Diagnostic steps taken** with results
3. **Resolution** or **escalation details**
4. **Root cause** if identified
