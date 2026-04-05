#!/usr/bin/env bash
set -euo pipefail

# GCP Pricing Helper Functions
# Source this file: source ./get_pricing_gcp.sh
# Returns on-demand pricing in tab-separated format (TOON).
# All prices are TAX-EXCLUSIVE.

# Machine type spec table: type -> vcpus ram_gb
_gcp_machine_specs() {
  local machine="$1"
  case "$machine" in
    e2-micro)       echo "2 1" ;;
    e2-small)       echo "2 2" ;;
    e2-medium)      echo "2 4" ;;
    e2-standard-2)  echo "2 8" ;;
    e2-standard-4)  echo "4 16" ;;
    e2-standard-8)  echo "8 32" ;;
    e2-standard-16) echo "16 64" ;;
    e2-standard-32) echo "32 128" ;;
    e2-highmem-2)   echo "2 16" ;;
    e2-highmem-4)   echo "4 32" ;;
    e2-highmem-8)   echo "8 64" ;;
    e2-highmem-16)  echo "16 128" ;;
    e2-highcpu-2)   echo "2 2" ;;
    e2-highcpu-4)   echo "4 4" ;;
    e2-highcpu-8)   echo "8 8" ;;
    e2-highcpu-16)  echo "16 16" ;;
    e2-highcpu-32)  echo "32 32" ;;
    n1-standard-1)  echo "1 3.75" ;;
    n1-standard-2)  echo "2 7.5" ;;
    n1-standard-4)  echo "4 15" ;;
    n1-standard-8)  echo "8 30" ;;
    n1-standard-16) echo "16 60" ;;
    n1-standard-32) echo "32 120" ;;
    n1-highmem-2)   echo "2 13" ;;
    n1-highmem-4)   echo "4 26" ;;
    n1-highmem-8)   echo "8 52" ;;
    n1-highcpu-2)   echo "2 1.8" ;;
    n1-highcpu-4)   echo "4 3.6" ;;
    n1-highcpu-8)   echo "8 7.2" ;;
    n2-standard-2)  echo "2 8" ;;
    n2-standard-4)  echo "4 16" ;;
    n2-standard-8)  echo "8 32" ;;
    n2-standard-16) echo "16 64" ;;
    n2-standard-32) echo "32 128" ;;
    n2-highmem-2)   echo "2 16" ;;
    n2-highmem-4)   echo "4 32" ;;
    n2-highmem-8)   echo "8 64" ;;
    n2-highcpu-2)   echo "2 2" ;;
    n2-highcpu-4)   echo "4 4" ;;
    n2-highcpu-8)   echo "8 8" ;;
    c2-standard-4)  echo "4 16" ;;
    c2-standard-8)  echo "8 32" ;;
    c2-standard-16) echo "16 64" ;;
    c2-standard-30) echo "30 120" ;;
    c2-standard-60) echo "60 240" ;;
    c3-standard-4)  echo "4 16" ;;
    c3-standard-8)  echo "8 32" ;;
    c3-standard-22) echo "22 88" ;;
    c3-standard-44) echo "44 176" ;;
    *) echo "" ;;
  esac
}

# Query GCP Pricing API for a specific SKU description pattern
# Returns nanos pricing from the Cloud Billing Catalog
_query_pricing_api() {
  local service_id="$1"
  local sku_pattern="$2"
  local region="$3"

  # Use gcloud to list SKUs and filter by description + region
  gcloud billing skus list --service="$service_id" \
    --filter="description~'${sku_pattern}' AND serviceRegions:${region}" \
    --format="value(description,pricingInfo[0].pricingExpression.tieredRates[0].unitPrice.nanos)" \
    --limit=5 2>/dev/null || echo ""
}

