#!/usr/bin/env bun
/**
 * Discovery script for tracking-jira
 * Discovers accessible Atlassian sites, current user, projects with issue types,
 * and pagination hints.
 */

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
const config = {
  token: process.env.ATLASSIAN_TOKEN || process.env.JIRA_TOKEN || '',
  email: process.env.ATLASSIAN_EMAIL || process.env.JIRA_EMAIL || '',
  baseUrl: (process.env.ATLASSIAN_URL || process.env.JIRA_URL || '').replace(/\/+$/, ''),
};

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

const MAX_PROJECTS = flag('max-projects', 50);

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
    if (config.baseUrl) {
      cloudId = '';
      siteUrl = config.baseUrl;
      results.resources = { note: 'Using configured base URL', url: config.baseUrl };
    } else {
      results.resources = { error: e.message };
    }
  }

  const apiBase = cloudId
    ? `https://api.atlassian.com/ex/jira/${cloudId}`
    : siteUrl;

  // --- Current user ---
  try {
    const user = await apiAtlassian<{
      accountId?: string;
      displayName?: string;
      emailAddress?: string;
    }>(`${apiBase}/rest/api/3/myself`);

    results.currentUser = {
      accountId: user.accountId ?? null,
      name: user.displayName ?? null,
      email: user.emailAddress ?? null,
    };
  } catch (e: any) {
    try {
      const user = await apiAtlassian<Record<string, unknown>>(`${apiBase}/rest/api/2/myself`);
      results.currentUser = user;
    } catch {
      results.currentUser = { error: e.message };
    }
  }

  // --- Projects with issue types ---
  try {
    const projects = await apiAtlassian<
      Array<{
        id: string;
        key: string;
        name: string;
        projectTypeKey: string;
        lead?: { displayName?: string; accountId?: string };
        issueTypes?: Array<{ id: string; name: string; subtask: boolean }>;
      }>
    >(`${apiBase}/rest/api/3/project/search?maxResults=${MAX_PROJECTS}&expand=issueTypes`);

    // Handle both array and paginated response
    const projectList = Array.isArray(projects)
      ? projects
      : (projects as any).values ?? (projects as any).projects ?? [];

    let unassignedCount = 0;
    const mapped = projectList.slice(0, MAX_PROJECTS).map((p: any) => {
      if (!p.lead) unassignedCount++;
      return {
        key: p.key,
        name: p.name,
        projectTypeKey: p.projectTypeKey ?? null,
        lead: p.lead?.displayName ?? null,
        issueTypes: (p.issueTypes ?? []).map((it: any) => ({
          id: it.id,
          name: it.name,
          subtask: it.subtask ?? false,
        })),
      };
    });

    results.projects = {
      total: mapped.length,
      unassignedCount,
      items: mapped,
    };
  } catch (e: any) {
    // Fallback to v2 API
    try {
      const projects = await apiAtlassian<Array<Record<string, unknown>>>(
        `${apiBase}/rest/api/2/project?maxResults=${MAX_PROJECTS}`,
      );
      const projectList = Array.isArray(projects) ? projects : [];
      results.projects = {
        total: projectList.length,
        items: projectList.map((p: any) => ({
          key: p.key,
          name: p.name,
          projectTypeKey: p.projectTypeKey ?? null,
        })),
      };
    } catch (e2: any) {
      results.projects = { error: e2.message };
    }
  }

  // --- Hints ---
  results.hints = {
    maxResults: 50,
    pagination: 'Use startAt for offset-based pagination. maxResults cap is 50 for search and projects.',
    cloudId: cloudId || 'Not available — using direct URL auth',
    siteUrl: siteUrl || config.baseUrl,
    jqlTip: 'Always double-quote project keys to avoid reserved word collisions (e.g., project = "IN")',
  };

  console.log(JSON.stringify(results, null, 2));
}

discover().catch((err) => {
  console.error('Discovery failed:', err.message);
  process.exit(1);
});
