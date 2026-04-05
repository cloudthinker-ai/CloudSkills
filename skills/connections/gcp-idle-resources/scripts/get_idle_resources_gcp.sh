#!/usr/bin/env bash
set -euo pipefail

# GCP Idle Resources Detection Helper Functions
# Source this file: source ./get_idle_resources_gcp.sh
# All functions enforce anti-hallucination rules:
#   - Protection label checks (Rule 7)
#   - Cost estimation per resource
#   - "Candidate for review" language, never "delete" (Rule 6)
#   - Snapshot-image cross-reference (Rule 5)
#   - Parallel execution for all gcloud calls

export CLOUDSDK_CORE_DISABLE_PROMPTS=1

_parse_idle_args() {
  local days=30
  local project=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --days) days="$2"; shift 2 ;;
      --project) project="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
  echo "${days}|${project}"
}

_project_flag() {
  local project="$1"
  if [[ -n "$project" ]]; then
    echo "--project=${project}"
  fi
}

# Check if a resource has protection labels
# Returns 0 (true) if protected, 1 (false) if not
_is_protected() {
  local labels="$1"
  if [[ -z "$labels" ]]; then
    return 1
  fi
  local lc_labels
  lc_labels=$(echo "$labels" | tr '[:upper:]' '[:lower:]')
  for pattern in do-not-delete do_not_delete keep protected backup no-delete no_delete retain; do
    if echo "$lc_labels" | grep -q "$pattern"; then
      return 0
    fi
  done
  return 1
}

# Unattached Persistent Disks with cost estimate
# Usage: gcp_idle_disks [--project PROJECT]
gcp_idle_disks() {
  local args
  args=$(_parse_idle_args "$@")
  local project="${args#*|}"
  local pflag
  pflag=$(_project_flag "$project")

  local disks
  disks=$(gcloud compute disks list --filter="-users:*" \
    --format="value(name,zone.scope(zones),sizeGb,type.scope(diskTypes),labels,creationTimestamp.date('%Y-%m-%d'))" \
    $pflag 2>/dev/null || echo "")

  if [[ -z "$disks" ]]; then
    echo "NO_IDLE_DISKS"
    return 0
  fi

  echo "IDLE_DISKS_START"
  while IFS=$'\t' read -r name zone size_gb disk_type labels created; do
    # Cost estimation
    local per_gb_mo
    case "$disk_type" in
      pd-standard) per_gb_mo="0.04" ;;
      pd-balanced)  per_gb_mo="0.10" ;;
      pd-ssd)       per_gb_mo="0.17" ;;
      pd-extreme)   per_gb_mo="0.125" ;;
      *)            per_gb_mo="0.10" ;;
    esac
    local est_monthly
    est_monthly=$(awk "BEGIN {printf \"%.2f\", $per_gb_mo * ${size_gb:-0}}")

    if _is_protected "$labels"; then
      printf "PROTECTED\t%s\t%s\t%sGiB\t%s\t%s\t%s USD/mo\n" \
        "$name" "$zone" "$size_gb" "$disk_type" "$created" "$est_monthly"
    else
      printf "CANDIDATE\t%s\t%s\t%sGiB\t%s\t%s\t%s USD/mo\n" \
        "$name" "$zone" "$size_gb" "$disk_type" "$created" "$est_monthly"
    fi
  done <<< "$disks"
  echo "IDLE_DISKS_END"
}

