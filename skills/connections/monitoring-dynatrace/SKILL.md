---
name: monitoring-dynatrace
description: Dynatrace observability, problem management, and DQL queries. Use when working with Dynatrace problems, vulnerabilities, entities, logs, metrics, spans, or events.
connection_type: dynatrace
preload: false
---

# Monitoring Dynatrace

## Discovery

<critical>
**If no `[cached_from_skill:monitoring-dynatrace:discover]` context exists, run discovery first:**
```bash
bun run ./_skills/connections/dynatrace/monitoring-dynatrace/scripts/discover.ts
```
Output is auto-cached.
</critical>

**What discovery provides:**
- `environment`: Connection status and raw environment info response
- `problems`: Active problems response from Dynatrace
- `vulnerabilities`: High-risk vulnerabilities response
- `analyzers`: Available Davis analyzers
- `capabilities`: Which tools are working (environmentInfo, problems, vulnerabilities, davisAnalyzers)
- `hints.dql`: Common DQL tables, default record limits

**Why run discovery:**
- Verify Dynatrace connection before running queries
- See active problems that need immediate attention
- Check critical vulnerabilities
- Know available Davis analyzers for root cause analysis

## Response Format

<critical>
**All Dynatrace MCP tools return formatted strings, not structured JSON.**

Responses are human-readable text with embedded data. Handle them as strings.
</critical>

## Tools

**Environment:** `get_environment_info()`

**Problems:** `list_problems({ timeframe?, status?, additionalFilter?, maxProblemsToDisplay? })`

**Vulnerabilities:** `list_vulnerabilities({ timeframe?, riskScore?, additionalFilter?, maxVulnerabilitiesToDisplay? })`

**Entities:** `find_entity_by_name({ entityNames, maxEntitiesToDisplay?, extendedSearch? })`

**DQL:** `verify_dql({ dqlStatement })`, `execute_dql({ dqlStatement, recordLimit?, recordSizeLimitMB? })`

**AI-Powered:** `generate_dql_from_natural_language({ text })`, `explain_dql_in_natural_language({ dql })`, `chat_with_davis_copilot({ text, context?, instruction? })`

**Kubernetes:** `get_kubernetes_events({ timeframe?, clusterId?, kubernetesEntityId?, eventType?, maxEventsToDisplay? })`

**Exceptions:** `list_exceptions({ timeframe?, additionalFilter?, maxExceptionsToDisplay? })`

**Davis Analyzers:** `list_davis_analyzers()`, `execute_davis_analyzer({ analyzerName, input?, timeframeStart?, timeframeEnd? })`

**Documents:** `create_dynatrace_notebook({ name, description?, content })`

**Notifications:** `send_slack_message({ channel, message })`, `send_email({ toRecipients, subject, body, ccRecipients?, bccRecipients? })`, `send_event({ eventType, title, entitySelector?, properties?, startTime?, endTime? })`

**Workflows:** `create_workflow_for_notification({ problemType?, teamName?, channel?, isPrivate? })`, `make_workflow_public({ workflowId? })`

**Budget:** `reset_grail_budget()`

## Quick Patterns

**Verify connection:**
```typescript
const env = await get_environment_info();
// Returns formatted string with tenant info
```

**List active problems:**
```typescript
const problems = await list_problems({
  timeframe: "24h",
  status: "ACTIVE",
  maxProblemsToDisplay: 10
});
// Returns formatted string: "Found X problems!..." + details
```

**Find vulnerabilities:**
```typescript
const vulns = await list_vulnerabilities({
  timeframe: "30d",
  riskScore: 8.0,
  maxVulnerabilitiesToDisplay: 25
});
// Returns formatted string with vulnerability list
```

**Execute DQL query:**
```typescript
// Validate first
const validation = await verify_dql({ dqlStatement: 'fetch logs | limit 100' });

// Then execute
const logs = await execute_dql({
  dqlStatement: 'fetch logs | filter loglevel == "ERROR" | limit 100',
  recordLimit: 100
});
// Returns formatted string with JSON results in code block
```

**Find entities by name:**
```typescript
const entities = await find_entity_by_name({
  entityNames: ["payment-service", "checkout-api"],
  maxEntitiesToDisplay: 10
});
// Returns formatted string with entity details
```

## DQL Quick Reference

<critical>
**Always use `verify_dql()` before `execute_dql()` to catch syntax errors.**
</critical>

**Common DQL patterns:**
```
fetch logs | filter loglevel == "ERROR" | limit 100
fetch dt.metrics | filter metric.key == "builtin:host.cpu.usage" | limit 50
fetch spans | filter span.kind == "SERVER" | fieldsAdd duration | limit 100
fetch events | filter event.type == "CUSTOM_DEPLOYMENT" | limit 50
fetch dt.davis.problems | filter affected_entity_ids contains "HOST-ABC123" | limit 10
```

**DQL operators:**
| Operator | Example |
|----------|---------|
| `==` | `filter status == "OPEN"` |
| `!=` | `filter status != "CLOSED"` |
| `contains` | `filter tags contains "production"` |
| `startsWith` | `filter name startsWith "api-"` |
| `and`, `or` | `filter status == "OPEN" and severity == "HIGH"` |

## Workflows

**Problem Investigation:**
1. `list_problems({status: "ACTIVE"})` → Get active problems
2. `find_entity_by_name({entityNames: [affected_entity]})` → Get entity details
3. `execute_dql({dqlStatement: 'fetch logs | filter ...'})` → Investigate logs
4. `chat_with_davis_copilot({text: "What caused this problem?"})` → AI analysis

**Security Audit:**
1. `list_vulnerabilities({riskScore: 8.0})` → High-risk vulnerabilities
2. `find_entity_by_name()` → Affected services
3. `execute_dql()` → Related security events

**Performance Analysis:**
1. `list_davis_analyzers()` → Available analyzers
2. `execute_davis_analyzer({analyzerName: "dt.davis.analyze.timeseries"})` → Run analysis
3. `execute_dql()` → Fetch specific metrics

**Natural Language Queries:**
```typescript
// Generate DQL from English
const dql = await generate_dql_from_natural_language({
  text: "Show me all errors from the checkout service in the last hour"
});

// Explain existing DQL
const explanation = await explain_dql_in_natural_language({
  dql: 'fetch logs | filter loglevel == "ERROR" | summarize count()'
});
```

## Common Errors

| Error | Solution |
|-------|----------|
| "Invalid DQL" | Use `verify_dql()` first to check syntax |
| "Query budget exceeded" | Use `reset_grail_budget()` or reduce `recordLimit` |
| "Entity not found" | Use `find_entity_by_name()` with `extendedSearch: true` |
| "Authentication failed" | Verify `DT_PLATFORM_TOKEN` has required scopes |

## Timeframe Formats

| Format | Example | Description |
|--------|---------|-------------|
| Relative | `"24h"`, `"7d"`, `"30d"` | Hours/days ago from now |
| Absolute | `"2024-01-15T00:00:00Z"` | ISO 8601 timestamp |

## Anti-Patterns

- **DQL without validation**: Always `verify_dql()` before `execute_dql()`
- **High record limits first**: Start with `recordLimit: 50-100`, increase if needed
- **Skipping environment check**: Use `get_environment_info()` to verify connection
- **Broad vulnerability queries**: Set `riskScore >= 7.0` to focus on critical issues
- **Ignoring budget**: Check response for budget usage, use `reset_grail_budget()` when needed

## Output Format

Present results as a structured report:
```
Monitoring Dynatrace Report
═══════════════════════════
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

