---
name: managing-perplexity-api
description: |
  Perplexity AI API management covering models, search-augmented generation, usage analytics, and rate limits. Use when monitoring API health, analyzing query performance, reviewing available models, checking usage quotas, or troubleshooting Perplexity API issues.
connection_type: perplexity
preload: false
---

# Perplexity API Management Skill

Manage and analyze Perplexity AI API resources including models, usage, and search-augmented generation.

## API Conventions

### Authentication
All API calls use Bearer API key, injected automatically.

### Base URL
`https://api.perplexity.ai`

### Core Helper Function

```bash
#!/bin/bash

perplexity_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
            -H "Content-Type: application/json" \
            "https://api.perplexity.ai${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
            "https://api.perplexity.ai${endpoint}"
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
perplexity_api GET "/models" \
    | jq -r '.data[] | "\(.id)\t\(.owned_by // "perplexity")\t\(.context_length // "N/A")"' \
    | column -t | head -15

echo ""
echo "=== API Health Check ==="
RESULT=$(perplexity_api POST "/chat/completions" '{"model": "sonar", "messages": [{"role": "user", "content": "test"}], "max_tokens": 1}')
echo "$RESULT" | jq '{model: .model, usage: .usage, citations: (.citations | length // 0)}' 2>/dev/null \
    || echo "Error: $(echo $RESULT | jq -r '.error.message // "unknown"')"
```

## Phase 2: Analysis

### Performance & Rate Limits

```bash
#!/bin/bash
echo "=== Model Latency Check ==="
for model in "sonar" "sonar-pro"; do
    START=$(date +%s%N)
    RESULT=$(perplexity_api POST "/chat/completions" "{\"model\": \"$model\", \"messages\": [{\"role\": \"user\", \"content\": \"What is 2+2?\"}], \"max_tokens\": 10}")
    END=$(date +%s%N)
    LATENCY=$(( (END - START) / 1000000 ))
    TOKENS=$(echo "$RESULT" | jq '.usage.total_tokens // 0')
    CITATIONS=$(echo "$RESULT" | jq '.citations | length // 0')
    echo "$model: ${LATENCY}ms, ${TOKENS} tokens, ${CITATIONS} citations"
done

echo ""
echo "=== Rate Limit Status ==="
HEADERS=$(curl -s -D- -o /dev/null -X POST \
    -H "Authorization: Bearer $PERPLEXITY_API_KEY" \
    -H "Content-Type: application/json" \
    "https://api.perplexity.ai/chat/completions" \
    -d '{"model": "sonar", "messages": [{"role": "user", "content": "test"}], "max_tokens": 1}')
echo "$HEADERS" | grep -i "x-ratelimit\|retry-after" | while read line; do
    echo "  $line"
done
```

### Search Quality

```bash
#!/bin/bash
echo "=== Search-Augmented Response Check ==="
RESULT=$(perplexity_api POST "/chat/completions" '{"model": "sonar", "messages": [{"role": "user", "content": "Latest news today"}], "max_tokens": 50}')
echo "$RESULT" | jq '{
    model: .model,
    citations_count: (.citations | length),
    citations: .citations[0:5],
    usage: .usage
}'

echo ""
echo "=== Model Comparison ==="
for model in "sonar" "sonar-pro"; do
    RESULT=$(perplexity_api POST "/chat/completions" "{\"model\": \"$model\", \"messages\": [{\"role\": \"user\", \"content\": \"Current weather in NYC\"}], \"max_tokens\": 30}")
    CITATIONS=$(echo "$RESULT" | jq '.citations | length // 0')
    TOKENS=$(echo "$RESULT" | jq '.usage | {input: .prompt_tokens, output: .completion_tokens}')
    echo "$model: $CITATIONS citations, tokens: $TOKENS"
done
```

## Output Format

```
=== Perplexity API ===
Models Available: <list>

--- Performance ---
<model>: <latency>ms, <tokens> tokens, <citations> citations

--- Rate Limits ---
Requests: <remaining>/<limit>

--- Search Quality ---
Avg Citations: <n> per query
```

## Common Pitfalls
- **Search-augmented**: Perplexity models include web search results and citations automatically
- **Citations field**: Responses include `citations` array with source URLs
- **OpenAI-compatible**: API follows OpenAI chat/completions format
- **Rate limits**: Check `x-ratelimit-*` response headers for current limits
- **Model names**: Use `sonar` or `sonar-pro` for search-augmented models
