#!/usr/bin/env bash
set -eo pipefail               # stop on first error + propagate exit codes
RPC=http://127.0.0.1:8545
KEY=ac0974be…ff80              # ← dev key 0 in Anvil mnemonic

export ETH_RPC_URL=$RPC
export PRIVATE_KEY=$KEY

echo "Using deployer $(cast wallet address --private-key $KEY)"

# 1. ERC‑20 asset (mock WETH)
ASSET=$(forge create --json \
  --rpc-url $RPC --private-key $KEY --broadcast \
  src/mocks/MockAToken.sol:MockAToken | jq -r '.deployedTo')

# 2. aToken representing staked asset
ATOKEN=$(forge create --json \
  --rpc-url $RPC --private-key $KEY --broadcast \
  src/mocks/MockAToken.sol:MockAToken | jq -r '.deployedTo')

# 3. Strategy
STRAT=$(forge create --json \
  --rpc-url $RPC --private-key $KEY --broadcast \
  --constructor-args $ASSET $ATOKEN \
  src/strategies/YieldNestStrategy.sol:YieldNestStrategy | jq -r '.deployedTo')

cat <<EOF
ASSET  deployed at $ASSET
ATOKEN deployed at $ATOKEN
STRAT  deployed at $STRAT
EOF

# Mint 1 token, approve & deposit
cast send $ASSET "mint(address,uint256)" $(cast wallet address --private-key $KEY) 1ether \
        --private-key $KEY --rpc-url $RPC --json >/dev/null
cast send $ASSET "approve(address,uint256)" $STRAT 1ether \
        --private-key $KEY --rpc-url $RPC --json >/dev/null
cast send $STRAT "deposit(uint256)" 1ether \
        --private-key $KEY --rpc-url $RPC --json >/dev/null

echo -e "\n=== post‑deposit state ==="
echo "Deployer balance: $(cast call $ASSET 'balanceOf(address)(uint256)' \
                        $(cast wallet address --private-key $KEY) --rpc-url $RPC)"
echo "aToken in strategy: $(cast call $ATOKEN 'balanceOf(address)(uint256)' \
                        $STRAT --rpc-url $RPC)"
