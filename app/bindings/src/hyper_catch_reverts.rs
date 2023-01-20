pub use hyper_catch_reverts::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod hyper_catch_reverts {
    #![allow(clippy::enum_variant_names)]
    #![allow(dead_code)]
    #![allow(clippy::type_complexity)]
    #![allow(unused_imports)]
    ///HyperCatchReverts was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
    use std::sync::Arc;
    use ::ethers::core::{
        abi::{Abi, Token, Detokenize, InvalidOutputType, Tokenizable},
        types::*,
    };
    use ::ethers::contract::{
        Contract, builders::{ContractCall, Event},
        Lazy,
    };
    use ::ethers::providers::Middleware;
    pub use super::super::shared_types::*;
    #[rustfmt::skip]
    const __ABI: &str = "[{\"inputs\":[{\"internalType\":\"address\",\"name\":\"weth\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"constructor\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"DrawBalance\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"EtherTransferFail\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"Infinity\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"type\":\"error\",\"name\":\"InsufficientPosition\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"delta\",\"type\":\"uint256\",\"components\":[]}],\"type\":\"error\",\"name\":\"InsufficientReserve\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidBalance\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"expected\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"length\",\"type\":\"uint256\",\"components\":[]}],\"type\":\"error\",\"name\":\"InvalidBytesLength\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint8\",\"name\":\"decimals\",\"type\":\"uint8\",\"components\":[]}],\"type\":\"error\",\"name\":\"InvalidDecimals\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]}],\"type\":\"error\",\"name\":\"InvalidFee\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidInstruction\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"int256\",\"name\":\"prev\",\"type\":\"int256\",\"components\":[]},{\"internalType\":\"int256\",\"name\":\"next\",\"type\":\"int256\",\"components\":[]}],\"type\":\"error\",\"name\":\"InvalidInvariant\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"pointer\",\"type\":\"uint256\",\"components\":[]}],\"type\":\"error\",\"name\":\"InvalidJump\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidReentrancy\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidReward\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidSettlement\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidTransfer\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"distance\",\"type\":\"uint256\",\"components\":[]}],\"type\":\"error\",\"name\":\"JitLiquidity\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"Min\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"NegativeInfinity\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"type\":\"error\",\"name\":\"NonExistentPool\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"type\":\"error\",\"name\":\"NonExistentPosition\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"NotController\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"NotPreparedToSettle\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"OOB\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"int256\",\"name\":\"wad\",\"type\":\"int256\",\"components\":[]}],\"type\":\"error\",\"name\":\"OverflowWad\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint24\",\"name\":\"pairId\",\"type\":\"uint24\",\"components\":[]}],\"type\":\"error\",\"name\":\"PairExists\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"PoolExists\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"PoolExpired\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint96\",\"name\":\"positionId\",\"type\":\"uint96\",\"components\":[]}],\"type\":\"error\",\"name\":\"PositionNotStaked\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"SameTokenError\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"type\":\"error\",\"name\":\"StakeNotMature\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"SwapLimitReached\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"ZeroInput\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"ZeroLiquidity\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"ZeroPrice\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"ZeroValue\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"quote\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"deltaLiquidity\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Allocate\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[],\"indexed\":false},{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[],\"indexed\":true}],\"type\":\"event\",\"name\":\"ChangeParameters\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"account\",\"type\":\"address\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"feeAsset\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"feeQuote\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"quote\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"feeReward\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"reward\",\"type\":\"address\",\"components\":[],\"indexed\":true}],\"type\":\"event\",\"name\":\"Collect\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint24\",\"name\":\"pairId\",\"type\":\"uint24\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"quote\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"CreatePair\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":true},{\"internalType\":\"bool\",\"name\":\"isMutable\",\"type\":\"bool\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"quote\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"price\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"CreatePool\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"DecreaseReserveBalance\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"account\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"DecreaseUserBalance\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"account\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Deposit\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"IncreaseReserveBalance\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"account\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"IncreaseUserBalance\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"deltaLiquidity\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Stake\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"price\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"tokenIn\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"input\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"tokenOut\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"output\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Swap\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"quote\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"deltaLiquidity\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Unallocate\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"deltaLiquidity\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Unstake\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[],\"stateMutability\":\"payable\",\"type\":\"fallback\",\"outputs\":[]},{\"inputs\":[],\"stateMutability\":\"pure\",\"type\":\"function\",\"name\":\"VERSION\",\"outputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"WETH\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__account__\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"prepared\",\"type\":\"bool\",\"components\":[]},{\"internalType\":\"bool\",\"name\":\"settled\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"allocate\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"changeParameters\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"claim\",\"outputs\":[]},{\"inputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\",\"name\":\"deposit\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"data\",\"type\":\"bytes\",\"components\":[]}],\"stateMutability\":\"payable\",\"type\":\"function\",\"name\":\"doJumpProcess\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"to\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"draw\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"fund\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"bool\",\"name\":\"sellAsset\",\"type\":\"bool\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amountIn\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getAmountOut\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"output\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getAmounts\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getLatestPrice\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"price\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"int128\",\"name\":\"deltaLiquidity\",\"type\":\"int128\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getLiquidityDeltas\",\"outputs\":[{\"internalType\":\"uint128\",\"name\":\"deltaAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"deltaQuote\",\"type\":\"uint128\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getMaxLiquidity\",\"outputs\":[{\"internalType\":\"uint128\",\"name\":\"deltaLiquidity\",\"type\":\"uint128\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getNetBalance\",\"outputs\":[{\"internalType\":\"int256\",\"name\":\"\",\"type\":\"int256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPairId\",\"outputs\":[{\"internalType\":\"uint24\",\"name\":\"\",\"type\":\"uint24\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPairNonce\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPoolNonce\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getReserve\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getTimePassed\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getVirtualReserves\",\"outputs\":[{\"internalType\":\"uint128\",\"name\":\"deltaAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"deltaQuote\",\"type\":\"uint128\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"jitDelay\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"data\",\"type\":\"bytes\",\"components\":[]}],\"stateMutability\":\"payable\",\"type\":\"function\",\"name\":\"jumpProcess\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"data\",\"type\":\"bytes\",\"components\":[]}],\"stateMutability\":\"payable\",\"type\":\"function\",\"name\":\"mockFallback\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint24\",\"name\":\"\",\"type\":\"uint24\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"pairs\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"pools\",\"outputs\":[{\"internalType\":\"int24\",\"name\":\"lastTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"lastTimestamp\",\"type\":\"uint32\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"controller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalReward\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"lastPrice\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"liquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"int128\",\"name\":\"stakedLiquidityDelta\",\"type\":\"int128\",\"components\":[]},{\"internalType\":\"struct HyperCurve\",\"name\":\"params\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]},{\"internalType\":\"struct HyperPair\",\"name\":\"pair\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"positions\",\"outputs\":[{\"internalType\":\"uint128\",\"name\":\"freeLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"lastTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"stakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"unstakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthRewardLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuoteLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedQuote\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedReward\",\"type\":\"uint128\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"data\",\"type\":\"bytes\",\"components\":[]}],\"stateMutability\":\"payable\",\"type\":\"function\",\"name\":\"process\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"delay\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"setJitPolicy\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint128\",\"name\":\"time\",\"type\":\"uint128\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"setTimestamp\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"deltaLiquidity\",\"type\":\"uint128\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"stake\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"bool\",\"name\":\"sellAsset\",\"type\":\"bool\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"limit\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"swap\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"output\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"remainder\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"timestamp\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"unallocate\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"deltaLiquidity\",\"type\":\"uint128\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"unstake\",\"outputs\":[]},{\"inputs\":[],\"stateMutability\":\"payable\",\"type\":\"receive\",\"outputs\":[]}]";
    /// The parsed JSON-ABI of the contract.
    pub static HYPERCATCHREVERTS_ABI: ::ethers::contract::Lazy<
        ::ethers::core::abi::Abi,
    > = ::ethers::contract::Lazy::new(|| {
        ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi")
    });
    /// Bytecode of the #name contract
    pub static HYPERCATCHREVERTS_BYTECODE: ::ethers::contract::Lazy<
        ::ethers::core::types::Bytes,
    > = ::ethers::contract::Lazy::new(|| {
        "0x60a06040526001600b553480156200001657600080fd5b5060405162009de738038062009de783398101604081905262000039916200005a565b6001600160a01b03166080526004805461ff0019166101001790556200008c565b6000602082840312156200006d57600080fd5b81516001600160a01b03811681146200008557600080fd5b9392505050565b608051619c97620001506000396000818161022e015281816102b3015281816109520152818161137601528181611450015281816116ef0152818161196701528181611e1d0152818161205c015281816123cb0152818161240901528181612454015281816124cd015281816125c5015281816127de0152818161296801528181612a0f01528181612aa601528181612ae201528181612b8601528181612c5b01528181612cff0152818161460c0152818161464101526146990152619c976000f3fe60806040526004361061021e5760003560e01c80639e5e2e2911610123578063bcf78a5a116100ab578063da31ee541161006f578063da31ee5414610b52578063e82b84b41461058c578063f740485b14610b8c578063fd2dbea114610bb5578063ffa1ad7414610bcb5761025a565b8063bcf78a5a14610a9c578063c9a396e914610abc578063d0e30db014610af2578063d4fac45d14610afa578063d6b7dec514610b1a5761025a565b8063ad24d6a0116100f2578063ad24d6a014610920578063ad5c464814610940578063b3b528a21461098c578063b68513ea1461099f578063b80777ea14610a865761025a565b80639e5e2e29146108aa578063a1f4405d146108ca578063a4c68d9d146108e0578063a81262d5146109005761025a565b80636a707efa116101a65780638992f20a116101755780638992f20a1461059f57806389a5f084146105bf5780638c470b8f146108575780638e26770f14610877578063928bc4b2146108975761025a565b80636a707efa1461052c5780637b1837de1461054c5780637dae48901461056c57806380aa20191461058c5761025a565b80633f92a339116101ed5780633f92a339146103d05780634a9866b4146104215780634dc68a90146104415780635e47663c146104615780635ef05b0c146104ec5761025a565b80630242f40314610332578063078888d614610365578063231358111461037b5780632c0f89031461039b5761025a565b3661025a57336001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000161461025857600080fd5b005b600b546001146102805760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff16156102ac5760405160016238ddf760e01b0319815260040160405180910390fd5b6102d760007f0000000000000000000000000000000000000000000000000000000000000000610bed565b6004805460ff191690556102ec610c56610ead565b6004805460ff19166001179055610301610efa565b600454610100900460ff16610329576040516304564c7160e21b815260040160405180910390fd5b6001600b819055005b34801561033e57600080fd5b5061035261034d366004619102565b6112d4565b6040519081526020015b60405180910390f35b34801561037157600080fd5b5061035260055481565b34801561038757600080fd5b50610258610396366004619134565b61131d565b3480156103a757600080fd5b506103bb6103b636600461915e565b6113f4565b6040805192835260208301919091520161035c565b3480156103dc57600080fd5b5061040d6103eb36600461919f565b600960209081526000928352604080842090915290825290205462ffffff1681565b60405162ffffff909116815260200161035c565b34801561042d57600080fd5b5061025861043c3660046191c9565b601355565b34801561044d57600080fd5b5061035261045c3660046191e2565b6114f5565b34801561046d57600080fd5b506104b861047c3660046191fd565b600760205260009081526040902080546001909101546001600160a01b038083169260ff600160a01b9182900481169392831692919091041684565b604080516001600160a01b03958616815260ff9485166020820152949092169184019190915216606082015260800161035c565b3480156104f857600080fd5b5061050c610507366004619102565b611508565b604080516001600160801b0393841681529290911660208301520161035c565b34801561053857600080fd5b50610258610547366004619234565b611696565b34801561055857600080fd5b506102586105673660046192c4565b61190e565b34801561057857600080fd5b506103526105873660046192f0565b6119a2565b61025861059a36600461932c565b611dc4565b3480156105ab57600080fd5b5061050c6105ba36600461939d565b611e58565b3480156105cb57600080fd5b5061083f6105da366004619102565b60086020528060005260406000206000915090508060000160009054906101000a900460020b908060000160039054906101000a900463ffffffff16908060000160079054906101000a90046001600160a01b0316908060010154908060020154908060030154908060040160009054906101000a90046001600160801b0316908060040160109054906101000a90046001600160801b0316908060050160009054906101000a90046001600160801b0316908060050160109054906101000a9004600f0b90806006016040518060e00160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900461ffff1661ffff1661ffff1681526020016000820160059054906101000a900461ffff1661ffff1661ffff1681526020016000820160079054906101000a900461ffff1661ffff1661ffff1681526020016000820160099054906101000a900461ffff1661ffff1661ffff16815260200160008201600b9054906101000a900461ffff1661ffff1661ffff16815260200160008201600d9054906101000a900463ffffffff1663ffffffff1663ffffffff168152505090806007016040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff168152505090508c565b60405161035c9c9b9a999897969594939291906193da565b34801561086357600080fd5b50610352610872366004619102565b611fef565b34801561088357600080fd5b506102586108923660046194f4565b612003565b6102586108a536600461932c565b61256c565b3480156108b657600080fd5b506103bb6108c5366004619102565b6125fd565b3480156108d657600080fd5b5061035260135481565b3480156108ec57600080fd5b506103bb6108fb366004619527565b612782565b34801561090c57600080fd5b5061025861091b366004619134565b61290f565b34801561092c57600080fd5b5061025861093b366004619569565b6129b6565b34801561094c57600080fd5b506109747f000000000000000000000000000000000000000000000000000000000000000081565b6040516001600160a01b03909116815260200161035c565b61025861099a36600461932c565b612b2d565b3480156109ab57600080fd5b50610a236109ba36600461959c565b600a6020908152600092835260408084209091529082529020805460018201546002830154600384015460048501546005860154600687015460078801546008909801546001600160801b0380891699600160801b998a9004821699818316939104821691168b565b604080516001600160801b039c8d1681529a8c1660208c01528a01989098526060890196909652608088019490945260a087019290925260c086015260e0850152841661010084015283166101208301529091166101408201526101600161035c565b348015610a9257600080fd5b5061035260125481565b348015610aa857600080fd5b506103bb610ab736600461915e565b612bff565b348015610ac857600080fd5b50610352610ad73660046191e2565b6001600160a01b031660009081526001602052604090205490565b610258612ca6565b348015610b0657600080fd5b50610352610b1536600461919f565b612dc7565b348015610b2657600080fd5b50610b3a610b353660046194f4565b612df0565b6040516001600160801b03909116815260200161035c565b348015610b5e57600080fd5b50600454610b759060ff8082169161010090041682565b60408051921515835290151560208301520161035c565b348015610b9857600080fd5b50610258610ba73660046195c6565b6001600160801b0316601255565b348015610bc157600080fd5b5061035260065481565b348015610bd757600080fd5b50610be0612f82565b60405161035c919061960d565b3415610c5257610bfd8282612f9f565b806001600160a01b031663d0e30db0346040518263ffffffff1660e01b81526004016000604051808303818588803b158015610c3857600080fd5b505af1158015610c4c573d6000803e3d6000fd5b50505050505b5050565b6000610c8b83836000818110610c6e57610c6e619640565b9190910135600481901c60ff60f41b1692600f60f81b9091169150565b9150506001600160f81b031980821601610ccf576000806000610cae8686613035565b925092509250610cc58360ff1660011483836130c2565b5050505050505050565b60fd60f81b6001600160f81b0319821601610d0a576000806000610cf3868661340f565b925092509250610cc58360ff1660011483836134a1565b60fb60f81b6001600160f81b0319821601610d91576040805160a081018252600080825260208201819052918101829052606081018290526080810191909152610d548484613980565b60ff90811660808701526001600160801b039182166060870152911660408501526001600160401b039091166020840152168152610cc581613a5d565b607d60f91b6001600160f81b0319821601610dc857600080610db385856147c3565b91509150610dc18282614827565b5050505050565b60f960f81b6001600160f81b0319821601610e0057600080610dea85856147c3565b91509150610df88282614d46565b505050505050565b60f560f81b6001600160f81b0319821601610e5f576000806000806000806000806000610e2d8c8c6150e2565b985098509850985098509850985098509850610e5089898989898989898961521f565b50505050505050505050505050565b603d60fa1b6001600160f81b0319821601610e8f57600080610e818585615ba8565b91509150610df88282615c14565b604051631b1891ed60e31b815260040160405180910390fd5b505050565b605560f91b6000368181610ec357610ec3619640565b9050013560f81c60f81b6001600160f81b03191614610eee57610eeb6000368363ffffffff16565b50565b610eeb60003683615ecc565b60045460ff16610f1d57604051630f7cede560e41b815260040160405180910390fd5b600080600301805480602002602001604051908101604052809291908181526020018280548015610f7757602002820191906000526020600020905b81546001600160a01b03168152600190910190602001808311610f59575b5050505050905060008151905080600003610f9657610c526000615f89565b6000815b600084610fa860018461966c565b81518110610fb857610fb8619640565b602002602001015190506000806000610fdd84306000615fc79092919063ffffffff16565b91945092509050811561106e576040518281526001600160a01b0385169033907f0b0b821953e5545b71f2085833e4a8dfd0d99bbdff511898672ae8179a982df39060200160405180910390a3836001600160a01b03167f1c711eca8d0b694bbcb0a14462a7006222e721954b2c5ff798f606817eb110328360405161106591815260200190565b60405180910390a25b82156110f8576040518381526001600160a01b0385169033907f49e1443cb25e17cbebc50aa3e3a5a3df3ac334af852bc6f3e8d258558257bb119060200160405180910390a3836001600160a01b03167f80b21748c787c52e87a6b222011e0a0ed0f9cc2015f0ced46748642dc62ee9f8846040516110ef91815260200190565b60405180910390a25b801561119257604080518082019091526001600160a01b03858116825260208201838152600c805460018101825560009190915292517fdf6966c971051c3d54ec59162606531493a51404a002842f56009d7e5cf4a8c7600290940293840180546001600160a01b0319169190931617909155517fdf6966c971051c3d54ec59162606531493a51404a002842f56009d7e5cf4a8c8909101555b60038054806111a3576111a3619683565b6001900381819060005260206000200160006101000a8154906001600160a01b0302191690559055846001900394508560010195505050505080600003610f9a576000600c805480602002602001604051908101604052809291908181526020016000905b82821015611250576000848152602090819020604080518082019091526002850290910180546001600160a01b03168252600190810154828401529083529092019101611208565b5050825192935050505b80156112be57600061126d60018361966c565b90506112b483828151811061128457611284619640565b602002602001015160000151308584815181106112a3576112a3619640565b6020026020010151602001516160ac565b506000190161125a565b6112c86000615f89565b610df8600c6000619071565b6001600160401b03811660009081526008602052604081205463ffffffff63010000009091041661130460125490565b61130e9190619699565b6001600160801b031692915050565b600b546001146113435760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff161561136f5760405160016238ddf760e01b0319815260040160405180910390fd5b61139a60007f0000000000000000000000000000000000000000000000000000000000000000610bed565b6004805460ff191690556113ae8282614827565b6004805460ff191660011790556113c3610efa565b600454610100900460ff166113eb576040516304564c7160e21b815260040160405180910390fd5b50506001600b55565b600080600b5460011461141d5760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff16156114495760405160016238ddf760e01b0319815260040160405180910390fd5b61147460007f0000000000000000000000000000000000000000000000000000000000000000610bed565b6004805460ff1916905560001983146114a3818661149e8261149657876160b8565b60015b6160b8565b6130c2565b6004805460ff1916600117905590935091506114bf9050610efa565b600454610100900460ff166114e7576040516304564c7160e21b815260040160405180910390fd5b6001600b5590939092509050565b60006115028183306160ce565b92915050565b6001600160401b03811660009081526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187015460608088019190915284880154608080890191909152600389015460a0808a019190915260048a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681850152600160481b8804861681840152600160581b880490951690850152600160681b90950490931694820194909452610140850152855191820186526007850154808416835260ff600160a01b918290048116988401989098529490970154918216948101949094529190910490921692810192909252610160810191909152819061168d9061610a565b91509150915091565b600b546001146116bc5760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff16156116e85760405160016238ddf760e01b0319815260040160405180910390fd5b61171360007f0000000000000000000000000000000000000000000000000000000000000000610bed565b6004805460ff191690556001600160401b03871660009081526008602052604090208054600160381b90046001600160a01b03163314611766576040516323019e6760e01b815260040160405180910390fd5b6040805160e0810182526006830154600281900b825261ffff6301000000820481166020840152600160281b8204811693830193909352600160381b810483166060830152600160481b810483166080830152600160581b8104831660a083015263ffffffff600160681b9091041660c0820152908416156117ed5761ffff841660208201525b8260020b60001461180057600283900b81525b61ffff8716156118155761ffff871660408201525b61ffff86161561182a5761ffff861660808201525b61ffff85161561183f5761ffff851660608201525b61ffff8816156118545761ffff881660a08201525b61185e8282616125565b6040805161ffff8a8116825288811660208301528781168284015286811660608301529151600286900b928a16916001600160401b038d16917f149d8f45beb243253e6bf4915f72c467b5a81370cfa27a62c7424755be95e5019181900360800190a450506004805460ff191660011790556118d8610efa565b600454610100900460ff16611900576040516304564c7160e21b815260040160405180910390fd5b50506001600b555050505050565b600b546001146119345760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff16156119605760405160016238ddf760e01b0319815260040160405180910390fd5b61198b60007f0000000000000000000000000000000000000000000000000000000000000000610bed565b6004805460ff191690556113ae600083308461620e565b600080602885901c62ffffff169050600060086000876001600160401b03166001600160401b03168152602001908152602001600020604051806101800160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900463ffffffff1663ffffffff1663ffffffff1681526020016000820160079054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820154815260200160028201548152602001600382015481526020016004820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016004820160109054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160109054906101000a9004600f0b600f0b600f0b8152602001600682016040518060e00160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900461ffff1661ffff1661ffff1681526020016000820160059054906101000a900461ffff1661ffff1661ffff1681526020016000820160079054906101000a900461ffff1661ffff1661ffff1681526020016000820160099054906101000a900461ffff1661ffff1661ffff16815260200160008201600b9054906101000a900461ffff1661ffff1661ffff16815260200160008201600d9054906101000a900463ffffffff1663ffffffff1663ffffffff16815250508152602001600782016040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff1681525050815250509050611db9600760008462ffffff1662ffffff1681526020019081526020016000206040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff16815250508686846020015163ffffffff16611d9c60125490565b611da69190619699565b85939291906001600160801b0316616229565b509695505050505050565b600b54600114611dea5760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff1615611e165760405160016238ddf760e01b0319815260040160405180910390fd5b611e4160007f0000000000000000000000000000000000000000000000000000000000000000610bed565b6004805460ff191690556113ae8282610c56615ecc565b6001600160401b03821660009081526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187015460608088019190915284880154608080890191909152600389015460a0808a019190915260048a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681850152600160481b8804861681840152600160581b880490951690850152600160681b909504841695830195909552610140860191909152865192830187526007860154808216845260ff600160a01b9182900481169985019990995295909801549788169582019590955292909504909316938101939093526101608201929092528291611fe39190859061652b16565b915091505b9250929050565b6000611ffa826165c0565b50909392505050565b600b546001146120295760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff16156120555760405160016238ddf760e01b0319815260040160405180910390fd5b61208060007f0000000000000000000000000000000000000000000000000000000000000000610bed565b6004805460ff191681556001600160401b03841660008181526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187810154606080890191909152858901546080808a019190915260038a015460a0808b01919091529f8a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681840152600160481b8804861681830152600160581b88049095169f85019f909f52600160681b9095049093169482019490945261014085015285519a8b01865260078501548084168c52600160a01b9081900460ff9081168d8a015295909801549283168b8701529690910490921691880191909152610160810196909652338452600a825280842094845293905291812091820154900361224e57604051632f9b02db60e11b81523360048201526001600160401b03861660248201526044015b60405180910390fd5b61227a8260e001516001600160801b031683608001518460a00151846167e8909392919063ffffffff16565b5050612285846160b8565b6007820180546000906122a29084906001600160801b0316619699565b92506101000a8154816001600160801b0302191690836001600160801b031602179055506122cf836160b8565b6007820180546010906122f3908490600160801b90046001600160801b0316619699565b92506101000a8154816001600160801b0302191690836001600160801b031602179055506000841115612331576101608201515161233190856168db565b821561234a5761234a82610160015160400151846168db565b6123718261010001516001600160801b031683606001518361692d9092919063ffffffff16565b506008810180546001600160801b031690819060006123908380619699565b92506101000a8154816001600160801b0302191690836001600160801b031602179055506000816001600160801b03161115612485576123f97f0000000000000000000000000000000000000000000000000000000000000000826001600160801b03166168db565b806001600160801b031661242d307f0000000000000000000000000000000000000000000000000000000000000000612dc7565b101561244c576040516314414f4160e11b815260040160405180910390fd5b6124826000307f00000000000000000000000000000000000000000000000000000000000000006001600160801b0385166169a5565b50505b610160830151604080820151915181516001600160401b038a168152336020820152918201889052606082018790526001600160801b03841660808301526001600160a01b037f00000000000000000000000000000000000000000000000000000000000000008116938116929116907f8c84cdba09392140d3a3451ef9fd7f258a06ace3b8492bc20598872a630084d49060a00160405180910390a450506004805460ff191660011790555061253a610efa565b600454610100900460ff16612562576040516304564c7160e21b815260040160405180910390fd5b50506001600b5550565b600b546001146125925760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff16156125be5760405160016238ddf760e01b0319815260040160405180910390fd5b6125e960007f0000000000000000000000000000000000000000000000000000000000000000610bed565b6004805460ff191690556113ae8282610c56565b6001600160401b03811660009081526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187015460608088019190915284880154608080890191909152600389015460a0808a019190915260048a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681850152600160481b8804861681840152600160581b880490951690850152600160681b90950490931694820194909452610140850152855191820186526007850154808416835260ff600160a01b918290048116988401989098529490970154918216948101949094529190910490921692810192909252610160810191909152819061168d90616a7b565b600080600b546001146127ab5760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff16156127d75760405160016238ddf760e01b0319815260040160405180910390fd5b61280260007f0000000000000000000000000000000000000000000000000000000000000000610bed565b6004805460ff191690556001830161281f576001600160801b0392505b600019841460008161283957612834866160b8565b612842565b6001600160801b035b90506128b76040518060a001604052808461285e576000612861565b60015b60ff1681526020018a6001600160401b03168152602001836001600160801b03168152602001612890886160b8565b6001600160801b03168152602001896128aa5760016128ad565b60005b60ff169052613a5d565b6004805460ff1916600117905596509094506128d79350610efa92505050565b600454610100900460ff166128ff576040516304564c7160e21b815260040160405180910390fd5b6001600b55909590945092505050565b600b546001146129355760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff16156129615760405160016238ddf760e01b0319815260040160405180910390fd5b61298c60007f0000000000000000000000000000000000000000000000000000000000000000610bed565b6004805460ff191690556129a08282614d46565b506004805460ff191660011790556113c3610efa565b600b546001146129dc5760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff1615612a085760405160016238ddf760e01b0319815260040160405180910390fd5b612a3360007f0000000000000000000000000000000000000000000000000000000000000000610bed565b6004805460ff19169055306001600160a01b03821603612a6657604051632f35253160e01b815260040160405180910390fd5b612a703384612dc7565b821115612a905760405163327cbc9b60e21b815260040160405180910390fd5b612a9a8383616ad7565b612aa48383616b23565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316836001600160a01b031603612b0d57612b087f00000000000000000000000000000000000000000000000000000000000000008284616b76565b612b18565b612b18838284616bda565b6004805460ff1916600117905561253a610efa565b600b54600114612b535760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff1615612b7f5760405160016238ddf760e01b0319815260040160405180910390fd5b612baa60007f0000000000000000000000000000000000000000000000000000000000000000610bed565b6004805460ff19169055605560f91b8282600081612bca57612bca619640565b9050013560f81c60f81b6001600160f81b03191614612bf257612bed8282610c56565b6113ae565b6113ae8282610c56615ecc565b600080600b54600114612c285760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff1615612c545760405160016238ddf760e01b0319815260040160405180910390fd5b612c7f60007f0000000000000000000000000000000000000000000000000000000000000000610bed565b6004805460ff1916905560001983146114a38186612ca18261149657876160b8565b6134a1565b600b54600114612ccc5760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff1615612cf85760405160016238ddf760e01b0319815260040160405180910390fd5b612d2360007f0000000000000000000000000000000000000000000000000000000000000000610bed565b6004805460ff1916905534600003612d4e57604051637c946ed760e01b815260040160405180910390fd5b60405134815233907fe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c9060200160405180910390a26004805460ff19166001179055612d98610efa565b600454610100900460ff16612dc0576040516304564c7160e21b815260040160405180910390fd5b6001600b55565b6001600160a01b0391821660009081526020818152604080832093909416825291909152205490565b6001600160401b03831660009081526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187015460608088019190915284880154608080890191909152600389015460a0808a019190915260048a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681850152600160481b8804861681840152600160581b880490951690850152600160681b909504841695830195909552610140860191909152865192830187526007860154808216845260ff600160a01b918290048116998501999099529590980154978816958201959095529290950490931693810193909352610160820192909252612f7a9185908590616c5816565b949350505050565b606060206000526b10626574612d76302e302e3160305260606000f35b6004820154610100900460ff1615612fbf5760048201805461ff00191690555b6001600160a01b038116600090815260028301602052604090205460ff16610c5257600382018054600180820183556000928352602080842090920180546001600160a01b0386166001600160a01b031990911681179091558352600285019091526040909120805460ff191690911790555050565b600080806009841015613065576040516370cee4af60e11b81526009600482015260248101859052604401612245565b600061307d86866000818110610c6e57610c6e619640565b5060f881901c945090506130956009600187896196c1565b61309e916196eb565b60c01c92506130b86130b3866009818a6196c1565b616ca9565b9150509250925092565b6001600160401b03821660009081526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187015460608088019190915284880154608080890191909152600389015460a0808a019190915260048a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681850152600160481b8804861681840152600160581b880490951690850152600160681b90950490931694820194909452610140850152855191820186526007850154808416835260ff600160a01b9182900481169884019890985294909701549182169481019490945291909104909216928101929092526101608101919091528190613251816020015163ffffffff16151590565b61327957604051636a2406a360e11b81526001600160401b0386166004820152602401612245565b85156132b3576132b06132953383610160015160000151612dc7565b6132a83384610160015160400151612dc7565b839190616c58565b93505b836001600160801b03166000036132dd57604051630200e8a960e31b815260040160405180910390fd5b6132f06132e985616d42565b829061652b565b60408051610100810182523381526001600160401b03891660208201526001600160801b039384169650919092169350600091810161332e60125490565b6001600160801b03168152602001858152602001848152602001836101600151600001516001600160a01b03168152602001836101600151604001516001600160a01b0316815260200161338187616d42565b600f0b9052905061339181616d58565b505061016082015160408082015191518151878152602081018790526001600160801b038916928101929092526001600160a01b039283169216906001600160401b038916907ffdffeca751f0dcaab75531cb813c12bbfd56ee3e964cc471d7ef43932402ee18906060015b60405180910390a45050935093915050565b60008080600984101561343f576040516370cee4af60e11b81526009600482015260248101859052604401612245565b60048585600081811061345457613454619640565b909101356001600160f81b03191690911c60f81c935061347a90506009600186886196c1565b613483916196eb565b60c01c91506134986130b385600981896196c1565b90509250925092565b60008084156134da57336000908152600a602090815260408083206001600160401b03881684529091529020546001600160801b031692505b826001600160801b031660000361350457604051630200e8a960e31b815260040160405180910390fd5b600060086000866001600160401b03166001600160401b03168152602001908152602001600020604051806101800160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900463ffffffff1663ffffffff1663ffffffff1681526020016000820160079054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820154815260200160028201548152602001600382015481526020016004820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016004820160109054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160109054906101000a9004600f0b600f0b600f0b8152602001600682016040518060e00160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900461ffff1661ffff1661ffff1681526020016000820160059054906101000a900461ffff1661ffff1661ffff1681526020016000820160079054906101000a900461ffff1661ffff1661ffff1681526020016000820160099054906101000a900461ffff1661ffff1661ffff16815260200160008201600b9054906101000a900461ffff1661ffff1661ffff16815260200160008201600d9054906101000a900463ffffffff1663ffffffff1663ffffffff16815250508152602001600782016040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff1681525050815250509050613829816020015163ffffffff16151590565b61385157604051636a2406a360e11b81526001600160401b0386166004820152602401612245565b61386661385d85616d42565b6132e990619719565b60408051610100810182523381526001600160401b03891660208201526001600160801b03938416965091909216935060009181016138a460125490565b6001600160801b03168152602001858152602001848152602001836101600151600001516001600160a01b03168152602001836101600151604001516001600160a01b031681526020016138f787616d42565b61390090619719565b600f0b9052905061391081616d58565b505061016082015160408082015191518151878152602081018790526001600160801b038916928101929092526001600160a01b039283169216906001600160401b038916907ffe322c782fa8cb650f7deaac661d6e7aacbaa8034eae3b8c3afd1490bed1be1e906060016133fd565b600080600080600060048787600081811061399d5761399d619640565b909101356001600160f81b03191690911c60f81c95506139c3905060096001888a6196c1565b6139cc916196eb565b60c01c93506000878760098181106139e6576139e6619640565b919091013560f81c9150613a0290506130b382600a8a8c6196c1565b9350613a258860ff831689613a1860018261966c565b926130b3939291906196c1565b92508787613a3460018261966c565b818110613a4357613a43619640565b9050013560f81c60f81b60f81c9150509295509295909350565b60008060008084604001516001600160801b0316600003613a915760405163af458c0760e01b815260040160405180910390fd5b60006008600087602001516001600160401b03166001600160401b031681526020019081526020016000209050613dba81604051806101800160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900463ffffffff1663ffffffff1663ffffffff1681526020016000820160079054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820154815260200160028201548152602001600382015481526020016004820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016004820160109054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160109054906101000a9004600f0b600f0b600f0b8152602001600682016040518060e00160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900461ffff1661ffff1661ffff1681526020016000820160059054906101000a900461ffff1661ffff1661ffff1681526020016000820160079054906101000a900461ffff1661ffff1661ffff1681526020016000820160099054906101000a900461ffff1661ffff1661ffff16815260200160008201600b9054906101000a900461ffff1661ffff1661ffff16815260200160008201600d9054906101000a900463ffffffff1663ffffffff1663ffffffff16815250508152602001600782016040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff1681525050815250506020015163ffffffff16151590565b613de8576020860151604051636a2406a360e11b81526001600160401b039091166004820152602401612245565b6080860151600d805460ff9092161560ff199092169190911790558054600160381b90046001600160a01b03163314613e30576006810154600160281b900461ffff16613e41565b6006810154600160581b900461ffff165b600f55600d5460ff16613e58578060030154613e5e565b80600201545b601055600d5460ff16613e7e5760088101546001600160a01b0316613e8d565b60078101546001600160a01b03165b600d80546001600160a01b039290921661010002610100600160a81b03198316811790915560ff908116911617613ed15760078101546001600160a01b0316613ee0565b60088101546001600160a01b03165b600e80546001600160a01b0319166001600160a01b03929092169190911790556040805161014081019091526006820154600281900b606083019081526301000000820461ffff9081166080850152600160281b8304811660a0850152600160381b8304811660c0850152600160481b8304811660e0850152600160581b830416610100840152600160681b90910463ffffffff16610120830152600091908190613f8a90616ddf565b81526020018360060160000160099054906101000a900461ffff1661ffff16815260200160008152509050613ff86040518060e00160405280600060020b81526020016000815260200160008152602001600081526020016000815260200160008152602001600081525090565b600080600061400a8b602001516165c0565b60408801819052600d54929550909350915060009061405290339060ff1661403f5760088901546001600160a01b0316612dc7565b60078901546001600160a01b0316612dc7565b90508b6000015160ff16600114614076578b604001516001600160801b0316614078565b805b600d54909a506140b79060ff1661409d576008880154600160a01b900460ff166140ad565b6007880154600160a01b900460ff165b8b9060ff16616dee565b99506040518060e001604052808460020b81526020018581526020018b8152602001600081526020018860040160109054906101000a90046001600160801b03166001600160801b03168152602001600081526020016000815250945050505050816040015160000361413d5760405163398b36db60e01b815260040160405180910390fd5b600d5460009081908190819081908190819060ff1615614195576020880151614167908a90616e05565b60808a015190985090955061418e9061418889670de0b6b3a764000061966c565b90616e45565b91506141c4565b60208801516141a5908a90616e05565b60808a01518b519299509096506141c191614188908a9061966c565b91505b8954600160381b90046001600160a01b031633146141e3576000614212565b600f5460048b01546127109161420891600160801b90046001600160801b031661973f565b6142129190619774565b92508260000361425557612710600d60020154838a604001511161423a57896040015161423c565b835b614246919061973f565b6142509190619774565b614258565b60005b60608901819052608089015161426e9190616e61565b601055821561428b576080880151614287908490616e61565b6011555b81886040015111156142f45760608801516142a6908361966c565b90506142bf886080015182616e6190919063ffffffff16565b6142c99088619788565b95508760600151816142db9190619788565b886040018181516142ec919061966c565b90525061433c565b87606001518860400151614308919061966c565b9050614321886080015182616e6190919063ffffffff16565b61432b9088619788565b604089018051600090915290965090505b600d5460ff1615614358576143518987616e76565b9350614365565b6143628987616e92565b93505b808860a0018181516143779190619788565b905250614384848661966c565b8860c0018181516143959190619788565b905250505060608d0151600d546000916001600160801b0316908290819060ff16156143e6576143c68b888b616eae565b91506143d38b878a616eae565b90506143df8b89616ee0565b935061440d565b6143f18b8a89616eae565b91506143fe8b8988616eae565b905061440a8b87616ee0565b93505b600d5460ff1615801561441f57508284115b1561443d5760405163a3869ab760e01b815260040160405180910390fd5b600d5460ff16801561444e57508383115b1561446c5760405163a3869ab760e01b815260040160405180910390fd5b60088c0154614486908390600160a01b900460ff16616efa565b60088d01549092506144a3908290600160a01b900460ff16616efa565b9050818112156144d057604051630424b42d60e31b81526004810183905260248101829052604401612245565b629896806144e1856298968161973f565b6144eb9190619774565b60208b01525050600d546000925082915060ff16156145275750506007880154600889015460ff600160a01b9283900481169290910416614546565b50506008880154600789015460ff600160a01b92839004811692909104165b60a08801516145559083616f10565b60a089015260c08801516145699082616f29565b8860c001818152505050506145c58d602001516145898860200151616f3f565b602089015160808a0151600d5460ff166145a45760006145a8565b6010545b600d5460ff166145ba576010546145bd565b60005b601154616f77565b50600d5460a08701516145e69161010090046001600160a01b0316906170fa565b600e5460c0870151614601916001600160a01b031690616b23565b80156146be576146317f0000000000000000000000000000000000000000000000000000000000000000826170fa565b6040518181526001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000169030907f49e1443cb25e17cbebc50aa3e3a5a3df3ac334af852bc6f3e8d258558257bb119060200160405180910390a36146be6000307f000000000000000000000000000000000000000000000000000000000000000084617141565b600d60010160009054906101000a90046001600160a01b03166001600160a01b0316600d60000160019054906101000a90046001600160a01b03166001600160a01b03168e602001516001600160401b03167f6ad6899405e7539158789043be9745c5def4f806aeb268c3c788953ff4f3c01089602001518a60a001518b60c00151604051614760939291909283526020830191909152604082015260600190565b60405180910390a45050600d80546001600160a81b03191690555050600e80546001600160a01b0319169055506000600f819055601081905560115560209790970151604088015160a089015160c0909901519199909897509095509350505050565b60008060098310156147f2576040516370cee4af60e11b81526009600482015260248101849052604401612245565b6148006009600185876196c1565b614809916196eb565b60c01c915061481e6130b384600981886196c1565b90509250929050565b600060086000846001600160401b03166001600160401b031681526020019081526020016000209050614b4c81604051806101800160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900463ffffffff1663ffffffff1663ffffffff1681526020016000820160079054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820154815260200160028201548152602001600382015481526020016004820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016004820160109054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160109054906101000a9004600f0b600f0b600f0b8152602001600682016040518060e00160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900461ffff1661ffff1661ffff1681526020016000820160059054906101000a900461ffff1661ffff1661ffff1681526020016000820160079054906101000a900461ffff1661ffff1661ffff1681526020016000820160099054906101000a900461ffff1661ffff1661ffff16815260200160008201600b9054906101000a900461ffff1661ffff1661ffff16815260200160008201600d9054906101000a900463ffffffff1663ffffffff1663ffffffff16815250508152602001600782016040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff1681525050815250506020015163ffffffff16151590565b614b7457604051636a2406a360e11b81526001600160401b0384166004820152602401612245565b336000908152600a602090815260408083206001600160401b0387168452825280832081516101608101835281546001600160801b038082168352600160801b918290048116958301959095526001830154938201939093526002820154606082015260038201546080820152600482015460a0820152600582015460c0820152600682015460e08201526007820154808516610100830152929092048316610120830152600801548216610140820152919084169003614c4857604051630200e8a960e31b815260040160405180910390fd5b80516001600160801b0380851691161015614c81576040516326e66cc760e11b81526001600160401b0385166004820152602401612245565b6000614c9585614c9086616d42565b61718b565b9050614ca084616d42565b600584018054601090614cbe908490600160801b9004600f0b6197a0565b92506101000a8154816001600160801b030219169083600f0b6001600160801b03160217905550336001600160a01b0316856001600160401b03167fc37a962db40f0f2a72f4a9ee4760e142ff06e5fb57cb4f23f494cbec9718e60586604051614d3791906001600160801b0391909116815260200190565b60405180910390a35050505050565b6001600160401b03821660009081526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187015460608088019190915284880154608080890191909152600389015460a0808a019190915260048a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681850152600160481b8804861681840152600160581b880490951690850152600160681b90950490931694820194909452610140850152855191820186526007850154808416835260ff600160a01b91829004811698840198909852978501549283169582019590955295900490931691840191909152610160820192909252614ed1906020015163ffffffff16151590565b614ef957604051636a2406a360e11b81526001600160401b0385166004820152602401612245565b6000614f0460125490565b336000908152600a602090815260408083206001600160401b038a168452825280832081516101608101835281546001600160801b038181168352600160801b9182900481169583019590955260018301549382019390935260028201546060820181905260038301546080830152600483015460a0830152600583015460c0830152600683015460e0830152600783015480861661010084015293909304841661012082015260089091015483166101408201529390911693509003614fe957604051630c47736b60e11b81526001600160401b0387166004820152602401612245565b81816080015111156150195760405163a4093bbf60e01b81526001600160401b0387166004820152602401612245565b61502f8661502687616d42565b614c9090619719565b935061503a85616d42565b600584018054601090615058908490600160801b9004600f0b6197ef565b92506101000a8154816001600160801b030219169083600f0b6001600160801b03160217905550336001600160a01b0316866001600160401b03167f850fd333bb55261aab49c7ed91d737f7c21674d43968a564ede778e0735d856f876040516150d191906001600160801b0391909116815260200190565b60405180910390a350505092915050565b6000808080808080808060358a14615117576040516370cee4af60e11b815260356004820152602481018b9052604401612245565b615125600460018c8e6196c1565b61512e9161983f565b60e81c9850615141601860048c8e6196c1565b61514a9161986c565b60601c975061515d601a60188c8e6196c1565b6151669161989f565b60f01c9650615179601c601a8c8e6196c1565b6151829161989f565b60f01c9550615195601e601c8c8e6196c1565b61519e9161989f565b60f01c94506151b16020601e8c8e6196c1565b6151ba9161989f565b60f01c93506151cd602260208c8e6196c1565b6151d69161989f565b60f01c92506151e9602560228c8e6196c1565b6151f29161983f565b60e81c91506152048a6025818e6196c1565b61520d916198cd565b60801c90509295985092959850929598565b6000816001600160801b031660000361524b57604051634dfba02360e01b815260040160405180910390fd5b600061526761525960125490565b6001600160801b03166175c2565b905061531d6040805161018081018252600080825260208083018290528284018290526060808401839052608080850184905260a080860185905260c080870186905260e0808801879052610100880187905261012088018790528851908101895286815294850186905296840185905291830184905282018390528101829052928301529061014082019081526040805160808101825260008082526020828101829052928201819052606082015291015290565b6001600160a01b038b16604082015263ffffffff821660208201526001600160801b03841660c0820181905261535290616f3f565b60020b815260408101516001600160a01b0316158015908190615377575061ffff8b16155b1561539b5760405163f6f4a38f60e01b815261ffff8c166004820152602401612245565b600062ffffff8e16156153ae578d6153b2565b6005545b62ffffff81166000908152600760209081526040808320815160808101835281546001600160a01b03808216835260ff600160a01b9283900481168488015260019094015490811683860152049091166060820152610160880152805160e0810190915260028b900b81529293509091908101846154355760135460ff16615437565b8a5b61ffff1681526020018d61ffff1681526020018b61ffff1681526020018c61ffff1681526020018461546a57600061546c565b8e5b61ffff1681526020018663ffffffff16815250905061548a816175d5565b5050610140840181905260068054600101908190556154aa838583617600565b96506157cc60086000896001600160401b03166001600160401b03168152602001908152602001600020604051806101800160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900463ffffffff1663ffffffff1663ffffffff1681526020016000820160079054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820154815260200160028201548152602001600382015481526020016004820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016004820160109054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160109054906101000a9004600f0b600f0b600f0b8152602001600682016040518060e00160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900461ffff1661ffff1661ffff1681526020016000820160059054906101000a900461ffff1661ffff1661ffff1681526020016000820160079054906101000a900461ffff1661ffff1661ffff1681526020016000820160099054906101000a900461ffff1661ffff1661ffff16815260200160008201600b9054906101000a900461ffff1661ffff1661ffff16815260200160008201600d9054906101000a900463ffffffff1663ffffffff1663ffffffff16815250508152602001600782016040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff1681525050815250506020015163ffffffff16151590565b156157ea57604051637a471e1360e11b815260040160405180910390fd5b8460086000896001600160401b03166001600160401b0316815260200190815260200160002060008201518160000160006101000a81548162ffffff021916908360020b62ffffff16021790555060208201518160000160036101000a81548163ffffffff021916908363ffffffff16021790555060408201518160000160076101000a8154816001600160a01b0302191690836001600160a01b03160217905550606082015181600101556080820151816002015560a0820151816003015560c08201518160040160006101000a8154816001600160801b0302191690836001600160801b0316021790555060e08201518160040160106101000a8154816001600160801b0302191690836001600160801b031602179055506101008201518160050160006101000a8154816001600160801b0302191690836001600160801b031602179055506101208201518160050160106101000a8154816001600160801b030219169083600f0b6001600160801b031602179055506101408201518160060160008201518160000160006101000a81548162ffffff021916908360020b62ffffff16021790555060208201518160000160036101000a81548161ffff021916908361ffff16021790555060408201518160000160056101000a81548161ffff021916908361ffff16021790555060608201518160000160076101000a81548161ffff021916908361ffff16021790555060808201518160000160096101000a81548161ffff021916908361ffff16021790555060a082015181600001600b6101000a81548161ffff021916908361ffff16021790555060c082015181600001600d6101000a81548163ffffffff021916908363ffffffff16021790555050506101608201518160070160008201518160000160006101000a8154816001600160a01b0302191690836001600160a01b0316021790555060208201518160000160146101000a81548160ff021916908360ff16021790555060408201518160010160006101000a8154816001600160a01b0302191690836001600160a01b0316021790555060608201518160010160146101000a81548160ff021916908360ff1602179055505050905050846101600151604001516001600160a01b0316856101600151600001516001600160a01b0316886001600160401b03167f7609f45e16378bb0782884719ba24d3bbc5ab6a373b9eacacc25c6143b87cf77878c604051615b8d92919091151582526001600160801b0316602082015260400190565b60405180910390a45050505050509998505050505050505050565b60008060298314615bd6576040516370cee4af60e11b81526029600482015260248101849052604401612245565b615be46015600185876196c1565b615bed9161986c565b60601c9150615bff83601581876196c1565b615c089161986c565b60601c90509250929050565b6000816001600160a01b0316836001600160a01b031603615c4857604051633b0e2de560e21b815260040160405180910390fd5b506001600160a01b0380831660009081526009602090815260408083209385168352929052205462ffffff168015615c9a57604051633325fa7760e01b815262ffffff82166004820152602401612245565b600080846001600160a01b031663313ce5676040518163ffffffff1660e01b8152600401602060405180830381865afa158015615cdb573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190615cff91906198fb565b846001600160a01b031663313ce5676040518163ffffffff1660e01b8152600401602060405180830381865afa158015615d3d573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190615d6191906198fb565b9092509050615d7660ff831660066012617676565b615d985760405163ca95039160e01b815260ff83166004820152602401612245565b615da860ff821660066012617676565b615dca5760405163ca95039160e01b815260ff82166004820152602401612245565b600580546001908101918290556001600160a01b0387811660008181526009602090815260408083208b8616808552908352818420805462ffffff191662ffffff8a16908117909155825160808101845286815260ff8c81168287018181528387018681528e841660608601818152878c5260078b529a899020955186549351908e166001600160a81b031994851617600160a01b9187168202178755915195909d0180549a5195909c169990911698909817929091169096021790965581519384529183019590955294975090927fc0c5df98a4ca87a321a33bf1277cf32d31a97b6ce14b9747382149b9e2631ea3910160405180910390a4505092915050565b600083836001818110615ee157615ee1619640565b919091013560f81c9150600290506000805b8360ff168114610c4c5760ff83169150868683818110615f1557615f15619640565b919091013560f81c93505085831115615f46576040516380f63bd160e01b815260ff84166004820152602401612245565b366000615f5860ff8616858a8c6196c1565b9092509050615f76615f6d82600181866196c1565b8963ffffffff16565b505080615f829061991e565b9050615ef3565b600381015415615f9b57615f9b619937565b60048101805461ff001916610100179055615fba600382016000619092565b600401805460ff19169055565b6000808080615fd78787876160ce565b9050600081131561602657925082615ff187338884617141565b6001600160a01b03861660009081526001880160205260408120805483929061601b908490619788565b909155506160819050565b6000811215616081576160388161994d565b9150616046873388856169a5565b90935091508215616081576001600160a01b03861660009081526001880160205260408120805485929061607b90849061966c565b90915550505b506001600160a01b03909416600090815260029095016020526040909420805460ff19169055939050565b610ea883338484617683565b6000600160801b82106160ca57600080fd5b5090565b6001600160a01b0382166000908152600184016020526040812054816160f4858561770a565b90506161008282619969565b9695505050505050565b60008061168d8360e0015161611e90619719565b849061652b565b6000616130826175d5565b508251600685018054602086015160408701516060880151608089015160a08a015160c08b015162ffffff90981664ffffffffff1990961695909517630100000061ffff958616021768ffffffff00000000001916600160281b9385169390930268ffff00000000000000191692909217600160381b91841691909102176cffffffff0000000000000000001916600160481b9183169190910261ffff60581b191617600160581b91909216021763ffffffff60681b1916600160681b63ffffffff90931692909202919091179055905080610ea857610ea8619937565b6162188484612f9f565b6162238383836160ac565b50505050565b60008061626f6040518060e00160405280600060020b81526020016000815260200160008152602001600081526020016000815260200160008152602001600081525090565b600061627a896177f3565b90506162906162888a617859565b8a9087617878565b60020b835260208301526162bc876162ac5788606001516162b2565b88602001515b879060ff16616dee565b604083015260e08901516001600160801b03166080830152600080808080808c156163255760208801516162f1908890616e05565b809750819650505061631e8f60e001516001600160801b031687670de0b6b3a7640000614188919061966c565b9150616361565b6020880151616335908890616e05565b809650819750505061635e8f60e001516001600160801b0316878960000151614188919061966c565b91505b6127108f61014001516040015161ffff16838a6040015111616387578960400151616389565b835b616393919061973f565b61639d9190619774565b6060890152604088015182101561640b5760608801516163bd908361966c565b90506163d6886080015182616e6190919063ffffffff16565b6163e09087619788565b93508760600151816163f29190619788565b88604001818151616403919061966c565b905250616453565b8760600151886040015161641f919061966c565b9050616438886080015182616e6190919063ffffffff16565b6164429087619788565b604089018051600090915290945090505b8c1561646a576164638785616e76565b9250616477565b6164748785616e92565b92505b808860a0018181516164899190619788565b905250616496838661966c565b8860c0018181516164a79190619788565b905250600091508190508c156164d0578d6020015160ff1691508d6060015160ff1690506164e5565b8d6060015160ff1691508d6020015160ff1690505b60a08801516164f49083616f10565b60a089015260c08801516165089082616f29565b60c08901819052604090980151979f979e50969c50505050505050505050505050565b600080600f83900b15611fe85760008061654486616a7b565b9150915060008086600f0b131561658357506001600160801b03851661656d61149984836178ce565b945061657c61149983836178ce565b93506165b6565b61658c86619719565b6001600160801b031690506165a46114998483616e45565b94506165b36114998383616e45565b93505b5050509250929050565b6001600160401b03811660009081526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187015460608088019190915284880154608080890191909152600389015460a0808a019190915260048a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681850152600160481b8804861681840152600160581b880490951690850152600160681b90950490931694820194909452610140850152855191820186526007850154808416835260ff600160a01b91829004811698840198909852949097015491821694810194909452919091049092169281019290925261016081019190915281908190616751816020015163ffffffff16151590565b61677957604051636a2406a360e11b81526001600160401b0386166004820152602401612245565b60c0810151815161679c61678c60125490565b84906001600160801b03166178e3565b6001600160801b0390921695509350915060006167b8866112d4565b905080156167df5760006167cb83617859565b90506167d8838284617878565b9096509450505b50509193909250565b60008060006167fb858860050154900390565b9050600061680d858960060154900390565b90506168198288616e45565b93506168258188616e45565b6005890187905560068901869055925061683e846160b8565b60078901805460009061685b9084906001600160801b03166199a8565b92506101000a8154816001600160801b0302191690836001600160801b03160217905550616888836160b8565b6007890180546010906168ac908490600160801b90046001600160801b03166199a8565b92506101000a8154816001600160801b0302191690836001600160801b03160217905550505094509492505050565b6168e86000338484617141565b6040518181526001600160a01b0383169033907f49e1443cb25e17cbebc50aa3e3a5a3df3ac334af852bc6f3e8d258558257bb11906020015b60405180910390a35050565b60008061693e838660040154900390565b905061694a8185616e45565b60048601819055915061695c826160b8565b6008860180546000906169799084906001600160801b03166199a8565b92506101000a8154816001600160801b0302191690836001600160801b03160217905550509392505050565b6000806169b28685612f9f565b6001600160a01b0380861660009081526020888152604080832093881683529290522054838110616a24576001600160a01b0380871660009081526020898152604080832093891683529290529081208054869550859290616a1590849061966c565b9091555060009250616a719050565b6001600160a01b03808716600090815260208981526040808320938916835292905290812080549294508492839290616a5e90849061966c565b90915550616a6e9050838561966c565b91505b5094509492505050565b600080600080616a8a85617918565b91509150616aad8561016001516020015160ff1683616f2990919063ffffffff16565b9350616ace8561016001516060015160ff1682616f2990919063ffffffff16565b92505050915091565b616ae460003384846169a5565b50506040518181526001600160a01b0383169033907f0b0b821953e5545b71f2085833e4a8dfd0d99bbdff511898672ae8179a982df390602001616921565b616b2f6000838361795c565b816001600160a01b03167f1c711eca8d0b694bbcb0a14462a7006222e721954b2c5ff798f606817eb1103282604051616b6a91815260200190565b60405180910390a25050565b604051632e1a7d4d60e01b8152600481018290526001600160a01b03841690632e1a7d4d90602401600060405180830381600087803b158015616bb857600080fd5b505af1158015616bcc573d6000803e3d6000fd5b50505050610ea882826179d6565b600060405163a9059cbb60e01b6000528360045282602452602060006044600080895af13d15601f3d11600160005114161716915060006060528060405250806162235760405162461bcd60e51b815260206004820152600f60248201526e1514905394d1915497d19052531151608a1b6044820152606401612245565b6000806000616c6686616a7b565b90925090506000616c778684616e61565b90506000616c858684616e61565b9050616c9d818310616c9757816160b8565b826160b8565b98975050505050505050565b60008083836000818110616cbf57616cbf619640565b919091013560f81c9150616d159050616cdb84600181886196c1565b8080601f016020809104026020016040519081016040528093929190818152602001838380828437600092019190915250617a6492505050565b60801c915060ff811615616d3b57616d2e81600a619ab7565b616d389083619ac6565b91505b5092915050565b600060016001607f1b038211156160ca57600080fd5b602081810180516001600160401b03908116600090815260088452604080822086516001600160a01b03168352600a8652818320945190931682529290935290822060048201546002830154600384015485949392616dca928492600160801b9092046001600160801b0316916167e8565b9094509250616dd885617a75565b5050915091565b60006115028260000151617bcb565b600080616dfa83617bf8565b939093029392505050565b600080616e2083856000015186602001518760400151617c10565b9050616e3c818560000151866020015187604001516000617d22565b91509250929050565b6000616e5a8383670de0b6b3a7640000617d3f565b9392505050565b6000616e5a83670de0b6b3a764000084617d3f565b6000616e5a828460000151856020015186604001516000617d22565b6000616e5a828460000151856020015186604001516000617d5e565b6000612f7a83838660000151616ed68860200151612710670de0b6b3a7640000919091020490565b8860400151617d7b565b6000616e5a82846000015185602001518660400151617d98565b600080616f0683617bf8565b9093059392505050565b600080616f1c83617bf8565b9093046001019392505050565b600080616f3583617bf8565b9093049392505050565b600080616f4b83617ec1565b90506000616f60670de111a6b7de4000617ec1565b9050616f6c8183619af5565b612f7a906001619b23565b6001600160401b038716600090815260086020526040812081616f9960125490565b6001600160801b03169050616fad8a6112d4565b92506001808410616fea576005830154616fdb906001600160801b03811690600160801b9004600f0b61809c565b6001600160801b031660058401555b825460028b810b91900b1461700b57825462ffffff191662ffffff8b161783555b60048301546001600160801b0316891461704b57617028896160b8565b6004840180546001600160801b0319166001600160801b03929092169190911790555b6004830154600160801b90046001600160801b0316881461708f5761706f886160b8565b6004840180546001600160801b03928316600160801b0292169190911790555b82546301000000900463ffffffff1682146170ae576170ae8383618120565b6170bc83600201548861814d565b600284015560038301546170d0908761814d565b600384015560018301546170e4908661814d565b8360010181905550505050979650505050505050565b61710660008383618159565b816001600160a01b03167f80b21748c787c52e87a6b222011e0a0ed0f9cc2015f0ced46748642dc62ee9f882604051616b6a91815260200190565b61714b8483612f9f565b6001600160a01b0380841660009081526020868152604080832093861683529290529081208054839290617180908490619788565b909155505050505050565b60008061719760125490565b6001600160801b03169050600060086000866001600160401b03166001600160401b03168152602001908152602001600020604051806101800160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900463ffffffff1663ffffffff1663ffffffff1681526020016000820160079054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820154815260200160028201548152602001600382015481526020016004820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016004820160109054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160109054906101000a9004600f0b600f0b600f0b8152602001600682016040518060e00160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900461ffff1661ffff1661ffff1681526020016000820160059054906101000a900461ffff1661ffff1661ffff1681526020016000820160079054906101000a900461ffff1661ffff1661ffff1681526020016000820160099054906101000a900461ffff1661ffff1661ffff16815260200160008201600b9054906101000a900461ffff1661ffff1661ffff16815260200160008201600d9054906101000a900463ffffffff1663ffffffff1663ffffffff16815250508152602001600782016040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff16815250508152505090506000600a6000336001600160a01b03166001600160a01b031681526020019081526020016000206000876001600160401b03166001600160401b031681526020019081526020016000209050806002015460000361752157617515836175c2565b63ffffffff1660028201555b80600301546000036175475761753b826101400151618197565b63ffffffff1660038201555b61756e8261010001516001600160801b031683606001518361692d9092919063ffffffff16565b93506175858361757d87619719565b8391906181ca565b80546175a190600160801b90046001600160801b03168661809c565b81546001600160801b03918216600160801b02911617905550909392505050565b600064010000000082106160ca57600080fd5b600060606000806175e585618206565b91509150816175f657805181602001fd5b9094909350915050565b6000838361760f576000617612565b60015b60405160e89290921b6001600160e81b031916602083015260f81b6001600160f81b031916602382015260e083901b6001600160e01b031916602482015260280160405160208183030381529060405261766b90619b64565b60c01c949350505050565b6000612f7a8484846183d3565b60006040516323b872dd60e01b6000528460045283602452826044526020600060646000808a5af13d15601f3d1160016000511416171691506000606052806040525080610dc15760405162461bcd60e51b81526020600482015260146024820152731514905394d1915497d19493d357d1905253115160621b6044820152606401612245565b604080516001600160a01b0383811660248084019190915283518084039091018152604490920183526020820180516001600160e01b03166370a0823160e01b179052915160009283928392918716916177649190619b9b565b600060405180830381855afa9150503d806000811461779f576040519150601f19603f3d011682016040523d82523d6000602084013e6177a4565b606091505b50915091508115806177b857508051602014155b156177d65760405163c52e3eff60e01b815260040160405180910390fd5b808060200190518101906177ea9190619bb7565b95945050505050565b61781760405180606001604052806000815260200160008152602001600081525090565b6040518060600160405280617830846101400151616ddf565b81526020018361014001516080015161ffff16815260200161785184617859565b905292915050565b6000611502826020015163ffffffff16836178e390919063ffffffff16565b600080600061788f86610140015160000151617bcb565b90506178b8818761014001516080015161ffff168860c001516001600160801b031688886183e4565b92506178c383616f3f565b915050935093915050565b6000616e5a8383670de0b6b3a7640000618551565b6000806178f4846101400151618197565b63ffffffff1690508083111561790e576000915050611502565b616d38838261966c565b6000806000617926846177f3565b90506179488460c001516001600160801b03168261857f90919063ffffffff16565b92506179548184616e76565b915050915091565b6001600160a01b0382166000908152600184016020526040902054808211156179a25760405163315276c960e01b81526004810182905260248101839052604401612245565b6179ac8484612f9f565b6001600160a01b03831660009081526001850160205260408120805484929061718090849061966c565b604080516000808252602082019092526001600160a01b038416908390604051617a009190619b9b565b60006040518083038185875af1925050503d8060008114617a3d576040519150601f19603f3d011682016040523d82523d6000602084013e617a42565b606091505b5050905080610ea8576040516375f4268360e01b815260040160405180910390fd5b602081015190516010036008021c90565b80516001600160a01b03166000908152600a60209081526040808320828501516001600160401b03168452909152812060e08301519091600f9190910b1215617bad576000617b59617ac660125490565b604080516101608101825285546001600160801b038181168352600160801b91829004811660208401526001880154938301939093526002870154606083015260038701546080830152600487015460a0830152600587015460c0830152600687015460e08301526007870154808416610100840152048216610120820152600886015482166101408201529116618599565b6020848101516001600160401b03166000908152600890915260409020600601549091506301000000900461ffff16811015617bab57604051632688c6cb60e21b815260048101829052602401612245565b505b604082015160e0830151617bc29183916181ca565b610c52826185ab565b600080617be4670de0b6b3a7640000600285900b619bd0565b9050616e5a670de111a6b7de400082618628565b6000617c0582601261966c565b61150290600a619c55565b60008415612f7a576000617c2c617c278787616e61565b617ec1565b90506301e18559670de0b6b3a76400008481029190910490612710908602046000671bc16d674ec80000617c60838061973f565b617c6a9190619774565b90506000617c78848361973f565b90506000617c9884633b9aca00617c8e88618654565b614188919061973f565b905060008183617cb0670de0b6b3a76400008a619bd0565b617cba9190619b23565b617cc49190619af5565b90506000617cd1826186f0565b9050670de0b6b3a7640000811315617cff5760405163b11558df60e01b815260048101829052602401612245565b617d1181670de0b6b3a7640000619969565b9d9c50505050505050505050505050565b60006161008686612710670de0b6b3a76400008802048686618733565b828202811515841585830485141716617d5757600080fd5b0492915050565b60006161008686612710670de0b6b3a76400008802048686618816565b600080617d8b8686868686618733565b9096039695505050505050565b6000806301e18559670de0b6b3a764000084020490506000612710670de0b6b3a7640000860204905086670de0b6b3a76400001015617ded5760405163b11558df60e01b815260048101889052602401612245565b6000617e0188670de0b6b3a7640000619969565b90506000617e0e8261892a565b90506000617e2484633b9aca00617c8e88618654565b90506000670de0b6b3a7640000617e3b8385619bd0565b617e459190619af5565b90506000671bc16d674ec80000617e5c878061973f565b617e669190619774565b90506000670de0b6b3a7640000617e7d898461973f565b617e879190619af5565b90506000617e958285619969565b90506000617ea2826189be565b9050617eae818f616e45565b9f9e505050505050505050505050505050565b6000808213617efe5760405162461bcd60e51b815260206004820152600960248201526815539111519253915160ba1b6044820152606401612245565b60006060617f0b84618b67565b03609f8181039490941b90931c6c465772b2bbbb5f824b15207a3081018102606090811d6d0388eaa27412d5aca026815d636e018202811d6d0df99ac502031bf953eff472fdcc018202811d6d13cdffb29d51d99322bdff5f2211018202811d6d0a0f742023def783a307a986912e018202811d6d01920d8043ca89b5239253284e42018202811d6c0b7a86d7375468fac667a0a527016c29508e458543d8aa4df2abee7883018302821d6d0139601a2efabe717e604cbb4894018302821d6d02247f7a7b6594320649aa03aba1018302821d6c8c3f38e95a6b1ff2ab1c3b343619018302821d6d02384773bdf1ac5676facced60901901830290911d6cb9a025d814b29c212b8b1a07cd1901909102780a09507084cc699bb0e71ea869ffffffffffffffffffffffff190105711340daa0d5f769dba1915cef59f0815a5506027d0267a36c0c95b3975ab3ee5b203a7614a3f75373f047d803ae7b6687f2b393909302929092017d57115e47018c7177eebf7cd370a3356a1b7863008a5ae8028c72b88642840160ae1d92915050565b6040805160048152602481019091526020810180516001600160e01b0316631fff968160e01b179052600090818312600181146180de5780156180fe57618118565b60001984198603019250848312806180f857825183602001fd5b50618118565b83850192508483126001810361811657825183602001fd5b505b505092915050565b618129816175c2565b825463ffffffff9190911663010000000266ffffffff000000199091161790915550565b81811561150257500190565b6181638383612f9f565b6001600160a01b03821660009081526001840160205260408120805483929061818d908490619788565b9091555050505050565b60006115028260c0015163ffffffff166181bb846060015161ffff16620151800290565b6181c59190619788565b6175c2565b6001830182905582546181e6906001600160801b03168261809c565b83546001600160801b0319166001600160801b0391909116179092555050565b60006060618220836080015161ffff1660646161a8617676565b61828357608083015160405161ffff90911660248201526000906327b67e7360e21b906044015b60408051601f198184030181529190526020810180516001600160e01b03166001600160e01b0319909316929092179091529094909350915050565b618299836060015161ffff1660016101f4617676565b6182c457606083015160405161ffff909116602482015260009063ae91902760e01b90604401618247565b8251620d89e860029190910b126182f957825160405160029190910b60248201526000906345c3193d60e11b90604401618247565b610258836020015161ffff16111561833257602083015160405161ffff9091166024820152600090637a7f104160e11b90604401618247565b618348836040015161ffff1660016103e8617676565b61837357604080840151905161ffff909116602482015260009063f6f4a38f60e01b90604401618247565b61838f8360a0015161ffff166000856040015161ffff16617676565b6183ba5760a083015160405161ffff909116602482015260009063f6f4a38f60e01b90604401618247565b5050604080516020810190915260008152600192909150565b600080828503848603021315612f7a565b6000816000036183f55750826177ea565b828211156184045750846177ea565b60408051606081018252878152602081018790529081018490526301e18559670de0b6b3a7640000808602829005919085020560006184438284618c05565b61845590670de0b6b3a764000061966c565b9050600061846282618654565b8551909150600090618475908b90618c05565b9050600061849161848a633b9aca008561973f565b8390618628565b90506000806184a0878961966c565b905060006184ad82618654565b6184b68a618654565b6184c0919061973f565b905060006184ce838361966c565b905060006184ee8c60200151612710670de0b6b3a7640000919091020490565b90506000671bc16d674ec80000618505838061973f565b61850f9190619774565b905060006185256185208386616e45565b6189be565b8e519091506185349082616e45565b96505050505050506000617eae8284616e4590919063ffffffff16565b82820281151584158583048514171661856957600080fd5b6001826001830304018115150290509392505050565b6000616e5a82846000015185602001518660400151617c10565b6000826040015182616e5a919061966c565b60a081015160c082015160e08301516020808501516001600160401b031660009081526008909152604090206185e091618c1a565b60008360e00151600f0b121561860c576185fe828460600151616b23565b610ea8818460800151616b23565b61861a8284606001516170fa565b610ea88184608001516170fa565b6000616e5a670de0b6b3a76400008361864086617ec1565b61864a9190619bd0565b6185209190619af5565b60b581600160881b811061866d5760409190911b9060801c5b600160481b81106186835760209190911b9060401c5b600160281b81106186995760109190911b9060201c5b630100000081106186af5760089190911b9060101c5b62010000010260121c80820401600190811c80830401811c80830401811c80830401811c80830401811c80830401811c80830401901c908190048111900390565b60006713a04bbdfdc9be88670de0b6b3a7640000830205196001018161871582618c5d565b671bc16d674ec80000670de0b6b3a764000090910205949350505050565b6000670de0b6b3a764000086111561875e5760405163aaf3956f60e01b815260040160405180910390fd5b670de0b6b3a7640000860361877e576187778286619b23565b90506177ea565b8560000361878d5750806177ea565b82156187fb576301e18558670de0b6b3a764000084020560006187af82618654565b670de0b6b3a7640000908702633b9aca000281900591508890036187d28161892a565b90508181036187e0816186f0565b670de0b6b3a7640000908a0205860194506177ea9350505050565b50670de0b6b3a7640000858103850205810195945050505050565b60008215618906576301e18558670de0b6b3a7640000840204600061883a82618654565b670de0b6b3a7640000908702633b9aca0002819004915088850102879005600081121561887a5760405163aaf3956f60e01b815260040160405180910390fd5b670de0b6b3a76400008113156188a35760405163aaf3956f60e01b815260040160405180910390fd5b670de0b6b3a764000081036188be57600093505050506177ea565b806000036188d957670de0b6b3a764000093505050506177ea565b6188e28161892a565b90508181016188f0816186f0565b670de0b6b3a76400000394506177ea9350505050565b84670de0b6b3a76400008388010205670de0b6b3a764000003905095945050505050565b60006706f05b59d3b20000820361894357506000919050565b670de0b6b3a7640000821261896b576040516307a0212760e01b815260040160405180910390fd5b8160000361898c576040516322ed598560e21b815260040160405180910390fd5b600282029150600061899d83618dd2565b670de0b6b3a76400006713a04bbdfdc9be8890910205196001019392505050565b6000680248ce36a70cb26b3e1982136189d957506000919050565b680755bf798b4a1bf1e58212618a205760405162461bcd60e51b815260206004820152600c60248201526b4558505f4f564552464c4f5760a01b6044820152606401612245565b6503782dace9d9604e83901b059150600060606bb17217f7d1cf79abc9e3b39884821b056001605f1b01901d6bb17217f7d1cf79abc9e3b39881029093036c240c330e9fb2d9cbaf0fd5aafb1981018102606090811d6d0277594991cfc85f6e2461837cd9018202811d6d1a521255e34f6a5061b25ef1c9c319018202811d6db1bbb201f443cf962f1a1d3db4a5018202811d6e02c72388d9f74f51a9331fed693f1419018202811d6e05180bb14799ab47a8a8cb2a527d57016d02d16720577bd19bf614176fe9ea6c10fe68e7fd37d0007b713f765084018402831d9081019084016d01d3967ed30fc4f89c02bab5708119010290911d6e0587f503bb6ea29d25fcb740196450019091026d360d7aeea093263ecc6e0ecb291760621b010574029d9dc38563c32e5c2f6dc192ee70ef65f9978af30260c3939093039290921c92915050565b6000808211618ba45760405162461bcd60e51b815260206004820152600960248201526815539111519253915160ba1b6044820152606401612245565b5060016001600160801b03821160071b82811c6001600160401b031060061b1782811c63ffffffff1060051b1782811c61ffff1060041b1782811c60ff10600390811b90911783811c600f1060021b1783811c909110821b1791821c111790565b6000616e5a83670de0b6b3a764000084618551565b6004820154618c3990600160801b90046001600160801b03168261809c565b600490920180546001600160801b03938416600160801b0293169290921790915550565b600080618c6983618ff0565b9050671bc16d674ec80000670de0b6b3a764000080830291909105016ec097ce7bc90715b34b9f100000000005600080618d07618cec618cd2670de0b6b3a764000067025f0fe105a31400870205670b68df18e471fbff190186670de0b6b3a764000091020590565b6714a8454c19e1ac000185670de0b6b3a764000091020590565b670fc10e01578277ff190184670de0b6b3a764000091020590565b6703debd083b8c7c00019150670de0b6b3a7640000670de0cc3d15610000670157d8b2ecc70800858502839005670295d400ea3257ff190186028390050185028290056705310aa7d52130000185028290050184020591508167119000ab100ffc00670de0b6b3a76400008680020560001902030190506000618d89826189be565b9050670de0b6b3a76400008482020560008812801590618db05760018114618dc257618dc6565b81671bc16d674ec80000039750618dc6565b8197505b50505050505050919050565b6000671bc16d674ec800008212618df0575068056bc75e2d630fffff195b60008213618e04575068056bc75e2d631000005b8015618e0f57919050565b6000670de0b6b3a76400008312801590618e305760018114618e3857618e46565b839150618e46565b83671bc16d674ec800000391505b506000618e5b82671bc16d674ec8000061902c565b905080600003618e7e576040516307a0212760e01b815260040160405180910390fd5b6000618e8982617ec1565b90506000618ea8618ea3671bc16d674ec7ffff1984619041565b618654565b633b9aca000290506000618f3c82618ee7670de0b6b3a7640000669f32752462a000830205670dc5527f642c20000185670de0b6b3a764000091020590565b670de0b6b3a764000001670de0b6b3a7640000618f166703c1665c7aab200087670de0b6b3a764000091020590565b672005fe4f268ea000010205036709d028cc6f205fff19670de0b6b3a764000091020590565b905060005b6002811015618fb9576000618f5583618c5d565b8790039050670de0b6b3a764000083800205196001016000618f76826189be565b9050670de0b6b3a764000085840205670de0b6b3a7640000670fa8cedfc2adddfa83020503670de0b6b3a764000084020585019450600184019350505050618f41565b670de0b6b3a76400008812801590618fd85760018114618fe057618dc6565b829750618dc6565b5050196001019695505050505050565b6000600160ff1b820361901657604051634d2d75b160e01b815260040160405180910390fd5b60008212156160ca57501960010190565b919050565b6000616e5a83670de0b6b3a764000084619052565b6000616e5a8383670de0b6b3a76400005b82820281151584158583058514171661906a57600080fd5b0592915050565b5080546000825560020290600052602060002090810190610eeb91906190b0565b5080546000825590600052602060002090810190610eeb91906190d6565b5b808211156160ca5780546001600160a01b0319168155600060018201556002016190b1565b5b808211156160ca57600081556001016190d7565b80356001600160401b038116811461902757600080fd5b60006020828403121561911457600080fd5b616e5a826190eb565b80356001600160801b038116811461902757600080fd5b6000806040838503121561914757600080fd5b619150836190eb565b915061481e6020840161911d565b6000806040838503121561917157600080fd5b61917a836190eb565b946020939093013593505050565b80356001600160a01b038116811461902757600080fd5b600080604083850312156191b257600080fd5b6191bb83619188565b915061481e60208401619188565b6000602082840312156191db57600080fd5b5035919050565b6000602082840312156191f457600080fd5b616e5a82619188565b60006020828403121561920f57600080fd5b813562ffffff81168114616e5a57600080fd5b803561ffff8116811461902757600080fd5b600080600080600080600060e0888a03121561924f57600080fd5b619258886190eb565b965061926660208901619222565b955061927460408901619222565b945061928260608901619222565b935061929060808901619222565b925061929e60a08901619222565b915060c08801358060020b81146192b457600080fd5b8091505092959891949750929550565b600080604083850312156192d757600080fd5b61917a83619188565b8035801515811461902757600080fd5b60008060006060848603121561930557600080fd5b61930e846190eb565b925061931c602085016192e0565b9150604084013590509250925092565b6000806020838503121561933f57600080fd5b82356001600160401b038082111561935657600080fd5b818501915085601f83011261936a57600080fd5b81358181111561937957600080fd5b86602082850101111561938b57600080fd5b60209290920196919550909350505050565b600080604083850312156193b057600080fd5b6193b9836190eb565b9150602083013580600f0b81146193cf57600080fd5b809150509250929050565b60028d900b815263ffffffff8c1660208201526001600160a01b038b166040820152606081018a90526080810189905260a081018890526001600160801b0387811660c083015286811660e083015285166101008201526102a08101619446610120830186600f0b9052565b835160020b610140830152602084015161ffff90811661016084015260408501518116610180840152606085015181166101a0840152608085015181166101c084015260a0850151166101e083015260c084015163ffffffff1661020083015282516001600160a01b03908116610220840152602084015160ff90811661024085015260408501519091166102608401526060840151166102808301529d9c50505050505050505050505050565b60008060006060848603121561950957600080fd5b619512846190eb565b95602085013595506040909401359392505050565b6000806000806080858703121561953d57600080fd5b619546856190eb565b9350619554602086016192e0565b93969395505050506040820135916060013590565b60008060006060848603121561957e57600080fd5b61958784619188565b92506020840135915061349860408501619188565b600080604083850312156195af57600080fd5b6195b883619188565b915061481e602084016190eb565b6000602082840312156195d857600080fd5b616e5a8261911d565b60005b838110156195fc5781810151838201526020016195e4565b838111156162235750506000910152565b602081526000825180602084015261962c8160408501602087016195e1565b601f01601f19169190910160400192915050565b634e487b7160e01b600052603260045260246000fd5b634e487b7160e01b600052601160045260246000fd5b60008282101561967e5761967e619656565b500390565b634e487b7160e01b600052603160045260246000fd5b60006001600160801b03838116908316818110156196b9576196b9619656565b039392505050565b600080858511156196d157600080fd5b838611156196de57600080fd5b5050820193919092039150565b6001600160c01b031981358181169160088510156181185760089490940360031b84901b1690921692915050565b600081600f0b60016001607f1b0319810361973657619736619656565b60000392915050565b600081600019048311821515161561975957619759619656565b500290565b634e487b7160e01b600052601260045260246000fd5b6000826197835761978361975e565b500490565b6000821982111561979b5761979b619656565b500190565b600081600f0b83600f0b600082128260016001607f1b03038213811516156197ca576197ca619656565b8260016001607f1b03190382128116156197e6576197e6619656565b50019392505050565b600081600f0b83600f0b600081128160016001607f1b03190183128115161561981a5761981a619656565b8160016001607f1b0301831381161561983557619835619656565b5090039392505050565b6001600160e81b0319813581811691600385101561811857600394850390941b84901b1690921692915050565b6bffffffffffffffffffffffff1981358181169160148510156181185760149490940360031b84901b1690921692915050565b6001600160f01b031981358181169160028510156181185760029490940360031b84901b1690921692915050565b6001600160801b031981358181169160108510156181185760109490940360031b84901b1690921692915050565b60006020828403121561990d57600080fd5b815160ff81168114616e5a57600080fd5b60006001820161993057619930619656565b5060010190565b634e487b7160e01b600052600160045260246000fd5b6000600160ff1b820161996257619962619656565b5060000390565b60008083128015600160ff1b85018412161561998757619987619656565b6001600160ff1b03840183138116156199a2576199a2619656565b50500390565b60006001600160801b038083168185168083038211156199ca576199ca619656565b01949350505050565b600181815b80851115619a0e5781600019048211156199f4576199f4619656565b80851615619a0157918102915b93841c93908002906199d8565b509250929050565b600082619a2557506001611502565b81619a3257506000611502565b8160018114619a485760028114619a5257619a6e565b6001915050611502565b60ff841115619a6357619a63619656565b50506001821b611502565b5060208310610133831016604e8410600b8410161715619a91575081810a611502565b619a9b83836199d3565b8060001904821115619aaf57619aaf619656565b029392505050565b6000616e5a60ff841683619a16565b60006001600160801b0380831681851681830481118215151615619aec57619aec619656565b02949350505050565b600082619b0457619b0461975e565b600160ff1b821460001984141615619b1e57619b1e619656565b500590565b600080821280156001600160ff1b0384900385131615619b4557619b45619656565b600160ff1b8390038412811615619b5e57619b5e619656565b50500190565b805160208201516001600160c01b03198082169291906008831015619b935780818460080360031b1b83161693505b505050919050565b60008251619bad8184602087016195e1565b9190910192915050565b600060208284031215619bc957600080fd5b5051919050565b60006001600160ff1b0381841382841380821686840486111615619bf657619bf6619656565b600160ff1b6000871282811687830589121615619c1557619c15619656565b60008712925087820587128484161615619c3157619c31619656565b87850587128184161615619c4757619c47619656565b505050929093029392505050565b6000616e5a8383619a1656fea2646970667358221220779aca11039da6594e1e2f1ea62730f89b836d532303fd26635c3fc0654a4ddf64736f6c634300080d0033"
            .parse()
            .expect("invalid bytecode")
    });
    pub struct HyperCatchReverts<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for HyperCatchReverts<M> {
        fn clone(&self) -> Self {
            HyperCatchReverts(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for HyperCatchReverts<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for HyperCatchReverts<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(HyperCatchReverts)).field(&self.address()).finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> HyperCatchReverts<M> {
        /// Creates a new contract instance with the specified `ethers`
        /// client at the given `Address`. The contract derefs to a `ethers::Contract`
        /// object
        pub fn new<T: Into<::ethers::core::types::Address>>(
            address: T,
            client: ::std::sync::Arc<M>,
        ) -> Self {
            Self(
                ::ethers::contract::Contract::new(
                    address.into(),
                    HYPERCATCHREVERTS_ABI.clone(),
                    client,
                ),
            )
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
                HYPERCATCHREVERTS_ABI.clone(),
                HYPERCATCHREVERTS_BYTECODE.clone().into(),
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
        ) -> ::ethers::contract::builders::ContractCall<
            M,
            ::ethers::core::types::Address,
        > {
            self.0
                .method_hash([173, 92, 70, 72], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `__account__` (0xda31ee54) function
        pub fn account(
            &self,
        ) -> ::ethers::contract::builders::ContractCall<M, (bool, bool)> {
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
                    (pool_id, priority_fee, fee, volatility, duration, jit, max_tick),
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
        ///Calls the contract's `doJumpProcess` (0xe82b84b4) function
        pub fn do_jump_process(
            &self,
            data: ::ethers::core::types::Bytes,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([232, 43, 132, 180], data)
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
        ///Calls the contract's `jitDelay` (0xa1f4405d) function
        pub fn jit_delay(
            &self,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([161, 244, 64, 93], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `jumpProcess` (0x80aa2019) function
        pub fn jump_process(
            &self,
            data: ::ethers::core::types::Bytes,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([128, 170, 32, 25], data)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `mockFallback` (0xb3b528a2) function
        pub fn mock_fallback(
            &self,
            data: ::ethers::core::types::Bytes,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([179, 181, 40, 162], data)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `pairs` (0x5e47663c) function
        pub fn pairs(
            &self,
            p0: u32,
        ) -> ::ethers::contract::builders::ContractCall<
            M,
            (::ethers::core::types::Address, u8, ::ethers::core::types::Address, u8),
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
        ///Calls the contract's `process` (0x928bc4b2) function
        pub fn process(
            &self,
            data: ::ethers::core::types::Bytes,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([146, 139, 196, 178], data)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `setJitPolicy` (0x4a9866b4) function
        pub fn set_jit_policy(
            &self,
            delay: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([74, 152, 102, 180], delay)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `setTimestamp` (0xf740485b) function
        pub fn set_timestamp(
            &self,
            time: u128,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([247, 64, 72, 91], time)
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
        ///Calls the contract's `timestamp` (0xb80777ea) function
        pub fn timestamp(
            &self,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([184, 7, 119, 234], ())
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
        pub fn allocate_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, AllocateFilter> {
            self.0.event()
        }
        ///Gets the contract's `ChangeParameters` event
        pub fn change_parameters_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, ChangeParametersFilter> {
            self.0.event()
        }
        ///Gets the contract's `Collect` event
        pub fn collect_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, CollectFilter> {
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
        pub fn deposit_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, DepositFilter> {
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
        pub fn stake_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, StakeFilter> {
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
        pub fn unstake_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, UnstakeFilter> {
            self.0.event()
        }
        /// Returns an [`Event`](#ethers_contract::builders::Event) builder for all events of this contract
        pub fn events(
            &self,
        ) -> ::ethers::contract::builders::Event<M, HyperCatchRevertsEvents> {
            self.0.event_with_filter(Default::default())
        }
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>>
    for HyperCatchReverts<M> {
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
    #[etherror(name = "InvalidBytesLength", abi = "InvalidBytesLength(uint256,uint256)")]
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
    pub enum HyperCatchRevertsErrors {
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
    impl ::ethers::core::abi::AbiDecode for HyperCatchRevertsErrors {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded)
                = <DrawBalance as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::DrawBalance(decoded));
            }
            if let Ok(decoded)
                = <EtherTransferFail as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::EtherTransferFail(decoded));
            }
            if let Ok(decoded)
                = <Infinity as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperCatchRevertsErrors::Infinity(decoded));
            }
            if let Ok(decoded)
                = <InsufficientPosition as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::InsufficientPosition(decoded));
            }
            if let Ok(decoded)
                = <InsufficientReserve as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::InsufficientReserve(decoded));
            }
            if let Ok(decoded)
                = <InvalidBalance as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::InvalidBalance(decoded));
            }
            if let Ok(decoded)
                = <InvalidBytesLength as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::InvalidBytesLength(decoded));
            }
            if let Ok(decoded)
                = <InvalidDecimals as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::InvalidDecimals(decoded));
            }
            if let Ok(decoded)
                = <InvalidFee as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperCatchRevertsErrors::InvalidFee(decoded));
            }
            if let Ok(decoded)
                = <InvalidInstruction as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::InvalidInstruction(decoded));
            }
            if let Ok(decoded)
                = <InvalidInvariant as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::InvalidInvariant(decoded));
            }
            if let Ok(decoded)
                = <InvalidJump as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::InvalidJump(decoded));
            }
            if let Ok(decoded)
                = <InvalidReentrancy as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::InvalidReentrancy(decoded));
            }
            if let Ok(decoded)
                = <InvalidReward as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::InvalidReward(decoded));
            }
            if let Ok(decoded)
                = <InvalidSettlement as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::InvalidSettlement(decoded));
            }
            if let Ok(decoded)
                = <InvalidTransfer as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::InvalidTransfer(decoded));
            }
            if let Ok(decoded)
                = <JitLiquidity as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::JitLiquidity(decoded));
            }
            if let Ok(decoded)
                = <Min as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperCatchRevertsErrors::Min(decoded));
            }
            if let Ok(decoded)
                = <NegativeInfinity as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::NegativeInfinity(decoded));
            }
            if let Ok(decoded)
                = <NonExistentPool as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::NonExistentPool(decoded));
            }
            if let Ok(decoded)
                = <NonExistentPosition as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::NonExistentPosition(decoded));
            }
            if let Ok(decoded)
                = <NotController as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::NotController(decoded));
            }
            if let Ok(decoded)
                = <NotPreparedToSettle as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::NotPreparedToSettle(decoded));
            }
            if let Ok(decoded)
                = <OOB as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperCatchRevertsErrors::OOB(decoded));
            }
            if let Ok(decoded)
                = <OverflowWad as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::OverflowWad(decoded));
            }
            if let Ok(decoded)
                = <PairExists as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperCatchRevertsErrors::PairExists(decoded));
            }
            if let Ok(decoded)
                = <PoolExists as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperCatchRevertsErrors::PoolExists(decoded));
            }
            if let Ok(decoded)
                = <PoolExpired as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::PoolExpired(decoded));
            }
            if let Ok(decoded)
                = <PositionNotStaked as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::PositionNotStaked(decoded));
            }
            if let Ok(decoded)
                = <SameTokenError as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::SameTokenError(decoded));
            }
            if let Ok(decoded)
                = <StakeNotMature as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::StakeNotMature(decoded));
            }
            if let Ok(decoded)
                = <SwapLimitReached as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::SwapLimitReached(decoded));
            }
            if let Ok(decoded)
                = <ZeroInput as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperCatchRevertsErrors::ZeroInput(decoded));
            }
            if let Ok(decoded)
                = <ZeroLiquidity as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsErrors::ZeroLiquidity(decoded));
            }
            if let Ok(decoded)
                = <ZeroPrice as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperCatchRevertsErrors::ZeroPrice(decoded));
            }
            if let Ok(decoded)
                = <ZeroValue as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperCatchRevertsErrors::ZeroValue(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for HyperCatchRevertsErrors {
        fn encode(self) -> Vec<u8> {
            match self {
                HyperCatchRevertsErrors::DrawBalance(element) => element.encode(),
                HyperCatchRevertsErrors::EtherTransferFail(element) => element.encode(),
                HyperCatchRevertsErrors::Infinity(element) => element.encode(),
                HyperCatchRevertsErrors::InsufficientPosition(element) => {
                    element.encode()
                }
                HyperCatchRevertsErrors::InsufficientReserve(element) => element.encode(),
                HyperCatchRevertsErrors::InvalidBalance(element) => element.encode(),
                HyperCatchRevertsErrors::InvalidBytesLength(element) => element.encode(),
                HyperCatchRevertsErrors::InvalidDecimals(element) => element.encode(),
                HyperCatchRevertsErrors::InvalidFee(element) => element.encode(),
                HyperCatchRevertsErrors::InvalidInstruction(element) => element.encode(),
                HyperCatchRevertsErrors::InvalidInvariant(element) => element.encode(),
                HyperCatchRevertsErrors::InvalidJump(element) => element.encode(),
                HyperCatchRevertsErrors::InvalidReentrancy(element) => element.encode(),
                HyperCatchRevertsErrors::InvalidReward(element) => element.encode(),
                HyperCatchRevertsErrors::InvalidSettlement(element) => element.encode(),
                HyperCatchRevertsErrors::InvalidTransfer(element) => element.encode(),
                HyperCatchRevertsErrors::JitLiquidity(element) => element.encode(),
                HyperCatchRevertsErrors::Min(element) => element.encode(),
                HyperCatchRevertsErrors::NegativeInfinity(element) => element.encode(),
                HyperCatchRevertsErrors::NonExistentPool(element) => element.encode(),
                HyperCatchRevertsErrors::NonExistentPosition(element) => element.encode(),
                HyperCatchRevertsErrors::NotController(element) => element.encode(),
                HyperCatchRevertsErrors::NotPreparedToSettle(element) => element.encode(),
                HyperCatchRevertsErrors::OOB(element) => element.encode(),
                HyperCatchRevertsErrors::OverflowWad(element) => element.encode(),
                HyperCatchRevertsErrors::PairExists(element) => element.encode(),
                HyperCatchRevertsErrors::PoolExists(element) => element.encode(),
                HyperCatchRevertsErrors::PoolExpired(element) => element.encode(),
                HyperCatchRevertsErrors::PositionNotStaked(element) => element.encode(),
                HyperCatchRevertsErrors::SameTokenError(element) => element.encode(),
                HyperCatchRevertsErrors::StakeNotMature(element) => element.encode(),
                HyperCatchRevertsErrors::SwapLimitReached(element) => element.encode(),
                HyperCatchRevertsErrors::ZeroInput(element) => element.encode(),
                HyperCatchRevertsErrors::ZeroLiquidity(element) => element.encode(),
                HyperCatchRevertsErrors::ZeroPrice(element) => element.encode(),
                HyperCatchRevertsErrors::ZeroValue(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for HyperCatchRevertsErrors {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                HyperCatchRevertsErrors::DrawBalance(element) => element.fmt(f),
                HyperCatchRevertsErrors::EtherTransferFail(element) => element.fmt(f),
                HyperCatchRevertsErrors::Infinity(element) => element.fmt(f),
                HyperCatchRevertsErrors::InsufficientPosition(element) => element.fmt(f),
                HyperCatchRevertsErrors::InsufficientReserve(element) => element.fmt(f),
                HyperCatchRevertsErrors::InvalidBalance(element) => element.fmt(f),
                HyperCatchRevertsErrors::InvalidBytesLength(element) => element.fmt(f),
                HyperCatchRevertsErrors::InvalidDecimals(element) => element.fmt(f),
                HyperCatchRevertsErrors::InvalidFee(element) => element.fmt(f),
                HyperCatchRevertsErrors::InvalidInstruction(element) => element.fmt(f),
                HyperCatchRevertsErrors::InvalidInvariant(element) => element.fmt(f),
                HyperCatchRevertsErrors::InvalidJump(element) => element.fmt(f),
                HyperCatchRevertsErrors::InvalidReentrancy(element) => element.fmt(f),
                HyperCatchRevertsErrors::InvalidReward(element) => element.fmt(f),
                HyperCatchRevertsErrors::InvalidSettlement(element) => element.fmt(f),
                HyperCatchRevertsErrors::InvalidTransfer(element) => element.fmt(f),
                HyperCatchRevertsErrors::JitLiquidity(element) => element.fmt(f),
                HyperCatchRevertsErrors::Min(element) => element.fmt(f),
                HyperCatchRevertsErrors::NegativeInfinity(element) => element.fmt(f),
                HyperCatchRevertsErrors::NonExistentPool(element) => element.fmt(f),
                HyperCatchRevertsErrors::NonExistentPosition(element) => element.fmt(f),
                HyperCatchRevertsErrors::NotController(element) => element.fmt(f),
                HyperCatchRevertsErrors::NotPreparedToSettle(element) => element.fmt(f),
                HyperCatchRevertsErrors::OOB(element) => element.fmt(f),
                HyperCatchRevertsErrors::OverflowWad(element) => element.fmt(f),
                HyperCatchRevertsErrors::PairExists(element) => element.fmt(f),
                HyperCatchRevertsErrors::PoolExists(element) => element.fmt(f),
                HyperCatchRevertsErrors::PoolExpired(element) => element.fmt(f),
                HyperCatchRevertsErrors::PositionNotStaked(element) => element.fmt(f),
                HyperCatchRevertsErrors::SameTokenError(element) => element.fmt(f),
                HyperCatchRevertsErrors::StakeNotMature(element) => element.fmt(f),
                HyperCatchRevertsErrors::SwapLimitReached(element) => element.fmt(f),
                HyperCatchRevertsErrors::ZeroInput(element) => element.fmt(f),
                HyperCatchRevertsErrors::ZeroLiquidity(element) => element.fmt(f),
                HyperCatchRevertsErrors::ZeroPrice(element) => element.fmt(f),
                HyperCatchRevertsErrors::ZeroValue(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<DrawBalance> for HyperCatchRevertsErrors {
        fn from(var: DrawBalance) -> Self {
            HyperCatchRevertsErrors::DrawBalance(var)
        }
    }
    impl ::std::convert::From<EtherTransferFail> for HyperCatchRevertsErrors {
        fn from(var: EtherTransferFail) -> Self {
            HyperCatchRevertsErrors::EtherTransferFail(var)
        }
    }
    impl ::std::convert::From<Infinity> for HyperCatchRevertsErrors {
        fn from(var: Infinity) -> Self {
            HyperCatchRevertsErrors::Infinity(var)
        }
    }
    impl ::std::convert::From<InsufficientPosition> for HyperCatchRevertsErrors {
        fn from(var: InsufficientPosition) -> Self {
            HyperCatchRevertsErrors::InsufficientPosition(var)
        }
    }
    impl ::std::convert::From<InsufficientReserve> for HyperCatchRevertsErrors {
        fn from(var: InsufficientReserve) -> Self {
            HyperCatchRevertsErrors::InsufficientReserve(var)
        }
    }
    impl ::std::convert::From<InvalidBalance> for HyperCatchRevertsErrors {
        fn from(var: InvalidBalance) -> Self {
            HyperCatchRevertsErrors::InvalidBalance(var)
        }
    }
    impl ::std::convert::From<InvalidBytesLength> for HyperCatchRevertsErrors {
        fn from(var: InvalidBytesLength) -> Self {
            HyperCatchRevertsErrors::InvalidBytesLength(var)
        }
    }
    impl ::std::convert::From<InvalidDecimals> for HyperCatchRevertsErrors {
        fn from(var: InvalidDecimals) -> Self {
            HyperCatchRevertsErrors::InvalidDecimals(var)
        }
    }
    impl ::std::convert::From<InvalidFee> for HyperCatchRevertsErrors {
        fn from(var: InvalidFee) -> Self {
            HyperCatchRevertsErrors::InvalidFee(var)
        }
    }
    impl ::std::convert::From<InvalidInstruction> for HyperCatchRevertsErrors {
        fn from(var: InvalidInstruction) -> Self {
            HyperCatchRevertsErrors::InvalidInstruction(var)
        }
    }
    impl ::std::convert::From<InvalidInvariant> for HyperCatchRevertsErrors {
        fn from(var: InvalidInvariant) -> Self {
            HyperCatchRevertsErrors::InvalidInvariant(var)
        }
    }
    impl ::std::convert::From<InvalidJump> for HyperCatchRevertsErrors {
        fn from(var: InvalidJump) -> Self {
            HyperCatchRevertsErrors::InvalidJump(var)
        }
    }
    impl ::std::convert::From<InvalidReentrancy> for HyperCatchRevertsErrors {
        fn from(var: InvalidReentrancy) -> Self {
            HyperCatchRevertsErrors::InvalidReentrancy(var)
        }
    }
    impl ::std::convert::From<InvalidReward> for HyperCatchRevertsErrors {
        fn from(var: InvalidReward) -> Self {
            HyperCatchRevertsErrors::InvalidReward(var)
        }
    }
    impl ::std::convert::From<InvalidSettlement> for HyperCatchRevertsErrors {
        fn from(var: InvalidSettlement) -> Self {
            HyperCatchRevertsErrors::InvalidSettlement(var)
        }
    }
    impl ::std::convert::From<InvalidTransfer> for HyperCatchRevertsErrors {
        fn from(var: InvalidTransfer) -> Self {
            HyperCatchRevertsErrors::InvalidTransfer(var)
        }
    }
    impl ::std::convert::From<JitLiquidity> for HyperCatchRevertsErrors {
        fn from(var: JitLiquidity) -> Self {
            HyperCatchRevertsErrors::JitLiquidity(var)
        }
    }
    impl ::std::convert::From<Min> for HyperCatchRevertsErrors {
        fn from(var: Min) -> Self {
            HyperCatchRevertsErrors::Min(var)
        }
    }
    impl ::std::convert::From<NegativeInfinity> for HyperCatchRevertsErrors {
        fn from(var: NegativeInfinity) -> Self {
            HyperCatchRevertsErrors::NegativeInfinity(var)
        }
    }
    impl ::std::convert::From<NonExistentPool> for HyperCatchRevertsErrors {
        fn from(var: NonExistentPool) -> Self {
            HyperCatchRevertsErrors::NonExistentPool(var)
        }
    }
    impl ::std::convert::From<NonExistentPosition> for HyperCatchRevertsErrors {
        fn from(var: NonExistentPosition) -> Self {
            HyperCatchRevertsErrors::NonExistentPosition(var)
        }
    }
    impl ::std::convert::From<NotController> for HyperCatchRevertsErrors {
        fn from(var: NotController) -> Self {
            HyperCatchRevertsErrors::NotController(var)
        }
    }
    impl ::std::convert::From<NotPreparedToSettle> for HyperCatchRevertsErrors {
        fn from(var: NotPreparedToSettle) -> Self {
            HyperCatchRevertsErrors::NotPreparedToSettle(var)
        }
    }
    impl ::std::convert::From<OOB> for HyperCatchRevertsErrors {
        fn from(var: OOB) -> Self {
            HyperCatchRevertsErrors::OOB(var)
        }
    }
    impl ::std::convert::From<OverflowWad> for HyperCatchRevertsErrors {
        fn from(var: OverflowWad) -> Self {
            HyperCatchRevertsErrors::OverflowWad(var)
        }
    }
    impl ::std::convert::From<PairExists> for HyperCatchRevertsErrors {
        fn from(var: PairExists) -> Self {
            HyperCatchRevertsErrors::PairExists(var)
        }
    }
    impl ::std::convert::From<PoolExists> for HyperCatchRevertsErrors {
        fn from(var: PoolExists) -> Self {
            HyperCatchRevertsErrors::PoolExists(var)
        }
    }
    impl ::std::convert::From<PoolExpired> for HyperCatchRevertsErrors {
        fn from(var: PoolExpired) -> Self {
            HyperCatchRevertsErrors::PoolExpired(var)
        }
    }
    impl ::std::convert::From<PositionNotStaked> for HyperCatchRevertsErrors {
        fn from(var: PositionNotStaked) -> Self {
            HyperCatchRevertsErrors::PositionNotStaked(var)
        }
    }
    impl ::std::convert::From<SameTokenError> for HyperCatchRevertsErrors {
        fn from(var: SameTokenError) -> Self {
            HyperCatchRevertsErrors::SameTokenError(var)
        }
    }
    impl ::std::convert::From<StakeNotMature> for HyperCatchRevertsErrors {
        fn from(var: StakeNotMature) -> Self {
            HyperCatchRevertsErrors::StakeNotMature(var)
        }
    }
    impl ::std::convert::From<SwapLimitReached> for HyperCatchRevertsErrors {
        fn from(var: SwapLimitReached) -> Self {
            HyperCatchRevertsErrors::SwapLimitReached(var)
        }
    }
    impl ::std::convert::From<ZeroInput> for HyperCatchRevertsErrors {
        fn from(var: ZeroInput) -> Self {
            HyperCatchRevertsErrors::ZeroInput(var)
        }
    }
    impl ::std::convert::From<ZeroLiquidity> for HyperCatchRevertsErrors {
        fn from(var: ZeroLiquidity) -> Self {
            HyperCatchRevertsErrors::ZeroLiquidity(var)
        }
    }
    impl ::std::convert::From<ZeroPrice> for HyperCatchRevertsErrors {
        fn from(var: ZeroPrice) -> Self {
            HyperCatchRevertsErrors::ZeroPrice(var)
        }
    }
    impl ::std::convert::From<ZeroValue> for HyperCatchRevertsErrors {
        fn from(var: ZeroValue) -> Self {
            HyperCatchRevertsErrors::ZeroValue(var)
        }
    }
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
    #[ethevent(name = "Unstake", abi = "Unstake(uint64,address,uint256)")]
    pub struct UnstakeFilter {
        #[ethevent(indexed)]
        pub pool_id: u64,
        #[ethevent(indexed)]
        pub owner: ::ethers::core::types::Address,
        pub delta_liquidity: ::ethers::core::types::U256,
    }
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum HyperCatchRevertsEvents {
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
    impl ::ethers::contract::EthLogDecode for HyperCatchRevertsEvents {
        fn decode_log(
            log: &::ethers::core::abi::RawLog,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::Error>
        where
            Self: Sized,
        {
            if let Ok(decoded) = AllocateFilter::decode_log(log) {
                return Ok(HyperCatchRevertsEvents::AllocateFilter(decoded));
            }
            if let Ok(decoded) = ChangeParametersFilter::decode_log(log) {
                return Ok(HyperCatchRevertsEvents::ChangeParametersFilter(decoded));
            }
            if let Ok(decoded) = CollectFilter::decode_log(log) {
                return Ok(HyperCatchRevertsEvents::CollectFilter(decoded));
            }
            if let Ok(decoded) = CreatePairFilter::decode_log(log) {
                return Ok(HyperCatchRevertsEvents::CreatePairFilter(decoded));
            }
            if let Ok(decoded) = CreatePoolFilter::decode_log(log) {
                return Ok(HyperCatchRevertsEvents::CreatePoolFilter(decoded));
            }
            if let Ok(decoded) = DecreaseReserveBalanceFilter::decode_log(log) {
                return Ok(
                    HyperCatchRevertsEvents::DecreaseReserveBalanceFilter(decoded),
                );
            }
            if let Ok(decoded) = DecreaseUserBalanceFilter::decode_log(log) {
                return Ok(HyperCatchRevertsEvents::DecreaseUserBalanceFilter(decoded));
            }
            if let Ok(decoded) = DepositFilter::decode_log(log) {
                return Ok(HyperCatchRevertsEvents::DepositFilter(decoded));
            }
            if let Ok(decoded) = IncreaseReserveBalanceFilter::decode_log(log) {
                return Ok(
                    HyperCatchRevertsEvents::IncreaseReserveBalanceFilter(decoded),
                );
            }
            if let Ok(decoded) = IncreaseUserBalanceFilter::decode_log(log) {
                return Ok(HyperCatchRevertsEvents::IncreaseUserBalanceFilter(decoded));
            }
            if let Ok(decoded) = StakeFilter::decode_log(log) {
                return Ok(HyperCatchRevertsEvents::StakeFilter(decoded));
            }
            if let Ok(decoded) = SwapFilter::decode_log(log) {
                return Ok(HyperCatchRevertsEvents::SwapFilter(decoded));
            }
            if let Ok(decoded) = UnallocateFilter::decode_log(log) {
                return Ok(HyperCatchRevertsEvents::UnallocateFilter(decoded));
            }
            if let Ok(decoded) = UnstakeFilter::decode_log(log) {
                return Ok(HyperCatchRevertsEvents::UnstakeFilter(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData)
        }
    }
    impl ::std::fmt::Display for HyperCatchRevertsEvents {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                HyperCatchRevertsEvents::AllocateFilter(element) => element.fmt(f),
                HyperCatchRevertsEvents::ChangeParametersFilter(element) => {
                    element.fmt(f)
                }
                HyperCatchRevertsEvents::CollectFilter(element) => element.fmt(f),
                HyperCatchRevertsEvents::CreatePairFilter(element) => element.fmt(f),
                HyperCatchRevertsEvents::CreatePoolFilter(element) => element.fmt(f),
                HyperCatchRevertsEvents::DecreaseReserveBalanceFilter(element) => {
                    element.fmt(f)
                }
                HyperCatchRevertsEvents::DecreaseUserBalanceFilter(element) => {
                    element.fmt(f)
                }
                HyperCatchRevertsEvents::DepositFilter(element) => element.fmt(f),
                HyperCatchRevertsEvents::IncreaseReserveBalanceFilter(element) => {
                    element.fmt(f)
                }
                HyperCatchRevertsEvents::IncreaseUserBalanceFilter(element) => {
                    element.fmt(f)
                }
                HyperCatchRevertsEvents::StakeFilter(element) => element.fmt(f),
                HyperCatchRevertsEvents::SwapFilter(element) => element.fmt(f),
                HyperCatchRevertsEvents::UnallocateFilter(element) => element.fmt(f),
                HyperCatchRevertsEvents::UnstakeFilter(element) => element.fmt(f),
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
    #[ethcall(name = "deposit", abi = "deposit()")]
    pub struct DepositCall;
    ///Container type for all input parameters for the `doJumpProcess` function with signature `doJumpProcess(bytes)` and selector `0xe82b84b4`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
    #[ethcall(name = "doJumpProcess", abi = "doJumpProcess(bytes)")]
    pub struct DoJumpProcessCall {
        pub data: ::ethers::core::types::Bytes,
    }
    ///Container type for all input parameters for the `draw` function with signature `draw(address,uint256,address)` and selector `0xad24d6a0`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
    #[ethcall(name = "getMaxLiquidity", abi = "getMaxLiquidity(uint64,uint256,uint256)")]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
    #[ethcall(name = "getVirtualReserves", abi = "getVirtualReserves(uint64)")]
    pub struct GetVirtualReservesCall {
        pub pool_id: u64,
    }
    ///Container type for all input parameters for the `jitDelay` function with signature `jitDelay()` and selector `0xa1f4405d`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
    #[ethcall(name = "jitDelay", abi = "jitDelay()")]
    pub struct JitDelayCall;
    ///Container type for all input parameters for the `jumpProcess` function with signature `jumpProcess(bytes)` and selector `0x80aa2019`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
    #[ethcall(name = "jumpProcess", abi = "jumpProcess(bytes)")]
    pub struct JumpProcessCall {
        pub data: ::ethers::core::types::Bytes,
    }
    ///Container type for all input parameters for the `mockFallback` function with signature `mockFallback(bytes)` and selector `0xb3b528a2`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
    #[ethcall(name = "mockFallback", abi = "mockFallback(bytes)")]
    pub struct MockFallbackCall {
        pub data: ::ethers::core::types::Bytes,
    }
    ///Container type for all input parameters for the `pairs` function with signature `pairs(uint24)` and selector `0x5e47663c`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
    #[ethcall(name = "positions", abi = "positions(address,uint64)")]
    pub struct PositionsCall(pub ::ethers::core::types::Address, pub u64);
    ///Container type for all input parameters for the `process` function with signature `process(bytes)` and selector `0x928bc4b2`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
    #[ethcall(name = "process", abi = "process(bytes)")]
    pub struct ProcessCall {
        pub data: ::ethers::core::types::Bytes,
    }
    ///Container type for all input parameters for the `setJitPolicy` function with signature `setJitPolicy(uint256)` and selector `0x4a9866b4`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
    #[ethcall(name = "setJitPolicy", abi = "setJitPolicy(uint256)")]
    pub struct SetJitPolicyCall {
        pub delay: ::ethers::core::types::U256,
    }
    ///Container type for all input parameters for the `setTimestamp` function with signature `setTimestamp(uint128)` and selector `0xf740485b`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
    #[ethcall(name = "setTimestamp", abi = "setTimestamp(uint128)")]
    pub struct SetTimestampCall {
        pub time: u128,
    }
    ///Container type for all input parameters for the `stake` function with signature `stake(uint64,uint128)` and selector `0x23135811`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
    #[ethcall(name = "swap", abi = "swap(uint64,bool,uint256,uint256)")]
    pub struct SwapCall {
        pub pool_id: u64,
        pub sell_asset: bool,
        pub amount: ::ethers::core::types::U256,
        pub limit: ::ethers::core::types::U256,
    }
    ///Container type for all input parameters for the `timestamp` function with signature `timestamp()` and selector `0xb80777ea`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
    #[ethcall(name = "timestamp", abi = "timestamp()")]
    pub struct TimestampCall;
    ///Container type for all input parameters for the `unallocate` function with signature `unallocate(uint64,uint256)` and selector `0xbcf78a5a`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
    #[ethcall(name = "unstake", abi = "unstake(uint64,uint128)")]
    pub struct UnstakeCall {
        pub pool_id: u64,
        pub delta_liquidity: u128,
    }
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum HyperCatchRevertsCalls {
        Version(VersionCall),
        Weth(WethCall),
        Account(AccountCall),
        Allocate(AllocateCall),
        ChangeParameters(ChangeParametersCall),
        Claim(ClaimCall),
        Deposit(DepositCall),
        DoJumpProcess(DoJumpProcessCall),
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
        JitDelay(JitDelayCall),
        JumpProcess(JumpProcessCall),
        MockFallback(MockFallbackCall),
        Pairs(PairsCall),
        Pools(PoolsCall),
        Positions(PositionsCall),
        Process(ProcessCall),
        SetJitPolicy(SetJitPolicyCall),
        SetTimestamp(SetTimestampCall),
        Stake(StakeCall),
        Swap(SwapCall),
        Timestamp(TimestampCall),
        Unallocate(UnallocateCall),
        Unstake(UnstakeCall),
    }
    impl ::ethers::core::abi::AbiDecode for HyperCatchRevertsCalls {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded)
                = <VersionCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::Version(decoded));
            }
            if let Ok(decoded)
                = <WethCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperCatchRevertsCalls::Weth(decoded));
            }
            if let Ok(decoded)
                = <AccountCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::Account(decoded));
            }
            if let Ok(decoded)
                = <AllocateCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::Allocate(decoded));
            }
            if let Ok(decoded)
                = <ChangeParametersCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::ChangeParameters(decoded));
            }
            if let Ok(decoded)
                = <ClaimCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperCatchRevertsCalls::Claim(decoded));
            }
            if let Ok(decoded)
                = <DepositCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::Deposit(decoded));
            }
            if let Ok(decoded)
                = <DoJumpProcessCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::DoJumpProcess(decoded));
            }
            if let Ok(decoded)
                = <DrawCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperCatchRevertsCalls::Draw(decoded));
            }
            if let Ok(decoded)
                = <FundCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperCatchRevertsCalls::Fund(decoded));
            }
            if let Ok(decoded)
                = <GetAmountOutCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::GetAmountOut(decoded));
            }
            if let Ok(decoded)
                = <GetAmountsCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::GetAmounts(decoded));
            }
            if let Ok(decoded)
                = <GetBalanceCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::GetBalance(decoded));
            }
            if let Ok(decoded)
                = <GetLatestPriceCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::GetLatestPrice(decoded));
            }
            if let Ok(decoded)
                = <GetLiquidityDeltasCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::GetLiquidityDeltas(decoded));
            }
            if let Ok(decoded)
                = <GetMaxLiquidityCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::GetMaxLiquidity(decoded));
            }
            if let Ok(decoded)
                = <GetNetBalanceCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::GetNetBalance(decoded));
            }
            if let Ok(decoded)
                = <GetPairIdCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::GetPairId(decoded));
            }
            if let Ok(decoded)
                = <GetPairNonceCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::GetPairNonce(decoded));
            }
            if let Ok(decoded)
                = <GetPoolNonceCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::GetPoolNonce(decoded));
            }
            if let Ok(decoded)
                = <GetReserveCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::GetReserve(decoded));
            }
            if let Ok(decoded)
                = <GetTimePassedCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::GetTimePassed(decoded));
            }
            if let Ok(decoded)
                = <GetVirtualReservesCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::GetVirtualReserves(decoded));
            }
            if let Ok(decoded)
                = <JitDelayCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::JitDelay(decoded));
            }
            if let Ok(decoded)
                = <JumpProcessCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::JumpProcess(decoded));
            }
            if let Ok(decoded)
                = <MockFallbackCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::MockFallback(decoded));
            }
            if let Ok(decoded)
                = <PairsCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperCatchRevertsCalls::Pairs(decoded));
            }
            if let Ok(decoded)
                = <PoolsCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperCatchRevertsCalls::Pools(decoded));
            }
            if let Ok(decoded)
                = <PositionsCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::Positions(decoded));
            }
            if let Ok(decoded)
                = <ProcessCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::Process(decoded));
            }
            if let Ok(decoded)
                = <SetJitPolicyCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::SetJitPolicy(decoded));
            }
            if let Ok(decoded)
                = <SetTimestampCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::SetTimestamp(decoded));
            }
            if let Ok(decoded)
                = <StakeCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperCatchRevertsCalls::Stake(decoded));
            }
            if let Ok(decoded)
                = <SwapCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperCatchRevertsCalls::Swap(decoded));
            }
            if let Ok(decoded)
                = <TimestampCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::Timestamp(decoded));
            }
            if let Ok(decoded)
                = <UnallocateCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::Unallocate(decoded));
            }
            if let Ok(decoded)
                = <UnstakeCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperCatchRevertsCalls::Unstake(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for HyperCatchRevertsCalls {
        fn encode(self) -> Vec<u8> {
            match self {
                HyperCatchRevertsCalls::Version(element) => element.encode(),
                HyperCatchRevertsCalls::Weth(element) => element.encode(),
                HyperCatchRevertsCalls::Account(element) => element.encode(),
                HyperCatchRevertsCalls::Allocate(element) => element.encode(),
                HyperCatchRevertsCalls::ChangeParameters(element) => element.encode(),
                HyperCatchRevertsCalls::Claim(element) => element.encode(),
                HyperCatchRevertsCalls::Deposit(element) => element.encode(),
                HyperCatchRevertsCalls::DoJumpProcess(element) => element.encode(),
                HyperCatchRevertsCalls::Draw(element) => element.encode(),
                HyperCatchRevertsCalls::Fund(element) => element.encode(),
                HyperCatchRevertsCalls::GetAmountOut(element) => element.encode(),
                HyperCatchRevertsCalls::GetAmounts(element) => element.encode(),
                HyperCatchRevertsCalls::GetBalance(element) => element.encode(),
                HyperCatchRevertsCalls::GetLatestPrice(element) => element.encode(),
                HyperCatchRevertsCalls::GetLiquidityDeltas(element) => element.encode(),
                HyperCatchRevertsCalls::GetMaxLiquidity(element) => element.encode(),
                HyperCatchRevertsCalls::GetNetBalance(element) => element.encode(),
                HyperCatchRevertsCalls::GetPairId(element) => element.encode(),
                HyperCatchRevertsCalls::GetPairNonce(element) => element.encode(),
                HyperCatchRevertsCalls::GetPoolNonce(element) => element.encode(),
                HyperCatchRevertsCalls::GetReserve(element) => element.encode(),
                HyperCatchRevertsCalls::GetTimePassed(element) => element.encode(),
                HyperCatchRevertsCalls::GetVirtualReserves(element) => element.encode(),
                HyperCatchRevertsCalls::JitDelay(element) => element.encode(),
                HyperCatchRevertsCalls::JumpProcess(element) => element.encode(),
                HyperCatchRevertsCalls::MockFallback(element) => element.encode(),
                HyperCatchRevertsCalls::Pairs(element) => element.encode(),
                HyperCatchRevertsCalls::Pools(element) => element.encode(),
                HyperCatchRevertsCalls::Positions(element) => element.encode(),
                HyperCatchRevertsCalls::Process(element) => element.encode(),
                HyperCatchRevertsCalls::SetJitPolicy(element) => element.encode(),
                HyperCatchRevertsCalls::SetTimestamp(element) => element.encode(),
                HyperCatchRevertsCalls::Stake(element) => element.encode(),
                HyperCatchRevertsCalls::Swap(element) => element.encode(),
                HyperCatchRevertsCalls::Timestamp(element) => element.encode(),
                HyperCatchRevertsCalls::Unallocate(element) => element.encode(),
                HyperCatchRevertsCalls::Unstake(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for HyperCatchRevertsCalls {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                HyperCatchRevertsCalls::Version(element) => element.fmt(f),
                HyperCatchRevertsCalls::Weth(element) => element.fmt(f),
                HyperCatchRevertsCalls::Account(element) => element.fmt(f),
                HyperCatchRevertsCalls::Allocate(element) => element.fmt(f),
                HyperCatchRevertsCalls::ChangeParameters(element) => element.fmt(f),
                HyperCatchRevertsCalls::Claim(element) => element.fmt(f),
                HyperCatchRevertsCalls::Deposit(element) => element.fmt(f),
                HyperCatchRevertsCalls::DoJumpProcess(element) => element.fmt(f),
                HyperCatchRevertsCalls::Draw(element) => element.fmt(f),
                HyperCatchRevertsCalls::Fund(element) => element.fmt(f),
                HyperCatchRevertsCalls::GetAmountOut(element) => element.fmt(f),
                HyperCatchRevertsCalls::GetAmounts(element) => element.fmt(f),
                HyperCatchRevertsCalls::GetBalance(element) => element.fmt(f),
                HyperCatchRevertsCalls::GetLatestPrice(element) => element.fmt(f),
                HyperCatchRevertsCalls::GetLiquidityDeltas(element) => element.fmt(f),
                HyperCatchRevertsCalls::GetMaxLiquidity(element) => element.fmt(f),
                HyperCatchRevertsCalls::GetNetBalance(element) => element.fmt(f),
                HyperCatchRevertsCalls::GetPairId(element) => element.fmt(f),
                HyperCatchRevertsCalls::GetPairNonce(element) => element.fmt(f),
                HyperCatchRevertsCalls::GetPoolNonce(element) => element.fmt(f),
                HyperCatchRevertsCalls::GetReserve(element) => element.fmt(f),
                HyperCatchRevertsCalls::GetTimePassed(element) => element.fmt(f),
                HyperCatchRevertsCalls::GetVirtualReserves(element) => element.fmt(f),
                HyperCatchRevertsCalls::JitDelay(element) => element.fmt(f),
                HyperCatchRevertsCalls::JumpProcess(element) => element.fmt(f),
                HyperCatchRevertsCalls::MockFallback(element) => element.fmt(f),
                HyperCatchRevertsCalls::Pairs(element) => element.fmt(f),
                HyperCatchRevertsCalls::Pools(element) => element.fmt(f),
                HyperCatchRevertsCalls::Positions(element) => element.fmt(f),
                HyperCatchRevertsCalls::Process(element) => element.fmt(f),
                HyperCatchRevertsCalls::SetJitPolicy(element) => element.fmt(f),
                HyperCatchRevertsCalls::SetTimestamp(element) => element.fmt(f),
                HyperCatchRevertsCalls::Stake(element) => element.fmt(f),
                HyperCatchRevertsCalls::Swap(element) => element.fmt(f),
                HyperCatchRevertsCalls::Timestamp(element) => element.fmt(f),
                HyperCatchRevertsCalls::Unallocate(element) => element.fmt(f),
                HyperCatchRevertsCalls::Unstake(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<VersionCall> for HyperCatchRevertsCalls {
        fn from(var: VersionCall) -> Self {
            HyperCatchRevertsCalls::Version(var)
        }
    }
    impl ::std::convert::From<WethCall> for HyperCatchRevertsCalls {
        fn from(var: WethCall) -> Self {
            HyperCatchRevertsCalls::Weth(var)
        }
    }
    impl ::std::convert::From<AccountCall> for HyperCatchRevertsCalls {
        fn from(var: AccountCall) -> Self {
            HyperCatchRevertsCalls::Account(var)
        }
    }
    impl ::std::convert::From<AllocateCall> for HyperCatchRevertsCalls {
        fn from(var: AllocateCall) -> Self {
            HyperCatchRevertsCalls::Allocate(var)
        }
    }
    impl ::std::convert::From<ChangeParametersCall> for HyperCatchRevertsCalls {
        fn from(var: ChangeParametersCall) -> Self {
            HyperCatchRevertsCalls::ChangeParameters(var)
        }
    }
    impl ::std::convert::From<ClaimCall> for HyperCatchRevertsCalls {
        fn from(var: ClaimCall) -> Self {
            HyperCatchRevertsCalls::Claim(var)
        }
    }
    impl ::std::convert::From<DepositCall> for HyperCatchRevertsCalls {
        fn from(var: DepositCall) -> Self {
            HyperCatchRevertsCalls::Deposit(var)
        }
    }
    impl ::std::convert::From<DoJumpProcessCall> for HyperCatchRevertsCalls {
        fn from(var: DoJumpProcessCall) -> Self {
            HyperCatchRevertsCalls::DoJumpProcess(var)
        }
    }
    impl ::std::convert::From<DrawCall> for HyperCatchRevertsCalls {
        fn from(var: DrawCall) -> Self {
            HyperCatchRevertsCalls::Draw(var)
        }
    }
    impl ::std::convert::From<FundCall> for HyperCatchRevertsCalls {
        fn from(var: FundCall) -> Self {
            HyperCatchRevertsCalls::Fund(var)
        }
    }
    impl ::std::convert::From<GetAmountOutCall> for HyperCatchRevertsCalls {
        fn from(var: GetAmountOutCall) -> Self {
            HyperCatchRevertsCalls::GetAmountOut(var)
        }
    }
    impl ::std::convert::From<GetAmountsCall> for HyperCatchRevertsCalls {
        fn from(var: GetAmountsCall) -> Self {
            HyperCatchRevertsCalls::GetAmounts(var)
        }
    }
    impl ::std::convert::From<GetBalanceCall> for HyperCatchRevertsCalls {
        fn from(var: GetBalanceCall) -> Self {
            HyperCatchRevertsCalls::GetBalance(var)
        }
    }
    impl ::std::convert::From<GetLatestPriceCall> for HyperCatchRevertsCalls {
        fn from(var: GetLatestPriceCall) -> Self {
            HyperCatchRevertsCalls::GetLatestPrice(var)
        }
    }
    impl ::std::convert::From<GetLiquidityDeltasCall> for HyperCatchRevertsCalls {
        fn from(var: GetLiquidityDeltasCall) -> Self {
            HyperCatchRevertsCalls::GetLiquidityDeltas(var)
        }
    }
    impl ::std::convert::From<GetMaxLiquidityCall> for HyperCatchRevertsCalls {
        fn from(var: GetMaxLiquidityCall) -> Self {
            HyperCatchRevertsCalls::GetMaxLiquidity(var)
        }
    }
    impl ::std::convert::From<GetNetBalanceCall> for HyperCatchRevertsCalls {
        fn from(var: GetNetBalanceCall) -> Self {
            HyperCatchRevertsCalls::GetNetBalance(var)
        }
    }
    impl ::std::convert::From<GetPairIdCall> for HyperCatchRevertsCalls {
        fn from(var: GetPairIdCall) -> Self {
            HyperCatchRevertsCalls::GetPairId(var)
        }
    }
    impl ::std::convert::From<GetPairNonceCall> for HyperCatchRevertsCalls {
        fn from(var: GetPairNonceCall) -> Self {
            HyperCatchRevertsCalls::GetPairNonce(var)
        }
    }
    impl ::std::convert::From<GetPoolNonceCall> for HyperCatchRevertsCalls {
        fn from(var: GetPoolNonceCall) -> Self {
            HyperCatchRevertsCalls::GetPoolNonce(var)
        }
    }
    impl ::std::convert::From<GetReserveCall> for HyperCatchRevertsCalls {
        fn from(var: GetReserveCall) -> Self {
            HyperCatchRevertsCalls::GetReserve(var)
        }
    }
    impl ::std::convert::From<GetTimePassedCall> for HyperCatchRevertsCalls {
        fn from(var: GetTimePassedCall) -> Self {
            HyperCatchRevertsCalls::GetTimePassed(var)
        }
    }
    impl ::std::convert::From<GetVirtualReservesCall> for HyperCatchRevertsCalls {
        fn from(var: GetVirtualReservesCall) -> Self {
            HyperCatchRevertsCalls::GetVirtualReserves(var)
        }
    }
    impl ::std::convert::From<JitDelayCall> for HyperCatchRevertsCalls {
        fn from(var: JitDelayCall) -> Self {
            HyperCatchRevertsCalls::JitDelay(var)
        }
    }
    impl ::std::convert::From<JumpProcessCall> for HyperCatchRevertsCalls {
        fn from(var: JumpProcessCall) -> Self {
            HyperCatchRevertsCalls::JumpProcess(var)
        }
    }
    impl ::std::convert::From<MockFallbackCall> for HyperCatchRevertsCalls {
        fn from(var: MockFallbackCall) -> Self {
            HyperCatchRevertsCalls::MockFallback(var)
        }
    }
    impl ::std::convert::From<PairsCall> for HyperCatchRevertsCalls {
        fn from(var: PairsCall) -> Self {
            HyperCatchRevertsCalls::Pairs(var)
        }
    }
    impl ::std::convert::From<PoolsCall> for HyperCatchRevertsCalls {
        fn from(var: PoolsCall) -> Self {
            HyperCatchRevertsCalls::Pools(var)
        }
    }
    impl ::std::convert::From<PositionsCall> for HyperCatchRevertsCalls {
        fn from(var: PositionsCall) -> Self {
            HyperCatchRevertsCalls::Positions(var)
        }
    }
    impl ::std::convert::From<ProcessCall> for HyperCatchRevertsCalls {
        fn from(var: ProcessCall) -> Self {
            HyperCatchRevertsCalls::Process(var)
        }
    }
    impl ::std::convert::From<SetJitPolicyCall> for HyperCatchRevertsCalls {
        fn from(var: SetJitPolicyCall) -> Self {
            HyperCatchRevertsCalls::SetJitPolicy(var)
        }
    }
    impl ::std::convert::From<SetTimestampCall> for HyperCatchRevertsCalls {
        fn from(var: SetTimestampCall) -> Self {
            HyperCatchRevertsCalls::SetTimestamp(var)
        }
    }
    impl ::std::convert::From<StakeCall> for HyperCatchRevertsCalls {
        fn from(var: StakeCall) -> Self {
            HyperCatchRevertsCalls::Stake(var)
        }
    }
    impl ::std::convert::From<SwapCall> for HyperCatchRevertsCalls {
        fn from(var: SwapCall) -> Self {
            HyperCatchRevertsCalls::Swap(var)
        }
    }
    impl ::std::convert::From<TimestampCall> for HyperCatchRevertsCalls {
        fn from(var: TimestampCall) -> Self {
            HyperCatchRevertsCalls::Timestamp(var)
        }
    }
    impl ::std::convert::From<UnallocateCall> for HyperCatchRevertsCalls {
        fn from(var: UnallocateCall) -> Self {
            HyperCatchRevertsCalls::Unallocate(var)
        }
    }
    impl ::std::convert::From<UnstakeCall> for HyperCatchRevertsCalls {
        fn from(var: UnstakeCall) -> Self {
            HyperCatchRevertsCalls::Unstake(var)
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
    )]
    #[derive(Default)]
    pub struct VersionReturn(pub String);
    ///Container type for all return fields from the `WETH` function with signature `WETH()` and selector `0xad5c4648`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct WethReturn(pub ::ethers::core::types::Address);
    ///Container type for all return fields from the `__account__` function with signature `__account__()` and selector `0xda31ee54`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
    pub struct GetBalanceReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getLatestPrice` function with signature `getLatestPrice(uint64)` and selector `0x8c470b8f`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
    pub struct GetNetBalanceReturn(pub ::ethers::core::types::I256);
    ///Container type for all return fields from the `getPairId` function with signature `getPairId(address,address)` and selector `0x3f92a339`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct GetPairIdReturn(pub u32);
    ///Container type for all return fields from the `getPairNonce` function with signature `getPairNonce()` and selector `0x078888d6`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct GetPairNonceReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getPoolNonce` function with signature `getPoolNonce()` and selector `0xfd2dbea1`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct GetPoolNonceReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getReserve` function with signature `getReserve(address)` and selector `0xc9a396e9`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct GetReserveReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getTimePassed` function with signature `getTimePassed(uint64)` and selector `0x0242f403`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct GetTimePassedReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getVirtualReserves` function with signature `getVirtualReserves(uint64)` and selector `0x5ef05b0c`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct GetVirtualReservesReturn {
        pub delta_asset: u128,
        pub delta_quote: u128,
    }
    ///Container type for all return fields from the `jitDelay` function with signature `jitDelay()` and selector `0xa1f4405d`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct JitDelayReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `pairs` function with signature `pairs(uint24)` and selector `0x5e47663c`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
    pub struct SwapReturn {
        pub output: ::ethers::core::types::U256,
        pub remainder: ::ethers::core::types::U256,
    }
    ///Container type for all return fields from the `timestamp` function with signature `timestamp()` and selector `0xb80777ea`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct TimestampReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `unallocate` function with signature `unallocate(uint64,uint256)` and selector `0xbcf78a5a`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct UnallocateReturn {
        pub delta_asset: ::ethers::core::types::U256,
        pub delta_quote: ::ethers::core::types::U256,
    }
}
