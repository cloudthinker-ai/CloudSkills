#!/usr/bin/env bun
/**
 * Discovery script for analytics-cloudflare
 * Discovers Cloudflare accounts, zones, data retention windows,
 * available GraphQL datasets, and query hints.
 */

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
const config = {
  apiToken: process.env.CLOUDFLARE_API_TOKEN || process.env.CF_API_TOKEN || '',
  apiKey: process.env.CLOUDFLARE_API_KEY || process.env.CF_API_KEY || '',
  email: process.env.CLOUDFLARE_EMAIL || process.env.CF_EMAIL || '',
};

if (!config.apiToken && !(config.apiKey && config.email)) {
  console.error(
    'Missing required environment variables:\n' +
    '  Option 1 (API token): CLOUDFLARE_API_TOKEN (or CF_API_TOKEN)\n' +
    '  Option 2 (API key):   CLOUDFLARE_API_KEY + CLOUDFLARE_EMAIL',
  );
  process.exit(1);
}

// ---------------------------------------------------------------------------
// CLI args
// ---------------------------------------------------------------------------
const args = process.argv.slice(2);
function flagStr(name: string, fallback: string): string {
  const idx = args.indexOf(`--${name}`);
  return idx !== -1 && args[idx + 1] ? args[idx + 1] : fallback;
}
function flagNum(name: string, fallback: number): number {
  const idx = args.indexOf(`--${name}`);
  return idx !== -1 && args[idx + 1] ? Number(args[idx + 1]) : fallback;
}

const MAX_ZONES = flagNum('max-zones', 20);
const ZONE_FILTER = flagStr('zone', '');

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function authHeaders(): Record<string, string> {
  if (config.apiToken) {
    return { Authorization: `Bearer ${config.apiToken}` };
  }
  return {
    'X-Auth-Key': config.apiKey,
    'X-Auth-Email': config.email,
  };
}

async function cfApi<T = unknown>(path: string): Promise<T> {
  const res = await fetch(`https://api.cloudflare.com/client/v4${path}`, {
    headers: { ...authHeaders(), 'Content-Type': 'application/json' },
  });
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    throw new Error(`GET ${path} → ${res.status} ${res.statusText}: ${body.slice(0, 200)}`);
  }
  return res.json() as Promise<T>;
}

async function graphql(query: string, variables: Record<string, unknown> = {}): Promise<unknown> {
  const res = await fetch('https://api.cloudflare.com/client/v4/graphql', {
    method: 'POST',
    headers: { ...authHeaders(), 'Content-Type': 'application/json' },
    body: JSON.stringify({ query, variables }),
  });
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    throw new Error(`GraphQL → ${res.status} ${res.statusText}: ${body.slice(0, 200)}`);
  }
  return res.json();
}

