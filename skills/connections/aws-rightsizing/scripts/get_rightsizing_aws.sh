#!/usr/bin/env bash
set -euo pipefail
export AWS_PAGER=""

###############################################################################
# AWS Rightsizing Helper Functions
# Source this file, then call functions individually. Do not execute directly.
#
# All functions enforce anti-hallucination rules: 14-day minimum window,
# burstable credit checks, avg+max stats, RI/SP savings disclaimers.
###############################################################################

# ── Constants ────────────────────────────────────────────────────────────────
_RS_MIN_DAYS=14
_RS_MAX_DAYS=90
_RS_DEFAULT_DAYS=14
_RS_CPU_LOW_THRESHOLD=10    # avg CPU below this = underutilized candidate
_RS_CPU_HIGH_THRESHOLD=80   # avg CPU above this = overutilized candidate
_RS_CREDIT_LOW=20           # credit balance below this = credit-starved

# ── Internal helpers ─────────────────────────────────────────────────────────

_rs_parse_args() {
  _DAYS="$_RS_DEFAULT_DAYS"
  _REGION_FLAG=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --days)   _DAYS="$2"; shift 2 ;;
      --region) _REGION_FLAG=(--region "$2"); shift 2 ;;
      *) shift ;;
    esac
  done
}

_rs_parse_days() {
  local days="$1"
  if [[ "$days" -lt "$_RS_MIN_DAYS" ]]; then
    echo "WARNING: Minimum observation window is ${_RS_MIN_DAYS} days. Using ${_RS_MIN_DAYS}." >&2
    echo "$_RS_MIN_DAYS"
    return
  fi
  if [[ "$days" -gt "$_RS_MAX_DAYS" ]]; then
    echo "WARNING: Maximum observation window is ${_RS_MAX_DAYS} days. Using ${_RS_MAX_DAYS}." >&2
    echo "$_RS_MAX_DAYS"
    return
  fi
  echo "$days"
}

_rs_cw_period() {
  local days="$1"
  # Use 1hr for <= 15 days, 1day for > 15 days
  if [[ "$days" -le 15 ]]; then
    echo 3600
  else
    echo 86400
  fi
}

_rs_start_time() {
  local days="$1"
  if [[ "$(uname)" == "Darwin" ]]; then
    date -u -v-"${days}"d '+%Y-%m-%dT00:00:00Z'
  else
    date -u -d "${days} days ago" '+%Y-%m-%dT00:00:00Z'
  fi
}

_rs_end_time() {
  date -u '+%Y-%m-%dT00:00:00Z'
}

# ── Public Functions ─────────────────────────────────────────────────────────

