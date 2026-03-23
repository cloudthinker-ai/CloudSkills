---
name: managing-podman
description: |
  Use when working with Podman — podman rootless container and pod management.
  Covers container lifecycle, pod orchestration, image building, systemd
  integration, rootless networking, and container migration from Docker. Use
  when managing Podman containers, creating pods, generating systemd units, or
  building images without a daemon.
connection_type: podman
preload: false
---

# Podman Management Skill

Manage Podman rootless containers, pods, images, and systemd integration.

## Core Helper Functions

```bash
#!/bin/bash

# Podman command wrapper
podman_cmd() {
    podman "$@" 2>/dev/null
}

# Podman JSON output helper
podman_json() {
    podman "$@" --format json 2>/dev/null | jq '.'
}

# Podman API helper (for remote management)
podman_api() {
    local endpoint="$1"
    local socket="${PODMAN_SOCKET:-/run/user/$(id -u)/podman/podman.sock}"
    curl -s --unix-socket "$socket" "http://d/v4.0.0${endpoint}"
}
```

## MANDATORY: Discovery-First Pattern

**Always inspect host capabilities and running containers before performing operations.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Podman Host Info ==="
podman info --format json 2>/dev/null | jq '{
    version: .version.Version,
    api_version: .version.APIVersion,
    os: .host.os,
    arch: .host.arch,
    rootless: .host.security.rootless,
    cgroup_version: .host.cgroupVersion,
    oci_runtime: .host.ociRuntime.name,
    storage_driver: .store.graphDriverName,
    image_store: .store.imageStore.number,
    container_store: .store.containerStore.number
}'

echo ""
echo "=== Running Containers ==="
podman ps --format '{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' | column -t | head -20

echo ""
echo "=== Pods ==="
podman pod ps --format '{{.Id}}\t{{.Name}}\t{{.Status}}\t{{.NumberOfContainers}} containers\t{{.InfraId}}' 2>/dev/null | column -t | head -15

echo ""
echo "=== Disk Usage ==="
podman system df 2>/dev/null
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `--format json` with jq or `--format` with Go templates
- Never dump full `podman inspect` -- extract key fields

## Common Operations

### Container Lifecycle Dashboard

```bash
#!/bin/bash
echo "=== All Containers ==="
podman ps -a --format json 2>/dev/null | jq '{
    total: length,
    running: [.[] | select(.State == "running")] | length,
    exited: [.[] | select(.State == "exited")] | length,
    created: [.[] | select(.State == "created")] | length
}'

echo ""
echo "=== Resource Usage ==="
podman stats --no-stream --format '{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}' \
    | column -t | head -20

echo ""
echo "=== Container Health ==="
podman ps -a --format json 2>/dev/null | jq -r '
    .[] | "\(.Names[0] // .Id[0:12])\t\(.State)\t\(.StartedAt[0:19])\t\(.ExitCode // "N/A")"
' | column -t | head -15

echo ""
echo "=== Containers with Restart Issues ==="
podman ps -a --format json 2>/dev/null | jq -r '
    .[] | select(.RestartCount > 0) | "\(.Names[0])\t\(.RestartCount) restarts\t\(.State)"
' | column -t
```

### Pod Management

```bash
#!/bin/bash
echo "=== Pod Overview ==="
podman pod ps --format json 2>/dev/null | jq -r '
    .[] | "\(.Name)\t\(.Status)\t\(.NumberOfContainers) containers\t\(.Id[0:12])"
' | column -t

echo ""
echo "=== Pod Detail ==="
POD="${1:-}"
if [ -n "$POD" ]; then
    podman pod inspect "$POD" 2>/dev/null | jq '{
        name: .Name,
        id: .Id[0:12],
        state: .State,
        created: .Created,
        infra_container: .InfraContainerId[0:12],
        shared_namespaces: .SharedNamespaces,
        containers: [.Containers[] | {id: .Id[0:12], name: .Name, state: .State}]
    }'

    echo ""
    echo "--- Pod Container Logs (last 10 lines each) ---"
    for cid in $(podman pod inspect "$POD" 2>/dev/null | jq -r '.Containers[].Id'); do
        CNAME=$(podman inspect "$cid" --format '{{.Name}}' 2>/dev/null)
        echo "=== $CNAME ==="
        podman logs "$cid" --tail 10 2>&1 | tail -5
    done
fi
```

### Image Building & Management

```bash
#!/bin/bash
echo "=== Local Images (sorted by size) ==="
podman images --format '{{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.ID}}\t{{.Created}}' \
    | sort -k2 -h -r | column -t | head -20

echo ""
echo "=== Dangling Images ==="
podman images -f "dangling=true" --format '{{.ID}}\t{{.Size}}\t{{.Created}}' | column -t

echo ""
echo "=== Build History ==="
IMAGE="${1:-}"
if [ -n "$IMAGE" ]; then
    podman history "$IMAGE" --format '{{.CreatedBy}}\t{{.Size}}' --no-trunc | head -15
fi

echo ""
echo "=== Image Tree ==="
if [ -n "$IMAGE" ]; then
    podman image tree "$IMAGE" 2>/dev/null | head -20
fi
```

