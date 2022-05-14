pragma solidity ^0.8.0;

import "../EnigmaVirtualMachine.sol";

contract TestEnigmaVirtualMachine is EnigmaVirtualMachine {
    // --- Test --- //
    function testBalanceOf(address token) public view returns (uint256) {
        uint256 bal0 = IERC20(token).balanceOf(address(this));
        uint256 bal1 = _balanceOf(token);
        assert(bal0 == bal1);
        return bal1;
    }

    function testBlockTimestamp() public view returns (uint128) {
        return _blockTimestamp();
    }

    function testUpdateLastTimestamp() public {
        uint256 blockTimestamp = updateLastTimestamp(0);
        assert(blockTimestamp == block.timestamp);
    }

    function updateLastTimestamp(uint48 poolId) public override lock returns (uint128 blockTimestamp) {
        blockTimestamp = _blockTimestamp();
    }

    function testConstants() public view {
        assert(BUFFER == 300);
        assert(MIN_LIQUIDITY_FACTOR == 6);
        assert(PERCENTAGE == 1e4);
        assert(MAX_POOL_FEE == 1e3);
        assert(PRECISION == 1e18);
    }

    // --- Must Implement --- //

    // --- Compiler --- //
    function fund(address token, uint256 amount) external override {}

    function draw(
        address token,
        uint256 amount,
        address to
    ) external override {}

    // --- Liquidity --- //
    function getLiquidityMinted(
        uint48,
        uint256,
        uint256
    ) public view returns (uint256) {}

    // --- Swap --- //
    function getInvariant(uint48) public view override returns (int128) {}

    function getPhysicalReserves(uint48, uint256) public view override returns (uint256, uint256) {}

    function checkJitLiquidity(address, uint48) external view returns (uint256, uint256) {}
}
