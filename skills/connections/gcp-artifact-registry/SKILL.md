---
name: gcp-artifact-registry
description: |
  Google Artifact Registry repository management, vulnerability scanning analysis, cleanup policy configuration, and artifact lifecycle management via gcloud CLI.
connection_type: gcp
preload: false
---

# Artifact Registry Skill

Manage and analyze Google Artifact Registry using `gcloud artifacts` commands.

## Discovery-First Rule

**ALWAYS discover before acting.** Never assume repository names, locations, or image tags.

```bash
# Discover repositories
gcloud artifacts repositories list --format=json \
  | jq '[.[] | {name: .name | split("/") | last, location: .name | split("/") | .[3], format: .format, mode: .mode, sizeBytes: .sizeBytes, createTime: .createTime}]'
```

## Parallel Execution Requirement

**ALL independent operations MUST run in parallel using background jobs (&) and wait.**

```bash
for repo in $(gcloud artifacts repositories list --format="value(name)" | xargs -I{} basename {}); do
  {
    gcloud artifacts repositories describe "$repo" --location="$LOCATION" --format=json
  } &
done
wait
```

## Helper Functions

```bash
# List images/packages in a repository
list_packages() {
  local repo="$1" location="$2"
  gcloud artifacts packages list --repository="$repo" --location="$location" --format=json \
    | jq '[.[] | {name: .name | split("/") | last, createTime: .createTime, updateTime: .updateTime}]'
}

# List image tags
list_tags() {
  local repo="$1" location="$2" package="$3"
  gcloud artifacts tags list --repository="$repo" --location="$location" --package="$package" --format=json \
    | jq '[.[] | {tag: .name | split("/") | last, version: .version | split("/") | last}]'
}

# List versions with metadata
list_versions() {
  local repo="$1" location="$2" package="$3" limit="${4:-20}"
  gcloud artifacts versions list --repository="$repo" --location="$location" --package="$package" --format=json --limit="$limit" \
    | jq '[.[] | {version: .name | split("/") | last, createTime: .createTime, metadata: .metadata}]'
}

# Get vulnerability scan results
get_vulnerabilities() {
  local image="$1"
  gcloud artifacts docker images list "$image" --include-tags --show-occurrences --format=json \
    | jq '[.[] | {digest: .version, tags: .tags, vulnerabilities: .vuln_counts}]'
}
```

## Common Operations

### 1. Repository Overview

```bash
repos=$(gcloud artifacts repositories list --format=json \
  | jq -c '[.[] | {name: .name | split("/") | last, location: .name | split("/") | .[3]}]')
for repo in $(echo "$repos" | jq -c '.[]'); do
  {
    name=$(echo "$repo" | jq -r '.name')
    location=$(echo "$repo" | jq -r '.location')
    echo "=== $name ($location) ==="
    gcloud artifacts repositories describe "$name" --location="$location" --format=json \
      | jq '{format: .format, mode: .mode, sizeBytes: .sizeBytes, cleanupPolicies: .cleanupPolicies, dockerConfig: .dockerConfig}'
    list_packages "$name" "$location"
  } &
done
wait
```

### 2. Vulnerability Scanning

```bash
# List images with vulnerability counts
gcloud artifacts docker images list "$LOCATION-docker.pkg.dev/$PROJECT/$REPO" \
  --include-tags --show-occurrences --format=json \
  | jq '[.[] | {image: .package, tags: .tags, createTime: .createTime, vulnerabilities: .vuln_counts}]'

# Get detailed vulnerability report for an image
gcloud artifacts docker images describe "$LOCATION-docker.pkg.dev/$PROJECT/$REPO/$IMAGE@$DIGEST" \
  --show-all-metadata --format=json \
  | jq '{digest: .image_summary.digest, fullyQualifiedDigest: .image_summary.fully_qualified_digest, vulnerabilities: .discovery_summary}'
```

### 3. Cleanup Policies

```bash
# Check cleanup policies on repositories
for repo in $(gcloud artifacts repositories list --format="value(name)" | xargs -I{} basename {}); do
  {
    gcloud artifacts repositories describe "$repo" --location="$LOCATION" --format=json \
      | jq --arg r "$repo" '{repo: $r, cleanupPolicies: .cleanupPolicies, cleanupPolicyDryRun: .cleanupPolicyDryRun}'
  } &
done
wait
```

### 4. Image Age and Size Analysis

```bash
# List images sorted by age (oldest first)
gcloud artifacts docker images list "$LOCATION-docker.pkg.dev/$PROJECT/$REPO" \
  --include-tags --format=json --sort-by="createTime" --limit=50 \
  | jq '[.[] | {image: .package | split("/") | last, tags: .tags, createTime: .createTime, mediaType: .mediaType}]'

# Untagged images (cleanup candidates)
gcloud artifacts docker images list "$LOCATION-docker.pkg.dev/$PROJECT/$REPO" \
  --include-tags --format=json \
  | jq '[.[] | select(.tags == null or (.tags | length == 0)) | {digest: .version, createTime: .createTime}]'
```

### 5. Repository Access and Configuration

```bash
# IAM policy
gcloud artifacts repositories get-iam-policy "$REPO" --location="$LOCATION" --format=json \
  | jq '.bindings[] | {role: .role, members: .members}'

# Repository settings
gcloud artifacts repositories describe "$REPO" --location="$LOCATION" --format=json \
  | jq '{format: .format, mode: .mode, dockerConfig: .dockerConfig, mavenConfig: .mavenConfig, remoteRepositoryConfig: .remoteRepositoryConfig, virtualRepositoryConfig: .virtualRepositoryConfig}'
```

## Common Pitfalls

1. **Repository format**: Each repository supports one format (Docker, Maven, npm, Python, etc.). Format cannot be changed after creation.
2. **Cleanup policy dry run**: New cleanup policies run in dry-run mode by default. Check `cleanupPolicyDryRun` -- set to false to actually delete artifacts.
3. **Vulnerability scanning**: On-Demand scanning must be explicitly enabled. Not all image types support automatic scanning. Check Container Analysis API status.
4. **Remote repositories**: Remote repository mode caches upstream artifacts (Docker Hub, Maven Central). Cache misses add latency. Check remote config.
5. **Tag immutability**: Docker tag immutability prevents tag overwrites when enabled. Existing tags cannot be moved to new digests. Check `dockerConfig.immutableTags`.
