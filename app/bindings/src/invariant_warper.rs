pub use invariant_warper::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod invariant_warper {
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
    ///InvariantWarper was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
    use std::sync::Arc;
    #[rustfmt::skip]
    const __ABI: &str = "[{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper_\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"asset_\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"quote_\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"constructor\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidBalance\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_address\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint256[]\",\"name\":\"val\",\"type\":\"uint256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"int256[]\",\"name\":\"val\",\"type\":\"int256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address[]\",\"name\":\"val\",\"type\":\"address[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"\",\"type\":\"bytes\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_bytes\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_bytes32\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"int256\",\"name\":\"\",\"type\":\"int256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_int\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"val\",\"type\":\"address\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_address\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256[]\",\"name\":\"val\",\"type\":\"uint256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"int256[]\",\"name\":\"val\",\"type\":\"int256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"address[]\",\"name\":\"val\",\"type\":\"address[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"bytes\",\"name\":\"val\",\"type\":\"bytes\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_bytes\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"bytes32\",\"name\":\"val\",\"type\":\"bytes32\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_bytes32\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"int256\",\"name\":\"val\",\"type\":\"int256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"decimals\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_decimal_int\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"val\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"decimals\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_decimal_uint\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"int256\",\"name\":\"val\",\"type\":\"int256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_int\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"string\",\"name\":\"val\",\"type\":\"string\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_string\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"val\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_uint\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_string\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_uint\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"\",\"type\":\"bytes\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"logs\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"IS_TEST\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__asset__\",\"outputs\":[{\"internalType\":\"contract TestERC20\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__hyper__\",\"outputs\":[{\"internalType\":\"contract HyperTimeOverride\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__poolId__\",\"outputs\":[{\"internalType\":\"uint64\",\"name\":\"\",\"type\":\"uint64\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__quote__\",\"outputs\":[{\"internalType\":\"contract TestERC20\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"contract HyperLike\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"contract TestERC20\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"contract IHyperStruct\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getPool\",\"outputs\":[{\"internalType\":\"struct HyperPool\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"lastTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"lastTimestamp\",\"type\":\"uint32\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"controller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalReward\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"lastPrice\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"liquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"int128\",\"name\":\"stakedLiquidityDelta\",\"type\":\"int128\",\"components\":[]},{\"internalType\":\"struct HyperCurve\",\"name\":\"params\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]},{\"internalType\":\"struct HyperPair\",\"name\":\"pair\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]}]},{\"inputs\":[{\"internalType\":\"contract IHyperStruct\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"positionId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getPosition\",\"outputs\":[{\"internalType\":\"struct HyperPosition\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"uint128\",\"name\":\"freeLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"lastTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"stakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"unstakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthRewardLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuoteLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedQuote\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedReward\",\"type\":\"uint128\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"contract HyperLike\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"contract TestERC20\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getReserve\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"failed\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getBalanceSum\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getCurve\",\"outputs\":[{\"internalType\":\"struct HyperCurve\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"bool\",\"name\":\"sellAsset\",\"type\":\"bool\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getMaxSwapLimit\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint24\",\"name\":\"pairId\",\"type\":\"uint24\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPair\",\"outputs\":[{\"internalType\":\"struct HyperPair\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPhysicalBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPool\",\"outputs\":[{\"internalType\":\"struct HyperPool\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"lastTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"lastTimestamp\",\"type\":\"uint32\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"controller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalReward\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"lastPrice\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"liquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"int128\",\"name\":\"stakedLiquidityDelta\",\"type\":\"int128\",\"components\":[]},{\"internalType\":\"struct HyperCurve\",\"name\":\"params\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]},{\"internalType\":\"struct HyperPair\",\"name\":\"pair\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"positionId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPosition\",\"outputs\":[{\"internalType\":\"struct HyperPosition\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"uint128\",\"name\":\"freeLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"lastTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"stakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"unstakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthRewardLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuoteLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedQuote\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedReward\",\"type\":\"uint128\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPositionLiquiditySum\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getReserve\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"caller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getState\",\"outputs\":[{\"internalType\":\"struct HyperState\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"uint256\",\"name\":\"reserveAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"reserveQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"physicalBalanceAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"physicalBalanceQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalBalanceAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalBalanceQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalPositionLiquidity\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"callerPositionLiquidity\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalPoolLiquidity\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetPool\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuotePool\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetPosition\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuotePosition\",\"type\":\"uint256\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getVirtualBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"warpAfterMaturity\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"warper\",\"outputs\":[]}]";
    /// The parsed JSON-ABI of the contract.
    pub static INVARIANTWARPER_ABI: ::ethers::contract::Lazy<::ethers::core::abi::Abi> =
        ::ethers::contract::Lazy::new(|| {
            ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi")
        });
    /// Bytecode of the #name contract
    pub static INVARIANTWARPER_BYTECODE: ::ethers::contract::Lazy<::ethers::core::types::Bytes> =
        ::ethers::contract::Lazy::new(|| {
            "0x60806040526000805460ff1916600117905560138054790100000000010000000000000000000000000000000000000000600160a01b600160e01b03199091161790553480156200004f57600080fd5b5060405162001e4638038062001e468339810160408190526200007291620001d6565b60138054336001600160a01b0319918216179091556014805482166001600160a01b03868116918217909255601680548416868416908117909155601580549094169285169290921790925560405163095ea7b360e01b81526004810192909252600019602483015284918491849163095ea7b3906044016020604051808303816000875af11580156200010a573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019062000130919062000220565b5060155460405163095ea7b360e01b81526001600160a01b03858116600483015260001960248301529091169063095ea7b3906044016020604051808303816000875af115801562000186573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190620001ac919062000220565b505050505050506200024b565b80516001600160a01b0381168114620001d157600080fd5b919050565b600080600060608486031215620001ec57600080fd5b620001f784620001b9565b92506200020760208501620001b9565b91506200021760408501620001b9565b90509250925092565b6000602082840312156200023357600080fd5b815180151581146200024457600080fd5b9392505050565b611beb806200025b6000396000f3fe608060405234801561001057600080fd5b50600436106101585760003560e01c8063c6a68a47116100c3578063d83410b61161007c578063d83410b6146102e9578063dc72380414610309578063dd05e29914610309578063f3140b1e14610329578063fa7626d4146103cf578063ff314c0a146103dc57600080fd5b8063c6a68a471461027e578063cbc3ab53146101c6578063cee2aaf5146102b0578063cf7dee1f146102c3578063d43c0f99146102d6578063d6bd603c146102c357600080fd5b80636dce537d116101155780636dce537d146101fa578063708f1e921461020d5780637b135ad1146102205780638828200d146102405780638dbc965114610253578063ba414fa61461026657600080fd5b806309deb4d31461015d5780631fabc33214610186578063273c329f1461015d5780633e81296e1461019b5780635a8be8b0146101c6578063634e05e0146101e7575b600080fd5b61017061016b3660046110e5565b6103ef565b60405161017d9190611177565b60405180910390f35b61019961019436600461128b565b61051e565b005b6014546101ae906001600160a01b031681565b6040516001600160a01b03909116815260200161017d565b6101d96101d43660046112a4565b610632565b60405190815260200161017d565b6101d96101f53660046112a4565b6106a0565b6101d96102083660046113e2565b6106ac565b61019961021b36600461128b565b6106d9565b61023361022e366004611443565b610757565b60405161017d9190611479565b6101d961024e3660046114ba565b6107e8565b6015546101ae906001600160a01b031681565b61026e610849565b604051901515815260200161017d565b60135461029890600160a01b90046001600160401b031681565b6040516001600160401b03909116815260200161017d565b6101d96102be3660046114f6565b610974565b6101d96102d1366004611513565b61098d565b6016546101ae906001600160a01b031681565b6102fc6102f73660046110e5565b610a0b565b60405161017d919061155e565b61031c61031736600461156c565b610a5b565b60405161017d91906115b3565b61033c610337366004611665565b610b5f565b60405161017d9190815181526020808301519082015260408083015190820152606080830151908201526080808301519082015260a0808301519082015260c0808301519082015260e08083015190820152610100808301519082015261012080830151908201526101408083015190820152610160808301519082015261018091820151918101919091526101a00190565b60005461026e9060ff1681565b6101d96103ea3660046113e2565b610ce0565b6104a36040805161018081018252600080825260208083018290528284018290526060808401839052608080850184905260a080860185905260c080870186905260e0808801879052610100880187905261012088018790528851908101895286815294850186905296840185905291830184905282018390528101829052928301529061014082019081526040805160808101825260008082526020828101829052928201819052606082015291015290565b6040516322697c2160e21b81526001600160401b03831660048201526001600160a01b038416906389a5f084906024016102a060405180830381865afa1580156104f1573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610515919061188b565b90505b92915050565b610530816201518063039ada00610d2e565b60145460135460405163f850c3a560e01b8152600160a01b9091046001600160401b031660048201529192506000916001600160a01b039091169063f850c3a590602401602060405180830381865afa158015610591573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906105b59190611965565b6013549091506001600160a01b03166371f76aac836105d48442611994565b6105de9190611994565b6040518263ffffffff1660e01b81526004016105fc91815260200190565b600060405180830381600087803b15801561061657600080fd5b505af115801561062a573d6000803e3d6000fd5b505050505050565b60405163c9a396e960e01b81526001600160a01b0382811660048301526000919084169063c9a396e990602401602060405180830381865afa15801561067c573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906105159190611965565b60006105158284610d6b565b6000806106ba858585610ce0565b6106c48686610632565b6106ce9190611994565b9150505b9392505050565b6013546001600160a01b03166371f76aac6106fa8360016301e13380610d2e565b6107049042611994565b6040518263ffffffff1660e01b815260040161072291815260200190565b600060405180830381600087803b15801561073c57600080fd5b505af1158015610750573d6000803e3d6000fd5b5050505050565b604080516080810182526000808252602082018190529181018290526060810191909152604051631791d98f60e21b815262ffffff831660048201526001600160a01b03841690635e47663c90602401608060405180830381865afa1580156107c4573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061051591906119ac565b60008060005b835181146108405761081a8685838151811061080c5761080c6119c8565b602002602001015187610a5b565b5161082e906001600160801b031683611994565b9150610839816119de565b90506107ee565b50949350505050565b60008054610100900460ff16156108695750600054610100900460ff1690565b6000737109709ecfa91a80626ff3989d68f67f5b1dd12d3b1561096f5760408051737109709ecfa91a80626ff3989d68f67f5b1dd12d602082018190526519985a5b195960d21b828401528251808303840181526060830190935260009290916108f7917f667f9d70ca411d70ead50d8d5c22070dafc36ad75f3dcf5e7237b22ade9aecc491608001611a27565b60408051601f198184030181529082905261091191611a58565b6000604051808303816000865af19150503d806000811461094e576040519150601f19603f3d011682016040523d82523d6000602084013e610953565b606091505b509150508080602001905181019061096b9190611a74565b9150505b919050565b6000811561098457506000919050565b50600019919050565b60405163d4fac45d60e01b81526001600160a01b03838116600483015282811660248301526000919085169063d4fac45d90604401602060405180830381865afa1580156109df573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610a039190611965565b949350505050565b6040805160e081018252600080825260208201819052918101829052606081018290526080810182905260a0810182905260c0810182905290610a4e84846103ef565b6101400151949350505050565b610ae560405180610160016040528060006001600160801b0316815260200160006001600160801b0316815260200160008152602001600081526020016000815260200160008152602001600081526020016000815260200160006001600160801b0316815260200160006001600160801b0316815260200160006001600160801b031681525090565b604051635b4289f560e11b81526001600160a01b0384811660048301526001600160401b038416602483015285169063b68513ea9060440161016060405180830381865afa158015610b3b573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610a039190611a91565b610bca604051806101a00160405280600081526020016000815260200160008152602001600081526020016000815260200160008152602001600081526020016000815260200160008152602001600081526020016000815260200160008152602001600081525090565b6000610bdf86602887901c62ffffff16610757565b80516040820151919250906000610bf689896103ef565b90506000610c058a898b610a5b565b90506000604051806101a00160405280610c1f8d88610632565b8152602001610c2e8d87610632565b8152602001610c3d8d886106a0565b8152602001610c4c8d876106a0565b8152602001610c5c8d888c610ce0565b8152602001610c6c8d878c610ce0565b8152602001610c7c8d8d8c6107e8565b815260200183600001516001600160801b031681526020018460e001516001600160801b03168152602001846080015181526020018460a0015181526020018360c0015181526020018360e001518152509050809650505050505050949350505050565b60008060005b8351811461084057610d1286858381518110610d0457610d046119c8565b60200260200101518761098d565b610d1c9083611994565b9150610d27816119de565b9050610ce6565b6000610d3b848484610e54565b90506106d26040518060400160405280600c81526020016b109bdd5b990814995cdd5b1d60a21b8152508261101c565b604080516001600160a01b0383811660248084019190915283518084039091018152604490920183526020820180516001600160e01b03166370a0823160e01b17905291516000928392839291871691610dc59190611a58565b600060405180830381855afa9150503d8060008114610e00576040519150601f19603f3d011682016040523d82523d6000602084013e610e05565b606091505b5091509150811580610e1957508051602014155b15610e375760405163c52e3eff60e01b815260040160405180910390fd5b80806020019051810190610e4b9190611965565b95945050505050565b600081831115610ed05760405162461bcd60e51b815260206004820152603e60248201527f5374645574696c7320626f756e642875696e743235362c75696e743235362c7560448201527f696e74323536293a204d6178206973206c657373207468616e206d696e2e0000606482015260840160405180910390fd5b828410158015610ee05750818411155b15610eec5750826106d2565b6000610ef88484611b41565b610f03906001611994565b905060038511158015610f1557508481115b15610f2c57610f248585611994565b9150506106d2565b610f396003600019611b41565b8510158015610f525750610f4f85600019611b41565b81115b15610f6d57610f6385600019611b41565b610f249084611b41565b82851115610fc3576000610f818487611b41565b90506000610f8f8383611b58565b905080600003610fa4578493505050506106d2565b6001610fb08288611994565b610fba9190611b41565b93505050611014565b83851015611014576000610fd78686611b41565b90506000610fe58383611b58565b905080600003610ffa578593505050506106d2565b6110048186611b41565b61100f906001611994565b935050505b509392505050565b60006a636f6e736f6c652e6c6f676001600160a01b03168383604051602401611046929190611b7a565b60408051601f198184030181529181526020820180516001600160e01b0316632d839cb360e21b1790525161107b9190611a58565b600060405180830381855afa9150503d806000811461062a576040519150601f19603f3d011682016040523d82523d6000602084013e61062a565b6001600160a01b03811681146110cb57600080fd5b50565b80356001600160401b038116811461096f57600080fd5b600080604083850312156110f857600080fd5b8235611103816110b6565b9150611111602084016110ce565b90509250929050565b805160020b8252602081015161ffff80821660208501528060408401511660408501528060608401511660608501528060808401511660808501528060a08401511660a0850152505063ffffffff60c08201511660c08301525050565b815160020b81526102a08101602083015161119a602084018263ffffffff169052565b5060408301516111b560408401826001600160a01b03169052565b50606083015160608301526080830151608083015260a083015160a083015260c08301516111ee60c08401826001600160801b03169052565b5060e083015161120960e08401826001600160801b03169052565b50610100838101516001600160801b03169083015261012080840151600f0b908301526101408084015161123f8285018261111a565b505061016083015180516001600160a01b03908116610220850152602082015160ff90811661024086015260408301519091166102608501526060820151166102808401525092915050565b60006020828403121561129d57600080fd5b5035919050565b600080604083850312156112b757600080fd5b82356112c2816110b6565b915060208301356112d2816110b6565b809150509250929050565b634e487b7160e01b600052604160045260246000fd5b60405161018081016001600160401b0381118282101715611316576113166112dd565b60405290565b60405161016081016001600160401b0381118282101715611316576113166112dd565b600082601f83011261135057600080fd5b813560206001600160401b038083111561136c5761136c6112dd565b8260051b604051601f19603f83011681018181108482111715611391576113916112dd565b6040529384528581018301938381019250878511156113af57600080fd5b83870191505b848210156113d75781356113c8816110b6565b835291830191908301906113b5565b979650505050505050565b6000806000606084860312156113f757600080fd5b8335611402816110b6565b92506020840135611412816110b6565b915060408401356001600160401b0381111561142d57600080fd5b6114398682870161133f565b9150509250925092565b6000806040838503121561145657600080fd5b8235611461816110b6565b9150602083013562ffffff811681146112d257600080fd5b60808101610518828460018060a01b0380825116835260ff60208301511660208401528060408301511660408401525060ff60608201511660608301525050565b6000806000606084860312156114cf57600080fd5b83356114da816110b6565b9250611412602085016110ce565b80151581146110cb57600080fd5b60006020828403121561150857600080fd5b81356106d2816114e8565b60008060006060848603121561152857600080fd5b8335611533816110b6565b92506020840135611543816110b6565b91506040840135611553816110b6565b809150509250925092565b60e08101610518828461111a565b60008060006060848603121561158157600080fd5b833561158c816110b6565b9250602084013561159c816110b6565b91506115aa604085016110ce565b90509250925092565b81516001600160801b03168152610160810160208301516115df60208401826001600160801b03169052565b5060408301516040830152606083015160608301526080830151608083015260a083015160a083015260c083015160c083015260e083015160e083015261010080840151611637828501826001600160801b03169052565b5050610120838101516001600160801b03908116918401919091526101409384015116929091019190915290565b6000806000806080858703121561167b57600080fd5b8435611686816110b6565b9350611694602086016110ce565b925060408501356116a4816110b6565b915060608501356001600160401b038111156116bf57600080fd5b6116cb8782880161133f565b91505092959194509250565b8051600281900b811461096f57600080fd5b805163ffffffff8116811461096f57600080fd5b805161096f816110b6565b80516001600160801b038116811461096f57600080fd5b8051600f81900b811461096f57600080fd5b805161ffff8116811461096f57600080fd5b600060e0828403121561175557600080fd5b60405160e081018181106001600160401b0382111715611777576117776112dd565b604052905080611786836116d7565b815261179460208401611731565b60208201526117a560408401611731565b60408201526117b660608401611731565b60608201526117c760808401611731565b60808201526117d860a08401611731565b60a08201526117e960c084016116e9565b60c08201525092915050565b805160ff8116811461096f57600080fd5b60006080828403121561181857600080fd5b604051608081018181106001600160401b038211171561183a5761183a6112dd565b8060405250809150825161184d816110b6565b815261185b602084016117f5565b6020820152604083015161186e816110b6565b604082015261187f606084016117f5565b60608201525092915050565b60006102a0828403121561189e57600080fd5b6118a66112f3565b6118af836116d7565b81526118bd602084016116e9565b60208201526118ce604084016116fd565b6040820152606083015160608201526080830151608082015260a083015160a08201526118fd60c08401611708565b60c082015261190e60e08401611708565b60e0820152610100611921818501611708565b9082015261012061193384820161171f565b9082015261014061194685858301611743565b90820152611958846102208501611806565b6101608201529392505050565b60006020828403121561197757600080fd5b5051919050565b634e487b7160e01b600052601160045260246000fd5b600082198211156119a7576119a761197e565b500190565b6000608082840312156119be57600080fd5b6105158383611806565b634e487b7160e01b600052603260045260246000fd5b6000600182016119f0576119f061197e565b5060010190565b60005b83811015611a125781810151838201526020016119fa565b83811115611a21576000848401525b50505050565b6001600160e01b0319831681528151600090611a4a8160048501602087016119f7565b919091016004019392505050565b60008251611a6a8184602087016119f7565b9190910192915050565b600060208284031215611a8657600080fd5b81516106d2816114e8565b60006101608284031215611aa457600080fd5b611aac61131c565b611ab583611708565b8152611ac360208401611708565b602082015260408301516040820152606083015160608201526080830151608082015260a083015160a082015260c083015160c082015260e083015160e0820152610100611b12818501611708565b90820152610120611b24848201611708565b90820152610140611b36848201611708565b908201529392505050565b600082821015611b5357611b5361197e565b500390565b600082611b7557634e487b7160e01b600052601260045260246000fd5b500690565b6040815260008351806040840152611b998160608501602088016119f7565b602083019390935250601f91909101601f19160160600191905056fea2646970667358221220931a490e60a37baf6c34bae0aa26114566ab370f009576b2e5ac079c7c15c9d064736f6c634300080d0033"
            .parse()
            .expect("invalid bytecode")
        });
    pub struct InvariantWarper<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for InvariantWarper<M> {
        fn clone(&self) -> Self {
            InvariantWarper(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for InvariantWarper<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for InvariantWarper<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(InvariantWarper))
                .field(&self.address())
                .finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> InvariantWarper<M> {
        /// Creates a new contract instance with the specified `ethers`
        /// client at the given `Address`. The contract derefs to a `ethers::Contract`
        /// object
        pub fn new<T: Into<::ethers::core::types::Address>>(
            address: T,
            client: ::std::sync::Arc<M>,
        ) -> Self {
            Self(::ethers::contract::Contract::new(
                address.into(),
                INVARIANTWARPER_ABI.clone(),
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
                INVARIANTWARPER_ABI.clone(),
                INVARIANTWARPER_BYTECODE.clone().into(),
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
        ///Calls the contract's `warpAfterMaturity` (0x1fabc332) function
        pub fn warp_after_maturity(
            &self,
            amount: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([31, 171, 195, 50], amount)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `warper` (0x708f1e92) function
        pub fn warper(
            &self,
            amount: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([112, 143, 30, 146], amount)
                .expect("method not found (this should never happen)")
        }
        ///Gets the contract's `log` event
        pub fn log_filter(&self) -> ::ethers::contract::builders::Event<M, LogFilter> {
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
        pub fn events(&self) -> ::ethers::contract::builders::Event<M, InvariantWarperEvents> {
            self.0.event_with_filter(Default::default())
        }
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>>
        for InvariantWarper<M>
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
    #[ethevent(name = "log", abi = "log(string)")]
    pub struct LogFilter(pub String);
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
    pub enum InvariantWarperEvents {
        LogFilter(LogFilter),
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
    impl ::ethers::contract::EthLogDecode for InvariantWarperEvents {
        fn decode_log(
            log: &::ethers::core::abi::RawLog,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::Error>
        where
            Self: Sized,
        {
            if let Ok(decoded) = LogFilter::decode_log(log) {
                return Ok(InvariantWarperEvents::LogFilter(decoded));
            }
            if let Ok(decoded) = LogAddressFilter::decode_log(log) {
                return Ok(InvariantWarperEvents::LogAddressFilter(decoded));
            }
            if let Ok(decoded) = LogArray1Filter::decode_log(log) {
                return Ok(InvariantWarperEvents::LogArray1Filter(decoded));
            }
            if let Ok(decoded) = LogArray2Filter::decode_log(log) {
                return Ok(InvariantWarperEvents::LogArray2Filter(decoded));
            }
            if let Ok(decoded) = LogArray3Filter::decode_log(log) {
                return Ok(InvariantWarperEvents::LogArray3Filter(decoded));
            }
            if let Ok(decoded) = LogBytesFilter::decode_log(log) {
                return Ok(InvariantWarperEvents::LogBytesFilter(decoded));
            }
            if let Ok(decoded) = LogBytes32Filter::decode_log(log) {
                return Ok(InvariantWarperEvents::LogBytes32Filter(decoded));
            }
            if let Ok(decoded) = LogIntFilter::decode_log(log) {
                return Ok(InvariantWarperEvents::LogIntFilter(decoded));
            }
            if let Ok(decoded) = LogNamedAddressFilter::decode_log(log) {
                return Ok(InvariantWarperEvents::LogNamedAddressFilter(decoded));
            }
            if let Ok(decoded) = LogNamedArray1Filter::decode_log(log) {
                return Ok(InvariantWarperEvents::LogNamedArray1Filter(decoded));
            }
            if let Ok(decoded) = LogNamedArray2Filter::decode_log(log) {
                return Ok(InvariantWarperEvents::LogNamedArray2Filter(decoded));
            }
            if let Ok(decoded) = LogNamedArray3Filter::decode_log(log) {
                return Ok(InvariantWarperEvents::LogNamedArray3Filter(decoded));
            }
            if let Ok(decoded) = LogNamedBytesFilter::decode_log(log) {
                return Ok(InvariantWarperEvents::LogNamedBytesFilter(decoded));
            }
            if let Ok(decoded) = LogNamedBytes32Filter::decode_log(log) {
                return Ok(InvariantWarperEvents::LogNamedBytes32Filter(decoded));
            }
            if let Ok(decoded) = LogNamedDecimalIntFilter::decode_log(log) {
                return Ok(InvariantWarperEvents::LogNamedDecimalIntFilter(decoded));
            }
            if let Ok(decoded) = LogNamedDecimalUintFilter::decode_log(log) {
                return Ok(InvariantWarperEvents::LogNamedDecimalUintFilter(decoded));
            }
            if let Ok(decoded) = LogNamedIntFilter::decode_log(log) {
                return Ok(InvariantWarperEvents::LogNamedIntFilter(decoded));
            }
            if let Ok(decoded) = LogNamedStringFilter::decode_log(log) {
                return Ok(InvariantWarperEvents::LogNamedStringFilter(decoded));
            }
            if let Ok(decoded) = LogNamedUintFilter::decode_log(log) {
                return Ok(InvariantWarperEvents::LogNamedUintFilter(decoded));
            }
            if let Ok(decoded) = LogStringFilter::decode_log(log) {
                return Ok(InvariantWarperEvents::LogStringFilter(decoded));
            }
            if let Ok(decoded) = LogUintFilter::decode_log(log) {
                return Ok(InvariantWarperEvents::LogUintFilter(decoded));
            }
            if let Ok(decoded) = LogsFilter::decode_log(log) {
                return Ok(InvariantWarperEvents::LogsFilter(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData)
        }
    }
    impl ::std::fmt::Display for InvariantWarperEvents {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                InvariantWarperEvents::LogFilter(element) => element.fmt(f),
                InvariantWarperEvents::LogAddressFilter(element) => element.fmt(f),
                InvariantWarperEvents::LogArray1Filter(element) => element.fmt(f),
                InvariantWarperEvents::LogArray2Filter(element) => element.fmt(f),
                InvariantWarperEvents::LogArray3Filter(element) => element.fmt(f),
                InvariantWarperEvents::LogBytesFilter(element) => element.fmt(f),
                InvariantWarperEvents::LogBytes32Filter(element) => element.fmt(f),
                InvariantWarperEvents::LogIntFilter(element) => element.fmt(f),
                InvariantWarperEvents::LogNamedAddressFilter(element) => element.fmt(f),
                InvariantWarperEvents::LogNamedArray1Filter(element) => element.fmt(f),
                InvariantWarperEvents::LogNamedArray2Filter(element) => element.fmt(f),
                InvariantWarperEvents::LogNamedArray3Filter(element) => element.fmt(f),
                InvariantWarperEvents::LogNamedBytesFilter(element) => element.fmt(f),
                InvariantWarperEvents::LogNamedBytes32Filter(element) => element.fmt(f),
                InvariantWarperEvents::LogNamedDecimalIntFilter(element) => element.fmt(f),
                InvariantWarperEvents::LogNamedDecimalUintFilter(element) => element.fmt(f),
                InvariantWarperEvents::LogNamedIntFilter(element) => element.fmt(f),
                InvariantWarperEvents::LogNamedStringFilter(element) => element.fmt(f),
                InvariantWarperEvents::LogNamedUintFilter(element) => element.fmt(f),
                InvariantWarperEvents::LogStringFilter(element) => element.fmt(f),
                InvariantWarperEvents::LogUintFilter(element) => element.fmt(f),
                InvariantWarperEvents::LogsFilter(element) => element.fmt(f),
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
    ///Container type for all input parameters for the `warpAfterMaturity` function with signature `warpAfterMaturity(uint256)` and selector `0x1fabc332`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "warpAfterMaturity", abi = "warpAfterMaturity(uint256)")]
    pub struct WarpAfterMaturityCall {
        pub amount: ::ethers::core::types::U256,
    }
    ///Container type for all input parameters for the `warper` function with signature `warper(uint256)` and selector `0x708f1e92`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "warper", abi = "warper(uint256)")]
    pub struct WarperCall {
        pub amount: ::ethers::core::types::U256,
    }
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum InvariantWarperCalls {
        IsTest(IsTestCall),
        Asset(AssetCall),
        Hyper(HyperCall),
        PoolId(PoolIdCall),
        Quote(QuoteCall),
        _GetBalance(_GetBalanceCall),
        _GetPool(_GetPoolCall),
        _GetPosition(_GetPositionCall),
        _GetReserve(_GetReserveCall),
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
        WarpAfterMaturity(WarpAfterMaturityCall),
        Warper(WarperCall),
    }
    impl ::ethers::core::abi::AbiDecode for InvariantWarperCalls {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded) =
                <IsTestCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::IsTest(decoded));
            }
            if let Ok(decoded) =
                <AssetCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::Asset(decoded));
            }
            if let Ok(decoded) =
                <HyperCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::Hyper(decoded));
            }
            if let Ok(decoded) =
                <PoolIdCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::PoolId(decoded));
            }
            if let Ok(decoded) =
                <QuoteCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::Quote(decoded));
            }
            if let Ok(decoded) =
                <_GetBalanceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::_GetBalance(decoded));
            }
            if let Ok(decoded) =
                <_GetPoolCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::_GetPool(decoded));
            }
            if let Ok(decoded) =
                <_GetPositionCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::_GetPosition(decoded));
            }
            if let Ok(decoded) =
                <_GetReserveCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::_GetReserve(decoded));
            }
            if let Ok(decoded) =
                <FailedCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::Failed(decoded));
            }
            if let Ok(decoded) =
                <GetBalanceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::GetBalance(decoded));
            }
            if let Ok(decoded) =
                <GetBalanceSumCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::GetBalanceSum(decoded));
            }
            if let Ok(decoded) =
                <GetCurveCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::GetCurve(decoded));
            }
            if let Ok(decoded) =
                <GetMaxSwapLimitCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::GetMaxSwapLimit(decoded));
            }
            if let Ok(decoded) =
                <GetPairCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::GetPair(decoded));
            }
            if let Ok(decoded) =
                <GetPhysicalBalanceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::GetPhysicalBalance(decoded));
            }
            if let Ok(decoded) =
                <GetPoolCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::GetPool(decoded));
            }
            if let Ok(decoded) =
                <GetPositionCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::GetPosition(decoded));
            }
            if let Ok(decoded) =
                <GetPositionLiquiditySumCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                )
            {
                return Ok(InvariantWarperCalls::GetPositionLiquiditySum(decoded));
            }
            if let Ok(decoded) =
                <GetReserveCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::GetReserve(decoded));
            }
            if let Ok(decoded) =
                <GetStateCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::GetState(decoded));
            }
            if let Ok(decoded) =
                <GetVirtualBalanceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::GetVirtualBalance(decoded));
            }
            if let Ok(decoded) =
                <WarpAfterMaturityCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::WarpAfterMaturity(decoded));
            }
            if let Ok(decoded) =
                <WarperCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantWarperCalls::Warper(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for InvariantWarperCalls {
        fn encode(self) -> Vec<u8> {
            match self {
                InvariantWarperCalls::IsTest(element) => element.encode(),
                InvariantWarperCalls::Asset(element) => element.encode(),
                InvariantWarperCalls::Hyper(element) => element.encode(),
                InvariantWarperCalls::PoolId(element) => element.encode(),
                InvariantWarperCalls::Quote(element) => element.encode(),
                InvariantWarperCalls::_GetBalance(element) => element.encode(),
                InvariantWarperCalls::_GetPool(element) => element.encode(),
                InvariantWarperCalls::_GetPosition(element) => element.encode(),
                InvariantWarperCalls::_GetReserve(element) => element.encode(),
                InvariantWarperCalls::Failed(element) => element.encode(),
                InvariantWarperCalls::GetBalance(element) => element.encode(),
                InvariantWarperCalls::GetBalanceSum(element) => element.encode(),
                InvariantWarperCalls::GetCurve(element) => element.encode(),
                InvariantWarperCalls::GetMaxSwapLimit(element) => element.encode(),
                InvariantWarperCalls::GetPair(element) => element.encode(),
                InvariantWarperCalls::GetPhysicalBalance(element) => element.encode(),
                InvariantWarperCalls::GetPool(element) => element.encode(),
                InvariantWarperCalls::GetPosition(element) => element.encode(),
                InvariantWarperCalls::GetPositionLiquiditySum(element) => element.encode(),
                InvariantWarperCalls::GetReserve(element) => element.encode(),
                InvariantWarperCalls::GetState(element) => element.encode(),
                InvariantWarperCalls::GetVirtualBalance(element) => element.encode(),
                InvariantWarperCalls::WarpAfterMaturity(element) => element.encode(),
                InvariantWarperCalls::Warper(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for InvariantWarperCalls {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                InvariantWarperCalls::IsTest(element) => element.fmt(f),
                InvariantWarperCalls::Asset(element) => element.fmt(f),
                InvariantWarperCalls::Hyper(element) => element.fmt(f),
                InvariantWarperCalls::PoolId(element) => element.fmt(f),
                InvariantWarperCalls::Quote(element) => element.fmt(f),
                InvariantWarperCalls::_GetBalance(element) => element.fmt(f),
                InvariantWarperCalls::_GetPool(element) => element.fmt(f),
                InvariantWarperCalls::_GetPosition(element) => element.fmt(f),
                InvariantWarperCalls::_GetReserve(element) => element.fmt(f),
                InvariantWarperCalls::Failed(element) => element.fmt(f),
                InvariantWarperCalls::GetBalance(element) => element.fmt(f),
                InvariantWarperCalls::GetBalanceSum(element) => element.fmt(f),
                InvariantWarperCalls::GetCurve(element) => element.fmt(f),
                InvariantWarperCalls::GetMaxSwapLimit(element) => element.fmt(f),
                InvariantWarperCalls::GetPair(element) => element.fmt(f),
                InvariantWarperCalls::GetPhysicalBalance(element) => element.fmt(f),
                InvariantWarperCalls::GetPool(element) => element.fmt(f),
                InvariantWarperCalls::GetPosition(element) => element.fmt(f),
                InvariantWarperCalls::GetPositionLiquiditySum(element) => element.fmt(f),
                InvariantWarperCalls::GetReserve(element) => element.fmt(f),
                InvariantWarperCalls::GetState(element) => element.fmt(f),
                InvariantWarperCalls::GetVirtualBalance(element) => element.fmt(f),
                InvariantWarperCalls::WarpAfterMaturity(element) => element.fmt(f),
                InvariantWarperCalls::Warper(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<IsTestCall> for InvariantWarperCalls {
        fn from(var: IsTestCall) -> Self {
            InvariantWarperCalls::IsTest(var)
        }
    }
    impl ::std::convert::From<AssetCall> for InvariantWarperCalls {
        fn from(var: AssetCall) -> Self {
            InvariantWarperCalls::Asset(var)
        }
    }
    impl ::std::convert::From<HyperCall> for InvariantWarperCalls {
        fn from(var: HyperCall) -> Self {
            InvariantWarperCalls::Hyper(var)
        }
    }
    impl ::std::convert::From<PoolIdCall> for InvariantWarperCalls {
        fn from(var: PoolIdCall) -> Self {
            InvariantWarperCalls::PoolId(var)
        }
    }
    impl ::std::convert::From<QuoteCall> for InvariantWarperCalls {
        fn from(var: QuoteCall) -> Self {
            InvariantWarperCalls::Quote(var)
        }
    }
    impl ::std::convert::From<_GetBalanceCall> for InvariantWarperCalls {
        fn from(var: _GetBalanceCall) -> Self {
            InvariantWarperCalls::_GetBalance(var)
        }
    }
    impl ::std::convert::From<_GetPoolCall> for InvariantWarperCalls {
        fn from(var: _GetPoolCall) -> Self {
            InvariantWarperCalls::_GetPool(var)
        }
    }
    impl ::std::convert::From<_GetPositionCall> for InvariantWarperCalls {
        fn from(var: _GetPositionCall) -> Self {
            InvariantWarperCalls::_GetPosition(var)
        }
    }
    impl ::std::convert::From<_GetReserveCall> for InvariantWarperCalls {
        fn from(var: _GetReserveCall) -> Self {
            InvariantWarperCalls::_GetReserve(var)
        }
    }
    impl ::std::convert::From<FailedCall> for InvariantWarperCalls {
        fn from(var: FailedCall) -> Self {
            InvariantWarperCalls::Failed(var)
        }
    }
    impl ::std::convert::From<GetBalanceCall> for InvariantWarperCalls {
        fn from(var: GetBalanceCall) -> Self {
            InvariantWarperCalls::GetBalance(var)
        }
    }
    impl ::std::convert::From<GetBalanceSumCall> for InvariantWarperCalls {
        fn from(var: GetBalanceSumCall) -> Self {
            InvariantWarperCalls::GetBalanceSum(var)
        }
    }
    impl ::std::convert::From<GetCurveCall> for InvariantWarperCalls {
        fn from(var: GetCurveCall) -> Self {
            InvariantWarperCalls::GetCurve(var)
        }
    }
    impl ::std::convert::From<GetMaxSwapLimitCall> for InvariantWarperCalls {
        fn from(var: GetMaxSwapLimitCall) -> Self {
            InvariantWarperCalls::GetMaxSwapLimit(var)
        }
    }
    impl ::std::convert::From<GetPairCall> for InvariantWarperCalls {
        fn from(var: GetPairCall) -> Self {
            InvariantWarperCalls::GetPair(var)
        }
    }
    impl ::std::convert::From<GetPhysicalBalanceCall> for InvariantWarperCalls {
        fn from(var: GetPhysicalBalanceCall) -> Self {
            InvariantWarperCalls::GetPhysicalBalance(var)
        }
    }
    impl ::std::convert::From<GetPoolCall> for InvariantWarperCalls {
        fn from(var: GetPoolCall) -> Self {
            InvariantWarperCalls::GetPool(var)
        }
    }
    impl ::std::convert::From<GetPositionCall> for InvariantWarperCalls {
        fn from(var: GetPositionCall) -> Self {
            InvariantWarperCalls::GetPosition(var)
        }
    }
    impl ::std::convert::From<GetPositionLiquiditySumCall> for InvariantWarperCalls {
        fn from(var: GetPositionLiquiditySumCall) -> Self {
            InvariantWarperCalls::GetPositionLiquiditySum(var)
        }
    }
    impl ::std::convert::From<GetReserveCall> for InvariantWarperCalls {
        fn from(var: GetReserveCall) -> Self {
            InvariantWarperCalls::GetReserve(var)
        }
    }
    impl ::std::convert::From<GetStateCall> for InvariantWarperCalls {
        fn from(var: GetStateCall) -> Self {
            InvariantWarperCalls::GetState(var)
        }
    }
    impl ::std::convert::From<GetVirtualBalanceCall> for InvariantWarperCalls {
        fn from(var: GetVirtualBalanceCall) -> Self {
            InvariantWarperCalls::GetVirtualBalance(var)
        }
    }
    impl ::std::convert::From<WarpAfterMaturityCall> for InvariantWarperCalls {
        fn from(var: WarpAfterMaturityCall) -> Self {
            InvariantWarperCalls::WarpAfterMaturity(var)
        }
    }
    impl ::std::convert::From<WarperCall> for InvariantWarperCalls {
        fn from(var: WarperCall) -> Self {
            InvariantWarperCalls::Warper(var)
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