# Get Compute Engine pricing by querying Core and Ram SKUs
_get_compute_pricing() {
  local machine="$1"
  local region="$2"
  local specs
  specs=$(_gcp_machine_specs "$machine")

  if [[ -z "$specs" ]]; then
    echo "ERROR: Unknown machine type $machine"
    return 1
  fi

  local vcpus ram_gb
  read -r vcpus ram_gb <<< "$specs"

  local family
  family=$(echo "$machine" | cut -d'-' -f1)

  # Map family to SKU description prefix
  local sku_prefix
  case "$family" in
    e2) sku_prefix="E2" ;;
    n1) sku_prefix="N1" ;;
    n2) sku_prefix="N2" ;;
    c2) sku_prefix="Compute optimized" ;;
    c3) sku_prefix="C3" ;;
    *) sku_prefix="$family" ;;
  esac

  # Service ID for Compute Engine
  local ce_service="6F81-5844-456A"

  # Fetch Core and Ram pricing in parallel
  local core_result ram_result
  local tmpdir
  tmpdir=$(mktemp -d)

  {
    _query_pricing_api "$ce_service" "${sku_prefix} Instance Core" "$region" > "${tmpdir}/core" 2>/dev/null
  } &
  {
    _query_pricing_api "$ce_service" "${sku_prefix} Instance Ram" "$region" > "${tmpdir}/ram" 2>/dev/null
  } &
  wait

  core_result=$(head -1 "${tmpdir}/core" 2>/dev/null || echo "")
  ram_result=$(head -1 "${tmpdir}/ram" 2>/dev/null || echo "")
  rm -rf "$tmpdir"

  # Extract nanos (price per unit per hour)
  local core_nanos ram_nanos
  core_nanos=$(echo "$core_result" | awk -F'\t' '{print $NF}')
  ram_nanos=$(echo "$ram_result" | awk -F'\t' '{print $NF}')

  if [[ -z "$core_nanos" || -z "$ram_nanos" ]]; then
    # Fallback to approximate pricing table
    _get_compute_pricing_fallback "$machine" "$region"
    return
  fi

  # Convert nanos to dollars per hour
  local core_hourly ram_hourly total_hourly total_monthly
  core_hourly=$(awk "BEGIN {printf \"%.6f\", ($core_nanos / 1000000000) * $vcpus}")
  ram_hourly=$(awk "BEGIN {printf \"%.6f\", ($ram_nanos / 1000000000) * $ram_gb}")
  total_hourly=$(awk "BEGIN {printf \"%.6f\", $core_hourly + $ram_hourly}")
  total_monthly=$(awk "BEGIN {printf \"%.2f\", $total_hourly * 730}")

  printf "%s\t%s\t%s vCPU\t%s GB RAM\t%s USD/hr\t%s USD/mo\n" \
    "$machine" "$region" "$vcpus" "$ram_gb" "$total_hourly" "$total_monthly"
}

# Fallback pricing table for when API is unavailable
_get_compute_pricing_fallback() {
  local machine="$1"
  local region="$2"

  # Approximate on-demand hourly rates (us-central1 baseline)
  local hourly
  case "$machine" in
    e2-micro)       hourly="0.00838" ;;
    e2-small)       hourly="0.01675" ;;
    e2-medium)      hourly="0.03351" ;;
    e2-standard-2)  hourly="0.06701" ;;
    e2-standard-4)  hourly="0.13402" ;;
    e2-standard-8)  hourly="0.26805" ;;
    e2-standard-16) hourly="0.53609" ;;
    e2-standard-32) hourly="1.07219" ;;
    e2-highmem-2)   hourly="0.09041" ;;
    e2-highmem-4)   hourly="0.18082" ;;
    e2-highmem-8)   hourly="0.36164" ;;
    e2-highcpu-2)   hourly="0.04948" ;;
    e2-highcpu-4)   hourly="0.09896" ;;
    e2-highcpu-8)   hourly="0.19792" ;;
    n1-standard-1)  hourly="0.04749" ;;
    n1-standard-2)  hourly="0.09498" ;;
    n1-standard-4)  hourly="0.18995" ;;
    n1-standard-8)  hourly="0.37990" ;;
    n2-standard-2)  hourly="0.07788" ;;
    n2-standard-4)  hourly="0.15576" ;;
    n2-standard-8)  hourly="0.31152" ;;
    n2-highmem-2)   hourly="0.10480" ;;
    n2-highmem-4)   hourly="0.20960" ;;
    n2-highcpu-2)   hourly="0.05778" ;;
    n2-highcpu-4)   hourly="0.11556" ;;
    c2-standard-4)  hourly="0.16964" ;;
    c2-standard-8)  hourly="0.33928" ;;
    c2-standard-16) hourly="0.67856" ;;
    c3-standard-4)  hourly="0.16489" ;;
    c3-standard-8)  hourly="0.32978" ;;
    *) echo "ERROR: Unknown machine type $machine"; return 1 ;;
  esac

  local specs
  specs=$(_gcp_machine_specs "$machine")
  local vcpus ram_gb
  read -r vcpus ram_gb <<< "$specs"

  local monthly
  monthly=$(awk "BEGIN {printf \"%.2f\", $hourly * 730}")
  printf "%s\t%s\t%s vCPU\t%s GB RAM\t%s USD/hr\t%s USD/mo\n" \
    "$machine" "$region" "$vcpus" "$ram_gb" "$hourly" "$monthly"
}

