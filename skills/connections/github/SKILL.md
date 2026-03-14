---
name: github
description: "REQUIRED --repo flag for all commands, helper functions for code review comments, suggestion block syntax rules"
connection_type: github
preload: false
---

# GitHub CLI Skill

Execute GitHub CLI and git commands with proper authentication.

**You must source the helpers before use:**

```bash
source ./_skills/connections/github/github/scripts/github_helpers.sh
```

## CLI Tips

### CRITICAL: Always Use --repo Flag

**ALL commands require explicit `--repo owner/repo` flag.**

```bash
✅ CORRECT:  gh pr list --repo owner/repo
❌ WRONG:    gh pr list              # No repo context!
```

### For Code Review - Use Helper Functions

**ALWAYS use `github_create_pr_comment` helper function for code review inline comments.**

**Why?** Helper functions auto-handle:

- Commit SHA fetching
- Line number targeting
- Suggestion block rendering
- Error recovery

### GitHub Helper Functions (Code Review)

**Inline comment with suggestion block:**

````bash
github_create_pr_comment OWNER REPO PR "file.py" LINE 'Comment text

```suggestion
fixed code
````

' "SIDE"

````
- `SIDE`: "RIGHT" for new code, "LEFT" for old code
- Use single quotes to preserve backticks literally - NO escaping needed

**Discussion comment:**
```bash
github_create_pr_discussion OWNER REPO PR 'Comment text'
````

### Suggestion Block Syntax (CRITICAL)

**✅ CORRECT - Single quotes preserve backticks:**

````bash
github_create_pr_comment owner repo 123 "file.py" 45 '🔴 CRITICAL: Issue

```suggestion
if not input:
    raise ValueError("Required")
````

' "RIGHT"

````

**❌ WRONG - Escaped backticks break rendering:**
```bash
github_create_pr_comment owner repo 123 "file.py" 45 "\`\`\`suggestion
code
\`\`\`" "RIGHT"
````

**Key rules:**

- Use single quotes to wrap comment body containing markdown
- Backticks inside single quotes are literal - write them normally
- NEVER escape backticks with backslashes (\\`) - this breaks GitHub's markdown parser
- Triple backticks for suggestion blocks must be literal: ` ```suggestion`

### Supported Parameters Reference

#### gh pr list

**Supported flags:**
- `--repo owner/repo` : REQUIRED - Repository target
- `--state open|closed|merged|all` : Filter by state
- `--author username` : Filter by author
- `--assignee username` : Filter by assignee
- `--label name` : Filter by label
- `--limit N` : Max number of PRs (default: 30)

**NOT SUPPORTED:**
- `--created` : Date filtering not available in gh CLI
- Alternative: Use `gh api` with GraphQL for date filtering

#### gh issue list

**Supported flags:**
- `--repo owner/repo` : REQUIRED
- `--state open|closed|all`
- `--author username`
- `--assignee username`
- `--label name`
- `--limit N`

**NOT SUPPORTED:**
- `--created-after` : Not available
- Alternative: Use `gh api` endpoint

#### gh pr view

**Supported flags:**
- `--repo owner/repo` : REQUIRED
- `--json FIELDS` : Output specific fields as JSON
- `--web` : Open in browser

**NOT SUPPORTED:**
- `--diff` : Not available (use `gh pr diff` instead)

#### gh pr diff

**Supported flags:**
- `--repo owner/repo` : REQUIRED
- `--patch` : Show full patch format

**NOT SUPPORTED:**
- `--filter` : File filtering not available (pipe to grep instead)

### Helper Function Parameters

#### github_create_pr_comment

**Required parameters:**
1. `owner` : Repository owner (org or user)
2. `repo` : Repository name
3. `pr_number` : PR number (not prefixed with #)
4. `file_path` : File path in repository
5. `end_line` : Line number for comment
6. `body` : Comment text (use single quotes for markdown)
7. `side` : "RIGHT" (new code) or "LEFT" (old code), optional, default: RIGHT
8. `start_line` : Start line for multi-line, optional

**NOT SUPPORTED:**
- `commit_sha` : Automatically fetched by helper
- `position` : Automatically calculated by helper

**Example:**
```bash
# ✅ Correct - single line comment
github_create_pr_comment owner repo 123 "src/main.py" 45 'Fix this issue' "RIGHT"

# ✅ Correct - multi-line with suggestion
github_create_pr_comment owner repo 123 "src/main.py" 45 '```suggestion
fixed code
```' "RIGHT" 43

# ❌ Wrong - escaped backticks
github_create_pr_comment owner repo 123 "src/main.py" 45 "\`\`\`suggestion..." "RIGHT"
```

#### github_create_pr_discussion

**Required parameters:**
1. `owner` : Repository owner
2. `repo` : Repository name
3. `pr_number` : PR number
4. `body` : Comment text

### Parameter Validation Rules

**BEFORE using gh CLI or GitHub helpers:**

1. **Check supported flags** - Verify in this SKILL.md
2. **--repo flag is MANDATORY** - Every gh command needs it
3. **If unsure about a flag** - Use `gh pr list --help` to check
4. **For advanced filtering** - Consider `gh api` with GraphQL

**Common mistake pattern:**
```bash
# User asks: "List PRs created after January 1"
# ❌ WRONG: Assume date filtering exists
gh pr list --repo owner/repo --created-after "2026-01-01"  # Will fail

# ✅ CORRECT: Check SKILL.md first, use alternative
gh api graphql -f query='query { repository(owner:"owner", name:"repo") { pullRequests(first:100, orderBy:{field:CREATED_AT, direction:DESC}) { nodes { number title createdAt } } } }' | jq '.data.repository.pullRequests.nodes[] | select(.createdAt >= "2026-01-01")'
```

### Key Rules

1. **ALWAYS use helper functions for code review inline comments** - Use `github_create_pr_comment`
2. **Always use --repo flag** with gh CLI commands
3. **For general operations**: Use gh CLI (list, view, merge, etc.) - NOT for code review comments
4. **Write operations**: All require user approval
5. **Suggestion blocks**: Must use helper functions with single quotes
6. **Parameter validation**: Check this SKILL.md before using any flag
