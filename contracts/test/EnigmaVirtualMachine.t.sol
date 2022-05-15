pragma solidity ^0.8.0;

import "../EnigmaVirtualMachine.sol";

import "./DSTest.sol";

contract EnigmaVirtualMachineActions is DSTest, EnigmaVirtualMachine {
    // --- Must Implement --- //

    // --- Compiler --- //
    function fund(address, uint256) external override {}

    function draw(
        address,
        uint256,
        address
    ) external override {}

    // --- Liquidity --- //
    function getLiquidityMinted(
        uint48,
        uint256,
        uint256
    ) public view returns (uint256) {}

    function checkJitLiquidity(address, uint48) external view returns (uint256, uint256) {}

    // --- Swap --- //
    function updateLastTimestamp(uint48) public override lock returns (uint128) {
        return _blockTimestamp();
    }

    function getInvariant(uint48) public view override returns (int128) {}

    function getPhysicalReserves(uint48, uint256) public view override returns (uint256, uint256) {}
}

contract TestEnigmaVirtualMachine is EnigmaVirtualMachineActions {
    // --- Test --- //
    function testBalanceOf(address token) public returns (uint256) {
        uint256 bal0 = IERC20(token).balanceOf(address(this));
        uint256 bal1 = _balanceOf(token);
        assertEq(bal0, bal1, "unequal-balance");
    }

    function testBlockTimestamp() public view returns (uint128) {
        return _blockTimestamp();
    }

    function testUpdateLastTimestamp() public {
        uint256 blockTimestamp = updateLastTimestamp(0);
        assertEq(blockTimestamp, block.timestamp, "unequal-timestamp");
    }

    function testConstants() public {
        assertEq(BUFFER, 300, "BUFFER");
        assertEq(MIN_LIQUIDITY_FACTOR, 6, "MIN_LIQUIDITY_FACTOR");
        assertEq(PERCENTAGE, 1e4, "PERCENTAGE");
        assertEq(MAX_POOL_FEE, 1e3, "MAX_POOL_FEE");
        assertEq(PRECISION, 1e18, "PRECISION");
    }
}
