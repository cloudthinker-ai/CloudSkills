---
name: gcp-cloud-build
description: |
  Use when working with Gcp Cloud Build — google Cloud Build trigger management,
  build history analysis, worker pool configuration, artifact management, and
  CI/CD pipeline diagnostics via gcloud CLI.
connection_type: gcp
preload: false
---

# Cloud Build Skill

Manage and analyze Google Cloud Build using `gcloud builds` commands.

## Discovery-First Rule

**ALWAYS discover before acting.** Never assume trigger names, build IDs, or worker pool names.

```bash
# Discover build triggers
gcloud builds triggers list --format=json \
  | jq '[.[] | {name: .name, id: .id, description: .description, disabled: .disabled, eventType: (if .github then "github" elif .triggerTemplate then "csr" elif .pubsubConfig then "pubsub" else "manual" end), createTime: .createTime}]'
```

## Parallel Execution Requirement

**ALL independent operations MUST run in parallel using background jobs (&) and wait.**

```bash
for trigger_id in $(gcloud builds triggers list --format="value(id)"); do
  {
    gcloud builds triggers describe "$trigger_id" --format=json
  } &
done
wait
```

## Helper Functions

```bash
# Get recent builds
list_builds() {
  local limit="${1:-25}"
  gcloud builds list --limit="$limit" --format=json \
    | jq '[.[] | {id: .id, status: .status, startTime: .startTime, duration: .duration, source: .substitutions.REPO_NAME // .source.repoSource.repoName, branch: .substitutions.BRANCH_NAME, trigger: .buildTriggerId}]'
}

# Get build details
get_build_details() {
  local build_id="$1"
  gcloud builds describe "$build_id" --format=json \
    | jq '{id: .id, status: .status, startTime: .startTime, finishTime: .finishTime, duration: .duration, steps: [.steps[] | {name: .name, status: .status, timing: .timing}], artifacts: .artifacts, logUrl: .logUrl}'
}

# List worker pools
list_worker_pools() {
  local region="$1"
  gcloud builds worker-pools list --region="$region" --format=json \
    | jq '[.[] | {name: .name, state: .state, machineType: .privatePoolV1Config.workerConfig.machineType, diskSizeGb: .privatePoolV1Config.workerConfig.diskSizeGb, network: .privatePoolV1Config.networkConfig}]'
}

# Get build logs
get_build_logs() {
  local build_id="$1"
  gcloud builds log "$build_id" 2>&1 | tail -100
}
```

## Common Operations

### 1. Build Health Overview

```bash
# Recent builds with status summary
gcloud builds list --limit=50 --format=json \
  | jq '{total: length, success: [.[] | select(.status=="SUCCESS")] | length, failure: [.[] | select(.status=="FAILURE")] | length, timeout: [.[] | select(.status=="TIMEOUT")] | length, cancelled: [.[] | select(.status=="CANCELLED")] | length, builds: [.[:10][] | {id: .id[:8], status: .status, duration: .duration, trigger: .buildTriggerId}]}'
```

### 2. Trigger Management

```bash
# List all triggers with config
gcloud builds triggers list --format=json \
  | jq '[.[] | {name: .name, id: .id, disabled: .disabled, github: .github, triggerTemplate: .triggerTemplate, filename: .filename, includedFiles: .includedFiles, ignoredFiles: .ignoredFiles, substitutions: .substitutions}]'

# Check disabled triggers
gcloud builds triggers list --format=json \
  | jq '[.[] | select(.disabled == true) | {name: .name, id: .id}]'
```

### 3. Build History and Failure Analysis

```bash
# Recent failures
gcloud builds list --filter="status=FAILURE" --limit=10 --format=json \
  | jq '[.[] | {id: .id, startTime: .startTime, duration: .duration, failedStep: (.steps[] | select(.status=="FAILURE") | .name), trigger: .buildTriggerId}]'

# Get failure details for a specific build
get_build_details "$BUILD_ID"
get_build_logs "$BUILD_ID"
```

### 4. Worker Pool Configuration

```bash
# List worker pools across regions
for region in us-central1 us-east1 europe-west1; do
  {
    echo "Region: $region"
    list_worker_pools "$region"
  } &
done
wait
```

### 5. Artifact Management

```bash
# Check artifact output from recent builds
gcloud builds list --limit=10 --format=json \
  | jq '[.[] | select(.artifacts) | {id: .id[:8], images: .images, artifacts: .artifacts.objects.location}]'

# List images built
gcloud builds list --limit=20 --format=json \
  | jq '[.[] | select(.images) | {id: .id[:8], images: .images, status: .status}]'
```

## Output Format

Present results as a structured report:
```
Gcp Cloud Build Report
══════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

## Anti-Hallucination Rules

1. **NEVER assume resource names** — always discover via CLI/API in Phase 1 before referencing in Phase 2.
2. **NEVER fabricate metric names or dimensions** — verify against the service documentation or `--help` output.
3. **NEVER mix CLI commands between service versions** — confirm which version/API you are targeting.
4. **ALWAYS use the discovery → verify → analyze chain** — every resource referenced must have been discovered first.
5. **ALWAYS handle empty results gracefully** — an empty response is valid data, not an error to retry.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

## Common Pitfalls

1. **Build timeout**: Default timeout is 10 minutes (600s). Long builds silently fail with TIMEOUT status. Check and set `--timeout` per trigger.
2. **Machine type**: Default machine type is `e2-standard-2`. CPU-intensive builds benefit from `e2-highcpu-8` or `e2-highcpu-32`. Check step durations.
3. **Source access**: Private GitHub repos require Cloud Build GitHub app installation. CSR repos need IAM permissions. Check source configuration on failures.
4. **Step ordering**: Steps run sequentially by default. Use `waitFor` with step IDs for parallel step execution in `cloudbuild.yaml`.
5. **Service account**: Cloud Build uses a default service account with broad permissions. For least-privilege, assign a custom service account per trigger.
