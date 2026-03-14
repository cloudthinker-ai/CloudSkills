---
name: cpu-profiling-guide
enabled: true
description: |
  Guides systematic CPU profiling to identify and resolve CPU-bound performance bottlenecks. Covers profiler selection and setup, flame graph analysis, hot path identification, optimization strategies, and validation procedures for common language runtimes.
required_connections:
  - prefix: apm
    label: "APM / Profiling Platform"
config_fields:
  - key: runtime
    label: "Application Runtime"
    required: true
    placeholder: "e.g., JVM, Node.js, Python, Go, .NET, Rust"
  - key: symptom
    label: "Primary CPU Symptom"
    required: true
    placeholder: "e.g., high CPU at idle, CPU spikes under load, slow response times"
  - key: profiling_tool
    label: "Preferred Profiling Tool"
    required: false
    placeholder: "e.g., async-profiler, pprof, py-spy, perf, dotTrace"
features:
  - PERFORMANCE
  - DEBUGGING
  - CPU
---

# CPU Profiling Guide

## Phase 1: Symptom Assessment
1. Characterize the CPU issue
   - [ ] Sustained high CPU (> 80% continuously)
   - [ ] CPU spikes correlated with specific operations
   - [ ] High CPU at low traffic (idle CPU waste)
   - [ ] CPU-bound latency (slow responses despite available I/O)
   - [ ] One core saturated (single-threaded bottleneck)
2. Collect baseline metrics
   - [ ] CPU utilization per core and per process
   - [ ] Thread/goroutine count
   - [ ] Context switch rate
   - [ ] System vs. user CPU time ratio
3. Correlate CPU with application events (requests, jobs, deployments)

### CPU Baseline

| Metric | Current | Normal Baseline | Status |
|--------|---------|-----------------|--------|
| Overall CPU | % | % | |
| User CPU | % | % | |
| System CPU | % | % | |
| Context switches/sec | | | |
| Active threads | | | |
| Load average | | | |

## Phase 2: Profiler Setup
1. Select appropriate profiler for runtime
   - JVM: async-profiler, JFR (Java Flight Recorder)
   - Node.js: --prof, 0x, clinic.js
   - Python: py-spy, cProfile, Pyroscope
   - Go: pprof (built-in)
   - .NET: dotTrace, PerfView
   - Native: perf, Instruments (macOS)
2. Configure profiler with minimal overhead (< 2% CPU impact)
3. Choose sampling rate (typically 99Hz or 997Hz)
4. Profile in production or production-like environment
5. Capture profiles during problematic period

## Phase 3: Flame Graph Analysis
1. Generate flame graphs from profile data
2. Analyze flame graph patterns
   - [ ] Wide plateaus: functions consuming most CPU time
   - [ ] Deep stacks: excessive call depth or recursion
   - [ ] Repeated patterns: hot loops
   - [ ] Framework vs. application code ratio
3. Identify top CPU-consuming functions

### Top CPU Consumers

| Function | Self Time % | Total Time % | Calls/sec | Category | Actionable |
|----------|-----------|-------------|----------|----------|-----------|
|          | %         | %           |          | App/Framework/GC | Yes/No |

## Phase 4: Hot Path Investigation
1. Investigate top CPU consumers
   - [ ] Inefficient algorithms (O(n^2) or worse)
   - [ ] Unnecessary computation in hot paths
   - [ ] Excessive object allocation triggering GC
   - [ ] Serialization/deserialization overhead
   - [ ] Regular expression backtracking
   - [ ] Logging in tight loops
   - [ ] Lock contention causing spin-waits
   - [ ] Redundant computation (missing caching)
2. Review code for identified hot functions
3. Check if work can be avoided, cached, or batched

### Root Cause Checklist

| Issue Type | Location | CPU Impact % | Fix Effort | Priority |
|-----------|----------|-------------|-----------|----------|
| Algorithmic inefficiency | | % | | |
| Excessive GC pressure | | % | | |
| Unnecessary computation | | % | | |
| Missing cache | | % | | |
| Lock contention | | % | | |

## Phase 5: Optimization Implementation
1. Apply targeted optimizations
   - [ ] Replace inefficient algorithms
   - [ ] Add caching for repeated computations
   - [ ] Reduce allocation rate in hot paths
   - [ ] Move work off hot path (async, batch, lazy)
   - [ ] Optimize data structures
   - [ ] Reduce serialization overhead
   - [ ] Fix lock contention (finer-grained locks, lock-free)
2. Benchmark each optimization in isolation
3. Verify no functionality regression

## Phase 6: Validation
1. Re-profile after optimizations
2. Generate comparison flame graphs (before vs. after)
3. Verify CPU utilization reduction
4. Load test to confirm improvement under peak traffic
5. Monitor for regressions over time

### Optimization Results

| Optimization | Before (CPU %) | After (CPU %) | Reduction | Latency Impact |
|-------------|---------------|-------------|-----------|----------------|
|             | %             | %           | -%        | -ms            |
| **Total**   | **%**         | **%**       | **-%**    | **-ms**        |

## Output Format
- **CPU Baseline**: Metrics before optimization
- **Flame Graphs**: Before and after comparison
- **Hot Path Analysis**: Top CPU consumers with root causes
- **Optimization Summary**: Changes made with measured impact
- **Monitoring Setup**: Continuous profiling and CPU alerts

## Action Items
- [ ] Collect CPU baseline and characterize the problem
- [ ] Set up profiler in production-like environment
- [ ] Capture and analyze flame graphs
- [ ] Identify and prioritize hot path optimizations
- [ ] Implement and benchmark optimizations
- [ ] Validate with re-profiling and load testing
- [ ] Set up continuous profiling for future regressions
