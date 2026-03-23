# REST API vs HTTP API — Deep Reference

## Feature Comparison Matrix

| Feature | REST API (v1) | HTTP API (v2) |
|---------|:------------:|:-------------:|
| **CLI namespace** | `apigateway` | `apigatewayv2` |
| **Protocol** | REST | HTTP, WebSocket |
| **Usage plans / API keys** | Yes | No |
| **Request validation** | Yes | No |
| **WAF integration** | Yes | No |
| **Caching** | Built-in (stage-level) | No (use CloudFront) |
| **Custom domain** | Yes | Yes |
| **Lambda authorizer** | Request/Token | Request only (v2 payload) |
| **Cognito authorizer** | Yes | JWT authorizer |
| **IAM auth** | Yes | Yes |
| **Mutual TLS** | Yes | Yes |
| **Private endpoints** | Yes | Yes (VPC link) |
| **Export/Import** | OpenAPI, Swagger | OpenAPI 3.0 |
| **Access logging** | Yes | Yes |
| **Execution logging** | Yes | No |
| **X-Ray tracing** | Yes | No |
| **Cost (per million)** | $3.50 | $1.00 |
| **Auto-deploy** | No (requires deployment) | Yes (default) |

## CloudWatch Metrics Differences

### REST API Metrics
```
Namespace: AWS/ApiGateway
Dimensions: ApiName, Stage, Method, Resource
Metrics: Count, Latency, IntegrationLatency, 4XXError, 5XXError, CacheHitCount, CacheMissCount
```

### HTTP API Metrics
```
Namespace: AWS/ApiGateway
Dimensions: ApiId, Stage
Metrics: Count, Latency, IntegrationLatency, 4xx, 5xx, DataProcessed
```

**Critical differences:**
- REST uses `ApiName` dimension; HTTP uses `ApiId` dimension
- REST uses `4XXError`/`5XXError`; HTTP uses `4xx`/`5xx` (lowercase)
- REST has `CacheHitCount`/`CacheMissCount`; HTTP does not
- HTTP has `DataProcessed`; REST does not

## Decision Guide: When to Use Which

```
Need usage plans or API keys?
├── Yes → REST API
└── No
    Need request validation or WAF?
    ├── Yes → REST API
    └── No
        Need execution logging or X-Ray?
        ├── Yes → REST API
        └── No
            Need lowest cost?
            ├── Yes → HTTP API ($1/M vs $3.50/M)
            └── No
                Need WebSocket?
                ├── Yes → HTTP API (WebSocket protocol)
                └── No → HTTP API (simpler, cheaper, auto-deploy)
```

## Migration: REST to HTTP

1. Export REST API as OpenAPI 3.0: `aws apigateway get-export --rest-api-id ID --stage-name prod --export-type oas30`
2. Review unsupported features (usage plans, request validation, caching)
3. Import to HTTP API: `aws apigatewayv2 import-api --body file://openapi.json`
4. Update Lambda authorizers to v2 payload format
5. Update CloudWatch alarms (dimension changes)
6. Update client integrations (endpoint URL changes)

## Throttling Architecture

### REST API Throttling (3 layers)
```
Account Level (default: 10,000 RPS, 5,000 burst)
└── Usage Plan Level (per consumer)
    └── Method Level (per stage/method/resource)
```

### HTTP API Throttling (2 layers)
```
Account Level (default: 10,000 RPS, 5,000 burst)
└── Route Level (per stage/route)
```
