// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import {
    IPortfolioActions,
    IPortfolioGetters
} from "contracts/interfaces/IPortfolio.sol";
import { IStrategy } from "contracts/interfaces/IStrategy.sol";

/// @dev Universal configuration of a pool in Portfolio to test.
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

using ConfigurationLib for Configuration global;

uint256 constant ConfigLib_DEFAULT_FEE = 30;
uint256 constant ConfigLib_DEFAULT_PRIORITY_FEE = 10;

function safeCastTo16(uint256 x) pure returns (uint16 y) {
    require(x < 1 << 16);

    y = uint16(x);
}

// todo: fix testing config so its more clear its for test setup.
/// @dev Instantiate a pool in Portfolio using a config.
library ConfigurationLib {
    using { safeCastTo16 } for uint256;

    function configure() internal pure returns (Configuration memory config) {
        config = Configuration({
            asset: address(0),
            quote: address(0),
            reserveXPerWad: 0,
            reserveYPerWad: 0,
            feeBasisPoints: ConfigLib_DEFAULT_FEE,
            priorityFeeBasisPoints: ConfigLib_DEFAULT_PRIORITY_FEE,
            controller: address(0),
            strategy: address(0),
            strategyArgs: ""
        });
    }

    function instantiate(
        Configuration memory config,
        address target
    ) internal returns (uint64 id) {
        require(config.asset != address(0), "ConfigType_Asset");
        require(config.quote != address(0), "ConfigType_Quote");
        require(config.reserveXPerWad != 0, "ConfigType_ReserveX");
        require(config.reserveYPerWad != 0, "ConfigType_ReserveY");

        if (config.feeBasisPoints == 0) {
            config.feeBasisPoints = ConfigLib_DEFAULT_FEE;
        }
        if (config.priorityFeeBasisPoints == 0) {
            config.priorityFeeBasisPoints = ConfigLib_DEFAULT_PRIORITY_FEE;
        }

        require(
            config.feeBasisPoints < type(uint16).max, "ConfigType_InvalidFee"
        );
        require(
            config.priorityFeeBasisPoints < type(uint16).max,
            "ConfigType_InvalidPriorityFee"
        );

        config.strategy = IPortfolioGetters(target).DEFAULT_STRATEGY();

        uint24 pairId =
            IPortfolioGetters(target).getPairId(config.asset, config.quote);

        // If pair is not deployed... we will deploy
        if (pairId == 0) {
            // Multicall payload
            bytes[] memory payload = new bytes[](2);
            payload[0] = abi.encodeCall(
                IPortfolioActions.createPair, (config.asset, config.quote)
            );

            payload[1] = abi.encodeCall(
                IPortfolioActions.createPool,
                (
                    pairId,
                    config.reserveXPerWad,
                    config.reserveYPerWad,
                    config.feeBasisPoints.safeCastTo16(),
                    config.priorityFeeBasisPoints.safeCastTo16(),
                    config.controller,
                    config.strategy,
                    config.strategyArgs
                )
            );

            try IPortfolioActions(target).multicall(payload) returns (
                bytes[] memory results
            ) {
                id = abi.decode(results[1], (uint64));
            } catch (bytes memory err) {
                assembly {
                    revert(add(32, err), mload(err))
                }
            }
        } else {
            // Else we can use the pairId to create a pool.
            try IPortfolioActions(target).createPool({
                pairId: pairId,
                reserveXPerWad: config.reserveXPerWad,
                reserveYPerWad: config.reserveYPerWad,
                feeBasisPoints: config.feeBasisPoints.safeCastTo16(),
                priorityFeeBasisPoints: config.priorityFeeBasisPoints.safeCastTo16(),
                controller: config.controller,
                strategy: config.strategy,
                strategyArgs: config.strategyArgs
            }) returns (uint64 _id) {
                id = _id;
            } catch (bytes memory err) {
                assembly {
                    revert(add(32, err), mload(err))
                }
            }
        }

        require(id != 0, "ConfigLib_fail_to_create_pool");
    }
}
