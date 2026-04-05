#!/usr/bin/env bash
set -euo pipefail

# GCP Rightsizing Helper Functions
# Source this file: source ./get_rightsizing_gcp.sh
# All functions enforce anti-hallucination rules:
#   - 14-day minimum observation window (Rule 1)
#   - E2 shared-core CPU cap handling (Rule 2)
#   - Sole-tenant detection (Rule 3)
#   - Peak AND average metrics (Rule 4)
#   - Preemptible/Spot exclusion (Rule 5)
#   - CUD/SUD disclaimers (Rule 6)
#   - Cloud SQL HA awareness (Rule 7)
#   - Parallel execution for all monitoring queries

export CLOUDSDK_CORE_DISABLE_PROMPTS=1

_parse_rs_args() {
  local days=14
  local project=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --days) days="$2"; shift 2 ;;
      --project) project="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  # Enforce minimum 14-day window (Rule 1)
  if [[ "$days" -lt 14 ]]; then
    days=14
  fi
  echo "${days}|${project}"
}

_rs_project_flag() {
  local project="$1"
  if [[ -n "$project" ]]; then
    echo "--project=${project}"
  fi
}

# E2 shared-core CPU cap reference (Rule 2)
_e2_shared_core_cap() {
  local machine="$1"
  case "$machine" in
    e2-micro)  echo "0.125" ;;  # 12.5%
    e2-small)  echo "0.250" ;;  # 25%
    e2-medium) echo "0.500" ;;  # 50%
    *) echo "" ;;
  esac
}

# SUD eligibility check (Rule 10)
_is_sud_eligible() {
  local machine="$1"
  local family
  family=$(echo "$machine" | cut -d'-' -f1)
  case "$family" in
    n1|n2|n2d|c2|m1|m2) return 0 ;;  # SUD eligible
    *) return 1 ;;  # Not SUD eligible (e2, t2d, c3, m3, etc.)
  esac
}

# Get approximate monthly cost for a machine type
_approx_monthly_cost() {
  local machine="$1"
  case "$machine" in
    e2-micro)       echo "6.11" ;;
    e2-small)       echo "12.23" ;;
    e2-medium)      echo "24.46" ;;
    e2-standard-2)  echo "48.92" ;;
    e2-standard-4)  echo "97.83" ;;
    e2-standard-8)  echo "195.67" ;;
    e2-standard-16) echo "391.34" ;;
    e2-standard-32) echo "782.67" ;;
    e2-highmem-2)   echo "65.98" ;;
    e2-highmem-4)   echo "131.96" ;;
    e2-highmem-8)   echo "263.92" ;;
    e2-highcpu-2)   echo "36.12" ;;
    e2-highcpu-4)   echo "72.24" ;;
    e2-highcpu-8)   echo "144.48" ;;
    n1-standard-1)  echo "24.27" ;;
    n1-standard-2)  echo "48.55" ;;
    n1-standard-4)  echo "97.09" ;;
    n1-standard-8)  echo "194.18" ;;
    n2-standard-2)  echo "56.82" ;;
    n2-standard-4)  echo "113.63" ;;
    n2-standard-8)  echo "227.26" ;;
    n2-standard-16) echo "454.52" ;;
    c2-standard-4)  echo "123.84" ;;
    c2-standard-8)  echo "247.67" ;;
    c3-standard-4)  echo "120.37" ;;
    c3-standard-8)  echo "240.74" ;;
    *) echo "0" ;;
  esac
}

# Get the next size down for a machine type
_downsize_target() {
  local machine="$1"
  case "$machine" in
    e2-standard-32) echo "e2-standard-16" ;;
    e2-standard-16) echo "e2-standard-8" ;;
    e2-standard-8)  echo "e2-standard-4" ;;
    e2-standard-4)  echo "e2-standard-2" ;;
    e2-highmem-8)   echo "e2-highmem-4" ;;
    e2-highmem-4)   echo "e2-highmem-2" ;;
    e2-highcpu-8)   echo "e2-highcpu-4" ;;
    e2-highcpu-4)   echo "e2-highcpu-2" ;;
    n1-standard-8)  echo "n1-standard-4" ;;
    n1-standard-4)  echo "n1-standard-2" ;;
    n1-standard-2)  echo "n1-standard-1" ;;
    n2-standard-16) echo "n2-standard-8" ;;
    n2-standard-8)  echo "n2-standard-4" ;;
    n2-standard-4)  echo "n2-standard-2" ;;
    c2-standard-8)  echo "c2-standard-4" ;;
    c3-standard-8)  echo "c3-standard-4" ;;
    *) echo "" ;;
  esac
}

