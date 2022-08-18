pragma solidity 0.8.13;

import "forge-std/Test.sol";

import "../../contracts/prototype/EnigmaVirtualMachinePrototype.sol";

contract FakeEnigmaAbstractOverrides is EnigmaVirtualMachinePrototype {
    // --- HyperPrototype --- //

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

    // --- Enigma Write --- //

    function _process(bytes calldata data) internal override {}

    // --- Enigma Read --- //

    function checkJitLiquidity(address account, uint48 poolId)
        external
        view
        override
        returns (uint256 distance, uint256 timestamp)
    {
        _checkJitLiquidity(account, poolId);
    }

    function pairs(uint16 pairId)
        external
        view
        override
        returns (
            address assetToken,
            uint8 assetDecimals,
            address quoteToken,
            uint8 quoteDecimals
        )
    {
        Pair memory p = _pairs[pairId];
        (assetToken, assetDecimals, quoteToken, quoteDecimals) = (
            p.tokenBase,
            p.decimalsBase,
            p.tokenQuote,
            p.decimalsQuote
        );
    }

    function curves(uint32 curveId)
        external
        view
        override
        returns (
            uint128 strike,
            uint24 sigma,
            uint32 maturity,
            uint32 gamma
        )
    {
        Curve memory c = _curves[curveId];
        (strike, sigma, maturity, gamma) = (c.strike, c.sigma, c.maturity, c.gamma);
    }

    function pools(uint48 poolId)
        external
        view
        override
        returns (
            uint256 lastPrice,
            int24 lastTick,
            uint256 blockTimestamp,
            uint256 liquidity
        )
    {
        HyperPool memory p = _pools[poolId];
        (lastPrice, lastTick, blockTimestamp, liquidity) = (p.lastPrice, p.lastTick, p.blockTimestamp, p.liquidity);
    }

    function getCurveId(bytes32 packedCurve) external view override returns (uint32) {
        return _getCurveIds[packedCurve];
    }

    function getCurveNonce() external view override returns (uint256) {
        return _curveNonce;
    }

    function getPairNonce() external view override returns (uint256) {
        return _curveNonce;
    }
}

contract StandardHelpers {
    uint128 public constant DEFAULT_STRIKE = 1e19;
    uint24 public constant DEFAULT_SIGMA = 1e4;
    uint32 public constant DEFAULT_MATURITY = 31556953; // adds 1
    uint16 public constant DEFAULT_FEE = 100;
    uint32 public constant DEFAULT_GAMMA = 9900;
    uint128 public constant DEFAULT_R1_QUOTE = 3085375387260000000;
    uint128 public constant DEFAULT_R2_ASSET = 308537538726000000;
    uint128 public constant DEFAULT_LIQUIDITY = 1e18;
    uint128 public constant DEFAULT_PRICE = 10e18;
    int24 public constant DEFAULT_TICK = int24(23027); // 10e18, rounded up! pay attention
}

contract BaseTest is Test, StandardHelpers, FakeEnigmaAbstractOverrides {}
