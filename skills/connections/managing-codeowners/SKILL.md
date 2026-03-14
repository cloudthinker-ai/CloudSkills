---
name: managing-codeowners
description: |
  CODEOWNERS file management covering ownership mapping analysis, coverage gap detection, team assignment validation, orphaned path identification, and review requirement auditing. Use when auditing code ownership across repositories, identifying unowned code paths, validating team configurations, or optimizing pull request review workflows.
connection_type: github
preload: false
---

# CODEOWNERS Management Skill

Analyze and audit CODEOWNERS files across repositories for coverage, consistency, and review efficiency.

## MANDATORY: Discovery-First Pattern

**Always locate CODEOWNERS files and list teams before analyzing ownership.**

### Phase 1: Discovery

```bash
#!/bin/bash

GH_API="https://api.github.com"

gh_api() {
    curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
         -H "Accept: application/vnd.github+json" \
         "${GH_API}/${1}"
}

echo "=== Locate CODEOWNERS Files ==="
gh_api "orgs/${GITHUB_ORG}/repos?per_page=20&sort=updated" | jq -r '.[].full_name' | while read repo; do
    for path in ".github/CODEOWNERS" "CODEOWNERS" "docs/CODEOWNERS"; do
        RESULT=$(gh_api "repos/${repo}/contents/${path}" 2>/dev/null)
        if echo "$RESULT" | jq -e '.name' >/dev/null 2>&1; then
            echo -e "${repo}\t${path}\tFOUND"
            break
        fi
    done
done | column -t | head -20

echo ""
echo "=== Organization Teams ==="
gh_api "orgs/${GITHUB_ORG}/teams?per_page=30" | jq -r '
    .[] |
    "\(.slug)\t\(.members_count // "?")\t\(.privacy)"
' | column -t | head -20
```

### Phase 2: Analysis

```bash
#!/bin/bash

REPO="${1:-${GITHUB_ORG}/${GITHUB_REPO}}"

echo "=== CODEOWNERS Content ==="
CODEOWNERS=$(gh_api "repos/${REPO}/contents/.github/CODEOWNERS" 2>/dev/null || \
    gh_api "repos/${REPO}/contents/CODEOWNERS" 2>/dev/null)
echo "$CODEOWNERS" | jq -r '.content' | base64 -d 2>/dev/null | grep -v '^#' | grep -v '^$' | head -30

echo ""
echo "=== Ownership Summary ==="
echo "$CODEOWNERS" | jq -r '.content' | base64 -d 2>/dev/null | grep -v '^#' | grep -v '^$' | \
    awk '{for(i=2;i<=NF;i++) owners[$i]++} END {for(o in owners) print o"\t"owners[o]" patterns"}' | \
    sort -t$'\t' -k2 -rn | column -t | head -20

echo ""
echo "=== Wildcard Patterns ==="
echo "$CODEOWNERS" | jq -r '.content' | base64 -d 2>/dev/null | grep -v '^#' | grep '\*' | head -15

echo ""
echo "=== Repos Without CODEOWNERS ==="
gh_api "orgs/${GITHUB_ORG}/repos?per_page=20&sort=updated" | jq -r '.[].full_name' | while read repo; do
    HAS=false
    for path in ".github/CODEOWNERS" "CODEOWNERS" "docs/CODEOWNERS"; do
        if gh_api "repos/${repo}/contents/${path}" 2>/dev/null | jq -e '.name' >/dev/null 2>&1; then
            HAS=true; break
        fi
    done
    [ "$HAS" = "false" ] && echo -e "${repo}\tNO CODEOWNERS"
done | column -t | head -15
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Summarize ownership patterns rather than dumping full files
- Focus on gaps and issues rather than complete listings

## Common Pitfalls

- **File location**: CODEOWNERS must be in .github/, root, or docs/ -- other locations are ignored
- **Pattern order**: Last matching pattern wins -- order matters for overlapping rules
- **Team existence**: References to deleted or renamed teams silently fail -- no review required
- **Syntax errors**: Invalid lines are silently ignored -- validate syntax
- **Glob patterns**: CODEOWNERS uses gitignore-style patterns, not full regex
- **Required reviews**: CODEOWNERS only enforces reviews if branch protection requires code owner approval
- **Performance**: Repositories with very large CODEOWNERS files may have slow PR review assignment
