pub use hyper::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod hyper {
    #![allow(clippy::enum_variant_names)]
    #![allow(dead_code)]
    #![allow(clippy::type_complexity)]
    #![allow(unused_imports)]
    pub use super::super::shared_types::*;
    use ::ethers::contract::{
        builders::{ContractCall, Event},
        Contract, Lazy,
    };
    use ::ethers::core::{
        abi::{Abi, Detokenize, InvalidOutputType, Token, Tokenizable},
        types::*,
    };
    use ::ethers::providers::Middleware;
    ///Hyper was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
    use std::sync::Arc;
    #[rustfmt::skip]
    const __ABI: &str = "[{\"inputs\":[{\"internalType\":\"address\",\"name\":\"weth\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"constructor\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"DrawBalance\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"EtherTransferFail\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"Infinity\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"type\":\"error\",\"name\":\"InsufficientPosition\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"delta\",\"type\":\"uint256\",\"components\":[]}],\"type\":\"error\",\"name\":\"InsufficientReserve\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidBalance\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"expected\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"length\",\"type\":\"uint256\",\"components\":[]}],\"type\":\"error\",\"name\":\"InvalidBytesLength\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint8\",\"name\":\"decimals\",\"type\":\"uint8\",\"components\":[]}],\"type\":\"error\",\"name\":\"InvalidDecimals\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]}],\"type\":\"error\",\"name\":\"InvalidFee\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidInstruction\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"int256\",\"name\":\"prev\",\"type\":\"int256\",\"components\":[]},{\"internalType\":\"int256\",\"name\":\"next\",\"type\":\"int256\",\"components\":[]}],\"type\":\"error\",\"name\":\"InvalidInvariant\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"pointer\",\"type\":\"uint256\",\"components\":[]}],\"type\":\"error\",\"name\":\"InvalidJump\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidReentrancy\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidReward\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidSettlement\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidTransfer\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"distance\",\"type\":\"uint256\",\"components\":[]}],\"type\":\"error\",\"name\":\"JitLiquidity\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"Min\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"NegativeInfinity\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"type\":\"error\",\"name\":\"NonExistentPool\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"type\":\"error\",\"name\":\"NonExistentPosition\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"NotController\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"NotPreparedToSettle\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"OOB\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"int256\",\"name\":\"wad\",\"type\":\"int256\",\"components\":[]}],\"type\":\"error\",\"name\":\"OverflowWad\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint24\",\"name\":\"pairId\",\"type\":\"uint24\",\"components\":[]}],\"type\":\"error\",\"name\":\"PairExists\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"PoolExists\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"PoolExpired\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint96\",\"name\":\"positionId\",\"type\":\"uint96\",\"components\":[]}],\"type\":\"error\",\"name\":\"PositionNotStaked\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"SameTokenError\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"type\":\"error\",\"name\":\"StakeNotMature\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"SwapLimitReached\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"ZeroInput\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"ZeroLiquidity\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"ZeroPrice\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"ZeroValue\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"quote\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"deltaLiquidity\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Allocate\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[],\"indexed\":false},{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[],\"indexed\":true}],\"type\":\"event\",\"name\":\"ChangeParameters\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"account\",\"type\":\"address\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"feeAsset\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"feeQuote\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"quote\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"feeReward\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"reward\",\"type\":\"address\",\"components\":[],\"indexed\":true}],\"type\":\"event\",\"name\":\"Collect\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint24\",\"name\":\"pairId\",\"type\":\"uint24\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"quote\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"CreatePair\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":true},{\"internalType\":\"bool\",\"name\":\"isMutable\",\"type\":\"bool\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"quote\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"price\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"CreatePool\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"DecreaseReserveBalance\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"account\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"DecreaseUserBalance\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"account\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Deposit\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"IncreaseReserveBalance\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"account\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"IncreaseUserBalance\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"deltaLiquidity\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Stake\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"price\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"tokenIn\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"input\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"tokenOut\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"output\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Swap\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"quote\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"deltaLiquidity\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Unallocate\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"deltaLiquidity\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Unstake\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[],\"stateMutability\":\"payable\",\"type\":\"fallback\",\"outputs\":[]},{\"inputs\":[],\"stateMutability\":\"pure\",\"type\":\"function\",\"name\":\"VERSION\",\"outputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"WETH\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__account__\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"prepared\",\"type\":\"bool\",\"components\":[]},{\"internalType\":\"bool\",\"name\":\"settled\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"allocate\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"changeParameters\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"claim\",\"outputs\":[]},{\"inputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\",\"name\":\"deposit\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"to\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"draw\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"fund\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"bool\",\"name\":\"sellAsset\",\"type\":\"bool\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amountIn\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getAmountOut\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"output\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getAmounts\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getLatestPrice\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"price\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"int128\",\"name\":\"deltaLiquidity\",\"type\":\"int128\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getLiquidityDeltas\",\"outputs\":[{\"internalType\":\"uint128\",\"name\":\"deltaAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"deltaQuote\",\"type\":\"uint128\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getMaxLiquidity\",\"outputs\":[{\"internalType\":\"uint128\",\"name\":\"deltaLiquidity\",\"type\":\"uint128\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getNetBalance\",\"outputs\":[{\"internalType\":\"int256\",\"name\":\"\",\"type\":\"int256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPairId\",\"outputs\":[{\"internalType\":\"uint24\",\"name\":\"\",\"type\":\"uint24\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPairNonce\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPoolNonce\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getReserve\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getTimePassed\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getVirtualReserves\",\"outputs\":[{\"internalType\":\"uint128\",\"name\":\"deltaAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"deltaQuote\",\"type\":\"uint128\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint24\",\"name\":\"\",\"type\":\"uint24\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"pairs\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"pools\",\"outputs\":[{\"internalType\":\"int24\",\"name\":\"lastTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"lastTimestamp\",\"type\":\"uint32\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"controller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalReward\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"lastPrice\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"liquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"int128\",\"name\":\"stakedLiquidityDelta\",\"type\":\"int128\",\"components\":[]},{\"internalType\":\"struct HyperCurve\",\"name\":\"params\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]},{\"internalType\":\"struct HyperPair\",\"name\":\"pair\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"positions\",\"outputs\":[{\"internalType\":\"uint128\",\"name\":\"freeLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"lastTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"stakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"unstakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthRewardLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuoteLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedQuote\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedReward\",\"type\":\"uint128\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"deltaLiquidity\",\"type\":\"uint128\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"stake\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"bool\",\"name\":\"sellAsset\",\"type\":\"bool\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"limit\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"swap\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"output\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"remainder\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"unallocate\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"deltaLiquidity\",\"type\":\"uint128\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"unstake\",\"outputs\":[]},{\"inputs\":[],\"stateMutability\":\"payable\",\"type\":\"receive\",\"outputs\":[]}]";
    /// The parsed JSON-ABI of the contract.
    pub static HYPER_ABI: ::ethers::contract::Lazy<::ethers::core::abi::Abi> =
        ::ethers::contract::Lazy::new(|| {
            ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi")
        });
    /// Bytecode of the #name contract
    pub static HYPER_BYTECODE: ::ethers::contract::Lazy<::ethers::core::types::Bytes> =
        ::ethers::contract::Lazy::new(|| {
            "0x60a06040526001600b553480156200001657600080fd5b50604051620099cf380380620099cf83398101604081905262000039916200005a565b6001600160a01b03166080526004805461ff0019166101001790556200008c565b6000602082840312156200006d57600080fd5b81516001600160a01b03811681146200008557600080fd5b9392505050565b6080516198946200013b600039600081816101d60152818161025b0152818161089e0152818161126701528181611341015281816115e00152818161185801528181611eb70152818161222601528181612264015281816122af01528181612328015281816125a801528181612732015281816127d901528181612870015281816128ac01528181612953015281816129f7015281816142f401528181614329015261438101526198946000f3fe6080604052600436106101c65760003560e01c80638e26770f116100f7578063bcf78a5a11610095578063d6b7dec511610064578063d6b7dec514610a3d578063da31ee5414610a75578063fd2dbea114610aaf578063ffa1ad7414610ac557610202565b8063bcf78a5a146109bf578063c9a396e9146109df578063d0e30db014610a15578063d4fac45d14610a1d57610202565b8063a81262d5116100d1578063a81262d51461084c578063ad24d6a01461086c578063ad5c46481461088c578063b68513ea146108d857610202565b80638e26770f146107ec5780639e5e2e291461080c578063a4c68d9d1461082c57610202565b80635ef05b0c116101645780637dae48901161013e5780637dae4890146104f45780638992f20a1461051457806389a5f084146105345780638c470b8f146107cc57610202565b80635ef05b0c146104745780636a707efa146104b45780637b1837de146104d457610202565b80632c0f8903116101a05780632c0f8903146103435780633f92a339146103785780634dc68a90146103c95780635e47663c146103e957610202565b80630242f403146102da578063078888d61461030d578063231358111461032357610202565b3661020257336001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000161461020057600080fd5b005b600b546001146102285760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff16156102545760405160016238ddf760e01b0319815260040160405180910390fd5b61027f60007f0000000000000000000000000000000000000000000000000000000000000000610ae7565b6004805460ff19169055610294610b50610da7565b6004805460ff191660011790556102a9610df4565b600454610100900460ff166102d1576040516304564c7160e21b815260040160405180910390fd5b6001600b819055005b3480156102e657600080fd5b506102fa6102f5366004618dad565b6111ce565b6040519081526020015b60405180910390f35b34801561031957600080fd5b506102fa60055481565b34801561032f57600080fd5b5061020061033e366004618dc8565b61120e565b34801561034f57600080fd5b5061036361035e366004618e0b565b6112e5565b60408051928352602083019190915201610304565b34801561038457600080fd5b506103b5610393366004618e4c565b600960209081526000928352604080842090915290825290205462ffffff1681565b60405162ffffff9091168152602001610304565b3480156103d557600080fd5b506102fa6103e4366004618e76565b6113e6565b3480156103f557600080fd5b50610440610404366004618e91565b600760205260009081526040902080546001909101546001600160a01b038083169260ff600160a01b9182900481169392831692919091041684565b604080516001600160a01b03958616815260ff94851660208201529490921691840191909152166060820152608001610304565b34801561048057600080fd5b5061049461048f366004618dad565b6113f9565b604080516001600160801b03938416815292909116602083015201610304565b3480156104c057600080fd5b506102006104cf366004618ec8565b611587565b3480156104e057600080fd5b506102006104ef366004618f58565b6117ff565b34801561050057600080fd5b506102fa61050f366004618f84565b611893565b34801561052057600080fd5b5061049461052f366004618fc0565b611cb3565b34801561054057600080fd5b506107b461054f366004618dad565b60086020528060005260406000206000915090508060000160009054906101000a900460020b908060000160039054906101000a900463ffffffff16908060000160079054906101000a90046001600160a01b0316908060010154908060020154908060030154908060040160009054906101000a90046001600160801b0316908060040160109054906101000a90046001600160801b0316908060050160009054906101000a90046001600160801b0316908060050160109054906101000a9004600f0b90806006016040518060e00160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900461ffff1661ffff1661ffff1681526020016000820160059054906101000a900461ffff1661ffff1661ffff1681526020016000820160079054906101000a900461ffff1661ffff1661ffff1681526020016000820160099054906101000a900461ffff1661ffff1661ffff16815260200160008201600b9054906101000a900461ffff1661ffff1661ffff16815260200160008201600d9054906101000a900463ffffffff1663ffffffff1663ffffffff168152505090806007016040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff168152505090508c565b6040516103049c9b9a99989796959493929190618ff2565b3480156107d857600080fd5b506102fa6107e7366004618dad565b611e4a565b3480156107f857600080fd5b5061020061080736600461910c565b611e5e565b34801561081857600080fd5b50610363610827366004618dad565b6123c7565b34801561083857600080fd5b5061036361084736600461913f565b61254c565b34801561085857600080fd5b50610200610867366004618dc8565b6126d9565b34801561087857600080fd5b50610200610887366004619181565b612780565b34801561089857600080fd5b506108c07f000000000000000000000000000000000000000000000000000000000000000081565b6040516001600160a01b039091168152602001610304565b3480156108e457600080fd5b5061095c6108f33660046191b4565b600a6020908152600092835260408084209091529082529020805460018201546002830154600384015460048501546005860154600687015460078801546008909801546001600160801b0380891699600160801b998a9004821699818316939104821691168b565b604080516001600160801b039c8d1681529a8c1660208c01528a01989098526060890196909652608088019490945260a087019290925260c086015260e08501528416610100840152831661012083015290911661014082015261016001610304565b3480156109cb57600080fd5b506103636109da366004618e0b565b6128f7565b3480156109eb57600080fd5b506102fa6109fa366004618e76565b6001600160a01b031660009081526001602052604090205490565b61020061299e565b348015610a2957600080fd5b506102fa610a38366004618e4c565b612abf565b348015610a4957600080fd5b50610a5d610a5836600461910c565b612ae8565b6040516001600160801b039091168152602001610304565b348015610a8157600080fd5b50600454610a989060ff8082169161010090041682565b604080519215158352901515602083015201610304565b348015610abb57600080fd5b506102fa60065481565b348015610ad157600080fd5b50610ada612c7a565b604051610304919061920a565b3415610b4c57610af78282612c97565b806001600160a01b031663d0e30db0346040518263ffffffff1660e01b81526004016000604051808303818588803b158015610b3257600080fd5b505af1158015610b46573d6000803e3d6000fd5b50505050505b5050565b6000610b8583836000818110610b6857610b6861923d565b9190910135600481901c60ff60f41b1692600f60f81b9091169150565b9150506001600160f81b031980821601610bc9576000806000610ba88686612d2d565b925092509250610bbf8360ff166001148383612dba565b5050505050505050565b60fd60f81b6001600160f81b0319821601610c04576000806000610bed86866130ff565b925092509250610bbf8360ff166001148383613191565b60fb60f81b6001600160f81b0319821601610c8b576040805160a081018252600080825260208201819052918101829052606081018290526080810191909152610c4e8484613668565b60ff90811660808701526001600160801b039182166060870152911660408501526001600160401b039091166020840152168152610bbf81613745565b607d60f91b6001600160f81b0319821601610cc257600080610cad85856144ab565b91509150610cbb828261450f565b5050505050565b60f960f81b6001600160f81b0319821601610cfa57600080610ce485856144ab565b91509150610cf28282614a2e565b505050505050565b60f560f81b6001600160f81b0319821601610d59576000806000806000806000806000610d278c8c614dbd565b985098509850985098509850985098509850610d4a898989898989898989614efa565b50505050505050505050505050565b603d60fa1b6001600160f81b0319821601610d8957600080610d7b8585615877565b91509150610cf282826158e3565b604051631b1891ed60e31b815260040160405180910390fd5b505050565b605560f91b6000368181610dbd57610dbd61923d565b9050013560f81c60f81b6001600160f81b03191614610de857610de56000368363ffffffff16565b50565b610de560003683615b9b565b60045460ff16610e1757604051630f7cede560e41b815260040160405180910390fd5b600080600301805480602002602001604051908101604052809291908181526020018280548015610e7157602002820191906000526020600020905b81546001600160a01b03168152600190910190602001808311610e53575b5050505050905060008151905080600003610e9057610b4c6000615c58565b6000815b600084610ea2600184619269565b81518110610eb257610eb261923d565b602002602001015190506000806000610ed784306000615c969092919063ffffffff16565b919450925090508115610f68576040518281526001600160a01b0385169033907f0b0b821953e5545b71f2085833e4a8dfd0d99bbdff511898672ae8179a982df39060200160405180910390a3836001600160a01b03167f1c711eca8d0b694bbcb0a14462a7006222e721954b2c5ff798f606817eb1103283604051610f5f91815260200190565b60405180910390a25b8215610ff2576040518381526001600160a01b0385169033907f49e1443cb25e17cbebc50aa3e3a5a3df3ac334af852bc6f3e8d258558257bb119060200160405180910390a3836001600160a01b03167f80b21748c787c52e87a6b222011e0a0ed0f9cc2015f0ced46748642dc62ee9f884604051610fe991815260200190565b60405180910390a25b801561108c57604080518082019091526001600160a01b03858116825260208201838152600c805460018101825560009190915292517fdf6966c971051c3d54ec59162606531493a51404a002842f56009d7e5cf4a8c7600290940293840180546001600160a01b0319169190931617909155517fdf6966c971051c3d54ec59162606531493a51404a002842f56009d7e5cf4a8c8909101555b600380548061109d5761109d619280565b6001900381819060005260206000200160006101000a8154906001600160a01b0302191690559055846001900394508560010195505050505080600003610e94576000600c805480602002602001604051908101604052809291908181526020016000905b8282101561114a576000848152602090819020604080518082019091526002850290910180546001600160a01b03168252600190810154828401529083529092019101611102565b5050825192935050505b80156111b8576000611167600183619269565b90506111ae83828151811061117e5761117e61923d565b6020026020010151600001513085848151811061119d5761119d61923d565b602002602001015160200151615d7b565b5060001901611154565b6111c26000615c58565b610cf2600c6000618d1c565b6001600160401b0381166000908152600860205260408120546301000000900463ffffffff16426111ff9190619296565b6001600160801b031692915050565b600b546001146112345760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff16156112605760405160016238ddf760e01b0319815260040160405180910390fd5b61128b60007f0000000000000000000000000000000000000000000000000000000000000000610ae7565b6004805460ff1916905561129f828261450f565b6004805460ff191660011790556112b4610df4565b600454610100900460ff166112dc576040516304564c7160e21b815260040160405180910390fd5b50506001600b55565b600080600b5460011461130e5760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff161561133a5760405160016238ddf760e01b0319815260040160405180910390fd5b61136560007f0000000000000000000000000000000000000000000000000000000000000000610ae7565b6004805460ff191690556000198314611394818661138f826113875787615d87565b60015b615d87565b612dba565b6004805460ff1916600117905590935091506113b09050610df4565b600454610100900460ff166113d8576040516304564c7160e21b815260040160405180910390fd5b6001600b5590939092509050565b60006113f3818330615d9d565b92915050565b6001600160401b03811660009081526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187015460608088019190915284880154608080890191909152600389015460a0808a019190915260048a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681850152600160481b8804861681840152600160581b880490951690850152600160681b90950490931694820194909452610140850152855191820186526007850154808416835260ff600160a01b918290048116988401989098529490970154918216948101949094529190910490921692810192909252610160810191909152819061157e90615dd9565b91509150915091565b600b546001146115ad5760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff16156115d95760405160016238ddf760e01b0319815260040160405180910390fd5b61160460007f0000000000000000000000000000000000000000000000000000000000000000610ae7565b6004805460ff191690556001600160401b03871660009081526008602052604090208054600160381b90046001600160a01b03163314611657576040516323019e6760e01b815260040160405180910390fd5b6040805160e0810182526006830154600281900b825261ffff6301000000820481166020840152600160281b8204811693830193909352600160381b810483166060830152600160481b810483166080830152600160581b8104831660a083015263ffffffff600160681b9091041660c0820152908416156116de5761ffff841660208201525b8260020b6000146116f157600283900b81525b61ffff8716156117065761ffff871660408201525b61ffff86161561171b5761ffff861660808201525b61ffff8516156117305761ffff851660608201525b61ffff8816156117455761ffff881660a08201525b61174f8282615df4565b6040805161ffff8a8116825288811660208301528781168284015286811660608301529151600286900b928a16916001600160401b038d16917f149d8f45beb243253e6bf4915f72c467b5a81370cfa27a62c7424755be95e5019181900360800190a450506004805460ff191660011790556117c9610df4565b600454610100900460ff166117f1576040516304564c7160e21b815260040160405180910390fd5b50506001600b555050505050565b600b546001146118255760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff16156118515760405160016238ddf760e01b0319815260040160405180910390fd5b61187c60007f0000000000000000000000000000000000000000000000000000000000000000610ae7565b6004805460ff1916905561129f6000833084615edd565b600080602885901c62ffffff169050600060086000876001600160401b03166001600160401b03168152602001908152602001600020604051806101800160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900463ffffffff1663ffffffff1663ffffffff1681526020016000820160079054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820154815260200160028201548152602001600382015481526020016004820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016004820160109054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160109054906101000a9004600f0b600f0b600f0b8152602001600682016040518060e00160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900461ffff1661ffff1661ffff1681526020016000820160059054906101000a900461ffff1661ffff1661ffff1681526020016000820160079054906101000a900461ffff1661ffff1661ffff1681526020016000820160099054906101000a900461ffff1661ffff1661ffff16815260200160008201600b9054906101000a900461ffff1661ffff1661ffff16815260200160008201600d9054906101000a900463ffffffff1663ffffffff1663ffffffff16815250508152602001600782016040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff1681525050815250509050611ca8600760008462ffffff1662ffffff1681526020019081526020016000206040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff16815250508686846020015163ffffffff16611c8b4290565b611c959190619296565b85939291906001600160801b0316615ef8565b509695505050505050565b6001600160401b03821660009081526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187015460608088019190915284880154608080890191909152600389015460a0808a019190915260048a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681850152600160481b8804861681840152600160581b880490951690850152600160681b909504841695830195909552610140860191909152865192830187526007860154808216845260ff600160a01b9182900481169985019990995295909801549788169582019590955292909504909316938101939093526101608201929092528291611e3e919085906161fa16565b915091505b9250929050565b6000611e558261628f565b50909392505050565b600b54600114611e845760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff1615611eb05760405160016238ddf760e01b0319815260040160405180910390fd5b611edb60007f0000000000000000000000000000000000000000000000000000000000000000610ae7565b6004805460ff191681556001600160401b03841660008181526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187810154606080890191909152858901546080808a019190915260038a015460a0808b01919091529f8a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681840152600160481b8804861681830152600160581b88049095169f85019f909f52600160681b9095049093169482019490945261014085015285519a8b01865260078501548084168c52600160a01b9081900460ff9081168d8a015295909801549283168b8701529690910490921691880191909152610160810196909652338452600a82528084209484529390529181209182015490036120a957604051632f9b02db60e11b81523360048201526001600160401b03861660248201526044015b60405180910390fd5b6120d58260e001516001600160801b031683608001518460a00151846164ae909392919063ffffffff16565b50506120e084615d87565b6007820180546000906120fd9084906001600160801b0316619296565b92506101000a8154816001600160801b0302191690836001600160801b0316021790555061212a83615d87565b60078201805460109061214e908490600160801b90046001600160801b0316619296565b92506101000a8154816001600160801b0302191690836001600160801b03160217905550600084111561218c576101608201515161218c90856165a1565b82156121a5576121a582610160015160400151846165a1565b6121cc8261010001516001600160801b03168360600151836165f39092919063ffffffff16565b506008810180546001600160801b031690819060006121eb8380619296565b92506101000a8154816001600160801b0302191690836001600160801b031602179055506000816001600160801b031611156122e0576122547f0000000000000000000000000000000000000000000000000000000000000000826001600160801b03166165a1565b806001600160801b0316612288307f0000000000000000000000000000000000000000000000000000000000000000612abf565b10156122a7576040516314414f4160e11b815260040160405180910390fd5b6122dd6000307f00000000000000000000000000000000000000000000000000000000000000006001600160801b03851661666b565b50505b610160830151604080820151915181516001600160401b038a168152336020820152918201889052606082018790526001600160801b03841660808301526001600160a01b037f00000000000000000000000000000000000000000000000000000000000000008116938116929116907f8c84cdba09392140d3a3451ef9fd7f258a06ace3b8492bc20598872a630084d49060a00160405180910390a450506004805460ff1916600117905550612395610df4565b600454610100900460ff166123bd576040516304564c7160e21b815260040160405180910390fd5b50506001600b5550565b6001600160401b03811660009081526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187015460608088019190915284880154608080890191909152600389015460a0808a019190915260048a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681850152600160481b8804861681840152600160581b880490951690850152600160681b90950490931694820194909452610140850152855191820186526007850154808416835260ff600160a01b918290048116988401989098529490970154918216948101949094529190910490921692810192909252610160810191909152819061157e90616741565b600080600b546001146125755760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff16156125a15760405160016238ddf760e01b0319815260040160405180910390fd5b6125cc60007f0000000000000000000000000000000000000000000000000000000000000000610ae7565b6004805460ff19169055600183016125e9576001600160801b0392505b6000198414600081612603576125fe86615d87565b61260c565b6001600160801b035b90506126816040518060a001604052808461262857600061262b565b60015b60ff1681526020018a6001600160401b03168152602001836001600160801b0316815260200161265a88615d87565b6001600160801b0316815260200189612674576001612677565b60005b60ff169052613745565b6004805460ff1916600117905596509094506126a19350610df492505050565b600454610100900460ff166126c9576040516304564c7160e21b815260040160405180910390fd5b6001600b55909590945092505050565b600b546001146126ff5760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff161561272b5760405160016238ddf760e01b0319815260040160405180910390fd5b61275660007f0000000000000000000000000000000000000000000000000000000000000000610ae7565b6004805460ff1916905561276a8282614a2e565b506004805460ff191660011790556112b4610df4565b600b546001146127a65760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff16156127d25760405160016238ddf760e01b0319815260040160405180910390fd5b6127fd60007f0000000000000000000000000000000000000000000000000000000000000000610ae7565b6004805460ff19169055306001600160a01b0382160361283057604051632f35253160e01b815260040160405180910390fd5b61283a3384612abf565b82111561285a5760405163327cbc9b60e21b815260040160405180910390fd5b612864838361679d565b61286e83836167e9565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316836001600160a01b0316036128d7576128d27f0000000000000000000000000000000000000000000000000000000000000000828461683c565b6128e2565b6128e28382846168a0565b6004805460ff19166001179055612395610df4565b600080600b546001146129205760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff161561294c5760405160016238ddf760e01b0319815260040160405180910390fd5b61297760007f0000000000000000000000000000000000000000000000000000000000000000610ae7565b6004805460ff1916905560001983146113948186612999826113875787615d87565b613191565b600b546001146129c45760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff16156129f05760405160016238ddf760e01b0319815260040160405180910390fd5b612a1b60007f0000000000000000000000000000000000000000000000000000000000000000610ae7565b6004805460ff1916905534600003612a4657604051637c946ed760e01b815260040160405180910390fd5b60405134815233907fe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c9060200160405180910390a26004805460ff19166001179055612a90610df4565b600454610100900460ff16612ab8576040516304564c7160e21b815260040160405180910390fd5b6001600b55565b6001600160a01b0391821660009081526020818152604080832093909416825291909152205490565b6001600160401b03831660009081526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187015460608088019190915284880154608080890191909152600389015460a0808a019190915260048a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681850152600160481b8804861681840152600160581b880490951690850152600160681b909504841695830195909552610140860191909152865192830187526007860154808216845260ff600160a01b918290048116998501999099529590980154978816958201959095529290950490931693810193909352610160820192909252612c72918590859061691e16565b949350505050565b606060206000526b10626574612d76302e302e3160305260606000f35b6004820154610100900460ff1615612cb75760048201805461ff00191690555b6001600160a01b038116600090815260028301602052604090205460ff16610b4c57600382018054600180820183556000928352602080842090920180546001600160a01b0386166001600160a01b031990911681179091558352600285019091526040909120805460ff191690911790555050565b600080806009841015612d5d576040516370cee4af60e11b815260096004820152602481018590526044016120a0565b6000612d7586866000818110610b6857610b6861923d565b5060f881901c94509050612d8d6009600187896192be565b612d96916192e8565b60c01c9250612db0612dab866009818a6192be565b61696f565b9150509250925092565b6001600160401b03821660009081526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187015460608088019190915284880154608080890191909152600389015460a0808a019190915260048a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681850152600160481b8804861681840152600160581b880490951690850152600160681b90950490931694820194909452610140850152855191820186526007850154808416835260ff600160a01b9182900481169884019890985294909701549182169481019490945291909104909216928101929092526101608101919091528190612f49816020015163ffffffff16151590565b612f7157604051636a2406a360e11b81526001600160401b03861660048201526024016120a0565b8515612fab57612fa8612f8d3383610160015160000151612abf565b612fa03384610160015160400151612abf565b83919061691e565b93505b836001600160801b0316600003612fd557604051630200e8a960e31b815260040160405180910390fd5b612fe8612fe185616a08565b82906161fa565b60408051610100810182523381526001600160401b03891660208201526001600160801b0393841696509190921693506000918101426001600160801b03168152602001858152602001848152602001836101600151600001516001600160a01b03168152602001836101600151604001516001600160a01b0316815260200161307187616a08565b600f0b9052905061308181616a1e565b505061016082015160408082015191518151878152602081018790526001600160801b038916928101929092526001600160a01b039283169216906001600160401b038916907ffdffeca751f0dcaab75531cb813c12bbfd56ee3e964cc471d7ef43932402ee18906060015b60405180910390a45050935093915050565b60008080600984101561312f576040516370cee4af60e11b815260096004820152602481018590526044016120a0565b6004858560008181106131445761314461923d565b909101356001600160f81b03191690911c60f81c935061316a90506009600186886192be565b613173916192e8565b60c01c9150613188612dab85600981896192be565b90509250925092565b60008084156131ca57336000908152600a602090815260408083206001600160401b03881684529091529020546001600160801b031692505b826001600160801b03166000036131f457604051630200e8a960e31b815260040160405180910390fd5b600060086000866001600160401b03166001600160401b03168152602001908152602001600020604051806101800160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900463ffffffff1663ffffffff1663ffffffff1681526020016000820160079054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820154815260200160028201548152602001600382015481526020016004820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016004820160109054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160109054906101000a9004600f0b600f0b600f0b8152602001600682016040518060e00160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900461ffff1661ffff1661ffff1681526020016000820160059054906101000a900461ffff1661ffff1661ffff1681526020016000820160079054906101000a900461ffff1661ffff1661ffff1681526020016000820160099054906101000a900461ffff1661ffff1661ffff16815260200160008201600b9054906101000a900461ffff1661ffff1661ffff16815260200160008201600d9054906101000a900463ffffffff1663ffffffff1663ffffffff16815250508152602001600782016040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff1681525050815250509050613519816020015163ffffffff16151590565b61354157604051636a2406a360e11b81526001600160401b03861660048201526024016120a0565b61355661354d85616a08565b612fe190619316565b60408051610100810182523381526001600160401b03891660208201526001600160801b0393841696509190921693506000918101426001600160801b03168152602001858152602001848152602001836101600151600001516001600160a01b03168152602001836101600151604001516001600160a01b031681526020016135df87616a08565b6135e890619316565b600f0b905290506135f881616a1e565b505061016082015160408082015191518151878152602081018790526001600160801b038916928101929092526001600160a01b039283169216906001600160401b038916907ffe322c782fa8cb650f7deaac661d6e7aacbaa8034eae3b8c3afd1490bed1be1e906060016130ed565b60008060008060006004878760008181106136855761368561923d565b909101356001600160f81b03191690911c60f81c95506136ab905060096001888a6192be565b6136b4916192e8565b60c01c93506000878760098181106136ce576136ce61923d565b919091013560f81c91506136ea9050612dab82600a8a8c6192be565b935061370d8860ff831689613700600182619269565b92612dab939291906192be565b9250878761371c600182619269565b81811061372b5761372b61923d565b9050013560f81c60f81b60f81c9150509295509295909350565b60008060008084604001516001600160801b03166000036137795760405163af458c0760e01b815260040160405180910390fd5b60006008600087602001516001600160401b03166001600160401b031681526020019081526020016000209050613aa281604051806101800160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900463ffffffff1663ffffffff1663ffffffff1681526020016000820160079054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820154815260200160028201548152602001600382015481526020016004820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016004820160109054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160109054906101000a9004600f0b600f0b600f0b8152602001600682016040518060e00160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900461ffff1661ffff1661ffff1681526020016000820160059054906101000a900461ffff1661ffff1661ffff1681526020016000820160079054906101000a900461ffff1661ffff1661ffff1681526020016000820160099054906101000a900461ffff1661ffff1661ffff16815260200160008201600b9054906101000a900461ffff1661ffff1661ffff16815260200160008201600d9054906101000a900463ffffffff1663ffffffff1663ffffffff16815250508152602001600782016040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff1681525050815250506020015163ffffffff16151590565b613ad0576020860151604051636a2406a360e11b81526001600160401b0390911660048201526024016120a0565b6080860151600d805460ff9092161560ff199092169190911790558054600160381b90046001600160a01b03163314613b18576006810154600160281b900461ffff16613b29565b6006810154600160581b900461ffff165b600f55600d5460ff16613b40578060030154613b46565b80600201545b601055600d5460ff16613b665760088101546001600160a01b0316613b75565b60078101546001600160a01b03165b600d80546001600160a01b039290921661010002610100600160a81b03198316811790915560ff908116911617613bb95760078101546001600160a01b0316613bc8565b60088101546001600160a01b03165b600e80546001600160a01b0319166001600160a01b03929092169190911790556040805161014081019091526006820154600281900b606083019081526301000000820461ffff9081166080850152600160281b8304811660a0850152600160381b8304811660c0850152600160481b8304811660e0850152600160581b830416610100840152600160681b90910463ffffffff16610120830152600091908190613c7290616aa5565b81526020018360060160000160099054906101000a900461ffff1661ffff16815260200160008152509050613ce06040518060e00160405280600060020b81526020016000815260200160008152602001600081526020016000815260200160008152602001600081525090565b6000806000613cf28b6020015161628f565b60408801819052600d549295509093509150600090613d3a90339060ff16613d275760088901546001600160a01b0316612abf565b60078901546001600160a01b0316612abf565b90508b6000015160ff16600114613d5e578b604001516001600160801b0316613d60565b805b600d54909a50613d9f9060ff16613d85576008880154600160a01b900460ff16613d95565b6007880154600160a01b900460ff165b8b9060ff16616ab4565b99506040518060e001604052808460020b81526020018581526020018b8152602001600081526020018860040160109054906101000a90046001600160801b03166001600160801b031681526020016000815260200160008152509450505050508160400151600003613e255760405163398b36db60e01b815260040160405180910390fd5b600d5460009081908190819081908190819060ff1615613e7d576020880151613e4f908a90616acb565b60808a0151909850909550613e7690613e7089670de0b6b3a7640000619269565b90616b0b565b9150613eac565b6020880151613e8d908a90616acb565b60808a01518b51929950909650613ea991613e70908a90619269565b91505b8954600160381b90046001600160a01b03163314613ecb576000613efa565b600f5460048b015461271091613ef091600160801b90046001600160801b031661933c565b613efa9190619371565b925082600003613f3d57612710600d60020154838a6040015111613f22578960400151613f24565b835b613f2e919061933c565b613f389190619371565b613f40565b60005b606089018190526080890151613f569190616b27565b6010558215613f73576080880151613f6f908490616b27565b6011555b8188604001511115613fdc576060880151613f8e9083619269565b9050613fa7886080015182616b2790919063ffffffff16565b613fb19088619385565b9550876060015181613fc39190619385565b88604001818151613fd49190619269565b905250614024565b87606001518860400151613ff09190619269565b9050614009886080015182616b2790919063ffffffff16565b6140139088619385565b604089018051600090915290965090505b600d5460ff1615614040576140398987616b3c565b935061404d565b61404a8987616b58565b93505b808860a00181815161405f9190619385565b90525061406c8486619269565b8860c00181815161407d9190619385565b905250505060608d0151600d546000916001600160801b0316908290819060ff16156140ce576140ae8b888b616b74565b91506140bb8b878a616b74565b90506140c78b89616ba6565b93506140f5565b6140d98b8a89616b74565b91506140e68b8988616b74565b90506140f28b87616ba6565b93505b600d5460ff1615801561410757508284115b156141255760405163a3869ab760e01b815260040160405180910390fd5b600d5460ff16801561413657508383115b156141545760405163a3869ab760e01b815260040160405180910390fd5b60088c015461416e908390600160a01b900460ff16616bc0565b60088d015490925061418b908290600160a01b900460ff16616bc0565b9050818112156141b857604051630424b42d60e31b815260048101839052602481018290526044016120a0565b629896806141c9856298968161933c565b6141d39190619371565b60208b01525050600d546000925082915060ff161561420f5750506007880154600889015460ff600160a01b928390048116929091041661422e565b50506008880154600789015460ff600160a01b92839004811692909104165b60a088015161423d9083616bd6565b60a089015260c08801516142519082616bef565b8860c001818152505050506142ad8d602001516142718860200151616c05565b602089015160808a0151600d5460ff1661428c576000614290565b6010545b600d5460ff166142a2576010546142a5565b60005b601154616c3d565b50600d5460a08701516142ce9161010090046001600160a01b031690616db5565b600e5460c08701516142e9916001600160a01b0316906167e9565b80156143a6576143197f000000000000000000000000000000000000000000000000000000000000000082616db5565b6040518181526001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000169030907f49e1443cb25e17cbebc50aa3e3a5a3df3ac334af852bc6f3e8d258558257bb119060200160405180910390a36143a66000307f000000000000000000000000000000000000000000000000000000000000000084616dfc565b600d60010160009054906101000a90046001600160a01b03166001600160a01b0316600d60000160019054906101000a90046001600160a01b03166001600160a01b03168e602001516001600160401b03167f6ad6899405e7539158789043be9745c5def4f806aeb268c3c788953ff4f3c01089602001518a60a001518b60c00151604051614448939291909283526020830191909152604082015260600190565b60405180910390a45050600d80546001600160a81b03191690555050600e80546001600160a01b0319169055506000600f819055601081905560115560209790970151604088015160a089015160c0909901519199909897509095509350505050565b60008060098310156144da576040516370cee4af60e11b815260096004820152602481018490526044016120a0565b6144e86009600185876192be565b6144f1916192e8565b60c01c9150614506612dab84600981886192be565b90509250929050565b600060086000846001600160401b03166001600160401b03168152602001908152602001600020905061483481604051806101800160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900463ffffffff1663ffffffff1663ffffffff1681526020016000820160079054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820154815260200160028201548152602001600382015481526020016004820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016004820160109054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160109054906101000a9004600f0b600f0b600f0b8152602001600682016040518060e00160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900461ffff1661ffff1661ffff1681526020016000820160059054906101000a900461ffff1661ffff1661ffff1681526020016000820160079054906101000a900461ffff1661ffff1661ffff1681526020016000820160099054906101000a900461ffff1661ffff1661ffff16815260200160008201600b9054906101000a900461ffff1661ffff1661ffff16815260200160008201600d9054906101000a900463ffffffff1663ffffffff1663ffffffff16815250508152602001600782016040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff1681525050815250506020015163ffffffff16151590565b61485c57604051636a2406a360e11b81526001600160401b03841660048201526024016120a0565b336000908152600a602090815260408083206001600160401b0387168452825280832081516101608101835281546001600160801b038082168352600160801b918290048116958301959095526001830154938201939093526002820154606082015260038201546080820152600482015460a0820152600582015460c0820152600682015460e0820152600782015480851661010083015292909204831661012083015260080154821661014082015291908416900361493057604051630200e8a960e31b815260040160405180910390fd5b80516001600160801b0380851691161015614969576040516326e66cc760e11b81526001600160401b03851660048201526024016120a0565b600061497d8561497886616a08565b616e46565b905061498884616a08565b6005840180546010906149a6908490600160801b9004600f0b61939d565b92506101000a8154816001600160801b030219169083600f0b6001600160801b03160217905550336001600160a01b0316856001600160401b03167fc37a962db40f0f2a72f4a9ee4760e142ff06e5fb57cb4f23f494cbec9718e60586604051614a1f91906001600160801b0391909116815260200190565b60405180910390a35050505050565b6001600160401b03821660009081526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187015460608088019190915284880154608080890191909152600389015460a0808a019190915260048a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681850152600160481b8804861681840152600160581b880490951690850152600160681b90950490931694820194909452610140850152855191820186526007850154808416835260ff600160a01b91829004811698840198909852978501549283169582019590955295900490931691840191909152610160820192909252614bb9906020015163ffffffff16151590565b614be157604051636a2406a360e11b81526001600160401b03851660048201526024016120a0565b336000908152600a602090815260408083206001600160401b0388168452825280832081516101608101835281546001600160801b038082168352600160801b9182900481169583019590955260018301549382019390935260028201546060820181905260038301546080830152600483015460a0830152600583015460c0830152600683015460e083015260078301548086166101008401529390930484166101208201526008909101548316610140820152429092169203614cc457604051630c47736b60e11b81526001600160401b03871660048201526024016120a0565b8181608001511115614cf45760405163a4093bbf60e01b81526001600160401b03871660048201526024016120a0565b614d0a86614d0187616a08565b61497890619316565b9350614d1585616a08565b600584018054601090614d33908490600160801b9004600f0b6193ec565b92506101000a8154816001600160801b030219169083600f0b6001600160801b03160217905550336001600160a01b0316866001600160401b03167f850fd333bb55261aab49c7ed91d737f7c21674d43968a564ede778e0735d856f87604051614dac91906001600160801b0391909116815260200190565b60405180910390a350505092915050565b6000808080808080808060358a14614df2576040516370cee4af60e11b815260356004820152602481018b90526044016120a0565b614e00600460018c8e6192be565b614e099161943c565b60e81c9850614e1c601860048c8e6192be565b614e2591619469565b60601c9750614e38601a60188c8e6192be565b614e419161949c565b60f01c9650614e54601c601a8c8e6192be565b614e5d9161949c565b60f01c9550614e70601e601c8c8e6192be565b614e799161949c565b60f01c9450614e8c6020601e8c8e6192be565b614e959161949c565b60f01c9350614ea8602260208c8e6192be565b614eb19161949c565b60f01c9250614ec4602560228c8e6192be565b614ecd9161943c565b60e81c9150614edf8a6025818e6192be565b614ee8916194ca565b60801c90509295985092959850929598565b6000816001600160801b0316600003614f2657604051634dfba02360e01b815260040160405180910390fd5b6000614f3a426001600160801b0316617275565b9050614ff06040805161018081018252600080825260208083018290528284018290526060808401839052608080850184905260a080860185905260c080870186905260e0808801879052610100880187905261012088018790528851908101895286815294850186905296840185905291830184905282018390528101829052928301529061014082019081526040805160808101825260008082526020828101829052928201819052606082015291015290565b6001600160a01b038b16604082015263ffffffff821660208201526001600160801b03841660c0820181905261502590616c05565b60020b815260408101516001600160a01b031615801590819061504a575061ffff8b16155b1561506e5760405163f6f4a38f60e01b815261ffff8c1660048201526024016120a0565b600062ffffff8e1615615081578d615085565b6005545b62ffffff81166000908152600760209081526040808320815160808101835281546001600160a01b03808216835260ff600160a01b9283900481168488015260019094015490811683860152049091166060820152610160880152805160e0810190915260028b900b8152929350909190810184615104576004615106565b8a5b61ffff1681526020018d61ffff1681526020018b61ffff1681526020018c61ffff1681526020018461513957600061513b565b8e5b61ffff1681526020018663ffffffff16815250905061515981617288565b5050610140840181905260068054600101908190556151798385836172b3565b965061549b60086000896001600160401b03166001600160401b03168152602001908152602001600020604051806101800160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900463ffffffff1663ffffffff1663ffffffff1681526020016000820160079054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820154815260200160028201548152602001600382015481526020016004820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016004820160109054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160109054906101000a9004600f0b600f0b600f0b8152602001600682016040518060e00160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900461ffff1661ffff1661ffff1681526020016000820160059054906101000a900461ffff1661ffff1661ffff1681526020016000820160079054906101000a900461ffff1661ffff1661ffff1681526020016000820160099054906101000a900461ffff1661ffff1661ffff16815260200160008201600b9054906101000a900461ffff1661ffff1661ffff16815260200160008201600d9054906101000a900463ffffffff1663ffffffff1663ffffffff16815250508152602001600782016040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff1681525050815250506020015163ffffffff16151590565b156154b957604051637a471e1360e11b815260040160405180910390fd5b8460086000896001600160401b03166001600160401b0316815260200190815260200160002060008201518160000160006101000a81548162ffffff021916908360020b62ffffff16021790555060208201518160000160036101000a81548163ffffffff021916908363ffffffff16021790555060408201518160000160076101000a8154816001600160a01b0302191690836001600160a01b03160217905550606082015181600101556080820151816002015560a0820151816003015560c08201518160040160006101000a8154816001600160801b0302191690836001600160801b0316021790555060e08201518160040160106101000a8154816001600160801b0302191690836001600160801b031602179055506101008201518160050160006101000a8154816001600160801b0302191690836001600160801b031602179055506101208201518160050160106101000a8154816001600160801b030219169083600f0b6001600160801b031602179055506101408201518160060160008201518160000160006101000a81548162ffffff021916908360020b62ffffff16021790555060208201518160000160036101000a81548161ffff021916908361ffff16021790555060408201518160000160056101000a81548161ffff021916908361ffff16021790555060608201518160000160076101000a81548161ffff021916908361ffff16021790555060808201518160000160096101000a81548161ffff021916908361ffff16021790555060a082015181600001600b6101000a81548161ffff021916908361ffff16021790555060c082015181600001600d6101000a81548163ffffffff021916908363ffffffff16021790555050506101608201518160070160008201518160000160006101000a8154816001600160a01b0302191690836001600160a01b0316021790555060208201518160000160146101000a81548160ff021916908360ff16021790555060408201518160010160006101000a8154816001600160a01b0302191690836001600160a01b0316021790555060608201518160010160146101000a81548160ff021916908360ff1602179055505050905050846101600151604001516001600160a01b0316856101600151600001516001600160a01b0316886001600160401b03167f7609f45e16378bb0782884719ba24d3bbc5ab6a373b9eacacc25c6143b87cf77878c60405161585c92919091151582526001600160801b0316602082015260400190565b60405180910390a45050505050509998505050505050505050565b600080602983146158a5576040516370cee4af60e11b815260296004820152602481018490526044016120a0565b6158b36015600185876192be565b6158bc91619469565b60601c91506158ce83601581876192be565b6158d791619469565b60601c90509250929050565b6000816001600160a01b0316836001600160a01b03160361591757604051633b0e2de560e21b815260040160405180910390fd5b506001600160a01b0380831660009081526009602090815260408083209385168352929052205462ffffff16801561596957604051633325fa7760e01b815262ffffff821660048201526024016120a0565b600080846001600160a01b031663313ce5676040518163ffffffff1660e01b8152600401602060405180830381865afa1580156159aa573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906159ce91906194f8565b846001600160a01b031663313ce5676040518163ffffffff1660e01b8152600401602060405180830381865afa158015615a0c573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190615a3091906194f8565b9092509050615a4560ff831660066012617329565b615a675760405163ca95039160e01b815260ff831660048201526024016120a0565b615a7760ff821660066012617329565b615a995760405163ca95039160e01b815260ff821660048201526024016120a0565b600580546001908101918290556001600160a01b0387811660008181526009602090815260408083208b8616808552908352818420805462ffffff191662ffffff8a16908117909155825160808101845286815260ff8c81168287018181528387018681528e841660608601818152878c5260078b529a899020955186549351908e166001600160a81b031994851617600160a01b9187168202178755915195909d0180549a5195909c169990911698909817929091169096021790965581519384529183019590955294975090927fc0c5df98a4ca87a321a33bf1277cf32d31a97b6ce14b9747382149b9e2631ea3910160405180910390a4505092915050565b600083836001818110615bb057615bb061923d565b919091013560f81c9150600290506000805b8360ff168114610b465760ff83169150868683818110615be457615be461923d565b919091013560f81c93505085831115615c15576040516380f63bd160e01b815260ff841660048201526024016120a0565b366000615c2760ff8616858a8c6192be565b9092509050615c45615c3c82600181866192be565b8963ffffffff16565b505080615c519061951b565b9050615bc2565b600381015415615c6a57615c6a619534565b60048101805461ff001916610100179055615c89600382016000618d3d565b600401805460ff19169055565b6000808080615ca6878787615d9d565b90506000811315615cf557925082615cc087338884616dfc565b6001600160a01b038616600090815260018801602052604081208054839290615cea908490619385565b90915550615d509050565b6000811215615d5057615d078161954a565b9150615d158733888561666b565b90935091508215615d50576001600160a01b038616600090815260018801602052604081208054859290615d4a908490619269565b90915550505b506001600160a01b03909416600090815260029095016020526040909420805460ff19169055939050565b610da283338484617336565b6000600160801b8210615d9957600080fd5b5090565b6001600160a01b038216600090815260018401602052604081205481615dc385856173bd565b9050615dcf8282619566565b9695505050505050565b60008061157e8360e00151615ded90619316565b84906161fa565b6000615dff82617288565b508251600685018054602086015160408701516060880151608089015160a08a015160c08b015162ffffff90981664ffffffffff1990961695909517630100000061ffff958616021768ffffffff00000000001916600160281b9385169390930268ffff00000000000000191692909217600160381b91841691909102176cffffffff0000000000000000001916600160481b9183169190910261ffff60581b191617600160581b91909216021763ffffffff60681b1916600160681b63ffffffff90931692909202919091179055905080610da257610da2619534565b615ee78484612c97565b615ef2838383615d7b565b50505050565b600080615f3e6040518060e00160405280600060020b81526020016000815260200160008152602001600081526020016000815260200160008152602001600081525090565b6000615f49896174a6565b9050615f5f615f578a61750c565b8a908761752b565b60020b83526020830152615f8b87615f7b578860600151615f81565b88602001515b879060ff16616ab4565b604083015260e08901516001600160801b03166080830152600080808080808c15615ff4576020880151615fc0908890616acb565b8097508196505050615fed8f60e001516001600160801b031687670de0b6b3a7640000613e709190619269565b9150616030565b6020880151616004908890616acb565b809650819750505061602d8f60e001516001600160801b0316878960000151613e709190619269565b91505b6127108f61014001516040015161ffff16838a6040015111616056578960400151616058565b835b616062919061933c565b61606c9190619371565b606089015260408801518210156160da57606088015161608c9083619269565b90506160a5886080015182616b2790919063ffffffff16565b6160af9087619385565b93508760600151816160c19190619385565b886040018181516160d29190619269565b905250616122565b876060015188604001516160ee9190619269565b9050616107886080015182616b2790919063ffffffff16565b6161119087619385565b604089018051600090915290945090505b8c15616139576161328785616b3c565b9250616146565b6161438785616b58565b92505b808860a0018181516161589190619385565b9052506161658386619269565b8860c0018181516161769190619385565b905250600091508190508c1561619f578d6020015160ff1691508d6060015160ff1690506161b4565b8d6060015160ff1691508d6020015160ff1690505b60a08801516161c39083616bd6565b60a089015260c08801516161d79082616bef565b60c08901819052604090980151979f979e50969c50505050505050505050505050565b600080600f83900b15611e435760008061621386616741565b9150915060008086600f0b131561625257506001600160801b03851661623c61138a8483617581565b945061624b61138a8383617581565b9350616285565b61625b86619316565b6001600160801b0316905061627361138a8483616b0b565b945061628261138a8383616b0b565b93505b5050509250929050565b6001600160401b03811660009081526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187015460608088019190915284880154608080890191909152600389015460a0808a019190915260048a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681850152600160481b8804861681840152600160581b880490951690850152600160681b90950490931694820194909452610140850152855191820186526007850154808416835260ff600160a01b91829004811698840198909852949097015491821694810194909452919091049092169281019290925261016081019190915281908190616420816020015163ffffffff16151590565b61644857604051636a2406a360e11b81526001600160401b03861660048201526024016120a0565b60c08101518151616462836001600160801b034216617596565b6001600160801b03909216955093509150600061647e866111ce565b905080156164a55760006164918361750c565b905061649e83828461752b565b9096509450505b50509193909250565b60008060006164c1858860050154900390565b905060006164d3858960060154900390565b90506164df8288616b0b565b93506164eb8188616b0b565b6005890187905560068901869055925061650484615d87565b6007890180546000906165219084906001600160801b03166195a5565b92506101000a8154816001600160801b0302191690836001600160801b0316021790555061654e83615d87565b600789018054601090616572908490600160801b90046001600160801b03166195a5565b92506101000a8154816001600160801b0302191690836001600160801b03160217905550505094509492505050565b6165ae6000338484616dfc565b6040518181526001600160a01b0383169033907f49e1443cb25e17cbebc50aa3e3a5a3df3ac334af852bc6f3e8d258558257bb11906020015b60405180910390a35050565b600080616604838660040154900390565b90506166108185616b0b565b60048601819055915061662282615d87565b60088601805460009061663f9084906001600160801b03166195a5565b92506101000a8154816001600160801b0302191690836001600160801b03160217905550509392505050565b6000806166788685612c97565b6001600160a01b03808616600090815260208881526040808320938816835292905220548381106166ea576001600160a01b03808716600090815260208981526040808320938916835292905290812080548695508592906166db908490619269565b90915550600092506167379050565b6001600160a01b03808716600090815260208981526040808320938916835292905290812080549294508492839290616724908490619269565b9091555061673490508385619269565b91505b5094509492505050565b600080600080616750856175cb565b915091506167738561016001516020015160ff1683616bef90919063ffffffff16565b93506167948561016001516060015160ff1682616bef90919063ffffffff16565b92505050915091565b6167aa600033848461666b565b50506040518181526001600160a01b0383169033907f0b0b821953e5545b71f2085833e4a8dfd0d99bbdff511898672ae8179a982df3906020016165e7565b6167f56000838361760f565b816001600160a01b03167f1c711eca8d0b694bbcb0a14462a7006222e721954b2c5ff798f606817eb110328260405161683091815260200190565b60405180910390a25050565b604051632e1a7d4d60e01b8152600481018290526001600160a01b03841690632e1a7d4d90602401600060405180830381600087803b15801561687e57600080fd5b505af1158015616892573d6000803e3d6000fd5b50505050610da28282617689565b600060405163a9059cbb60e01b6000528360045282602452602060006044600080895af13d15601f3d1160016000511416171691506000606052806040525080615ef25760405162461bcd60e51b815260206004820152600f60248201526e1514905394d1915497d19052531151608a1b60448201526064016120a0565b600080600061692c86616741565b9092509050600061693d8684616b27565b9050600061694b8684616b27565b905061696381831061695d5781615d87565b82615d87565b98975050505050505050565b600080838360008181106169855761698561923d565b919091013560f81c91506169db90506169a184600181886192be565b8080601f01602080910402602001604051908101604052809392919081815260200183838082843760009201919091525061771792505050565b60801c915060ff811615616a01576169f481600a6196b4565b6169fe90836196c3565b91505b5092915050565b600060016001607f1b03821115615d9957600080fd5b602081810180516001600160401b03908116600090815260088452604080822086516001600160a01b03168352600a8652818320945190931682529290935290822060048201546002830154600384015485949392616a90928492600160801b9092046001600160801b0316916164ae565b9094509250616a9e85617728565b5050915091565b60006113f38260000151617876565b600080616ac0836178a3565b939093029392505050565b600080616ae6838560000151866020015187604001516178bb565b9050616b028185600001518660200151876040015160006179cd565b91509250929050565b6000616b208383670de0b6b3a76400006179ea565b9392505050565b6000616b2083670de0b6b3a7640000846179ea565b6000616b208284600001518560200151866040015160006179cd565b6000616b20828460000151856020015186604001516000617a09565b6000612c7283838660000151616b9c8860200151612710670de0b6b3a7640000919091020490565b8860400151617a26565b6000616b2082846000015185602001518660400151617a43565b600080616bcc836178a3565b9093059392505050565b600080616be2836178a3565b9093046001019392505050565b600080616bfb836178a3565b9093049392505050565b600080616c1183617b6c565b90506000616c26670de111a6b7de4000617b6c565b9050616c3281836196f2565b612c72906001619720565b6001600160401b03871660009081526008602052604081206001600160801b034216616c688a6111ce565b92506001808410616ca5576005830154616c96906001600160801b03811690600160801b9004600f0b617d47565b6001600160801b031660058401555b825460028b810b91900b14616cc657825462ffffff191662ffffff8b161783555b60048301546001600160801b03168914616d0657616ce389615d87565b6004840180546001600160801b0319166001600160801b03929092169190911790555b6004830154600160801b90046001600160801b03168814616d4a57616d2a88615d87565b6004840180546001600160801b03928316600160801b0292169190911790555b82546301000000900463ffffffff168214616d6957616d698383617dcb565b616d77836002015488617df8565b60028401556003830154616d8b9087617df8565b60038401556001830154616d9f9086617df8565b8360010181905550505050979650505050505050565b616dc160008383617e04565b816001600160a01b03167f80b21748c787c52e87a6b222011e0a0ed0f9cc2015f0ced46748642dc62ee9f88260405161683091815260200190565b616e068483612c97565b6001600160a01b0380841660009081526020868152604080832093861683529290529081208054839290616e3b908490619385565b909155505050505050565b600080426001600160801b03169050600060086000866001600160401b03166001600160401b03168152602001908152602001600020604051806101800160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900463ffffffff1663ffffffff1663ffffffff1681526020016000820160079054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820154815260200160028201548152602001600382015481526020016004820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016004820160109054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160109054906101000a9004600f0b600f0b600f0b8152602001600682016040518060e00160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900461ffff1661ffff1661ffff1681526020016000820160059054906101000a900461ffff1661ffff1661ffff1681526020016000820160079054906101000a900461ffff1661ffff1661ffff1681526020016000820160099054906101000a900461ffff1661ffff1661ffff16815260200160008201600b9054906101000a900461ffff1661ffff1661ffff16815260200160008201600d9054906101000a900463ffffffff1663ffffffff1663ffffffff16815250508152602001600782016040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff16815250508152505090506000600a6000336001600160a01b03166001600160a01b031681526020019081526020016000206000876001600160401b03166001600160401b03168152602001908152602001600020905080600201546000036171d4576171c883617275565b63ffffffff1660028201555b80600301546000036171fa576171ee826101400151617e42565b63ffffffff1660038201555b6172218261010001516001600160801b03168360600151836165f39092919063ffffffff16565b93506172388361723087619316565b839190617e75565b805461725490600160801b90046001600160801b031686617d47565b81546001600160801b03918216600160801b02911617905550909392505050565b60006401000000008210615d9957600080fd5b6000606060008061729885617eb1565b91509150816172a957805181602001fd5b9094909350915050565b600083836172c25760006172c5565b60015b60405160e89290921b6001600160e81b031916602083015260f81b6001600160f81b031916602382015260e083901b6001600160e01b031916602482015260280160405160208183030381529060405261731e90619761565b60c01c949350505050565b6000612c7284848461807e565b60006040516323b872dd60e01b6000528460045283602452826044526020600060646000808a5af13d15601f3d1160016000511416171691506000606052806040525080610cbb5760405162461bcd60e51b81526020600482015260146024820152731514905394d1915497d19493d357d1905253115160621b60448201526064016120a0565b604080516001600160a01b0383811660248084019190915283518084039091018152604490920183526020820180516001600160e01b03166370a0823160e01b179052915160009283928392918716916174179190619798565b600060405180830381855afa9150503d8060008114617452576040519150601f19603f3d011682016040523d82523d6000602084013e617457565b606091505b509150915081158061746b57508051602014155b156174895760405163c52e3eff60e01b815260040160405180910390fd5b8080602001905181019061749d91906197b4565b95945050505050565b6174ca60405180606001604052806000815260200160008152602001600081525090565b60405180606001604052806174e3846101400151616aa5565b81526020018361014001516080015161ffff1681526020016175048461750c565b905292915050565b60006113f3826020015163ffffffff168361759690919063ffffffff16565b600080600061754286610140015160000151617876565b905061756b818761014001516080015161ffff168860c001516001600160801b0316888861808f565b925061757683616c05565b915050935093915050565b6000616b208383670de0b6b3a76400006181fc565b6000806175a7846101400151617e42565b63ffffffff169050808311156175c15760009150506113f3565b6169fe8382619269565b60008060006175d9846174a6565b90506175fb8460c001516001600160801b03168261822a90919063ffffffff16565b92506176078184616b3c565b915050915091565b6001600160a01b0382166000908152600184016020526040902054808211156176555760405163315276c960e01b815260048101829052602481018390526044016120a0565b61765f8484612c97565b6001600160a01b038316600090815260018501602052604081208054849290616e3b908490619269565b604080516000808252602082019092526001600160a01b0384169083906040516176b39190619798565b60006040518083038185875af1925050503d80600081146176f0576040519150601f19603f3d011682016040523d82523d6000602084013e6176f5565b606091505b5050905080610da2576040516375f4268360e01b815260040160405180910390fd5b602081015190516010036008021c90565b80516001600160a01b03166000908152600a60209081526040808320828501516001600160401b03168452909152812060e08301519091600f9190910b121561785857600061780442604080516101608101825285546001600160801b038181168352600160801b91829004811660208401526001880154938301939093526002870154606083015260038701546080830152600487015460a0830152600587015460c0830152600687015460e08301526007870154808416610100840152048216610120820152600886015482166101408201529116618244565b6020848101516001600160401b03166000908152600890915260409020600601549091506301000000900461ffff1681101561785657604051632688c6cb60e21b8152600481018290526024016120a0565b505b604082015160e083015161786d918391617e75565b610b4c82618256565b60008061788f670de0b6b3a7640000600285900b6197cd565b9050616b20670de111a6b7de4000826182d3565b60006178b0826012619269565b6113f390600a619852565b60008415612c725760006178d76178d28787616b27565b617b6c565b90506301e18559670de0b6b3a76400008481029190910490612710908602046000671bc16d674ec8000061790b838061933c565b6179159190619371565b90506000617923848361933c565b9050600061794384633b9aca00617939886182ff565b613e70919061933c565b90506000818361795b670de0b6b3a76400008a6197cd565b6179659190619720565b61796f91906196f2565b9050600061797c8261839b565b9050670de0b6b3a76400008113156179aa5760405163b11558df60e01b8152600481018290526024016120a0565b6179bc81670de0b6b3a7640000619566565b9d9c50505050505050505050505050565b6000615dcf8686612710670de0b6b3a764000088020486866183de565b828202811515841585830485141716617a0257600080fd5b0492915050565b6000615dcf8686612710670de0b6b3a764000088020486866184c1565b600080617a3686868686866183de565b9096039695505050505050565b6000806301e18559670de0b6b3a764000084020490506000612710670de0b6b3a7640000860204905086670de0b6b3a76400001015617a985760405163b11558df60e01b8152600481018890526024016120a0565b6000617aac88670de0b6b3a7640000619566565b90506000617ab9826185d5565b90506000617acf84633b9aca00617939886182ff565b90506000670de0b6b3a7640000617ae683856197cd565b617af091906196f2565b90506000671bc16d674ec80000617b07878061933c565b617b119190619371565b90506000670de0b6b3a7640000617b28898461933c565b617b3291906196f2565b90506000617b408285619566565b90506000617b4d82618669565b9050617b59818f616b0b565b9f9e505050505050505050505050505050565b6000808213617ba95760405162461bcd60e51b815260206004820152600960248201526815539111519253915160ba1b60448201526064016120a0565b60006060617bb684618812565b03609f8181039490941b90931c6c465772b2bbbb5f824b15207a3081018102606090811d6d0388eaa27412d5aca026815d636e018202811d6d0df99ac502031bf953eff472fdcc018202811d6d13cdffb29d51d99322bdff5f2211018202811d6d0a0f742023def783a307a986912e018202811d6d01920d8043ca89b5239253284e42018202811d6c0b7a86d7375468fac667a0a527016c29508e458543d8aa4df2abee7883018302821d6d0139601a2efabe717e604cbb4894018302821d6d02247f7a7b6594320649aa03aba1018302821d6c8c3f38e95a6b1ff2ab1c3b343619018302821d6d02384773bdf1ac5676facced60901901830290911d6cb9a025d814b29c212b8b1a07cd1901909102780a09507084cc699bb0e71ea869ffffffffffffffffffffffff190105711340daa0d5f769dba1915cef59f0815a5506027d0267a36c0c95b3975ab3ee5b203a7614a3f75373f047d803ae7b6687f2b393909302929092017d57115e47018c7177eebf7cd370a3356a1b7863008a5ae8028c72b88642840160ae1d92915050565b6040805160048152602481019091526020810180516001600160e01b0316631fff968160e01b17905260009081831260018114617d89578015617da957617dc3565b6000198419860301925084831280617da357825183602001fd5b50617dc3565b838501925084831260018103617dc157825183602001fd5b505b505092915050565b617dd481617275565b825463ffffffff9190911663010000000266ffffffff000000199091161790915550565b8181156113f357500190565b617e0e8383612c97565b6001600160a01b038216600090815260018401602052604081208054839290617e38908490619385565b9091555050505050565b60006113f38260c0015163ffffffff16617e66846060015161ffff16620151800290565b617e709190619385565b617275565b600183018290558254617e91906001600160801b031682617d47565b83546001600160801b0319166001600160801b0391909116179092555050565b60006060617ecb836080015161ffff1660646161a8617329565b617f2e57608083015160405161ffff90911660248201526000906327b67e7360e21b906044015b60408051601f198184030181529190526020810180516001600160e01b03166001600160e01b0319909316929092179091529094909350915050565b617f44836060015161ffff1660016101f4617329565b617f6f57606083015160405161ffff909116602482015260009063ae91902760e01b90604401617ef2565b8251620d89e860029190910b12617fa457825160405160029190910b60248201526000906345c3193d60e11b90604401617ef2565b610258836020015161ffff161115617fdd57602083015160405161ffff9091166024820152600090637a7f104160e11b90604401617ef2565b617ff3836040015161ffff1660016103e8617329565b61801e57604080840151905161ffff909116602482015260009063f6f4a38f60e01b90604401617ef2565b61803a8360a0015161ffff166000856040015161ffff16617329565b6180655760a083015160405161ffff909116602482015260009063f6f4a38f60e01b90604401617ef2565b5050604080516020810190915260008152600192909150565b600080828503848603021315612c72565b6000816000036180a057508261749d565b828211156180af57508461749d565b60408051606081018252878152602081018790529081018490526301e18559670de0b6b3a7640000808602829005919085020560006180ee82846188b0565b61810090670de0b6b3a7640000619269565b9050600061810d826182ff565b8551909150600090618120908b906188b0565b9050600061813c618135633b9aca008561933c565b83906182d3565b905060008061814b8789619269565b90506000618158826182ff565b6181618a6182ff565b61816b919061933c565b905060006181798383619269565b905060006181998c60200151612710670de0b6b3a7640000919091020490565b90506000671bc16d674ec800006181b0838061933c565b6181ba9190619371565b905060006181d06181cb8386616b0b565b618669565b8e519091506181df9082616b0b565b96505050505050506000617b598284616b0b90919063ffffffff16565b82820281151584158583048514171661821457600080fd5b6001826001830304018115150290509392505050565b6000616b20828460000151856020015186604001516178bb565b6000826040015182616b209190619269565b60a081015160c082015160e08301516020808501516001600160401b0316600090815260089091526040902061828b916188c5565b60008360e00151600f0b12156182b7576182a98284606001516167e9565b610da28184608001516167e9565b6182c5828460600151616db5565b610da2818460800151616db5565b6000616b20670de0b6b3a7640000836182eb86617b6c565b6182f591906197cd565b6181cb91906196f2565b60b581600160881b81106183185760409190911b9060801c5b600160481b811061832e5760209190911b9060401c5b600160281b81106183445760109190911b9060201c5b6301000000811061835a5760089190911b9060101c5b62010000010260121c80820401600190811c80830401811c80830401811c80830401811c80830401811c80830401811c80830401901c908190048111900390565b60006713a04bbdfdc9be88670de0b6b3a764000083020519600101816183c082618908565b671bc16d674ec80000670de0b6b3a764000090910205949350505050565b6000670de0b6b3a76400008611156184095760405163aaf3956f60e01b815260040160405180910390fd5b670de0b6b3a76400008603618429576184228286619720565b905061749d565b8560000361843857508061749d565b82156184a6576301e18558670de0b6b3a7640000840205600061845a826182ff565b670de0b6b3a7640000908702633b9aca0002819005915088900361847d816185d5565b905081810361848b8161839b565b670de0b6b3a7640000908a02058601945061749d9350505050565b50670de0b6b3a7640000858103850205810195945050505050565b600082156185b1576301e18558670de0b6b3a764000084020460006184e5826182ff565b670de0b6b3a7640000908702633b9aca000281900491508885010287900560008112156185255760405163aaf3956f60e01b815260040160405180910390fd5b670de0b6b3a764000081131561854e5760405163aaf3956f60e01b815260040160405180910390fd5b670de0b6b3a76400008103618569576000935050505061749d565b8060000361858457670de0b6b3a7640000935050505061749d565b61858d816185d5565b905081810161859b8161839b565b670de0b6b3a764000003945061749d9350505050565b84670de0b6b3a76400008388010205670de0b6b3a764000003905095945050505050565b60006706f05b59d3b2000082036185ee57506000919050565b670de0b6b3a76400008212618616576040516307a0212760e01b815260040160405180910390fd5b81600003618637576040516322ed598560e21b815260040160405180910390fd5b600282029150600061864883618a7d565b670de0b6b3a76400006713a04bbdfdc9be8890910205196001019392505050565b6000680248ce36a70cb26b3e19821361868457506000919050565b680755bf798b4a1bf1e582126186cb5760405162461bcd60e51b815260206004820152600c60248201526b4558505f4f564552464c4f5760a01b60448201526064016120a0565b6503782dace9d9604e83901b059150600060606bb17217f7d1cf79abc9e3b39884821b056001605f1b01901d6bb17217f7d1cf79abc9e3b39881029093036c240c330e9fb2d9cbaf0fd5aafb1981018102606090811d6d0277594991cfc85f6e2461837cd9018202811d6d1a521255e34f6a5061b25ef1c9c319018202811d6db1bbb201f443cf962f1a1d3db4a5018202811d6e02c72388d9f74f51a9331fed693f1419018202811d6e05180bb14799ab47a8a8cb2a527d57016d02d16720577bd19bf614176fe9ea6c10fe68e7fd37d0007b713f765084018402831d9081019084016d01d3967ed30fc4f89c02bab5708119010290911d6e0587f503bb6ea29d25fcb740196450019091026d360d7aeea093263ecc6e0ecb291760621b010574029d9dc38563c32e5c2f6dc192ee70ef65f9978af30260c3939093039290921c92915050565b600080821161884f5760405162461bcd60e51b815260206004820152600960248201526815539111519253915160ba1b60448201526064016120a0565b5060016001600160801b03821160071b82811c6001600160401b031060061b1782811c63ffffffff1060051b1782811c61ffff1060041b1782811c60ff10600390811b90911783811c600f1060021b1783811c909110821b1791821c111790565b6000616b2083670de0b6b3a7640000846181fc565b60048201546188e490600160801b90046001600160801b031682617d47565b600490920180546001600160801b03938416600160801b0293169290921790915550565b60008061891483618c9b565b9050671bc16d674ec80000670de0b6b3a764000080830291909105016ec097ce7bc90715b34b9f1000000000056000806189b261899761897d670de0b6b3a764000067025f0fe105a31400870205670b68df18e471fbff190186670de0b6b3a764000091020590565b6714a8454c19e1ac000185670de0b6b3a764000091020590565b670fc10e01578277ff190184670de0b6b3a764000091020590565b6703debd083b8c7c00019150670de0b6b3a7640000670de0cc3d15610000670157d8b2ecc70800858502839005670295d400ea3257ff190186028390050185028290056705310aa7d52130000185028290050184020591508167119000ab100ffc00670de0b6b3a76400008680020560001902030190506000618a3482618669565b9050670de0b6b3a76400008482020560008812801590618a5b5760018114618a6d57618a71565b81671bc16d674ec80000039750618a71565b8197505b50505050505050919050565b6000671bc16d674ec800008212618a9b575068056bc75e2d630fffff195b60008213618aaf575068056bc75e2d631000005b8015618aba57919050565b6000670de0b6b3a76400008312801590618adb5760018114618ae357618af1565b839150618af1565b83671bc16d674ec800000391505b506000618b0682671bc16d674ec80000618cd7565b905080600003618b29576040516307a0212760e01b815260040160405180910390fd5b6000618b3482617b6c565b90506000618b53618b4e671bc16d674ec7ffff1984618cec565b6182ff565b633b9aca000290506000618be782618b92670de0b6b3a7640000669f32752462a000830205670dc5527f642c20000185670de0b6b3a764000091020590565b670de0b6b3a764000001670de0b6b3a7640000618bc16703c1665c7aab200087670de0b6b3a764000091020590565b672005fe4f268ea000010205036709d028cc6f205fff19670de0b6b3a764000091020590565b905060005b6002811015618c64576000618c0083618908565b8790039050670de0b6b3a764000083800205196001016000618c2182618669565b9050670de0b6b3a764000085840205670de0b6b3a7640000670fa8cedfc2adddfa83020503670de0b6b3a764000084020585019450600184019350505050618bec565b670de0b6b3a76400008812801590618c835760018114618c8b57618a71565b829750618a71565b5050196001019695505050505050565b6000600160ff1b8203618cc157604051634d2d75b160e01b815260040160405180910390fd5b6000821215615d9957501960010190565b919050565b6000616b2083670de0b6b3a764000084618cfd565b6000616b208383670de0b6b3a76400005b828202811515841585830585141716618d1557600080fd5b0592915050565b5080546000825560020290600052602060002090810190610de59190618d5b565b5080546000825590600052602060002090810190610de59190618d81565b5b80821115615d995780546001600160a01b031916815560006001820155600201618d5c565b5b80821115615d995760008155600101618d82565b80356001600160401b0381168114618cd257600080fd5b600060208284031215618dbf57600080fd5b616b2082618d96565b60008060408385031215618ddb57600080fd5b618de483618d96565b915060208301356001600160801b0381168114618e0057600080fd5b809150509250929050565b60008060408385031215618e1e57600080fd5b618e2783618d96565b946020939093013593505050565b80356001600160a01b0381168114618cd257600080fd5b60008060408385031215618e5f57600080fd5b618e6883618e35565b915061450660208401618e35565b600060208284031215618e8857600080fd5b616b2082618e35565b600060208284031215618ea357600080fd5b813562ffffff81168114616b2057600080fd5b803561ffff81168114618cd257600080fd5b600080600080600080600060e0888a031215618ee357600080fd5b618eec88618d96565b9650618efa60208901618eb6565b9550618f0860408901618eb6565b9450618f1660608901618eb6565b9350618f2460808901618eb6565b9250618f3260a08901618eb6565b915060c08801358060020b8114618f4857600080fd5b8091505092959891949750929550565b60008060408385031215618f6b57600080fd5b618e2783618e35565b80358015158114618cd257600080fd5b600080600060608486031215618f9957600080fd5b618fa284618d96565b9250618fb060208501618f74565b9150604084013590509250925092565b60008060408385031215618fd357600080fd5b618fdc83618d96565b9150602083013580600f0b8114618e0057600080fd5b60028d900b815263ffffffff8c1660208201526001600160a01b038b166040820152606081018a90526080810189905260a081018890526001600160801b0387811660c083015286811660e083015285166101008201526102a0810161905e610120830186600f0b9052565b835160020b610140830152602084015161ffff90811661016084015260408501518116610180840152606085015181166101a0840152608085015181166101c084015260a0850151166101e083015260c084015163ffffffff1661020083015282516001600160a01b03908116610220840152602084015160ff90811661024085015260408501519091166102608401526060840151166102808301529d9c50505050505050505050505050565b60008060006060848603121561912157600080fd5b61912a84618d96565b95602085013595506040909401359392505050565b6000806000806080858703121561915557600080fd5b61915e85618d96565b935061916c60208601618f74565b93969395505050506040820135916060013590565b60008060006060848603121561919657600080fd5b61919f84618e35565b92506020840135915061318860408501618e35565b600080604083850312156191c757600080fd5b6191d083618e35565b915061450660208401618d96565b60005b838110156191f95781810151838201526020016191e1565b83811115615ef25750506000910152565b60208152600082518060208401526192298160408501602087016191de565b601f01601f19169190910160400192915050565b634e487b7160e01b600052603260045260246000fd5b634e487b7160e01b600052601160045260246000fd5b60008282101561927b5761927b619253565b500390565b634e487b7160e01b600052603160045260246000fd5b60006001600160801b03838116908316818110156192b6576192b6619253565b039392505050565b600080858511156192ce57600080fd5b838611156192db57600080fd5b5050820193919092039150565b6001600160c01b03198135818116916008851015617dc35760089490940360031b84901b1690921692915050565b600081600f0b60016001607f1b0319810361933357619333619253565b60000392915050565b600081600019048311821515161561935657619356619253565b500290565b634e487b7160e01b600052601260045260246000fd5b6000826193805761938061935b565b500490565b6000821982111561939857619398619253565b500190565b600081600f0b83600f0b600082128260016001607f1b03038213811516156193c7576193c7619253565b8260016001607f1b03190382128116156193e3576193e3619253565b50019392505050565b600081600f0b83600f0b600081128160016001607f1b03190183128115161561941757619417619253565b8160016001607f1b0301831381161561943257619432619253565b5090039392505050565b6001600160e81b03198135818116916003851015617dc357600394850390941b84901b1690921692915050565b6bffffffffffffffffffffffff198135818116916014851015617dc35760149490940360031b84901b1690921692915050565b6001600160f01b03198135818116916002851015617dc35760029490940360031b84901b1690921692915050565b6001600160801b03198135818116916010851015617dc35760109490940360031b84901b1690921692915050565b60006020828403121561950a57600080fd5b815160ff81168114616b2057600080fd5b60006001820161952d5761952d619253565b5060010190565b634e487b7160e01b600052600160045260246000fd5b6000600160ff1b820161955f5761955f619253565b5060000390565b60008083128015600160ff1b85018412161561958457619584619253565b6001600160ff1b038401831381161561959f5761959f619253565b50500390565b60006001600160801b038083168185168083038211156195c7576195c7619253565b01949350505050565b600181815b8085111561960b5781600019048211156195f1576195f1619253565b808516156195fe57918102915b93841c93908002906195d5565b509250929050565b600082619622575060016113f3565b8161962f575060006113f3565b8160018114619645576002811461964f5761966b565b60019150506113f3565b60ff84111561966057619660619253565b50506001821b6113f3565b5060208310610133831016604e8410600b841016171561968e575081810a6113f3565b61969883836195d0565b80600019048211156196ac576196ac619253565b029392505050565b6000616b2060ff841683619613565b60006001600160801b03808316818516818304811182151516156196e9576196e9619253565b02949350505050565b6000826197015761970161935b565b600160ff1b82146000198414161561971b5761971b619253565b500590565b600080821280156001600160ff1b038490038513161561974257619742619253565b600160ff1b839003841281161561975b5761975b619253565b50500190565b805160208201516001600160c01b031980821692919060088310156197905780818460080360031b1b83161693505b505050919050565b600082516197aa8184602087016191de565b9190910192915050565b6000602082840312156197c657600080fd5b5051919050565b60006001600160ff1b03818413828413808216868404861116156197f3576197f3619253565b600160ff1b600087128281168783058912161561981257619812619253565b6000871292508782058712848416161561982e5761982e619253565b8785058712818416161561984457619844619253565b505050929093029392505050565b6000616b20838361961356fea2646970667358221220e3a0636033c7b1ef67279787951e59e559e0674a14915bbe98af5ec4968d7afb64736f6c634300080d0033"
            .parse()
            .expect("invalid bytecode")
        });
    pub struct Hyper<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for Hyper<M> {
        fn clone(&self) -> Self {
            Hyper(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for Hyper<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for Hyper<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(Hyper))
                .field(&self.address())
                .finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> Hyper<M> {
        /// Creates a new contract instance with the specified `ethers`
        /// client at the given `Address`. The contract derefs to a `ethers::Contract`
        /// object
        pub fn new<T: Into<::ethers::core::types::Address>>(
            address: T,
            client: ::std::sync::Arc<M>,
        ) -> Self {
            Self(::ethers::contract::Contract::new(
                address.into(),
                HYPER_ABI.clone(),
                client,
            ))
        }
        /// Constructs the general purpose `Deployer` instance based on the provided constructor arguments and sends it.
        /// Returns a new instance of a deployer that returns an instance of this contract after sending the transaction
        ///
        /// Notes:
        /// 1. If there are no constructor arguments, you should pass `()` as the argument.
        /// 1. The default poll duration is 7 seconds.
        /// 1. The default number of confirmations is 1 block.
        ///
        ///
        /// # Example
        ///
        /// Generate contract bindings with `abigen!` and deploy a new contract instance.
        ///
        /// *Note*: this requires a `bytecode` and `abi` object in the `greeter.json` artifact.
        ///
        /// ```ignore
        /// # async fn deploy<M: ethers::providers::Middleware>(client: ::std::sync::Arc<M>) {
        ///     abigen!(Greeter,"../greeter.json");
        ///
        ///    let greeter_contract = Greeter::deploy(client, "Hello world!".to_string()).unwrap().send().await.unwrap();
        ///    let msg = greeter_contract.greet().call().await.unwrap();
        /// # }
        /// ```
        pub fn deploy<T: ::ethers::core::abi::Tokenize>(
            client: ::std::sync::Arc<M>,
            constructor_args: T,
        ) -> ::std::result::Result<
            ::ethers::contract::builders::ContractDeployer<M, Self>,
            ::ethers::contract::ContractError<M>,
        > {
            let factory = ::ethers::contract::ContractFactory::new(
                HYPER_ABI.clone(),
                HYPER_BYTECODE.clone().into(),
                client,
            );
            let deployer = factory.deploy(constructor_args)?;
            let deployer = ::ethers::contract::ContractDeployer::new(deployer);
            Ok(deployer)
        }
        ///Calls the contract's `VERSION` (0xffa1ad74) function
        pub fn version(&self) -> ::ethers::contract::builders::ContractCall<M, String> {
            self.0
                .method_hash([255, 161, 173, 116], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `WETH` (0xad5c4648) function
        pub fn weth(
            &self,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::Address> {
            self.0
                .method_hash([173, 92, 70, 72], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `__account__` (0xda31ee54) function
        pub fn account(&self) -> ::ethers::contract::builders::ContractCall<M, (bool, bool)> {
            self.0
                .method_hash([218, 49, 238, 84], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `allocate` (0x2c0f8903) function
        pub fn allocate(
            &self,
            pool_id: u64,
            amount: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<
            M,
            (::ethers::core::types::U256, ::ethers::core::types::U256),
        > {
            self.0
                .method_hash([44, 15, 137, 3], (pool_id, amount))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `changeParameters` (0x6a707efa) function
        pub fn change_parameters(
            &self,
            pool_id: u64,
            priority_fee: u16,
            fee: u16,
            volatility: u16,
            duration: u16,
            jit: u16,
            max_tick: i32,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash(
                    [106, 112, 126, 250],
                    (
                        pool_id,
                        priority_fee,
                        fee,
                        volatility,
                        duration,
                        jit,
                        max_tick,
                    ),
                )
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `claim` (0x8e26770f) function
        pub fn claim(
            &self,
            pool_id: u64,
            delta_asset: ::ethers::core::types::U256,
            delta_quote: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([142, 38, 119, 15], (pool_id, delta_asset, delta_quote))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `deposit` (0xd0e30db0) function
        pub fn deposit(&self) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([208, 227, 13, 176], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `draw` (0xad24d6a0) function
        pub fn draw(
            &self,
            token: ::ethers::core::types::Address,
            amount: ::ethers::core::types::U256,
            to: ::ethers::core::types::Address,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([173, 36, 214, 160], (token, amount, to))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `fund` (0x7b1837de) function
        pub fn fund(
            &self,
            token: ::ethers::core::types::Address,
            amount: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([123, 24, 55, 222], (token, amount))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getAmountOut` (0x7dae4890) function
        pub fn get_amount_out(
            &self,
            pool_id: u64,
            sell_asset: bool,
            amount_in: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([125, 174, 72, 144], (pool_id, sell_asset, amount_in))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getAmounts` (0x9e5e2e29) function
        pub fn get_amounts(
            &self,
            pool_id: u64,
        ) -> ::ethers::contract::builders::ContractCall<
            M,
            (::ethers::core::types::U256, ::ethers::core::types::U256),
        > {
            self.0
                .method_hash([158, 94, 46, 41], pool_id)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getBalance` (0xd4fac45d) function
        pub fn get_balance(
            &self,
            owner: ::ethers::core::types::Address,
            token: ::ethers::core::types::Address,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([212, 250, 196, 93], (owner, token))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getLatestPrice` (0x8c470b8f) function
        pub fn get_latest_price(
            &self,
            pool_id: u64,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([140, 71, 11, 143], pool_id)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getLiquidityDeltas` (0x8992f20a) function
        pub fn get_liquidity_deltas(
            &self,
            pool_id: u64,
            delta_liquidity: i128,
        ) -> ::ethers::contract::builders::ContractCall<M, (u128, u128)> {
            self.0
                .method_hash([137, 146, 242, 10], (pool_id, delta_liquidity))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getMaxLiquidity` (0xd6b7dec5) function
        pub fn get_max_liquidity(
            &self,
            pool_id: u64,
            delta_asset: ::ethers::core::types::U256,
            delta_quote: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<M, u128> {
            self.0
                .method_hash([214, 183, 222, 197], (pool_id, delta_asset, delta_quote))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getNetBalance` (0x4dc68a90) function
        pub fn get_net_balance(
            &self,
            token: ::ethers::core::types::Address,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::I256> {
            self.0
                .method_hash([77, 198, 138, 144], token)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getPairId` (0x3f92a339) function
        pub fn get_pair_id(
            &self,
            p0: ::ethers::core::types::Address,
            p1: ::ethers::core::types::Address,
        ) -> ::ethers::contract::builders::ContractCall<M, u32> {
            self.0
                .method_hash([63, 146, 163, 57], (p0, p1))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getPairNonce` (0x078888d6) function
        pub fn get_pair_nonce(
            &self,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([7, 136, 136, 214], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getPoolNonce` (0xfd2dbea1) function
        pub fn get_pool_nonce(
            &self,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([253, 45, 190, 161], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getReserve` (0xc9a396e9) function
        pub fn get_reserve(
            &self,
            token: ::ethers::core::types::Address,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([201, 163, 150, 233], token)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getTimePassed` (0x0242f403) function
        pub fn get_time_passed(
            &self,
            pool_id: u64,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([2, 66, 244, 3], pool_id)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getVirtualReserves` (0x5ef05b0c) function
        pub fn get_virtual_reserves(
            &self,
            pool_id: u64,
        ) -> ::ethers::contract::builders::ContractCall<M, (u128, u128)> {
            self.0
                .method_hash([94, 240, 91, 12], pool_id)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `pairs` (0x5e47663c) function
        pub fn pairs(
            &self,
            p0: u32,
        ) -> ::ethers::contract::builders::ContractCall<
            M,
            (
                ::ethers::core::types::Address,
                u8,
                ::ethers::core::types::Address,
                u8,
            ),
        > {
            self.0
                .method_hash([94, 71, 102, 60], p0)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `pools` (0x89a5f084) function
        pub fn pools(
            &self,
            p0: u64,
        ) -> ::ethers::contract::builders::ContractCall<
            M,
            (
                i32,
                u32,
                ::ethers::core::types::Address,
                ::ethers::core::types::U256,
                ::ethers::core::types::U256,
                ::ethers::core::types::U256,
                u128,
                u128,
                u128,
                i128,
                HyperCurve,
                HyperPair,
            ),
        > {
            self.0
                .method_hash([137, 165, 240, 132], p0)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `positions` (0xb68513ea) function
        pub fn positions(
            &self,
            p0: ::ethers::core::types::Address,
            p1: u64,
        ) -> ::ethers::contract::builders::ContractCall<
            M,
            (
                u128,
                u128,
                ::ethers::core::types::U256,
                ::ethers::core::types::U256,
                ::ethers::core::types::U256,
                ::ethers::core::types::U256,
                ::ethers::core::types::U256,
                ::ethers::core::types::U256,
                u128,
                u128,
                u128,
            ),
        > {
            self.0
                .method_hash([182, 133, 19, 234], (p0, p1))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `stake` (0x23135811) function
        pub fn stake(
            &self,
            pool_id: u64,
            delta_liquidity: u128,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([35, 19, 88, 17], (pool_id, delta_liquidity))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `swap` (0xa4c68d9d) function
        pub fn swap(
            &self,
            pool_id: u64,
            sell_asset: bool,
            amount: ::ethers::core::types::U256,
            limit: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<
            M,
            (::ethers::core::types::U256, ::ethers::core::types::U256),
        > {
            self.0
                .method_hash([164, 198, 141, 157], (pool_id, sell_asset, amount, limit))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `unallocate` (0xbcf78a5a) function
        pub fn unallocate(
            &self,
            pool_id: u64,
            amount: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<
            M,
            (::ethers::core::types::U256, ::ethers::core::types::U256),
        > {
            self.0
                .method_hash([188, 247, 138, 90], (pool_id, amount))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `unstake` (0xa81262d5) function
        pub fn unstake(
            &self,
            pool_id: u64,
            delta_liquidity: u128,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([168, 18, 98, 213], (pool_id, delta_liquidity))
                .expect("method not found (this should never happen)")
        }
        ///Gets the contract's `Allocate` event
        pub fn allocate_filter(&self) -> ::ethers::contract::builders::Event<M, AllocateFilter> {
            self.0.event()
        }
        ///Gets the contract's `ChangeParameters` event
        pub fn change_parameters_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, ChangeParametersFilter> {
            self.0.event()
        }
        ///Gets the contract's `Collect` event
        pub fn collect_filter(&self) -> ::ethers::contract::builders::Event<M, CollectFilter> {
            self.0.event()
        }
        ///Gets the contract's `CreatePair` event
        pub fn create_pair_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, CreatePairFilter> {
            self.0.event()
        }
        ///Gets the contract's `CreatePool` event
        pub fn create_pool_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, CreatePoolFilter> {
            self.0.event()
        }
        ///Gets the contract's `DecreaseReserveBalance` event
        pub fn decrease_reserve_balance_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, DecreaseReserveBalanceFilter> {
            self.0.event()
        }
        ///Gets the contract's `DecreaseUserBalance` event
        pub fn decrease_user_balance_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, DecreaseUserBalanceFilter> {
            self.0.event()
        }
        ///Gets the contract's `Deposit` event
        pub fn deposit_filter(&self) -> ::ethers::contract::builders::Event<M, DepositFilter> {
            self.0.event()
        }
        ///Gets the contract's `IncreaseReserveBalance` event
        pub fn increase_reserve_balance_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, IncreaseReserveBalanceFilter> {
            self.0.event()
        }
        ///Gets the contract's `IncreaseUserBalance` event
        pub fn increase_user_balance_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, IncreaseUserBalanceFilter> {
            self.0.event()
        }
        ///Gets the contract's `Stake` event
        pub fn stake_filter(&self) -> ::ethers::contract::builders::Event<M, StakeFilter> {
            self.0.event()
        }
        ///Gets the contract's `Swap` event
        pub fn swap_filter(&self) -> ::ethers::contract::builders::Event<M, SwapFilter> {
            self.0.event()
        }
        ///Gets the contract's `Unallocate` event
        pub fn unallocate_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, UnallocateFilter> {
            self.0.event()
        }
        ///Gets the contract's `Unstake` event
        pub fn unstake_filter(&self) -> ::ethers::contract::builders::Event<M, UnstakeFilter> {
            self.0.event()
        }
        /// Returns an [`Event`](#ethers_contract::builders::Event) builder for all events of this contract
        pub fn events(&self) -> ::ethers::contract::builders::Event<M, HyperEvents> {
            self.0.event_with_filter(Default::default())
        }
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>> for Hyper<M> {
        fn from(contract: ::ethers::contract::Contract<M>) -> Self {
            Self::new(contract.address(), contract.client())
        }
    }
    ///Custom Error type `DrawBalance` with signature `DrawBalance()` and selector `0xc9f2f26c`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "DrawBalance", abi = "DrawBalance()")]
    pub struct DrawBalance;
    ///Custom Error type `EtherTransferFail` with signature `EtherTransferFail()` and selector `0x75f42683`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "EtherTransferFail", abi = "EtherTransferFail()")]
    pub struct EtherTransferFail;
    ///Custom Error type `Infinity` with signature `Infinity()` and selector `0x07a02127`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "Infinity", abi = "Infinity()")]
    pub struct Infinity;
    ///Custom Error type `InsufficientPosition` with signature `InsufficientPosition(uint64)` and selector `0x4dccd98e`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "InsufficientPosition", abi = "InsufficientPosition(uint64)")]
    pub struct InsufficientPosition {
        pub pool_id: u64,
    }
    ///Custom Error type `InsufficientReserve` with signature `InsufficientReserve(uint256,uint256)` and selector `0x315276c9`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(
        name = "InsufficientReserve",
        abi = "InsufficientReserve(uint256,uint256)"
    )]
    pub struct InsufficientReserve {
        pub amount: ::ethers::core::types::U256,
        pub delta: ::ethers::core::types::U256,
    }
    ///Custom Error type `InvalidBalance` with signature `InvalidBalance()` and selector `0xc52e3eff`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "InvalidBalance", abi = "InvalidBalance()")]
    pub struct InvalidBalance;
    ///Custom Error type `InvalidBytesLength` with signature `InvalidBytesLength(uint256,uint256)` and selector `0xe19dc95e`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(
        name = "InvalidBytesLength",
        abi = "InvalidBytesLength(uint256,uint256)"
    )]
    pub struct InvalidBytesLength {
        pub expected: ::ethers::core::types::U256,
        pub length: ::ethers::core::types::U256,
    }
    ///Custom Error type `InvalidDecimals` with signature `InvalidDecimals(uint8)` and selector `0xca950391`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "InvalidDecimals", abi = "InvalidDecimals(uint8)")]
    pub struct InvalidDecimals {
        pub decimals: u8,
    }
    ///Custom Error type `InvalidFee` with signature `InvalidFee(uint16)` and selector `0xf6f4a38f`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "InvalidFee", abi = "InvalidFee(uint16)")]
    pub struct InvalidFee {
        pub fee: u16,
    }
    ///Custom Error type `InvalidInstruction` with signature `InvalidInstruction()` and selector `0xd8c48f68`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "InvalidInstruction", abi = "InvalidInstruction()")]
    pub struct InvalidInstruction;
    ///Custom Error type `InvalidInvariant` with signature `InvalidInvariant(int256,int256)` and selector `0x2125a168`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "InvalidInvariant", abi = "InvalidInvariant(int256,int256)")]
    pub struct InvalidInvariant {
        pub prev: ::ethers::core::types::I256,
        pub next: ::ethers::core::types::I256,
    }
    ///Custom Error type `InvalidJump` with signature `InvalidJump(uint256)` and selector `0x80f63bd1`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "InvalidJump", abi = "InvalidJump(uint256)")]
    pub struct InvalidJump {
        pub pointer: ::ethers::core::types::U256,
    }
    ///Custom Error type `InvalidReentrancy` with signature `InvalidReentrancy()` and selector `0xffc72209`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "InvalidReentrancy", abi = "InvalidReentrancy()")]
    pub struct InvalidReentrancy;
    ///Custom Error type `InvalidReward` with signature `InvalidReward()` and selector `0x28829e82`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "InvalidReward", abi = "InvalidReward()")]
    pub struct InvalidReward;
    ///Custom Error type `InvalidSettlement` with signature `InvalidSettlement()` and selector `0x115931c4`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "InvalidSettlement", abi = "InvalidSettlement()")]
    pub struct InvalidSettlement;
    ///Custom Error type `InvalidTransfer` with signature `InvalidTransfer()` and selector `0x2f352531`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "InvalidTransfer", abi = "InvalidTransfer()")]
    pub struct InvalidTransfer;
    ///Custom Error type `JitLiquidity` with signature `JitLiquidity(uint256)` and selector `0x9a231b2c`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "JitLiquidity", abi = "JitLiquidity(uint256)")]
    pub struct JitLiquidity {
        pub distance: ::ethers::core::types::U256,
    }
    ///Custom Error type `Min` with signature `Min()` and selector `0x4d2d75b1`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "Min", abi = "Min()")]
    pub struct Min;
    ///Custom Error type `NegativeInfinity` with signature `NegativeInfinity()` and selector `0x8bb56614`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "NegativeInfinity", abi = "NegativeInfinity()")]
    pub struct NegativeInfinity;
    ///Custom Error type `NonExistentPool` with signature `NonExistentPool(uint64)` and selector `0xd4480d46`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "NonExistentPool", abi = "NonExistentPool(uint64)")]
    pub struct NonExistentPool {
        pub pool_id: u64,
    }
    ///Custom Error type `NonExistentPosition` with signature `NonExistentPosition(address,uint64)` and selector `0x5f3605b6`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(
        name = "NonExistentPosition",
        abi = "NonExistentPosition(address,uint64)"
    )]
    pub struct NonExistentPosition {
        pub owner: ::ethers::core::types::Address,
        pub pool_id: u64,
    }
    ///Custom Error type `NotController` with signature `NotController()` and selector `0x23019e67`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "NotController", abi = "NotController()")]
    pub struct NotController;
    ///Custom Error type `NotPreparedToSettle` with signature `NotPreparedToSettle()` and selector `0xf7cede50`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "NotPreparedToSettle", abi = "NotPreparedToSettle()")]
    pub struct NotPreparedToSettle;
    ///Custom Error type `OOB` with signature `OOB()` and selector `0xaaf3956f`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "OOB", abi = "OOB()")]
    pub struct OOB;
    ///Custom Error type `OverflowWad` with signature `OverflowWad(int256)` and selector `0xb11558df`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "OverflowWad", abi = "OverflowWad(int256)")]
    pub struct OverflowWad {
        pub wad: ::ethers::core::types::I256,
    }
    ///Custom Error type `PairExists` with signature `PairExists(uint24)` and selector `0x3325fa77`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "PairExists", abi = "PairExists(uint24)")]
    pub struct PairExists {
        pub pair_id: u32,
    }
    ///Custom Error type `PoolExists` with signature `PoolExists()` and selector `0xf48e3c26`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "PoolExists", abi = "PoolExists()")]
    pub struct PoolExists;
    ///Custom Error type `PoolExpired` with signature `PoolExpired()` and selector `0x398b36db`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "PoolExpired", abi = "PoolExpired()")]
    pub struct PoolExpired;
    ///Custom Error type `PositionNotStaked` with signature `PositionNotStaked(uint96)` and selector `0x188ee6d6`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "PositionNotStaked", abi = "PositionNotStaked(uint96)")]
    pub struct PositionNotStaked {
        pub position_id: u128,
    }
    ///Custom Error type `SameTokenError` with signature `SameTokenError()` and selector `0xec38b794`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "SameTokenError", abi = "SameTokenError()")]
    pub struct SameTokenError;
    ///Custom Error type `StakeNotMature` with signature `StakeNotMature(uint64)` and selector `0xa4093bbf`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "StakeNotMature", abi = "StakeNotMature(uint64)")]
    pub struct StakeNotMature {
        pub pool_id: u64,
    }
    ///Custom Error type `SwapLimitReached` with signature `SwapLimitReached()` and selector `0xa3869ab7`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "SwapLimitReached", abi = "SwapLimitReached()")]
    pub struct SwapLimitReached;
    ///Custom Error type `ZeroInput` with signature `ZeroInput()` and selector `0xaf458c07`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "ZeroInput", abi = "ZeroInput()")]
    pub struct ZeroInput;
    ///Custom Error type `ZeroLiquidity` with signature `ZeroLiquidity()` and selector `0x10074548`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "ZeroLiquidity", abi = "ZeroLiquidity()")]
    pub struct ZeroLiquidity;
    ///Custom Error type `ZeroPrice` with signature `ZeroPrice()` and selector `0x4dfba023`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "ZeroPrice", abi = "ZeroPrice()")]
    pub struct ZeroPrice;
    ///Custom Error type `ZeroValue` with signature `ZeroValue()` and selector `0x7c946ed7`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "ZeroValue", abi = "ZeroValue()")]
    pub struct ZeroValue;
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum HyperErrors {
        DrawBalance(DrawBalance),
        EtherTransferFail(EtherTransferFail),
        Infinity(Infinity),
        InsufficientPosition(InsufficientPosition),
        InsufficientReserve(InsufficientReserve),
        InvalidBalance(InvalidBalance),
        InvalidBytesLength(InvalidBytesLength),
        InvalidDecimals(InvalidDecimals),
        InvalidFee(InvalidFee),
        InvalidInstruction(InvalidInstruction),
        InvalidInvariant(InvalidInvariant),
        InvalidJump(InvalidJump),
        InvalidReentrancy(InvalidReentrancy),
        InvalidReward(InvalidReward),
        InvalidSettlement(InvalidSettlement),
        InvalidTransfer(InvalidTransfer),
        JitLiquidity(JitLiquidity),
        Min(Min),
        NegativeInfinity(NegativeInfinity),
        NonExistentPool(NonExistentPool),
        NonExistentPosition(NonExistentPosition),
        NotController(NotController),
        NotPreparedToSettle(NotPreparedToSettle),
        OOB(OOB),
        OverflowWad(OverflowWad),
        PairExists(PairExists),
        PoolExists(PoolExists),
        PoolExpired(PoolExpired),
        PositionNotStaked(PositionNotStaked),
        SameTokenError(SameTokenError),
        StakeNotMature(StakeNotMature),
        SwapLimitReached(SwapLimitReached),
        ZeroInput(ZeroInput),
        ZeroLiquidity(ZeroLiquidity),
        ZeroPrice(ZeroPrice),
        ZeroValue(ZeroValue),
    }
    impl ::ethers::core::abi::AbiDecode for HyperErrors {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded) =
                <DrawBalance as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::DrawBalance(decoded));
            }
            if let Ok(decoded) =
                <EtherTransferFail as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::EtherTransferFail(decoded));
            }
            if let Ok(decoded) = <Infinity as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::Infinity(decoded));
            }
            if let Ok(decoded) =
                <InsufficientPosition as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::InsufficientPosition(decoded));
            }
            if let Ok(decoded) =
                <InsufficientReserve as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::InsufficientReserve(decoded));
            }
            if let Ok(decoded) =
                <InvalidBalance as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::InvalidBalance(decoded));
            }
            if let Ok(decoded) =
                <InvalidBytesLength as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::InvalidBytesLength(decoded));
            }
            if let Ok(decoded) =
                <InvalidDecimals as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::InvalidDecimals(decoded));
            }
            if let Ok(decoded) =
                <InvalidFee as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::InvalidFee(decoded));
            }
            if let Ok(decoded) =
                <InvalidInstruction as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::InvalidInstruction(decoded));
            }
            if let Ok(decoded) =
                <InvalidInvariant as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::InvalidInvariant(decoded));
            }
            if let Ok(decoded) =
                <InvalidJump as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::InvalidJump(decoded));
            }
            if let Ok(decoded) =
                <InvalidReentrancy as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::InvalidReentrancy(decoded));
            }
            if let Ok(decoded) =
                <InvalidReward as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::InvalidReward(decoded));
            }
            if let Ok(decoded) =
                <InvalidSettlement as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::InvalidSettlement(decoded));
            }
            if let Ok(decoded) =
                <InvalidTransfer as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::InvalidTransfer(decoded));
            }
            if let Ok(decoded) =
                <JitLiquidity as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::JitLiquidity(decoded));
            }
            if let Ok(decoded) = <Min as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperErrors::Min(decoded));
            }
            if let Ok(decoded) =
                <NegativeInfinity as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::NegativeInfinity(decoded));
            }
            if let Ok(decoded) =
                <NonExistentPool as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::NonExistentPool(decoded));
            }
            if let Ok(decoded) =
                <NonExistentPosition as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::NonExistentPosition(decoded));
            }
            if let Ok(decoded) =
                <NotController as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::NotController(decoded));
            }
            if let Ok(decoded) =
                <NotPreparedToSettle as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::NotPreparedToSettle(decoded));
            }
            if let Ok(decoded) = <OOB as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperErrors::OOB(decoded));
            }
            if let Ok(decoded) =
                <OverflowWad as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::OverflowWad(decoded));
            }
            if let Ok(decoded) =
                <PairExists as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::PairExists(decoded));
            }
            if let Ok(decoded) =
                <PoolExists as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::PoolExists(decoded));
            }
            if let Ok(decoded) =
                <PoolExpired as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::PoolExpired(decoded));
            }
            if let Ok(decoded) =
                <PositionNotStaked as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::PositionNotStaked(decoded));
            }
            if let Ok(decoded) =
                <SameTokenError as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::SameTokenError(decoded));
            }
            if let Ok(decoded) =
                <StakeNotMature as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::StakeNotMature(decoded));
            }
            if let Ok(decoded) =
                <SwapLimitReached as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::SwapLimitReached(decoded));
            }
            if let Ok(decoded) =
                <ZeroInput as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::ZeroInput(decoded));
            }
            if let Ok(decoded) =
                <ZeroLiquidity as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::ZeroLiquidity(decoded));
            }
            if let Ok(decoded) =
                <ZeroPrice as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::ZeroPrice(decoded));
            }
            if let Ok(decoded) =
                <ZeroValue as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperErrors::ZeroValue(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for HyperErrors {
        fn encode(self) -> Vec<u8> {
            match self {
                HyperErrors::DrawBalance(element) => element.encode(),
                HyperErrors::EtherTransferFail(element) => element.encode(),
                HyperErrors::Infinity(element) => element.encode(),
                HyperErrors::InsufficientPosition(element) => element.encode(),
                HyperErrors::InsufficientReserve(element) => element.encode(),
                HyperErrors::InvalidBalance(element) => element.encode(),
                HyperErrors::InvalidBytesLength(element) => element.encode(),
                HyperErrors::InvalidDecimals(element) => element.encode(),
                HyperErrors::InvalidFee(element) => element.encode(),
                HyperErrors::InvalidInstruction(element) => element.encode(),
                HyperErrors::InvalidInvariant(element) => element.encode(),
                HyperErrors::InvalidJump(element) => element.encode(),
                HyperErrors::InvalidReentrancy(element) => element.encode(),
                HyperErrors::InvalidReward(element) => element.encode(),
                HyperErrors::InvalidSettlement(element) => element.encode(),
                HyperErrors::InvalidTransfer(element) => element.encode(),
                HyperErrors::JitLiquidity(element) => element.encode(),
                HyperErrors::Min(element) => element.encode(),
                HyperErrors::NegativeInfinity(element) => element.encode(),
                HyperErrors::NonExistentPool(element) => element.encode(),
                HyperErrors::NonExistentPosition(element) => element.encode(),
                HyperErrors::NotController(element) => element.encode(),
                HyperErrors::NotPreparedToSettle(element) => element.encode(),
                HyperErrors::OOB(element) => element.encode(),
                HyperErrors::OverflowWad(element) => element.encode(),
                HyperErrors::PairExists(element) => element.encode(),
                HyperErrors::PoolExists(element) => element.encode(),
                HyperErrors::PoolExpired(element) => element.encode(),
                HyperErrors::PositionNotStaked(element) => element.encode(),
                HyperErrors::SameTokenError(element) => element.encode(),
                HyperErrors::StakeNotMature(element) => element.encode(),
                HyperErrors::SwapLimitReached(element) => element.encode(),
                HyperErrors::ZeroInput(element) => element.encode(),
                HyperErrors::ZeroLiquidity(element) => element.encode(),
                HyperErrors::ZeroPrice(element) => element.encode(),
                HyperErrors::ZeroValue(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for HyperErrors {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                HyperErrors::DrawBalance(element) => element.fmt(f),
                HyperErrors::EtherTransferFail(element) => element.fmt(f),
                HyperErrors::Infinity(element) => element.fmt(f),
                HyperErrors::InsufficientPosition(element) => element.fmt(f),
                HyperErrors::InsufficientReserve(element) => element.fmt(f),
                HyperErrors::InvalidBalance(element) => element.fmt(f),
                HyperErrors::InvalidBytesLength(element) => element.fmt(f),
                HyperErrors::InvalidDecimals(element) => element.fmt(f),
                HyperErrors::InvalidFee(element) => element.fmt(f),
                HyperErrors::InvalidInstruction(element) => element.fmt(f),
                HyperErrors::InvalidInvariant(element) => element.fmt(f),
                HyperErrors::InvalidJump(element) => element.fmt(f),
                HyperErrors::InvalidReentrancy(element) => element.fmt(f),
                HyperErrors::InvalidReward(element) => element.fmt(f),
                HyperErrors::InvalidSettlement(element) => element.fmt(f),
                HyperErrors::InvalidTransfer(element) => element.fmt(f),
                HyperErrors::JitLiquidity(element) => element.fmt(f),
                HyperErrors::Min(element) => element.fmt(f),
                HyperErrors::NegativeInfinity(element) => element.fmt(f),
                HyperErrors::NonExistentPool(element) => element.fmt(f),
                HyperErrors::NonExistentPosition(element) => element.fmt(f),
                HyperErrors::NotController(element) => element.fmt(f),
                HyperErrors::NotPreparedToSettle(element) => element.fmt(f),
                HyperErrors::OOB(element) => element.fmt(f),
                HyperErrors::OverflowWad(element) => element.fmt(f),
                HyperErrors::PairExists(element) => element.fmt(f),
                HyperErrors::PoolExists(element) => element.fmt(f),
                HyperErrors::PoolExpired(element) => element.fmt(f),
                HyperErrors::PositionNotStaked(element) => element.fmt(f),
                HyperErrors::SameTokenError(element) => element.fmt(f),
                HyperErrors::StakeNotMature(element) => element.fmt(f),
                HyperErrors::SwapLimitReached(element) => element.fmt(f),
                HyperErrors::ZeroInput(element) => element.fmt(f),
                HyperErrors::ZeroLiquidity(element) => element.fmt(f),
                HyperErrors::ZeroPrice(element) => element.fmt(f),
                HyperErrors::ZeroValue(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<DrawBalance> for HyperErrors {
        fn from(var: DrawBalance) -> Self {
            HyperErrors::DrawBalance(var)
        }
    }
    impl ::std::convert::From<EtherTransferFail> for HyperErrors {
        fn from(var: EtherTransferFail) -> Self {
            HyperErrors::EtherTransferFail(var)
        }
    }
    impl ::std::convert::From<Infinity> for HyperErrors {
        fn from(var: Infinity) -> Self {
            HyperErrors::Infinity(var)
        }
    }
    impl ::std::convert::From<InsufficientPosition> for HyperErrors {
        fn from(var: InsufficientPosition) -> Self {
            HyperErrors::InsufficientPosition(var)
        }
    }
    impl ::std::convert::From<InsufficientReserve> for HyperErrors {
        fn from(var: InsufficientReserve) -> Self {
            HyperErrors::InsufficientReserve(var)
        }
    }
    impl ::std::convert::From<InvalidBalance> for HyperErrors {
        fn from(var: InvalidBalance) -> Self {
            HyperErrors::InvalidBalance(var)
        }
    }
    impl ::std::convert::From<InvalidBytesLength> for HyperErrors {
        fn from(var: InvalidBytesLength) -> Self {
            HyperErrors::InvalidBytesLength(var)
        }
    }
    impl ::std::convert::From<InvalidDecimals> for HyperErrors {
        fn from(var: InvalidDecimals) -> Self {
            HyperErrors::InvalidDecimals(var)
        }
    }
    impl ::std::convert::From<InvalidFee> for HyperErrors {
        fn from(var: InvalidFee) -> Self {
            HyperErrors::InvalidFee(var)
        }
    }
    impl ::std::convert::From<InvalidInstruction> for HyperErrors {
        fn from(var: InvalidInstruction) -> Self {
            HyperErrors::InvalidInstruction(var)
        }
    }
    impl ::std::convert::From<InvalidInvariant> for HyperErrors {
        fn from(var: InvalidInvariant) -> Self {
            HyperErrors::InvalidInvariant(var)
        }
    }
    impl ::std::convert::From<InvalidJump> for HyperErrors {
        fn from(var: InvalidJump) -> Self {
            HyperErrors::InvalidJump(var)
        }
    }
    impl ::std::convert::From<InvalidReentrancy> for HyperErrors {
        fn from(var: InvalidReentrancy) -> Self {
            HyperErrors::InvalidReentrancy(var)
        }
    }
    impl ::std::convert::From<InvalidReward> for HyperErrors {
        fn from(var: InvalidReward) -> Self {
            HyperErrors::InvalidReward(var)
        }
    }
    impl ::std::convert::From<InvalidSettlement> for HyperErrors {
        fn from(var: InvalidSettlement) -> Self {
            HyperErrors::InvalidSettlement(var)
        }
    }
    impl ::std::convert::From<InvalidTransfer> for HyperErrors {
        fn from(var: InvalidTransfer) -> Self {
            HyperErrors::InvalidTransfer(var)
        }
    }
    impl ::std::convert::From<JitLiquidity> for HyperErrors {
        fn from(var: JitLiquidity) -> Self {
            HyperErrors::JitLiquidity(var)
        }
    }
    impl ::std::convert::From<Min> for HyperErrors {
        fn from(var: Min) -> Self {
            HyperErrors::Min(var)
        }
    }
    impl ::std::convert::From<NegativeInfinity> for HyperErrors {
        fn from(var: NegativeInfinity) -> Self {
            HyperErrors::NegativeInfinity(var)
        }
    }
    impl ::std::convert::From<NonExistentPool> for HyperErrors {
        fn from(var: NonExistentPool) -> Self {
            HyperErrors::NonExistentPool(var)
        }
    }
    impl ::std::convert::From<NonExistentPosition> for HyperErrors {
        fn from(var: NonExistentPosition) -> Self {
            HyperErrors::NonExistentPosition(var)
        }
    }
    impl ::std::convert::From<NotController> for HyperErrors {
        fn from(var: NotController) -> Self {
            HyperErrors::NotController(var)
        }
    }
    impl ::std::convert::From<NotPreparedToSettle> for HyperErrors {
        fn from(var: NotPreparedToSettle) -> Self {
            HyperErrors::NotPreparedToSettle(var)
        }
    }
    impl ::std::convert::From<OOB> for HyperErrors {
        fn from(var: OOB) -> Self {
            HyperErrors::OOB(var)
        }
    }
    impl ::std::convert::From<OverflowWad> for HyperErrors {
        fn from(var: OverflowWad) -> Self {
            HyperErrors::OverflowWad(var)
        }
    }
    impl ::std::convert::From<PairExists> for HyperErrors {
        fn from(var: PairExists) -> Self {
            HyperErrors::PairExists(var)
        }
    }
    impl ::std::convert::From<PoolExists> for HyperErrors {
        fn from(var: PoolExists) -> Self {
            HyperErrors::PoolExists(var)
        }
    }
    impl ::std::convert::From<PoolExpired> for HyperErrors {
        fn from(var: PoolExpired) -> Self {
            HyperErrors::PoolExpired(var)
        }
    }
    impl ::std::convert::From<PositionNotStaked> for HyperErrors {
        fn from(var: PositionNotStaked) -> Self {
            HyperErrors::PositionNotStaked(var)
        }
    }
    impl ::std::convert::From<SameTokenError> for HyperErrors {
        fn from(var: SameTokenError) -> Self {
            HyperErrors::SameTokenError(var)
        }
    }
    impl ::std::convert::From<StakeNotMature> for HyperErrors {
        fn from(var: StakeNotMature) -> Self {
            HyperErrors::StakeNotMature(var)
        }
    }
    impl ::std::convert::From<SwapLimitReached> for HyperErrors {
        fn from(var: SwapLimitReached) -> Self {
            HyperErrors::SwapLimitReached(var)
        }
    }
    impl ::std::convert::From<ZeroInput> for HyperErrors {
        fn from(var: ZeroInput) -> Self {
            HyperErrors::ZeroInput(var)
        }
    }
    impl ::std::convert::From<ZeroLiquidity> for HyperErrors {
        fn from(var: ZeroLiquidity) -> Self {
            HyperErrors::ZeroLiquidity(var)
        }
    }
    impl ::std::convert::From<ZeroPrice> for HyperErrors {
        fn from(var: ZeroPrice) -> Self {
            HyperErrors::ZeroPrice(var)
        }
    }
    impl ::std::convert::From<ZeroValue> for HyperErrors {
        fn from(var: ZeroValue) -> Self {
            HyperErrors::ZeroValue(var)
        }
    }
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(
        name = "Allocate",
        abi = "Allocate(uint64,address,address,uint256,uint256,uint256)"
    )]
    pub struct AllocateFilter {
        #[ethevent(indexed)]
        pub pool_id: u64,
        #[ethevent(indexed)]
        pub asset: ::ethers::core::types::Address,
        #[ethevent(indexed)]
        pub quote: ::ethers::core::types::Address,
        pub delta_asset: ::ethers::core::types::U256,
        pub delta_quote: ::ethers::core::types::U256,
        pub delta_liquidity: ::ethers::core::types::U256,
    }
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(
        name = "ChangeParameters",
        abi = "ChangeParameters(uint64,uint16,uint16,uint16,uint16,uint16,int24)"
    )]
    pub struct ChangeParametersFilter {
        #[ethevent(indexed)]
        pub pool_id: u64,
        pub priority_fee: u16,
        #[ethevent(indexed)]
        pub fee: u16,
        pub volatility: u16,
        pub duration: u16,
        pub jit: u16,
        #[ethevent(indexed)]
        pub max_tick: i32,
    }
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(
        name = "Collect",
        abi = "Collect(uint64,address,uint256,address,uint256,address,uint256,address)"
    )]
    pub struct CollectFilter {
        pub pool_id: u64,
        pub account: ::ethers::core::types::Address,
        pub fee_asset: ::ethers::core::types::U256,
        #[ethevent(indexed)]
        pub asset: ::ethers::core::types::Address,
        pub fee_quote: ::ethers::core::types::U256,
        #[ethevent(indexed)]
        pub quote: ::ethers::core::types::Address,
        pub fee_reward: ::ethers::core::types::U256,
        #[ethevent(indexed)]
        pub reward: ::ethers::core::types::Address,
    }
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(
        name = "CreatePair",
        abi = "CreatePair(uint24,address,address,uint8,uint8)"
    )]
    pub struct CreatePairFilter {
        #[ethevent(indexed)]
        pub pair_id: u32,
        #[ethevent(indexed)]
        pub asset: ::ethers::core::types::Address,
        #[ethevent(indexed)]
        pub quote: ::ethers::core::types::Address,
        pub decimals_asset: u8,
        pub decimals_quote: u8,
    }
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(
        name = "CreatePool",
        abi = "CreatePool(uint64,bool,address,address,uint256)"
    )]
    pub struct CreatePoolFilter {
        #[ethevent(indexed)]
        pub pool_id: u64,
        pub is_mutable: bool,
        #[ethevent(indexed)]
        pub asset: ::ethers::core::types::Address,
        #[ethevent(indexed)]
        pub quote: ::ethers::core::types::Address,
        pub price: ::ethers::core::types::U256,
    }
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(
        name = "DecreaseReserveBalance",
        abi = "DecreaseReserveBalance(address,uint256)"
    )]
    pub struct DecreaseReserveBalanceFilter {
        #[ethevent(indexed)]
        pub token: ::ethers::core::types::Address,
        pub amount: ::ethers::core::types::U256,
    }
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(
        name = "DecreaseUserBalance",
        abi = "DecreaseUserBalance(address,address,uint256)"
    )]
    pub struct DecreaseUserBalanceFilter {
        #[ethevent(indexed)]
        pub account: ::ethers::core::types::Address,
        #[ethevent(indexed)]
        pub token: ::ethers::core::types::Address,
        pub amount: ::ethers::core::types::U256,
    }
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "Deposit", abi = "Deposit(address,uint256)")]
    pub struct DepositFilter {
        #[ethevent(indexed)]
        pub account: ::ethers::core::types::Address,
        pub amount: ::ethers::core::types::U256,
    }
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(
        name = "IncreaseReserveBalance",
        abi = "IncreaseReserveBalance(address,uint256)"
    )]
    pub struct IncreaseReserveBalanceFilter {
        #[ethevent(indexed)]
        pub token: ::ethers::core::types::Address,
        pub amount: ::ethers::core::types::U256,
    }
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(
        name = "IncreaseUserBalance",
        abi = "IncreaseUserBalance(address,address,uint256)"
    )]
    pub struct IncreaseUserBalanceFilter {
        #[ethevent(indexed)]
        pub account: ::ethers::core::types::Address,
        #[ethevent(indexed)]
        pub token: ::ethers::core::types::Address,
        pub amount: ::ethers::core::types::U256,
    }
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "Stake", abi = "Stake(uint64,address,uint256)")]
    pub struct StakeFilter {
        #[ethevent(indexed)]
        pub pool_id: u64,
        #[ethevent(indexed)]
        pub owner: ::ethers::core::types::Address,
        pub delta_liquidity: ::ethers::core::types::U256,
    }
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(
        name = "Swap",
        abi = "Swap(uint64,uint256,address,uint256,address,uint256)"
    )]
    pub struct SwapFilter {
        #[ethevent(indexed)]
        pub pool_id: u64,
        pub price: ::ethers::core::types::U256,
        #[ethevent(indexed)]
        pub token_in: ::ethers::core::types::Address,
        pub input: ::ethers::core::types::U256,
        #[ethevent(indexed)]
        pub token_out: ::ethers::core::types::Address,
        pub output: ::ethers::core::types::U256,
    }
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(
        name = "Unallocate",
        abi = "Unallocate(uint64,address,address,uint256,uint256,uint256)"
    )]
    pub struct UnallocateFilter {
        #[ethevent(indexed)]
        pub pool_id: u64,
        #[ethevent(indexed)]
        pub asset: ::ethers::core::types::Address,
        #[ethevent(indexed)]
        pub quote: ::ethers::core::types::Address,
        pub delta_asset: ::ethers::core::types::U256,
        pub delta_quote: ::ethers::core::types::U256,
        pub delta_liquidity: ::ethers::core::types::U256,
    }
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "Unstake", abi = "Unstake(uint64,address,uint256)")]
    pub struct UnstakeFilter {
        #[ethevent(indexed)]
        pub pool_id: u64,
        #[ethevent(indexed)]
        pub owner: ::ethers::core::types::Address,
        pub delta_liquidity: ::ethers::core::types::U256,
    }
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum HyperEvents {
        AllocateFilter(AllocateFilter),
        ChangeParametersFilter(ChangeParametersFilter),
        CollectFilter(CollectFilter),
        CreatePairFilter(CreatePairFilter),
        CreatePoolFilter(CreatePoolFilter),
        DecreaseReserveBalanceFilter(DecreaseReserveBalanceFilter),
        DecreaseUserBalanceFilter(DecreaseUserBalanceFilter),
        DepositFilter(DepositFilter),
        IncreaseReserveBalanceFilter(IncreaseReserveBalanceFilter),
        IncreaseUserBalanceFilter(IncreaseUserBalanceFilter),
        StakeFilter(StakeFilter),
        SwapFilter(SwapFilter),
        UnallocateFilter(UnallocateFilter),
        UnstakeFilter(UnstakeFilter),
    }
    impl ::ethers::contract::EthLogDecode for HyperEvents {
        fn decode_log(
            log: &::ethers::core::abi::RawLog,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::Error>
        where
            Self: Sized,
        {
            if let Ok(decoded) = AllocateFilter::decode_log(log) {
                return Ok(HyperEvents::AllocateFilter(decoded));
            }
            if let Ok(decoded) = ChangeParametersFilter::decode_log(log) {
                return Ok(HyperEvents::ChangeParametersFilter(decoded));
            }
            if let Ok(decoded) = CollectFilter::decode_log(log) {
                return Ok(HyperEvents::CollectFilter(decoded));
            }
            if let Ok(decoded) = CreatePairFilter::decode_log(log) {
                return Ok(HyperEvents::CreatePairFilter(decoded));
            }
            if let Ok(decoded) = CreatePoolFilter::decode_log(log) {
                return Ok(HyperEvents::CreatePoolFilter(decoded));
            }
            if let Ok(decoded) = DecreaseReserveBalanceFilter::decode_log(log) {
                return Ok(HyperEvents::DecreaseReserveBalanceFilter(decoded));
            }
            if let Ok(decoded) = DecreaseUserBalanceFilter::decode_log(log) {
                return Ok(HyperEvents::DecreaseUserBalanceFilter(decoded));
            }
            if let Ok(decoded) = DepositFilter::decode_log(log) {
                return Ok(HyperEvents::DepositFilter(decoded));
            }
            if let Ok(decoded) = IncreaseReserveBalanceFilter::decode_log(log) {
                return Ok(HyperEvents::IncreaseReserveBalanceFilter(decoded));
            }
            if let Ok(decoded) = IncreaseUserBalanceFilter::decode_log(log) {
                return Ok(HyperEvents::IncreaseUserBalanceFilter(decoded));
            }
            if let Ok(decoded) = StakeFilter::decode_log(log) {
                return Ok(HyperEvents::StakeFilter(decoded));
            }
            if let Ok(decoded) = SwapFilter::decode_log(log) {
                return Ok(HyperEvents::SwapFilter(decoded));
            }
            if let Ok(decoded) = UnallocateFilter::decode_log(log) {
                return Ok(HyperEvents::UnallocateFilter(decoded));
            }
            if let Ok(decoded) = UnstakeFilter::decode_log(log) {
                return Ok(HyperEvents::UnstakeFilter(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData)
        }
    }
    impl ::std::fmt::Display for HyperEvents {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                HyperEvents::AllocateFilter(element) => element.fmt(f),
                HyperEvents::ChangeParametersFilter(element) => element.fmt(f),
                HyperEvents::CollectFilter(element) => element.fmt(f),
                HyperEvents::CreatePairFilter(element) => element.fmt(f),
                HyperEvents::CreatePoolFilter(element) => element.fmt(f),
                HyperEvents::DecreaseReserveBalanceFilter(element) => element.fmt(f),
                HyperEvents::DecreaseUserBalanceFilter(element) => element.fmt(f),
                HyperEvents::DepositFilter(element) => element.fmt(f),
                HyperEvents::IncreaseReserveBalanceFilter(element) => element.fmt(f),
                HyperEvents::IncreaseUserBalanceFilter(element) => element.fmt(f),
                HyperEvents::StakeFilter(element) => element.fmt(f),
                HyperEvents::SwapFilter(element) => element.fmt(f),
                HyperEvents::UnallocateFilter(element) => element.fmt(f),
                HyperEvents::UnstakeFilter(element) => element.fmt(f),
            }
        }
    }
    ///Container type for all input parameters for the `VERSION` function with signature `VERSION()` and selector `0xffa1ad74`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "VERSION", abi = "VERSION()")]
    pub struct VersionCall;
    ///Container type for all input parameters for the `WETH` function with signature `WETH()` and selector `0xad5c4648`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "WETH", abi = "WETH()")]
    pub struct WethCall;
    ///Container type for all input parameters for the `__account__` function with signature `__account__()` and selector `0xda31ee54`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "__account__", abi = "__account__()")]
    pub struct AccountCall;
    ///Container type for all input parameters for the `allocate` function with signature `allocate(uint64,uint256)` and selector `0x2c0f8903`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "allocate", abi = "allocate(uint64,uint256)")]
    pub struct AllocateCall {
        pub pool_id: u64,
        pub amount: ::ethers::core::types::U256,
    }
    ///Container type for all input parameters for the `changeParameters` function with signature `changeParameters(uint64,uint16,uint16,uint16,uint16,uint16,int24)` and selector `0x6a707efa`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(
        name = "changeParameters",
        abi = "changeParameters(uint64,uint16,uint16,uint16,uint16,uint16,int24)"
    )]
    pub struct ChangeParametersCall {
        pub pool_id: u64,
        pub priority_fee: u16,
        pub fee: u16,
        pub volatility: u16,
        pub duration: u16,
        pub jit: u16,
        pub max_tick: i32,
    }
    ///Container type for all input parameters for the `claim` function with signature `claim(uint64,uint256,uint256)` and selector `0x8e26770f`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "claim", abi = "claim(uint64,uint256,uint256)")]
    pub struct ClaimCall {
        pub pool_id: u64,
        pub delta_asset: ::ethers::core::types::U256,
        pub delta_quote: ::ethers::core::types::U256,
    }
    ///Container type for all input parameters for the `deposit` function with signature `deposit()` and selector `0xd0e30db0`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "deposit", abi = "deposit()")]
    pub struct DepositCall;
    ///Container type for all input parameters for the `draw` function with signature `draw(address,uint256,address)` and selector `0xad24d6a0`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "draw", abi = "draw(address,uint256,address)")]
    pub struct DrawCall {
        pub token: ::ethers::core::types::Address,
        pub amount: ::ethers::core::types::U256,
        pub to: ::ethers::core::types::Address,
    }
    ///Container type for all input parameters for the `fund` function with signature `fund(address,uint256)` and selector `0x7b1837de`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "fund", abi = "fund(address,uint256)")]
    pub struct FundCall {
        pub token: ::ethers::core::types::Address,
        pub amount: ::ethers::core::types::U256,
    }
    ///Container type for all input parameters for the `getAmountOut` function with signature `getAmountOut(uint64,bool,uint256)` and selector `0x7dae4890`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getAmountOut", abi = "getAmountOut(uint64,bool,uint256)")]
    pub struct GetAmountOutCall {
        pub pool_id: u64,
        pub sell_asset: bool,
        pub amount_in: ::ethers::core::types::U256,
    }
    ///Container type for all input parameters for the `getAmounts` function with signature `getAmounts(uint64)` and selector `0x9e5e2e29`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getAmounts", abi = "getAmounts(uint64)")]
    pub struct GetAmountsCall {
        pub pool_id: u64,
    }
    ///Container type for all input parameters for the `getBalance` function with signature `getBalance(address,address)` and selector `0xd4fac45d`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getBalance", abi = "getBalance(address,address)")]
    pub struct GetBalanceCall {
        pub owner: ::ethers::core::types::Address,
        pub token: ::ethers::core::types::Address,
    }
    ///Container type for all input parameters for the `getLatestPrice` function with signature `getLatestPrice(uint64)` and selector `0x8c470b8f`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getLatestPrice", abi = "getLatestPrice(uint64)")]
    pub struct GetLatestPriceCall {
        pub pool_id: u64,
    }
    ///Container type for all input parameters for the `getLiquidityDeltas` function with signature `getLiquidityDeltas(uint64,int128)` and selector `0x8992f20a`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getLiquidityDeltas", abi = "getLiquidityDeltas(uint64,int128)")]
    pub struct GetLiquidityDeltasCall {
        pub pool_id: u64,
        pub delta_liquidity: i128,
    }
    ///Container type for all input parameters for the `getMaxLiquidity` function with signature `getMaxLiquidity(uint64,uint256,uint256)` and selector `0xd6b7dec5`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(
        name = "getMaxLiquidity",
        abi = "getMaxLiquidity(uint64,uint256,uint256)"
    )]
    pub struct GetMaxLiquidityCall {
        pub pool_id: u64,
        pub delta_asset: ::ethers::core::types::U256,
        pub delta_quote: ::ethers::core::types::U256,
    }
    ///Container type for all input parameters for the `getNetBalance` function with signature `getNetBalance(address)` and selector `0x4dc68a90`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getNetBalance", abi = "getNetBalance(address)")]
    pub struct GetNetBalanceCall {
        pub token: ::ethers::core::types::Address,
    }
    ///Container type for all input parameters for the `getPairId` function with signature `getPairId(address,address)` and selector `0x3f92a339`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getPairId", abi = "getPairId(address,address)")]
    pub struct GetPairIdCall(
        pub ::ethers::core::types::Address,
        pub ::ethers::core::types::Address,
    );
    ///Container type for all input parameters for the `getPairNonce` function with signature `getPairNonce()` and selector `0x078888d6`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getPairNonce", abi = "getPairNonce()")]
    pub struct GetPairNonceCall;
    ///Container type for all input parameters for the `getPoolNonce` function with signature `getPoolNonce()` and selector `0xfd2dbea1`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getPoolNonce", abi = "getPoolNonce()")]
    pub struct GetPoolNonceCall;
    ///Container type for all input parameters for the `getReserve` function with signature `getReserve(address)` and selector `0xc9a396e9`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getReserve", abi = "getReserve(address)")]
    pub struct GetReserveCall {
        pub token: ::ethers::core::types::Address,
    }
    ///Container type for all input parameters for the `getTimePassed` function with signature `getTimePassed(uint64)` and selector `0x0242f403`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getTimePassed", abi = "getTimePassed(uint64)")]
    pub struct GetTimePassedCall {
        pub pool_id: u64,
    }
    ///Container type for all input parameters for the `getVirtualReserves` function with signature `getVirtualReserves(uint64)` and selector `0x5ef05b0c`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getVirtualReserves", abi = "getVirtualReserves(uint64)")]
    pub struct GetVirtualReservesCall {
        pub pool_id: u64,
    }
    ///Container type for all input parameters for the `pairs` function with signature `pairs(uint24)` and selector `0x5e47663c`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "pairs", abi = "pairs(uint24)")]
    pub struct PairsCall(pub u32);
    ///Container type for all input parameters for the `pools` function with signature `pools(uint64)` and selector `0x89a5f084`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "pools", abi = "pools(uint64)")]
    pub struct PoolsCall(pub u64);
    ///Container type for all input parameters for the `positions` function with signature `positions(address,uint64)` and selector `0xb68513ea`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "positions", abi = "positions(address,uint64)")]
    pub struct PositionsCall(pub ::ethers::core::types::Address, pub u64);
    ///Container type for all input parameters for the `stake` function with signature `stake(uint64,uint128)` and selector `0x23135811`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "stake", abi = "stake(uint64,uint128)")]
    pub struct StakeCall {
        pub pool_id: u64,
        pub delta_liquidity: u128,
    }
    ///Container type for all input parameters for the `swap` function with signature `swap(uint64,bool,uint256,uint256)` and selector `0xa4c68d9d`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "swap", abi = "swap(uint64,bool,uint256,uint256)")]
    pub struct SwapCall {
        pub pool_id: u64,
        pub sell_asset: bool,
        pub amount: ::ethers::core::types::U256,
        pub limit: ::ethers::core::types::U256,
    }
    ///Container type for all input parameters for the `unallocate` function with signature `unallocate(uint64,uint256)` and selector `0xbcf78a5a`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "unallocate", abi = "unallocate(uint64,uint256)")]
    pub struct UnallocateCall {
        pub pool_id: u64,
        pub amount: ::ethers::core::types::U256,
    }
    ///Container type for all input parameters for the `unstake` function with signature `unstake(uint64,uint128)` and selector `0xa81262d5`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "unstake", abi = "unstake(uint64,uint128)")]
    pub struct UnstakeCall {
        pub pool_id: u64,
        pub delta_liquidity: u128,
    }
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum HyperCalls {
        Version(VersionCall),
        Weth(WethCall),
        Account(AccountCall),
        Allocate(AllocateCall),
        ChangeParameters(ChangeParametersCall),
        Claim(ClaimCall),
        Deposit(DepositCall),
        Draw(DrawCall),
        Fund(FundCall),
        GetAmountOut(GetAmountOutCall),
        GetAmounts(GetAmountsCall),
        GetBalance(GetBalanceCall),
        GetLatestPrice(GetLatestPriceCall),
        GetLiquidityDeltas(GetLiquidityDeltasCall),
        GetMaxLiquidity(GetMaxLiquidityCall),
        GetNetBalance(GetNetBalanceCall),
        GetPairId(GetPairIdCall),
        GetPairNonce(GetPairNonceCall),
        GetPoolNonce(GetPoolNonceCall),
        GetReserve(GetReserveCall),
        GetTimePassed(GetTimePassedCall),
        GetVirtualReserves(GetVirtualReservesCall),
        Pairs(PairsCall),
        Pools(PoolsCall),
        Positions(PositionsCall),
        Stake(StakeCall),
        Swap(SwapCall),
        Unallocate(UnallocateCall),
        Unstake(UnstakeCall),
    }
    impl ::ethers::core::abi::AbiDecode for HyperCalls {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded) =
                <VersionCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::Version(decoded));
            }
            if let Ok(decoded) = <WethCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::Weth(decoded));
            }
            if let Ok(decoded) =
                <AccountCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::Account(decoded));
            }
            if let Ok(decoded) =
                <AllocateCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::Allocate(decoded));
            }
            if let Ok(decoded) =
                <ChangeParametersCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::ChangeParameters(decoded));
            }
            if let Ok(decoded) =
                <ClaimCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::Claim(decoded));
            }
            if let Ok(decoded) =
                <DepositCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::Deposit(decoded));
            }
            if let Ok(decoded) = <DrawCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::Draw(decoded));
            }
            if let Ok(decoded) = <FundCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::Fund(decoded));
            }
            if let Ok(decoded) =
                <GetAmountOutCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::GetAmountOut(decoded));
            }
            if let Ok(decoded) =
                <GetAmountsCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::GetAmounts(decoded));
            }
            if let Ok(decoded) =
                <GetBalanceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::GetBalance(decoded));
            }
            if let Ok(decoded) =
                <GetLatestPriceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::GetLatestPrice(decoded));
            }
            if let Ok(decoded) =
                <GetLiquidityDeltasCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::GetLiquidityDeltas(decoded));
            }
            if let Ok(decoded) =
                <GetMaxLiquidityCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::GetMaxLiquidity(decoded));
            }
            if let Ok(decoded) =
                <GetNetBalanceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::GetNetBalance(decoded));
            }
            if let Ok(decoded) =
                <GetPairIdCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::GetPairId(decoded));
            }
            if let Ok(decoded) =
                <GetPairNonceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::GetPairNonce(decoded));
            }
            if let Ok(decoded) =
                <GetPoolNonceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::GetPoolNonce(decoded));
            }
            if let Ok(decoded) =
                <GetReserveCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::GetReserve(decoded));
            }
            if let Ok(decoded) =
                <GetTimePassedCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::GetTimePassed(decoded));
            }
            if let Ok(decoded) =
                <GetVirtualReservesCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::GetVirtualReserves(decoded));
            }
            if let Ok(decoded) =
                <PairsCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::Pairs(decoded));
            }
            if let Ok(decoded) =
                <PoolsCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::Pools(decoded));
            }
            if let Ok(decoded) =
                <PositionsCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::Positions(decoded));
            }
            if let Ok(decoded) =
                <StakeCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::Stake(decoded));
            }
            if let Ok(decoded) = <SwapCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::Swap(decoded));
            }
            if let Ok(decoded) =
                <UnallocateCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::Unallocate(decoded));
            }
            if let Ok(decoded) =
                <UnstakeCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperCalls::Unstake(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for HyperCalls {
        fn encode(self) -> Vec<u8> {
            match self {
                HyperCalls::Version(element) => element.encode(),
                HyperCalls::Weth(element) => element.encode(),
                HyperCalls::Account(element) => element.encode(),
                HyperCalls::Allocate(element) => element.encode(),
                HyperCalls::ChangeParameters(element) => element.encode(),
                HyperCalls::Claim(element) => element.encode(),
                HyperCalls::Deposit(element) => element.encode(),
                HyperCalls::Draw(element) => element.encode(),
                HyperCalls::Fund(element) => element.encode(),
                HyperCalls::GetAmountOut(element) => element.encode(),
                HyperCalls::GetAmounts(element) => element.encode(),
                HyperCalls::GetBalance(element) => element.encode(),
                HyperCalls::GetLatestPrice(element) => element.encode(),
                HyperCalls::GetLiquidityDeltas(element) => element.encode(),
                HyperCalls::GetMaxLiquidity(element) => element.encode(),
                HyperCalls::GetNetBalance(element) => element.encode(),
                HyperCalls::GetPairId(element) => element.encode(),
                HyperCalls::GetPairNonce(element) => element.encode(),
                HyperCalls::GetPoolNonce(element) => element.encode(),
                HyperCalls::GetReserve(element) => element.encode(),
                HyperCalls::GetTimePassed(element) => element.encode(),
                HyperCalls::GetVirtualReserves(element) => element.encode(),
                HyperCalls::Pairs(element) => element.encode(),
                HyperCalls::Pools(element) => element.encode(),
                HyperCalls::Positions(element) => element.encode(),
                HyperCalls::Stake(element) => element.encode(),
                HyperCalls::Swap(element) => element.encode(),
                HyperCalls::Unallocate(element) => element.encode(),
                HyperCalls::Unstake(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for HyperCalls {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                HyperCalls::Version(element) => element.fmt(f),
                HyperCalls::Weth(element) => element.fmt(f),
                HyperCalls::Account(element) => element.fmt(f),
                HyperCalls::Allocate(element) => element.fmt(f),
                HyperCalls::ChangeParameters(element) => element.fmt(f),
                HyperCalls::Claim(element) => element.fmt(f),
                HyperCalls::Deposit(element) => element.fmt(f),
                HyperCalls::Draw(element) => element.fmt(f),
                HyperCalls::Fund(element) => element.fmt(f),
                HyperCalls::GetAmountOut(element) => element.fmt(f),
                HyperCalls::GetAmounts(element) => element.fmt(f),
                HyperCalls::GetBalance(element) => element.fmt(f),
                HyperCalls::GetLatestPrice(element) => element.fmt(f),
                HyperCalls::GetLiquidityDeltas(element) => element.fmt(f),
                HyperCalls::GetMaxLiquidity(element) => element.fmt(f),
                HyperCalls::GetNetBalance(element) => element.fmt(f),
                HyperCalls::GetPairId(element) => element.fmt(f),
                HyperCalls::GetPairNonce(element) => element.fmt(f),
                HyperCalls::GetPoolNonce(element) => element.fmt(f),
                HyperCalls::GetReserve(element) => element.fmt(f),
                HyperCalls::GetTimePassed(element) => element.fmt(f),
                HyperCalls::GetVirtualReserves(element) => element.fmt(f),
                HyperCalls::Pairs(element) => element.fmt(f),
                HyperCalls::Pools(element) => element.fmt(f),
                HyperCalls::Positions(element) => element.fmt(f),
                HyperCalls::Stake(element) => element.fmt(f),
                HyperCalls::Swap(element) => element.fmt(f),
                HyperCalls::Unallocate(element) => element.fmt(f),
                HyperCalls::Unstake(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<VersionCall> for HyperCalls {
        fn from(var: VersionCall) -> Self {
            HyperCalls::Version(var)
        }
    }
    impl ::std::convert::From<WethCall> for HyperCalls {
        fn from(var: WethCall) -> Self {
            HyperCalls::Weth(var)
        }
    }
    impl ::std::convert::From<AccountCall> for HyperCalls {
        fn from(var: AccountCall) -> Self {
            HyperCalls::Account(var)
        }
    }
    impl ::std::convert::From<AllocateCall> for HyperCalls {
        fn from(var: AllocateCall) -> Self {
            HyperCalls::Allocate(var)
        }
    }
    impl ::std::convert::From<ChangeParametersCall> for HyperCalls {
        fn from(var: ChangeParametersCall) -> Self {
            HyperCalls::ChangeParameters(var)
        }
    }
    impl ::std::convert::From<ClaimCall> for HyperCalls {
        fn from(var: ClaimCall) -> Self {
            HyperCalls::Claim(var)
        }
    }
    impl ::std::convert::From<DepositCall> for HyperCalls {
        fn from(var: DepositCall) -> Self {
            HyperCalls::Deposit(var)
        }
    }
    impl ::std::convert::From<DrawCall> for HyperCalls {
        fn from(var: DrawCall) -> Self {
            HyperCalls::Draw(var)
        }
    }
    impl ::std::convert::From<FundCall> for HyperCalls {
        fn from(var: FundCall) -> Self {
            HyperCalls::Fund(var)
        }
    }
    impl ::std::convert::From<GetAmountOutCall> for HyperCalls {
        fn from(var: GetAmountOutCall) -> Self {
            HyperCalls::GetAmountOut(var)
        }
    }
    impl ::std::convert::From<GetAmountsCall> for HyperCalls {
        fn from(var: GetAmountsCall) -> Self {
            HyperCalls::GetAmounts(var)
        }
    }
    impl ::std::convert::From<GetBalanceCall> for HyperCalls {
        fn from(var: GetBalanceCall) -> Self {
            HyperCalls::GetBalance(var)
        }
    }
    impl ::std::convert::From<GetLatestPriceCall> for HyperCalls {
        fn from(var: GetLatestPriceCall) -> Self {
            HyperCalls::GetLatestPrice(var)
        }
    }
    impl ::std::convert::From<GetLiquidityDeltasCall> for HyperCalls {
        fn from(var: GetLiquidityDeltasCall) -> Self {
            HyperCalls::GetLiquidityDeltas(var)
        }
    }
    impl ::std::convert::From<GetMaxLiquidityCall> for HyperCalls {
        fn from(var: GetMaxLiquidityCall) -> Self {
            HyperCalls::GetMaxLiquidity(var)
        }
    }
    impl ::std::convert::From<GetNetBalanceCall> for HyperCalls {
        fn from(var: GetNetBalanceCall) -> Self {
            HyperCalls::GetNetBalance(var)
        }
    }
    impl ::std::convert::From<GetPairIdCall> for HyperCalls {
        fn from(var: GetPairIdCall) -> Self {
            HyperCalls::GetPairId(var)
        }
    }
    impl ::std::convert::From<GetPairNonceCall> for HyperCalls {
        fn from(var: GetPairNonceCall) -> Self {
            HyperCalls::GetPairNonce(var)
        }
    }
    impl ::std::convert::From<GetPoolNonceCall> for HyperCalls {
        fn from(var: GetPoolNonceCall) -> Self {
            HyperCalls::GetPoolNonce(var)
        }
    }
    impl ::std::convert::From<GetReserveCall> for HyperCalls {
        fn from(var: GetReserveCall) -> Self {
            HyperCalls::GetReserve(var)
        }
    }
    impl ::std::convert::From<GetTimePassedCall> for HyperCalls {
        fn from(var: GetTimePassedCall) -> Self {
            HyperCalls::GetTimePassed(var)
        }
    }
    impl ::std::convert::From<GetVirtualReservesCall> for HyperCalls {
        fn from(var: GetVirtualReservesCall) -> Self {
            HyperCalls::GetVirtualReserves(var)
        }
    }
    impl ::std::convert::From<PairsCall> for HyperCalls {
        fn from(var: PairsCall) -> Self {
            HyperCalls::Pairs(var)
        }
    }
    impl ::std::convert::From<PoolsCall> for HyperCalls {
        fn from(var: PoolsCall) -> Self {
            HyperCalls::Pools(var)
        }
    }
    impl ::std::convert::From<PositionsCall> for HyperCalls {
        fn from(var: PositionsCall) -> Self {
            HyperCalls::Positions(var)
        }
    }
    impl ::std::convert::From<StakeCall> for HyperCalls {
        fn from(var: StakeCall) -> Self {
            HyperCalls::Stake(var)
        }
    }
    impl ::std::convert::From<SwapCall> for HyperCalls {
        fn from(var: SwapCall) -> Self {
            HyperCalls::Swap(var)
        }
    }
    impl ::std::convert::From<UnallocateCall> for HyperCalls {
        fn from(var: UnallocateCall) -> Self {
            HyperCalls::Unallocate(var)
        }
    }
    impl ::std::convert::From<UnstakeCall> for HyperCalls {
        fn from(var: UnstakeCall) -> Self {
            HyperCalls::Unstake(var)
        }
    }
    ///Container type for all return fields from the `VERSION` function with signature `VERSION()` and selector `0xffa1ad74`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct VersionReturn(pub String);
    ///Container type for all return fields from the `WETH` function with signature `WETH()` and selector `0xad5c4648`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct WethReturn(pub ::ethers::core::types::Address);
    ///Container type for all return fields from the `__account__` function with signature `__account__()` and selector `0xda31ee54`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct AccountReturn {
        pub prepared: bool,
        pub settled: bool,
    }
    ///Container type for all return fields from the `allocate` function with signature `allocate(uint64,uint256)` and selector `0x2c0f8903`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct AllocateReturn {
        pub delta_asset: ::ethers::core::types::U256,
        pub delta_quote: ::ethers::core::types::U256,
    }
    ///Container type for all return fields from the `getAmountOut` function with signature `getAmountOut(uint64,bool,uint256)` and selector `0x7dae4890`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetAmountOutReturn {
        pub output: ::ethers::core::types::U256,
    }
    ///Container type for all return fields from the `getAmounts` function with signature `getAmounts(uint64)` and selector `0x9e5e2e29`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetAmountsReturn {
        pub delta_asset: ::ethers::core::types::U256,
        pub delta_quote: ::ethers::core::types::U256,
    }
    ///Container type for all return fields from the `getBalance` function with signature `getBalance(address,address)` and selector `0xd4fac45d`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetBalanceReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getLatestPrice` function with signature `getLatestPrice(uint64)` and selector `0x8c470b8f`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetLatestPriceReturn {
        pub price: ::ethers::core::types::U256,
    }
    ///Container type for all return fields from the `getLiquidityDeltas` function with signature `getLiquidityDeltas(uint64,int128)` and selector `0x8992f20a`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetLiquidityDeltasReturn {
        pub delta_asset: u128,
        pub delta_quote: u128,
    }
    ///Container type for all return fields from the `getMaxLiquidity` function with signature `getMaxLiquidity(uint64,uint256,uint256)` and selector `0xd6b7dec5`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetMaxLiquidityReturn {
        pub delta_liquidity: u128,
    }
    ///Container type for all return fields from the `getNetBalance` function with signature `getNetBalance(address)` and selector `0x4dc68a90`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetNetBalanceReturn(pub ::ethers::core::types::I256);
    ///Container type for all return fields from the `getPairId` function with signature `getPairId(address,address)` and selector `0x3f92a339`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetPairIdReturn(pub u32);
    ///Container type for all return fields from the `getPairNonce` function with signature `getPairNonce()` and selector `0x078888d6`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetPairNonceReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getPoolNonce` function with signature `getPoolNonce()` and selector `0xfd2dbea1`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetPoolNonceReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getReserve` function with signature `getReserve(address)` and selector `0xc9a396e9`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetReserveReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getTimePassed` function with signature `getTimePassed(uint64)` and selector `0x0242f403`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetTimePassedReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getVirtualReserves` function with signature `getVirtualReserves(uint64)` and selector `0x5ef05b0c`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetVirtualReservesReturn {
        pub delta_asset: u128,
        pub delta_quote: u128,
    }
    ///Container type for all return fields from the `pairs` function with signature `pairs(uint24)` and selector `0x5e47663c`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct PairsReturn {
        pub token_asset: ::ethers::core::types::Address,
        pub decimals_asset: u8,
        pub token_quote: ::ethers::core::types::Address,
        pub decimals_quote: u8,
    }
    ///Container type for all return fields from the `pools` function with signature `pools(uint64)` and selector `0x89a5f084`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct PoolsReturn {
        pub last_tick: i32,
        pub last_timestamp: u32,
        pub controller: ::ethers::core::types::Address,
        pub fee_growth_global_reward: ::ethers::core::types::U256,
        pub fee_growth_global_asset: ::ethers::core::types::U256,
        pub fee_growth_global_quote: ::ethers::core::types::U256,
        pub last_price: u128,
        pub liquidity: u128,
        pub staked_liquidity: u128,
        pub staked_liquidity_delta: i128,
        pub params: HyperCurve,
        pub pair: HyperPair,
    }
    ///Container type for all return fields from the `positions` function with signature `positions(address,uint64)` and selector `0xb68513ea`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct PositionsReturn {
        pub free_liquidity: u128,
        pub staked_liquidity: u128,
        pub last_timestamp: ::ethers::core::types::U256,
        pub stake_timestamp: ::ethers::core::types::U256,
        pub unstake_timestamp: ::ethers::core::types::U256,
        pub fee_growth_reward_last: ::ethers::core::types::U256,
        pub fee_growth_asset_last: ::ethers::core::types::U256,
        pub fee_growth_quote_last: ::ethers::core::types::U256,
        pub tokens_owed_asset: u128,
        pub tokens_owed_quote: u128,
        pub tokens_owed_reward: u128,
    }
    ///Container type for all return fields from the `swap` function with signature `swap(uint64,bool,uint256,uint256)` and selector `0xa4c68d9d`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct SwapReturn {
        pub output: ::ethers::core::types::U256,
        pub remainder: ::ethers::core::types::U256,
    }
    ///Container type for all return fields from the `unallocate` function with signature `unallocate(uint64,uint256)` and selector `0xbcf78a5a`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct UnallocateReturn {
        pub delta_asset: ::ethers::core::types::U256,
        pub delta_quote: ::ethers::core::types::U256,
    }
}