# Get Cloud SQL pricing
_get_cloudsql_pricing() {
  local resource="$1"
  local region="$2"

  # Strip cloudsql- prefix if present
  local tier="${resource#cloudsql-}"

  local monthly
  case "$tier" in
    db-f1-micro)         monthly="10.80" ;;
    db-g1-small)         monthly="36.00" ;;
    db-custom-1-3840)    monthly="49.64" ;;
    db-custom-2-7680)    monthly="99.29" ;;
    db-custom-4-15360)   monthly="198.58" ;;
    db-custom-8-30720)   monthly="397.15" ;;
    db-custom-16-61440)  monthly="794.30" ;;
    db-n1-standard-1)    monthly="49.64" ;;
    db-n1-standard-2)    monthly="99.29" ;;
    db-n1-standard-4)    monthly="198.58" ;;
    db-n1-standard-8)    monthly="397.15" ;;
    db-n1-standard-16)   monthly="794.30" ;;
    db-n1-highmem-2)     monthly="130.41" ;;
    db-n1-highmem-4)     monthly="260.83" ;;
    db-n1-highmem-8)     monthly="521.65" ;;
    *) echo "ERROR: Unknown Cloud SQL tier $tier"; return 1 ;;
  esac

  local hourly
  hourly=$(awk "BEGIN {printf \"%.4f\", $monthly / 730}")
  printf "%s\t%s\t%s USD/hr\t%s USD/mo (zonal)\n" "$tier" "$region" "$hourly" "$monthly"
}

# Get GCS pricing
_get_gcs_pricing() {
  local resource="$1"
  local region="$2"

  local class="${resource#gcs-}"
  local per_gb_mo
  case "$class" in
    standard) per_gb_mo="0.020" ;;
    nearline) per_gb_mo="0.010" ;;
    coldline) per_gb_mo="0.004" ;;
    archive)  per_gb_mo="0.0012" ;;
    *) echo "ERROR: Unknown GCS class $class"; return 1 ;;
  esac
  printf "%s\t%s\t%s USD/GB/mo\n" "gcs-${class}" "$region" "$per_gb_mo"
}

# Get Persistent Disk pricing
_get_pd_pricing() {
  local resource="$1"
  local region="$2"

  local disk_spec="${resource#pd-}"
  # Parse format: type-sizeGB (e.g., ssd-100gb)
  local disk_type size_gb
  disk_type=$(echo "$disk_spec" | sed 's/-[0-9]*gb$//')
  size_gb=$(echo "$disk_spec" | grep -o '[0-9]*gb$' | sed 's/gb//' || echo "")

  local per_gb_mo
  case "$disk_type" in
    standard) per_gb_mo="0.04" ;;
    balanced) per_gb_mo="0.10" ;;
    ssd)      per_gb_mo="0.17" ;;
    extreme)  per_gb_mo="0.125" ;;
    *) echo "ERROR: Unknown PD type $disk_type"; return 1 ;;
  esac

  if [[ -n "$size_gb" ]]; then
    local monthly
    monthly=$(awk "BEGIN {printf \"%.2f\", $per_gb_mo * $size_gb}")
    printf "pd-%s\t%s\t%sGiB\t%s USD/GiB/mo\t%s USD/mo\n" "$disk_type" "$region" "$size_gb" "$per_gb_mo" "$monthly"
  else
    printf "pd-%s\t%s\t%s USD/GiB/mo\n" "$disk_type" "$region" "$per_gb_mo"
  fi
}

# Get Cloud Functions pricing
_get_functions_pricing() {
  local resource="$1"
  local region="$2"

  local mem="${resource#functions-}"
  # Pricing: $0.000000231 per 100ms per GB-second, $0.0000004 per invocation
  printf "functions-%s\t%s\t0.0000004 USD/invocation\t0.000000231 USD/100ms/GB-sec\n" "$mem" "$region"
}

