// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

// Test Utils
import "contracts/libraries/AssemblyLib.sol";

// Contracts
import { MIN_FEE, MAX_FEE } from "contracts/libraries/PoolLib.sol";
import {
    IPortfolioActions,
    IPortfolioGetters
} from "contracts/interfaces/IPortfolio.sol";
import { IStrategy } from "contracts/interfaces/IStrategy.sol";

using AssemblyLib for uint256;

/**
 * @notice
 * Global test configuration for Portfolio.
 *
 * @dev
 * Portfolio has this special configuration type to make it easier to manager
 * the many parameters, tokens, and states that Portfolio can have.
 *
 * @param asset Primary token of the pool. Token for reserve "X".
 * @param quote Secondary token of the pool. Token for reserve "Y".
 * @param reserveXPerWad Amount of X reserves in WAD units, per WAD of liquidity. Used for pool price initialization.
 * @param reserveYPerWad Amount of Y reserves in WAD units, per WAD of liquidity. Used for pool price initialization.
 * @param feeBasisPoints Pool's swap fee in basis points.
 * @param priorityFeeBasisPoints Pool's swap fee charged to the pool's controller if swapping, in basis points.
 * @param controller Address of the pool's controller.
 * @param strategy Address of the pool's strategy.
 * @param strategyArgs Strategy arguments to be passed to the strategy, dependent on the `strategy`.
 */

struct Configuration {
    address asset;
    address quote;
    uint256 reserveXPerWad;
    uint256 reserveYPerWad;
    uint256 feeBasisPoints;
    uint256 priorityFeeBasisPoints;
    address controller;
    address strategy;
    bytes strategyArgs;
}

using { activate, edit, fuzz, validate } for Configuration global;

error Configuration_InvalidKey(bytes32 what);
error Configuration_FuzzInvalidKey(bytes32 what);

address constant Configuration_DEFAULT_CONTROLLER = address(0);
address constant Configuration_DEFAULT_STRATEGY = address(0);
uint16 constant Configuration_DEFAULT_FEE = 30;
uint16 constant Configuration_DEFAULT_PRIORITY_FEE = 0;

/// @dev Instantiates a configuration with default values.
function configure() pure returns (Configuration memory) {
    return Configuration({
        asset: address(0),
        quote: address(0),
        reserveXPerWad: 0,
        reserveYPerWad: 0,
        feeBasisPoints: Configuration_DEFAULT_FEE,
        priorityFeeBasisPoints: Configuration_DEFAULT_PRIORITY_FEE,
        controller: Configuration_DEFAULT_CONTROLLER,
        strategy: Configuration_DEFAULT_STRATEGY,
        strategyArgs: ""
    });
}

/// @dev Validates a configuration for Portfolio, reverting on invalid state.
function validate(
    Configuration memory self,
    function (Configuration memory) pure returns(bool) validateStrategy
) pure returns (bool) {
    require(self.asset != address(0), "Configuration_InvalidAsset");
    require(self.quote != address(0), "Configuration_InvalidQuote");
    require(self.reserveXPerWad != 0, "Configuration_InvalidReserveX");
    require(self.reserveYPerWad != 0, "Configuration_InvalidReserveY");
    require(
        self.feeBasisPoints.isBetween(MIN_FEE, MAX_FEE),
        "Configuration_InvalidFee"
    );

    if (self.priorityFeeBasisPoints > 0) {
        require(
            self.priorityFeeBasisPoints.isBetween(MIN_FEE, self.feeBasisPoints),
            "Configuration_InvalidPriorityFee"
        );
        require(
            self.controller != address(0),
            "Configuration_PriorityFeeWithoutController"
        );
    }

    require(validateStrategy(self), "Configuration_InvalidStrategyArgs");
    return true;
}

