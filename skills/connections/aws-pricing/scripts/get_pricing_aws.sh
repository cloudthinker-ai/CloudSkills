#!/usr/bin/env bash
set -euo pipefail
export AWS_PAGER=""

###############################################################################
# AWS Pricing Helper Functions
# Source this file, then call get_aws_cost. Do not execute directly.
#
# Usage: get_aws_cost <resource> <region> [options]
# Options: --spot, --detailed, --no-reserved
###############################################################################

# ── Internal helpers ─────────────────────────────────────────────────────────

# Map common region strings to AWS API location names
_pricing_normalize_region() {
  local region="$1"
  # If already a location name (contains spaces), return as-is
  if [[ "$region" == *" "* ]]; then
    echo "$region"
    return
  fi
  # Map region codes to location names
  case "$region" in
    us-east-1)      echo "US East (N. Virginia)" ;;
    us-east-2)      echo "US East (Ohio)" ;;
    us-west-1)      echo "US West (N. California)" ;;
    us-west-2)      echo "US West (Oregon)" ;;
    eu-west-1)      echo "Europe (Ireland)" ;;
    eu-west-2)      echo "Europe (London)" ;;
    eu-west-3)      echo "Europe (Paris)" ;;
    eu-central-1)   echo "Europe (Frankfurt)" ;;
    eu-north-1)     echo "Europe (Stockholm)" ;;
    ap-southeast-1) echo "Asia Pacific (Singapore)" ;;
    ap-southeast-2) echo "Asia Pacific (Sydney)" ;;
    ap-northeast-1) echo "Asia Pacific (Tokyo)" ;;
    ap-northeast-2) echo "Asia Pacific (Seoul)" ;;
    ap-northeast-3) echo "Asia Pacific (Osaka)" ;;
    ap-south-1)     echo "Asia Pacific (Mumbai)" ;;
    sa-east-1)      echo "South America (Sao Paulo)" ;;
    ca-central-1)   echo "Canada (Central)" ;;
    me-south-1)     echo "Middle East (Bahrain)" ;;
    af-south-1)     echo "Africa (Cape Town)" ;;
    *)              echo "$region" ;;
  esac
}

# Detect resource type from naming pattern
_pricing_detect_type() {
  local resource="$1"
  case "$resource" in
    t[234]*|m[456]*|c[567]*|r[567]*|i[34]*|g[45]*|p[345]*|x[12]*|z1*|a1*|hpc*|inf*|trn*|dl*|im4*|is4*)
      echo "ec2" ;;
    db.*)
      echo "rds" ;;
    cache.*)
      echo "elasticache" ;;
    s3-*)
      echo "s3" ;;
    lambda-*)
      echo "lambda" ;;
    dynamodb-*)
      echo "dynamodb" ;;
    efs-*)
      echo "efs" ;;
    gp[23]-*|io[12]-*|st1-*|sc1-*)
      echo "ebs" ;;
    cloudfront-*)
      echo "cloudfront" ;;
    apigateway-*)
      echo "apigateway" ;;
    sqs-*)
      echo "sqs" ;;
    sns-*)
      echo "sns" ;;
    route53-*)
      echo "route53" ;;
    alb-*)
      echo "alb" ;;
    natgw-*)
      echo "natgw" ;;
    vpce-*)
      echo "vpce" ;;
    *)
      echo "unknown" ;;
  esac
}

