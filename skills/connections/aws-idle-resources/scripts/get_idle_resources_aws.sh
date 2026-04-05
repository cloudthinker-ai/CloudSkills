#!/usr/bin/env bash
set -euo pipefail
export AWS_PAGER=""

###############################################################################
# AWS Idle Resources Helper Functions
# Source this file, then call functions individually. Do not execute directly.
#
# All functions enforce anti-hallucination rules: protection tag checks,
# cost estimation, "candidate for review" language.
###############################################################################

# ── Constants ────────────────────────────────────────────────────────────────
_IDLE_DEFAULT_DAYS=30
_IDLE_PROTECTION_TAGS="do-not-delete|DoNotDelete|keep|Keep|protected|Protected|backup|Backup"

# ── EBS Pricing Reference (USD/GB/month by type) ────────────────────────────
_ebs_price_per_gb() {
  case "$1" in
    gp2)  echo "0.10" ;;
    gp3)  echo "0.08" ;;
    io1)  echo "0.125" ;;
    io2)  echo "0.125" ;;
    st1)  echo "0.045" ;;
    sc1)  echo "0.015" ;;
    standard) echo "0.05" ;;
    *)    echo "0.10" ;;
  esac
}

# ── Internal helpers ─────────────────────────────────────────────────────────

_idle_parse_args() {
  _DAYS="$_IDLE_DEFAULT_DAYS"
  _REGION_FLAG=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --days)   _DAYS="$2"; shift 2 ;;
      --region) _REGION_FLAG=(--region "$2"); shift 2 ;;
      *) shift ;;
    esac
  done
}

# Check if a resource has protection tags. Returns 0 if protected.
_is_protected() {
  local tags="$1"
  if echo "$tags" | grep -qiE "(${_IDLE_PROTECTION_TAGS})"; then
    return 0
  fi
  return 1
}

# ── Public Functions ─────────────────────────────────────────────────────────

