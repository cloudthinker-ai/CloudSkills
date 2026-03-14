---
name: legacy-api-modernization
enabled: true
description: |
  Guides the modernization of legacy APIs (SOAP, XML-RPC, proprietary protocols) to modern RESTful or GraphQL interfaces. Covers API discovery, contract analysis, versioning strategy, backward compatibility, consumer migration, and deprecation planning.
required_connections:
  - prefix: api-gateway
    label: "API Gateway"
config_fields:
  - key: legacy_api_type
    label: "Legacy API Type"
    required: true
    placeholder: "e.g., SOAP, XML-RPC, proprietary REST"
  - key: target_api_style
    label: "Target API Style"
    required: true
    placeholder: "e.g., REST, GraphQL, gRPC"
  - key: consumer_count
    label: "Number of API Consumers"
    required: false
    placeholder: "e.g., 15"
features:
  - CLOUD_MIGRATION
  - API
  - MODERNIZATION
---

# Legacy API Modernization Plan

## Phase 1: API Discovery & Analysis
1. Catalog all legacy API endpoints
   - [ ] Endpoint URLs and methods
   - [ ] Request/response schemas (WSDL, XSD, etc.)
   - [ ] Authentication mechanisms
   - [ ] Rate limits and SLAs
   - [ ] Error handling patterns
2. Identify all API consumers and their usage patterns
3. Document business logic embedded in API layer
4. Measure current traffic volumes and latency baselines

### Consumer Impact Matrix

| Consumer | Endpoints Used | Traffic Volume | Migration Difficulty | Priority |
|----------|---------------|----------------|---------------------|----------|
|          |               | req/day        | Low/Med/High        | 1-5      |

## Phase 2: Modern API Design
1. Design resource-oriented API structure (REST) or schema (GraphQL)
2. Define OpenAPI / GraphQL schema specification
3. Plan versioning strategy (URL path, header, query param)
4. Design authentication flow (OAuth 2.0, API keys, JWT)
5. Define rate limiting and throttling policies
6. Plan pagination, filtering, and sorting patterns

### Endpoint Mapping

| Legacy Endpoint | Modern Endpoint | Method | Breaking Change | Adapter Needed |
|----------------|-----------------|--------|-----------------|----------------|
|                |                 |        | Yes/No          | Yes/No         |

## Phase 3: Adapter Layer Implementation
1. Build adapter/facade layer between legacy and modern APIs
2. Implement request/response transformation logic
3. Handle data format conversion (XML to JSON, etc.)
4. Maintain backward compatibility through the adapter
5. Add comprehensive logging for both old and new paths

## Phase 4: Modern API Implementation
1. Implement modern API endpoints
2. Write comprehensive API tests (unit, integration, contract)
3. Set up API documentation (Swagger UI, GraphQL Playground)
4. Configure API gateway routing
5. Implement monitoring and alerting

## Phase 5: Consumer Migration
1. Publish migration guide and updated SDK/client libraries
2. Provide sandbox environment for consumer testing
3. Migrate consumers in waves, starting with internal teams
4. Monitor error rates per consumer during migration
5. Provide support window for each migration wave

## Phase 6: Deprecation & Decommission
1. Announce deprecation timeline for legacy endpoints
2. Add deprecation headers to legacy API responses
3. Monitor remaining legacy traffic
4. Remove adapter layer after all consumers migrated
5. Decommission legacy API infrastructure

## Output Format
- **API Inventory**: Complete catalog of legacy endpoints and consumers
- **Modern API Specification**: OpenAPI/GraphQL schema document
- **Migration Guide**: Consumer-facing documentation for migration
- **Adapter Architecture**: Design for backward-compatible transition
- **Deprecation Timeline**: Phased schedule with milestones

## Action Items
- [ ] Complete legacy API discovery and consumer mapping
- [ ] Design and review modern API specification
- [ ] Build adapter layer with backward compatibility
- [ ] Deploy modern API to staging for consumer testing
- [ ] Migrate consumers in planned waves
- [ ] Enforce deprecation dates and decommission legacy API
