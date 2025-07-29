// SPDX‑License‑Identifier: MIT
pragma solidity ^0.8.25;

import {IERC20}  from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {MockAToken} from "../mocks/MockAToken.sol";

contract YieldNestStrategy is Ownable {
    IERC20     public immutable asset;   // deposit token (e.g., WETH)
    MockAToken public immutable aToken;

    /// @param _asset ERC‑20 the user deposits
    /// @param _aToken Mock aToken we “stake” into
    constructor(IERC20 _asset, MockAToken _aToken)
        Ownable(msg.sender)          // <<<––––– this line fixes the error
    {
        asset  = _asset;
        aToken = _aToken;

        // give the aToken contract unlimited allowance so the strategy
        // can stake deposits automatically
        asset.approve(address(aToken), type(uint256).max);
    }

    /* ---------- user actions ---------- */
    function deposit(uint256 amount) external {
        asset.transferFrom(msg.sender, address(this), amount);
        aToken.mint(address(this), amount);   // mock stake 1:1
    }

    function withdraw(uint256 amount) external onlyOwner {
        aToken.burn(address(this), amount);
        asset.transfer(msg.sender, amount);
    }

    function harvest() external onlyOwner {
        // simple mock “yield” – mint 1% of current balance
        uint256 bal = aToken.balanceOf(address(this));
        aToken.mint(address(this), bal / 100);
    }
}

