// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "../interfaces/IERC20.sol";
import "solmate/utils/SafeTransferLib.sol";

using SafeTransferLib for ERC20;

using {cache, computeNetReserves, increaseBalance, decreaseBalance, settle, clearTransient} for AccountSystem global;

struct AccountSystem {
    mapping(address => mapping(address => uint)) balances;
    mapping(address => uint) reserves;
    mapping(address => bool) cached;
    address[] warm; // Transiently stored, should always be length zero outside of execution.
    bool locked;
}

error InsufficientBalance(uint amount, uint delta);
error BalanceError1();

function fetchBalance(address token, address account) view returns (uint256) {
    (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, account));
    if (!success || data.length != 32) revert BalanceError1();
    return abi.decode(data, (uint256));
}

function increaseBalance(AccountSystem storage self, address owner, address token, uint amount) {
    self.balances[owner][token] += amount;
}

function decreaseBalance(AccountSystem storage self, address owner, address token, uint amount) {
    uint balance = self.balances[owner][token];
    if (amount > balance) revert InsufficientBalance(balance, amount);
    self.balances[owner][token] -= amount;
}

function computeNetReserves(AccountSystem storage self, address token, address account) view returns (int256 net) {
    uint internalBalance = self.reserves[token];
    uint physicalBalance = fetchBalance(token, account);
    net = int256(physicalBalance) - int256(internalBalance);
}

function increaseReserve(AccountSystem storage self, address token, uint amount) {
    self.reserves[token] += amount;
}

function decreaseReserve(AccountSystem storage self, address token, uint amount) {
    uint balance = self.reserves[token];
    if (amount > balance) revert InsufficientBalance(balance, amount);
    self.reserves[token] -= amount;
}

function prepare(AccountSystem storage self) {
    self.locked = true;
}

/** @notice Settles the difference in balance between tracked tokens and physically held tokens. */
function settle(AccountSystem storage self, function (address token, address to, uint amount) pay, address token, address account) {
    if(!self.locked) revert NotPreparedToSettle();

    int net = self.computeNetReserves(token, account);
    if (net == 0) return;
    if (net > 0) return self.increaseBalance(msg.sender, token, uint(net));

    uint amount = uint(-net);
    self.decreaseBalance(msg.sender, token, amount);
    pay(token, account, amount); // todo: fix this, seems dangerous.
    delete self.cached[token];
    /* ERC20(token).safeTransferFrom(msg.sender, account, amount); */
}

error NotPreparedToSettle();

function multiSettle(AccountSystem storage self, function (address token, address to, uint amount) pay, address account) {
    if(!self.locked) revert NotPreparedToSettle();

    address[] memory tokens = self.warm;
    if(tokens.length == 0) return;

  
    for(uint i; i != tokens.length; ++i) {
        address token = tokens[i];
        self.settle(pay, token, account);
    }

    self.clearTransient();
}

function warmToken(AccountSystem storage self, address token) {
    if (self.cached[token]) return;
    self.warm.push(token);
    self.cache(token, true);
}

function clearTransient(AccountSystem storage self) {
    delete self.warm;
    delete self.locked;
}

function cache(AccountSystem storage self, address token, bool status) {
    self.cached[token] = status;
}
