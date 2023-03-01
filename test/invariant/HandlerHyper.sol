// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "./setup/HandlerBase.sol";

contract HandlerHyper is HandlerBase {
    function callSummary() external view {
        console.log("deposit", calls["deposit"]);
        console.log("fund-asset", calls["fund-asset"]);
        console.log("fund-quote", calls["fund-quote"]);
        console.log("create", calls["create"]);
    }

    function deposit(uint amount, uint seed) external countCall("deposit") createActor useActor(seed) usePool(seed) {
        amount = bound(amount, 1, 1e36);

        vm.deal(ctx.actor(), amount);

        address weth = ctx.subject().WETH();

        uint256 preBal = ctx.ghost().balance(ctx.actor(), weth);
        uint256 preRes = ctx.ghost().reserve(weth);

        ctx.subject().deposit{value: amount}();

        uint256 postRes = ctx.ghost().reserve(weth);
        uint256 postBal = ctx.ghost().balance(ctx.actor(), weth);

        assertEq(postRes, preRes + amount, "weth-reserve");
        assertEq(postBal, preBal + amount, "weth-balance");
        assertEq(address(ctx.subject()).balance, 0, "eth-balance");
        assertEq(ctx.ghost().physicalBalance(weth), postRes, "weth-physical");
    }

    function fund_asset(
        uint256 amount,
        uint256 seed
    ) public countCall("fund-asset") createActor useActor(seed) usePool(seed) {
        amount = bound(amount, 1, 1e36);

        // If net balance > 0, there are tokens in the contract which are not in a pool or balance.
        // They will be credited to the msg.sender of the next call.
        int256 netAssetBalance = ctx.subject().getNetBalance(address(ctx.ghost().asset().to_token()));
        int256 netQuoteBalance = ctx.subject().getNetBalance(address(ctx.ghost().quote().to_token()));
        assertTrue(netAssetBalance >= 0, "negative-net-asset-tokens");
        assertTrue(netQuoteBalance >= 0, "negative-net-quote-tokens");

        ctx.ghost().asset().to_token().approve(address(ctx.subject()), amount);
        deal(address(ctx.ghost().asset().to_token()), ctx.actor(), amount);

        uint256 preRes = ctx.ghost().reserve(address(ctx.ghost().asset().to_token()));
        uint256 preBal = ctx.ghost().balance(ctx.actor(), address(ctx.ghost().asset().to_token()));

        ctx.subject().fund(address(ctx.ghost().asset().to_token()), amount);
        uint256 postRes = ctx.ghost().reserve(address(ctx.ghost().asset().to_token()));
        uint256 postBal = ctx.ghost().balance(ctx.actor(), address(ctx.ghost().asset().to_token()));

        assertEq(postBal, preBal + amount + uint256(netAssetBalance), "fund-delta-asset-balance");
        assertEq(postRes, preRes + amount + uint256(netQuoteBalance), "fund-delta-asset-reserve");
    }

    function fund_quote(
        uint256 amount,
        uint256 seed
    ) public countCall("fund-quote") createActor useActor(seed) usePool(seed) {
        amount = bound(amount, 1, 1e36);

        ctx.ghost().quote().to_token().approve(address(ctx.subject()), amount);
        deal(address(ctx.ghost().quote().to_token()), ctx.actor(), amount);

        uint256 preRes = ctx.ghost().reserve(address(ctx.ghost().quote().to_token()));
        uint256 preBal = ctx.ghost().balance(ctx.actor(), address(ctx.ghost().quote().to_token()));

        ctx.subject().fund(address(ctx.ghost().quote().to_token()), amount);
        uint256 postRes = ctx.ghost().reserve(address(ctx.ghost().quote().to_token()));
        uint256 postBal = ctx.ghost().balance(ctx.actor(), address(ctx.ghost().quote().to_token()));

        assertEq(postBal, preBal + amount, "fund-delta-quote-balance");
        assertEq(postRes, preRes + amount, "fund-delta-quote-reserve");
    }

    function create_pool(
        uint256 seed,
        uint128 price,
        uint128 terminalPrice,
        uint16 volatility,
        uint16 duration,
        uint16 fee,
        uint16 priorityFee
    ) external countCall("create") createActor useActor(seed) usePool(seed) {
        vm.assume(terminalPrice != 0);

        volatility = uint16(bound(volatility, MIN_VOLATILITY, MAX_VOLATILITY));
        duration = uint16(block.timestamp + bound(duration, MIN_DURATION, MAX_DURATION));
        price = uint128(bound(price, 1, 1e36));
        fee = uint16(bound(fee, MIN_FEE, MAX_FEE));
        priorityFee = uint16(bound(priorityFee, MIN_FEE, fee));

        // Random user
        {
            MockERC20[] memory mock_tokens = ctx.getTokens();
            address[] memory tokens = new address[](mock_tokens.length);
            for (uint i; i != mock_tokens.length; ++i) {
                tokens[i] = address(mock_tokens[i]);
            }

            tokens = shuffle(seed, tokens);
            address token0 = tokens[0];
            address token1 = tokens[1];
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
            if (pairId == 0) instructions.push(Enigma.encodeCreatePair(args.token0, args.token1));

            // Push create pool to stack
            instructions.push(
                Enigma.encodeCreatePool(
                    pairId,
                    address(0),
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
        bytes memory payload = Enigma.encodeJumpInstruction(instructions);

        try ctx.subject().multiprocess(payload) {
            console.log("Successfully created a pool.");
        } catch {
            console.log("Errored on attempting to create a pool.");
        }

        // Refetch the poolId. Current poolId could be "magic" zero variable.
        pairId = ctx.subject().getPairId(args.token0, args.token1);
        assertTrue(pairId != 0, "pair-not-created");

        // todo: make sure we create the last pool...
        uint64 poolId = Enigma.encodePoolId(pairId, isMutable, uint32(ctx.subject().getPoolNonce()));
        // Add the created pool to the list of pools.
        // todo: fix assertTrue(getPool(address(subject()), poolId).lastPrice != 0, "pool-price-zero");
        ctx.addGhostPoolId(poolId);

        // Reset instructions so we don't use some old payload data...
        delete instructions;
    }
}
