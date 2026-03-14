---
name: tracking-jira
description: Jira issue tracking, project management, and workflow automation. Use when working with Jira issues, projects, sprints, or Atlassian connections.
connection_type: atlassian
preload: false
---

# Tracking Jira

## Discovery

<critical>
**If no `[cached_from_skill:tracking-jira:discover]` context exists, run discovery first:**
```bash
bun run ./_skills/connections/jira/tracking-jira/scripts/discover.ts
bun run ./_skills/connections/jira/tracking-jira/scripts/discover.ts --max-projects 50
```
Output is auto-cached.
</critical>

**What discovery provides:**
- `resources`: List of accessible Atlassian sites with `cloudId`, `url`, `name`
- `currentUser`: Your `accountId`, `name`, and `email` (for JQL queries like `assignee = currentUser()`)
- `projects`: Available projects with `key`, `name`, `projectTypeKey`, and `issueTypes` (id, name, subtask); includes `unassignedCount` (projects without a lead)
- `hints`: API limits (`maxResults: 50`) and pagination requirements

**Why run discovery:**
- Get `cloudId` required for all Jira API calls
- Know available projects and their issue types before creating issues
- Get your `accountId` for assignment operations
- Understand pagination needs (if `total > maxProjects`)

## Tools

**Issues:** `getJiraIssue(cloudId, issueIdOrKey)`, `createJiraIssue(cloudId, projectKey, issueTypeName, summary, ...)`, `editJiraIssue(cloudId, issueIdOrKey, fields)`, `searchJiraIssuesUsingJql(cloudId, jql, maxResults?, startAt?)`

**Operations:** `addCommentToJiraIssue(cloudId, issueIdOrKey, commentBody)`, `transitionJiraIssue(cloudId, issueIdOrKey, transition)`, `addWorklogToJiraIssue(cloudId, issueIdOrKey, timeSpent)`

**Metadata:** `getTransitionsForJiraIssue(cloudId, issueIdOrKey)`, `getJiraIssueRemoteIssueLinks(cloudId, issueIdOrKey)`

**Projects:** `getVisibleJiraProjects(cloudId, searchString?, maxResults?, startAt?)`, `getJiraProjectIssueTypesMetadata(cloudId, projectIdOrKey)`, `getJiraIssueTypeMetaWithFields(cloudId, projectIdOrKey, issueTypeId)`

**Users:** `lookupJiraAccountId(cloudId, searchString)`, `atlassianUserInfo()`

**Discovery:** `getAccessibleAtlassianResources()`

## Quick Patterns

**Create issue:**
```typescript
const metadata = await getJiraProjectIssueTypesMetadata({ cloudId, projectIdOrKey: 'PROJ' });
const result = await createJiraIssue({ cloudId, projectKey: 'PROJ', issueTypeName: 'Task', summary: 'Title' });
const url = `${siteUrl}/browse/${result.key}`;
```

**Search issues:**
```typescript
const response = await searchJiraIssuesUsingJql({ cloudId, jql: 'project = PROJ AND status = "In Progress"', maxResults: 50 });
const issues = response.issues; // JiraSearchResult: { issues, total, startAt, maxResults }
```

**Transition issue:**
```typescript
const { transitions } = await getTransitionsForJiraIssue({ cloudId, issueIdOrKey: 'PROJ-123' });
await transitionJiraIssue({ cloudId, issueIdOrKey: 'PROJ-123', transition: { id: transitions[0].id } });
```

**Lookup user and assign issue:**
```typescript
const result = await lookupJiraAccountId({ cloudId, searchString: 'john.doe@example.com' });
const users = result.users.users; // Note: nested structure - result.users.users, not result.users
const accountId = users[0]?.accountId;
await editJiraIssue({ cloudId, issueIdOrKey: 'PROJ-123', fields: { assignee: { accountId } } });
```

<critical>
**RATE LIMITS:** `maxResults` max is **50** for `getVisibleJiraProjects()` and `searchJiraIssuesUsingJql()`. Use `startAt` for pagination:
```typescript
let startAt = 0, allIssues = [];
while (true) {
  const resp = await searchJiraIssuesUsingJql({ cloudId, jql, maxResults: 50, startAt });
  allIssues.push(...resp.issues);
  if (allIssues.length >= resp.total) break;
  startAt += 50;
}
```
</critical>

## Workflows

**Create issue:** `getJiraProjectIssueTypesMetadata({cloudId, projectIdOrKey})` → `createJiraIssue({cloudId, projectKey, issueTypeName, summary})` → return `${siteUrl}/browse/${result.key}`

**Find my issues:** `searchJiraIssuesUsingJql({cloudId, jql: 'assignee = currentUser() AND status != Done'})`

**Transition issue:** `getTransitionsForJiraIssue({cloudId, issueIdOrKey})` → find target ID → `transitionJiraIssue({cloudId, issueIdOrKey, transition: {id}})`

## JQL Reference

**Operators:** `=`, `!=`, `>`, `<`, `>=`, `<=`, `IN`, `NOT IN`, `~` (contains), `IS EMPTY`, `IS NOT EMPTY`

**Functions:** `currentUser()`, `openSprints()`, `membersOf("group")`, `startOfWeek()`, `endOfMonth()`

**Time:** `created >= -7d`, `updated >= startOfWeek()`, `duedate <= endOfMonth()`

**Examples:** `status = "In Progress"`, `status IN ("To Do", "In Progress")`, `summary ~ "bug"`, `assignee IS EMPTY`, `sprint in openSprints()`

## JQL Best Practices

<critical>
**Always quote project keys** to avoid reserved word collisions:
- `project = "IN"` — safe
- `project = IN` — JQL parse error
Reserved words: AND, OR, NOT, IN, IS, NULL, EMPTY, ORDER, BY, TO, FROM, etc.
</critical>

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `returned unexpected response: null` | OAuth token expired | Re-authenticate |
| `JQL parse error` | Reserved word project key | Quote the key |
| `Field 'X' does not exist` | Invalid JQL field | Use standard fields |
| `UNAUTHENTICATED` | Token expired mid-session | Re-run discovery |
| `Issue does not exist` | Wrong cloudId or key typo | Verify cloudId from discovery |
| Discovery returns 0 projects | Missing OAuth scopes | Ensure `read:jira-work` granted |

## Connection Resilience

- Always use `cloudId` from discovery output, never hardcode
- If discovery fails with auth errors, re-authenticate the Atlassian connection and re-run discovery
- For multi-site workspaces, discovery returns all accessible sites in `resources[]` — pick the correct `cloudId` for the target site