# Get Cloud Run pricing
_get_cloudrun_pricing() {
  local resource="$1"
  local region="$2"
  # Cloud Run: $0.00002400/vCPU-sec, $0.00000250/GiB-sec
  printf "cloudrun\t%s\t0.00002400 USD/vCPU-sec\t0.00000250 USD/GiB-sec\n" "$region"
}

# Get Memorystore Redis pricing
_get_redis_pricing() {
  local resource="$1"
  local region="$2"

  local tier_size="${resource#redis-}"
  local tier size_gb
  tier=$(echo "$tier_size" | cut -d'-' -f1)
  size_gb=$(echo "$tier_size" | grep -o '[0-9]*gb$' | sed 's/gb//' || echo "1")

  local per_gb_hr
  case "$tier" in
    basic)    per_gb_hr="0.049" ;;
    standard) per_gb_hr="0.068" ;;
    *) per_gb_hr="0.049" ;;
  esac

  local monthly
  monthly=$(awk "BEGIN {printf \"%.2f\", $per_gb_hr * $size_gb * 730}")
  printf "redis-%s\t%s\t%sGB\t%s USD/GB/hr\t%s USD/mo\n" "$tier" "$region" "$size_gb" "$per_gb_hr" "$monthly"
}

# Get BigQuery pricing
_get_bq_pricing() {
  local resource="$1"
  local region="$2"
  # On-demand: $6.25 per TiB queried
  printf "bq-ondemand\t%s\t6.25 USD/TiB queried\n" "$region"
}

# Get Load Balancer pricing
_get_lb_pricing() {
  local resource="$1"
  local region="$2"
  # $0.025/hr per 5 forwarding rules, $0.008/GB data processed
  printf "lb\t%s\t0.025 USD/hr (per 5 rules)\t0.008 USD/GB processed\n" "$region"
}

# Get Cloud NAT pricing
_get_cloudnat_pricing() {
  local resource="$1"
  local region="$2"
  # $0.0014/hr per VM (capped at $0.044/hr), $0.045/GB
  printf "cloudnat\t%s\t0.0014 USD/hr/VM (cap 0.044)\t0.045 USD/GB processed\n" "$region"
}

# Get GKE pricing
_get_gke_pricing() {
  local resource="$1"
  local region="$2"
  # GKE Standard: $0.10/hr per cluster, Autopilot: per-pod pricing
  printf "gke\t%s\t0.10 USD/hr (standard cluster mgmt fee)\n" "$region"
}

# Main pricing function - auto-detects service from resource prefix
# Usage: get_gcp_cost RESOURCE REGION
# Examples:
#   get_gcp_cost e2-standard-2 asia-southeast1
#   get_gcp_cost cloudsql-db-n1-standard-2 asia-southeast1
#   get_gcp_cost gcs-standard us-central1
#   get_gcp_cost pd-ssd-100gb us-central1
get_gcp_cost() {
  local resource="$1"
  local region="${2:-us-central1}"

  case "$resource" in
    e2-*|n1-*|n2-*|c2-*|c3-*)
      _get_compute_pricing "$resource" "$region"
      ;;
    cloudsql-*|db-*)
      _get_cloudsql_pricing "$resource" "$region"
      ;;
    gcs-*)
      _get_gcs_pricing "$resource" "$region"
      ;;
    pd-*)
      _get_pd_pricing "$resource" "$region"
      ;;
    functions-*)
      _get_functions_pricing "$resource" "$region"
      ;;
    cloudrun-*)
      _get_cloudrun_pricing "$resource" "$region"
      ;;
    redis-*)
      _get_redis_pricing "$resource" "$region"
      ;;
    bq-*)
      _get_bq_pricing "$resource" "$region"
      ;;
    lb-*)
      _get_lb_pricing "$resource" "$region"
      ;;
    cloudnat-*)
      _get_cloudnat_pricing "$resource" "$region"
      ;;
    gke-*)
      _get_gke_pricing "$resource" "$region"
      ;;
    *)
      echo "ERROR: Unknown resource prefix for '$resource'. Supported: e2-/n1-/n2-/c2-/c3-/cloudsql-/db-/gcs-/pd-/functions-/cloudrun-/redis-/bq-/lb-/cloudnat-/gke-"
      return 1
      ;;
  esac
}
