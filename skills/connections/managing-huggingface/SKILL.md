---
name: managing-huggingface
description: |
  Hugging Face platform management. Covers model hub, datasets, spaces, inference endpoints, tokenizer inspection, and model card analysis. Use when searching for models, managing datasets, deploying inference endpoints, testing model outputs, or auditing Hugging Face organization resources.
connection_type: huggingface
preload: false
---

# Hugging Face Management Skill

Manage and monitor Hugging Face Hub models, datasets, spaces, and inference endpoints.

## MANDATORY: Discovery-First Pattern

**Always search and list existing resources before downloading or deploying anything.**

### Phase 1: Discovery

```bash
#!/bin/bash

HF_TOKEN="${HF_TOKEN:-$(cat ~/.cache/huggingface/token 2>/dev/null)}"

hf_api() {
    local endpoint="$1"
    curl -s -H "Authorization: Bearer $HF_TOKEN" \
        "https://huggingface.co/api/${endpoint}"
}

echo "=== Authenticated User ==="
hf_api "whoami-v2" | jq '{username: .name, orgs: [.orgs[]?.name]}'

echo ""
echo "=== My Models ==="
hf_api "models?author=$(hf_api whoami-v2 | jq -r .name)&limit=10" | jq -r '
    .[] | "\(.id)\t\(.downloads // 0) downloads\t\(.lastModified[0:10])"
' | column -t

echo ""
echo "=== My Datasets ==="
hf_api "datasets?author=$(hf_api whoami-v2 | jq -r .name)&limit=10" | jq -r '
    .[] | "\(.id)\t\(.downloads // 0) downloads\t\(.lastModified[0:10])"
' | column -t

echo ""
echo "=== My Spaces ==="
hf_api "spaces?author=$(hf_api whoami-v2 | jq -r .name)&limit=10" | jq -r '
    .[] | "\(.id)\t\(.sdk // "unknown")\t\(.lastModified[0:10])"
' | column -t

echo ""
echo "=== Inference Endpoints ==="
curl -s -H "Authorization: Bearer $HF_TOKEN" \
    "https://api.endpoints.huggingface.cloud/v2/endpoint" 2>/dev/null \
    | jq -r '.items[]? | "\(.name)\t\(.status.state)\t\(.model.repository)\t\(.compute.instanceType)"' | column -t
```

## Core Helper Functions

```bash
#!/bin/bash

HF_TOKEN="${HF_TOKEN:-$(cat ~/.cache/huggingface/token 2>/dev/null)}"

# Hugging Face Hub API helper
hf_api() {
    local endpoint="$1"
    curl -s -H "Authorization: Bearer $HF_TOKEN" \
        "https://huggingface.co/api/${endpoint}"
}

# Inference API helper
hf_infer() {
    local model="$1"
    local data="$2"
    curl -s -X POST -H "Authorization: Bearer $HF_TOKEN" \
        -H "Content-Type: application/json" \
        "https://api-inference.huggingface.co/models/${model}" -d "$data"
}

# huggingface-cli wrapper
hf_cli() {
    huggingface-cli "$@" 2>/dev/null
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target ≤50 lines per output
- Use Hub API with jq for structured queries
- Never dump full model configs -- extract key architecture details
- Truncate long model/dataset descriptions to first 100 characters

## Common Operations

### Model Hub Search and Inspection

```bash
#!/bin/bash
QUERY="${1:?Search query required}"
TASK="${2:-}"

echo "=== Model Search: $QUERY ==="
FILTER=""
if [ -n "$TASK" ]; then
    FILTER="&pipeline_tag=${TASK}"
fi
hf_api "models?search=${QUERY}${FILTER}&sort=downloads&direction=-1&limit=10" | jq -r '
    .[] | "\(.id)\t\(.pipeline_tag // "N/A")\t\(.downloads // 0) downloads\t\(.likes // 0) likes"
' | column -t

MODEL_ID="${3:-}"
if [ -n "$MODEL_ID" ]; then
    echo ""
    echo "=== Model Details: $MODEL_ID ==="
    hf_api "models/${MODEL_ID}" | jq '{
        id: .id,
        pipeline_tag: .pipeline_tag,
        library: .library_name,
        tags: .tags[:10],
        downloads: .downloads,
        likes: .likes,
        last_modified: .lastModified,
        model_size: .safetensors.total,
        license: (.tags[] | select(startswith("license:")) // "unknown")
    }'
fi
```

### Dataset Management

```bash
#!/bin/bash
QUERY="${1:-}"

if [ -n "$QUERY" ]; then
    echo "=== Dataset Search: $QUERY ==="
    hf_api "datasets?search=${QUERY}&sort=downloads&direction=-1&limit=10" | jq -r '
        .[] | "\(.id)\t\(.downloads // 0) downloads\t\(.lastModified[0:10])"
    ' | column -t
fi

