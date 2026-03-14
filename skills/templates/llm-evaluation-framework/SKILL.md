---
name: llm-evaluation-framework
enabled: true
description: |
  Provides a structured framework for evaluating large language models (LLMs) for production use. Covers task-specific benchmarking, safety testing, cost analysis, latency measurement, prompt engineering evaluation, and comparison across models to select the optimal LLM for a given use case.
required_connections:
  - prefix: llm-provider
    label: "LLM API Provider"
config_fields:
  - key: use_case
    label: "Target Use Case"
    required: true
    placeholder: "e.g., customer support chatbot, code generation, document summarization"
  - key: models_to_evaluate
    label: "Models to Evaluate"
    required: true
    placeholder: "e.g., GPT-4, Claude, Gemini, Llama 3, Mistral"
  - key: deployment_type
    label: "Deployment Type"
    required: false
    placeholder: "e.g., API, self-hosted, fine-tuned"
features:
  - DATA
  - AI
  - LLM
  - EVALUATION
---

# LLM Evaluation Framework

## Phase 1: Evaluation Criteria Definition
1. Define use case requirements
   - [ ] Task type (generation, classification, extraction, summarization, Q&A)
   - [ ] Input characteristics (length, language, domain)
   - [ ] Output requirements (format, length, structure)
   - [ ] Latency requirements (real-time vs. batch)
   - [ ] Throughput requirements (requests per minute)
   - [ ] Cost constraints (per-token or per-request budget)
   - [ ] Privacy and data residency requirements
   - [ ] Safety and content policy requirements
2. Define evaluation metrics and weights

### Evaluation Criteria Weights

| Criterion | Weight (%) | Minimum Threshold | Measurement Method |
|-----------|-----------|-------------------|-------------------|
| Task quality | % | | Human eval + automated metrics |
| Latency | % | < ms | P50, P95, P99 |
| Cost | % | < $/1K tokens | Token-based pricing |
| Safety | % | Pass all checks | Red team + automated |
| Reliability | % | > % uptime | API availability |
| Context window | % | > K tokens | Model spec |

## Phase 2: Evaluation Dataset Creation
1. Build evaluation datasets
   - [ ] Representative inputs from real use case
   - [ ] Edge cases and adversarial inputs
   - [ ] Multi-language inputs (if applicable)
   - [ ] Long-context inputs (if applicable)
   - [ ] Ground truth / reference outputs for automated scoring
   - [ ] Minimum 100+ examples per task category
2. Create human evaluation rubrics
3. Define automated evaluation metrics (BLEU, ROUGE, exact match, F1)

### Dataset Summary

| Category | Examples | Ground Truth | Difficulty | Purpose |
|----------|---------|-------------|-----------|---------|
| Standard inputs | | Yes/No | Normal | Baseline quality |
| Edge cases | | Yes/No | Hard | Robustness |
| Adversarial | | N/A | Hard | Safety |
| Domain-specific | | Yes/No | Variable | Domain fitness |
| Long context | | Yes/No | Variable | Context handling |

## Phase 3: Quality Evaluation
1. Run task-specific quality benchmarks
   - [ ] Generate outputs for all evaluation examples
   - [ ] Score with automated metrics
   - [ ] Conduct human evaluation on sample
   - [ ] Evaluate instruction following accuracy
   - [ ] Test structured output generation (JSON, XML)
   - [ ] Assess factual accuracy and hallucination rate
2. Compare across models

### Quality Comparison

| Model | Automated Score | Human Score (1-5) | Hallucination Rate | Instruction Following | Overall Quality |
|-------|----------------|------------------|-------------------|---------------------|----------------|
|       |                |                  | %                 | %                   | /100           |

## Phase 4: Performance & Cost Evaluation
1. Measure performance characteristics
   - [ ] Time to first token (TTFT)
   - [ ] Tokens per second (throughput)
   - [ ] P50, P95, P99 end-to-end latency
   - [ ] Latency under concurrent load
   - [ ] Rate limit behavior
   - [ ] Context window utilization impact on latency
2. Calculate cost per use case
   - [ ] Input token cost
   - [ ] Output token cost
   - [ ] Total cost per request (average)
   - [ ] Monthly projected cost at expected volume

### Performance & Cost Comparison

| Model | TTFT (ms) | P50 (ms) | P95 (ms) | Tokens/sec | Input $/1M | Output $/1M | Cost/Request |
|-------|----------|---------|---------|-----------|-----------|------------|-------------|
|       |          |         |         |           | $         | $          | $           |

## Phase 5: Safety & Reliability Evaluation
1. Test safety and content policies
   - [ ] Harmful content generation resistance
   - [ ] PII handling and redaction
   - [ ] Bias in outputs across demographics
   - [ ] Jailbreak resistance
   - [ ] Content policy compliance
   - [ ] Confidentiality (does not leak training data)
2. Test reliability
   - [ ] API uptime and error rates
   - [ ] Consistency of outputs (temperature=0 determinism)
   - [ ] Graceful degradation under load
   - [ ] Rate limit recovery behavior

## Phase 6: Selection & Recommendation
1. Score each model across all criteria
2. Apply weights to calculate overall score
3. Consider operational factors (vendor relationship, support, SLA)
4. Evaluate fine-tuning potential if needed
5. Make recommendation with justification

### Final Comparison Matrix

| Model | Quality | Latency | Cost | Safety | Reliability | Weighted Score | Rank |
|-------|---------|---------|------|--------|-------------|---------------|------|
|       | /100    | /100    | /100 | /100   | /100        | /100          |      |

## Output Format
- **Evaluation Dataset**: Test cases with ground truth
- **Quality Report**: Per-model quality metrics and human eval results
- **Performance Report**: Latency and throughput benchmarks
- **Cost Analysis**: Per-model cost projections at expected volume
- **Recommendation**: Selected model with justification and tradeoffs

## Action Items
- [ ] Define evaluation criteria and weights for use case
- [ ] Build evaluation dataset with representative examples
- [ ] Run quality benchmarks across candidate models
- [ ] Measure performance and calculate costs
- [ ] Conduct safety and reliability testing
- [ ] Select model and document decision rationale
- [ ] Set up monitoring for model quality in production
