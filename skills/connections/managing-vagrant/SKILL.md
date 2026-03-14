---
name: managing-vagrant
description: |
  Vagrant development environment management. Covers box management, VM lifecycle, provisioner execution, multi-machine environments, snapshot management, and networking configuration. Use when managing Vagrant VMs, debugging provisioning failures, or inspecting development environment configurations.
connection_type: vagrant
preload: false
---

# Vagrant Management Skill

Manage and inspect Vagrant virtual machines, boxes, provisioners, and development environments.

## MANDATORY: Discovery-First Pattern

**Always check VM status and Vagrantfile before modifying environments.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Vagrant Version ==="
vagrant version 2>/dev/null | head -3

echo ""
echo "=== VM Status ==="
vagrant status 2>/dev/null

echo ""
echo "=== Global Status (all VMs) ==="
vagrant global-status 2>/dev/null | head -20

echo ""
echo "=== Installed Boxes ==="
vagrant box list 2>/dev/null | head -15

echo ""
echo "=== Vagrantfile Summary ==="
grep -E '(config\.vm\.|\.provision|\.network|\.synced_folder)' Vagrantfile 2>/dev/null | head -20
```

## Core Helper Functions

```bash
#!/bin/bash

# Vagrant wrapper with machine targeting
vg_cmd() {
    vagrant "$@" 2>&1
}

# Get machine info
vg_info() {
    local machine="${1:-default}"
    vagrant ssh-config "$machine" 2>/dev/null
}

# Check if machine is running
vg_running() {
    local machine="${1:-default}"
    vagrant status "$machine" 2>/dev/null | grep -q "running"
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `vagrant status` and `vagrant ssh-config` for machine info
- Use `--machine-readable` for parseable output
- Never dump full Vagrantfile -- extract key configuration blocks

## Common Operations

### VM Lifecycle Management

```bash
#!/bin/bash
MACHINE="${1:-default}"
ACTION="${2:-status}"

case "$ACTION" in
    status)
        echo "=== VM Status ==="
        vagrant status "$MACHINE" 2>/dev/null
        echo ""
        echo "=== SSH Config ==="
        vagrant ssh-config "$MACHINE" 2>/dev/null
        ;;
    up)
        echo "=== Starting $MACHINE ==="
        vagrant up "$MACHINE" 2>&1 | tail -20
        ;;
    halt)
        echo "=== Stopping $MACHINE ==="
        vagrant halt "$MACHINE" 2>&1
        ;;
    reload)
        echo "=== Reloading $MACHINE ==="
        vagrant reload "$MACHINE" 2>&1 | tail -15
        ;;
    destroy)
        echo "=== DRY RUN: Would destroy $MACHINE ==="
        echo "Run: vagrant destroy $MACHINE -f"
        ;;
esac
```

### Provisioner Execution

```bash
#!/bin/bash
MACHINE="${1:-default}"

echo "=== Provisioners Defined ==="
grep -E '\.provision' Vagrantfile 2>/dev/null | head -10

echo ""
echo "=== Running Provisioners ==="
vagrant provision "$MACHINE" 2>&1 | tail -30

echo ""
echo "=== Provision Status ==="
vagrant status "$MACHINE" 2>/dev/null
```

### Box Management

```bash
#!/bin/bash
echo "=== Installed Boxes ==="
vagrant box list 2>/dev/null

echo ""
echo "=== Outdated Boxes ==="
vagrant box outdated --global 2>/dev/null | head -10

echo ""
echo "=== Box Disk Usage ==="
du -sh ~/.vagrant.d/boxes/*/ 2>/dev/null | sort -rh | head -10
```

### Snapshot Management

```bash
#!/bin/bash
MACHINE="${1:-default}"

echo "=== Snapshots for $MACHINE ==="
vagrant snapshot list "$MACHINE" 2>/dev/null

echo ""
ACTION="${2:-list}"
SNAP_NAME="${3:-}"
case "$ACTION" in
    save)
        SNAP_NAME="${SNAP_NAME:-snap-$(date +%s)}"
        echo "=== Saving Snapshot: $SNAP_NAME ==="
        vagrant snapshot save "$MACHINE" "$SNAP_NAME" 2>&1
        ;;
    restore)
        echo "=== Restoring Snapshot: $SNAP_NAME ==="
        echo "Run: vagrant snapshot restore $MACHINE $SNAP_NAME"
        ;;
    delete)
        echo "=== Deleting Snapshot: $SNAP_NAME ==="
        echo "Run: vagrant snapshot delete $MACHINE $SNAP_NAME"
        ;;
esac
```

### Multi-Machine Environment

```bash
#!/bin/bash
echo "=== All Machines ==="
vagrant status 2>/dev/null

echo ""
echo "=== Machine Configurations ==="
grep -B1 -A5 'define' Vagrantfile 2>/dev/null | head -30

echo ""
echo "=== Network Configuration ==="
grep -E '(private_network|public_network|forwarded_port)' Vagrantfile 2>/dev/null

echo ""
echo "=== Synced Folders ==="
grep 'synced_folder' Vagrantfile 2>/dev/null
```

## Safety Rules

- **NEVER `vagrant destroy` without explicit confirmation** -- data in VMs is lost permanently
- **Use snapshots before risky operations** -- quick rollback if provisioning breaks
- **Check port conflicts** before `vagrant up` -- forwarded ports may conflict with host services
- **Synced folders expose host files** -- be careful with sensitive data on host
- **Multi-machine destroy** removes ALL machines unless a name is specified

## Common Pitfalls

- **Provider not installed**: VirtualBox/VMware/Docker provider must be installed and compatible with Vagrant version
- **Port collisions**: Forwarded ports already in use cause `vagrant up` failures -- use `auto_correct: true`
- **NFS synced folders**: Require NFS server on host and may prompt for sudo password
- **Box version drift**: Older boxes may not work with newer Vagrant -- update with `vagrant box update`
- **Global status stale**: `vagrant global-status` can show stale entries -- use `--prune` to clean up
- **Provisioner ordering**: Provisioners run in order defined -- later provisioners may depend on earlier ones
- **Memory allocation**: Default VM memory may be insufficient -- configure `vb.memory` in Vagrantfile
- **Networking conflicts**: Private network IPs can conflict with host networks -- check subnet assignments
