---
name: managing-supabase
description: Supabase project management - databases, Edge Functions, branches, and migrations. Use when working with Supabase infrastructure, executing SQL, or deploying serverless functions.
connection_type: supabase
preload: false
---

# Managing Supabase

Tools for comprehensive Supabase project management via the official MCP server.

**Important:** All tools require a parameter object. Pass `{}` for tools with no required parameters.

## Tools

### Account & Projects

| Tool | Description |
|------|-------------|
| `list_organizations({})` | List all organizations |
| `get_organization({ id })` | Get organization details |
| `list_projects({})` | List all projects in organization |
| `get_project({ id })` | Get project details |
| `create_project({ name, organization_id, region })` | Create new project |
| `pause_project({ id })` | Pause project to save costs |
| `restore_project({ id })` | Restore paused project |
| `get_cost({})` | Get current billing costs |

### Database

| Tool | Description |
|------|-------------|
| `list_tables({ project_id })` | List all tables in database |
| `list_extensions({ project_id })` | List installed PostgreSQL extensions |
| `list_migrations({ project_id })` | List database migrations |
| `apply_migration({ project_id, sql })` | Apply a new migration |
| `execute_sql({ project_id, query })` | Execute SQL query |

### Development

| Tool | Description |
|------|-------------|
| `get_project_url({ project_id })` | Get project API URL |
| `get_publishable_keys({ project_id })` | Get anon/service keys |
| `generate_typescript_types({ project_id })` | Generate TypeScript types from schema |

### Edge Functions

| Tool | Description |
|------|-------------|
| `list_edge_functions({ project_id })` | List all Edge Functions |
| `get_edge_function({ project_id, function_slug })` | Get function details |
| `deploy_edge_function({ project_id, name, code })` | Deploy Edge Function |

### Branching

| Tool | Description |
|------|-------------|
| `list_branches({ project_id })` | List all branches |
| `create_branch({ project_id, name })` | Create database branch |
| `delete_branch({ project_id, branch_id })` | Delete branch |
| `merge_branch({ project_id, branch_id })` | Merge branch to production |
| `reset_branch({ project_id, branch_id })` | Reset branch |
| `rebase_branch({ project_id, branch_id })` | Rebase branch |

### Debugging

| Tool | Description |
|------|-------------|
| `get_logs({ project_id })` | Retrieve project logs |
| `get_advisors({ project_id })` | Get performance advisors |

### Storage

| Tool | Description |
|------|-------------|
| `list_storage_buckets({ project_id })` | List storage buckets |
| `get_storage_config({ project_id })` | Get storage configuration |
| `update_storage_config({ project_id, config })` | Update storage config |

### Knowledge Base

| Tool | Description |
|------|-------------|
| `search_docs({ query })` | Search Supabase documentation |

## Examples

### List Projects and Tables

```typescript
import { list_projects, list_tables } from '@connections/supabase';

const projects = await list_projects({});

const tables = await list_tables({ project_id: 'your-project-id' });
```

### Execute SQL Query

```typescript
import { execute_sql } from '@connections/supabase';

const result = await execute_sql({
  project_id: 'your-project-id',
  query: 'SELECT * FROM users WHERE created_at > now() - interval \'7 days\''
});
```

### Branch-Based Development

```typescript
import { create_branch, apply_migration, merge_branch } from '@connections/supabase';

// Create feature branch
await create_branch({
  project_id: 'your-project-id',
  name: 'feature/auth'
});

// Apply migration to branch
await apply_migration({
  project_id: 'your-project-id',
  sql: 'ALTER TABLE users ADD COLUMN role TEXT;'
});

// Merge when ready
await merge_branch({
  project_id: 'your-project-id',
  branch_id: 'branch-id'
});
```

### Deploy Edge Function

```typescript
import { deploy_edge_function } from '@connections/supabase';

await deploy_edge_function({
  project_id: 'your-project-id',
  name: 'hello-world',
  code: 'Deno.serve(() => new Response("Hello!"))'
});
```

## Security Best Practices

| Practice | Description |
|----------|-------------|
| Use dev projects | Don't connect MCP to production databases |
| Read-only mode | Enable for real data access scenarios |
| Project scoping | Limit access to specific projects only |
| Review queries | Always review SQL before execution |

## Common Errors

| Error | Solution |
|-------|----------|
| Authentication failed | Re-authenticate via OAuth flow |
| Project not found | Verify project ID and permissions |
| Migration failed | Check SQL syntax and dependencies |
| Rate limited | Reduce request frequency |
| 422 | Pass `{}` for tools with no required params |

## Output Format

Present results as a structured report:
```
Managing Supabase Report
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

