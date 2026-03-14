---
name: managing-aws-codebuild
description: |
  AWS CodeBuild project management and build analysis. Covers build project inventory, build history, build phase details, environment configurations, source credentials, report groups, and build metrics. Use when inspecting build projects, debugging build failures, reviewing build environments, or analyzing build performance.
connection_type: aws
preload: false
---

# AWS CodeBuild Management Skill

Analyze and manage AWS CodeBuild projects, builds, and build environments.

## MANDATORY: Discovery-First Pattern

**Always list projects before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash
export AWS_PAGER=""

echo "=== CodeBuild Projects ==="
PROJECT_NAMES=$(aws codebuild list-projects --output text --query 'projects[]')

echo ""
echo "=== Project Details ==="
if [ -n "$PROJECT_NAMES" ]; then
  aws codebuild batch-get-projects --names $PROJECT_NAMES --output text \
    --query 'projects[].[name,source.type,environment.computeType,environment.image,lastModified]' | head -30
fi

echo ""
echo "=== Source Credentials ==="
aws codebuild list-source-credentials --output text \
  --query 'sourceCredentialsInfos[].[serverType,authType,arn]' 2>/dev/null

echo ""
echo "=== Report Groups ==="
aws codebuild list-report-groups --output text \
  --query 'reportGroups[]' 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash
export AWS_PAGER=""

echo "=== Recent Builds ==="
BUILD_IDS=$(aws codebuild list-builds --max-items 20 --output text --query 'ids[]')
if [ -n "$BUILD_IDS" ]; then
  aws codebuild batch-get-builds --ids $BUILD_IDS --output text \
    --query 'builds[].[projectName,buildNumber,buildStatus,startTime,endTime,sourceVersion]' | head -20
fi

echo ""
echo "=== Failed Builds (last 20) ==="
if [ -n "$BUILD_IDS" ]; then
  aws codebuild batch-get-builds --ids $BUILD_IDS --output text \
    --query "builds[?buildStatus=='FAILED'].[projectName,buildNumber,buildStatus,phases[-1].phaseType,phases[-1].phaseStatus]"
fi

echo ""
echo "=== Build Duration Analysis ==="
for project in $(aws codebuild list-projects --output text --query 'projects[]'); do
  {
    build_ids=$(aws codebuild list-builds-for-project --project-name "$project" --max-items 5 --output text --query 'ids[]')
    if [ -n "$build_ids" ]; then
      aws codebuild batch-get-builds --ids $build_ids --output text \
        --query "builds[].[projectName,buildNumber,buildStatus]" | head -5
    fi
  } &
done
wait

echo ""
echo "=== Build Environment Summary ==="
PROJECT_NAMES=$(aws codebuild list-projects --output text --query 'projects[]')
if [ -n "$PROJECT_NAMES" ]; then
  aws codebuild batch-get-projects --names $PROJECT_NAMES --output text \
    --query 'projects[].[name,environment.computeType,environment.type,environment.privilegedMode]' | head -20
fi
```

## Output Format

- Target ≤50 lines per output
- Use `--output text --query` and `batch-get-*` APIs for efficiency
- Tab-delimited fields: ProjectName, BuildNumber, Status, Duration
- Use batch APIs instead of individual describe calls
- Never dump full buildspec -- show source type and environment only

## Common Pitfalls

- **Build status values**: SUCCEEDED, FAILED, FAULT, TIMED_OUT, IN_PROGRESS, STOPPED
- **Batch APIs**: Always use `batch-get-projects` and `batch-get-builds` instead of individual calls
- **Build phases**: SUBMITTED, QUEUED, PROVISIONING, DOWNLOAD_SOURCE, INSTALL, PRE_BUILD, BUILD, POST_BUILD, UPLOAD_ARTIFACTS, FINALIZING
- **Privileged mode**: Required for Docker builds -- check `privilegedMode` in environment config
- **Compute types**: BUILD_GENERAL1_SMALL, MEDIUM, LARGE, 2XLARGE -- affects cost and build speed
- **Source credentials**: Shared across projects per server type -- changing affects all projects
- **Cache**: Check `cache.type` (NO_CACHE, S3, LOCAL) -- caching significantly impacts build times
