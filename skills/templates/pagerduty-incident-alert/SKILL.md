---
name: pagerduty-incident-alert
enabled: true
description: |
  Create a PagerDuty incident from an RCA finding, monitoring alert, or escalation. Automatically formats incident details, selects the appropriate service and escalation policy, and posts an incident via the PagerDuty API. Use after an incident is identified and needs to be formally declared in PagerDuty.
required_connections:
  - prefix: pagerduty
    label: "PagerDuty"
config_fields:
  - key: service_name
    label: "Affected Service Name"
    required: true
    placeholder: "e.g., payment-api"
  - key: urgency
    label: "Urgency (high / low)"
    required: true
    placeholder: "e.g., high"
  - key: escalation_policy
    label: "Escalation Policy Name (optional)"
    required: false
    placeholder: "e.g., Engineering On-Call"
features:
  - RCA
  - INCIDENT
---

# PagerDuty Incident Alert Skill

Create a PagerDuty incident for **{{ service_name }}** with urgency **{{ urgency }}**.

## Workflow

### Step 1 — Validate PagerDuty Configuration

Before creating the incident, verify the target service and escalation policy exist:

```bash
#!/bin/bash

pd_api() {
    curl -s -X "$1" \
        -H "Authorization: Token token=$PAGERDUTY_API_KEY" \
        -H "Accept: application/vnd.pagerduty+json;version=2" \
        -H "Content-Type: application/json" \
        "https://api.pagerduty.com${2}" \
        ${3:+-d "$3"}
}

echo "=== Finding Service: {{ service_name }} ==="
SERVICE=$(pd_api GET "/services?query={{ service_name | urlencode }}&limit=10" \
    | jq -r '.services[] | "\(.id)\t\(.name)\t\(.status)"')

if [ -z "$SERVICE" ]; then
    echo "ERROR: No PagerDuty service found matching '{{ service_name }}'"
    echo "Available services:"
    pd_api GET "/services?limit=25" | jq -r '.services[] | "  \(.id)\t\(.name)"'
    exit 1
fi

echo "$SERVICE" | column -t

echo ""
echo "=== Finding Escalation Policy ==="
{% if escalation_policy %}
EP=$(pd_api GET "/escalation_policies?query={{ escalation_policy | urlencode }}&limit=5" \
    | jq -r '.escalation_policies[] | "\(.id)\t\(.name)"')
echo "$EP" | column -t
{% else %}
echo "Using service default escalation policy"
{% endif %}
```

### Step 2 — Extract Incident Details

Gather the following information from the current conversation context (RCA, alert, or description):

1. **Incident title** — concise, actionable description (max 100 chars)
2. **Incident body** — detailed description including:
   - What is broken (symptoms)
   - When it started
   - Who/what is impacted
   - Current hypothesis
   - What has been tried
3. **Urgency** — `{{ urgency }}` (high = immediate page, low = next business hours)
4. **Assignee** (if specific person should be paged, not escalation policy)

### Step 3 — Create PagerDuty Incident

```bash
#!/bin/bash

# Get service ID
SERVICE_ID=$(pd_api GET "/services?query={{ service_name | urlencode }}&limit=5" \
    | jq -r '.services[0].id')

if [ -z "$SERVICE_ID" ] || [ "$SERVICE_ID" = "null" ]; then
    echo "ERROR: Could not find service '{{ service_name }}' in PagerDuty"
    exit 1
fi

# Prepare incident payload
TITLE="[extracted from context]"
DETAILS="[extracted from context — structured description]"

echo "=== Creating PagerDuty Incident ==="
RESULT=$(pd_api POST "/incidents" "{
    \"incident\": {
        \"type\": \"incident\",
        \"title\": \"$TITLE\",
        \"urgency\": \"{{ urgency }}\",
        \"service\": {
            \"id\": \"$SERVICE_ID\",
            \"type\": \"service_reference\"
        },
        \"body\": {
            \"type\": \"incident_body\",
            \"details\": \"$DETAILS\"
        }
    }
}")

INCIDENT_ID=$(echo "$RESULT" | jq -r '.incident.id')
INCIDENT_NUM=$(echo "$RESULT" | jq -r '.incident.incident_number')
INCIDENT_URL=$(echo "$RESULT" | jq -r '.incident.html_url')

if [ -z "$INCIDENT_ID" ] || [ "$INCIDENT_ID" = "null" ]; then
    echo "ERROR: Failed to create incident"
    echo "$RESULT" | jq '.error'
    exit 1
fi

echo "Incident created:"
echo "  Number: #$INCIDENT_NUM"
echo "  ID: $INCIDENT_ID"
echo "  URL: $INCIDENT_URL"
echo "  Urgency: {{ urgency }}"
echo "  Service: {{ service_name }}"
```

### Step 4 — Add Incident Note

Add initial context as a note so responders have full information immediately:

```bash
#!/bin/bash

INITIAL_NOTE="[Full context extracted from conversation: incident details, timeline, hypothesis, steps taken]"

pd_api POST "/incidents/${INCIDENT_ID}/notes" "{
    \"note\": {
        \"content\": \"$INITIAL_NOTE\"
    }
}"

echo "Initial note added to incident #$INCIDENT_NUM"
```

### Step 5 — Post Summary

After creating the incident, produce a summary:

```
PAGERDUTY INCIDENT CREATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Incident: #[number]
Title: [title]
Service: {{ service_name }}
Urgency: {{ urgency }}
Status: triggered
URL: [incident URL]

The on-call engineer for {{ service_name }} has been paged.
Escalation policy: [policy name]
Expected response time: [based on urgency — high=5min, low=30min]

Next steps:
1. Join the incident bridge channel
2. Acknowledge the PagerDuty alert
3. Follow the incident response runbook
```

## Output Format

Produce:
1. **Validation results** (service found, policy found)
2. **Incident creation confirmation** with ID, number, and URL
3. **On-call responder** who was paged
4. **Next steps** for the incident commander
