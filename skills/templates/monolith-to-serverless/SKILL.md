---
name: monolith-to-serverless
enabled: true
description: |
  Guides the decomposition of a monolithic application into serverless functions and managed services. Covers domain boundary identification, function extraction, event-driven architecture design, state management, and incremental migration using the strangler fig pattern.
required_connections:
  - prefix: cloud-provider
    label: "Cloud Provider"
config_fields:
  - key: source_language
    label: "Source Application Language"
    required: true
    placeholder: "e.g., Java, Python, Node.js, .NET"
  - key: target_serverless_platform
    label: "Target Serverless Platform"
    required: true
    placeholder: "e.g., AWS Lambda, Google Cloud Functions, Azure Functions"
  - key: current_architecture
    label: "Current Architecture Type"
    required: false
    placeholder: "e.g., MVC monolith, layered architecture"
features:
  - CLOUD_MIGRATION
  - SERVERLESS
  - ARCHITECTURE
---

# Monolith to Serverless Migration Plan

## Phase 1: Domain Analysis
1. Map the monolith's bounded contexts
   - [ ] Identify distinct business domains within the application
   - [ ] Document data ownership per domain
   - [ ] Map synchronous and asynchronous communication patterns
   - [ ] Identify shared libraries and cross-cutting concerns
2. Assess each domain for serverless suitability

### Serverless Suitability Matrix

| Domain | Stateless | Event-Driven | Short-Lived | Cold Start OK | Serverless Fit |
|--------|-----------|-------------|-------------|---------------|----------------|
|        | [ ]       | [ ]         | [ ]         | [ ]           | High/Med/Low   |

## Phase 2: Architecture Design
1. Design event-driven architecture with message broker
2. Define API Gateway routes and function mappings
3. Plan state management strategy (database per function vs. shared)
4. Design authentication and authorization flow
5. Plan for cold start mitigation (provisioned concurrency, warm-up)

### Component Mapping

| Monolith Component | Serverless Target | Trigger Type | State Store |
|-------------------|-------------------|-------------|-------------|
|                   | Function/Step Function/Container | HTTP/Event/Schedule | |

## Phase 3: Infrastructure Setup
1. Provision serverless platform and supporting services
2. Set up API Gateway with routing rules
3. Configure event bus or message queue
4. Set up databases per domain (DynamoDB, Firestore, etc.)
5. Implement shared layers/extensions for common code
6. Configure monitoring and distributed tracing

## Phase 4: Incremental Extraction (Strangler Fig)
1. Start with the lowest-risk, most independent domain
2. Extract domain logic into serverless functions
3. Route traffic through API Gateway with fallback to monolith
4. Validate behavior matches monolith
5. Repeat for each domain in priority order

## Phase 5: Data Migration
1. Migrate data from monolith database to domain-specific stores
2. Implement data synchronization during transition period
3. Handle cross-domain queries with aggregation patterns
4. Validate data consistency across services

## Phase 6: Optimization & Finalization
1. Remove extracted code from monolith
2. Optimize function memory and timeout settings
3. Implement cost monitoring per function
4. Set up auto-scaling policies
5. Decommission monolith after all domains extracted

## Output Format
- **Domain Map**: Bounded contexts with dependencies and data ownership
- **Architecture Diagram**: Serverless target architecture with event flows
- **Function Catalog**: List of all functions with triggers, inputs, outputs
- **Migration Sequence**: Ordered extraction plan with dependencies
- **Cost Projection**: Expected serverless costs vs. current infrastructure

## Action Items
- [ ] Complete domain analysis and boundary identification
- [ ] Design target serverless architecture
- [ ] Extract first domain as proof of concept
- [ ] Validate performance and cost projections
- [ ] Execute remaining domain extractions in priority order
- [ ] Decommission monolith after full migration
