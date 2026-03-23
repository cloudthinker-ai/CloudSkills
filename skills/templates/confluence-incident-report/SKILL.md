---
name: confluence-incident-report
enabled: true
description: Create structured Confluence incident report pages from RCA findings. Generates comprehensive post-incident documentation with timeline, impact analysis, root cause, and action items.
required_connections:
  - prefix: atlassian
    label: "Confluence / Atlassian"
config_fields:
  - key: space_key
    label: "Space Key"
    required: true
    placeholder: "e.g., OPS"
  - key: parent_page_id
    label: "Parent Page ID"
    required: false
    placeholder: "e.g., 12345"
features:
  - RCA
---

# Confluence Incident Report

Create structured Confluence pages documenting incident post-mortems from RCA findings.

## Prerequisites

Before executing this skill, ensure:
1. The RCA analysis has been completed and findings are available in context
2. The Atlassian connection is configured with Confluence access
3. The target space `{{config.space_key}}` exists and is accessible

## Discovery

<critical>
**Run discovery first to get the cloudId and validate the space:**
```typescript
const resources = await getAccessibleAtlassianResources();
const cloudId = resources[0].id;
const siteUrl = resources[0].url;

const spaces = await getConfluenceSpaces({ cloudId, limit: 50 });
// Find the space matching {{config.space_key}}
```
</critical>

## Workflow

### Step 1: Resolve the Space

```typescript
const resources = await getAccessibleAtlassianResources();
const cloudId = resources[0].id;
const siteUrl = resources[0].url;

const spaces = await getConfluenceSpaces({ cloudId, limit: 50 });
const targetSpace = spaces.results.find(s => s.key === '{{config.space_key}}');
const spaceId = targetSpace.id;
```

If `{{config.parent_page_id}}` is provided, verify the parent page exists:

```typescript
const parentPage = await getConfluencePage({
  cloudId,
  pageId: '{{config.parent_page_id}}'
});
```

### Step 2: Extract RCA Information

From the RCA context, gather:

| Section | Content | Required |
|---------|---------|----------|
| Incident metadata | Date, duration, severity, status | Yes |
| Executive summary | Brief incident overview | Yes |
| Timeline | Chronological events | Yes |
| Impact analysis | Users, services, revenue affected | Yes |
| Root cause | Technical root cause details | Yes |
| Resolution | Steps taken to resolve | Yes |
| Action items | Follow-up tasks with owners | Yes |
| Lessons learned | What went well, what to improve | If available |
| Supporting evidence | Metrics, logs, screenshots | If available |

### Step 3: Build the Page Content

Format the incident report in Markdown (Confluence accepts `contentFormat: 'markdown'`):

```markdown
# Incident Report: {incident_title}

| Field | Value |
|-------|-------|
| Date | {incident_date} |
| Duration | {duration} |
| Severity | {severity} |
| Status | Resolved |
| Lead | {incident_lead} |
| Affected Services | {services_list} |

---

## Executive Summary

{2-3 paragraph summary of what happened, the impact, and current status}

---

## Timeline

| Time (UTC) | Event |
|------------|-------|
| {time_1} | {event_1} |
| {time_2} | {event_2} |
| {time_3} | {event_3} |
| {time_4} | {event_4} |

---

## Impact Analysis

### User Impact
{description of how users were affected, including numbers if available}

### Service Impact
{which services were degraded or unavailable}

### Business Impact
{revenue impact, SLA violations, customer communications sent}

---

## Root Cause Analysis

### Direct Cause
{the immediate technical cause of the incident}

### Contributing Factors
- {factor_1}
- {factor_2}
- {factor_3}

### Why It Wasn't Caught
{gaps in monitoring, testing, or processes that allowed this to happen}

---

## Resolution

### Immediate Actions Taken
1. {action_1}
2. {action_2}
3. {action_3}

### Verification
{how resolution was verified, metrics that confirmed recovery}

---

## Action Items

| ID | Action | Owner | Priority | Due Date | Status |
|----|--------|-------|----------|----------|--------|
| 1 | {action_item_1} | {owner} | {priority} | {date} | Open |
| 2 | {action_item_2} | {owner} | {priority} | {date} | Open |
| 3 | {action_item_3} | {owner} | {priority} | {date} | Open |

---

## Lessons Learned

### What Went Well
- {positive_1}
- {positive_2}

### What Needs Improvement
- {improvement_1}
- {improvement_2}

### Process Changes
- {process_change_1}
- {process_change_2}

---

## Supporting Evidence

{metrics, graphs, log excerpts, or references to monitoring dashboards}
```

### Step 4: Create the Confluence Page

```typescript
const pageTitle = `Incident Report: ${incidentTitle} - ${incidentDate}`;

const createParams = {
  cloudId,
  spaceId: spaceId.toString(),
  title: pageTitle,
  body: formattedContent,
  contentFormat: 'markdown'
};

const result = await createConfluencePage(createParams);
const pageUrl = `${siteUrl}/wiki/spaces/${spaceId}/pages/${result.id}`;
```

If `{{config.parent_page_id}}` is provided, the page should be nested under that parent. Include the parent page ID in the creation call if the API supports it, or move the page after creation.

### Step 5: Add Labels

After creating the page, add relevant labels for organization and searchability:
- `incident-report`
- `rca`
- `severity-{level}`
- `{affected-service}` (for each affected service)

## Output

After successful creation, report:
1. The page URL
2. The page title
3. A summary of sections populated
4. Any sections left incomplete due to missing RCA data
5. Reminder to review and add any missing details (owners for action items, due dates)

## Error Handling

| Scenario | Action |
|----------|--------|
| Space not found | Report error with the configured space key `{{config.space_key}}` |
| Parent page not found | Create page at space root, warn about missing parent |
| Permission denied | Report required Confluence permissions |
| Duplicate title | Append timestamp to make title unique |
| Missing RCA sections | Create page with available data, mark missing sections with placeholders |

## Formatting Guidelines

- Use Markdown format with `contentFormat: 'markdown'`
- Use tables for structured data (timeline, action items, metadata)
- Use horizontal rules (`---`) to separate major sections
- Keep the executive summary concise (2-3 paragraphs max)
- Action items must have Owner, Priority, and Due Date columns
- Include the incident date in the page title for chronological sorting

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

