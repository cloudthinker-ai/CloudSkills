---
name: managing-dokku
description: |
  Dokku self-hosted PaaS management covering app inventory, container status, domain configuration, plugin listing, persistent storage mounts, environment variable auditing, proxy settings, and deployment history. Use for managing Dokku-based infrastructure.
connection_type: dokku
preload: false
---

# Dokku Management

Analyze Dokku apps, containers, plugins, and deployment configuration on self-hosted PaaS.

## Phase 1: Discovery

```bash
#!/bin/bash
DOKKU_HOST="${DOKKU_HOST:-localhost}"
DOKKU_CMD="ssh dokku@${DOKKU_HOST}"

echo "=== Apps Inventory ==="
$DOKKU_CMD apps:list 2>/dev/null | tail -n +2 | while read APP; do
  STATUS=$($DOKKU_CMD ps:report "$APP" --ps-computed-status 2>/dev/null)
  echo -e "${APP}\t${STATUS}"
done | column -t | head -20

echo ""
echo "=== Container Status ==="
for APP in $($DOKKU_CMD apps:list 2>/dev/null | tail -n +2); do
  $DOKKU_CMD ps:report "$APP" 2>/dev/null | grep -E "running|deployed|restore" | head -5
done

echo ""
echo "=== Domains ==="
for APP in $($DOKKU_CMD apps:list 2>/dev/null | tail -n +2); do
  DOMAINS=$($DOKKU_CMD domains:report "$APP" --domains-app-vhosts 2>/dev/null)
  echo "${APP}: ${DOMAINS}"
done

echo ""
echo "=== Plugins ==="
$DOKKU_CMD plugin:list 2>/dev/null

echo ""
echo "=== Storage Mounts ==="
for APP in $($DOKKU_CMD apps:list 2>/dev/null | tail -n +2); do
  MOUNTS=$($DOKKU_CMD storage:report "$APP" --storage-bind-mounts 2>/dev/null)
  [ -n "$MOUNTS" ] && echo "${APP}: ${MOUNTS}"
done
```

## Phase 2: Analysis

```bash
#!/bin/bash
DOKKU_HOST="${DOKKU_HOST:-localhost}"
DOKKU_CMD="ssh dokku@${DOKKU_HOST}"

echo "=== Process Scaling ==="
for APP in $($DOKKU_CMD apps:list 2>/dev/null | tail -n +2); do
  SCALE=$($DOKKU_CMD ps:scale "$APP" 2>/dev/null | tail -n +2 | tr '\n' ' ')
  echo "${APP}: ${SCALE}"
done

echo ""
echo "=== Environment Variables (count only) ==="
for APP in $($DOKKU_CMD apps:list 2>/dev/null | tail -n +2); do
  COUNT=$($DOKKU_CMD config:export "$APP" 2>/dev/null | wc -l)
  echo "${APP}: ${COUNT} env vars"
done

echo ""
echo "=== Proxy Configuration ==="
for APP in $($DOKKU_CMD apps:list 2>/dev/null | tail -n +2); do
  PORTS=$($DOKKU_CMD proxy:ports "$APP" 2>/dev/null | tail -n +2 | tr '\n' ' ')
  echo "${APP}: ${PORTS}"
done

echo ""
echo "=== Docker Container Resources ==="
for APP in $($DOKKU_CMD apps:list 2>/dev/null | tail -n +2); do
  $DOKKU_CMD resource:report "$APP" 2>/dev/null | grep -E "memory|cpu" | head -4
done

echo ""
echo "=== Network Config ==="
for APP in $($DOKKU_CMD apps:list 2>/dev/null | tail -n +2); do
  $DOKKU_CMD network:report "$APP" 2>/dev/null | grep -E "bind-all|attach-post" | head -3
done

echo ""
echo "=== SSL/TLS Status ==="
for APP in $($DOKKU_CMD apps:list 2>/dev/null | tail -n +2); do
  SSL=$($DOKKU_CMD certs:report "$APP" 2>/dev/null | grep -i "ssl-enabled" | head -1)
  echo "${APP}: ${SSL}"
done
```

## Output Format

```
DOKKU ANALYSIS
===============
App              Status    Scale        Domains              Storage  SSL
──────────────────────────────────────────────────────────────────────────
web-app          running   web:2        app.example.com      2 mounts Yes
worker           running   worker:1     none                 1 mount  No
api              running   web:3        api.example.com      0 mounts Yes

Apps: 3 | Plugins: 8 installed | Total Processes: 6
SSL: 2/3 apps secured | Storage: 3 bind mounts
```

## Safety Rules

- **Read-only**: Only use `list`, `report`, and `show` Dokku subcommands
- **Never deploy, scale, or destroy** apps without explicit confirmation
- **Env vars**: Never output config variable values, only counts
- **SSH access**: Requires SSH key authentication to the Dokku host
