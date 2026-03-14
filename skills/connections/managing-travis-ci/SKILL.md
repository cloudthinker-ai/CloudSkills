---
name: managing-travis-ci
description: |
  Travis CI build management and monitoring. Covers build history, repository settings, cron job management, cache administration, and environment variable configuration. Use when checking build status, investigating failures, managing cron schedules, or auditing Travis CI repository settings.
connection_type: travis-ci
preload: false
---

# Travis CI Management Skill

Manage and monitor Travis CI builds, repositories, and cron jobs.

## Core Helper Functions

```bash
#!/bin/bash

# Travis CI API v3 helper
travis_api() {
    local method="${1:-GET}"
    local endpoint="$2"
    local data="${3:-}"
    local api_url="${TRAVIS_API_URL:-https://api.travis-ci.com}"

    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Travis-API-Version: 3" \
            -H "Authorization: token ${TRAVIS_TOKEN}" \
            -H "Content-Type: application/json" \
            "${api_url}/${endpoint}" \
            -d "$data"
    else
        curl -s -X "$method" \
            -H "Travis-API-Version: 3" \
            -H "Authorization: token ${TRAVIS_TOKEN}" \
            "${api_url}/${endpoint}"
    fi
}

# URL-encode repo slug
travis_repo_slug() {
    echo "${1}" | sed 's/\//%2F/g'
}
```

## MANDATORY: Discovery-First Pattern

**Always list repositories and recent builds before querying specifics.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Current User ==="
travis_api GET "user" | jq '{login: .login, name: .name, is_syncing: .is_syncing}'

echo ""
echo "=== Active Repositories ==="
travis_api GET "repos?active=true&sort_by=current_build:desc&limit=20" | jq -r '
    .repositories[] |
    "\(.slug)\t\(.current_build.state // "none")\tbranch=\(.default_branch.name)\t#\(.current_build.number // "0")"
' | column -t

echo ""
echo "=== Recent Builds (across repos) ==="
travis_api GET "builds?sort_by=started_at:desc&limit=15" | jq -r '
    .builds[] |
    "\(.repository.slug)\t#\(.number)\t\(.state)\t\(.branch.name)\t\(.started_at[0:16] // "pending")"
' | column -t
```

## Output Rules
- **TOKEN EFFICIENCY**: Target 50 lines per output
- Use `include` parameter to embed related resources in single request
- Never dump full job logs — tail relevant sections

## Common Operations

### Build History Dashboard

```bash
#!/bin/bash
REPO_SLUG=$(travis_repo_slug "${1:?Repo slug required (owner/repo)}")

echo "=== Recent Builds ==="
travis_api GET "repo/${REPO_SLUG}/builds?limit=15&sort_by=started_at:desc" | jq -r '
    .builds[] |
    "\(#\(.number))\t\(.state)\t\(.branch.name)\t\(.event_type)\t\(.duration // 0)s\t\(.started_at[0:16] // "pending")"
' | column -t

echo ""
echo "=== Build Statistics ==="
travis_api GET "repo/${REPO_SLUG}/builds?limit=50" | jq '{
    total: (.builds | length),
    passed: [.builds[] | select(.state == "passed")] | length,
    failed: [.builds[] | select(.state == "failed")] | length,
    errored: [.builds[] | select(.state == "errored")] | length,
    canceled: [.builds[] | select(.state == "canceled")] | length,
    avg_duration: ([.builds[] | select(.duration != null) | .duration] | add / length | floor)
}'
```

### Job Log Analysis

```bash
#!/bin/bash
REPO_SLUG=$(travis_repo_slug "${1:?Repo slug required}")
BUILD_NUMBER="${2:?Build number required}"

echo "=== Build Jobs ==="
travis_api GET "repo/${REPO_SLUG}/build/${BUILD_NUMBER}?include=build.jobs" | jq -r '
    .jobs[] |
    "\(.id)\t\(.number)\t\(.state)\t\(.os // "linux")\t\(.duration // 0)s"
' | column -t

echo ""
echo "=== Failed Job Log (tail) ==="
FAILED_JOB=$(travis_api GET "repo/${REPO_SLUG}/build/${BUILD_NUMBER}?include=build.jobs" | jq '.jobs[] | select(.state == "failed") | .id' | head -1)
if [ -n "$FAILED_JOB" ]; then
    travis_api GET "job/${FAILED_JOB}/log" | jq -r '.content' | tail -60
fi
```

### Repository Settings

```bash
#!/bin/bash
REPO_SLUG=$(travis_repo_slug "${1:?Repo slug required}")

echo "=== Repository Settings ==="
travis_api GET "repo/${REPO_SLUG}/settings" | jq -r '
    .settings[] | "\(.name)\t\(.value)"
' | column -t

echo ""
echo "=== Repository Info ==="
travis_api GET "repo/${REPO_SLUG}" | jq '{
    slug: .slug,
    active: .active,
    default_branch: .default_branch.name,
    starred: .starred,
    managed_by_installation: .managed_by_installation,
    server_type: .server_type
}'
```

### Cron Job Management

```bash
#!/bin/bash
REPO_SLUG=$(travis_repo_slug "${1:?Repo slug required}")

echo "=== Cron Jobs ==="
travis_api GET "repo/${REPO_SLUG}/crons" | jq -r '
    .crons[] |
    "\(.id)\tbranch=\(.branch.name)\tinterval=\(.interval)\tnext=\(.next_run[0:16])\tactive=\(.active)"
' | column -t

echo ""
echo "=== Cron Details ==="
travis_api GET "repo/${REPO_SLUG}/crons" | jq '.crons[] | {
    id, interval, active,
    branch: .branch.name,
    dont_run_if_recent_build_exists: .dont_run_if_recent_build_exists,
    next_run, last_run: .last_run
}'
```

### Cache Management

```bash
#!/bin/bash
REPO_SLUG=$(travis_repo_slug "${1:?Repo slug required}")

echo "=== Repository Caches ==="
travis_api GET "repo/${REPO_SLUG}/caches" | jq -r '
    .caches[]? |
    "\(.branch)\t\(.name)\tsize=\(.size // 0)\tlast_modified=\(.last_modified[0:16])"
' | column -t

echo ""
echo "=== Environment Variables ==="
travis_api GET "repo/${REPO_SLUG}/env_vars" | jq -r '
    .env_vars[] | "\(.name)\tpublic=\(.public)\tbranch=\(.branch // "all")"
' | column -t
```

## Anti-Hallucination Rules
- NEVER guess repository slugs — always discover via API first
- NEVER fabricate build numbers — query build history
- NEVER assume job IDs — they are numeric and must be looked up
- Travis CI .com and .org have different API endpoints — confirm which is in use

## Safety Rules
- NEVER restart or cancel builds without explicit user confirmation
- NEVER delete caches without user approval — can cause slow builds
- NEVER modify environment variables without confirming — may contain secrets
- Public env vars are visible in build logs — flag security concern

## Common Pitfalls
- **travis-ci.com vs .org**: `.org` is legacy (free open source), `.com` is current — use correct API URL
- **API v3 header**: Must include `Travis-API-Version: 3` header — omitting uses v2 (deprecated)
- **Repo slug encoding**: Slugs with `/` must be URL-encoded (e.g., `owner%2Frepo`)
- **Build vs job**: A build contains multiple jobs (matrix) — check individual jobs for failures
- **Cron intervals**: Only `daily`, `weekly`, `monthly` — no custom cron expressions
- **Migration status**: Many projects have migrated away from Travis — check if repo is still active