// ---------------------------------------------------------------------------
// Discovery
// ---------------------------------------------------------------------------
async function discover() {
  const results: Record<string, unknown> = {};

  // --- Accounts ---
  try {
    const acctResp = await cfApi<{
      result: Array<{ id: string; name: string }>;
    }>('/accounts?per_page=10');

    results.accounts = (acctResp.result ?? []).map((a) => ({
      id: a.id,
      name: a.name,
    }));
  } catch (e: any) {
    results.accounts = { error: e.message };
  }

  // --- Zones ---
  try {
    const zonePath = ZONE_FILTER
      ? `/zones?name=${encodeURIComponent(ZONE_FILTER)}&per_page=${MAX_ZONES}`
      : `/zones?per_page=${MAX_ZONES}`;

    const zoneResp = await cfApi<{
      result: Array<{
        id: string;
        name: string;
        status: string;
        account: { id: string; name: string };
        plan?: { name: string };
      }>;
      result_info?: { total_count: number };
    }>(zonePath);

    const zones = (zoneResp.result ?? []).map((z) => ({
      id: z.id,
      name: z.name,
      status: z.status,
      accountId: z.account.id,
      accountName: z.account.name,
      plan: z.plan?.name ?? 'unknown',
    }));

    results.zones = {
      total: zoneResp.result_info?.total_count ?? zones.length,
      items: zones,
    };

    // --- Data retention based on plan ---
    const planTier = zones[0]?.plan?.toLowerCase() ?? 'free';
    const retentionDays: Record<string, { dns: number; http: number; firewall: number; workers: number }> = {
      free: { dns: 7, http: 31, firewall: 30, workers: 30 },
      pro: { dns: 7, http: 31, firewall: 30, workers: 30 },
      business: { dns: 30, http: 62, firewall: 30, workers: 30 },
      enterprise: { dns: 90, http: 62, firewall: 30, workers: 30 },
    };

    const tier = Object.keys(retentionDays).find((t) => planTier.includes(t)) ?? 'free';
    results.dataRetention = retentionDays[tier];

    // --- Safe date ranges ---
    const now = new Date();
    const retention = retentionDays[tier];
    const safeDateRanges: Record<string, { start: string; end: string }> = {};

    // DNS uses Date! format
    const dnsStart = new Date(now.getTime() - (retention.dns - 1) * 86400000);
    safeDateRanges.dns = {
      start: dnsStart.toISOString().split('T')[0],
      end: now.toISOString().split('T')[0],
    };

    // HTTP uses Time! format
    const httpStart = new Date(now.getTime() - (retention.http - 1) * 86400000);
    safeDateRanges.http = {
      start: httpStart.toISOString(),
      end: now.toISOString(),
    };

    // Firewall uses Time! format
    const fwStart = new Date(now.getTime() - (retention.firewall - 1) * 86400000);
    safeDateRanges.firewall = {
      start: fwStart.toISOString(),
      end: now.toISOString(),
    };

    // Workers uses Time! format
    const wkStart = new Date(now.getTime() - (retention.workers - 1) * 86400000);
    safeDateRanges.workers = {
      start: wkStart.toISOString(),
      end: now.toISOString(),
    };

    results.safeDateRanges = safeDateRanges;

  } catch (e: any) {
    results.zones = { error: e.message };
  }

  // --- Available datasets ---
  results.availableDatasets = [
    {
      name: 'dnsAnalyticsAdaptiveGroups',
      scope: 'account',
      variableType: 'Date!',
      description: 'DNS analytics with adaptive grouping',
    },
    {
      name: 'httpRequests1hGroups',
      scope: 'zone',
      variableType: 'Time!',
      description: 'HTTP request analytics (1-hour groups)',
    },
    {
      name: 'firewallEventsAdaptive',
      scope: 'zone',
      variableType: 'Time!',
      description: 'Firewall events with adaptive grouping',
    },
    {
      name: 'workersInvocationsAdaptive',
      scope: 'account',
      variableType: 'Time!',
      description: 'Workers invocation analytics',
    },
  ];

  // --- GraphQL introspection probe ---
  try {
    const intro = await graphql(`{
      __schema {
        queryType { name }
      }
    }`) as { data?: { __schema?: { queryType?: { name: string } } }; errors?: unknown[] };

    if (intro.errors && (intro.errors as unknown[]).length > 0) {
      results.graphqlStatus = { available: false, errors: intro.errors };
    } else {
      results.graphqlStatus = { available: true };
    }
  } catch (e: any) {
    results.graphqlStatus = { available: false, error: e.message };
  }

  // --- Query hints ---
  results.queryHints = {
    criticalRequirement: 'MUST call graphql_zones_list({ name: "domain.com" }) before DNS queries to establish zone context',
    correctWorkflow: [
      '1. Call graphql_zones_list({ name: "domain.com" }) to establish context',
      '2. Extract accountId from zones response',
      '3. Build GraphQL query with correct variable types',
      '4. Parse response: JSON.parse(result.split("\\n\\n")[0])',
      '5. Check for errors before accessing data',
    ],
    variableTypes: {
      'Date!': 'Used by DNS datasets. Format: "2026-01-27"',
      'Time!': 'Used by HTTP, Firewall, Workers datasets. Format: "2026-01-27T00:00:00Z"',
    },
    scopeRequirements: {
      account: ['dnsAnalyticsAdaptiveGroups', 'workersInvocationsAdaptive'],
      zone: ['httpRequests1hGroups', 'firewallEventsAdaptive'],
    },
    responseHandling: 'graphql_graphql_query returns a string with JSON + markdown link. Always split on \\n\\n and parse the first part.',
  };

  console.log(JSON.stringify(results, null, 2));
}

discover().catch((err) => {
  console.error('Discovery failed:', err.message);
  process.exit(1);
});
