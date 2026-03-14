---
name: api-sunset-notification
enabled: true
description: |
  Template for managing API sunset notifications and deprecation communications. Covers consumer identification, multi-channel notification strategy, deprecation header implementation, migration tracking, escalation procedures, and sunset enforcement to ensure smooth API retirement.
required_connections:
  - prefix: github
    label: "GitHub"
config_fields:
  - key: api_name
    label: "API Name"
    required: true
    placeholder: "e.g., Orders API v1"
  - key: api_version
    label: "API Version Being Sunset"
    required: true
    placeholder: "e.g., v1"
  - key: sunset_date
    label: "Sunset Date"
    required: true
    placeholder: "e.g., 2026-09-01"
  - key: replacement_version
    label: "Replacement Version"
    required: false
    placeholder: "e.g., v2"
features:
  - COMPLIANCE
  - API_MANAGEMENT
---

# API Sunset Notification Skill

Manage sunset of **{{ api_name }} {{ api_version }}** on **{{ sunset_date }}** (replacement: **{{ replacement_version }}**).

## Workflow

### Phase 1 — Consumer Identification

```
API CONSUMER MAP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Total active consumers: ___
[ ] Consumer inventory:
    Consumer          | API Key/Client | Daily Calls | Contact     | Priority
    __________________|________________|_____________|_____________|_________
                      |                |             |             |
                      |                |             |             |
                      |                |             |             |

[ ] Consumers by type:
    - Internal services: ___
    - External partners: ___
    - Public developers: ___
[ ] Endpoints most used:
    - ___: ___ calls/day
    - ___: ___ calls/day
    - ___: ___ calls/day
```

### Phase 2 — Notification Strategy

```
COMMUNICATION CHANNELS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] API response headers:
    Deprecation: true
    Sunset: {{ sunset_date }}
    Link: <migration-guide-url>; rel="successor-version"

[ ] Direct communication:
    [ ] Email to registered API consumers
    [ ] Partner portal notification
    [ ] Developer portal banner
    [ ] Changelog entry

[ ] Documentation:
    [ ] Migration guide published
    [ ] API diff ({{ api_version }} vs {{ replacement_version }})
    [ ] Code examples for migration
    [ ] FAQ document

NOTIFICATION SCHEDULE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Date          | Action                    | Channel          | Status
______________|___________________________|__________________|_______
T-6 months    | Initial announcement      | All channels     | [ ]
T-3 months    | Migration reminder        | Email + headers  | [ ]
T-2 months    | Usage report to consumers | Email            | [ ]
T-1 month     | Final warning             | All channels     | [ ]
T-2 weeks     | Last call                 | Direct contact   | [ ]
T-0           | Sunset enforcement        | API returns 410  | [ ]
```

### Phase 3 — Migration Tracking

```
MIGRATION STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Migration dashboard deployed
[ ] Tracking metrics:
    - {{ api_version }} daily request count: ___
    - {{ replacement_version }} daily request count: ___
    - Migration percentage: ___%

    Consumer          | Status        | {{ api_version }} Calls | {{ replacement_version }} Calls
    __________________|_______________|________________________|___________________________
                      | NOT STARTED   |                        |
                      | IN PROGRESS   |                        |
                      | COMPLETED     |                        |

[ ] Consumers requiring assistance:
    - ___: blocker: ___
    - ___: blocker: ___
```

### Phase 4 — Escalation and Enforcement

```
ESCALATION PROCEDURES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
For unmigrated consumers at T-1 month:
[ ] Direct outreach by account manager / developer relations
[ ] Technical support session offered
[ ] Extension request process:
    - Maximum extension: ___
    - Approval required from: ___
    - Extension granted to: ___

ENFORCEMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Gradual enforcement (optional):
    [ ] T-2 weeks: Rate limit {{ api_version }} to 50% of current
    [ ] T-1 week: Rate limit {{ api_version }} to 10% of current
    [ ] T-0: Return 410 Gone with migration link
[ ] Hard enforcement:
    [ ] T-0: Immediately return 410 Gone
[ ] 410 response body includes:
    [ ] Migration guide URL
    [ ] {{ replacement_version }} endpoint URL
    [ ] Support contact information
```

### Phase 5 — Post-Sunset

```
POST-SUNSET CLEANUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] {{ api_version }} traffic at zero for ___ days
[ ] {{ api_version }} code removed or archived
[ ] {{ api_version }} documentation marked as sunset
[ ] API gateway routes removed
[ ] {{ api_version }}-specific infrastructure decommissioned
[ ] Lessons learned documented:
    - Total migration duration: ___
    - Consumers that required extensions: ___
    - Improvements for next sunset: ___
```

## Output Format

Produce an API sunset management report with:
1. **Consumer analysis** (who is affected, usage volumes)
2. **Notification log** (communications sent, dates, channels)
3. **Migration progress** (consumer-by-consumer status)
4. **Escalations** (unmigrated consumers, extensions granted)
5. **Post-sunset status** (cleanup completed, lessons learned)
