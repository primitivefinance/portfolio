// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.4;

import "../contracts/libraries/StringsLib.sol";
import "./Setup.sol";

contract TestStringsLib {
    function test_toStringPercent() public view {
        console.log(StringsLib.toStringPercent(10000));
        console.log(StringsLib.toStringPercent(0));
        console.log(StringsLib.toStringPercent(5000));
        console.log(StringsLib.toStringPercent(2500));
        console.log(StringsLib.toStringPercent(250));
        console.log(StringsLib.toStringPercent(25));
        console.log(StringsLib.toStringPercent(1));
    }

    function test_toFormatString() public view {
        console.log(StringsLib.toFormatAmount(1 ether, 18));
        console.log(StringsLib.toFormatAmount(0.001 ether, 18));
        console.log(StringsLib.toFormatAmount(2000 * 10 ** 6, 6));
        console.log(StringsLib.toFormatAmount(42 * 10 ** 4, 6));
    }
}
