// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IERC20.sol";
import "./libraries/ReplicationMath.sol";

contract PrimitiveHyper {
    error DecimalsError();
    error SameTokenError();
    error SigmaError();
    error StrikeError();
    error MinLiquidityError();
    error RiskyPerLpError();
    error GammaError();
    error PoolExpiredError();
    error CalibrationError();

    uint256 public constant MIN_LIQUIDITY_FACTOR = 6;
    uint256 public constant PRECISION = 10 ** 18;
    address public immutable WETH;

    struct Pool {
        address risky;
        address stable;
        uint128 strike;
        uint32 sigma;
        uint32 gamma;
        uint32 maturity;
        uint8 riskyDecimals;
        uint8 stableDecimals;
        uint256 scaleFactorRisky;
        uint256 scaleFactorStable;
    }

    Pool[] public pools;

    struct Reserve {
        uint128 reserveRisky;
        uint128 reserveStable;
        uint128 liquidity;
        uint32 lastTimestamp;
    }

    mapping(uint256 => Reserve) public reserves;

    mapping(address => mapping(uint256 => uint256)) liquidityOf;

    constructor(address WETH_) { WETH = WETH_; }

    struct CreateParams {
        address risky;
        address stable;
        uint128 strike;
        uint32 sigma;
        uint32 gamma;
        uint32 maturity;
        uint256 riskyPerLp;
        uint256 delLiquidity;
    }

    function checkTokens(address risky, address stable) private returns (
        uint8 riskyDecimals,
        uint8 stableDecimals,
        uint256 scaleFactorRisky,
        uint256 scaleFactorStable,
        uint256 minLiquidity
    ) {
        if (risky == stable) revert SameTokenError();
        if (stable == address(0)) stable = WETH;
        if (risky == address(0)) risky = WETH;

        uint8 riskyDecimals = IERC20(risky).decimals();
        uint8 stableDecimals = IERC20(stable).decimals();

        if (riskyDecimals > 18 || riskyDecimals < 6) revert DecimalsError();
        if (stableDecimals > 18 || stableDecimals < 6) revert DecimalsError();

        unchecked {
            scaleFactorRisky = 10 ** (18 - riskyDecimals);
            scaleFactorStable = 10 ** (18 - stableDecimals);
            uint256 lowestDecimals = riskyDecimals < stableDecimals ? riskyDecimals : stableDecimals;
            minLiquidity = 10 ** (lowestDecimals / MIN_LIQUIDITY_FACTOR);
        }
    }

    // TODO: Check if it's better to create an engine and a pool separately or do it in one time like this
    function create(CreateParams memory params) external returns (
        uint256 poolId,
        uint256 delRisky,
        uint256 delStable
    ) {
        (
            uint8 riskyDecimals,
            uint8 stableDecimals,
            uint256 scaleFactorRisky,
            uint256 scaleFactorStable,
            uint256 minLiquidity
        ) = checkTokens(params.risky, params.stable);

        /*
        if (params.risky == params.stable) revert SameTokenError();

        if (params.stable == address(0)) params.stable = WETH;
        if (params.risky == address(0)) params.risky = WETH;

        uint8 riskyDecimals = IERC20(params.risky).decimals();
        uint8 stableDecimals = IERC20(params.stable).decimals();

        if (riskyDecimals > 18 || riskyDecimals < 6) revert DecimalsError();
        if (stableDecimals > 18 || stableDecimals < 6) revert DecimalsError();

        uint256 minLiquidity;
        uint256 scaleFactorRisky;
        uint256 scaleFactorStable;

        unchecked {
            scaleFactorRisky = 10 ** (18 - riskyDecimals);
            scaleFactorStable = 10 ** (18 - stableDecimals);
            uint256 lowestDecimals = riskyDecimals < stableDecimals ? riskyDecimals : stableDecimals;
            minLiquidity = 10 ** (lowestDecimals / MIN_LIQUIDITY_FACTOR);
        }
        */

        if (params.sigma > 1e7 || params.sigma < 1) revert SigmaError();
        if (params.strike == 0) revert StrikeError();
        if (params.delLiquidity <= minLiquidity) revert MinLiquidityError();
        if (params.riskyPerLp > PRECISION / scaleFactorRisky || params.riskyPerLp == 0) revert RiskyPerLpError();
        if (params.gamma > 10000 || params.gamma < 9000) revert GammaError(); // check gamma > Units.PERCENTAGE
        if (params.maturity < block.timestamp) revert PoolExpiredError();

        uint32 tau = uint32(params.maturity - block.timestamp);
        delStable = ReplicationMath.getStableGivenRisky(
            0,
            scaleFactorRisky,
            scaleFactorStable,
            params.riskyPerLp,
            params.strike,
            params.sigma,
            tau
        );

        delRisky = (params.riskyPerLp * params.delLiquidity) / PRECISION;
        delStable = (delStable * params.delLiquidity) / PRECISION;
        if (delRisky == 0 || delStable == 0) revert CalibrationError();

        pools.push(Pool({
            risky: params.risky,
            stable: params.stable,
            strike: params.strike,
            sigma: params.sigma,
            gamma: params.gamma,
            maturity: params.maturity,
            riskyDecimals: riskyDecimals,
            stableDecimals: stableDecimals,
            scaleFactorRisky: scaleFactorRisky,
            scaleFactorStable: scaleFactorStable
        }));

        poolId = pools.length - 1;

        reserves[poolId] = Reserve({
            reserveRisky: uint128(delRisky),
            reserveStable: uint128(delStable),
            liquidity: uint128(params.delLiquidity),
            lastTimestamp: uint32(block.timestamp)
        });

        uint256 amount = params.delLiquidity - minLiquidity;
        liquidityOf[msg.sender][poolId] += amount;

        // TODO: move risky and stable tokens
    }

    error ZeroDeltaError();
    error ZeroLiquidityError();

    function allocate(uint256 poolId, uint256 delRisky, uint256 delStable) external returns (uint256 delLiquidity) {
        if (delRisky == 0 || delStable == 0) revert ZeroDeltaError();
        Reserve memory reserve = reserves[poolId];

        uint256 liquidity0 = (delRisky * reserve.liquidity) / uint256(reserve.reserveRisky);
        uint256 liquidity1 = (delStable * reserve.liquidity) / uint256(reserve.reserveStable);
        delLiquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        if (delLiquidity == 0) revert ZeroLiquidityError();

        liquidityOf[msg.sender][poolId] += delLiquidity;

        // TODO: Move this to a function, use safecast
        reserves[poolId].reserveRisky += uint128(delRisky);
        reserves[poolId].reserveStable += uint128(delStable);
        reserves[poolId].lastTimestamp = uint32(block.timestamp);
        reserves[poolId].liquidity += uint128(delLiquidity);

        // TODO: move the tokens
    }

    function remove(uint256 poolId, uint256 delLiquidity) external returns (uint256 delRisky, uint256 delStable) {
        if (delLiquidity == 0) revert ZeroLiquidityError();
        liquidityOf[msg.sender][poolId] -= delLiquidity;

        Reserve memory reserve = reserves[poolId];

        delRisky = (delLiquidity * uint256(reserve.reserveRisky)) / reserve.liquidity;
        delStable = (delLiquidity * uint256(reserve.reserveStable)) / reserve.liquidity;

        // TODO: Move this to a function, use safecast
        reserves[poolId].reserveRisky -= uint128(delRisky);
        reserves[poolId].reserveStable += uint128(delStable);
        reserves[poolId].lastTimestamp = uint32(block.timestamp);
        reserves[poolId].liquidity += uint128(delLiquidity);

        // TODO: Send the tokens back
    }

    uint256 BUFFER = 120 seconds;

    function swap(
        uint256 poolId,
        bool riskyForStable,
        uint256 deltaIn,
        uint256 deltaOut
    ) external {
        if (deltaIn == 0 || deltaOut == 0) revert ZeroDeltaError();

        // pools[poolId].lastTimestamp = block.timestamp >= pools[poolId].maturity ? pools[poolId].maturity : block.timestamp;

        // if (pools[poolId].lastTimestamp >


    }

    function invariantOf(uint256 poolId) public view returns (int128 invariant) {
        Pool memory pool = pools[poolId];

        (uint256 riskyPerLiquidity, uint256 stablePerLiquidity) = getAmounts(reserves[poolId], PRECISION); // 1e18 liquidity
        invariant = ReplicationMath.calcInvariant(
            pool.scaleFactorRisky,
            pool.scaleFactorStable,
            riskyPerLiquidity,
            stablePerLiquidity,
            pool.strike,
            pool.sigma,
            pool.maturity - reserves[poolId].lastTimestamp
        );
    }

    /// @notice                 Calculates risky and stable token amounts of `delLiquidity`
    /// @param reserve          Reserve in memory to use reserves and liquidity of
    /// @param delLiquidity     Amount of liquidity to fetch underlying tokens of
    /// @return delRisky        Amount of risky tokens controlled by `delLiquidity`
    /// @return delStable       Amount of stable tokens controlled by `delLiquidity`
    function getAmounts(Reserve memory reserve, uint256 delLiquidity)
        internal
        pure
        returns (uint256 delRisky, uint256 delStable)
    {
        uint256 liq = uint256(reserve.liquidity);
        delRisky = (delLiquidity * uint256(reserve.reserveRisky)) / liq;
        delStable = (delLiquidity * uint256(reserve.reserveStable)) / liq;
    }
}
