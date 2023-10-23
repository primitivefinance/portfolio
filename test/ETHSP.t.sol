// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "solmate/test/utils/mocks/MockERC20.sol";
import "solmate/utils/SafeCastLib.sol";
import "../contracts/test/ERC20Wrapper.sol";

import "./Setup.sol";

using SafeCastLib for uint256;

function to128(uint256 x) pure returns (uint128 y) {
    y = x.safeCastTo128();
}

contract ETHSP is Setup {
    using { to128 } for uint256;
    using NormalConfiguration for Configuration;

    Configuration CONFIG;

    address TOKEN_0;
    address TOKEN_1;
    address TOKEN_2;
    address TOKEN_3;

    uint64 TRANCHE_A_POOL;
    uint64 TRANCHE_B_POOL;

    address TRANCHE_A_TOKEN;
    address TRANCHE_B_TOKEN;

    address ETHSP_TOKEN;

    address PRIMARY_MARKET_USER;

    function create_actor() public {
        PRIMARY_MARKET_USER = address(0x0444);
    }

    modifier usePrimaryMarketUser() {
        vm.startPrank(PRIMARY_MARKET_USER);
        _;
        vm.stopPrank();
    }

    /// @dev ETHSP is a pool of two liquidity pool tokens.
    function test_ethsp() public {
        create_actor();

        _create_tokens();
        _create_pairs();
        _create_tranche_pools();
        _tokenize_tranches();
        _tokenize_ethsp();

        approve_tokens();
        allocate();
        issue();
        rebalance();
    }

    function approve_tokens() public usePrimaryMarketUser {
        // Approves tokens to subject (portfolio)
        MockERC20(TOKEN_0).approve(address(subject()), type(uint256).max);
        MockERC20(TOKEN_1).approve(address(subject()), type(uint256).max);
        MockERC20(TOKEN_2).approve(address(subject()), type(uint256).max);
        MockERC20(TOKEN_3).approve(address(subject()), type(uint256).max);

        // Approve tokenized pools to subject (portfolio)
        MockERC20(TRANCHE_A_TOKEN).approve(
            address(subject()), type(uint256).max
        );
        MockERC20(TRANCHE_B_TOKEN).approve(
            address(subject()), type(uint256).max
        );
        MockERC20(ETHSP_TOKEN).approve(address(subject()), type(uint256).max);
    }

    function allocate() public usePrimaryMarketUser {
        // Allocate 10 liquidity to each tranche
        uint256 amount = 10 ether;

        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeWithSelector(
            IPortfolioActions.allocate.selector,
            false,
            PRIMARY_MARKET_USER,
            TRANCHE_A_POOL,
            amount,
            type(uint128).max,
            type(uint128).max
        );

        calls[1] = abi.encodeWithSelector(
            IPortfolioActions.allocate.selector,
            false,
            PRIMARY_MARKET_USER,
            TRANCHE_B_POOL,
            amount,
            type(uint128).max,
            type(uint128).max
        );

        subject().multicall(calls);
    }

    function issue() public usePrimaryMarketUser {
        // Gets amounts of liquidity to wrap into ETHSP token.
        uint256 amount = 1 ether;
        ERC1155(address(subject())).setApprovalForAll(ETHSP_TOKEN, true);
        ERC1155(address(subject())).setApprovalForAll(ETHSP_TOKEN, true);
        ERC20Wrapper(ETHSP_TOKEN).mint(PRIMARY_MARKET_USER, amount);
    }

    function rebalance() public usePrimaryMarketUser {
        // Assume I receive 1 ETHSP token.
        // For example, I purchase it on a DEX for $0.9,
        // but the underlying assets are worth $1.0.
        // I want to redeem it for the underlying assest and sell it into the market.

        uint256[4] memory startBalances = [
            MockERC20(TOKEN_0).balanceOf(PRIMARY_MARKET_USER),
            MockERC20(TOKEN_1).balanceOf(PRIMARY_MARKET_USER),
            MockERC20(TOKEN_2).balanceOf(PRIMARY_MARKET_USER),
            MockERC20(TOKEN_3).balanceOf(PRIMARY_MARKET_USER)
        ];

        // Redeem ETHSP
        uint256 amount = 1 ether;
        ERC20Wrapper(ETHSP_TOKEN).burn(PRIMARY_MARKET_USER, amount);

        // Remove liquidity from both ERC115 pool tokens.
        bytes[] memory calls = new bytes[](2);
        calls[0] = abi.encodeWithSelector(
            IPortfolioActions.deallocate.selector,
            false,
            TRANCHE_A_POOL,
            amount,
            0,
            0
        );
        calls[1] = abi.encodeWithSelector(
            IPortfolioActions.deallocate.selector,
            false,
            TRANCHE_B_POOL,
            amount,
            0,
            0
        );

        subject().multicall(calls);

        uint256[4] memory endBalances = [
            MockERC20(TOKEN_0).balanceOf(PRIMARY_MARKET_USER),
            MockERC20(TOKEN_1).balanceOf(PRIMARY_MARKET_USER),
            MockERC20(TOKEN_2).balanceOf(PRIMARY_MARKET_USER),
            MockERC20(TOKEN_3).balanceOf(PRIMARY_MARKET_USER)
        ];

        uint256[4] memory deltas = [
            endBalances[0] - startBalances[0],
            endBalances[1] - startBalances[1],
            endBalances[2] - startBalances[2],
            endBalances[3] - startBalances[3]
        ];

        console2.log("ethsp delta: -", amount);
        for (uint256 i; i < deltas.length; i++) {
            emit delta(i, deltas[i]);
        }

        // Send the tokens to pay the DEX, or anyone else, back!
    }

    event delta(uint256 i, uint256 amt);

    function _create_tokens() internal {
        // Basket A
        TOKEN_0 = address(new MockERC20("Token0", "0", 18));
        TOKEN_1 = address(new MockERC20("Token1", "1", 18));

        // Basket B
        TOKEN_2 = address(new MockERC20("Token2", "2", 18));
        TOKEN_3 = address(new MockERC20("Token3", "3", 18));

        // Labels
        vm.label(TOKEN_0, "Token0");
        vm.label(TOKEN_1, "Token1");
        vm.label(TOKEN_2, "Token2");
        vm.label(TOKEN_3, "Token3");

        // Mint some tokens to primary market user.
        MockERC20(TOKEN_0).mint(PRIMARY_MARKET_USER, 1_000_000_000 ether);
        MockERC20(TOKEN_1).mint(PRIMARY_MARKET_USER, 1_000_000_000 ether);
        MockERC20(TOKEN_2).mint(PRIMARY_MARKET_USER, 1_000_000_000 ether);
        MockERC20(TOKEN_3).mint(PRIMARY_MARKET_USER, 1_000_000_000 ether);
    }

    function _create_pairs() internal {
        // Create both pairs
        uint24 TRANCHE_A_PAIR = subject().createPair(TOKEN_0, TOKEN_1);
        uint24 TRANCHE_B_PAIR = subject().createPair(TOKEN_2, TOKEN_3);
    }

    function _create_tranche_pools() internal {
        // Create both pools
        uint256 volatility_bps = 1000;
        uint256 duration_sec = SECONDS_PER_YEAR;
        uint256 strike_price = 2000 ether;
        uint256 last_price = 1800 ether;
        uint256 fee_bps = 10;
        uint256 priority_fee_bps = 0;

        // Pool config is specific to the NormalStrategy.
        PortfolioConfig memory POOL_CONFIG = PortfolioConfig({
            strikePriceWad: strike_price.to128(),
            volatilityBasisPoints: volatility_bps.safeCastTo32(),
            durationSeconds: duration_sec.safeCastTo32(),
            isPerpetual: false,
            creationTimestamp: uint32(block.timestamp)
        });

        // Makes a defaut config which defines the Portfolio pool state.
        CONFIG = configure();
        // Edits the fee of the pool.
        CONFIG = CONFIG.edit("feeBasisPoints", abi.encode(fee_bps)).edit(
            "priorityFeeBasisPoints", abi.encode(priority_fee_bps)
        );
        // Adds the strategy specific arguments to the config, by computing the reserves and also encoding the strategy data.
        CONFIG = CONFIG.combine(POOL_CONFIG);
        // Updates the strategy to have the reserves match a price.
        CONFIG = CONFIG.editStrategy("priceWad", abi.encode(last_price));
        // Applies the respective tokens to each config.
        Configuration memory TRANCHE_A_CONFIG = CONFIG.edit(
            "asset", abi.encode(TOKEN_0)
        ).edit("quote", abi.encode(TOKEN_1));

        Configuration memory TRANCHE_B_CONFIG = CONFIG.edit(
            "asset", abi.encode(TOKEN_2)
        ).edit("quote", abi.encode(TOKEN_3));
        // Creates the pools with the configs.
        TRANCHE_A_POOL = TRANCHE_A_CONFIG.activate(
            address(subject()), NormalConfiguration.validateNormalStrategy
        );
        TRANCHE_B_POOL = TRANCHE_B_CONFIG.activate(
            address(subject()), NormalConfiguration.validateNormalStrategy
        );
    }

    function _tokenize_tranches() public {
        uint64[] memory a_pools = new uint64[](1);
        a_pools[0] = TRANCHE_A_POOL;
        TRANCHE_A_TOKEN = address(
            new ERC20Wrapper(
            address(subject()),
            a_pools,
            "ETHSP Tranche A",
            "ETHSP-A"
            )
        );

        uint64[] memory b_pools = new uint64[](1);
        b_pools[0] = TRANCHE_B_POOL;
        TRANCHE_B_TOKEN = address(
            new ERC20Wrapper(
            address(subject()),
            b_pools,
            "ETHSP Tranche B",
            "ETHSP-B"
            )
        );

        // Labels
        vm.label(TRANCHE_A_TOKEN, "ETHSP Tranche A");
        vm.label(TRANCHE_B_TOKEN, "ETHSP Tranche B");
    }

    function _tokenize_ethsp() public {
        uint64[] memory ethsp_pools = new uint64[](2);
        ethsp_pools[0] = TRANCHE_A_POOL;
        ethsp_pools[1] = TRANCHE_B_POOL;
        ETHSP_TOKEN = address(
            new ERC20Wrapper(
            address(subject()),
            ethsp_pools,
            "ETHSP",
            "ETHSP"
            )
        );

        // Labels
        vm.label(ETHSP_TOKEN, "ETHSP");
    }
}
