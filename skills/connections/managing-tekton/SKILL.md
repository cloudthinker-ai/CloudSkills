---
name: managing-tekton
description: |
  Tekton Pipelines management for Kubernetes-native CI/CD. Covers pipeline runs, task management, trigger bindings, event listeners, and workspace configuration. Use when checking pipeline execution, investigating task failures, managing triggers, or auditing Tekton resources in a Kubernetes cluster.
connection_type: tekton
preload: false
---

# Tekton Management Skill

Manage and monitor Tekton Pipelines, Tasks, and Triggers on Kubernetes.

## Core Helper Functions

```bash
#!/bin/bash

# Tekton CLI wrapper with namespace
tkn_cmd() {
    tkn "$@" --namespace "${TEKTON_NAMESPACE:-default}" 2>/dev/null
}

# kubectl wrapper for Tekton CRDs
tkn_k8s() {
    kubectl "$@" -n "${TEKTON_NAMESPACE:-default}" 2>/dev/null
}
```

## MANDATORY: Discovery-First Pattern

**Always list available pipelines, tasks, and triggers before querying specific runs.**

### Phase 1: Discovery

```bash
#!/bin/bash
NS="${TEKTON_NAMESPACE:-default}"

echo "=== Tekton Pipelines ==="
tkn_cmd pipeline list || \
    tkn_k8s get pipelines -o custom-columns="NAME:.metadata.name,AGE:.metadata.creationTimestamp"

echo ""
echo "=== Tekton Tasks ==="
tkn_cmd task list || \
    tkn_k8s get tasks -o custom-columns="NAME:.metadata.name,AGE:.metadata.creationTimestamp"

echo ""
echo "=== ClusterTasks ==="
tkn clustertask list 2>/dev/null || \
    kubectl get clustertasks -o custom-columns="NAME:.metadata.name" 2>/dev/null

echo ""
echo "=== Recent PipelineRuns ==="
tkn_cmd pipelinerun list --limit 15 || \
    tkn_k8s get pipelineruns -o custom-columns="NAME:.metadata.name,PIPELINE:.spec.pipelineRef.name,STATUS:.status.conditions[0].reason,START:.status.startTime" --sort-by=.status.startTime | tail -15

echo ""
echo "=== EventListeners ==="
tkn_k8s get eventlisteners -o custom-columns="NAME:.metadata.name,STATUS:.status.conditions[0].reason" 2>/dev/null
```

## Output Rules
- **TOKEN EFFICIENCY**: Target 50 lines per output
- Use `tkn` CLI for human-friendly output, `kubectl -o json | jq` for programmatic queries
- Never dump full task logs — extract step-level output

## Common Operations

### PipelineRun Status Dashboard

```bash
#!/bin/bash
NS="${TEKTON_NAMESPACE:-default}"

echo "=== PipelineRun Summary ==="
tkn_k8s get pipelineruns -o json | jq '{
    total: (.items | length),
    succeeded: [.items[] | select(.status.conditions[0].reason == "Succeeded")] | length,
    failed: [.items[] | select(.status.conditions[0].reason == "Failed")] | length,
    running: [.items[] | select(.status.conditions[0].reason == "Running")] | length,
    pending: [.items[] | select(.status.conditions[0].reason == "PipelineRunPending")] | length
}'

echo ""
echo "=== Failed PipelineRuns ==="
tkn_k8s get pipelineruns -o json | jq -r '
    .items[] | select(.status.conditions[0].reason == "Failed") |
    "\(.metadata.name)\t\(.spec.pipelineRef.name // "inline")\t\(.status.conditions[0].message[0:60])"
' | column -t | head -10

echo ""
echo "=== Running Pipelines ==="
tkn_cmd pipelinerun list --label tekton.dev/pipeline --limit 10 2>/dev/null || \
    tkn_k8s get pipelineruns --field-selector="status.conditions[0].reason=Running" -o custom-columns="NAME:.metadata.name,PIPELINE:.spec.pipelineRef.name,START:.status.startTime"
```

### TaskRun Analysis

