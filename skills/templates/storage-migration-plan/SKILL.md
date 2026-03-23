---
name: storage-migration-plan
enabled: true
description: |
  Use when performing storage migration plan — structured plan for migrating
  data between storage systems, volumes, or tiers. Covers capacity planning,
  data transfer strategy, performance benchmarking, cutover coordination, and
  validation to ensure data integrity and minimal disruption during storage
  transitions.
required_connections:
  - prefix: aws
    label: "AWS (or cloud provider)"
config_fields:
  - key: source_storage
    label: "Source Storage"
    required: true
    placeholder: "e.g., EBS gp2 volumes, on-prem NFS"
  - key: target_storage
    label: "Target Storage"
    required: true
    placeholder: "e.g., EBS gp3 volumes, EFS, S3"
  - key: data_volume
    label: "Data Volume"
    required: true
    placeholder: "e.g., 5 TB"
features:
  - DEVOPS
  - MIGRATION
---

# Storage Migration Plan Skill

Migrate **{{ data_volume }}** from **{{ source_storage }}** to **{{ target_storage }}**.

## Workflow

### Phase 1 — Storage Assessment

```
CURRENT STATE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Source: {{ source_storage }}
    - Total capacity: ___
    - Used capacity: {{ data_volume }}
    - IOPS (current): ___
    - Throughput (current): ___ MB/s
    - Latency (P95): ___ms
[ ] Target: {{ target_storage }}
    - Provisioned capacity: ___
    - IOPS (expected): ___
    - Throughput (expected): ___ MB/s
    - Latency (expected): ___ms
[ ] Data classification:
    - Hot data: ___ GB
    - Warm data: ___ GB
    - Cold data: ___ GB
[ ] File/object count: ___
```

### Phase 2 — Migration Strategy

```
STRATEGY SELECTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Transfer method (choose one):
[ ] Online copy (rsync, AWS DataSync, robocopy)
[ ] Snapshot-based (snapshot + restore)
[ ] Streaming replication
[ ] Offline transfer (AWS Snowball, physical media)

Estimated transfer time: ___
Transfer bandwidth allocated: ___ MB/s
Impact on production workload: [ ] NONE  [ ] LOW  [ ] MEDIUM

Migration order:
[ ] 1. Cold data first (lowest risk)
[ ] 2. Warm data
[ ] 3. Hot data (with cutover)
```

### Phase 3 — Data Transfer

```
TRANSFER EXECUTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Initial sync started — timestamp: ___
[ ] Progress:
    - Data transferred: ___ / {{ data_volume }}
    - Transfer rate: ___ MB/s
    - Estimated completion: ___
[ ] Incremental sync configured for delta changes
[ ] Transfer errors encountered: ___
[ ] Integrity checks during transfer:
    - Checksums validated: [ ] YES
    - File count matches: [ ] YES
```

### Phase 4 — Cutover

```
CUTOVER EXECUTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Final incremental sync completed
[ ] Application downtime window (if required): ___
[ ] Mount points / storage paths updated
[ ] Application configuration updated to target storage
[ ] Application restarted and connected to target
[ ] Read/write operations verified on target
[ ] Cutover complete — timestamp: ___
```

### Phase 5 — Validation and Cleanup

```
POST-MIGRATION VALIDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Data integrity confirmed:
    - File/object count: source ___ vs target ___
    - Total size: source ___ vs target ___
    - Checksum spot check: [ ] PASS  [ ] FAIL
[ ] Performance benchmarks met:
    - IOPS: ___  (target: ___)
    - Throughput: ___ MB/s  (target: ___)
    - Latency: ___ms  (target: ___ms)
[ ] Application performance normal
[ ] Source storage retained for ___ days (rollback window)
[ ] Source storage decommissioned — date: ___
[ ] Cost comparison: source $___ /mo vs target $___ /mo
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

Produce a storage migration report with:
1. **Migration summary** (source, target, volume, timeline)
2. **Transfer metrics** (duration, throughput, errors)
3. **Data integrity** (counts, checksums, validation results)
4. **Performance comparison** (IOPS, throughput, latency before vs after)
5. **Cost impact** (monthly cost change and projected savings)
