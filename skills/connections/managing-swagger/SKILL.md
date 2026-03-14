---
name: managing-swagger
description: |
  Swagger and OpenAPI specification management - spec validation, code generation, Swagger UI management, and schema analysis. Use when validating API specifications, generating client/server code from OpenAPI specs, managing Swagger UI deployments, or analyzing API schema structures.
connection_type: swagger
preload: false
---

# Swagger/OpenAPI Management Skill

Manage OpenAPI specifications, validate schemas, generate code, and analyze API structures.

## Core Helper Functions

```bash
#!/bin/bash

# Swagger/OpenAPI tooling paths
SWAGGER_CLI="${SWAGGER_CLI:-swagger-cli}"
OPENAPI_GENERATOR="${OPENAPI_GENERATOR:-openapi-generator-cli}"

# Validate spec and return structured result
validate_spec() {
    local spec_file="$1"
    $SWAGGER_CLI validate "$spec_file" 2>&1
}

# Parse spec with yq/jq depending on format
parse_spec() {
    local spec_file="$1"
    if [[ "$spec_file" == *.yaml ]] || [[ "$spec_file" == *.yml ]]; then
        yq eval -o=json "$spec_file"
    else
        jq '.' "$spec_file"
    fi
}

# Extract OpenAPI version
spec_version() {
    local spec_file="$1"
    parse_spec "$spec_file" | jq -r '.openapi // .swagger // "unknown"'
}
```

## MANDATORY: Discovery-First Pattern

**Always validate and analyze the spec before performing operations.**

### Phase 1: Discovery

```bash
#!/bin/bash
SPEC_FILE="${1:?Spec file path required}"

echo "=== Spec Overview ==="
parse_spec "$SPEC_FILE" | jq '{
    title: .info.title,
    version: .info.version,
    openapi_version: (.openapi // .swagger),
    description: (.info.description // "none")[0:100],
    contact: .info.contact,
    license: .info.license.name,
    servers: [(.servers // [])[] | .url],
    total_paths: (.paths | length),
    total_schemas: ((.components.schemas // .definitions) | length)
}'

echo ""
echo "=== Validation ==="
validate_spec "$SPEC_FILE"

echo ""
echo "=== Endpoints Summary ==="
parse_spec "$SPEC_FILE" | jq '[.paths | to_entries[] | {path: .key, methods: (.value | keys | map(select(. != "parameters")))}]'
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Summarize schemas rather than dumping full definitions
- Group endpoints by tags or path prefixes for readability

## Common Operations

### Spec Validation and Linting

```bash
#!/bin/bash
SPEC_FILE="${1:?Spec file path required}"

echo "=== Structural Validation ==="
validate_spec "$SPEC_FILE"

