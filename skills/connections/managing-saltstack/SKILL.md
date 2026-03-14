---
name: managing-saltstack
description: |
  SaltStack configuration management and remote execution. Covers state management, grain data, pillar data, job management, targeting, event system, and orchestration. Use when managing Salt infrastructure, executing remote commands, debugging state failures, or inspecting minion data.
connection_type: saltstack
preload: false
---

# SaltStack Management Skill

Manage and inspect SaltStack states, grains, pillars, jobs, and minion connectivity.

## MANDATORY: Discovery-First Pattern

**Always check minion connectivity and key status before executing states or commands.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Salt Version ==="
salt --version 2>/dev/null

echo ""
echo "=== Minion Key Status ==="
salt-key --list all 2>/dev/null | head -20

echo ""
echo "=== Connected Minions ==="
salt '*' test.ping --output=json 2>/dev/null | jq 'to_entries | length' | xargs -I{} echo "{} minions responding"

echo ""
echo "=== Salt Master Status ==="
salt-run manage.status 2>/dev/null | head -15
```

## Core Helper Functions

```bash
#!/bin/bash

# Salt command wrapper with timeout
salt_cmd() {
    salt "$@" --timeout=30 --output=json 2>/dev/null
}

# Salt API call (if salt-api is running)
salt_api() {
    local endpoint="$1"
    local data="${2:-}"
    curl -s -H "X-Auth-Token: $SALT_TOKEN" \
        -H "Content-Type: application/json" \
        "http://localhost:8000/$endpoint" \
        ${data:+-d "$data"}
}

# Target helper
salt_target() {
    local target="$1"
    shift
    salt "$target" "$@" --timeout=30 --output=json 2>/dev/null
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `--output=json` with jq for structured output
- Use compound targeting to narrow scope
- Never run commands against '*' in production without `--batch-size`

## Common Operations

### State Management

```bash
#!/bin/bash
TARGET="${1:?Target required (minion or glob)}"
SLS="${2:-}"

if [ -n "$SLS" ]; then
    echo "=== Dry Run: State $SLS on $TARGET ==="
    salt "$TARGET" state.apply "$SLS" test=True --output=json 2>/dev/null | jq '
        to_entries[] | {
            minion: .key,
            states: [.value | to_entries[] | {
                id: .key,
                result: .value.result,
                changes: (.value.changes | length > 0),
                comment: .value.comment
            }]
        }
    ' | head -50
else
    echo "=== Highstate Dry Run on $TARGET ==="
    salt "$TARGET" state.highstate test=True --output=json 2>/dev/null | jq '
        to_entries[] | {
            minion: .key,
            summary: {
                total: (.value | length),
                changed: ([.value | to_entries[] | select(.value.changes | length > 0)] | length),
                failed: ([.value | to_entries[] | select(.value.result == false)] | length)
            }
        }
    ' | head -30
fi
```

### Grain and Pillar Inspection

```bash
#!/bin/bash
TARGET="${1:?Target required}"

echo "=== Key Grains ==="
salt "$TARGET" grains.items --output=json 2>/dev/null | jq '
    to_entries[] | {
        minion: .key,
        os: .value.os,
        osrelease: .value.osrelease,
        kernel: .value.kernel,
        cpus: .value.num_cpus,
        mem_total: .value.mem_total,
        ip4: .value.ipv4
    }
' | head -30

echo ""
echo "=== Pillar Data ==="
salt "$TARGET" pillar.items --output=json 2>/dev/null | jq '
    to_entries[] | {minion: .key, pillar_keys: (.value | keys)}
' | head -20
```

### Job Management

```bash
#!/bin/bash
echo "=== Active Jobs ==="
salt-run jobs.active --output=json 2>/dev/null | jq '
    to_entries[] | {
        jid: .key,
        function: .value.Function,
        target: .value.Target,
        user: .value.User,
        started: .value.StartTime
    }
'

echo ""
echo "=== Recent Jobs ==="
salt-run jobs.list_jobs --output=json 2>/dev/null | jq '
    to_entries | sort_by(.key) | reverse | .[:10][] | {
        jid: .key,
        function: .value.Function,
        target: .value.Target,
        user: .value.User
    }
'

echo ""
echo "=== Job Result ==="
JID="${1:-}"
if [ -n "$JID" ]; then
    salt-run jobs.lookup_jid "$JID" --output=json 2>/dev/null | jq '.' | head -30
fi
```

### Remote Execution

```bash
#!/bin/bash
TARGET="${1:?Target required}"
CMD="${2:?Command required}"

echo "=== Executing on $TARGET ==="
salt "$TARGET" cmd.run "$CMD" --timeout=30 --output=json 2>/dev/null | jq '
    to_entries[] | "\(.key): \(.value)"
' | head -30
```

### Event and Reactor Monitoring

```bash
#!/bin/bash
echo "=== Recent Events ==="
salt-run state.event tagmatch='salt/*' count=10 2>/dev/null | head -20

echo ""
echo "=== Reactor Configuration ==="
cat /etc/salt/master.d/reactor.conf 2>/dev/null || \
grep -A 10 'reactor:' /etc/salt/master 2>/dev/null | head -15
```

## Safety Rules

- **NEVER run highstate on '*' in production** -- use `--batch-size` or specific targeting
- **Always use `test=True` first** before applying states
- **Pillar data may contain secrets** -- never dump all pillar data without filtering
- **Key acceptance is a security operation** -- verify minion identity before accepting keys
- **Use compound targeting** for precision -- avoid broad globs in production

## Common Pitfalls

- **Minion not responding**: Check minion service, firewall (ports 4505/4506), and key acceptance
- **Pillar rendering errors**: Jinja errors in pillar files cause empty/partial pillar data -- check `pillar.items` for errors
- **State ordering**: States execute in file order by default -- use `require`/`watch` for explicit ordering
- **Grain targeting drift**: Grain values can change -- don't rely on volatile grains for targeting
- **Job timeout**: Long-running states may exceed default timeout -- increase with `--timeout`
- **Returner failures**: If returner (MySQL, Redis) is down, job results may be lost
- **File server caching**: Salt master caches files -- use `salt-run fileserver.update` after changes
- **Reactor storms**: Poorly scoped reactors can trigger cascading events -- test reactor configs carefully
