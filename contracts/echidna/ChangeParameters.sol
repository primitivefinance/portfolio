pragma solidity ^0.8.0;
import "./EchidnaStateHandling.sol";

contract ChangeParameters is EchidnaStateHandling {
    // ******************** Change Pool Parameters ********************
    function change_parameters(
        uint256 id,
        uint16 priorityFee,
        uint16 fee,
        int24 maxTick,
        uint16 volatility,
        uint16 duration,
        uint16 jit,
        uint128 price
    ) public {
        (HyperPool memory preChangeState, uint64 poolId, , ) = retrieve_random_pool_and_tokens(id);
        emit LogUint256("created pools", poolIds.length);
        emit LogUint256("pool ID", uint256(poolId));
        require(preChangeState.isMutable());
        require(preChangeState.controller == address(this));
        {
            // scaling remaining pool creation values
            fee = uint16(between(fee, MIN_FEE, MAX_FEE));
            priorityFee = uint16(between(priorityFee, 1, fee));
            volatility = uint16(between(volatility, MIN_VOLATILITY, MAX_VOLATILITY));
            duration = uint16(between(duration, MIN_DURATION, MAX_DURATION));
            maxTick = (-MAX_TICK) + (maxTick % (MAX_TICK - (-MAX_TICK))); // [-MAX_TICK,MAX_TICK]
            jit = uint16(between(jit, 1, JUST_IN_TIME_MAX));
            price = uint128(between(price, 1, type(uint128).max)); // price is between 1-uint256.max
        }

        _hyper.changeParameters(poolId, priorityFee, fee, volatility, duration, jit, maxTick);
        {
            (HyperPool memory postChangeState, , , ) = retrieve_random_pool_and_tokens(id);
            HyperCurve memory preChangeCurve = preChangeState.params;
            HyperCurve memory postChangeCurve = postChangeState.params;
            assert(postChangeState.lastTimestamp == preChangeState.lastTimestamp);
            assert(postChangeState.controller == address(this));
            assert(postChangeCurve.createdAt == preChangeCurve.createdAt);
            assert(postChangeCurve.priorityFee == priorityFee);
            assert(postChangeCurve.fee == fee);
            assert(postChangeCurve.volatility == volatility);
            assert(postChangeCurve.duration == duration);
            assert(postChangeCurve.jit == jit);
            assert(postChangeCurve.maxTick == maxTick);
        }
    }

    // Invariant: Attempting to change parameters of a nonmutable pool should fail
    function change_parameters_to_non_mutable_pool_should_fail(
        uint256 id,
        uint16 priorityFee,
        uint16 fee,
        int24 maxTick,
        uint16 volatility,
        uint16 duration,
        uint16 jit,
        uint128 price
    ) public {
        (HyperPool memory preChangeState, uint64 poolId, , ) = retrieve_random_pool_and_tokens(id);
        emit LogUint256("created pools", poolIds.length);
        emit LogUint256("pool ID", uint256(poolId));
        require(!preChangeState.isMutable());
        require(preChangeState.controller == address(this));
        {
            // scaling remaining pool creation values
            fee = uint16(between(fee, MIN_FEE, MAX_FEE));
            priorityFee = uint16(between(priorityFee, 1, fee));
            volatility = uint16(between(volatility, MIN_VOLATILITY, MAX_VOLATILITY));
            duration = uint16(between(duration, MIN_DURATION, MAX_DURATION));
            maxTick = (-MAX_TICK) + (maxTick % (MAX_TICK - (-MAX_TICK))); // [-MAX_TICK,MAX_TICK]
            jit = uint16(between(jit, 1, JUST_IN_TIME_MAX));
            price = uint128(between(price, 1, type(uint128).max)); // price is between 1-uint256.max
        }

        try _hyper.changeParameters(poolId, priorityFee, fee, volatility, duration, jit, maxTick) {
            emit AssertionFailed("BUG: Changing pool parameters of a nonmutable pool should not be possible");
        } catch {}
    }
    // Invariant: Attempting to change parameters by a non-controller should fail
}
