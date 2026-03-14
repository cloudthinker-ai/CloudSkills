---
name: network-partition-recovery
enabled: true
description: |
  Runbook for diagnosing and recovering from network partition events across distributed systems. Covers partition detection, impact assessment, split-brain resolution, data reconciliation, connectivity restoration, and post-recovery validation to restore full cluster consistency.
required_connections:
  - prefix: aws
    label: "AWS (or cloud provider)"
  - prefix: datadog
    label: "Datadog (or monitoring tool)"
config_fields:
  - key: affected_systems
    label: "Affected Systems"
    required: true
    placeholder: "e.g., us-east-1 cluster, payment-service"
  - key: partition_type
    label: "Partition Type"
    required: true
    placeholder: "e.g., AZ isolation, region split, service mesh failure"
features:
  - DEVOPS
  - INCIDENT_RESPONSE
---

# Network Partition Recovery Skill

Recover from **{{ partition_type }}** affecting **{{ affected_systems }}**.

## Workflow

### Phase 1 — Partition Detection and Scoping

```
PARTITION ASSESSMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Partition detected — timestamp: ___
[ ] Affected systems: {{ affected_systems }}
[ ] Partition type: {{ partition_type }}
[ ] Scope:
    - Nodes/services on side A: ___
    - Nodes/services on side B: ___
    - Fully isolated nodes: ___
[ ] Impact assessment:
    - Services degraded: ___
    - Services fully unavailable: ___
    - Users affected (estimated): ___
```

### Phase 2 — Split-Brain Assessment

```
SPLIT-BRAIN CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Determine if split-brain has occurred:
    - Multiple leaders elected: [ ] YES  [ ] NO
    - Divergent writes detected: [ ] YES  [ ] NO
    - Quorum status:
      Side A: ___ nodes (quorum: [ ] YES  [ ] NO)
      Side B: ___ nodes (quorum: [ ] YES  [ ] NO)

DECISION MATRIX
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Scenario              | Action
No split-brain        | Restore connectivity, verify
Split-brain, one side | Fence minority side, restore
  has quorum          |
Split-brain, no       | Manual intervention, pick
  quorum either side  | canonical side
Divergent writes      | Data reconciliation required
```

### Phase 3 — Connectivity Restoration

```
NETWORK RECOVERY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Root cause identified:
    [ ] Security group / firewall change
    [ ] Route table misconfiguration
    [ ] VPN/peering connection failure
    [ ] Physical network issue
    [ ] Service mesh / overlay network failure
[ ] Fix applied — timestamp: ___
[ ] Connectivity verified (ping, traceroute, TCP checks):
    - Side A -> Side B: [ ] OK
    - Side B -> Side A: [ ] OK
    - Latency restored to baseline: [ ] YES
```

### Phase 4 — Data Reconciliation

```
DATA RECONCILIATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Identify divergent data (if split-brain occurred):
    - Conflicting records: ___
    - Conflict resolution strategy:
      [ ] Timestamp-based (last write wins)
      [ ] Application-specific merge
      [ ] Manual review required
[ ] Reconciliation executed — timestamp: ___
[ ] Data consistency verified across all nodes
[ ] Replication caught up and healthy
```

### Phase 5 — Post-Recovery Validation

```
VALIDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] All services healthy and serving traffic
[ ] Cluster membership correct (all nodes visible)
[ ] No remaining network errors in logs
[ ] Metrics returned to baseline:
    - Error rate: ___% (baseline: ___%)
    - Latency: ___ms (baseline: ___ms)
[ ] Monitoring alerts cleared
[ ] Incident timeline documented
[ ] Preventive measures identified:
    - ___
    - ___
```

## Output Format

Produce a partition recovery report with:
1. **Incident summary** (partition type, scope, duration)
2. **Split-brain analysis** (whether divergence occurred, resolution)
3. **Root cause** (what caused the partition)
4. **Data reconciliation** (conflicts found and how resolved)
5. **Preventive measures** (changes to prevent recurrence)
