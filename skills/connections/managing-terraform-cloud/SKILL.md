---
name: managing-terraform-cloud
description: |
  Use when working with Terraform Cloud — terraform Cloud workspace and run
  management. Covers workspace configuration, run triggers, variable sets,
  policy checks (Sentinel/OPA), VCS integration, state management, and team
  access controls. Use when managing Terraform Cloud workspaces, inspecting
  runs, reviewing policy failures, or auditing organization settings.
connection_type: terraform-cloud
preload: false
---

# Terraform Cloud Management Skill

Manage Terraform Cloud workspaces, runs, policies, and organization settings via the TFC API.

## MANDATORY: Discovery-First Pattern

**Always inspect organization and workspace state before taking action.**

### Phase 1: Discovery

```bash
#!/bin/bash
TFC_TOKEN="${TFC_TOKEN:?TFC_TOKEN required}"
TFC_ORG="${TFC_ORG:?TFC_ORG required}"
API="https://app.terraform.io/api/v2"
AUTH="Authorization: Bearer $TFC_TOKEN"

echo "=== Organization Details ==="
curl -s -H "$AUTH" "$API/organizations/$TFC_ORG" | jq '{name: .data.attributes.name, email: .data.attributes.email, plan: .data.attributes."plan-name"}'

echo ""
echo "=== Workspaces (top 20) ==="
curl -s -H "$AUTH" "$API/organizations/$TFC_ORG/workspaces?page[size]=20" | jq -r '.data[] | "\(.attributes.name) | \(.attributes."terraform-version") | \(.attributes."resource-count") resources | locked=\(.attributes.locked)"'

echo ""
echo "=== Recent Runs ==="
curl -s -H "$AUTH" "$API/organizations/$TFC_ORG/runs?page[size]=10" | jq -r '.data[] | "\(.attributes.status) | \(.relationships.workspace.data.id) | \(.attributes."created-at")"' 2>/dev/null | head -10
```

### Phase 2: Analysis

```bash
#!/bin/bash
TFC_TOKEN="${TFC_TOKEN:?TFC_TOKEN required}"
TFC_ORG="${TFC_ORG:?TFC_ORG required}"
API="https://app.terraform.io/api/v2"
AUTH="Authorization: Bearer $TFC_TOKEN"
WS_NAME="${1:?Workspace name required}"

WS_ID=$(curl -s -H "$AUTH" "$API/organizations/$TFC_ORG/workspaces/$WS_NAME" | jq -r '.data.id')

echo "=== Workspace Config ==="
curl -s -H "$AUTH" "$API/workspaces/$WS_ID" | jq '{name: .data.attributes.name, execution_mode: .data.attributes."execution-mode", auto_apply: .data.attributes."auto-apply", tf_version: .data.attributes."terraform-version", vcs: .data.attributes."vcs-repo"}'

echo ""
echo "=== Variables ==="
curl -s -H "$AUTH" "$API/workspaces/$WS_ID/vars" | jq -r '.data[] | "\(.attributes.key) = \(if .attributes.sensitive then "***" else .attributes.value end) [\(.attributes.category)]"' | head -20

echo ""
echo "=== Latest Run ==="
curl -s -H "$AUTH" "$API/workspaces/$WS_ID/runs?page[size]=1" | jq '.data[0] | {status: .attributes.status, created: .attributes."created-at", plan_adds: .attributes."resource-additions", plan_changes: .attributes."resource-changes", plan_destroys: .attributes."resource-destructions"}'

echo ""
echo "=== Policy Checks ==="
RUN_ID=$(curl -s -H "$AUTH" "$API/workspaces/$WS_ID/runs?page[size]=1" | jq -r '.data[0].id')
curl -s -H "$AUTH" "$API/runs/$RUN_ID/policy-checks" | jq -r '.data[]? | "\(.attributes.status) | \(.attributes.scope) | passed=\(.attributes.result."passed") failed=\(.attributes.result."total-failed")"'
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Always redact sensitive variable values
- Summarize run history rather than listing every run
- Use workspace name filters to narrow queries

## Safety Rules
- **NEVER trigger applies without explicit confirmation**
- **Always use plan-only runs** for investigation
- **Check policy results** before recommending apply
- **Lock workspaces** before manual state operations
- **Verify VCS branch** before triggering runs

## Output Format

Present results as a structured report:
```
Managing Terraform Cloud Report
═══════════════════════════════
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

