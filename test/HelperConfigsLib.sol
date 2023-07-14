// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "solmate/utils/SafeCastLib.sol";
import "contracts/interfaces/IPortfolio.sol";
import "contracts/libraries/AssemblyLib.sol";
import { PortfolioConfig } from "contracts/libraries/CurveLib.sol";

using Configs for ConfigState global;

struct ConfigState {
    address asset;
    address quote;
    address controller;
    uint16 feeBps;
    uint16 priorityFeeBps;
    uint16 durationSeconds;
    uint16 volatilityBps;
    uint128 terminalPriceWad;
    uint128 reportedPriceWad;
}

uint16 constant DEFAULT_PRIORITY_FEE = 10;
uint16 constant DEFAULT_FEE = 100; // 100 bps = 1%
uint16 constant DEFAULT_VOLATILITY = 10_000;
// 1 day in seconds
uint16 constant DEFAULT_DURATION = 365;
uint128 constant DEFAULT_STRIKE = 10 ether;
uint128 constant DEFAULT_PRICE = 10 ether;
uint128 constant DEFAULT_LIQUIDITY = 1 ether;

function safeCastTo16(uint256 x) pure returns (uint16 y) {
    require(x < 1 << 16);

    y = uint16(x);
}

/**
 * @dev Manages the different parameters that can be tested against.
 *
 * User Manual:
 * - Make a fresh config with defaults using `Configs.fresh()`.
 * - Use `edit` to make modifications to the config.
 * - Must `edit` the `asset` and `quote` parameters of the config.
 * - Call `generate()` on a config to create the pool in the test subject (a Portfolio contract).
 */
library Configs {
    using SafeCastLib for uint256;
    using { safeCastTo16 } for uint256;

    function encodeCreate(
        uint24 pairId,
        address controller,
        uint16 priorityFee,
        uint16 fee,
        uint16 volatility,
        uint16 duration,
        uint128 strikePrice,
        uint128 price
    ) internal view returns (bytes memory) {
        return abi.encodeCall(
            IPortfolioActions.createPool,
            (
                pairId,
                0,
                0,
                fee,
                priorityFee,
                controller,
                abi.encode(
                    PortfolioConfig(
                        strikePrice,
                        volatility,
                        uint32(duration) * 1 days,
                        uint32(block.timestamp),
                        false
                    ),
                    price
                    )
            )
        );
    }

    /**
     * @dev Creates a new config with defaults.
     * @custom:example
     * ```
     * // Get the Portfolio contract that is the subject of the test.
     * address Portfolio = address(subject());
     * // Creates the pool with the fresh config.
     * Configs.fresh().{edit asset}.{edit quote}.generate(Portfolio);
     * // note: Must edit the `asset` and `quote`, or `generate` will revert.
     * ```
     */
    function fresh() internal pure returns (ConfigState memory) {
        ConfigState memory config = ConfigState({
            asset: address(0),
            quote: address(0),
            controller: address(0),
            feeBps: DEFAULT_FEE,
            priorityFeeBps: DEFAULT_PRIORITY_FEE,
            durationSeconds: DEFAULT_DURATION,
            volatilityBps: DEFAULT_VOLATILITY,
            terminalPriceWad: DEFAULT_STRIKE,
            reportedPriceWad: DEFAULT_PRICE
        });
        return config;
    }

    /**
     * @dev Modifies a parameter of the default config. Chain edits to modify the full config.
     * @custom:example
     * ```
     * // Expects abi encoded arguments as the `data`. Types must match expected types.
     * // Creates a new pool with `asset_address`.
     * Configs.fresh().edit("asset", abi.encode(asset_address)).generate(Portfolio);
     * ```
     */
    function edit(
        ConfigState memory self,
        bytes32 what,
        bytes memory data
    ) internal pure returns (ConfigState memory) {
        if (what == "asset") {
            self.asset = abi.decode(data, (address));
        } else if (what == "quote") {
            self.quote = abi.decode(data, (address));
        } else if (what == "duration") {
            self.durationSeconds = abi.decode(data, (uint16));
        } else if (what == "volatility") {
            self.volatilityBps = abi.decode(data, (uint16));
        } else if (what == "controller") {
            self.controller = abi.decode(data, (address));
        } else if (what == "priorityFee") {
            self.priorityFeeBps = abi.decode(data, (uint16));
        } else if (what == "fee") {
            self.feeBps = abi.decode(data, (uint16));
        }
        return self;
    }

    /**
     * @notice Uses a config and `Portfolio` address to create the pool in the contract.
     * @dev Will create a pair if the `asset` and `quote` are not an existing pair.
     * @custom:example
     * ```
     * uint64 poolId = Configs
     *      .fresh()
     *      .edit("asset", abi.encode(address(subjects().tokens[0])))
     *      .edit("quote", abi.encode(address(subjects().tokens[1])))
     *      .generate(address(subject()));
     * ```
     */
    function generate(
        ConfigState memory self,
        address Portfolio
    ) internal returns (uint64 poolId) {
        require(self.asset != address(0), "did you set asset in config?");
        require(self.quote != address(0), "did you set quote in config?");
        uint24 pairId =
            IPortfolioGetters(Portfolio).getPairId(self.asset, self.quote);
        if (pairId == 0) {
            bytes[] memory data = new bytes[](2);
            data[0] = abi.encodeCall(
                IPortfolioActions.createPair, (self.asset, self.quote)
            );
            data[1] = encodeCreate(
                pairId, // uses 0 pairId as magic variable. todo: maybe change to max uint24?
                self.controller,
                self.priorityFeeBps,
                self.feeBps,
                self.volatilityBps,
                self.durationSeconds,
                self.terminalPriceWad,
                self.reportedPriceWad
            );

            IPortfolio(Portfolio).multicall(data);

            bool controlled = self.controller != address(0);
            uint24 pairNonce = IPortfolioGetters(Portfolio).getPairNonce();
            poolId = AssemblyLib.encodePoolId(
                pairNonce,
                controlled,
                IPortfolioGetters(Portfolio).getPoolNonce(pairNonce)
            );
            require(poolId != 0, "ConfigLib.generate failed to createPool");
        } else {
            bytes[] memory data = new bytes[](1);

            data[0] = encodeCreate(
                pairId, // uses 0 pairId as magic variable. todo: maybe change to max uint24?
                self.controller,
                self.priorityFeeBps,
                self.feeBps,
                self.volatilityBps,
                self.durationSeconds,
                self.terminalPriceWad,
                self.reportedPriceWad
            );

            IPortfolio(Portfolio).multicall(data);
            bool controlled = self.controller != address(0);
            poolId = AssemblyLib.encodePoolId(
                pairId,
                controlled,
                IPortfolioGetters(Portfolio).getPoolNonce(pairId)
            );
            require(poolId != 0, "ConfigLib.generate failed to createPool");
        }
    }
}
