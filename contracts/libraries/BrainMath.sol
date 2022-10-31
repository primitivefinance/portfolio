// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "solmate/utils/FixedPointMathLib.sol";

function _abs(int256 x) pure returns (uint256) {
    return uint256(~x + 1);
}

/// @dev slot index = ln(price) / ln(a) + 0.5
function getSlotFromPrice(uint256 priceF, uint256 aF) pure returns (int128) {
    return
        int128(
            int256(
                (FixedPointMathLib.divWadDown(
                    uint256(FixedPointMathLib.lnWad(int256(priceF))),
                    uint256(FixedPointMathLib.lnWad(int256(aF)))
                ) + 500000000000000000)
            )
        ) / int128(int256(FixedPointMathLib.WAD));
}

/// @dev proportion = ln(price) / ln(a) - activeSlot + 0.5
function getSlotProportionFromPrice(
    uint256 priceF,
    uint256 aF,
    int128 activeSlot
) pure returns (uint256) {
    return
        uint256(
            int256(
                FixedPointMathLib.divWadDown(
                    uint256(FixedPointMathLib.lnWad(int256(priceF))),
                    uint256(FixedPointMathLib.lnWad(int256(aF)))
                )
            ) -
                activeSlot *
                int128(int256(FixedPointMathLib.WAD)) +
                500000000000000000
        );
}

/// @dev price = a^(slotIndex + slotProportion - 0.5)
function getPriceFromSlot(
    uint256 aF,
    int128 slotIndex,
    uint256 slotProportionF
) returns (uint256) {
    return
        uint256(
            FixedPointMathLib.powWad(
                int256(aF),
                slotIndex * int128(int256(FixedPointMathLib.WAD)) + int256(slotProportionF) - 500000000000000000
            )
        );
}
