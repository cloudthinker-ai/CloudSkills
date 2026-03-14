---
name: managing-terraform-enterprise
description: |
  Terraform Enterprise administration and workspace management. Covers TFE installation health, admin settings, workspace operations, Sentinel policies, cost estimation, private module registry, and audit log analysis. Use when administering a self-hosted TFE instance, managing workspaces, or troubleshooting enterprise-specific features.
connection_type: terraform-enterprise
preload: false
---

# Terraform Enterprise Management Skill

Administer self-hosted Terraform Enterprise instances, workspaces, policies, and private registries.

## MANDATORY: Discovery-First Pattern

**Always check TFE instance health and admin status before operations.**

### Phase 1: Discovery

```bash
#!/bin/bash
TFE_TOKEN="${TFE_TOKEN:?TFE_TOKEN required}"
TFE_ADDR="${TFE_ADDR:?TFE_ADDR required}"
API="$TFE_ADDR/api/v2"
AUTH="Authorization: Bearer $TFE_TOKEN"

echo "=== TFE Health ==="
curl -sk "$TFE_ADDR/_health_check" | head -5

echo ""
echo "=== Admin Organizations ==="
curl -sk -H "$AUTH" "$API/admin/organizations" | jq -r '.data[] | "\(.attributes.name) | workspaces=\(.attributes."workspace-count") | \(.attributes."plan-name")"' | head -15

echo ""
echo "=== Admin Runs Queue ==="
curl -sk -H "$AUTH" "$API/admin/runs?filter[status]=pending,planning,applying" | jq -r '.data[] | "\(.id) | \(.attributes.status) | \(.attributes."created-at")"' | head -10

echo ""
echo "=== Sentinel Policies ==="
curl -sk -H "$AUTH" "$API/admin/policy-sets" | jq -r '.data[] | "\(.attributes.name) | scope=\(.attributes.scope) | enforced=\(.attributes.enforced)"' 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash
TFE_TOKEN="${TFE_TOKEN:?TFE_TOKEN required}"
TFE_ADDR="${TFE_ADDR:?TFE_ADDR required}"
API="$TFE_ADDR/api/v2"
AUTH="Authorization: Bearer $TFE_TOKEN"

echo "=== Capacity and Agents ==="
curl -sk -H "$AUTH" "$API/admin/terraform-versions" | jq -r '.data[:5][] | "\(.attributes.version) | official=\(.attributes.official) | enabled=\(.attributes.enabled)"'

echo ""
echo "=== Module Registry ==="
curl -sk -H "$AUTH" "$API/admin/module-sharing" | jq '.' 2>/dev/null

echo ""
echo "=== Audit Log (Recent) ==="
curl -sk -H "$AUTH" "$API/organization/audit-trail?page[size]=10" | jq -r '.data[]? | "\(.attributes.timestamp) | \(.attributes.type) | \(.attributes.action) | \(.attributes.actor.name)"' | head -10

echo ""
echo "=== SAML/SSO Status ==="
curl -sk -H "$AUTH" "$API/admin/saml-settings" | jq '{enabled: .data.attributes.enabled, idp_cert_present: (.data.attributes."idp-cert" != null), slo_url: .data.attributes."slo-endpoint-url"}' 2>/dev/null
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Always use `-k` flag for self-signed certs common in TFE
- Summarize admin metrics rather than full dumps
- Redact tokens and SAML certificates

## Safety Rules
- **NEVER modify admin settings without explicit confirmation**
- **Check TFE health** before administrative operations
- **Backup state** before state migration operations
- **Verify Sentinel policy impacts** before enforcement changes
- **Audit log review** before granting elevated permissions