# EC2 CPU + optional memory analysis
aws_rightsizing_ec2() {
  _rs_parse_args "$@"
  local days
  days=$(_rs_parse_days "$_DAYS")
  local period start_time end_time
  period=$(_rs_cw_period "$days")
  start_time=$(_rs_start_time "$days")
  end_time=$(_rs_end_time)

  echo "=== EC2 Rightsizing Analysis (${days}-day window) ==="
  echo ""

  # Get all running instances
  local instances
  instances=$(aws ec2 describe-instances \
    "${_REGION_FLAG[@]+"${_REGION_FLAG[@]}"}" \
    --filters Name=instance-state-name,Values=running \
    --output json \
    --query 'Reservations[].Instances[].{InstanceId:InstanceId,InstanceType:InstanceType,Tags:Tags}')

  echo "$instances" | python3 -c "
import json, sys, subprocess

instances = json.load(sys.stdin)
if not instances:
    print('No running EC2 instances found.')
    sys.exit(0)

print(f'Running instances: {len(instances)}')
print()
print(f'{\"InstanceId\":<22} {\"Type\":<14} {\"AvgCPU\":>7} {\"MaxCPU\":>7} {\"Credits\":>8} {\"Memory\":>10} {\"Assessment\":<30}')
print('-' * 110)

underutilized = 0
overutilized = 0
credit_starved = 0

for inst in instances:
    iid = inst['InstanceId']
    itype = inst['InstanceType']
    is_burstable = itype.startswith(('t2', 't3', 't4'))

    # Get CPU utilization (Average and Maximum)
    try:
        result = subprocess.run(
            ['aws', 'cloudwatch', 'get-metric-statistics',
             '--namespace', 'AWS/EC2',
             '--metric-name', 'CPUUtilization',
             '--dimensions', f'Name=InstanceId,Value={iid}',
             '--start-time', '${start_time}',
             '--end-time', '${end_time}',
             '--period', str(${days} * 86400),
             '--statistics', 'Average', 'Maximum',
             '--output', 'json'],
            capture_output=True, text=True, timeout=30
        )
        data = json.loads(result.stdout)
        dps = data.get('Datapoints', [])
        if dps:
            avg_cpu = dps[0].get('Average', -1)
            max_cpu = dps[0].get('Maximum', -1)
        else:
            avg_cpu = max_cpu = -1
    except:
        avg_cpu = max_cpu = -1

    # Check CPU credit balance for burstable instances
    credit_balance = 'N/A'
    credit_val = -1
    if is_burstable:
        try:
            result = subprocess.run(
                ['aws', 'cloudwatch', 'get-metric-statistics',
                 '--namespace', 'AWS/EC2',
                 '--metric-name', 'CPUCreditBalance',
                 '--dimensions', f'Name=InstanceId,Value={iid}',
                 '--start-time', '${start_time}',
                 '--end-time', '${end_time}',
                 '--period', str(${days} * 86400),
                 '--statistics', 'Average',
                 '--output', 'json'],
                capture_output=True, text=True, timeout=30
            )
            data = json.loads(result.stdout)
            dps = data.get('Datapoints', [])
            if dps:
                credit_val = dps[0].get('Average', -1)
                credit_balance = f'{credit_val:.0f}'
        except:
            pass

    # Check memory via CWAgent
    mem_str = 'No agent'
    try:
        result = subprocess.run(
            ['aws', 'cloudwatch', 'get-metric-statistics',
             '--namespace', 'CWAgent',
             '--metric-name', 'mem_used_percent',
             '--dimensions', f'Name=InstanceId,Value={iid}',
             '--start-time', '${start_time}',
             '--end-time', '${end_time}',
             '--period', str(${days} * 86400),
             '--statistics', 'Average',
             '--output', 'json'],
            capture_output=True, text=True, timeout=30
        )
        data = json.loads(result.stdout)
        dps = data.get('Datapoints', [])
        if dps:
            mem_avg = dps[0].get('Average', -1)
            mem_str = f'{mem_avg:.1f}%'
    except:
        pass

    # Assessment
    assessment = ''
    if avg_cpu < 0:
        assessment = 'No data'
    elif is_burstable and credit_val >= 0 and credit_val < ${_RS_CREDIT_LOW}:
        assessment = 'CREDIT-STARVED - consider upsizing'
        credit_starved += 1
    elif avg_cpu < ${_RS_CPU_LOW_THRESHOLD} and max_cpu < 30:
        assessment = 'Underutilized - downsize candidate'
        underutilized += 1
    elif avg_cpu < ${_RS_CPU_LOW_THRESHOLD} and max_cpu >= 50:
        assessment = 'Bursty - do NOT downsize'
    elif avg_cpu > ${_RS_CPU_HIGH_THRESHOLD}:
        assessment = 'Overutilized - upsize candidate'
        overutilized += 1
    else:
        assessment = 'Right-sized'

    avg_str = f'{avg_cpu:.1f}%' if avg_cpu >= 0 else 'N/A'
    max_str = f'{max_cpu:.1f}%' if max_cpu >= 0 else 'N/A'

    print(f'{iid:<22} {itype:<14} {avg_str:>7} {max_str:>7} {credit_balance:>8} {mem_str:>10} {assessment}')

print()
print(f'Summary: {len(instances)} instances | {underutilized} underutilized | {overutilized} overutilized | {credit_starved} credit-starved')
print(f'NOTE: Memory data requires CloudWatch Agent (CWAgent). \"No agent\" = CWAgent not installed.')
"
}

