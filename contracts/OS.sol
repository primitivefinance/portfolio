// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "solmate/utils/SafeTransferLib.sol";

import "./interfaces/IWETH.sol";
import "./interfaces/IERC20.sol";
import {BalanceError, EtherTransferFail} from "./EnigmaTypes.sol";

using {__wrapEther__, dangerousFund, cache, deposit, withdraw, credit, debit, prepare, settle, settlement, clear, getNetBalance, touch} for AccountSystem global;

/** @dev Novel accounting mechanism to track internally held balances and settle differences with actual balances. */
struct AccountSystem {
    mapping(address => mapping(address => uint)) balances; // Internal user balances.
    mapping(address => uint) reserves; // Global balance of tokens held by a contract.
    mapping(address => bool) cached; // Tokens interacted with that must be settled.
    address[] warm; // Transiently stored, must be length zero outside of execution.
    bool prepared; // Must be false outside of execution.
    bool settled; // Must be true outside of execution.
}

error InsufficientBalance(uint amount, uint delta);
error NotPreparedToSettle();

/** @dev Gas optimized. */
function __balanceOf__(address token, address account) view returns (uint256) {
    (bool success, bytes memory data) = token.staticcall(abi.encodeWithSelector(IERC20.balanceOf.selector, account));
    if (!success || data.length != 32) revert BalanceError();
    return abi.decode(data, (uint256));
}

/** @dev Sends ether in `deposit` function to target address. Must validate `weth`. */
function __wrapEther__(AccountSystem storage self, address weth) {
    // todo: be careful with this, since it uses msg.value
    if(msg.value > 0) {
        IWETH(weth).deposit{value: msg.value}();
        self.touch(weth);
    } 
}

/** @dev Dangerously sends ether to `to` in a low-level call. */
function __dangerousUnwrapEther__(address weth, address to, uint256 amount) {
    IWETH(weth).withdraw(amount);
    __dangerousTransferEther__(to, amount);
}

/** @dev Dangerously sends ether to `to` in a low-level call. */
function __dangerousTransferEther__(address to, uint256 value) {
    (bool success, ) = to.call{value: value}(new bytes(0));
    if (!success) revert EtherTransferFail();
}

/** @dev Used in a for loop in the `settlement` function. */
function __dangerousTransferFrom__(address token, address to, uint amount) {
    SafeTransferLib.safeTransferFrom(ERC20(token), msg.sender, to, amount);
}

function dangerousFund(AccountSystem storage self, address token, address to, uint amount) {
    self.touch(token);
    __dangerousTransferFrom__(token, to, amount);
}

/** @dev Increases an `owner`'s spendable balance. */
function credit(AccountSystem storage self, address owner, address token, uint amount) {
    self.balances[owner][token] += amount;
}

/** @dev Decreases an `owner`'s spendable balance. */
function debit(AccountSystem storage self, address owner, address token, uint amount) returns(bool paid) {
    uint balance = self.balances[owner][token];
    if (balance >= amount) {
        self.balances[owner][token] -= amount;
        paid = true;
    }

    paid = false; // for clarity
}

/** @dev Actives a token and increases the reserves. Settlement will pick up this activated token. */
function deposit(AccountSystem storage self, address token, uint amount) {
    self.touch(token);
    self.reserves[token] += amount;
}

/** @dev Actives a token and decreases the reserves. Settlement will pick up this activated token. */
function withdraw(AccountSystem storage self, address token, uint amount) {
    uint balance = self.reserves[token];
    if (amount > balance) revert InsufficientBalance(balance, amount);
    self.touch(token);
    self.reserves[token] -= amount;
}

/** @dev Must be called prior to settlement. */
function prepare(AccountSystem storage self) {
    self.prepared = true;
}

/** @notice Settles the difference in balance between tracked tokens and physically held tokens. */
function settle(AccountSystem storage self, function (address token, address to, uint amount) pay, address token, address account) {
    if(!self.prepared) revert NotPreparedToSettle();

    int net = self.getNetBalance(token, account);
    if (net == 0) return;
    if (net > 0) return self.credit(msg.sender, token, uint(net));

    uint amount = uint(-net);
    bool paid = self.debit(msg.sender, token, amount);
    delete self.cached[token];
    if(!paid) pay(token, account, amount); // todo: fix this, seems dangerous using an anonymous function?
}



/** @dev Settles the discrepency in all activated token balances so the net balance is zero or positive. */
function settlement(AccountSystem storage self, function (address token, address to, uint amount) pay, address account) {
    if(!self.prepared) revert NotPreparedToSettle();

    address[] memory tokens = self.warm;
    if(tokens.length == 0) return self.clear();

  
    for(uint i; i != tokens.length; ++i) {
        address token = tokens[i];
        self.settle(pay, token, account);
    }

    self.clear();
}

/** @dev Interacting with a token will activate it, adding it to an array of interacted tokens for settlement to loop through. */
function touch(AccountSystem storage self, address token) {
    if (self.settled) self.settled = false; // If tokens are warm, they are not settled.
    if (self.cached[token]) return;
    self.warm.push(token);
    self.cache(token, true);
}

/** @dev Account system is reset after settlement is successful. */
function clear(AccountSystem storage self) {
    self.settled = true;
    delete self.warm;
    delete self.prepared;
}

/** @dev Used to check if a token was already activated after being interacted with again. */
function cache(AccountSystem storage self, address token, bool status) {
    self.cached[token] = status;
}

/** @dev Computes surplus (positive) or deficit (negative) in actual tokens compared to tracked amounts. */
function getNetBalance(AccountSystem storage self, address token, address account) view returns (int256 net) {
    uint internalBalance = self.reserves[token];
    uint physicalBalance = __balanceOf__(token, account);
    net = int256(physicalBalance) - int256(internalBalance);
}