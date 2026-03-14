---
name: gcp-cloud-storage
description: |
  Google Cloud Storage bucket analysis, lifecycle rule management, access control configuration, transfer service operations, and storage class optimization via gsutil and gcloud CLI.
connection_type: gcp
preload: false
---

# Cloud Storage Skill

Manage and analyze Google Cloud Storage using `gcloud storage` and `gsutil` commands.

## Discovery-First Rule

**ALWAYS discover before acting.** Never assume bucket names, storage classes, or lifecycle configurations.

```bash
# Discover buckets
gcloud storage buckets list --format=json \
  | jq '[.[] | {name: .name, location: .location, storageClass: .storageClass, locationType: .locationType, publicAccessPrevention: .iamConfiguration.publicAccessPrevention, uniformAccess: .iamConfiguration.uniformBucketLevelAccess.enabled}]'
```

## Parallel Execution Requirement

**ALL independent operations MUST run in parallel using background jobs (&) and wait.**

```bash
for bucket in $(gcloud storage buckets list --format="value(name)"); do
  {
    gcloud storage buckets describe "gs://$bucket" --format=json
  } &
done
wait
```

## Helper Functions

```bash
# Get bucket details
get_bucket_details() {
  local bucket="$1"
  gcloud storage buckets describe "gs://$bucket" --format=json \
    | jq '{name: .name, location: .location, storageClass: .storageClass, versioning: .versioning.enabled, lifecycle: .lifecycle.rule | length, retentionPolicy: .retentionPolicy, encryption: .encryption, cors: .cors | length, logging: .logging, website: .website}'
}

# Get bucket size and object count
get_bucket_stats() {
  local bucket="$1"
  gsutil du -s "gs://$bucket" 2>/dev/null
  gcloud storage ls --recursive "gs://$bucket" --format=json --limit=1 2>/dev/null | jq 'length'
}

# List lifecycle rules
get_lifecycle_rules() {
  local bucket="$1"
  gcloud storage buckets describe "gs://$bucket" --format=json \
    | jq '.lifecycle.rule // [] | [.[] | {action: .action.type, storageClass: .action.storageClass, age: .condition.age, createdBefore: .condition.createdBefore, numNewerVersions: .condition.numNewerVersions, matchesStorageClass: .condition.matchesStorageClass, isLive: .condition.isLive}]'
}

# Get IAM policy
get_bucket_iam() {
  local bucket="$1"
  gcloud storage buckets get-iam-policy "gs://$bucket" --format=json \
    | jq '.bindings[] | {role: .role, members: .members}'
}
```

## Common Operations

### 1. Bucket Inventory and Security

```bash
buckets=$(gcloud storage buckets list --format="value(name)")
for bucket in $buckets; do
  {
    get_bucket_details "$bucket"
  } &
done
wait
```

### 2. Lifecycle Rule Analysis

```bash
for bucket in $(gcloud storage buckets list --format="value(name)"); do
  {
    echo "=== $bucket ==="
    get_lifecycle_rules "$bucket"
  } &
done
wait
```

### 3. Access Control Audit

```bash
for bucket in $(gcloud storage buckets list --format="value(name)"); do
  {
    echo "=== $bucket ==="
    gcloud storage buckets describe "gs://$bucket" --format=json \
      | jq '{uniformAccess: .iamConfiguration.uniformBucketLevelAccess.enabled, publicAccessPrevention: .iamConfiguration.publicAccessPrevention}'
    get_bucket_iam "$bucket"
  } &
done
wait
```

### 4. Storage Class Distribution

```bash
# Check object storage classes in a bucket (sample)
gcloud storage ls "gs://$BUCKET" --long --format=json --limit=1000 \
  | jq '[.[].storageClass] | group_by(.) | map({class: .[0], count: length})'

# Bucket-level metrics via monitoring
gcloud monitoring time-series list \
  --filter="metric.type=\"storage.googleapis.com/storage/total_bytes\" AND resource.labels.bucket_name=\"$BUCKET\"" \
  --interval-start-time="$(date -u -v-24H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ)" \
  --format=json
```

### 5. Transfer Service

```bash
# List transfer jobs
gcloud transfer jobs list --format=json \
  | jq '[.[] | {name: .name, status: .status, source: .transferSpec.gcsDataSource // .transferSpec.httpDataSource // .transferSpec.awsS3DataSource, destination: .transferSpec.gcsDataSink, schedule: .schedule, lastModified: .lastModificationTime}]'

# Check recent transfer operations
gcloud transfer operations list --format=json --limit=10 \
  | jq '[.[] | {name: .name, status: .metadata.status, counters: .metadata.counters, startTime: .metadata.startTime}]'
```

## Common Pitfalls

1. **Uniform vs fine-grained access**: Uniform bucket-level access uses only IAM. Fine-grained uses both IAM and ACLs. Check `uniformBucketLevelAccess` before managing permissions.
2. **Storage class transitions**: Objects can be moved to colder classes but cannot be moved back to Standard without rewriting. Check lifecycle rule direction.
3. **Requester pays**: Buckets with requester-pays enabled charge the requester, not the bucket owner. Include `--billing-project` when accessing such buckets.
4. **Object versioning cost**: Versioning keeps all object versions, multiplying storage costs. Check `versioning.enabled` and add lifecycle rules to delete old versions.
5. **Retention policies**: Locked retention policies cannot be removed or shortened. Always verify before locking.
