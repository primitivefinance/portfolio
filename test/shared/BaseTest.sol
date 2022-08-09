pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../contracts/EnigmaVirtualMachine.sol";

contract FakeEnigmaAbstractOverrides is EnigmaVirtualMachine {
    // --- Implemented --- //

    function _process(bytes calldata data) internal override {}

    function updateLastTimestamp(uint48) public override returns (uint128) {
        return _blockTimestamp();
    }

    function getLiquidityMinted(
        uint48,
        uint256,
        uint256
    ) public view override returns (uint256) {}

    function getInvariant(uint48) public view override returns (int128) {}

    function getPhysicalReserves(uint48 poolId, uint256 deltaLiquidity)
        public
        view
        override
        returns (uint256 deltaBase, uint256 deltaQuote)
    {}

    function fund(address, uint256) external override {}

    function draw(
        address,
        uint256,
        address
    ) external override {}
}

contract BaseTest is Test, FakeEnigmaAbstractOverrides {}
