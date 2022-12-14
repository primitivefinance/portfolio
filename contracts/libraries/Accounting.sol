// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "../interfaces/IERC20.sol";

using {cache, deposit, withdraw, credit, debit, prepare, settle, multiSettle, clearTransient, computeNetReserves, warmToken} for AccountSystem global;

struct AccountSystem {
    mapping(address => mapping(address => uint)) balances;
    mapping(address => uint) reserves;
    mapping(address => bool) cached;
    address[] warm; // Transiently stored, should always be length zero outside of execution.
    bool prepared;
    bool settled;
}

error InsufficientBalance(uint amount, uint delta);
error BalanceError1();

/** @dev Gas optimized. */
function __balanceOf__(address token, address account) view returns (uint256) {
    (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, account));
    if (!success || data.length != 32) revert BalanceError1();
    return abi.decode(data, (uint256));
}

function credit(AccountSystem storage self, address owner, address token, uint amount) {
    self.balances[owner][token] += amount;
}

// todo: deposit in here is a little dangerous, because we usually do debit to pay for deposit.
function debit(AccountSystem storage self, address owner, address token, uint amount) returns(bool paid) {
    uint balance = self.balances[owner][token];
    if (balance >= amount) {
        self.balances[owner][token] -= amount;
        paid = true;
    }
}

function computeNetReserves(AccountSystem storage self, address token, address account) view returns (int256 net) {
    uint internalBalance = self.reserves[token];
    uint physicalBalance = __balanceOf__(token, account);
    net = int256(physicalBalance) - int256(internalBalance);
}

function deposit(AccountSystem storage self, address token, uint amount) {
    self.warmToken(token);
    self.reserves[token] += amount;
}

function withdraw(AccountSystem storage self, address token, uint amount) {
    uint balance = self.reserves[token];
    if (amount > balance) revert InsufficientBalance(balance, amount);
    self.warmToken(token);
    self.reserves[token] -= amount;
}

function prepare(AccountSystem storage self) {
    self.prepared = true;
}

/** @notice Settles the difference in balance between tracked tokens and physically held tokens. */
function settle(AccountSystem storage self, function (address token, address to, uint amount) pay, address token, address account) {
    if(!self.prepared) revert NotPreparedToSettle();

    int net = self.computeNetReserves(token, account);
    if (net == 0) return;
    if (net > 0) return self.credit(msg.sender, token, uint(net));

    uint amount = uint(-net);
    bool paid = self.debit(msg.sender, token, amount);
    delete self.cached[token];
    if(!paid) pay(token, account, amount); // todo: fix this, seems dangerous.
    /* ERC20(token).safeTransferFrom(msg.sender, account, amount); */
}

error NotPreparedToSettle();

function multiSettle(AccountSystem storage self, function (address token, address to, uint amount) pay, address account) {
    if(!self.prepared) revert NotPreparedToSettle();

    address[] memory tokens = self.warm;
    if(tokens.length == 0) return;

  
    for(uint i; i != tokens.length; ++i) {
        address token = tokens[i];
        self.settle(pay, token, account);
    }

    self.clearTransient();
}

function warmToken(AccountSystem storage self, address token) {
    if (self.settled) self.settled = false; // If tokens are warm, they are not settled.
    if (self.cached[token]) return;
    self.warm.push(token);
    self.cache(token, true);
}

function clearTransient(AccountSystem storage self) {
    self.settled = true;
    delete self.warm;
    delete self.prepared;
}

function cache(AccountSystem storage self, address token, bool status) {
    self.cached[token] = status;
}
