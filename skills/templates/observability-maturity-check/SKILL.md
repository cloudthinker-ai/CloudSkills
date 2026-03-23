---
name: observability-maturity-check
enabled: true
description: |
  Use when performing observability maturity check — evaluates an organization's
  observability maturity across the three pillars (metrics, logs, traces) plus
  alerting, dashboards, and AIOps capabilities. Identifies gaps in visibility,
  assesses signal quality, and produces a roadmap for achieving full-stack
  observability.
required_connections:
  - prefix: monitoring
    label: "Monitoring Platform"
config_fields:
  - key: monitoring_stack
    label: "Current Monitoring Stack"
    required: true
    placeholder: "e.g., Datadog, Prometheus+Grafana, New Relic, Splunk"
  - key: service_count
    label: "Number of Services in Production"
    required: true
    placeholder: "e.g., 50"
  - key: primary_concern
    label: "Primary Observability Concern"
    required: false
    placeholder: "e.g., alert fatigue, blind spots, slow troubleshooting"
features:
  - DEVOPS
  - OBSERVABILITY
  - MONITORING
---

# Observability Maturity Check

## Phase 1: Metrics Assessment
1. Evaluate metrics collection and usage
   - [ ] Infrastructure metrics (CPU, memory, disk, network)
   - [ ] Application metrics (request rate, error rate, latency - RED)
   - [ ] Business metrics (transactions, revenue, user activity)
   - [ ] Custom metrics for domain-specific KPIs
   - [ ] Metrics retention and resolution appropriate
   - [ ] Metrics naming conventions standardized
   - [ ] Service-level indicators (SLIs) derived from metrics
2. Score: 1 (Basic infra only) to 5 (Full-stack with business metrics)

### Metrics Coverage

| Layer | Coverage | Gaps | Quality |
|-------|----------|------|---------|
| Infrastructure | % of hosts/containers | | High/Med/Low |
| Application (RED) | % of services | | |
| Database | % of instances | | |
| External dependencies | % of integrations | | |
| Business KPIs | % defined | | |

## Phase 2: Logging Assessment
1. Evaluate logging practices
   - [ ] Centralized log aggregation
   - [ ] Structured logging (JSON) across all services
   - [ ] Consistent log levels (DEBUG, INFO, WARN, ERROR)
   - [ ] Request/correlation IDs in all log entries
   - [ ] PII/sensitive data redaction in logs
   - [ ] Log retention policies defined
   - [ ] Log search performance adequate
   - [ ] Log-based alerting configured
2. Score: 1 (Scattered file logs) to 5 (Centralized, structured, searchable)

## Phase 3: Distributed Tracing Assessment
1. Evaluate tracing implementation
   - [ ] Tracing instrumented across services
   - [ ] Trace propagation across service boundaries
   - [ ] Span attributes include relevant context
   - [ ] Sampling strategy defined (head, tail, adaptive)
   - [ ] Trace-to-log and trace-to-metric correlation
   - [ ] Service dependency map generated from traces
   - [ ] Trace data used in incident investigation
2. Score: 1 (No tracing) to 5 (Full distributed tracing with correlation)

### Three Pillars Coverage

| Pillar | Coverage (%) | Quality (1-5) | Tool | Key Gap |
|--------|-------------|--------------|------|---------|
| Metrics | % | | | |
| Logs | % | | | |
| Traces | % | | | |
| **Combined** | **%** | **/5** | | |

## Phase 4: Alerting Quality Assessment
1. Evaluate alerting effectiveness
   - [ ] Alerts are actionable (every alert requires human action)
   - [ ] Alert severity levels match impact
   - [ ] On-call rotation and escalation configured
   - [ ] Alert noise ratio acceptable (signal vs. noise)
   - [ ] Symptom-based alerts (not cause-based)
   - [ ] Runbooks linked to alerts
   - [ ] Alert fatigue measured and managed
   - [ ] SLO-based alerting (burn rate alerts)
2. Measure alert quality metrics

### Alert Quality Metrics

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| Alerts/week | | < | |
| Actionable alerts % | % | > 80% | |
| Alerts with runbooks % | % | 100% | |
| MTTA (time to acknowledge) | min | < 5 min | |
| False positive rate | % | < 10% | |
| Duplicate/correlated alerts | % | < 5% | |

## Phase 5: Dashboards & Visualization
1. Evaluate dashboard practices
   - [ ] Service-level dashboards for each team
   - [ ] On-call dashboard (single pane of glass)
   - [ ] SLO status dashboards
   - [ ] Infrastructure overview dashboards
   - [ ] Business metrics dashboards
   - [ ] Dashboard naming and organization standards
   - [ ] Dashboard-as-code (version controlled)
2. Assess dashboard discoverability and usefulness

## Phase 6: Advanced Capabilities
1. Evaluate advanced observability features
   - [ ] Anomaly detection (automated baseline comparison)
   - [ ] Root cause analysis automation
   - [ ] Service dependency visualization
   - [ ] Change correlation (deploy/config changes vs. incidents)
   - [ ] Continuous profiling (CPU, memory, lock)
   - [ ] Real User Monitoring (RUM) / frontend observability
   - [ ] Synthetic monitoring for critical paths
   - [ ] OpenTelemetry adoption for vendor neutrality

### Maturity Scorecard

| Dimension | Score (1-5) | Current State | Target State |
|-----------|-----------|---------------|-------------|
| Metrics | | | |
| Logging | | | |
| Tracing | | | |
| Alerting | | | |
| Dashboards | | | |
| Advanced (AI/ML) | | | |
| **Overall** | **/5** | | |

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Pillar Assessment**: Metrics, logs, traces coverage and quality
- **Alert Quality Report**: Noise analysis and improvement recommendations
- **Coverage Gaps**: Services and layers lacking observability
- **Tool Assessment**: Current stack evaluation and recommendations
- **Improvement Roadmap**: Phased plan to advance observability maturity

## Action Items
- [ ] Assess coverage across all three pillars
- [ ] Audit alert quality and reduce noise
- [ ] Implement structured logging across all services
- [ ] Roll out distributed tracing to uninstrumented services
- [ ] Standardize dashboards and make discoverable
- [ ] Evaluate and pilot advanced capabilities
- [ ] Schedule quarterly observability review
