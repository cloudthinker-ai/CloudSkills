# Rationalization Table (REFACTOR Phase)

Track common rationalizations (excuses agents use to skip best practices) and their counters. When a new rationalization is discovered during compliance verification, add it here and update the relevant skill's `## Counter-Rationalizations` section.

---

## Universal Rationalizations

These appear across many skills and should be countered in every skill.

| # | Rationalization | Counter | Affected Skills |
|---|----------------|---------|----------------|
| U1 | "I'll check that later" | Check it now — deferred checks are forgotten | All discovery skills |
| U2 | "The user only asked for X" | Always include discovery phase — missing context leads to wrong conclusions | All connection skills |
| U3 | "This is a quick check, no need for structure" | Structured output prevents missed findings | All skills |
| U4 | "The defaults are fine" | Audit defaults explicitly — they often leave logging/security disabled | All infrastructure skills |
| U5 | "I don't have access to that" | Try the command first — report permission errors, don't assume | All skills |

---

## AWS-Specific Rationalizations

| # | Rationalization | Counter | Affected Skills |
|---|----------------|---------|----------------|
| A1 | "REST and HTTP APIs work the same way" | They use different CLI commands, metrics, and features — never mix | aws-api-gateway |
| A2 | "CloudWatch metrics aren't necessary for a health check" | Metrics reveal silent failures invisible to API calls | All AWS skills |
| A3 | "I'll just check one region" | Multi-region discovery is required unless user specifies a region | All AWS skills |
| A4 | "The API is responding, so it's healthy" | Response ≠ healthy — check error rates, latency percentiles, and throttling | aws-api-gateway |

---

## Incident Response Rationalizations

| # | Rationalization | Counter | Affected Skills |
|---|----------------|---------|----------------|
| I1 | "Skip triage, we know what's wrong" | Triage reveals blast radius — you can't mitigate what you haven't measured | incident-response-runbook |
| I2 | "Just restart the service" | Restart masks root cause and may cause data loss — investigate first | incident-response-runbook |
| I3 | "We don't need an IC for this" | Every incident needs a single decision-maker to avoid conflicting actions | incident-response-runbook |
| I4 | "Post-mortem can wait" | Schedule within 48h — details fade quickly | incident-response-runbook |
| I5 | "This is only SEV3, don't need the full process" | Adapt the process, don't skip it — SEV3s become SEV1s when unmanaged | incident-response-runbook |

---

## Database Rationalizations

| # | Rationalization | Counter | Affected Skills |
|---|----------------|---------|----------------|
| D1 | "SELECT 1 confirms the database is healthy" | SELECT 1 only confirms connectivity — check replication, vacuum, bloat, connections | All database skills |
| D2 | "I know the database name" | Discover instances via cloud API first — names change, instances are added | All database skills |
| D3 | "Read replicas don't need monitoring" | Replication lag is a critical metric — stale reads cause silent data issues | All database skills |

---

## Kubernetes Rationalizations

| # | Rationalization | Counter | Affected Skills |
|---|----------------|---------|----------------|
| K1 | "Just delete the crashing pod" | Investigate first — deletion hides crash logs and restarts the same broken code | All k8s skills |
| K2 | "I'll check the default namespace" | Discover all namespaces — production workloads are rarely in default | All k8s skills |
| K3 | "Node health isn't relevant to pod crashes" | Node pressure (memory, disk, PID) causes evictions that look like app crashes | All k8s skills |

---

## Meta-Rationalizations

Rationalizations about the testing/quality process itself.

| # | Rationalization | Counter |
|---|----------------|---------|
| M1 | "Testing is overkill for a skill" | Untested skills produce inconsistent behavior — TDD catches regressions |
| M2 | "Counter-rationalizations are too prescriptive" | Without them, agents consistently find creative ways to skip best practices |
| M3 | "500 lines is too restrictive" | Token efficiency directly impacts response quality — use progressive disclosure |
| M4 | "Users don't need structured output" | Structured output is scannable, comparable across runs, and parseable by tooling |
