---
name: aws-cloudtrail
description: |
  AWS CloudTrail event analysis, trail management, insight event investigation, and organization trail configuration. Covers API activity analysis, security event investigation, resource change tracking, unauthorized access detection, and event history querying.
connection_type: aws
preload: false
---

# AWS CloudTrail Skill

Analyze AWS CloudTrail events and trails with parallel execution and anti-hallucination guardrails.

**Relationship to other AWS skills:**

- `aws-cloudtrail/` → CloudTrail-specific analysis (events, trails, insights)
- `aws/` → "How to execute" (parallel patterns, throttling, output format)

## CRITICAL: Parallel Execution Requirement

**ALL independent operations MUST run in parallel using background jobs (&) and wait.**

```bash
#!/bin/bash
export AWS_PAGER=""

for trail in $trails; do
  get_trail_status "$trail" &
done
wait
```

## Helper Functions

```bash
#!/bin/bash
export AWS_PAGER=""

# List trails
list_trails() {
  aws cloudtrail describe-trails \
    --output text \
    --query 'trailList[].[Name,IsMultiRegionTrail,IsOrganizationTrail,S3BucketName,HomeRegion,HasCustomEventSelectors]'
}

# Get trail status
get_trail_status() {
  local trail_name=$1
  aws cloudtrail get-trail-status --name "$trail_name" \
    --output text \
    --query '[IsLogging,LatestDeliveryTime,LatestDeliveryError,LatestNotificationTime,LatestNotificationError]'
}

# Lookup events (last N hours)
lookup_events() {
  local attribute_key=$1 attribute_value=$2 hours=${3:-24}
  local end_time start_time
  end_time=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  start_time=$(date -u -d "$hours hours ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v-${hours}H +"%Y-%m-%dT%H:%M:%SZ")
  aws cloudtrail lookup-events \
    --lookup-attributes AttributeKey="$attribute_key",AttributeValue="$attribute_value" \
    --start-time "$start_time" --end-time "$end_time" \
    --max-results 20 \
    --output text \
    --query 'Events[].[EventTime,EventName,Username,Resources[0].ResourceName]'
}

# Get event selectors
get_event_selectors() {
  local trail_name=$1
  aws cloudtrail get-event-selectors --trail-name "$trail_name" \
    --output text \
    --query '[EventSelectors[].[ReadWriteType,IncludeManagementEvents,DataResources[].Type],AdvancedEventSelectors[].Name]'
}

# Get insight selectors
get_insight_selectors() {
  local trail_name=$1
  aws cloudtrail get-insight-selectors --trail-name "$trail_name" \
    --output text \
    --query 'InsightSelectors[].[InsightType]' 2>/dev/null
}
```

## Common Operations

### 1. Trail Inventory and Health

```bash
#!/bin/bash
export AWS_PAGER=""
TRAILS=$(aws cloudtrail describe-trails --output text --query 'trailList[].Name')
for trail in $TRAILS; do
  {
    config=$(aws cloudtrail describe-trails --trail-name-list "$trail" \
      --output text --query 'trailList[].[Name,IsMultiRegionTrail,IsOrganizationTrail,S3BucketName,LogFileValidationEnabled]')
    status=$(aws cloudtrail get-trail-status --name "$trail" \
      --output text --query '[IsLogging,LatestDeliveryTime]')
    printf "%s\t%s\n" "$config" "$status"
  } &
done
wait
```

### 2. Recent API Activity by User

```bash
#!/bin/bash
export AWS_PAGER=""
USERNAME=$1
END=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
START=$(date -u -d "24 hours ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v-24H +"%Y-%m-%dT%H:%M:%SZ")
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue="$USERNAME" \
  --start-time "$START" --end-time "$END" \
  --max-results 50 \
  --output text \
  --query 'Events[].[EventTime,EventName,EventSource,Resources[0].ResourceName]' | sort -k1
```

### 3. Security Event Investigation

```bash
#!/bin/bash
export AWS_PAGER=""
END=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
START=$(date -u -d "24 hours ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v-24H +"%Y-%m-%dT%H:%M:%SZ")

# Check for console login events
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=ConsoleLogin \
  --start-time "$START" --end-time "$END" --max-results 20 \
  --output text \
  --query 'Events[].[EventTime,Username,Resources[0].ResourceName]' &

# Check for IAM changes
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventSource,AttributeValue=iam.amazonaws.com \
  --start-time "$START" --end-time "$END" --max-results 20 \
  --output text \
  --query 'Events[].[EventTime,EventName,Username]' &
wait
```

### 4. Resource Change Tracking

```bash
#!/bin/bash
export AWS_PAGER=""
RESOURCE_NAME=$1
END=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
START=$(date -u -d "7 days ago" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || date -u -v-7d +"%Y-%m-%dT%H:%M:%SZ")
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue="$RESOURCE_NAME" \
  --start-time "$START" --end-time "$END" --max-results 50 \
  --output text \
  --query 'Events[].[EventTime,EventName,Username,EventSource]' | sort -k1
```

### 5. Event Selector Audit

```bash
#!/bin/bash
export AWS_PAGER=""
TRAILS=$(aws cloudtrail describe-trails --output text --query 'trailList[].Name')
for trail in $TRAILS; do
  {
    selectors=$(aws cloudtrail get-event-selectors --trail-name "$trail" \
      --output text \
      --query '[EventSelectors[].[ReadWriteType,IncludeManagementEvents],AdvancedEventSelectors[].Name]')
    printf "%s\t%s\n" "$trail" "$selectors"
  } &
done
wait
```

## Anti-Hallucination Rules

1. **lookup-events has 90-day limit** - CloudTrail `lookup-events` API only covers the last 90 days of management events. For older events, query S3 directly or use Athena.
2. **Management vs data events** - Management events (API calls like CreateBucket) are logged by default. Data events (S3 object access, Lambda invocations) require explicit configuration.
3. **CloudTrailEvent field is JSON string** - The `CloudTrailEvent` field in lookup-events results is a JSON string, not parsed JSON. Use `jq` with `fromjson` to parse it.
4. **Read-only vs write-only** - Event selectors can filter by ReadWriteType: All, ReadOnly, WriteOnly. Check this before assuming all events are captured.
5. **Organization trails** - Organization trails log events for all accounts. But member account users may not have access to query the trail.

## Common Pitfalls

- **Event delivery delay**: CloudTrail events can take up to 15 minutes to appear in lookup-events API.
- **Log file validation**: If `LogFileValidationEnabled` is false, log integrity cannot be verified. This is a security concern.
- **Insight events**: CloudTrail Insights detects unusual API activity. Must be explicitly enabled per trail. Costs extra.
- **CloudWatch statistics syntax**: Use spaces not commas: `--statistics Average Maximum`.
- **S3 data events volume**: Enabling S3 data events can generate massive volumes. Use advanced event selectors to filter by bucket/prefix.
