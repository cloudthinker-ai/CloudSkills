---
name: issue-context-review
enabled: true
description: Enrich code reviews with business context by finding the linked issue/ticket from branch name or PR/MR description. Validates that code changes satisfy acceptance criteria and business requirements before reviewing.
required_connections: []
config_fields:
  - key: issue_tracker
    label: "Issue Tracker"
    required: true
    placeholder: "e.g., gitlab, github, jira, bitbucket"
  - key: project_key
    label: "Project Key (Jira) or Project Path (GitLab/GitHub/Bitbucket)"
    required: false
    placeholder: "e.g., OPS or team/repo-name"
features:
  - CODE_REVIEW
---

# Issue-Context Code Review

Enrich code reviews with business context by resolving linked issues/tickets before the review begins. Ensures code changes satisfy acceptance criteria and business requirements — not just code quality.

## Prerequisites

Before executing this skill, ensure:
1. A code review is in progress with access to the PR/MR metadata (branch name, title, description)
2. The relevant issue tracker is accessible via the configured connection
3. The `{{config.issue_tracker}}` connection is available

## Workflow

### Step 1: Extract Issue References

Parse the branch name, PR/MR title, and PR/MR description to find issue references.

**Branch name patterns:**

| Pattern | Example | Extracted Reference |
|---------|---------|---------------------|
| `{type}/{KEY}-{number}-*` | `feature/OPS-1234-add-auth` | `OPS-1234` |
| `{type}/{number}-*` | `fix/1234-null-check` | `#1234` |
| `{type}/#{number}` | `bugfix/#567` | `#567` |
| `{KEY}-{number}` | `PROJ-99` | `PROJ-99` |
| `{type}/{KEY}_{number}_*` | `feature/OPS_1234_add_auth` | `OPS-1234` |

**PR/MR description patterns:**

| Pattern | Example | Tracker |
|---------|---------|---------|
| `{KEY}-{number}` | `Fixes OPS-1234` | Jira |
| `#{number}` | `Closes #456` | GitLab / GitHub |
| `Closes/Fixes/Resolves #{number}` | `Resolves #789` | GitLab / GitHub |
| Jira URL | `https://myorg.atlassian.net/browse/OPS-1234` | Jira |
| GitLab/GitHub issue URL | `https://gitlab.com/team/repo/-/issues/456` | GitLab / GitHub |

**Extraction priority:**
1. PR/MR description (most explicit signal)
2. PR/MR title
3. Branch name

If **no issue reference is found** from any source, **skip this skill entirely** and proceed with the standard code review. Do not fabricate or guess issue references.

### Step 2: Fetch Issue Details

Based on `{{config.issue_tracker}}`, fetch the issue details:

**GitLab:**
```bash
source ./_skills/connections/gitlab/gitlab/scripts/gitlab_helpers.sh
ISSUE=$(gitlab_get_issue "{{config.project_key}}" $ISSUE_NUMBER)
```

**GitHub:**
```bash
source ./_skills/connections/github/github/scripts/github_helpers.sh
ISSUE=$(gh issue view $ISSUE_NUMBER --repo "{{config.project_key}}" --json title,body,labels,state,assignees)
```

**Jira:**
```bash
source ./_skills/connections/atlassian/jira/scripts/jira_helpers.sh
ISSUE=$(jira_get_issue "{{config.project_key}}-${ISSUE_NUMBER}")
```

**Bitbucket:**
```bash
source ./_skills/connections/bitbucket/bitbucket/scripts/bitbucket_helpers.sh
ISSUE=$(bitbucket_get_issue "{{config.project_key}}" $ISSUE_NUMBER)
```

Extract from the fetched issue:

| Field | Required | Notes |
|-------|----------|-------|
| Title | Yes | Issue summary |
| Description / Body | Yes | Full requirement description |
| Acceptance Criteria | If present | Checklist or bullet points defining "done" |
| Labels / Type | If present | Bug, Feature, Story, Task |
| Priority | If present | Helps weight review severity |
| Status | If present | Verify issue is not already closed/done |

### Step 3: Build Business Context Summary

Compile a structured context block for the code review agent:

```markdown
## Linked Issue Context

**Issue:** {tracker_prefix}{issue_number} — {issue_title}
**Tracker:** {{config.issue_tracker}}
**Status:** {issue_status}
**Type:** {issue_type}

### Requirements
{issue_description_or_body}

### Acceptance Criteria
{extracted_acceptance_criteria_as_checklist}
```

### Step 4: Inject Context into Review

Provide the business context to the code review with these instructions:

1. **Requirements coverage** — Verify that the code changes address the requirements described in the linked issue
2. **Acceptance criteria** — Check each acceptance criterion against the diff. Flag any that appear unmet
3. **Scope alignment** — Flag changes that appear unrelated to the issue (scope creep) or requirements that are not addressed by any changed file
4. **Edge cases from requirements** — If the issue describes specific scenarios or constraints, verify the code handles them

### Step 5: Append Findings to Review

Add a dedicated section to the review output:

```markdown
### Business Logic Validation

**Linked Issue:** {tracker_prefix}{issue_number} — {issue_title}

#### Acceptance Criteria Coverage
- [x] {criterion_1} — Addressed in `{file}:{line}`
- [ ] {criterion_2} — **Not addressed in this PR/MR**
- [x] {criterion_3} — Addressed in `{file}:{line}`

#### Observations
- {any scope misalignment, missing requirements, or partial implementations}
```

## Skip Conditions

**Do NOT execute this skill when:**
- No issue reference is found in the branch name, PR/MR title, or PR/MR description
- The referenced issue cannot be fetched (tracker unreachable, permission denied, issue not found)
- The issue is in a terminal state (Closed, Done, Cancelled) and appears stale

When skipping, silently proceed with standard code review. Do not post warnings about missing issue references.

## Output

When this skill executes successfully, the code review output includes:
1. The linked issue reference and title
2. Acceptance criteria coverage checklist (met vs. unmet)
3. Scope alignment observations
4. Any business logic concerns found during review

## Error Handling

| Scenario | Action |
|----------|--------|
| No issue reference found | Skip silently, proceed with standard review |
| Issue not found in tracker | Skip silently, proceed with standard review |
| Tracker connection unavailable | Skip silently, log warning, proceed with standard review |
| Issue found but has no acceptance criteria | Include issue title and description as context, note absence of formal criteria |
| Multiple issue references found | Use the first valid reference; mention others in the review context |

## Branch Name Parsing Rules

Apply patterns in this order (first match wins):

1. Jira-style key: `/([A-Z][A-Z0-9_]+-\d+)/` → e.g., `OPS-1234`
2. Hash-prefixed number: `/#(\d+)/` or `/\b#(\d+)\b/` → e.g., `#456`
3. Bare number after slash: `/\/(\d+)[-_]/` → e.g., `/1234-fix-bug`
4. Bare number in description: `/(?:close[sd]?|fix(?:e[sd])?|resolve[sd]?)\s+#?(\d+)/i`

## Guidelines

- Never block a review because an issue reference is missing — this is an enrichment, not a gate
- Keep the business context section concise — summarize long issue descriptions
- Do not repeat the entire issue body verbatim; extract the actionable requirements
- When acceptance criteria are informal (prose instead of checklist), convert them to checkable items
- If the issue has subtasks or child tickets, only reference the directly linked issue
