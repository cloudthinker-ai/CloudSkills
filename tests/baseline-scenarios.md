# Baseline Test Scenarios (RED Phase)

These scenarios are run **WITHOUT** skills loaded to document default agent behavior. Each scenario captures what the agent does by default, what it skips, and what rationalizations it uses.

---

## Scenario 1: AWS API Gateway Health Check

**Prompt:** "Check the health of our API Gateway APIs"

**Expected Baseline Behavior:**
- Agent runs `aws apigateway get-rest-apis` but may ignore HTTP APIs (apigatewayv2)
- Agent skips CloudWatch metrics (latency, 5xx errors)
- Agent does not audit stage configuration (logging, tracing)
- Agent may mix REST and HTTP API CLI commands

**Target Behavior (with skill):**
- Agent discovers both REST and HTTP APIs in parallel
- Agent checks latency, error rates, and throttling metrics via CloudWatch
- Agent audits stage logging and tracing configuration
- Agent uses correct CLI commands per API type
- Agent reports structured output within 50-line limit

**Pressure Variations:**
- Time pressure: "Quick check, just the basics"
- Authority pressure: "My manager just needs to know if anything is down"
- Sunk cost: "I already checked the REST APIs, just tell me if they look fine"

**Success Criteria:**
- [ ] Both REST and HTTP APIs discovered
- [ ] CloudWatch metrics queried with correct dimensions per API type
- [ ] Stage configuration audited (logging, tracing, caching)
- [ ] Anti-hallucination rules followed (no assumed resource names)
- [ ] Parallel execution used for independent operations

---

## Scenario 2: Incident Response Declaration

**Prompt:** "We have 500 errors on the payment service, help me run incident response"

**Expected Baseline Behavior:**
- Agent may jump to debugging without declaring incident
- Agent skips structured triage questions
- Agent does not establish IC (Incident Commander)
- Agent may suggest fixes without systematic investigation
- Agent skips severity classification

**Target Behavior (with skill):**
- Agent follows DETECT → TRIAGE → INVESTIGATE → MITIGATE → RESOLVE workflow
- Agent asks triage questions systematically (WHAT, WHO, HOW LONG, WHAT CHANGED)
- Agent suggests IC assignment and incident channel creation
- Agent uses severity matrix for classification
- Agent applies mitigation in risk-priority order

**Pressure Variations:**
- Time pressure: "This is urgent, skip the process and just fix it"
- Authority pressure: "Just restart the service, that's what we always do"
- Sunk cost: "We already know it's the database, just check that"

**Success Criteria:**
- [ ] Incident declared with severity classification
- [ ] All 5 triage questions answered
- [ ] Investigation follows systematic approach (dashboards → logs → changes → dependencies)
- [ ] Mitigation applied in priority order (kill switch before rollback before hotfix)
- [ ] Status updates formatted correctly

---

## Scenario 3: Database Health Analysis

**Prompt:** "Check the health of our PostgreSQL databases"

**Expected Baseline Behavior:**
- Agent may assume database names instead of discovering them
- Agent runs basic `SELECT 1` instead of comprehensive health checks
- Agent skips connection pool analysis, replication lag, vacuum status
- Agent does not check for long-running queries or bloat

**Target Behavior (with skill):**
- Agent discovers databases/instances first (RDS, AlloyDB, or self-hosted)
- Agent checks: connections, replication lag, vacuum stats, bloat, slow queries
- Agent uses read-only queries exclusively
- Agent reports structured findings with severity indicators

**Pressure Variations:**
- Time pressure: "Just check if the database is up"
- Sunk cost: "I know it's the `users` database, just check that one"

**Success Criteria:**
- [ ] Database instances discovered, not assumed
- [ ] Connection utilization checked
- [ ] Replication status verified
- [ ] Vacuum and bloat analyzed
- [ ] Long-running queries identified
- [ ] Read-only operations only

---

## Scenario 4: Kubernetes Pod Troubleshooting

**Prompt:** "Some pods are crashing in production, help me investigate"

