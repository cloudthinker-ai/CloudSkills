---
name: aws-api-gateway
description: |
  Use when working with AWS API Gateway — analyzing REST or HTTP APIs, debugging
  latency or 5xx errors, auditing throttling and stage configuration, reviewing
  usage plans, or checking authorization setup. Covers API inventory, CloudWatch
  metrics, stage audits, and integration health for both REST (v1) and HTTP (v2) APIs.
connection_type: aws
preload: false
---

# AWS API Gateway Skill

Analyze AWS API Gateway REST and HTTP APIs with parallel execution and anti-hallucination guardrails.

## Decision Matrix: REST vs HTTP API

| Need | Use | Why |
|------|-----|-----|
| Usage plans / API keys | REST API | HTTP APIs don't support usage plans |
| Request validation / WAF | REST API | Not available in HTTP API |
| Execution logging / X-Ray | REST API | HTTP API only supports access logging |
| Lowest cost | HTTP API | $1/M vs $3.50/M requests |
| WebSocket support | HTTP API (v2) | Only v2 supports WebSocket protocol |
| Auto-deploy | HTTP API | REST requires explicit deployment |
| Simple proxy to Lambda | HTTP API | Simpler, cheaper, auto-deploy |

[Full feature comparison](./references/rest-vs-http.md)

## Phase 1 — Discovery

**CRITICAL:** Discover both REST and HTTP APIs in parallel. NEVER assume API names or IDs.

```bash
#!/bin/bash
export AWS_PAGER=""

echo "=== REST APIs (apigateway) ==="
aws apigateway get-rest-apis \
  --output text \
  --query 'items[].[id,name,endpointConfiguration.types[0]]' &

echo "=== HTTP APIs (apigatewayv2) ==="
aws apigatewayv2 get-apis \
  --output text \
  --query 'Items[].[ApiId,Name,ProtocolType]' &
wait
```

## Phase 2 — Analysis

Run ALL independent operations in parallel using `&` and `wait`.

### Latency & Error Analysis
```bash
#!/bin/bash
export AWS_PAGER=""
END=$(date -u +"%Y-%m-%dT%H:%M:%S")
START=$(date -u -d "7 days ago" +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || date -u -v-7d +"%Y-%m-%dT%H:%M:%S")

# REST APIs: use ApiName dimension
APIS=$(aws apigateway get-rest-apis --output text --query 'items[].[name]')
for api in $APIS; do
  {
    latency=$(aws cloudwatch get-metric-statistics \
      --namespace AWS/ApiGateway --metric-name Latency \
      --dimensions Name=ApiName,Value="$api" \
      --start-time "$START" --end-time "$END" \
      --period 604800 --statistics Average Maximum \
      --output text --query 'Datapoints[0].[Average,Maximum]')
    errors=$(aws cloudwatch get-metric-statistics \
      --namespace AWS/ApiGateway --metric-name 5XXError \
      --dimensions Name=ApiName,Value="$api" \
      --start-time "$START" --end-time "$END" \
      --period 604800 --statistics Sum \
      --output text --query 'Datapoints[0].Sum')
    printf "REST\t%s\tLatency:%s\t5xx:%s\n" "$api" "$latency" "${errors:-0}"
  } &
done

# HTTP APIs: use ApiId dimension and lowercase metric names
HTTP_APIS=$(aws apigatewayv2 get-apis --output text --query 'Items[].[ApiId,Name]')
echo "$HTTP_APIS" | while read api_id api_name; do
  {
    latency=$(aws cloudwatch get-metric-statistics \
      --namespace AWS/ApiGateway --metric-name Latency \
      --dimensions Name=ApiId,Value="$api_id" \
      --start-time "$START" --end-time "$END" \
      --period 604800 --statistics Average Maximum \
      --output text --query 'Datapoints[0].[Average,Maximum]')
    errors=$(aws cloudwatch get-metric-statistics \
      --namespace AWS/ApiGateway --metric-name 5xx \
      --dimensions Name=ApiId,Value="$api_id" \
      --start-time "$START" --end-time "$END" \
      --period 604800 --statistics Sum \
      --output text --query 'Datapoints[0].Sum')
    printf "HTTP\t%s(%s)\tLatency:%s\t5xx:%s\n" "$api_name" "$api_id" "$latency" "${errors:-0}"
  } &
done
wait
```

