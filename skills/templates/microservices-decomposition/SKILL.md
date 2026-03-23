---
name: microservices-decomposition
enabled: true
description: |
  Use when performing microservices decomposition — template for analyzing
  monolithic applications and planning decomposition into microservices. Covers
  bounded context identification, domain-driven design analysis, service
  boundary definition, data ownership mapping, communication pattern selection,
  and incremental extraction strategy.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: monolith_name
    label: "Monolith Application Name"
    required: true
    placeholder: "e.g., main-platform"
  - key: target_domain
    label: "Target Domain to Extract"
    required: true
    placeholder: "e.g., order-management, user-auth"
  - key: extraction_priority
    label: "Extraction Priority"
    required: false
    placeholder: "e.g., scalability, team autonomy, deployment frequency"
features:
  - ENGINEERING
  - ARCHITECTURE
---

# Microservices Decomposition Skill

Analyze **{{ monolith_name }}** for extracting **{{ target_domain }}** as a microservice. Priority: **{{ extraction_priority }}**.

## Workflow

### Phase 1 — Domain Analysis

```
DOMAIN MAP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Bounded contexts identified in monolith:
    Context              | Coupling | Cohesion | Size
    _____________________|__________|__________|______
                         |          |          |
                         |          |          |
                         |          |          |

[ ] Target domain: {{ target_domain }}
    - Core entities: ___
    - Domain events: ___
    - Business rules: ___
    - External integrations: ___
```

### Phase 2 — Dependency Analysis

```
COUPLING ASSESSMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Inbound dependencies (other domains -> {{ target_domain }}):
    - ___: ___ calls/references
    - ___: ___ calls/references
[ ] Outbound dependencies ({{ target_domain }} -> other domains):
    - ___: ___ calls/references
    - ___: ___ calls/references
[ ] Shared database tables: ___
[ ] Shared code/libraries: ___
[ ] Circular dependencies: [ ] NONE  [ ] IDENTIFIED

COUPLING SEVERITY MATRIX
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Dependency Type     | Count | Severity  | Resolution
Database joins      |       | HIGH      | Split tables, API calls
Shared models       |       | MEDIUM    | Duplicate, sync via events
Direct function     |       | MEDIUM    | API / event interface
Shared config       |       | LOW       | Per-service config
```

### Phase 3 — Service Boundary Definition

```
SERVICE DESIGN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Service name: ___
[ ] Owned data entities:
    - ___
    - ___
[ ] API surface:
    - Endpoints: ___
    - Events published: ___
    - Events consumed: ___
[ ] Data store: ___ (separate from monolith)
[ ] Authentication/authorization model: ___
[ ] SLA requirements:
    - Availability: ___
    - Latency P95: ___ms
    - Throughput: ___ RPS
```

### Phase 4 — Communication Patterns

```
INTER-SERVICE COMMUNICATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Synchronous (request/response):
[ ] REST API
[ ] gRPC
[ ] GraphQL federation

Asynchronous (event-driven):
[ ] Message queue (SQS, RabbitMQ)
[ ] Event streaming (Kafka, EventBridge)
[ ] Pub/sub

Selected pattern: ___
Justification: ___

[ ] Data consistency strategy:
    [ ] Eventual consistency (saga pattern)
    [ ] Distributed transactions (avoid if possible)
    [ ] CQRS for read models
```

### Phase 5 — Extraction Plan

```
INCREMENTAL EXTRACTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Step 1 — Strangler Fig:
[ ] Create new service alongside monolith
[ ] Proxy/route requests to new service
[ ] Monolith retains fallback capability

Step 2 — Data Migration:
[ ] Identify data to move
[ ] Set up dual-write or CDC
[ ] Migrate historical data
[ ] Validate data consistency

Step 3 — Traffic Migration:
[ ] Route ___ % traffic to new service
[ ] Monitor error rates and latency
[ ] Gradually increase to 100%

Step 4 — Cleanup:
[ ] Remove extracted code from monolith
[ ] Remove dual-write / CDC
[ ] Update documentation
[ ] Archive migration tooling
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

Produce a decomposition analysis report with:
1. **Domain analysis** (bounded contexts, entities, relationships)
2. **Coupling assessment** (dependencies, shared resources, severity)
3. **Service design** (boundaries, API, data ownership)
4. **Communication patterns** (selected approach with rationale)
5. **Extraction plan** (phased steps with risk mitigation)
