---
name: managing-watchtower
description: |
  Watchtower container update automation analysis covering monitored container inventory, update schedules, notification configuration, update history, container labeling for inclusion and exclusion, and rolling restart policies. Use for auditing automated container update infrastructure.
connection_type: watchtower
preload: false
---

# Watchtower Management

Analyze Watchtower automated container update configuration and update history.

## Phase 1: Discovery

```bash
#!/bin/bash
DOCKER_CMD="${DOCKER_CMD:-docker}"

echo "=== Watchtower Container ==="
$DOCKER_CMD inspect watchtower 2>/dev/null | jq '.[0] | {
  id: .Id[0:12],
  image: .Config.Image,
  state: .State.Status,
  started: .State.StartedAt,
  env: [.Config.Env[] | select(startswith("WATCHTOWER_"))]
}'

echo ""
echo "=== Watchtower Schedule ==="
$DOCKER_CMD inspect watchtower 2>/dev/null | jq -r '.[0].Config.Env[] | select(startswith("WATCHTOWER_SCHEDULE") or startswith("WATCHTOWER_POLL_INTERVAL"))' 2>/dev/null
POLL=$($DOCKER_CMD inspect watchtower 2>/dev/null | jq -r '.[0].Config.Env[] | select(startswith("WATCHTOWER_POLL_INTERVAL")) | split("=") | last' 2>/dev/null)
[ -n "$POLL" ] && echo "Poll interval: ${POLL}s ($(echo "$POLL / 3600" | bc)h)"

echo ""
echo "=== Monitored Containers ==="
$DOCKER_CMD ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' | while IFS=$'\t' read NAME IMAGE STATUS; do
  LABEL=$($DOCKER_CMD inspect "$NAME" 2>/dev/null | jq -r '.[0].Config.Labels["com.centurylinklabs.watchtower.enable"] // "default"')
  echo -e "${NAME}\t${IMAGE}\t${LABEL}\t${STATUS}"
done | column -t | head -20

echo ""
echo "=== Excluded Containers ==="
$DOCKER_CMD ps -a --format '{{.Names}}' | while read NAME; do
  LABEL=$($DOCKER_CMD inspect "$NAME" 2>/dev/null | jq -r '.[0].Config.Labels["com.centurylinklabs.watchtower.enable"] // "default"')
  [ "$LABEL" = "false" ] && echo "$NAME"
done

echo ""
echo "=== Notification Config ==="
$DOCKER_CMD inspect watchtower 2>/dev/null | jq -r '.[0].Config.Env[] | select(startswith("WATCHTOWER_NOTIFICATION"))' 2>/dev/null | sed 's/=.*TOKEN.*/=<REDACTED>/' | sed 's/=.*URL.*/=<REDACTED>/'
```

## Phase 2: Analysis

```bash
#!/bin/bash
DOCKER_CMD="${DOCKER_CMD:-docker}"

echo "=== Watchtower Logs (recent updates) ==="
$DOCKER_CMD logs watchtower --tail 100 2>&1 \
  | grep -E "Found new|Updating|Stopping|Starting|Unable" | tail -20

echo ""
echo "=== Update Summary ==="
UPDATED=$($DOCKER_CMD logs watchtower --tail 500 2>&1 | grep -c "Found new" 2>/dev/null)
FAILED=$($DOCKER_CMD logs watchtower --tail 500 2>&1 | grep -c "Unable to update" 2>/dev/null)
echo "Recent updates: ${UPDATED:-0} successful, ${FAILED:-0} failed"

echo ""
echo "=== Container Image Freshness ==="
$DOCKER_CMD ps --format '{{.Names}}\t{{.Image}}\t{{.CreatedAt}}' | while IFS=$'\t' read NAME IMAGE CREATED; do
  DIGEST=$($DOCKER_CMD inspect "$NAME" 2>/dev/null | jq -r '.[0].Image[0:19]')
  echo -e "${NAME}\t${IMAGE}\t${CREATED}\t${DIGEST}"
done | column -t | head -20

echo ""
echo "=== Watchtower Configuration Flags ==="
$DOCKER_CMD inspect watchtower 2>/dev/null | jq '{
  cleanup: ([.[0].Config.Env[] | select(startswith("WATCHTOWER_CLEANUP"))] | length > 0),
  rolling_restart: ([.[0].Config.Env[] | select(startswith("WATCHTOWER_ROLLING_RESTART"))] | length > 0),
  monitor_only: ([.[0].Config.Env[] | select(startswith("WATCHTOWER_MONITOR_ONLY"))] | length > 0),
  include_stopped: ([.[0].Config.Env[] | select(startswith("WATCHTOWER_INCLUDE_STOPPED"))] | length > 0),
  revive_stopped: ([.[0].Config.Env[] | select(startswith("WATCHTOWER_REVIVE_STOPPED"))] | length > 0),
  label_enable: ([.[0].Config.Env[] | select(startswith("WATCHTOWER_LABEL_ENABLE"))] | length > 0)
}'

echo ""
echo "=== Containers Needing Attention ==="
$DOCKER_CMD logs watchtower --tail 200 2>&1 \
  | grep -E "Unable|error|failed" | tail -10
```

## Output Format

```
WATCHTOWER ANALYSIS
====================
Container        Image                  Watched  Last Updated     Status
────────────────────────────────────────────────────────────────────────
nginx-proxy      jwilder/nginx-proxy    yes      2h ago           running
app-web          myapp:latest           yes      1d ago           running
postgres-db      postgres:15            no       manual           running

Schedule: Every 6h (POLL_INTERVAL=21600)
Mode: Update (not monitor-only) | Cleanup: enabled | Rolling: disabled
Recent: 5 updates, 0 failures | Notifications: slack
```

## Safety Rules

- **Read-only**: Only use `docker inspect`, `docker ps`, and `docker logs`
- **Never modify** Watchtower configuration or restart containers without confirmation
- **Notifications**: Redact webhook URLs and tokens from notification config
- **Log limits**: Always use `--tail` to prevent unbounded log output
