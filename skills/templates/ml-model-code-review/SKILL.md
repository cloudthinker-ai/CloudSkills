---
name: ml-model-code-review
enabled: true
description: |
  ML/AI code review template covering data leakage detection, model reproducibility, bias assessment, feature engineering validation, and experiment tracking. Provides a systematic review framework for machine learning pipelines, model training code, and inference service changes.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: repository
    label: "Repository"
    required: true
    placeholder: "e.g., org/ml-pipeline"
  - key: pr_number
    label: "PR Number"
    required: true
    placeholder: "e.g., 1234"
  - key: model_type
    label: "Model Type"
    required: false
    placeholder: "e.g., classification, NLP, computer vision, recommendation"
features:
  - CODE_REVIEW
---

# ML Model Code Review Skill

Review ML PR **#{{ pr_number }}** in **{{ repository }}** for **{{ model_type }}** model.

## Workflow

### Phase 1 — Data Leakage

```
DATA LEAKAGE CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Train/test split:
    [ ] Data split before any preprocessing
    [ ] No information from test set in training
    [ ] Temporal splits for time-series data
    [ ] Group-aware splits (same entity not in both sets)
[ ] Feature leakage:
    [ ] No target-derived features
    [ ] No future data used in features
    [ ] No features unavailable at inference time
    [ ] Label encoding fit only on training data
[ ] Preprocessing leakage:
    [ ] Scalers/normalizers fit only on training data
    [ ] Imputation values from training data only
    [ ] Feature selection based on training data only
```

### Phase 2 — Reproducibility

```
REPRODUCIBILITY CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Random seeds:
    [ ] Random seeds set for all stochastic operations
    [ ] Seeds documented and versioned
    [ ] Deterministic mode enabled where possible
[ ] Experiment tracking:
    [ ] Hyperparameters logged (MLflow, W&B, etc.)
    [ ] Training metrics tracked
    [ ] Model artifacts versioned
    [ ] Data version recorded (DVC, dataset hash)
[ ] Environment:
    [ ] Dependencies pinned (requirements.txt / conda.yml)
    [ ] GPU/CUDA version documented
    [ ] Docker image versioned for training environment
```

### Phase 3 — Bias and Fairness

```
BIAS ASSESSMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Data bias:
    [ ] Training data representative of target population
    [ ] Class imbalance addressed (oversampling, weights)
    [ ] Protected attributes identified
    [ ] Demographic parity evaluated
[ ] Model bias:
    [ ] Performance metrics computed per subgroup
    [ ] Disparate impact ratio calculated
    [ ] Fairness constraints applied if needed
    [ ] Bias mitigation documented
[ ] Documentation:
    [ ] Model card created/updated
    [ ] Known limitations documented
    [ ] Intended use cases specified
```

### Phase 4 — Model Quality

```
MODEL QUALITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Evaluation:
    [ ] Appropriate metrics for task (not just accuracy)
    [ ] Evaluation on held-out test set
    [ ] Cross-validation where appropriate
    [ ] Baseline comparison provided
[ ] Production readiness:
    [ ] Model size acceptable for deployment target
    [ ] Inference latency within SLA
    [ ] Model serialization format compatible
    [ ] Input validation at inference time
    [ ] Graceful handling of missing/malformed features
    [ ] A/B test plan for model rollout
```

## Output Format

Produce an ML review report with:
1. **Data leakage findings** (none / potential / confirmed)
2. **Reproducibility assessment** (reproducible / partially / not reproducible)
3. **Bias and fairness** evaluation
4. **Model quality** metrics vs baseline
5. **Production readiness** checklist status
