---
name: managing-github-deep
description: |
  Use when working with Github Deep — gitHub deep platform management covering
  repository inventory, branch protection analysis, Actions workflow monitoring,
  security alerts, dependency graph, code scanning results, organization member
  auditing, and webhook management. Use when auditing repository configurations,
  investigating CI/CD failures, reviewing security posture, or managing
  organization-wide settings.
connection_type: github
preload: false
---

# GitHub Deep Management Skill

Manage and monitor GitHub repositories, Actions, security, and organization settings at depth.

## MANDATORY: Discovery-First Pattern

**Always list repositories and check organization settings before querying specific resources.**

### Phase 1: Discovery

```bash
#!/bin/bash

GH_API="https://api.github.com"

gh_api() {
    curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
         -H "Accept: application/vnd.github+json" \
         -H "X-GitHub-Api-Version: 2022-11-28" \
         "${GH_API}/${1}"
}

echo "=== Organization Info ==="
gh_api "orgs/${GITHUB_ORG}" | jq '{
    name: .name, plan: .plan.name,
    repos: .total_private_repos, public_repos: .public_repos,
    members: .collaborators
}'

echo ""
echo "=== Repositories ==="
gh_api "orgs/${GITHUB_ORG}/repos?per_page=30&sort=updated" | jq -r '
    .[] |
    "\(.name)\t\(.visibility)\t\(.default_branch)\t\(.pushed_at[:10])\t\(.archived)"
' | column -t | head -30

echo ""
echo "=== Teams ==="
gh_api "orgs/${GITHUB_ORG}/teams?per_page=30" | jq -r '
    .[] |
    "\(.slug)\t\(.privacy)\t\(.members_count // "?")\t\(.repos_count // "?")"
' | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Branch Protection (top repos) ==="
gh_api "orgs/${GITHUB_ORG}/repos?per_page=10&sort=updated" | jq -r '.[].name' | while read repo; do
    DEFAULT=$(gh_api "repos/${GITHUB_ORG}/${repo}" | jq -r '.default_branch')
    PROT=$(gh_api "repos/${GITHUB_ORG}/${repo}/branches/${DEFAULT}/protection" 2>/dev/null)
    STATUS=$(echo "$PROT" | jq -r '.required_status_checks.strict // "none"' 2>/dev/null)
    REVIEWS=$(echo "$PROT" | jq -r '.required_pull_request_reviews.required_approving_review_count // 0' 2>/dev/null)
    echo -e "${repo}\t${DEFAULT}\tstrict=${STATUS}\treviews=${REVIEWS}"
done | column -t

echo ""
echo "=== Security Alerts (Dependabot) ==="
gh_api "orgs/${GITHUB_ORG}/repos?per_page=10&sort=updated" | jq -r '.[].name' | while read repo; do
    COUNT=$(gh_api "repos/${GITHUB_ORG}/${repo}/dependabot/alerts?state=open&per_page=1" | jq '. | length' 2>/dev/null)
    [ "$COUNT" != "0" ] && echo -e "${repo}\t${COUNT} open alerts"
done | column -t

echo ""
echo "=== Failed Actions Workflows (recent) ==="
gh_api "orgs/${GITHUB_ORG}/repos?per_page=5&sort=updated" | jq -r '.[].name' | while read repo; do
    gh_api "repos/${GITHUB_ORG}/${repo}/actions/runs?status=failure&per_page=3" | jq -r --arg repo "$repo" '
        .workflow_runs[]? |
        "\($repo)\t\(.name)\t\(.conclusion)\t\(.created_at[:10])"
    '
done | column -t | head -20

echo ""
echo "=== Webhooks (org level) ==="
gh_api "orgs/${GITHUB_ORG}/hooks" | jq -r '
    .[] |
    "\(.id)\t\(.config.url[:50])\t\(.active)\t\(.events | join(","))"
' | column -t | head -10
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use per_page parameter to limit results
- Never dump full repository contents or workflow logs -- extract status metadata

## Output Format

Present results as a structured report:
```
Managing Github Deep Report
═══════════════════════════
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

- **Rate limits**: GitHub API allows 5000 req/h for authenticated users -- batch queries carefully
- **Branch protection bypass**: Admin users can bypass branch protection unless "include administrators" is set
- **Actions minutes**: Private repos consume Actions minutes from org quota
- **Secret scanning**: Leaked secrets in history require rotation even after removal
- **CODEOWNERS**: CODEOWNERS file must be in correct location (.github/, root, or docs/) to be active
- **Forked PRs**: PRs from forks have limited Actions permissions -- secrets are not available
- **GraphQL alternative**: For complex queries, GitHub GraphQL API is more efficient than REST
- **Archived repos**: Archived repos still count toward plan limits but cannot be modified
