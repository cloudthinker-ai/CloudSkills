---
name: tracking-confluence
description: Confluence page management, space administration, and content collaboration. Use when working with Confluence pages, spaces, comments, or Atlassian connections.
connection_type: atlassian
preload: false
---

# Tracking Confluence

## Discovery

<critical>
**If no `[cached_from_skill:tracking-confluence:discover]` context exists, run discovery first:**
```bash
bun run ./_skills/connections/confluence/tracking-confluence/scripts/discover.ts
bun run ./_skills/connections/confluence/tracking-confluence/scripts/discover.ts --max-spaces 25
```
Output is auto-cached.
</critical>

**What discovery provides:**
- `resources`: List of accessible Atlassian sites with `cloudId`, `url`, `name`
- `currentUser`: Your `accountId`, `name`, and `email` (for CQL queries like `creator = currentUser()`)
- `spaces`: Available spaces with `id`, `key`, `name`, `type` (global/personal); includes `byType` counts
- `recentPages`: Last 10 modified pages with `title`, `spaceKey`, `type`, `modified`
- `hints`: Pagination model info (cursor-based via `_links.next`)

**Why run discovery:**
- Get `cloudId` required for all Confluence API calls
- Know available spaces before creating pages
- Get your `accountId` for CQL queries
- Understand pagination model (cursor-based, not offset-based)

## Tools

**Pages:** `getConfluencePage(cloudId, pageId, expand?)`, `createConfluencePage(cloudId, spaceId, title, body, contentFormat?)`, `updateConfluencePage(cloudId, pageId, title, body, contentFormat?, versionMessage?)`, `getConfluencePageDescendants(cloudId, pageId)`

**Spaces:** `getConfluenceSpaces(cloudId, limit?)`, `getPagesInConfluenceSpace(cloudId, spaceId)`

**Comments:** `getConfluencePageFooterComments(cloudId, pageId)`, `getConfluencePageInlineComments(cloudId, pageId)`, `createConfluenceFooterComment(cloudId, pageId, body)`

**Search:** `searchConfluenceUsingCql(cloudId, cql, maxResults?)`

## Quick Patterns

**Get cloudId (always first):**
```typescript
const resources = await getAccessibleAtlassianResources();
const cloudId = resources[0].id;
const siteUrl = resources[0].url;
```

**Create page:**
```typescript
const spaces = await getConfluenceSpaces({ cloudId, limit: 10 });
const spaceId = spaces.results[0].id;
const result = await createConfluencePage({ cloudId, spaceId: spaceId.toString(), title: 'Page Title', body: '# Markdown', contentFormat: 'markdown' });
const url = `${siteUrl}/wiki/spaces/${spaceId}/pages/${result.id}`;
```

**Search pages:**
```typescript
const results = await searchConfluenceUsingCql({ cloudId, cql: 'space = "DOCS" AND type = page AND title ~ "API"', maxResults: 10 });
results.results.forEach(page => console.log(page.title, page.url));
```

**Update page:**
```typescript
const page = await getConfluencePage({ cloudId, pageId: '12345' });
await updateConfluencePage({ cloudId, pageId: '12345', title: 'Updated', body: '# New content', contentFormat: 'markdown' });
```

## Pagination

<critical>
**Confluence uses cursor-based pagination via `_links.next`.** The `start`, `limit`, and `size` fields may be `undefined` — do not rely on them for pagination logic.
</critical>

**Pattern:**
```typescript
let allResults = [];
let response = await getConfluenceSpaces({ cloudId, limit: 25 });
allResults.push(...response.results);
while (response._links?.next) {
  // _links.next contains the full path for the next page
  // Re-call with updated parameters from the next link
  response = await getConfluenceSpaces({ cloudId, limit: 25 /* next cursor handled internally */ });
  allResults.push(...response.results);
}
```

## Workflows

**Create page:** `getAccessibleAtlassianResources()` → `getConfluenceSpaces({cloudId})` → `createConfluencePage({cloudId, spaceId, title, body})` → return `${siteUrl}/wiki/spaces/${spaceId}/pages/${result.id}`

