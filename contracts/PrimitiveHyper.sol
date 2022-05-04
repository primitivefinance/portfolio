// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract PrimitiveHyper {
    error DecimalsError();
    error SameTokenError();

    struct Pool {
        address risky;
        address stable;
        uint128 strike;
        uint32 sigma;
        uint8 riskyDecimals;
        uint8 stableDecimals;
    }

    Pool[] public pools;

    function create(
        address risky,
        address stable
    ) external {
        if (risky == stable) revert SameTokenError();
    }
}
