# Severity-Specific Playbooks

## SEV1 — Critical (All-Hands)

**Criteria:** >25% users affected, revenue-impacting, data loss risk, security breach

### Response Timeline
| Time | Action |
|------|--------|
| 0 min | Declare incident, page all-hands, open bridge |
| 5 min | IC confirmed, triage started, status page updated |
| 15 min | First status update, blast radius quantified |
| 30 min | Mitigation in progress or escalation triggered |
| Every 15 min | Status updates to stakeholders |
| Resolution + 24h | Post-mortem scheduled |
| Resolution + 48h | Post-mortem document completed |

### Escalation Matrix
```
5 min — Primary on-call not responding → Page secondary
10 min — No IC assigned → Engineering manager becomes IC
15 min — Root cause unknown → Page team leads for affected services
30 min — No mitigation path → Escalate to VP Engineering
60 min — Still unresolved → Executive notification
```

### Communication Channels
- **Incident bridge:** Dedicated Slack channel + video call
- **Status page:** Update every 15 minutes
- **Customer success:** Notify immediately for customer-facing impact
- **Executive team:** Notify within 30 minutes
- **External comms:** Prepare statement if customer-facing >1 hour

---

## SEV2 — High (Team Response)

**Criteria:** 5-25% users affected, degraded experience, no data loss

### Response Timeline
| Time | Action |
|------|--------|
| 0 min | Declare incident, page primary on-call |
| 15 min | IC confirmed, triage complete |
| 30 min | Investigation findings shared |
| 60 min | Mitigation applied or escalate to SEV1 |
| Every 30 min | Status updates |
| Resolution + 48h | Post-mortem completed |

### Escalation Triggers (SEV2 → SEV1)
- Impact increases beyond 25% users
- Duration exceeds 1 hour without mitigation path
- Data integrity concerns discovered
- Customer-reported impact increases

---

## SEV3 — Medium (Individual Response)

**Criteria:** <5% users affected, minor degradation, workaround available

### Response Timeline
| Time | Action |
|------|--------|
| 0 min | Create incident ticket |
| 1 hour | Initial investigation |
| 4 hours | Root cause identified or escalate |
| Business hours | Fix deployed |
| 1 week | Brief post-incident review |

### Escalation Triggers (SEV3 → SEV2)
- Impact increases beyond 5% users
- No workaround available
- Duration exceeds 4 hours

---

## SEV4 — Low (Tracked)

**Criteria:** No user impact, monitoring/infrastructure issue, potential future risk

### Response
- Create ticket in backlog
- Assign to relevant team
- Fix within current sprint if quick, else prioritize
- No post-mortem required (but root cause should be documented in ticket)

---

## Investigation Runbooks by Symptom

### High Error Rate (5xx)
```
1. Check recent deployments (last 2h)
   → If deployment found: compare error rate before/after
   → If correlation: rollback is fastest mitigation

2. Check dependency health
   → Database: connection count, replication lag, slow queries
   → Cache: hit rate, eviction rate, memory pressure
   → External APIs: status pages, response times

3. Check resource utilization
   → CPU > 80%: scale up/out
   → Memory > 90%: check for leaks, OOM kills
   → Disk > 90%: clear logs, expand volume
   → Connections exhausted: check pool config

4. Check for traffic anomaly
   → Sudden spike: DDoS? Viral content? Bot traffic?
   → Geographic shift: CDN or DNS issue?
```

### High Latency
```
1. Identify latency source
   → Application: profiling, slow query log
   → Network: traceroute, DNS resolution time
   → Database: query explain plans, lock contention
   → External: third-party API response times

2. Check for resource contention
   → Thread pool exhaustion
   → Connection pool saturation
   → Lock contention (DB, distributed locks)
   → Garbage collection pressure

3. Check for capacity issues
   → HPA at max replicas
   → Node resource pressure
   → Load balancer connection limits
```

### Data Inconsistency
```
1. STOP — Do not attempt automated fixes
2. Identify scope: which records, which time window
3. Check replication lag across all replicas
4. Check for recent schema changes or migrations
5. Check for race conditions in recent code changes
6. Preserve evidence: take snapshots before any remediation
7. Engage database team for recovery plan
```

---

## Post-Mortem Question Bank

Use these to ensure thorough post-mortems:

### Detection
- How was the incident detected? (monitoring, customer report, internal discovery)
- How long between incident start and detection?
- Could we have detected it earlier? How?

### Response
- How long between detection and IC assignment?
- Was the right team engaged? Were there unnecessary escalations?
- Did communication flow effectively?

### Mitigation
- Was the mitigation appropriate for the severity?
- Could we have mitigated faster? What blocked us?
- Did the mitigation introduce any new risks?

### Prevention
- What systemic changes would prevent recurrence?
- Are there similar systems that could have the same issue?
- What monitoring gaps were revealed?
