pragma solidity 0.8.13;

interface IERC20 {
    function approve(address spender, uint256 amount) external;
}

contract HyperForwarderHelper {
    Caller public caller;

    event Success();
    event Fail(bytes reason);

    constructor() {
        caller = new Caller();
    }

    function approve(address token, address target) external {
        caller.approve(token, target, type(uint256).max);
    }

    // Assumes Hyper calls this, for testing only.
    function pass(address target, bytes calldata data) external payable returns (bool) {
        try caller.forward{value: msg.value}(target, data) {
            emit Success();
            return true;
        } catch (bytes memory reason) {
            emit Fail(reason);
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }

    function getPoolId(uint16 pairId, uint32 curveId) public pure returns (uint48) {
        return uint48(bytes6(abi.encodePacked(pairId, curveId)));
    }
}

/// @dev msg.sender in Hyper calls.
contract Caller {
    function approve(
        address token,
        address to,
        uint256 amount
    ) external {
        IERC20(token).approve(to, amount);
    }

    function forward(address target, bytes calldata data) external payable returns (bool) {
        (bool success, bytes memory returnData) = target.call{value: msg.value}(data);
        if (!success) {
            assembly {
                revert(add(32, returnData), mload(returnData))
            }
        }

        return success;
    }
}