pub use invariant_allocate_unallocate::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod invariant_allocate_unallocate {
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
    ///InvariantAllocateUnallocate was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
    use std::sync::Arc;
    #[rustfmt::skip]
    const __ABI: &str = "[{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper_\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"asset_\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"quote_\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"constructor\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidBalance\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"FinishedCall\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"int256\",\"name\":\"\",\"type\":\"int256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_address\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint256[]\",\"name\":\"val\",\"type\":\"uint256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"int256[]\",\"name\":\"val\",\"type\":\"int256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address[]\",\"name\":\"val\",\"type\":\"address[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"\",\"type\":\"bytes\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_bytes\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_bytes32\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"int256\",\"name\":\"\",\"type\":\"int256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_int\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"val\",\"type\":\"address\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_address\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256[]\",\"name\":\"val\",\"type\":\"uint256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"int256[]\",\"name\":\"val\",\"type\":\"int256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"address[]\",\"name\":\"val\",\"type\":\"address[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"bytes\",\"name\":\"val\",\"type\":\"bytes\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_bytes\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"bytes32\",\"name\":\"val\",\"type\":\"bytes32\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_bytes32\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"int256\",\"name\":\"val\",\"type\":\"int256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"decimals\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_decimal_int\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"val\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"decimals\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_decimal_uint\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"int256\",\"name\":\"val\",\"type\":\"int256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_int\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"string\",\"name\":\"val\",\"type\":\"string\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_string\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"val\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_uint\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_string\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_uint\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"\",\"type\":\"bytes\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"logs\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"IS_TEST\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__asset__\",\"outputs\":[{\"internalType\":\"contract TestERC20\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__hyper__\",\"outputs\":[{\"internalType\":\"contract HyperTimeOverride\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__poolId__\",\"outputs\":[{\"internalType\":\"uint64\",\"name\":\"\",\"type\":\"uint64\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__quote__\",\"outputs\":[{\"internalType\":\"contract TestERC20\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"contract HyperLike\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"contract TestERC20\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"contract IHyperStruct\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getPool\",\"outputs\":[{\"internalType\":\"struct HyperPool\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"lastTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"lastTimestamp\",\"type\":\"uint32\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"controller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalReward\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"lastPrice\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"liquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"int128\",\"name\":\"stakedLiquidityDelta\",\"type\":\"int128\",\"components\":[]},{\"internalType\":\"struct HyperCurve\",\"name\":\"params\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]},{\"internalType\":\"struct HyperPair\",\"name\":\"pair\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]}]},{\"inputs\":[{\"internalType\":\"contract IHyperStruct\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"positionId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getPosition\",\"outputs\":[{\"internalType\":\"struct HyperPosition\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"uint128\",\"name\":\"freeLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"lastTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"stakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"unstakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthRewardLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuoteLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedQuote\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedReward\",\"type\":\"uint128\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"contract HyperLike\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"contract TestERC20\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getReserve\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"deltaLiquidity\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"index\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"allocate\",\"outputs\":[]},{\"inputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"failed\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getBalanceSum\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getCurve\",\"outputs\":[{\"internalType\":\"struct HyperCurve\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"bool\",\"name\":\"sellAsset\",\"type\":\"bool\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getMaxSwapLimit\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint24\",\"name\":\"pairId\",\"type\":\"uint24\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPair\",\"outputs\":[{\"internalType\":\"struct HyperPair\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPhysicalBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPool\",\"outputs\":[{\"internalType\":\"struct HyperPool\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"lastTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"lastTimestamp\",\"type\":\"uint32\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"controller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalReward\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"lastPrice\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"liquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"int128\",\"name\":\"stakedLiquidityDelta\",\"type\":\"int128\",\"components\":[]},{\"internalType\":\"struct HyperCurve\",\"name\":\"params\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]},{\"internalType\":\"struct HyperPair\",\"name\":\"pair\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"positionId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPosition\",\"outputs\":[{\"internalType\":\"struct HyperPosition\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"uint128\",\"name\":\"freeLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"lastTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"stakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"unstakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthRewardLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuoteLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedQuote\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedReward\",\"type\":\"uint128\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPositionLiquiditySum\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getReserve\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"caller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getState\",\"outputs\":[{\"internalType\":\"struct HyperState\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"uint256\",\"name\":\"reserveAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"reserveQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"physicalBalanceAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"physicalBalanceQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalBalanceAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalBalanceQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalPositionLiquidity\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"callerPositionLiquidity\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalPoolLiquidity\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetPool\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuotePool\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetPosition\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuotePosition\",\"type\":\"uint256\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getVirtualBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"deltaLiquidity\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"index\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"unallocate\",\"outputs\":[]}]";
    /// The parsed JSON-ABI of the contract.
    pub static INVARIANTALLOCATEUNALLOCATE_ABI: ::ethers::contract::Lazy<::ethers::core::abi::Abi> =
        ::ethers::contract::Lazy::new(|| {
            ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi")
        });
    /// Bytecode of the #name contract
    pub static INVARIANTALLOCATEUNALLOCATE_BYTECODE: ::ethers::contract::Lazy<
        ::ethers::core::types::Bytes,
    > = ::ethers::contract::Lazy::new(|| {
        "0x60806040526000805460ff1916600117905560138054790100000000010000000000000000000000000000000000000000600160a01b600160e01b03199091161790553480156200004f57600080fd5b5060405162003842380380620038428339810160408190526200007291620001d6565b60138054336001600160a01b0319918216179091556014805482166001600160a01b03868116918217909255601680548416868416908117909155601580549094169285169290921790925560405163095ea7b360e01b81526004810192909252600019602483015284918491849163095ea7b3906044016020604051808303816000875af11580156200010a573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019062000130919062000220565b5060155460405163095ea7b360e01b81526001600160a01b03858116600483015260001960248301529091169063095ea7b3906044016020604051808303816000875af115801562000186573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190620001ac919062000220565b505050505050506200024b565b80516001600160a01b0381168114620001d157600080fd5b919050565b600080600060608486031215620001ec57600080fd5b620001f784620001b9565b92506200020760208501620001b9565b91506200021760408501620001b9565b90509250925092565b6000602082840312156200023357600080fd5b815180151581146200024457600080fd5b9392505050565b6135e7806200025b6000396000f3fe608060405234801561001057600080fd5b50600436106101585760003560e01c8063cbc3ab53116100c3578063dc7238041161007c578063dc723804146102f6578063dd05e299146102f6578063e179eed614610316578063f3140b1e14610329578063fa7626d4146103cf578063ff314c0a146103dc57600080fd5b8063cbc3ab53146101c6578063cee2aaf51461029d578063cf7dee1f146102b0578063d43c0f99146102c3578063d6bd603c146102b0578063d83410b6146102d657600080fd5b80636dce537d116101155780636dce537d146101fa5780637b135ad11461020d5780638828200d1461022d5780638dbc965114610240578063ba414fa614610253578063c6a68a471461026b57600080fd5b806309deb4d31461015d578063172cfa4c14610186578063273c329f1461015d5780633e81296e1461019b5780635a8be8b0146101c6578063634e05e0146101e7575b600080fd5b61017061016b3660046128e1565b6103ef565b60405161017d9190612977565b60405180910390f35b610199610194366004612a8b565b61051e565b005b6014546101ae906001600160a01b031681565b6040516001600160a01b03909116815260200161017d565b6101d96101d4366004612aad565b6105b5565b60405190815260200161017d565b6101d96101f5366004612aad565b610623565b6101d9610208366004612c04565b61062f565b61022061021b366004612c65565b61065c565b60405161017d9190612c9b565b6101d961023b366004612cdc565b6106ed565b6015546101ae906001600160a01b031681565b61025b61074e565b604051901515815260200161017d565b60135461028590600160a01b90046001600160401b031681565b6040516001600160401b03909116815260200161017d565b6101d96102ab366004612d1a565b610879565b6101d96102be366004612d37565b610892565b6016546101ae906001600160a01b031681565b6102e96102e43660046128e1565b610910565b60405161017d9190612d82565b610309610304366004612d90565b610960565b60405161017d9190612dd0565b610199610324366004612a8b565b610a64565b61033c610337366004612e82565b610ab5565b60405161017d9190815181526020808301519082015260408083015190820152606080830151908201526080808301519082015260a0808301519082015260c0808301519082015260e08083015190820152610100808301519082015261012080830151908201526101408083015190820152610160808301519082015261018091820151918101919091526101a00190565b60005461025b9060ff1681565b6101d96103ea366004612c04565b610bd3565b6104a36040805161018081018252600080825260208083018290528284018290526060808401839052608080850184905260a080860185905260c080870186905260e0808801879052610100880187905261012088018790528851908101895286815294850186905296840185905291830184905282018390528101829052928301529061014082019081526040805160808101825260008082526020828101829052928201819052606082015291015290565b6040516322697c2160e21b81526001600160401b03831660048201526001600160a01b038416906389a5f084906024016102a060405180830381865afa1580156104f1573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061051591906130aa565b90505b92915050565b61052e8260016001607e1b610c21565b601354604051631741369f60e01b8152600481018490529193506105a8916001600160a01b0390911690631741369f906024015b602060405180830381865afa15801561057f573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906105a39190613184565b610c5e565b6105b182610d1d565b5050565b60405163c9a396e960e01b81526001600160a01b0382811660048301526000919084169063c9a396e990602401602060405180830381865afa1580156105ff573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061051591906131a1565b600061051582846116f5565b60008061063d858585610bd3565b61064786866105b5565b61065191906131d0565b9150505b9392505050565b604080516080810182526000808252602082018190529181018290526060810191909152604051631791d98f60e21b815262ffffff831660048201526001600160a01b03841690635e47663c90602401608060405180830381865afa1580156106c9573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061051591906131e8565b60008060005b835181146107455761071f8685838151811061071157610711613204565b602002602001015187610960565b51610733906001600160801b0316836131d0565b915061073e8161321a565b90506106f3565b50949350505050565b60008054610100900460ff161561076e5750600054610100900460ff1690565b6000737109709ecfa91a80626ff3989d68f67f5b1dd12d3b156108745760408051737109709ecfa91a80626ff3989d68f67f5b1dd12d602082018190526519985a5b195960d21b828401528251808303840181526060830190935260009290916107fc917f667f9d70ca411d70ead50d8d5c22070dafc36ad75f3dcf5e7237b22ade9aecc491608001613263565b60408051601f198184030181529082905261081691613294565b6000604051808303816000865af19150503d8060008114610853576040519150601f19603f3d011682016040523d82523d6000602084013e610858565b606091505b509150508080602001905181019061087091906132b0565b9150505b919050565b6000811561088957506000919050565b50600019919050565b60405163d4fac45d60e01b81526001600160a01b03838116600483015282811660248301526000919085169063d4fac45d90604401602060405180830381865afa1580156108e4573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061090891906131a1565b949350505050565b6040805160e081018252600080825260208201819052918101829052606081018290526080810182905260a0810182905260c081018290529061095384846103ef565b6101400151949350505050565b6109ea60405180610160016040528060006001600160801b0316815260200160006001600160801b0316815260200160008152602001600081526020016000815260200160008152602001600081526020016000815260200160006001600160801b0316815260200160006001600160801b0316815260200160006001600160801b031681525090565b604051635b4289f560e11b81526001600160a01b0384811660048301526001600160401b038416602483015285169063b68513ea9060440161016060405180830381865afa158015610a40573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061090891906132cd565b610a748260016001607e1b610c21565b601354604051631741369f60e01b815260048101849052919350610aac916001600160a01b0390911690631741369f90602401610562565b6105b1826117de565b610abd61284f565b6000610ad286602887901c62ffffff1661065c565b80516040820151919250906000610ae989896103ef565b90506000610af88a898b610960565b90506000604051806101a00160405280610b128d886105b5565b8152602001610b218d876105b5565b8152602001610b308d88610623565b8152602001610b3f8d87610623565b8152602001610b4f8d888c610bd3565b8152602001610b5f8d878c610bd3565b8152602001610b6f8d8d8c6106ed565b815260200183600001516001600160801b031681526020018460e001516001600160801b03168152602001846080015181526020018460a0015181526020018360c0015181526020018360e001518152509050809650505050505050949350505050565b60008060005b8351811461074557610c0586858381518110610bf757610bf7613204565b602002602001015187610892565b610c0f90836131d0565b9150610c1a8161321a565b9050610bd9565b6000610c2e848484611e48565b90506106556040518060400160405280600c81526020016b109bdd5b990814995cdd5b1d60a21b8152508261200c565b601354604051635104ff8360e11b81526001600160401b03831660048201526001600160a01b039091169063a209ff0690602401600060405180830381600087803b158015610cac57600080fd5b505af1158015610cc0573d6000803e3d6000fd5b505060145460009250610ce691506001600160a01b0316602884901c62ffffff1661065c565b8051601680546001600160a01b03199081166001600160a01b03938416179091556040909201516015805490931691161790555050565b6019805461ffff1916610101179055601454601354600091610d5a916001600160a01b0390911690600160a01b90046001600160401b03166103ef565b9050610da0816020015163ffffffff166000141560405180604001604052806014815260200173141bdbdb081b9bdd081a5b9a5d1a585b1a5e995960621b8152506120a6565b610df08160c001516001600160801b0316600014156040518060400160405280601d81526020017f506f6f6c206e6f742063726561746564207769746820612070726963650000008152506120a6565b6014546013546040516344c9790560e11b8152600160a01b9091046001600160401b03166004820152600f84900b60248201526001600160a01b0390911690638992f20a906044016040805180830381865afa158015610e54573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610e78919061337d565b6001600160801b03908116601855166017556014546016546040516304dc68a960e41b81526001600160a01b039182166004820152911690634dc68a9090602401602060405180830381865afa158015610ed6573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610efa91906131a1565b601a556014546015546040516304dc68a960e41b81526001600160a01b039182166004820152911690634dc68a9090602401602060405180830381865afa158015610f49573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610f6d91906131a1565b601b81905550610fb86000601a5412156040518060400160405280601981526020017f6e656761746976652d6e65742d61737365742d746f6b656e73000000000000008152506120a6565b610ffd6000601b5412156040518060400160405280601981526020017f6e656761746976652d6e65742d71756f74652d746f6b656e73000000000000008152506120a6565b60145460165461101b916001600160a01b0390811691309116610892565b601e5560145460155461103c916001600160a01b0390811691309116610892565b601f55601754601a541161105f57601a5460175461105a91906133b0565b611062565b60005b602055601854601b541161108557601b5460185461108091906133b0565b611088565b60005b602155602054601e54116110ab57601e546020546110a691906133b0565b6110ae565b60005b602055602154601f54116110d157601f546021546110cc91906133b0565b6110d4565b60005b6021556020546000036110ec576019805460ff191690555b602154600003611102576019805461ff00191690555b60195460ff1615611176576016546020546040516340c10f1960e01b815230600482015260248101919091526001600160a01b03909116906340c10f1990604401600060405180830381600087803b15801561115d57600080fd5b505af1158015611171573d6000803e3d6000fd5b505050505b601954610100900460ff16156111ef576015546021546040516340c10f1960e01b815230600482015260248101919091526001600160a01b03909116906340c10f1990604401600060405180830381600087803b1580156111d657600080fd5b505af11580156111ea573d6000803e3d6000fd5b505050505b6111f76120eb565b8051602255602081015160235560408082015160249081556060830151602555608083015160265560a083015160275560c083015160285560e0830151602955610100830151602a55610120830151602b55610140830151602c55610160830151602d5561018090920151602e556014546013549151632c0f890360e01b8152600160a01b9092046001600160401b031660048301529181018490526001600160a01b0390911690632c0f89039060440160408051808303816000875af11580156112c6573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906112ea91906133c7565b601d55601c556112f86120eb565b8051602f556020808201516030556040808301516031556060830151603255608083015160335560a083015160345560c083015160355560e0830151603655610100830151603755610120830151603855610140830151603955610160830151603a5561018090920151603b55601c546017548351808501909452601084526f1c1bdbdb0b59195b1d184b585cdcd95d60821b9284019290925261139e92909190612188565b6113d5601d546018546040518060400160405280601081526020016f706f6f6c2d64656c74612d71756f746560801b815250612188565b603754602a5461141d91906113eb9085906131d0565b60405180604001604052806014815260200173706f6f6c2d746f74616c2d6c697175696469747960601b815250612188565b611468602260080154602f60080154116040518060400160405280601881526020017f706f6f6c2d6c69717569646974792d696e6372656173657300000000000000008152506120a6565b6036546029546114b9919061147e9085906131d0565b6040518060400160405280601c81526020017f706f736974696f6e2d6c69717569646974792d696e6372656173657300000000815250612188565b602f54601a546020546022546115099392916114d4916131d0565b6114de91906131d0565b6040518060400160405280600d81526020016c1c995cd95c9d994b585cdcd95d609a1b815250612188565b603054601b54602154602354611559939291611524916131d0565b61152e91906131d0565b6040518060400160405280600d81526020016c726573657276652d71756f746560981b815250612188565b60315460205460245461159c9291611570916131d0565b6040518060400160405280600e81526020016d1c1a1e5cda58d85b0b585cdcd95d60921b815250612188565b6032546021546025546115df92916115b3916131d0565b6040518060400160405280600e81526020016d706879736963616c2d71756f746560901b815250612188565b602d54603a546000916115f1916133b0565b602b5460385491925060009161160791906133b0565b90506116398183146040518060400160405280600c81526020016b0c2e6e6cae85acee4deeee8d60a31b8152506120a6565b602e54603b5460009161164b916133b0565b602c5460395491925060009161166191906133b0565b90506116938183146040518060400160405280600c81526020016b0e2eadee8ca5acee4deeee8d60a31b8152506120a6565b7f266e5337533f2620683681410ac0b3ed8c4c53b7b0bb5524400a2e477a410de66040516116dd90602080825260089082015267416c6c6f6361746560c01b604082015260600190565b60405180910390a16116ed6121d5565b505050505050565b604080516001600160a01b0383811660248084019190915283518084039091018152604490920183526020820180516001600160e01b03166370a0823160e01b1790529151600092839283929187169161174f9190613294565b600060405180830381855afa9150503d806000811461178a576040519150601f19603f3d011682016040523d82523d6000602084013e61178f565b606091505b50915091508115806117a357508051602014155b156117c15760405163c52e3eff60e01b815260040160405180910390fd5b808060200190518101906117d591906131a1565b95945050505050565b60145460135460009161180e916001600160a01b03909116903090600160a01b90046001600160401b0316610960565b90508181600001516001600160801b031610156118695760405162461bcd60e51b81526020600482015260146024820152734e6f7420656e6f756768206c697175696469747960601b60448201526064015b60405180910390fd5b80516001600160801b03168211611dec576014546013546000916118a8916001600160a01b0390911690600160a01b90046001600160401b03166103ef565b90506118ee816020015163ffffffff166000141560405180604001604052806014815260200173141bdbdb081b9bdd081a5b9a5d1a585b1a5e995960621b8152506120a6565b61193e8160c001516001600160801b0316600014156040518060400160405280601d81526020017f506f6f6c206e6f742063726561746564207769746820612070726963650000008152506120a6565b600061194b4260046131d0565b6040516372eb5f8160e11b815260048101829052909150737109709ecfa91a80626ff3989d68f67f5b1dd12d9063e5d6bf0290602401600060405180830381600087803b15801561199b57600080fd5b505af11580156119af573d6000803e3d6000fd5b505060145460405163f740485b60e01b81526001600160801b03851660048201526001600160a01b03909116925063f740485b9150602401600060405180830381600087803b158015611a0157600080fd5b505af1158015611a15573d6000803e3d6000fd5b50506014546013546001600160a01b039091169250638992f20a9150600160a01b90046001600160401b0316611a4a876133eb565b6040516001600160e01b031960e085901b1681526001600160401b039092166004830152600f0b60248201526044016040805180830381865afa158015611a95573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190611ab9919061337d565b6001600160801b0390811660185516601755611ad36120eb565b8051602255602081015160235560408082015160249081556060830151602555608083015160265560a083015160275560c083015160285560e0830151602955610100830151602a55610120830151602b55610140830151602c55610160830151602d5561018090920151602e556014546013549151635e7bc52d60e11b8152600160a01b9092046001600160401b0316600483015291810186905260009182916001600160a01b039091169063bcf78a5a9060440160408051808303816000875af1158015611ba7573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190611bcb91906133c7565b915091506000611bd96120eb565b9050611c0b836017546040518060400160405280600b81526020016a61737365742d64656c746160a81b815250612188565b611c3b826018546040518060400160405280600b81526020016a71756f74652d64656c746160a81b815250612188565b8051602254611c5091906114de9086906133b0565b611c6981602001518360226001015461152e91906133b0565b611cb081610100015188602260080154611c8391906133b0565b6040518060400160405280600f81526020016e746f74616c2d6c697175696469747960881b815250612188565b611cf78760226006015410156040518060400160405280601781526020017f746f74616c2d706f732d6c69712d756e646572666c6f770000000000000000008152506120a6565b611d3e8760226007015410156040518060400160405280601881526020017f63616c6c65722d706f732d6c69712d756e646572666c6f7700000000000000008152506120a6565b611d928160c0015188602260060154611d5791906133b0565b6040518060400160405280601881526020017f746f74616c2d706f736974696f6e2d6c69717569646974790000000000000000815250612188565b611de68160e0015188602260070154611dab91906133b0565b6040518060400160405280601981526020017f63616c6c65722d706f736974696f6e2d6c697175696469747900000000000000815250612188565b50505050505b7f266e5337533f2620683681410ac0b3ed8c4c53b7b0bb5524400a2e477a410de6604051611e38906020808252600a9082015269556e616c6c6f6361746560b01b604082015260600190565b60405180910390a16105b16121d5565b600081831115611ec05760405162461bcd60e51b815260206004820152603e60248201527f5374645574696c7320626f756e642875696e743235362c75696e743235362c7560448201527f696e74323536293a204d6178206973206c657373207468616e206d696e2e00006064820152608401611860565b828410158015611ed05750818411155b15611edc575082610655565b6000611ee884846133b0565b611ef39060016131d0565b905060038511158015611f0557508481115b15611f1c57611f1485856131d0565b915050610655565b611f2960036000196133b0565b8510158015611f425750611f3f856000196133b0565b81115b15611f5d57611f53856000196133b0565b611f1490846133b0565b82851115611fb3576000611f7184876133b0565b90506000611f7f838361341a565b905080600003611f9457849350505050610655565b6001611fa082886131d0565b611faa91906133b0565b93505050612004565b83851015612004576000611fc786866133b0565b90506000611fd5838361341a565b905080600003611fea57859350505050610655565b611ff481866133b0565b611fff9060016131d0565b935050505b509392505050565b60006a636f6e736f6c652e6c6f676001600160a01b03168383604051602401612036929190613468565b60408051601f198184030181529181526020820180516001600160e01b0316632d839cb360e21b1790525161206b9190613294565b600060405180830381855afa9150503d80600081146116ed576040519150601f19603f3d011682016040523d82523d6000602084013e6116ed565b816105b1577f280f4446b28a1372417dda658d30b95b2992b12ac9c7f378535f29a97acf3583816040516120da919061348a565b60405180910390a16105b1826125a9565b6120f361284f565b6014546013546040805163f202027560e01b81529051612183936001600160a01b03908116936001600160401b03600160a01b820416933093919092169163f20202759160048083019260009291908290030181865afa15801561215b573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f1916820160405261033791908101906134b9565b905090565b8183146121d0577f280f4446b28a1372417dda658d30b95b2992b12ac9c7f378535f29a97acf3583816040516121be919061348a565b60405180910390a16121d08383612620565b505050565b601454601354600091612203916001600160a01b0390911690600160a01b90046001600160401b03166103ef565b6014546013546040516317bc16c360e21b8152600160a01b9091046001600160401b0316600482015291925060009182916001600160a01b031690635ef05b0c906024016040805180830381865afa158015612263573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190612287919061337d565b6001600160801b031691506001600160801b03169150600080516020613592833981519152826040516122dd919060408082526006908201526519105cdcd95d60d21b6060820152602081019190915260800190565b60405180910390a160408051818152600681830152656451756f746560d01b60608201526020810183905290516000805160206135928339815191529181900360800190a1601454601654600091612341916001600160a01b039182169116610623565b601454601554919250600091612363916001600160a01b039081169116610623565b9050600080516020613592833981519152826040516123a5919060408082526006908201526518905cdcd95d60d21b6060820152602081019190915260800190565b60405180910390a160408051818152600681830152656251756f746560d01b60608201526020810183905290516000805160206135928339815191529181900360800190a160006123f68584613552565b905060006124048584613552565b90507f3ca6268e2d626deb26c45bf74aa3316f24594d4f4b66b5d8fd8e966d88ac4e258260405161245b9190604080825260099082015268191a5999905cdcd95d60ba1b6060820152602081019190915260800190565b60405180910390a160408051818152600981830152686469666651756f746560b81b60608201526020810183905290517f3ca6268e2d626deb26c45bf74aa3316f24594d4f4b66b5d8fd8e966d88ac4e259181900360800190a16124f7868510156040518060400160405280602081526020017f696e76617269616e742d7669727475616c2d72657365727665732d61737365748152506120a6565b612539858410156040518060400160405280602081526020017f696e76617269616e742d7669727475616c2d72657365727665732d71756f74658152506120a6565b7f266e5337533f2620683681410ac0b3ed8c4c53b7b0bb5524400a2e477a410de66040516125989060208082526017908201527f436865636b205669727475616c20496e76617269616e74000000000000000000604082015260600190565b60405180910390a150505050505050565b8061261d577f41304facd9323d75b11bcdd609cb38effffdb05710f7caf0e9b16c6d9d709f5060405161260d9060208082526017908201527f4572726f723a20417373657274696f6e204661696c6564000000000000000000604082015260600190565b60405180910390a161261d612743565b50565b8082146105b1577f41304facd9323d75b11bcdd609cb38effffdb05710f7caf0e9b16c6d9d709f506040516126919060208082526022908201527f4572726f723a2061203d3d2062206e6f7420736174697366696564205b75696e604082015261745d60f01b606082015260800190565b60405180910390a160408051818152600a81830152690808115e1c1958dd195960b21b60608201526020810183905290517fb2de2fbe801a0df6c0cbddfd448ba3c41d48a040ca35c56c8196ef0fcae721a89181900360800190a160408051818152600a8183015269080808081058dd1d585b60b21b60608201526020810184905290517fb2de2fbe801a0df6c0cbddfd448ba3c41d48a040ca35c56c8196ef0fcae721a89181900360800190a16105b15b737109709ecfa91a80626ff3989d68f67f5b1dd12d3b1561283e5760408051737109709ecfa91a80626ff3989d68f67f5b1dd12d602082018190526519985a5b195960d21b9282019290925260016060820152600091907f70ca10bbd0dbfd9020a9f4b13402c16cb120705e0d1c0aeab10fa353ae586fc49060800160408051601f19818403018152908290526127dd9291602001613263565b60408051601f19818403018152908290526127f791613294565b6000604051808303816000865af19150503d8060008114612834576040519150601f19603f3d011682016040523d82523d6000602084013e612839565b606091505b505050505b6000805461ff001916610100179055565b604051806101a00160405280600081526020016000815260200160008152602001600081526020016000815260200160008152602001600081526020016000815260200160008152602001600081526020016000815260200160008152602001600081525090565b6001600160a01b038116811461261d57600080fd5b6001600160401b038116811461261d57600080fd5b600080604083850312156128f457600080fd5b82356128ff816128b7565b9150602083013561290f816128cc565b809150509250929050565b805160020b8252602081015161ffff80821660208501528060408401511660408501528060608401511660608501528060808401511660808501528060a08401511660a0850152505063ffffffff60c08201511660c08301525050565b815160020b81526102a08101602083015161299a602084018263ffffffff169052565b5060408301516129b560408401826001600160a01b03169052565b50606083015160608301526080830151608083015260a083015160a083015260c08301516129ee60c08401826001600160801b03169052565b5060e0830151612a0960e08401826001600160801b03169052565b50610100838101516001600160801b03169083015261012080840151600f0b9083015261014080840151612a3f8285018261291a565b505061016083015180516001600160a01b03908116610220850152602082015160ff90811661024086015260408301519091166102608501526060820151166102808401525092915050565b60008060408385031215612a9e57600080fd5b50508035926020909101359150565b60008060408385031215612ac057600080fd5b8235612acb816128b7565b9150602083013561290f816128b7565b634e487b7160e01b600052604160045260246000fd5b60405161018081016001600160401b0381118282101715612b1457612b14612adb565b60405290565b60405161016081016001600160401b0381118282101715612b1457612b14612adb565b604051601f8201601f191681016001600160401b0381118282101715612b6557612b65612adb565b604052919050565b60006001600160401b03821115612b8657612b86612adb565b5060051b60200190565b600082601f830112612ba157600080fd5b81356020612bb6612bb183612b6d565b612b3d565b82815260059290921b84018101918181019086841115612bd557600080fd5b8286015b84811015612bf9578035612bec816128b7565b8352918301918301612bd9565b509695505050505050565b600080600060608486031215612c1957600080fd5b8335612c24816128b7565b92506020840135612c34816128b7565b915060408401356001600160401b03811115612c4f57600080fd5b612c5b86828701612b90565b9150509250925092565b60008060408385031215612c7857600080fd5b8235612c83816128b7565b9150602083013562ffffff8116811461290f57600080fd5b60808101610518828460018060a01b0380825116835260ff60208301511660208401528060408301511660408401525060ff60608201511660608301525050565b600080600060608486031215612cf157600080fd5b8335612cfc816128b7565b92506020840135612c34816128cc565b801515811461261d57600080fd5b600060208284031215612d2c57600080fd5b813561065581612d0c565b600080600060608486031215612d4c57600080fd5b8335612d57816128b7565b92506020840135612d67816128b7565b91506040840135612d77816128b7565b809150509250925092565b60e08101610518828461291a565b600080600060608486031215612da557600080fd5b8335612db0816128b7565b92506020840135612dc0816128b7565b91506040840135612d77816128cc565b81516001600160801b0316815261016081016020830151612dfc60208401826001600160801b03169052565b5060408301516040830152606083015160608301526080830151608083015260a083015160a083015260c083015160c083015260e083015160e083015261010080840151612e54828501826001600160801b03169052565b5050610120838101516001600160801b03908116918401919091526101409384015116929091019190915290565b60008060008060808587031215612e9857600080fd5b8435612ea3816128b7565b93506020850135612eb3816128cc565b92506040850135612ec3816128b7565b915060608501356001600160401b03811115612ede57600080fd5b612eea87828801612b90565b91505092959194509250565b8051600281900b811461087457600080fd5b805163ffffffff8116811461087457600080fd5b8051610874816128b7565b80516001600160801b038116811461087457600080fd5b8051600f81900b811461087457600080fd5b805161ffff8116811461087457600080fd5b600060e08284031215612f7457600080fd5b60405160e081018181106001600160401b0382111715612f9657612f96612adb565b604052905080612fa583612ef6565b8152612fb360208401612f50565b6020820152612fc460408401612f50565b6040820152612fd560608401612f50565b6060820152612fe660808401612f50565b6080820152612ff760a08401612f50565b60a082015261300860c08401612f08565b60c08201525092915050565b805160ff8116811461087457600080fd5b60006080828403121561303757600080fd5b604051608081018181106001600160401b038211171561305957613059612adb565b8060405250809150825161306c816128b7565b815261307a60208401613014565b6020820152604083015161308d816128b7565b604082015261309e60608401613014565b60608201525092915050565b60006102a082840312156130bd57600080fd5b6130c5612af1565b6130ce83612ef6565b81526130dc60208401612f08565b60208201526130ed60408401612f1c565b6040820152606083015160608201526080830151608082015260a083015160a082015261311c60c08401612f27565b60c082015261312d60e08401612f27565b60e0820152610100613140818501612f27565b90820152610120613152848201612f3e565b9082015261014061316585858301612f62565b90820152613177846102208501613025565b6101608201529392505050565b60006020828403121561319657600080fd5b8151610655816128cc565b6000602082840312156131b357600080fd5b5051919050565b634e487b7160e01b600052601160045260246000fd5b600082198211156131e3576131e36131ba565b500190565b6000608082840312156131fa57600080fd5b6105158383613025565b634e487b7160e01b600052603260045260246000fd5b60006001820161322c5761322c6131ba565b5060010190565b60005b8381101561324e578181015183820152602001613236565b8381111561325d576000848401525b50505050565b6001600160e01b0319831681528151600090613286816004850160208701613233565b919091016004019392505050565b600082516132a6818460208701613233565b9190910192915050565b6000602082840312156132c257600080fd5b815161065581612d0c565b600061016082840312156132e057600080fd5b6132e8612b1a565b6132f183612f27565b81526132ff60208401612f27565b602082015260408301516040820152606083015160608201526080830151608082015260a083015160a082015260c083015160c082015260e083015160e082015261010061334e818501612f27565b90820152610120613360848201612f27565b90820152610140613372848201612f27565b908201529392505050565b6000806040838503121561339057600080fd5b61339983612f27565b91506133a760208401612f27565b90509250929050565b6000828210156133c2576133c26131ba565b500390565b600080604083850312156133da57600080fd5b505080516020909101519092909150565b600081600f0b6f7fffffffffffffffffffffffffffffff198103613411576134116131ba565b60000392915050565b60008261343757634e487b7160e01b600052601260045260246000fd5b500690565b60008151808452613454816020860160208601613233565b601f01601f19169290920160200192915050565b60408152600061347b604083018561343c565b90508260208301529392505050565b60408152600560408201526422b93937b960d91b6060820152608060208201526000610515608083018461343c565b600060208083850312156134cc57600080fd5b82516001600160401b038111156134e257600080fd5b8301601f810185136134f357600080fd5b8051613501612bb182612b6d565b81815260059190911b8201830190838101908783111561352057600080fd5b928401925b82841015613547578351613538816128b7565b82529284019290840190613525565b979650505050505050565b60008083128015600160ff1b850184121615613570576135706131ba565b6001600160ff1b038401831381161561358b5761358b6131ba565b5050039056feb60e72ccf6d57ab53eb84d7e94a9545806ed7f93c4d5673f11a64f03471e584ea264697066735822122075c5f7db30aedc81ab6b97230b9acbbe94a3a40894d40ccb0e1e290f4642117264736f6c634300080d0033"
            .parse()
            .expect("invalid bytecode")
    });
    pub struct InvariantAllocateUnallocate<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for InvariantAllocateUnallocate<M> {
        fn clone(&self) -> Self {
            InvariantAllocateUnallocate(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for InvariantAllocateUnallocate<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for InvariantAllocateUnallocate<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(InvariantAllocateUnallocate))
                .field(&self.address())
                .finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> InvariantAllocateUnallocate<M> {
        /// Creates a new contract instance with the specified `ethers`
        /// client at the given `Address`. The contract derefs to a `ethers::Contract`
        /// object
        pub fn new<T: Into<::ethers::core::types::Address>>(
            address: T,
            client: ::std::sync::Arc<M>,
        ) -> Self {
            Self(::ethers::contract::Contract::new(
                address.into(),
                INVARIANTALLOCATEUNALLOCATE_ABI.clone(),
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
                INVARIANTALLOCATEUNALLOCATE_ABI.clone(),
                INVARIANTALLOCATEUNALLOCATE_BYTECODE.clone().into(),
                client,
            );
            let deployer = factory.deploy(constructor_args)?;
            let deployer = ::ethers::contract::ContractDeployer::new(deployer);
            Ok(deployer)
        }
        ///Calls the contract's `IS_TEST` (0xfa7626d4) function
        pub fn is_test(&self) -> ::ethers::contract::builders::ContractCall<M, bool> {
            self.0
                .method_hash([250, 118, 38, 212], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `__asset__` (0xd43c0f99) function
        pub fn asset(
            &self,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::Address> {
            self.0
                .method_hash([212, 60, 15, 153], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `__hyper__` (0x3e81296e) function
        pub fn hyper(
            &self,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::Address> {
            self.0
                .method_hash([62, 129, 41, 110], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `__poolId__` (0xc6a68a47) function
        pub fn pool_id(&self) -> ::ethers::contract::builders::ContractCall<M, u64> {
            self.0
                .method_hash([198, 166, 138, 71], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `__quote__` (0x8dbc9651) function
        pub fn quote(
            &self,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::Address> {
            self.0
                .method_hash([141, 188, 150, 81], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `_getBalance` (0xcf7dee1f) function
        pub fn _get_balance(
            &self,
            hyper: ::ethers::core::types::Address,
            owner: ::ethers::core::types::Address,
            token: ::ethers::core::types::Address,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([207, 125, 238, 31], (hyper, owner, token))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `_getPool` (0x09deb4d3) function
        pub fn _get_pool(
            &self,
            hyper: ::ethers::core::types::Address,
            pool_id: u64,
        ) -> ::ethers::contract::builders::ContractCall<M, HyperPool> {
            self.0
                .method_hash([9, 222, 180, 211], (hyper, pool_id))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `_getPosition` (0xdc723804) function
        pub fn _get_position(
            &self,
            hyper: ::ethers::core::types::Address,
            owner: ::ethers::core::types::Address,
            position_id: u64,
        ) -> ::ethers::contract::builders::ContractCall<M, HyperPosition> {
            self.0
                .method_hash([220, 114, 56, 4], (hyper, owner, position_id))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `_getReserve` (0x5a8be8b0) function
        pub fn _get_reserve(
            &self,
            hyper: ::ethers::core::types::Address,
            token: ::ethers::core::types::Address,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([90, 139, 232, 176], (hyper, token))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `allocate` (0x172cfa4c) function
        pub fn allocate(
            &self,
            delta_liquidity: ::ethers::core::types::U256,
            index: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([23, 44, 250, 76], (delta_liquidity, index))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `failed` (0xba414fa6) function
        pub fn failed(&self) -> ::ethers::contract::builders::ContractCall<M, bool> {
            self.0
                .method_hash([186, 65, 79, 166], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getBalance` (0xd6bd603c) function
        pub fn get_balance(
            &self,
            hyper: ::ethers::core::types::Address,
            owner: ::ethers::core::types::Address,
            token: ::ethers::core::types::Address,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([214, 189, 96, 60], (hyper, owner, token))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getBalanceSum` (0xff314c0a) function
        pub fn get_balance_sum(
            &self,
            hyper: ::ethers::core::types::Address,
            token: ::ethers::core::types::Address,
            owners: ::std::vec::Vec<::ethers::core::types::Address>,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([255, 49, 76, 10], (hyper, token, owners))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getCurve` (0xd83410b6) function
        pub fn get_curve(
            &self,
            hyper: ::ethers::core::types::Address,
            pool_id: u64,
        ) -> ::ethers::contract::builders::ContractCall<M, HyperCurve> {
            self.0
                .method_hash([216, 52, 16, 182], (hyper, pool_id))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getMaxSwapLimit` (0xcee2aaf5) function
        pub fn get_max_swap_limit(
            &self,
            sell_asset: bool,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([206, 226, 170, 245], sell_asset)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getPair` (0x7b135ad1) function
        pub fn get_pair(
            &self,
            hyper: ::ethers::core::types::Address,
            pair_id: u32,
        ) -> ::ethers::contract::builders::ContractCall<M, HyperPair> {
            self.0
                .method_hash([123, 19, 90, 209], (hyper, pair_id))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getPhysicalBalance` (0x634e05e0) function
        pub fn get_physical_balance(
            &self,
            hyper: ::ethers::core::types::Address,
            token: ::ethers::core::types::Address,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([99, 78, 5, 224], (hyper, token))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getPool` (0x273c329f) function
        pub fn get_pool(
            &self,
            hyper: ::ethers::core::types::Address,
            pool_id: u64,
        ) -> ::ethers::contract::builders::ContractCall<M, HyperPool> {
            self.0
                .method_hash([39, 60, 50, 159], (hyper, pool_id))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getPosition` (0xdd05e299) function
        pub fn get_position(
            &self,
            hyper: ::ethers::core::types::Address,
            owner: ::ethers::core::types::Address,
            position_id: u64,
        ) -> ::ethers::contract::builders::ContractCall<M, HyperPosition> {
            self.0
                .method_hash([221, 5, 226, 153], (hyper, owner, position_id))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getPositionLiquiditySum` (0x8828200d) function
        pub fn get_position_liquidity_sum(
            &self,
            hyper: ::ethers::core::types::Address,
            pool_id: u64,
            owners: ::std::vec::Vec<::ethers::core::types::Address>,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([136, 40, 32, 13], (hyper, pool_id, owners))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getReserve` (0xcbc3ab53) function
        pub fn get_reserve(
            &self,
            hyper: ::ethers::core::types::Address,
            token: ::ethers::core::types::Address,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([203, 195, 171, 83], (hyper, token))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getState` (0xf3140b1e) function
        pub fn get_state(
            &self,
            hyper: ::ethers::core::types::Address,
            pool_id: u64,
            caller: ::ethers::core::types::Address,
            owners: ::std::vec::Vec<::ethers::core::types::Address>,
        ) -> ::ethers::contract::builders::ContractCall<M, HyperState> {
            self.0
                .method_hash([243, 20, 11, 30], (hyper, pool_id, caller, owners))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getVirtualBalance` (0x6dce537d) function
        pub fn get_virtual_balance(
            &self,
            hyper: ::ethers::core::types::Address,
            token: ::ethers::core::types::Address,
            owners: ::std::vec::Vec<::ethers::core::types::Address>,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([109, 206, 83, 125], (hyper, token, owners))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `unallocate` (0xe179eed6) function
        pub fn unallocate(
            &self,
            delta_liquidity: ::ethers::core::types::U256,
            index: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([225, 121, 238, 214], (delta_liquidity, index))
                .expect("method not found (this should never happen)")
        }
        ///Gets the contract's `FinishedCall` event
        pub fn finished_call_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, FinishedCallFilter> {
            self.0.event()
        }
        ///Gets the contract's `log` event
        pub fn log_1_filter(&self) -> ::ethers::contract::builders::Event<M, Log1Filter> {
            self.0.event()
        }
        ///Gets the contract's `log` event
        pub fn log_2_filter(&self) -> ::ethers::contract::builders::Event<M, Log2Filter> {
            self.0.event()
        }
        ///Gets the contract's `log` event
        pub fn log_3_filter(&self) -> ::ethers::contract::builders::Event<M, Log3Filter> {
            self.0.event()
        }
        ///Gets the contract's `log_address` event
        pub fn log_address_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogAddressFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_array` event
        pub fn log_array_1_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogArray1Filter> {
            self.0.event()
        }
        ///Gets the contract's `log_array` event
        pub fn log_array_2_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogArray2Filter> {
            self.0.event()
        }
        ///Gets the contract's `log_array` event
        pub fn log_array_3_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogArray3Filter> {
            self.0.event()
        }
        ///Gets the contract's `log_bytes` event
        pub fn log_bytes_filter(&self) -> ::ethers::contract::builders::Event<M, LogBytesFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_bytes32` event
        pub fn log_bytes_32_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogBytes32Filter> {
            self.0.event()
        }
        ///Gets the contract's `log_int` event
        pub fn log_int_filter(&self) -> ::ethers::contract::builders::Event<M, LogIntFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_named_address` event
        pub fn log_named_address_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogNamedAddressFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_named_array` event
        pub fn log_named_array_1_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogNamedArray1Filter> {
            self.0.event()
        }
        ///Gets the contract's `log_named_array` event
        pub fn log_named_array_2_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogNamedArray2Filter> {
            self.0.event()
        }
        ///Gets the contract's `log_named_array` event
        pub fn log_named_array_3_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogNamedArray3Filter> {
            self.0.event()
        }
        ///Gets the contract's `log_named_bytes` event
        pub fn log_named_bytes_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogNamedBytesFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_named_bytes32` event
        pub fn log_named_bytes_32_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogNamedBytes32Filter> {
            self.0.event()
        }
        ///Gets the contract's `log_named_decimal_int` event
        pub fn log_named_decimal_int_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogNamedDecimalIntFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_named_decimal_uint` event
        pub fn log_named_decimal_uint_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogNamedDecimalUintFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_named_int` event
        pub fn log_named_int_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogNamedIntFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_named_string` event
        pub fn log_named_string_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogNamedStringFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_named_uint` event
        pub fn log_named_uint_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogNamedUintFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_string` event
        pub fn log_string_filter(&self) -> ::ethers::contract::builders::Event<M, LogStringFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_uint` event
        pub fn log_uint_filter(&self) -> ::ethers::contract::builders::Event<M, LogUintFilter> {
            self.0.event()
        }
        ///Gets the contract's `logs` event
        pub fn logs_filter(&self) -> ::ethers::contract::builders::Event<M, LogsFilter> {
            self.0.event()
        }
        /// Returns an [`Event`](#ethers_contract::builders::Event) builder for all events of this contract
        pub fn events(
            &self,
        ) -> ::ethers::contract::builders::Event<M, InvariantAllocateUnallocateEvents> {
            self.0.event_with_filter(Default::default())
        }
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>>
        for InvariantAllocateUnallocate<M>
    {
        fn from(contract: ::ethers::contract::Contract<M>) -> Self {
            Self::new(contract.address(), contract.client())
        }
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
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "FinishedCall", abi = "FinishedCall(string)")]
    pub struct FinishedCallFilter(pub String);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "log", abi = "log(string,uint256)")]
    pub struct Log1Filter(pub String, pub ::ethers::core::types::U256);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "log", abi = "log(string,int256)")]
    pub struct Log2Filter(pub String, pub ::ethers::core::types::I256);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "log", abi = "log(string)")]
    pub struct Log3Filter(pub String);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "log_address", abi = "log_address(address)")]
    pub struct LogAddressFilter(pub ::ethers::core::types::Address);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "log_array", abi = "log_array(uint256[])")]
    pub struct LogArray1Filter {
        pub val: Vec<::ethers::core::types::U256>,
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
    #[ethevent(name = "log_array", abi = "log_array(int256[])")]
    pub struct LogArray2Filter {
        pub val: Vec<::ethers::core::types::I256>,
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
    #[ethevent(name = "log_array", abi = "log_array(address[])")]
    pub struct LogArray3Filter {
        pub val: Vec<::ethers::core::types::Address>,
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
    #[ethevent(name = "log_bytes", abi = "log_bytes(bytes)")]
    pub struct LogBytesFilter(pub ::ethers::core::types::Bytes);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "log_bytes32", abi = "log_bytes32(bytes32)")]
    pub struct LogBytes32Filter(pub [u8; 32]);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "log_int", abi = "log_int(int256)")]
    pub struct LogIntFilter(pub ::ethers::core::types::I256);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "log_named_address", abi = "log_named_address(string,address)")]
    pub struct LogNamedAddressFilter {
        pub key: String,
        pub val: ::ethers::core::types::Address,
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
    #[ethevent(name = "log_named_array", abi = "log_named_array(string,uint256[])")]
    pub struct LogNamedArray1Filter {
        pub key: String,
        pub val: Vec<::ethers::core::types::U256>,
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
    #[ethevent(name = "log_named_array", abi = "log_named_array(string,int256[])")]
    pub struct LogNamedArray2Filter {
        pub key: String,
        pub val: Vec<::ethers::core::types::I256>,
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
    #[ethevent(name = "log_named_array", abi = "log_named_array(string,address[])")]
    pub struct LogNamedArray3Filter {
        pub key: String,
        pub val: Vec<::ethers::core::types::Address>,
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
    #[ethevent(name = "log_named_bytes", abi = "log_named_bytes(string,bytes)")]
    pub struct LogNamedBytesFilter {
        pub key: String,
        pub val: ::ethers::core::types::Bytes,
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
    #[ethevent(name = "log_named_bytes32", abi = "log_named_bytes32(string,bytes32)")]
    pub struct LogNamedBytes32Filter {
        pub key: String,
        pub val: [u8; 32],
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
        name = "log_named_decimal_int",
        abi = "log_named_decimal_int(string,int256,uint256)"
    )]
    pub struct LogNamedDecimalIntFilter {
        pub key: String,
        pub val: ::ethers::core::types::I256,
        pub decimals: ::ethers::core::types::U256,
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
        name = "log_named_decimal_uint",
        abi = "log_named_decimal_uint(string,uint256,uint256)"
    )]
    pub struct LogNamedDecimalUintFilter {
        pub key: String,
        pub val: ::ethers::core::types::U256,
        pub decimals: ::ethers::core::types::U256,
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
    #[ethevent(name = "log_named_int", abi = "log_named_int(string,int256)")]
    pub struct LogNamedIntFilter {
        pub key: String,
        pub val: ::ethers::core::types::I256,
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
    #[ethevent(name = "log_named_string", abi = "log_named_string(string,string)")]
    pub struct LogNamedStringFilter {
        pub key: String,
        pub val: String,
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
    #[ethevent(name = "log_named_uint", abi = "log_named_uint(string,uint256)")]
    pub struct LogNamedUintFilter {
        pub key: String,
        pub val: ::ethers::core::types::U256,
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
    #[ethevent(name = "log_string", abi = "log_string(string)")]
    pub struct LogStringFilter(pub String);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "log_uint", abi = "log_uint(uint256)")]
    pub struct LogUintFilter(pub ::ethers::core::types::U256);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "logs", abi = "logs(bytes)")]
    pub struct LogsFilter(pub ::ethers::core::types::Bytes);
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum InvariantAllocateUnallocateEvents {
        FinishedCallFilter(FinishedCallFilter),
        Log1Filter(Log1Filter),
        Log2Filter(Log2Filter),
        Log3Filter(Log3Filter),
        LogAddressFilter(LogAddressFilter),
        LogArray1Filter(LogArray1Filter),
        LogArray2Filter(LogArray2Filter),
        LogArray3Filter(LogArray3Filter),
        LogBytesFilter(LogBytesFilter),
        LogBytes32Filter(LogBytes32Filter),
        LogIntFilter(LogIntFilter),
        LogNamedAddressFilter(LogNamedAddressFilter),
        LogNamedArray1Filter(LogNamedArray1Filter),
        LogNamedArray2Filter(LogNamedArray2Filter),
        LogNamedArray3Filter(LogNamedArray3Filter),
        LogNamedBytesFilter(LogNamedBytesFilter),
        LogNamedBytes32Filter(LogNamedBytes32Filter),
        LogNamedDecimalIntFilter(LogNamedDecimalIntFilter),
        LogNamedDecimalUintFilter(LogNamedDecimalUintFilter),
        LogNamedIntFilter(LogNamedIntFilter),
        LogNamedStringFilter(LogNamedStringFilter),
        LogNamedUintFilter(LogNamedUintFilter),
        LogStringFilter(LogStringFilter),
        LogUintFilter(LogUintFilter),
        LogsFilter(LogsFilter),
    }
    impl ::ethers::contract::EthLogDecode for InvariantAllocateUnallocateEvents {
        fn decode_log(
            log: &::ethers::core::abi::RawLog,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::Error>
        where
            Self: Sized,
        {
            if let Ok(decoded) = FinishedCallFilter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::FinishedCallFilter(
                    decoded,
                ));
            }
            if let Ok(decoded) = Log1Filter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::Log1Filter(decoded));
            }
            if let Ok(decoded) = Log2Filter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::Log2Filter(decoded));
            }
            if let Ok(decoded) = Log3Filter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::Log3Filter(decoded));
            }
            if let Ok(decoded) = LogAddressFilter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::LogAddressFilter(decoded));
            }
            if let Ok(decoded) = LogArray1Filter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::LogArray1Filter(decoded));
            }
            if let Ok(decoded) = LogArray2Filter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::LogArray2Filter(decoded));
            }
            if let Ok(decoded) = LogArray3Filter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::LogArray3Filter(decoded));
            }
            if let Ok(decoded) = LogBytesFilter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::LogBytesFilter(decoded));
            }
            if let Ok(decoded) = LogBytes32Filter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::LogBytes32Filter(decoded));
            }
            if let Ok(decoded) = LogIntFilter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::LogIntFilter(decoded));
            }
            if let Ok(decoded) = LogNamedAddressFilter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::LogNamedAddressFilter(
                    decoded,
                ));
            }
            if let Ok(decoded) = LogNamedArray1Filter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::LogNamedArray1Filter(
                    decoded,
                ));
            }
            if let Ok(decoded) = LogNamedArray2Filter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::LogNamedArray2Filter(
                    decoded,
                ));
            }
            if let Ok(decoded) = LogNamedArray3Filter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::LogNamedArray3Filter(
                    decoded,
                ));
            }
            if let Ok(decoded) = LogNamedBytesFilter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::LogNamedBytesFilter(
                    decoded,
                ));
            }
            if let Ok(decoded) = LogNamedBytes32Filter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::LogNamedBytes32Filter(
                    decoded,
                ));
            }
            if let Ok(decoded) = LogNamedDecimalIntFilter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::LogNamedDecimalIntFilter(
                    decoded,
                ));
            }
            if let Ok(decoded) = LogNamedDecimalUintFilter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::LogNamedDecimalUintFilter(decoded));
            }
            if let Ok(decoded) = LogNamedIntFilter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::LogNamedIntFilter(
                    decoded,
                ));
            }
            if let Ok(decoded) = LogNamedStringFilter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::LogNamedStringFilter(
                    decoded,
                ));
            }
            if let Ok(decoded) = LogNamedUintFilter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::LogNamedUintFilter(
                    decoded,
                ));
            }
            if let Ok(decoded) = LogStringFilter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::LogStringFilter(decoded));
            }
            if let Ok(decoded) = LogUintFilter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::LogUintFilter(decoded));
            }
            if let Ok(decoded) = LogsFilter::decode_log(log) {
                return Ok(InvariantAllocateUnallocateEvents::LogsFilter(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData)
        }
    }
    impl ::std::fmt::Display for InvariantAllocateUnallocateEvents {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                InvariantAllocateUnallocateEvents::FinishedCallFilter(element) => element.fmt(f),
                InvariantAllocateUnallocateEvents::Log1Filter(element) => element.fmt(f),
                InvariantAllocateUnallocateEvents::Log2Filter(element) => element.fmt(f),
                InvariantAllocateUnallocateEvents::Log3Filter(element) => element.fmt(f),
                InvariantAllocateUnallocateEvents::LogAddressFilter(element) => element.fmt(f),
                InvariantAllocateUnallocateEvents::LogArray1Filter(element) => element.fmt(f),
                InvariantAllocateUnallocateEvents::LogArray2Filter(element) => element.fmt(f),
                InvariantAllocateUnallocateEvents::LogArray3Filter(element) => element.fmt(f),
                InvariantAllocateUnallocateEvents::LogBytesFilter(element) => element.fmt(f),
                InvariantAllocateUnallocateEvents::LogBytes32Filter(element) => element.fmt(f),
                InvariantAllocateUnallocateEvents::LogIntFilter(element) => element.fmt(f),
                InvariantAllocateUnallocateEvents::LogNamedAddressFilter(element) => element.fmt(f),
                InvariantAllocateUnallocateEvents::LogNamedArray1Filter(element) => element.fmt(f),
                InvariantAllocateUnallocateEvents::LogNamedArray2Filter(element) => element.fmt(f),
                InvariantAllocateUnallocateEvents::LogNamedArray3Filter(element) => element.fmt(f),
                InvariantAllocateUnallocateEvents::LogNamedBytesFilter(element) => element.fmt(f),
                InvariantAllocateUnallocateEvents::LogNamedBytes32Filter(element) => element.fmt(f),
                InvariantAllocateUnallocateEvents::LogNamedDecimalIntFilter(element) => {
                    element.fmt(f)
                }
                InvariantAllocateUnallocateEvents::LogNamedDecimalUintFilter(element) => {
                    element.fmt(f)
                }
                InvariantAllocateUnallocateEvents::LogNamedIntFilter(element) => element.fmt(f),
                InvariantAllocateUnallocateEvents::LogNamedStringFilter(element) => element.fmt(f),
                InvariantAllocateUnallocateEvents::LogNamedUintFilter(element) => element.fmt(f),
                InvariantAllocateUnallocateEvents::LogStringFilter(element) => element.fmt(f),
                InvariantAllocateUnallocateEvents::LogUintFilter(element) => element.fmt(f),
                InvariantAllocateUnallocateEvents::LogsFilter(element) => element.fmt(f),
            }
        }
    }
    ///Container type for all input parameters for the `IS_TEST` function with signature `IS_TEST()` and selector `0xfa7626d4`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "IS_TEST", abi = "IS_TEST()")]
    pub struct IsTestCall;
    ///Container type for all input parameters for the `__asset__` function with signature `__asset__()` and selector `0xd43c0f99`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "__asset__", abi = "__asset__()")]
    pub struct AssetCall;
    ///Container type for all input parameters for the `__hyper__` function with signature `__hyper__()` and selector `0x3e81296e`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "__hyper__", abi = "__hyper__()")]
    pub struct HyperCall;
    ///Container type for all input parameters for the `__poolId__` function with signature `__poolId__()` and selector `0xc6a68a47`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "__poolId__", abi = "__poolId__()")]
    pub struct PoolIdCall;
    ///Container type for all input parameters for the `__quote__` function with signature `__quote__()` and selector `0x8dbc9651`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "__quote__", abi = "__quote__()")]
    pub struct QuoteCall;
    ///Container type for all input parameters for the `_getBalance` function with signature `_getBalance(address,address,address)` and selector `0xcf7dee1f`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "_getBalance", abi = "_getBalance(address,address,address)")]
    pub struct _GetBalanceCall {
        pub hyper: ::ethers::core::types::Address,
        pub owner: ::ethers::core::types::Address,
        pub token: ::ethers::core::types::Address,
    }
    ///Container type for all input parameters for the `_getPool` function with signature `_getPool(address,uint64)` and selector `0x09deb4d3`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "_getPool", abi = "_getPool(address,uint64)")]
    pub struct _GetPoolCall {
        pub hyper: ::ethers::core::types::Address,
        pub pool_id: u64,
    }
    ///Container type for all input parameters for the `_getPosition` function with signature `_getPosition(address,address,uint64)` and selector `0xdc723804`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "_getPosition", abi = "_getPosition(address,address,uint64)")]
    pub struct _GetPositionCall {
        pub hyper: ::ethers::core::types::Address,
        pub owner: ::ethers::core::types::Address,
        pub position_id: u64,
    }
    ///Container type for all input parameters for the `_getReserve` function with signature `_getReserve(address,address)` and selector `0x5a8be8b0`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "_getReserve", abi = "_getReserve(address,address)")]
    pub struct _GetReserveCall {
        pub hyper: ::ethers::core::types::Address,
        pub token: ::ethers::core::types::Address,
    }
    ///Container type for all input parameters for the `allocate` function with signature `allocate(uint256,uint256)` and selector `0x172cfa4c`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "allocate", abi = "allocate(uint256,uint256)")]
    pub struct AllocateCall {
        pub delta_liquidity: ::ethers::core::types::U256,
        pub index: ::ethers::core::types::U256,
    }
    ///Container type for all input parameters for the `failed` function with signature `failed()` and selector `0xba414fa6`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "failed", abi = "failed()")]
    pub struct FailedCall;
    ///Container type for all input parameters for the `getBalance` function with signature `getBalance(address,address,address)` and selector `0xd6bd603c`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getBalance", abi = "getBalance(address,address,address)")]
    pub struct GetBalanceCall {
        pub hyper: ::ethers::core::types::Address,
        pub owner: ::ethers::core::types::Address,
        pub token: ::ethers::core::types::Address,
    }
    ///Container type for all input parameters for the `getBalanceSum` function with signature `getBalanceSum(address,address,address[])` and selector `0xff314c0a`
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
        name = "getBalanceSum",
        abi = "getBalanceSum(address,address,address[])"
    )]
    pub struct GetBalanceSumCall {
        pub hyper: ::ethers::core::types::Address,
        pub token: ::ethers::core::types::Address,
        pub owners: ::std::vec::Vec<::ethers::core::types::Address>,
    }
    ///Container type for all input parameters for the `getCurve` function with signature `getCurve(address,uint64)` and selector `0xd83410b6`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getCurve", abi = "getCurve(address,uint64)")]
    pub struct GetCurveCall {
        pub hyper: ::ethers::core::types::Address,
        pub pool_id: u64,
    }
    ///Container type for all input parameters for the `getMaxSwapLimit` function with signature `getMaxSwapLimit(bool)` and selector `0xcee2aaf5`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getMaxSwapLimit", abi = "getMaxSwapLimit(bool)")]
    pub struct GetMaxSwapLimitCall {
        pub sell_asset: bool,
    }
    ///Container type for all input parameters for the `getPair` function with signature `getPair(address,uint24)` and selector `0x7b135ad1`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getPair", abi = "getPair(address,uint24)")]
    pub struct GetPairCall {
        pub hyper: ::ethers::core::types::Address,
        pub pair_id: u32,
    }
    ///Container type for all input parameters for the `getPhysicalBalance` function with signature `getPhysicalBalance(address,address)` and selector `0x634e05e0`
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
        name = "getPhysicalBalance",
        abi = "getPhysicalBalance(address,address)"
    )]
    pub struct GetPhysicalBalanceCall {
        pub hyper: ::ethers::core::types::Address,
        pub token: ::ethers::core::types::Address,
    }
    ///Container type for all input parameters for the `getPool` function with signature `getPool(address,uint64)` and selector `0x273c329f`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getPool", abi = "getPool(address,uint64)")]
    pub struct GetPoolCall {
        pub hyper: ::ethers::core::types::Address,
        pub pool_id: u64,
    }
    ///Container type for all input parameters for the `getPosition` function with signature `getPosition(address,address,uint64)` and selector `0xdd05e299`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getPosition", abi = "getPosition(address,address,uint64)")]
    pub struct GetPositionCall {
        pub hyper: ::ethers::core::types::Address,
        pub owner: ::ethers::core::types::Address,
        pub position_id: u64,
    }
    ///Container type for all input parameters for the `getPositionLiquiditySum` function with signature `getPositionLiquiditySum(address,uint64,address[])` and selector `0x8828200d`
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
        name = "getPositionLiquiditySum",
        abi = "getPositionLiquiditySum(address,uint64,address[])"
    )]
    pub struct GetPositionLiquiditySumCall {
        pub hyper: ::ethers::core::types::Address,
        pub pool_id: u64,
        pub owners: ::std::vec::Vec<::ethers::core::types::Address>,
    }
    ///Container type for all input parameters for the `getReserve` function with signature `getReserve(address,address)` and selector `0xcbc3ab53`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getReserve", abi = "getReserve(address,address)")]
    pub struct GetReserveCall {
        pub hyper: ::ethers::core::types::Address,
        pub token: ::ethers::core::types::Address,
    }
    ///Container type for all input parameters for the `getState` function with signature `getState(address,uint64,address,address[])` and selector `0xf3140b1e`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getState", abi = "getState(address,uint64,address,address[])")]
    pub struct GetStateCall {
        pub hyper: ::ethers::core::types::Address,
        pub pool_id: u64,
        pub caller: ::ethers::core::types::Address,
        pub owners: ::std::vec::Vec<::ethers::core::types::Address>,
    }
    ///Container type for all input parameters for the `getVirtualBalance` function with signature `getVirtualBalance(address,address,address[])` and selector `0x6dce537d`
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
        name = "getVirtualBalance",
        abi = "getVirtualBalance(address,address,address[])"
    )]
    pub struct GetVirtualBalanceCall {
        pub hyper: ::ethers::core::types::Address,
        pub token: ::ethers::core::types::Address,
        pub owners: ::std::vec::Vec<::ethers::core::types::Address>,
    }
    ///Container type for all input parameters for the `unallocate` function with signature `unallocate(uint256,uint256)` and selector `0xe179eed6`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "unallocate", abi = "unallocate(uint256,uint256)")]
    pub struct UnallocateCall {
        pub delta_liquidity: ::ethers::core::types::U256,
        pub index: ::ethers::core::types::U256,
    }
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum InvariantAllocateUnallocateCalls {
        IsTest(IsTestCall),
        Asset(AssetCall),
        Hyper(HyperCall),
        PoolId(PoolIdCall),
        Quote(QuoteCall),
        _GetBalance(_GetBalanceCall),
        _GetPool(_GetPoolCall),
        _GetPosition(_GetPositionCall),
        _GetReserve(_GetReserveCall),
        Allocate(AllocateCall),
        Failed(FailedCall),
        GetBalance(GetBalanceCall),
        GetBalanceSum(GetBalanceSumCall),
        GetCurve(GetCurveCall),
        GetMaxSwapLimit(GetMaxSwapLimitCall),
        GetPair(GetPairCall),
        GetPhysicalBalance(GetPhysicalBalanceCall),
        GetPool(GetPoolCall),
        GetPosition(GetPositionCall),
        GetPositionLiquiditySum(GetPositionLiquiditySumCall),
        GetReserve(GetReserveCall),
        GetState(GetStateCall),
        GetVirtualBalance(GetVirtualBalanceCall),
        Unallocate(UnallocateCall),
    }
    impl ::ethers::core::abi::AbiDecode for InvariantAllocateUnallocateCalls {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded) =
                <IsTestCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::IsTest(decoded));
            }
            if let Ok(decoded) =
                <AssetCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::Asset(decoded));
            }
            if let Ok(decoded) =
                <HyperCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::Hyper(decoded));
            }
            if let Ok(decoded) =
                <PoolIdCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::PoolId(decoded));
            }
            if let Ok(decoded) =
                <QuoteCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::Quote(decoded));
            }
            if let Ok(decoded) =
                <_GetBalanceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::_GetBalance(decoded));
            }
            if let Ok(decoded) =
                <_GetPoolCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::_GetPool(decoded));
            }
            if let Ok(decoded) =
                <_GetPositionCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::_GetPosition(decoded));
            }
            if let Ok(decoded) =
                <_GetReserveCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::_GetReserve(decoded));
            }
            if let Ok(decoded) =
                <AllocateCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::Allocate(decoded));
            }
            if let Ok(decoded) =
                <FailedCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::Failed(decoded));
            }
            if let Ok(decoded) =
                <GetBalanceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::GetBalance(decoded));
            }
            if let Ok(decoded) =
                <GetBalanceSumCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::GetBalanceSum(decoded));
            }
            if let Ok(decoded) =
                <GetCurveCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::GetCurve(decoded));
            }
            if let Ok(decoded) =
                <GetMaxSwapLimitCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::GetMaxSwapLimit(decoded));
            }
            if let Ok(decoded) =
                <GetPairCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::GetPair(decoded));
            }
            if let Ok(decoded) =
                <GetPhysicalBalanceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::GetPhysicalBalance(
                    decoded,
                ));
            }
            if let Ok(decoded) =
                <GetPoolCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::GetPool(decoded));
            }
            if let Ok(decoded) =
                <GetPositionCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::GetPosition(decoded));
            }
            if let Ok(decoded) =
                <GetPositionLiquiditySumCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                )
            {
                return Ok(InvariantAllocateUnallocateCalls::GetPositionLiquiditySum(
                    decoded,
                ));
            }
            if let Ok(decoded) =
                <GetReserveCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::GetReserve(decoded));
            }
            if let Ok(decoded) =
                <GetStateCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::GetState(decoded));
            }
            if let Ok(decoded) =
                <GetVirtualBalanceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::GetVirtualBalance(decoded));
            }
            if let Ok(decoded) =
                <UnallocateCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantAllocateUnallocateCalls::Unallocate(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for InvariantAllocateUnallocateCalls {
        fn encode(self) -> Vec<u8> {
            match self {
                InvariantAllocateUnallocateCalls::IsTest(element) => element.encode(),
                InvariantAllocateUnallocateCalls::Asset(element) => element.encode(),
                InvariantAllocateUnallocateCalls::Hyper(element) => element.encode(),
                InvariantAllocateUnallocateCalls::PoolId(element) => element.encode(),
                InvariantAllocateUnallocateCalls::Quote(element) => element.encode(),
                InvariantAllocateUnallocateCalls::_GetBalance(element) => element.encode(),
                InvariantAllocateUnallocateCalls::_GetPool(element) => element.encode(),
                InvariantAllocateUnallocateCalls::_GetPosition(element) => element.encode(),
                InvariantAllocateUnallocateCalls::_GetReserve(element) => element.encode(),
                InvariantAllocateUnallocateCalls::Allocate(element) => element.encode(),
                InvariantAllocateUnallocateCalls::Failed(element) => element.encode(),
                InvariantAllocateUnallocateCalls::GetBalance(element) => element.encode(),
                InvariantAllocateUnallocateCalls::GetBalanceSum(element) => element.encode(),
                InvariantAllocateUnallocateCalls::GetCurve(element) => element.encode(),
                InvariantAllocateUnallocateCalls::GetMaxSwapLimit(element) => element.encode(),
                InvariantAllocateUnallocateCalls::GetPair(element) => element.encode(),
                InvariantAllocateUnallocateCalls::GetPhysicalBalance(element) => element.encode(),
                InvariantAllocateUnallocateCalls::GetPool(element) => element.encode(),
                InvariantAllocateUnallocateCalls::GetPosition(element) => element.encode(),
                InvariantAllocateUnallocateCalls::GetPositionLiquiditySum(element) => {
                    element.encode()
                }
                InvariantAllocateUnallocateCalls::GetReserve(element) => element.encode(),
                InvariantAllocateUnallocateCalls::GetState(element) => element.encode(),
                InvariantAllocateUnallocateCalls::GetVirtualBalance(element) => element.encode(),
                InvariantAllocateUnallocateCalls::Unallocate(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for InvariantAllocateUnallocateCalls {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                InvariantAllocateUnallocateCalls::IsTest(element) => element.fmt(f),
                InvariantAllocateUnallocateCalls::Asset(element) => element.fmt(f),
                InvariantAllocateUnallocateCalls::Hyper(element) => element.fmt(f),
                InvariantAllocateUnallocateCalls::PoolId(element) => element.fmt(f),
                InvariantAllocateUnallocateCalls::Quote(element) => element.fmt(f),
                InvariantAllocateUnallocateCalls::_GetBalance(element) => element.fmt(f),
                InvariantAllocateUnallocateCalls::_GetPool(element) => element.fmt(f),
                InvariantAllocateUnallocateCalls::_GetPosition(element) => element.fmt(f),
                InvariantAllocateUnallocateCalls::_GetReserve(element) => element.fmt(f),
                InvariantAllocateUnallocateCalls::Allocate(element) => element.fmt(f),
                InvariantAllocateUnallocateCalls::Failed(element) => element.fmt(f),
                InvariantAllocateUnallocateCalls::GetBalance(element) => element.fmt(f),
                InvariantAllocateUnallocateCalls::GetBalanceSum(element) => element.fmt(f),
                InvariantAllocateUnallocateCalls::GetCurve(element) => element.fmt(f),
                InvariantAllocateUnallocateCalls::GetMaxSwapLimit(element) => element.fmt(f),
                InvariantAllocateUnallocateCalls::GetPair(element) => element.fmt(f),
                InvariantAllocateUnallocateCalls::GetPhysicalBalance(element) => element.fmt(f),
                InvariantAllocateUnallocateCalls::GetPool(element) => element.fmt(f),
                InvariantAllocateUnallocateCalls::GetPosition(element) => element.fmt(f),
                InvariantAllocateUnallocateCalls::GetPositionLiquiditySum(element) => {
                    element.fmt(f)
                }
                InvariantAllocateUnallocateCalls::GetReserve(element) => element.fmt(f),
                InvariantAllocateUnallocateCalls::GetState(element) => element.fmt(f),
                InvariantAllocateUnallocateCalls::GetVirtualBalance(element) => element.fmt(f),
                InvariantAllocateUnallocateCalls::Unallocate(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<IsTestCall> for InvariantAllocateUnallocateCalls {
        fn from(var: IsTestCall) -> Self {
            InvariantAllocateUnallocateCalls::IsTest(var)
        }
    }
    impl ::std::convert::From<AssetCall> for InvariantAllocateUnallocateCalls {
        fn from(var: AssetCall) -> Self {
            InvariantAllocateUnallocateCalls::Asset(var)
        }
    }
    impl ::std::convert::From<HyperCall> for InvariantAllocateUnallocateCalls {
        fn from(var: HyperCall) -> Self {
            InvariantAllocateUnallocateCalls::Hyper(var)
        }
    }
    impl ::std::convert::From<PoolIdCall> for InvariantAllocateUnallocateCalls {
        fn from(var: PoolIdCall) -> Self {
            InvariantAllocateUnallocateCalls::PoolId(var)
        }
    }
    impl ::std::convert::From<QuoteCall> for InvariantAllocateUnallocateCalls {
        fn from(var: QuoteCall) -> Self {
            InvariantAllocateUnallocateCalls::Quote(var)
        }
    }
    impl ::std::convert::From<_GetBalanceCall> for InvariantAllocateUnallocateCalls {
        fn from(var: _GetBalanceCall) -> Self {
            InvariantAllocateUnallocateCalls::_GetBalance(var)
        }
    }
    impl ::std::convert::From<_GetPoolCall> for InvariantAllocateUnallocateCalls {
        fn from(var: _GetPoolCall) -> Self {
            InvariantAllocateUnallocateCalls::_GetPool(var)
        }
    }
    impl ::std::convert::From<_GetPositionCall> for InvariantAllocateUnallocateCalls {
        fn from(var: _GetPositionCall) -> Self {
            InvariantAllocateUnallocateCalls::_GetPosition(var)
        }
    }
    impl ::std::convert::From<_GetReserveCall> for InvariantAllocateUnallocateCalls {
        fn from(var: _GetReserveCall) -> Self {
            InvariantAllocateUnallocateCalls::_GetReserve(var)
        }
    }
    impl ::std::convert::From<AllocateCall> for InvariantAllocateUnallocateCalls {
        fn from(var: AllocateCall) -> Self {
            InvariantAllocateUnallocateCalls::Allocate(var)
        }
    }
    impl ::std::convert::From<FailedCall> for InvariantAllocateUnallocateCalls {
        fn from(var: FailedCall) -> Self {
            InvariantAllocateUnallocateCalls::Failed(var)
        }
    }
    impl ::std::convert::From<GetBalanceCall> for InvariantAllocateUnallocateCalls {
        fn from(var: GetBalanceCall) -> Self {
            InvariantAllocateUnallocateCalls::GetBalance(var)
        }
    }
    impl ::std::convert::From<GetBalanceSumCall> for InvariantAllocateUnallocateCalls {
        fn from(var: GetBalanceSumCall) -> Self {
            InvariantAllocateUnallocateCalls::GetBalanceSum(var)
        }
    }
    impl ::std::convert::From<GetCurveCall> for InvariantAllocateUnallocateCalls {
        fn from(var: GetCurveCall) -> Self {
            InvariantAllocateUnallocateCalls::GetCurve(var)
        }
    }
    impl ::std::convert::From<GetMaxSwapLimitCall> for InvariantAllocateUnallocateCalls {
        fn from(var: GetMaxSwapLimitCall) -> Self {
            InvariantAllocateUnallocateCalls::GetMaxSwapLimit(var)
        }
    }
    impl ::std::convert::From<GetPairCall> for InvariantAllocateUnallocateCalls {
        fn from(var: GetPairCall) -> Self {
            InvariantAllocateUnallocateCalls::GetPair(var)
        }
    }
    impl ::std::convert::From<GetPhysicalBalanceCall> for InvariantAllocateUnallocateCalls {
        fn from(var: GetPhysicalBalanceCall) -> Self {
            InvariantAllocateUnallocateCalls::GetPhysicalBalance(var)
        }
    }
    impl ::std::convert::From<GetPoolCall> for InvariantAllocateUnallocateCalls {
        fn from(var: GetPoolCall) -> Self {
            InvariantAllocateUnallocateCalls::GetPool(var)
        }
    }
    impl ::std::convert::From<GetPositionCall> for InvariantAllocateUnallocateCalls {
        fn from(var: GetPositionCall) -> Self {
            InvariantAllocateUnallocateCalls::GetPosition(var)
        }
    }
    impl ::std::convert::From<GetPositionLiquiditySumCall> for InvariantAllocateUnallocateCalls {
        fn from(var: GetPositionLiquiditySumCall) -> Self {
            InvariantAllocateUnallocateCalls::GetPositionLiquiditySum(var)
        }
    }
    impl ::std::convert::From<GetReserveCall> for InvariantAllocateUnallocateCalls {
        fn from(var: GetReserveCall) -> Self {
            InvariantAllocateUnallocateCalls::GetReserve(var)
        }
    }
    impl ::std::convert::From<GetStateCall> for InvariantAllocateUnallocateCalls {
        fn from(var: GetStateCall) -> Self {
            InvariantAllocateUnallocateCalls::GetState(var)
        }
    }
    impl ::std::convert::From<GetVirtualBalanceCall> for InvariantAllocateUnallocateCalls {
        fn from(var: GetVirtualBalanceCall) -> Self {
            InvariantAllocateUnallocateCalls::GetVirtualBalance(var)
        }
    }
    impl ::std::convert::From<UnallocateCall> for InvariantAllocateUnallocateCalls {
        fn from(var: UnallocateCall) -> Self {
            InvariantAllocateUnallocateCalls::Unallocate(var)
        }
    }
    ///Container type for all return fields from the `IS_TEST` function with signature `IS_TEST()` and selector `0xfa7626d4`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct IsTestReturn(pub bool);
    ///Container type for all return fields from the `__asset__` function with signature `__asset__()` and selector `0xd43c0f99`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct AssetReturn(pub ::ethers::core::types::Address);
    ///Container type for all return fields from the `__hyper__` function with signature `__hyper__()` and selector `0x3e81296e`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct HyperReturn(pub ::ethers::core::types::Address);
    ///Container type for all return fields from the `__poolId__` function with signature `__poolId__()` and selector `0xc6a68a47`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct PoolIdReturn(pub u64);
    ///Container type for all return fields from the `__quote__` function with signature `__quote__()` and selector `0x8dbc9651`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct QuoteReturn(pub ::ethers::core::types::Address);
    ///Container type for all return fields from the `_getBalance` function with signature `_getBalance(address,address,address)` and selector `0xcf7dee1f`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct _GetBalanceReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `_getPool` function with signature `_getPool(address,uint64)` and selector `0x09deb4d3`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct _GetPoolReturn(pub HyperPool);
    ///Container type for all return fields from the `_getPosition` function with signature `_getPosition(address,address,uint64)` and selector `0xdc723804`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct _GetPositionReturn(pub HyperPosition);
    ///Container type for all return fields from the `_getReserve` function with signature `_getReserve(address,address)` and selector `0x5a8be8b0`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct _GetReserveReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `failed` function with signature `failed()` and selector `0xba414fa6`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct FailedReturn(pub bool);
    ///Container type for all return fields from the `getBalance` function with signature `getBalance(address,address,address)` and selector `0xd6bd603c`
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
    ///Container type for all return fields from the `getBalanceSum` function with signature `getBalanceSum(address,address,address[])` and selector `0xff314c0a`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetBalanceSumReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getCurve` function with signature `getCurve(address,uint64)` and selector `0xd83410b6`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetCurveReturn(pub HyperCurve);
    ///Container type for all return fields from the `getMaxSwapLimit` function with signature `getMaxSwapLimit(bool)` and selector `0xcee2aaf5`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetMaxSwapLimitReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getPair` function with signature `getPair(address,uint24)` and selector `0x7b135ad1`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetPairReturn(pub HyperPair);
    ///Container type for all return fields from the `getPhysicalBalance` function with signature `getPhysicalBalance(address,address)` and selector `0x634e05e0`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetPhysicalBalanceReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getPool` function with signature `getPool(address,uint64)` and selector `0x273c329f`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetPoolReturn(pub HyperPool);
    ///Container type for all return fields from the `getPosition` function with signature `getPosition(address,address,uint64)` and selector `0xdd05e299`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetPositionReturn(pub HyperPosition);
    ///Container type for all return fields from the `getPositionLiquiditySum` function with signature `getPositionLiquiditySum(address,uint64,address[])` and selector `0x8828200d`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetPositionLiquiditySumReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getReserve` function with signature `getReserve(address,address)` and selector `0xcbc3ab53`
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
    ///Container type for all return fields from the `getState` function with signature `getState(address,uint64,address,address[])` and selector `0xf3140b1e`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetStateReturn(pub HyperState);
    ///Container type for all return fields from the `getVirtualBalance` function with signature `getVirtualBalance(address,address,address[])` and selector `0x6dce537d`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetVirtualBalanceReturn(pub ::ethers::core::types::U256);
}
