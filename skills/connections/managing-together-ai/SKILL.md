---
name: managing-together-ai
description: |
  Together AI inference platform management covering models, fine-tuning jobs, usage analytics, and billing. Use when monitoring API usage and costs, analyzing model performance, reviewing fine-tuning status, checking available models, or troubleshooting Together AI API issues.
connection_type: together-ai
preload: false
---

# Together AI Management Skill

Manage and analyze Together AI platform resources including models, fine-tuning, and usage.

## API Conventions

### Authentication
All API calls use Bearer API key, injected automatically.

### Base URL
`https://api.together.xyz/v1`

### Core Helper Function

```bash
#!/bin/bash

together_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $TOGETHER_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.together.xyz/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $TOGETHER_API_KEY" \
            "https://api.together.xyz/v1${endpoint}"
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
echo "=== Available Models (chat) ==="
together_api GET "/models" \
    | jq -r '.[] | select(.type == "chat") | "\(.id)\t\(.context_length // "N/A")\t\(.pricing.input // "N/A")"' \
    | head -20

echo ""
echo "=== Available Models (language) ==="
together_api GET "/models" \
    | jq -r '.[] | select(.type == "language") | .id' | head -10

echo ""
echo "=== Fine-Tuning Jobs ==="
together_api GET "/fine-tunes" \
    | jq -r '.data[] | "\(.id[0:16])\t\(.model)\t\(.status)\t\(.created_at[0:10])"' \
    | column -t | head -10

echo ""
echo "=== Uploaded Files ==="
together_api GET "/files" \
    | jq -r '.data[] | "\(.id[0:16])\t\(.filename[0:30])\t\(.purpose)\t\(.bytes) bytes"' \
    | column -t | head -10
```

## Phase 2: Analysis

### Usage & Billing

```bash
#!/bin/bash
echo "=== Account Balance ==="
together_api GET "/billing/balance" \
    | jq '{balance: .balance, currency: .currency}'

echo ""
echo "=== Model Count by Type ==="
together_api GET "/models" \
    | jq -r '[.[] | .type] | group_by(.) | map({(.[0]): length}) | add'

echo ""
echo "=== API Health Check ==="
RESULT=$(together_api POST "/chat/completions" '{"model": "meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo", "messages": [{"role": "user", "content": "test"}], "max_tokens": 1}')
echo "$RESULT" | jq '{model: .model, usage: .usage}' 2>/dev/null || echo "Error: $(echo $RESULT | jq -r '.error.message // "unknown"')"
```

### Fine-Tuning Health

```bash
#!/bin/bash
echo "=== Fine-Tuning Status Summary ==="
together_api GET "/fine-tunes" \
    | jq -r '.data[] | .status' | sort | uniq -c | sort -rn

echo ""
echo "=== Recent Fine-Tuning Jobs ==="
together_api GET "/fine-tunes" \
    | jq -r '.data[] | "\(.id[0:16])\t\(.model)\t\(.status)\t\(.training_type // "full")\t\(.n_epochs) epochs"' \
    | column -t | head -10

echo ""
echo "=== Custom Models ==="
together_api GET "/models" \
    | jq -r '.[] | select(.type == "custom") | "\(.id)\t\(.created_at[0:10] // "N/A")"' | head -10
```

## Output Format

```
=== Together AI Account ===
Balance: $<amount>

--- Models ---
Chat: <n>  Language: <n>  Embedding: <n>  Image: <n>

--- Fine-Tuning ---
Active: <n>  Completed: <n>  Failed: <n>

--- API Health ---
Status: <healthy|degraded>
```

## Common Pitfalls
- **Model IDs**: Use full organization/model format (e.g., `meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo`)
- **Rate limits**: Vary by plan; check response headers for current limits
- **OpenAI-compatible**: API follows OpenAI format for chat/completions endpoints
- **Fine-tuning**: Supports LoRA and full fine-tuning; specify in job config
