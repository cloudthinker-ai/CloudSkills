#!/usr/bin/env bash
set -euo pipefail

# GCP Billing Helper Functions
# Source this file: source ./get_billing_gcp.sh
# All queries enforce anti-hallucination rules:
#   - WHERE project.id filter (Rule 2)
#   - CAST(... AS NUMERIC) on financial fields (Rule 8)
#   - Net cost via UNNEST subquery, never LEFT JOIN UNNEST + SUM(cost) (Rule 3)
#   - cost_type awareness (Rule 9)

_bq_query() {
  local query="$1"
  bq query --use_legacy_sql=false --format=prettyjson --quiet "$query"
}

_parse_billing_args() {
  local -n _table_ref=$1 _project_ref=$2
  shift 2
  _table_ref="$1"; shift
  _project_ref="${1:-}"; shift || true
  local days=""
  local month=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --days) days="$2"; shift 2 ;;
      --month) month="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  echo "${days:-}|${month:-}"
}

# Detect billing currency (MANDATORY first call)
# Usage: gcp_billing_currency TABLE PROJECT_ID
gcp_billing_currency() {
  local table="$1"
  local project_id="$2"
  _bq_query "
    SELECT DISTINCT currency
    FROM \`${table}\`
    WHERE project.id = '${project_id}'
    LIMIT 1
  "
}

# Credit program detection (MANDATORY second call)
# Usage: gcp_billing_credits TABLE PROJECT_ID
gcp_billing_credits() {
  local table="$1"
  local project_id="$2"
  _bq_query "
    SELECT
      c.type AS credit_type,
      c.full_name AS credit_name,
      COUNT(*) AS line_items,
      SUM(CAST(c.amount AS NUMERIC)) AS total_credit_amount,
      SAFE_DIVIDE(
        SUM(CAST(c.amount AS NUMERIC)),
        NULLIF((SELECT SUM(CAST(cost AS NUMERIC)) FROM \`${table}\`
                WHERE project.id = '${project_id}'
                  AND cost_type = 'regular'
                  AND DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)), 0)
      ) AS credit_coverage_ratio
    FROM \`${table}\`, UNNEST(credits) AS c
    WHERE DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
      AND project.id = '${project_id}'
    GROUP BY 1, 2
    ORDER BY total_credit_amount ASC
  "
}

# Top services by net cost
# Usage: gcp_billing_summary TABLE PROJECT_ID [--days N]
gcp_billing_summary() {
  local table="$1"
  local project_id="$2"
  shift 2
  local days=30
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --days) days="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  _bq_query "
    SELECT
      service.description AS service,
      SUM(CAST(cost AS NUMERIC)) AS gross_cost,
      SUM(IFNULL((SELECT SUM(CAST(c.amount AS NUMERIC)) FROM UNNEST(credits) c), 0)) AS total_credits,
      SUM(CAST(cost AS NUMERIC))
        + SUM(IFNULL((SELECT SUM(CAST(c.amount AS NUMERIC)) FROM UNNEST(credits) c), 0)) AS net_cost,
      (SELECT DISTINCT currency FROM \`${table}\` WHERE project.id = '${project_id}' LIMIT 1) AS currency
    FROM \`${table}\`
    WHERE project.id = '${project_id}'
      AND cost_type = 'regular'
      AND DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL ${days} DAY)
    GROUP BY 1
    ORDER BY net_cost DESC
    LIMIT 20
  "
}

# Daily net cost trend
# Usage: gcp_billing_trend TABLE PROJECT_ID [--days N]
gcp_billing_trend() {
  local table="$1"
  local project_id="$2"
  shift 2
  local days=30
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --days) days="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  _bq_query "
    SELECT
      DATE(usage_start_time) AS usage_date,
      SUM(CAST(cost AS NUMERIC)) AS gross_cost,
      SUM(IFNULL((SELECT SUM(CAST(c.amount AS NUMERIC)) FROM UNNEST(credits) c), 0)) AS total_credits,
      SUM(CAST(cost AS NUMERIC))
        + SUM(IFNULL((SELECT SUM(CAST(c.amount AS NUMERIC)) FROM UNNEST(credits) c), 0)) AS net_cost
    FROM \`${table}\`
    WHERE project.id = '${project_id}'
      AND cost_type = 'regular'
      AND DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL ${days} DAY)
    GROUP BY 1
    ORDER BY 1 ASC
  "
}

# Z-score anomaly detection on net cost
# Usage: gcp_billing_anomalies TABLE PROJECT_ID
gcp_billing_anomalies() {
  local table="$1"
  local project_id="$2"
  _bq_query "
    WITH daily AS (
      SELECT
        DATE(usage_start_time) AS usage_date,
        SUM(CAST(cost AS NUMERIC))
          + SUM(IFNULL((SELECT SUM(CAST(c.amount AS NUMERIC)) FROM UNNEST(credits) c), 0)) AS net_cost
      FROM \`${table}\`
      WHERE project.id = '${project_id}'
        AND cost_type = 'regular'
        AND DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
        AND DATE(usage_start_time) < CURRENT_DATE()
      GROUP BY 1
    ),
    stats AS (
      SELECT
        AVG(net_cost) AS avg_cost,
        STDDEV(net_cost) AS stddev_cost
      FROM daily
    )
    SELECT
      d.usage_date,
      ROUND(d.net_cost, 2) AS net_cost,
      ROUND(s.avg_cost, 2) AS avg_cost,
      ROUND(SAFE_DIVIDE(d.net_cost - s.avg_cost, NULLIF(s.stddev_cost, 0)), 2) AS z_score
    FROM daily d
    CROSS JOIN stats s
    WHERE ABS(SAFE_DIVIDE(d.net_cost - s.avg_cost, NULLIF(s.stddev_cost, 0))) > 2.0
    ORDER BY d.usage_date DESC
  "
}

# Resource-level breakdown (requires detailed export table)
# Usage: gcp_billing_by_resource TABLE PROJECT_ID [--days N]
gcp_billing_by_resource() {
  local table="$1"
  local project_id="$2"
  shift 2
  local days=7
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --days) days="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  _bq_query "
    SELECT
      service.description AS service,
      resource.name AS resource_name,
      sku.description AS sku,
      SUM(CAST(cost AS NUMERIC))
        + SUM(IFNULL((SELECT SUM(CAST(c.amount AS NUMERIC)) FROM UNNEST(credits) c), 0)) AS net_cost
    FROM \`${table}\`
    WHERE project.id = '${project_id}'
      AND cost_type = 'regular'
      AND DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL ${days} DAY)
    GROUP BY 1, 2, 3
    HAVING net_cost > 0.01
    ORDER BY net_cost DESC
    LIMIT 30
  "
}

# SKU-level breakdown
# Usage: gcp_billing_by_sku TABLE PROJECT_ID [--days N]
gcp_billing_by_sku() {
  local table="$1"
  local project_id="$2"
  shift 2
  local days=7
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --days) days="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  _bq_query "
    SELECT
      service.description AS service,
      sku.description AS sku,
      SUM(CAST(cost AS NUMERIC)) AS gross_cost,
      SUM(IFNULL((SELECT SUM(CAST(c.amount AS NUMERIC)) FROM UNNEST(credits) c), 0)) AS total_credits,
      SUM(CAST(cost AS NUMERIC))
        + SUM(IFNULL((SELECT SUM(CAST(c.amount AS NUMERIC)) FROM UNNEST(credits) c), 0)) AS net_cost
    FROM \`${table}\`
    WHERE project.id = '${project_id}'
      AND cost_type = 'regular'
      AND DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL ${days} DAY)
    GROUP BY 1, 2
    HAVING net_cost > 0.01
    ORDER BY net_cost DESC
    LIMIT 30
  "
}

# Invoice reconciliation
# Usage: gcp_billing_invoice TABLE PROJECT_ID [--month YYYYMM]
gcp_billing_invoice() {
  local table="$1"
  local project_id="$2"
  shift 2
  local month=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --month) month="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  local month_filter
  if [[ -n "$month" ]]; then
    month_filter="AND invoice.month = '${month}'"
  else
    month_filter="AND invoice.month = FORMAT_DATE('%Y%m', CURRENT_DATE())"
  fi
  _bq_query "
    SELECT
      invoice.month AS invoice_month,
      SUM(CASE WHEN cost_type = 'regular' THEN CAST(cost AS NUMERIC) ELSE 0 END) AS usage_cost,
      SUM(CASE WHEN cost_type = 'tax' THEN CAST(cost AS NUMERIC) ELSE 0 END) AS tax_amount,
      SUM(CASE WHEN cost_type IN ('adjustment', 'rounding_error') THEN CAST(cost AS NUMERIC) ELSE 0 END) AS adjustments,
      SUM(IFNULL((SELECT SUM(CAST(c.amount AS NUMERIC)) FROM UNNEST(credits) c), 0)) AS total_credits,
      SUM(CAST(cost AS NUMERIC))
        + SUM(IFNULL((SELECT SUM(CAST(c.amount AS NUMERIC)) FROM UNNEST(credits) c), 0)) AS net_total
    FROM \`${table}\`
    WHERE project.id = '${project_id}'
      ${month_filter}
    GROUP BY 1
    ORDER BY 1
  "
}

# Multi-project comparison (no project filter)
# Usage: gcp_billing_compare TABLE [--days N]
gcp_billing_compare() {
  local table="$1"
  shift
  local days=7
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --days) days="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  _bq_query "
    SELECT
      project.id AS project_id,
      SUM(CAST(cost AS NUMERIC)) AS gross_cost,
      SUM(IFNULL((SELECT SUM(CAST(c.amount AS NUMERIC)) FROM UNNEST(credits) c), 0)) AS total_credits,
      SUM(CAST(cost AS NUMERIC))
        + SUM(IFNULL((SELECT SUM(CAST(c.amount AS NUMERIC)) FROM UNNEST(credits) c), 0)) AS net_cost
    FROM \`${table}\`
    WHERE cost_type = 'regular'
      AND DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL ${days} DAY)
    GROUP BY 1
    ORDER BY net_cost DESC
    LIMIT 20
  "
}
