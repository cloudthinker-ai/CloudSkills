---
name: managing-rubygems
description: |
  Use when working with Rubygems — rubyGems package registry management. Covers
  gem publishing, version management, Bundler dependency resolution, gemspec
  configuration, and security scanning. Use when managing Ruby gems, publishing
  to RubyGems.org, resolving Bundler conflicts, or auditing gem vulnerabilities.
connection_type: rubygems
preload: false
---

# RubyGems Registry Management Skill

Manage and analyze Ruby gems, Bundler dependencies, and gem publishing.

## MANDATORY: Discovery-First Pattern

**Always check current Gemfile and gemspec configuration before modifying packages.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Gemspec ==="
cat *.gemspec 2>/dev/null | head -20

echo ""
echo "=== Gemfile ==="
cat Gemfile 2>/dev/null | head -20

echo ""
echo "=== Ruby/Bundler Version ==="
ruby --version 2>/dev/null
bundler --version 2>/dev/null

echo ""
echo "=== Gem Sources ==="
gem sources --list 2>/dev/null
```

### Phase 2: Analysis

```bash
#!/bin/bash

echo "=== Installed Gems ==="
bundle list 2>/dev/null | head -15

echo ""
echo "=== Outdated Gems ==="
bundle outdated 2>/dev/null | head -15

echo ""
echo "=== Security Audit ==="
bundle audit check 2>/dev/null | head -15
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- List gems with version constraints
- Report audit findings by severity
- Never expose gem credentials in output

## Common Operations

### Gem Lookup

```bash
#!/bin/bash
GEM="${1:?Gem name required}"
echo "=== Gem Info: $GEM ==="
curl -s "https://rubygems.org/api/v1/gems/${GEM}.json" | jq '{
  name: .name,
  version: .version,
  downloads: .downloads,
  info: .info,
  licenses: .licenses
}' 2>/dev/null
```

### Build and Push Preview

```bash
#!/bin/bash
echo "=== Build Gem ==="
gem build *.gemspec 2>&1 | tail -5
ls -la *.gem 2>/dev/null
```

## Safety Rules

- **Never expose RubyGems API keys** in Gemfile or configuration
- **Run `bundle audit`** before deploying to catch known vulnerabilities
- **Use Gemfile.lock** for applications to ensure reproducible installs
- **Test gem builds** with `gem build` before pushing to RubyGems.org

## Output Format

Present results as a structured report:
```
Managing Rubygems Report
════════════════════════
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

