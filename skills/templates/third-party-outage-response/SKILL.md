---
name: third-party-outage-response
enabled: true
description: |
  Response playbook for when a third-party vendor or external dependency experiences an outage. Covers impact assessment, customer communication, workaround activation, vendor status monitoring, internal coordination, and post-outage follow-up actions to minimize blast radius from upstream failures.
required_connections:
  - prefix: slack
    label: "Slack (for coordination)"
config_fields:
  - key: vendor_name
    label: "Vendor / Dependency Name"
    required: true
    placeholder: "e.g., Stripe, AWS S3, Twilio"
  - key: vendor_status_url
    label: "Vendor Status Page URL"
    required: false
    placeholder: "e.g., https://status.stripe.com"
  - key: affected_services
    label: "Our Affected Services"
    required: true
    placeholder: "e.g., payment processing, notification service"
features:
  - INCIDENT
---

# Third-Party Outage Response Playbook

Vendor: **{{ vendor_name }}** | Status: **{{ vendor_status_url }}**
Our Affected Services: **{{ affected_services }}**

## Immediate Actions (0-10 min)

### 1. Confirm the Outage
- [ ] Check vendor status page: {{ vendor_status_url }}
- [ ] Check vendor's Twitter/X for announcements
- [ ] Verify the issue from our own monitoring (not just vendor self-report)
- [ ] Confirm it is a vendor issue, not our integration code
- [ ] Check community reports (e.g., Downdetector, Hacker News)

### 2. Assess Our Impact
- [ ] Which of our services depend on {{ vendor_name }}?
- [ ] What is the user-facing impact?
- [ ] Are there any workarounds or fallbacks available?
- [ ] How many users/customers are affected?
- [ ] Is there revenue impact?

### 3. Declare Incident (if warranted)
- [ ] Open incident channel
- [ ] Assign IC and roles
- [ ] Set severity based on OUR customer impact, not vendor severity

## Impact Assessment Matrix

| Our Service | Dependency Type | Fallback Available | User Impact | Severity |
|-------------|----------------|-------------------|-------------|----------|
| _service_ | _critical/degraded/optional_ | _yes/no_ | _description_ | _SEV_ |

## Workaround Activation

### Available Fallbacks
For each affected service, document available workarounds:

| Service | Workaround | Activation Steps | Limitations |
|---------|-----------|-----------------|-------------|
| _service_ | _cache/queue/alternate provider/manual_ | _steps_ | _what is lost_ |

### Fallback Decision Criteria
- Activate automatic fallback if available and tested
- For manual fallbacks, IC must approve before activation
- Document when each fallback was activated and its limitations

## Vendor Monitoring

### Status Tracking
Monitor these sources every 15 minutes:

- [ ] Vendor status page: {{ vendor_status_url }}
- [ ] Vendor support ticket (if filed)
- [ ] Vendor Slack/community channel
- [ ] Our own health checks against the vendor

### Vendor Communication
- [ ] File support ticket with vendor (reference case number: ___)
- [ ] Request ETA for resolution
- [ ] Ask for root cause information
- [ ] Document all vendor communications in incident channel

## Customer Communication

### Key Message Points
- Acknowledge the issue transparently
- State that a third-party provider is experiencing issues (name the vendor only if contractually permitted)
- Describe the impact on our service
- Share workarounds if available
- Provide next update time

### Status Page Update Template
```
We are experiencing issues with {{ affected_services }} due to a
disruption at one of our infrastructure providers. Our team is
actively monitoring the situation and working on mitigations.

Impact: [describe customer impact]
Workaround: [if available]
Next update: [time]
```

## Recovery Phase

### When Vendor Recovers
- [ ] Confirm vendor reports resolution on their status page
- [ ] Verify our services are recovering (check metrics)
- [ ] Deactivate workarounds/fallbacks in controlled manner
- [ ] Verify data consistency (any queued/cached operations need replay?)
- [ ] Run integration tests against vendor
- [ ] Update status page to "Monitoring"
- [ ] Wait 30 minutes of stable operation before declaring resolved

### Data Reconciliation
- [ ] Check for failed transactions that need retry
- [ ] Verify queued operations are processing
- [ ] Reconcile any data that used fallback paths
- [ ] Confirm webhook/callback backlog is draining

## Post-Outage Follow-Up

### Within 48 Hours
- [ ] Conduct internal post-incident review
- [ ] Request vendor's post-incident report
- [ ] Evaluate our dependency on {{ vendor_name }}

### Longer Term
- [ ] Assess need for multi-vendor strategy
- [ ] Improve fallback mechanisms based on lessons learned
- [ ] Update SLAs/contracts with vendor if needed
- [ ] Add vendor outage scenario to chaos engineering drills
- [ ] Review circuit breaker and timeout configurations
