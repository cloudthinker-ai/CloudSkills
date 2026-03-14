---
name: managing-aws-iot-core
description: |
  AWS IoT Core management including things, thing groups, certificates, policies, rules, topic monitoring, device shadows, and fleet indexing. Covers device connectivity health, message throughput, rule action errors, certificate expiration, and shadow drift analysis.
connection_type: aws-iot-core
preload: false
---

# AWS IoT Core Management Skill

Monitor and manage AWS IoT Core device fleet and messaging infrastructure.

## MANDATORY: Discovery-First Pattern

**Always discover things, certificates, and rules before querying metrics or shadows.**

### Phase 1: Discovery

```bash
#!/bin/bash
REGION="${AWS_REGION:-us-east-1}"

echo "=== IoT Endpoint ==="
aws iot describe-endpoint --endpoint-type iot:Data-ATS --region "$REGION" \
  --query 'endpointAddress' --output text

echo ""
echo "=== Thing Summary ==="
aws iot list-things --region "$REGION" --max-items 20 \
  --query 'things[].{Name:thingName,Type:thingTypeName,Version:version}' \
  --output table

echo ""
echo "=== Thing Groups ==="
aws iot list-thing-groups --region "$REGION" \
  --query 'thingGroups[].{Name:groupName,ARN:groupArn}' \
  --output table

echo ""
echo "=== Thing Types ==="
aws iot list-thing-types --region "$REGION" \
  --query 'thingTypes[].{Name:thingTypeName,Deprecated:thingTypeProperties.deprecated}' \
  --output table

echo ""
echo "=== Certificates ==="
aws iot list-certificates --region "$REGION" \
  --query 'certificates[].{ID:certificateId,Status:status,Created:creationDate}' \
  --output table | head -15

echo ""
echo "=== IoT Rules ==="
aws iot list-topic-rules --region "$REGION" \
  --query 'rules[].{Name:ruleName,Created:createdAt,Disabled:ruleDisabled}' \
  --output table
```

**Phase 1 outputs:** Endpoint, things, groups, types, certificates, rules

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Fleet Connectivity (via indexing) ==="
aws iot search-index --region "$REGION" \
  --query-string "connectivity.connected:true" \
  --query 'things | length(@)' --output text 2>/dev/null | \
  xargs -I{} echo "Connected things: {}" || echo "Fleet indexing not enabled"

echo ""
echo "=== Certificate Expiration Check ==="
for cert_id in $(aws iot list-certificates --region "$REGION" --query 'certificates[].certificateId' --output text | head -10); do
  aws iot describe-certificate --certificate-id "$cert_id" --region "$REGION" \
    --query '{ID:certificateDescription.certificateId,Status:certificateDescription.status,Expiry:certificateDescription.validity.notAfter}' \
    --output json | jq -r '"\(.ID[:12]) | Status: \(.Status) | Expires: \(.Expiry)"'
done

echo ""
echo "=== Rule Action Errors (24h) ==="
aws cloudwatch get-metric-statistics --namespace AWS/IoT \
  --metric-name RuleActionFailure --period 86400 \
  --start-time "$(date -u -v-1d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%SZ)" \
  --end-time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --statistics Sum --region "$REGION" \
  --query 'Datapoints[0].Sum' --output text

echo ""
echo "=== Message Broker Metrics (24h) ==="
for metric in PublishIn.Success Subscribe.Success Connect.Success; do
  val=$(aws cloudwatch get-metric-statistics --namespace AWS/IoT \
    --metric-name "$metric" --period 86400 \
    --start-time "$(date -u -v-1d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '1 day ago' +%Y-%m-%dT%H:%M:%SZ)" \
    --end-time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --statistics Sum --region "$REGION" \
    --query 'Datapoints[0].Sum' --output text 2>/dev/null)
  echo "$metric: ${val:-0}"
done
```

## Output Format

```
AWS IOT CORE STATUS
===================
Region: {region} | Endpoint: {endpoint}
Things: {count} | Connected: {count}
Thing Groups: {count} | Types: {count}
Certificates: {active}/{total} (expiring soon: {count})
Rules: {enabled}/{total}
24h Messages: {publish} published, {subscribe} subscribed
Rule Failures (24h): {count}
Issues: {list_of_warnings}
```

## Common Pitfalls

- **Fleet indexing**: Must be enabled separately — required for connectivity queries
- **Certificate rotation**: Certificates expire — set up automated rotation
- **Rule SQL versioning**: IoT SQL has versions (2015-10-08, 2016-03-23) — check rule SQL version
- **Topic depth**: Max 8 topic levels — design topic hierarchy carefully
