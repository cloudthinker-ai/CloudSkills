#!/usr/bin/env bun
/**
 * Discovery script for analyzing-postgres
 * Discovers schemas, tables with row counts and sizes, indexes,
 * foreign key relationships, database size, security info, and performance hotspots.
 */

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------
const config = {
  host: process.env.PGHOST || process.env.POSTGRES_HOST || 'localhost',
  port: Number(process.env.PGPORT || process.env.POSTGRES_PORT || 5432),
  database: process.env.PGDATABASE || process.env.POSTGRES_DATABASE || process.env.POSTGRES_DB || '',
  user: process.env.PGUSER || process.env.POSTGRES_USER || '',
  password: process.env.PGPASSWORD || process.env.POSTGRES_PASSWORD || '',
  connectionString: process.env.DATABASE_URL || process.env.POSTGRES_URL || '',
  ssl: process.env.PGSSLMODE || process.env.POSTGRES_SSL || '',
};

if (!config.connectionString && (!config.database || !config.user)) {
  console.error(
    'Missing required environment variables:\n' +
    '  Option 1: DATABASE_URL (or POSTGRES_URL)\n' +
    '  Option 2: PGDATABASE + PGUSER + PGPASSWORD (or POSTGRES_DATABASE + POSTGRES_USER + POSTGRES_PASSWORD)',
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
function flagBool(name: string, fallback: boolean): boolean {
  const idx = args.indexOf(`--${name}`);
  if (idx === -1) return fallback;
  const val = args[idx + 1];
  return val === 'true' || val === '1' || val === 'yes';
}

const MAX_TABLES = flagNum('max-tables', 50);
const SAMPLING = flagBool('sampling', false);
const TIMEOUT = flagNum('timeout', 60);
const ALIAS = flagStr('alias', '');

// ---------------------------------------------------------------------------
// Postgres client (using Bun's built-in postgres or pg-compatible fetch)
// ---------------------------------------------------------------------------

// We use a raw TCP approach via the `pg` package if available,
// but for maximum compatibility we'll shell out to psql for discovery.
import { $ } from 'bun';

function buildConnArgs(): string[] {
  if (config.connectionString) {
    return [config.connectionString];
  }
  const parts: string[] = [];
  if (config.host) parts.push(`-h`, config.host);
  if (config.port) parts.push(`-p`, String(config.port));
  if (config.database) parts.push(`-d`, config.database);
  if (config.user) parts.push(`-U`, config.user);
  return parts;
}

const env: Record<string, string> = { ...process.env as Record<string, string> };
if (config.password) env.PGPASSWORD = config.password;
if (config.ssl === 'require' || config.ssl === 'true') env.PGSSLMODE = 'require';

async function psql(query: string): Promise<string> {
  const connArgs = buildConnArgs();
  const isUrl = connArgs.length === 1 && connArgs[0].startsWith('postgres');

  const proc = isUrl
    ? Bun.spawn(['psql', connArgs[0], '-t', '-A', '-F', '\t', '-c', query], {
        env,
        stdout: 'pipe',
        stderr: 'pipe',
      })
    : Bun.spawn(['psql', ...connArgs, '-t', '-A', '-F', '\t', '-c', query], {
        env,
        stdout: 'pipe',
        stderr: 'pipe',
      });

  const stdout = await new Response(proc.stdout).text();
  const stderr = await new Response(proc.stderr).text();
  const exitCode = await proc.exited;

  if (exitCode !== 0) {
    throw new Error(`psql error (exit ${exitCode}): ${stderr.slice(0, 300)}`);
  }
  return stdout.trim();
}

function parseRows(output: string): string[][] {
  if (!output) return [];
  return output.split('\n').filter(Boolean).map((line) => line.split('\t'));
}

// ---------------------------------------------------------------------------
// Discovery
// ---------------------------------------------------------------------------
async function discover() {
  const results: Record<string, unknown> = {};

  if (ALIAS) {
    results.alias = ALIAS;
  }

  // --- Schemas ---
  try {
    const out = await psql(
      `SELECT schema_name FROM information_schema.schemata WHERE schema_name NOT IN ('pg_catalog', 'information_schema', 'pg_toast') ORDER BY schema_name`,
    );
    results.schemas = parseRows(out).map((r) => r[0]);
  } catch (e: any) {
    results.schemas = { error: e.message };
  }

  // --- Tables with row counts and sizes ---
  try {
    const out = await psql(`
      SELECT
        schemaname,
        relname AS table_name,
        n_live_tup AS row_count,
        pg_size_pretty(pg_total_relation_size(schemaname || '.' || relname)) AS total_size,
        pg_total_relation_size(schemaname || '.' || relname) AS size_bytes
      FROM pg_stat_user_tables
      ORDER BY pg_total_relation_size(schemaname || '.' || relname) DESC
      LIMIT ${MAX_TABLES}
    `);
    results.tables = parseRows(out).map((r) => ({
      schema: r[0],
      name: r[1],
      rowCount: Number(r[2] ?? 0),
      totalSize: r[3],
      sizeBytes: Number(r[4] ?? 0),
    }));
  } catch (e: any) {
    results.tables = { error: e.message };
  }

  // --- Indexes ---
  try {
    const out = await psql(`
      SELECT
        schemaname,
        tablename,
        indexname,
        pg_size_pretty(pg_relation_size(schemaname || '.' || indexname)) AS index_size,
        idx_scan AS scans,
        idx_tup_read AS tuples_read
      FROM pg_stat_user_indexes
      ORDER BY pg_relation_size(schemaname || '.' || indexname) DESC
      LIMIT 50
    `);
    results.indexes = parseRows(out).map((r) => ({
      schema: r[0],
      table: r[1],
      name: r[2],
      size: r[3],
      scans: Number(r[4] ?? 0),
      tuplesRead: Number(r[5] ?? 0),
    }));
  } catch (e: any) {
    results.indexes = { error: e.message };
  }

  // --- Foreign key relationships ---
  try {
    const out = await psql(`
      SELECT
        tc.table_schema,
        tc.table_name,
        kcu.column_name,
        ccu.table_schema AS foreign_schema,
        ccu.table_name AS foreign_table,
        ccu.column_name AS foreign_column
      FROM information_schema.table_constraints AS tc
      JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name AND tc.table_schema = kcu.table_schema
      JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name AND ccu.table_schema = tc.table_schema
      WHERE tc.constraint_type = 'FOREIGN KEY'
      ORDER BY tc.table_schema, tc.table_name
      LIMIT 100
    `);
    results.relationships = parseRows(out).map((r) => ({
      schema: r[0],
      table: r[1],
      column: r[2],
      foreignSchema: r[3],
      foreignTable: r[4],
      foreignColumn: r[5],
    }));
  } catch (e: any) {
    results.relationships = { error: e.message };
  }

  // --- Database size ---
  try {
    const out = await psql(
      `SELECT pg_size_pretty(pg_database_size(current_database())), pg_database_size(current_database())`,
    );
    const row = parseRows(out)[0];
    results.size_info = {
      databaseSize: row?.[0] ?? 'unknown',
      sizeBytes: Number(row?.[1] ?? 0),
    };
  } catch (e: any) {
    results.size_info = { error: e.message };
  }

  // --- Security overview ---
  try {
    const superuserOut = await psql(
      `SELECT count(*) FROM pg_roles WHERE rolsuper = true`,
    );
    const sslOut = await psql(
      `SELECT CASE WHEN ssl THEN 'on' ELSE 'off' END FROM pg_stat_ssl WHERE pid = pg_backend_pid()`,
    ).catch(() => 'unknown');

    results.security = {
      superuserCount: Number(parseRows(superuserOut)[0]?.[0] ?? 0),
      sslStatus: sslOut.trim() || 'unknown',
    };
  } catch (e: any) {
    results.security = { error: e.message };
  }

  // --- Performance hotspots ---
  try {
    const out = await psql(`
      SELECT
        schemaname,
        relname,
        seq_scan,
        seq_tup_read,
        n_dead_tup,
        n_live_tup,
        CASE WHEN n_live_tup > 0 THEN round(100.0 * n_dead_tup / n_live_tup, 1) ELSE 0 END AS dead_ratio
      FROM pg_stat_user_tables
      WHERE seq_scan > 1000 OR n_dead_tup > 10000
      ORDER BY seq_scan DESC
      LIMIT 20
    `);
    results.performance_hotspots = parseRows(out).map((r) => ({
      schema: r[0],
      table: r[1],
      seqScans: Number(r[2] ?? 0),
      seqTupRead: Number(r[3] ?? 0),
      deadTuples: Number(r[4] ?? 0),
      liveTuples: Number(r[5] ?? 0),
      deadRatioPercent: Number(r[6] ?? 0),
    }));
  } catch (e: any) {
    results.performance_hotspots = { error: e.message };
  }

  console.log(JSON.stringify(results, null, 2));
}

discover().catch((err) => {
  console.error('Discovery failed:', err.message);
  process.exit(1);
});
