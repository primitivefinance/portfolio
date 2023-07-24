// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

// Test Utilities
import { Configuration, configure } from "test/Configuration.sol";

// Utilities
import "solmate/utils/SafeCastLib.sol";

using SafeCastLib for uint256;

import "contracts/libraries/AssemblyLib.sol";

using AssemblyLib for uint256;
using AssemblyLib for uint128;
using AssemblyLib for uint32;

// Strategy contract
import "contracts/strategies/NormalStrategyLib.sol";

uint256 constant NormalConfiguration_DEFAULT_PRICE = 1 ether;
uint256 constant NormalConfiguration_DEFAULT_STRIKE_WAD = 1 ether;
uint256 constant NormalConfiguration_DEFAULT_VOLATILITY_BPS = 1000 wei; // in bps
uint256 constant NormalConfiguration_DEFAULT_DURATION_SEC = 1 days; // in seconds
uint256 constant NormalConfiguration_DEFAULT_CREATION_TIMESTAMP = 0;
bool constant NormalConfiguration_DEFAULT_IS_PERPETUAL = false;

using NormalConfiguration for Configuration;
using { NormalStrategyLib.decode } for bytes;

/// @dev Creates a Configuration with default normal strategy arguments.
function configureNormalStrategy() pure returns (Configuration memory) {
    // Price needs to be set seperately because it requires the reserves to be updated.
    Configuration memory self = configure();

    PortfolioConfig memory strategyConfig = PortfolioConfig({
        strikePriceWad: NormalConfiguration_DEFAULT_STRIKE_WAD.safeCastTo128(),
        volatilityBasisPoints: NormalConfiguration_DEFAULT_VOLATILITY_BPS
            .safeCastTo32(),
        durationSeconds: NormalConfiguration_DEFAULT_DURATION_SEC.safeCastTo32(),
        creationTimestamp: NormalConfiguration_DEFAULT_CREATION_TIMESTAMP
            .safeCastTo32(),
        isPerpetual: NormalConfiguration_DEFAULT_IS_PERPETUAL
    });

    self = NormalConfiguration.combine(self, strategyConfig);

    // Updating the price of the strategy must be done after the initial strategy args are set!
    return self.editStrategy(
        "priceWad", abi.encode(NormalConfiguration_DEFAULT_PRICE)
    );
}

/// @dev Use this in the `Setup.sol` file to test the normal strategy: `using NormalConfiguration for Configuration`.
library NormalConfiguration {
    error NormalConfiguration_InvalidKey(bytes32 what);

    /// @dev Validates the normal strategy configuration, reverting if invalid, used in `Configuration.activate`.
    function validateNormalStrategy(Configuration memory self)
        internal
        pure
        returns (bool)
    {
        PortfolioConfig memory strategyConfig = self.strategyArgs.decode(); // this can silently fail!

        require(
            strategyConfig.strikePriceWad.isBetween(
                MIN_STRIKE_PRICE, MAX_STRIKE_PRICE
            ),
            "NormalConfiguration_InvalidStrikePrice"
        );
        require(
            strategyConfig.volatilityBasisPoints.isBetween(
                MIN_VOLATILITY, MAX_VOLATILITY
            ),
            "NormalConfiguration_InvalidVolatility"
        );
        require(
            strategyConfig.durationSeconds.isBetween(MIN_DURATION, MAX_DURATION),
            "NormalConfiguration_InvalidDuration"
        );

        return true;
    }

    /// @dev Sets the strategyArgs for the root Configuration using the normal strategy config.
    function combine(
        Configuration memory config,
        PortfolioConfig memory strategyConfig
    ) internal pure returns (Configuration memory) {
        config.strategyArgs = strategyConfig.encode();
        return config;
    }

    /// @dev Edits the normal strategy configuration.
    /// IMPORTANT: Make sure to change priceWad after editing the strategy to take into account your modifications!
    function editStrategy(
        Configuration memory self,
        bytes32 key,
        bytes memory value
    ) internal pure returns (Configuration memory) {
        // Editing the strategy's initial price requires the root configuration's
        // reserves to be updated using the approximated prices...
        if (key == "priceWad") {
            return setReserves(self, abi.decode(value, (uint256)));
        }

        // If not editing the initial price, then the strategy can be edited directly.
        PortfolioConfig memory strategyConfig = self.strategyArgs.decode();
        if (key == "strikePriceWad") {
            // Verbose... but not to not revert silently from the abi.decode!
            uint256 strike = abi.decode(value, (uint256));
            require(
                strike <= type(uint128).max,
                "NormalConfiguration_DecodeInvalidStrikePrice"
            );
            strategyConfig.strikePriceWad = strike.safeCastTo128();
        } else if (key == "volatilityBasisPoints") {
            uint256 volatility = abi.decode(value, (uint256));
            require(
                volatility <= type(uint32).max,
                "NormalConfiguration_DecodeInvalidVolatility"
            );
            strategyConfig.volatilityBasisPoints = volatility.safeCastTo32();
        } else if (key == "durationSeconds") {
            uint256 duration = abi.decode(value, (uint256));
            require(
                duration <= type(uint32).max,
                "NormalConfiguration_DecodeInvalidDuration"
            );
            strategyConfig.durationSeconds = duration.safeCastTo32();
        } else if (key == "isPerpetual") {
            strategyConfig.isPerpetual = abi.decode(value, (bool));
        } else {
            revert NormalConfiguration_InvalidKey(key);
        }

        return self.edit("strategyArgs", strategyConfig.encode());
    }

    /// @dev Sets the reserves given a target price.
    function setReserves(
        Configuration memory config,
        uint256 priceWad
    ) internal pure returns (Configuration memory) {
        PortfolioConfig memory strategyConfig = config.strategyArgs.decode();

        (config.reserveXPerWad, config.reserveYPerWad) =
            strategyConfig.transform().approximateReservesGivenPrice(priceWad);
        return config;
    }
}