**Find pages:** `getAccessibleAtlassianResources()` → `searchConfluenceUsingCql({cloudId, cql: 'type = page AND title ~ "topic"'})`

**Update page:** `getConfluencePage({cloudId, pageId})` → `updateConfluencePage({cloudId, pageId, title, body, contentFormat: 'markdown'})`

## CQL Reference

**Operators:** `=`, `!=`, `~` (contains), `IN`, `>=`, `<=`

**Fields:** `space`, `type`, `title`, `text`, `created`, `modified`, `creator`, `contributor`, `label`

<critical>
**Note:** `status` field is NOT supported in CQL. Use `type` instead.
</critical>

**Examples:** `space = "DOCS" AND type = page`, `title ~ "API"`, `created >= -7d ORDER BY created DESC`, `label = "important"`, `creator = currentUser()`

## CQL Best Practices

<critical>
**Always double-quote string values** to avoid reserved word collisions:
- `space = "IN"` — safe
- `space = IN` — CQL parse error
Reserved words: AND, OR, NOT, IN, IS, NULL, EMPTY, ORDER, BY, TO, FROM, etc.
</critical>

## Content Formats

| Format | `contentFormat` value | When to use | Notes |
|--------|----------------------|-------------|-------|
| **Markdown** | `markdown` | Default for new pages | Simplest; auto-converted by Confluence |
| **Storage** | `storage` | Precise HTML control | Uses `<ac:*>` macros for rich content |
| **Wiki** | `wiki` | Legacy content | Rarely needed for new pages |

**Recommendation:** Use `markdown` as the default `contentFormat`. Only use `storage` when you need Confluence-specific macros (code blocks, panels, etc.).

## SDK Utilities

Import from `@connections/_utils` (NOT from `format` module):

```typescript
import { format, normalize, countBy, groupBy, parseArgs, parallel } from "@connections/_utils";
```

| Utility | Purpose |
|---------|---------|
| `format(data)` | Pretty-print JSON output for discovery scripts |
| `normalize(arr, key)` | Convert array to `Record<string, T>` keyed by field |
| `countBy(arr, fn)` | Count items by category (e.g., spaces by type) |
| `groupBy(arr, fn)` | Group items by category |
| `parseArgs()` | Parse CLI flags (`--max-spaces 25`) |
| `parallel(items, fn, opts)` | Execute async operations in parallel with fallback |

## Defensive Coding

<critical>
**Confluence API responses may omit fields that TypeScript types mark as present.** Always use optional chaining when accessing nested properties:

```typescript
// ❌ WRONG — crashes if space.links is undefined
const webUrl = space.links.webui;

// ✅ CORRECT — safe access with fallback
const webUrl = space.links?.webui ?? "N/A";
```

Fields commonly missing at runtime: `space.links`, `space.homepage`, `page.version`, `result._links`, `start`, `limit`, `size`.
</critical>

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `returned unexpected response: null` | OAuth token expired | Re-authenticate |
| `CQL parse error` | Unquoted reserved word | Double-quote string values |
| `start/limit/size undefined` | Normal — pagination fields are optional | Use `_links.next` for pagination |
| `TypeError: undefined is not an object` | Accessing nested property on missing field (e.g., `space.links.webui`) | Use optional chaining: `space.links?.webui` |
| `UNAUTHENTICATED` | Token expired mid-session | Re-run discovery |
| `Page does not exist` | Wrong cloudId or pageId | Verify cloudId from discovery |
| Discovery returns 0 spaces | Missing OAuth scopes | Ensure `read:confluence-space.summary` granted |

## Connection Resilience

- Always use `cloudId` from discovery output, never hardcode
- If discovery fails with auth errors, re-authenticate the Atlassian connection and re-run discovery
- For multi-site workspaces, discovery returns all accessible sites in `resources[]` — pick the correct `cloudId` for the target site
