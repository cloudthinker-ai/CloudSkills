---
name: managing-aws-gamelift
description: |
  AWS GameLift fleet management including game server deployments, fleet scaling, matchmaking configuration, game session monitoring, and player session tracking. Covers fleet health, capacity utilization, matchmaking metrics, and cost analysis.
connection_type: aws-gamelift
preload: false
---

# AWS GameLift Management Skill

Monitor and manage AWS GameLift fleets, matchmaking, and game sessions.

## MANDATORY: Discovery-First Pattern

**Always discover fleets and aliases before inspecting sessions or scaling.**

### Phase 1: Discovery

```bash
#!/bin/bash
REGION="${AWS_REGION:-us-east-1}"

echo "=== GameLift Fleets ==="
aws gamelift describe-fleet-attributes --region "$REGION" \
  --query 'FleetAttributes[].{Name:Name,ID:FleetId,Status:Status,Type:ComputeType,OS:OperatingSystem}' \
  --output table

echo ""
echo "=== Fleet Capacity ==="
aws gamelift describe-fleet-capacity --region "$REGION" \
  --query 'FleetCapacity[].{Fleet:FleetId,Desired:InstanceCounts.DESIRED,Active:InstanceCounts.ACTIVE,Idle:InstanceCounts.IDLE,Pending:InstanceCounts.PENDING}' \
  --output table

echo ""
echo "=== Aliases ==="
aws gamelift list-aliases --region "$REGION" \
  --query 'Aliases[].{Name:Name,ID:AliasId,Strategy:RoutingStrategy.Type,Fleet:RoutingStrategy.FleetId}' \
  --output table

echo ""
echo "=== Matchmaking Configurations ==="
aws gamelift describe-matchmaking-configurations --region "$REGION" \
  --query 'Configurations[].{Name:Name,Status:ConfigurationStatus,Timeout:RequestTimeoutSeconds,Backfill:BackfillMode}' \
  --output table
```

**Phase 1 outputs:** Fleet list with status, capacity, aliases, matchmaking configs

### Phase 2: Analysis

```bash
#!/bin/bash
FLEET_ID="${1:-$GAMELIFT_FLEET_ID}"

echo "=== Fleet Utilization ==="
aws gamelift describe-fleet-utilization --fleet-ids "$FLEET_ID" --region "$REGION" \
  --query 'FleetUtilization[].{Fleet:FleetId,ActiveSessions:ActiveGameSessionCount,ActivePlayers:CurrentPlayerSessionCount,MaxSessions:MaximumPlayerSessionCount}' \
  --output table

echo ""
echo "=== Active Game Sessions ==="
aws gamelift describe-game-sessions --fleet-id "$FLEET_ID" --region "$REGION" \
  --status-filter ACTIVE \
  --query 'GameSessions[].{ID:GameSessionId,Status:Status,Players:CurrentPlayerSessionCount,Max:MaximumPlayerSessionCount,Created:CreationTime}' \
  --output table | head -20

echo ""
echo "=== Scaling Policies ==="
aws gamelift describe-scaling-policies --fleet-id "$FLEET_ID" --region "$REGION" \
  --query 'ScalingPolicies[].{Name:Name,Type:PolicyType,Metric:MetricName,Threshold:Threshold,Status:Status}' \
  --output table

echo ""
echo "=== Fleet Events (last 24h) ==="
aws gamelift describe-fleet-events --fleet-id "$FLEET_ID" --region "$REGION" \
  --start-time "$(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v-24H +%Y-%m-%dT%H:%M:%SZ)" \
  --query 'Events[].{Time:EventTime,Code:EventCode,Message:Message}' \
  --output table | head -20
```

## Output Format

```
AWS GAMELIFT STATUS
===================
Region: {region}
Fleets: {count} (Active: {active}, Error: {error})
Total Capacity: {instances} instances
Active Sessions: {count} | Players: {count}
Utilization: {percent}%
Matchmaking Configs: {count}
Scaling Policies: {count} active
Issues: {list_of_warnings}
```

## Common Pitfalls

- **Fleet ID vs Alias**: Always resolve aliases to fleet IDs before querying sessions
- **Multi-region**: GameLift fleets are regional — check all active regions
- **Spot vs On-Demand**: Spot fleets can lose instances — monitor FLEET_ACTIVATION_FAILED events
- **Session limits**: Default 1 game session per instance — check runtime configuration
