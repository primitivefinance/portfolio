// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/InvariantTargetContract.sol";

contract InvariantDeposit is InvariantTargetContract {
    constructor(address hyper_, address asset_, address quote_) InvariantTargetContract(hyper_, asset_, quote_) {}

    function deposit(uint256 amount, uint256 index) external {
        amount = bound(amount, 1, 1e36);

        address target = ctx.getRandomUser(index);

        vm.deal(target, amount);

        address weth = __hyper__.WETH();

        uint256 preBal = getBalance(address(__hyper__), target, weth);
        uint256 preRes = getReserve(address(__hyper__), weth);
        vm.prank(target);
        __hyper__.deposit{value: amount}();
        uint256 postRes = getReserve(address(__hyper__), weth);
        uint256 postBal = getBalance(address(__hyper__), target, weth);

        assertEq(postRes, preRes + amount, "weth-reserve");
        assertEq(postBal, preBal + amount, "weth-balance");
        assertEq(address(__hyper__).balance, 0, "eth-balance");
        assertEq(getPhysicalBalance(address(__hyper__), weth), postRes, "weth-physical");
    }
}
