---
name: rate-limiting-design
enabled: true
description: |
  Guides teams through designing and implementing rate limiting strategies for APIs and services. This template covers algorithm selection, limit configuration, client communication, and monitoring to protect backend systems from abuse and overload while maintaining a good developer experience.
required_connections:
  - prefix: api-gateway
    label: "API Gateway"
  - prefix: monitoring
    label: "Monitoring Platform"
config_fields:
  - key: service_name
    label: "Service Name"
    required: true
    placeholder: "e.g., Public REST API"
  - key: rate_limit_strategy
    label: "Rate Limiting Strategy"
    required: true
    placeholder: "e.g., Token Bucket, Sliding Window, Fixed Window"
features:
  - RATE_LIMITING
  - API_DESIGN
  - RELIABILITY
---

# Rate Limiting Design

## Phase 1: Requirements Gathering

Define the goals and constraints for rate limiting.

- [ ] Identify services or endpoints requiring rate limiting
- [ ] Determine the primary goal: abuse prevention / fair usage / cost control / stability
- [ ] List client types and their expected usage patterns:

| Client Type | Expected RPS | Burst Tolerance | SLA Tier |
|-------------|-------------|-----------------|----------|
|             |             |                 |          |

- [ ] Define acceptable latency overhead for rate limit checks: ___ms
- [ ] Identify regulatory or contractual rate limit requirements

## Phase 2: Algorithm Selection

Evaluate and select the rate limiting algorithm.

| Algorithm | Pros | Cons | Fit |
|-----------|------|------|-----|
| Fixed Window | Simple, low memory | Burst at window edges | |
| Sliding Window Log | Accurate | High memory for high-volume | |
| Sliding Window Counter | Good accuracy, low memory | Slight approximation | |
| Token Bucket | Allows controlled bursts | Slightly complex | |
| Leaky Bucket | Smooth output rate | No burst tolerance | |

- [ ] Selected algorithm: ___
- [ ] Justification: ___

## Phase 3: Limit Configuration

Define rate limits per client tier and endpoint.

| Endpoint / Group | Tier | Requests per Window | Window Size | Burst Limit |
|-----------------|------|--------------------:|-------------|------------:|
|                 |      |                     |             |             |

**Graduated Limits:**

- [ ] Unauthenticated requests: ___ req/min
- [ ] Authenticated (free tier): ___ req/min
- [ ] Authenticated (paid tier): ___ req/min
- [ ] Internal services: ___ req/min (or exempt)

## Phase 4: Implementation Design

- [ ] Enforcement point: API gateway / middleware / application layer / sidecar
- [ ] State storage: in-memory / Redis / distributed cache
- [ ] Key strategy: API key / IP address / user ID / composite
- [ ] Distributed coordination approach (if multi-instance): ___
- [ ] Response headers to include:
  - [ ] `X-RateLimit-Limit` (max requests)
  - [ ] `X-RateLimit-Remaining` (requests left)
  - [ ] `X-RateLimit-Reset` (reset timestamp)
  - [ ] `Retry-After` (on 429 responses)
- [ ] HTTP 429 response body format defined
- [ ] Graceful degradation if rate limit store is unavailable

## Phase 5: Monitoring and Alerting

- [ ] Dashboard showing current rate limit utilization per client/tier
- [ ] Alert when clients consistently hit rate limits (potential legitimate need)
- [ ] Alert when rate limit infrastructure latency exceeds threshold
- [ ] Log all rate-limited requests with client identifier and endpoint
- [ ] Track rate limit bypass attempts or anomalous patterns

## Output Format

### Summary

- **Service:** ___
- **Algorithm:** ___
- **Enforcement point:** ___
- **Client tiers:** ___
- **Endpoints covered:** ___

### Action Items

- [ ] Implement rate limiting at selected enforcement point
- [ ] Configure limits per tier and endpoint
- [ ] Add standard rate limit response headers
- [ ] Set up monitoring dashboard and alerts
- [ ] Document rate limits in API documentation
- [ ] Communicate limits to existing clients with migration timeline