```bash
#!/bin/bash
PIPELINE_RUN="${1:?PipelineRun name required}"
NS="${TEKTON_NAMESPACE:-default}"

echo "=== TaskRuns in PipelineRun ==="
tkn_cmd pipelinerun describe "$PIPELINE_RUN" 2>/dev/null || \
    tkn_k8s get taskruns -l "tekton.dev/pipelineRun=${PIPELINE_RUN}" -o json | jq -r '
        .items[] |
        "\(.metadata.name)\t\(.metadata.labels["tekton.dev/pipelineTask"])\t\(.status.conditions[0].reason)\t\(.status.startTime[0:16])"
    ' | column -t

echo ""
echo "=== Failed TaskRun Logs ==="
FAILED_TR=$(tkn_k8s get taskruns -l "tekton.dev/pipelineRun=${PIPELINE_RUN}" -o json | jq -r '
    .items[] | select(.status.conditions[0].reason == "Failed") | .metadata.name' | head -1)
if [ -n "$FAILED_TR" ]; then
    tkn_cmd taskrun logs "$FAILED_TR" 2>/dev/null || \
        tkn_k8s get taskrun "$FAILED_TR" -o json | jq -r '
            .status.steps[] | select(.terminated.exitCode != 0) |
            "Step: \(.name)\nExit: \(.terminated.exitCode)\nReason: \(.terminated.reason)"
        '
fi
```

### Task Management

```bash
#!/bin/bash
NS="${TEKTON_NAMESPACE:-default}"

echo "=== Pipeline Definition ==="
PIPELINE_NAME="${1:?Pipeline name required}"
tkn_k8s get pipeline "$PIPELINE_NAME" -o json | jq '{
    name: .metadata.name,
    params: [.spec.params[]? | {name, type, default}],
    tasks: [.spec.tasks[] | {name, taskRef: .taskRef.name, runAfter: .runAfter}],
    workspaces: [.spec.workspaces[]? | .name]
}'

echo ""
echo "=== Task Details ==="
TASK_NAME="${2:-}"
if [ -n "$TASK_NAME" ]; then
    tkn_k8s get task "$TASK_NAME" -o json | jq '{
        name: .metadata.name,
        params: [.spec.params[]? | {name, type, default}],
        steps: [.spec.steps[] | {name, image}],
        workspaces: [.spec.workspaces[]? | .name]
    }'
fi
```

### Trigger Bindings & Templates

```bash
#!/bin/bash
NS="${TEKTON_NAMESPACE:-default}"

echo "=== TriggerBindings ==="
tkn_k8s get triggerbindings -o json | jq -r '
    .items[] | "\(.metadata.name)\tparams=\([.spec.params[]? | .name] | join(","))"
' | column -t

echo ""
echo "=== TriggerTemplates ==="
tkn_k8s get triggertemplates -o json | jq -r '
    .items[] | "\(.metadata.name)\tparams=\([.spec.params[]? | .name] | join(","))"
' | column -t

echo ""
echo "=== EventListeners ==="
tkn_k8s get eventlisteners -o json | jq -r '
    .items[] |
    "\(.metadata.name)\tstatus=\(.status.conditions[0].reason // "unknown")\taddress=\(.status.address.url // "pending")"
' | column -t
```

### Pipeline Execution

```bash
#!/bin/bash
PIPELINE_NAME="${1:?Pipeline name required}"
DRY_RUN="${2:-true}"

if [ "$DRY_RUN" = "true" ]; then
    echo "=== DRY RUN: Pipeline params and workspaces ==="
    tkn_k8s get pipeline "$PIPELINE_NAME" -o json | jq '{
        required_params: [.spec.params[]? | select(.default == null) | .name],
        optional_params: [.spec.params[]? | select(.default != null) | {name, default}],
        workspaces: [.spec.workspaces[]? | {name, optional: .optional}]
    }'
    echo ""
    echo "To execute, use: tkn pipeline start $PIPELINE_NAME -p key=value -w name=pvc,claimName=my-pvc"
else
    echo "=== Starting Pipeline ==="
    tkn_cmd pipeline start "$PIPELINE_NAME" --showlog
fi
```

## Anti-Hallucination Rules
- NEVER guess PipelineRun or TaskRun names — always list first
- NEVER fabricate task step names — inspect the task definition
- NEVER assume namespace — Tekton resources are namespace-scoped
- ClusterTasks are cluster-scoped — do not add namespace when querying

## Safety Rules
- NEVER start pipelines without explicit user confirmation
- NEVER delete PipelineRuns or TaskRuns without user approval
- NEVER modify TriggerBindings without understanding downstream effects
- Pipeline execution may provision cloud resources — confirm intent

## Common Pitfalls
- **tkn vs kubectl**: `tkn` CLI provides better UX but requires installation — fall back to kubectl
- **ClusterTask deprecation**: ClusterTasks are deprecated in favor of Tekton Resolver — check version
- **Workspace binding**: PipelineRuns must bind workspaces — missing bindings cause failures
- **Finally tasks**: `finally` tasks always run regardless of pipeline success — check for cleanup tasks
- **Result propagation**: Task results are passed via `$(tasks.taskname.results.resultname)` — verify names exactly
- **Timeout defaults**: Default pipeline timeout is 1 hour — long builds may be killed silently
