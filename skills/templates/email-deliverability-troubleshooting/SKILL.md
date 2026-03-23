---
name: email-deliverability-troubleshooting
enabled: true
description: |
  Use when performing email deliverability troubleshooting — email delivery
  issues investigation workflow covering bounce analysis, spam filter diagnosis,
  SPF/DKIM/DMARC validation, mail flow tracing, and mailbox quota management.
  Guides helpdesk agents through systematic diagnosis of email delivery failures
  for both sending and receiving issues.
required_connections:
  - prefix: itsm
    label: "ITSM Tool (ServiceNow, Freshservice, etc.)"
config_fields:
  - key: user_name
    label: "Affected User Name"
    required: true
    placeholder: "e.g., Jane Smith"
  - key: email_direction
    label: "Issue Direction (sending/receiving/both)"
    required: true
    placeholder: "e.g., sending, receiving, both"
  - key: recipient_or_sender
    label: "Other Party Email Address"
    required: false
    placeholder: "e.g., client@external.com"
  - key: email_platform
    label: "Email Platform"
    required: false
    placeholder: "e.g., Microsoft 365, Google Workspace, Exchange On-Prem"
features:
  - HELPDESK
---

# Email Deliverability Troubleshooting

Investigating email issue for **{{ user_name }}**
Direction: **{{ email_direction }}** | Platform: {{ email_platform }}
Other party: {{ recipient_or_sender }}

## Decision Tree

```
START: What is the email issue?
│
├─ Emails Not Being SENT
│  ├─ Bounce-back / NDR received?
│  │  ├─ Yes → Analyze NDR error code (see below)
│  │  └─ No → Check outbox, stuck in queue?
│  ├─ Sending to all recipients or specific ones?
│  │  ├─ All → Account or server issue
│  │  └─ Specific → Recipient-side issue
│  └─ Attachment issues?
│     └─ Check size limits (typically 25-35MB)
│
├─ Emails Not Being RECEIVED
│  ├─ From all senders or specific?
│  │  ├─ All → Mailbox or routing issue
│  │  └─ Specific → Spam filter or sender issue
│  ├─ Check spam/junk folder
│  ├─ Mailbox full?
│  └─ Mail flow rules blocking?
│
└─ Emails Delayed
   ├─ Internal or external?
   ├─ Check mail queue on server
   └─ DNS/MX record issues?
```

## Diagnostic Steps

### Step 1 — Basic Checks
- [ ] Verify {{ user_name }}'s mailbox is active and not over quota
- [ ] Check mailbox size: current usage vs limit
- [ ] Verify {{ user_name }} can log into webmail (rules out client-only issues)
- [ ] Check for any active mail flow rules / inbox rules that might redirect or delete emails

### Step 2 — Bounce / NDR Analysis

Common NDR codes and meanings:
| Code | Meaning | Action |
|------|---------|--------|
| 550 5.1.1 | Recipient does not exist | Verify recipient address spelling |
| 550 5.7.1 | Relay denied / not authorized | Check authentication, connector config |
| 552 5.2.2 | Mailbox full | Recipient needs to clear space |
| 554 5.7.1 | Message rejected (spam) | Check SPF/DKIM/DMARC, content filters |
| 421 4.7.0 | Temporary failure, try later | Server greylisting, retry automatically |
| 550 5.4.1 | Recipient domain not found | Verify domain exists, check MX records |

### Step 3 — DNS & Authentication Records
- [ ] Verify MX records point to correct mail servers
- [ ] Validate SPF record: `nslookup -type=txt domain.com` — look for `v=spf1`
- [ ] Validate DKIM: check selector records in DNS
- [ ] Validate DMARC: `nslookup -type=txt _dmarc.domain.com`
- [ ] If records are missing or incorrect, escalate to DNS administrator

### Step 4 — Message Trace
- [ ] Run message trace in {{ email_platform }} admin console
- [ ] Search by sender, recipient, date range, and message ID
- [ ] Check trace results for:
  - Delivery status (delivered, failed, pending, filtered)
  - Transport rules applied
  - Spam filter verdict and confidence level
  - Connector routing path

### Step 5 — Spam Filter Investigation
- [ ] Check if message was quarantined
- [ ] Review spam filter logs for the specific message
- [ ] If legitimate email was blocked:
  - Whitelist sender domain or address
  - Adjust spam filter sensitivity if false positives are frequent
  - Release message from quarantine
- [ ] If company emails are being marked as spam by recipients:
  - Verify SPF/DKIM/DMARC alignment
  - Check if company domain/IP is on any blacklists
  - Review email content for spam trigger words

## Escalation Criteria

Escalate to email/messaging team if:
- Mail server queue is backed up
- DNS record changes are needed
- Domain is blacklisted
- Transport rules need modification
- Multiple users affected simultaneously

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "We can skip some steps for this case" | Adapt the workflow steps, don't skip them | Skipped steps are where incidents and oversights originate |
| "The user seems to already know what to do" | Complete all workflow phases with the user | The workflow catches blind spots that experience alone misses |
| "This is a minor case, full process is overkill" | Scale the process down, don't turn it off | Minor cases become major when unstructured; the process scales, not disappears |
| "I'll fill in the details later" | Complete each section before moving on | Deferred details are forgotten; real-time capture is more accurate |
| "The template output isn't necessary" | Always produce the structured output format | Structured output enables comparison, audit trails, and handoff to other teams |

## Output Format

Generate a diagnostic report with:
1. **Issue summary** (user, direction, platform)
2. **Diagnostic findings** from each step
3. **Root cause** identified
4. **Resolution** applied or **escalation** with details