# Estimate savings for flagged EC2 instances
aws_rightsizing_ec2_savings() {
  _rs_parse_args "$@"
  local days
  days=$(_rs_parse_days "$_DAYS")

  echo "=== EC2 Rightsizing Savings Estimates ==="
  echo ""

  local instances
  instances=$(aws ec2 describe-instances \
    "${_REGION_FLAG[@]+"${_REGION_FLAG[@]}"}" \
    --filters Name=instance-state-name,Values=running \
    --output json \
    --query 'Reservations[].Instances[].{InstanceId:InstanceId,InstanceType:InstanceType}')

  echo "$instances" | python3 -c "
import json, sys, subprocess

# Approximate on-demand monthly prices (us-east-1)
prices = {
    't3.micro':8,'t3.small':15,'t3.medium':30,'t3.large':61,'t3.xlarge':122,
    't3a.micro':7,'t3a.small':14,'t3a.medium':27,'t3a.large':55,
    'm5.large':70,'m5.xlarge':140,'m5.2xlarge':281,'m5.4xlarge':562,
    'm6i.large':69,'m6i.xlarge':138,'m6i.2xlarge':276,
    'c5.large':62,'c5.xlarge':124,'c5.2xlarge':248,
    'c6i.large':61,'c6i.xlarge':122,'c6i.2xlarge':245,
    'r5.large':91,'r5.xlarge':182,'r5.2xlarge':364,
    'r6i.large':90,'r6i.xlarge':181,'r6i.2xlarge':362,
}

# Size order within families for downsizing recommendations
size_order = ['nano','micro','small','medium','large','xlarge','2xlarge','4xlarge','8xlarge','12xlarge','16xlarge','24xlarge']

def get_smaller(itype):
    parts = itype.split('.')
    if len(parts) != 2:
        return None
    family, size = parts
    if size in size_order:
        idx = size_order.index(size)
        if idx > 0:
            return f'{family}.{size_order[idx-1]}'
    return None

instances = json.load(sys.stdin)
if not instances:
    print('No running instances found.')
    sys.exit(0)

start_time = '${start_time}'
end_time = '${end_time}'
total_period = ${days} * 86400

total_savings = 0.0

print(f'{\"InstanceId\":<22} {\"Current\":<14} {\"AvgCPU\":>7} {\"MaxCPU\":>7} {\"Suggest\":<14} {\"Savings\":>12}')
print('-' * 80)

for inst in instances:
    iid = inst['InstanceId']
    itype = inst['InstanceType']

    # Get CPU
    try:
        result = subprocess.run(
            ['aws', 'cloudwatch', 'get-metric-statistics',
             '--namespace', 'AWS/EC2', '--metric-name', 'CPUUtilization',
             '--dimensions', f'Name=InstanceId,Value={iid}',
             '--start-time', start_time, '--end-time', end_time,
             '--period', str(total_period), '--statistics', 'Average', 'Maximum',
             '--output', 'json'],
            capture_output=True, text=True, timeout=30
        )
        data = json.loads(result.stdout)
        dps = data.get('Datapoints', [])
        avg_cpu = dps[0].get('Average', -1) if dps else -1
        max_cpu = dps[0].get('Maximum', -1) if dps else -1
    except:
        avg_cpu = max_cpu = -1

    if avg_cpu < 0 or avg_cpu >= ${_RS_CPU_LOW_THRESHOLD} or max_cpu >= 50:
        continue

    current_price = prices.get(itype, 0)
    smaller = get_smaller(itype)
    smaller_price = prices.get(smaller, 0) if smaller else 0

    if current_price > 0 and smaller_price > 0:
        savings = current_price - smaller_price
        total_savings += savings
        print(f'{iid:<22} {itype:<14} {avg_cpu:>6.1f}% {max_cpu:>6.1f}% {smaller:<14} \${savings:>10.2f}/mo')

print()
print(f'Total estimated savings: \${total_savings:,.2f}/mo (based on on-demand rates)')
print(f'DISCLAIMER: Actual savings may differ if RI/SP coverage applies to these instances.')
" 2>/dev/null

  local start_time end_time
  start_time=$(_rs_start_time "$days")
  end_time=$(_rs_end_time)
}

