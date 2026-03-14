---
name: it-asset-lifecycle-management
enabled: true
description: |
  IT asset lifecycle tracking from procurement through disposal covering asset intake, deployment, maintenance, refresh planning, and secure decommissioning. Provides a framework for managing assets at every stage to optimize costs, ensure compliance, and maintain accurate inventory records.
required_connections:
  - prefix: itsm
    label: "ITSM Tool (ServiceNow, Freshservice, etc.)"
config_fields:
  - key: asset_tag
    label: "Asset Tag / ID"
    required: true
    placeholder: "e.g., ASSET-2026-0042"
  - key: asset_type
    label: "Asset Type"
    required: true
    placeholder: "e.g., Laptop, Server, Network Switch, Monitor"
  - key: current_stage
    label: "Current Lifecycle Stage"
    required: true
    placeholder: "e.g., procurement, active, maintenance, refresh, disposal"
  - key: assigned_to
    label: "Currently Assigned To"
    required: false
    placeholder: "e.g., Jane Smith, Server Room B, Unassigned"
features:
  - HELPDESK
---

# IT Asset Lifecycle Management

Asset: **{{ asset_tag }}** ({{ asset_type }})
Stage: **{{ current_stage }}** | Assigned: {{ assigned_to }}

## Lifecycle Stages

```
PROCUREMENT → INTAKE → DEPLOYMENT → ACTIVE USE → MAINTENANCE → REFRESH → DISPOSAL
     │           │          │            │             │           │          │
  Purchase    Receive    Assign to    Monitor &    Repair or   Replace    Secure
  & approve   & tag      user/loc     track        upgrade     with new   wipe &
                                                               asset      recycle
```

## Stage: Procurement
- [ ] Purchase request approved with business justification
- [ ] Vendor selected and PO issued
- [ ] Order tracked with expected delivery date
- [ ] Budget allocated and cost recorded

## Stage: Intake & Registration
- [ ] Verify received item matches purchase order
- [ ] Inspect for damage during shipping
- [ ] Assign asset tag: {{ asset_tag }}
- [ ] Record in asset management system:
  - Asset tag, serial number, model, manufacturer
  - Purchase date, cost, PO number
  - Warranty start and end dates
  - Vendor and support contract details
- [ ] Apply company asset label physically to device
- [ ] Store securely until deployment

## Stage: Deployment
- [ ] Configure device per standard build (OS, software, security)
- [ ] Enroll in management tools (MDM, monitoring)
- [ ] Assign to {{ assigned_to }}
- [ ] Update asset record with assignment details
- [ ] Document location (office, rack, remote address)
- [ ] Provide user with asset acknowledgment form

## Stage: Active Use — Ongoing Tracking
- [ ] Monitor device health via management tools
- [ ] Track software installations and compliance
- [ ] Record any moves, additions, or changes
- [ ] Conduct periodic asset audits (quarterly recommended)
- [ ] Verify physical asset matches system records

### Key Metrics to Track
| Metric | Target | Action if Exceeded |
|--------|--------|--------------------|
| Age | <4 years (laptops), <5 years (desktops) | Plan refresh |
| Warranty Status | Active | Evaluate renewal or replacement |
| Repair Count | <3 major repairs | Consider replacement |
| Performance | Meets job requirements | Upgrade or replace |

## Stage: Maintenance & Repair
- [ ] Log maintenance request in ITSM
- [ ] Determine if under warranty or support contract
  - **Under warranty**: Contact vendor for repair
  - **Out of warranty**: Evaluate repair vs replace cost
- [ ] If repair: track parts and labor cost against asset
- [ ] If loaner needed: issue temporary device and track
- [ ] Update asset record with maintenance history
- [ ] Return to active use or escalate to refresh

## Stage: Refresh / Replacement
- [ ] Asset meets refresh criteria (age, performance, cost of repairs)
- [ ] Initiate procurement for replacement
- [ ] Plan data migration from old to new asset
- [ ] Deploy replacement to {{ assigned_to }}
- [ ] Collect old asset
- [ ] Move old asset to disposal stage

## Stage: Disposal / Decommission
- [ ] Back up any data per retention policy
- [ ] Perform certified data wipe (NIST 800-88 compliant)
- [ ] Obtain certificate of data destruction
- [ ] Remove from all management systems (MDM, monitoring, AD)
- [ ] Reclaim any transferable software licenses
- [ ] Dispose via approved method:
  - **Recycle**: Through certified e-waste recycler (R2/e-Stewards)
  - **Donate**: If eligible, with data wipe certification
  - **Auction/Sell**: Through approved surplus process
- [ ] Update asset record to "Disposed" with disposal date and method
- [ ] Retain disposal records for compliance (typically 7 years)

## Output Format

Generate an asset lifecycle report with:
1. **Asset details** (tag, type, current stage)
2. **Lifecycle history** (key dates and events)
3. **Current status** and recommended actions
4. **Upcoming milestones** (warranty expiry, refresh date)
