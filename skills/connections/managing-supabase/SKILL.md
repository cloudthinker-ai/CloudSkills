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