# RDS CPU, connections, storage utilization
aws_rightsizing_rds() {
  _rs_parse_args "$@"
  local days
  days=$(_rs_parse_days "$_DAYS")
  local start_time end_time
  start_time=$(_rs_start_time "$days")
  end_time=$(_rs_end_time)

  echo "=== RDS Rightsizing Analysis (${days}-day window) ==="
  echo ""

  local instances
  instances=$(aws rds describe-db-instances \
    "${_REGION_FLAG[@]+"${_REGION_FLAG[@]}"}" \
    --output json \
    --query 'DBInstances[].{DBInstanceIdentifier:DBInstanceIdentifier,DBInstanceClass:DBInstanceClass,Engine:Engine,MultiAZ:MultiAZ,AllocatedStorage:AllocatedStorage,StorageType:StorageType}')

  echo "$instances" | python3 -c "
import json, sys, subprocess

instances = json.load(sys.stdin)
if not instances:
    print('No RDS instances found.')
    sys.exit(0)

print(f'RDS instances: {len(instances)}')
print()
print(f'{\"DBInstance\":<30} {\"Class\":<16} {\"Engine\":<12} {\"MultiAZ\":<8} {\"AvgCPU\":>7} {\"MaxCPU\":>7} {\"AvgConn\":>8} {\"Assessment\":<28}')
print('-' * 130)

total_period = ${days} * 86400

for inst in instances:
    dbid = inst['DBInstanceIdentifier']
    dbclass = inst['DBInstanceClass']
    engine = inst['Engine']
    multi_az = 'Yes' if inst['MultiAZ'] else 'No'

    # CPU utilization
    try:
        result = subprocess.run(
            ['aws', 'cloudwatch', 'get-metric-statistics',
             '--namespace', 'AWS/RDS', '--metric-name', 'CPUUtilization',
             '--dimensions', f'Name=DBInstanceIdentifier,Value={dbid}',
             '--start-time', '${start_time}', '--end-time', '${end_time}',
             '--period', str(total_period), '--statistics', 'Average', 'Maximum',
             '--output', 'json'],
            capture_output=True, text=True, timeout=30
        )
        data = json.loads(result.stdout)
        dps = data.get('Datapoints', [])
        avg_cpu = dps[0].get('Average', -1) if dps else -1
        max_cpu = dps[0].get('Maximum', -1) if dps else -1
    except:
        avg_cpu = max_cpu = -1

    # Database connections
    try:
        result = subprocess.run(
            ['aws', 'cloudwatch', 'get-metric-statistics',
             '--namespace', 'AWS/RDS', '--metric-name', 'DatabaseConnections',
             '--dimensions', f'Name=DBInstanceIdentifier,Value={dbid}',
             '--start-time', '${start_time}', '--end-time', '${end_time}',
             '--period', str(total_period), '--statistics', 'Average',
             '--output', 'json'],
            capture_output=True, text=True, timeout=30
        )
        data = json.loads(result.stdout)
        dps = data.get('Datapoints', [])
        avg_conn = dps[0].get('Average', -1) if dps else -1
    except:
        avg_conn = -1

    # Assessment
    if avg_cpu < 0:
        assessment = 'No data'
    elif avg_cpu < 10 and max_cpu < 30 and avg_conn >= 0 and avg_conn < 5:
        assessment = 'Underutilized - downsize candidate'
    elif avg_cpu < 10 and max_cpu >= 50:
        assessment = 'Bursty - do NOT downsize'
    elif avg_cpu > 80:
        assessment = 'Overutilized - upsize candidate'
    else:
        assessment = 'Right-sized'

    avg_str = f'{avg_cpu:.1f}%' if avg_cpu >= 0 else 'N/A'
    max_str = f'{max_cpu:.1f}%' if max_cpu >= 0 else 'N/A'
    conn_str = f'{avg_conn:.0f}' if avg_conn >= 0 else 'N/A'

    print(f'{dbid:<30} {dbclass:<16} {engine:<12} {multi_az:<8} {avg_str:>7} {max_str:>7} {conn_str:>8} {assessment}')

print()
print(f'NOTE: Multi-AZ doubles compute cost. Always check MultiAZ flag before estimating savings.')
print(f'NOTE: Savings estimates based on on-demand rates; actual savings may differ if RI/SP applies.')
"
}

