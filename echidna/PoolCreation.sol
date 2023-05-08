pragma solidity ^0.8.4;

import "./EchidnaStateHandling.sol";

contract PoolCreation is EchidnaStateHandling {
    // ******************** Create Pool ********************
    // Create a non controlled pool (controller address is 0) with default pair
    // Note: This function can be extended to choose from any created pair and create a pool on top of it
    function create_non_controlled_pool(
        uint256 id,
        uint16 fee,
        uint128 strikePrice,
        uint16 volatility,
        uint16 duration,
        uint128 price
    ) public {
        uint24 pairId = retrieve_created_pair(uint256(id));
        {
            (, fee, strikePrice, volatility, duration,, price) =
            clam_safe_create_bounds(
                0, fee, strikePrice, volatility, duration, 0, price
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
            strikePrice,
            price
        );
        {
            (PortfolioPool memory pool, uint64 poolId) =
                execute_create_pool(pairId, createPoolData, false);
            assert(!pool.isMutable());
            PortfolioCurve memory curve = pool.params;
            assert(pool.lastTimestamp == block.timestamp);
            assert(_portfolio.getVirtualPrice(poolId) == price);
            assert(curve.createdAt == block.timestamp);
            assert(pool.controller == address(0));
            assert(curve.priorityFee == 0);
            assert(curve.fee == fee);
            assert(curve.volatility == volatility);
            assert(curve.duration == duration);
            assert(curve.strikePrice == strikePrice);
            // assert(curve.maturity() >= block.timestamp);
        }
    }

    function create_controlled_pool(
        uint256 id,
        uint16 priorityFee,
        uint16 fee,
        uint128 strikePrice,
        uint16 volatility,
        uint16 duration,
        uint16 jit,
        uint128 price
    ) public {
        uint24 pairId = retrieve_created_pair(id);
        {
            (, fee, strikePrice, volatility, duration,, price) =
            clam_safe_create_bounds(
                0, fee, strikePrice, volatility, duration, 0, price
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
            strikePrice,
            price
        );
        {
            (PortfolioPool memory pool,) =
                execute_create_pool(pairId, createPoolData, true);
            assert(pool.isMutable());
            PortfolioCurve memory curve = pool.params;
            assert(pool.lastTimestamp == block.timestamp);
            assert(curve.createdAt == block.timestamp);
            assert(pool.controller == address(this));
            assert(curve.priorityFee == priorityFee);
            assert(curve.fee == fee);
            assert(curve.volatility == volatility);
            assert(curve.duration == duration);
            assert(curve.jit == jit);
            assert(curve.strikePrice == strikePrice);
            // assert(curve.maturity() > block.timestamp);
        }
    }

    function create_controlled_pool_with_zero_priority_fee_should_fail(
        uint256 id,
        uint16 fee,
        uint128 strikePrice,
        uint16 volatility,
        uint16 duration,
        uint16 jit,
        uint128 price
    ) public {
        uint24 pairId = retrieve_created_pair(id);
        uint16 priorityFee = 0;
        {
            (, fee, strikePrice, volatility, duration,, price) =
            clam_safe_create_bounds(
                0, fee, strikePrice, volatility, duration, 0, price
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
            strikePrice,
            price
        );
        (bool success,) = address(_portfolio).call(createPoolData);
        assert(!success);
    }

    function execute_create_pool(
        uint24 pairId,
        bytes memory createPoolData,
        bool hasController
    ) private returns (PortfolioPool memory pool, uint64 poolId) {
        uint256 preCreationPoolNonce = _portfolio.getPoolNonce(pairId);
        (bool success,) = address(_portfolio).call(createPoolData);
        assert(success);

        // pool nonce should increase by 1 each time a pool is created
        uint256 poolNonce = _portfolio.getPoolNonce(pairId);
        assert(poolNonce == preCreationPoolNonce + 1);

        // pool should be created and exist
        poolId =
            ProcessingLib.encodePoolId(pairId, hasController, uint32(poolNonce));
        pool = getPool(address(_portfolio), poolId);
        if (!pool.exists()) {
            emit AssertionFailed(
                "BUG: Pool should return true on exists after being created."
            );
        }

        // save pools in Echidna
        save_pool_id(poolId);
    }

    /// @dev Create Special Pool is used to test swaps where quote token has 15 decimals.
    function create_special_pool(
        uint24 pairId,
        PoolParams memory pp
    ) internal returns (uint64 poolId) {
        PoolParams memory _pp;
        (
            _pp.priorityFee,
            _pp.fee,
            _pp.strikePrice,
            _pp.volatility,
            _pp.duration,
            _pp.jit,
            _pp.price
        ) = clam_safe_create_bounds(
            pp.priorityFee,
            pp.fee,
            pp.strikePrice,
            pp.volatility,
            pp.duration,
            pp.jit,
            pp.price
        );
        bytes memory createPoolData = ProcessingLib.encodeCreatePool(
            pairId,
            address(this),
            _pp.priorityFee,
            _pp.fee,
            _pp.volatility,
            _pp.duration,
            _pp.jit,
            _pp.strikePrice,
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
