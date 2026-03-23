---
name: mobile-code-review
enabled: true
description: |
  Use when performing mobile code review — mobile application code review
  template covering battery efficiency, memory management, offline-first
  patterns, permission handling, app lifecycle management, and platform-specific
  best practices. Provides a systematic review framework for iOS, Android, React
  Native, and Flutter mobile applications.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: repository
    label: "Repository"
    required: true
    placeholder: "e.g., org/mobile-app"
  - key: pr_number
    label: "PR Number"
    required: true
    placeholder: "e.g., 1234"
  - key: platform
    label: "Mobile Platform"
    required: true
    placeholder: "e.g., iOS, Android, React Native, Flutter"
features:
  - CODE_REVIEW
---

# Mobile Code Review Skill

Review mobile PR **#{{ pr_number }}** in **{{ repository }}** for **{{ platform }}**.

## Workflow

### Phase 1 — Battery and Resource Efficiency

```
BATTERY / RESOURCES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Background processing:
    [ ] Background tasks use appropriate APIs (WorkManager, BGTaskScheduler)
    [ ] No unnecessary wake locks or alarms
    [ ] Location tracking uses appropriate accuracy level
    [ ] Background fetch intervals are reasonable
[ ] Network efficiency:
    [ ] Batch network requests where possible
    [ ] Compression used for large payloads
    [ ] Polling replaced with push notifications where possible
    [ ] Network requests respect low-data mode
[ ] CPU usage:
    [ ] Heavy computation offloaded from main thread
    [ ] No busy-wait loops
    [ ] Animation frame rates appropriate (60fps)
    [ ] Image processing uses optimized libraries
```

### Phase 2 — Memory Management

```
MEMORY REVIEW
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Leak prevention:
    [ ] No retain cycles (weak references for delegates/closures)
    [ ] Observers/listeners removed on destroy
    [ ] Large bitmaps recycled/downsampled
    [ ] Caches bounded with eviction policies
[ ] Memory usage:
    [ ] Images loaded at display resolution (not full size)
    [ ] RecyclerView/UICollectionView used for lists
    [ ] View recycling implemented correctly
    [ ] Memory warnings handled (didReceiveMemoryWarning)
```

### Phase 3 — Offline and Data

```
OFFLINE SUPPORT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Offline-first:
    [ ] App functions without network (degraded mode)
    [ ] Local data persisted (SQLite, Core Data, Room)
    [ ] Sync conflicts handled gracefully
    [ ] Queue operations for offline execution
[ ] Data management:
    [ ] Database migrations tested
    [ ] Sensitive data encrypted at rest
    [ ] Cache expiration policies defined
    [ ] Data cleanup on logout/account deletion
```

### Phase 4 — Permissions and Security

```
PERMISSIONS / SECURITY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Permissions:
    [ ] Only necessary permissions requested
    [ ] Runtime permissions requested in context
    [ ] Graceful degradation if permission denied
    [ ] Permission rationale shown to user
[ ] Security:
    [ ] API keys not embedded in app binary
    [ ] Certificate pinning for sensitive endpoints
    [ ] Biometric/PIN for sensitive operations
    [ ] No sensitive data in logs or crash reports
    [ ] ProGuard/R8 obfuscation enabled (Android)
    [ ] App Transport Security configured (iOS)
```

### Phase 5 — App Lifecycle

```
LIFECYCLE MANAGEMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] State preservation:
    [ ] State saved on background/destroy
    [ ] State restored on foreground/recreate
    [ ] Deep links handled correctly
    [ ] Push notification handling in all states
[ ] Error handling:
    [ ] Crash reporting integrated
    [ ] Network errors shown to user
    [ ] Retry mechanisms for transient failures
    [ ] Graceful degradation for API version mismatches
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

Produce a mobile review report with:
1. **Resource efficiency** (battery, memory, network impact)
2. **Offline capability** assessment
3. **Security and permission** findings
4. **Platform-specific** concerns
5. **User experience** impact analysis
