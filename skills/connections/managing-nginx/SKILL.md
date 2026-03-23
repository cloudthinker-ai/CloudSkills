---
name: managing-nginx
description: |
  Use when working with Nginx — nginx web server and reverse proxy management,
  upstream health monitoring, virtual host analysis, access log analytics, and
  rate limiting configuration. Covers server block inspection, SSL certificate
  status, connection metrics, and load balancing tuning. Read this skill before
  any Nginx operations — it enforces discovery-first patterns,
  anti-hallucination rules, and safety constraints.
connection_type: nginx
preload: false
---

# Nginx Management Skill

Monitor, analyze, and manage Nginx servers safely.

## MANDATORY: Discovery-First Pattern

**Always inspect the running Nginx configuration and status before making changes. Never guess server names or upstream blocks.**

### Phase 1: Discovery

```bash
#!/bin/bash

nginx_cmd() {
    ${NGINX_SUDO:+sudo} nginx "$@"
}

echo "=== Nginx Version & Modules ==="
nginx_cmd -V 2>&1 | head -5

echo ""
echo "=== Configuration Test ==="
nginx_cmd -t 2>&1

echo ""
echo "=== Active Configuration File ==="
nginx_cmd -T 2>&1 | grep -E '# configuration file' | head -20

echo ""
echo "=== Running Processes ==="
ps aux | grep '[n]ginx' | awk '{print $1, $2, $11}'

echo ""
echo "=== Listening Ports ==="
${NGINX_SUDO:+sudo} ss -tlnp | grep nginx 2>/dev/null || \
    ${NGINX_SUDO:+sudo} netstat -tlnp 2>/dev/null | grep nginx

echo ""
echo "=== Stub Status (if enabled) ==="
curl -s http://127.0.0.1/nginx_status 2>/dev/null || \
    curl -s http://127.0.0.1:8080/nginx_status 2>/dev/null || \
    echo "stub_status not enabled — add 'stub_status;' to a location block"
```

**Phase 1 outputs:** Version, loaded modules, server blocks, upstream definitions, listening ports

### Phase 2: Analysis

Only inspect server blocks and upstreams confirmed in Phase 1 output.

## Anti-Hallucination Rules

- **NEVER assume server_name values** — always parse from `nginx -T` output
- **NEVER guess upstream block names** — extract from active configuration
- **NEVER assume log paths** — check `access_log` and `error_log` directives
- **NEVER assume SSL cert paths** — verify from `ssl_certificate` directives
- **ALWAYS validate config** with `nginx -t` before any reload

## Safety Rules

- **READ-ONLY by default**: Use `nginx -T`, stub_status, log reading
- **FORBIDDEN without explicit request**: `nginx -s stop`, editing config files, deleting logs
- **ALWAYS test before reload**: Run `nginx -t` before `nginx -s reload`
- **NEVER hot-edit**: Copy config, edit copy, test copy, then move into place
- **Backup configs**: Always `cp nginx.conf nginx.conf.bak.$(date +%s)` before changes

## Core Helper Functions

```bash
#!/bin/bash

# Parse all server blocks
list_server_blocks() {
    nginx -T 2>&1 | awk '/server_name/{print $2}' | sort -u
}

# Parse all upstream blocks
list_upstreams() {
    nginx -T 2>&1 | awk '/upstream\s+/{print $2}' | tr -d '{' | sort -u
}

# Check upstream health (requires upstream module or stub_status)
check_upstream_health() {
    local upstream="$1"
    nginx -T 2>&1 | awk -v us="$upstream" '
        /upstream.*'$upstream'/ { found=1 }
        found && /server / { print $2 }
        found && /}/ { found=0 }
    '
}

# Get connection metrics from stub_status
get_connections() {
    local status_url="${1:-http://127.0.0.1/nginx_status}"
    curl -s "$status_url" | awk '
        /Active/ { print "Active connections:", $3 }
        /accepts/ { getline; print "Accepts:", $1, "Handled:", $2, "Requests:", $3 }
        /Reading/ { print $0 }
    '
}
```

## Common Operations

### Virtual Host Analysis

