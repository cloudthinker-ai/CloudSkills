---
name: managing-thirdweb
description: |
  Use when working with Thirdweb — thirdweb Web3 development platform management
  including contract deployments, Engine instances, embedded wallets, auth
  sessions, RPC usage, and storage (IPFS). Covers contract interaction health,
  wallet provisioning, transaction relayer status, and gasless transaction
  monitoring.
connection_type: thirdweb
preload: false
---

# thirdweb Management Skill

Monitor and manage thirdweb Web3 development infrastructure.

## MANDATORY: Discovery-First Pattern

**Always discover Engine instances and deployed contracts before querying transactions.**

### Phase 1: Discovery

```bash
#!/bin/bash
TW_ENGINE="${THIRDWEB_ENGINE_URL}"
AUTH="Authorization: Bearer ${THIRDWEB_SECRET_KEY}"

echo "=== RPC Endpoint Health ==="
for chain in 1 137 42161 10 8453; do
  result=$(curl -s -X POST "https://$chain.rpc.thirdweb.com/${THIRDWEB_CLIENT_ID}" \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}')
  status=$(echo "$result" | jq -r 'if .result then "OK" else "ERROR" end')
  echo "Chain $chain: $status"
done

echo ""
echo "=== Engine Status ==="
if [ -n "$TW_ENGINE" ]; then
  curl -s -H "$AUTH" "$TW_ENGINE/system/health" | \
    jq -r '"Engine: \(.status // "unknown")"'
  echo ""
  echo "=== Engine Wallets ==="
  curl -s -H "$AUTH" "$TW_ENGINE/backend-wallet/get-all" | \
    jq -r '.result[] | "\(.address) | Type: \(.type) | Chain: \(.chainId // "multi")"' | head -10
else
  echo "Engine URL not configured"
fi

echo ""
echo "=== IPFS Storage Test ==="
curl -s -o /dev/null -w "IPFS Gateway: %{http_code} (%{time_total}s)\n" \
  "https://ipfs.thirdwebcdn.com/ipfs/QmV9tSDx9UiPeWExXEeH6aoDvmihvx6jD5eLb4jbTaKGps"
```

**Phase 1 outputs:** RPC health, Engine status, wallets, IPFS gateway

### Phase 2: Analysis

```bash
#!/bin/bash
echo "=== Engine Transaction Queue ==="
if [ -n "$TW_ENGINE" ]; then
  curl -s -H "$AUTH" "$TW_ENGINE/transaction/get-all?status=queued" | \
    jq -r '"Queued: \(.result | length)"'
  curl -s -H "$AUTH" "$TW_ENGINE/transaction/get-all?status=sent" | \
    jq -r '"Sent (pending): \(.result | length)"'
  curl -s -H "$AUTH" "$TW_ENGINE/transaction/get-all?status=errored&limit=5" | \
    jq -r '"Errored: \(.result | length)"'

  echo ""
  echo "=== Recent Transactions ==="
  curl -s -H "$AUTH" "$TW_ENGINE/transaction/get-all?limit=5" | \
    jq -r '.result[] | "\(.id[:8]) | Chain: \(.chainId) | Status: \(.status) | To: \(.toAddress[:12])..."'

  echo ""
  echo "=== Backend Wallet Balances ==="
  for wallet in $(curl -s -H "$AUTH" "$TW_ENGINE/backend-wallet/get-all" | jq -r '.result[:3][].address'); do
    balance=$(curl -s -H "$AUTH" "$TW_ENGINE/backend-wallet/${wallet}/get-balance?chain=1" | jq -r '.result.value // "N/A"')
    echo "$wallet: $balance ETH"
  done
fi

echo ""
echo "=== Contract Read Test ==="
curl -s -X POST "https://1.rpc.thirdweb.com/${THIRDWEB_CLIENT_ID}" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_getCode","params":["0xdAC17F958D2ee523a2206206994597C13D831ec7","latest"],"id":1}' | \
  jq -r '"Contract read: \(if .result and (.result | length) > 2 then "OK" else "Error" end)"'
```

## Output Format

```
THIRDWEB STATUS
===============
RPC Endpoints: {healthy}/{total} healthy
Engine: {status}
Backend Wallets: {count} ({total_balance} ETH)
Transaction Queue: {queued} queued, {pending} pending, {errored} errored
IPFS Gateway: {status}
Issues: {list_of_warnings}
```

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

- **Client ID vs Secret Key**: Client ID for public endpoints; secret key for Engine and admin APIs
- **Engine self-hosted**: Engine runs as a Docker container — monitor its health separately
- **Gas estimation**: Backend wallets need sufficient native tokens for gas
- **Chain IDs**: Use numeric chain IDs (1=Ethereum, 137=Polygon) not names
