---
name: incident-bridge-facilitation
enabled: true
description: |
  Guide for running an effective incident bridge call or war room, covering agenda structure, facilitation techniques, role assignments, information flow management, and decision-making frameworks. Ensures bridge calls remain focused, productive, and lead to faster incident resolution.
required_connections:
  - prefix: slack
    label: "Slack (for incident channel)"
config_fields:
  - key: incident_title
    label: "Incident Title"
    required: true
    placeholder: "e.g., Database cluster failover failure"
  - key: severity
    label: "Severity"
    required: true
    placeholder: "e.g., SEV1"
  - key: bridge_link
    label: "Bridge Call / War Room Link"
    required: false
    placeholder: "e.g., https://meet.google.com/xxx-yyyy-zzz"
features:
  - INCIDENT
---

# Incident Bridge Facilitation

Incident: **{{ incident_title }}**
Severity: **{{ severity }}** | Bridge: **{{ bridge_link }}**

## Bridge Setup Checklist

- [ ] Open dedicated Slack channel (e.g., #inc-YYYY-MM-DD-short-name)
- [ ] Start video/audio bridge: {{ bridge_link }}
- [ ] Pin incident summary in channel
- [ ] Set channel topic to current status and IC name
- [ ] Invite required responders based on severity

## Opening the Bridge (First 3 Minutes)

The IC opens the bridge with a structured situation report:

```
"This is [IC name], I am the Incident Commander for [incident title].

Current severity: [SEV level]
Impact: [who is affected and how]
Timeline: [when it started, what we know so far]
Current theory: [what we think is happening]
Active investigation: [who is looking at what]

Roles:
- Tech Lead: [name]
- Comms Lead: [name]
- Scribe: [name]

Ground rules:
1. Mute when not speaking
2. Identify yourself before speaking
3. Direct questions to IC
4. Post findings in the Slack channel, not just verbally
"
```

## Bridge Ground Rules

1. **Mute by default** — unmute only when speaking
2. **Identify yourself** — "This is [name] from [team]" before speaking
3. **Be concise** — state findings in 30 seconds or less
4. **Write it down** — all findings must be posted in the incident channel
5. **No side conversations** — one thread of discussion at a time
6. **No spectators** — if you are not actively contributing, drop off the bridge
7. **IC controls the floor** — IC decides who speaks and when to context-switch

## Facilitation Techniques

### Round-Robin Status Check (Every 15 min for SEV1)
```
IC: "Time for a status round. [Tech Lead], what is the current state of investigation?"
IC: "[Service owner], what is the status of [affected service]?"
IC: "[Comms Lead], when was the last customer update?"
IC: "Any new information from anyone else? Speak now."
IC: "Next update in 15 minutes. [Tech Lead], continue with [specific action]."
```

### Decision Framework
When a decision is needed:
1. IC states the decision to be made
2. IC asks for options (maximum 3)
3. IC asks for recommendation from Tech Lead
4. IC makes the decision and announces it clearly
5. Scribe records the decision with timestamp

### Controlling Scope Creep
```
"That is a valid concern but not related to the current incident.
Please create a ticket for follow-up. Let us stay focused on [current priority]."
```

### Breaking Deadlocks
```
"We have been discussing this for [X] minutes without consensus.
I am making the call: we will [decision]. If it does not work,
we will revisit in [Y] minutes. Let us move forward."
```

## Information Flow

### What Goes in Slack (Written Record)
- All findings and observations
- Graphs, dashboards, and log snippets
- Decisions made and rationale
- Action items with owners
- Timeline entries

### What Stays on the Bridge (Verbal Only)
- Real-time coordination
- Brainstorming theories
- Quick questions that need immediate answers

## Bridge Etiquette for Participants

- **Join promptly** when paged — within 5 minutes for SEV1
- **Come prepared** — check dashboards before joining
- **Report findings** — do not wait to be asked
- **Flag blockers** — if you are stuck, say so immediately
- **Announce departures** — "This is [name], I need to drop. [Handoff person] will cover."

## Closing the Bridge

When the incident is mitigated:

```
IC: "The incident has been mitigated. Here is the summary:

- Root cause: [brief description]
- Mitigation: [what was done]
- Duration: [start to end]
- Remaining actions: [any follow-up items]

Post-incident review will be scheduled within 48 hours.
Thank you all for your response. Bridge is now closed."
```

## Anti-Patterns to Avoid

- **Too many people on the bridge** — limit to essential responders only
- **No clear IC** — always have one person running the call
- **Debugging by committee** — assign specific investigation tracks to individuals
- **Ignoring the clock** — track elapsed time and escalate if MTTR targets are at risk
- **Verbal-only updates** — everything must also be written in the incident channel
