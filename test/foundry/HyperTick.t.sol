// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@primitivefi/rmm-core/contracts/libraries/Units.sol";

import "../../contracts/HyperTick.sol";

import "../../contracts/test/DSTest.sol";
import "../../contracts/test/Helpers.sol";

contract TestHyperTick is DSTest, Helpers, HyperTick {
    function _liquidityPolicy() internal pure override returns (uint256) {
        return 0;
    }

    function helperCreateStandardTick(uint24 tick, uint256 price) public {
        setPrice(tick, price);
    }

    function testAssetOfTick() public {
        uint48 poolId = 10;
        uint24 tick = 8;
        uint256 price = 22;
        helperCreateStandardPool(poolId);
        helperCreateStandardTick(tick, price);

        (uint256 x1, ) = assetOfTick(tick, poolId);
        emit log_uint(x1);
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