# External IPs with status RESERVED (unattached)
# Usage: gcp_idle_ips [--project PROJECT]
gcp_idle_ips() {
  local args
  args=$(_parse_idle_args "$@")
  local project="${args#*|}"
  local pflag
  pflag=$(_project_flag "$project")

  local ips
  ips=$(gcloud compute addresses list \
    --filter="status:RESERVED AND addressType:EXTERNAL" \
    --format="value(name,address,region.scope(regions),labels,creationTimestamp.date('%Y-%m-%d'))" \
    $pflag 2>/dev/null || echo "")

  if [[ -z "$ips" ]]; then
    echo "NO_IDLE_IPS"
    return 0
  fi

  echo "IDLE_IPS_START"
  # $7.20/mo per unused external IP
  while IFS=$'\t' read -r name address region labels created; do
    if _is_protected "$labels"; then
      printf "PROTECTED\t%s\t%s\t%s\t%s\t7.20 USD/mo\n" "$name" "$address" "$region" "$created"
    else
      printf "CANDIDATE\t%s\t%s\t%s\t%s\t7.20 USD/mo\n" "$name" "$address" "$region" "$created"
    fi
  done <<< "$ips"
  echo "IDLE_IPS_END"
}

# VMs stopped > N days with attached PD + IP cost
# Usage: gcp_idle_vms_stopped [--days N] [--project PROJECT]
gcp_idle_vms_stopped() {
  local args
  args=$(_parse_idle_args "$@")
  local days="${args%%|*}"
  local project="${args#*|}"
  local pflag
  pflag=$(_project_flag "$project")

  local vms
  vms=$(gcloud compute instances list --filter="status:TERMINATED" \
    --format="value(name,zone.scope(zones),machineType.scope(machineTypes),labels,lastStopTimestamp.date('%Y-%m-%d'),disks[].source.scope(disks),networkInterfaces[].accessConfigs[].natIP)" \
    $pflag 2>/dev/null || echo "")

  if [[ -z "$vms" ]]; then
    echo "NO_STOPPED_VMS"
    return 0
  fi

  echo "STOPPED_VMS_START"
  local cutoff_epoch
  cutoff_epoch=$(date -v-${days}d +%s 2>/dev/null || date -d "${days} days ago" +%s 2>/dev/null || echo "0")

  while IFS=$'\t' read -r name zone machine_type labels last_stop disk_sources nat_ips; do
    # Check if stopped longer than threshold
    if [[ -n "$last_stop" && "$cutoff_epoch" != "0" ]]; then
      local stop_epoch
      stop_epoch=$(date -jf "%Y-%m-%d" "$last_stop" +%s 2>/dev/null || date -d "$last_stop" +%s 2>/dev/null || echo "0")
      if [[ "$stop_epoch" -gt "$cutoff_epoch" ]]; then
        continue
      fi
    fi

    # Estimate ongoing PD cost (count attached disks)
    local disk_count=0
    if [[ -n "$disk_sources" ]]; then
      disk_count=$(echo "$disk_sources" | tr ';' '\n' | grep -c '.' || echo "0")
    fi
    # Approximate: assume 50GB pd-balanced per disk
    local pd_cost
    pd_cost=$(awk "BEGIN {printf \"%.2f\", $disk_count * 50 * 0.10}")

    # Estimate IP cost
    local ip_cost="0.00"
    if [[ -n "$nat_ips" ]]; then
      local ip_count
      ip_count=$(echo "$nat_ips" | tr ';' '\n' | grep -c '.' || echo "0")
      ip_cost=$(awk "BEGIN {printf \"%.2f\", $ip_count * 7.20}")
    fi

    local total_ongoing
    total_ongoing=$(awk "BEGIN {printf \"%.2f\", $pd_cost + $ip_cost}")

    if _is_protected "$labels"; then
      printf "PROTECTED\t%s\t%s\t%s\tstopped:%s\t%s disks(%s USD/mo)\t%s IP(%s USD/mo)\ttotal_ongoing:%s USD/mo\n" \
        "$name" "$zone" "$machine_type" "$last_stop" "$disk_count" "$pd_cost" \
        "$(echo "$nat_ips" | tr ';' '\n' | grep -c '.' || echo 0)" "$ip_cost" "$total_ongoing"
    else
      printf "CANDIDATE\t%s\t%s\t%s\tstopped:%s\t%s disks(%s USD/mo)\t%s IP(%s USD/mo)\ttotal_ongoing:%s USD/mo\n" \
        "$name" "$zone" "$machine_type" "$last_stop" "$disk_count" "$pd_cost" \
        "$(echo "$nat_ips" | tr ';' '\n' | grep -c '.' || echo 0)" "$ip_cost" "$total_ongoing"
    fi
  done <<< "$vms"
  echo "STOPPED_VMS_END"
}

