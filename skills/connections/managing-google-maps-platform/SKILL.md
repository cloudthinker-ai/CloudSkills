---
name: managing-google-maps-platform
description: |
  Google Maps Platform management including API key configuration, usage metrics, billing, quota monitoring, and service health across Maps, Routes, Places, and Geocoding APIs. Covers cost analysis, quota utilization, key restriction auditing, and error rate monitoring.
connection_type: google-maps-platform
preload: false
---

# Google Maps Platform Management Skill

Monitor and manage Google Maps Platform services and costs.

## MANDATORY: Discovery-First Pattern

**Always discover enabled APIs and key restrictions before querying usage metrics.**

### Phase 1: Discovery

```bash
#!/bin/bash
PROJECT="${GCP_PROJECT_ID}"

echo "=== Enabled Maps APIs ==="
gcloud services list --enabled --project="$PROJECT" \
  --filter="config.name:maps OR config.name:places OR config.name:geocoding OR config.name:directions OR config.name:routes OR config.name:elevation" \
  --format="table(config.name, config.title)"

echo ""
echo "=== API Keys ==="
gcloud services api-keys list --project="$PROJECT" \
  --format="table(name.basename(), displayName, restrictions.apiTargets[0].service)"

echo ""
echo "=== Key Restrictions Audit ==="
for key in $(gcloud services api-keys list --project="$PROJECT" --format="value(name.basename())"); do
  gcloud services api-keys describe "$key" --project="$PROJECT" \
    --format="json" | jq -r '"Key: \(.displayName // .uid)\n  API Restrictions: \(.restrictions.apiTargets // ["UNRESTRICTED"] | length)\n  App Restrictions: \(.restrictions.browserKeyRestrictions // .restrictions.androidKeyRestrictions // .restrictions.iosKeyRestrictions // "NONE")"'
done

echo ""
echo "=== Quota Overview ==="
gcloud services quotas list --service=maps-backend.googleapis.com --project="$PROJECT" \
  --format="table(metric, limit, usage)" 2>/dev/null || echo "Check quotas in Cloud Console"
```

**Phase 1 outputs:** Enabled APIs, key config, restrictions, quotas

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== API Usage (last 7 days) ==="
for api in maps-backend.googleapis.com geocoding-backend.googleapis.com directions-backend.googleapis.com places-backend.googleapis.com; do
  usage=$(gcloud monitoring time-series list \
    --project="$PROJECT" \
    --filter="metric.type=\"serviceruntime.googleapis.com/api/request_count\" AND resource.labels.service=\"$api\"" \
    --interval-start-time="$(date -v-7d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -d '7 days ago' +%Y-%m-%dT%H:%M:%SZ)" \
    --format="value(points[0].value.int64Value)" 2>/dev/null)
  echo "$api: ${usage:-0} requests"
done

echo ""
echo "=== Error Rates ==="
gcloud monitoring time-series list \
  --project="$PROJECT" \
  --filter='metric.type="serviceruntime.googleapis.com/api/request_count" AND metric.labels.response_code!="200"' \
  --interval-start-time="$(date -v-1d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -d '1 day ago' +%Y-%m-%dT%H:%M:%SZ)" \
  --format="table(metric.labels.service, metric.labels.response_code, points[0].value.int64Value)" 2>/dev/null || echo "Check error rates in Cloud Console"

echo ""
echo "=== Billing Estimate ==="
gcloud billing accounts list --format="table(name, displayName, open)" 2>/dev/null
echo "Note: Check billing dashboard for Maps Platform SKU costs"
```

## Output Format

```
GOOGLE MAPS PLATFORM STATUS
============================
Project: {project_id}
Enabled APIs: {count}
API Keys: {count} ({restricted}/{total} restricted)
7-Day Requests: Maps={count} Geocoding={count} Directions={count}
Error Rate: {percent}%
Unrestricted Keys: {count} (security risk)
Issues: {list_of_warnings}
```

## Common Pitfalls

- **Unrestricted keys**: Always restrict API keys by API and application — unrestricted keys are a billing risk
- **$200 monthly credit**: Google provides $200/month free — monitor usage to stay within
- **SKU pricing**: Different request types have different costs — dynamic maps cost more than static
- **Client-side vs Server-side**: Client-side requests use different quotas and pricing
