// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console2} from "forge-std/Test.sol";
import {MockAToken}     from "../src/mocks/MockAToken.sol";
import {YieldNestStrategy} from "../src/strategies/YieldNestStrategy.sol";

contract YieldNestStrategyTest is Test {
    address alice = vm.addr(1);

    MockAToken          asset;
    YieldNestStrategy   strat;

    function setUp() public {
        asset = new MockAToken();
        strat = new YieldNestStrategy(asset, new MockAToken()); // separate aToken

        // Give Alice 100 “WETH”
        asset.mint(alice, 100 ether);
        vm.prank(alice);
        asset.approve(address(strat), type(uint256).max);
    }

    function test_deposit_and_withdraw() public {
        vm.startPrank(alice);
        strat.deposit(20 ether);
        vm.stopPrank();

        assertEq(asset.balanceOf(alice), 80 ether, "Alice should have sent 20");

        // Owner is the test contract; withdraw 15
        strat.withdraw(15 ether);
        assertEq(asset.balanceOf(address(this)), 15 ether, "owner got funds back");
    }

    function test_harvest_increases_balance() public {
        vm.prank(alice);
        strat.deposit(50 ether);

        uint256 beforeBal = strat.aToken().balanceOf(address(strat));
        strat.harvest();
        uint256 afterBal  = strat.aToken().balanceOf(address(strat));

        assertGt(afterBal, beforeBal, "harvest must mint yield");
    }
}
