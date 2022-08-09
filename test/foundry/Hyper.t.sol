// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "forge-std/Test.sol";
import "../../contracts/test/Helpers.sol";
import "../../contracts/test/TestERC20.sol";

import "../../contracts/Hyper.sol";

contract TestHyperMain is Test, Helpers, Hyper {
    // --- Tests --- //

    function testSwapInternal() public {
        timestamp = StandardPoolHelpers.MATURITY / 2;
        _swap(_poolId, 1, 1e16, 1); // deltaX = 0.01
    }

    // --- Setup --- //

    uint48 public _poolId;

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
        //setPrice(tick, price);
        setPrice(_poolId, price, 1e18);
    }

    address public base_;
    address public quote_;

    function setUp() public {
        address user = address(0x1);
        setTimestamp(1);
        uint48 poolId = uint48(10);
        _poolId = poolId;
        uint24 tick = 8;
        uint256 price = 10 * 1e18;
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
