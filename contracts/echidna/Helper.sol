pragma solidity ^0.8.0;

contract Helper {
    event AssertionFailed(string msg);
    event LogUint256(string msg, uint256 value);
    event LogBytes(string msg, bytes value);
    event LogAddress(string msg, address tkn);
    event LogBool(string msg, bool value);
    event LogInt24(string msg, int24 value);
    event LogInt128(string msg, int128 value);

    int24 constant MAX_TICK = 887272;
    int24 constant MIN_TICK = -414486;
    uint256 constant BUFFER = 300 seconds;
    uint256 constant MIN_FEE = 1; // 0.01%
    uint256 constant MAX_FEE = 1000; // 10%
    uint256 constant MIN_VOLATILITY = 100; // 1%
    uint256 constant MAX_VOLATILITY = 25_000; // 250%
    uint256 constant MIN_DURATION = 1; // days, but without units
    uint256 constant MAX_DURATION = 500; // days, but without units
    uint256 constant JUST_IN_TIME_MAX = 600 seconds;
    uint256 constant JUST_IN_TIME_LIQUIDITY_POLICY = 4 seconds;

    function clam_safe_create_bounds(
        uint16 priorityFee,
        uint16 fee,
        int24 maxTick,
        uint16 volatility,
        uint16 duration,
        uint16 jit,
        uint128 price
    ) internal returns (uint16, uint16, int24, uint16, uint16, uint16, uint128) {
        // scaling remaining pool creation values
        fee = uint16(between(fee, MIN_FEE, MAX_FEE));
        priorityFee = uint16(between(priorityFee, 1, fee));
        emit LogUint256("priority fee", uint256(priorityFee));
        volatility = uint16(between(volatility, MIN_VOLATILITY, MAX_VOLATILITY));
        duration = uint16(between(duration, MIN_DURATION, MAX_DURATION));
        maxTick = (-MIN_TICK) + (maxTick % (MAX_TICK - (-MIN_TICK))); // [-MIN_TICK,MAX_TICK]
        if (maxTick == 0) {
            maxTick += 1;
        }
        emit LogInt24("maxTick", maxTick);
        jit = uint16(between(jit, 1, JUST_IN_TIME_MAX));
        price = uint128(between(price, 1, type(uint128).max)); // price is between 1-uint256.max
        return (priorityFee, fee, maxTick, volatility, duration, jit, price);
    }
    // ******************** Helper ********************

    function between(uint256 random, uint256 low, uint256 high) internal pure returns (uint256) {
        return low + (random % (high - low));
    }

    function convertToInt128(uint128 a) internal pure returns (int128 b) {
        assembly {
            if gt(a, 0x7fffffffffffffffffffffffffffffff) { revert(0, 0) }

            b := a
        }
    }

    uint24[] pairIds;

    function save_pair_id(uint24 pairId) internal {
        pairIds.push(pairId);
    }

    function retrieve_created_pair(uint256 id) internal view returns (uint24 pairId) {
        require(pairIds.length > 0);
        id = between(id, 0, pairIds.length);
        return pairIds[id];
    }
}
