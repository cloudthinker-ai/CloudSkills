---
name: cdn-optimization-review
enabled: true
description: |
  Use when performing cdn optimization review — reviews and optimizes CDN
  configuration for maximum cache hit ratio, minimal latency, and cost
  efficiency. Covers cache policy tuning, origin shield configuration, edge
  function optimization, security headers, and geographic performance analysis.
required_connections:
  - prefix: cdn
    label: "CDN Provider"
  - prefix: monitoring
    label: "Monitoring Platform"
config_fields:
  - key: cdn_provider
    label: "CDN Provider"
    required: true
    placeholder: "e.g., CloudFront, Cloud CDN, Fastly, Cloudflare"
  - key: primary_content_type
    label: "Primary Content Type"
    required: true
    placeholder: "e.g., static website, API, video streaming, mixed"
  - key: current_cache_hit_ratio
    label: "Current Cache Hit Ratio"
    required: false
    placeholder: "e.g., 75%"
features:
  - PERFORMANCE
  - CDN
  - OPTIMIZATION
---

# CDN Optimization Review

## Phase 1: Current State Assessment
1. Collect CDN performance metrics
   - [ ] Cache hit ratio (overall and per content type)
   - [ ] Origin request rate and latency
   - [ ] Edge latency by geographic region
   - [ ] Bandwidth consumption and costs
   - [ ] Error rates (4xx, 5xx) at edge and origin
   - [ ] TLS handshake times
2. Review current CDN configuration
3. Identify top-requested content by volume and bandwidth

### Performance Baseline

| Metric | Current | Target | Gap |
|--------|---------|--------|-----|
| Cache hit ratio | % | > 90% | |
| P50 edge latency | ms | < 50ms | |
| P95 edge latency | ms | < 200ms | |
| Origin request rate | req/s | < current * 0.1 | |
| Error rate | % | < 0.1% | |

## Phase 2: Cache Policy Optimization
1. Review and optimize cache behaviors
   - [ ] Set appropriate TTLs per content type (static, dynamic, API)
   - [ ] Configure cache key normalization (query string sorting, header filtering)
   - [ ] Enable compression (gzip, Brotli) at edge
   - [ ] Set correct Cache-Control and Vary headers at origin
   - [ ] Remove unnecessary query parameters from cache keys
   - [ ] Configure stale-while-revalidate and stale-if-error
2. Identify cache-busting patterns reducing hit ratio

### Cache Policy Matrix

| Content Type | Current TTL | Recommended TTL | Cache Key | Compression |
|-------------|------------|----------------|-----------|-------------|
| HTML | | | | gzip/br |
| CSS/JS | | | | gzip/br |
| Images | | | | N/A |
| API responses | | | | gzip |
| Fonts | | | | gzip |
| Video/media | | | | N/A |

## Phase 3: Origin Optimization
1. Optimize origin configuration
   - [ ] Enable origin shield / mid-tier cache
   - [ ] Configure connection keep-alive to origin
   - [ ] Set up origin failover and health checks
   - [ ] Optimize origin response headers for caching
   - [ ] Reduce origin response times
2. Evaluate need for multiple origins
3. Configure custom error pages at edge

## Phase 4: Edge Computing Review
1. Review edge function usage and opportunities
   - [ ] URL rewrites and redirects at edge
   - [ ] A/B testing and feature flags
   - [ ] Authentication at edge
   - [ ] Image optimization and resizing
   - [ ] Response header manipulation
   - [ ] Geographic routing logic
2. Optimize existing edge functions for performance
3. Identify new edge computing opportunities

## Phase 5: Security Configuration
1. Review CDN security settings
   - [ ] DDoS protection enabled and configured
   - [ ] WAF rules appropriate and not over-blocking
   - [ ] Bot management configured
   - [ ] TLS configuration (TLS 1.2+, strong ciphers)
   - [ ] HTTP Strict Transport Security (HSTS)
   - [ ] Content Security Policy headers
   - [ ] Signed URLs/cookies for private content

## Phase 6: Geographic Performance Analysis
1. Analyze performance by region
   - [ ] Identify regions with high latency
   - [ ] Verify POP coverage for target audience
   - [ ] Consider additional origin regions for global apps
   - [ ] Test from key geographic locations
2. Optimize for mobile users and low-bandwidth regions

### Regional Performance

| Region | P50 Latency | P95 Latency | Cache Hit % | Bandwidth | Action Needed |
|--------|-------------|-------------|-------------|-----------|---------------|
| North America | ms | ms | % | | |
| Europe | ms | ms | % | | |
| Asia Pacific | ms | ms | % | | |
| Other | ms | ms | % | | |

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Performance Baseline**: Current metrics by region and content type
- **Cache Policy Updates**: Recommended TTL and cache key changes
- **Origin Optimization**: Configuration changes for origin efficiency
- **Security Review**: Security configuration recommendations
- **Cost Analysis**: Projected savings from optimization

## Action Items
- [ ] Collect current CDN performance metrics
- [ ] Optimize cache policies and TTLs
- [ ] Configure origin shield and connection optimization
- [ ] Review and update security configuration
- [ ] Test changes in staging before production
- [ ] Monitor cache hit ratio improvement over 7 days
