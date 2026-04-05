#!/usr/bin/env bun
/**
 * Discovery script for monitoring-elasticsearch
 * Discovers cluster health, indices, shards, mappings, and index patterns.
 */

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
const config = {
  url: (process.env.ELASTICSEARCH_URL || process.env.ES_URL || '').replace(/\/+$/, ''),
  username: process.env.ELASTICSEARCH_USERNAME || process.env.ES_USERNAME || '',
  password: process.env.ELASTICSEARCH_PASSWORD || process.env.ES_PASSWORD || '',
  apiKey: process.env.ELASTICSEARCH_API_KEY || process.env.ES_API_KEY || '',
};

if (!config.url) {
  console.error(
    'Missing required environment variable: ELASTICSEARCH_URL (or ES_URL)',
  );
  process.exit(1);
}

if (!config.apiKey && !config.username) {
  console.error(
    'Missing auth: provide ELASTICSEARCH_API_KEY (or ES_API_KEY), or ELASTICSEARCH_USERNAME + ELASTICSEARCH_PASSWORD',
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

const MAX_INDICES = flag('max-indices', 50);
const MAX_MAPPINGS = flag('max-mappings', 5);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
function authHeaders(): Record<string, string> {
  if (config.apiKey) {
    return { Authorization: `ApiKey ${config.apiKey}` };
  }
  const creds = Buffer.from(`${config.username}:${config.password}`).toString('base64');
  return { Authorization: `Basic ${creds}` };
}

async function api<T = unknown>(path: string): Promise<T> {
  const res = await fetch(`${config.url}${path}`, {
    headers: { ...authHeaders(), Accept: 'application/json' },
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

  // --- Cluster health ---
  try {
    const health = await api<Record<string, unknown>>('/_cluster/health');
    results.clusterHealth = {
      status: health.status,
      numberOfNodes: health.number_of_nodes,
      numberOfDataNodes: health.number_of_data_nodes,
      activePrimaryShards: health.active_primary_shards,
      activeShards: health.active_shards,
      unassignedShards: health.unassigned_shards,
      relocatingShards: health.relocating_shards,
      initializingShards: health.initializing_shards,
    };
  } catch (e: any) {
    results.clusterHealth = { error: e.message };
  }

  // --- Indices ---
  try {
    const raw = await api<
      Array<{
        index: string;
        status: string;
        health: string;
        'docs.count': string;
        'store.size': string;
      }>
    >('/_cat/indices?format=json&s=docs.count:desc');

    const indices = raw
      .filter((i) => !i.index.startsWith('.'))
      .slice(0, MAX_INDICES)
      .map((i) => ({
        index: i.index,
        status: i.status,
        health: i.health,
        docsCount: Number(i['docs.count'] ?? 0),
        storeSize: i['store.size'] ?? 'unknown',
      }));

    results.indices = { total: raw.filter((i) => !i.index.startsWith('.')).length, items: indices };

    // --- Index patterns ---
    const prefixCounts: Record<string, number> = {};
    for (const idx of indices) {
      const parts = idx.index.split('-');
      if (parts.length >= 2) {
        const prefix = parts.slice(0, Math.min(parts.length - 1, 2)).join('-');
        prefixCounts[prefix] = (prefixCounts[prefix] ?? 0) + 1;
      }
    }
    results.indexPatterns = Object.entries(prefixCounts)
      .filter(([, count]) => count > 1)
      .sort((a, b) => b[1] - a[1])
      .map(([prefix, count]) => ({ pattern: `${prefix}-*`, count }));

    // --- Mappings for top indices ---
    const topIndices = indices.slice(0, MAX_MAPPINGS);
    const mappings: Record<string, string[]> = {};
    for (const idx of topIndices) {
      try {
        const mapping = await api<Record<string, any>>(`/${idx.index}/_mapping`);
        const indexMapping = mapping[idx.index];
        const props = indexMapping?.mappings?.properties ?? {};
        mappings[idx.index] = Object.keys(props).slice(0, 50);
      } catch {
        mappings[idx.index] = [];
      }
    }
    results.mappings = mappings;
  } catch (e: any) {
    results.indices = { error: e.message };
  }

  // --- Shards ---
  try {
    const raw = await api<Array<{ index: string; shard: string; state: string; node: string | null }>>(
      '/_cat/shards?format=json',
    );
    const total = raw.length;
    const unassigned = raw.filter((s) => s.state !== 'STARTED' && s.state !== 'RELOCATING');
    results.shards = {
      total,
      unassignedCount: unassigned.length,
      unassigned: unassigned.slice(0, 20).map((s) => ({
        index: s.index,
        shard: s.shard,
        state: s.state,
      })),
    };
  } catch (e: any) {
    results.shards = { error: e.message };
  }

  console.log(JSON.stringify(results, null, 2));
}

discover().catch((err) => {
  console.error('Discovery failed:', err.message);
  process.exit(1);
});
