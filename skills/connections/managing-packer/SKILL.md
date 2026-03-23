---
name: managing-packer
description: |
  Use when working with Packer — packer machine image building. Covers image
  builds, template validation, variable management, post-processor
  configuration, build debugging, and multi-builder pipelines. Use when building
  machine images, validating templates, debugging build failures, or managing
  image pipelines.
connection_type: packer
preload: false
---

# Packer Management Skill

Manage and inspect Packer image builds, templates, and post-processors.

## MANDATORY: Discovery-First Pattern

**Always validate templates and inspect variables before running builds.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Packer Version ==="
packer version 2>/dev/null

echo ""
echo "=== Available Templates ==="
find . -maxdepth 3 \( -name "*.pkr.hcl" -o -name "*.pkr.json" -o -name "packer.json" \) 2>/dev/null | head -20

echo ""
echo "=== Installed Plugins ==="
packer plugins installed 2>/dev/null || \
ls ~/.config/packer/plugins/ 2>/dev/null | head -15

echo ""
echo "=== Template Variables ==="
TEMPLATE="${1:-$(find . -maxdepth 2 -name "*.pkr.hcl" | head -1)}"
if [ -n "$TEMPLATE" ]; then
    packer inspect "$TEMPLATE" 2>/dev/null | head -30
fi
```

## Core Helper Functions

```bash
#!/bin/bash

# Packer wrapper with logging
pk_cmd() {
    PACKER_LOG=0 packer "$@" 2>&1
}

# Validate template
pk_validate() {
    local template="$1"
    shift
    packer validate "$@" "$template" 2>&1
}

# Build with machine-readable output
pk_build() {
    local template="$1"
    shift
    packer build -machine-readable "$@" "$template" 2>&1
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `-machine-readable` for parseable build output
- Use `packer inspect` for template overview
- Never dump full provisioner scripts -- summarize build steps

## Common Operations

### Template Validation

```bash
#!/bin/bash
TEMPLATE="${1:?Template path required}"
VAR_FILE="${2:-}"

echo "=== Validating Template ==="
if [ -n "$VAR_FILE" ]; then
    packer validate -var-file="$VAR_FILE" "$TEMPLATE" 2>&1
else
    packer validate "$TEMPLATE" 2>&1
fi

echo ""
echo "=== Template Inspection ==="
packer inspect "$TEMPLATE" 2>/dev/null

echo ""
echo "=== Required Variables ==="
if [[ "$TEMPLATE" == *.hcl ]]; then
    grep -A 3 'variable "' "$TEMPLATE" 2>/dev/null | head -30
else
    jq '.variables // {}' "$TEMPLATE" 2>/dev/null | head -20
fi
```

### Image Build Execution

```bash
#!/bin/bash
TEMPLATE="${1:?Template path required}"
DRY_RUN="${2:-true}"

if [ "$DRY_RUN" = "true" ]; then
    echo "=== DRY RUN: Build Plan ==="
    packer inspect "$TEMPLATE" 2>/dev/null
    echo ""
    echo "=== Validation ==="
    packer validate "$TEMPLATE" 2>&1
    echo ""
    echo "To build, confirm with dry_run=false"
else
    echo "=== Building Image ==="
    packer build -color=false -timestamp-ui "$TEMPLATE" 2>&1 | tail -40
fi
```

### Multi-Builder Pipeline

```bash
#!/bin/bash
TEMPLATE="${1:?Template path required}"

echo "=== Builders in Template ==="
if [[ "$TEMPLATE" == *.hcl ]]; then
    grep -E '^source "' "$TEMPLATE" 2>/dev/null || \
    grep -E 'source\s*=' "$TEMPLATE" 2>/dev/null
else
    jq -r '.builders[] | "\(.type)\t\(.name // "default")"' "$TEMPLATE" 2>/dev/null
fi

echo ""
echo "=== Provisioners ==="
if [[ "$TEMPLATE" == *.hcl ]]; then
    grep -E '^\s*provisioner "' "$TEMPLATE" 2>/dev/null | head -10
else
    jq -r '.provisioners[] | "\(.type)\t\(.inline[0] // .source // .script // "complex config")"' "$TEMPLATE" 2>/dev/null | head -10
fi

echo ""
echo "=== Post-Processors ==="
if [[ "$TEMPLATE" == *.hcl ]]; then
    grep -E '^\s*post-processor "' "$TEMPLATE" 2>/dev/null | head -10
else
    jq -r '(.["post-processors"] // [])[][] | .type // .' "$TEMPLATE" 2>/dev/null | head -10
fi
```

### Build Debugging

```bash
#!/bin/bash
TEMPLATE="${1:?Template path required}"

echo "=== Debug Build (step-by-step) ==="
echo "To run debug build: PACKER_LOG=1 packer build -debug $TEMPLATE"
echo ""

echo "=== Common Build Errors ==="
echo "1. SSH timeout: Check security group rules and SSH key configuration"
echo "2. AMI not found: Verify source_ami or use source_ami_filter"
echo "3. Permission denied: Check IAM role/credentials"
echo "4. Provisioner failed: Check script paths and permissions"

echo ""
echo "=== Last Build Log ==="
if [ -f "packer.log" ]; then
    grep -E "(Error|error|FAIL|amazon-ebs|googlecompute|azure-arm)" packer.log | tail -20
fi
```

### Variable and Auto-Vars Management

```bash
#!/bin/bash
echo "=== Variable Files ==="
find . -maxdepth 2 \( -name "*.pkrvars.hcl" -o -name "*.auto.pkrvars.hcl" -o -name "variables.pkr.hcl" \) 2>/dev/null

echo ""
echo "=== Variable Definitions ==="
TEMPLATE="${1:-$(find . -maxdepth 2 -name "*.pkr.hcl" | head -1)}"
grep -A 5 'variable "' "$TEMPLATE" 2>/dev/null | head -40

echo ""
echo "=== Environment Variables ==="
env | grep -i PKR_ 2>/dev/null | head -10
```

## Safety Rules

- **NEVER build without validating first** -- `packer validate` catches config errors before spending compute
- **Use `-on-error=ask`** during development to allow debugging failed builds
- **Set build timeouts** to prevent runaway builds consuming resources
- **Clean up failed builds** -- interrupted builds may leave instances/disks running in cloud accounts
- **Use `-only` flag** to target specific builders in multi-builder templates

## Output Format

Present results as a structured report:
```
Managing Packer Report
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

- **SSH timeout**: Most common failure -- ensure security group allows SSH and communicator config is correct
- **Source image availability**: AMIs/images are region-specific -- use filters instead of hardcoded IDs
- **Plugin version conflicts**: HCL2 templates require `packer init` to install plugins -- run before validate
- **File provisioner paths**: Relative paths are relative to working directory, not template location
- **Windows builds**: WinRM communicator requires different timeout and retry settings than SSH
- **Parallel builds**: Multiple builders run in parallel by default -- use `-parallel-builds=1` if they conflict
- **Temporary credentials**: Long builds may exceed temporary credential expiry (STS, instance profiles)
- **Post-processor ordering**: Post-processors in a sequence share artifacts -- order matters for chaining
