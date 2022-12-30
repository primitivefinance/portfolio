// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "contracts/CPU.sol" as CPU;
import "./setup/InvariantTargetContract.sol";

contract InvariantCreatePool is InvariantTargetContract {
    constructor(address hyper_, address asset_, address quote_) InvariantTargetContract(hyper_, asset_, quote_) {}

    function create_pool(
        uint index,
        uint128 price,
        uint128 strike,
        uint24 sigma,
        uint32 maturity,
        uint32 gamma,
        uint32 priorityGamma
    ) external {
        vm.assume(price != 0);
        vm.assume(strike != 0);
        vm.assume(sigma != 0);
        gamma = uint32(bound(sigma, 1e4 - __hyper__.MAX_POOL_FEE(), 1e4 - __hyper__.MIN_POOL_FEE()));
        priorityGamma = uint32(bound(sigma, gamma, 1e4 - __hyper__.MIN_POOL_FEE()));

        // Random user
        address caller = ctx.getRandomUser(index);
        address[] memory tokens = new address[](3);
        tokens[0] = address(ctx.__weth__());
        tokens[1] = address(ctx.__asset__());
        tokens[2] = address(ctx.__quote__());

        address token0 = tokens[index % tokens.length];
        address token1 = tokens[index % tokens.length];

        CreateArgs memory args = CreateArgs(
            caller,
            token0,
            token1,
            price,
            strike,
            sigma,
            maturity,
            gamma,
            priorityGamma
        );
        _assertCreatePool(args);
    }

    struct CreateArgs {
        address caller;
        address token0;
        address token1;
        uint128 price;
        uint128 strike;
        uint24 sigma;
        uint32 maturity;
        uint32 gamma;
        uint32 priorityGamma;
    }

    bytes[] instructions;

    function _assertCreatePool(CreateArgs memory args) internal {
        uint16 pairId = __hyper__.getPairId(args.token0, args.token1);

        // Pair not created? Push a create pair call to the stack.
        if (pairId == 0) instructions.push(CPU.encodeCreatePair(args.token0, args.token1));

        uint16 fee = uint16(1e4 - args.gamma);
        uint16 priorityFee = uint16(1e4 - args.priorityGamma);
        bytes32 rawCurveId = CPU.toBytes32(abi.encodePacked(args.sigma, args.maturity, fee, priorityFee, args.strike));
        uint32 curveId = __hyper__.getCurveId(rawCurveId);

        // Curve not created? Push create curve to stack.
        if (curveId == 0)
            instructions.push(CPU.encodeCreateCurve(args.sigma, args.maturity, fee, priorityFee, args.strike));

        // Push create pool to stack
        uint48 poolId = CPU.encodePoolId(pairId, curveId);
        instructions.push(CPU.encodeCreatePool(poolId, args.price));

        bytes memory payload = CPU.encodeJumpInstruction(instructions);
        vm.prank(args.caller);
        (bool success, ) = address(__hyper__).call(payload); // TODO: Fallback function does not bubble up custom errors.
        assertTrue(success, "hyper-call-failed");
        assertTrue(getPool(address(__hyper__), poolId).lastPrice != 0, "pool-price-zero");

        // Refetch the poolId. Current poolId could be "magic" zero variable.
        pairId = __hyper__.getPairId(args.token0, args.token1);
        assertTrue(pairId != 0, "pair-not-created");

        curveId = __hyper__.getCurveId(rawCurveId);
        assertTrue(curveId != 0, "curve-not-created");

        poolId = CPU.encodePoolId(pairId, curveId);

        // Add the created pool to the list of pools.
        ctx.addPoolId(poolId);
    }
}
