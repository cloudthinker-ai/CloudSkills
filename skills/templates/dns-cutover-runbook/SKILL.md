---
name: dns-cutover-runbook
enabled: true
description: |
  DNS cutover procedure covering pre-checks, TTL reduction, cutover execution, validation, and rollback. Use for domain migrations, CDN changes, load balancer swaps, or any DNS-dependent infrastructure transition.
required_connections:
  - prefix: aws
    label: "AWS Route53 (or DNS provider)"
config_fields:
  - key: domain
    label: "Domain / Record"
    required: true
    placeholder: "e.g., api.example.com"
  - key: old_target
    label: "Current Target"
    required: true
    placeholder: "e.g., old-alb-1234.us-east-1.elb.amazonaws.com"
  - key: new_target
    label: "New Target"
    required: true
    placeholder: "e.g., new-alb-5678.us-east-1.elb.amazonaws.com"
  - key: record_type
    label: "Record Type"
    required: false
    placeholder: "e.g., A, CNAME, ALIAS"
features:
  - DEPLOYMENT
  - NETWORKING
---

# DNS Cutover Runbook Skill

Execute DNS cutover for **{{ domain }}** from **{{ old_target }}** to **{{ new_target }}**.

## Workflow

### Step 1 — Pre-Cutover Checklist

```
PRE-CUTOVER CHECKS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
RECORD DETAILS
  Domain: {{ domain }}
  Type: {{ record_type | "CNAME" }}
  Current target: {{ old_target }}
  New target: {{ new_target }}
  Current TTL: ___ seconds

NEW TARGET VALIDATION
[ ] New target is reachable and responding
[ ] Health checks passing on new target
[ ] SSL certificate valid for {{ domain }} on new target
[ ] Application responses correct (test with Host header override)
[ ] Performance baseline captured on new target
[ ] Load test completed against new target (if applicable)

DEPENDENCIES
[ ] All services pointing to {{ domain }} identified
[ ] Internal DNS caches / hard-coded references audited
[ ] CDN or proxy configurations reviewed
[ ] Third-party integrations using {{ domain }} notified
[ ] Monitoring configured for both old and new targets
```

### Step 2 — TTL Reduction (T-24h to T-48h)

```
TTL REDUCTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Reduce TTL to 60 seconds (from current value)
[ ] Wait for old TTL to expire (at least 1x old TTL duration)
[ ] Verify low TTL is propagated:
    - dig {{ domain }} (check TTL in response)
    - Test from multiple DNS resolvers (Google 8.8.8.8, Cloudflare 1.1.1.1)
[ ] Confirm TTL reduction has been live for ≥ old TTL duration
[ ] Document original TTL for restoration: ___ seconds
```

### Step 3 — Cutover Execution

```
CUTOVER (T-0)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PRE-FLIGHT
[ ] Confirm change window with stakeholders
[ ] On-call engineer standing by
[ ] Monitoring dashboards open (both targets)
[ ] Rollback command prepared and ready

EXECUTE
[ ] Update DNS record: {{ domain }} -> {{ new_target }}
[ ] Record exact timestamp of change: ___
[ ] Verify change in DNS provider console

PROPAGATION MONITORING
[ ] Verify via dig (authoritative nameserver): ___
[ ] Verify via Google DNS (8.8.8.8): ___
[ ] Verify via Cloudflare DNS (1.1.1.1): ___
[ ] Verify via local resolver: ___
[ ] Full propagation confirmed at: ___
```

### Step 4 — Post-Cutover Validation

```
POST-CUTOVER VALIDATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
HEALTH (check at T+5min, T+15min, T+1h)
[ ] Application responding correctly via {{ domain }}
[ ] SSL certificate valid (no mixed content or cert errors)
[ ] HTTP status codes normal (no increase in 4xx/5xx)
[ ] Response times within baseline
[ ] No increase in error rates

TRAFFIC
[ ] Traffic arriving at new target (visible in metrics)
[ ] Traffic draining from old target
[ ] No split-brain (requests not bouncing between targets)

FUNCTIONALITY
[ ] Key user journeys tested (login, checkout, API calls)
[ ] Webhooks and callbacks resolving to new target
[ ] Email deliverability unaffected (MX records if changed)
```

### Step 5 — Rollback Procedure

```
ROLLBACK (if issues detected)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Trigger: [error rate >X%, latency >Xms, functionality broken]
Window: Rollback effective within ~60 seconds (low TTL)

Steps:
1. [ ] Revert DNS record: {{ domain }} -> {{ old_target }}
2. [ ] Verify revert in DNS provider console
3. [ ] Confirm propagation via dig queries
4. [ ] Verify traffic returning to old target
5. [ ] Confirm application health on old target
6. [ ] Notify stakeholders of rollback
7. [ ] Document failure reason for retry planning
```

### Step 6 — Stabilization & Cleanup

```
STABILIZATION (T+1h to T+48h)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Monitor for 24-48 hours for late-propagating DNS caches
[ ] Increase TTL back to original value: ___ seconds
[ ] Verify no traffic reaching old target (after 48h)
[ ] Decommission old target (or schedule decommission)
[ ] Update documentation with new target details
[ ] Remove temporary monitoring for old target
[ ] Update infrastructure-as-code with new DNS records
[ ] Close change management ticket
```

## Output Format

Produce a DNS cutover execution report with:
1. **Cutover summary** (domain, old target, new target, timestamps)
2. **Pre-cutover validation** results
3. **Propagation tracking** with resolver-by-resolver confirmation
4. **Post-cutover health** metrics comparison
5. **Issues and resolution** (or rollback details if rolled back)
