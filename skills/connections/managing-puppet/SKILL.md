---
name: managing-puppet
description: |
  Puppet configuration management. Covers catalog compilation, node management, module installation, report analysis, fact inspection, environment management, and resource auditing. Use when managing Puppet infrastructure, debugging catalog failures, inspecting node states, or auditing configuration compliance.
connection_type: puppet
preload: false
---

# Puppet Management Skill

Manage and inspect Puppet catalogs, nodes, modules, and configuration reports.

## MANDATORY: Discovery-First Pattern

**Always check node status and environment before compiling catalogs or applying changes.**

### Phase 1: Discovery

```bash
#!/bin/bash

echo "=== Puppet Version ==="
puppet --version 2>/dev/null

echo ""
echo "=== Puppet Server Status ==="
curl -s --cert /etc/puppetlabs/puppet/ssl/certs/$(hostname -f).pem \
     --key /etc/puppetlabs/puppet/ssl/private_keys/$(hostname -f).pem \
     --cacert /etc/puppetlabs/puppet/ssl/certs/ca.pem \
     "https://$(puppet config print server):8140/status/v1/services" 2>/dev/null | jq '.["status-service"].state' || \
puppetserver status 2>/dev/null

echo ""
echo "=== Environments ==="
ls /etc/puppetlabs/code/environments/ 2>/dev/null

echo ""
echo "=== Node Count ==="
puppet node status --terminus rest 2>/dev/null | wc -l || \
curl -s "http://localhost:8080/pdb/query/v4/nodes" 2>/dev/null | jq 'length'
```

## Core Helper Functions

```bash
#!/bin/bash

# PuppetDB query helper
puppetdb_query() {
    local endpoint="$1"
    local query="${2:-}"
    if [ -n "$query" ]; then
        curl -s -G "http://localhost:8080/pdb/query/v4/${endpoint}" \
            --data-urlencode "query=${query}" 2>/dev/null
    else
        curl -s "http://localhost:8080/pdb/query/v4/${endpoint}" 2>/dev/null
    fi
}

# Puppet command wrapper
pup_cmd() {
    puppet "$@" 2>/dev/null
}
```

## Output Rules
- **TOKEN EFFICIENCY**: Target <=50 lines per output
- Use PuppetDB API with query parameters for filtering
- Use `--render-as json` for structured Puppet CLI output
- Never dump full catalogs -- extract resource summaries

## Common Operations

### Node Status and Facts

```bash
#!/bin/bash
NODE="${1:-}"

if [ -n "$NODE" ]; then
    echo "=== Node Details: $NODE ==="
    puppetdb_query "nodes/$NODE" | jq '{
        certname: .certname,
        deactivated: .deactivated,
        expired: .expired,
        catalog_timestamp: .catalog_timestamp,
        facts_timestamp: .facts_timestamp,
        report_timestamp: .report_timestamp,
        latest_report_status: .latest_report_status
    }'

    echo ""
    echo "=== Key Facts ==="
    puppetdb_query "facts" "['and', ['=', 'certname', '$NODE'], ['or', ['=', 'name', 'os'], ['=', 'name', 'ipaddress'], ['=', 'name', 'memorysize'], ['=', 'name', 'processorcount']]]" | jq -r '.[] | "\(.name): \(.value)"'
else
    echo "=== All Nodes ==="
    puppetdb_query "nodes" | jq -r '.[] | "\(.certname)\t\(.latest_report_status)\t\(.report_timestamp)"' | column -t | head -30
fi
```

### Catalog Compilation and Inspection

```bash
#!/bin/bash
NODE="${1:?Node certname required}"
ENVIRONMENT="${2:-production}"

echo "=== Compiling Catalog for $NODE ==="
puppet catalog compile "$NODE" --environment "$ENVIRONMENT" --render-as json 2>/dev/null | jq '{
    name: .name,
    environment: .environment,
    resource_count: (.resources | length),
    resource_types: ([.resources[].type] | group_by(.) | map({type: .[0], count: length}) | sort_by(-.count)[:15]),
    classes: .classes
}' | head -40

echo ""
echo "=== Resource Summary ==="
puppet catalog compile "$NODE" --environment "$ENVIRONMENT" --render-as json 2>/dev/null | jq -r '
    [.resources[].type] | group_by(.) | map("\(.[0]): \(length)") | .[]
' | sort -t: -k2 -rn | head -15
```

### Module Management

```bash
#!/bin/bash
echo "=== Installed Modules ==="
puppet module list --tree 2>/dev/null | head -30

echo ""
echo "=== Module Details ==="
MODULE="${1:-}"
if [ -n "$MODULE" ]; then
    puppet module list --tree 2>/dev/null | grep -i "$MODULE"
    echo ""
    echo "=== Module Classes ==="
    find /etc/puppetlabs/code/environments/production/modules/"$MODULE"/manifests -name "*.pp" 2>/dev/null | \
        sed 's|.*/manifests/||;s|\.pp$||;s|/|::|g' | head -20
fi
```

### Report Analysis

```bash
#!/bin/bash
echo "=== Recent Reports ==="
puppetdb_query "reports" "['=', 'latest_report?', true]" | jq -r '
    .[:20][] | "\(.certname)\t\(.status)\t\(.start_time[0:16])\t\(.noop): noop"
' | column -t

echo ""
echo "=== Failed Reports ==="
puppetdb_query "reports" "['and', ['=', 'latest_report?', true], ['=', 'status', 'failed']]" | jq -r '
    .[] | "\(.certname)\t\(.start_time[0:16])\t\(.metrics.resources.values | map(select(.[0] == "failed")) | .[0][2] // 0) failures"
' | column -t | head -15
```

### Resource Auditing

```bash
#!/bin/bash
RESOURCE_TYPE="${1:-File}"
NODE="${2:-}"

echo "=== Resources of Type: $RESOURCE_TYPE ==="
if [ -n "$NODE" ]; then
    puppetdb_query "resources" "['and', ['=', 'certname', '$NODE'], ['=', 'type', '$RESOURCE_TYPE']]" | jq -r '
        .[:20][] | "\(.title)\t\(.parameters.ensure // "present")"
    ' | column -t
else
    puppetdb_query "resources" "['=', 'type', '$RESOURCE_TYPE']" | jq -r '
        .[:20][] | "\(.certname)\t\(.title)\t\(.parameters.ensure // "present")"
    ' | column -t
fi
```

## Safety Rules

- **NEVER apply catalogs in production without `--noop` first** -- always dry-run
- **Use `--environment` to test in non-production environments** before promoting
- **Certificate management is critical** -- revoking a cert locks out the node
- **Hiera data changes affect all nodes** matching the hierarchy -- review scope carefully
- **Module upgrades can break catalogs** -- test compilation before deploying

## Common Pitfalls

- **Certificate issues**: Most connection failures are SSL cert problems -- check `puppet ssl verify`
- **Catalog compilation errors**: Missing facts or Hiera data cause compilation failures -- check with `puppet lookup`
- **Environment caching**: Puppet Server caches environments -- use `puppet admin environment cache clear`
- **Dependency cycles**: Circular resource dependencies cause catalog compilation to fail
- **Fact convergence**: Some facts change after first run (e.g., custom facts from packages) -- may need two runs
- **Hiera precedence**: Wrong hierarchy level can override intended values -- use `puppet lookup --explain`
- **PuppetDB sync lag**: Reports and facts may take seconds to appear in PuppetDB after agent run
- **r10k deploy**: Code deployment via r10k can leave environments in inconsistent state during deploy
