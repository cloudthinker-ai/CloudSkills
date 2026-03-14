---
name: load-testing-plan
enabled: true
description: |
  Designs a comprehensive load testing plan covering test scenario definition, workload modeling, environment preparation, tool selection, execution strategy, and results analysis. Supports stress testing, soak testing, spike testing, and capacity planning for web applications and APIs.
required_connections:
  - prefix: monitoring
    label: "Monitoring Platform"
config_fields:
  - key: target_application
    label: "Target Application or API"
    required: true
    placeholder: "e.g., api.example.com, checkout service"
  - key: expected_peak_load
    label: "Expected Peak Load"
    required: true
    placeholder: "e.g., 5,000 concurrent users, 10,000 req/s"
  - key: test_tool
    label: "Load Testing Tool"
    required: false
    placeholder: "e.g., k6, JMeter, Gatling, Locust"
features:
  - PERFORMANCE
  - TESTING
  - LOAD_TEST
---

# Load Testing Plan

## Phase 1: Test Objectives & Scenarios
1. Define load testing objectives
   - [ ] Validate system handles expected peak load
   - [ ] Identify breaking point (stress test)
   - [ ] Verify stability under sustained load (soak test)
   - [ ] Test behavior under sudden traffic spikes
   - [ ] Establish performance baselines
2. Define user scenarios and workflows
   - [ ] Identify critical user journeys
   - [ ] Define think times and pacing
   - [ ] Map API call sequences per scenario
   - [ ] Assign scenario weights based on production traffic

### Scenario Definition

| Scenario | Steps | Weight (%) | Think Time | Data Requirements |
|----------|-------|-----------|------------|-------------------|
| Browse products | | % | s | Product catalog |
| Search | | % | s | Search queries |
| Add to cart | | % | s | Product IDs |
| Checkout | | % | s | Payment test data |
| API integration | | % | s | API keys |

## Phase 2: Workload Model
1. Define load profiles
   - [ ] Baseline load: normal traffic pattern
   - [ ] Peak load: maximum expected concurrent users
   - [ ] Stress load: 1.5-2x peak to find breaking point
   - [ ] Soak load: sustained peak for 4-8 hours
   - [ ] Spike load: sudden jump from baseline to 3x peak
2. Define ramp-up and ramp-down patterns
3. Set performance acceptance criteria

### Performance Acceptance Criteria

| Metric | Target | Threshold (Warning) | Limit (Fail) |
|--------|--------|--------------------|----|
| Response time (P50) | < ms | < ms | < ms |
| Response time (P95) | < ms | < ms | < ms |
| Response time (P99) | < ms | < ms | < ms |
| Error rate | < % | < % | < % |
| Throughput | > req/s | > req/s | > req/s |
| CPU utilization | < % | < % | < % |
| Memory utilization | < % | < % | < % |

## Phase 3: Environment Preparation
1. Prepare test environment
   - [ ] Environment matches production configuration (or scaled ratio)
   - [ ] Test data seeded in databases
   - [ ] External dependencies stubbed or isolated
   - [ ] Monitoring and APM tools configured
   - [ ] Load generators provisioned (distributed if needed)
2. Validate load generator capacity is sufficient
3. Baseline the environment under zero load
4. Coordinate with dependent teams

## Phase 4: Test Script Development
1. Write test scripts per scenario
2. Parameterize test data (user credentials, product IDs, etc.)
3. Implement proper correlation for dynamic values
4. Add response validation assertions
5. Test scripts with single user before scaling
6. Version control all test artifacts

## Phase 5: Test Execution
1. Execute tests in order
   - Run 1: Baseline test (low load, validate scripts)
   - Run 2: Normal load test (expected average traffic)
   - Run 3: Peak load test (expected maximum)
   - Run 4: Stress test (beyond peak, find breaking point)
   - Run 5: Soak test (sustained load, 4-8 hours)
   - Run 6: Spike test (sudden load increase)
2. Collect metrics during each run
3. Document observations and anomalies
4. Allow system recovery between test runs

## Phase 6: Results Analysis & Reporting
1. Analyze results against acceptance criteria
2. Identify bottlenecks and their root causes
3. Generate performance comparison charts
4. Document capacity limits discovered
5. Provide optimization recommendations

### Results Summary

| Test Type | Max Users | P95 Latency | Error Rate | Throughput | Pass/Fail |
|-----------|----------|-------------|------------|------------|-----------|
| Baseline | | ms | % | req/s | |
| Peak | | ms | % | req/s | |
| Stress | | ms | % | req/s | |
| Soak | | ms | % | req/s | |
| Spike | | ms | % | req/s | |

## Output Format
- **Test Plan Document**: Scenarios, workload model, acceptance criteria
- **Test Scripts**: Version-controlled load test code
- **Execution Log**: Run results with timestamps and observations
- **Results Report**: Metrics, charts, bottleneck analysis
- **Recommendations**: Performance optimization actions

## Action Items
- [ ] Define test scenarios and acceptance criteria
- [ ] Prepare test environment and data
- [ ] Develop and validate test scripts
- [ ] Execute all test runs
- [ ] Analyze results and identify bottlenecks
- [ ] Present findings and recommendations to team
- [ ] Schedule follow-up test after optimizations
