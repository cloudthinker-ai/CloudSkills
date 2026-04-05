#!/usr/bin/env bun
/**
 * Discovery script for k8s
 * Discovers cluster info, nodes, namespaces, workloads, services, and recent events.
 * Uses kubectl with the configured kubeconfig.
 */

import { $ } from 'bun';

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
const KUBECONFIG = process.env.KUBECONFIG || `${process.env.HOME}/.kube/config`;
const KUBECTL = process.env.KUBECTL_PATH || 'kubectl';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
async function kubectl<T = unknown>(args: string): Promise<T> {
  const result = await $`${KUBECTL} --kubeconfig=${KUBECONFIG} ${args.split(' ')} -o json`
    .quiet()
    .text();
  return JSON.parse(result) as T;
}

async function kubectlRaw(args: string): Promise<string> {
  return $`${KUBECTL} --kubeconfig=${KUBECONFIG} ${args.split(' ')}`.quiet().text();
}

// ---------------------------------------------------------------------------
// Discovery
// ---------------------------------------------------------------------------
async function discover() {
  const results: Record<string, unknown> = {};

  // --- Cluster info ---
  try {
    const version = await kubectl<Record<string, unknown>>('version');
    results.clusterVersion = version;
  } catch (e: any) {
    try {
      const versionText = await kubectlRaw('version --short');
      results.clusterVersion = versionText.trim();
    } catch (e2: any) {
      results.clusterVersion = { error: e2.message };
    }
  }

  // --- Context ---
  try {
    const ctx = await kubectlRaw('config current-context');
    results.currentContext = ctx.trim();
  } catch (e: any) {
    results.currentContext = { error: e.message };
  }

  // --- Nodes ---
  try {
    const nodes = await kubectl<{ items: Array<{
      metadata: { name: string; labels?: Record<string, string> };
      status: {
        conditions?: Array<{ type: string; status: string }>;
        nodeInfo?: { kubeletVersion: string; osImage: string; containerRuntimeVersion: string };
        capacity?: Record<string, string>;
        allocatable?: Record<string, string>;
      };
    }> }>('get nodes');

    results.nodes = nodes.items.map((n) => {
      const ready = n.status.conditions?.find((c) => c.type === 'Ready');
      return {
        name: n.metadata.name,
        ready: ready?.status === 'True',
        kubeletVersion: n.status.nodeInfo?.kubeletVersion ?? 'unknown',
        os: n.status.nodeInfo?.osImage ?? 'unknown',
        cpu: n.status.capacity?.cpu ?? 'unknown',
        memory: n.status.capacity?.memory ?? 'unknown',
      };
    });
  } catch (e: any) {
    results.nodes = { error: e.message };
  }

  // --- Namespaces ---
  try {
    const ns = await kubectl<{ items: Array<{ metadata: { name: string }; status: { phase: string } }> }>(
      'get namespaces',
    );
    results.namespaces = ns.items.map((n) => ({
      name: n.metadata.name,
      phase: n.status.phase,
    }));
  } catch (e: any) {
    results.namespaces = { error: e.message };
  }

  // --- Pod summary per namespace ---
  try {
    const allPods = await kubectl<{
      items: Array<{
        metadata: { name: string; namespace: string };
        status: { phase: string; containerStatuses?: Array<{ ready: boolean; restartCount: number }> };
      }>;
    }>('get pods --all-namespaces');

    const nsSummary: Record<string, { total: number; running: number; pending: number; failed: number; crashLooping: number }> = {};
    for (const pod of allPods.items) {
      const ns = pod.metadata.namespace;
      if (!nsSummary[ns]) nsSummary[ns] = { total: 0, running: 0, pending: 0, failed: 0, crashLooping: 0 };
      nsSummary[ns].total++;
      if (pod.status.phase === 'Running') nsSummary[ns].running++;
      else if (pod.status.phase === 'Pending') nsSummary[ns].pending++;
      else if (pod.status.phase === 'Failed') nsSummary[ns].failed++;

      const restarts = pod.status.containerStatuses?.reduce((sum, c) => sum + c.restartCount, 0) ?? 0;
      if (restarts > 10) nsSummary[ns].crashLooping++;
    }
    results.pods = {
      totalCount: allPods.items.length,
      byNamespace: nsSummary,
    };
  } catch (e: any) {
    results.pods = { error: e.message };
  }

  // --- Services ---
  try {
    const svcs = await kubectl<{
      items: Array<{
        metadata: { name: string; namespace: string };
        spec: { type: string; clusterIP?: string; ports?: Array<{ port: number; protocol: string }> };
      }>;
    }>('get services --all-namespaces');

    results.services = {
      total: svcs.items.length,
      byType: svcs.items.reduce<Record<string, number>>((acc, s) => {
        acc[s.spec.type] = (acc[s.spec.type] ?? 0) + 1;
        return acc;
      }, {}),
    };
  } catch (e: any) {
    results.services = { error: e.message };
  }

  // --- Recent events (warnings only) ---
  try {
    const events = await kubectl<{
      items: Array<{
        metadata: { namespace: string };
        type: string;
        reason: string;
        message: string;
        involvedObject: { kind: string; name: string };
        count?: number;
        lastTimestamp?: string;
      }>;
    }>('get events --all-namespaces --field-selector type=Warning');

    const warnings = events.items
      .sort((a, b) => {
        const ta = a.lastTimestamp ? new Date(a.lastTimestamp).getTime() : 0;
        const tb = b.lastTimestamp ? new Date(b.lastTimestamp).getTime() : 0;
        return tb - ta;
      })
      .slice(0, 20)
      .map((e) => ({
        namespace: e.metadata.namespace,
        reason: e.reason,
        message: e.message?.slice(0, 200),
        object: `${e.involvedObject.kind}/${e.involvedObject.name}`,
        count: e.count ?? 1,
        lastSeen: e.lastTimestamp ?? null,
      }));

    results.recentWarnings = warnings;
  } catch (e: any) {
    results.recentWarnings = { error: e.message };
  }

  // --- Resource usage (if metrics-server available) ---
  try {
    const topNodes = await kubectlRaw('top nodes --no-headers');
    const lines = topNodes.trim().split('\n').filter(Boolean);
    results.resourceUsage = {
      nodes: lines.map((line) => {
        const parts = line.trim().split(/\s+/);
        return {
          name: parts[0],
          cpuUsage: parts[1],
          cpuPercent: parts[2],
          memoryUsage: parts[3],
          memoryPercent: parts[4],
        };
      }),
    };
  } catch {
    results.resourceUsage = { note: 'metrics-server not available' };
  }

  console.log(JSON.stringify(results, null, 2));
}

discover().catch((err) => {
  console.error('Discovery failed:', err.message);
  process.exit(1);
});
