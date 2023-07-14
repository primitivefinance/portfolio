// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "contracts/interfaces/IPortfolio.sol";
import "contracts/libraries/PortfolioLib.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "contracts/libraries/CurveLib.sol";
import "contracts/RMM01Portfolio.sol";

import { Coin } from "./CoinType.sol";

using Ghost for GhostType global;

/// @dev Universal state for unit tests.
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

    function pair(GhostType memory self)
        internal
        view
        returns (PortfolioPair memory)
    {
        return IPortfolioStruct(self.subject).pairs(uint16(self.poolId));
    }

    function pool(GhostType memory self)
        internal
        view
        returns (PortfolioPool memory)
    {
        return IPortfolioStruct(self.subject).pools(self.poolId);
    }

    function position(
        GhostType memory self,
        address owner
    ) internal view returns (uint128) {
        return IPortfolio(self.subject).positions(owner, self.poolId);
    }

    function pairOf(
        GhostType memory self,
        uint24 pairId
    ) internal view returns (PortfolioPair memory) {
        return IPortfolioStruct(self.subject).pairs(pairId);
    }

    function poolOf(
        GhostType memory self,
        uint64 poolId
    ) internal view returns (PortfolioPool memory) {
        return IPortfolioStruct(self.subject).pools(poolId);
    }

    function configOf(
        GhostType memory self,
        uint64 poolId
    ) internal view returns (PortfolioConfig memory) {
        return IPortfolioStruct(self.subject).configs(poolId);
    }

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

    function net(
        GhostType memory self,
        address token
    ) internal view returns (int256) {
        return IPortfolioGetters(self.subject).getNetBalance(token);
    }

    function physicalBalance(
        GhostType memory self,
        address token
    ) internal view returns (uint256) {
        return MockERC20(token).balanceOf(self.subject);
    }

    function reserve(
        GhostType memory self,
        address token
    ) internal view returns (uint256) {
        return IPortfolioGetters(self.subject).getReserve(token);
    }

    function config(GhostType memory self)
        internal
        view
        returns (PortfolioConfig memory)
    {
        return IPortfolioStruct(self.subject).configs(self.poolId);
    }

    function asset(GhostType memory self) internal view returns (Coin) {
        return Coin.wrap(self.pair().tokenAsset);
    }

    function quote(GhostType memory self) internal view returns (Coin) {
        return Coin.wrap(self.pair().tokenQuote);
    }
}

interface IPortfolioStruct {
    function pairs(uint24 pairId)
        external
        view
        returns (PortfolioPair memory);

    function pools(uint64 poolId)
        external
        view
        returns (PortfolioPool memory);

    function configs(uint64 poolId)
        external
        view
        returns (PortfolioConfig memory);
}