# Compute Engine VM CPU analysis
# Usage: gcp_rightsizing_vms [--days N] [--project PROJECT]
gcp_rightsizing_vms() {
  local args
  args=$(_parse_rs_args "$@")
  local days="${args%%|*}"
  local project="${args#*|}"
  local pflag
  pflag=$(_rs_project_flag "$project")
  local proj_id
  proj_id="${project:-$(gcloud config get-value project 2>/dev/null)}"

  local end_time start_time
  end_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  start_time=$(date -u -v-${days}d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
    date -u -d "${days} days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)

  # Get running instances (exclude TERMINATED)
  local instances
  instances=$(gcloud compute instances list --filter="status:RUNNING" \
    --format="value(name,zone.scope(zones),machineType.scope(machineTypes),scheduling.preemptible,labels,nodeAffinities)" \
    $pflag 2>/dev/null || echo "")

  if [[ -z "$instances" ]]; then
    echo "NO_RUNNING_VMS"
    return 0
  fi

  echo "RIGHTSIZING_VMS_START"
  echo "observation_window\t${days} days"
  local tmpdir
  tmpdir=$(mktemp -d)

  while IFS=$'\t' read -r name zone machine_type preemptible labels node_affinities; do
    {
      # Rule 5: Skip preemptible/spot VMs
      if [[ "$preemptible" == "True" ]]; then
        printf "PREEMPTIBLE_SKIP\t%s\t%s\t%s\tskipped (already cost-optimized)\n" \
          "$name" "$zone" "$machine_type"
        exit 0
      fi

      # Rule 3: Flag sole-tenant VMs separately
      if [[ -n "$node_affinities" ]]; then
        printf "SOLE_TENANT\t%s\t%s\t%s\tdeferred (optimize node fill rate instead)\n" \
          "$name" "$zone" "$machine_type"
        exit 0
      fi

      # Fetch avg and max CPU in parallel (Rule 4)
      local avg_cpu_file="${tmpdir}/${name}_avg_cpu"
      local max_cpu_file="${tmpdir}/${name}_max_cpu"

      gcloud monitoring time-series list \
        --filter="resource.labels.instance_id='$name' AND metric.type='compute.googleapis.com/instance/cpu/utilization'" \
        --interval.start-time="$start_time" --interval.end-time="$end_time" \
        --aggregation.alignment-period=3600s \
        --aggregation.per-series-aligner=ALIGN_MEAN \
        --format="value(points[].value.doubleValue)" \
        --project="$proj_id" 2>/dev/null | awk '{sum+=$1; count++} END {if(count>0) printf "%.4f", sum/count; else print "N/A"}' > "$avg_cpu_file" &

      gcloud monitoring time-series list \
        --filter="resource.labels.instance_id='$name' AND metric.type='compute.googleapis.com/instance/cpu/utilization'" \
        --interval.start-time="$start_time" --interval.end-time="$end_time" \
        --aggregation.alignment-period=3600s \
        --aggregation.per-series-aligner=ALIGN_MAX \
        --format="value(points[].value.doubleValue)" \
        --project="$proj_id" 2>/dev/null | awk '{if($1>max) max=$1} END {if(max) printf "%.4f", max; else print "N/A"}' > "$max_cpu_file" &

      wait

      local avg_cpu max_cpu
      avg_cpu=$(cat "$avg_cpu_file" 2>/dev/null || echo "N/A")
      max_cpu=$(cat "$max_cpu_file" 2>/dev/null || echo "N/A")

      # Rule 2: E2 shared-core CPU cap handling
      local cpu_cap
      cpu_cap=$(_e2_shared_core_cap "$machine_type")
      local shared_core_note=""
      if [[ -n "$cpu_cap" ]]; then
        if [[ "$avg_cpu" != "N/A" ]]; then
          local cap_pct
          cap_pct=$(awk "BEGIN {printf \"%.1f\", ($avg_cpu / $cpu_cap) * 100}")
          shared_core_note="shared_core_cap:${cpu_cap}\tcap_usage:${cap_pct}%"
        fi
      fi

      # SUD eligibility (Rule 10 / Rule 6)
      local sud_note="NOT_SUD_ELIGIBLE"
      if _is_sud_eligible "$machine_type"; then
        sud_note="SUD_ELIGIBLE(up to 30%)"
      fi

      # Determine recommendation based on avg + max (Rule 4)
      local recommendation="RIGHT_SIZED"
      local current_cost downsize_target savings_est
      current_cost=$(_approx_monthly_cost "$machine_type")
      downsize_target=$(_downsize_target "$machine_type")

      if [[ "$avg_cpu" != "N/A" && "$max_cpu" != "N/A" && -z "$cpu_cap" ]]; then
        local is_underutil
        is_underutil=$(awk "BEGIN {print ($avg_cpu < 0.10 && $max_cpu < 0.40) ? 1 : 0}")
        if [[ "$is_underutil" == "1" && -n "$downsize_target" ]]; then
          local target_cost
          target_cost=$(_approx_monthly_cost "$downsize_target")
          savings_est=$(awk "BEGIN {printf \"%.2f\", $current_cost - $target_cost}")
          recommendation="DOWNSIZE_CANDIDATE\ttarget:${downsize_target}\test_savings:${savings_est} USD/mo (on-demand; CUD/SUD may apply)"
        fi
        local is_bursty
        is_bursty=$(awk "BEGIN {print ($avg_cpu < 0.15 && $max_cpu > 0.80) ? 1 : 0}")
        if [[ "$is_bursty" == "1" ]]; then
          recommendation="BURSTY_WORKLOAD\tdo_NOT_downsize (avg low but peak high)"
        fi
      fi

      if [[ -n "$shared_core_note" ]]; then
        printf "VM\t%s\t%s\t%s\tavg_cpu:%s\tmax_cpu:%s\t%s\t%s\t%s\t%s USD/mo\n" \
          "$name" "$zone" "$machine_type" "$avg_cpu" "$max_cpu" "$shared_core_note" "$sud_note" "$recommendation" "$current_cost"
      else
        printf "VM\t%s\t%s\t%s\tavg_cpu:%s\tmax_cpu:%s\t%s\t%s\t%s USD/mo\n" \
          "$name" "$zone" "$machine_type" "$avg_cpu" "$max_cpu" "$sud_note" "$recommendation" "$current_cost"
      fi
    } >> "${tmpdir}/results" &
  done <<< "$instances"
  wait

  if [[ -f "${tmpdir}/results" ]]; then
    cat "${tmpdir}/results"
  fi
  rm -rf "$tmpdir"
  echo "RIGHTSIZING_VMS_END"
}

# Cloud SQL CPU + connections with HA cost awareness
# Usage: gcp_rightsizing_cloudsql [--days N] [--project PROJECT]
gcp_rightsizing_cloudsql() {
  local args
  args=$(_parse_rs_args "$@")
  local days="${args%%|*}"
  local project="${args#*|}"
  local pflag
  pflag=$(_rs_project_flag "$project")
  local proj_id
  proj_id="${project:-$(gcloud config get-value project 2>/dev/null)}"

  local end_time start_time
  end_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  start_time=$(date -u -v-${days}d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
    date -u -d "${days} days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)

  local instances
  instances=$(gcloud sql instances list --filter="state:RUNNABLE" \
    --format="value(name,databaseVersion,region,settings.tier,settings.activationPolicy,settings.availabilityType,settings.dataDiskSizeGb,settings.dataDiskType)" \
    $pflag 2>/dev/null || echo "")

  if [[ -z "$instances" ]]; then
    echo "NO_CLOUDSQL_INSTANCES"
    return 0
  fi

  echo "RIGHTSIZING_CLOUDSQL_START"
  echo "observation_window\t${days} days"
  local tmpdir
  tmpdir=$(mktemp -d)

  while IFS=$'\t' read -r name db_version region tier activation_policy availability_type disk_size disk_type; do
    {
      # Skip stopped instances
      if [[ "$activation_policy" == "NEVER" ]]; then
        printf "STOPPED\t%s\t%s\t%s\tactivationPolicy=NEVER\tskipped\n" "$name" "$tier" "$region"
        exit 0
      fi

      # Fetch avg CPU, max CPU, and connections in parallel
      local avg_file="${tmpdir}/${name}_avg"
      local max_file="${tmpdir}/${name}_max"
      local conn_file="${tmpdir}/${name}_conn"

      gcloud monitoring time-series list \
        --filter="resource.type='cloudsql_database' AND resource.labels.database_id='${proj_id}:${name}' AND metric.type='cloudsql.googleapis.com/database/cpu/utilization'" \
        --interval.start-time="$start_time" --interval.end-time="$end_time" \
        --aggregation.alignment-period=3600s \
        --aggregation.per-series-aligner=ALIGN_MEAN \
        --format="value(points[].value.doubleValue)" \
        --project="$proj_id" 2>/dev/null | awk '{sum+=$1; count++} END {if(count>0) printf "%.4f", sum/count; else print "N/A"}' > "$avg_file" &

      gcloud monitoring time-series list \
        --filter="resource.type='cloudsql_database' AND resource.labels.database_id='${proj_id}:${name}' AND metric.type='cloudsql.googleapis.com/database/cpu/utilization'" \
        --interval.start-time="$start_time" --interval.end-time="$end_time" \
        --aggregation.alignment-period=3600s \
        --aggregation.per-series-aligner=ALIGN_MAX \
        --format="value(points[].value.doubleValue)" \
        --project="$proj_id" 2>/dev/null | awk '{if($1>max) max=$1} END {if(max) printf "%.4f", max; else print "N/A"}' > "$max_file" &

      gcloud monitoring time-series list \
        --filter="resource.type='cloudsql_database' AND resource.labels.database_id='${proj_id}:${name}' AND metric.type='cloudsql.googleapis.com/database/network/connections'" \
        --interval.start-time="$start_time" --interval.end-time="$end_time" \
        --aggregation.alignment-period=3600s \
        --aggregation.per-series-aligner=ALIGN_MEAN \
        --format="value(points[].value.int64Value)" \
        --project="$proj_id" 2>/dev/null | awk '{sum+=$1; count++} END {if(count>0) printf "%.0f", sum/count; else print "N/A"}' > "$conn_file" &

      wait

      local avg_cpu max_cpu avg_conn
      avg_cpu=$(cat "$avg_file" 2>/dev/null || echo "N/A")
      max_cpu=$(cat "$max_file" 2>/dev/null || echo "N/A")
      avg_conn=$(cat "$conn_file" 2>/dev/null || echo "N/A")

      # Rule 7: HA doubles compute cost
      local ha_note="ZONAL"
      local cost_multiplier=1
      if [[ "$availability_type" == "REGIONAL" ]]; then
        ha_note="HA(2x compute)"
        cost_multiplier=2
      fi

      # Approximate tier cost
      local tier_monthly="0"
      case "$tier" in
        db-f1-micro)        tier_monthly="10.80" ;;
        db-g1-small)        tier_monthly="36.00" ;;
        db-custom-1-3840)   tier_monthly=$(awk "BEGIN {printf \"%.2f\", 49.64 * $cost_multiplier}") ;;
        db-custom-2-7680)   tier_monthly=$(awk "BEGIN {printf \"%.2f\", 99.29 * $cost_multiplier}") ;;
        db-custom-4-15360)  tier_monthly=$(awk "BEGIN {printf \"%.2f\", 198.58 * $cost_multiplier}") ;;
        db-custom-8-30720)  tier_monthly=$(awk "BEGIN {printf \"%.2f\", 397.15 * $cost_multiplier}") ;;
        db-custom-16-61440) tier_monthly=$(awk "BEGIN {printf \"%.2f\", 794.30 * $cost_multiplier}") ;;
        db-n1-standard-1)   tier_monthly=$(awk "BEGIN {printf \"%.2f\", 49.64 * $cost_multiplier}") ;;
        db-n1-standard-2)   tier_monthly=$(awk "BEGIN {printf \"%.2f\", 99.29 * $cost_multiplier}") ;;
        db-n1-standard-4)   tier_monthly=$(awk "BEGIN {printf \"%.2f\", 198.58 * $cost_multiplier}") ;;
        db-n1-standard-8)   tier_monthly=$(awk "BEGIN {printf \"%.2f\", 397.15 * $cost_multiplier}") ;;
        *) tier_monthly="0" ;;
      esac

      # Storage cost
      local storage_cost
      case "$disk_type" in
        PD_SSD) storage_cost=$(awk "BEGIN {printf \"%.2f\", 0.17 * ${disk_size:-0}}") ;;
        PD_HDD) storage_cost=$(awk "BEGIN {printf \"%.2f\", 0.09 * ${disk_size:-0}}") ;;
        *)      storage_cost=$(awk "BEGIN {printf \"%.2f\", 0.17 * ${disk_size:-0}}") ;;
      esac

      printf "CLOUDSQL\t%s\t%s\t%s\t%s\tavg_cpu:%s\tmax_cpu:%s\tavg_connections:%s\t%s\tcompute:%s USD/mo\tstorage:%s USD/mo\tCUD/SUD caveat applies\n" \
        "$name" "$tier" "$region" "$db_version" "$avg_cpu" "$max_cpu" "$avg_conn" "$ha_note" "$tier_monthly" "$storage_cost"
    } >> "${tmpdir}/results" &
  done <<< "$instances"
  wait

  if [[ -f "${tmpdir}/results" ]]; then
    cat "${tmpdir}/results"
  fi
  rm -rf "$tmpdir"
  echo "RIGHTSIZING_CLOUDSQL_END"
}

