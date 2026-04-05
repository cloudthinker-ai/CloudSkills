#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# GitHub Helper Functions for Code Review
#
# Usage: source this file, then call functions directly.
#   source ./scripts/github_helpers.sh
#
# Requirements:
#   - GitHub CLI (gh) installed and authenticated
#   - All commands use --repo flag (mandatory)
###############################################################################

# -----------------------------------------------------------------------------
# Read-only helpers
# -----------------------------------------------------------------------------

# Get PR metadata as JSON
# Usage: github_pr_info OWNER REPO PR_NUMBER
github_pr_info() {
  local owner="${1:?owner required}"
  local repo="${2:?repo required}"
  local pr_number="${3:?pr_number required}"

  gh pr view "${pr_number}" \
    --repo "${owner}/${repo}" \
    --json number,title,state,author,baseRefName,headRefName,body,createdAt,updatedAt,mergeable,labels,reviewDecision,additions,deletions,changedFiles
}

# Get PR diff output
# Usage: github_pr_diff OWNER REPO PR_NUMBER
github_pr_diff() {
  local owner="${1:?owner required}"
  local repo="${2:?repo required}"
  local pr_number="${3:?pr_number required}"

  gh pr diff "${pr_number}" --repo "${owner}/${repo}"
}

# Get list of files changed in a PR
# Usage: github_pr_files OWNER REPO PR_NUMBER
github_pr_files() {
  local owner="${1:?owner required}"
  local repo="${2:?repo required}"
  local pr_number="${3:?pr_number required}"

  gh api "repos/${owner}/${repo}/pulls/${pr_number}/files" \
    --paginate \
    --jq '.[] | {filename, status, additions, deletions, changes}'
}

# -----------------------------------------------------------------------------
# Write helpers (code review)
# -----------------------------------------------------------------------------

# Create an inline PR review comment on a specific line.
# Automatically fetches the latest commit SHA from the PR.
#
# Usage:
#   github_create_pr_comment OWNER REPO PR_NUMBER FILE_PATH END_LINE BODY [SIDE] [START_LINE]
#
# Parameters:
#   OWNER      - Repository owner (org or user)
#   REPO       - Repository name
#   PR_NUMBER  - Pull request number
#   FILE_PATH  - File path relative to repo root
#   END_LINE   - Line number to attach comment to
#   BODY       - Comment body (use single quotes for suggestion blocks)
#   SIDE       - "RIGHT" (new code, default) or "LEFT" (old code)
#   START_LINE - Start line for multi-line comments (optional)
#
# Example with suggestion block (single quotes, no escaping):
#   github_create_pr_comment owner repo 123 "src/main.py" 45 '```suggestion
#   fixed code here
#   ```' "RIGHT"
#
github_create_pr_comment() {
  local owner="${1:?owner required}"
  local repo="${2:?repo required}"
  local pr_number="${3:?pr_number required}"
  local file_path="${4:?file_path required}"
  local end_line="${5:?end_line required}"
  local body="${6:?body required}"
  local side="${7:-RIGHT}"
  local start_line="${8:-}"

  # Auto-fetch the latest commit SHA on the PR head
  local commit_sha
  commit_sha=$(gh api "repos/${owner}/${repo}/pulls/${pr_number}" --jq '.head.sha')

  if [[ -z "${commit_sha}" ]]; then
    echo "ERROR: Could not fetch commit SHA for PR #${pr_number}" >&2
    return 1
  fi

  # Build the JSON payload
  local json_payload
  if [[ -n "${start_line}" ]]; then
    json_payload=$(jq -n \
      --arg body "${body}" \
      --arg commit_id "${commit_sha}" \
      --arg path "${file_path}" \
      --arg side "${side}" \
      --argjson line "${end_line}" \
      --argjson start_line "${start_line}" \
      '{
        body: $body,
        commit_id: $commit_id,
        path: $path,
        side: $side,
        line: $line,
        start_line: $start_line,
        start_side: $side
      }')
  else
    json_payload=$(jq -n \
      --arg body "${body}" \
      --arg commit_id "${commit_sha}" \
      --arg path "${file_path}" \
      --arg side "${side}" \
      --argjson line "${end_line}" \
      '{
        body: $body,
        commit_id: $commit_id,
        path: $path,
        side: $side,
        line: $line
      }')
  fi

  local response
  response=$(echo "${json_payload}" | gh api \
    "repos/${owner}/${repo}/pulls/${pr_number}/comments" \
    --method POST \
    --input - 2>&1) || {
    echo "ERROR: Failed to create PR comment" >&2
    echo "${response}" >&2
    return 1
  }

  echo "${response}" | jq -r '{id: .id, html_url: .html_url, created_at: .created_at}'
  echo "Comment created successfully on ${file_path}:${end_line}"
}

# Create a general discussion comment on a PR (not line-specific).
#
# Usage:
#   github_create_pr_discussion OWNER REPO PR_NUMBER BODY
#
# Parameters:
#   OWNER      - Repository owner
#   REPO       - Repository name
#   PR_NUMBER  - Pull request number
#   BODY       - Comment body (use single quotes for markdown)
#
github_create_pr_discussion() {
  local owner="${1:?owner required}"
  local repo="${2:?repo required}"
  local pr_number="${3:?pr_number required}"
  local body="${4:?body required}"

  local response
  response=$(gh pr comment "${pr_number}" \
    --repo "${owner}/${repo}" \
    --body "${body}" 2>&1) || {
    echo "ERROR: Failed to create PR discussion comment" >&2
    echo "${response}" >&2
    return 1
  }

  echo "${response}"
  echo "Discussion comment created successfully on PR #${pr_number}"
}
