---
name: managing-semantic-release
description: |
  Use when working with Semantic Release — semantic-release automated versioning
  management covering release configuration analysis, release history tracking,
  commit convention compliance, plugin chain auditing, branch strategy review,
  and changelog generation monitoring. Use when auditing release pipelines,
  investigating failed releases, reviewing version bump patterns, or validating
  commit message conventions.
connection_type: github
preload: false
---

# Semantic Release Management Skill

Analyze and monitor semantic-release configurations, release history, and commit conventions.

## MANDATORY: Discovery-First Pattern

**Always locate release configuration and check recent releases before analyzing specific issues.**

### Phase 1: Discovery

```bash
#!/bin/bash

GH_API="https://api.github.com"

gh_api() {
    curl -s -H "Authorization: Bearer $GITHUB_TOKEN" \
         -H "Accept: application/vnd.github+json" \
         "${GH_API}/${1}"
}

echo "=== Locate Release Config ==="
gh_api "orgs/${GITHUB_ORG}/repos?per_page=15&sort=updated" | jq -r '.[].full_name' | while read repo; do
    for cfg in ".releaserc" ".releaserc.json" ".releaserc.yml" ".releaserc.yaml" "release.config.js" "release.config.cjs" "release.config.mjs"; do
        if gh_api "repos/${repo}/contents/${cfg}" 2>/dev/null | jq -e '.name' >/dev/null 2>&1; then
            echo -e "${repo}\t${cfg}\tFOUND"
            break
        fi
    done
done | column -t | head -15

echo ""
echo "=== Recent Releases ==="
gh_api "orgs/${GITHUB_ORG}/repos?per_page=10&sort=updated" | jq -r '.[].full_name' | while read repo; do
    gh_api "repos/${repo}/releases?per_page=3" | jq -r --arg repo "$repo" '
        .[]? |
        "\($repo)\t\(.tag_name)\t\(.published_at[:10])\t\(.prerelease)"
    '
done | column -t | head -20

echo ""
echo "=== Latest Tags ==="
gh_api "orgs/${GITHUB_ORG}/repos?per_page=10&sort=updated" | jq -r '.[].full_name' | while read repo; do
    LATEST=$(gh_api "repos/${repo}/tags?per_page=1" | jq -r '.[0].name // "none"')
    echo -e "${repo}\t${LATEST}"
done | column -t | head -15
```

### Phase 2: Analysis

```bash
#!/bin/bash

REPO="${1:-${GITHUB_ORG}/${GITHUB_REPO}}"

echo "=== Release Config Analysis ==="
for cfg in ".releaserc" ".releaserc.json" ".releaserc.yml" "release.config.js" "release.config.cjs"; do
    CONTENT=$(gh_api "repos/${REPO}/contents/${cfg}" 2>/dev/null)
    if echo "$CONTENT" | jq -e '.name' >/dev/null 2>&1; then
        echo "Config: ${cfg}"
        echo "$CONTENT" | jq -r '.content' | base64 -d 2>/dev/null | head -30
        break
    fi
done

echo ""
echo "=== Release History (last 10) ==="
gh_api "repos/${REPO}/releases?per_page=10" | jq -r '
    .[] |
    "\(.tag_name)\t\(.published_at[:10])\tpre=\(.prerelease)\tdraft=\(.draft)"
' | column -t

echo ""
echo "=== Version Bump Pattern ==="
gh_api "repos/${REPO}/releases?per_page=20" | jq -r '[.[] | .tag_name] |
    if length > 1 then
        {
            latest: .[0],
            oldest_shown: .[-1],
            total_releases: length
        }
    else
        {latest: .[0] // "none"}
    end'

echo ""
echo "=== Recent Commits (convention check) ==="
gh_api "repos/${REPO}/commits?per_page=15" | jq -r '
    .[] |
    "\(.sha[:7])\t\(.commit.message | split("\n")[0][:60])"
' | column -t
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Summarize plugin chains and branch configs rather than dumping raw config
- Focus on version patterns and convention compliance

## Output Format

Present results as a structured report:
```
Managing Semantic Release Report
════════════════════════════════
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

- **Commit conventions**: Non-conventional commits produce no release -- verify commit message format
- **Plugin order**: Plugins execute in order -- analyzeCommits before generateNotes before publish
- **Branch config**: Release branches (main, next, beta) control which branches trigger releases
- **Dry run**: Always test with --dry-run before changing config
- **CI permissions**: Release needs write access to repo, registry, and changelog
- **Monorepo**: Multi-package repos need semantic-release-monorepo or workspace plugin
- **Pre-release channels**: Beta/alpha channels use separate version tracks
- **Git tags**: Deleted tags confuse semantic-release version calculation
