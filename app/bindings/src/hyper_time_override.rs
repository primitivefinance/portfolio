pub use hyper_time_override::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod hyper_time_override {
    #![allow(clippy::enum_variant_names)]
    #![allow(dead_code)]
    #![allow(clippy::type_complexity)]
    #![allow(unused_imports)]
    ///HyperTimeOverride was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
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
    const __ABI: &str = "[{\"inputs\":[{\"internalType\":\"address\",\"name\":\"weth\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"constructor\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"DrawBalance\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"EtherTransferFail\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"Infinity\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"type\":\"error\",\"name\":\"InsufficientPosition\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"delta\",\"type\":\"uint256\",\"components\":[]}],\"type\":\"error\",\"name\":\"InsufficientReserve\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidBalance\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"expected\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"length\",\"type\":\"uint256\",\"components\":[]}],\"type\":\"error\",\"name\":\"InvalidBytesLength\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint8\",\"name\":\"decimals\",\"type\":\"uint8\",\"components\":[]}],\"type\":\"error\",\"name\":\"InvalidDecimals\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]}],\"type\":\"error\",\"name\":\"InvalidFee\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidInstruction\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"int256\",\"name\":\"prev\",\"type\":\"int256\",\"components\":[]},{\"internalType\":\"int256\",\"name\":\"next\",\"type\":\"int256\",\"components\":[]}],\"type\":\"error\",\"name\":\"InvalidInvariant\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"pointer\",\"type\":\"uint256\",\"components\":[]}],\"type\":\"error\",\"name\":\"InvalidJump\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidReentrancy\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidReward\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidSettlement\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidTransfer\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"distance\",\"type\":\"uint256\",\"components\":[]}],\"type\":\"error\",\"name\":\"JitLiquidity\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"Min\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"NegativeInfinity\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"type\":\"error\",\"name\":\"NonExistentPool\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"type\":\"error\",\"name\":\"NonExistentPosition\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"NotController\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"NotPreparedToSettle\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"OOB\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"int256\",\"name\":\"wad\",\"type\":\"int256\",\"components\":[]}],\"type\":\"error\",\"name\":\"OverflowWad\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint24\",\"name\":\"pairId\",\"type\":\"uint24\",\"components\":[]}],\"type\":\"error\",\"name\":\"PairExists\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"PoolExists\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"PoolExpired\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint96\",\"name\":\"positionId\",\"type\":\"uint96\",\"components\":[]}],\"type\":\"error\",\"name\":\"PositionNotStaked\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"SameTokenError\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"type\":\"error\",\"name\":\"StakeNotMature\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"SwapLimitReached\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"ZeroInput\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"ZeroLiquidity\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"ZeroPrice\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"ZeroValue\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"quote\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"deltaLiquidity\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Allocate\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[],\"indexed\":false},{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[],\"indexed\":true}],\"type\":\"event\",\"name\":\"ChangeParameters\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"account\",\"type\":\"address\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"feeAsset\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"feeQuote\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"quote\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"feeReward\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"reward\",\"type\":\"address\",\"components\":[],\"indexed\":true}],\"type\":\"event\",\"name\":\"Collect\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint24\",\"name\":\"pairId\",\"type\":\"uint24\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"quote\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"CreatePair\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":true},{\"internalType\":\"bool\",\"name\":\"isMutable\",\"type\":\"bool\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"quote\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"price\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"CreatePool\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"DecreaseReserveBalance\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"account\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"DecreaseUserBalance\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"account\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Deposit\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"IncreaseReserveBalance\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"account\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"IncreaseUserBalance\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"deltaLiquidity\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Stake\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"price\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"tokenIn\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"input\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"tokenOut\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"output\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Swap\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"asset\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"quote\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"deltaLiquidity\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Unallocate\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"deltaLiquidity\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Unstake\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[],\"stateMutability\":\"payable\",\"type\":\"fallback\",\"outputs\":[]},{\"inputs\":[],\"stateMutability\":\"pure\",\"type\":\"function\",\"name\":\"VERSION\",\"outputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"WETH\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__account__\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"prepared\",\"type\":\"bool\",\"components\":[]},{\"internalType\":\"bool\",\"name\":\"settled\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"allocate\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"changeParameters\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"claim\",\"outputs\":[]},{\"inputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\",\"name\":\"deposit\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"data\",\"type\":\"bytes\",\"components\":[]}],\"stateMutability\":\"payable\",\"type\":\"function\",\"name\":\"doJumpProcess\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"to\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"draw\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"fund\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"bool\",\"name\":\"sellAsset\",\"type\":\"bool\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amountIn\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getAmountOut\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"output\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getAmounts\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getLatestPrice\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"price\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"int128\",\"name\":\"deltaLiquidity\",\"type\":\"int128\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getLiquidityDeltas\",\"outputs\":[{\"internalType\":\"uint128\",\"name\":\"deltaAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"deltaQuote\",\"type\":\"uint128\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getMaxLiquidity\",\"outputs\":[{\"internalType\":\"uint128\",\"name\":\"deltaLiquidity\",\"type\":\"uint128\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getNetBalance\",\"outputs\":[{\"internalType\":\"int256\",\"name\":\"\",\"type\":\"int256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPairId\",\"outputs\":[{\"internalType\":\"uint24\",\"name\":\"\",\"type\":\"uint24\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPairNonce\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPoolNonce\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getReserve\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getTimePassed\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getVirtualReserves\",\"outputs\":[{\"internalType\":\"uint128\",\"name\":\"deltaAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"deltaQuote\",\"type\":\"uint128\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"jitDelay\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint24\",\"name\":\"\",\"type\":\"uint24\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"pairs\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"pools\",\"outputs\":[{\"internalType\":\"int24\",\"name\":\"lastTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"lastTimestamp\",\"type\":\"uint32\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"controller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalReward\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"lastPrice\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"liquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"int128\",\"name\":\"stakedLiquidityDelta\",\"type\":\"int128\",\"components\":[]},{\"internalType\":\"struct HyperCurve\",\"name\":\"params\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]},{\"internalType\":\"struct HyperPair\",\"name\":\"pair\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"positions\",\"outputs\":[{\"internalType\":\"uint128\",\"name\":\"freeLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"lastTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"stakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"unstakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthRewardLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuoteLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedQuote\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedReward\",\"type\":\"uint128\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"delay\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"setJitPolicy\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint128\",\"name\":\"time\",\"type\":\"uint128\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"setTimestamp\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"deltaLiquidity\",\"type\":\"uint128\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"stake\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"bool\",\"name\":\"sellAsset\",\"type\":\"bool\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"limit\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"swap\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"output\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"remainder\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"timestamp\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"unallocate\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"deltaLiquidity\",\"type\":\"uint128\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"unstake\",\"outputs\":[]},{\"inputs\":[],\"stateMutability\":\"payable\",\"type\":\"receive\",\"outputs\":[]}]";
    /// The parsed JSON-ABI of the contract.
    pub static HYPERTIMEOVERRIDE_ABI: ::ethers::contract::Lazy<
        ::ethers::core::abi::Abi,
    > = ::ethers::contract::Lazy::new(|| {
        ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi")
    });
    /// Bytecode of the #name contract
    pub static HYPERTIMEOVERRIDE_BYTECODE: ::ethers::contract::Lazy<
        ::ethers::core::types::Bytes,
    > = ::ethers::contract::Lazy::new(|| {
        "0x60a06040526001600b553480156200001657600080fd5b5060405162009c2f38038062009c2f83398101604081905262000039916200005a565b6001600160a01b03166080526004805461ff0019166101001790556200008c565b6000602082840312156200006d57600080fd5b81516001600160a01b03811681146200008557600080fd5b9392505050565b608051619aed620001426000396000818161020d015281816102920152818161090b0152818161132f01528181611409015281816116a80152818161192001528181611f81015281816122f00152818161232e01528181612379015281816123f201528181612672015281816127fc015281816128a30152818161293a0152818161297601528181612a1d01528181612ac101528181612d9d015281816144620152818161449701526144ef0152619aed6000f3fe6080604052600436106101fd5760003560e01c8063a1f4405d1161010d578063c9a396e9116100a0578063da31ee541161006f578063da31ee5414610af8578063e82b84b414610b32578063f740485b14610b45578063fd2dbea114610b6e578063ffa1ad7414610b8457610239565b8063c9a396e914610a62578063d0e30db014610a98578063d4fac45d14610aa0578063d6b7dec514610ac057610239565b8063ad5c4648116100dc578063ad5c4648146108f9578063b68513ea14610945578063b80777ea14610a2c578063bcf78a5a14610a4257610239565b8063a1f4405d14610883578063a4c68d9d14610899578063a81262d5146108b9578063ad24d6a0146108d957610239565b80635ef05b0c116101905780638992f20a1161015f5780638992f20a1461056b57806389a5f0841461058b5780638c470b8f146108235780638e26770f146108435780639e5e2e291461086357610239565b80635ef05b0c146104cb5780636a707efa1461050b5780637b1837de1461052b5780637dae48901461054b57610239565b80633f92a339116101cc5780633f92a339146103af5780634a9866b4146104005780634dc68a90146104205780635e47663c1461044057610239565b80630242f40314610311578063078888d614610344578063231358111461035a5780632c0f89031461037a57610239565b3661023957336001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000161461023757600080fd5b005b600b5460011461025f5760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff161561028b5760405160016238ddf760e01b0319815260040160405180910390fd5b6102b660007f0000000000000000000000000000000000000000000000000000000000000000610ba6565b6004805460ff191690556102cb610c0f610e66565b6004805460ff191660011790556102e0610eb3565b600454610100900460ff16610308576040516304564c7160e21b815260040160405180910390fd5b6001600b819055005b34801561031d57600080fd5b5061033161032c366004618f58565b61128d565b6040519081526020015b60405180910390f35b34801561035057600080fd5b5061033160055481565b34801561036657600080fd5b50610237610375366004618f8a565b6112d6565b34801561038657600080fd5b5061039a610395366004618fb4565b6113ad565b6040805192835260208301919091520161033b565b3480156103bb57600080fd5b506103ec6103ca366004618ff5565b600960209081526000928352604080842090915290825290205462ffffff1681565b60405162ffffff909116815260200161033b565b34801561040c57600080fd5b5061023761041b36600461901f565b601355565b34801561042c57600080fd5b5061033161043b366004619038565b6114ae565b34801561044c57600080fd5b5061049761045b366004619053565b600760205260009081526040902080546001909101546001600160a01b038083169260ff600160a01b9182900481169392831692919091041684565b604080516001600160a01b03958616815260ff9485166020820152949092169184019190915216606082015260800161033b565b3480156104d757600080fd5b506104eb6104e6366004618f58565b6114c1565b604080516001600160801b0393841681529290911660208301520161033b565b34801561051757600080fd5b5061023761052636600461908a565b61164f565b34801561053757600080fd5b5061023761054636600461911a565b6118c7565b34801561055757600080fd5b50610331610566366004619146565b61195b565b34801561057757600080fd5b506104eb610586366004619182565b611d7d565b34801561059757600080fd5b5061080b6105a6366004618f58565b60086020528060005260406000206000915090508060000160009054906101000a900460020b908060000160039054906101000a900463ffffffff16908060000160079054906101000a90046001600160a01b0316908060010154908060020154908060030154908060040160009054906101000a90046001600160801b0316908060040160109054906101000a90046001600160801b0316908060050160009054906101000a90046001600160801b0316908060050160109054906101000a9004600f0b90806006016040518060e00160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900461ffff1661ffff1661ffff1681526020016000820160059054906101000a900461ffff1661ffff1661ffff1681526020016000820160079054906101000a900461ffff1661ffff1661ffff1681526020016000820160099054906101000a900461ffff1661ffff1661ffff16815260200160008201600b9054906101000a900461ffff1661ffff1661ffff16815260200160008201600d9054906101000a900463ffffffff1663ffffffff1663ffffffff168152505090806007016040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff168152505090508c565b60405161033b9c9b9a999897969594939291906191bf565b34801561082f57600080fd5b5061033161083e366004618f58565b611f14565b34801561084f57600080fd5b5061023761085e3660046192d9565b611f28565b34801561086f57600080fd5b5061039a61087e366004618f58565b612491565b34801561088f57600080fd5b5061033160135481565b3480156108a557600080fd5b5061039a6108b436600461930c565b612616565b3480156108c557600080fd5b506102376108d4366004618f8a565b6127a3565b3480156108e557600080fd5b506102376108f436600461934e565b61284a565b34801561090557600080fd5b5061092d7f000000000000000000000000000000000000000000000000000000000000000081565b6040516001600160a01b03909116815260200161033b565b34801561095157600080fd5b506109c9610960366004619381565b600a6020908152600092835260408084209091529082529020805460018201546002830154600384015460048501546005860154600687015460078801546008909801546001600160801b0380891699600160801b998a9004821699818316939104821691168b565b604080516001600160801b039c8d1681529a8c1660208c01528a01989098526060890196909652608088019490945260a087019290925260c086015260e0850152841661010084015283166101208301529091166101408201526101600161033b565b348015610a3857600080fd5b5061033160125481565b348015610a4e57600080fd5b5061039a610a5d366004618fb4565b6129c1565b348015610a6e57600080fd5b50610331610a7d366004619038565b6001600160a01b031660009081526001602052604090205490565b610237612a68565b348015610aac57600080fd5b50610331610abb366004618ff5565b612b89565b348015610acc57600080fd5b50610ae0610adb3660046192d9565b612bb2565b6040516001600160801b03909116815260200161033b565b348015610b0457600080fd5b50600454610b1b9060ff8082169161010090041682565b60408051921515835290151560208301520161033b565b610237610b403660046193ab565b612d44565b348015610b5157600080fd5b50610237610b6036600461941c565b6001600160801b0316601255565b348015610b7a57600080fd5b5061033160065481565b348015610b9057600080fd5b50610b99612dd8565b60405161033b9190619463565b3415610c0b57610bb68282612df5565b806001600160a01b031663d0e30db0346040518263ffffffff1660e01b81526004016000604051808303818588803b158015610bf157600080fd5b505af1158015610c05573d6000803e3d6000fd5b50505050505b5050565b6000610c4483836000818110610c2757610c27619496565b9190910135600481901c60ff60f41b1692600f60f81b9091169150565b9150506001600160f81b031980821601610c88576000806000610c678686612e8b565b925092509250610c7e8360ff166001148383612f18565b5050505050505050565b60fd60f81b6001600160f81b0319821601610cc3576000806000610cac8686613265565b925092509250610c7e8360ff1660011483836132f7565b60fb60f81b6001600160f81b0319821601610d4a576040805160a081018252600080825260208201819052918101829052606081018290526080810191909152610d0d84846137d6565b60ff90811660808701526001600160801b039182166060870152911660408501526001600160401b039091166020840152168152610c7e816138b3565b607d60f91b6001600160f81b0319821601610d8157600080610d6c8585614619565b91509150610d7a828261467d565b5050505050565b60f960f81b6001600160f81b0319821601610db957600080610da38585614619565b91509150610db18282614b9c565b505050505050565b60f560f81b6001600160f81b0319821601610e18576000806000806000806000806000610de68c8c614f38565b985098509850985098509850985098509850610e09898989898989898989615075565b50505050505050505050505050565b603d60fa1b6001600160f81b0319821601610e4857600080610e3a85856159fe565b91509150610db18282615a6a565b604051631b1891ed60e31b815260040160405180910390fd5b505050565b605560f91b6000368181610e7c57610e7c619496565b9050013560f81c60f81b6001600160f81b03191614610ea757610ea46000368363ffffffff16565b50565b610ea460003683615d22565b60045460ff16610ed657604051630f7cede560e41b815260040160405180910390fd5b600080600301805480602002602001604051908101604052809291908181526020018280548015610f3057602002820191906000526020600020905b81546001600160a01b03168152600190910190602001808311610f12575b5050505050905060008151905080600003610f4f57610c0b6000615ddf565b6000815b600084610f616001846194c2565b81518110610f7157610f71619496565b602002602001015190506000806000610f9684306000615e1d9092919063ffffffff16565b919450925090508115611027576040518281526001600160a01b0385169033907f0b0b821953e5545b71f2085833e4a8dfd0d99bbdff511898672ae8179a982df39060200160405180910390a3836001600160a01b03167f1c711eca8d0b694bbcb0a14462a7006222e721954b2c5ff798f606817eb110328360405161101e91815260200190565b60405180910390a25b82156110b1576040518381526001600160a01b0385169033907f49e1443cb25e17cbebc50aa3e3a5a3df3ac334af852bc6f3e8d258558257bb119060200160405180910390a3836001600160a01b03167f80b21748c787c52e87a6b222011e0a0ed0f9cc2015f0ced46748642dc62ee9f8846040516110a891815260200190565b60405180910390a25b801561114b57604080518082019091526001600160a01b03858116825260208201838152600c805460018101825560009190915292517fdf6966c971051c3d54ec59162606531493a51404a002842f56009d7e5cf4a8c7600290940293840180546001600160a01b0319169190931617909155517fdf6966c971051c3d54ec59162606531493a51404a002842f56009d7e5cf4a8c8909101555b600380548061115c5761115c6194d9565b6001900381819060005260206000200160006101000a8154906001600160a01b0302191690559055846001900394508560010195505050505080600003610f53576000600c805480602002602001604051908101604052809291908181526020016000905b82821015611209576000848152602090819020604080518082019091526002850290910180546001600160a01b031682526001908101548284015290835290920191016111c1565b5050825192935050505b80156112775760006112266001836194c2565b905061126d83828151811061123d5761123d619496565b6020026020010151600001513085848151811061125c5761125c619496565b602002602001015160200151615f02565b5060001901611213565b6112816000615ddf565b610db1600c6000618ec7565b6001600160401b03811660009081526008602052604081205463ffffffff6301000000909104166112bd60125490565b6112c791906194ef565b6001600160801b031692915050565b600b546001146112fc5760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff16156113285760405160016238ddf760e01b0319815260040160405180910390fd5b61135360007f0000000000000000000000000000000000000000000000000000000000000000610ba6565b6004805460ff19169055611367828261467d565b6004805460ff1916600117905561137c610eb3565b600454610100900460ff166113a4576040516304564c7160e21b815260040160405180910390fd5b50506001600b55565b600080600b546001146113d65760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff16156114025760405160016238ddf760e01b0319815260040160405180910390fd5b61142d60007f0000000000000000000000000000000000000000000000000000000000000000610ba6565b6004805460ff19169055600019831461145c81866114578261144f5787615f0e565b60015b615f0e565b612f18565b6004805460ff1916600117905590935091506114789050610eb3565b600454610100900460ff166114a0576040516304564c7160e21b815260040160405180910390fd5b6001600b5590939092509050565b60006114bb818330615f24565b92915050565b6001600160401b03811660009081526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187015460608088019190915284880154608080890191909152600389015460a0808a019190915260048a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681850152600160481b8804861681840152600160581b880490951690850152600160681b90950490931694820194909452610140850152855191820186526007850154808416835260ff600160a01b918290048116988401989098529490970154918216948101949094529190910490921692810192909252610160810191909152819061164690615f60565b91509150915091565b600b546001146116755760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff16156116a15760405160016238ddf760e01b0319815260040160405180910390fd5b6116cc60007f0000000000000000000000000000000000000000000000000000000000000000610ba6565b6004805460ff191690556001600160401b03871660009081526008602052604090208054600160381b90046001600160a01b0316331461171f576040516323019e6760e01b815260040160405180910390fd5b6040805160e0810182526006830154600281900b825261ffff6301000000820481166020840152600160281b8204811693830193909352600160381b810483166060830152600160481b810483166080830152600160581b8104831660a083015263ffffffff600160681b9091041660c0820152908416156117a65761ffff841660208201525b8260020b6000146117b957600283900b81525b61ffff8716156117ce5761ffff871660408201525b61ffff8616156117e35761ffff861660808201525b61ffff8516156117f85761ffff851660608201525b61ffff88161561180d5761ffff881660a08201525b6118178282615f7b565b6040805161ffff8a8116825288811660208301528781168284015286811660608301529151600286900b928a16916001600160401b038d16917f149d8f45beb243253e6bf4915f72c467b5a81370cfa27a62c7424755be95e5019181900360800190a450506004805460ff19166001179055611891610eb3565b600454610100900460ff166118b9576040516304564c7160e21b815260040160405180910390fd5b50506001600b555050505050565b600b546001146118ed5760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff16156119195760405160016238ddf760e01b0319815260040160405180910390fd5b61194460007f0000000000000000000000000000000000000000000000000000000000000000610ba6565b6004805460ff191690556113676000833084616064565b600080602885901c62ffffff169050600060086000876001600160401b03166001600160401b03168152602001908152602001600020604051806101800160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900463ffffffff1663ffffffff1663ffffffff1681526020016000820160079054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820154815260200160028201548152602001600382015481526020016004820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016004820160109054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160109054906101000a9004600f0b600f0b600f0b8152602001600682016040518060e00160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900461ffff1661ffff1661ffff1681526020016000820160059054906101000a900461ffff1661ffff1661ffff1681526020016000820160079054906101000a900461ffff1661ffff1661ffff1681526020016000820160099054906101000a900461ffff1661ffff1661ffff16815260200160008201600b9054906101000a900461ffff1661ffff1661ffff16815260200160008201600d9054906101000a900463ffffffff1663ffffffff1663ffffffff16815250508152602001600782016040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff1681525050815250509050611d72600760008462ffffff1662ffffff1681526020019081526020016000206040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff16815250508686846020015163ffffffff16611d5560125490565b611d5f91906194ef565b85939291906001600160801b031661607f565b509695505050505050565b6001600160401b03821660009081526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187015460608088019190915284880154608080890191909152600389015460a0808a019190915260048a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681850152600160481b8804861681840152600160581b880490951690850152600160681b909504841695830195909552610140860191909152865192830187526007860154808216845260ff600160a01b9182900481169985019990995295909801549788169582019590955292909504909316938101939093526101608201929092528291611f089190859061638116565b915091505b9250929050565b6000611f1f82616416565b50909392505050565b600b54600114611f4e5760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff1615611f7a5760405160016238ddf760e01b0319815260040160405180910390fd5b611fa560007f0000000000000000000000000000000000000000000000000000000000000000610ba6565b6004805460ff191681556001600160401b03841660008181526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187810154606080890191909152858901546080808a019190915260038a015460a0808b01919091529f8a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681840152600160481b8804861681830152600160581b88049095169f85019f909f52600160681b9095049093169482019490945261014085015285519a8b01865260078501548084168c52600160a01b9081900460ff9081168d8a015295909801549283168b8701529690910490921691880191909152610160810196909652338452600a825280842094845293905291812091820154900361217357604051632f9b02db60e11b81523360048201526001600160401b03861660248201526044015b60405180910390fd5b61219f8260e001516001600160801b031683608001518460a001518461663e909392919063ffffffff16565b50506121aa84615f0e565b6007820180546000906121c79084906001600160801b03166194ef565b92506101000a8154816001600160801b0302191690836001600160801b031602179055506121f483615f0e565b600782018054601090612218908490600160801b90046001600160801b03166194ef565b92506101000a8154816001600160801b0302191690836001600160801b03160217905550600084111561225657610160820151516122569085616731565b821561226f5761226f8261016001516040015184616731565b6122968261010001516001600160801b03168360600151836167839092919063ffffffff16565b506008810180546001600160801b031690819060006122b583806194ef565b92506101000a8154816001600160801b0302191690836001600160801b031602179055506000816001600160801b031611156123aa5761231e7f0000000000000000000000000000000000000000000000000000000000000000826001600160801b0316616731565b806001600160801b0316612352307f0000000000000000000000000000000000000000000000000000000000000000612b89565b1015612371576040516314414f4160e11b815260040160405180910390fd5b6123a76000307f00000000000000000000000000000000000000000000000000000000000000006001600160801b0385166167fb565b50505b610160830151604080820151915181516001600160401b038a168152336020820152918201889052606082018790526001600160801b03841660808301526001600160a01b037f00000000000000000000000000000000000000000000000000000000000000008116938116929116907f8c84cdba09392140d3a3451ef9fd7f258a06ace3b8492bc20598872a630084d49060a00160405180910390a450506004805460ff191660011790555061245f610eb3565b600454610100900460ff16612487576040516304564c7160e21b815260040160405180910390fd5b50506001600b5550565b6001600160401b03811660009081526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187015460608088019190915284880154608080890191909152600389015460a0808a019190915260048a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681850152600160481b8804861681840152600160581b880490951690850152600160681b90950490931694820194909452610140850152855191820186526007850154808416835260ff600160a01b9182900481169884019890985294909701549182169481019490945291909104909216928101929092526101608101919091528190611646906168d1565b600080600b5460011461263f5760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff161561266b5760405160016238ddf760e01b0319815260040160405180910390fd5b61269660007f0000000000000000000000000000000000000000000000000000000000000000610ba6565b6004805460ff19169055600183016126b3576001600160801b0392505b60001984146000816126cd576126c886615f0e565b6126d6565b6001600160801b035b905061274b6040518060a00160405280846126f25760006126f5565b60015b60ff1681526020018a6001600160401b03168152602001836001600160801b0316815260200161272488615f0e565b6001600160801b031681526020018961273e576001612741565b60005b60ff1690526138b3565b6004805460ff19166001179055965090945061276b9350610eb392505050565b600454610100900460ff16612793576040516304564c7160e21b815260040160405180910390fd5b6001600b55909590945092505050565b600b546001146127c95760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff16156127f55760405160016238ddf760e01b0319815260040160405180910390fd5b61282060007f0000000000000000000000000000000000000000000000000000000000000000610ba6565b6004805460ff191690556128348282614b9c565b506004805460ff1916600117905561137c610eb3565b600b546001146128705760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff161561289c5760405160016238ddf760e01b0319815260040160405180910390fd5b6128c760007f0000000000000000000000000000000000000000000000000000000000000000610ba6565b6004805460ff19169055306001600160a01b038216036128fa57604051632f35253160e01b815260040160405180910390fd5b6129043384612b89565b8211156129245760405163327cbc9b60e21b815260040160405180910390fd5b61292e838361692d565b6129388383616979565b7f00000000000000000000000000000000000000000000000000000000000000006001600160a01b0316836001600160a01b0316036129a15761299c7f000000000000000000000000000000000000000000000000000000000000000082846169cc565b6129ac565b6129ac838284616a30565b6004805460ff1916600117905561245f610eb3565b600080600b546001146129ea5760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff1615612a165760405160016238ddf760e01b0319815260040160405180910390fd5b612a4160007f0000000000000000000000000000000000000000000000000000000000000000610ba6565b6004805460ff19169055600019831461145c8186612a638261144f5787615f0e565b6132f7565b600b54600114612a8e5760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff1615612aba5760405160016238ddf760e01b0319815260040160405180910390fd5b612ae560007f0000000000000000000000000000000000000000000000000000000000000000610ba6565b6004805460ff1916905534600003612b1057604051637c946ed760e01b815260040160405180910390fd5b60405134815233907fe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c9060200160405180910390a26004805460ff19166001179055612b5a610eb3565b600454610100900460ff16612b82576040516304564c7160e21b815260040160405180910390fd5b6001600b55565b6001600160a01b0391821660009081526020818152604080832093909416825291909152205490565b6001600160401b03831660009081526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187015460608088019190915284880154608080890191909152600389015460a0808a019190915260048a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681850152600160481b8804861681840152600160581b880490951690850152600160681b909504841695830195909552610140860191909152865192830187526007860154808216845260ff600160a01b918290048116998501999099529590980154978816958201959095529290950490931693810193909352610160820192909252612d3c9185908590616aae16565b949350505050565b600b54600114612d6a5760405160016238ddf760e01b0319815260040160405180910390fd5b6002600b5560045460ff1615612d965760405160016238ddf760e01b0319815260040160405180910390fd5b612dc160007f0000000000000000000000000000000000000000000000000000000000000000610ba6565b6004805460ff191690556113678282610c0f615d22565b606060206000526b10626574612d76302e302e3160305260606000f35b6004820154610100900460ff1615612e155760048201805461ff00191690555b6001600160a01b038116600090815260028301602052604090205460ff16610c0b57600382018054600180820183556000928352602080842090920180546001600160a01b0386166001600160a01b031990911681179091558352600285019091526040909120805460ff191690911790555050565b600080806009841015612ebb576040516370cee4af60e11b8152600960048201526024810185905260440161216a565b6000612ed386866000818110610c2757610c27619496565b5060f881901c94509050612eeb600960018789619517565b612ef491619541565b60c01c9250612f0e612f09866009818a619517565b616aff565b9150509250925092565b6001600160401b03821660009081526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187015460608088019190915284880154608080890191909152600389015460a0808a019190915260048a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681850152600160481b8804861681840152600160581b880490951690850152600160681b90950490931694820194909452610140850152855191820186526007850154808416835260ff600160a01b91829004811698840198909852949097015491821694810194909452919091049092169281019290925261016081019190915281906130a7816020015163ffffffff16151590565b6130cf57604051636a2406a360e11b81526001600160401b038616600482015260240161216a565b8515613109576131066130eb3383610160015160000151612b89565b6130fe3384610160015160400151612b89565b839190616aae565b93505b836001600160801b031660000361313357604051630200e8a960e31b815260040160405180910390fd5b61314661313f85616b98565b8290616381565b60408051610100810182523381526001600160401b03891660208201526001600160801b039384169650919092169350600091810161318460125490565b6001600160801b03168152602001858152602001848152602001836101600151600001516001600160a01b03168152602001836101600151604001516001600160a01b031681526020016131d787616b98565b600f0b905290506131e781616bae565b505061016082015160408082015191518151878152602081018790526001600160801b038916928101929092526001600160a01b039283169216906001600160401b038916907ffdffeca751f0dcaab75531cb813c12bbfd56ee3e964cc471d7ef43932402ee18906060015b60405180910390a45050935093915050565b600080806009841015613295576040516370cee4af60e11b8152600960048201526024810185905260440161216a565b6004858560008181106132aa576132aa619496565b909101356001600160f81b03191690911c60f81c93506132d09050600960018688619517565b6132d991619541565b60c01c91506132ee612f098560098189619517565b90509250925092565b600080841561333057336000908152600a602090815260408083206001600160401b03881684529091529020546001600160801b031692505b826001600160801b031660000361335a57604051630200e8a960e31b815260040160405180910390fd5b600060086000866001600160401b03166001600160401b03168152602001908152602001600020604051806101800160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900463ffffffff1663ffffffff1663ffffffff1681526020016000820160079054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820154815260200160028201548152602001600382015481526020016004820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016004820160109054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160109054906101000a9004600f0b600f0b600f0b8152602001600682016040518060e00160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900461ffff1661ffff1661ffff1681526020016000820160059054906101000a900461ffff1661ffff1661ffff1681526020016000820160079054906101000a900461ffff1661ffff1661ffff1681526020016000820160099054906101000a900461ffff1661ffff1661ffff16815260200160008201600b9054906101000a900461ffff1661ffff1661ffff16815260200160008201600d9054906101000a900463ffffffff1663ffffffff1663ffffffff16815250508152602001600782016040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff168152505081525050905061367f816020015163ffffffff16151590565b6136a757604051636a2406a360e11b81526001600160401b038616600482015260240161216a565b6136bc6136b385616b98565b61313f9061956f565b60408051610100810182523381526001600160401b03891660208201526001600160801b03938416965091909216935060009181016136fa60125490565b6001600160801b03168152602001858152602001848152602001836101600151600001516001600160a01b03168152602001836101600151604001516001600160a01b0316815260200161374d87616b98565b6137569061956f565b600f0b9052905061376681616bae565b505061016082015160408082015191518151878152602081018790526001600160801b038916928101929092526001600160a01b039283169216906001600160401b038916907ffe322c782fa8cb650f7deaac661d6e7aacbaa8034eae3b8c3afd1490bed1be1e90606001613253565b60008060008060006004878760008181106137f3576137f3619496565b909101356001600160f81b03191690911c60f81c9550613819905060096001888a619517565b61382291619541565b60c01c935060008787600981811061383c5761383c619496565b919091013560f81c91506138589050612f0982600a8a8c619517565b935061387b8860ff83168961386e6001826194c2565b92612f0993929190619517565b9250878761388a6001826194c2565b81811061389957613899619496565b9050013560f81c60f81b60f81c9150509295509295909350565b60008060008084604001516001600160801b03166000036138e75760405163af458c0760e01b815260040160405180910390fd5b60006008600087602001516001600160401b03166001600160401b031681526020019081526020016000209050613c1081604051806101800160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900463ffffffff1663ffffffff1663ffffffff1681526020016000820160079054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820154815260200160028201548152602001600382015481526020016004820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016004820160109054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160109054906101000a9004600f0b600f0b600f0b8152602001600682016040518060e00160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900461ffff1661ffff1661ffff1681526020016000820160059054906101000a900461ffff1661ffff1661ffff1681526020016000820160079054906101000a900461ffff1661ffff1661ffff1681526020016000820160099054906101000a900461ffff1661ffff1661ffff16815260200160008201600b9054906101000a900461ffff1661ffff1661ffff16815260200160008201600d9054906101000a900463ffffffff1663ffffffff1663ffffffff16815250508152602001600782016040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff1681525050815250506020015163ffffffff16151590565b613c3e576020860151604051636a2406a360e11b81526001600160401b03909116600482015260240161216a565b6080860151600d805460ff9092161560ff199092169190911790558054600160381b90046001600160a01b03163314613c86576006810154600160281b900461ffff16613c97565b6006810154600160581b900461ffff165b600f55600d5460ff16613cae578060030154613cb4565b80600201545b601055600d5460ff16613cd45760088101546001600160a01b0316613ce3565b60078101546001600160a01b03165b600d80546001600160a01b039290921661010002610100600160a81b03198316811790915560ff908116911617613d275760078101546001600160a01b0316613d36565b60088101546001600160a01b03165b600e80546001600160a01b0319166001600160a01b03929092169190911790556040805161014081019091526006820154600281900b606083019081526301000000820461ffff9081166080850152600160281b8304811660a0850152600160381b8304811660c0850152600160481b8304811660e0850152600160581b830416610100840152600160681b90910463ffffffff16610120830152600091908190613de090616c35565b81526020018360060160000160099054906101000a900461ffff1661ffff16815260200160008152509050613e4e6040518060e00160405280600060020b81526020016000815260200160008152602001600081526020016000815260200160008152602001600081525090565b6000806000613e608b60200151616416565b60408801819052600d549295509093509150600090613ea890339060ff16613e955760088901546001600160a01b0316612b89565b60078901546001600160a01b0316612b89565b90508b6000015160ff16600114613ecc578b604001516001600160801b0316613ece565b805b600d54909a50613f0d9060ff16613ef3576008880154600160a01b900460ff16613f03565b6007880154600160a01b900460ff165b8b9060ff16616c44565b99506040518060e001604052808460020b81526020018581526020018b8152602001600081526020018860040160109054906101000a90046001600160801b03166001600160801b031681526020016000815260200160008152509450505050508160400151600003613f935760405163398b36db60e01b815260040160405180910390fd5b600d5460009081908190819081908190819060ff1615613feb576020880151613fbd908a90616c5b565b60808a0151909850909550613fe490613fde89670de0b6b3a76400006194c2565b90616c9b565b915061401a565b6020880151613ffb908a90616c5b565b60808a01518b5192995090965061401791613fde908a906194c2565b91505b8954600160381b90046001600160a01b03163314614039576000614068565b600f5460048b01546127109161405e91600160801b90046001600160801b0316619595565b61406891906195ca565b9250826000036140ab57612710600d60020154838a6040015111614090578960400151614092565b835b61409c9190619595565b6140a691906195ca565b6140ae565b60005b6060890181905260808901516140c49190616cb7565b60105582156140e15760808801516140dd908490616cb7565b6011555b818860400151111561414a5760608801516140fc90836194c2565b9050614115886080015182616cb790919063ffffffff16565b61411f90886195de565b955087606001518161413191906195de565b8860400181815161414291906194c2565b905250614192565b8760600151886040015161415e91906194c2565b9050614177886080015182616cb790919063ffffffff16565b61418190886195de565b604089018051600090915290965090505b600d5460ff16156141ae576141a78987616ccc565b93506141bb565b6141b88987616ce8565b93505b808860a0018181516141cd91906195de565b9052506141da84866194c2565b8860c0018181516141eb91906195de565b905250505060608d0151600d546000916001600160801b0316908290819060ff161561423c5761421c8b888b616d04565b91506142298b878a616d04565b90506142358b89616d36565b9350614263565b6142478b8a89616d04565b91506142548b8988616d04565b90506142608b87616d36565b93505b600d5460ff1615801561427557508284115b156142935760405163a3869ab760e01b815260040160405180910390fd5b600d5460ff1680156142a457508383115b156142c25760405163a3869ab760e01b815260040160405180910390fd5b60088c01546142dc908390600160a01b900460ff16616d50565b60088d01549092506142f9908290600160a01b900460ff16616d50565b90508181121561432657604051630424b42d60e31b8152600481018390526024810182905260440161216a565b629896806143378562989681619595565b61434191906195ca565b60208b01525050600d546000925082915060ff161561437d5750506007880154600889015460ff600160a01b928390048116929091041661439c565b50506008880154600789015460ff600160a01b92839004811692909104165b60a08801516143ab9083616d66565b60a089015260c08801516143bf9082616d7f565b8860c0018181525050505061441b8d602001516143df8860200151616d95565b602089015160808a0151600d5460ff166143fa5760006143fe565b6010545b600d5460ff1661441057601054614413565b60005b601154616dcd565b50600d5460a087015161443c9161010090046001600160a01b031690616f50565b600e5460c0870151614457916001600160a01b031690616979565b8015614514576144877f000000000000000000000000000000000000000000000000000000000000000082616f50565b6040518181526001600160a01b037f0000000000000000000000000000000000000000000000000000000000000000169030907f49e1443cb25e17cbebc50aa3e3a5a3df3ac334af852bc6f3e8d258558257bb119060200160405180910390a36145146000307f000000000000000000000000000000000000000000000000000000000000000084616f97565b600d60010160009054906101000a90046001600160a01b03166001600160a01b0316600d60000160019054906101000a90046001600160a01b03166001600160a01b03168e602001516001600160401b03167f6ad6899405e7539158789043be9745c5def4f806aeb268c3c788953ff4f3c01089602001518a60a001518b60c001516040516145b6939291909283526020830191909152604082015260600190565b60405180910390a45050600d80546001600160a81b03191690555050600e80546001600160a01b0319169055506000600f819055601081905560115560209790970151604088015160a089015160c0909901519199909897509095509350505050565b6000806009831015614648576040516370cee4af60e11b8152600960048201526024810184905260440161216a565b614656600960018587619517565b61465f91619541565b60c01c9150614674612f098460098188619517565b90509250929050565b600060086000846001600160401b03166001600160401b0316815260200190815260200160002090506149a281604051806101800160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900463ffffffff1663ffffffff1663ffffffff1681526020016000820160079054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820154815260200160028201548152602001600382015481526020016004820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016004820160109054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160109054906101000a9004600f0b600f0b600f0b8152602001600682016040518060e00160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900461ffff1661ffff1661ffff1681526020016000820160059054906101000a900461ffff1661ffff1661ffff1681526020016000820160079054906101000a900461ffff1661ffff1661ffff1681526020016000820160099054906101000a900461ffff1661ffff1661ffff16815260200160008201600b9054906101000a900461ffff1661ffff1661ffff16815260200160008201600d9054906101000a900463ffffffff1663ffffffff1663ffffffff16815250508152602001600782016040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff1681525050815250506020015163ffffffff16151590565b6149ca57604051636a2406a360e11b81526001600160401b038416600482015260240161216a565b336000908152600a602090815260408083206001600160401b0387168452825280832081516101608101835281546001600160801b038082168352600160801b918290048116958301959095526001830154938201939093526002820154606082015260038201546080820152600482015460a0820152600582015460c0820152600682015460e08201526007820154808516610100830152929092048316610120830152600801548216610140820152919084169003614a9e57604051630200e8a960e31b815260040160405180910390fd5b80516001600160801b0380851691161015614ad7576040516326e66cc760e11b81526001600160401b038516600482015260240161216a565b6000614aeb85614ae686616b98565b616fe1565b9050614af684616b98565b600584018054601090614b14908490600160801b9004600f0b6195f6565b92506101000a8154816001600160801b030219169083600f0b6001600160801b03160217905550336001600160a01b0316856001600160401b03167fc37a962db40f0f2a72f4a9ee4760e142ff06e5fb57cb4f23f494cbec9718e60586604051614b8d91906001600160801b0391909116815260200190565b60405180910390a35050505050565b6001600160401b03821660009081526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187015460608088019190915284880154608080890191909152600389015460a0808a019190915260048a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681850152600160481b8804861681840152600160581b880490951690850152600160681b90950490931694820194909452610140850152855191820186526007850154808416835260ff600160a01b91829004811698840198909852978501549283169582019590955295900490931691840191909152610160820192909252614d27906020015163ffffffff16151590565b614d4f57604051636a2406a360e11b81526001600160401b038516600482015260240161216a565b6000614d5a60125490565b336000908152600a602090815260408083206001600160401b038a168452825280832081516101608101835281546001600160801b038181168352600160801b9182900481169583019590955260018301549382019390935260028201546060820181905260038301546080830152600483015460a0830152600583015460c0830152600683015460e0830152600783015480861661010084015293909304841661012082015260089091015483166101408201529390911693509003614e3f57604051630c47736b60e11b81526001600160401b038716600482015260240161216a565b8181608001511115614e6f5760405163a4093bbf60e01b81526001600160401b038716600482015260240161216a565b614e8586614e7c87616b98565b614ae69061956f565b9350614e9085616b98565b600584018054601090614eae908490600160801b9004600f0b619645565b92506101000a8154816001600160801b030219169083600f0b6001600160801b03160217905550336001600160a01b0316866001600160401b03167f850fd333bb55261aab49c7ed91d737f7c21674d43968a564ede778e0735d856f87604051614f2791906001600160801b0391909116815260200190565b60405180910390a350505092915050565b6000808080808080808060358a14614f6d576040516370cee4af60e11b815260356004820152602481018b905260440161216a565b614f7b600460018c8e619517565b614f8491619695565b60e81c9850614f97601860048c8e619517565b614fa0916196c2565b60601c9750614fb3601a60188c8e619517565b614fbc916196f5565b60f01c9650614fcf601c601a8c8e619517565b614fd8916196f5565b60f01c9550614feb601e601c8c8e619517565b614ff4916196f5565b60f01c94506150076020601e8c8e619517565b615010916196f5565b60f01c9350615023602260208c8e619517565b61502c916196f5565b60f01c925061503f602560228c8e619517565b61504891619695565b60e81c915061505a8a6025818e619517565b61506391619723565b60801c90509295985092959850929598565b6000816001600160801b03166000036150a157604051634dfba02360e01b815260040160405180910390fd5b60006150bd6150af60125490565b6001600160801b0316617418565b90506151736040805161018081018252600080825260208083018290528284018290526060808401839052608080850184905260a080860185905260c080870186905260e0808801879052610100880187905261012088018790528851908101895286815294850186905296840185905291830184905282018390528101829052928301529061014082019081526040805160808101825260008082526020828101829052928201819052606082015291015290565b6001600160a01b038b16604082015263ffffffff821660208201526001600160801b03841660c082018190526151a890616d95565b60020b815260408101516001600160a01b03161580159081906151cd575061ffff8b16155b156151f15760405163f6f4a38f60e01b815261ffff8c16600482015260240161216a565b600062ffffff8e1615615204578d615208565b6005545b62ffffff81166000908152600760209081526040808320815160808101835281546001600160a01b03808216835260ff600160a01b9283900481168488015260019094015490811683860152049091166060820152610160880152805160e0810190915260028b900b815292935090919081018461528b5760135460ff1661528d565b8a5b61ffff1681526020018d61ffff1681526020018b61ffff1681526020018c61ffff168152602001846152c05760006152c2565b8e5b61ffff1681526020018663ffffffff1681525090506152e08161742b565b505061014084018190526006805460010190819055615300838583617456565b965061562260086000896001600160401b03166001600160401b03168152602001908152602001600020604051806101800160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900463ffffffff1663ffffffff1663ffffffff1681526020016000820160079054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820154815260200160028201548152602001600382015481526020016004820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016004820160109054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160109054906101000a9004600f0b600f0b600f0b8152602001600682016040518060e00160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900461ffff1661ffff1661ffff1681526020016000820160059054906101000a900461ffff1661ffff1661ffff1681526020016000820160079054906101000a900461ffff1661ffff1661ffff1681526020016000820160099054906101000a900461ffff1661ffff1661ffff16815260200160008201600b9054906101000a900461ffff1661ffff1661ffff16815260200160008201600d9054906101000a900463ffffffff1663ffffffff1663ffffffff16815250508152602001600782016040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff1681525050815250506020015163ffffffff16151590565b1561564057604051637a471e1360e11b815260040160405180910390fd5b8460086000896001600160401b03166001600160401b0316815260200190815260200160002060008201518160000160006101000a81548162ffffff021916908360020b62ffffff16021790555060208201518160000160036101000a81548163ffffffff021916908363ffffffff16021790555060408201518160000160076101000a8154816001600160a01b0302191690836001600160a01b03160217905550606082015181600101556080820151816002015560a0820151816003015560c08201518160040160006101000a8154816001600160801b0302191690836001600160801b0316021790555060e08201518160040160106101000a8154816001600160801b0302191690836001600160801b031602179055506101008201518160050160006101000a8154816001600160801b0302191690836001600160801b031602179055506101208201518160050160106101000a8154816001600160801b030219169083600f0b6001600160801b031602179055506101408201518160060160008201518160000160006101000a81548162ffffff021916908360020b62ffffff16021790555060208201518160000160036101000a81548161ffff021916908361ffff16021790555060408201518160000160056101000a81548161ffff021916908361ffff16021790555060608201518160000160076101000a81548161ffff021916908361ffff16021790555060808201518160000160096101000a81548161ffff021916908361ffff16021790555060a082015181600001600b6101000a81548161ffff021916908361ffff16021790555060c082015181600001600d6101000a81548163ffffffff021916908363ffffffff16021790555050506101608201518160070160008201518160000160006101000a8154816001600160a01b0302191690836001600160a01b0316021790555060208201518160000160146101000a81548160ff021916908360ff16021790555060408201518160010160006101000a8154816001600160a01b0302191690836001600160a01b0316021790555060608201518160010160146101000a81548160ff021916908360ff1602179055505050905050846101600151604001516001600160a01b0316856101600151600001516001600160a01b0316886001600160401b03167f7609f45e16378bb0782884719ba24d3bbc5ab6a373b9eacacc25c6143b87cf77878c6040516159e392919091151582526001600160801b0316602082015260400190565b60405180910390a45050505050509998505050505050505050565b60008060298314615a2c576040516370cee4af60e11b8152602960048201526024810184905260440161216a565b615a3a601560018587619517565b615a43916196c2565b60601c9150615a558360158187619517565b615a5e916196c2565b60601c90509250929050565b6000816001600160a01b0316836001600160a01b031603615a9e57604051633b0e2de560e21b815260040160405180910390fd5b506001600160a01b0380831660009081526009602090815260408083209385168352929052205462ffffff168015615af057604051633325fa7760e01b815262ffffff8216600482015260240161216a565b600080846001600160a01b031663313ce5676040518163ffffffff1660e01b8152600401602060405180830381865afa158015615b31573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190615b559190619751565b846001600160a01b031663313ce5676040518163ffffffff1660e01b8152600401602060405180830381865afa158015615b93573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190615bb79190619751565b9092509050615bcc60ff8316600660126174cc565b615bee5760405163ca95039160e01b815260ff8316600482015260240161216a565b615bfe60ff8216600660126174cc565b615c205760405163ca95039160e01b815260ff8216600482015260240161216a565b600580546001908101918290556001600160a01b0387811660008181526009602090815260408083208b8616808552908352818420805462ffffff191662ffffff8a16908117909155825160808101845286815260ff8c81168287018181528387018681528e841660608601818152878c5260078b529a899020955186549351908e166001600160a81b031994851617600160a01b9187168202178755915195909d0180549a5195909c169990911698909817929091169096021790965581519384529183019590955294975090927fc0c5df98a4ca87a321a33bf1277cf32d31a97b6ce14b9747382149b9e2631ea3910160405180910390a4505092915050565b600083836001818110615d3757615d37619496565b919091013560f81c9150600290506000805b8360ff168114610c055760ff83169150868683818110615d6b57615d6b619496565b919091013560f81c93505085831115615d9c576040516380f63bd160e01b815260ff8416600482015260240161216a565b366000615dae60ff8616858a8c619517565b9092509050615dcc615dc38260018186619517565b8963ffffffff16565b505080615dd890619774565b9050615d49565b600381015415615df157615df161978d565b60048101805461ff001916610100179055615e10600382016000618ee8565b600401805460ff19169055565b6000808080615e2d878787615f24565b90506000811315615e7c57925082615e4787338884616f97565b6001600160a01b038616600090815260018801602052604081208054839290615e719084906195de565b90915550615ed79050565b6000811215615ed757615e8e816197a3565b9150615e9c873388856167fb565b90935091508215615ed7576001600160a01b038616600090815260018801602052604081208054859290615ed19084906194c2565b90915550505b506001600160a01b03909416600090815260029095016020526040909420805460ff19169055939050565b610e61833384846174d9565b6000600160801b8210615f2057600080fd5b5090565b6001600160a01b038216600090815260018401602052604081205481615f4a8585617560565b9050615f5682826197bf565b9695505050505050565b6000806116468360e00151615f749061956f565b8490616381565b6000615f868261742b565b508251600685018054602086015160408701516060880151608089015160a08a015160c08b015162ffffff90981664ffffffffff1990961695909517630100000061ffff958616021768ffffffff00000000001916600160281b9385169390930268ffff00000000000000191692909217600160381b91841691909102176cffffffff0000000000000000001916600160481b9183169190910261ffff60581b191617600160581b91909216021763ffffffff60681b1916600160681b63ffffffff90931692909202919091179055905080610e6157610e6161978d565b61606e8484612df5565b616079838383615f02565b50505050565b6000806160c56040518060e00160405280600060020b81526020016000815260200160008152602001600081526020016000815260200160008152602001600081525090565b60006160d089617649565b90506160e66160de8a6176af565b8a90876176ce565b60020b8352602083015261611287616102578860600151616108565b88602001515b879060ff16616c44565b604083015260e08901516001600160801b03166080830152600080808080808c1561617b576020880151616147908890616c5b565b80975081965050506161748f60e001516001600160801b031687670de0b6b3a7640000613fde91906194c2565b91506161b7565b602088015161618b908890616c5b565b80965081975050506161b48f60e001516001600160801b0316878960000151613fde91906194c2565b91505b6127108f61014001516040015161ffff16838a60400151116161dd5789604001516161df565b835b6161e99190619595565b6161f391906195ca565b6060890152604088015182101561626157606088015161621390836194c2565b905061622c886080015182616cb790919063ffffffff16565b61623690876195de565b935087606001518161624891906195de565b8860400181815161625991906194c2565b9052506162a9565b8760600151886040015161627591906194c2565b905061628e886080015182616cb790919063ffffffff16565b61629890876195de565b604089018051600090915290945090505b8c156162c0576162b98785616ccc565b92506162cd565b6162ca8785616ce8565b92505b808860a0018181516162df91906195de565b9052506162ec83866194c2565b8860c0018181516162fd91906195de565b905250600091508190508c15616326578d6020015160ff1691508d6060015160ff16905061633b565b8d6060015160ff1691508d6020015160ff1690505b60a088015161634a9083616d66565b60a089015260c088015161635e9082616d7f565b60c08901819052604090980151979f979e50969c50505050505050505050505050565b600080600f83900b15611f0d5760008061639a866168d1565b9150915060008086600f0b13156163d957506001600160801b0385166163c36114528483617724565b94506163d26114528383617724565b935061640c565b6163e28661956f565b6001600160801b031690506163fa6114528483616c9b565b94506164096114528383616c9b565b93505b5050509250929050565b6001600160401b03811660009081526008602081815260408084208151610180810183528154600281810b835263ffffffff63010000008084048216858901526001600160a01b03600160381b94859004811686890152600187015460608088019190915284880154608080890191909152600389015460a0808a019190915260048a01546001600160801b0380821660c0808d0191909152600160801b92839004821660e0808e019190915260058e01549283166101008e015292909104600f0b6101208c01528c519182018d5260068c01549889900b825261ffff9689048716828f0152600160281b89048716828e0152988804861681850152600160481b8804861681840152600160581b880490951690850152600160681b90950490931694820194909452610140850152855191820186526007850154808416835260ff600160a01b918290048116988401989098529490970154918216948101949094529190910490921692810192909252610160810191909152819081906165a7816020015163ffffffff16151590565b6165cf57604051636a2406a360e11b81526001600160401b038616600482015260240161216a565b60c081015181516165f26165e260125490565b84906001600160801b0316617739565b6001600160801b03909216955093509150600061660e8661128d565b90508015616635576000616621836176af565b905061662e8382846176ce565b9096509450505b50509193909250565b6000806000616651858860050154900390565b90506000616663858960060154900390565b905061666f8288616c9b565b935061667b8188616c9b565b6005890187905560068901869055925061669484615f0e565b6007890180546000906166b19084906001600160801b03166197fe565b92506101000a8154816001600160801b0302191690836001600160801b031602179055506166de83615f0e565b600789018054601090616702908490600160801b90046001600160801b03166197fe565b92506101000a8154816001600160801b0302191690836001600160801b03160217905550505094509492505050565b61673e6000338484616f97565b6040518181526001600160a01b0383169033907f49e1443cb25e17cbebc50aa3e3a5a3df3ac334af852bc6f3e8d258558257bb11906020015b60405180910390a35050565b600080616794838660040154900390565b90506167a08185616c9b565b6004860181905591506167b282615f0e565b6008860180546000906167cf9084906001600160801b03166197fe565b92506101000a8154816001600160801b0302191690836001600160801b03160217905550509392505050565b6000806168088685612df5565b6001600160a01b038086166000908152602088815260408083209388168352929052205483811061687a576001600160a01b038087166000908152602089815260408083209389168352929052908120805486955085929061686b9084906194c2565b90915550600092506168c79050565b6001600160a01b038087166000908152602089815260408083209389168352929052908120805492945084928392906168b49084906194c2565b909155506168c4905083856194c2565b91505b5094509492505050565b6000806000806168e08561776e565b915091506169038561016001516020015160ff1683616d7f90919063ffffffff16565b93506169248561016001516060015160ff1682616d7f90919063ffffffff16565b92505050915091565b61693a60003384846167fb565b50506040518181526001600160a01b0383169033907f0b0b821953e5545b71f2085833e4a8dfd0d99bbdff511898672ae8179a982df390602001616777565b616985600083836177b2565b816001600160a01b03167f1c711eca8d0b694bbcb0a14462a7006222e721954b2c5ff798f606817eb11032826040516169c091815260200190565b60405180910390a25050565b604051632e1a7d4d60e01b8152600481018290526001600160a01b03841690632e1a7d4d90602401600060405180830381600087803b158015616a0e57600080fd5b505af1158015616a22573d6000803e3d6000fd5b50505050610e61828261782c565b600060405163a9059cbb60e01b6000528360045282602452602060006044600080895af13d15601f3d11600160005114161716915060006060528060405250806160795760405162461bcd60e51b815260206004820152600f60248201526e1514905394d1915497d19052531151608a1b604482015260640161216a565b6000806000616abc866168d1565b90925090506000616acd8684616cb7565b90506000616adb8684616cb7565b9050616af3818310616aed5781615f0e565b82615f0e565b98975050505050505050565b60008083836000818110616b1557616b15619496565b919091013560f81c9150616b6b9050616b318460018188619517565b8080601f0160208091040260200160405190810160405280939291908181526020018383808284376000920191909152506178ba92505050565b60801c915060ff811615616b9157616b8481600a61990d565b616b8e908361991c565b91505b5092915050565b600060016001607f1b03821115615f2057600080fd5b602081810180516001600160401b03908116600090815260088452604080822086516001600160a01b03168352600a8652818320945190931682529290935290822060048201546002830154600384015485949392616c20928492600160801b9092046001600160801b03169161663e565b9094509250616c2e856178cb565b5050915091565b60006114bb8260000151617a21565b600080616c5083617a4e565b939093029392505050565b600080616c7683856000015186602001518760400151617a66565b9050616c92818560000151866020015187604001516000617b78565b91509250929050565b6000616cb08383670de0b6b3a7640000617b95565b9392505050565b6000616cb083670de0b6b3a764000084617b95565b6000616cb0828460000151856020015186604001516000617b78565b6000616cb0828460000151856020015186604001516000617bb4565b6000612d3c83838660000151616d2c8860200151612710670de0b6b3a7640000919091020490565b8860400151617bd1565b6000616cb082846000015185602001518660400151617bee565b600080616d5c83617a4e565b9093059392505050565b600080616d7283617a4e565b9093046001019392505050565b600080616d8b83617a4e565b9093049392505050565b600080616da183617d17565b90506000616db6670de111a6b7de4000617d17565b9050616dc2818361994b565b612d3c906001619979565b6001600160401b038716600090815260086020526040812081616def60125490565b6001600160801b03169050616e038a61128d565b92506001808410616e40576005830154616e31906001600160801b03811690600160801b9004600f0b617ef2565b6001600160801b031660058401555b825460028b810b91900b14616e6157825462ffffff191662ffffff8b161783555b60048301546001600160801b03168914616ea157616e7e89615f0e565b6004840180546001600160801b0319166001600160801b03929092169190911790555b6004830154600160801b90046001600160801b03168814616ee557616ec588615f0e565b6004840180546001600160801b03928316600160801b0292169190911790555b82546301000000900463ffffffff168214616f0457616f048383617f76565b616f12836002015488617fa3565b60028401556003830154616f269087617fa3565b60038401556001830154616f3a9086617fa3565b8360010181905550505050979650505050505050565b616f5c60008383617faf565b816001600160a01b03167f80b21748c787c52e87a6b222011e0a0ed0f9cc2015f0ced46748642dc62ee9f8826040516169c091815260200190565b616fa18483612df5565b6001600160a01b0380841660009081526020868152604080832093861683529290529081208054839290616fd69084906195de565b909155505050505050565b600080616fed60125490565b6001600160801b03169050600060086000866001600160401b03166001600160401b03168152602001908152602001600020604051806101800160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900463ffffffff1663ffffffff1663ffffffff1681526020016000820160079054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820154815260200160028201548152602001600382015481526020016004820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016004820160109054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160009054906101000a90046001600160801b03166001600160801b03166001600160801b031681526020016005820160109054906101000a9004600f0b600f0b600f0b8152602001600682016040518060e00160405290816000820160009054906101000a900460020b60020b60020b81526020016000820160039054906101000a900461ffff1661ffff1661ffff1681526020016000820160059054906101000a900461ffff1661ffff1661ffff1681526020016000820160079054906101000a900461ffff1661ffff1661ffff1681526020016000820160099054906101000a900461ffff1661ffff1661ffff16815260200160008201600b9054906101000a900461ffff1661ffff1661ffff16815260200160008201600d9054906101000a900463ffffffff1663ffffffff1663ffffffff16815250508152602001600782016040518060800160405290816000820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016000820160149054906101000a900460ff1660ff1660ff1681526020016001820160009054906101000a90046001600160a01b03166001600160a01b03166001600160a01b031681526020016001820160149054906101000a900460ff1660ff1660ff16815250508152505090506000600a6000336001600160a01b03166001600160a01b031681526020019081526020016000206000876001600160401b03166001600160401b03168152602001908152602001600020905080600201546000036173775761736b83617418565b63ffffffff1660028201555b806003015460000361739d57617391826101400151617fed565b63ffffffff1660038201555b6173c48261010001516001600160801b03168360600151836167839092919063ffffffff16565b93506173db836173d38761956f565b839190618020565b80546173f790600160801b90046001600160801b031686617ef2565b81546001600160801b03918216600160801b02911617905550909392505050565b60006401000000008210615f2057600080fd5b6000606060008061743b8561805c565b915091508161744c57805181602001fd5b9094909350915050565b60008383617465576000617468565b60015b60405160e89290921b6001600160e81b031916602083015260f81b6001600160f81b031916602382015260e083901b6001600160e01b03191660248201526028016040516020818303038152906040526174c1906199ba565b60c01c949350505050565b6000612d3c848484618229565b60006040516323b872dd60e01b6000528460045283602452826044526020600060646000808a5af13d15601f3d1160016000511416171691506000606052806040525080610d7a5760405162461bcd60e51b81526020600482015260146024820152731514905394d1915497d19493d357d1905253115160621b604482015260640161216a565b604080516001600160a01b0383811660248084019190915283518084039091018152604490920183526020820180516001600160e01b03166370a0823160e01b179052915160009283928392918716916175ba91906199f1565b600060405180830381855afa9150503d80600081146175f5576040519150601f19603f3d011682016040523d82523d6000602084013e6175fa565b606091505b509150915081158061760e57508051602014155b1561762c5760405163c52e3eff60e01b815260040160405180910390fd5b808060200190518101906176409190619a0d565b95945050505050565b61766d60405180606001604052806000815260200160008152602001600081525090565b6040518060600160405280617686846101400151616c35565b81526020018361014001516080015161ffff1681526020016176a7846176af565b905292915050565b60006114bb826020015163ffffffff168361773990919063ffffffff16565b60008060006176e586610140015160000151617a21565b905061770e818761014001516080015161ffff168860c001516001600160801b0316888861823a565b925061771983616d95565b915050935093915050565b6000616cb08383670de0b6b3a76400006183a7565b60008061774a846101400151617fed565b63ffffffff169050808311156177645760009150506114bb565b616b8e83826194c2565b600080600061777c84617649565b905061779e8460c001516001600160801b0316826183d590919063ffffffff16565b92506177aa8184616ccc565b915050915091565b6001600160a01b0382166000908152600184016020526040902054808211156177f85760405163315276c960e01b8152600481018290526024810183905260440161216a565b6178028484612df5565b6001600160a01b038316600090815260018501602052604081208054849290616fd69084906194c2565b604080516000808252602082019092526001600160a01b03841690839060405161785691906199f1565b60006040518083038185875af1925050503d8060008114617893576040519150601f19603f3d011682016040523d82523d6000602084013e617898565b606091505b5050905080610e61576040516375f4268360e01b815260040160405180910390fd5b602081015190516010036008021c90565b80516001600160a01b03166000908152600a60209081526040808320828501516001600160401b03168452909152812060e08301519091600f9190910b1215617a035760006179af61791c60125490565b604080516101608101825285546001600160801b038181168352600160801b91829004811660208401526001880154938301939093526002870154606083015260038701546080830152600487015460a0830152600587015460c0830152600687015460e083015260078701548084166101008401520482166101208201526008860154821661014082015291166183ef565b6020848101516001600160401b03166000908152600890915260409020600601549091506301000000900461ffff16811015617a0157604051632688c6cb60e21b81526004810182905260240161216a565b505b604082015160e0830151617a18918391618020565b610c0b82618401565b600080617a3a670de0b6b3a7640000600285900b619a26565b9050616cb0670de111a6b7de40008261847e565b6000617a5b8260126194c2565b6114bb90600a619aab565b60008415612d3c576000617a82617a7d8787616cb7565b617d17565b90506301e18559670de0b6b3a76400008481029190910490612710908602046000671bc16d674ec80000617ab68380619595565b617ac091906195ca565b90506000617ace8483619595565b90506000617aee84633b9aca00617ae4886184aa565b613fde9190619595565b905060008183617b06670de0b6b3a76400008a619a26565b617b109190619979565b617b1a919061994b565b90506000617b2782618546565b9050670de0b6b3a7640000811315617b555760405163b11558df60e01b81526004810182905260240161216a565b617b6781670de0b6b3a76400006197bf565b9d9c50505050505050505050505050565b6000615f568686612710670de0b6b3a76400008802048686618589565b828202811515841585830485141716617bad57600080fd5b0492915050565b6000615f568686612710670de0b6b3a7640000880204868661866c565b600080617be18686868686618589565b9096039695505050505050565b6000806301e18559670de0b6b3a764000084020490506000612710670de0b6b3a7640000860204905086670de0b6b3a76400001015617c435760405163b11558df60e01b81526004810188905260240161216a565b6000617c5788670de0b6b3a76400006197bf565b90506000617c6482618780565b90506000617c7a84633b9aca00617ae4886184aa565b90506000670de0b6b3a7640000617c918385619a26565b617c9b919061994b565b90506000671bc16d674ec80000617cb28780619595565b617cbc91906195ca565b90506000670de0b6b3a7640000617cd38984619595565b617cdd919061994b565b90506000617ceb82856197bf565b90506000617cf882618814565b9050617d04818f616c9b565b9f9e505050505050505050505050505050565b6000808213617d545760405162461bcd60e51b815260206004820152600960248201526815539111519253915160ba1b604482015260640161216a565b60006060617d61846189bd565b03609f8181039490941b90931c6c465772b2bbbb5f824b15207a3081018102606090811d6d0388eaa27412d5aca026815d636e018202811d6d0df99ac502031bf953eff472fdcc018202811d6d13cdffb29d51d99322bdff5f2211018202811d6d0a0f742023def783a307a986912e018202811d6d01920d8043ca89b5239253284e42018202811d6c0b7a86d7375468fac667a0a527016c29508e458543d8aa4df2abee7883018302821d6d0139601a2efabe717e604cbb4894018302821d6d02247f7a7b6594320649aa03aba1018302821d6c8c3f38e95a6b1ff2ab1c3b343619018302821d6d02384773bdf1ac5676facced60901901830290911d6cb9a025d814b29c212b8b1a07cd1901909102780a09507084cc699bb0e71ea869ffffffffffffffffffffffff190105711340daa0d5f769dba1915cef59f0815a5506027d0267a36c0c95b3975ab3ee5b203a7614a3f75373f047d803ae7b6687f2b393909302929092017d57115e47018c7177eebf7cd370a3356a1b7863008a5ae8028c72b88642840160ae1d92915050565b6040805160048152602481019091526020810180516001600160e01b0316631fff968160e01b17905260009081831260018114617f34578015617f5457617f6e565b6000198419860301925084831280617f4e57825183602001fd5b50617f6e565b838501925084831260018103617f6c57825183602001fd5b505b505092915050565b617f7f81617418565b825463ffffffff9190911663010000000266ffffffff000000199091161790915550565b8181156114bb57500190565b617fb98383612df5565b6001600160a01b038216600090815260018401602052604081208054839290617fe39084906195de565b9091555050505050565b60006114bb8260c0015163ffffffff16618011846060015161ffff16620151800290565b61801b91906195de565b617418565b60018301829055825461803c906001600160801b031682617ef2565b83546001600160801b0319166001600160801b0391909116179092555050565b60006060618076836080015161ffff1660646161a86174cc565b6180d957608083015160405161ffff90911660248201526000906327b67e7360e21b906044015b60408051601f198184030181529190526020810180516001600160e01b03166001600160e01b0319909316929092179091529094909350915050565b6180ef836060015161ffff1660016101f46174cc565b61811a57606083015160405161ffff909116602482015260009063ae91902760e01b9060440161809d565b8251620d89e860029190910b1261814f57825160405160029190910b60248201526000906345c3193d60e11b9060440161809d565b610258836020015161ffff16111561818857602083015160405161ffff9091166024820152600090637a7f104160e11b9060440161809d565b61819e836040015161ffff1660016103e86174cc565b6181c957604080840151905161ffff909116602482015260009063f6f4a38f60e01b9060440161809d565b6181e58360a0015161ffff166000856040015161ffff166174cc565b6182105760a083015160405161ffff909116602482015260009063f6f4a38f60e01b9060440161809d565b5050604080516020810190915260008152600192909150565b600080828503848603021315612d3c565b60008160000361824b575082617640565b8282111561825a575084617640565b60408051606081018252878152602081018790529081018490526301e18559670de0b6b3a7640000808602829005919085020560006182998284618a5b565b6182ab90670de0b6b3a76400006194c2565b905060006182b8826184aa565b85519091506000906182cb908b90618a5b565b905060006182e76182e0633b9aca0085619595565b839061847e565b90506000806182f687896194c2565b90506000618303826184aa565b61830c8a6184aa565b6183169190619595565b9050600061832483836194c2565b905060006183448c60200151612710670de0b6b3a7640000919091020490565b90506000671bc16d674ec8000061835b8380619595565b61836591906195ca565b9050600061837b6183768386616c9b565b618814565b8e5190915061838a9082616c9b565b96505050505050506000617d048284616c9b90919063ffffffff16565b8282028115158415858304851417166183bf57600080fd5b6001826001830304018115150290509392505050565b6000616cb082846000015185602001518660400151617a66565b6000826040015182616cb091906194c2565b60a081015160c082015160e08301516020808501516001600160401b0316600090815260089091526040902061843691618a70565b60008360e00151600f0b121561846257618454828460600151616979565b610e61818460800151616979565b618470828460600151616f50565b610e61818460800151616f50565b6000616cb0670de0b6b3a76400008361849686617d17565b6184a09190619a26565b618376919061994b565b60b581600160881b81106184c35760409190911b9060801c5b600160481b81106184d95760209190911b9060401c5b600160281b81106184ef5760109190911b9060201c5b630100000081106185055760089190911b9060101c5b62010000010260121c80820401600190811c80830401811c80830401811c80830401811c80830401811c80830401811c80830401901c908190048111900390565b60006713a04bbdfdc9be88670de0b6b3a7640000830205196001018161856b82618ab3565b671bc16d674ec80000670de0b6b3a764000090910205949350505050565b6000670de0b6b3a76400008611156185b45760405163aaf3956f60e01b815260040160405180910390fd5b670de0b6b3a764000086036185d4576185cd8286619979565b9050617640565b856000036185e3575080617640565b8215618651576301e18558670de0b6b3a76400008402056000618605826184aa565b670de0b6b3a7640000908702633b9aca0002819005915088900361862881618780565b905081810361863681618546565b670de0b6b3a7640000908a0205860194506176409350505050565b50670de0b6b3a7640000858103850205810195945050505050565b6000821561875c576301e18558670de0b6b3a76400008402046000618690826184aa565b670de0b6b3a7640000908702633b9aca000281900491508885010287900560008112156186d05760405163aaf3956f60e01b815260040160405180910390fd5b670de0b6b3a76400008113156186f95760405163aaf3956f60e01b815260040160405180910390fd5b670de0b6b3a764000081036187145760009350505050617640565b8060000361872f57670de0b6b3a76400009350505050617640565b61873881618780565b905081810161874681618546565b670de0b6b3a76400000394506176409350505050565b84670de0b6b3a76400008388010205670de0b6b3a764000003905095945050505050565b60006706f05b59d3b20000820361879957506000919050565b670de0b6b3a764000082126187c1576040516307a0212760e01b815260040160405180910390fd5b816000036187e2576040516322ed598560e21b815260040160405180910390fd5b60028202915060006187f383618c28565b670de0b6b3a76400006713a04bbdfdc9be8890910205196001019392505050565b6000680248ce36a70cb26b3e19821361882f57506000919050565b680755bf798b4a1bf1e582126188765760405162461bcd60e51b815260206004820152600c60248201526b4558505f4f564552464c4f5760a01b604482015260640161216a565b6503782dace9d9604e83901b059150600060606bb17217f7d1cf79abc9e3b39884821b056001605f1b01901d6bb17217f7d1cf79abc9e3b39881029093036c240c330e9fb2d9cbaf0fd5aafb1981018102606090811d6d0277594991cfc85f6e2461837cd9018202811d6d1a521255e34f6a5061b25ef1c9c319018202811d6db1bbb201f443cf962f1a1d3db4a5018202811d6e02c72388d9f74f51a9331fed693f1419018202811d6e05180bb14799ab47a8a8cb2a527d57016d02d16720577bd19bf614176fe9ea6c10fe68e7fd37d0007b713f765084018402831d9081019084016d01d3967ed30fc4f89c02bab5708119010290911d6e0587f503bb6ea29d25fcb740196450019091026d360d7aeea093263ecc6e0ecb291760621b010574029d9dc38563c32e5c2f6dc192ee70ef65f9978af30260c3939093039290921c92915050565b60008082116189fa5760405162461bcd60e51b815260206004820152600960248201526815539111519253915160ba1b604482015260640161216a565b5060016001600160801b03821160071b82811c6001600160401b031060061b1782811c63ffffffff1060051b1782811c61ffff1060041b1782811c60ff10600390811b90911783811c600f1060021b1783811c909110821b1791821c111790565b6000616cb083670de0b6b3a7640000846183a7565b6004820154618a8f90600160801b90046001600160801b031682617ef2565b600490920180546001600160801b03938416600160801b0293169290921790915550565b600080618abf83618e46565b9050671bc16d674ec80000670de0b6b3a764000080830291909105016ec097ce7bc90715b34b9f100000000005600080618b5d618b42618b28670de0b6b3a764000067025f0fe105a31400870205670b68df18e471fbff190186670de0b6b3a764000091020590565b6714a8454c19e1ac000185670de0b6b3a764000091020590565b670fc10e01578277ff190184670de0b6b3a764000091020590565b6703debd083b8c7c00019150670de0b6b3a7640000670de0cc3d15610000670157d8b2ecc70800858502839005670295d400ea3257ff190186028390050185028290056705310aa7d52130000185028290050184020591508167119000ab100ffc00670de0b6b3a76400008680020560001902030190506000618bdf82618814565b9050670de0b6b3a76400008482020560008812801590618c065760018114618c1857618c1c565b81671bc16d674ec80000039750618c1c565b8197505b50505050505050919050565b6000671bc16d674ec800008212618c46575068056bc75e2d630fffff195b60008213618c5a575068056bc75e2d631000005b8015618c6557919050565b6000670de0b6b3a76400008312801590618c865760018114618c8e57618c9c565b839150618c9c565b83671bc16d674ec800000391505b506000618cb182671bc16d674ec80000618e82565b905080600003618cd4576040516307a0212760e01b815260040160405180910390fd5b6000618cdf82617d17565b90506000618cfe618cf9671bc16d674ec7ffff1984618e97565b6184aa565b633b9aca000290506000618d9282618d3d670de0b6b3a7640000669f32752462a000830205670dc5527f642c20000185670de0b6b3a764000091020590565b670de0b6b3a764000001670de0b6b3a7640000618d6c6703c1665c7aab200087670de0b6b3a764000091020590565b672005fe4f268ea000010205036709d028cc6f205fff19670de0b6b3a764000091020590565b905060005b6002811015618e0f576000618dab83618ab3565b8790039050670de0b6b3a764000083800205196001016000618dcc82618814565b9050670de0b6b3a764000085840205670de0b6b3a7640000670fa8cedfc2adddfa83020503670de0b6b3a764000084020585019450600184019350505050618d97565b670de0b6b3a76400008812801590618e2e5760018114618e3657618c1c565b829750618c1c565b5050196001019695505050505050565b6000600160ff1b8203618e6c57604051634d2d75b160e01b815260040160405180910390fd5b6000821215615f2057501960010190565b919050565b6000616cb083670de0b6b3a764000084618ea8565b6000616cb08383670de0b6b3a76400005b828202811515841585830585141716618ec057600080fd5b0592915050565b5080546000825560020290600052602060002090810190610ea49190618f06565b5080546000825590600052602060002090810190610ea49190618f2c565b5b80821115615f205780546001600160a01b031916815560006001820155600201618f07565b5b80821115615f205760008155600101618f2d565b80356001600160401b0381168114618e7d57600080fd5b600060208284031215618f6a57600080fd5b616cb082618f41565b80356001600160801b0381168114618e7d57600080fd5b60008060408385031215618f9d57600080fd5b618fa683618f41565b915061467460208401618f73565b60008060408385031215618fc757600080fd5b618fd083618f41565b946020939093013593505050565b80356001600160a01b0381168114618e7d57600080fd5b6000806040838503121561900857600080fd5b61901183618fde565b915061467460208401618fde565b60006020828403121561903157600080fd5b5035919050565b60006020828403121561904a57600080fd5b616cb082618fde565b60006020828403121561906557600080fd5b813562ffffff81168114616cb057600080fd5b803561ffff81168114618e7d57600080fd5b600080600080600080600060e0888a0312156190a557600080fd5b6190ae88618f41565b96506190bc60208901619078565b95506190ca60408901619078565b94506190d860608901619078565b93506190e660808901619078565b92506190f460a08901619078565b915060c08801358060020b811461910a57600080fd5b8091505092959891949750929550565b6000806040838503121561912d57600080fd5b618fd083618fde565b80358015158114618e7d57600080fd5b60008060006060848603121561915b57600080fd5b61916484618f41565b925061917260208501619136565b9150604084013590509250925092565b6000806040838503121561919557600080fd5b61919e83618f41565b9150602083013580600f0b81146191b457600080fd5b809150509250929050565b60028d900b815263ffffffff8c1660208201526001600160a01b038b166040820152606081018a90526080810189905260a081018890526001600160801b0387811660c083015286811660e083015285166101008201526102a0810161922b610120830186600f0b9052565b835160020b610140830152602084015161ffff90811661016084015260408501518116610180840152606085015181166101a0840152608085015181166101c084015260a0850151166101e083015260c084015163ffffffff1661020083015282516001600160a01b03908116610220840152602084015160ff90811661024085015260408501519091166102608401526060840151166102808301529d9c50505050505050505050505050565b6000806000606084860312156192ee57600080fd5b6192f784618f41565b95602085013595506040909401359392505050565b6000806000806080858703121561932257600080fd5b61932b85618f41565b935061933960208601619136565b93969395505050506040820135916060013590565b60008060006060848603121561936357600080fd5b61936c84618fde565b9250602084013591506132ee60408501618fde565b6000806040838503121561939457600080fd5b61939d83618fde565b915061467460208401618f41565b600080602083850312156193be57600080fd5b82356001600160401b03808211156193d557600080fd5b818501915085601f8301126193e957600080fd5b8135818111156193f857600080fd5b86602082850101111561940a57600080fd5b60209290920196919550909350505050565b60006020828403121561942e57600080fd5b616cb082618f73565b60005b8381101561945257818101518382015260200161943a565b838111156160795750506000910152565b6020815260008251806020840152619482816040850160208701619437565b601f01601f19169190910160400192915050565b634e487b7160e01b600052603260045260246000fd5b634e487b7160e01b600052601160045260246000fd5b6000828210156194d4576194d46194ac565b500390565b634e487b7160e01b600052603160045260246000fd5b60006001600160801b038381169083168181101561950f5761950f6194ac565b039392505050565b6000808585111561952757600080fd5b8386111561953457600080fd5b5050820193919092039150565b6001600160c01b03198135818116916008851015617f6e5760089490940360031b84901b1690921692915050565b600081600f0b60016001607f1b0319810361958c5761958c6194ac565b60000392915050565b60008160001904831182151516156195af576195af6194ac565b500290565b634e487b7160e01b600052601260045260246000fd5b6000826195d9576195d96195b4565b500490565b600082198211156195f1576195f16194ac565b500190565b600081600f0b83600f0b600082128260016001607f1b0303821381151615619620576196206194ac565b8260016001607f1b031903821281161561963c5761963c6194ac565b50019392505050565b600081600f0b83600f0b600081128160016001607f1b031901831281151615619670576196706194ac565b8160016001607f1b0301831381161561968b5761968b6194ac565b5090039392505050565b6001600160e81b03198135818116916003851015617f6e57600394850390941b84901b1690921692915050565b6bffffffffffffffffffffffff198135818116916014851015617f6e5760149490940360031b84901b1690921692915050565b6001600160f01b03198135818116916002851015617f6e5760029490940360031b84901b1690921692915050565b6001600160801b03198135818116916010851015617f6e5760109490940360031b84901b1690921692915050565b60006020828403121561976357600080fd5b815160ff81168114616cb057600080fd5b600060018201619786576197866194ac565b5060010190565b634e487b7160e01b600052600160045260246000fd5b6000600160ff1b82016197b8576197b86194ac565b5060000390565b60008083128015600160ff1b8501841216156197dd576197dd6194ac565b6001600160ff1b03840183138116156197f8576197f86194ac565b50500390565b60006001600160801b03808316818516808303821115619820576198206194ac565b01949350505050565b600181815b8085111561986457816000190482111561984a5761984a6194ac565b8085161561985757918102915b93841c939080029061982e565b509250929050565b60008261987b575060016114bb565b81619888575060006114bb565b816001811461989e57600281146198a8576198c4565b60019150506114bb565b60ff8411156198b9576198b96194ac565b50506001821b6114bb565b5060208310610133831016604e8410600b84101617156198e7575081810a6114bb565b6198f18383619829565b8060001904821115619905576199056194ac565b029392505050565b6000616cb060ff84168361986c565b60006001600160801b0380831681851681830481118215151615619942576199426194ac565b02949350505050565b60008261995a5761995a6195b4565b600160ff1b821460001984141615619974576199746194ac565b500590565b600080821280156001600160ff1b038490038513161561999b5761999b6194ac565b600160ff1b83900384128116156199b4576199b46194ac565b50500190565b805160208201516001600160c01b031980821692919060088310156199e95780818460080360031b1b83161693505b505050919050565b60008251619a03818460208701619437565b9190910192915050565b600060208284031215619a1f57600080fd5b5051919050565b60006001600160ff1b0381841382841380821686840486111615619a4c57619a4c6194ac565b600160ff1b6000871282811687830589121615619a6b57619a6b6194ac565b60008712925087820587128484161615619a8757619a876194ac565b87850587128184161615619a9d57619a9d6194ac565b505050929093029392505050565b6000616cb0838361986c56fea264697066735822122037153f1f715c48f31ae636357b1c7bdb33986f513e847e2defd0169e706cb95064736f6c634300080d0033"
            .parse()
            .expect("invalid bytecode")
    });
    pub struct HyperTimeOverride<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for HyperTimeOverride<M> {
        fn clone(&self) -> Self {
            HyperTimeOverride(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for HyperTimeOverride<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for HyperTimeOverride<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(HyperTimeOverride)).field(&self.address()).finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> HyperTimeOverride<M> {
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
                    HYPERTIMEOVERRIDE_ABI.clone(),
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
                HYPERTIMEOVERRIDE_ABI.clone(),
                HYPERTIMEOVERRIDE_BYTECODE.clone().into(),
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
        ) -> ::ethers::contract::builders::Event<M, HyperTimeOverrideEvents> {
            self.0.event_with_filter(Default::default())
        }
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>>
    for HyperTimeOverride<M> {
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
    pub enum HyperTimeOverrideErrors {
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
    impl ::ethers::core::abi::AbiDecode for HyperTimeOverrideErrors {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded)
                = <DrawBalance as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::DrawBalance(decoded));
            }
            if let Ok(decoded)
                = <EtherTransferFail as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::EtherTransferFail(decoded));
            }
            if let Ok(decoded)
                = <Infinity as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperTimeOverrideErrors::Infinity(decoded));
            }
            if let Ok(decoded)
                = <InsufficientPosition as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::InsufficientPosition(decoded));
            }
            if let Ok(decoded)
                = <InsufficientReserve as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::InsufficientReserve(decoded));
            }
            if let Ok(decoded)
                = <InvalidBalance as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::InvalidBalance(decoded));
            }
            if let Ok(decoded)
                = <InvalidBytesLength as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::InvalidBytesLength(decoded));
            }
            if let Ok(decoded)
                = <InvalidDecimals as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::InvalidDecimals(decoded));
            }
            if let Ok(decoded)
                = <InvalidFee as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperTimeOverrideErrors::InvalidFee(decoded));
            }
            if let Ok(decoded)
                = <InvalidInstruction as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::InvalidInstruction(decoded));
            }
            if let Ok(decoded)
                = <InvalidInvariant as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::InvalidInvariant(decoded));
            }
            if let Ok(decoded)
                = <InvalidJump as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::InvalidJump(decoded));
            }
            if let Ok(decoded)
                = <InvalidReentrancy as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::InvalidReentrancy(decoded));
            }
            if let Ok(decoded)
                = <InvalidReward as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::InvalidReward(decoded));
            }
            if let Ok(decoded)
                = <InvalidSettlement as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::InvalidSettlement(decoded));
            }
            if let Ok(decoded)
                = <InvalidTransfer as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::InvalidTransfer(decoded));
            }
            if let Ok(decoded)
                = <JitLiquidity as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::JitLiquidity(decoded));
            }
            if let Ok(decoded)
                = <Min as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperTimeOverrideErrors::Min(decoded));
            }
            if let Ok(decoded)
                = <NegativeInfinity as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::NegativeInfinity(decoded));
            }
            if let Ok(decoded)
                = <NonExistentPool as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::NonExistentPool(decoded));
            }
            if let Ok(decoded)
                = <NonExistentPosition as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::NonExistentPosition(decoded));
            }
            if let Ok(decoded)
                = <NotController as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::NotController(decoded));
            }
            if let Ok(decoded)
                = <NotPreparedToSettle as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::NotPreparedToSettle(decoded));
            }
            if let Ok(decoded)
                = <OOB as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperTimeOverrideErrors::OOB(decoded));
            }
            if let Ok(decoded)
                = <OverflowWad as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::OverflowWad(decoded));
            }
            if let Ok(decoded)
                = <PairExists as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperTimeOverrideErrors::PairExists(decoded));
            }
            if let Ok(decoded)
                = <PoolExists as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperTimeOverrideErrors::PoolExists(decoded));
            }
            if let Ok(decoded)
                = <PoolExpired as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::PoolExpired(decoded));
            }
            if let Ok(decoded)
                = <PositionNotStaked as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::PositionNotStaked(decoded));
            }
            if let Ok(decoded)
                = <SameTokenError as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::SameTokenError(decoded));
            }
            if let Ok(decoded)
                = <StakeNotMature as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::StakeNotMature(decoded));
            }
            if let Ok(decoded)
                = <SwapLimitReached as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::SwapLimitReached(decoded));
            }
            if let Ok(decoded)
                = <ZeroInput as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperTimeOverrideErrors::ZeroInput(decoded));
            }
            if let Ok(decoded)
                = <ZeroLiquidity as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideErrors::ZeroLiquidity(decoded));
            }
            if let Ok(decoded)
                = <ZeroPrice as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperTimeOverrideErrors::ZeroPrice(decoded));
            }
            if let Ok(decoded)
                = <ZeroValue as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperTimeOverrideErrors::ZeroValue(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for HyperTimeOverrideErrors {
        fn encode(self) -> Vec<u8> {
            match self {
                HyperTimeOverrideErrors::DrawBalance(element) => element.encode(),
                HyperTimeOverrideErrors::EtherTransferFail(element) => element.encode(),
                HyperTimeOverrideErrors::Infinity(element) => element.encode(),
                HyperTimeOverrideErrors::InsufficientPosition(element) => {
                    element.encode()
                }
                HyperTimeOverrideErrors::InsufficientReserve(element) => element.encode(),
                HyperTimeOverrideErrors::InvalidBalance(element) => element.encode(),
                HyperTimeOverrideErrors::InvalidBytesLength(element) => element.encode(),
                HyperTimeOverrideErrors::InvalidDecimals(element) => element.encode(),
                HyperTimeOverrideErrors::InvalidFee(element) => element.encode(),
                HyperTimeOverrideErrors::InvalidInstruction(element) => element.encode(),
                HyperTimeOverrideErrors::InvalidInvariant(element) => element.encode(),
                HyperTimeOverrideErrors::InvalidJump(element) => element.encode(),
                HyperTimeOverrideErrors::InvalidReentrancy(element) => element.encode(),
                HyperTimeOverrideErrors::InvalidReward(element) => element.encode(),
                HyperTimeOverrideErrors::InvalidSettlement(element) => element.encode(),
                HyperTimeOverrideErrors::InvalidTransfer(element) => element.encode(),
                HyperTimeOverrideErrors::JitLiquidity(element) => element.encode(),
                HyperTimeOverrideErrors::Min(element) => element.encode(),
                HyperTimeOverrideErrors::NegativeInfinity(element) => element.encode(),
                HyperTimeOverrideErrors::NonExistentPool(element) => element.encode(),
                HyperTimeOverrideErrors::NonExistentPosition(element) => element.encode(),
                HyperTimeOverrideErrors::NotController(element) => element.encode(),
                HyperTimeOverrideErrors::NotPreparedToSettle(element) => element.encode(),
                HyperTimeOverrideErrors::OOB(element) => element.encode(),
                HyperTimeOverrideErrors::OverflowWad(element) => element.encode(),
                HyperTimeOverrideErrors::PairExists(element) => element.encode(),
                HyperTimeOverrideErrors::PoolExists(element) => element.encode(),
                HyperTimeOverrideErrors::PoolExpired(element) => element.encode(),
                HyperTimeOverrideErrors::PositionNotStaked(element) => element.encode(),
                HyperTimeOverrideErrors::SameTokenError(element) => element.encode(),
                HyperTimeOverrideErrors::StakeNotMature(element) => element.encode(),
                HyperTimeOverrideErrors::SwapLimitReached(element) => element.encode(),
                HyperTimeOverrideErrors::ZeroInput(element) => element.encode(),
                HyperTimeOverrideErrors::ZeroLiquidity(element) => element.encode(),
                HyperTimeOverrideErrors::ZeroPrice(element) => element.encode(),
                HyperTimeOverrideErrors::ZeroValue(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for HyperTimeOverrideErrors {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                HyperTimeOverrideErrors::DrawBalance(element) => element.fmt(f),
                HyperTimeOverrideErrors::EtherTransferFail(element) => element.fmt(f),
                HyperTimeOverrideErrors::Infinity(element) => element.fmt(f),
                HyperTimeOverrideErrors::InsufficientPosition(element) => element.fmt(f),
                HyperTimeOverrideErrors::InsufficientReserve(element) => element.fmt(f),
                HyperTimeOverrideErrors::InvalidBalance(element) => element.fmt(f),
                HyperTimeOverrideErrors::InvalidBytesLength(element) => element.fmt(f),
                HyperTimeOverrideErrors::InvalidDecimals(element) => element.fmt(f),
                HyperTimeOverrideErrors::InvalidFee(element) => element.fmt(f),
                HyperTimeOverrideErrors::InvalidInstruction(element) => element.fmt(f),
                HyperTimeOverrideErrors::InvalidInvariant(element) => element.fmt(f),
                HyperTimeOverrideErrors::InvalidJump(element) => element.fmt(f),
                HyperTimeOverrideErrors::InvalidReentrancy(element) => element.fmt(f),
                HyperTimeOverrideErrors::InvalidReward(element) => element.fmt(f),
                HyperTimeOverrideErrors::InvalidSettlement(element) => element.fmt(f),
                HyperTimeOverrideErrors::InvalidTransfer(element) => element.fmt(f),
                HyperTimeOverrideErrors::JitLiquidity(element) => element.fmt(f),
                HyperTimeOverrideErrors::Min(element) => element.fmt(f),
                HyperTimeOverrideErrors::NegativeInfinity(element) => element.fmt(f),
                HyperTimeOverrideErrors::NonExistentPool(element) => element.fmt(f),
                HyperTimeOverrideErrors::NonExistentPosition(element) => element.fmt(f),
                HyperTimeOverrideErrors::NotController(element) => element.fmt(f),
                HyperTimeOverrideErrors::NotPreparedToSettle(element) => element.fmt(f),
                HyperTimeOverrideErrors::OOB(element) => element.fmt(f),
                HyperTimeOverrideErrors::OverflowWad(element) => element.fmt(f),
                HyperTimeOverrideErrors::PairExists(element) => element.fmt(f),
                HyperTimeOverrideErrors::PoolExists(element) => element.fmt(f),
                HyperTimeOverrideErrors::PoolExpired(element) => element.fmt(f),
                HyperTimeOverrideErrors::PositionNotStaked(element) => element.fmt(f),
                HyperTimeOverrideErrors::SameTokenError(element) => element.fmt(f),
                HyperTimeOverrideErrors::StakeNotMature(element) => element.fmt(f),
                HyperTimeOverrideErrors::SwapLimitReached(element) => element.fmt(f),
                HyperTimeOverrideErrors::ZeroInput(element) => element.fmt(f),
                HyperTimeOverrideErrors::ZeroLiquidity(element) => element.fmt(f),
                HyperTimeOverrideErrors::ZeroPrice(element) => element.fmt(f),
                HyperTimeOverrideErrors::ZeroValue(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<DrawBalance> for HyperTimeOverrideErrors {
        fn from(var: DrawBalance) -> Self {
            HyperTimeOverrideErrors::DrawBalance(var)
        }
    }
    impl ::std::convert::From<EtherTransferFail> for HyperTimeOverrideErrors {
        fn from(var: EtherTransferFail) -> Self {
            HyperTimeOverrideErrors::EtherTransferFail(var)
        }
    }
    impl ::std::convert::From<Infinity> for HyperTimeOverrideErrors {
        fn from(var: Infinity) -> Self {
            HyperTimeOverrideErrors::Infinity(var)
        }
    }
    impl ::std::convert::From<InsufficientPosition> for HyperTimeOverrideErrors {
        fn from(var: InsufficientPosition) -> Self {
            HyperTimeOverrideErrors::InsufficientPosition(var)
        }
    }
    impl ::std::convert::From<InsufficientReserve> for HyperTimeOverrideErrors {
        fn from(var: InsufficientReserve) -> Self {
            HyperTimeOverrideErrors::InsufficientReserve(var)
        }
    }
    impl ::std::convert::From<InvalidBalance> for HyperTimeOverrideErrors {
        fn from(var: InvalidBalance) -> Self {
            HyperTimeOverrideErrors::InvalidBalance(var)
        }
    }
    impl ::std::convert::From<InvalidBytesLength> for HyperTimeOverrideErrors {
        fn from(var: InvalidBytesLength) -> Self {
            HyperTimeOverrideErrors::InvalidBytesLength(var)
        }
    }
    impl ::std::convert::From<InvalidDecimals> for HyperTimeOverrideErrors {
        fn from(var: InvalidDecimals) -> Self {
            HyperTimeOverrideErrors::InvalidDecimals(var)
        }
    }
    impl ::std::convert::From<InvalidFee> for HyperTimeOverrideErrors {
        fn from(var: InvalidFee) -> Self {
            HyperTimeOverrideErrors::InvalidFee(var)
        }
    }
    impl ::std::convert::From<InvalidInstruction> for HyperTimeOverrideErrors {
        fn from(var: InvalidInstruction) -> Self {
            HyperTimeOverrideErrors::InvalidInstruction(var)
        }
    }
    impl ::std::convert::From<InvalidInvariant> for HyperTimeOverrideErrors {
        fn from(var: InvalidInvariant) -> Self {
            HyperTimeOverrideErrors::InvalidInvariant(var)
        }
    }
    impl ::std::convert::From<InvalidJump> for HyperTimeOverrideErrors {
        fn from(var: InvalidJump) -> Self {
            HyperTimeOverrideErrors::InvalidJump(var)
        }
    }
    impl ::std::convert::From<InvalidReentrancy> for HyperTimeOverrideErrors {
        fn from(var: InvalidReentrancy) -> Self {
            HyperTimeOverrideErrors::InvalidReentrancy(var)
        }
    }
    impl ::std::convert::From<InvalidReward> for HyperTimeOverrideErrors {
        fn from(var: InvalidReward) -> Self {
            HyperTimeOverrideErrors::InvalidReward(var)
        }
    }
    impl ::std::convert::From<InvalidSettlement> for HyperTimeOverrideErrors {
        fn from(var: InvalidSettlement) -> Self {
            HyperTimeOverrideErrors::InvalidSettlement(var)
        }
    }
    impl ::std::convert::From<InvalidTransfer> for HyperTimeOverrideErrors {
        fn from(var: InvalidTransfer) -> Self {
            HyperTimeOverrideErrors::InvalidTransfer(var)
        }
    }
    impl ::std::convert::From<JitLiquidity> for HyperTimeOverrideErrors {
        fn from(var: JitLiquidity) -> Self {
            HyperTimeOverrideErrors::JitLiquidity(var)
        }
    }
    impl ::std::convert::From<Min> for HyperTimeOverrideErrors {
        fn from(var: Min) -> Self {
            HyperTimeOverrideErrors::Min(var)
        }
    }
    impl ::std::convert::From<NegativeInfinity> for HyperTimeOverrideErrors {
        fn from(var: NegativeInfinity) -> Self {
            HyperTimeOverrideErrors::NegativeInfinity(var)
        }
    }
    impl ::std::convert::From<NonExistentPool> for HyperTimeOverrideErrors {
        fn from(var: NonExistentPool) -> Self {
            HyperTimeOverrideErrors::NonExistentPool(var)
        }
    }
    impl ::std::convert::From<NonExistentPosition> for HyperTimeOverrideErrors {
        fn from(var: NonExistentPosition) -> Self {
            HyperTimeOverrideErrors::NonExistentPosition(var)
        }
    }
    impl ::std::convert::From<NotController> for HyperTimeOverrideErrors {
        fn from(var: NotController) -> Self {
            HyperTimeOverrideErrors::NotController(var)
        }
    }
    impl ::std::convert::From<NotPreparedToSettle> for HyperTimeOverrideErrors {
        fn from(var: NotPreparedToSettle) -> Self {
            HyperTimeOverrideErrors::NotPreparedToSettle(var)
        }
    }
    impl ::std::convert::From<OOB> for HyperTimeOverrideErrors {
        fn from(var: OOB) -> Self {
            HyperTimeOverrideErrors::OOB(var)
        }
    }
    impl ::std::convert::From<OverflowWad> for HyperTimeOverrideErrors {
        fn from(var: OverflowWad) -> Self {
            HyperTimeOverrideErrors::OverflowWad(var)
        }
    }
    impl ::std::convert::From<PairExists> for HyperTimeOverrideErrors {
        fn from(var: PairExists) -> Self {
            HyperTimeOverrideErrors::PairExists(var)
        }
    }
    impl ::std::convert::From<PoolExists> for HyperTimeOverrideErrors {
        fn from(var: PoolExists) -> Self {
            HyperTimeOverrideErrors::PoolExists(var)
        }
    }
    impl ::std::convert::From<PoolExpired> for HyperTimeOverrideErrors {
        fn from(var: PoolExpired) -> Self {
            HyperTimeOverrideErrors::PoolExpired(var)
        }
    }
    impl ::std::convert::From<PositionNotStaked> for HyperTimeOverrideErrors {
        fn from(var: PositionNotStaked) -> Self {
            HyperTimeOverrideErrors::PositionNotStaked(var)
        }
    }
    impl ::std::convert::From<SameTokenError> for HyperTimeOverrideErrors {
        fn from(var: SameTokenError) -> Self {
            HyperTimeOverrideErrors::SameTokenError(var)
        }
    }
    impl ::std::convert::From<StakeNotMature> for HyperTimeOverrideErrors {
        fn from(var: StakeNotMature) -> Self {
            HyperTimeOverrideErrors::StakeNotMature(var)
        }
    }
    impl ::std::convert::From<SwapLimitReached> for HyperTimeOverrideErrors {
        fn from(var: SwapLimitReached) -> Self {
            HyperTimeOverrideErrors::SwapLimitReached(var)
        }
    }
    impl ::std::convert::From<ZeroInput> for HyperTimeOverrideErrors {
        fn from(var: ZeroInput) -> Self {
            HyperTimeOverrideErrors::ZeroInput(var)
        }
    }
    impl ::std::convert::From<ZeroLiquidity> for HyperTimeOverrideErrors {
        fn from(var: ZeroLiquidity) -> Self {
            HyperTimeOverrideErrors::ZeroLiquidity(var)
        }
    }
    impl ::std::convert::From<ZeroPrice> for HyperTimeOverrideErrors {
        fn from(var: ZeroPrice) -> Self {
            HyperTimeOverrideErrors::ZeroPrice(var)
        }
    }
    impl ::std::convert::From<ZeroValue> for HyperTimeOverrideErrors {
        fn from(var: ZeroValue) -> Self {
            HyperTimeOverrideErrors::ZeroValue(var)
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
    pub enum HyperTimeOverrideEvents {
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
    impl ::ethers::contract::EthLogDecode for HyperTimeOverrideEvents {
        fn decode_log(
            log: &::ethers::core::abi::RawLog,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::Error>
        where
            Self: Sized,
        {
            if let Ok(decoded) = AllocateFilter::decode_log(log) {
                return Ok(HyperTimeOverrideEvents::AllocateFilter(decoded));
            }
            if let Ok(decoded) = ChangeParametersFilter::decode_log(log) {
                return Ok(HyperTimeOverrideEvents::ChangeParametersFilter(decoded));
            }
            if let Ok(decoded) = CollectFilter::decode_log(log) {
                return Ok(HyperTimeOverrideEvents::CollectFilter(decoded));
            }
            if let Ok(decoded) = CreatePairFilter::decode_log(log) {
                return Ok(HyperTimeOverrideEvents::CreatePairFilter(decoded));
            }
            if let Ok(decoded) = CreatePoolFilter::decode_log(log) {
                return Ok(HyperTimeOverrideEvents::CreatePoolFilter(decoded));
            }
            if let Ok(decoded) = DecreaseReserveBalanceFilter::decode_log(log) {
                return Ok(
                    HyperTimeOverrideEvents::DecreaseReserveBalanceFilter(decoded),
                );
            }
            if let Ok(decoded) = DecreaseUserBalanceFilter::decode_log(log) {
                return Ok(HyperTimeOverrideEvents::DecreaseUserBalanceFilter(decoded));
            }
            if let Ok(decoded) = DepositFilter::decode_log(log) {
                return Ok(HyperTimeOverrideEvents::DepositFilter(decoded));
            }
            if let Ok(decoded) = IncreaseReserveBalanceFilter::decode_log(log) {
                return Ok(
                    HyperTimeOverrideEvents::IncreaseReserveBalanceFilter(decoded),
                );
            }
            if let Ok(decoded) = IncreaseUserBalanceFilter::decode_log(log) {
                return Ok(HyperTimeOverrideEvents::IncreaseUserBalanceFilter(decoded));
            }
            if let Ok(decoded) = StakeFilter::decode_log(log) {
                return Ok(HyperTimeOverrideEvents::StakeFilter(decoded));
            }
            if let Ok(decoded) = SwapFilter::decode_log(log) {
                return Ok(HyperTimeOverrideEvents::SwapFilter(decoded));
            }
            if let Ok(decoded) = UnallocateFilter::decode_log(log) {
                return Ok(HyperTimeOverrideEvents::UnallocateFilter(decoded));
            }
            if let Ok(decoded) = UnstakeFilter::decode_log(log) {
                return Ok(HyperTimeOverrideEvents::UnstakeFilter(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData)
        }
    }
    impl ::std::fmt::Display for HyperTimeOverrideEvents {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                HyperTimeOverrideEvents::AllocateFilter(element) => element.fmt(f),
                HyperTimeOverrideEvents::ChangeParametersFilter(element) => {
                    element.fmt(f)
                }
                HyperTimeOverrideEvents::CollectFilter(element) => element.fmt(f),
                HyperTimeOverrideEvents::CreatePairFilter(element) => element.fmt(f),
                HyperTimeOverrideEvents::CreatePoolFilter(element) => element.fmt(f),
                HyperTimeOverrideEvents::DecreaseReserveBalanceFilter(element) => {
                    element.fmt(f)
                }
                HyperTimeOverrideEvents::DecreaseUserBalanceFilter(element) => {
                    element.fmt(f)
                }
                HyperTimeOverrideEvents::DepositFilter(element) => element.fmt(f),
                HyperTimeOverrideEvents::IncreaseReserveBalanceFilter(element) => {
                    element.fmt(f)
                }
                HyperTimeOverrideEvents::IncreaseUserBalanceFilter(element) => {
                    element.fmt(f)
                }
                HyperTimeOverrideEvents::StakeFilter(element) => element.fmt(f),
                HyperTimeOverrideEvents::SwapFilter(element) => element.fmt(f),
                HyperTimeOverrideEvents::UnallocateFilter(element) => element.fmt(f),
                HyperTimeOverrideEvents::UnstakeFilter(element) => element.fmt(f),
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
    pub enum HyperTimeOverrideCalls {
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
        Pairs(PairsCall),
        Pools(PoolsCall),
        Positions(PositionsCall),
        SetJitPolicy(SetJitPolicyCall),
        SetTimestamp(SetTimestampCall),
        Stake(StakeCall),
        Swap(SwapCall),
        Timestamp(TimestampCall),
        Unallocate(UnallocateCall),
        Unstake(UnstakeCall),
    }
    impl ::ethers::core::abi::AbiDecode for HyperTimeOverrideCalls {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded)
                = <VersionCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::Version(decoded));
            }
            if let Ok(decoded)
                = <WethCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperTimeOverrideCalls::Weth(decoded));
            }
            if let Ok(decoded)
                = <AccountCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::Account(decoded));
            }
            if let Ok(decoded)
                = <AllocateCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::Allocate(decoded));
            }
            if let Ok(decoded)
                = <ChangeParametersCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::ChangeParameters(decoded));
            }
            if let Ok(decoded)
                = <ClaimCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperTimeOverrideCalls::Claim(decoded));
            }
            if let Ok(decoded)
                = <DepositCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::Deposit(decoded));
            }
            if let Ok(decoded)
                = <DoJumpProcessCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::DoJumpProcess(decoded));
            }
            if let Ok(decoded)
                = <DrawCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperTimeOverrideCalls::Draw(decoded));
            }
            if let Ok(decoded)
                = <FundCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperTimeOverrideCalls::Fund(decoded));
            }
            if let Ok(decoded)
                = <GetAmountOutCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::GetAmountOut(decoded));
            }
            if let Ok(decoded)
                = <GetAmountsCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::GetAmounts(decoded));
            }
            if let Ok(decoded)
                = <GetBalanceCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::GetBalance(decoded));
            }
            if let Ok(decoded)
                = <GetLatestPriceCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::GetLatestPrice(decoded));
            }
            if let Ok(decoded)
                = <GetLiquidityDeltasCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::GetLiquidityDeltas(decoded));
            }
            if let Ok(decoded)
                = <GetMaxLiquidityCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::GetMaxLiquidity(decoded));
            }
            if let Ok(decoded)
                = <GetNetBalanceCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::GetNetBalance(decoded));
            }
            if let Ok(decoded)
                = <GetPairIdCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::GetPairId(decoded));
            }
            if let Ok(decoded)
                = <GetPairNonceCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::GetPairNonce(decoded));
            }
            if let Ok(decoded)
                = <GetPoolNonceCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::GetPoolNonce(decoded));
            }
            if let Ok(decoded)
                = <GetReserveCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::GetReserve(decoded));
            }
            if let Ok(decoded)
                = <GetTimePassedCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::GetTimePassed(decoded));
            }
            if let Ok(decoded)
                = <GetVirtualReservesCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::GetVirtualReserves(decoded));
            }
            if let Ok(decoded)
                = <JitDelayCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::JitDelay(decoded));
            }
            if let Ok(decoded)
                = <PairsCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperTimeOverrideCalls::Pairs(decoded));
            }
            if let Ok(decoded)
                = <PoolsCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperTimeOverrideCalls::Pools(decoded));
            }
            if let Ok(decoded)
                = <PositionsCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::Positions(decoded));
            }
            if let Ok(decoded)
                = <SetJitPolicyCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::SetJitPolicy(decoded));
            }
            if let Ok(decoded)
                = <SetTimestampCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::SetTimestamp(decoded));
            }
            if let Ok(decoded)
                = <StakeCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperTimeOverrideCalls::Stake(decoded));
            }
            if let Ok(decoded)
                = <SwapCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(HyperTimeOverrideCalls::Swap(decoded));
            }
            if let Ok(decoded)
                = <TimestampCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::Timestamp(decoded));
            }
            if let Ok(decoded)
                = <UnallocateCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::Unallocate(decoded));
            }
            if let Ok(decoded)
                = <UnstakeCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(HyperTimeOverrideCalls::Unstake(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for HyperTimeOverrideCalls {
        fn encode(self) -> Vec<u8> {
            match self {
                HyperTimeOverrideCalls::Version(element) => element.encode(),
                HyperTimeOverrideCalls::Weth(element) => element.encode(),
                HyperTimeOverrideCalls::Account(element) => element.encode(),
                HyperTimeOverrideCalls::Allocate(element) => element.encode(),
                HyperTimeOverrideCalls::ChangeParameters(element) => element.encode(),
                HyperTimeOverrideCalls::Claim(element) => element.encode(),
                HyperTimeOverrideCalls::Deposit(element) => element.encode(),
                HyperTimeOverrideCalls::DoJumpProcess(element) => element.encode(),
                HyperTimeOverrideCalls::Draw(element) => element.encode(),
                HyperTimeOverrideCalls::Fund(element) => element.encode(),
                HyperTimeOverrideCalls::GetAmountOut(element) => element.encode(),
                HyperTimeOverrideCalls::GetAmounts(element) => element.encode(),
                HyperTimeOverrideCalls::GetBalance(element) => element.encode(),
                HyperTimeOverrideCalls::GetLatestPrice(element) => element.encode(),
                HyperTimeOverrideCalls::GetLiquidityDeltas(element) => element.encode(),
                HyperTimeOverrideCalls::GetMaxLiquidity(element) => element.encode(),
                HyperTimeOverrideCalls::GetNetBalance(element) => element.encode(),
                HyperTimeOverrideCalls::GetPairId(element) => element.encode(),
                HyperTimeOverrideCalls::GetPairNonce(element) => element.encode(),
                HyperTimeOverrideCalls::GetPoolNonce(element) => element.encode(),
                HyperTimeOverrideCalls::GetReserve(element) => element.encode(),
                HyperTimeOverrideCalls::GetTimePassed(element) => element.encode(),
                HyperTimeOverrideCalls::GetVirtualReserves(element) => element.encode(),
                HyperTimeOverrideCalls::JitDelay(element) => element.encode(),
                HyperTimeOverrideCalls::Pairs(element) => element.encode(),
                HyperTimeOverrideCalls::Pools(element) => element.encode(),
                HyperTimeOverrideCalls::Positions(element) => element.encode(),
                HyperTimeOverrideCalls::SetJitPolicy(element) => element.encode(),
                HyperTimeOverrideCalls::SetTimestamp(element) => element.encode(),
                HyperTimeOverrideCalls::Stake(element) => element.encode(),
                HyperTimeOverrideCalls::Swap(element) => element.encode(),
                HyperTimeOverrideCalls::Timestamp(element) => element.encode(),
                HyperTimeOverrideCalls::Unallocate(element) => element.encode(),
                HyperTimeOverrideCalls::Unstake(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for HyperTimeOverrideCalls {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                HyperTimeOverrideCalls::Version(element) => element.fmt(f),
                HyperTimeOverrideCalls::Weth(element) => element.fmt(f),
                HyperTimeOverrideCalls::Account(element) => element.fmt(f),
                HyperTimeOverrideCalls::Allocate(element) => element.fmt(f),
                HyperTimeOverrideCalls::ChangeParameters(element) => element.fmt(f),
                HyperTimeOverrideCalls::Claim(element) => element.fmt(f),
                HyperTimeOverrideCalls::Deposit(element) => element.fmt(f),
                HyperTimeOverrideCalls::DoJumpProcess(element) => element.fmt(f),
                HyperTimeOverrideCalls::Draw(element) => element.fmt(f),
                HyperTimeOverrideCalls::Fund(element) => element.fmt(f),
                HyperTimeOverrideCalls::GetAmountOut(element) => element.fmt(f),
                HyperTimeOverrideCalls::GetAmounts(element) => element.fmt(f),
                HyperTimeOverrideCalls::GetBalance(element) => element.fmt(f),
                HyperTimeOverrideCalls::GetLatestPrice(element) => element.fmt(f),
                HyperTimeOverrideCalls::GetLiquidityDeltas(element) => element.fmt(f),
                HyperTimeOverrideCalls::GetMaxLiquidity(element) => element.fmt(f),
                HyperTimeOverrideCalls::GetNetBalance(element) => element.fmt(f),
                HyperTimeOverrideCalls::GetPairId(element) => element.fmt(f),
                HyperTimeOverrideCalls::GetPairNonce(element) => element.fmt(f),
                HyperTimeOverrideCalls::GetPoolNonce(element) => element.fmt(f),
                HyperTimeOverrideCalls::GetReserve(element) => element.fmt(f),
                HyperTimeOverrideCalls::GetTimePassed(element) => element.fmt(f),
                HyperTimeOverrideCalls::GetVirtualReserves(element) => element.fmt(f),
                HyperTimeOverrideCalls::JitDelay(element) => element.fmt(f),
                HyperTimeOverrideCalls::Pairs(element) => element.fmt(f),
                HyperTimeOverrideCalls::Pools(element) => element.fmt(f),
                HyperTimeOverrideCalls::Positions(element) => element.fmt(f),
                HyperTimeOverrideCalls::SetJitPolicy(element) => element.fmt(f),
                HyperTimeOverrideCalls::SetTimestamp(element) => element.fmt(f),
                HyperTimeOverrideCalls::Stake(element) => element.fmt(f),
                HyperTimeOverrideCalls::Swap(element) => element.fmt(f),
                HyperTimeOverrideCalls::Timestamp(element) => element.fmt(f),
                HyperTimeOverrideCalls::Unallocate(element) => element.fmt(f),
                HyperTimeOverrideCalls::Unstake(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<VersionCall> for HyperTimeOverrideCalls {
        fn from(var: VersionCall) -> Self {
            HyperTimeOverrideCalls::Version(var)
        }
    }
    impl ::std::convert::From<WethCall> for HyperTimeOverrideCalls {
        fn from(var: WethCall) -> Self {
            HyperTimeOverrideCalls::Weth(var)
        }
    }
    impl ::std::convert::From<AccountCall> for HyperTimeOverrideCalls {
        fn from(var: AccountCall) -> Self {
            HyperTimeOverrideCalls::Account(var)
        }
    }
    impl ::std::convert::From<AllocateCall> for HyperTimeOverrideCalls {
        fn from(var: AllocateCall) -> Self {
            HyperTimeOverrideCalls::Allocate(var)
        }
    }
    impl ::std::convert::From<ChangeParametersCall> for HyperTimeOverrideCalls {
        fn from(var: ChangeParametersCall) -> Self {
            HyperTimeOverrideCalls::ChangeParameters(var)
        }
    }
    impl ::std::convert::From<ClaimCall> for HyperTimeOverrideCalls {
        fn from(var: ClaimCall) -> Self {
            HyperTimeOverrideCalls::Claim(var)
        }
    }
    impl ::std::convert::From<DepositCall> for HyperTimeOverrideCalls {
        fn from(var: DepositCall) -> Self {
            HyperTimeOverrideCalls::Deposit(var)
        }
    }
    impl ::std::convert::From<DoJumpProcessCall> for HyperTimeOverrideCalls {
        fn from(var: DoJumpProcessCall) -> Self {
            HyperTimeOverrideCalls::DoJumpProcess(var)
        }
    }
    impl ::std::convert::From<DrawCall> for HyperTimeOverrideCalls {
        fn from(var: DrawCall) -> Self {
            HyperTimeOverrideCalls::Draw(var)
        }
    }
    impl ::std::convert::From<FundCall> for HyperTimeOverrideCalls {
        fn from(var: FundCall) -> Self {
            HyperTimeOverrideCalls::Fund(var)
        }
    }
    impl ::std::convert::From<GetAmountOutCall> for HyperTimeOverrideCalls {
        fn from(var: GetAmountOutCall) -> Self {
            HyperTimeOverrideCalls::GetAmountOut(var)
        }
    }
    impl ::std::convert::From<GetAmountsCall> for HyperTimeOverrideCalls {
        fn from(var: GetAmountsCall) -> Self {
            HyperTimeOverrideCalls::GetAmounts(var)
        }
    }
    impl ::std::convert::From<GetBalanceCall> for HyperTimeOverrideCalls {
        fn from(var: GetBalanceCall) -> Self {
            HyperTimeOverrideCalls::GetBalance(var)
        }
    }
    impl ::std::convert::From<GetLatestPriceCall> for HyperTimeOverrideCalls {
        fn from(var: GetLatestPriceCall) -> Self {
            HyperTimeOverrideCalls::GetLatestPrice(var)
        }
    }
    impl ::std::convert::From<GetLiquidityDeltasCall> for HyperTimeOverrideCalls {
        fn from(var: GetLiquidityDeltasCall) -> Self {
            HyperTimeOverrideCalls::GetLiquidityDeltas(var)
        }
    }
    impl ::std::convert::From<GetMaxLiquidityCall> for HyperTimeOverrideCalls {
        fn from(var: GetMaxLiquidityCall) -> Self {
            HyperTimeOverrideCalls::GetMaxLiquidity(var)
        }
    }
    impl ::std::convert::From<GetNetBalanceCall> for HyperTimeOverrideCalls {
        fn from(var: GetNetBalanceCall) -> Self {
            HyperTimeOverrideCalls::GetNetBalance(var)
        }
    }
    impl ::std::convert::From<GetPairIdCall> for HyperTimeOverrideCalls {
        fn from(var: GetPairIdCall) -> Self {
            HyperTimeOverrideCalls::GetPairId(var)
        }
    }
    impl ::std::convert::From<GetPairNonceCall> for HyperTimeOverrideCalls {
        fn from(var: GetPairNonceCall) -> Self {
            HyperTimeOverrideCalls::GetPairNonce(var)
        }
    }
    impl ::std::convert::From<GetPoolNonceCall> for HyperTimeOverrideCalls {
        fn from(var: GetPoolNonceCall) -> Self {
            HyperTimeOverrideCalls::GetPoolNonce(var)
        }
    }
    impl ::std::convert::From<GetReserveCall> for HyperTimeOverrideCalls {
        fn from(var: GetReserveCall) -> Self {
            HyperTimeOverrideCalls::GetReserve(var)
        }
    }
    impl ::std::convert::From<GetTimePassedCall> for HyperTimeOverrideCalls {
        fn from(var: GetTimePassedCall) -> Self {
            HyperTimeOverrideCalls::GetTimePassed(var)
        }
    }
    impl ::std::convert::From<GetVirtualReservesCall> for HyperTimeOverrideCalls {
        fn from(var: GetVirtualReservesCall) -> Self {
            HyperTimeOverrideCalls::GetVirtualReserves(var)
        }
    }
    impl ::std::convert::From<JitDelayCall> for HyperTimeOverrideCalls {
        fn from(var: JitDelayCall) -> Self {
            HyperTimeOverrideCalls::JitDelay(var)
        }
    }
    impl ::std::convert::From<PairsCall> for HyperTimeOverrideCalls {
        fn from(var: PairsCall) -> Self {
            HyperTimeOverrideCalls::Pairs(var)
        }
    }
    impl ::std::convert::From<PoolsCall> for HyperTimeOverrideCalls {
        fn from(var: PoolsCall) -> Self {
            HyperTimeOverrideCalls::Pools(var)
        }
    }
    impl ::std::convert::From<PositionsCall> for HyperTimeOverrideCalls {
        fn from(var: PositionsCall) -> Self {
            HyperTimeOverrideCalls::Positions(var)
        }
    }
    impl ::std::convert::From<SetJitPolicyCall> for HyperTimeOverrideCalls {
        fn from(var: SetJitPolicyCall) -> Self {
            HyperTimeOverrideCalls::SetJitPolicy(var)
        }
    }
    impl ::std::convert::From<SetTimestampCall> for HyperTimeOverrideCalls {
        fn from(var: SetTimestampCall) -> Self {
            HyperTimeOverrideCalls::SetTimestamp(var)
        }
    }
    impl ::std::convert::From<StakeCall> for HyperTimeOverrideCalls {
        fn from(var: StakeCall) -> Self {
            HyperTimeOverrideCalls::Stake(var)
        }
    }
    impl ::std::convert::From<SwapCall> for HyperTimeOverrideCalls {
        fn from(var: SwapCall) -> Self {
            HyperTimeOverrideCalls::Swap(var)
        }
    }
    impl ::std::convert::From<TimestampCall> for HyperTimeOverrideCalls {
        fn from(var: TimestampCall) -> Self {
            HyperTimeOverrideCalls::Timestamp(var)
        }
    }
    impl ::std::convert::From<UnallocateCall> for HyperTimeOverrideCalls {
        fn from(var: UnallocateCall) -> Self {
            HyperTimeOverrideCalls::Unallocate(var)
        }
    }
    impl ::std::convert::From<UnstakeCall> for HyperTimeOverrideCalls {
        fn from(var: UnstakeCall) -> Self {
            HyperTimeOverrideCalls::Unstake(var)
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