# Query EC2 on-demand pricing via Pricing API
_pricing_ec2() {
  local instance_type="$1"
  local location="$2"
  local show_spot="$3"
  local show_reserved="$4"
  local detailed="$5"

  echo "=== EC2 Pricing: ${instance_type} ==="
  echo "Region: ${location}"
  echo ""

  # On-demand pricing
  echo "--- On-Demand ---"
  aws pricing get-products \
    --service-code AmazonEC2 \
    --region us-east-1 \
    --filters \
      "Type=TERM_MATCH,Field=instanceType,Value=${instance_type}" \
      "Type=TERM_MATCH,Field=location,Value=${location}" \
      "Type=TERM_MATCH,Field=tenancy,Value=Shared" \
      "Type=TERM_MATCH,Field=operatingSystem,Value=Linux" \
      "Type=TERM_MATCH,Field=preInstalledSw,Value=NA" \
      "Type=TERM_MATCH,Field=capacitystatus,Value=Used" \
    --output json \
    --query 'PriceList' \
    | python3 -c "
import json, sys
prices = json.load(sys.stdin)
if not prices:
    print('No pricing data found for this instance type and region.')
    sys.exit(0)

product = json.loads(prices[0])
attrs = product.get('product', {}).get('attributes', {})
print(f'Instance Type: {attrs.get(\"instanceType\", \"N/A\")}')
print(f'vCPU: {attrs.get(\"vcpu\", \"N/A\")}')
print(f'Memory: {attrs.get(\"memory\", \"N/A\")}')
print(f'Storage: {attrs.get(\"storage\", \"N/A\")}')
print(f'Network: {attrs.get(\"networkPerformance\", \"N/A\")}')

terms = product.get('terms', {})
od = terms.get('OnDemand', {})
for term_key, term_val in od.items():
    for dim_key, dim_val in term_val.get('priceDimensions', {}).items():
        price = float(dim_val['pricePerUnit'].get('USD', 0))
        if price > 0:
            monthly = price * 730
            print(f'On-Demand: \${price:.4f}/hr (\${monthly:,.2f}/mo)')
            break
    break
"

  # Reserved pricing
  if [[ "$show_reserved" == true ]]; then
    echo ""
    echo "--- Reserved (1yr, No Upfront) ---"
    aws pricing get-products \
      --service-code AmazonEC2 \
      --region us-east-1 \
      --filters \
        "Type=TERM_MATCH,Field=instanceType,Value=${instance_type}" \
        "Type=TERM_MATCH,Field=location,Value=${location}" \
        "Type=TERM_MATCH,Field=tenancy,Value=Shared" \
        "Type=TERM_MATCH,Field=operatingSystem,Value=Linux" \
        "Type=TERM_MATCH,Field=preInstalledSw,Value=NA" \
        "Type=TERM_MATCH,Field=capacitystatus,Value=Used" \
      --output json \
      --query 'PriceList' \
      | python3 -c "
import json, sys
prices = json.load(sys.stdin)
if not prices:
    print('No reserved pricing data found.')
    sys.exit(0)

product = json.loads(prices[0])
terms = product.get('terms', {})
reserved = terms.get('Reserved', {})
for term_key, term_val in reserved.items():
    desc = term_val.get('termAttributes', {})
    lease = desc.get('LeaseContractLength', '')
    purchase = desc.get('PurchaseOption', '')
    offering = desc.get('OfferingClass', '')
    for dim_key, dim_val in term_val.get('priceDimensions', {}).items():
        price = float(dim_val['pricePerUnit'].get('USD', 0))
        unit = dim_val.get('unit', '')
        if price > 0 and 'Hrs' in unit:
            monthly = price * 730
            print(f'{lease} {offering} {purchase}: \${price:.4f}/hr (\${monthly:,.2f}/mo)')
" 2>/dev/null || echo "(Reserved pricing lookup failed)"
  fi

  # Spot pricing
  if [[ "$show_spot" == true ]]; then
    echo ""
    echo "--- Spot (current) ---"
    # Convert location name back to region code for spot API
    local region_code
    region_code=$(aws ec2 describe-availability-zones \
      --output text \
      --query 'AvailabilityZones[0].RegionName' 2>/dev/null || echo "us-east-1")
    aws ec2 describe-spot-price-history \
      --instance-types "$instance_type" \
      --product-descriptions "Linux/UNIX" \
      --start-time "$(date -u '+%Y-%m-%dT%H:%M:%S')" \
      --output text \
      --query 'SpotPriceHistory[*].[AvailabilityZone,SpotPrice]' \
      | head -5 \
      | awk '{printf "  %s: $%s/hr ($%.2f/mo)\n", $1, $2, $2*730}'
  fi
}