### Stage Configuration Audit
```bash
#!/bin/bash
export AWS_PAGER=""
APIS=$(aws apigateway get-rest-apis --output text --query 'items[].id')
for api_id in $APIS; do
  aws apigateway get-stages --rest-api-id "$api_id" \
    --output text \
    --query "item[].[\"$api_id\",stageName,cacheClusterEnabled,tracingEnabled,methodSettings.*.loggingLevel]" &
done
wait
```

### Throttling Review
```bash
#!/bin/bash
export AWS_PAGER=""
# Account-level limits
aws apigateway get-account \
  --output text --query '[throttleSettings.burstLimit,throttleSettings.rateLimit]'

# Usage plans (REST only)
aws apigateway get-usage-plans \
  --output text \
  --query 'items[].[id,name,throttle.burstLimit,throttle.rateLimit,quota.limit,quota.period]'
```

## Anti-Hallucination Rules

| Rule | Detail |
|------|--------|
| REST vs HTTP CLI | `apigateway` (REST/v1) vs `apigatewayv2` (HTTP/WebSocket). **NEVER mix.** |
| CloudWatch dimensions | REST uses `ApiName`; HTTP uses `ApiId`. Wrong dimension = empty results. |
| Metric name casing | REST: `5XXError`; HTTP: `5xx`. Check API type before querying. |
| Usage plans | REST API only. HTTP APIs use route-level throttling. |
| Latency metrics | `Latency` = total (including APIGW overhead). `IntegrationLatency` = backend only. |
| Stage requirement | Metrics require Stage dimension for per-stage accuracy. |
| Deployment | REST: changes require new deployment. HTTP: auto-deploy by default. |

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll just check REST APIs" | Always discover both REST and HTTP APIs | HTTP APIs are increasingly common; missing them gives incomplete picture |
| "Metrics aren't needed for health check" | Always check CloudWatch metrics | APIs can return 200 while silently failing on a subset of requests |
| "Default stage config is fine" | Audit stage config explicitly | Defaults leave execution logging, tracing, and caching disabled |
| "Usage plans aren't relevant" | Review if REST API has external consumers | Unthrottled APIs cause cascading failures under load |
| "The API is responding, so it's healthy" | Check error rates AND latency percentiles | p50 may be fine while p99 is unacceptable |

## Output Format

```
API Gateway Health Report
═══════════════════════════
REST APIs: [count] | HTTP APIs: [count]

API          Type  Stage  Latency(avg/max)  5xx(7d)  Cache  Logging  Tracing
─────────────────────────────────────────────────────────────────────────────
my-api       REST  prod   45ms/230ms        12       ON     ERROR    ON
payment-api  HTTP  $def   22ms/89ms         0        N/A    ACCESS   N/A

Throttling: Account [burst/rate] | Plans: [count]
Issues: [list of findings with severity]
```

## Common Pitfalls

- **Endpoint types**: REGIONAL, EDGE, or PRIVATE. Edge uses CloudFront automatically — don't confuse with standalone distributions.
- **API key ≠ authentication**: API keys track usage/throttling only. Use authorizers (Lambda, Cognito, IAM) for auth.
- **CloudWatch statistics syntax**: Use spaces not commas: `--statistics Average Maximum`.
- **WebSocket APIs**: Use `apigatewayv2` with `ProtocolType=WEBSOCKET`. Different metric dimensions.
- **Cross-platform date**: macOS uses `-v-7d`, Linux uses `-d "7 days ago"`. Scripts handle both.

## References

- [REST vs HTTP API — Full Comparison](./references/rest-vs-http.md)
- [Troubleshooting Guide — Diagnostic Decision Trees](./references/troubleshooting.md)
