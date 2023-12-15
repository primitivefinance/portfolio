// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "solmate/tokens/ERC1155.sol";
import "contracts/interfaces/IStrategy.sol";
import "contracts/interfaces/IPortfolio.sol";
import "contracts/libraries/PortfolioLib.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "contracts/strategies/NormalStrategy/NormalStrategyLib.sol";
import "contracts/Portfolio.sol";

import { Coin } from "./CoinType.sol";

using Ghost for GhostType global;

interface ConfigLike {
    function DEFAULT_STRATEGY() external view returns (address);
    function configs(uint64 poolId)
        external
        view
        returns (PortfolioConfig memory);
}

/// @dev Universal "ghost" state for unit tests.
struct GhostType {
    address actor;
    address subject;
    uint64 poolId;
}

/**
 * @dev Manages the state that exists only within the testing environment.
 *
 * User Manual:
 * - Edit ghost variables via `file`.
 * - Fetch ghost variables via view functions.
 * - Fetch the tokens of the subject configuration as the `Coin` type, with utility functions.
 * - Fetch the subject's state as structs instead of variables, e.g. PortfolioPair, PortfolioPool, or PortfolioPosition.
 */
library Ghost {
    error InvalidFileKey(bytes32 what);

    /// @dev Sets the ghost state.
    function file(
        GhostType storage self,
        bytes32 what,
        bytes memory data
    ) internal {
        if (what == "subject") {
            self.subject = abi.decode(data, (address));
        } else if (what == "poolId") {
            self.poolId = abi.decode(data, (uint64));
        } else if (what == "actor") {
            self.actor = abi.decode(data, (address));
        } else {
            revert InvalidFileKey(what);
        }
    }

    /// @dev Gets the pair state of the subject pool.
    function pair(GhostType memory self)
        internal
        view
        returns (PortfolioPair memory)
    {
        return IPortfolioStruct(self.subject).pairs(uint16(self.poolId));
    }

    /// @dev Gets the pool state of the subject pool.
    function pool(GhostType memory self)
        internal
        view
        returns (PortfolioPool memory)
    {
        return IPortfolioStruct(self.subject).pools(self.poolId);
    }

    /// @dev Gets the position state of the subject pool for the `owner`.
    function position(
        GhostType memory self,
        address owner
    ) internal view returns (uint128) {
        return uint128(
            ERC1155(self.subject).balanceOf(owner, uint256(self.poolId))
        );
    }

    /// @dev Gets the subject's net balance of a token.
    function net(
        GhostType memory self,
        address token
    ) internal view returns (int256) {
        return IPortfolioGetters(self.subject).getNetBalance(token);
    }

    /// @dev Gets the subject's physical balance of a token.
    function physicalBalance(
        GhostType memory self,
        address token
    ) internal view returns (uint256) {
        return MockERC20(token).balanceOf(self.subject);
    }

    /// @dev Gets the subject's reserve of a token.
    function reserve(
        GhostType memory self,
        address token
    ) internal view returns (uint256) {
        return IPortfolioGetters(self.subject).getReserve(token);
    }

    /// @dev Gets the subject poolid's strategy configuration.
    function config(GhostType memory self)
        internal
        view
        returns (PortfolioConfig memory)
    {
        return configOf(self, self.poolId);
    }

    /// @dev Gets the asset token, casted to the Coin type, of the subject pool.
    function asset(GhostType memory self) internal view returns (Coin) {
        return Coin.wrap(self.pair().tokenAsset);
    }

    /// @dev Gets the quote token, casted to the Coin type, of the subject pool.
    function quote(GhostType memory self) internal view returns (Coin) {
        return Coin.wrap(self.pair().tokenQuote);
    }

    /// @dev Gets the subject's default strategy.
    function strategy(GhostType memory self)
        internal
        view
        returns (IStrategy)
    {
        return IStrategy(self.pool().strategy);
    }

    /// @dev Gets the subject's default strategy.
    function DEFAULT_STRATEGY(GhostType memory self)
        internal
        view
        returns (IStrategy)
    {
        return IStrategy(ConfigLike(self.subject).DEFAULT_STRATEGY());
    }

    /// @dev Gets the pair state of a target pairId.
    function pairOf(
        GhostType memory self,
        uint24 pairId
    ) internal view returns (PortfolioPair memory) {
        return IPortfolioStruct(self.subject).pairs(pairId);
    }

    /// @dev Gets the pool state of a target poolId.
    function poolOf(
        GhostType memory self,
        uint64 poolId
    ) internal view returns (PortfolioPool memory) {
        return IPortfolioStruct(self.subject).pools(poolId);
    }

    /// @dev Gets the strategy configuration of a target poolId.
    function configOf(
        GhostType memory self,
        uint64 poolId
    ) internal view returns (PortfolioConfig memory) {
        address target = poolOf(self, poolId).strategy;

        require(target != address(0), "no config/strategy/controller config!");
        return ConfigLike(target).configs(poolId);
    }
}