# Persistent Disk IOPS/throughput utilization
# Usage: gcp_rightsizing_disks [--days N] [--project PROJECT]
gcp_rightsizing_disks() {
  local args
  args=$(_parse_rs_args "$@")
  local days="${args%%|*}"
  local project="${args#*|}"
  local pflag
  pflag=$(_rs_project_flag "$project")
  local proj_id
  proj_id="${project:-$(gcloud config get-value project 2>/dev/null)}"

  local end_time start_time
  end_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  start_time=$(date -u -v-${days}d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
    date -u -d "${days} days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)

  # Only analyze attached disks (unattached handled by idle-resources skill)
  local disks
  disks=$(gcloud compute disks list --filter="users:*" \
    --format="value(name,zone.scope(zones),sizeGb,type.scope(diskTypes),users[0].scope(instances))" \
    $pflag 2>/dev/null || echo "")

  if [[ -z "$disks" ]]; then
    echo "NO_ATTACHED_DISKS"
    return 0
  fi

  echo "RIGHTSIZING_DISKS_START"
  echo "observation_window\t${days} days"
  local tmpdir
  tmpdir=$(mktemp -d)

  while IFS=$'\t' read -r name zone size_gb disk_type attached_instance; do
    {
      # Calculate baseline IOPS for disk type (Rule 8)
      local baseline_iops per_gb_mo
      case "$disk_type" in
        pd-standard)
          baseline_iops=$(awk "BEGIN {printf \"%.0f\", 0.75 * ${size_gb}}")
          per_gb_mo="0.04"
          ;;
        pd-balanced)
          baseline_iops=$(awk "BEGIN {printf \"%.0f\", 6 * ${size_gb}}")
          per_gb_mo="0.10"
          ;;
        pd-ssd)
          baseline_iops=$(awk "BEGIN {printf \"%.0f\", 30 * ${size_gb}}")
          per_gb_mo="0.17"
          ;;
        pd-extreme)
          baseline_iops="configurable"
          per_gb_mo="0.125"
          ;;
        *)
          baseline_iops="unknown"
          per_gb_mo="0.10"
          ;;
      esac

      # Fetch read and write IOPS in parallel
      local read_file="${tmpdir}/${name}_read"
      local write_file="${tmpdir}/${name}_write"

      gcloud monitoring time-series list \
        --filter="resource.labels.instance_id='$attached_instance' AND metric.type='compute.googleapis.com/instance/disk/read_ops_count' AND metric.labels.device_name='$name'" \
        --interval.start-time="$start_time" --interval.end-time="$end_time" \
        --aggregation.alignment-period=3600s \
        --aggregation.per-series-aligner=ALIGN_RATE \
        --format="value(points[].value.doubleValue)" \
        --project="$proj_id" 2>/dev/null | awk '{sum+=$1; count++} END {if(count>0) printf "%.1f", sum/count; else print "N/A"}' > "$read_file" &

      gcloud monitoring time-series list \
        --filter="resource.labels.instance_id='$attached_instance' AND metric.type='compute.googleapis.com/instance/disk/write_ops_count' AND metric.labels.device_name='$name'" \
        --interval.start-time="$start_time" --interval.end-time="$end_time" \
        --aggregation.alignment-period=3600s \
        --aggregation.per-series-aligner=ALIGN_RATE \
        --format="value(points[].value.doubleValue)" \
        --project="$proj_id" 2>/dev/null | awk '{sum+=$1; count++} END {if(count>0) printf "%.1f", sum/count; else print "N/A"}' > "$write_file" &

      wait

      local avg_read_iops avg_write_iops
      avg_read_iops=$(cat "$read_file" 2>/dev/null || echo "N/A")
      avg_write_iops=$(cat "$write_file" 2>/dev/null || echo "N/A")

      local monthly_cost
      monthly_cost=$(awk "BEGIN {printf \"%.2f\", $per_gb_mo * ${size_gb}}")

      # Determine utilization vs baseline (Rule 8)
      local iops_note="N/A"
      if [[ "$avg_read_iops" != "N/A" && "$avg_write_iops" != "N/A" && "$baseline_iops" != "configurable" && "$baseline_iops" != "unknown" ]]; then
        local total_iops
        total_iops=$(awk "BEGIN {printf \"%.1f\", $avg_read_iops + $avg_write_iops}")
        local iops_pct
        iops_pct=$(awk "BEGIN {if($baseline_iops > 0) printf \"%.1f\", ($total_iops / $baseline_iops) * 100; else print \"N/A\"}")
        iops_note="total_avg_iops:${total_iops}\tbaseline:${baseline_iops}\tutilization:${iops_pct}%"

        # Suggest type migration if pd-standard is near cap
        if [[ "$disk_type" == "pd-standard" ]]; then
          local near_cap
          near_cap=$(awk "BEGIN {print ($total_iops / $baseline_iops > 0.80) ? 1 : 0}" 2>/dev/null || echo "0")
          if [[ "$near_cap" == "1" ]]; then
            local balanced_cost
            balanced_cost=$(awk "BEGIN {printf \"%.2f\", 0.10 * ${size_gb}}")
            local cost_delta
            cost_delta=$(awk "BEGIN {printf \"%.2f\", $balanced_cost - $monthly_cost}")
            iops_note="${iops_note}\tUPGRADE_CANDIDATE:pd-balanced (6x IOPS, +${cost_delta} USD/mo)"
          fi
        fi

        # Suggest downgrade if pd-ssd has low utilization
        if [[ "$disk_type" == "pd-ssd" ]]; then
          local low_util
          low_util=$(awk "BEGIN {print ($total_iops / $baseline_iops < 0.10) ? 1 : 0}" 2>/dev/null || echo "0")
          if [[ "$low_util" == "1" ]]; then
            local balanced_cost
            balanced_cost=$(awk "BEGIN {printf \"%.2f\", 0.10 * ${size_gb}}")
            local savings
            savings=$(awk "BEGIN {printf \"%.2f\", $monthly_cost - $balanced_cost}")
            iops_note="${iops_note}\tDOWNGRADE_CANDIDATE:pd-balanced (saves ${savings} USD/mo)"
          fi
        fi
      fi

      printf "DISK\t%s\t%s\t%sGiB\t%s\tattached:%s\tavg_read_iops:%s\tavg_write_iops:%s\t%s\t%s USD/mo\n" \
        "$name" "$zone" "$size_gb" "$disk_type" "$attached_instance" "$avg_read_iops" "$avg_write_iops" "$iops_note" "$monthly_cost"
    } >> "${tmpdir}/results" &
  done <<< "$disks"
  wait

  if [[ -f "${tmpdir}/results" ]]; then
    cat "${tmpdir}/results"
  fi
  rm -rf "$tmpdir"
  echo "RIGHTSIZING_DISKS_END"
}