### Systemd Integration

```bash
#!/bin/bash
echo "=== Generate Systemd Unit for Container ==="
CONTAINER="${1:-}"
if [ -n "$CONTAINER" ]; then
    echo "--- Unit file preview ---"
    podman generate systemd --name "$CONTAINER" --new 2>/dev/null | head -30

    echo ""
    echo "--- Quadlet support (Podman 4.4+) ---"
    echo "Place .container files in ~/.config/containers/systemd/ for rootless"
    echo "Place .container files in /etc/containers/systemd/ for rootful"
fi

echo ""
echo "=== Existing Podman Systemd Units ==="
systemctl --user list-units 'podman-*' --no-pager 2>/dev/null | head -15
systemctl list-units 'podman-*' --no-pager 2>/dev/null | head -15

echo ""
echo "=== Auto-Update Eligible Containers ==="
podman auto-update --dry-run 2>/dev/null | head -10
```

### Rootless Networking & Volumes

```bash
#!/bin/bash
echo "=== Networks ==="
podman network ls --format '{{.Name}}\t{{.Driver}}\t{{.ID}}' | column -t

echo ""
echo "=== Network Details ==="
for net in $(podman network ls --format '{{.Name}}' | grep -v "podman"); do
    podman network inspect "$net" 2>/dev/null | jq '.[0] | {
        name: .name,
        driver: .driver,
        subnets: [.subnets[]? | .subnet],
        dns_enabled: .dns_enabled
    }'
done

echo ""
echo "=== Volumes ==="
podman volume ls --format '{{.Name}}\t{{.Driver}}\t{{.Mountpoint}}' | column -t | head -15

echo ""
echo "=== Unused Volumes ==="
podman volume ls -f "dangling=true" --format '{{.Name}}\t{{.Driver}}' | column -t

echo ""
echo "=== Rootless Port Forwarding ==="
echo "Note: Rootless requires ports >= 1024 unless net.ipv4.ip_unprivileged_port_start is adjusted"
podman ps --format '{{.Names}}\t{{.Ports}}' | grep -v "^$" | column -t
```

## Safety Rules
- **Read-only by default**: Use `podman inspect`, `podman ps`, `podman logs`, `podman stats`
- **Never remove** containers or images without explicit user confirmation
- **Rootless limitations**: Be aware of port, storage, and networking restrictions
- **Systemd units**: Generating units is safe; installing them changes system state

## Output Format

Present results as a structured report:
```
Managing Podman Report
══════════════════════
Resources discovered: [count]

Resource       Status    Key Metric    Issues
──────────────────────────────────────────────
[name]         [ok/warn] [value]       [findings]

Summary: [total] resources | [ok] healthy | [warn] warnings | [crit] critical
Action Items: [list of prioritized findings]
```

Target ≤50 lines of output. Use tables for multi-resource comparisons.

## Anti-Hallucination Rules

1. **NEVER assume resource names** — always discover via CLI/API in Phase 1 before referencing in Phase 2.
2. **NEVER fabricate metric names or dimensions** — verify against the service documentation or `--help` output.
3. **NEVER mix CLI commands between service versions** — confirm which version/API you are targeting.
4. **ALWAYS use the discovery → verify → analyze chain** — every resource referenced must have been discovered first.
5. **ALWAYS handle empty results gracefully** — an empty response is valid data, not an error to retry.

## Counter-Rationalizations

| Shortcut | Counter | Why |
|----------|---------|-----|
| "I'll skip discovery and check known resources" | Always run Phase 1 discovery first | Resource names change, new resources appear — assumed names cause errors |
| "The user only asked for a quick check" | Follow the full discovery → analysis flow | Quick checks miss critical issues; structured analysis catches silent failures |
| "Default configuration is probably fine" | Audit configuration explicitly | Defaults often leave logging, security, and optimization features disabled |
| "Metrics aren't needed for this" | Always check relevant metrics when available | API/CLI responses show current state; metrics reveal trends and intermittent issues |
| "I don't have access to that" | Try the command and report the actual error | Assumed permission failures prevent useful investigation; actual errors are informative |

## Common Pitfalls
- **Rootless vs rootful**: Commands behave differently -- check `podman info` for rootless status
- **Networking**: Rootless uses slirp4netns or pasta -- different from Docker's bridge networking
- **Storage**: Rootless stores images in `~/.local/share/containers` -- different path from rootful
- **Docker compatibility**: Most Docker commands work but some flags differ (e.g., `--privileged` behavior)
- **Systemd integration**: Use `podman generate systemd --new` to create units that recreate containers on start
