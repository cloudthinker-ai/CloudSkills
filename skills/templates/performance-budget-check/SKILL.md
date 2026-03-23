---
name: performance-budget-check
enabled: true
description: |
  Use when performing performance budget check — template for defining,
  measuring, and enforcing performance budgets across web applications and
  services. Covers Core Web Vitals targets, bundle size limits, API latency
  thresholds, resource loading budgets, and regression detection to maintain
  fast user experiences.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: application_name
    label: "Application Name"
    required: true
    placeholder: "e.g., customer-portal"
  - key: target_lcp
    label: "Target LCP (ms)"
    required: false
    placeholder: "e.g., 2500"
  - key: target_bundle_size
    label: "Target Bundle Size (KB)"
    required: false
    placeholder: "e.g., 250"
features:
  - ENGINEERING
  - PERFORMANCE
---

# Performance Budget Check Skill

Evaluate performance budget compliance for **{{ application_name }}**.

## Workflow

### Phase 1 — Budget Definition

```
PERFORMANCE BUDGETS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Core Web Vitals:
  LCP (Largest Contentful Paint):  target {{ target_lcp }}ms | actual ___ms
  FID (First Input Delay):         target 100ms              | actual ___ms
  CLS (Cumulative Layout Shift):   target 0.1                | actual ___
  INP (Interaction to Next Paint): target 200ms              | actual ___ms

Bundle Size:
  Main bundle:     target {{ target_bundle_size }}KB | actual ___KB
  Total JS:        target ___KB                      | actual ___KB
  Total CSS:       target ___KB                      | actual ___KB
  Total images:    target ___KB                      | actual ___KB

API Latency:
  P50:  target ___ms  | actual ___ms
  P95:  target ___ms  | actual ___ms
  P99:  target ___ms  | actual ___ms

Time to Interactive: target ___ms  | actual ___ms
```

### Phase 2 — Measurement

```
MEASUREMENT METHODOLOGY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Lab data collected:
    [ ] Lighthouse CI run
    [ ] WebPageTest
    [ ] Bundle analyzer
[ ] Field data collected:
    [ ] RUM (Real User Monitoring)
    [ ] CrUX (Chrome User Experience Report)
[ ] Test conditions:
    - Network: [ ] 4G  [ ] 3G  [ ] Cable
    - Device: [ ] Mobile  [ ] Desktop
    - Region: ___
```

### Phase 3 — Budget Compliance

```
COMPLIANCE CHECK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Metric               | Budget | Actual | Status    | Delta
━━━━━━━━━━━━━━━━━━━━━|━━━━━━━━|━━━━━━━━|━━━━━━━━━━━|━━━━━━
LCP                  |        |        | PASS/FAIL |
FID                  |        |        | PASS/FAIL |
CLS                  |        |        | PASS/FAIL |
INP                  |        |        | PASS/FAIL |
Main bundle size     |        |        | PASS/FAIL |
Total JS             |        |        | PASS/FAIL |
API P95 latency      |        |        | PASS/FAIL |
TTI                  |        |        | PASS/FAIL |

Overall: ___ / ___ budgets met
```

### Phase 4 — Regression Analysis

```
REGRESSION DETECTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Compare against previous release:
    - Metrics improved: ___
    - Metrics unchanged: ___
    - Metrics regressed: ___

[ ] Top regressions (if any):
    1. ___ : ___ms/KB increase (caused by ___)
    2. ___ : ___ms/KB increase (caused by ___)
    3. ___ : ___ms/KB increase (caused by ___)

[ ] Bundle size diff:
    - New dependencies added: ___
    - Largest new chunks: ___
    - Tree-shaking opportunities: ___
```

### Phase 5 — Optimization Recommendations

```
RECOMMENDATIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Priority | Recommendation              | Expected Impact
HIGH     | ___                          | ___
HIGH     | ___                          | ___
MEDIUM   | ___                          | ___
MEDIUM   | ___                          | ___
LOW      | ___                          | ___
```

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

Produce a performance budget report with:
1. **Budget scorecard** (all metrics with pass/fail status)
2. **Regression analysis** (changes from previous release)
3. **Top issues** (budget violations ranked by severity)
4. **Optimization recommendations** (prioritized action items)
5. **Trend data** (performance trajectory over recent releases)
