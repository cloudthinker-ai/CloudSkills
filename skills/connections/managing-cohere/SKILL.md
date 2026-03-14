---
name: managing-cohere
description: |
  Cohere AI platform management covering models, embeddings, reranking, datasets, fine-tuning, and connectors. Use when monitoring API usage, analyzing model performance, reviewing fine-tuning jobs, managing datasets and connectors, or troubleshooting Cohere API issues.
connection_type: cohere
preload: false
---

# Cohere Management Skill

Manage and analyze Cohere AI platform resources including models, datasets, and fine-tuning.

## API Conventions

### Authentication
All API calls use Bearer API key, injected automatically.

### Base URL
`https://api.cohere.com/v1`

### Core Helper Function

```bash
#!/bin/bash

cohere_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $COHERE_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.cohere.com/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $COHERE_API_KEY" \
            "https://api.cohere.com/v1${endpoint}"
    fi
}
```

## Output Rules
- Target ≤50 lines per script output
- Use `jq` to extract only needed fields
- Never dump full API responses

## Phase 1: Discovery

```bash
#!/bin/bash
echo "=== Available Models ==="
cohere_api GET "/models" \
    | jq -r '.models[] | "\(.name)\t\(.endpoints | join(","))\t\(.context_length // "N/A")"' \
    | column -t | head -20

echo ""
echo "=== Connectors ==="
cohere_api GET "/connectors" \
    | jq -r '.connectors[] | "\(.id[0:16])\t\(.name)\t\(.active)\t\(.created_at[0:10])"' \
    | column -t | head -15

echo ""
echo "=== Datasets ==="
cohere_api GET "/datasets" \
    | jq -r '.datasets[] | "\(.id[0:16])\t\(.name[0:30])\t\(.dataset_type)\t\(.validation_status)\t\(.created_at[0:10])"' \
    | column -t | head -15

echo ""
echo "=== Fine-Tuning Jobs ==="
cohere_api GET "/finetuning/finetuned-models" \
    | jq -r '.finetuned_models[] | "\(.id[0:16])\t\(.name[0:30])\t\(.status)\t\(.created_at[0:10])"' \
    | head -10
```

## Phase 2: Analysis

### API Health & Usage

```bash
#!/bin/bash
echo "=== API Health Check ==="
RESULT=$(cohere_api POST "/chat" '{"message": "test", "model": "command-r", "max_tokens": 1}')
echo "$RESULT" | jq '{response_id: .response_id, model: .generation_id, meta: .meta}' 2>/dev/null \
    || echo "Error: $(echo $RESULT | jq -r '.message // "unknown"')"

echo ""
echo "=== Model Endpoints ==="
cohere_api GET "/models" \
    | jq -r '.models[] | {name: .name, endpoints: .endpoints}' | head -30
```

### Fine-Tuning & Dataset Health

```bash
#!/bin/bash
echo "=== Fine-Tuning Status Summary ==="
cohere_api GET "/finetuning/finetuned-models" \
    | jq -r '.finetuned_models[] | .status' | sort | uniq -c | sort -rn

echo ""
echo "=== Dataset Validation Status ==="
cohere_api GET "/datasets" \
    | jq -r '.datasets[] | .validation_status' | sort | uniq -c | sort -rn

echo ""
echo "=== Dataset Sizes ==="
cohere_api GET "/datasets" \
    | jq -r '.datasets[] | "\(.name[0:30])\t\(.dataset_parts[0].num_rows // "N/A") rows\t\(.size_bytes // 0) bytes"' \
    | column -t | head -10

echo ""
echo "=== Connector Health ==="
cohere_api GET "/connectors" \
    | jq -r '.connectors[] | "\(.name)\t\(.active)\t\(.url[0:40])"' | head -10
```

## Output Format

```
=== Cohere Platform ===
Models: <n>  Connectors: <n>  Datasets: <n>

--- Fine-Tuning ---
Active: <n>  Completed: <n>  Failed: <n>

--- Datasets ---
Total: <n>  Valid: <n>  Invalid: <n>

--- API Health ---
Status: <healthy|degraded>
```

## Common Pitfalls
- **Model names**: Use exact model IDs (e.g., `command-r`, `command-r-plus`, `embed-english-v3.0`)
- **Rate limits**: Vary by plan; check `X-RateLimit-*` response headers
- **Pagination**: Use `page_size` and `page_token` for list endpoints
- **Fine-tuning**: Only specific base models support fine-tuning
- **Connector auth**: Connectors may need separate OAuth configuration
