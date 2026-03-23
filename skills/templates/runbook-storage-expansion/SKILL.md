---
name: runbook-storage-expansion
enabled: true
description: |
  Use when performing runbook storage expansion — storage expansion procedure
  covering capacity check, volume resize, filesystem extension, and validation.
  Use when disk usage approaches thresholds, before large data ingestion, or for
  planned storage growth.
required_connections: []
config_fields:
  - key: target_host
    label: "Target Host / Volume"
    required: true
    placeholder: "e.g., prod-db-01 /dev/xvdf"
  - key: current_size
    label: "Current Size"
    required: true
    placeholder: "e.g., 500 GB"
  - key: target_size
    label: "Target Size"
    required: true
    placeholder: "e.g., 1 TB"
  - key: filesystem_type
    label: "Filesystem Type"
    required: false
    placeholder: "e.g., ext4, xfs, gp3"
features:
  - RUNBOOK
  - INFRASTRUCTURE
---

# Storage Expansion Runbook Skill

Expand storage on **{{ target_host }}** from **{{ current_size }}** to **{{ target_size }}**.
Filesystem: **{{ filesystem_type }}**

## Workflow

### Phase 1 — Capacity Assessment

```
CAPACITY ASSESSMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CURRENT STATE
  Host: {{ target_host }}
  Volume / device: ___
  Filesystem: {{ filesystem_type }}
  Current size: {{ current_size }}
  Used space: ___ (___%)
  Available space: ___
  Inode usage: ___% (check for inode exhaustion)
  Growth rate: ___ GB/day

EXPANSION DETAILS
  Target size: {{ target_size }}
  Increase: ___ GB (___ % increase)
  Estimated runway after expansion: ___ days

PREREQUISITES
[ ] Volume type supports online resize (e.g., AWS EBS gp3, Azure managed disk)
[ ] No pending volume modifications in progress
[ ] Sufficient quota / limits for new size
[ ] Budget approval for additional storage cost: $___/month
```

### Phase 2 — Pre-Expansion Backup

```
PRE-EXPANSION BACKUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Create volume snapshot before resize
    Snapshot ID: ___
[ ] Verify snapshot completed and is usable
[ ] Record current mount options: ___
[ ] Record current fstab entry: ___
[ ] Record partition table layout (fdisk -l / lsblk)
[ ] Verify no active writes paused by snapshot (if applicable)
```

### Phase 3 — Volume Resize

```
VOLUME RESIZE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CLOUD PROVIDER RESIZE (AWS EBS / GCP PD / Azure Disk):
1. [ ] Modify volume size: {{ current_size }} -> {{ target_size }}
2. [ ] Record modification request ID: ___
3. [ ] Wait for volume state: "optimizing" -> "completed"
4. [ ] Verify new size visible in cloud console
5. [ ] Check volume modification history for errors

ON-PREMISE / LVM:
1. [ ] Add new physical volume or expand existing LUN
2. [ ] Extend volume group: vgextend
3. [ ] Extend logical volume: lvextend
4. [ ] Verify new size with lvdisplay / vgdisplay
```

### Phase 4 — Filesystem Extension

```
FILESYSTEM EXTENSION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PARTITION RESIZE (if partitioned):
1. [ ] Extend partition to use new space (growpart / parted)
2. [ ] Verify partition table updated (lsblk)

FILESYSTEM RESIZE:
  ext4:   resize2fs /dev/xxx
  xfs:    xfs_growfs /mount/point
  btrfs:  btrfs filesystem resize max /mount/point

1. [ ] Execute filesystem resize command
2. [ ] Verify new size:
    - df -h shows: ___
    - Expected: {{ target_size }} (minus filesystem overhead)
3. [ ] Verify filesystem integrity (no errors in dmesg)
4. [ ] Confirm mount options unchanged
```

### Phase 5 — Post-Expansion Validation

```
POST-EXPANSION VALIDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
STORAGE HEALTH
[ ] df -h shows correct new size
[ ] Filesystem check reports no errors
[ ] I/O performance test (dd or fio baseline):
    - Write throughput: ___ MB/s (vs. baseline: ___ MB/s)
    - Read throughput: ___ MB/s (vs. baseline: ___ MB/s)
    - IOPS: ___ (vs. baseline: ___)
[ ] No increased latency on storage operations

APPLICATION HEALTH
[ ] Application read/write operations functioning
[ ] Database (if applicable) reports correct data directory size
[ ] Log writes continuing without errors
[ ] No "disk full" alerts cleared / no new alerts

MONITORING
[ ] Disk usage alerts updated for new thresholds
[ ] Monitoring showing correct volume size
[ ] Growth rate tracking resumed
```

### Phase 6 — Cleanup

```
CLEANUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Remove pre-expansion snapshot after 48h stabilization
[ ] Update CMDB / infrastructure inventory with new size
[ ] Update capacity planning spreadsheet
[ ] Update infrastructure-as-code (Terraform, CloudFormation)
[ ] Close change management ticket
[ ] Set monitoring alert for next capacity threshold (e.g., 80%)
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

Produce a storage expansion report with:
1. **Expansion summary** (host, old size, new size, filesystem)
2. **Pre-expansion backup** confirmation with snapshot ID
3. **Resize execution** log with provider-specific details
4. **Filesystem extension** confirmation with df output
5. **Performance validation** (throughput and IOPS comparison)
6. **Updated capacity forecast** with new runway estimate
