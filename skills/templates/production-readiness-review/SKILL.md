---
name: production-readiness-review
enabled: true
description: |
  Production readiness checklist covering scalability, reliability, observability, security, operational maturity, and documentation. Use before promoting a service to production or during periodic production-readiness audits.
required_connections:
  - prefix: github
    label: "GitHub (for repo review)"
config_fields:
  - key: service_name
    label: "Service Name"
    required: true
    placeholder: "e.g., order-service"
  - key: team
    label: "Owning Team"
    required: true
    placeholder: "e.g., platform-team"
  - key: target_date
    label: "Target Production Date"
    required: false
    placeholder: "e.g., 2026-04-01"
features:
  - DEPLOYMENT
  - SRE
---

# Production Readiness Review Skill

Evaluate production readiness for **{{ service_name }}** owned by **{{ team }}**.

## Workflow

### Step 1 — Service Overview

Gather service context:
1. **Service**: {{ service_name }}
2. **Team**: {{ team }}
3. **Target date**: {{ target_date | "TBD" }}
4. **Architecture**: [microservice / monolith / serverless / hybrid]
5. **Dependencies**: [upstream and downstream services]
6. **Expected traffic**: [requests/sec, peak patterns]

### Step 2 — Reliability & Availability

```
RELIABILITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] SLO defined (availability, latency, error rate)
[ ] Error budget policy documented
[ ] Multi-AZ or multi-region deployment
[ ] Health check endpoints implemented (liveness + readiness)
[ ] Graceful shutdown handles in-flight requests
[ ] Circuit breakers on all downstream dependencies
[ ] Retry logic with exponential backoff and jitter
[ ] Timeout configured on all outbound calls
[ ] Rate limiting on inbound requests
[ ] Load tested at 2x expected peak traffic
```

### Step 3 — Scalability

```
SCALABILITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Horizontal autoscaling configured (HPA / ASG)
[ ] Resource requests and limits set (CPU, memory)
[ ] Database connection pooling configured
[ ] Caching strategy defined and implemented
[ ] Stateless design (no local session state)
[ ] Async processing for long-running operations
[ ] Database queries optimized (no N+1, proper indexes)
[ ] CDN configured for static assets (if applicable)
```

### Step 4 — Observability

```
OBSERVABILITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Structured logging with correlation IDs
[ ] Metrics emitted: request rate, error rate, latency (RED)
[ ] Metrics emitted: utilization, saturation, errors (USE) for resources
[ ] Distributed tracing instrumented
[ ] Dashboard exists with key service metrics
[ ] Alerts configured for SLO violations
[ ] Alerts configured for resource exhaustion
[ ] Log aggregation and retention configured
[ ] On-call runbook linked in alerting tool
[ ] Dependency health visible in dashboard
```

### Step 5 — Security

```
SECURITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Authentication required on all endpoints (or explicitly public)
[ ] Authorization checks enforce least privilege
[ ] Input validation on all user-facing inputs
[ ] No secrets in code, environment variables use secrets manager
[ ] Container image scanned for vulnerabilities
[ ] Dependencies scanned for known CVEs
[ ] Network policies restrict pod-to-pod communication
[ ] TLS on all internal and external communication
[ ] Security review completed by security team
```

### Step 6 — Operational Maturity

```
OPERATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] CI/CD pipeline with automated tests
[ ] Deployment rollback procedure tested
[ ] On-call rotation assigned and staffed
[ ] Incident response runbook documented
[ ] Disaster recovery plan with tested RTO/RPO
[ ] Backup and restore procedure tested
[ ] Capacity planning reviewed for next 6 months
[ ] Feature flags for risky functionality
[ ] Canary or blue-green deployment strategy
[ ] Chaos testing performed (at least failure injection)
```

### Step 7 — Documentation

```
DOCUMENTATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Architecture diagram current
[ ] API documentation (OpenAPI / gRPC proto)
[ ] Data model and schema documentation
[ ] Runbook for common operational tasks
[ ] On-call escalation path documented
[ ] Dependency map with SLAs
[ ] Change log maintained
```

### Step 8 — Readiness Verdict

| Category | Score | Status |
|----------|-------|--------|
| Reliability | X/10 | READY / NOT READY |
| Scalability | X/8 | READY / NOT READY |
| Observability | X/10 | READY / NOT READY |
| Security | X/9 | READY / NOT READY |
| Operations | X/10 | READY / NOT READY |
| Documentation | X/7 | READY / NOT READY |

**Verdict**: APPROVED / CONDITIONAL / BLOCKED

- **APPROVED**: All categories READY (≥80% items passed)
- **CONDITIONAL**: Minor gaps with documented risk acceptance and remediation plan
- **BLOCKED**: Critical gaps that must be resolved before production

## Output Format

Produce a production readiness report with:
1. **Service overview** (name, team, architecture, dependencies)
2. **Category checklists** with PASS/FAIL per item
3. **Readiness matrix** with per-category scores
4. **Verdict** with justification
5. **Action items** for any gaps, with owner and due date
