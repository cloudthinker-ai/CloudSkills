---
name: runbook-network-partition
enabled: true
description: |
  Use when performing runbook network partition — network partition recovery
  procedure covering diagnosis, route fix, connectivity validation, and root
  cause analysis. Use when services experience network segmentation,
  intermittent connectivity, or cross-zone communication failures.
required_connections: []
config_fields:
  - key: affected_segment
    label: "Affected Network Segment"
    required: true
    placeholder: "e.g., us-east-1a private subnet, VLAN 200"
  - key: symptoms
    label: "Observed Symptoms"
    required: true
    placeholder: "e.g., timeouts between app tier and database tier"
  - key: affected_services
    label: "Affected Services"
    required: false
    placeholder: "e.g., api-gateway, payment-service"
  - key: start_time
    label: "Issue Start Time"
    required: false
    placeholder: "e.g., 2026-03-14 14:30 UTC"
features:
  - RUNBOOK
  - NETWORKING
---

# Network Partition Recovery Runbook Skill

Diagnose and recover network partition in **{{ affected_segment }}**.
Symptoms: **{{ symptoms }}** | Affected: **{{ affected_services }}**

## Workflow

### Phase 1 — Initial Diagnosis

```
INITIAL DIAGNOSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SCOPE DETERMINATION
[ ] Identify all hosts/services affected by the partition
[ ] Determine if partition is complete (no connectivity) or partial (packet loss)
[ ] Map which source->destination pairs are failing
[ ] Check if issue is unidirectional or bidirectional
[ ] Identify the network boundary where connectivity fails

CONNECTIVITY TESTS
  From: ___ To: ___ Result: [OK / FAIL / PARTIAL]
  From: ___ To: ___ Result: [OK / FAIL / PARTIAL]
  From: ___ To: ___ Result: [OK / FAIL / PARTIAL]

LAYER-BY-LAYER CHECK
[ ] Layer 2: ARP resolution working (arping)
[ ] Layer 3: IP routing correct (traceroute, ip route)
[ ] Layer 4: TCP connections establishing (telnet, nc)
[ ] Layer 7: Application-level connectivity (curl, health checks)
[ ] DNS: Name resolution working from affected hosts
```

### Phase 2 — Root Cause Investigation

```
ROOT CAUSE INVESTIGATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ROUTING
[ ] Check route tables for missing or incorrect routes
[ ] Verify default gateway reachable from affected hosts
[ ] Check for asymmetric routing issues
[ ] Review recent route table changes (cloud provider / on-prem)
[ ] Check BGP session status (if applicable)

SECURITY GROUPS / FIREWALLS
[ ] Review security group rules for recent changes
[ ] Check network ACLs for deny rules
[ ] Verify firewall rules (iptables, nftables, cloud firewall)
[ ] Check for IP blocklist entries matching affected hosts
[ ] Review WAF or DDoS protection rule changes

INFRASTRUCTURE
[ ] Check VPC peering / transit gateway status
[ ] Verify VPN tunnel status (if cross-network)
[ ] Check network interface status on affected hosts
[ ] Review cloud provider service health dashboard
[ ] Check for NIC driver issues or MTU mismatches:
    Expected MTU: ___  Actual MTU: ___

RECENT CHANGES
[ ] Infrastructure-as-code deployments in last 24h
[ ] Security group or NACL modifications
[ ] Route table changes
[ ] VPN or peering configuration changes
[ ] DNS changes
```

### Phase 3 — Route and Connectivity Fix

```
FIX APPLICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IDENTIFIED ROOT CAUSE: ___

FIX STEPS (select applicable):

ROUTING FIX:
[ ] Add/correct route: ___ via ___
[ ] Verify route propagation across all route tables
[ ] Test connectivity after route change

SECURITY GROUP / FIREWALL FIX:
[ ] Add/modify rule: allow ___ from ___ to ___ port ___
[ ] Verify rule applied (describe-security-groups / iptables -L)
[ ] Test connectivity after rule change

INFRASTRUCTURE FIX:
[ ] Restore peering connection / transit gateway attachment
[ ] Re-establish VPN tunnel
[ ] Restart network interface on affected host(s)
[ ] Fix MTU mismatch (ip link set dev ___ mtu ___)

ROLLBACK PLAN:
  If fix causes wider issues:
  [ ] Revert change: ___
  [ ] Verify original connectivity pattern restored
```

### Phase 4 — Connectivity Validation

```
CONNECTIVITY VALIDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
NETWORK TESTS (repeat initial diagnosis tests):
  From: ___ To: ___ Result: [OK / FAIL]
  From: ___ To: ___ Result: [OK / FAIL]
  From: ___ To: ___ Result: [OK / FAIL]

[ ] Packet loss rate: ___% (target: 0%)
[ ] Latency within baseline: ___ ms (baseline: ___ ms)
[ ] Traceroute path as expected (no unexpected hops)
[ ] TCP connections establishing within normal timeout
[ ] No retransmissions above baseline

APPLICATION VALIDATION
[ ] All previously affected services communicating
[ ] Health checks passing across all service pairs
[ ] Database connections re-established
[ ] Message queue consumers reconnected
[ ] API response times returned to baseline
```

### Phase 5 — Prevention and Documentation

```
PREVENTION AND DOCUMENTATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Add monitoring for the specific failure mode detected
[ ] Create alert for route table changes in affected segment
[ ] Add network connectivity smoke tests to CI/CD
[ ] Update network diagrams if topology changed
[ ] Document root cause and fix in incident report
[ ] Review change management process for network changes
[ ] Consider adding redundant network paths
[ ] Update runbook with lessons learned
```

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

Produce a network partition recovery report with:
1. **Partition summary** (segment, symptoms, scope, duration)
2. **Diagnosis results** (layer-by-layer findings)
3. **Root cause** identification with evidence
4. **Fix applied** with before/after connectivity tests
5. **Validation** results confirming full recovery
6. **Prevention measures** to avoid recurrence