# Cloud Functions + Cloud Run memory/CPU waste detection
# Usage: gcp_rightsizing_serverless [--days N] [--project PROJECT]
gcp_rightsizing_serverless() {
  local args
  args=$(_parse_rs_args "$@")
  local days="${args%%|*}"
  local project="${args#*|}"
  local pflag
  pflag=$(_rs_project_flag "$project")
  local proj_id
  proj_id="${project:-$(gcloud config get-value project 2>/dev/null)}"

  local end_time start_time
  end_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  start_time=$(date -u -v-${days}d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
    date -u -d "${days} days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)

  echo "RIGHTSIZING_SERVERLESS_START"
  echo "observation_window\t${days} days"
  local tmpdir
  tmpdir=$(mktemp -d)

  # Check Cloud Functions and Cloud Run in parallel
  {
    # Cloud Functions (Gen 1 + Gen 2)
    local functions
    functions=$(gcloud functions list \
      --format="value(name.scope(functions),entryPoint,availableMemoryMb,status,runtime)" \
      $pflag 2>/dev/null || echo "")

    if [[ -n "$functions" ]]; then
      while IFS=$'\t' read -r fn_name entry_point mem_mb status runtime; do
        # Query peak memory usage
        local peak_mem
        peak_mem=$(gcloud monitoring time-series list \
          --filter="resource.labels.function_name='$fn_name' AND metric.type='cloudfunctions.googleapis.com/function/user_memory_bytes'" \
          --interval.start-time="$start_time" --interval.end-time="$end_time" \
          --aggregation.alignment-period=86400s \
          --aggregation.per-series-aligner=ALIGN_MAX \
          --format="value(points[].value.int64Value)" \
          --project="$proj_id" 2>/dev/null | awk '{if($1>max) max=$1} END {if(max) printf "%.0f", max/1048576; else print "N/A"}')

        # Query execution count
        local exec_count
        exec_count=$(gcloud monitoring time-series list \
          --filter="resource.labels.function_name='$fn_name' AND metric.type='cloudfunctions.googleapis.com/function/execution_count'" \
          --interval.start-time="$start_time" --interval.end-time="$end_time" \
          --aggregation.alignment-period=86400s \
          --aggregation.per-series-aligner=ALIGN_SUM \
          --format="value(points[].value.int64Value)" \
          --project="$proj_id" 2>/dev/null | awk '{sum+=$1} END {if(sum) printf "%.0f", sum; else print "0"}')

        # Rule 9: Flag waste but don't prescribe values
        local waste_note=""
        if [[ "$peak_mem" != "N/A" && -n "$mem_mb" ]]; then
          local ratio
          ratio=$(awk "BEGIN {printf \"%.1f\", ($peak_mem / $mem_mb) * 100}")
          local is_wasteful
          is_wasteful=$(awk "BEGIN {print ($peak_mem / $mem_mb < 0.25) ? 1 : 0}")
          if [[ "$is_wasteful" == "1" ]]; then
            waste_note="MEMORY_WASTE_CANDIDATE\tallocated:${mem_mb}MiB\tpeak:${peak_mem}MiB\tusage:${ratio}% (benchmark required before reducing)"
          else
            waste_note="allocated:${mem_mb}MiB\tpeak:${peak_mem}MiB\tusage:${ratio}%"
          fi
        else
          waste_note="allocated:${mem_mb}MiB\tpeak:${peak_mem}MiB"
        fi

        printf "FUNCTION\t%s\t%s\t%s\texecutions:%s\t%s\n" \
          "$fn_name" "$runtime" "$status" "$exec_count" "$waste_note"
      done <<< "$functions"
    fi
  } >> "${tmpdir}/functions_results" &

  {
    # Cloud Run services
    local services
    services=$(gcloud run services list \
      --format="value(metadata.name,status.conditions[0].status,spec.template.spec.containers[0].resources.limits.memory,spec.template.spec.containers[0].resources.limits.cpu)" \
      $pflag 2>/dev/null || echo "")

    if [[ -n "$services" ]]; then
      while IFS=$'\t' read -r svc_name status mem_limit cpu_limit; do
        # Query peak memory utilization
        local peak_mem_util
        peak_mem_util=$(gcloud monitoring time-series list \
          --filter="resource.labels.service_name='$svc_name' AND metric.type='run.googleapis.com/container/memory/utilizations'" \
          --interval.start-time="$start_time" --interval.end-time="$end_time" \
          --aggregation.alignment-period=86400s \
          --aggregation.per-series-aligner=ALIGN_MAX \
          --format="value(points[].value.doubleValue)" \
          --project="$proj_id" 2>/dev/null | awk '{if($1>max) max=$1} END {if(max) printf "%.4f", max; else print "N/A"}')

        # Query request count
        local req_count
        req_count=$(gcloud monitoring time-series list \
          --filter="resource.labels.service_name='$svc_name' AND metric.type='run.googleapis.com/request_count'" \
          --interval.start-time="$start_time" --interval.end-time="$end_time" \
          --aggregation.alignment-period=86400s \
          --aggregation.per-series-aligner=ALIGN_SUM \
          --format="value(points[].value.int64Value)" \
          --project="$proj_id" 2>/dev/null | awk '{sum+=$1} END {if(sum) printf "%.0f", sum; else print "0"}')

        # Rule 9: Flag but don't prescribe
        local waste_note=""
        if [[ "$peak_mem_util" != "N/A" ]]; then
          local pct
          pct=$(awk "BEGIN {printf \"%.1f\", $peak_mem_util * 100}")
          local is_wasteful
          is_wasteful=$(awk "BEGIN {print ($peak_mem_util < 0.25) ? 1 : 0}")
          if [[ "$is_wasteful" == "1" ]]; then
            waste_note="MEMORY_WASTE_CANDIDATE\tmem_limit:${mem_limit}\tcpu_limit:${cpu_limit}\tpeak_util:${pct}% (benchmark required before reducing)"
          else
            waste_note="mem_limit:${mem_limit}\tcpu_limit:${cpu_limit}\tpeak_util:${pct}%"
          fi
        else
          waste_note="mem_limit:${mem_limit}\tcpu_limit:${cpu_limit}\tpeak_util:N/A"
        fi

        printf "CLOUD_RUN\t%s\t%s\trequests:%s\t%s\n" \
          "$svc_name" "$status" "$req_count" "$waste_note"
      done <<< "$services"
    fi
  } >> "${tmpdir}/run_results" &

  wait

  for f in "${tmpdir}/functions_results" "${tmpdir}/run_results"; do
    if [[ -f "$f" && -s "$f" ]]; then
      cat "$f"
    fi
  done

  local has_output=false
  for f in "${tmpdir}/functions_results" "${tmpdir}/run_results"; do
    if [[ -f "$f" && -s "$f" ]]; then
      has_output=true
      break
    fi
  done
  if [[ "$has_output" == "false" ]]; then
    echo "NO_SERVERLESS_RESOURCES"
  fi

  rm -rf "$tmpdir"
  echo "RIGHTSIZING_SERVERLESS_END"
}

# Run all rightsizing checks, unified summary
# Usage: gcp_rightsizing_summary [--days N] [--project PROJECT]
gcp_rightsizing_summary() {
  local pass_args=("$@")
  local tmpdir
  tmpdir=$(mktemp -d)

  # Run all checks in parallel
  { gcp_rightsizing_vms "${pass_args[@]}" > "${tmpdir}/vms" 2>/dev/null; } &
  { gcp_rightsizing_cloudsql "${pass_args[@]}" > "${tmpdir}/cloudsql" 2>/dev/null; } &
  { gcp_rightsizing_disks "${pass_args[@]}" > "${tmpdir}/disks" 2>/dev/null; } &
  { gcp_rightsizing_serverless "${pass_args[@]}" > "${tmpdir}/serverless" 2>/dev/null; } &
  wait

  echo "RIGHTSIZING_SUMMARY_START"
  echo "NOTE: All savings estimates are based on on-demand rates. CUD/SUD commitments may reduce actual savings."

  for section in vms cloudsql disks serverless; do
    if [[ -f "${tmpdir}/${section}" ]]; then
      cat "${tmpdir}/${section}"
    fi
  done

  # Tally downsize candidates
  local downsize_count
  downsize_count=$(cat "${tmpdir}"/* 2>/dev/null | grep -c "DOWNSIZE_CANDIDATE" || echo "0")
  local waste_count
  waste_count=$(cat "${tmpdir}"/* 2>/dev/null | grep -c "WASTE_CANDIDATE" || echo "0")
  local bursty_count
  bursty_count=$(cat "${tmpdir}"/* 2>/dev/null | grep -c "BURSTY_WORKLOAD" || echo "0")

  echo "TOTALS\tdownsize_candidates:${downsize_count}\twaste_candidates:${waste_count}\tbursty_workloads:${bursty_count}"
  echo "RIGHTSIZING_SUMMARY_END"

  rm -rf "$tmpdir"
}
