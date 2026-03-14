---
name: managing-ansible
description: |
  Ansible automation and configuration management. Covers playbook execution, inventory management, role management, vault secrets, ad-hoc commands, fact gathering, and task debugging. Use when running playbooks, managing inventories, debugging task failures, or auditing Ansible configurations.
connection_type: ansible
preload: false
---

# Ansible Management Skill

Manage and execute Ansible playbooks, inventories, roles, and vault-encrypted secrets.

## MANDATORY: Discovery-First Pattern

**Always inspect inventory and available playbooks before executing tasks.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Ansible Version ==="
ansible --version 2>/dev/null | head -5

echo ""
echo "=== Inventory Summary ==="
ansible-inventory --list --yaml 2>/dev/null | head -30 || \
ansible-inventory --graph 2>/dev/null | head -30

echo ""
echo "=== Available Playbooks ==="
find . -maxdepth 3 -name "*.yml" -o -name "*.yaml" | grep -i playbook | head -20

echo ""
echo "=== Available Roles ==="
ls roles/ 2>/dev/null || ansible-galaxy list 2>/dev/null | head -15
```

## Core Helper Functions

```bash
#!/bin/bash

# Ansible wrapper with common options
ans_cmd() {
    ansible "$@" --forks=10 2>/dev/null
}

# Playbook execution with check mode
ans_playbook() {
    local playbook="$1"
    shift
    ansible-playbook "$playbook" "$@" 2>&1
}

# Vault wrapper
ans_vault() {
    ansible-vault "$@" 2>/dev/null
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use `--list-tasks` or `--list-tags` for playbook inspection without execution
- Use `--check` (dry-run) before actual execution
- Never dump full inventories -- use `--graph` or filter by group

## Common Operations

### Inventory Analysis

```bash
#!/bin/bash
echo "=== Host Groups ==="
ansible-inventory --graph 2>/dev/null

echo ""
echo "=== Group Variables ==="
GROUP="${1:-all}"
ansible-inventory --host "${GROUP}" --yaml 2>/dev/null | head -30 || \
ansible-inventory --list 2>/dev/null | jq --arg g "$GROUP" '.[$g] // "Group not found"'

echo ""
echo "=== Host Count by Group ==="
ansible-inventory --list 2>/dev/null | jq '
    to_entries[] |
    select(.value | type == "object" and has("hosts")) |
    "\(.key): \(.value.hosts | length) hosts"
' 2>/dev/null
```

### Playbook Dry Run and Inspection

```bash
#!/bin/bash
PLAYBOOK="${1:?Playbook path required}"

echo "=== Playbook Tasks ==="
ansible-playbook "$PLAYBOOK" --list-tasks 2>/dev/null

echo ""
echo "=== Playbook Tags ==="
ansible-playbook "$PLAYBOOK" --list-tags 2>/dev/null

echo ""
echo "=== Dry Run (Check Mode) ==="
ansible-playbook "$PLAYBOOK" --check --diff --limit "${2:-all}" 2>&1 | tail -30
```

### Ad-Hoc Commands and Fact Gathering

```bash
#!/bin/bash
HOST_PATTERN="${1:?Host pattern required}"

echo "=== Host Facts ==="
ansible "$HOST_PATTERN" -m setup -a 'filter=ansible_distribution*,ansible_memtotal_mb,ansible_processor_vcpus' 2>/dev/null | head -40

echo ""
echo "=== Connectivity Check ==="
ansible "$HOST_PATTERN" -m ping 2>/dev/null

echo ""
echo "=== Uptime ==="
ansible "$HOST_PATTERN" -m command -a "uptime" 2>/dev/null | head -20
```

### Vault Management

```bash
#!/bin/bash
ACTION="${1:?Action required: view|encrypt|decrypt|rekey}"

case "$ACTION" in
    view)
        echo "=== Encrypted Files ==="
        find . -name "*.yml" -o -name "*.yaml" | xargs grep -l 'ANSIBLE_VAULT' 2>/dev/null
        ;;
    encrypt)
        FILE="${2:?File path required}"
        echo "=== Encrypting: $FILE ==="
        ansible-vault encrypt "$FILE" 2>&1
        ;;
    decrypt)
        FILE="${2:?File path required}"
        echo "=== Decrypting: $FILE (view only) ==="
        ansible-vault view "$FILE" 2>/dev/null | head -20
        ;;
    rekey)
        FILE="${2:?File path required}"
        echo "=== Rekeying: $FILE ==="
        echo "Run: ansible-vault rekey $FILE"
        ;;
esac
```

### Role Management

```bash
#!/bin/bash
echo "=== Installed Roles ==="
ansible-galaxy list 2>/dev/null

echo ""
echo "=== Role Dependencies ==="
for role in roles/*/; do
    if [ -f "${role}meta/main.yml" ]; then
        echo "--- $(basename $role) ---"
        grep -A 5 'dependencies:' "${role}meta/main.yml" 2>/dev/null
    fi
done | head -30

echo ""
echo "=== Requirements File ==="
cat requirements.yml 2>/dev/null || cat roles/requirements.yml 2>/dev/null | head -20
```

## Safety Rules

- **NEVER run playbooks without `--check` first** unless explicitly confirmed
- **Always use `--limit`** to target specific hosts during testing
- **Vault passwords** must never be stored in plaintext -- use vault password files or prompt
- **Use `--diff`** with `--check` to see what would change before applying
- **Tag dangerous tasks** with `never` tag to prevent accidental execution

## Common Pitfalls

- **SSH key issues**: Most connection failures are SSH key or user permission problems -- test with `ansible -m ping` first
- **Python interpreter**: Remote hosts need Python -- set `ansible_python_interpreter` if not at default path
- **Idempotency**: Tasks using `command`/`shell` modules are not idempotent -- use `creates`/`removes` parameters
- **Variable precedence**: Ansible has 22 levels of variable precedence -- group_vars < host_vars < play vars < extra vars
- **Vault ID mismatch**: Using wrong vault password silently fails decryption -- check vault-id labels
- **Become issues**: `become: yes` requires sudo access on target -- check sudoers configuration
- **Fact caching**: Stale cached facts can cause unexpected behavior -- use `gather_facts: yes` or clear cache
- **Handler ordering**: Handlers run at end of play, not immediately -- use `meta: flush_handlers` if needed earlier
