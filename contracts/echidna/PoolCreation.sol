pragma solidity ^0.8.0;
import "./EchidnaStateHandling.sol";

contract PoolCreation is EchidnaStateHandling {
    // ******************** Create Pool ********************
    // Create a non controlled pool (controller address is 0) with default pair
    // Note: This function can be extended to choose from any created pair and create a pool on top of it
    function create_non_controlled_pool(
        uint256 id,
        uint16 fee,
        int24 maxTick,
        uint16 volatility,
        uint16 duration,
        uint128 price
    ) public {
        uint24 pairId = retrieve_created_pair(uint256(id));
        {
            (, fee, maxTick, volatility, duration, , price) = clam_safe_create_bounds(
                0,
                fee,
                maxTick,
                volatility,
                duration,
                0,
                price
            );
        }
        bytes memory createPoolData = ProcessingLib.encodeCreatePool(
            pairId,
            address(0), // no controller
            0, // no priority fee
            fee,
            volatility,
            duration,
            0, // no jit
            maxTick,
            price
        );
        {
            (HyperPool memory pool, ) = execute_create_pool(pairId, createPoolData, false);
            assert(!pool.isMutable());
            HyperCurve memory curve = pool.params;
            assert(pool.lastTimestamp == block.timestamp);
            assert(pool.lastPrice == price);
            assert(curve.createdAt == block.timestamp);
            assert(pool.controller == address(0));
            assert(curve.priorityFee == 0);
            assert(curve.fee == fee);
            assert(curve.volatility == volatility);
            assert(curve.duration == duration);
            assert(curve.jit == JUST_IN_TIME_LIQUIDITY_POLICY);
            assert(curve.maxTick == maxTick);
            assert(curve.maturity() >= block.timestamp);
        }
    }

    function create_controlled_pool(
        uint256 id,
        uint16 priorityFee,
        uint16 fee,
        int24 maxTick,
        uint16 volatility,
        uint16 duration,
        uint16 jit,
        uint128 price
    ) public {
        uint24 pairId = retrieve_created_pair(id);
        {
            (priorityFee, fee, maxTick, volatility, duration, jit, price) = clam_safe_create_bounds(
                priorityFee,
                fee,
                maxTick,
                volatility,
                duration,
                jit,
                price
            );
        }
        bytes memory createPoolData = ProcessingLib.encodeCreatePool(
            pairId,
            address(this), //controller
            priorityFee, // no priority fee
            fee,
            volatility,
            duration,
            jit, // no jit
            maxTick,
            price
        );
        {
            (HyperPool memory pool, ) = execute_create_pool(pairId, createPoolData, true);
            assert(pool.isMutable());
            HyperCurve memory curve = pool.params;
            assert(pool.lastTimestamp == block.timestamp);
            assert(curve.createdAt == block.timestamp);
            assert(pool.controller == address(this));
            assert(curve.priorityFee == priorityFee);
            assert(curve.fee == fee);
            assert(curve.volatility == volatility);
            assert(curve.duration == duration);
            assert(curve.jit == jit);
            assert(curve.maxTick == maxTick);
            assert(curve.maturity() > block.timestamp);
        }
    }

    function create_controlled_pool_with_zero_priority_fee_should_fail(
        uint256 id,
        uint16 fee,
        int24 maxTick,
        uint16 volatility,
        uint16 duration,
        uint16 jit,
        uint128 price
    ) public {
        uint24 pairId = retrieve_created_pair(id);
        uint16 priorityFee = 0;
        {
            (, fee, maxTick, volatility, duration, jit, price) = clam_safe_create_bounds(
                priorityFee,
                fee,
                maxTick,
                volatility,
                duration,
                jit,
                price
            );
        }
        bytes memory createPoolData = ProcessingLib.encodeCreatePool(
            pairId,
            address(this), //controller
            priorityFee, // no priority fee
            fee,
            volatility,
            duration,
            jit, // no jit
            maxTick,
            price
        );
        (bool success, ) = address(_hyper).call(createPoolData);
        assert(!success);
    }

    function create_pool_with_negative_max_tick_as_bounds(
        uint256 id,
        uint16 priorityFee,
        uint16 fee,
        int24 maxTick,
        uint16 volatility,
        uint16 duration,
        uint16 jit,
        uint128 price
    ) public {
        uint24 pairId = retrieve_created_pair(id);
        {
            (priorityFee, fee, maxTick, volatility, duration, jit, price) = clam_safe_create_bounds(
                priorityFee,
                fee,
                maxTick,
                volatility,
                duration,
                jit,
                price
            );
        }
        bytes memory createPoolData = ProcessingLib.encodeCreatePool(
            pairId,
            address(this), //controller
            priorityFee, // no priority fee
            fee,
            volatility,
            duration,
            jit, // no jit
            maxTick,
            price
        );
        {
            (HyperPool memory pool, ) = execute_create_pool(pairId, createPoolData, true);
            assert(pool.isMutable());
            HyperCurve memory curve = pool.params;
            assert(pool.lastTimestamp == block.timestamp);
            assert(curve.createdAt == block.timestamp);
            assert(pool.controller == address(this));
            assert(curve.priorityFee == priorityFee);
            assert(curve.fee == fee);
            assert(curve.volatility == volatility);
            assert(curve.duration == duration);
            assert(curve.jit == jit);
            assert(curve.maxTick == maxTick);
        }
    }

    function execute_create_pool(
        uint24 pairId,
        bytes memory createPoolData,
        bool hasController
    ) private returns (HyperPool memory pool, uint64 poolId) {
        uint256 preCreationPoolNonce = _hyper.getPoolNonce();
        (bool success, ) = address(_hyper).call(createPoolData);
        assert(success);

        // pool nonce should increase by 1 each time a pool is created
        uint256 poolNonce = _hyper.getPoolNonce();
        assert(poolNonce == preCreationPoolNonce + 1);

        // pool should be created and exist
        poolId = ProcessingLib.encodePoolId(pairId, hasController, uint32(poolNonce));
        pool = getPool(address(_hyper), poolId);
        if (!pool.exists()) {
            emit AssertionFailed("BUG: Pool should return true on exists after being created.");
        }

        // save pools in Echidna
        save_pool_id(poolId);
    }

    /// @dev Create Special Pool is used to test swaps where quote token has 15 decimals.
    function create_special_pool(uint24 pairId, PoolParams memory pp) internal returns (uint64 poolId) {
        PoolParams memory _pp;
        (
            _pp.priorityFee,
            _pp.fee,
            _pp.maxTick,
            _pp.volatility,
            _pp.duration,
            _pp.jit,
            _pp.price
        ) = clam_safe_create_bounds(pp.priorityFee, pp.fee, pp.maxTick, pp.volatility, pp.duration, pp.jit, pp.price);
        bytes memory createPoolData = ProcessingLib.encodeCreatePool(
            pairId,
            address(this),
            _pp.priorityFee,
            _pp.fee,
            _pp.volatility,
            _pp.duration,
            _pp.jit,
            _pp.maxTick,
            _pp.price
        );
        (, poolId) = execute_create_pool(pairId, createPoolData, false);
        specialPoolId = poolId;
        specialPoolCreated = true;
    }

    // function check_decoding_pool_id(uint64 _poolId, uint24 _pairId, uint8 _isMutable, uint32 _poolNonce) private {

    //     (uint64 poolId, uint24 pairId, uint8 isMutable, uint32 poolNonce) = ProcessingLib.decodePoolId([_poolId,_pairId,_isMutable,_poolNonce]);

    // }
}