# Estimate savings for flagged RDS instances
aws_rightsizing_rds_savings() {
  _rs_parse_args "$@"
  local days
  days=$(_rs_parse_days "$_DAYS")
  local start_time end_time
  start_time=$(_rs_start_time "$days")
  end_time=$(_rs_end_time)

  echo "=== RDS Rightsizing Savings Estimates ==="
  echo ""

  local instances
  instances=$(aws rds describe-db-instances \
    "${_REGION_FLAG[@]+"${_REGION_FLAG[@]}"}" \
    --output json \
    --query 'DBInstances[].{DBInstanceIdentifier:DBInstanceIdentifier,DBInstanceClass:DBInstanceClass,MultiAZ:MultiAZ}')

  echo "$instances" | python3 -c "
import json, sys, subprocess

# Approximate monthly on-demand prices (Single-AZ, MySQL, us-east-1)
prices = {
    'db.t3.micro':15,'db.t3.small':29,'db.t3.medium':58,'db.t3.large':116,
    'db.t4g.micro':14,'db.t4g.small':26,'db.t4g.medium':52,'db.t4g.large':104,
    'db.m5.large':125,'db.m5.xlarge':250,'db.m5.2xlarge':500,
    'db.m6i.large':124,'db.m6i.xlarge':248,'db.m6i.2xlarge':496,
    'db.r5.large':175,'db.r5.xlarge':350,'db.r5.2xlarge':700,
    'db.r6i.large':174,'db.r6i.xlarge':348,'db.r6i.2xlarge':696,
}

size_order = ['micro','small','medium','large','xlarge','2xlarge','4xlarge','8xlarge','16xlarge']

def get_smaller(dbclass):
    parts = dbclass.split('.')
    if len(parts) != 3:
        return None
    prefix, family, size = parts
    if size in size_order:
        idx = size_order.index(size)
        if idx > 0:
            return f'{prefix}.{family}.{size_order[idx-1]}'
    return None

instances = json.load(sys.stdin)
if not instances:
    print('No RDS instances found.')
    sys.exit(0)

total_period = ${days} * 86400
total_savings = 0.0

print(f'{\"DBInstance\":<30} {\"Current\":<16} {\"MultiAZ\":<8} {\"AvgCPU\":>7} {\"Suggest\":<16} {\"Savings\":>12}')
print('-' * 100)

for inst in instances:
    dbid = inst['DBInstanceIdentifier']
    dbclass = inst['DBInstanceClass']
    multi_az = inst['MultiAZ']

    try:
        result = subprocess.run(
            ['aws', 'cloudwatch', 'get-metric-statistics',
             '--namespace', 'AWS/RDS', '--metric-name', 'CPUUtilization',
             '--dimensions', f'Name=DBInstanceIdentifier,Value={dbid}',
             '--start-time', '${start_time}', '--end-time', '${end_time}',
             '--period', str(total_period), '--statistics', 'Average', 'Maximum',
             '--output', 'json'],
            capture_output=True, text=True, timeout=30
        )
        data = json.loads(result.stdout)
        dps = data.get('Datapoints', [])
        avg_cpu = dps[0].get('Average', -1) if dps else -1
        max_cpu = dps[0].get('Maximum', -1) if dps else -1
    except:
        avg_cpu = max_cpu = -1

    if avg_cpu < 0 or avg_cpu >= 10 or max_cpu >= 50:
        continue

    current_price = prices.get(dbclass, 0)
    if multi_az:
        current_price *= 2

    smaller = get_smaller(dbclass)
    smaller_price = prices.get(smaller, 0) if smaller else 0
    if multi_az:
        smaller_price *= 2

    if current_price > 0 and smaller_price > 0:
        savings = current_price - smaller_price
        total_savings += savings
        maz = 'Yes' if multi_az else 'No'
        print(f'{dbid:<30} {dbclass:<16} {maz:<8} {avg_cpu:>6.1f}% {smaller:<16} \${savings:>10.2f}/mo')

print()
print(f'Total estimated savings: \${total_savings:,.2f}/mo (based on on-demand rates)')
print(f'DISCLAIMER: Actual savings may differ if RI/SP coverage applies to these instances.')
print(f'DISCLAIMER: Multi-AZ cost is doubled in estimates above.')
"
}