```bash
#!/bin/bash
echo "=== All Server Blocks ==="
nginx -T 2>&1 | awk '
    /server\s*\{/ { in_server=1; block="" }
    in_server { block = block "\n" $0 }
    in_server && /server_name/ { name=$2 }
    in_server && /listen/ { listen=$2 }
    in_server && /root/ { root=$2 }
    in_server && /\}/ && --in_server==0 {
        printf "%-30s listen=%-10s root=%s\n", name, listen, root
    }
'

echo ""
echo "=== SSL Certificate Status ==="
nginx -T 2>&1 | grep ssl_certificate | grep -v '#' | while read _ cert; do
    cert=$(echo "$cert" | tr -d ';')
    if [ -f "$cert" ]; then
        expiry=$(openssl x509 -enddate -noout -in "$cert" 2>/dev/null | cut -d= -f2)
        echo "$cert -> expires: $expiry"
    else
        echo "$cert -> FILE NOT FOUND"
    fi
done
```

### Access Log Analytics

```bash
#!/bin/bash
LOG_FILE="${1:-/var/log/nginx/access.log}"

echo "=== Request Volume (last 1000 lines) ==="
tail -1000 "$LOG_FILE" | awk '{print $9}' | sort | uniq -c | sort -rn | head -10
echo "(status code distribution)"

echo ""
echo "=== Top Requesting IPs ==="
tail -1000 "$LOG_FILE" | awk '{print $1}' | sort | uniq -c | sort -rn | head -10

echo ""
echo "=== Top Requested Paths ==="
tail -1000 "$LOG_FILE" | awk '{print $7}' | sort | uniq -c | sort -rn | head -10

echo ""
echo "=== 5xx Errors ==="
tail -5000 "$LOG_FILE" | awk '$9 ~ /^5/ {print $0}' | tail -10

echo ""
echo "=== Slow Requests (>2s response time, if using $request_time) ==="
tail -5000 "$LOG_FILE" | awk '{if ($NF+0 > 2.0) print $0}' | tail -10
```

### Rate Limiting Status

```bash
#!/bin/bash
echo "=== Rate Limit Zones ==="
nginx -T 2>&1 | grep -E 'limit_req_zone|limit_conn_zone' | grep -v '#'

echo ""
echo "=== Rate Limit Applications ==="
nginx -T 2>&1 | grep -E 'limit_req |limit_conn ' | grep -v '#'

echo ""
echo "=== Rate Limit Rejections (from error log) ==="
ERROR_LOG="${1:-/var/log/nginx/error.log}"
tail -1000 "$ERROR_LOG" 2>/dev/null | grep -c 'limiting requests' | \
    xargs -I{} echo "Rate limit hits (last 1000 log lines): {}"
```

### Upstream Health Check

```bash
#!/bin/bash
echo "=== Upstream Definitions ==="
nginx -T 2>&1 | awk '
    /upstream/ { name=$2; gsub(/\{/,"",name) }
    /server / && name { printf "upstream=%-20s server=%s\n", name, $2 }
    /\}/ { name="" }
' | grep -v '^$'

echo ""
echo "=== Backend Connectivity Test ==="
nginx -T 2>&1 | awk '/upstream/{name=$2} /server /{print name, $2}' | \
    tr -d '{;' | while read upstream server; do
    host=$(echo "$server" | cut -d: -f1)
    port=$(echo "$server" | cut -d: -f2)
    timeout 2 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null && \
        echo "OK   $upstream -> $server" || \
        echo "FAIL $upstream -> $server"
done
```

## Output Format

Present results as a structured report:
```
Managing Nginx Report
═════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

## Common Pitfalls

- **`nginx -s reload` without `-t`**: Always test config before reloading — a bad config can bring down the server
- **Editing sites-enabled symlinks**: Edit the source in sites-available, not the symlink
- **Log rotation**: Ensure logrotate sends `USR1` signal — otherwise Nginx writes to deleted file handles
- **worker_connections vs ulimit**: `worker_connections` is limited by the system's file descriptor limit
- **proxy_pass trailing slash**: `proxy_pass http://backend/` vs `proxy_pass http://backend` behave differently with URI stripping
- **Large client bodies**: Default `client_max_body_size` is 1MB — uploads will fail silently with 413 errors
- **DNS caching**: Nginx caches DNS at startup — use `resolver` directive with upstream variables for dynamic resolution