# Query RDS on-demand pricing
_pricing_rds() {
  local instance_type="$1"
  local location="$2"

  echo "=== RDS Pricing: ${instance_type} ==="
  echo "Region: ${location}"
  echo ""

  # Strip 'db.' prefix for display; API uses full name
  echo "--- On-Demand (Single-AZ, MySQL) ---"
  aws pricing get-products \
    --service-code AmazonRDS \
    --region us-east-1 \
    --filters \
      "Type=TERM_MATCH,Field=instanceType,Value=${instance_type}" \
      "Type=TERM_MATCH,Field=location,Value=${location}" \
      "Type=TERM_MATCH,Field=databaseEngine,Value=MySQL" \
      "Type=TERM_MATCH,Field=deploymentOption,Value=Single-AZ" \
    --output json \
    --query 'PriceList' \
    | python3 -c "
import json, sys
prices = json.load(sys.stdin)
if not prices:
    print('No pricing data found. Try a different engine or region.')
    sys.exit(0)

product = json.loads(prices[0])
attrs = product.get('product', {}).get('attributes', {})
print(f'Instance Type: {attrs.get(\"instanceType\", \"N/A\")}')
print(f'vCPU: {attrs.get(\"vcpu\", \"N/A\")}')
print(f'Memory: {attrs.get(\"memory\", \"N/A\")}')
print(f'Engine: {attrs.get(\"databaseEngine\", \"N/A\")}')

terms = product.get('terms', {})
od = terms.get('OnDemand', {})
for term_key, term_val in od.items():
    for dim_key, dim_val in term_val.get('priceDimensions', {}).items():
        price = float(dim_val['pricePerUnit'].get('USD', 0))
        if price > 0:
            monthly = price * 730
            multi_az = monthly * 2
            print(f'Single-AZ: \${price:.4f}/hr (\${monthly:,.2f}/mo)')
            print(f'Multi-AZ:  \${price * 2:.4f}/hr (\${multi_az:,.2f}/mo)')
            break
    break
"
}

# Query ElastiCache pricing
_pricing_elasticache() {
  local instance_type="$1"
  local location="$2"

  echo "=== ElastiCache Pricing: ${instance_type} ==="
  echo "Region: ${location}"
  echo ""

  aws pricing get-products \
    --service-code AmazonElastiCache \
    --region us-east-1 \
    --filters \
      "Type=TERM_MATCH,Field=instanceType,Value=${instance_type}" \
      "Type=TERM_MATCH,Field=location,Value=${location}" \
      "Type=TERM_MATCH,Field=cacheEngine,Value=Redis" \
    --output json \
    --query 'PriceList' \
    | python3 -c "
import json, sys
prices = json.load(sys.stdin)
if not prices:
    print('No pricing data found.')
    sys.exit(0)

product = json.loads(prices[0])
attrs = product.get('product', {}).get('attributes', {})
print(f'Node Type: {attrs.get(\"instanceType\", \"N/A\")}')
print(f'vCPU: {attrs.get(\"vcpu\", \"N/A\")}')
print(f'Memory: {attrs.get(\"memory\", \"N/A\")}')

terms = product.get('terms', {})
od = terms.get('OnDemand', {})
for term_key, term_val in od.items():
    for dim_key, dim_val in term_val.get('priceDimensions', {}).items():
        price = float(dim_val['pricePerUnit'].get('USD', 0))
        if price > 0:
            monthly = price * 730
            print(f'On-Demand: \${price:.4f}/hr (\${monthly:,.2f}/mo)')
            break
    break
"
}

# S3 storage class pricing reference
_pricing_s3() {
  local storage_class="$1"
  local location="$2"

  echo "=== S3 Pricing: ${storage_class} ==="
  echo "Region: ${location}"
  echo ""

  local filter_value
  case "$storage_class" in
    s3-standard)     filter_value="General Purpose" ;;
    s3-ia)           filter_value="Infrequent Access" ;;
    s3-glacier)      filter_value="Amazon Glacier" ;;
    s3-glacier-deep) filter_value="Amazon Glacier Deep Archive" ;;
    *) echo "Unknown S3 class: $storage_class"; return 1 ;;
  esac

  aws pricing get-products \
    --service-code AmazonS3 \
    --region us-east-1 \
    --filters \
      "Type=TERM_MATCH,Field=location,Value=${location}" \
      "Type=TERM_MATCH,Field=storageClass,Value=${filter_value}" \
      "Type=TERM_MATCH,Field=volumeType,Value=${filter_value}" \
    --output json \
    --query 'PriceList[:3]' \
    | python3 -c "
