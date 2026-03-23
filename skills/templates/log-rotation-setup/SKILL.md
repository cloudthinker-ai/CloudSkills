---
name: log-rotation-setup
enabled: true
description: |
  Use when performing log rotation setup — template for configuring and
  validating log rotation policies across services and infrastructure. Covers
  log volume assessment, rotation strategy selection, retention policy
  configuration, compression settings, and monitoring to prevent disk exhaustion
  and ensure compliance with retention requirements.
required_connections:
  - prefix: aws
    label: "AWS (or cloud provider)"
config_fields:
  - key: service_name
    label: "Service Name"
    required: true
    placeholder: "e.g., payment-api"
  - key: log_path
    label: "Log File Path"
    required: true
    placeholder: "e.g., /var/log/payment-api/"
  - key: retention_days
    label: "Retention Period (days)"
    required: true
    placeholder: "e.g., 90"
features:
  - DEVOPS
  - OBSERVABILITY
---

# Log Rotation Setup Skill

Configure log rotation for **{{ service_name }}** at **{{ log_path }}** with **{{ retention_days }}-day** retention.

## Workflow

### Phase 1 — Log Volume Assessment

```
CURRENT STATE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Log files identified:
    - Path: {{ log_path }}
    - Current total size: ___ GB
    - Daily growth rate: ___ MB/day
    - Projected 30-day volume: ___ GB
[ ] Log format: [ ] JSON  [ ] Plain text  [ ] Structured
[ ] Log levels in use: [ ] DEBUG  [ ] INFO  [ ] WARN  [ ] ERROR
[ ] Disk capacity at log path: ___ GB total, ___ GB available
[ ] Disk usage alert threshold: ___%
```

### Phase 2 — Rotation Strategy

```
ROTATION CONFIGURATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Rotation trigger (choose one):
[ ] Size-based: rotate at ___ MB
[ ] Time-based: rotate every ___ hours
[ ] Hybrid: rotate at ___ MB or ___ hours, whichever first

Compression:
[ ] Enable gzip compression for rotated files
[ ] Estimated compression ratio: ___:1
[ ] Compressed retention size estimate: ___ GB

Naming convention:
[ ] {{ service_name }}.log.YYYYMMDD.gz
[ ] {{ service_name }}.log.N.gz (numbered)

Retention:
[ ] Keep rotated files for {{ retention_days }} days
[ ] Archive to cold storage after ___ days (optional)
[ ] Delete after {{ retention_days }} days
```

### Phase 3 — Implementation

```
SETUP CHECKLIST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Logrotate config file created/updated:
    - Path: /etc/logrotate.d/{{ service_name }}
[ ] Configuration validated (logrotate -d)
[ ] Test rotation executed (logrotate -f)
[ ] Service handles log file rotation gracefully:
    [ ] copytruncate (for services that hold file handles)
    [ ] create (for services that reopen log files)
    [ ] postrotate signal configured (e.g., SIGHUP)
[ ] Permissions correct on rotated files
[ ] SELinux/AppArmor context preserved (if applicable)
```

### Phase 4 — Monitoring and Alerting

```
MONITORING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Disk usage alert configured (threshold: ___%)
[ ] Log rotation failure alert configured
[ ] Log volume anomaly detection enabled
[ ] Dashboard created showing:
    - Daily log volume trend
    - Disk usage at log path
    - Rotation execution history
[ ] Compliance verification:
    - Retention meets {{ retention_days }}-day requirement
    - No PII in logs past retention window
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

Produce a log rotation configuration report with:
1. **Service summary** (name, log path, volume metrics)
2. **Rotation policy** (trigger, compression, retention settings)
3. **Implementation details** (config file, rotation method)
4. **Monitoring setup** (alerts, dashboards, compliance status)
5. **Capacity projection** (storage needs over 6 and 12 months)
