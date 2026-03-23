---
name: dns-outage-response
enabled: true
description: |
  Use when performing dns outage response — dNS-specific incident response
  playbook covering DNS resolution failures, propagation issues, DNSSEC
  validation errors, DNS provider outages, and misconfiguration recovery.
  Provides diagnostic commands, TTL-aware recovery timelines, failover
  procedures, and DNS health verification steps.
required_connections:
  - prefix: slack
    label: "Slack (for incident coordination)"
config_fields:
  - key: affected_domain
    label: "Affected Domain"
    required: true
    placeholder: "e.g., api.example.com, *.example.com"
  - key: dns_provider
    label: "DNS Provider"
    required: false
    placeholder: "e.g., Route53, Cloudflare, NS1"
  - key: symptom
    label: "Symptom Description"
    required: true
    placeholder: "e.g., NXDOMAIN for api.example.com, slow DNS resolution"
features:
  - INCIDENT
---

# DNS Outage Response Playbook

Domain: **{{ affected_domain }}**
Provider: **{{ dns_provider }}**
Symptom: **{{ symptom }}**

## Why DNS Outages Are Critical

DNS failures are often perceived as "the internet is down" because they affect ALL services behind the domain. DNS issues are also tricky because:
- Changes propagate based on TTL (not instantly)
- Caching at multiple layers makes debugging difficult
- Impact can be regional or resolver-specific
- Recovery takes TTL time even after the fix is applied

## Phase 1 — Diagnosis (0-10 min)

### Immediate Diagnostic Commands

```bash
# Check DNS resolution from multiple resolvers
dig {{ affected_domain }} @8.8.8.8        # Google
dig {{ affected_domain }} @1.1.1.1        # Cloudflare
dig {{ affected_domain }} @9.9.9.9        # Quad9
dig {{ affected_domain }} @208.67.222.222 # OpenDNS

# Check authoritative nameservers
dig NS {{ affected_domain }}
dig {{ affected_domain }} @<authoritative-ns>

# Check for DNSSEC issues
dig {{ affected_domain }} +dnssec +cd
delv {{ affected_domain }}

# Check SOA record
dig SOA {{ affected_domain }}

# Full DNS trace
dig +trace {{ affected_domain }}

# Check specific record types
dig A {{ affected_domain }}
dig AAAA {{ affected_domain }}
dig CNAME {{ affected_domain }}
dig MX {{ affected_domain }}
```

### Common DNS Failure Modes

| Symptom | Likely Cause | Verification |
|---------|-------------|-------------|
| NXDOMAIN | Domain/record deleted, zone misconfiguration | Check zone file / DNS dashboard |
| SERVFAIL | DNSSEC validation failure, NS unreachable | `dig +dnssec`, check NS health |
| Timeout | DNS provider outage, firewall blocking | Check provider status, test from multiple locations |
| Wrong IP | Record changed, DNS hijacking | Compare with expected value, check audit logs |
| Slow resolution | Provider degradation, high TTL stale cache | Time queries, check provider metrics |
| Partial failure | Regional DNS issues, anycast routing | Test from multiple geographic locations |

### Provider Status Check
- [ ] Check {{ dns_provider }} status page
- [ ] Check {{ dns_provider }} for zone configuration changes
- [ ] Review DNS audit logs for recent changes
- [ ] Check domain registration status (expired domain?)

## Phase 2 — Containment and Mitigation

### If DNS Provider Is Down
- [ ] Switch to backup DNS provider (if configured)
- [ ] Update NS records at domain registrar (propagation: 24-48 hours)
- [ ] Consider temporary IP-based access for critical services
- [ ] Communicate expected recovery timeline based on TTL

### If Records Are Misconfigured
- [ ] Identify the incorrect change in audit logs
- [ ] Revert to correct DNS records
- [ ] Note current TTL — recovery will take up to TTL duration
- [ ] Flush DNS caches where possible

### If DNSSEC Is Broken
- [ ] Check DS records at parent zone match current DNSKEY
- [ ] Verify DNSSEC signing is functioning
- [ ] If necessary, temporarily disable DNSSEC (remove DS from parent)
- [ ] Fix DNSSEC chain of trust before re-enabling

### TTL-Aware Recovery Timeline
```
Current TTL: _____ seconds
Fix applied at: _____
Expected full propagation: _____ (fix time + TTL)
```

**Important:** Even after fixing DNS, cached stale records persist until TTL expires. Users with cached bad records will continue to experience issues.

## Phase 3 — Verification

### Verify Resolution Is Working
```bash
# Test from multiple resolvers
for ns in 8.8.8.8 1.1.1.1 9.9.9.9; do
  echo "=== Resolver: $ns ==="
  dig +short {{ affected_domain }} @$ns
done

# Verify correct response
dig {{ affected_domain }} +short
# Expected: <correct IP or CNAME>

# Check propagation globally
# Use: https://dnschecker.org or https://www.whatsmydns.net
```

### Verification Checklist
- [ ] Resolution working from Google DNS (8.8.8.8)
- [ ] Resolution working from Cloudflare DNS (1.1.1.1)
- [ ] Resolution working from ISP resolvers
- [ ] DNSSEC validation passing (if enabled)
- [ ] TTL values are correct
- [ ] All record types resolving correctly (A, AAAA, CNAME, MX)
- [ ] Application health checks passing
- [ ] Global propagation confirmed via external tools

## Phase 4 — Prevention

### DNS Resilience Measures
- [ ] Configure secondary/backup DNS provider
- [ ] Set appropriate TTL values (low enough for failover, high enough for performance)
- [ ] Monitor DNS resolution from external vantage points
- [ ] Set up alerts for DNS query failures and latency
- [ ] Implement DNS failover with health checks
- [ ] Maintain DNS runbook with current configuration details
- [ ] Use infrastructure-as-code for DNS records (version controlled)
- [ ] Implement change approval process for DNS modifications
- [ ] DNSSEC key rotation schedule documented and tested

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

