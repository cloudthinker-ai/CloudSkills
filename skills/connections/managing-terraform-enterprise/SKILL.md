---
name: managing-terraform-enterprise
description: |
  Use when working with Terraform Enterprise — terraform Enterprise
  administration and workspace management. Covers TFE installation health, admin
  settings, workspace operations, Sentinel policies, cost estimation, private
  module registry, and audit log analysis. Use when administering a self-hosted
  TFE instance, managing workspaces, or troubleshooting enterprise-specific
  features.
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

## Output Format

Present results as a structured report:
```
Managing Terraform Enterprise Report
════════════════════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

## Anti-Hallucination Rules

1. **NEVER assume resource names** — always discover via CLI/API in Phase 1 before referencing in Phase 2.
2. **NEVER fabricate metric names or dimensions** — verify against the service documentation or `--help` output.
3. **NEVER mix CLI commands between service versions** — confirm which version/API you are targeting.
4. **ALWAYS use the discovery → verify → analyze chain** — every resource referenced must have been discovered first.
5. **ALWAYS handle empty results gracefully** — an empty response is valid data, not an error to retry.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

