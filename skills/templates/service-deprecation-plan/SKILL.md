---
name: service-deprecation-plan
enabled: true
description: |
  Template for planning and executing the deprecation and decommissioning of services. Covers consumer impact analysis, migration path definition, communication timeline, traffic monitoring, graceful shutdown procedures, and resource cleanup to safely retire services without disrupting dependents.
required_connections:
  - prefix: github
    label: "GitHub"
  - prefix: jira
    label: "Jira (or project tracker)"
config_fields:
  - key: service_name
    label: "Service to Deprecate"
    required: true
    placeholder: "e.g., legacy-auth-service"
  - key: replacement_service
    label: "Replacement Service"
    required: false
    placeholder: "e.g., auth-service-v2"
  - key: sunset_date
    label: "Target Sunset Date"
    required: true
    placeholder: "e.g., 2026-09-01"
features:
  - COMPLIANCE
  - OPERATIONS
---

# Service Deprecation Plan Skill

Plan deprecation of **{{ service_name }}** (replacement: **{{ replacement_service }}**, sunset: **{{ sunset_date }}**).

## Workflow

### Phase 1 — Impact Analysis

```
SERVICE INVENTORY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Service: {{ service_name }}
[ ] Current traffic: ___ requests/day
[ ] Consumers:
    Consumer            | Integration Type | Traffic | Owner
    ____________________|__________________|_________|______
                        |                  |         |
                        |                  |         |
                        |                  |         |

[ ] Data owned by service:
    - Databases: ___
    - Storage: ___ GB
    - Data migration required: [ ] YES  [ ] NO
[ ] Scheduled jobs/cron tasks: ___
[ ] Infrastructure resources:
    - Compute: ___
    - Monthly cost: $___
```

### Phase 2 — Migration Path

```
MIGRATION STRATEGY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Replacement service: {{ replacement_service }}
[ ] Feature parity assessment:
    Feature              | Legacy | Replacement | Gap
    _____________________|________|_____________|_____
                         |        |             |
                         |        |             |
                         |        |             |

[ ] Migration guide for consumers:
    [ ] API mapping document (old endpoint -> new endpoint)
    [ ] SDK/client library updated
    [ ] Code examples provided
    [ ] Data migration tooling available
[ ] Migration support:
    - Support channel: ___
    - Office hours: ___
    - Migration deadline: ___
```

### Phase 3 — Communication Timeline

```
DEPRECATION TIMELINE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
T-6 months: [ ] Deprecation announcement
            [ ] Migration guide published
            [ ] Deprecation headers added to API responses

T-3 months: [ ] Reminder notification to all consumers
            [ ] Usage report sent to consumer teams
            [ ] Migration support sessions offered

T-1 month:  [ ] Final warning notification
            [ ] Unmigrated consumers contacted directly
            [ ] Rate limiting on deprecated endpoints (optional)

T-0:        [ ] Service sunset: {{ sunset_date }}
            [ ] Traffic rejected with informative error
            [ ] Redirect to replacement service docs

T+1 month:  [ ] Infrastructure decommissioned
            [ ] Data archived or migrated
            [ ] DNS records removed
```

### Phase 4 — Graceful Shutdown

```
SHUTDOWN PROCEDURE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Traffic monitoring:
    - Current consumer count: ___
    - Consumers migrated: ___
    - Consumers remaining: ___
[ ] Pre-shutdown checks:
    [ ] Zero or near-zero traffic confirmed
    [ ] Remaining consumers acknowledged sunset
    [ ] Data backup taken
[ ] Shutdown steps:
    [ ] 1. Return 410 Gone with migration info
    [ ] 2. Stop accepting new requests
    [ ] 3. Drain in-flight requests
    [ ] 4. Stop service processes
    [ ] 5. Remove from service registry/load balancer
    [ ] 6. Remove DNS entries
```

### Phase 5 — Resource Cleanup

```
DECOMMISSIONING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[ ] Compute resources terminated
[ ] Database instances removed (after archive period)
[ ] Storage buckets emptied and deleted
[ ] CI/CD pipelines removed
[ ] Monitoring dashboards and alerts removed
[ ] Source code archived (read-only)
[ ] Documentation marked as deprecated
[ ] Secrets/certificates revoked
[ ] IAM roles/permissions removed
[ ] Monthly cost savings realized: $___
```

## Output Format

Produce a service deprecation plan with:
1. **Service profile** (traffic, consumers, resources, costs)
2. **Migration path** (replacement mapping, feature parity, support)
3. **Communication timeline** (notifications at each milestone)
4. **Consumer migration status** (migrated vs remaining)
5. **Decommissioning checklist** (resources to clean up, cost savings)