import json, sys
prices = json.load(sys.stdin)
if not prices:
    print('No pricing data found.')
    sys.exit(0)

for p_str in prices:
    product = json.loads(p_str)
    attrs = product.get('product', {}).get('attributes', {})
    terms = product.get('terms', {})
    od = terms.get('OnDemand', {})
    for term_key, term_val in od.items():
        for dim_key, dim_val in term_val.get('priceDimensions', {}).items():
            desc = dim_val.get('description', '')
            price = float(dim_val['pricePerUnit'].get('USD', 0))
            unit = dim_val.get('unit', '')
            if price > 0:
                print(f'  {desc}: \${price}/GB-month')
" 2>/dev/null || echo "S3 pricing lookup returned no results."
}

# Lambda pricing reference
_pricing_lambda() {
  local config="$1"
  local location="$2"

  echo "=== Lambda Pricing: ${config} ==="
  echo "Region: ${location}"
  echo ""

  local memory_mb
  case "$config" in
    lambda-128mb) memory_mb=128 ;;
    lambda-256mb) memory_mb=256 ;;
    lambda-512mb) memory_mb=512 ;;
    lambda-1gb)   memory_mb=1024 ;;
    lambda-2gb)   memory_mb=2048 ;;
    lambda-3gb)   memory_mb=3072 ;;
    lambda-10gb)  memory_mb=10240 ;;
    *) echo "Unknown Lambda config: $config"; return 1 ;;
  esac

  # Lambda pricing: $0.20 per 1M requests + $0.0000166667 per GB-second
  local gb_sec_price=0.0000166667
  local request_price=0.0000002  # per request
  local memory_gb
  memory_gb=$(echo "scale=4; ${memory_mb}/1024" | bc)

  echo "Memory: ${memory_mb} MB (${memory_gb} GB)"
  echo "Request price: \$0.20 per 1M requests (\$0.0000002 per request)"
  echo "Duration price: \$0.0000166667 per GB-second"
  echo ""
  echo "--- Cost Estimates (1M invocations, 1 second avg duration) ---"
  python3 -c "
memory_gb = ${memory_gb}
invocations = 1_000_000
avg_duration_sec = 1.0
gb_seconds = memory_gb * avg_duration_sec * invocations
duration_cost = gb_seconds * ${gb_sec_price}
request_cost = invocations * ${request_price}
total = duration_cost + request_cost
print(f'  Requests:  \${request_cost:,.2f}')
print(f'  Duration:  \${duration_cost:,.2f} ({gb_seconds:,.0f} GB-sec)')
print(f'  Total:     \${total:,.2f}')
print()
print('Scaling examples:')
for inv in [100_000, 500_000, 1_000_000, 5_000_000, 10_000_000]:
    gs = memory_gb * avg_duration_sec * inv
    dc = gs * ${gb_sec_price}
    rc = inv * ${request_price}
    t = dc + rc
    print(f'  {inv:>12,} invocations/mo: \${t:>10,.2f}')
"
}

# DynamoDB pricing
_pricing_dynamodb() {
  local mode="$1"
  local location="$2"

  echo "=== DynamoDB Pricing: ${mode} ==="
  echo "Region: ${location}"
  echo ""

  case "$mode" in
    dynamodb-ondemand)
      echo "--- On-Demand Mode ---"
      echo "  Write: \$1.25 per million WRUs"
      echo "  Read:  \$0.25 per million RRUs"
      echo "  Storage: \$0.25 per GB-month (first 25GB free)"
      echo ""
      echo "--- Cost Examples ---"
      python3 -c "
