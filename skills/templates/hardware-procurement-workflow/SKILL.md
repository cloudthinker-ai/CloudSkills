---
name: hardware-procurement-workflow
enabled: true
description: |
  Use when performing hardware procurement workflow — hardware request through
  procurement, setup, and deployment covering the full lifecycle from initial
  request and budget approval through vendor selection, purchase order
  processing, hardware configuration, and delivery to the end user. Ensures
  hardware procurement follows organizational policies and budget controls.
required_connections:
  - prefix: itsm
    label: "ITSM Tool (ServiceNow, Freshservice, etc.)"
config_fields:
  - key: requester_name
    label: "Requester Name"
    required: true
    placeholder: "e.g., Jane Smith"
  - key: hardware_type
    label: "Hardware Type"
    required: true
    placeholder: "e.g., Laptop, Desktop, Monitor, Docking Station"
  - key: business_justification
    label: "Business Justification"
    required: true
    placeholder: "e.g., New hire starting April 1, current laptop end-of-life"
  - key: budget_code
    label: "Budget / Cost Center Code"
    required: false
    placeholder: "e.g., CC-ENG-2026, DEPT-MARKETING"
  - key: urgency
    label: "Urgency (standard/expedited)"
    required: false
    placeholder: "e.g., standard (2-3 weeks), expedited (3-5 days)"
features:
  - HELPDESK
---

# Hardware Procurement Workflow

Hardware request: **{{ hardware_type }}** for **{{ requester_name }}**
Justification: {{ business_justification }}
Budget: {{ budget_code }} | Urgency: {{ urgency }}

## Step 1 — Request & Approval

### Request Validation
- [ ] Verify {{ requester_name }} is an active employee
- [ ] Confirm {{ hardware_type }} is a standard catalog item
- [ ] If non-standard: document special requirements and get additional approval

### Standard Hardware Catalog
```
STANDARD OPTIONS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Laptop (Standard):    [Model/Spec from catalog]
Laptop (Power User):  [Model/Spec from catalog]
Desktop (Standard):   [Model/Spec from catalog]
Monitor:              [Model/Spec from catalog]
Docking Station:      [Model/Spec from catalog]
Peripherals Kit:      Keyboard, mouse, headset
```

### Approval Chain
- [ ] Manager approval for {{ requester_name }}
- [ ] Budget owner approval ({{ budget_code }})
- [ ] If cost > threshold: director/VP approval required
- [ ] Procurement team notified

## Step 2 — Procurement

### Vendor & Pricing
- [ ] Check existing inventory for available {{ hardware_type }}
  - **If available in inventory**: skip to Step 3 (Setup)
  - **If not available**: proceed with purchase
- [ ] Obtain quotes from approved vendors (minimum 2 for items > $1000)
- [ ] Select vendor based on price, availability, and warranty
- [ ] Verify vendor is on approved vendor list

### Purchase Order
- [ ] Create purchase order with:
  - Item description and specifications
  - Quantity
  - Unit price and total cost
  - Budget code: {{ budget_code }}
  - Delivery address and attention
  - Requested delivery date based on {{ urgency }}
- [ ] PO approved and submitted to vendor
- [ ] Order confirmation received with estimated delivery date
- [ ] Track shipment

## Step 3 — Receiving & Setup

### Receiving
- [ ] Verify received hardware matches PO (model, specs, quantity)
- [ ] Inspect for physical damage
- [ ] Record serial numbers and asset tags
- [ ] Create asset record in asset management system

### Configuration
- [ ] Apply standard OS image
- [ ] Install latest OS patches and updates
- [ ] Install standard software suite for {{ requester_name }}'s role
- [ ] Configure device encryption (BitLocker/FileVault)
- [ ] Enroll in MDM (Intune/Jamf/etc.)
- [ ] Configure network settings (WiFi profiles, certificates)
- [ ] Apply security baseline policies
- [ ] Run hardware diagnostics

### Quality Check
- [ ] Boot and verify all hardware components functional
- [ ] Test network connectivity (wired and wireless)
- [ ] Verify all installed software launches correctly
- [ ] Confirm encryption is active

## Step 4 — Deployment

### Delivery
- [ ] Schedule handoff with {{ requester_name }}
- [ ] For remote employees: ship with tracking and insurance
- [ ] Include setup instructions and IT contact information
- [ ] Hand off device with any peripherals

### User Setup
- [ ] Assist {{ requester_name }} with initial login
- [ ] Complete MFA enrollment on new device
- [ ] Transfer data from old device if applicable
- [ ] Verify {{ requester_name }} can access all required resources

### Old Device Handling (if replacement)
- [ ] Collect old device from {{ requester_name }}
- [ ] Back up any user data
- [ ] Wipe and reimage or decommission
- [ ] Update asset records

## Step 5 — Documentation & Close

- [ ] Update asset management: assign {{ hardware_type }} to {{ requester_name }}
- [ ] Record warranty information and expiration date
- [ ] Update budget tracking with actual cost
- [ ] Close procurement ticket in ITSM
- [ ] Notify {{ requester_name }} and manager of completion

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

Generate a procurement report with:
1. **Request summary** (hardware, requester, justification)
2. **Procurement details** (vendor, cost, PO number)
3. **Configuration summary** (OS, software, security)
4. **Deployment confirmation** and asset assignment