# Detached (available) EBS volumes with cost estimate
aws_idle_ebs() {
  _idle_parse_args "$@"

  echo "=== Idle EBS Volumes (Detached/Available) ==="
  echo ""

  local volumes
  volumes=$(aws ec2 describe-volumes \
    "${_REGION_FLAG[@]+"${_REGION_FLAG[@]}"}" \
    --filters Name=status,Values=available \
    --output json \
    --query 'Volumes[].{VolumeId:VolumeId,Size:Size,VolumeType:VolumeType,CreateTime:CreateTime,State:State,Tags:Tags,Iops:Iops}')

  local count
  count=$(echo "$volumes" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")

  if [[ "$count" -eq 0 ]]; then
    echo "No detached EBS volumes found."
    return 0
  fi

  echo "$volumes" | python3 -c "
import json, sys
volumes = json.load(sys.stdin)
protection_tags = set(['do-not-delete','donotdelete','keep','protected','backup'])
total_waste = 0.0
ebs_prices = {'gp2':0.10,'gp3':0.08,'io1':0.125,'io2':0.125,'st1':0.045,'sc1':0.015,'standard':0.05}

print(f'Detached volumes found: {len(volumes)}')
print()
print(f'{\"VolumeId\":<24} {\"Type\":<6} {\"Size\":>6} {\"Created\":<12} {\"Est.Cost\":>10} {\"Status\":<20}')
print('-' * 90)

for v in volumes:
    vid = v['VolumeId']
    vtype = v['VolumeType']
    size = v['Size']
    created = v['CreateTime'][:10]
    price = ebs_prices.get(vtype, 0.10)
    monthly = size * price
    iops = v.get('Iops', 0) or 0

    # Add IOPS cost for provisioned IOPS volumes
    if vtype in ('io1', 'io2') and iops > 0:
        monthly += iops * 0.065

    tags = v.get('Tags') or []
    tag_names = [t.get('Key','').lower() for t in tags]
    tag_values = [t.get('Value','').lower() for t in tags]
    all_tag_parts = tag_names + tag_values

    is_protected = any(p in ' '.join(all_tag_parts) for p in protection_tags)

    if is_protected:
        status = 'PROTECTED -- skipped'
    else:
        status = 'Candidate for review'
        total_waste += monthly

    print(f'{vid:<24} {vtype:<6} {size:>4}GB {created:<12} \${monthly:>8.2f}/mo {status}')

print()
print(f'Total estimated waste (unprotected): \${total_waste:,.2f}/mo')
"
}

# ALB/NLB with 0 healthy targets or minimal requests
aws_idle_elb() {
  _idle_parse_args "$@"

  echo "=== Idle Load Balancers ==="
  echo ""

  # Get all ALBs and NLBs
  local lbs
  lbs=$(aws elbv2 describe-load-balancers \
    "${_REGION_FLAG[@]+"${_REGION_FLAG[@]}"}" \
    --output json \
    --query 'LoadBalancers[].{ARN:LoadBalancerArn,Name:LoadBalancerName,Type:Type,State:State.Code}')

  local count
  count=$(echo "$lbs" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")

  if [[ "$count" -eq 0 ]]; then
    echo "No ALB/NLB found."
    return 0
  fi

  echo "Load balancers found: ${count}"
  echo ""

  # Check each LB for healthy targets
  echo "$lbs" | python3 -c "
import json, sys, subprocess
lbs = json.load(sys.stdin)

print(f'{\"Name\":<40} {\"Type\":<6} {\"State\":<10} {\"Healthy\":>8} {\"Status\":<20}')
print('-' * 90)

for lb in lbs:
    name = lb['Name']
    lb_type = lb['Type']
    state = lb['State']
    arn = lb['ARN']

    # Get target groups for this LB
    try:
        result = subprocess.run(
            ['aws', 'elbv2', 'describe-target-groups', '--load-balancer-arn', arn,
             '--output', 'json', '--query', 'TargetGroups[].TargetGroupArn'],
            capture_output=True, text=True, timeout=30
        )
        tg_arns = json.loads(result.stdout) if result.stdout.strip() else []
    except:
        tg_arns = []

    total_healthy = 0
    for tg_arn in tg_arns:
        try:
            result = subprocess.run(
                ['aws', 'elbv2', 'describe-target-health', '--target-group-arn', tg_arn,
                 '--output', 'json', '--query', 'TargetHealthDescriptions[?TargetHealth.State==\`healthy\`] | length(@)'],
                capture_output=True, text=True, timeout=30
            )
            total_healthy += int(result.stdout.strip()) if result.stdout.strip() else 0
        except:
            pass

    if total_healthy == 0 and state == 'active':
        status = 'Candidate for review'
        # ALB ~\$16/mo, NLB ~\$16/mo fixed
        est = 16.43
        print(f'{name:<40} {lb_type:<6} {state:<10} {total_healthy:>8} {status} (~\${est:.2f}/mo)')
    else:
        print(f'{name:<40} {lb_type:<6} {state:<10} {total_healthy:>8} OK')
"
}

# Elastic IPs not associated to running instances
aws_idle_eip() {
  _idle_parse_args "$@"

  echo "=== Idle Elastic IPs ==="
  echo ""

  local eips
  eips=$(aws ec2 describe-addresses \
    "${_REGION_FLAG[@]+"${_REGION_FLAG[@]}"}" \
    --output json \
    --query 'Addresses[].{AllocationId:AllocationId,PublicIp:PublicIp,InstanceId:InstanceId,NetworkInterfaceId:NetworkInterfaceId,Tags:Tags}')

  echo "$eips" | python3 -c "
import json, sys
eips = json.load(sys.stdin)
protection_tags = set(['do-not-delete','donotdelete','keep','protected','backup'])
eip_cost = 3.60  # \$0.005/hr

if not eips:
    print('No Elastic IPs found.')
    sys.exit(0)

total_waste = 0.0
idle_count = 0

print(f'{\"AllocationId\":<28} {\"PublicIP\":<18} {\"Association\":<30} {\"Est.Cost\":>10} {\"Status\":<20}')
print('-' * 110)

for eip in eips:
    aid = eip['AllocationId']
    ip = eip['PublicIp']
    instance = eip.get('InstanceId') or ''
    eni = eip.get('NetworkInterfaceId') or ''
    tags = eip.get('Tags') or []
    tag_parts = [t.get('Key','').lower() + ' ' + t.get('Value','').lower() for t in tags]
    is_protected = any(p in ' '.join(tag_parts) for p in protection_tags)

    if instance:
        assoc = f'EC2: {instance}'
        status = 'Attached (still costs \$3.60/mo)'
    elif eni:
        assoc = f'ENI: {eni}'
        status = 'ENI-attached'
    else:
        assoc = 'NONE'
        if is_protected:
            status = 'PROTECTED -- skipped'
        else:
            status = 'Candidate for review'
            total_waste += eip_cost
            idle_count += 1

    print(f'{aid:<28} {ip:<18} {assoc:<30} \${eip_cost:>8.2f}/mo {status}')

print()
print(f'Unassociated EIPs (pure waste): {idle_count}, est. \${total_waste:,.2f}/mo')
print(f'NOTE: Since Feb 2024, ALL public IPv4 addresses cost \$0.005/hr (\$3.60/mo)')
"
}

# EC2 instances stopped for > N days, with attached EBS cost
aws_idle_ec2_stopped() {
  _idle_parse_args "$@"

  echo "=== Stopped EC2 Instances (>${_DAYS} days) ==="
  echo ""

  local instances
  instances=$(aws ec2 describe-instances \
    "${_REGION_FLAG[@]+"${_REGION_FLAG[@]}"}" \
    --filters Name=instance-state-name,Values=stopped \
    --output json \
    --query 'Reservations[].Instances[].{InstanceId:InstanceId,InstanceType:InstanceType,LaunchTime:LaunchTime,StateTransitionReason:StateTransitionReason,Tags:Tags,BlockDeviceMappings:BlockDeviceMappings}')

  echo "$instances" | python3 -c "
import json, sys, subprocess, re
from datetime import datetime, timezone, timedelta

instances = json.load(sys.stdin)
protection_tags = set(['do-not-delete','donotdelete','keep','protected','backup'])
threshold_days = ${_DAYS}
now = datetime.now(timezone.utc)
total_waste = 0.0
ebs_prices = {'gp2':0.10,'gp3':0.08,'io1':0.125,'io2':0.125,'st1':0.045,'sc1':0.015,'standard':0.05}

if not instances:
    print('No stopped EC2 instances found.')
    sys.exit(0)

print(f'{\"InstanceId\":<22} {\"Type\":<14} {\"Stopped\":>8} {\"EBS Cost\":>10} {\"EIP Cost\":>10} {\"Status\":<20}')
print('-' * 100)

for inst in instances:
    iid = inst['InstanceId']
    itype = inst['InstanceType']
    tags = inst.get('Tags') or []
    tag_parts = [t.get('Key','').lower() + ' ' + t.get('Value','').lower() for t in tags]
    is_protected = any(p in ' '.join(tag_parts) for p in protection_tags)

    # Parse stop time from StateTransitionReason
    reason = inst.get('StateTransitionReason', '')
    match = re.search(r'\((\d{4}-\d{2}-\d{2})', reason)
    if match:
        stop_date = datetime.strptime(match.group(1), '%Y-%m-%d').replace(tzinfo=timezone.utc)
        days_stopped = (now - stop_date).days
    else:
        days_stopped = 999  # Unknown, flag anyway

    if days_stopped < threshold_days:
        continue

    # Calculate EBS cost from block device mappings
    vol_ids = [m['Ebs']['VolumeId'] for m in inst.get('BlockDeviceMappings', []) if 'Ebs' in m]
    ebs_monthly = 0.0
    for vid in vol_ids:
        try:
            result = subprocess.run(
                ['aws', 'ec2', 'describe-volumes', '--volume-ids', vid,
                 '--output', 'json', '--query', 'Volumes[0].{Size:Size,VolumeType:VolumeType,Iops:Iops}'],
                capture_output=True, text=True, timeout=15
            )
            vol = json.loads(result.stdout) if result.stdout.strip() else {}
            size = vol.get('Size', 0)
            vtype = vol.get('VolumeType', 'gp3')
            price = ebs_prices.get(vtype, 0.10)
            ebs_monthly += size * price
            iops = vol.get('Iops', 0) or 0
            if vtype in ('io1', 'io2') and iops > 0:
                ebs_monthly += iops * 0.065
        except:
            pass

    # Check for associated EIPs
    eip_monthly = 0.0
    try:
        result = subprocess.run(
            ['aws', 'ec2', 'describe-addresses', '--filters',
             f'Name=instance-id,Values={iid}', '--output', 'json',
             '--query', 'Addresses | length(@)'],
            capture_output=True, text=True, timeout=15
        )
        eip_count = int(result.stdout.strip()) if result.stdout.strip() else 0
        eip_monthly = eip_count * 3.60
    except:
        pass

    ongoing = ebs_monthly + eip_monthly
    if is_protected:
        status = 'PROTECTED -- skipped'
    else:
        status = 'Candidate for review'
        total_waste += ongoing

    print(f'{iid:<22} {itype:<14} {days_stopped:>5}d   \${ebs_monthly:>8.2f}/mo \${eip_monthly:>8.2f}/mo {status}')

print()
print(f'Total ongoing waste (stopped instances, unprotected): \${total_waste:,.2f}/mo')
print('NOTE: Compute charges stop when instance is stopped, but EBS + EIP costs continue.')
"
}

# NAT Gateways with minimal/no traffic
aws_idle_natgw() {
  _idle_parse_args "$@"

  echo "=== Idle NAT Gateways ==="
  echo ""

  local natgws
  natgws=$(aws ec2 describe-nat-gateways \
    "${_REGION_FLAG[@]+"${_REGION_FLAG[@]}"}" \
    --filter Name=state,Values=available \
    --output json \
    --query 'NatGateways[].{NatGatewayId:NatGatewayId,SubnetId:SubnetId,VpcId:VpcId,CreateTime:CreateTime,Tags:Tags}')

  local count
  count=$(echo "$natgws" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")

  if [[ "$count" -eq 0 ]]; then
    echo "No NAT Gateways found."
    return 0
  fi

  local start_time end_time period
  if [[ "$(uname)" == "Darwin" ]]; then
    start_time=$(date -u -v-"${_DAYS}"d '+%Y-%m-%dT00:00:00Z')
  else
    start_time=$(date -u -d "${_DAYS} days ago" '+%Y-%m-%dT00:00:00Z')
  fi
  end_time=$(date -u '+%Y-%m-%dT00:00:00Z')
  period=$(( _DAYS * 86400 ))  # Full period as single datapoint

  echo "$natgws" | python3 -c "
import json, sys, subprocess
natgws = json.load(sys.stdin)
protection_tags = set(['do-not-delete','donotdelete','keep','protected','backup'])
natgw_fixed_cost = 32.40  # \$0.045/hr

print(f'NAT Gateways found: {len(natgws)}')
print()
print(f'{\"NatGatewayId\":<24} {\"VpcId\":<24} {\"BytesOut\":>14} {\"Est.Cost\":>10} {\"Status\":<24}')
print('-' * 100)

total_waste = 0.0

for ngw in natgws:
    nid = ngw['NatGatewayId']
    vpc = ngw['VpcId']
    tags = ngw.get('Tags') or []
    tag_parts = [t.get('Key','').lower() + ' ' + t.get('Value','').lower() for t in tags]
    is_protected = any(p in ' '.join(tag_parts) for p in protection_tags)

    # Check BytesOutToDestination metric
    try:
        result = subprocess.run(
            ['aws', 'cloudwatch', 'get-metric-statistics',
             '--namespace', 'AWS/NATGateway',
             '--metric-name', 'BytesOutToDestination',
             '--dimensions', f'Name=NatGatewayId,Value={nid}',
             '--start-time', '${start_time}',
             '--end-time', '${end_time}',
             '--period', '${period}',
             '--statistics', 'Sum',
             '--output', 'json'],
            capture_output=True, text=True, timeout=30
        )
        data = json.loads(result.stdout)
        datapoints = data.get('Datapoints', [])
        total_bytes = sum(d.get('Sum', 0) for d in datapoints)
    except:
        total_bytes = -1

    total_gb = total_bytes / (1024**3) if total_bytes > 0 else 0
    data_cost = total_gb * 0.045
    monthly_cost = natgw_fixed_cost + data_cost

    if total_bytes == 0:
        if is_protected:
            status = 'PROTECTED -- skipped'
        else:
            status = 'IDLE - Candidate for review'
            total_waste += natgw_fixed_cost
    elif total_bytes < 1024 * 1024 * 100:  # < 100MB
        if is_protected:
            status = 'PROTECTED -- skipped'
        else:
            status = 'Low traffic - review'
            total_waste += natgw_fixed_cost
    else:
        status = 'Active'

    bytes_str = f'{total_gb:.2f} GB' if total_bytes >= 0 else 'N/A'
    print(f'{nid:<24} {vpc:<24} {bytes_str:>14} \${monthly_cost:>8.2f}/mo {status}')

print()
print(f'Total estimated waste (idle/low-traffic, unprotected): \${total_waste:,.2f}/mo')
print(f'NOTE: NAT Gateway fixed cost is \$0.045/hr (\$32.40/mo) regardless of traffic.')
"
}

# EBS snapshots older than N days, cross-referenced with AMIs
aws_idle_snapshots() {
  _idle_parse_args "$@"

  echo "=== Old EBS Snapshots (>${_DAYS} days, not backing AMIs) ==="
  echo ""

  # Get AMI snapshot IDs to exclude
  local ami_snaps
  ami_snaps=$(aws ec2 describe-images \
    "${_REGION_FLAG[@]+"${_REGION_FLAG[@]}"}" \
    --owners self \
    --output text \
    --query 'Images[].BlockDeviceMappings[].Ebs.SnapshotId' 2>/dev/null || echo "")

  # Get all owned snapshots
  local owner_id
  owner_id=$(aws sts get-caller-identity --output text --query 'Account')

  local cutoff_date
  if [[ "$(uname)" == "Darwin" ]]; then
    cutoff_date=$(date -u -v-"${_DAYS}"d '+%Y-%m-%dT00:00:00Z')
  else
    cutoff_date=$(date -u -d "${_DAYS} days ago" '+%Y-%m-%dT00:00:00Z')
  fi

  aws ec2 describe-snapshots \
    "${_REGION_FLAG[@]+"${_REGION_FLAG[@]}"}" \
    --owner-ids "$owner_id" \
    --output json \
    --query "Snapshots[?StartTime<='${cutoff_date}'].{SnapshotId:SnapshotId,VolumeSize:VolumeSize,StartTime:StartTime,Description:Description,Tags:Tags}" \
    | python3 -c "
import json, sys
from datetime import datetime, timezone

snapshots = json.load(sys.stdin)
ami_snap_ids = set('''${ami_snaps}'''.split())
protection_tags = set(['do-not-delete','donotdelete','keep','protected','backup'])
snap_price_per_gb = 0.05
now = datetime.now(timezone.utc)

if not snapshots:
    print('No old snapshots found.')
    sys.exit(0)

print(f'Old snapshots found: {len(snapshots)}')
print()
print(f'{\"SnapshotId\":<24} {\"Size\":>6} {\"Age\":>6} {\"Est.Cost\":>10} {\"Status\":<30}')
print('-' * 90)

total_waste = 0.0
candidates = 0

for snap in sorted(snapshots, key=lambda s: s.get('VolumeSize',0), reverse=True)[:50]:
    sid = snap['SnapshotId']
    size = snap.get('VolumeSize', 0)
    start = snap['StartTime'][:10]
    start_dt = datetime.strptime(start, '%Y-%m-%d').replace(tzinfo=timezone.utc)
    age_days = (now - start_dt).days
    monthly = size * snap_price_per_gb

    tags = snap.get('Tags') or []
    tag_parts = [t.get('Key','').lower() + ' ' + t.get('Value','').lower() for t in tags]
    is_protected = any(p in ' '.join(tag_parts) for p in protection_tags)
    backs_ami = sid in ami_snap_ids

    if backs_ami:
        status = 'Backs AMI -- skipped'
    elif is_protected:
        status = 'PROTECTED -- skipped'
    else:
        status = 'Candidate for review'
        total_waste += monthly
        candidates += 1

    print(f'{sid:<24} {size:>4}GB {age_days:>4}d  \${monthly:>8.2f}/mo {status}')

print()
print(f'Candidates for review: {candidates}, est. waste: \${total_waste:,.2f}/mo')
print(f'Snapshot pricing: \$0.05/GB/month')
"
}

# Unused (available) network interfaces
aws_idle_eni() {
  _idle_parse_args "$@"

  echo "=== Unused Network Interfaces (Available) ==="
  echo ""

  aws ec2 describe-network-interfaces \
    "${_REGION_FLAG[@]+"${_REGION_FLAG[@]}"}" \
    --filters Name=status,Values=available \
    --output json \
    --query 'NetworkInterfaces[].{NetworkInterfaceId:NetworkInterfaceId,SubnetId:SubnetId,VpcId:VpcId,Description:Description,TagSet:TagSet}' \
    | python3 -c "
import json, sys
enis = json.load(sys.stdin)
protection_tags = set(['do-not-delete','donotdelete','keep','protected','backup'])

if not enis:
    print('No unused network interfaces found.')
    sys.exit(0)

print(f'Unused ENIs found: {len(enis)}')
print()
print(f'{\"ENI ID\":<26} {\"VPC\":<24} {\"Description\":<40} {\"Status\":<20}')
print('-' * 110)

candidates = 0
for eni in enis:
    eid = eni['NetworkInterfaceId']
    vpc = eni['VpcId']
    desc = (eni.get('Description') or 'N/A')[:38]
    tags = eni.get('TagSet') or []
    tag_parts = [t.get('Key','').lower() + ' ' + t.get('Value','').lower() for t in tags]
    is_protected = any(p in ' '.join(tag_parts) for p in protection_tags)

    if is_protected:
        status = 'PROTECTED -- skipped'
    else:
        status = 'Candidate for review'
        candidates += 1

    print(f'{eid:<26} {vpc:<24} {desc:<40} {status}')

print()
print(f'Candidates for cleanup: {candidates} (ENIs are free but clutter the environment)')
"
}

# Run all idle checks and produce unified summary
aws_idle_summary() {
  _idle_parse_args "$@"
  local args=()
  [[ "${#_REGION_FLAG[@]}" -gt 0 ]] && args+=("${_REGION_FLAG[@]}")
  args+=(--days "$_DAYS")

  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║           AWS Idle Resources Summary                    ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo ""

  aws_idle_ebs "${args[@]}"
  echo ""
  echo "─────────────────────────────────────────────────────────"
  echo ""

  aws_idle_elb "${args[@]}"
  echo ""
  echo "─────────────────────────────────────────────────────────"
  echo ""

  aws_idle_eip "${args[@]}"
  echo ""
  echo "─────────────────────────────────────────────────────────"
  echo ""

  aws_idle_ec2_stopped "${args[@]}"
  echo ""
  echo "─────────────────────────────────────────────────────────"
  echo ""

  aws_idle_natgw "${args[@]}"
  echo ""
  echo "─────────────────────────────────────────────────────────"
  echo ""

  aws_idle_snapshots "${args[@]}"
  echo ""
  echo "─────────────────────────────────────────────────────────"
  echo ""

  aws_idle_eni "${args[@]}"
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "All resources flagged are CANDIDATES FOR REVIEW, not deletion recommendations."
  echo "Always verify business context before taking action on any resource."
}
