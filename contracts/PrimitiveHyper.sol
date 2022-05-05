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
        uint32 lastTimestamp;
        uint128 reserveRisky;
        uint128 reserveStable;
        uint128 liquidity;
    }

    Pool[] public pools;

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

    // TODO: Check if it's better to create an engine and a pool separately or do it in one time like this
    function create(CreateParams memory params) external returns (
        uint256 poolId,
        uint256 delRisky,
        uint256 delStable
    ) {
        if (params.risky == params.stable) revert SameTokenError();

        if (params.stable == address(0)) params.stable = WETH;
        if (params.risky == address(0)) params.risky = WETH;

        uint8 riskyDecimals = IERC20(params.risky).decimals();
        uint8 stableDecimals = IERC20(params.stable).decimals();

        if (riskyDecimals > 18 || riskyDecimals < 6) revert DecimalsError();
        if (stableDecimals > 18 || stableDecimals < 6) revert DecimalsError();

        uint256 minLiquidity;
        uint256 scaleFactoryRisky;
        uint256 scaleFactoryStable;

        unchecked {
            scaleFactoryRisky = 10 ** (18 - riskyDecimals);
            scaleFactoryStable = 10 ** (18 - stableDecimals);
            uint256 lowestDecimals = riskyDecimals < stableDecimals ? riskyDecimals : stableDecimals;
            minLiquidity = 10 ** (lowestDecimals / MIN_LIQUIDITY_FACTOR);
        }

        if (params.sigma > 1e7 || params.sigma < 1) revert SigmaError();
        if (params.strike == 0) revert StrikeError();
        if (params.delLiquidity <= minLiquidity) revert MinLiquidityError();
        if (params.riskyPerLp > PRECISION / scaleFactoryRisky || params.riskyPerLp == 0) revert RiskyPerLpError();
        if (params.gamma > 10000 || params.gamma < 9000) revert GammaError(); // check gamma > Units.PERCENTAGE
        if (params.maturity < block.timestamp) revert PoolExpiredError();

        uint32 tau = uint32(params.maturity - block.timestamp);
        delStable = ReplicationMath.getStableGivenRisky(
            0,
            scaleFactoryRisky,
            scaleFactoryStable,
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
            lastTimestamp: uint32(block.timestamp),
            reserveRisky: uint128(delRisky),
            reserveStable: uint128(delStable),
            liquidity: uint128(params.delLiquidity)
        }));

        poolId = pools.length - 1;
        uint256 amount = params.delLiquidity - minLiquidity;
        liquidityOf[msg.sender][poolId] += amount;

        // TODO: move risky and stable tokens
    }

    error ZeroDeltaError();
    error ZeroLiquidityError();

    function allocate(uint256 poolId, uint256 delRisky, uint256 delStable) external returns (uint256 delLiquidity) {
        if (delRisky == 0 || delStable == 0) revert ZeroDeltaError();
        Pool memory pool = pools[poolId];

        uint256 liquidity0 = (delRisky * pool.liquidity) / uint256(pool.reserveRisky);
        uint256 liquidity1 = (delStable * pool.liquidity) / uint256(pool.reserveStable);
        delLiquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        if (delLiquidity == 0) revert ZeroLiquidityError();

        liquidityOf[msg.sender][poolId] += delLiquidity;

        // TODO: Move this to a function, use safecast
        pools[poolId].reserveRisky += uint128(delRisky);
        pools[poolId].reserveStable += uint128(delStable);
        pools[poolId].lastTimestamp = uint32(block.timestamp);
        pools[poolId].liquidity += uint128(delLiquidity);

        // TODO: move the tokens
    }

    function remove(uint256 poolId, uint256 delLiquidity) external returns (uint256 delRisky, uint256 delStable) {
        if (delLiquidity == 0) revert ZeroLiquidityError();
        liquidityOf[msg.sender][poolId] -= delLiquidity;

        Pool memory pool = pools[poolId];

        delRisky = (delLiquidity * uint256(pool.reserveRisky)) / pool.liquidity;
        delStable = (delLiquidity * uint256(pool.reserveStable)) / pool.liquidity;

        // TODO: Move this to a function, use safecast
        pools[poolId].reserveRisky -= uint128(delRisky);
        pools[poolId].reserveStable += uint128(delStable);
        pools[poolId].lastTimestamp = uint32(block.timestamp);
        pools[poolId].liquidity += uint128(delLiquidity);

        // TODO: Send the tokens back
    }
}