# EBS IOPS/throughput utilization, GP2->GP3 candidates
aws_rightsizing_ebs() {
  _rs_parse_args "$@"
  local days
  days=$(_rs_parse_days "$_DAYS")
  local start_time end_time
  start_time=$(_rs_start_time "$days")
  end_time=$(_rs_end_time)

  echo "=== EBS Rightsizing Analysis (${days}-day window) ==="
  echo ""

  local volumes
  volumes=$(aws ec2 describe-volumes \
    "${_REGION_FLAG[@]+"${_REGION_FLAG[@]}"}" \
    --filters Name=status,Values=in-use \
    --output json \
    --query 'Volumes[].{VolumeId:VolumeId,Size:Size,VolumeType:VolumeType,Iops:Iops,Throughput:Throughput}')

  echo "$volumes" | python3 -c "
import json, sys, subprocess

volumes = json.load(sys.stdin)
if not volumes:
    print('No in-use EBS volumes found.')
    sys.exit(0)

print(f'In-use volumes: {len(volumes)}')
print()

gp2_candidates = []
total_period = ${days} * 86400

print(f'{\"VolumeId\":<24} {\"Type\":<6} {\"Size\":>6} {\"IOPS\":>6} {\"AvgRead\":>10} {\"AvgWrite\":>10} {\"Assessment\":<30}')
print('-' * 100)

for vol in volumes:
    vid = vol['VolumeId']
    vtype = vol['VolumeType']
    size = vol['Size']
    prov_iops = vol.get('Iops', 0) or 0

    # Get read/write IOPS from CloudWatch
    avg_read = avg_write = -1
    for metric, label in [('VolumeReadOps', 'read'), ('VolumeWriteOps', 'write')]:
        try:
            result = subprocess.run(
                ['aws', 'cloudwatch', 'get-metric-statistics',
                 '--namespace', 'AWS/EBS', '--metric-name', metric,
                 '--dimensions', f'Name=VolumeId,Value={vid}',
                 '--start-time', '${start_time}', '--end-time', '${end_time}',
                 '--period', str(total_period), '--statistics', 'Average',
                 '--output', 'json'],
                capture_output=True, text=True, timeout=30
            )
            data = json.loads(result.stdout)
            dps = data.get('Datapoints', [])
            val = dps[0].get('Average', 0) if dps else 0
            if label == 'read':
                avg_read = val
            else:
                avg_write = val
        except:
            pass

    read_str = f'{avg_read:.0f}' if avg_read >= 0 else 'N/A'
    write_str = f'{avg_write:.0f}' if avg_write >= 0 else 'N/A'

    # Assessment
    assessment = ''
    if vtype == 'gp2':
        gp2_baseline = max(100, 3 * size)
        gp2_cost = size * 0.10
        gp3_cost = size * 0.08
        savings = gp2_cost - gp3_cost
        assessment = f'GP2->GP3 save \${savings:.2f}/mo + 10x IOPS'
        gp2_candidates.append((vid, size, gp2_cost, gp3_cost, savings))
    elif vtype in ('io1', 'io2') and avg_read >= 0 and avg_write >= 0:
        total_iops = avg_read + avg_write
        if prov_iops > 0 and total_iops < prov_iops * 0.1:
            assessment = 'Low IOPS usage - review provisioned IOPS'
        else:
            assessment = 'Right-sized'
    else:
        assessment = 'Right-sized'

    print(f'{vid:<24} {vtype:<6} {size:>4}GB {prov_iops:>6} {read_str:>10} {write_str:>10} {assessment}')

if gp2_candidates:
    print()
    total_gp2_savings = sum(s for _, _, _, _, s in gp2_candidates)
    print(f'GP2->GP3 Migration Candidates: {len(gp2_candidates)} volumes')
    print(f'Total potential savings: \${total_gp2_savings:,.2f}/mo')
    print(f'GP3 provides 3000 baseline IOPS (vs GP2 3*GB) at 20% lower cost per GB.')
"
}

