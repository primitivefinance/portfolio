// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "contracts/interfaces/IPortfolio.sol";
import "contracts/libraries/PortfolioLib.sol";
import "solmate/test/utils/mocks/MockERC20.sol";
import "contracts/libraries/CurveLib.sol";
import "contracts/RMM01Portfolio.sol";
import { Coin } from "./HelperUtils.sol";

using Ghost for GhostState global;

struct GhostState {
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

    function pair(GhostState memory self)
        internal
        view
        returns (PortfolioPair memory)
    {
        return IPortfolioStruct(self.subject).pairs(uint16(self.poolId >> 48));
    }

    function pool(GhostState memory self)
        internal
        view
        returns (PortfolioPool memory)
    {
        return IPortfolioStruct(self.subject).pools(self.poolId);
    }

    function position(
        GhostState memory self,
        address owner
    ) internal view returns (uint128) {
        return IPortfolio(self.subject).positions(owner, self.poolId);
    }

    function pairOf(
        GhostState memory self,
        uint24 pairId
    ) internal view returns (PortfolioPair memory) {
        return IPortfolioStruct(self.subject).pairs(pairId);
    }

    function poolOf(
        GhostState memory self,
        uint64 poolId
    ) internal view returns (PortfolioPool memory) {
        return IPortfolioStruct(self.subject).pools(poolId);
    }

    function configOf(
        GhostState memory self,
        uint64 poolId
    ) internal view returns (PortfolioConfig memory) {
        return IPortfolioStruct(self.subject).configs(poolId);
    }

    function file(
        GhostState storage self,
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
        GhostState memory self,
        address token
    ) internal view returns (int256) {
        return IPortfolioGetters(self.subject).getNetBalance(token);
    }

    function physicalBalance(
        GhostState memory self,
        address token
    ) internal view returns (uint256) {
        return MockERC20(token).balanceOf(self.subject);
    }

    function reserve(
        GhostState memory self,
        address token
    ) internal view returns (uint256) {
        return IPortfolioGetters(self.subject).getReserve(token);
    }

    function config(GhostState memory self)
        internal
        view
        returns (PortfolioConfig memory)
    {
        return IPortfolioStruct(self.subject).configs(self.poolId);
    }

    function asset(GhostState memory self) internal view returns (Coin) {
        return Coin.wrap(self.pair().tokenAsset);
    }

    function quote(GhostState memory self) internal view returns (Coin) {
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
