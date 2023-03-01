pragma solidity ^0.8.4;

import "./EchidnaStateHandling.sol";
import {RMM01Portfolio as Portfolio} from "contracts/RMM01Portfolio.sol";

contract ChangeParameters is EchidnaStateHandling {
    // ******************** Change Pool Parameters ********************
    function change_parameters(uint256 id, uint16 priorityFee, uint16 fee, uint16 jit) public {
        (PortfolioPool memory preChangeState, uint64 poolId, , ) = retrieve_random_pool_and_tokens(id);
        emit LogUint256("created pools", poolIds.length);
        emit LogUint256("pool ID", uint256(poolId));
        require(preChangeState.isMutable());
        require(preChangeState.controller == address(this));
        {
            // scaling remaining pool creation values
            fee = uint16(between(fee, MIN_FEE, MAX_FEE));
            priorityFee = uint16(between(priorityFee, 1, fee));
            jit = uint16(between(jit, 1, JUST_IN_TIME_MAX));
        }

        _Portfolio.changeParameters(poolId, priorityFee, fee, jit);
        {
            (PortfolioPool memory postChangeState, , , ) = retrieve_random_pool_and_tokens(id);
            PortfolioCurve memory preChangeCurve = preChangeState.params;
            PortfolioCurve memory postChangeCurve = postChangeState.params;
            assert(postChangeState.lastTimestamp == preChangeState.lastTimestamp);
            assert(postChangeState.controller == address(this));
            assert(postChangeCurve.createdAt == preChangeCurve.createdAt);
            assert(postChangeCurve.priorityFee == priorityFee);
            assert(postChangeCurve.fee == fee);
            assert(postChangeCurve.jit == jit);
        }
    }

    // Invariant: Attempting to change parameters of a nonmutable pool should fail
    function change_parameters_to_non_mutable_pool_should_fail(
        uint256 id,
        uint16 priorityFee,
        uint16 fee,
        uint16 jit
    ) public {
        (PortfolioPool memory preChangeState, uint64 poolId, , ) = retrieve_random_pool_and_tokens(id);
        emit LogUint256("created pools", poolIds.length);
        emit LogUint256("pool ID", uint256(poolId));
        require(!preChangeState.isMutable());
        require(preChangeState.controller == address(this));
        {
            // scaling remaining pool creation values
            fee = uint16(between(fee, MIN_FEE, MAX_FEE));
            priorityFee = uint16(between(priorityFee, 1, fee));
            jit = uint16(between(jit, 1, JUST_IN_TIME_MAX));
        }

        try _Portfolio.changeParameters(poolId, priorityFee, fee, jit) {
            emit AssertionFailed("BUG: Changing pool parameters of a nonmutable pool should not be possible");
        } catch {}
    }
    // Invariant: Attempting to change parameters by a non-controller should fail
}