examples = [
    ('Light', 100_000, 1_000_000, 1),
    ('Medium', 1_000_000, 10_000_000, 10),
    ('Heavy', 10_000_000, 100_000_000, 100),
]
for label, writes, reads, storage_gb in examples:
    w = writes / 1_000_000 * 1.25
    r = reads / 1_000_000 * 0.25
    s = max(0, storage_gb - 25) * 0.25
    total = w + r + s
    print(f'  {label}: {writes:,} writes + {reads:,} reads + {storage_gb}GB = \${total:,.2f}/mo')
"
      ;;
    dynamodb-provisioned)
      echo "--- Provisioned Mode ---"
      echo "  Write: \$0.00065 per WCU/hr (\$0.4745/WCU/mo)"
      echo "  Read:  \$0.00013 per RCU/hr (\$0.0949/RCU/mo)"
      echo "  Storage: \$0.25 per GB-month (first 25GB free)"
      echo ""
      echo "--- Cost Examples ---"
      python3 -c "
examples = [
    ('Light', 5, 25, 1),
    ('Medium', 50, 250, 10),
    ('Heavy', 500, 2500, 100),
]
for label, wcu, rcu, storage_gb in examples:
    w = wcu * 0.4745
    r = rcu * 0.0949
    s = max(0, storage_gb - 25) * 0.25
    total = w + r + s
    print(f'  {label}: {wcu} WCU + {rcu} RCU + {storage_gb}GB = \${total:,.2f}/mo')
"
      ;;
  esac
}

# EFS pricing
_pricing_efs() {
  local tier="$1"
  local location="$2"

  echo "=== EFS Pricing: ${tier} ==="
  echo "Region: ${location}"
  echo ""

  case "$tier" in
    efs-standard)
      echo "  Storage: \$0.30/GB-month"
      echo "  Throughput (bursting): included with storage"
      echo "  Throughput (provisioned): \$6.00/MBps-month"
      echo ""
      echo "--- Cost Examples ---"
      for gb in 10 50 100 500 1000; do
        cost=$(echo "scale=2; ${gb} * 0.30" | bc)
        echo "  ${gb} GB: \$${cost}/mo"
      done
      ;;
    efs-ia)
      echo "  Storage: \$0.025/GB-month"
      echo "  Read access: \$0.01/GB transferred"
      echo ""
      echo "--- Cost Examples ---"
      for gb in 100 500 1000 5000; do
        cost=$(echo "scale=2; ${gb} * 0.025" | bc)
        echo "  ${gb} GB: \$${cost}/mo (storage only)"
      done
      ;;
  esac
}

