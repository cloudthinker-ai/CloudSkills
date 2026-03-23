# AWS API Gateway Troubleshooting Guide

## Diagnostic Decision Tree

```
API returning errors?
├── 4xx errors
│   ├── 401 Unauthorized → Check authorizer config, token expiry, CORS
│   ├── 403 Forbidden → Check IAM policy, resource policy, WAF rules, API key
│   ├── 404 Not Found → Check route/resource path, stage, deployment status
│   ├── 429 Too Many Requests → Check throttle limits (account, usage plan, method)
│   └── Other 4xx → Check request validation, model schema, content type
├── 5xx errors
│   ├── 500 Internal → Check integration (Lambda error, backend crash)
│   ├── 502 Bad Gateway → Check Lambda timeout, response format, VPC connectivity
│   ├── 503 Service Unavailable → Check backend health, circuit breaker, capacity
│   └── 504 Gateway Timeout → Check integration timeout (REST: 29s max, HTTP: 30s max)
└── Latency spikes
    ├── IntegrationLatency high → Backend is slow (Lambda cold start, DB query, external API)
    ├── Latency - IntegrationLatency high → API Gateway overhead (auth, validation, mapping)
    └── Intermittent → Check throttling, connection reuse, DNS resolution
```

## Common Investigation Commands

### Check API health (last 1 hour)
```bash
#!/bin/bash
export AWS_PAGER=""
END=$(date -u +"%Y-%m-%dT%H:%M:%S")
START=$(date -u -d "1 hour ago" +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || date -u -v-1H +"%Y-%m-%dT%H:%M:%S")

# For REST APIs
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway --metric-name 5XXError \
  --dimensions Name=ApiName,Value="$API_NAME" Name=Stage,Value="$STAGE" \
  --start-time "$START" --end-time "$END" \
  --period 300 --statistics Sum \
  --output text --query 'Datapoints[*].[Timestamp,Sum]'

# For HTTP APIs (note: different dimension and metric name)
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway --metric-name 5xx \
  --dimensions Name=ApiId,Value="$API_ID" Name=Stage,Value="$STAGE" \
  --start-time "$START" --end-time "$END" \
  --period 300 --statistics Sum \
  --output text --query 'Datapoints[*].[Timestamp,Sum]'
```

### Check execution logs (REST API only)
```bash
#!/bin/bash
export AWS_PAGER=""
# Execution logs require stage logging to be enabled
LOG_GROUP="API-Gateway-Execution-Logs_${API_ID}/${STAGE}"
aws logs filter-log-events \
  --log-group-name "$LOG_GROUP" \
  --start-time $(($(date +%s) - 3600))000 \
  --filter-pattern "ERROR" \
  --output text --query 'events[*].[timestamp,message]'
```

### Check throttle status
```bash
#!/bin/bash
export AWS_PAGER=""
# Account-level limits
aws apigateway get-account \
  --output text --query '[throttleSettings.burstLimit,throttleSettings.rateLimit]'

# Current usage against limits (if usage plan exists)
aws apigateway get-usage \
  --usage-plan-id "$PLAN_ID" \
  --key-id "$KEY_ID" \
  --start-date "$(date -u +%Y-%m-%d)" \
  --end-date "$(date -u +%Y-%m-%d)" \
  --output json
```

## Latency Optimization Checklist

| Check | Action | Expected Impact |
|-------|--------|----------------|
| Lambda cold starts | Enable provisioned concurrency or SnapStart | -200-500ms on cold |
| Response caching | Enable stage cache (REST only) | -50-90% latency on cache hits |
| Regional endpoint | Switch from EDGE to REGIONAL if clients are in same region | -20-50ms |
| Payload size | Enable compression (REST: `minimumCompressionSize`) | Variable |
| Connection reuse | Ensure backend uses keep-alive | -10-30ms per request |
| Lambda memory | Increase Lambda memory (also increases CPU) | Variable |
| VPC Lambda | Use VPC endpoints or Hyperplane ENI | -100-200ms cold start |

## CORS Troubleshooting

```
CORS error in browser?
├── Preflight (OPTIONS) failing?
│   ├── REST API: Add OPTIONS method with Mock integration + response headers
│   └── HTTP API: Enable CORS in API config (automatic OPTIONS handling)
├── Response missing headers?
│   ├── Check Access-Control-Allow-Origin matches request origin
│   ├── Check Access-Control-Allow-Methods includes request method
│   └── Check Access-Control-Allow-Headers includes custom headers
└── Credentials mode?
    └── Cannot use wildcard (*) with credentials — must specify exact origin
```
