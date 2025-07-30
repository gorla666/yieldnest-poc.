#!/usr/bin/env bash
set -euo pipefail

#########################
# 0.  prerequisites
#########################
# – anvil running on the default endpoint
# – PRIVATE_KEY is one of the unlocked keys anvil prints
export ETH_RPC_URL=http://127.0.0.1:8545
export PRIVATE_KEY=ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export DEPLOYER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266   # just for nicer logs

echo "Using deployer $DEPLOYER"

#########################
# 1.  deploy mock asset & aToken
#########################
export ASSET=$(
  forge create \
    --rpc-url      "$ETH_RPC_URL" \
    --private-key  "$PRIVATE_KEY" \
    --broadcast \
    src/mocks/MockAToken.sol:MockAToken \
  | awk '/Deployed to:/ {print $3}'
)
echo "ASSET  deployed at $ASSET"

export ATOKEN=$(
  forge create \
    --rpc-url      "$ETH_RPC_URL" \
    --private-key  "$PRIVATE_KEY" \
    --broadcast \
    src/mocks/MockAToken.sol:MockAToken \
  | awk '/Deployed to:/ {print $3}'
)
echo "ATOKEN deployed at $ATOKEN"

#########################
# 2.  deploy strategy wired to those addresses
#########################
export STRAT=$(
  forge create \
    --rpc-url      "$ETH_RPC_URL" \
    --private-key  "$PRIVATE_KEY" \
    --broadcast \
    src/strategies/YieldNestStrategy.sol:YieldNestStrategy \
    --constructor-args "$ASSET" "$ATOKEN" \
  | awk '/Deployed to:/ {print $3}'
)
echo "STRAT  deployed at $STRAT"

#########################
# 3.  mint, approve, deposit 1 ether (1e18)
#########################
ONE_ETHER=1000000000000000000   # 1 * 10^18

# 3‑a  mint to deployer
cast send "$ASSET" \
  "mint(address,uint256)" "$DEPLOYER" "$ONE_ETHER" \
  --private-key "$PRIVATE_KEY" --rpc-url "$ETH_RPC_URL" \
  --quiet
echo "Minted 1 token to $DEPLOYER"

# 3‑b  give strategy unlimited allowance
cast send "$ASSET" \
  "approve(address,uint256)" "$STRAT" 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff \
  --private-key "$PRIVATE_KEY" --rpc-url "$ETH_RPC_URL" \
  --quiet
echo "Approved STRAT to spend tokens"

# 3‑c  deposit
cast send "$STRAT" \
  "deposit(uint256)" "$ONE_ETHER" \
  --private-key "$PRIVATE_KEY" --rpc-url "$ETH_RPC_URL" \
  --quiet
echo "Deposited 1 token into strategy"

#########################
# 4.  sanity‑check balances
#########################
echo ""
echo "=== post‑deposit state ==="
cast call "$ASSET"  "balanceOf(address)(uint256)" "$DEPLOYER" --rpc-url "$ETH_RPC_URL" | xargs -I{} echo "Deployer balance: {}"
cast call "$ATOKEN" "balanceOf(address)(uint256)" "$STRAT"    --rpc-url "$ETH_RPC_URL" | xargs -I{} echo "aToken balance   : {} (should be 1e18)"
cast call "$ASSET"  "allowance(address,address)(uint256)" "$DEPLOYER" "$STRAT" --rpc-url "$ETH_RPC_URL" | xargs -I{} echo "Allowance        : {}"