# EBS pricing
_pricing_ebs() {
  local config="$1"
  local location="$2"

  echo "=== EBS Pricing: ${config} ==="
  echo "Region: ${location}"
  echo ""

  local vol_type size_gb
  vol_type=$(echo "$config" | cut -d'-' -f1)
  size_gb=$(echo "$config" | sed 's/[^0-9]//g')

  case "$vol_type" in
    gp3)
      local gb_price=0.08
      local iops_baseline=3000
      local throughput_baseline=125
      local cost
      cost=$(echo "scale=2; ${size_gb} * ${gb_price}" | bc)
      echo "  Type: gp3"
      echo "  Size: ${size_gb} GB"
      echo "  Baseline IOPS: ${iops_baseline} (free)"
      echo "  Baseline Throughput: ${throughput_baseline} MBps (free)"
      echo "  Storage cost: \$${cost}/mo (\$${gb_price}/GB-mo)"
      echo "  Extra IOPS: \$0.005/IOPS-mo (above ${iops_baseline})"
      echo "  Extra Throughput: \$0.040/MBps-mo (above ${throughput_baseline} MBps)"
      ;;
    gp2)
      local gb_price=0.10
      local iops_baseline
      iops_baseline=$(python3 -c "print(max(100, 3 * ${size_gb}))")
      local cost
      cost=$(echo "scale=2; ${size_gb} * ${gb_price}" | bc)
      echo "  Type: gp2"
      echo "  Size: ${size_gb} GB"
      echo "  Baseline IOPS: ${iops_baseline} (3 per GB, min 100)"
      echo "  Storage cost: \$${cost}/mo (\$${gb_price}/GB-mo)"
      echo ""
      echo "  NOTE: Consider GP3 migration for better IOPS at lower cost."
      local gp3_cost
      gp3_cost=$(echo "scale=2; ${size_gb} * 0.08" | bc)
      echo "  GP3 equivalent: \$${gp3_cost}/mo with 3000 IOPS baseline"
      ;;
    io2|io1)
      local gb_price=0.125
      local iops_price=0.065
      # Extract IOPS from config if present, default to 3000
      local iops=3000
      local storage_cost iops_cost total_cost
      storage_cost=$(echo "scale=2; ${size_gb} * ${gb_price}" | bc)
      iops_cost=$(echo "scale=2; ${iops} * ${iops_price}" | bc)
      total_cost=$(echo "scale=2; ${storage_cost} + ${iops_cost}" | bc)
      echo "  Type: ${vol_type}"
      echo "  Size: ${size_gb} GB"
      echo "  Provisioned IOPS: ${iops} (default estimate)"
      echo "  Storage: \$${storage_cost}/mo (\$${gb_price}/GB-mo)"
      echo "  IOPS:    \$${iops_cost}/mo (\$${iops_price}/IOPS-mo)"
      echo "  Total:   \$${total_cost}/mo"
      ;;
    st1)
      local gb_price=0.045
      local cost
      cost=$(echo "scale=2; ${size_gb} * ${gb_price}" | bc)
      echo "  Type: st1 (Throughput Optimized HDD)"
      echo "  Size: ${size_gb} GB"
      echo "  Cost: \$${cost}/mo (\$${gb_price}/GB-mo)"
      ;;
    sc1)
      local gb_price=0.015
      local cost
      cost=$(echo "scale=2; ${size_gb} * ${gb_price}" | bc)
      echo "  Type: sc1 (Cold HDD)"
      echo "  Size: ${size_gb} GB"
      echo "  Cost: \$${cost}/mo (\$${gb_price}/GB-mo)"
      ;;
  esac
}