# Lambda memory/duration/invocation analysis
aws_rightsizing_lambda() {
  _rs_parse_args "$@"
  local days
  days=$(_rs_parse_days "$_DAYS")
  local start_time end_time
  start_time=$(_rs_start_time "$days")
  end_time=$(_rs_end_time)

  echo "=== Lambda Rightsizing Analysis (${days}-day window) ==="
  echo ""

  local functions
  functions=$(aws lambda list-functions \
    "${_REGION_FLAG[@]+"${_REGION_FLAG[@]}"}" \
    --output json \
    --query 'Functions[].{FunctionName:FunctionName,MemorySize:MemorySize,Timeout:Timeout,Runtime:Runtime}')

  echo "$functions" | python3 -c "
import json, sys, subprocess

functions = json.load(sys.stdin)
if not functions:
    print('No Lambda functions found.')
    sys.exit(0)

print(f'Lambda functions: {len(functions)}')
print()
print(f'{\"Function\":<40} {\"Memory\":>8} {\"Timeout\":>8} {\"AvgDur\":>8} {\"MaxDur\":>8} {\"Invocations\":>12} {\"Assessment\":<28}')
print('-' * 120)

total_period = ${days} * 86400

for fn in functions:
    fname = fn['FunctionName']
    memory = fn['MemorySize']
    timeout = fn['Timeout']

    # Duration
    try:
        result = subprocess.run(
            ['aws', 'cloudwatch', 'get-metric-statistics',
             '--namespace', 'AWS/Lambda', '--metric-name', 'Duration',
             '--dimensions', f'Name=FunctionName,Value={fname}',
             '--start-time', '${start_time}', '--end-time', '${end_time}',
             '--period', str(total_period), '--statistics', 'Average', 'Maximum',
             '--output', 'json'],
            capture_output=True, text=True, timeout=30
        )
        data = json.loads(result.stdout)
        dps = data.get('Datapoints', [])
        avg_dur = dps[0].get('Average', -1) if dps else -1
        max_dur = dps[0].get('Maximum', -1) if dps else -1
    except:
        avg_dur = max_dur = -1

    # Invocations
    try:
        result = subprocess.run(
            ['aws', 'cloudwatch', 'get-metric-statistics',
             '--namespace', 'AWS/Lambda', '--metric-name', 'Invocations',
             '--dimensions', f'Name=FunctionName,Value={fname}',
             '--start-time', '${start_time}', '--end-time', '${end_time}',
             '--period', str(total_period), '--statistics', 'Sum',
             '--output', 'json'],
            capture_output=True, text=True, timeout=30
        )
        data = json.loads(result.stdout)
        dps = data.get('Datapoints', [])
        invocations = int(dps[0].get('Sum', 0)) if dps else 0
    except:
        invocations = 0

    # Assessment
    if invocations == 0:
        assessment = 'No invocations - review need'
    elif avg_dur < 0:
        assessment = 'No duration data'
    elif memory >= 1024 and avg_dur < 100 and max_dur < 500:
        assessment = 'Over-provisioned memory?'
    elif max_dur > timeout * 1000 * 0.8:
        assessment = 'Near timeout - check config'
    else:
        assessment = 'Right-sized'

    avg_str = f'{avg_dur:.0f}ms' if avg_dur >= 0 else 'N/A'
    max_str = f'{max_dur:.0f}ms' if max_dur >= 0 else 'N/A'

    print(f'{fname:<40} {memory:>6}MB {timeout:>6}s {avg_str:>8} {max_str:>8} {invocations:>12,} {assessment}')

print()
print(f'NOTE: Reducing Lambda memory also reduces CPU allocation proportionally.')
print(f'NOTE: Check duration trends before reducing memory -- duration may increase, negating savings.')
"
}

# Run all rightsizing checks, unified summary
aws_rightsizing_summary() {
  _rs_parse_args "$@"
  local args=()
  [[ "${#_REGION_FLAG[@]}" -gt 0 ]] && args+=("${_REGION_FLAG[@]}")
  args+=(--days "$_DAYS")

  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║           AWS Rightsizing Summary                       ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo ""

  aws_rightsizing_ec2 "${args[@]}"
  echo ""
  echo "─────────────────────────────────────────────────────────"
  echo ""

  aws_rightsizing_rds "${args[@]}"
  echo ""
  echo "─────────────────────────────────────────────────────────"
  echo ""

  aws_rightsizing_ebs "${args[@]}"
  echo ""
  echo "─────────────────────────────────────────────────────────"
  echo ""

  aws_rightsizing_lambda "${args[@]}"
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo "All savings estimates based on on-demand rates."
  echo "Actual savings may differ if RI/SP coverage applies."
}
