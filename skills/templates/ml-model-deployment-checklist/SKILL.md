---
name: ml-model-deployment-checklist
enabled: true
description: |
  Use when performing ml model deployment checklist — provides a comprehensive
  checklist for deploying machine learning models to production, covering model
  validation, infrastructure setup, serving configuration, monitoring, A/B
  testing, and rollback procedures. Ensures models are reliable, observable, and
  maintainable in production environments.
required_connections:
  - prefix: ml-platform
    label: "ML Platform"
  - prefix: monitoring
    label: "Monitoring Platform"
config_fields:
  - key: model_type
    label: "Model Type"
    required: true
    placeholder: "e.g., classification, regression, NLP, computer vision, recommendation"
  - key: serving_platform
    label: "Serving Platform"
    required: true
    placeholder: "e.g., SageMaker, Vertex AI, KServe, custom API"
  - key: inference_type
    label: "Inference Type"
    required: false
    placeholder: "e.g., real-time, batch, streaming"
features:
  - DATA
  - ML
  - DEPLOYMENT
---

# ML Model Deployment Checklist

## Phase 1: Model Validation
1. Validate model before deployment
   - [ ] Model performance metrics meet acceptance criteria
   - [ ] Evaluated on held-out test set (not training data)
   - [ ] Tested on edge cases and failure modes
   - [ ] Bias and fairness metrics reviewed
   - [ ] Model size and inference latency within requirements
   - [ ] Comparison with current production model (if exists)
   - [ ] Model card/documentation completed
2. Get model review sign-off from stakeholders

### Model Performance Summary

| Metric | Training | Validation | Test | Production Baseline | Threshold |
|--------|---------|-----------|------|-------------------|-----------|
| Primary metric | | | | | > |
| Secondary metric | | | | | > |
| Latency (P50) | N/A | N/A | ms | ms | < ms |
| Latency (P99) | N/A | N/A | ms | ms | < ms |
| Model size | MB | N/A | N/A | MB | < MB |

## Phase 2: Infrastructure Setup
1. Prepare serving infrastructure
   - [ ] Compute resources provisioned (GPU/CPU, memory)
   - [ ] Auto-scaling configured (min/max replicas)
   - [ ] Load balancer and health checks configured
   - [ ] Model artifact stored in versioned registry
   - [ ] Feature store connected (if real-time features needed)
   - [ ] Caching layer configured (if applicable)
   - [ ] Network security (API authentication, rate limiting)
2. Validate infrastructure handles expected load

### Resource Configuration

| Resource | Specification | Auto-Scale Min | Auto-Scale Max | Cost/hour |
|----------|-------------|----------------|----------------|-----------|
| Compute | | | | $ |
| GPU | | | | $ |
| Memory | GB | | | |
| Storage | GB | N/A | N/A | $ |

## Phase 3: Serving Configuration
1. Configure model serving
   - [ ] Model serialization format (ONNX, TensorFlow SavedModel, PyTorch, pickle)
   - [ ] Input validation and preprocessing pipeline
   - [ ] Output post-processing and formatting
   - [ ] Batching configuration (dynamic batching for throughput)
   - [ ] Timeout configuration for inference requests
   - [ ] Fallback behavior on model errors
   - [ ] API versioning for model versions
2. Test serving endpoint thoroughly

### API Contract

| Field | Request | Response | Required | Validation |
|-------|---------|----------|----------|-----------|
| Input features | | N/A | | Type, range checks |
| Predictions | N/A | | | |
| Confidence scores | N/A | | | |
| Model version | N/A | | | |
| Request ID | | | | UUID format |

## Phase 4: Monitoring Setup
1. Configure model monitoring
   - [ ] Prediction latency (P50, P95, P99)
   - [ ] Prediction throughput (requests/sec)
   - [ ] Error rate and error types
   - [ ] Input data distribution (feature drift detection)
   - [ ] Output distribution (prediction drift detection)
   - [ ] Model performance degradation (if ground truth available)
   - [ ] Resource utilization (CPU, GPU, memory)
   - [ ] Feature store freshness (if applicable)
2. Set up alerts for anomalies

### Monitoring Alert Configuration

| Alert | Condition | Severity | Action |
|-------|-----------|----------|--------|
| Latency spike | P95 > threshold | Warning | Investigate |
| Error rate | > 1% | Critical | Page on-call |
| Data drift | Distribution shift > threshold | Warning | Investigate model |
| Prediction drift | Output shift > threshold | Warning | Retrain pipeline |
| Resource saturation | CPU/GPU > 90% | Warning | Scale up |

## Phase 5: Deployment Strategy
1. Select deployment strategy
   - [ ] Shadow deployment (run alongside, compare outputs)
   - [ ] Canary deployment (gradual traffic shift)
   - [ ] A/B test (controlled experiment with metrics)
   - [ ] Blue-green (instant switch with rollback)
2. Execute deployment
   - [ ] Deploy new model version
   - [ ] Route initial traffic percentage
   - [ ] Monitor metrics during rollout
   - [ ] Gradually increase traffic if healthy
   - [ ] Full rollout or rollback decision

### Rollout Plan

| Phase | Traffic % | Duration | Success Criteria | Rollback Trigger |
|-------|----------|----------|-----------------|-----------------|
| Shadow | 0% (duplicate) | 24 hours | Output matches expectations | N/A |
| Canary | 5% | 4 hours | Error rate < 0.5%, latency OK | Error > 2% |
| Expand | 25% | 12 hours | Metrics stable | Performance degradation |
| Expand | 50% | 24 hours | Business metrics OK | Business impact |
| Full | 100% | - | Stable for 72 hours | Any regression |

## Phase 6: Post-Deployment
1. Post-deployment validation
   - [ ] Verify model version serving correctly
   - [ ] Validate end-to-end prediction quality
   - [ ] Confirm monitoring and alerting working
   - [ ] Document deployment in model registry
   - [ ] Archive previous model version (keep for rollback)
   - [ ] Schedule model retraining pipeline
   - [ ] Set up data pipeline for ground truth collection

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Model Card**: Performance, limitations, and intended use
- **Deployment Runbook**: Step-by-step deployment procedures
- **Monitoring Dashboard**: Model health and drift metrics
- **Rollback Procedure**: Steps to revert to previous version
- **Retraining Schedule**: Automated retraining cadence

## Action Items
- [ ] Validate model meets performance thresholds
- [ ] Provision and test serving infrastructure
- [ ] Configure monitoring and drift detection
- [ ] Execute phased deployment with monitoring
- [ ] Validate post-deployment metrics
- [ ] Set up automated retraining pipeline
- [ ] Document model version and deployment details
