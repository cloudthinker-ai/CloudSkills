---
name: memory-leak-investigation
enabled: true
description: |
  Use when performing memory leak investigation — provides a systematic
  methodology for detecting, diagnosing, and resolving memory leaks in
  production applications. Covers heap analysis, allocation profiling, leak
  pattern identification, garbage collection tuning, and validation procedures
  across common runtime environments.
required_connections:
  - prefix: apm
    label: "APM / Profiling Platform"
  - prefix: monitoring
    label: "Monitoring Platform"
config_fields:
  - key: runtime
    label: "Application Runtime"
    required: true
    placeholder: "e.g., JVM (Java 17), Node.js 20, Python 3.12, Go 1.22, .NET 8"
  - key: symptom
    label: "Primary Symptom"
    required: true
    placeholder: "e.g., OOM kills, growing RSS, increasing GC pauses"
  - key: time_to_oom
    label: "Approximate Time to OOM"
    required: false
    placeholder: "e.g., 6 hours, 3 days"
features:
  - PERFORMANCE
  - DEBUGGING
  - MEMORY
---

# Memory Leak Investigation

## Phase 1: Symptom Confirmation
1. Verify memory leak exists
   - [ ] Memory usage grows continuously over time (not plateauing)
   - [ ] Memory not reclaimed after GC cycles
   - [ ] OOM kills or restarts observed
   - [ ] GC pause times increasing over time
   - [ ] Application performance degrades over uptime
2. Establish the leak rate (MB/hour or MB/day)
3. Determine if leak correlates with specific operations
4. Check when the leak started (deployment, config change, traffic change)

### Memory Growth Profile

| Metric | At Start | After 1hr | After 6hr | After 24hr | Trend |
|--------|---------|----------|----------|-----------|-------|
| Heap used (MB) | | | | | +MB/hr |
| RSS (MB) | | | | | |
| GC frequency | | | | | |
| GC pause (ms) | | | | | |
| Live objects | | | | | |

## Phase 2: Heap Snapshot Analysis
1. Capture heap snapshots at intervals
   - Snapshot 1: Shortly after application start
   - Snapshot 2: After several hours of operation
   - Snapshot 3: When memory is significantly elevated
2. Compare snapshots to identify growing object types
3. Find objects that should be garbage collected but are retained
4. Identify the retention path from GC root to leaked objects

### Top Growing Object Types

| Object Type | Count (T1) | Count (T2) | Size (T1) | Size (T2) | Growth Rate | Suspect |
|------------|-----------|-----------|----------|----------|-------------|---------|
|            |           |           | MB       | MB       | MB/hr       | [ ]     |

## Phase 3: Allocation Profiling
1. Enable allocation tracking in profiler
2. Identify hot allocation sites (where leaked objects are created)
3. Trace allocation call stacks for suspected object types
4. Correlate allocations with specific request types or code paths
5. Check for known leak patterns

### Common Leak Patterns Checklist

| Pattern | Description | Detected |
|---------|-------------|----------|
| Event listener accumulation | Listeners added but never removed | [ ] |
| Cache without eviction | Unbounded cache or map growth | [ ] |
| Connection/stream not closed | DB connections, file handles, HTTP connections | [ ] |
| Circular references | Objects preventing GC (weak references needed) | [ ] |
| Static/global collections | Collections growing without bounds | [ ] |
| Timer/interval not cleared | Scheduled tasks holding references | [ ] |
| Thread-local accumulation | Thread-local storage not cleaned | [ ] |
| Closure capturing | Closures retaining large scope references | [ ] |
| Native memory leak | JNI, native buffers, off-heap allocations | [ ] |

## Phase 4: Root Cause Isolation
1. Reproduce the leak in a controlled environment
2. Narrow down to specific code module or dependency
3. Write a minimal reproduction if possible
4. Verify the root cause with targeted profiling
5. Document the leak mechanism

### Root Cause Analysis

| Finding | Code Location | Leak Mechanism | Impact | Fix Approach |
|---------|-------------|---------------|--------|-------------|
|         | file:line   |               | MB/hr  |             |

## Phase 5: Fix Implementation
1. Implement the fix
   - [ ] Add proper resource cleanup (close, dispose, remove listener)
   - [ ] Add eviction policy to caches (LRU, TTL, size limit)
   - [ ] Fix object lifecycle management
   - [ ] Use weak references where appropriate
   - [ ] Add connection pool limits and timeout
2. Add defensive measures
   - [ ] Add memory usage logging
   - [ ] Implement resource tracking in development mode
   - [ ] Add unit tests for resource cleanup

## Phase 6: Validation
1. Deploy fix and monitor memory profile
2. Verify memory stabilizes at expected level
3. Run extended soak test (48+ hours)
4. Compare memory profile against pre-leak baseline
5. Set up ongoing memory monitoring and alerts

### Validation Results

| Metric | Before Fix | After Fix | Target | Status |
|--------|-----------|----------|--------|--------|
| Heap growth rate | MB/hr | MB/hr | ~0 MB/hr | Pass/Fail |
| Stable heap size | N/A (growing) | MB | < MB | |
| GC pause P95 | ms | ms | < ms | |
| OOM incidents/week | | 0 | 0 | |

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format
- **Leak Confirmation**: Growth rate and correlation analysis
- **Heap Analysis**: Object type growth and retention paths
- **Root Cause Report**: Code location and leak mechanism
- **Fix Description**: Changes made with rationale
- **Validation Report**: Post-fix memory stability proof

## Action Items
- [ ] Confirm memory leak with growth rate measurement
- [ ] Capture and compare heap snapshots
- [ ] Identify leaking object types and retention paths
- [ ] Isolate root cause to specific code
- [ ] Implement and test fix
- [ ] Validate with extended soak test
- [ ] Set up memory growth alerting to detect future leaks
