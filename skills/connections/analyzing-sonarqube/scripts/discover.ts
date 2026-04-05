#!/usr/bin/env bun
/**
 * Discovery script for analyzing-sonarqube
 * Discovers projects, quality gate statuses, issue summaries by severity,
 * and available capabilities.
 */

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
const config = {
  url: (process.env.SONARQUBE_URL || process.env.SONAR_URL || '').replace(/\/+$/, ''),
  token: process.env.SONARQUBE_TOKEN || process.env.SONAR_TOKEN || '',
};

if (!config.url || !config.token) {
  console.error(
    'Missing required environment variables: SONARQUBE_URL (or SONAR_URL) and SONARQUBE_TOKEN (or SONAR_TOKEN)',
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

const MAX_PROJECTS = flag('max-projects', 10);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
async function api<T = unknown>(path: string): Promise<T> {
  const creds = Buffer.from(`${config.token}:`).toString('base64');
  const res = await fetch(`${config.url}${path}`, {
    headers: { Authorization: `Basic ${creds}`, Accept: 'application/json' },
  });
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    throw new Error(`GET ${path} → ${res.status} ${res.statusText}: ${body.slice(0, 200)}`);
  }
  return res.json() as Promise<T>;
}

// ---------------------------------------------------------------------------
// Discovery
// ---------------------------------------------------------------------------
async function discover() {
  const results: Record<string, unknown> = {};
  const capabilities: Record<string, boolean> = {};

  // --- Projects ---
  let projectKeys: string[] = [];
  try {
    const projects = await api<{
      components?: Array<{
        key: string;
        name: string;
        qualifier: string;
        visibility: string;
      }>;
      paging?: { total: number };
    }>(`/api/projects/search?ps=${MAX_PROJECTS}`);

    const items = (projects.components ?? []).map((p) => ({
      key: p.key,
      name: p.name,
      qualifier: p.qualifier,
      visibility: p.visibility,
    }));
    projectKeys = items.map((p) => p.key);

    results.projects = {
      total: projects.paging?.total ?? items.length,
      items,
    };
    capabilities.projects = true;
  } catch (e: any) {
    results.projects = { error: e.message };
    capabilities.projects = false;
  }

  // --- Quality gate statuses ---
  if (projectKeys.length > 0) {
    const qualityGates: Record<string, string> = {};
    for (const key of projectKeys) {
      try {
        const gate = await api<{
          projectStatus?: { status: string };
        }>(`/api/qualitygates/project_status?projectKey=${encodeURIComponent(key)}`);
        qualityGates[key] = gate.projectStatus?.status ?? 'UNKNOWN';
      } catch {
        qualityGates[key] = 'ERROR';
      }
    }
    results.qualityGates = qualityGates;
    capabilities['quality-gates'] = true;
  }

  // --- Issue summary by severity ---
  if (projectKeys.length > 0) {
    const issueSummary: Record<string, Record<string, number>> = {};
    for (const key of projectKeys) {
      try {
        const issues = await api<{
          facets?: Array<{
            property: string;
            values: Array<{ val: string; count: number }>;
          }>;
          total?: number;
        }>(
          `/api/issues/search?componentKeys=${encodeURIComponent(key)}&ps=1&facets=severities`,
        );

        const severityFacet = issues.facets?.find((f) => f.property === 'severities');
        const breakdown: Record<string, number> = {};
        for (const v of severityFacet?.values ?? []) {
          breakdown[v.val] = v.count;
        }
        issueSummary[key] = { total: issues.total ?? 0, ...breakdown };
      } catch {
        issueSummary[key] = { total: -1, error: 1 };
      }
    }
    results.issueSummary = issueSummary;
    capabilities.issues = true;
  }

  // --- Capability probes ---
  const toolsets = [
    { name: 'analysis', path: '/api/ce/component?component=__probe__' },
    { name: 'rules', path: '/api/rules/search?ps=1' },
    { name: 'duplications', path: '/api/duplications/show?key=__probe__' },
    { name: 'measures', path: '/api/measures/component?component=__probe__&metricKeys=ncloc' },
    { name: 'security-hotspots', path: '/api/hotspots/search?projectKey=__probe__' },
    { name: 'coverage', path: '/api/measures/component?component=__probe__&metricKeys=coverage' },
    { name: 'sources', path: '/api/sources/raw?key=__probe__' },
    { name: 'system', path: '/api/system/status' },
  ];

  for (const probe of toolsets) {
    if (capabilities[probe.name] !== undefined) continue;
    try {
      const res = await fetch(`${config.url}${probe.path}`, {
        headers: {
          Authorization: `Basic ${Buffer.from(`${config.token}:`).toString('base64')}`,
          Accept: 'application/json',
        },
      });
      // 200 or 404 (component not found) = capability available; 401/403 = not available
      capabilities[probe.name] = res.status !== 401 && res.status !== 403;
    } catch {
      capabilities[probe.name] = false;
    }
  }

  // --- Dependency risks probe ---
  try {
    const res = await fetch(
      `${config.url}/api/dependency_risks/search?projectKey=__probe__`,
      {
        headers: {
          Authorization: `Basic ${Buffer.from(`${config.token}:`).toString('base64')}`,
          Accept: 'application/json',
        },
      },
    );
    capabilities['dependency-risks'] = res.status !== 401 && res.status !== 403 && res.status !== 404;
  } catch {
    capabilities['dependency-risks'] = false;
  }

  results.capabilities = capabilities;

  console.log(JSON.stringify(results, null, 2));
}

discover().catch((err) => {
  console.error('Discovery failed:', err.message);
  process.exit(1);
});
