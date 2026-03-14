---
name: managing-aws-ses-deep
description: |
  Advanced AWS SES management including sending quotas, identity verification, configuration sets, dedicated IPs, reputation dashboard, suppression list, email receiving rules, and deliverability advisor. Goes beyond basic SES to cover DKIM/DMARC compliance, event publishing, and virtual deliverability manager.
connection_type: aws-ses-deep
preload: false
---

# AWS SES Deep Management Skill

Advanced monitoring and management of AWS Simple Email Service.

## MANDATORY: Discovery-First Pattern

**Always discover identities, configuration sets, and account status before querying metrics.**

### Phase 1: Discovery

```bash
#!/bin/bash
REGION="${AWS_REGION:-us-east-1}"

echo "=== Account Sending Status ==="
aws sesv2 get-account --region "$REGION" \
  --query '{ProductionAccess:ProductionAccessEnabled,SendingEnabled:SendingEnabled,Quota:SendQuota,EnforcementStatus:EnforcementStatus}' \
  --output json | jq '.'

echo ""
echo "=== Verified Identities ==="
aws sesv2 list-email-identities --region "$REGION" \
  --query 'EmailIdentities[].{Identity:IdentityName,Type:IdentityType,Sending:SendingEnabled,Verification:VerificationStatus}' \
  --output table

echo ""
echo "=== Configuration Sets ==="
aws sesv2 list-configuration-sets --region "$REGION" \
  --query 'ConfigurationSets[]' --output table

echo ""
echo "=== Dedicated IPs ==="
aws sesv2 get-dedicated-ips --region "$REGION" \
  --query 'DedicatedIps[].{IP:Ip,Warmup:WarmupStatus,WarmupPct:WarmupPercentage,Pool:PoolName}' \
  --output table 2>/dev/null || echo "No dedicated IPs"

echo ""
echo "=== Suppression List Summary ==="
aws sesv2 list-suppressed-destinations --region "$REGION" \
  --query 'SuppressedDestinationSummaries | length(@)' --output text | \
  xargs -I{} echo "Suppressed addresses: {}"
```

**Phase 1 outputs:** Account status, identities, config sets, IPs, suppressions

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Reputation Metrics ==="
aws sesv2 get-account --region "$REGION" \
  --query '{BounceRate:Details.BounceRate,ComplaintRate:Details.ComplaintRate,ReviewStatus:Details.ReviewDetails.Status}' \
  --output json | jq '.'

echo ""
echo "=== DKIM/DMARC Status per Identity ==="
for id in $(aws sesv2 list-email-identities --region "$REGION" --query 'EmailIdentities[].IdentityName' --output text); do
  dkim=$(aws sesv2 get-email-identity --email-identity "$id" --region "$REGION" \
    --query '{DKIM:DkimAttributes.Status,DMARC:Policies.Dmarc}' --output json 2>/dev/null)
  echo "$id | $dkim"
done

echo ""
echo "=== Event Destinations ==="
for cs in $(aws sesv2 list-configuration-sets --region "$REGION" --query 'ConfigurationSets[]' --output text); do
  aws sesv2 get-configuration-set-event-destinations --configuration-set-name "$cs" --region "$REGION" \
    --query "EventDestinations[].{Name:Name,Events:MatchingEventTypes,Enabled:Enabled}" --output table 2>/dev/null
done

echo ""
echo "=== Sending Stats (last 7 days) ==="
aws cloudwatch get-metric-statistics --namespace AWS/SES --metric-name Send \
  --start-time "$(date -u -v-7d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)" \
  --end-time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --period 86400 --statistics Sum --region "$REGION" \
  --query 'Datapoints | sort_by(@, &Timestamp)' --output table
```

## Output Format

```
AWS SES DEEP STATUS
===================
Region: {region} | Production Access: {yes/no}
Sending Quota: {used}/{max} per day
Bounce Rate: {rate}% | Complaint Rate: {rate}%
Identities: {verified}/{total} verified
DKIM: {compliant}/{total} | DMARC: {status}
Dedicated IPs: {count} ({warmup_status})
Config Sets: {count} | Event Destinations: {count}
Suppressions: {count}
Issues: {list_of_warnings}
```

## Common Pitfalls

- **Sandbox mode**: New accounts are sandboxed — can only send to verified addresses
- **Bounce rate threshold**: AWS warns at 5%, suspends at 10% — monitor closely
- **Complaint rate**: Must stay below 0.1% — check feedback loop setup
- **SES v1 vs v2**: Use sesv2 CLI commands — v1 is deprecated
- **Cross-region**: SES identities are regional — verify in each sending region