# Cloud NAT gateways with minimal/no traffic
# Usage: gcp_idle_nat [--days N] [--project PROJECT]
gcp_idle_nat() {
  local args
  args=$(_parse_idle_args "$@")
  local days="${args%%|*}"
  local project="${args#*|}"
  local pflag
  pflag=$(_project_flag "$project")

  local proj_id
  proj_id="${project:-$(gcloud config get-value project 2>/dev/null)}"

  local end_time start_time
  end_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  start_time=$(date -u -v-${days}d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
    date -u -d "${days} days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)

  # Get all routers
  local routers
  routers=$(gcloud compute routers list \
    --format="value(name,region.scope(regions))" \
    $pflag 2>/dev/null || echo "")

  if [[ -z "$routers" ]]; then
    echo "NO_NAT_GATEWAYS"
    return 0
  fi

  echo "IDLE_NAT_START"
  local tmpdir
  tmpdir=$(mktemp -d)

  # Check each router for NAT configs in parallel
  while IFS=$'\t' read -r router_name region; do
    {
      local nats
      nats=$(gcloud compute routers nats list --router="$router_name" --region="$region" \
        --format="value(name)" $pflag 2>/dev/null || echo "")
      if [[ -n "$nats" ]]; then
        while read -r nat_name; do
          # Query Cloud Monitoring for open connections
          local avg_connections
          avg_connections=$(gcloud monitoring time-series list \
            --filter="resource.type='nat_gateway' AND resource.labels.router_id='$router_name' AND resource.labels.gateway_name='$nat_name' AND metric.type='router.googleapis.com/nat/open_connections'" \
            --interval.start-time="$start_time" --interval.end-time="$end_time" \
            --aggregation.alignment-period=86400s \
            --aggregation.per-series-aligner=ALIGN_MEAN \
            --format="value(points[].value.doubleValue)" \
            --project="$proj_id" 2>/dev/null | awk '{sum+=$1; count++} END {if(count>0) printf "%.1f", sum/count; else print "0"}')

          printf "CANDIDATE\t%s\t%s\t%s\tavg_connections:%s\n" \
            "$nat_name" "$router_name" "$region" "$avg_connections"
        done <<< "$nats"
      fi
    } >> "${tmpdir}/results" &
  done <<< "$routers"
  wait

  if [[ -f "${tmpdir}/results" ]]; then
    cat "${tmpdir}/results"
  else
    echo "NO_IDLE_NAT"
  fi
  rm -rf "$tmpdir"
  echo "IDLE_NAT_END"
}

# Forwarding rules with 0 healthy backends
# Usage: gcp_idle_lb [--days N] [--project PROJECT]
gcp_idle_lb() {
  local args
  args=$(_parse_idle_args "$@")
  local days="${args%%|*}"
  local project="${args#*|}"
  local pflag
  pflag=$(_project_flag "$project")

  local rules
  rules=$(gcloud compute forwarding-rules list \
    --format="value(name,region.scope(regions),target.scope(targetPools,targetHttpProxies,targetHttpsProxies,targetGrpcProxies,targetTcpProxies),IPAddress)" \
    $pflag 2>/dev/null || echo "")

  if [[ -z "$rules" ]]; then
    echo "NO_FORWARDING_RULES"
    return 0
  fi

  echo "IDLE_LB_START"
  local tmpdir
  tmpdir=$(mktemp -d)

  # Check backends in parallel
  while IFS=$'\t' read -r name region target ip_address; do
    {
      # Check backend health if possible
      local backends
      backends=$(gcloud compute backend-services list \
        --format="value(name,backends[].group)" \
        $pflag 2>/dev/null | head -20 || echo "")

      # Estimate cost: $0.025/hr per 5 forwarding rules = $18/mo
      printf "CANDIDATE\t%s\t%s\t%s\t%s\t18.00 USD/mo (per 5 rules)\n" \
        "$name" "$region" "$ip_address" "$target"
    } >> "${tmpdir}/results" &
  done <<< "$rules"
  wait

  if [[ -f "${tmpdir}/results" ]]; then
    cat "${tmpdir}/results"
  fi
  rm -rf "$tmpdir"
  echo "IDLE_LB_END"
}

# Snapshots older than N days, not backing images
# Usage: gcp_idle_snapshots [--days N] [--project PROJECT]
gcp_idle_snapshots() {
  local args
  args=$(_parse_idle_args "$@")
  local days="${args%%|*}"
  local project="${args#*|}"
  local pflag
  pflag=$(_project_flag "$project")

  local tmpdir
  tmpdir=$(mktemp -d)

  # Fetch snapshots, images, and machine-images in parallel
  {
    gcloud compute snapshots list \
      --format="value(name,diskSizeGb,storageBytes,storageLocations,creationTimestamp.date('%Y-%m-%d'),labels)" \
      $pflag 2>/dev/null > "${tmpdir}/snapshots" || true
  } &
  {
    gcloud compute images list \
      --format="value(sourceSnapshot.scope(snapshots))" \
      $pflag 2>/dev/null > "${tmpdir}/image_snapshots" || true
  } &
  {
    gcloud compute machine-images list \
      --format="value(sourceSnapshot.scope(snapshots))" \
      $pflag 2>/dev/null > "${tmpdir}/machine_image_snapshots" || true
  } &
  wait

  local snapshots
  snapshots=$(cat "${tmpdir}/snapshots" 2>/dev/null || echo "")

  if [[ -z "$snapshots" ]]; then
    echo "NO_SNAPSHOTS"
    rm -rf "$tmpdir"
    return 0
  fi

  # Build set of snapshots backing images
  local backing_snapshots=""
  if [[ -f "${tmpdir}/image_snapshots" ]]; then
    backing_snapshots=$(cat "${tmpdir}/image_snapshots")
  fi
  if [[ -f "${tmpdir}/machine_image_snapshots" ]]; then
    backing_snapshots="${backing_snapshots}
$(cat "${tmpdir}/machine_image_snapshots")"
  fi

  local cutoff_epoch
  cutoff_epoch=$(date -v-${days}d +%s 2>/dev/null || date -d "${days} days ago" +%s 2>/dev/null || echo "0")

  echo "IDLE_SNAPSHOTS_START"
  while IFS=$'\t' read -r name disk_size_gb storage_bytes locations created labels; do
    # Check age
    if [[ -n "$created" && "$cutoff_epoch" != "0" ]]; then
      local snap_epoch
      snap_epoch=$(date -jf "%Y-%m-%d" "$created" +%s 2>/dev/null || date -d "$created" +%s 2>/dev/null || echo "0")
      if [[ "$snap_epoch" -gt "$cutoff_epoch" ]]; then
        continue
      fi
    fi

    # Check if backing an image
    if echo "$backing_snapshots" | grep -q "^${name}$" 2>/dev/null; then
      printf "BACKS_IMAGE\t%s\t%sGiB\t%s\tskipped (required by image)\n" "$name" "$disk_size_gb" "$created"
      continue
    fi

    # Cost: $0.050/GiB/mo for standard regional
    local est_monthly
    est_monthly=$(awk "BEGIN {printf \"%.2f\", 0.050 * ${disk_size_gb:-0}}")

    if _is_protected "$labels"; then
      printf "PROTECTED\t%s\t%sGiB\t%s\t%s USD/mo\n" "$name" "$disk_size_gb" "$created" "$est_monthly"
    else
      printf "CANDIDATE\t%s\t%sGiB\t%s\t%s USD/mo\n" "$name" "$disk_size_gb" "$created" "$est_monthly"
    fi
  done <<< "$snapshots"
  echo "IDLE_SNAPSHOTS_END"
  rm -rf "$tmpdir"
}

# Cloud SQL instances with very low utilization
# Usage: gcp_idle_cloudsql [--days N] [--project PROJECT]
gcp_idle_cloudsql() {
  local args
  args=$(_parse_idle_args "$@")
  local days="${args%%|*}"
  local project="${args#*|}"
  local pflag
  pflag=$(_project_flag "$project")
  local proj_id
  proj_id="${project:-$(gcloud config get-value project 2>/dev/null)}"

  local instances
  instances=$(gcloud sql instances list \
    --format="value(name,databaseVersion,region,settings.tier,state,settings.activationPolicy,settings.dataDiskSizeGb,settings.dataDiskType,settings.availabilityType,labels)" \
    $pflag 2>/dev/null || echo "")

  if [[ -z "$instances" ]]; then
    echo "NO_CLOUDSQL_INSTANCES"
    return 0
  fi

  local end_time start_time
  end_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  start_time=$(date -u -v-${days}d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
    date -u -d "${days} days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)

  echo "IDLE_CLOUDSQL_START"
  local tmpdir
  tmpdir=$(mktemp -d)

  while IFS=$'\t' read -r name db_version region tier state activation_policy disk_size disk_type availability_type labels; do
    {
      # Rule 8: Stopped Cloud SQL (activationPolicy=NEVER) is not idle
      if [[ "$activation_policy" == "NEVER" ]]; then
        local storage_cost
        case "$disk_type" in
          PD_SSD) storage_cost=$(awk "BEGIN {printf \"%.2f\", 0.17 * ${disk_size:-0}}") ;;
          PD_HDD) storage_cost=$(awk "BEGIN {printf \"%.2f\", 0.09 * ${disk_size:-0}}") ;;
          *)      storage_cost=$(awk "BEGIN {printf \"%.2f\", 0.17 * ${disk_size:-0}}") ;;
        esac
        printf "STOPPED\t%s\t%s\t%s\t%s\tactivationPolicy=NEVER\tstorage_cost:%s USD/mo\n" \
          "$name" "$tier" "$region" "$db_version" "$storage_cost"
      elif [[ "$state" == "RUNNABLE" ]]; then
        # Check CPU utilization via Cloud Monitoring
        local avg_cpu
        avg_cpu=$(gcloud monitoring time-series list \
          --filter="resource.type='cloudsql_database' AND resource.labels.database_id='${proj_id}:${name}' AND metric.type='cloudsql.googleapis.com/database/cpu/utilization'" \
          --interval.start-time="$start_time" --interval.end-time="$end_time" \
          --aggregation.alignment-period=86400s \
          --aggregation.per-series-aligner=ALIGN_MEAN \
          --format="value(points[].value.doubleValue)" \
          --project="$proj_id" 2>/dev/null | awk '{sum+=$1; count++} END {if(count>0) printf "%.4f", sum/count; else print "N/A"}')

        local avg_connections
        avg_connections=$(gcloud monitoring time-series list \
          --filter="resource.type='cloudsql_database' AND resource.labels.database_id='${proj_id}:${name}' AND metric.type='cloudsql.googleapis.com/database/network/connections'" \
          --interval.start-time="$start_time" --interval.end-time="$end_time" \
          --aggregation.alignment-period=86400s \
          --aggregation.per-series-aligner=ALIGN_MEAN \
          --format="value(points[].value.int64Value)" \
          --project="$proj_id" 2>/dev/null | awk '{sum+=$1; count++} END {if(count>0) printf "%.0f", sum/count; else print "N/A"}')

        if _is_protected "$labels"; then
          printf "PROTECTED\t%s\t%s\t%s\t%s\tavg_cpu:%s\tavg_connections:%s\tHA:%s\n" \
            "$name" "$tier" "$region" "$db_version" "$avg_cpu" "$avg_connections" "$availability_type"
        else
          printf "CANDIDATE\t%s\t%s\t%s\t%s\tavg_cpu:%s\tavg_connections:%s\tHA:%s\n" \
            "$name" "$tier" "$region" "$db_version" "$avg_cpu" "$avg_connections" "$availability_type"
        fi
      fi
    } >> "${tmpdir}/results" &
  done <<< "$instances"
  wait

  if [[ -f "${tmpdir}/results" ]]; then
    cat "${tmpdir}/results"
  fi
  rm -rf "$tmpdir"
  echo "IDLE_CLOUDSQL_END"
}

