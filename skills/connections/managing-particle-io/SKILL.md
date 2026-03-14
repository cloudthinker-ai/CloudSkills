---
name: managing-particle-io
description: |
  Particle IoT platform management including device fleet, firmware, products, events, integrations, and SIM cards. Covers device connectivity monitoring, OTA firmware deployment status, data usage tracking, event stream health, and fleet-wide diagnostics.
connection_type: particle-io
preload: false
---

# Particle IoT Management Skill

Monitor and manage Particle IoT device fleet and cloud services.

## MANDATORY: Discovery-First Pattern

**Always discover products and devices before querying events or diagnostics.**

### Phase 1: Discovery

```bash
#!/bin/bash
PARTICLE_API="https://api.particle.io/v1"
AUTH="Authorization: Bearer ${PARTICLE_ACCESS_TOKEN}"

echo "=== User Info ==="
curl -s -H "$AUTH" "$PARTICLE_API/user" | \
  jq -r '"Username: \(.username)\nTier: \(.account_info.tier // "free")"'

echo ""
echo "=== Products ==="
curl -s -H "$AUTH" "$PARTICLE_API/user/products" | \
  jq -r '.products[] | "\(.name) | ID: \(.id) | Platform: \(.platform_id) | Devices: \(.device_count)"'

echo ""
echo "=== Devices ==="
curl -s -H "$AUTH" "$PARTICLE_API/devices" | \
  jq -r '.[] | "\(.name) | ID: \(.id) | Online: \(.online) | Platform: \(.platform_id) | FW: \(.system_firmware_version)"' | head -20

echo ""
echo "=== Device Summary ==="
curl -s -H "$AUTH" "$PARTICLE_API/devices" | \
  jq -r '"Total: \(length)\nOnline: \([.[] | select(.online==true)] | length)\nOffline: \([.[] | select(.online==false)] | length)"'

echo ""
echo "=== Integrations (Webhooks) ==="
curl -s -H "$AUTH" "$PARTICLE_API/integrations" | \
  jq -r '.[] | "\(.name // .id) | Type: \(.integrationType) | Event: \(.event) | Enabled: \(.disabled | not)"'
```

**Phase 1 outputs:** User info, products, devices, connectivity, integrations

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Firmware Versions ==="
curl -s -H "$AUTH" "$PARTICLE_API/devices" | \
  jq -r '[.[].system_firmware_version] | group_by(.) | map({version: .[0], count: length}) | sort_by(-.count) | .[] | "\(.version): \(.count) devices"'

echo ""
echo "=== Product Firmware ==="
for product_id in $(curl -s -H "$AUTH" "$PARTICLE_API/user/products" | jq -r '.products[].id'); do
  curl -s -H "$AUTH" "$PARTICLE_API/products/$product_id/firmware" | \
    jq -r '.[] | "\(.title // "v\(.version)") | Version: \(.version) | Size: \(.size) | Uploaded: \(.uploaded_on)"' | head -3
done

echo ""
echo "=== SIM Card Status ==="
curl -s -H "$AUTH" "$PARTICLE_API/sims" | \
  jq -r '.sims[:10] | .[] | "\(.iccid) | Status: \(.status) | Data: \(.data_usage_mb // 0)MB | Device: \(.device_name // "unassigned")"' 2>/dev/null || echo "No SIM management available"

echo ""
echo "=== Recent Events ==="
curl -s -H "$AUTH" "$PARTICLE_API/devices/events?limit=10" | \
  jq -r '.[] | "\(.name) | Device: \(.coreid) | Data: \(.data[:50]) | \(.published_at)"' 2>/dev/null || echo "Use SSE stream for events"

echo ""
echo "=== Device Diagnostics ==="
DEVICE_ID=$(curl -s -H "$AUTH" "$PARTICLE_API/devices" | jq -r '.[0].id')
curl -s -H "$AUTH" "$PARTICLE_API/devices/$DEVICE_ID/diagnostics/last" | \
  jq -r '"Signal: \(.diagnostics.network.signal.strength // "N/A")\nRSSI: \(.diagnostics.network.signal.rssi // "N/A")\nRoundTrip: \(.diagnostics.cloud.roundTripTime // "N/A")ms"' 2>/dev/null
```

## Output Format

```
PARTICLE IOT STATUS
===================
Products: {count}
Devices: {total} (Online: {online}, Offline: {offline})
Firmware Versions: {unique_count} in fleet
Integrations: {count} ({enabled} enabled)
SIMs: {active}/{total}
Issues: {list_of_warnings}
```

## Common Pitfalls

- **Product vs Sandbox**: Product devices are fleet-managed; sandbox devices are individual
- **OTA firmware**: Flash targets specific devices or entire product fleet — verify before deploying
- **Rate limits**: 30 requests/second — throttle fleet-wide queries
- **Cellular data**: SIM data caps apply — monitor usage to avoid overage charges
