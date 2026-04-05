#!/usr/bin/env bun
/**
 * Discovery script for monitoring-dynatrace
 * Discovers environment info, active problems, vulnerabilities,
 * and available Davis analyzers.
 */

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
const config = {
  url: (process.env.DT_ENVIRONMENT_URL || process.env.DYNATRACE_URL || '').replace(/\/+$/, ''),
  token: process.env.DT_PLATFORM_TOKEN || process.env.DYNATRACE_TOKEN || process.env.DT_API_TOKEN || '',
};

if (!config.url || !config.token) {
  console.error(
    'Missing required environment variables: DT_ENVIRONMENT_URL (or DYNATRACE_URL) and DT_PLATFORM_TOKEN (or DYNATRACE_TOKEN)',
  );
  process.exit(1);
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
async function api<T = unknown>(path: string): Promise<T> {
  const res = await fetch(`${config.url}${path}`, {
    headers: {
      Authorization: `Api-Token ${config.token}`,
      Accept: 'application/json',
    },
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

  // --- Environment info ---
  try {
    const env = await api<Record<string, unknown>>('/api/v1/config/clusterversion');
    results.environment = env;
    capabilities.environmentInfo = true;
  } catch (e: any) {
    // Try v2 endpoint as fallback
    try {
      const env = await api<Record<string, unknown>>('/api/v2/environment');
      results.environment = env;
      capabilities.environmentInfo = true;
    } catch (e2: any) {
      results.environment = { error: e2.message };
      capabilities.environmentInfo = false;
    }
  }

  // --- Active problems ---
  try {
    const problems = await api<{
      totalCount?: number;
      problems?: Array<{
        problemId: string;
        displayId: string;
        title: string;
        status: string;
        severityLevel: string;
        impactLevel: string;
        startTime: number;
        endTime: number;
      }>;
    }>('/api/v2/problems?problemSelector=status("OPEN")&pageSize=50');

    results.problems = {
      totalCount: problems.totalCount ?? 0,
      items: (problems.problems ?? []).map((p) => ({
        problemId: p.problemId,
        displayId: p.displayId,
        title: p.title,
        status: p.status,
        severity: p.severityLevel,
        impact: p.impactLevel,
        startTime: p.startTime ? new Date(p.startTime).toISOString() : null,
      })),
    };
    capabilities.problems = true;
  } catch (e: any) {
    results.problems = { error: e.message };
    capabilities.problems = false;
  }

  // --- Vulnerabilities ---
  try {
    const vulns = await api<{
      totalCount?: number;
      vulnerabilities?: Array<{
        vulnerabilityId: string;
        displayId: string;
        title: string;
        riskLevel: string;
        riskScore?: number;
        status: string;
      }>;
    }>('/api/v2/securityProblems?securityProblemSelector=riskLevel("CRITICAL","HIGH")&pageSize=25');

    results.vulnerabilities = {
      totalCount: vulns.totalCount ?? 0,
      items: (vulns.vulnerabilities ?? []).slice(0, 25).map((v) => ({
        vulnerabilityId: v.vulnerabilityId,
        displayId: v.displayId,
        title: v.title,
        riskLevel: v.riskLevel,
        riskScore: v.riskScore ?? null,
        status: v.status,
      })),
    };
    capabilities.vulnerabilities = true;
  } catch (e: any) {
    results.vulnerabilities = { error: e.message };
    capabilities.vulnerabilities = false;
  }

  // --- Davis analyzers ---
  try {
    const analyzers = await api<{
      analyzers?: Array<{
        analyzerName: string;
        description?: string;
      }>;
    }>('/api/v2/davis/analyzers');

    results.analyzers = (analyzers.analyzers ?? []).map((a) => ({
      name: a.analyzerName,
      description: a.description ?? '',
    }));
    capabilities.davisAnalyzers = true;
  } catch (e: any) {
    results.analyzers = { error: e.message };
    capabilities.davisAnalyzers = false;
  }

  results.capabilities = capabilities;

  // --- Hints ---
  results.hints = {
    dql: {
      commonTables: [
        'fetch logs',
        'fetch dt.metrics',
        'fetch spans',
        'fetch events',
        'fetch dt.davis.problems',
      ],
      defaultRecordLimit: 100,
      tip: 'Always use verify_dql() before execute_dql() to catch syntax errors',
    },
  };

  console.log(JSON.stringify(results, null, 2));
}

discover().catch((err) => {
  console.error('Discovery failed:', err.message);
  process.exit(1);
});