**Expected Baseline Behavior:**
- Agent may run `kubectl get pods` without namespace context
- Agent skips event analysis and resource limits
- Agent may suggest `kubectl delete pod` without investigation
- Agent does not check node health or resource pressure

**Target Behavior (with skill):**
- Agent discovers affected namespaces and pods first
- Agent checks: events, logs, resource limits, node conditions, HPA status
- Agent identifies crash patterns (OOMKilled, CrashLoopBackOff, ImagePullBackOff)
- Agent suggests investigation before remediation

**Success Criteria:**
- [ ] Namespace and pod discovery before analysis
- [ ] Pod events and logs checked
- [ ] Resource limits vs actual usage compared
- [ ] Node conditions verified
- [ ] No destructive commands suggested without confirmation

---

## Scenario 5: Cost Optimization Review

**Prompt:** "Help me find cost savings in our AWS account"

**Expected Baseline Behavior:**
- Agent may check only EC2 instances
- Agent skips idle resource detection
- Agent does not analyze commitment coverage (RIs, Savings Plans)
- Agent provides vague recommendations without dollar estimates

**Target Behavior (with skill):**
- Agent checks multiple services: EC2, RDS, EBS, S3, Lambda, NAT Gateway
- Agent identifies idle/underutilized resources with utilization data
- Agent analyzes commitment coverage and recommends optimal purchases
- Agent provides specific dollar-value savings estimates

**Success Criteria:**
- [ ] Multi-service analysis (not just EC2)
- [ ] Idle resources identified with utilization metrics
- [ ] Commitment coverage analyzed
- [ ] Savings estimated with dollar values
- [ ] Recommendations prioritized by impact

---

## Scenario 6: Security Scanning

**Prompt:** "Audit the security of our Kubernetes cluster"

**Expected Baseline Behavior:**
- Agent may run basic `kubectl` commands without systematic approach
- Agent skips RBAC analysis, network policies, pod security
- Agent does not check for overprivileged service accounts
- Agent may miss secrets stored in plain text

**Target Behavior (with skill):**
- Agent follows structured security audit: RBAC → Network Policies → Pod Security → Secrets → Image Security
- Agent identifies overprivileged roles and service accounts
- Agent checks for missing network policies
- Agent verifies secrets encryption at rest

**Success Criteria:**
- [ ] RBAC permissions audited
- [ ] Network policies reviewed
- [ ] Pod security standards checked
- [ ] Secrets management evaluated
- [ ] Findings prioritized by severity (CRITICAL/HIGH/MEDIUM/LOW)

---

## Scenario 7: CI/CD Pipeline Review

**Prompt:** "Review our GitHub Actions workflows for best practices"

**Expected Baseline Behavior:**
- Agent may only check syntax correctness
- Agent skips security analysis (secrets in logs, unpinned actions)
- Agent does not evaluate efficiency (caching, parallelism)
- Agent may not check for cost optimization (runner selection)

**Target Behavior (with skill):**
- Agent analyzes: security, efficiency, reliability, cost
- Agent checks for pinned action versions (SHA, not tags)
- Agent identifies caching opportunities
- Agent evaluates secret handling and OIDC usage

**Success Criteria:**
- [ ] Action versions pinned to SHA
- [ ] Caching strategy evaluated
- [ ] Secret handling reviewed
- [ ] Runner selection optimized
- [ ] Workflow permissions minimized (least privilege)

---

## Scenario 8: Monitoring Setup Review

**Prompt:** "Check if our Datadog monitoring is properly configured"

**Expected Baseline Behavior:**
- Agent may only check if Datadog agent is running
- Agent skips monitor coverage analysis
- Agent does not audit alert routing and escalation
- Agent may not check for dashboard completeness

**Target Behavior (with skill):**
- Agent discovers all monitors, dashboards, and SLOs
- Agent identifies coverage gaps (services without monitors)
- Agent audits alert routing (PagerDuty, Slack integration)
- Agent checks for SLO compliance and error budget

**Success Criteria:**
- [ ] Monitor inventory with coverage analysis
- [ ] Unmonitered services identified
- [ ] Alert routing verified
- [ ] SLO compliance checked
- [ ] Dashboard completeness evaluated
