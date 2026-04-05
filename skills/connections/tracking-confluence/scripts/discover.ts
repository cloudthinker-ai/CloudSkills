#!/usr/bin/env bun
/**
 * Discovery script for tracking-confluence
 * Discovers accessible Atlassian sites, current user, spaces, and recent pages.
 */

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
const config = {
  token: process.env.ATLASSIAN_TOKEN || process.env.CONFLUENCE_TOKEN || '',
  email: process.env.ATLASSIAN_EMAIL || process.env.CONFLUENCE_EMAIL || '',
  baseUrl: (process.env.ATLASSIAN_URL || process.env.CONFLUENCE_URL || '').replace(/\/+$/, ''),
};

// For OAuth-based flows the token might be an OAuth access token
const oauthToken = process.env.ATLASSIAN_OAUTH_TOKEN || '';

if (!oauthToken && (!config.token || !config.email)) {
  console.error(
    'Missing required environment variables:\n' +
    '  Option 1 (API token): ATLASSIAN_EMAIL + ATLASSIAN_TOKEN\n' +
    '  Option 2 (OAuth):     ATLASSIAN_OAUTH_TOKEN',
  );
  process.exit(1);
}

// ---------------------------------------------------------------------------
// CLI args
// ---------------------------------------------------------------------------
const args = process.argv.slice(2);
function flag(name: string, fallback: number): number {
  const idx = args.indexOf(`--${name}`);
  return idx !== -1 && args[idx + 1] ? Number(args[idx + 1]) : fallback;
}

const MAX_SPACES = flag('max-spaces', 25);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function authHeaders(): Record<string, string> {
  if (oauthToken) {
    return { Authorization: `Bearer ${oauthToken}`, Accept: 'application/json' };
  }
  const creds = Buffer.from(`${config.email}:${config.token}`).toString('base64');
  return { Authorization: `Basic ${creds}`, Accept: 'application/json' };
}

async function apiAtlassian<T = unknown>(url: string): Promise<T> {
  const res = await fetch(url, { headers: authHeaders() });
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    throw new Error(`GET ${url} → ${res.status} ${res.statusText}: ${body.slice(0, 200)}`);
  }
  return res.json() as Promise<T>;
}

// ---------------------------------------------------------------------------
// Discovery
// ---------------------------------------------------------------------------
async function discover() {
  const results: Record<string, unknown> = {};

  // --- Accessible resources (sites) ---
  let cloudId = '';
  let siteUrl = '';
  try {
    const resources = await apiAtlassian<
      Array<{ id: string; url: string; name: string; scopes: string[] }>
    >('https://api.atlassian.com/oauth/token/accessible-resources');

    results.resources = resources.map((r) => ({
      cloudId: r.id,
      url: r.url,
      name: r.name,
    }));
    if (resources.length > 0) {
      cloudId = resources[0].id;
      siteUrl = resources[0].url;
    }
  } catch (e: any) {
    // Fallback: use configured base URL
    if (config.baseUrl) {
      cloudId = '';
      siteUrl = config.baseUrl;
      results.resources = { note: 'Using configured base URL', url: config.baseUrl };
    } else {
      results.resources = { error: e.message };
    }
  }

  const apiBase = cloudId
    ? `https://api.atlassian.com/ex/confluence/${cloudId}`
    : `${siteUrl}/wiki`;

  // --- Current user ---
  try {
    const user = await apiAtlassian<{
      accountId?: string;
      displayName?: string;
      emailAddress?: string;
    }>(`${apiBase}/rest/api/user/current`);

    results.currentUser = {
      accountId: user.accountId ?? null,
      name: user.displayName ?? null,
      email: user.emailAddress ?? null,
    };
  } catch (e: any) {
    // Try the wiki/rest path
    try {
      const user = await apiAtlassian<Record<string, unknown>>(
        `${apiBase}/wiki/rest/api/user/current`,
      );
      results.currentUser = user;
    } catch {
      results.currentUser = { error: e.message };
    }
  }

  // --- Spaces ---
  try {
    const spaces = await apiAtlassian<{
      results: Array<{
        id: string;
        key: string;
        name: string;
        type: string;
        status?: string;
        links?: { webui?: string };
      }>;
      _links?: { next?: string };
    }>(`${apiBase}/api/v2/spaces?limit=${MAX_SPACES}`);

    const spaceList = (spaces.results ?? []).map((s) => ({
      id: s.id,
      key: s.key,
      name: s.name,
      type: s.type,
    }));

    const byType: Record<string, number> = {};
    for (const s of spaceList) {
      byType[s.type] = (byType[s.type] ?? 0) + 1;
    }

    results.spaces = {
      total: spaceList.length,
      hasMore: !!spaces._links?.next,
      byType,
      items: spaceList,
    };
  } catch (e: any) {
    // Fallback to v1 API
    try {
      const spaces = await apiAtlassian<{
        results: Array<{ id: number; key: string; name: string; type: string }>;
        size: number;
      }>(`${apiBase}/rest/api/space?limit=${MAX_SPACES}`);

      const spaceList = (spaces.results ?? []).map((s) => ({
        id: String(s.id),
        key: s.key,
        name: s.name,
        type: s.type,
      }));

      const byType: Record<string, number> = {};
      for (const s of spaceList) {
        byType[s.type] = (byType[s.type] ?? 0) + 1;
      }

      results.spaces = { total: spaceList.length, byType, items: spaceList };
    } catch (e2: any) {
      results.spaces = { error: e2.message };
    }
  }

  // --- Recent pages ---
  try {
    const pages = await apiAtlassian<{
      results: Array<{
        id: string;
        title: string;
        spaceId?: string;
        status?: string;
        version?: { createdAt?: string };
        _links?: { webui?: string };
      }>;
    }>(`${apiBase}/api/v2/pages?sort=-modified-date&limit=10`);

    results.recentPages = (pages.results ?? []).map((p) => ({
      id: p.id,
      title: p.title,
      spaceId: p.spaceId ?? null,
      status: p.status ?? null,
      modified: p.version?.createdAt ?? null,
    }));
  } catch (e: any) {
    // Fallback to CQL search
    try {
      const cqlResult = await apiAtlassian<{
        results: Array<{ id: string; title: string; type: string; space?: { key: string } }>;
      }>(
        `${apiBase}/rest/api/content/search?cql=${encodeURIComponent('type = page ORDER BY lastmodified DESC')}&limit=10`,
      );
      results.recentPages = (cqlResult.results ?? []).map((p) => ({
        id: p.id,
        title: p.title,
        type: p.type,
        spaceKey: p.space?.key ?? null,
      }));
    } catch {
      results.recentPages = { error: e.message };
    }
  }

  // --- Hints ---
  results.hints = {
    pagination: 'Confluence uses cursor-based pagination via _links.next. Do not rely on start/limit/size fields.',
    cloudId: cloudId || 'Not available — using direct URL auth',
    siteUrl: siteUrl || config.baseUrl,
  };

  console.log(JSON.stringify(results, null, 2));
}

discover().catch((err) => {
  console.error('Discovery failed:', err.message);
  process.exit(1);
});
