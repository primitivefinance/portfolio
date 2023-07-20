// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import {
    IPortfolioActions,
    IPortfolioGetters
} from "contracts/interfaces/IPortfolio.sol";
import { IStrategy } from "contracts/interfaces/IStrategy.sol";

/// @dev Universal configuration of a pool in Portfolio to test.
struct ConfigType {
    address asset;
    address quote;
    uint256 reserveXPerWad;
    uint256 reserveYPerWad;
    uint256 feeBasisPoints;
    uint256 priorityFeeBasisPoints;
    address controller;
    bytes strategyArgs;
}

using ConfigLib for ConfigType global;

uint256 constant ConfigLib_DEFAULT_FEE = 30;
uint256 constant ConfigLib_DEFAULT_PRIORITY_FEE = 10;

function safeCastTo16(uint256 x) pure returns (uint16 y) {
    require(x < 1 << 16);

    y = uint16(x);
}

// todo: fix testing config so its more clear its for test setup.
/// @dev Instantiate a pool in Portfolio using a config.
library ConfigLib {
    using { safeCastTo16 } for uint256;

    function instantiate(
        ConfigType memory config,
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
