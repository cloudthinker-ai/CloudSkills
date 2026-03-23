---
name: monitoring-falco
description: |
  Use when working with Falco — falco runtime threat detection and monitoring.
  Covers rule management, alert analysis, system call monitoring, Kubernetes
  audit log analysis, custom rule creation, and output channel configuration.
  Use when investigating runtime security alerts, managing detection rules,
  analyzing suspicious activity, or auditing system call patterns.
connection_type: falco
preload: false
---

# Falco Runtime Threat Detection Skill

Monitor and analyze Falco runtime security alerts, rules, and system call events.

## MANDATORY: Discovery-First Pattern

**Always check Falco status and loaded rules before investigating alerts.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Falco Version ==="
falco --version 2>/dev/null || \
kubectl get pods -n falco -o jsonpath='{.items[0].spec.containers[0].image}' 2>/dev/null

echo ""
echo "=== Falco Service Status ==="
systemctl status falco 2>/dev/null | head -10 || \
kubectl get pods -n falco -o wide 2>/dev/null

echo ""
echo "=== Loaded Rules Files ==="
falco --list --json 2>/dev/null | jq 'length' | xargs -I{} echo "{} rules loaded" || \
ls /etc/falco/falco_rules.yaml /etc/falco/falco_rules.local.yaml /etc/falco/rules.d/*.yaml 2>/dev/null

echo ""
echo "=== Output Channels ==="
grep -E '(enabled|program|url)' /etc/falco/falco.yaml 2>/dev/null | head -15 || \
kubectl get configmap -n falco falco -o jsonpath='{.data.falco\.yaml}' 2>/dev/null | grep -E 'output' | head -10
```

## Core Helper Functions

```bash
#!/bin/bash

# Falco gRPC API (if enabled)
falco_api() {
    local endpoint="$1"
    grpcurl -plaintext localhost:5060 "falco.output.service/${endpoint}" 2>/dev/null
}

# Falco HTTP API (if web server enabled)
falco_http() {
    local endpoint="$1"
    curl -s "http://localhost:8765/${endpoint}" 2>/dev/null
}

# Parse Falco JSON logs
falco_parse_logs() {
    local log_file="${1:-/var/log/falco/falco.log}"
    jq -r 'select(.priority != null) | "\(.time)\t\(.priority)\t\(.rule)\t\(.output)"' "$log_file" 2>/dev/null
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Parse JSON log output with jq for structured analysis
- Group alerts by rule and severity for summaries
- Never dump raw syscall data -- aggregate and summarize

## Common Operations

### Alert Analysis

```bash
#!/bin/bash
LOG_FILE="${1:-/var/log/falco/falco.log}"

echo "=== Alert Summary (last 1000 events) ==="
tail -1000 "$LOG_FILE" 2>/dev/null | jq -rs '
    group_by(.priority) | map({
        priority: .[0].priority,
        count: length,
        rules: ([.[].rule] | group_by(.) | map({rule: .[0], count: length}) | sort_by(-.count)[:3])
    }) | sort_by(.priority)
' 2>/dev/null || \
kubectl logs -n falco -l app.kubernetes.io/name=falco --tail=1000 2>/dev/null | \
    jq -rs 'group_by(.priority) | map({priority: .[0].priority, count: length})' 2>/dev/null

echo ""
echo "=== Recent Critical/Warning Alerts ==="
tail -500 "$LOG_FILE" 2>/dev/null | jq -r '
    select(.priority == "Critical" or .priority == "Warning") |
    "\(.time[0:19])\t\(.priority)\t\(.rule)\t\(.output[:80])"
' | tail -15 | column -t
```

### Rule Management

```bash
#!/bin/bash
echo "=== Loaded Rules ==="
falco --list --json 2>/dev/null | jq -r '
    .[] | "\(.rule)\t\(.priority)\t\(.source)"
' | column -t | head -30

echo ""
echo "=== Custom Rules ==="
cat /etc/falco/falco_rules.local.yaml 2>/dev/null | head -40 || \
ls /etc/falco/rules.d/ 2>/dev/null

echo ""
echo "=== Disabled Rules ==="
grep -r 'enabled: false' /etc/falco/falco_rules.local.yaml /etc/falco/rules.d/ 2>/dev/null | head -10
```

### Kubernetes Audit Analysis

```bash
#!/bin/bash
echo "=== K8s Audit Alerts ==="
LOG_FILE="${1:-/var/log/falco/falco.log}"
tail -1000 "$LOG_FILE" 2>/dev/null | jq -r '
    select(.source == "k8s_audit") |
    "\(.time[0:19])\t\(.priority)\t\(.rule)\t\(.output[:60])"
' | tail -20 | column -t

echo ""
echo "=== K8s Audit Rules Triggered ==="
tail -2000 "$LOG_FILE" 2>/dev/null | jq -rs '
    [.[] | select(.source == "k8s_audit")] |
    group_by(.rule) | map({rule: .[0].rule, count: length}) |
    sort_by(-.count) | .[0:10]
' 2>/dev/null
```

### Container Activity Monitoring

```bash
#!/bin/bash
CONTAINER="${1:-}"
LOG_FILE="${2:-/var/log/falco/falco.log}"

if [ -n "$CONTAINER" ]; then
    echo "=== Alerts for Container: $CONTAINER ==="
    tail -5000 "$LOG_FILE" 2>/dev/null | jq -r "
        select(.output | contains(\"$CONTAINER\")) |
        \"\(.time[0:19])\t\(.priority)\t\(.rule)\"
    " | tail -20 | column -t
else
    echo "=== Top Alerting Containers ==="
    tail -2000 "$LOG_FILE" 2>/dev/null | jq -rs '
        [.[] | .output_fields["container.name"] // "host"] |
        group_by(.) | map({container: .[0], alerts: length}) |
        sort_by(-.alerts) | .[0:10]
    ' 2>/dev/null
fi
```

### Rule Validation and Testing

```bash
#!/bin/bash
RULES_FILE="${1:-/etc/falco/falco_rules.local.yaml}"

echo "=== Validating Rules ==="
falco --validate "$RULES_FILE" 2>&1 | tail -10

echo ""
echo "=== Dry Run (check rule loading) ==="
falco --dry-run -r "$RULES_FILE" 2>&1 | tail -10

echo ""
echo "=== Rule Syntax Check ==="
falco --list -r "$RULES_FILE" --json 2>/dev/null | jq 'length' | xargs -I{} echo "{} rules parsed successfully"
```

## Safety Rules

- **Never disable critical detection rules in production** without compensating controls
- **Rule changes require Falco restart** or SIGHUP -- coordinate with operations team
- **Alert volume** -- overly broad rules can generate noise and fill disks -- tune carefully
- **Kernel module/eBPF driver issues** can cause system instability -- test on non-production first
- **K8s audit log integration** requires API server configuration changes

## Output Format

Present results as a structured report:
```
Monitoring Falco Report
═══════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

## Anti-Hallucination Rules

1. **NEVER assume resource names** — always discover via CLI/API in Phase 1 before referencing in Phase 2.
2. **NEVER fabricate metric names or dimensions** — verify against the service documentation or `--help` output.
3. **NEVER mix CLI commands between service versions** — confirm which version/API you are targeting.
4. **ALWAYS use the discovery → verify → analyze chain** — every resource referenced must have been discovered first.
5. **ALWAYS handle empty results gracefully** — an empty response is valid data, not an error to retry.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

## Common Pitfalls

- **Driver compatibility**: Falco kernel module must match kernel version -- use eBPF driver for better compatibility
- **High alert volume**: Default rules generate many alerts -- prioritize and tune before production use
- **Log rotation**: Falco logs can grow rapidly -- configure log rotation to prevent disk exhaustion
- **Dropped events**: Under high syscall load, events can be dropped -- monitor `falco.drops` metrics
- **Rule ordering**: Rules are evaluated in order -- later rules with same condition can override earlier ones
- **Macro dependencies**: Custom rules depending on default macros break when Falco upgrades change macros
- **Container runtime**: Falco needs CRI socket access -- misconfigured socket path causes missing container metadata
- **Output throttling**: High-frequency rules can overwhelm output channels -- use rate limiting in output config
