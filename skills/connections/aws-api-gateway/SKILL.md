---
name: aws-api-gateway
description: |
  AWS API Gateway REST and HTTP API management, stage analysis, usage plans, throttling configuration, and deployment tracking. Covers API inventory, endpoint metrics, latency analysis, authorization configuration, and integration health.
connection_type: aws
preload: false
---

# AWS API Gateway Skill

Analyze AWS API Gateway REST and HTTP APIs with parallel execution and anti-hallucination guardrails.

**Relationship to other AWS skills:**

- `aws-api-gateway/` → API Gateway-specific analysis (REST/HTTP APIs, stages, usage plans)
- `aws/` → "How to execute" (parallel patterns, throttling, output format)

## CRITICAL: Parallel Execution Requirement

**ALL independent operations MUST run in parallel using background jobs (&) and wait.**

```bash
#!/bin/bash
export AWS_PAGER=""

for api_id in $apis; do
  get_api_details "$api_id" &
done
wait
```

## Helper Functions

```bash
#!/bin/bash
export AWS_PAGER=""

# List REST APIs
list_rest_apis() {
  aws apigateway get-rest-apis \
    --output text \
    --query 'items[].[id,name,createdDate,endpointConfiguration.types[0]]'
}

# List HTTP APIs (API Gateway v2)
list_http_apis() {
  aws apigatewayv2 get-apis \
    --output text \
    --query 'Items[].[ApiId,Name,ProtocolType,CreatedDate,ApiEndpoint]'
}

# Get REST API stages
get_rest_stages() {
  local api_id=$1
  aws apigateway get-stages --rest-api-id "$api_id" \
    --output text \
    --query 'item[].[stageName,deploymentId,lastUpdatedDate,cacheClusterEnabled,cacheClusterSize]'
}

# Get HTTP API stages
get_http_stages() {
  local api_id=$1
  aws apigatewayv2 get-stages --api-id "$api_id" \
    --output text \
    --query 'Items[].[StageName,DeploymentId,LastUpdatedDate,DefaultRouteSettings.ThrottlingBurstLimit,DefaultRouteSettings.ThrottlingRateLimit]'
}

# Get usage plan details
get_usage_plans() {
  aws apigateway get-usage-plans \
    --output text \
    --query 'items[].[id,name,throttle.burstLimit,throttle.rateLimit,quota.limit,quota.period]'
}

# Get API metrics
get_api_metrics() {
  local api_name=$1 stage=$2 days=${3:-7}
  local end_time start_time
  end_time=$(date -u +"%Y-%m-%dT%H:%M:%S")
  start_time=$(date -u -d "$days days ago" +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || date -u -v-${days}d +"%Y-%m-%dT%H:%M:%S")

  aws cloudwatch get-metric-statistics \
    --namespace AWS/ApiGateway --metric-name Count \
    --dimensions Name=ApiName,Value="$api_name" Name=Stage,Value="$stage" \
    --start-time "$start_time" --end-time "$end_time" \
    --period $((days * 86400)) --statistics Sum \
    --output text --query 'Datapoints[0].Sum'
}
```

## Common Operations

### 1. API Inventory (REST + HTTP)

```bash
#!/bin/bash
export AWS_PAGER=""
echo "=== REST APIs ==="
aws apigateway get-rest-apis \
  --output text \
  --query 'items[].[id,name,endpointConfiguration.types[0]]' &

echo "=== HTTP APIs ==="
aws apigatewayv2 get-apis \
  --output text \
  --query 'Items[].[ApiId,Name,ProtocolType]' &
wait
```

### 2. Latency and Error Analysis

```bash
#!/bin/bash
export AWS_PAGER=""
END=$(date -u +"%Y-%m-%dT%H:%M:%S")
START=$(date -u -d "7 days ago" +"%Y-%m-%dT%H:%M:%S" 2>/dev/null || date -u -v-7d +"%Y-%m-%dT%H:%M:%S")
APIS=$(aws apigateway get-rest-apis --output text --query 'items[].[name]')
for api in $APIS; do
  {
    latency=$(aws cloudwatch get-metric-statistics \
      --namespace AWS/ApiGateway --metric-name Latency \
      --dimensions Name=ApiName,Value="$api" \
      --start-time "$START" --end-time "$END" \
      --period 604800 --statistics Average Maximum \
      --output text --query 'Datapoints[0].[Average,Maximum]')
    errors5xx=$(aws cloudwatch get-metric-statistics \
      --namespace AWS/ApiGateway --metric-name 5XXError \
      --dimensions Name=ApiName,Value="$api" \
      --start-time "$START" --end-time "$END" \
      --period 604800 --statistics Sum \
      --output text --query 'Datapoints[0].Sum')
    printf "%s\tLatency:%s\t5xx:%s\n" "$api" "$latency" "${errors5xx:-0}"
  } &
done
wait
```

### 3. Usage Plan and API Key Analysis

```bash
#!/bin/bash
export AWS_PAGER=""
PLANS=$(aws apigateway get-usage-plans --output text --query 'items[].id')
for plan_id in $PLANS; do
  {
    plan_info=$(aws apigateway get-usage-plan --usage-plan-id "$plan_id" \
      --output text --query '[name,throttle.burstLimit,throttle.rateLimit,quota.limit,quota.period]')
    key_count=$(aws apigateway get-usage-plan-keys --usage-plan-id "$plan_id" \
      --output text --query 'length(items)')
    printf "%s\t%s\tKeys:%s\n" "$plan_id" "$plan_info" "$key_count"
  } &
done
wait
```

### 4. Stage Configuration Audit

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

### 5. Throttling Configuration Review

```bash
#!/bin/bash
export AWS_PAGER=""
# Account-level throttle limits
aws apigateway get-account --output text --query '[throttleSettings.burstLimit,throttleSettings.rateLimit]'

# Per-API stage throttle settings
APIS=$(aws apigateway get-rest-apis --output text --query 'items[].[id,name]')
echo "$APIS" | while read api_id api_name; do
  aws apigateway get-stages --rest-api-id "$api_id" \
    --output text \
    --query "item[].[\"$api_name\",stageName,methodSettings.*.throttlingBurstLimit,methodSettings.*.throttlingRateLimit]" &
done
wait
```

## Anti-Hallucination Rules

1. **REST API vs HTTP API** - These are different services with different CLI commands: `apigateway` (REST/v1) vs `apigatewayv2` (HTTP/WebSocket). Never mix them.
2. **CloudWatch metric names differ** - REST APIs use `ApiName` dimension; HTTP APIs use `ApiId` dimension. Check which type you are querying.
3. **Stage is required for metrics** - API Gateway metrics require the Stage dimension for accurate per-stage analysis.
4. **Usage plans are REST API only** - HTTP APIs do not support usage plans. They use throttling on routes directly.
5. **Integration latency vs total latency** - `Latency` includes API Gateway overhead. `IntegrationLatency` is backend-only time.

## Common Pitfalls

- **Endpoint types**: REGIONAL, EDGE, or PRIVATE. Edge endpoints use CloudFront automatically. Do not confuse with standalone CloudFront distributions.
- **API key != authentication**: API keys are for usage tracking/throttling, not security. Use authorizers (Lambda, Cognito, IAM) for auth.
- **Deployment required**: Changes to REST APIs require a new deployment to take effect. HTTP APIs auto-deploy by default.
- **CloudWatch statistics syntax**: Use spaces not commas: `--statistics Average Maximum`.
- **WebSocket APIs**: Use `apigatewayv2` with ProtocolType=WEBSOCKET. Different metric dimensions apply.
