---
name: gitlab-issue-from-review
enabled: false
description: Create GitLab issues from code review findings. Converts review comments into trackable issues with severity labels, code references, and remediation guidance.
required_connections:
  - prefix: gitlab
    label: "GitLab"
config_fields:
  - key: project_path
    label: "Project Path"
    required: true
    placeholder: "e.g., team/repo-name"
features:
  - CODE_REVIEW
---

# GitLab Issue from Code Review

Create GitLab issues from code review findings for tracking and remediation.

## Prerequisites

Before executing this skill, ensure:
1. Code review findings are available in context
2. The GitLab connection is configured with API access
3. The target project `{{config.project_path}}` exists and is accessible

## Setup

Source the GitLab helper functions:

```bash
source ./_skills/connections/gitlab/gitlab/scripts/gitlab_helpers.sh
PROJ=$(gitlab_project_id "{{config.project_path}}")
```

## Workflow

### Step 1: Get Project ID

```bash
PROJ=$(gitlab_project_id "{{config.project_path}}")
```

If the project is not found, report the error with the configured path.

### Step 2: Extract Review Findings

From the code review context, extract each finding:

| Field | Source | Required |
|-------|--------|----------|
| Title | Finding summary | Yes |
| Severity | Review severity classification | Yes |
| Category | Finding type (security, performance, bug, style) | Yes |
| File path | Source file where issue was found | Yes |
| Line number(s) | Specific lines referenced | Yes |
| Description | Detailed explanation of the issue | Yes |
| Suggestion | Recommended fix or approach | If available |
| MR reference | Merge request where finding originated | If available |

### Step 3: Classify and Label Each Finding

Map review findings to GitLab labels:

**Severity labels:**
| Review Severity | GitLab Label |
|----------------|--------------|
| Critical | `severity::critical` |
| High | `severity::high` |
| Medium | `severity::medium` |
| Low | `severity::low` |

**Category labels:**
| Category | GitLab Label |
|----------|--------------|
| Security vulnerability | `type::security` |
| Bug / Logic error | `type::bug` |
| Performance issue | `type::performance` |
| Code quality | `type::code-quality` |
| Documentation | `type::documentation` |

### Step 4: Format Issue Description

For each finding, structure the issue description:

```markdown
## Code Review Finding

**Source:** MR !{mr_number} (if available)
**File:** `{file_path}:{line_number}`
**Severity:** {severity}
**Category:** {category}

---

## Description

{detailed explanation of the finding, why it is problematic, and what risk it introduces}

## Code Reference

The issue was identified in [`{file_path}`]({link_to_file}#L{line_number}):

\`\`\`{language}
{code_snippet_with_issue}
\`\`\`

## Suggested Fix

{description of the recommended approach to resolve the issue}

\`\`\`{language}
{suggested_code_fix}
\`\`\`

## Acceptance Criteria

- [ ] The identified issue is resolved
- [ ] Fix does not introduce regressions
- [ ] Relevant tests are added or updated
- [ ] Changes are reviewed and approved
```

### Step 5: Create the GitLab Issue

```bash
gitlab_create_issue $PROJ \
  --title "[Code Review] ${finding_title}" \
  --description "${formatted_description}" \
  --labels "code-review,${severity_label},${category_label}"
```

### Step 6: Link to Source MR (Optional)

If the finding originated from a specific merge request, add a comment on the MR referencing the created issue:

```bash
gitlab_create_mr_discussion $PROJ $MR_IID \
  "Created tracking issue #${issue_iid} for this code review finding: ${finding_title}"
```

## Batch Processing

When multiple findings exist from a single review, process them efficiently:

1. Group findings by severity (Critical first, then High, Medium, Low)
2. Create issues sequentially to avoid rate limits
3. Report a summary table after all issues are created

### Summary Output Format

```
| # | Issue | Severity | Category | File |
|---|-------|----------|----------|------|
| 1 | #123 - SQL injection risk | Critical | Security | src/db/query.py:45 |
| 2 | #124 - Missing null check | High | Bug | src/api/handler.py:112 |
| 3 | #125 - N+1 query pattern | Medium | Performance | src/services/user.py:78 |
```

## Output

After successful creation, report:
1. Number of issues created
2. Summary table with issue numbers, titles, severity, and links
3. Any findings that could not be converted to issues (with reasons)
4. Link back to the source MR if applicable

## Error Handling

| Scenario | Action |
|----------|--------|
| Project not found | Report error with configured path `{{config.project_path}}` |
| Permission denied | Report required GitLab permissions (Reporter role minimum) |
| Label does not exist | Create the issue without the missing label, note it in output |
| Duplicate issue detected | Skip creation, reference the existing issue |
| Rate limit hit | Pause and retry, report partial progress |

## Issue Title Convention

Prefix all issue titles with `[Code Review]` for filtering:
- `[Code Review] SQL injection vulnerability in user query`
- `[Code Review] Missing error handling in payment flow`
- `[Code Review] Unused import increases bundle size`

## Guidelines

- One issue per distinct finding (do not combine unrelated findings)
- Include enough code context for someone unfamiliar with the review to understand the issue
- Link to the specific file and line in the repository
- Set severity labels accurately based on the review finding's impact
- Add acceptance criteria that define what "done" looks like
- Reference the originating MR in the issue description when available

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

