// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./setup/HandlerBase.sol";
import "contracts/HyperLib.sol" as HyperTypes;

contract HandlerCreatePool is HandlerBase {
    function create_pool(
        uint256 seed,
        uint128 price,
        uint128 terminalPrice,
        uint16 volatility,
        uint16 duration,
        uint16 fee,
        uint16 priorityFee
    ) external createActor useActor(seed) usePool(seed) countCall("create") {
        vm.assume(terminalPrice != 0);

        volatility = uint16(bound(volatility, HyperTypes.MIN_VOLATILITY, HyperTypes.MAX_VOLATILITY));
        duration = uint16(block.timestamp + bound(duration, 1, 365 days / HyperTypes.Assembly.SECONDS_PER_DAY));
        price = uint128(bound(price, 1, 1e36));
        fee = uint16(bound(fee, HyperTypes.MAX_FEE, HyperTypes.MIN_FEE));
        priorityFee = uint16(bound(priorityFee, fee, HyperTypes.MIN_FEE));

        // Random user
        {
            address[] memory tokens = new address[](3);
            tokens[0] = ctx.ghost().asset().to_addr();
            tokens[1] = ctx.ghost().quote().to_addr();

            address[] memory shuffled = shuffle(seed, tokens);
            address token0 = shuffled[0];
            address token1 = shuffled[1];
            assertTrue(token0 != token1, "same-token");

            CreateArgs memory args = CreateArgs(
                ctx.actor(),
                token0,
                token1,
                price,
                terminalPrice,
                volatility,
                duration,
                fee,
                priorityFee
            );
            _assertCreatePool(args);
        }
    }

    function shuffle(uint256 random, address[] memory array) internal pure returns (address[] memory output) {
        for (uint256 i = 0; i < array.length; i++) {
            uint256 n = i + (random % (array.length - i));
            address temp = array[n];
            array[n] = array[i];
            array[i] = temp;
        }

        output = array;
    }

    struct CreateArgs {
        address caller;
        address token0;
        address token1;
        uint128 price;
        uint128 terminalPrice;
        uint16 volatility;
        uint16 duration;
        uint16 fee;
        uint16 priorityFee;
    }

    bytes[] instructions;

    function _assertCreatePool(CreateArgs memory args) internal {
        bool isMutable = true;
        uint24 pairId = ctx.subject().getPairId(args.token0, args.token1);
        {
            // HyperPair not created? Push a create pair call to the stack.
            if (pairId == 0) instructions.push(HyperTypes.Enigma.encodeCreatePair(args.token0, args.token1));

            // Push create pool to stack
            instructions.push(
                HyperTypes.Enigma.encodeCreatePool(
                    pairId,
                    ctx.actor(),
                    args.priorityFee, // priorityFee
                    args.fee, // fee
                    args.volatility, // vol
                    args.duration, // dur
                    4, // jit
                    args.terminalPrice,
                    args.price
                )
            ); // temp
        }
        bytes memory payload = HyperTypes.Enigma.encodeJumpInstruction(instructions);
        vm.prank(args.caller);
        ctx.subject().multiprocess(payload);

        // Refetch the poolId. Current poolId could be "magic" zero variable.
        pairId = ctx.subject().getPairId(args.token0, args.token1);
        assertTrue(pairId != 0, "pair-not-created");

        // todo: make sure we create the last pool...
        uint64 poolId = HyperTypes.Enigma.encodePoolId(pairId, isMutable, uint32(ctx.subject().getPoolNonce()));

        // Add the created pool to the list of pools.
        // todo: fix assertTrue(getPool(address(subject()), poolId).lastPrice != 0, "pool-price-zero");
        ctx.addGhostPoolId(poolId);

        // Reset instructions so we don't use some old payload data...
        delete instructions;
    }
}
