---
name: managing-groq-cloud
description: |
  Groq Cloud inference platform management covering models, API usage, rate limits, and performance metrics. Use when monitoring API health, analyzing inference latency, reviewing available models, checking rate limit status, or troubleshooting Groq Cloud API issues.
connection_type: groq
preload: false
---

# Groq Cloud Management Skill

Manage and analyze Groq Cloud inference platform resources including models, usage, and performance.

## API Conventions

### Authentication
All API calls use Bearer API key, injected automatically.

### Base URL
`https://api.groq.com/openai/v1`

### Core Helper Function

```bash
#!/bin/bash

groq_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $GROQ_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.groq.com/openai/v1${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $GROQ_API_KEY" \
            "https://api.groq.com/openai/v1${endpoint}"
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
groq_api GET "/models" \
    | jq -r '.data[] | "\(.id)\t\(.owned_by)\t\(.context_window // "N/A")"' \
    | sort | column -t | head -20

echo ""
echo "=== API Health Check ==="
RESULT=$(groq_api POST "/chat/completions" '{"model": "llama-3.1-8b-instant", "messages": [{"role": "user", "content": "test"}], "max_tokens": 1}')
echo "$RESULT" | jq '{model: .model, usage: .usage}' 2>/dev/null || echo "Error: $(echo $RESULT | jq -r '.error.message // "unknown"')"
```

## Phase 2: Analysis

### Performance & Rate Limits

```bash
#!/bin/bash
echo "=== Latency Benchmark ==="
for model in "llama-3.1-8b-instant" "llama-3.1-70b-versatile" "mixtral-8x7b-32768"; do
    START=$(date +%s%N)
    RESULT=$(groq_api POST "/chat/completions" "{\"model\": \"$model\", \"messages\": [{\"role\": \"user\", \"content\": \"Say hello\"}], \"max_tokens\": 10}")
    END=$(date +%s%N)
    LATENCY=$(( (END - START) / 1000000 ))
    TOKENS=$(echo "$RESULT" | jq '.usage.total_tokens // 0')
    echo "$model: ${LATENCY}ms (${TOKENS} tokens)"
done

echo ""
echo "=== Rate Limit Status ==="
HEADERS=$(curl -s -D- -o /dev/null -X POST \
    -H "Authorization: Bearer $GROQ_API_KEY" \
    -H "Content-Type: application/json" \
    "https://api.groq.com/openai/v1/chat/completions" \
    -d '{"model": "llama-3.1-8b-instant", "messages": [{"role": "user", "content": "test"}], "max_tokens": 1}')
echo "$HEADERS" | grep -i "x-ratelimit\|retry-after" | while read line; do
    echo "  $line"
done
```

### Model Availability

```bash
#!/bin/bash
echo "=== Model Availability Check ==="
groq_api GET "/models" | jq -r '.data[].id' | while read model; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
        -H "Authorization: Bearer $GROQ_API_KEY" \
        -H "Content-Type: application/json" \
        "https://api.groq.com/openai/v1/chat/completions" \
        -d "{\"model\": \"$model\", \"messages\": [{\"role\": \"user\", \"content\": \"test\"}], \"max_tokens\": 1}")
    echo "$model: HTTP $STATUS"
done | head -15

echo ""
echo "=== Models by Owner ==="
groq_api GET "/models" \
    | jq -r '[.data[] | .owned_by] | group_by(.) | map({(.[0]): length}) | add'
```

## Output Format

```
=== Groq Cloud ===
Models Available: <n>

--- Performance ---
<model>: <latency>ms (<tokens> tokens)

--- Rate Limits ---
Requests: <remaining>/<limit> per minute
Tokens: <remaining>/<limit> per minute

--- Model Availability ---
<model>: <available|unavailable>
```

## Common Pitfalls
- **OpenAI-compatible**: API follows OpenAI chat/completions format
- **Rate limits**: Vary by model and plan; check `x-ratelimit-*` headers
- **Model names**: Use exact model IDs from `/models` endpoint
- **Token limits**: Different models have different context windows
- **No fine-tuning**: Groq does not currently support custom fine-tuning
