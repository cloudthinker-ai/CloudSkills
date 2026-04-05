#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# GitLab Helper Functions for Code Review and CI/CD
#
# Usage: source this file, then call functions directly.
#   source ./scripts/gitlab_helpers.sh
#
# Requirements:
#   - GITLAB_TOKEN environment variable set
#   - GITLAB_URL environment variable set (e.g., https://gitlab.com)
#   - curl and jq installed
#   - project_id as first parameter for all project-scoped functions
###############################################################################

_gitlab_api() {
  local method="${1:?method required}"
  local endpoint="${2:?endpoint required}"
  shift 2
  local data="${1:-}"

  local url="${GITLAB_URL:?GITLAB_URL not set}/api/v4${endpoint}"

  local -a curl_args=(
    -s
    --fail-with-body
    -H "PRIVATE-TOKEN: ${GITLAB_TOKEN:?GITLAB_TOKEN not set}"
    -H "Content-Type: application/json"
    -X "${method}"
  )

  if [[ -n "${data}" ]]; then
    curl_args+=(-d "${data}")
  fi

  local response http_code
  response=$(curl -w "\n%{http_code}" "${curl_args[@]}" "${url}" 2>&1) || true
  http_code=$(echo "${response}" | tail -1)
  local body
  body=$(echo "${response}" | sed '$d')

  if [[ "${http_code}" -ge 400 ]] 2>/dev/null; then
    echo "ERROR: GitLab API returned HTTP ${http_code}" >&2
    echo "${body}" >&2
    return 1
  fi

  echo "${body}"
}

_gitlab_get() { _gitlab_api GET "$@"; }
_gitlab_post() { _gitlab_api POST "$@"; }
_gitlab_put() { _gitlab_api PUT "$@"; }

# -----------------------------------------------------------------------------
# Read-only helpers
# -----------------------------------------------------------------------------

# Get MR metadata
# Usage: gitlab_mr PROJECT_ID MR_IID
gitlab_mr() {
  local project_id="${1:?project_id required}"
  local mr_iid="${2:?mr_iid required}"

  _gitlab_get "/projects/${project_id}/merge_requests/${mr_iid}"
}

# Get MR diff
# Usage: gitlab_mr_diff PROJECT_ID MR_IID [--summary] [--filter PATTERN]
gitlab_mr_diff() {
  local project_id="${1:?project_id required}"
  local mr_iid="${2:?mr_iid required}"
  shift 2

  local summary=false
  local filter=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --summary) summary=true; shift ;;
      --filter) filter="${2:?filter pattern required}"; shift 2 ;;
      *) echo "Unknown option: $1" >&2; return 1 ;;
    esac
  done

  local response
  response=$(_gitlab_get "/projects/${project_id}/merge_requests/${mr_iid}/diffs")

  if [[ "${summary}" == true ]]; then
    echo "${response}" | jq -r '.[] | "\(.new_path) (+\(.additions // 0)/-\(.deletions // 0))"' 2>/dev/null || \
    echo "${response}" | jq -r '.[] | .new_path'
    return
  fi

  if [[ -n "${filter}" ]]; then
    echo "${response}" | jq --arg pat "${filter}" '[.[] | select(.new_path | test($pat))]'
    return
  fi

  echo "${response}"
}

# List MR commits
# Usage: gitlab_mr_commits PROJECT_ID MR_IID
gitlab_mr_commits() {
  local project_id="${1:?project_id required}"
  local mr_iid="${2:?mr_iid required}"

  _gitlab_get "/projects/${project_id}/merge_requests/${mr_iid}/commits"
}

# List changed files in an MR
# Usage: gitlab_mr_changes PROJECT_ID MR_IID [PER_PAGE] [PAGE]
gitlab_mr_changes() {
  local project_id="${1:?project_id required}"
  local mr_iid="${2:?mr_iid required}"
  local per_page="${3:-100}"
  local page="${4:-1}"

  _gitlab_get "/projects/${project_id}/merge_requests/${mr_iid}/changes?per_page=${per_page}&page=${page}"
}

# List pipelines
# Usage: gitlab_pipelines PROJECT_ID [--status STATUS] [--ref REF] [--per-page N]
gitlab_pipelines() {
  local project_id="${1:?project_id required}"
  shift

  local query=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --status) query="${query}&status=${2}"; shift 2 ;;
      --ref) query="${query}&ref=${2}"; shift 2 ;;
      --per-page) query="${query}&per_page=${2}"; shift 2 ;;
      *) echo "Unknown option: $1" >&2; return 1 ;;
    esac
  done

  # Strip leading &
  query="${query#&}"

  _gitlab_get "/projects/${project_id}/pipelines${query:+?${query}}"
}

# List jobs in a pipeline
# Usage: gitlab_jobs PROJECT_ID PIPELINE_ID
gitlab_jobs() {
  local project_id="${1:?project_id required}"
  local pipeline_id="${2:?pipeline_id required}"

  _gitlab_get "/projects/${project_id}/pipelines/${pipeline_id}/jobs"
}

