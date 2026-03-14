---
name: managing-duckdb
description: |
  DuckDB database management, query performance analysis, extension management, and storage optimization. Covers database file inspection, table statistics, memory configuration, Parquet/CSV import health, and columnar storage efficiency metrics. Read this skill before any DuckDB operations.
connection_type: duckdb
preload: false
---

# DuckDB Management Skill

Monitor, analyze, and optimize DuckDB instances safely.

## MANDATORY: Discovery-First Pattern

**Always check database metadata and list tables before any query operations. Never assume table names or column types.**

### Phase 1: Discovery

```bash
#!/bin/bash

DUCKDB_FILE="${DUCKDB_FILE:-my_database.duckdb}"

duck_query() {
    duckdb "$DUCKDB_FILE" -c "$1" 2>/dev/null
}

echo "=== DuckDB Version ==="
duckdb -c "SELECT version();" 2>/dev/null

echo ""
echo "=== Database Info ==="
duck_query "CALL pragma_database_size();"

echo ""
echo "=== Schemas ==="
duck_query "SELECT schema_name FROM information_schema.schemata;"

echo ""
echo "=== Tables ==="
duck_query "SELECT table_schema, table_name, table_type FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog','information_schema') ORDER BY table_schema, table_name;"

echo ""
echo "=== Extensions ==="
duck_query "SELECT extension_name, installed, loaded FROM duckdb_extensions() ORDER BY installed DESC, extension_name;"

echo ""
echo "=== Settings (key) ==="
duck_query "SELECT name, value FROM duckdb_settings() WHERE name IN ('memory_limit','threads','default_order','access_mode','temp_directory');"
```

**Phase 1 outputs:** Version, database size, table inventory, installed extensions, key settings.

### Phase 2: Analysis

```bash
#!/bin/bash

DUCKDB_FILE="${DUCKDB_FILE:-my_database.duckdb}"
TABLE="${1:-my_table}"

duck_query() {
    duckdb "$DUCKDB_FILE" -c "$1" 2>/dev/null
}

echo "=== Table Details ==="
duck_query "DESCRIBE $TABLE;"

echo ""
echo "=== Table Statistics ==="
duck_query "SELECT COUNT(*) as row_count FROM $TABLE;"
duck_query "CALL pragma_storage_info('$TABLE');" | head -20

echo ""
echo "=== Column Stats ==="
duck_query "SELECT column_name, column_type, null_percentage, avg_width, n_unique FROM pragma_table_info('$TABLE');" 2>/dev/null || \
    duck_query "SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name='$TABLE';"

echo ""
echo "=== Memory Usage ==="
duck_query "SELECT * FROM pragma_database_size();"

echo ""
echo "=== Recent Queries Profile ==="
duck_query "SELECT * FROM pragma_last_profiling_output;" 2>/dev/null || echo "Profiling not enabled"

echo ""
echo "=== Storage Info ==="
ls -lh "$DUCKDB_FILE" 2>/dev/null
ls -lh "${DUCKDB_FILE}.wal" 2>/dev/null || echo "No WAL file"
```

## Output Format

```
DUCKDB ANALYSIS
===============
Version: [version] | File: [path] | Size: [size]
Tables: [count] | Extensions: [loaded]

ISSUES FOUND:
- [issue with affected table/setting]

RECOMMENDATIONS:
- [actionable recommendation]
```
