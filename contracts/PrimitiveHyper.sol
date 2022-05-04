// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./interfaces/IERC20.sol";

contract PrimitiveHyper {
    error DecimalsError();
    error SameTokenError();

    uint256 public constant MIN_LIQUIDITY_FACTOR = 6;
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
    }

    Pool[] public pools;

    constructor(address WETH_) { WETH = WETH_; }

    function create(
        address risky,
        address stable,
        uint128 strike,
        uint32 sigma,
        uint32 gamma,
        uint32 maturity,
        uint256 riskyPerLp,
        uint256 delLiquidity
    ) external {
        if (risky == stable) revert SameTokenError();

    }
}