# Get job trace/log output
# Usage: gitlab_job_log PROJECT_ID JOB_ID
gitlab_job_log() {
  local project_id="${1:?project_id required}"
  local job_id="${2:?job_id required}"

  local url="${GITLAB_URL:?GITLAB_URL not set}/api/v4/projects/${project_id}/jobs/${job_id}/trace"

  curl -s \
    -H "PRIVATE-TOKEN: ${GITLAB_TOKEN:?GITLAB_TOKEN not set}" \
    "${url}"
}

# List failed jobs in a pipeline
# Usage: gitlab_pipeline_failures PROJECT_ID PIPELINE_ID
gitlab_pipeline_failures() {
  local project_id="${1:?project_id required}"
  local pipeline_id="${2:?pipeline_id required}"

  local jobs
  jobs=$(_gitlab_get "/projects/${project_id}/pipelines/${pipeline_id}/jobs")

  echo "${jobs}" | jq '[.[] | select(.status == "failed") | {id, name, stage, failure_reason, web_url}]'
}

# -----------------------------------------------------------------------------
# Write helpers (code review)
# -----------------------------------------------------------------------------

# Create an inline diff note (review comment) on a merge request.
# Fetches diff metadata automatically for positioning.
#
# Usage:
#   gitlab_create_diff_note PROJECT_ID MR_IID FILE_PATH LINE BODY [LINE_TYPE]
#
# Parameters:
#   PROJECT_ID - Numeric GitLab project ID
#   MR_IID     - Merge request IID
#   FILE_PATH  - File path relative to repo root
#   LINE       - Line number to comment on
#   BODY       - Comment body (use single quotes for suggestion blocks with offset notation)
#   LINE_TYPE  - "new" (default) for added lines, "old" for removed lines
#
# Example with suggestion block (single quotes, offset notation):
#   gitlab_create_diff_note $PROJ 45 "src/app.py" 10 '```suggestion:-0+1
#   fixed code
#   ```' "new"
#
gitlab_create_diff_note() {
  local project_id="${1:?project_id required}"
  local mr_iid="${2:?mr_iid required}"
  local file_path="${3:?file_path required}"
  local line="${4:?line required}"
  local body="${5:?body required}"
  local line_type="${6:-new}"

  # Fetch diff metadata to get base_sha, head_sha, start_sha
  local diff_meta
  diff_meta=$(_gitlab_get "/projects/${project_id}/merge_requests/${mr_iid}/versions")

  if [[ -z "${diff_meta}" ]] || [[ "${diff_meta}" == "[]" ]]; then
    echo "ERROR: Could not fetch diff versions for MR !${mr_iid}" >&2
    return 1
  fi

  local base_sha head_sha start_sha
  base_sha=$(echo "${diff_meta}" | jq -r '.[0].base_commit_sha')
  head_sha=$(echo "${diff_meta}" | jq -r '.[0].head_commit_sha')
  start_sha=$(echo "${diff_meta}" | jq -r '.[0].start_commit_sha')

  # Build position object
  local old_line new_line
  if [[ "${line_type}" == "old" ]]; then
    old_line="${line}"
    new_line="null"
  else
    old_line="null"
    new_line="${line}"
  fi

  local payload
  payload=$(jq -n \
    --arg body "${body}" \
    --arg base_sha "${base_sha}" \
    --arg head_sha "${head_sha}" \
    --arg start_sha "${start_sha}" \
    --arg new_path "${file_path}" \
    --arg old_path "${file_path}" \
    --argjson old_line "${old_line}" \
    --argjson new_line "${new_line}" \
    '{
      body: $body,
      position: {
        position_type: "text",
        base_sha: $base_sha,
        head_sha: $head_sha,
        start_sha: $start_sha,
        new_path: $new_path,
        old_path: $old_path,
        old_line: $old_line,
        new_line: $new_line
      }
    }')

  local response
  response=$(_gitlab_post "/projects/${project_id}/merge_requests/${mr_iid}/discussions" "${payload}")

  echo "${response}" | jq '{id: .id, notes: [.notes[] | {id: .id, body: .body}]}'
  echo "Diff note created successfully on ${file_path}:${line}"
}

# Create a general discussion comment on an MR (not line-specific).
#
# Usage:
#   gitlab_create_mr_discussion PROJECT_ID MR_IID BODY
#
# Parameters:
#   PROJECT_ID - Numeric GitLab project ID
#   MR_IID     - Merge request IID
#   BODY       - Comment body (use single quotes for markdown)
#
gitlab_create_mr_discussion() {
  local project_id="${1:?project_id required}"
  local mr_iid="${2:?mr_iid required}"
  local body="${3:?body required}"

  local payload
  payload=$(jq -n --arg body "${body}" '{body: $body}')

  local response
  response=$(_gitlab_post "/projects/${project_id}/merge_requests/${mr_iid}/discussions" "${payload}")

  echo "${response}" | jq '{id: .id, web_url: .notes[0].web_url // "N/A"}'
  echo "Discussion created successfully on MR !${mr_iid}"
}
