#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# Bitbucket Helper Functions for Code Review
#
# Usage: source this file, then call functions directly.
#   source ./scripts/bitbucket_helpers.sh
#
# Requirements:
#   - BITBUCKET_TOKEN environment variable set (OAuth bearer token)
#   - curl and jq installed
#   - workspace and repo_slug as parameters for all repo-scoped functions
###############################################################################

readonly BITBUCKET_API_BASE="https://api.bitbucket.org/2.0"

_bitbucket_api() {
  local method="${1:?method required}"
  local endpoint="${2:?endpoint required}"
  shift 2
  local data="${1:-}"

  local url="${BITBUCKET_API_BASE}${endpoint}"

  local -a curl_args=(
    -s
    --fail-with-body
    -H "Authorization: Bearer ${BITBUCKET_TOKEN:?BITBUCKET_TOKEN not set}"
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
    # Retry once on 429 (rate limit)
    if [[ "${http_code}" == "429" ]]; then
      echo "Rate limited, retrying in 3 seconds..." >&2
      sleep 3
      response=$(curl -w "\n%{http_code}" "${curl_args[@]}" "${url}" 2>&1) || true
      http_code=$(echo "${response}" | tail -1)
      body=$(echo "${response}" | sed '$d')
      if [[ "${http_code}" -ge 400 ]] 2>/dev/null; then
        echo "ERROR: Bitbucket API returned HTTP ${http_code} after retry" >&2
        echo "${body}" >&2
        return 1
      fi
    else
      echo "ERROR: Bitbucket API returned HTTP ${http_code}" >&2
      echo "${body}" >&2
      return 1
    fi
  fi

  echo "${body}"
}

_bitbucket_get() { _bitbucket_api GET "$@"; }
_bitbucket_post() { _bitbucket_api POST "$@"; }

# -----------------------------------------------------------------------------
# Read-only helpers
# -----------------------------------------------------------------------------

# Get PR details
# Usage: bitbucket_pr WORKSPACE REPO_SLUG PR_ID
bitbucket_pr() {
  local workspace="${1:?workspace required}"
  local repo_slug="${2:?repo_slug required}"
  local pr_id="${3:?pr_id required}"

  _bitbucket_get "/repositories/${workspace}/${repo_slug}/pullrequests/${pr_id}"
}

# Get PR diff
# Usage: bitbucket_pr_diff WORKSPACE REPO_SLUG PR_ID
bitbucket_pr_diff() {
  local workspace="${1:?workspace required}"
  local repo_slug="${2:?repo_slug required}"
  local pr_id="${3:?pr_id required}"

  local url="${BITBUCKET_API_BASE}/repositories/${workspace}/${repo_slug}/pullrequests/${pr_id}/diff"

  curl -s \
    -H "Authorization: Bearer ${BITBUCKET_TOKEN:?BITBUCKET_TOKEN not set}" \
    "${url}"
}

# Get PR comments
# Usage: bitbucket_pr_comments WORKSPACE REPO_SLUG PR_ID
bitbucket_pr_comments() {
  local workspace="${1:?workspace required}"
  local repo_slug="${2:?repo_slug required}"
  local pr_id="${3:?pr_id required}"

  _bitbucket_get "/repositories/${workspace}/${repo_slug}/pullrequests/${pr_id}/comments"
}

# List repositories in a workspace
# Usage: bitbucket_repos WORKSPACE [PER_PAGE]
bitbucket_repos() {
  local workspace="${1:?workspace required}"
  local per_page="${2:-25}"

  _bitbucket_get "/repositories/${workspace}?pagelen=${per_page}"
}

# List branches in a repository
# Usage: bitbucket_branches WORKSPACE REPO_SLUG
bitbucket_branches() {
  local workspace="${1:?workspace required}"
  local repo_slug="${2:?repo_slug required}"

  _bitbucket_get "/repositories/${workspace}/${repo_slug}/refs/branches"
}

# -----------------------------------------------------------------------------
# Write helpers (code review)
# -----------------------------------------------------------------------------

# Create an inline PR comment on a specific line.
#
# Usage:
#   bitbucket_create_pr_comment WORKSPACE REPO_SLUG PR_ID FILE_PATH LINE_NUMBER BODY
#
# Parameters:
#   WORKSPACE   - Bitbucket workspace slug
#   REPO_SLUG   - Repository slug
#   PR_ID       - Pull request ID
#   FILE_PATH   - File path relative to repo root
#   LINE_NUMBER - Line number on the NEW side of the diff
#   BODY        - Comment body (use single quotes for suggestion blocks)
#
# Example with suggestion block (single quotes, no escaping):
#   bitbucket_create_pr_comment myworkspace myrepo 123 "src/auth.py" 45 '```suggestion
#   if not validate_input(data):
#       raise ValueError("Invalid input")
#   ```'
#
bitbucket_create_pr_comment() {
  local workspace="${1:?workspace required}"
  local repo_slug="${2:?repo_slug required}"
  local pr_id="${3:?pr_id required}"
  local file_path="${4:?file_path required}"
  local line_number="${5:?line_number required}"
  local body="${6:?body required}"

  local payload
  payload=$(jq -n \
    --arg body "${body}" \
    --arg path "${file_path}" \
    --argjson line "${line_number}" \
    '{
      content: {
        raw: $body
      },
      inline: {
        to: $line,
        path: $path
      }
    }')

  local response
  response=$(_bitbucket_post "/repositories/${workspace}/${repo_slug}/pullrequests/${pr_id}/comments" "${payload}")

  echo "${response}" | jq '{id: .id, created_on: .created_on, links: .links.html.href}'
  echo "Inline comment created on ${file_path}:${line_number}"
}

# Create a general discussion comment on a PR (not line-specific).
#
# Usage:
#   bitbucket_create_pr_discussion WORKSPACE REPO_SLUG PR_ID BODY
#
# Parameters:
#   WORKSPACE - Bitbucket workspace slug
#   REPO_SLUG - Repository slug
#   PR_ID     - Pull request ID
#   BODY      - Comment body (use single quotes for markdown)
#
bitbucket_create_pr_discussion() {
  local workspace="${1:?workspace required}"
  local repo_slug="${2:?repo_slug required}"
  local pr_id="${3:?pr_id required}"
  local body="${4:?body required}"

  local payload
  payload=$(jq -n \
    --arg body "${body}" \
    '{
      content: {
        raw: $body
      }
    }')

  local response
  response=$(_bitbucket_post "/repositories/${workspace}/${repo_slug}/pullrequests/${pr_id}/comments" "${payload}")

  echo "${response}" | jq '{id: .id, created_on: .created_on, links: .links.html.href}'
  echo "Discussion comment created on PR #${pr_id}"
}
