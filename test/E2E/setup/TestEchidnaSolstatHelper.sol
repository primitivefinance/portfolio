// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "solmate/utils/LibString.sol";

/// @notice requires editing "lib/forge-std/lib/ds-test/src/test.sol"
///         in order to make `fail()` overridable:
///         `function fail() internal` -> `function fail() internal virtual`.
contract TestEchidnaSolstatHelper is Test {
    event AssertionFailed(string msg);

    address private constant canRevertCaller = 0xc65f435F6dC164bE5D52Bc0a90D9A680052bFab2;

    function fail() internal override {
        emit AssertionFailed("FAIL");
    }

    modifier canRevert() {
        if (msg.sender == canRevertCaller) {
            _;
        } else {
            vm.prank(canRevertCaller);

            (bool success, bytes memory returndata) = address(this).call(msg.data);

            if (success) {
                assembly {
                    return(add(returndata, 32), mload(returndata))
                }
            } else {
                // vm.assume(false);
            }
        }
    }

    function assertEqCall(bytes memory calldata1, bytes memory calldata2) internal {
        assertEqCall(address(this), calldata1, address(this), calldata2, true);
    }

    function assertEqCall(bytes memory calldata1, bytes memory calldata2, bool eqRevertData) internal {
        assertEqCall(address(this), calldata1, address(this), calldata2, eqRevertData);
    }

    function assertEqCall(address addr, bytes memory calldata1, bytes memory calldata2) internal {
        assertEqCall(addr, calldata1, addr, calldata2, true);
    }

    function assertEqCall(address addr, bytes memory calldata1, bytes memory calldata2, bool eqRevertData) internal {
        assertEqCall(addr, calldata1, addr, calldata2, eqRevertData);
    }

    function assertEqCall(address address1, bytes memory calldata1, address address2, bytes memory calldata2) internal {
        assertEqCall(address1, calldata1, address2, calldata2, true);
    }

    function assertEqCall(
        address address1,
        bytes memory calldata1,
        address address2,
        bytes memory calldata2,
        bool eqRevertData
    ) internal {
        (bool success1, bytes memory returndata1) = address(address1).call(calldata1);
        (bool success2, bytes memory returndata2) = address(address2).call(calldata2);

        if (success1 && success2) {
            assertEq(returndata1, returndata2, "Returned value does not match");
        }
        if (!success1 && success2) {
            emit log("Error: Call reverted unexpectedly");
            emit log_named_bytes("  Expected return-value", returndata2);
            emit log_named_bytes("       Call revert-data", returndata1);
            assert(false);
        }
        if (success1 && !success2) {
            emit log("Error: Call did not revert");
            emit log_named_bytes("  Expected revert-data", returndata2);
            emit log_named_bytes("     Call return-value", returndata1);
            assert(false);
        }
        if (!success1 && !success2 && eqRevertData) {
            assertEq(returndata1, returndata2, "Call revert data does not match");
        }
    }

    function assertGte(uint256 a, uint256 b) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            assert(false);
        }
    }

    function assertGte(int256 a, int256 b) internal {
        if (a < b) {
            emit log("Error: a >= b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            assert(false);
        }
    }

    function assertLte(int256 a, int256 b) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [int]");
            emit log_named_int("  Value a", a);
            emit log_named_int("  Value b", b);
            assert(false);
        }
    }

    function assertLte(uint256 a, uint256 b) internal {
        if (a > b) {
            emit log("Error: a <= b not satisfied [uint]");
            emit log_named_uint("  Value a", a);
            emit log_named_uint("  Value b", b);
            assert(false);
        }
    }

    function logInt(string memory name, int256 x) internal {
        string memory repr = string.concat(
            x >= 0 ? "" : "-",
            (x == type(int256).min)
                ? "-57896044618658097711785492504343953926634992332820282019728792003956564819968"
                : LibString.toString(uint256(x > 0 ? x : -x))
        );
        emit log_named_string(name, repr);
    }

    function wasteGas(uint256 slots) internal pure {
        assembly {
            let memPtr := mload(0x40)
            mstore(add(memPtr, mul(32, slots)), 1) // Expand memory
        }
    }
}
