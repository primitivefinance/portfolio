// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "solmate/utils/SafeCastLib.sol";
import "contracts/interfaces/IHyper.sol";
import "contracts/libraries/EnigmaLib.sol" as EnigmaLib;

using Configs for ConfigState global;

struct ConfigState {
    address asset;
    address quote;
    address controller;
    uint16 feeBps;
    uint16 priorityFeeBps;
    uint16 durationDays;
    uint16 volatilityBps;
    uint16 justInTimeSec;
    uint128 terminalPriceWad;
    uint128 reportedPriceWad;
}

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
 * - Call `generate()` on a config to create the pool in the test subject (a Hyper contract).
 */
library Configs {
    using SafeCastLib for uint;
    using {safeCastTo16} for uint;

    /**
     * @dev Creates a new config with defaults.
     * @custom:example
     * ```
     * // Get the hyper contract that is the subject of the test.
     * address hyper = address(subject());
     * // Creates the pool with the fresh config.
     * Configs.fresh().{edit asset}.{edit quote}.generate(hyper);
     * // note: Must edit the `asset` and `quote`, or `generate` will revert.
     * ```
     */
    function fresh() internal returns (ConfigState memory) {
        ConfigState memory config = ConfigState({
            asset: address(0),
            quote: address(0),
            controller: address(0),
            feeBps: 100,
            priorityFeeBps: 10,
            durationDays: 365,
            volatilityBps: 10_000,
            justInTimeSec: 4,
            terminalPriceWad: 10 ether,
            reportedPriceWad: 10 ether
        });
        return config;
    }

    /**
     * @dev Modifies a parameter of the default config. Chain edits to modify the full config.
     * @custom:example
     * ```
     * // Expects abi encoded arguments as the `data`. Types must match expected types.
     * // Creates a new pool with `asset_address`.
     * Configs.fresh().edit("asset", abi.encode(asset_address)).generate(hyper);
     * ```
     */
    function edit(ConfigState memory self, bytes32 what, bytes memory data) internal pure returns (ConfigState memory) {
        if (what == "asset") {
            self.asset = abi.decode(data, (address));
        } else if (what == "quote") {
            self.quote = abi.decode(data, (address));
        } else if (what == "duration") {
            self.durationDays = abi.decode(data, (uint16));
        } else if (what == "volatility") {
            self.volatilityBps = abi.decode(data, (uint16));
        }
        return self;
    }

    /**
     * @notice Uses a config and `hyper` address to create the pool in the contract.
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
    function generate(ConfigState memory self, address hyper) internal returns (uint64 poolId) {
        require(self.asset != address(0), "did you set asset in config?");
        require(self.quote != address(0), "did you set quote in config?");
        uint24 pairId = IHyperGetters(hyper).getPairId(self.asset, self.quote);
        if (pairId == 0) {
            bytes[] memory data = new bytes[](2);
            data[0] = (EnigmaLib.encodeCreatePair(self.asset, self.quote));
            data[1] = (
                EnigmaLib.encodeCreatePool({
                    pairId: pairId, // uses 0 pairId as magic variable. todo: maybe change to max uint24?
                    controller: self.controller,
                    priorityFee: self.priorityFeeBps,
                    fee: self.feeBps,
                    dur: self.durationDays,
                    vol: self.volatilityBps,
                    jit: self.justInTimeSec,
                    maxPrice: self.terminalPriceWad,
                    price: self.reportedPriceWad
                })
            );

            bytes memory payload = EnigmaLib.encodeJumpInstruction(data);
            (bool success, bytes memory result) = hyper.call(payload); // todo: replace with try hyper.multiprocess(payload) {} catch (bytes memory err) {}
            bool controlled = self.controller != address(0);
            poolId = EnigmaLib.encodePoolId(
                IHyperGetters(hyper).getPairNonce(),
                controlled,
                IHyperGetters(hyper).getPoolNonce()
            );
            require(poolId != 0, "ConfigLib.generate failed to createPool");
        } else {
            poolId = IHyper(hyper).createPool({
                pairId: pairId,
                controller: self.controller,
                priorityFee: self.priorityFeeBps,
                fee: self.feeBps,
                dur: self.durationDays,
                vol: self.volatilityBps,
                jit: self.justInTimeSec,
                maxPrice: self.terminalPriceWad,
                price: self.reportedPriceWad
            });
        }
    }
}