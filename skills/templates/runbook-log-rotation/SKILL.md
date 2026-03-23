---
name: runbook-log-rotation
enabled: true
description: |
  Use when performing runbook log rotation — log rotation and cleanup procedure
  covering disk usage check, rotation configuration, archival, and cleanup. Use
  when disk usage is high due to logs, configuring new log rotation policies, or
  performing periodic log maintenance.
required_connections: []
config_fields:
  - key: target_host
    label: "Target Host / Service"
    required: true
    placeholder: "e.g., prod-web-01, api-service pods"
  - key: log_path
    label: "Log Path(s)"
    required: true
    placeholder: "e.g., /var/log/app/, /data/logs/nginx/"
  - key: retention_days
    label: "Retention Period (days)"
    required: true
    placeholder: "e.g., 30, 90"
  - key: disk_threshold
    label: "Disk Alert Threshold"
    required: false
    placeholder: "e.g., 85%"
features:
  - RUNBOOK
  - INFRASTRUCTURE
---

# Log Rotation and Cleanup Runbook Skill

Execute log rotation on **{{ target_host }}** for **{{ log_path }}**.
Retention: **{{ retention_days }} days** | Disk threshold: **{{ disk_threshold }}**

## Workflow

### Phase 1 — Disk Usage Assessment

```
DISK USAGE ASSESSMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HOST: {{ target_host }}

CURRENT DISK STATE
  Filesystem: ___
  Total size: ___
  Used: ___ (___%)
  Available: ___
  Threshold: {{ disk_threshold }}
  Status: [OK / WARNING / CRITICAL]

LOG DIRECTORY ANALYSIS ({{ log_path }})
  Total log size: ___
  Number of log files: ___
  Oldest log file: ___ (date: ___)
  Largest log file: ___ (size: ___)
  Daily log growth rate: ___ MB/day
  Estimated days until disk full: ___

TOP SPACE CONSUMERS
  1. ___ — ___ GB
  2. ___ — ___ GB
  3. ___ — ___ GB
  4. ___ — ___ GB
  5. ___ — ___ GB
```

### Phase 2 — Rotation Configuration Review

```
ROTATION CONFIGURATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CURRENT LOGROTATE CONFIG (if exists):
  Config file: /etc/logrotate.d/___
  Rotation frequency: [daily / weekly / monthly]
  Retention count: ___ rotated files
  Compression: [enabled / disabled]
  Max size trigger: ___
  Post-rotate script: [yes / no]

RECOMMENDED CONFIGURATION:
  Path: {{ log_path }}*.log
  Rotation: daily
  Retention: {{ retention_days }} days
  Compression: enabled (gzip/zstd)
  Max size: ___ MB (rotate if exceeded between scheduled runs)
  Copytruncate: [yes — if app cannot reopen log files]
  Missingok: yes
  Notifempty: yes

[ ] Review current logrotate configuration
[ ] Identify logs NOT covered by logrotate
[ ] Check for application-level log rotation (log4j, logback, etc.)
[ ] Verify log rotation does not conflict with log shipping (fluentd, filebeat)
```

### Phase 3 — Emergency Cleanup (if disk critical)

```
EMERGENCY CLEANUP (if disk > {{ disk_threshold }})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
SAFE TO DELETE:
[ ] Compressed rotated logs older than {{ retention_days }} days
[ ] Orphaned .tmp log files
[ ] Core dumps (if not needed for investigation)
[ ] Package manager cache (apt/yum cache)

PROCEED WITH CAUTION:
[ ] Truncate active log files (> 1GB) if application supports it
    - Use truncate -s 0 (NOT rm) for active log files
    - Verify application continues logging after truncation
[ ] Compress uncompressed rotated logs

SPACE RECOVERED: ___ GB
Disk usage after cleanup: ___% (target: < {{ disk_threshold }})
```

### Phase 4 — Apply Rotation Policy

```
APPLY ROTATION POLICY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Create or update logrotate configuration file
[ ] Test configuration: logrotate -d /etc/logrotate.d/___
[ ] Execute manual rotation: logrotate -f /etc/logrotate.d/___
[ ] Verify rotation executed:
    - New rotated file created: ___
    - Compressed file created: ___
    - Old files beyond retention deleted: ___
[ ] Verify application still writing to log file
[ ] Verify log shipper (if any) handling rotation correctly
```

### Phase 5 — Archive Configuration

```
ARCHIVE CONFIGURATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
LONG-TERM ARCHIVAL (if required):
[ ] Archive destination: [S3 / GCS / Azure Blob / NFS]
[ ] Archive bucket/path: ___
[ ] Lifecycle policy: move to cold storage after ___ days
[ ] Delete from archive after ___ days
[ ] Encryption: [enabled / disabled]

ARCHIVE PROCESS:
[ ] Compress logs before archival
[ ] Upload to archive destination
[ ] Verify archive integrity (checksum)
[ ] Record archived date range: ___ to ___
[ ] Remove local copies after archive confirmation
```

### Phase 6 — Validation and Monitoring

```
VALIDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Disk usage after rotation: ___% (target: < {{ disk_threshold }})
[ ] Logrotate cron job scheduled and active
[ ] Next scheduled rotation: ___
[ ] Application logging uninterrupted
[ ] Log shipping pipeline healthy (no gaps in ingestion)
[ ] Monitoring alert set for disk usage > {{ disk_threshold }}
[ ] Monitoring alert set for log growth rate anomalies
[ ] Document rotation policy for this host/service
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

Produce a log rotation report with:
1. **Disk assessment** before and after cleanup
2. **Space recovered** from immediate cleanup actions
3. **Rotation policy** applied with configuration details
4. **Archive status** for long-term retention
5. **Validation** confirming healthy logging and disk state
6. **Monitoring** alerts configured for ongoing protection
