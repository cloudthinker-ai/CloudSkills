---
name: github-pr-review-checklist
enabled: false
description: Post structured review checklists as comments on GitHub pull requests. Summarizes code review findings with categorized checks, severity indicators, and actionable feedback.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: repo_owner
    label: "Repository Owner"
    required: true
    placeholder: "e.g., my-org"
  - key: repo_name
    label: "Repository Name"
    required: true
    placeholder: "e.g., my-repo"
features:
  - CODE_REVIEW
---

# GitHub PR Review Checklist

Post a structured review checklist comment on GitHub pull requests.

## Prerequisites

Before executing this skill, ensure:
1. Code review findings are available in context
2. The GitHub connection is configured with repository access
3. The repository `{{config.repo_owner}}/{{config.repo_name}}` exists and is accessible
4. The PR number is known from the review context

## Setup

Source the GitHub helper functions:

```bash
source ./_skills/connections/github/github/scripts/github_helpers.sh
```

## Workflow

### Step 1: Get PR Information

```bash
gh pr view $PR_NUMBER --repo {{config.repo_owner}}/{{config.repo_name}} --json number,title,changedFiles,additions,deletions
```

Retrieve the PR metadata to include in the checklist header.

### Step 2: Analyze Review Findings

From the code review context, categorize each finding into one of these sections:

| Category | Description | Severity Indicator |
|----------|-------------|--------------------|
| Critical Issues | Must fix before merge (security, data loss, crashes) | CRITICAL |
| Bugs & Logic Errors | Incorrect behavior, edge cases, race conditions | HIGH |
| Performance | Inefficiencies, N+1 queries, memory leaks | MEDIUM |
| Code Quality | Naming, structure, duplication, readability | LOW |
| Security | Input validation, auth checks, secrets exposure | Varies |
| Testing | Missing tests, inadequate coverage, flaky tests | MEDIUM |
| Documentation | Missing docs, outdated comments, unclear APIs | LOW |
| Suggestions | Optional improvements, alternative approaches | INFO |

### Step 3: Build the Checklist Comment

Format the review checklist using GitHub-flavored Markdown:

```markdown
## Code Review Checklist

**PR:** #{pr_number} - {pr_title}
**Files Changed:** {changed_files} | **+{additions}** / **-{deletions}**
**Reviewed by:** CloudThinker Code Review

---

### Critical Issues
> These must be resolved before merging.

- [ ] **{file_path}:{line}** - {finding_title}
  {brief description of the issue and why it is critical}

- [ ] **{file_path}:{line}** - {finding_title}
  {brief description}

---

### Bugs & Logic Errors

- [ ] **{file_path}:{line}** - {finding_title}
  {description of the bug or logic error}

---

### Performance

- [ ] **{file_path}:{line}** - {finding_title}
  {description of the performance concern}

---

### Security

- [ ] **{file_path}:{line}** - {finding_title}
  {description of the security concern}

---

### Code Quality

- [ ] **{file_path}:{line}** - {finding_title}
  {description of the quality improvement}

---

### Testing

- [ ] **{file_path}:{line}** - {finding_title}
  {description of testing gaps}

---

### Suggestions
> Optional improvements that are not blockers.

- [ ] **{file_path}:{line}** - {finding_title}
  {description of the suggestion}

---

### Summary

| Category | Count |
|----------|-------|
| Critical | {n} |
| Bugs | {n} |
| Performance | {n} |
| Security | {n} |
| Code Quality | {n} |
| Testing | {n} |
| Suggestions | {n} |
| **Total** | **{total}** |

**Verdict:** {APPROVE / REQUEST_CHANGES / COMMENT}
{1-2 sentence overall assessment}
```

### Step 4: Post the Checklist Comment

```bash
github_create_pr_discussion {{config.repo_owner}} {{config.repo_name}} $PR_NUMBER \
  '${formatted_checklist}'
```

### Step 5: Post Inline Comments for Critical Findings

For critical and high-severity findings, also post inline comments on the specific lines:

```bash
github_create_pr_comment {{config.repo_owner}} {{config.repo_name}} $PR_NUMBER \
  "${file_path}" ${line_number} '${inline_comment}' "RIGHT"
```

This provides both a high-level checklist and targeted inline feedback.

## Checklist Rules

### Section Inclusion
- Only include sections that have findings (omit empty sections)
- Always include the Summary table
- Critical Issues section always appears first when present
- Suggestions section always appears last

### Finding Format
Each checklist item follows this structure:
- `- [ ]` checkbox for tracking resolution
- `**file:line**` bold file reference for navigation
- `{title}` concise finding title on the same line
- Indented description on the next line (1-2 sentences max)

### Verdict Logic
| Condition | Verdict |
|-----------|---------|
| Any Critical findings | REQUEST_CHANGES |
| No Critical but has Bugs or Security findings | REQUEST_CHANGES |
| Only Performance, Quality, or Suggestions | COMMENT |
| No findings | APPROVE |

## Output

After posting the checklist, report:
1. Confirmation that the checklist was posted on PR #{pr_number}
2. Total number of findings by category
3. The verdict (APPROVE / REQUEST_CHANGES / COMMENT)
4. Number of inline comments posted
5. Link to the PR

## Error Handling

| Scenario | Action |
|----------|--------|
| Repository not found | Report error with `{{config.repo_owner}}/{{config.repo_name}}` |
| PR not found | Report error with the PR number |
| No permission to comment | Report required GitHub permissions |
| Comment too long | Split into multiple comments (checklist + details) |
| No findings | Post a brief approval comment instead of empty checklist |

## Guidelines

- Keep finding descriptions concise (1-2 sentences per item)
- Use file:line references that GitHub auto-links to the diff
- Group related findings under the most relevant category
- Do not duplicate findings across categories
- Use checkboxes (`- [ ]`) so PR authors can track their fixes
- Include the verdict clearly at the bottom
- Post inline comments only for Critical and High severity items to avoid noise

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