/// @dev Instatiates the Portfolio state to match the configuration. Calls `createPool`.
function activate(
    Configuration memory self,
    address portfolio,
    function (Configuration memory) pure returns(bool) validateStrategy
) returns (uint64 poolId) {
    require(self.validate(validateStrategy), "Configuration_Invalid");

    // Check if the pair exists, it's pairId will be non-zero.
    uint24 pairId =
        IPortfolioGetters(portfolio).getPairId(self.asset, self.quote);

    // If pair is not deployed... we will deploy
    if (pairId == 0) {
        // Multicall payload
        bytes[] memory payload = new bytes[](2);
        payload[0] = abi.encodeCall(
            IPortfolioActions.createPair, (self.asset, self.quote)
        );

        payload[1] = abi.encodeCall(
            IPortfolioActions.createPool,
            (
                pairId, // pairId is 0, a magic value to tell portfolio to "use the last created pair".
                self.reserveXPerWad,
                self.reserveYPerWad,
                self.feeBasisPoints.safeCastTo16(),
                self.priorityFeeBasisPoints.safeCastTo16(),
                self.controller,
                self.strategy,
                self.strategyArgs
            )
        );

        try IPortfolioActions(portfolio).multicall(payload) returns (
            bytes[] memory results
        ) {
            poolId = abi.decode(results[1], (uint64));
        } catch (bytes memory err) {
            // Bubble up any custom error that gets thrown.
            assembly {
                revert(add(32, err), mload(err))
            }
        }
    } else {
        // Else we can use the pairId to create a pool.
        try IPortfolioActions(portfolio).createPool({
            pairId: pairId,
            reserveXPerWad: self.reserveXPerWad,
            reserveYPerWad: self.reserveYPerWad,
            feeBasisPoints: self.feeBasisPoints.safeCastTo16(),
            priorityFeeBasisPoints: self.priorityFeeBasisPoints.safeCastTo16(),
            controller: self.controller,
            strategy: self.strategy,
            strategyArgs: self.strategyArgs
        }) returns (uint64 id_) {
            poolId = id_;
        } catch (bytes memory err) {
            // Bubble up any custom error that gets thrown.
            assembly {
                revert(add(32, err), mload(err))
            }
        }
    }

    require(poolId != 0, "Configuration_CreatePoolFail");
}

/// @dev Edit a configuration value.
function edit(
    Configuration memory self,
    bytes32 key,
    bytes memory value
) pure returns (Configuration memory) {
    if (key == "asset") {
        self.asset = abi.decode(value, (address));
    } else if (key == "quote") {
        self.quote = abi.decode(value, (address));
    } else if (key == "reserveXPerWad") {
        self.reserveXPerWad = abi.decode(value, (uint256));
    } else if (key == "reserveYPerWad") {
        self.reserveYPerWad = abi.decode(value, (uint256));
    } else if (key == "feeBasisPoints") {
        self.feeBasisPoints = abi.decode(value, (uint256));
    } else if (key == "priorityFeeBasisPoints") {
        self.priorityFeeBasisPoints = abi.decode(value, (uint256));
    } else if (key == "controller") {
        self.controller = abi.decode(value, (address));
    } else if (key == "strategy") {
        self.strategy = abi.decode(value, (address));
    } else if (key == "strategyArgs") {
        self.strategyArgs = value;
    } else {
        revert Configuration_InvalidKey(key);
    }

    return self;
}

/// @dev Fuzzes the fee arguments within its valid range.
function fuzz(
    Configuration memory self,
    function (uint256 , uint256 , uint256) internal view returns (uint256) bound,
    bytes32 key,
    uint256 seed
) view returns (Configuration memory) {
    if (key == "feeBasisPoints") {
        self.feeBasisPoints = bound(seed, MIN_FEE, MAX_FEE).safeCastTo16();
    } else if (key == "priorityFeeBasisPoints") {
        self.priorityFeeBasisPoints =
            bound(seed, MIN_FEE, self.feeBasisPoints).safeCastTo16();
    } else {
        revert Configuration_FuzzInvalidKey(key);
    }

    return self;
}