# Static pricing for services without Pricing API support
_pricing_static() {
  local resource="$1"
  local location="$2"

  case "$resource" in
    cloudfront-standard)
      echo "=== CloudFront Pricing ==="
      echo "Region: ${location}"
      echo ""
      echo "  First 10 TB/mo: \$0.085/GB (US/EU)"
      echo "  Next 40 TB/mo:  \$0.080/GB"
      echo "  Next 100 TB/mo: \$0.060/GB"
      echo "  Requests (HTTP):  \$0.0075 per 10,000"
      echo "  Requests (HTTPS): \$0.0100 per 10,000"
      echo "  Origin Shield:    \$0.0090 per 10,000"
      ;;
    apigateway-rest)
      echo "=== API Gateway (REST) Pricing ==="
      echo "Region: ${location}"
      echo ""
      echo "  First 333M calls/mo: \$3.50 per million"
      echo "  Next 667M calls/mo:  \$2.80 per million"
      echo "  Over 1B calls/mo:    \$2.38 per million"
      echo "  Caching (0.5GB): \$0.020/hr (\$14.60/mo)"
      ;;
    apigateway-http)
      echo "=== API Gateway (HTTP) Pricing ==="
      echo "Region: ${location}"
      echo ""
      echo "  First 300M calls/mo: \$1.00 per million"
      echo "  Over 300M calls/mo:  \$0.90 per million"
      ;;
    sqs-standard)
      echo "=== SQS Standard Pricing ==="
      echo "Region: ${location}"
      echo ""
      echo "  First 1M requests/mo: Free"
      echo "  After 1M: \$0.40 per million requests"
      echo "  Data transfer: Standard AWS rates"
      ;;
    sqs-fifo)
      echo "=== SQS FIFO Pricing ==="
      echo "Region: ${location}"
      echo ""
      echo "  First 1M requests/mo: Free"
      echo "  After 1M: \$0.50 per million requests"
      ;;
    sns-standard)
      echo "=== SNS Pricing ==="
      echo "Region: ${location}"
      echo ""
      echo "  First 1M publishes/mo: Free"
      echo "  After 1M: \$0.50 per million"
      echo "  SMS: varies by destination country"
      echo "  Email: \$2.00 per 100,000"
      ;;
    route53-hosted-zone)
      echo "=== Route 53 Hosted Zone Pricing ==="
      echo ""
      echo "  \$0.50/hosted zone/month (first 25 zones)"
      echo "  \$0.10/hosted zone/month (additional)"
      ;;
    route53-query)
      echo "=== Route 53 Query Pricing ==="
      echo ""
      echo "  Standard: \$0.40 per million queries"
      echo "  Latency-based: \$0.60 per million queries"
      echo "  Geo DNS: \$0.70 per million queries"
      ;;
    alb-standard)
      echo "=== ALB Pricing ==="
      echo "Region: ${location}"
      echo ""
      echo "  Fixed: \$0.0225/hr (\$16.43/mo)"
      echo "  LCU:   \$0.008/LCU-hr"
      echo "  LCU = max of: 25 new conn/s, 3000 active conn/min, 1 GB/hr, 1000 rules evaluated/s"
      ;;
    natgw-standard)
      echo "=== NAT Gateway Pricing ==="
      echo "Region: ${location}"
      echo ""
      echo "  Fixed: \$0.045/hr (\$32.40/mo)"
      echo "  Data:  \$0.045/GB processed"
      ;;
    vpce-gateway)
      echo "=== VPC Gateway Endpoint Pricing ==="
      echo "Region: ${location}"
      echo ""
      echo "  Free (S3 and DynamoDB endpoints)"
      ;;
    vpce-interface)
      echo "=== VPC Interface Endpoint Pricing ==="
      echo "Region: ${location}"
      echo ""
      echo "  Per AZ: \$0.01/hr (\$7.30/mo)"
      echo "  Data:   \$0.01/GB processed"
      echo "  Typical 3-AZ: \$21.90/mo + data"
      ;;
    *)
      echo "Unsupported resource: $resource"
      echo ""
      echo "To query manually, use the AWS Pricing API:"
      echo "  aws pricing get-products --service-code <ServiceCode> --region us-east-1 \\"
      echo "    --filters 'Type=TERM_MATCH,Field=location,Value=${location}'"
      echo ""
      echo "Common service codes: AmazonEC2, AmazonRDS, AmazonS3, AmazonElastiCache,"
      echo "  AWSLambda, AmazonDynamoDB, AmazonEFS, AmazonEBS"
      return 1
      ;;
  esac
}

# ── Public Function ──────────────────────────────────────────────────────────

get_aws_cost() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: get_aws_cost <resource> <region> [--spot] [--detailed] [--no-reserved]"
    echo ""
    echo "Examples:"
    echo "  get_aws_cost t3.micro \"US East (N. Virginia)\" --spot"
    echo "  get_aws_cost db.t3.micro \"Asia Pacific (Singapore)\""
    echo "  get_aws_cost s3-standard \"US East (N. Virginia)\""
    echo "  get_aws_cost lambda-1gb \"US East (N. Virginia)\""
    return 1
  fi

  local resource="$1"
  local region="$2"
  shift 2

  local show_spot=false
  local show_reserved=true
  local detailed=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --spot)        show_spot=true; shift ;;
      --detailed)    detailed=true; shift ;;
      --no-reserved) show_reserved=false; shift ;;
      *) shift ;;
    esac
  done

  local location
  location=$(_pricing_normalize_region "$region")

  local resource_type
  resource_type=$(_pricing_detect_type "$resource")

  case "$resource_type" in
    ec2)         _pricing_ec2 "$resource" "$location" "$show_spot" "$show_reserved" "$detailed" ;;
    rds)         _pricing_rds "$resource" "$location" ;;
    elasticache) _pricing_elasticache "$resource" "$location" ;;
    s3)          _pricing_s3 "$resource" "$location" ;;
    lambda)      _pricing_lambda "$resource" "$location" ;;
    dynamodb)    _pricing_dynamodb "$resource" "$location" ;;
    efs)         _pricing_efs "$resource" "$location" ;;
    ebs)         _pricing_ebs "$resource" "$location" ;;
    *)           _pricing_static "$resource" "$location" ;;
  esac
}
