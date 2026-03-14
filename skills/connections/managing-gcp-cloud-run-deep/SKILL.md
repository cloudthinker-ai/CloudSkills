---
name: managing-gcp-cloud-run-deep
description: |
  Deep Google Cloud Run analysis covering service inventory, revision management, traffic splitting, autoscaling configuration, request latency metrics, container resource limits, domain mappings, and VPC connector usage. Use for comprehensive Cloud Run optimization and health assessment.
connection_type: gcp
preload: false
---

# GCP Cloud Run Deep Management

Comprehensive analysis of Cloud Run services, revisions, traffic routing, and performance.

## Phase 1: Discovery

```bash
#!/bin/bash
PROJECT="${GOOGLE_CLOUD_PROJECT}"

echo "=== Cloud Run Services ==="
gcloud run services list --project="$PROJECT" \
  --format="table(name, region, status.url, status.conditions[0].status:label=READY, metadata.annotations.'run.googleapis.com/launch-stage':label=STAGE)" \
  2>/dev/null | head -20

echo ""
echo "=== Service Details ==="
for SVC in $(gcloud run services list --project="$PROJECT" --format="value(name)" 2>/dev/null); do
  REGION=$(gcloud run services list --project="$PROJECT" --format="value(region)" --filter="name=${SVC}" 2>/dev/null)
  gcloud run services describe "$SVC" --project="$PROJECT" --region="$REGION" --format="json" \
    | jq '{name: .metadata.name, image: .spec.template.spec.containers[0].image, cpu: .spec.template.spec.containers[0].resources.limits.cpu, memory: .spec.template.spec.containers[0].resources.limits.memory, concurrency: .spec.template.spec.containerConcurrency, timeout: .spec.template.metadata.annotations["run.googleapis.com/execution-environment"], minInstances: .spec.template.metadata.annotations["autoscaling.knative.dev/minScale"], maxInstances: .spec.template.metadata.annotations["autoscaling.knative.dev/maxScale"]}' 2>/dev/null
done | head -30

echo ""
echo "=== Traffic Splitting ==="
for SVC in $(gcloud run services list --project="$PROJECT" --format="value(name)" 2>/dev/null); do
  REGION=$(gcloud run services list --project="$PROJECT" --format="value(region)" --filter="name=${SVC}" 2>/dev/null)
  gcloud run services describe "$SVC" --project="$PROJECT" --region="$REGION" \
    --format="json" | jq ".status.traffic[] | {revision: .revisionName, percent: .percent, tag: .tag}" 2>/dev/null
done

echo ""
echo "=== Domain Mappings ==="
gcloud run domain-mappings list --project="$PROJECT" \
  --format="table(name, routeName, status.conditions[0].status:label=READY)" 2>/dev/null

echo ""
echo "=== Revisions ==="
for SVC in $(gcloud run services list --project="$PROJECT" --format="value(name)" 2>/dev/null); do
  REGION=$(gcloud run services list --project="$PROJECT" --format="value(region)" --filter="name=${SVC}" 2>/dev/null)
  gcloud run revisions list --service="$SVC" --project="$PROJECT" --region="$REGION" \
    --format="table(name, active, status.conditions[0].status:label=READY, metadata.creationTimestamp)" \
    2>/dev/null | head -5
done
```

## Phase 2: Analysis

```bash
#!/bin/bash
PROJECT="${GOOGLE_CLOUD_PROJECT}"
END=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
START=$(date -u -d "7 days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v-7d +"%Y-%m-%dT%H:%M:%SZ")

echo "=== Request Count & Latency ==="
gcloud monitoring time-series list \
  --project="$PROJECT" \
  --filter='metric.type="run.googleapis.com/request_count"' \
  --interval-start-time="$START" --interval-end-time="$END" \
  --format="table(resource.labels.service_name, metric.labels.response_code_class, points[0].value.int64Value:label=REQUESTS)" \
  2>/dev/null | head -20

echo ""
echo "=== Request Latencies ==="
gcloud monitoring time-series list \
  --project="$PROJECT" \
  --filter='metric.type="run.googleapis.com/request_latencies"' \
  --interval-start-time="$START" --interval-end-time="$END" \
  --format="table(resource.labels.service_name, points[0].value.distributionValue.mean:label=AVG_MS)" \
  2>/dev/null | head -20

echo ""
echo "=== Instance Count ==="
gcloud monitoring time-series list \
  --project="$PROJECT" \
  --filter='metric.type="run.googleapis.com/container/instance_count"' \
  --interval-start-time="$START" --interval-end-time="$END" \
  --format="table(resource.labels.service_name, metric.labels.state, points[0].value.int64Value:label=COUNT)" \
  2>/dev/null | head -20

echo ""
echo "=== CPU & Memory Utilization ==="
gcloud monitoring time-series list \
  --project="$PROJECT" \
  --filter='metric.type="run.googleapis.com/container/cpu/utilizations"' \
  --interval-start-time="$START" --interval-end-time="$END" \
  --format="table(resource.labels.service_name, points[0].value.distributionValue.mean:label=CPU_UTIL)" \
  2>/dev/null | head -20

echo ""
echo "=== VPC Connectors ==="
for SVC in $(gcloud run services list --project="$PROJECT" --format="value(name)" 2>/dev/null); do
  REGION=$(gcloud run services list --project="$PROJECT" --format="value(region)" --filter="name=${SVC}" 2>/dev/null)
  VPC=$(gcloud run services describe "$SVC" --project="$PROJECT" --region="$REGION" --format="json" \
    | jq -r '.spec.template.metadata.annotations["run.googleapis.com/vpc-access-connector"] // "none"' 2>/dev/null)
  echo "${SVC}: ${VPC}"
done
```

## Output Format

```
GCP CLOUD RUN DEEP ANALYSIS
==============================
Service          Region       CPU    Memory  Min/Max  Requests  P50-ms  P99-ms
──────────────────────────────────────────────────────────────────────────────────
order-api        us-central1  1      512Mi   1/10     125000    45      230
auth-service     us-central1  2      1Gi     2/50     890000    12      85
batch-worker     us-east1     1      2Gi     0/5      8900      2400    5000

Traffic: 3 services with 100% on latest | 1 canary at 10%
VPC Connectors: 2/3 services connected | Domain Mappings: 2
```

## Safety Rules

- **Read-only**: Only use `gcloud run services list`, `describe`, `revisions list`, and monitoring queries
- **Never deploy, update traffic**, or delete services without confirmation
- **Secrets**: Never output secret environment variable values
- **Quota**: Cloud Monitoring API quota is 6000 read requests per minute
