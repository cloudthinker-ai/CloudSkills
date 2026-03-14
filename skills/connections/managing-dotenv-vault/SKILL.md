---
name: managing-dotenv-vault
description: |
  Dotenv Vault encrypted environment variable management, environment syncing, team collaboration, and version tracking. Covers vault creation, environment pushing and pulling, key listing, version history, and multi-environment management. Use when managing encrypted .env files, syncing environment variables across teams, comparing environments, or auditing config changes with Dotenv Vault.
connection_type: dotenv-vault
preload: false
---

# Dotenv Vault Management Skill

Manage and analyze encrypted environment files, environments, and versions in Dotenv Vault.

## Tool Conventions

### Prerequisites
`npx dotenv-vault` CLI must be available. Projects must be linked with `npx dotenv-vault new` or `npx dotenv-vault login`.

### Core Commands
- `npx dotenv-vault push <environment>` -- push local .env to vault
- `npx dotenv-vault pull <environment>` -- pull from vault to local .env
- `npx dotenv-vault open <environment>` -- open vault UI
- `npx dotenv-vault keys <environment>` -- show decryption key

## Output Rules
- **TOKEN EFFICIENCY**: Extract only needed fields
- Target <=50 lines per script output
- **NEVER** output secret values or decryption keys -- only output key names
- Never dump full .env file contents

## Discovery Phase

### List Environment Keys

```bash
#!/bin/bash
ENV_FILE="${1:-.env}"

echo "=== Environment Variable Keys (${ENV_FILE}) ==="
if [ -f "$ENV_FILE" ]; then
    grep -v '^#' "$ENV_FILE" | grep -v '^\s*$' | cut -d'=' -f1 | head -25
    echo ""
    echo "Total keys: $(grep -v '^#' "$ENV_FILE" | grep -v '^\s*$' | wc -l)"
else
    echo "File not found: $ENV_FILE"
fi
```

### Check Vault Status

```bash
#!/bin/bash
echo "=== Vault Files ==="
ls -la .env.vault .env.me .env.keys 2>/dev/null || echo "No vault files found"

echo ""
echo "=== Environment Files ==="
ls -la .env .env.* 2>/dev/null | grep -v '.vault' | grep -v '.me' | grep -v '.keys'

echo ""
echo "=== Vault Project ==="
if [ -f ".env.vault" ]; then
    echo "Vault file exists - project is connected"
    wc -c < .env.vault | xargs -I{} echo "Vault size: {} bytes"
else
    echo "No vault file - run 'npx dotenv-vault new' to initialize"
fi
```

## Analysis Phase

### Compare Environments

```bash
#!/bin/bash
echo "=== Key Count by Environment ==="
for env_file in .env .env.development .env.staging .env.production; do
    if [ -f "$env_file" ]; then
        count=$(grep -v '^#' "$env_file" | grep -v '^\s*$' | wc -l)
        echo "${env_file}\t${count} keys"
    fi
done | column -t

echo ""
echo "=== Keys in .env.development Missing from .env.production ==="
if [ -f ".env.development" ] && [ -f ".env.production" ]; then
    DEV_KEYS=$(grep -v '^#' .env.development | grep -v '^\s*$' | cut -d'=' -f1 | sort)
    PROD_KEYS=$(grep -v '^#' .env.production | grep -v '^\s*$' | cut -d'=' -f1 | sort)
    comm -23 <(echo "$DEV_KEYS") <(echo "$PROD_KEYS") | head -15
else
    echo "Both .env.development and .env.production required"
fi
```

### Audit Configuration

```bash
#!/bin/bash
echo "=== Git-tracked .env Files (potential leak) ==="
git ls-files | grep -E '\.env($|\.)' | grep -v '.vault' | grep -v '.example' | grep -v '.sample' | head -10

echo ""
echo "=== .gitignore Coverage ==="
if [ -f ".gitignore" ]; then
    grep -E '\.env' .gitignore || echo "WARNING: No .env patterns in .gitignore"
else
    echo "WARNING: No .gitignore found"
fi

echo ""
echo "=== Vault Encryption Status ==="
if [ -f ".env.vault" ]; then
    grep -c 'DOTENV_VAULT_' .env.vault | xargs -I{} echo "{} encrypted environment blocks"
fi
```

## Output Format
- Use tab-separated columns with `column -t`
- Limit lists to 15-25 items
- NEVER display secret values or decryption keys
- Show summaries before details

## Common Pitfalls
- **Never expose values**: Only display variable names, never values or decryption keys
- **`.env.vault` is encrypted**: Safe to commit to Git; `.env` files with values must NOT be committed
- **`.env.me` is personal**: Contains your authentication -- never share or commit
- **Environment naming**: `development`, `staging`, `production`, and `ci` are standard environments
- **Pull before edit**: Always pull latest from vault before making changes to avoid conflicts
- **DOTENV_KEY**: Required at runtime to decrypt `.env.vault` -- set as environment variable in deployment
