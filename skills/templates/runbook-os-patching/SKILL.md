---
name: runbook-os-patching
enabled: true
description: |
  Use when performing runbook os patching — oS patching window procedure
  covering pre-patch backup, patch application, reboot sequence, and validation.
  Use for scheduled maintenance windows, security patch deployments, or kernel
  upgrades.
required_connections: []
config_fields:
  - key: target_hosts
    label: "Target Hosts / Group"
    required: true
    placeholder: "e.g., web-servers-prod, db-replicas-us-east"
  - key: patch_type
    label: "Patch Type"
    required: true
    placeholder: "e.g., security updates, kernel upgrade, full OS update"
  - key: maintenance_window
    label: "Maintenance Window"
    required: true
    placeholder: "e.g., 2026-03-20 02:00-06:00 UTC"
  - key: reboot_required
    label: "Reboot Required"
    required: false
    placeholder: "e.g., yes, no, conditional"
features:
  - RUNBOOK
  - INFRASTRUCTURE
---

# OS Patching Runbook Skill

Execute OS patching for **{{ target_hosts }}** during **{{ maintenance_window }}**.
Patch type: **{{ patch_type }}** | Reboot: **{{ reboot_required }}**

## Workflow

### Phase 1 — Pre-Patch Planning

```
PRE-PATCH PLANNING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HOST INVENTORY
  Target group: {{ target_hosts }}
  Total host count: ___
  OS distribution: ___
  Current kernel version: ___
  Patching order: [rolling / blue-green / all-at-once]

PATCH REVIEW
[ ] List available patches and review changelog
[ ] Identify security-critical patches (CVE numbers)
[ ] Check vendor advisories for known issues
[ ] Verify patches tested in staging/dev environment
[ ] Confirm patch compatibility with running applications
[ ] Document patches to apply:
    Package: ___ (current: ___ -> target: ___)
```

### Phase 2 — Pre-Patch Backup

```
PRE-PATCH BACKUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Create VM snapshots or AMI images of target hosts
    Snapshot IDs: ___
[ ] Verify backups completed successfully
[ ] Confirm backup restoration procedure is documented
[ ] Record current system state:
    - Uptime: ___
    - Running services: ___
    - Open connections: ___
    - Disk usage: ___%
[ ] Export current package list (dpkg --list / rpm -qa)
[ ] Save current kernel parameters (sysctl -a)
```

### Phase 3 — Rolling Patch Execution

```
PATCH EXECUTION (rolling — one batch at a time)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
FOR EACH BATCH:

PRE-PATCH
[ ] Remove host(s) from load balancer / service discovery
[ ] Drain active connections (wait for in-flight requests)
[ ] Verify host removed from traffic rotation
[ ] Stop non-essential services

APPLY PATCHES
[ ] Update package index (apt update / yum check-update)
[ ] Apply patches (apt upgrade / yum update)
[ ] Record packages updated: ___
[ ] Check for held-back packages or conflicts: ___
[ ] Resolve any dependency issues

REBOOT (if {{ reboot_required }}):
[ ] Initiate graceful reboot
[ ] Wait for host to come back online
[ ] Verify new kernel version: ___
[ ] Verify boot completed without errors (check dmesg, journal)

POST-PATCH
[ ] Verify all critical services started
[ ] Run application health checks
[ ] Re-add host to load balancer / service discovery
[ ] Confirm traffic flowing to patched host
[ ] Monitor for 10 minutes before proceeding to next batch

BATCH PROGRESS:
  Batch 1: [ ] patched [ ] validated [ ] in rotation
  Batch 2: [ ] patched [ ] validated [ ] in rotation
  Batch 3: [ ] patched [ ] validated [ ] in rotation
```

### Phase 4 — Post-Patch Validation

```
POST-PATCH VALIDATION (all hosts)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SYSTEM HEALTH
[ ] All hosts reporting healthy in monitoring
[ ] Kernel version consistent across fleet: ___
[ ] No unexpected service restarts
[ ] System logs clean (no new errors in syslog/journal)
[ ] Disk usage within normal range

APPLICATION HEALTH
[ ] All services running and passing health checks
[ ] Response times within baseline
[ ] Error rates at or below pre-patch levels
[ ] Cron jobs and scheduled tasks executing normally
[ ] SSL/TLS certificates still valid and serving

SECURITY VALIDATION
[ ] Vulnerability scan confirms patches applied
[ ] No new open ports or changed firewall rules
[ ] Security agent (if any) running and reporting
```

### Phase 5 — Rollback Procedure

```
ROLLBACK (if issues detected)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Trigger: [service failure, performance degradation, boot failure]

Steps:
1. [ ] Remove affected host from load balancer
2. [ ] Restore from snapshot: ___
3. [ ] Verify host boots with previous kernel
4. [ ] Verify services start correctly
5. [ ] Re-add host to load balancer
6. [ ] Document rollback reason for retry planning
```

### Phase 6 — Cleanup and Documentation

```
CLEANUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Remove old snapshots after stabilization period (48-72h)
[ ] Update CMDB / inventory with new OS versions
[ ] Update patching documentation and runbook
[ ] Close change management ticket
[ ] Report patching compliance status
[ ] Schedule next patching window: ___
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

Produce an OS patching execution report with:
1. **Patching summary** (hosts, patch type, window, kernel versions)
2. **Backup confirmation** with snapshot IDs
3. **Batch execution log** with per-host results
4. **Post-patch validation** results (system and application health)
5. **Issues and rollbacks** (if any occurred)
6. **Compliance status** (patched vs. total hosts)
