// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @notice *Very* simple mint‑and‑burn ERC‑20 used only in tests.
/// ‑ No decimals handling, no safety checks – keep it short.
contract MockAToken is IERC20 {
    string  public constant name   = "Mock AToken";
    string  public constant symbol = "mATKN";
    uint8   public constant decimals = 18;

    uint256 public override totalSupply;
    mapping(address => uint256)                public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    /* -------- IERC20 -------- */

    function transfer(address to, uint256 amount) external override returns (bool) {
        _move(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;
        _move(from, to, amount);
        return true;
    }

    /* -------- Test helpers -------- */

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) external {
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }

    /* -------- Internals -------- */

    function _move(address from, address to, uint256 amount) internal {
        balanceOf[from] -= amount;
        balanceOf[to]   += amount;
        emit Transfer(from, to, amount);
    }
}