echo ""
echo "=== Missing Descriptions ==="
parse_spec "$SPEC_FILE" | jq '{
    paths_without_summary: [.paths | to_entries[] | .value | to_entries[] | select(.value.summary == null and .key != "parameters") | .key] | length,
    schemas_without_description: [(.components.schemas // .definitions // {}) | to_entries[] | select(.value.description == null) | .key],
    params_without_description: [.paths | .. | .parameters? // [] | .[] | select(.description == null) | .name] | unique
}'

echo ""
echo "=== Security Definitions ==="
parse_spec "$SPEC_FILE" | jq '{
    security_schemes: (.components.securitySchemes // .securityDefinitions // {}),
    global_security: (.security // []),
    unsecured_endpoints: [.paths | to_entries[] | .value | to_entries[] | select(.value.security == [] or (.value.security == null and .key != "parameters")) | .key] | length
}'

echo ""
echo "=== Deprecated Endpoints ==="
parse_spec "$SPEC_FILE" | jq '[.paths | to_entries[] | {path: .key, methods: [.value | to_entries[] | select(.value.deprecated == true) | .key]}| select(.methods | length > 0)]'
```

### Schema Analysis

```bash
#!/bin/bash
SPEC_FILE="${1:?Spec file path required}"

echo "=== Schema Overview ==="
parse_spec "$SPEC_FILE" | jq '{
    total_schemas: ((.components.schemas // .definitions // {}) | length),
    schemas: [(.components.schemas // .definitions // {}) | to_entries[] | {
        name: .key,
        type: .value.type,
        required_fields: (.value.required // []) | length,
        total_properties: (.value.properties // {} | length),
        has_example: (.value.example != null)
    }]
}'

echo ""
echo "=== Schema Relationships (References) ==="
parse_spec "$SPEC_FILE" | jq '[(.components.schemas // .definitions // {}) | to_entries[] | {
    schema: .key,
    references: [.value | .. | .["$ref"]? // empty | split("/") | last] | unique
}] | map(select(.references | length > 0))'

echo ""
echo "=== Enum Values ==="
parse_spec "$SPEC_FILE" | jq '[(.components.schemas // .definitions // {}) | to_entries[] | .value.properties // {} | to_entries[] | select(.value.enum) | {field: .key, enum: .value.enum}]'
```

### Code Generation

```bash
#!/bin/bash
SPEC_FILE="${1:?Spec file path required}"

echo "=== Available Generators ==="
$OPENAPI_GENERATOR list | head -30

echo ""
echo "=== Generate Client Example ==="
LANGUAGE="${2:-typescript-axios}"
OUTPUT_DIR="${3:-./generated}"
echo "Command to generate ${LANGUAGE} client:"
echo "  $OPENAPI_GENERATOR generate -i ${SPEC_FILE} -g ${LANGUAGE} -o ${OUTPUT_DIR}"

echo ""
echo "=== Generator Config Options ==="
$OPENAPI_GENERATOR config-help -g "${LANGUAGE}" 2>/dev/null | head -30

echo ""
echo "=== Spec Compatibility Check ==="
spec_ver=$(spec_version "$SPEC_FILE")
echo "Spec version: ${spec_ver}"
if [[ "$spec_ver" == 2* ]]; then
    echo "WARNING: Swagger 2.0 spec. Consider converting to OpenAPI 3.x for broader generator support."
    echo "Convert command: $SWAGGER_CLI convert ${SPEC_FILE} -o converted-spec.json"
fi
```

### API Surface Analysis

```bash
#!/bin/bash
SPEC_FILE="${1:?Spec file path required}"

echo "=== API Surface by Tag ==="
parse_spec "$SPEC_FILE" | jq '[.paths | to_entries[] | .value | to_entries[] | select(.key != "parameters") | {method: .key, tags: (.value.tags // ["untagged"])}] | group_by(.tags[0]) | map({tag: .[0].tags[0], count: length, methods: [.[].method] | group_by(.) | map({method: .[0], count: length})})'

echo ""
echo "=== Request/Response Content Types ==="
parse_spec "$SPEC_FILE" | jq '{
    request_types: [.paths | .. | .requestBody?.content? // empty | keys] | flatten | unique,
    response_types: [.paths | .. | .responses? // {} | .[] | .content? // {} | keys] | flatten | unique
}'

echo ""
echo "=== Path Parameter Patterns ==="
parse_spec "$SPEC_FILE" | jq '[.paths | keys[] | select(test("\\{"))] | map({path: ., params: [match("\\{([^}]+)\\}"; "g") | .captures[0].string]})'

echo ""
echo "=== Pagination Patterns ==="
parse_spec "$SPEC_FILE" | jq '[.paths | to_entries[] | .value | to_entries[] | select(.value.parameters) | .value.parameters[] | select(.name | test("page|limit|offset|cursor|skip|take"; "i")) | {name, in: .in, type: (.schema.type // .type)}] | unique_by(.name)'
```

## Safety Rules
- **Read-only by default**: Only validate and analyze specs; do not modify without confirmation
- **Never run** code generators that overwrite existing directories without user confirmation
- **Validate before generating**: Always validate the spec before running code generation
- **Version check**: Confirm OpenAPI version compatibility with the target generator
- **Backup specs**: Before any spec transformation, confirm the original is backed up

## Common Pitfalls
- **Circular references**: Deeply nested $ref cycles cause validators and generators to fail or loop
- **Swagger 2.0 vs OpenAPI 3.x**: Many tools only support one version; check before using
- **allOf/oneOf/anyOf**: Complex schema composition can produce unexpected generated code
- **Server URL templates**: Parameterized server URLs need variable values for code generation
- **Spec drift**: Generated code goes stale when the spec changes; integrate generation into CI/CD
