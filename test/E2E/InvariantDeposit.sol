// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "./setup/InvariantTargetContract.sol";

contract InvariantDeposit is InvariantTargetContract {
    constructor(address hyper_, address asset_, address quote_) InvariantTargetContract(hyper_, asset_, quote_) {}

    function deposit(uint amount) external {
        amount = bound(amount, 1, 1e36);
        vm.deal(address(this), amount);

        address weth = __hyper__.WETH();

        uint preBal = getBalance(address(__hyper__), address(this), weth);
        uint preRes = getReserve(address(__hyper__), weth);
        __hyper__.deposit{value: amount}();
        uint postRes = getReserve(address(__hyper__), weth);
        uint postBal = getBalance(address(__hyper__), address(this), weth);

        assertEq(postRes, preRes + amount, "weth-reserve");
        assertEq(postBal, preBal + amount, "weth-balance");
        assertEq(address(__hyper__).balance, 0, "eth-balance");
        assertEq(getPhysicalBalance(address(__hyper__), weth), postRes, "weth-physical");
    }
}
