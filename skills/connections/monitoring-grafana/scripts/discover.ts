#!/usr/bin/env bun
/**
 * Discovery script for monitoring-grafana
 * Discovers datasources, dashboards, folders, alerts, incidents,
 * Prometheus/Loki label metadata, and Sift plugin availability.
 */

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
const config = {
  url: (process.env.GRAFANA_URL || '').replace(/\/+$/, ''),
  token: process.env.GRAFANA_TOKEN || process.env.GRAFANA_API_KEY || '',
};

if (!config.url || !config.token) {
  console.error(
    'Missing required environment variables: GRAFANA_URL and GRAFANA_TOKEN (or GRAFANA_API_KEY)',
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

const MAX_DATASOURCES = flag('max-datasources', 50);
const MAX_DASHBOARDS = flag('max-dashboards', 50);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
async function api<T = unknown>(path: string): Promise<T> {
  const res = await fetch(`${config.url}${path}`, {
    headers: { Authorization: `Bearer ${config.token}`, Accept: 'application/json' },
  });
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    throw new Error(`GET ${path} → ${res.status} ${res.statusText}: ${body.slice(0, 200)}`);
  }
  return res.json() as Promise<T>;
}

interface Datasource {
  uid: string;
  name: string;
  type: string;
  isDefault: boolean;
}

interface Dashboard {
  uid: string;
  title: string;
  folderTitle?: string;
  tags?: string[];
  type: string;
}

interface Folder {
  uid: string;
  title: string;
}

interface AlertRule {
  uid: string;
  title: string;
  state?: string;
  labels?: Record<string, string>;
}

// ---------------------------------------------------------------------------
// Discovery
// ---------------------------------------------------------------------------
async function discover() {
  const results: Record<string, unknown> = {};
  const capabilities: Record<string, boolean> = {};

  // --- Datasources ---
  try {
    const raw = await api<Datasource[]>('/api/datasources');
    const datasources = raw.slice(0, MAX_DATASOURCES).map((ds) => ({
      uid: ds.uid,
      name: ds.name,
      type: ds.type,
      isDefault: ds.isDefault,
    }));
    const grouped: Record<string, typeof datasources> = {};
    for (const ds of datasources) {
      (grouped[ds.type] ??= []).push(ds);
    }
    results.datasources = { total: raw.length, byType: grouped };
    capabilities.datasources = true;
  } catch (e: any) {
    results.datasources = { error: e.message };
    capabilities.datasources = false;
  }

  // --- Dashboards ---
  try {
    const raw = await api<Dashboard[]>(`/api/search?type=dash-db&limit=${MAX_DASHBOARDS}`);
    results.dashboards = raw.map((d) => ({
      uid: d.uid,
      title: d.title,
      folderTitle: d.folderTitle ?? null,
      tags: d.tags ?? [],
    }));
    capabilities.dashboards = true;
  } catch (e: any) {
    results.dashboards = { error: e.message };
    capabilities.dashboards = false;
  }

  // --- Folders ---
  try {
    const raw = await api<Folder[]>('/api/folders?limit=100');
    results.folders = raw.map((f) => ({ uid: f.uid, title: f.title }));
    capabilities.folders = true;
  } catch (e: any) {
    results.folders = { error: e.message };
    capabilities.folders = false;
  }

  // --- Alerts ---
  try {
    const raw = await api<AlertRule[]>('/api/ruler/grafana/api/v1/rules');
    // raw is typically { [namespace]: [{ rules }] }
    const rules: AlertRule[] = [];
    if (typeof raw === 'object' && raw !== null && !Array.isArray(raw)) {
      for (const groups of Object.values(raw as Record<string, any[]>)) {
        for (const group of groups) {
          if (Array.isArray(group.rules)) {
            rules.push(...group.rules);
          }
        }
      }
    }
    const stateBreakdown: Record<string, number> = {};
    const firing: AlertRule[] = [];
    for (const r of rules) {
      const state = r.state ?? 'unknown';
      stateBreakdown[state] = (stateBreakdown[state] ?? 0) + 1;
      if (state === 'firing') firing.push({ uid: r.uid, title: r.title, state });
    }
    results.alerts = { total: rules.length, stateBreakdown, firing };
    capabilities.alerts = true;
  } catch (e: any) {
    results.alerts = { error: e.message };
    capabilities.alerts = false;
  }

  // --- Incidents ---
  try {
    const raw = await api<{ incidents?: any[] }>('/api/plugins/grafana-incident-app/resources/api/v1/IncidentsService.QueryIncidentPreviews');
    const incidents = (raw.incidents ?? []).map((inc: any) => ({
      id: inc.incidentID,
      title: inc.title,
      status: inc.status,
    }));
    results.incidents = incidents;
    capabilities.incidents = true;
  } catch (e: any) {
    results.incidents = { error: e.message };
    capabilities.incidents = false;
  }

  // --- Prometheus label discovery ---
  const promDatasources = ((results.datasources as any)?.byType?.prometheus ?? []) as Datasource[];
  if (promDatasources.length > 0) {
    const promMeta: Record<string, unknown> = {};
    for (const ds of promDatasources.slice(0, 3)) {
      try {
        const labels = await api<{ data?: string[] }>(
          `/api/datasources/proxy/uid/${ds.uid}/api/v1/labels`,
        );
        const labelNames = labels.data ?? [];
        const keyLabels: Record<string, string[]> = {};
        for (const key of ['job', 'namespace', 'instance']) {
          if (labelNames.includes(key)) {
            try {
              const vals = await api<{ data?: string[] }>(
                `/api/datasources/proxy/uid/${ds.uid}/api/v1/label/${key}/values`,
              );
              keyLabels[key] = (vals.data ?? []).slice(0, 20);
            } catch {
              keyLabels[key] = [];
            }
          }
        }
        promMeta[ds.uid] = { name: ds.name, labelNames: labelNames.slice(0, 50), keyLabels };
      } catch (e: any) {
        promMeta[ds.uid] = { name: ds.name, error: e.message };
      }
    }
    results.prometheus = promMeta;
  }

  // --- Loki label discovery ---
  const lokiDatasources = ((results.datasources as any)?.byType?.loki ?? []) as Datasource[];
  if (lokiDatasources.length > 0) {
    const lokiMeta: Record<string, unknown> = {};
    for (const ds of lokiDatasources.slice(0, 3)) {
      try {
        const labels = await api<{ data?: string[] }>(
          `/api/datasources/proxy/uid/${ds.uid}/loki/api/v1/labels`,
        );
        const labelNames = labels.data ?? [];
        const keyLabels: Record<string, string[]> = {};
        for (const key of ['app', 'namespace', 'pod']) {
          if (labelNames.includes(key)) {
            try {
              const vals = await api<{ data?: string[] }>(
                `/api/datasources/proxy/uid/${ds.uid}/loki/api/v1/label/${key}/values`,
              );
              keyLabels[key] = (vals.data ?? []).slice(0, 20);
            } catch {
              keyLabels[key] = [];
            }
          }
        }
        lokiMeta[ds.uid] = { name: ds.name, labelNames: labelNames.slice(0, 50), keyLabels };
      } catch (e: any) {
        lokiMeta[ds.uid] = { name: ds.name, error: e.message };
      }
    }
    results.loki = lokiMeta;
  }

  // --- Sift plugin availability ---
  try {
    const plugins = await api<any[]>('/api/plugins?type=app');
    const sift = (plugins ?? []).find((p: any) => p.id === 'grafana-ml-app' || p.id === 'grafana-sift-app');
    capabilities.siftAvailable = !!sift;
  } catch {
    capabilities.siftAvailable = false;
  }

  results.capabilities = capabilities;

  // --- Hints ---
  results.hints = {
    loki: {
      queryLimits: 'Start with limit: 20-50, max 1000',
      forbiddenRegex: ['\\w', '\\d', '\\s', '\\b', '(?i)'],
      safeAlternatives: ['[A-Za-z0-9_]', '[0-9]', '[ \\t]', 'alternation'],
      emptySelector: 'NEVER use logql: "{}" — always include at least one label matcher',
      rateLimits: 'Max 2-3 concurrent queries; prefer single query + TypeScript filtering',
    },
  };

  console.log(JSON.stringify(results, null, 2));
}

discover().catch((err) => {
  console.error('Discovery failed:', err.message);
  process.exit(1);
});