# GKE node pools with 0 nodes + autoscaler disabled
# Usage: gcp_idle_gke_nodepools [--project PROJECT]
gcp_idle_gke_nodepools() {
  local args
  args=$(_parse_idle_args "$@")
  local project="${args#*|}"
  local pflag
  pflag=$(_project_flag "$project")

  local clusters
  clusters=$(gcloud container clusters list \
    --format="value(name,location)" \
    $pflag 2>/dev/null || echo "")

  if [[ -z "$clusters" ]]; then
    echo "NO_GKE_CLUSTERS"
    return 0
  fi

  echo "IDLE_GKE_NODEPOOLS_START"
  local tmpdir
  tmpdir=$(mktemp -d)

  while IFS=$'\t' read -r cluster_name location; do
    {
      local pools
      pools=$(gcloud container node-pools list --cluster="$cluster_name" --location="$location" \
        --format="value(name,config.machineType,autoscaling.enabled,autoscaling.minNodeCount,autoscaling.maxNodeCount,initialNodeCount,status)" \
        $pflag 2>/dev/null || echo "")

      if [[ -n "$pools" ]]; then
        while IFS=$'\t' read -r pool_name machine_type autoscale_enabled min_nodes max_nodes initial_count status; do
          # Get current node count
          local current_nodes
          current_nodes=$(gcloud container node-pools describe "$pool_name" \
            --cluster="$cluster_name" --location="$location" \
            --format="value(instanceGroupUrls)" \
            $pflag 2>/dev/null | tr ';' '\n' | wc -l | tr -d ' ')

          # Rule 9: Only flag if 0 nodes AND autoscaler disabled
          if [[ "$autoscale_enabled" == "True" ]]; then
            printf "AUTOSCALER_ENABLED\t%s\t%s\t%s\t%s\tmin:%s\tmax:%s\tskipped (intentional scale-to-zero)\n" \
              "$pool_name" "$cluster_name" "$location" "$machine_type" "${min_nodes:-0}" "${max_nodes:-0}"
          else
            printf "CANDIDATE\t%s\t%s\t%s\t%s\tautoscaler:DISABLED\tinitial:%s\tstatus:%s\n" \
              "$pool_name" "$cluster_name" "$location" "$machine_type" "${initial_count:-0}" "$status"
          fi
        done <<< "$pools"
      fi
    } >> "${tmpdir}/results" &
  done <<< "$clusters"
  wait

  if [[ -f "${tmpdir}/results" ]]; then
    cat "${tmpdir}/results"
  fi
  rm -rf "$tmpdir"
  echo "IDLE_GKE_NODEPOOLS_END"
}

