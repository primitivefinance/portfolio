// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@primitivefi/rmm-core/contracts/libraries/Units.sol";

import "../../contracts/HyperTick.sol";

import "forge-std/Test.sol";
import "../../contracts/test/Helpers.sol";

import "../../contracts/test/TestERC20.sol";

import "../../contracts/libraries/PriceMath.sol";

contract TestHyperTick is Test, Helpers, HyperTick {
    function _liquidityPolicy() internal pure override returns (uint256) {
        return 0;
    }

    uint256 public timestamp;

    function setTimestamp(uint256 timestamp_) public {
        timestamp = timestamp_;
    }

    function _blockTimestamp() internal view override(EnigmaVirtualMachine) returns (uint128) {
        return uint128(timestamp);
    }

    function helperCreateStandardTick(uint24 tick, uint256 price) public {
        setPrice(tick, price);
    }

    address public base_;
    address public quote_;

    function setUp() public {
        address user = address(0x1);
        setTimestamp(1);
        uint48 poolId = uint48(10);
        uint24 tick = 8;
        uint256 price = 22;
        base_ = address(new TestERC20("Test", "TST", 18));
        quote_ = address(new TestERC20("Test", "TST", 18));
        helperSetTokens(base_, quote_);

        TestERC20(base_).mint(user, 100 ether);
        TestERC20(quote_).mint(user, 100 ether);

        vm.prank(user);
        TestERC20(base_).approve(address(this), 100 ether);

        vm.prank(user);
        TestERC20(quote_).approve(address(this), 100 ether);

        vm.prank(user);
        helperCreateStandardPool(poolId);

        helperCreateStandardTick(tick, price);
    }

    function testDeltaXPerpetual() public {
        uint256 price = 1e18;
        uint256 strike = 2e18;
        uint256 sigma = 1e18;
        uint256 rate = 1e17;
        (int256 res, int256 exp, uint256 z) = PriceMath.deltaXPerpetual(price, strike, sigma, rate);
        console.logInt(res);
        console.logInt(exp);
        console.log(z);
    }

    function testAssetOfTick() public {
        uint48 poolId = 10;
        uint24 tick = 8;
        uint256 price = 22;

        (uint256 x1, uint256 x2) = assetOfTick(tick, poolId);
        emit log_uint(x1);
        emit log_uint(x2);
    }

    // --- Implemented --- //
    function getLiquidityMinted(
        uint48,
        uint256,
        uint256
    ) public view override returns (uint256) {}

    function _process(bytes calldata data) internal override {}

    function fund(address, uint256) external override {}

    function draw(
        address,
        uint256,
        address
    ) external override {}

    function updateLastTimestamp(uint48) public override lock returns (uint128) {
        return _blockTimestamp();
    }

    function getInvariant(uint48) public view override returns (int128) {}

    function getPhysicalReserves(uint48 poolId, uint256 deltaLiquidity)
        public
        view
        override
        returns (uint256 deltaBase, uint256 deltaQuote)
    {}
}