DATASET_ID="${2:-}"
if [ -n "$DATASET_ID" ]; then
    echo ""
    echo "=== Dataset Details: $DATASET_ID ==="
    hf_api "datasets/${DATASET_ID}" | jq '{
        id: .id,
        description: (.description // "" | .[0:100]),
        downloads: .downloads,
        tags: .tags[:10],
        splits: .cardData.dataset_info.splits,
        size: .cardData.dataset_info.dataset_size
    }'

    echo ""
    echo "=== Dataset Files ==="
    hf_api "datasets/${DATASET_ID}/tree/main" | jq -r '
        .[] | "\(.type)\t\(.path)\t\(.size // "-")"
    ' | column -t | head -15
fi
```

### Spaces Management

```bash
#!/bin/bash
echo "=== My Spaces ==="
USERNAME=$(hf_api "whoami-v2" | jq -r '.name')
hf_api "spaces?author=${USERNAME}&limit=15" | jq -r '
    .[] | "\(.id)\t\(.sdk // "unknown")\t\(.status // "unknown")\t\(.lastModified[0:10])"
' | column -t

SPACE_ID="${1:-}"
if [ -n "$SPACE_ID" ]; then
    echo ""
    echo "=== Space Details: $SPACE_ID ==="
    hf_api "spaces/${SPACE_ID}" | jq '{
        id: .id,
        sdk: .sdk,
        sdk_version: .sdk_version,
        status: .status,
        hardware: .hardware,
        last_modified: .lastModified
    }'

    echo ""
    echo "=== Space Runtime ==="
    hf_api "spaces/${SPACE_ID}/runtime" | jq '{
        stage: .stage,
        hardware: .hardware.current,
        storage: .storage
    }' 2>/dev/null
fi
```

### Inference Endpoints

```bash
#!/bin/bash
echo "=== Inference Endpoints ==="
curl -s -H "Authorization: Bearer $HF_TOKEN" \
    "https://api.endpoints.huggingface.cloud/v2/endpoint" 2>/dev/null \
    | jq -r '.items[]? | "\(.name)\t\(.status.state)\t\(.model.repository)\t\(.compute.instanceType)\t\(.compute.scaling.minReplica)-\(.compute.scaling.maxReplica) replicas"' | column -t

ENDPOINT_NAME="${1:-}"
NAMESPACE="${2:-}"
if [ -n "$ENDPOINT_NAME" ] && [ -n "$NAMESPACE" ]; then
    echo ""
    echo "=== Endpoint Detail: $ENDPOINT_NAME ==="
    curl -s -H "Authorization: Bearer $HF_TOKEN" \
        "https://api.endpoints.huggingface.cloud/v2/endpoint/${NAMESPACE}/${ENDPOINT_NAME}" 2>/dev/null \
        | jq '{
            name: .name,
            status: .status,
            model: .model,
            compute: .compute,
            url: .status.url
        }'
fi
```

### Tokenizer Inspection

```bash
#!/bin/bash
MODEL_ID="${1:?Model ID required}"

echo "=== Tokenizer Config ==="
hf_api "models/${MODEL_ID}/tree/main" | jq -r '
    .[] | select(.path | test("tokenizer|vocab"; "i")) | "\(.path)\t\(.size)"
' | column -t

echo ""
echo "=== Model Config ==="
curl -s -H "Authorization: Bearer $HF_TOKEN" \
    "https://huggingface.co/${MODEL_ID}/resolve/main/config.json" 2>/dev/null \
    | jq '{
        model_type: .model_type,
        vocab_size: .vocab_size,
        hidden_size: .hidden_size,
        num_layers: .num_hidden_layers,
        num_heads: .num_attention_heads,
        max_position_embeddings: .max_position_embeddings
    }' 2>/dev/null || echo "config.json not found or not accessible"
```

## Safety Rules

- **NEVER delete public models or datasets** without explicit confirmation -- they may have external dependents
- **NEVER share API tokens** in code or logs -- use environment variables or secret managers
- **Always check model licenses** before using models -- some licenses restrict commercial use
- **Inference endpoint costs**: GPU endpoints incur hourly charges even when idle -- pause or scale to zero when not in use
- **Private model access**: Verify access permissions before sharing private models with teams

## Common Pitfalls

- **Token permissions**: Read tokens cannot push models -- use write tokens for uploads
- **Model size**: Large models (>10GB) require `git-lfs` for upload -- standard git push will fail
- **Inference API cold starts**: Free inference API has cold starts -- first request may timeout
- **Gated models**: Some models require accepting terms before access -- API returns 403 until terms are accepted
- **Space hardware**: Free tier Spaces have limited resources -- large models need upgraded hardware
- **Dataset streaming**: Large datasets should use streaming mode -- downloading full datasets can exhaust disk space
- **Model card validation**: Missing model cards reduce discoverability -- always include README.md with model metadata
- **Revision pinning**: Always pin model revisions in production -- "main" branch can change unexpectedly
