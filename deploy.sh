#!/usr/bin/env bash
set -euo pipefail

# ---- user settings -------------------------------------------------
PRIVATE_KEY=ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
RPC=http://127.0.0.1:8545
# --------------------------------------------------------------------

export ETH_RPC_URL=$RPC
export PRIVATE_KEY

echo "Deploying with $(cast wallet address --private-key $PRIVATE_KEY)"

# 1. Mock deposit token (“asset”)
ASSET=$(forge create --json          \
        --rpc-url  "$RPC"            \
        --private-key "$PRIVATE_KEY" \
        src/mocks/MockAToken.sol:MockAToken \
        | jq -r '.deployedTo')

# 2. Mock aToken
ATOKEN=$(forge create --json          \
         --rpc-url  "$RPC"            \
         --private-key "$PRIVATE_KEY" \
         src/mocks/MockAToken.sol:MockAToken \
         | jq -r '.deployedTo')

# 3. Strategy – needs *two* constructor args
STRAT=$(forge create --json             \
        --rpc-url  "$RPC"               \
        --private-key "$PRIVATE_KEY"    \
        --constructor-args "$ASSET" "$ATOKEN" \
        src/strategies/YieldNestStrategy.sol:YieldNestStrategy \
        | jq -r '.deployedTo')

cat > .env <<EOF
# auto‑generated each deploy
ETH_RPC_URL=$RPC
PRIVATE_KEY=$PRIVATE_KEY
ASSET=$ASSET
ATOKEN=$ATOKEN
STRAT=$STRAT
EOF

echo "ASSET  -> $ASSET"
echo "ATOKEN -> $ATOKEN"
echo "STRAT  -> $STRAT"
