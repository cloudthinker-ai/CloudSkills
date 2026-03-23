---
name: gcp-secret-manager
description: |
  Use when working with Gcp Secret Manager — google Secret Manager secret
  lifecycle management, version control, rotation configuration, IAM policy
  auditing, and access diagnostics via gcloud CLI.
connection_type: gcp
preload: false
---

# Secret Manager Skill

Manage and analyze Google Secret Manager using `gcloud secrets` commands.

## Discovery-First Rule

**ALWAYS discover before acting.** Never assume secret names, version numbers, or rotation schedules.

```bash
# Discover secrets
gcloud secrets list --format=json \
  | jq '[.[] | {name: .name | split("/") | last, createTime: .createTime, replication: .replication, expireTime: .expireTime, rotation: .rotation, labels: .labels}]'
```

## Parallel Execution Requirement

**ALL independent operations MUST run in parallel using background jobs (&) and wait.**

```bash
for secret in $(gcloud secrets list --format="value(name)" | xargs -I{} basename {}); do
  {
    gcloud secrets describe "$secret" --format=json
    gcloud secrets versions list "$secret" --format=json --limit=5
  } &
done
wait
```

## Helper Functions

```bash
# Get secret metadata (NEVER access secret values)
get_secret_metadata() {
  local secret="$1"
  gcloud secrets describe "$secret" --format=json \
    | jq '{name: .name | split("/") | last, createTime: .createTime, replication: .replication, expireTime: .expireTime, rotation: .rotation, labels: .labels, topics: .topics}'
}

# List versions
list_versions() {
  local secret="$1" limit="${2:-10}"
  gcloud secrets versions list "$secret" --format=json --limit="$limit" \
    | jq '[.[] | {version: .name | split("/") | last, state: .state, createTime: .createTime, destroyTime: .destroyTime}]'
}

# Get IAM policy for a secret
get_secret_iam() {
  local secret="$1"
  gcloud secrets get-iam-policy "$secret" --format=json \
    | jq '.bindings[] | {role: .role, members: .members}'
}

# Check rotation config
get_rotation_config() {
  local secret="$1"
  gcloud secrets describe "$secret" --format=json \
    | jq '{rotation: .rotation, topics: .topics, expireTime: .expireTime}'
}
```

## Common Operations

### 1. Secret Inventory

```bash
secrets=$(gcloud secrets list --format="value(name)" | xargs -I{} basename {})
for secret in $secrets; do
  {
    echo "=== $secret ==="
    get_secret_metadata "$secret"
    list_versions "$secret" 3
  } &
done
wait
```

### 2. Version Management

```bash
# Versions with their states
gcloud secrets versions list "$SECRET" --format=json \
  | jq '[.[] | {version: .name | split("/") | last, state: .state, createTime: .createTime}]'

# Find secrets with only disabled/destroyed versions (stale)
for secret in $(gcloud secrets list --format="value(name)" | xargs -I{} basename {}); do
  {
    enabled=$(gcloud secrets versions list "$secret" --filter="state=ENABLED" --format="value(name)" | wc -l)
    if [ "$enabled" -eq 0 ]; then
      echo "STALE: $secret (no enabled versions)"
    fi
  } &
done
wait

# Secrets with many versions (cleanup candidates)
for secret in $(gcloud secrets list --format="value(name)" | xargs -I{} basename {}); do
  {
    count=$(gcloud secrets versions list "$secret" --format="value(name)" | wc -l)
    echo "$secret: $count versions"
  } &
done
wait
```

### 3. Rotation Status

```bash
# Secrets with rotation configured
gcloud secrets list --format=json \
  | jq '[.[] | select(.rotation) | {name: .name | split("/") | last, rotationPeriod: .rotation.rotationPeriod, nextRotation: .rotation.nextRotationTime, topics: [.topics[]?.name | split("/") | last]}]'

# Secrets WITHOUT rotation (security risk)
gcloud secrets list --format=json \
  | jq '[.[] | select(.rotation == null) | {name: .name | split("/") | last, createTime: .createTime}]'
```

### 4. IAM Policy Audit

```bash
for secret in $(gcloud secrets list --format="value(name)" | xargs -I{} basename {}); do
  {
    echo "=== $secret ==="
    get_secret_iam "$secret"
  } &
done
wait

# Find secrets accessible by allUsers or allAuthenticatedUsers (security risk)
for secret in $(gcloud secrets list --format="value(name)" | xargs -I{} basename {}); do
  {
    policy=$(gcloud secrets get-iam-policy "$secret" --format=json 2>/dev/null)
    if echo "$policy" | jq -e '.bindings[]?.members[]? | select(. == "allUsers" or . == "allAuthenticatedUsers")' >/dev/null 2>&1; then
      echo "PUBLIC ACCESS: $secret"
    fi
  } &
done
wait
```

### 5. Access Monitoring

```bash
# Recent secret access via audit logs
gcloud logging read "protoPayload.methodName=\"google.cloud.secretmanager.v1.SecretManagerService.AccessSecretVersion\" AND timestamp>=\"$(date -u -v-24H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)\"" --limit=50 --format=json \
  | jq '[.[] | {timestamp: .timestamp, caller: .protoPayload.authenticationInfo.principalEmail, secret: .protoPayload.resourceName | split("/") | .[-3], version: .protoPayload.resourceName | split("/") | last}]'
```

## Output Format

Present results as a structured report:
```
Gcp Secret Manager Report
═════════════════════════
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

1. **NEVER output secret values**: Always use metadata commands (`describe`, `list`). Never use `gcloud secrets versions access` and display the output.
2. **Version states**: Disabled versions still exist and can be re-enabled. Only destroyed versions are permanently inaccessible. Check `state` field.
3. **Rotation Pub/Sub**: Rotation configuration requires a Pub/Sub topic. The topic must exist and the Secret Manager service account needs publish permissions.
4. **Replication policy**: Automatic replication copies to all regions. User-managed replication allows specific regions but requires manual management.
5. **Expiration vs rotation**: `expireTime` deletes the entire secret permanently. Rotation creates new versions. Do not confuse the two.