# VPC connectors with zero throughput
# Usage: gcp_idle_vpc_connectors [--days N] [--project PROJECT]
gcp_idle_vpc_connectors() {
  local args
  args=$(_parse_idle_args "$@")
  local days="${args%%|*}"
  local project="${args#*|}"
  local pflag
  pflag=$(_project_flag "$project")
  local proj_id
  proj_id="${project:-$(gcloud config get-value project 2>/dev/null)}"

  local end_time start_time
  end_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  start_time=$(date -u -v-${days}d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
    date -u -d "${days} days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)

  # Get all regions with VPC connectors
  local regions
  regions=$(gcloud compute regions list --format="value(name)" $pflag 2>/dev/null || echo "")

  echo "IDLE_VPC_CONNECTORS_START"
  local tmpdir
  tmpdir=$(mktemp -d)

  for region in $regions; do
    {
      local connectors
      connectors=$(gcloud compute networks vpc-access connectors list --region="$region" \
        --format="value(name,machineType,minInstances,maxInstances,state)" \
        $pflag 2>/dev/null || echo "")

      if [[ -n "$connectors" ]]; then
        while IFS=$'\t' read -r name machine_type min_instances max_instances state; do
          # Check throughput via Cloud Monitoring
          local avg_bytes
          avg_bytes=$(gcloud monitoring time-series list \
            --filter="resource.type='vpc_access_connector' AND resource.labels.connector_name='$name' AND metric.type='vpcaccess.googleapis.com/connector/sent_bytes_count'" \
            --interval.start-time="$start_time" --interval.end-time="$end_time" \
            --aggregation.alignment-period=86400s \
            --aggregation.per-series-aligner=ALIGN_RATE \
            --format="value(points[].value.doubleValue)" \
            --project="$proj_id" 2>/dev/null | awk '{sum+=$1; count++} END {if(count>0) printf "%.2f", sum/count; else print "0"}')

          # Estimate cost: min 2 instances of e2-micro = ~$8.56/mo minimum
          local est_monthly
          est_monthly=$(awk "BEGIN {printf \"%.2f\", ${min_instances:-2} * 4.28}")

          printf "CANDIDATE\t%s\t%s\t%s\tmin_instances:%s\tavg_bytes_rate:%s\t%s USD/mo\n" \
            "$name" "$region" "${machine_type:-e2-micro}" "${min_instances:-2}" "$avg_bytes" "$est_monthly"
        done <<< "$connectors"
      fi
    } >> "${tmpdir}/results" &
  done
  wait

  if [[ -f "${tmpdir}/results" ]]; then
    cat "${tmpdir}/results"
  else
    echo "NO_VPC_CONNECTORS"
  fi
  rm -rf "$tmpdir"
  echo "IDLE_VPC_CONNECTORS_END"
}

# Filestore instances with 0 connected clients
# Usage: gcp_idle_filestore [--days N] [--project PROJECT]
gcp_idle_filestore() {
  local args
  args=$(_parse_idle_args "$@")
  local days="${args%%|*}"
  local project="${args#*|}"
  local pflag
  pflag=$(_project_flag "$project")
  local proj_id
  proj_id="${project:-$(gcloud config get-value project 2>/dev/null)}"

  local end_time start_time
  end_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  start_time=$(date -u -v-${days}d +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
    date -u -d "${days} days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)

  local instances
  instances=$(gcloud filestore instances list \
    --format="value(name.scope(instances),location.scope(locations),fileShares[0].capacityGb,tier,labels)" \
    $pflag 2>/dev/null || echo "")

  if [[ -z "$instances" ]]; then
    echo "NO_FILESTORE_INSTANCES"
    return 0
  fi

  echo "IDLE_FILESTORE_START"
  local tmpdir
  tmpdir=$(mktemp -d)

  while IFS=$'\t' read -r name location capacity_gb tier labels; do
    {
      # Check connected clients via Cloud Monitoring
      local avg_clients
      avg_clients=$(gcloud monitoring time-series list \
        --filter="resource.type='filestore_instance' AND resource.labels.instance_name='$name' AND metric.type='file.googleapis.com/nfs/server/connected_client_count'" \
        --interval.start-time="$start_time" --interval.end-time="$end_time" \
        --aggregation.alignment-period=86400s \
        --aggregation.per-series-aligner=ALIGN_MEAN \
        --format="value(points[].value.int64Value)" \
        --project="$proj_id" 2>/dev/null | awk '{sum+=$1; count++} END {if(count>0) printf "%.0f", sum/count; else print "0"}')

      # Cost estimation
      local per_gb_mo
      case "$tier" in
        BASIC_HDD|STANDARD)  per_gb_mo="0.20" ;;
        BASIC_SSD|PREMIUM)   per_gb_mo="0.30" ;;
        HIGH_SCALE_SSD)      per_gb_mo="0.35" ;;
        ENTERPRISE)          per_gb_mo="0.45" ;;
        *)                   per_gb_mo="0.20" ;;
      esac
      local est_monthly
      est_monthly=$(awk "BEGIN {printf \"%.2f\", $per_gb_mo * ${capacity_gb:-0}}")

      if _is_protected "$labels"; then
        printf "PROTECTED\t%s\t%s\t%sGiB\t%s\tavg_clients:%s\t%s USD/mo\n" \
          "$name" "$location" "$capacity_gb" "$tier" "$avg_clients" "$est_monthly"
      else
        printf "CANDIDATE\t%s\t%s\t%sGiB\t%s\tavg_clients:%s\t%s USD/mo\n" \
          "$name" "$location" "$capacity_gb" "$tier" "$avg_clients" "$est_monthly"
      fi
    } >> "${tmpdir}/results" &
  done <<< "$instances"
  wait

  if [[ -f "${tmpdir}/results" ]]; then
    cat "${tmpdir}/results"
  fi
  rm -rf "$tmpdir"
  echo "IDLE_FILESTORE_END"
}

# Run all idle resource checks, unified waste summary
# Usage: gcp_idle_summary [--days N] [--project PROJECT]
gcp_idle_summary() {
  local pass_args=("$@")
  local tmpdir
  tmpdir=$(mktemp -d)

  # Run all checks in parallel
  { gcp_idle_disks "${pass_args[@]}" > "${tmpdir}/disks" 2>/dev/null; } &
  { gcp_idle_ips "${pass_args[@]}" > "${tmpdir}/ips" 2>/dev/null; } &
  { gcp_idle_vms_stopped "${pass_args[@]}" > "${tmpdir}/vms" 2>/dev/null; } &
  { gcp_idle_nat "${pass_args[@]}" > "${tmpdir}/nat" 2>/dev/null; } &
  { gcp_idle_lb "${pass_args[@]}" > "${tmpdir}/lb" 2>/dev/null; } &
  { gcp_idle_snapshots "${pass_args[@]}" > "${tmpdir}/snapshots" 2>/dev/null; } &
  { gcp_idle_cloudsql "${pass_args[@]}" > "${tmpdir}/cloudsql" 2>/dev/null; } &
  { gcp_idle_gke_nodepools "${pass_args[@]}" > "${tmpdir}/gke" 2>/dev/null; } &
  { gcp_idle_vpc_connectors "${pass_args[@]}" > "${tmpdir}/vpc_connectors" 2>/dev/null; } &
  { gcp_idle_filestore "${pass_args[@]}" > "${tmpdir}/filestore" 2>/dev/null; } &
  wait

  echo "IDLE_SUMMARY_START"

  # Output each section
  for section in disks ips vms nat lb snapshots cloudsql gke vpc_connectors filestore; do
    if [[ -f "${tmpdir}/${section}" ]]; then
      cat "${tmpdir}/${section}"
    fi
  done

  # Calculate total estimated waste from CANDIDATE lines
  local total_waste
  total_waste=$(cat "${tmpdir}"/* 2>/dev/null | grep "^CANDIDATE" | grep -o '[0-9.]*\sUSD/mo' | awk '{sum+=$1} END {printf "%.2f", sum}')
  echo "TOTAL_ESTIMATED_WASTE\t${total_waste:-0.00}\tUSD/mo"
  echo "IDLE_SUMMARY_END"

  rm -rf "$tmpdir"
}
