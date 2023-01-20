pub use invariant_create_pool::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod invariant_create_pool {
    #![allow(clippy::enum_variant_names)]
    #![allow(dead_code)]
    #![allow(clippy::type_complexity)]
    #![allow(unused_imports)]
    ///InvariantCreatePool was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
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
    const __ABI: &str = "[{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper_\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"asset_\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"quote_\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"constructor\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidBalance\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_address\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint256[]\",\"name\":\"val\",\"type\":\"uint256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"int256[]\",\"name\":\"val\",\"type\":\"int256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address[]\",\"name\":\"val\",\"type\":\"address[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"\",\"type\":\"bytes\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_bytes\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_bytes32\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"int256\",\"name\":\"\",\"type\":\"int256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_int\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"val\",\"type\":\"address\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_address\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256[]\",\"name\":\"val\",\"type\":\"uint256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"int256[]\",\"name\":\"val\",\"type\":\"int256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"address[]\",\"name\":\"val\",\"type\":\"address[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"bytes\",\"name\":\"val\",\"type\":\"bytes\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_bytes\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"bytes32\",\"name\":\"val\",\"type\":\"bytes32\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_bytes32\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"int256\",\"name\":\"val\",\"type\":\"int256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"decimals\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_decimal_int\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"val\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"decimals\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_decimal_uint\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"int256\",\"name\":\"val\",\"type\":\"int256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_int\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"string\",\"name\":\"val\",\"type\":\"string\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_string\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"val\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_uint\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_string\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_uint\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"\",\"type\":\"bytes\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"logs\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"IS_TEST\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__asset__\",\"outputs\":[{\"internalType\":\"contract TestERC20\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__hyper__\",\"outputs\":[{\"internalType\":\"contract HyperTimeOverride\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__poolId__\",\"outputs\":[{\"internalType\":\"uint64\",\"name\":\"\",\"type\":\"uint64\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__quote__\",\"outputs\":[{\"internalType\":\"contract TestERC20\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"contract HyperLike\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"contract TestERC20\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"contract IHyperStruct\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getPool\",\"outputs\":[{\"internalType\":\"struct HyperPool\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"lastTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"lastTimestamp\",\"type\":\"uint32\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"controller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalReward\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"lastPrice\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"liquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"int128\",\"name\":\"stakedLiquidityDelta\",\"type\":\"int128\",\"components\":[]},{\"internalType\":\"struct HyperCurve\",\"name\":\"params\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]},{\"internalType\":\"struct HyperPair\",\"name\":\"pair\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]}]},{\"inputs\":[{\"internalType\":\"contract IHyperStruct\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"positionId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getPosition\",\"outputs\":[{\"internalType\":\"struct HyperPosition\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"uint128\",\"name\":\"freeLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"lastTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"stakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"unstakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthRewardLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuoteLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedQuote\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedReward\",\"type\":\"uint128\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"contract HyperLike\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"contract TestERC20\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getReserve\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"index\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"price\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"strike\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint24\",\"name\":\"sigma\",\"type\":\"uint24\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"maturity\",\"type\":\"uint32\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"gamma\",\"type\":\"uint32\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"priorityGamma\",\"type\":\"uint32\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"create_pool\",\"outputs\":[]},{\"inputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"failed\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getBalanceSum\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getCurve\",\"outputs\":[{\"internalType\":\"struct HyperCurve\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"bool\",\"name\":\"sellAsset\",\"type\":\"bool\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getMaxSwapLimit\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint24\",\"name\":\"pairId\",\"type\":\"uint24\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPair\",\"outputs\":[{\"internalType\":\"struct HyperPair\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPhysicalBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPool\",\"outputs\":[{\"internalType\":\"struct HyperPool\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"lastTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"lastTimestamp\",\"type\":\"uint32\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"controller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalReward\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"lastPrice\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"liquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"int128\",\"name\":\"stakedLiquidityDelta\",\"type\":\"int128\",\"components\":[]},{\"internalType\":\"struct HyperCurve\",\"name\":\"params\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]},{\"internalType\":\"struct HyperPair\",\"name\":\"pair\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"positionId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPosition\",\"outputs\":[{\"internalType\":\"struct HyperPosition\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"uint128\",\"name\":\"freeLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"lastTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"stakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"unstakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthRewardLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuoteLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedQuote\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedReward\",\"type\":\"uint128\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPositionLiquiditySum\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getReserve\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"caller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getState\",\"outputs\":[{\"internalType\":\"struct HyperState\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"uint256\",\"name\":\"reserveAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"reserveQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"physicalBalanceAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"physicalBalanceQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalBalanceAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalBalanceQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalPositionLiquidity\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"callerPositionLiquidity\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalPoolLiquidity\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetPool\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuotePool\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetPosition\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuotePosition\",\"type\":\"uint256\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getVirtualBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]}]";
    /// The parsed JSON-ABI of the contract.
    pub static INVARIANTCREATEPOOL_ABI: ::ethers::contract::Lazy<
        ::ethers::core::abi::Abi,
    > = ::ethers::contract::Lazy::new(|| {
        ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi")
    });
    /// Bytecode of the #name contract
    pub static INVARIANTCREATEPOOL_BYTECODE: ::ethers::contract::Lazy<
        ::ethers::core::types::Bytes,
    > = ::ethers::contract::Lazy::new(|| {
        "0x60806040526000805460ff1916600117905560138054790100000000010000000000000000000000000000000000000000600160a01b600160e01b03199091161790553480156200004f57600080fd5b506040516200317738038062003177833981016040819052620000729162000231565b60138054336001600160a01b0319918216179091556014805482166001600160a01b03868116918217909255601680548416868416908117909155601580549094169285169290921790925560405163095ea7b360e01b81526004810192909252600019602483015284918491849163095ea7b3906044016020604051808303816000875af11580156200010a573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906200013091906200027b565b5060155460405163095ea7b360e01b81526001600160a01b03858116600483015260001960248301529091169063095ea7b3906044016020604051808303816000875af115801562000186573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190620001ac91906200027b565b50505050604051620001be9062000206565b604051809103906000f080158015620001db573d6000803e3d6000fd5b50601780546001600160a01b0319166001600160a01b039290921691909117905550620002a6915050565b6102028062002f7583390190565b80516001600160a01b03811681146200022c57600080fd5b919050565b6000806000606084860312156200024757600080fd5b620002528462000214565b9250620002626020850162000214565b9150620002726040850162000214565b90509250925092565b6000602082840312156200028e57600080fd5b815180151581146200029f57600080fd5b9392505050565b612cbf80620002b66000396000f3fe608060405234801561001057600080fd5b506004361061014d5760003560e01c8063c6a68a47116100c3578063d83410b61161007c578063d83410b6146102cb578063dc723804146102eb578063dd05e299146102eb578063f3140b1e1461030b578063fa7626d4146103b1578063ff314c0a146103be57600080fd5b8063c6a68a4714610260578063cbc3ab53146101bb578063cee2aaf514610292578063cf7dee1f146102a5578063d43c0f99146102b8578063d6bd603c146102a557600080fd5b8063634e05e011610115578063634e05e0146101dc5780636dce537d146101ef5780637b135ad1146102025780638828200d146102225780638dbc965114610235578063ba414fa61461024857600080fd5b806309deb4d314610152578063273c329f146101525780633c07bc651461017b5780633e81296e146101905780635a8be8b0146101bb575b600080fd5b610165610160366004611ec9565b6103d1565b6040516101729190611f5b565b60405180910390f35b61018e6101893660046120a7565b610500565b005b6014546101a3906001600160a01b031681565b6040516001600160a01b039091168152602001610172565b6101ce6101c9366004612134565b61093d565b604051908152602001610172565b6101ce6101ea366004612134565b6109ab565b6101ce6101fd366004612272565b6109b7565b6102156102103660046122d3565b6109e4565b6040516101729190612301565b6101ce610230366004612342565b610a75565b6015546101a3906001600160a01b031681565b610250610ad6565b6040519015158152602001610172565b60135461027a90600160a01b90046001600160401b031681565b6040516001600160401b039091168152602001610172565b6101ce6102a036600461237e565b610c01565b6101ce6102b336600461239b565b610c1a565b6016546101a3906001600160a01b031681565b6102de6102d9366004611ec9565b610c98565b60405161017291906123e6565b6102fe6102f93660046123f4565b610ce8565b604051610172919061243b565b61031e6103193660046124ed565b610dec565b6040516101729190815181526020808301519082015260408083015190820152606080830151908201526080808301519082015260a0808301519082015260c0808301519082015260e08083015190820152610100808301519082015261012080830151908201526101408083015190820152610160808301519082015261018091820151918101919091526101a00190565b6000546102509060ff1681565b6101ce6103cc366004612272565b610f6d565b6104856040805161018081018252600080825260208083018290528284018290526060808401839052608080850184905260a080860185905260c080870186905260e0808801879052610100880187905261012088018790528851908101895286815294850186905296840185905291830184905282018390528101829052928301529061014082019081526040805160808101825260008082526020828101829052928201819052606082015291015290565b6040516322697c2160e21b81526001600160401b03831660048201526001600160a01b038416906389a5f084906024016102a060405180830381865afa1580156104d3573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906104f79190612701565b90505b92915050565b604051632631f2b160e11b81526001600160801b03861615156004820152737109709ecfa91a80626ff3989d68f67f5b1dd12d90634c63e5629060240160006040518083038186803b15801561055557600080fd5b505afa158015610569573d6000803e3d6000fd5b5050604051632631f2b160e11b815262ffffff871615156004820152737109709ecfa91a80626ff3989d68f67f5b1dd12d9250634c63e562915060240160006040518083038186803b1580156105be57600080fd5b505afa1580156105d2573d6000803e3d6000fd5b505050506105ec8363ffffffff1660016301e13380610fbb565b6105f690426127f1565b925061061c866001600160801b031660016ec097ce7bc90715b34b9f1000000000610fbb565b955061064762ffffff85166106356103e8612710612809565b6106426001612710612809565b610fbb565b915061066662ffffff851663ffffffff84166106426001612710612809565b601354604051631ad9ed5760e21b8152600481018a90529192506000916001600160a01b0390911690636b67b55c90602401602060405180830381865afa1580156106b5573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906106d99190612820565b60408051600380825260808201909252919250600091906020820160608036833750506013546040805163d43c0f9960e01b815290519394506001600160a01b039091169263d43c0f99925060048083019260209291908290030181865afa158015610749573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061076d9190612820565b816000815181106107805761078061283d565b6001600160a01b0392831660209182029290920181019190915260135460408051638dbc965160e01b815290519190931692638dbc96519260048083019391928290030181865afa1580156107d9573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906107fd9190612820565b816001815181106108105761081061283d565b60200260200101906001600160a01b031690816001600160a01b031681525050600061083c8a83610ff8565b90506000816000815181106108535761085361283d565b602002602001015190506000826001815181106108725761087261283d565b602002602001015190506108bd816001600160a01b0316836001600160a01b031614156040518060400160405280600a81526020016939b0b6b296ba37b5b2b760b11b8152506110e5565b60408051610120810182526001600160a01b03808816825284811660208301528316918101919091526001600160801b03808d1660608301528b16608082015262ffffff8a1660a082015263ffffffff808a1660c083015288811660e0830152871661010082015261092e8161112e565b50505050505050505050505050565b60405163c9a396e960e01b81526001600160a01b0382811660048301526000919084169063c9a396e990602401602060405180830381865afa158015610987573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906104f79190612853565b60006104f78284611693565b6000806109c5858585610f6d565b6109cf868661093d565b6109d991906127f1565b9150505b9392505050565b604080516080810182526000808252602082018190529181018290526060810191909152604051631791d98f60e21b815262ffffff831660048201526001600160a01b03841690635e47663c90602401608060405180830381865afa158015610a51573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906104f7919061286c565b60008060005b83518114610acd57610aa786858381518110610a9957610a9961283d565b602002602001015187610ce8565b51610abb906001600160801b0316836127f1565b9150610ac681612888565b9050610a7b565b50949350505050565b60008054610100900460ff1615610af65750600054610100900460ff1690565b6000737109709ecfa91a80626ff3989d68f67f5b1dd12d3b15610bfc5760408051737109709ecfa91a80626ff3989d68f67f5b1dd12d602082018190526519985a5b195960d21b82840152825180830384018152606083019093526000929091610b84917f667f9d70ca411d70ead50d8d5c22070dafc36ad75f3dcf5e7237b22ade9aecc4916080016128d1565b60408051601f1981840301815290829052610b9e91612902565b6000604051808303816000865af19150503d8060008114610bdb576040519150601f19603f3d011682016040523d82523d6000602084013e610be0565b606091505b5091505080806020019051810190610bf8919061291e565b9150505b919050565b60008115610c1157506000919050565b50600019919050565b60405163d4fac45d60e01b81526001600160a01b03838116600483015282811660248301526000919085169063d4fac45d90604401602060405180830381865afa158015610c6c573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610c909190612853565b949350505050565b6040805160e081018252600080825260208201819052918101829052606081018290526080810182905260a0810182905260c0810182905290610cdb84846103d1565b6101400151949350505050565b610d7260405180610160016040528060006001600160801b0316815260200160006001600160801b0316815260200160008152602001600081526020016000815260200160008152602001600081526020016000815260200160006001600160801b0316815260200160006001600160801b0316815260200160006001600160801b031681525090565b604051635b4289f560e11b81526001600160a01b0384811660048301526001600160401b038416602483015285169063b68513ea9060440161016060405180830381865afa158015610dc8573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610c90919061293b565b610e57604051806101a00160405280600081526020016000815260200160008152602001600081526020016000815260200160008152602001600081526020016000815260200160008152602001600081526020016000815260200160008152602001600081525090565b6000610e6c86602887901c62ffffff166109e4565b80516040820151919250906000610e8389896103d1565b90506000610e928a898b610ce8565b90506000604051806101a00160405280610eac8d8861093d565b8152602001610ebb8d8761093d565b8152602001610eca8d886109ab565b8152602001610ed98d876109ab565b8152602001610ee98d888c610f6d565b8152602001610ef98d878c610f6d565b8152602001610f098d8d8c610a75565b815260200183600001516001600160801b031681526020018460e001516001600160801b03168152602001846080015181526020018460a0015181526020018360c0015181526020018360e001518152509050809650505050505050949350505050565b60008060005b83518114610acd57610f9f86858381518110610f9157610f9161283d565b602002602001015187610c1a565b610fa990836127f1565b9150610fb481612888565b9050610f73565b6000610fc884848461177c565b90506109dd6040518060400160405280600c81526020016b109bdd5b990814995cdd5b1d60a21b81525082611944565b606060005b82518110156110dd5760008184516110159190612809565b61101f90866129eb565b61102990836127f1565b9050600084828151811061103f5761103f61283d565b6020026020010151905084838151811061105b5761105b61283d565b60200260200101518583815181106110755761107561283d565b60200260200101906001600160a01b031690816001600160a01b031681525050808584815181106110a8576110a861283d565b60200260200101906001600160a01b031690816001600160a01b031681525050505080806110d590612888565b915050610ffd565b509092915050565b8161112a577f280f4446b28a1372417dda658d30b95b2992b12ac9c7f378535f29a97acf3583816040516111199190612a39565b60405180910390a161112a826119eb565b5050565b60145460208201516040808401519051633f92a33960e01b81526001600160a01b03928316600482015290821660248201526001926000921690633f92a33990604401602060405180830381865afa15801561118e573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906111b29190612a68565b90508062ffffff1660000361123f5760186112188460200151856040015160408051600360fa1b60208201526bffffffffffffffffffffffff19606094851b811660218301529290931b9091166035830152805160298184030181526049909201905290565b81546001810183556000928352602092839020825161123d9491909201920190611d8f565b505b601861125b82306001806001806005614e208c60600151611a62565b8154600181018355600092835260209283902082516112809491909201920190611d8f565b50600061135d6018805480602002602001604051908101604052809291908181526020016000905b828210156113545783829060005260206000200180546112c790612a85565b80601f01602080910402602001604051908101604052809291908181526020018280546112f390612a85565b80156113405780601f1061131557610100808354040283529160200191611340565b820191906000526020600020905b81548152906001019060200180831161132357829003601f168201915b5050505050815260200190600101906112a8565b50505050611aaa565b845160405163ca669fa760e01b81526001600160a01b039091166004820152909150737109709ecfa91a80626ff3989d68f67f5b1dd12d9063ca669fa790602401600060405180830381600087803b1580156113b857600080fd5b505af11580156113cc573d6000803e3d6000fd5b505050506113d981611ba9565b60145460405160009182916001600160a01b03909116906113fb908590612902565b6000604051808303816000865af19150503d8060008114611438576040519150601f19603f3d011682016040523d82523d6000602084013e61143d565b606091505b5091509150805181602001a061147c82604051806040016040528060118152602001701a1e5c195c8b58d85b1b0b59985a5b1959607a1b8152506110e5565b60145460208701516040808901519051633f92a33960e01b81526001600160a01b0392831660048201529082166024820152911690633f92a33990604401602060405180830381865afa1580156114d7573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906114fb9190612a68565b93506115388462ffffff16600014156040518060400160405280601081526020016f1c185a5c8b5b9bdd0b58dc99585d195960821b8152506110e5565b60006115bb8587601460009054906101000a90046001600160a01b03166001600160a01b031663fd2dbea16040518163ffffffff1660e01b8152600401602060405180830381865afa158015611592573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906115b69190612853565b611bec565b601454909150611616906115d8906001600160a01b0316836103d1565b60c001516001600160801b0316600014156040518060400160405280600f81526020016e706f6f6c2d70726963652d7a65726f60881b8152506110e5565b60135460405163ce5b07c360e01b81526001600160401b03831660048201526001600160a01b039091169063ce5b07c390602401600060405180830381600087803b15801561166457600080fd5b505af1158015611678573d6000803e3d6000fd5b505050506018600061168a9190611e13565b50505050505050565b604080516001600160a01b0383811660248084019190915283518084039091018152604490920183526020820180516001600160e01b03166370a0823160e01b179052915160009283928392918716916116ed9190612902565b600060405180830381855afa9150503d8060008114611728576040519150601f19603f3d011682016040523d82523d6000602084013e61172d565b606091505b509150915081158061174157508051602014155b1561175f5760405163c52e3eff60e01b815260040160405180910390fd5b808060200190518101906117739190612853565b95945050505050565b6000818311156117f85760405162461bcd60e51b815260206004820152603e60248201527f5374645574696c7320626f756e642875696e743235362c75696e743235362c7560448201527f696e74323536293a204d6178206973206c657373207468616e206d696e2e0000606482015260840160405180910390fd5b8284101580156118085750818411155b156118145750826109dd565b60006118208484612809565b61182b9060016127f1565b90506003851115801561183d57508481115b156118545761184c85856127f1565b9150506109dd565b6118616003600019612809565b851015801561187a575061187785600019612809565b81115b156118955761188b85600019612809565b61184c9084612809565b828511156118eb5760006118a98487612809565b905060006118b783836129eb565b9050806000036118cc578493505050506109dd565b60016118d882886127f1565b6118e29190612809565b9350505061193c565b8385101561193c5760006118ff8686612809565b9050600061190d83836129eb565b905080600003611922578593505050506109dd565b61192c8186612809565b6119379060016127f1565b935050505b509392505050565b60006a636f6e736f6c652e6c6f676001600160a01b0316838360405160240161196e929190612abf565b60408051601f198184030181529181526020820180516001600160e01b0316632d839cb360e21b179052516119a39190612902565b600060405180830381855afa9150503d80600081146119de576040519150601f19603f3d011682016040523d82523d6000602084013e6119e3565b606091505b505050505050565b80611a5f577f41304facd9323d75b11bcdd609cb38effffdb05710f7caf0e9b16c6d9d709f50604051611a4f9060208082526017908201527f4572726f723a20417373657274696f6e204661696c6564000000000000000000604082015260600190565b60405180910390a1611a5f611c62565b50565b604051606090611a8c90600b60f81b908c908c908c908c908c908c908c908c908c90602001612ae1565b60405160208183030381529060405290509998505050505050505050565b805160408051605560f91b602082015260f883901b6001600160f81b0319166021820152815160028183030181526022909101909152606091600091825b8260ff168114610acd576000868281518110611b0657611b0661283d565b6020026020010151905060008151905082600003611b3057611b29816003612bba565b9550611b48565b611b3a8187612bba565b611b45906001612bba565b95505b60008660f81b83604051602001611b60929190612bdf565b60405160208183030381529060405290508481604051602001611b84929190612c10565b604051602081830303815290604052945050505080611ba290612888565b9050611ae8565b611a5f81604051602401611bbd9190612c3f565b60408051601f198184030181529190526020810180516001600160e01b03166305f3bfab60e11b179052611d6e565b60008383611bfb576000611bfe565b60015b60405160e89290921b6001600160e81b031916602083015260f81b6001600160f81b031916602382015260e083901b6001600160e01b0319166024820152602801604051602081830303815290604052611c5790612c52565b60c01c949350505050565b737109709ecfa91a80626ff3989d68f67f5b1dd12d3b15611d5d5760408051737109709ecfa91a80626ff3989d68f67f5b1dd12d602082018190526519985a5b195960d21b9282019290925260016060820152600091907f70ca10bbd0dbfd9020a9f4b13402c16cb120705e0d1c0aeab10fa353ae586fc49060800160408051601f1981840301815290829052611cfc92916020016128d1565b60408051601f1981840301815290829052611d1691612902565b6000604051808303816000865af19150503d8060008114611d53576040519150601f19603f3d011682016040523d82523d6000602084013e611d58565b606091505b505050505b6000805461ff001916610100179055565b80516a636f6e736f6c652e6c6f67602083016000808483855afa5050505050565b828054611d9b90612a85565b90600052602060002090601f016020900481019282611dbd5760008555611e03565b82601f10611dd657805160ff1916838001178555611e03565b82800160010185558215611e03579182015b82811115611e03578251825591602001919060010190611de8565b50611e0f929150611e31565b5090565b5080546000825590600052602060002090810190611a5f9190611e46565b5b80821115611e0f5760008155600101611e32565b80821115611e0f576000611e5a8282611e63565b50600101611e46565b508054611e6f90612a85565b6000825580601f10611e7f575050565b601f016020900490600052602060002090810190611a5f9190611e31565b6001600160a01b0381168114611a5f57600080fd5b80356001600160401b0381168114610bfc57600080fd5b60008060408385031215611edc57600080fd5b8235611ee781611e9d565b9150611ef560208401611eb2565b90509250929050565b805160020b8252602081015161ffff80821660208501528060408401511660408501528060608401511660608501528060808401511660808501528060a08401511660a0850152505063ffffffff60c08201511660c08301525050565b815160020b81526102a081016020830151611f7e602084018263ffffffff169052565b506040830151611f9960408401826001600160a01b03169052565b50606083015160608301526080830151608083015260a083015160a083015260c0830151611fd260c08401826001600160801b03169052565b5060e0830151611fed60e08401826001600160801b03169052565b50610100838101516001600160801b03169083015261012080840151600f0b908301526101408084015161202382850182611efe565b505061016083015180516001600160a01b03908116610220850152602082015160ff90811661024086015260408301519091166102608501526060820151166102808401525092915050565b6001600160801b0381168114611a5f57600080fd5b62ffffff81168114611a5f57600080fd5b63ffffffff81168114611a5f57600080fd5b600080600080600080600060e0888a0312156120c257600080fd5b8735965060208801356120d48161206f565b955060408801356120e48161206f565b945060608801356120f481612084565b9350608088013561210481612095565b925060a088013561211481612095565b915060c088013561212481612095565b8091505092959891949750929550565b6000806040838503121561214757600080fd5b823561215281611e9d565b9150602083013561216281611e9d565b809150509250929050565b634e487b7160e01b600052604160045260246000fd5b60405161018081016001600160401b03811182821017156121a6576121a661216d565b60405290565b60405161016081016001600160401b03811182821017156121a6576121a661216d565b600082601f8301126121e057600080fd5b813560206001600160401b03808311156121fc576121fc61216d565b8260051b604051601f19603f830116810181811084821117156122215761222161216d565b60405293845285810183019383810192508785111561223f57600080fd5b83870191505b8482101561226757813561225881611e9d565b83529183019190830190612245565b979650505050505050565b60008060006060848603121561228757600080fd5b833561229281611e9d565b925060208401356122a281611e9d565b915060408401356001600160401b038111156122bd57600080fd5b6122c9868287016121cf565b9150509250925092565b600080604083850312156122e657600080fd5b82356122f181611e9d565b9150602083013561216281612084565b608081016104fa828460018060a01b0380825116835260ff60208301511660208401528060408301511660408401525060ff60608201511660608301525050565b60008060006060848603121561235757600080fd5b833561236281611e9d565b92506122a260208501611eb2565b8015158114611a5f57600080fd5b60006020828403121561239057600080fd5b81356109dd81612370565b6000806000606084860312156123b057600080fd5b83356123bb81611e9d565b925060208401356123cb81611e9d565b915060408401356123db81611e9d565b809150509250925092565b60e081016104fa8284611efe565b60008060006060848603121561240957600080fd5b833561241481611e9d565b9250602084013561242481611e9d565b915061243260408501611eb2565b90509250925092565b81516001600160801b031681526101608101602083015161246760208401826001600160801b03169052565b5060408301516040830152606083015160608301526080830151608083015260a083015160a083015260c083015160c083015260e083015160e0830152610100808401516124bf828501826001600160801b03169052565b5050610120838101516001600160801b03908116918401919091526101409384015116929091019190915290565b6000806000806080858703121561250357600080fd5b843561250e81611e9d565b935061251c60208601611eb2565b9250604085013561252c81611e9d565b915060608501356001600160401b0381111561254757600080fd5b612553878288016121cf565b91505092959194509250565b8051600281900b8114610bfc57600080fd5b8051610bfc81612095565b8051610bfc81611e9d565b8051610bfc8161206f565b8051600f81900b8114610bfc57600080fd5b805161ffff81168114610bfc57600080fd5b600060e082840312156125c857600080fd5b60405160e081018181106001600160401b03821117156125ea576125ea61216d565b6040529050806125f98361255f565b8152612607602084016125a4565b6020820152612618604084016125a4565b6040820152612629606084016125a4565b606082015261263a608084016125a4565b608082015261264b60a084016125a4565b60a082015260c083015161265e81612095565b60c0919091015292915050565b805160ff81168114610bfc57600080fd5b60006080828403121561268e57600080fd5b604051608081018181106001600160401b03821117156126b0576126b061216d565b806040525080915082516126c381611e9d565b81526126d16020840161266b565b602082015260408301516126e481611e9d565b60408201526126f56060840161266b565b60608201525092915050565b60006102a0828403121561271457600080fd5b61271c612183565b6127258361255f565b815261273360208401612571565b60208201526127446040840161257c565b6040820152606083015160608201526080830151608082015260a083015160a082015261277360c08401612587565b60c082015261278460e08401612587565b60e0820152610100612797818501612587565b908201526101206127a9848201612592565b908201526101406127bc858583016125b6565b908201526127ce84610220850161267c565b6101608201529392505050565b634e487b7160e01b600052601160045260246000fd5b60008219821115612804576128046127db565b500190565b60008282101561281b5761281b6127db565b500390565b60006020828403121561283257600080fd5b81516109dd81611e9d565b634e487b7160e01b600052603260045260246000fd5b60006020828403121561286557600080fd5b5051919050565b60006080828403121561287e57600080fd5b6104f7838361267c565b60006001820161289a5761289a6127db565b5060010190565b60005b838110156128bc5781810151838201526020016128a4565b838111156128cb576000848401525b50505050565b6001600160e01b03198316815281516000906128f48160048501602087016128a1565b919091016004019392505050565b600082516129148184602087016128a1565b9190910192915050565b60006020828403121561293057600080fd5b81516109dd81612370565b6000610160828403121561294e57600080fd5b6129566121ac565b61295f83612587565b815261296d60208401612587565b602082015260408301516040820152606083015160608201526080830151608082015260a083015160a082015260c083015160c082015260e083015160e08201526101006129bc818501612587565b908201526101206129ce848201612587565b908201526101406129e0848201612587565b908201529392505050565b600082612a0857634e487b7160e01b600052601260045260246000fd5b500690565b60008151808452612a258160208601602086016128a1565b601f01601f19169290920160200192915050565b60408152600560408201526422b93937b960d91b60608201526080602082015260006104f76080830184612a0d565b600060208284031215612a7a57600080fd5b81516109dd81612084565b600181811c90821680612a9957607f821691505b602082108103612ab957634e487b7160e01b600052602260045260246000fd5b50919050565b604081526000612ad26040830185612a0d565b90508260208301529392505050565b6001600160f81b03198b1681526001600160e81b031960e88b901b1660018201526bffffffffffffffffffffffff1960608a901b1660048201526001600160f01b031960f089811b8216601884015288811b8216601a84015287901b16601c8201526000612b5e601e83018760f01b6001600160f01b0319169052565b612b77602083018660f01b6001600160f01b0319169052565b612b86602283018560e81b9052565b612ba8602583018460801b6fffffffffffffffffffffffffffffffff19169052565b506035019a9950505050505050505050565b600060ff821660ff84168060ff03821115612bd757612bd76127db565b019392505050565b6001600160f81b0319831681528151600090612c028160018501602087016128a1565b919091016001019392505050565b60008351612c228184602088016128a1565b835190830190612c368183602088016128a1565b01949350505050565b6020815260006104f76020830184612a0d565b805160208201516001600160c01b03198082169291906008831015612c815780818460080360031b1b83161693505b50505091905056fea26469706673582212208585a2da3e47a8ffac2ee2fb026a0c248b1f32beaff13244876b0c5f01c3dedb64736f6c634300080d0033608060405234801561001057600080fd5b506101e2806100206000396000f3fe60806040526004361061001e5760003560e01c80636fadcf7214610023575b600080fd5b6100366100313660046100ec565b61004a565b604051901515815260200160405180910390f35b6000836001600160a01b031663e82b84b43485856040518463ffffffff1660e01b815260040161007b92919061017d565b6000604051808303818588803b15801561009457600080fd5b505af1935050505080156100a6575060015b6100e2573d8080156100d4576040519150601f19603f3d011682016040523d82523d6000602084013e6100d9565b606091505b50805181602001fd5b5060019392505050565b60008060006040848603121561010157600080fd5b83356001600160a01b038116811461011857600080fd5b9250602084013567ffffffffffffffff8082111561013557600080fd5b818601915086601f83011261014957600080fd5b81358181111561015857600080fd5b87602082850101111561016a57600080fd5b6020830194508093505050509250925092565b60208152816020820152818360408301376000818301604090810191909152601f909201601f1916010191905056fea26469706673582212208910f261d30970d772146975efc08ef063cc2dec11fde15631c6893f79ef156564736f6c634300080d0033"
            .parse()
            .expect("invalid bytecode")
    });
    pub struct InvariantCreatePool<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for InvariantCreatePool<M> {
        fn clone(&self) -> Self {
            InvariantCreatePool(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for InvariantCreatePool<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for InvariantCreatePool<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(InvariantCreatePool))
                .field(&self.address())
                .finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> InvariantCreatePool<M> {
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
                    INVARIANTCREATEPOOL_ABI.clone(),
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
                INVARIANTCREATEPOOL_ABI.clone(),
                INVARIANTCREATEPOOL_BYTECODE.clone().into(),
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
        ) -> ::ethers::contract::builders::ContractCall<
            M,
            ::ethers::core::types::Address,
        > {
            self.0
                .method_hash([212, 60, 15, 153], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `__hyper__` (0x3e81296e) function
        pub fn hyper(
            &self,
        ) -> ::ethers::contract::builders::ContractCall<
            M,
            ::ethers::core::types::Address,
        > {
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
        ) -> ::ethers::contract::builders::ContractCall<
            M,
            ::ethers::core::types::Address,
        > {
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
        ///Calls the contract's `create_pool` (0x3c07bc65) function
        pub fn create_pool(
            &self,
            index: ::ethers::core::types::U256,
            price: u128,
            strike: u128,
            sigma: u32,
            maturity: u32,
            gamma: u32,
            priority_gamma: u32,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash(
                    [60, 7, 188, 101],
                    (index, price, strike, sigma, maturity, gamma, priority_gamma),
                )
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
        pub fn log_bytes_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogBytesFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_bytes32` event
        pub fn log_bytes_32_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogBytes32Filter> {
            self.0.event()
        }
        ///Gets the contract's `log_int` event
        pub fn log_int_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogIntFilter> {
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
        pub fn log_string_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogStringFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_uint` event
        pub fn log_uint_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogUintFilter> {
            self.0.event()
        }
        ///Gets the contract's `logs` event
        pub fn logs_filter(&self) -> ::ethers::contract::builders::Event<M, LogsFilter> {
            self.0.event()
        }
        /// Returns an [`Event`](#ethers_contract::builders::Event) builder for all events of this contract
        pub fn events(
            &self,
        ) -> ::ethers::contract::builders::Event<M, InvariantCreatePoolEvents> {
            self.0.event_with_filter(Default::default())
        }
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>>
    for InvariantCreatePool<M> {
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
    )]
    #[derive(Default)]
    #[ethevent(name = "log", abi = "log(string)")]
    pub struct LogFilter(pub String);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
    #[ethevent(name = "log_address", abi = "log_address(address)")]
    pub struct LogAddressFilter(pub ::ethers::core::types::Address);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
    #[ethevent(name = "log_bytes", abi = "log_bytes(bytes)")]
    pub struct LogBytesFilter(pub ::ethers::core::types::Bytes);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
    #[ethevent(name = "log_bytes32", abi = "log_bytes32(bytes32)")]
    pub struct LogBytes32Filter(pub [u8; 32]);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
    #[ethevent(name = "log_int", abi = "log_int(int256)")]
    pub struct LogIntFilter(pub ::ethers::core::types::I256);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
    #[ethevent(name = "log_string", abi = "log_string(string)")]
    pub struct LogStringFilter(pub String);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
    #[ethevent(name = "log_uint", abi = "log_uint(uint256)")]
    pub struct LogUintFilter(pub ::ethers::core::types::U256);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
    #[ethevent(name = "logs", abi = "logs(bytes)")]
    pub struct LogsFilter(pub ::ethers::core::types::Bytes);
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum InvariantCreatePoolEvents {
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
    impl ::ethers::contract::EthLogDecode for InvariantCreatePoolEvents {
        fn decode_log(
            log: &::ethers::core::abi::RawLog,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::Error>
        where
            Self: Sized,
        {
            if let Ok(decoded) = LogFilter::decode_log(log) {
                return Ok(InvariantCreatePoolEvents::LogFilter(decoded));
            }
            if let Ok(decoded) = LogAddressFilter::decode_log(log) {
                return Ok(InvariantCreatePoolEvents::LogAddressFilter(decoded));
            }
            if let Ok(decoded) = LogArray1Filter::decode_log(log) {
                return Ok(InvariantCreatePoolEvents::LogArray1Filter(decoded));
            }
            if let Ok(decoded) = LogArray2Filter::decode_log(log) {
                return Ok(InvariantCreatePoolEvents::LogArray2Filter(decoded));
            }
            if let Ok(decoded) = LogArray3Filter::decode_log(log) {
                return Ok(InvariantCreatePoolEvents::LogArray3Filter(decoded));
            }
            if let Ok(decoded) = LogBytesFilter::decode_log(log) {
                return Ok(InvariantCreatePoolEvents::LogBytesFilter(decoded));
            }
            if let Ok(decoded) = LogBytes32Filter::decode_log(log) {
                return Ok(InvariantCreatePoolEvents::LogBytes32Filter(decoded));
            }
            if let Ok(decoded) = LogIntFilter::decode_log(log) {
                return Ok(InvariantCreatePoolEvents::LogIntFilter(decoded));
            }
            if let Ok(decoded) = LogNamedAddressFilter::decode_log(log) {
                return Ok(InvariantCreatePoolEvents::LogNamedAddressFilter(decoded));
            }
            if let Ok(decoded) = LogNamedArray1Filter::decode_log(log) {
                return Ok(InvariantCreatePoolEvents::LogNamedArray1Filter(decoded));
            }
            if let Ok(decoded) = LogNamedArray2Filter::decode_log(log) {
                return Ok(InvariantCreatePoolEvents::LogNamedArray2Filter(decoded));
            }
            if let Ok(decoded) = LogNamedArray3Filter::decode_log(log) {
                return Ok(InvariantCreatePoolEvents::LogNamedArray3Filter(decoded));
            }
            if let Ok(decoded) = LogNamedBytesFilter::decode_log(log) {
                return Ok(InvariantCreatePoolEvents::LogNamedBytesFilter(decoded));
            }
            if let Ok(decoded) = LogNamedBytes32Filter::decode_log(log) {
                return Ok(InvariantCreatePoolEvents::LogNamedBytes32Filter(decoded));
            }
            if let Ok(decoded) = LogNamedDecimalIntFilter::decode_log(log) {
                return Ok(InvariantCreatePoolEvents::LogNamedDecimalIntFilter(decoded));
            }
            if let Ok(decoded) = LogNamedDecimalUintFilter::decode_log(log) {
                return Ok(InvariantCreatePoolEvents::LogNamedDecimalUintFilter(decoded));
            }
            if let Ok(decoded) = LogNamedIntFilter::decode_log(log) {
                return Ok(InvariantCreatePoolEvents::LogNamedIntFilter(decoded));
            }
            if let Ok(decoded) = LogNamedStringFilter::decode_log(log) {
                return Ok(InvariantCreatePoolEvents::LogNamedStringFilter(decoded));
            }
            if let Ok(decoded) = LogNamedUintFilter::decode_log(log) {
                return Ok(InvariantCreatePoolEvents::LogNamedUintFilter(decoded));
            }
            if let Ok(decoded) = LogStringFilter::decode_log(log) {
                return Ok(InvariantCreatePoolEvents::LogStringFilter(decoded));
            }
            if let Ok(decoded) = LogUintFilter::decode_log(log) {
                return Ok(InvariantCreatePoolEvents::LogUintFilter(decoded));
            }
            if let Ok(decoded) = LogsFilter::decode_log(log) {
                return Ok(InvariantCreatePoolEvents::LogsFilter(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData)
        }
    }
    impl ::std::fmt::Display for InvariantCreatePoolEvents {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                InvariantCreatePoolEvents::LogFilter(element) => element.fmt(f),
                InvariantCreatePoolEvents::LogAddressFilter(element) => element.fmt(f),
                InvariantCreatePoolEvents::LogArray1Filter(element) => element.fmt(f),
                InvariantCreatePoolEvents::LogArray2Filter(element) => element.fmt(f),
                InvariantCreatePoolEvents::LogArray3Filter(element) => element.fmt(f),
                InvariantCreatePoolEvents::LogBytesFilter(element) => element.fmt(f),
                InvariantCreatePoolEvents::LogBytes32Filter(element) => element.fmt(f),
                InvariantCreatePoolEvents::LogIntFilter(element) => element.fmt(f),
                InvariantCreatePoolEvents::LogNamedAddressFilter(element) => {
                    element.fmt(f)
                }
                InvariantCreatePoolEvents::LogNamedArray1Filter(element) => {
                    element.fmt(f)
                }
                InvariantCreatePoolEvents::LogNamedArray2Filter(element) => {
                    element.fmt(f)
                }
                InvariantCreatePoolEvents::LogNamedArray3Filter(element) => {
                    element.fmt(f)
                }
                InvariantCreatePoolEvents::LogNamedBytesFilter(element) => element.fmt(f),
                InvariantCreatePoolEvents::LogNamedBytes32Filter(element) => {
                    element.fmt(f)
                }
                InvariantCreatePoolEvents::LogNamedDecimalIntFilter(element) => {
                    element.fmt(f)
                }
                InvariantCreatePoolEvents::LogNamedDecimalUintFilter(element) => {
                    element.fmt(f)
                }
                InvariantCreatePoolEvents::LogNamedIntFilter(element) => element.fmt(f),
                InvariantCreatePoolEvents::LogNamedStringFilter(element) => {
                    element.fmt(f)
                }
                InvariantCreatePoolEvents::LogNamedUintFilter(element) => element.fmt(f),
                InvariantCreatePoolEvents::LogStringFilter(element) => element.fmt(f),
                InvariantCreatePoolEvents::LogUintFilter(element) => element.fmt(f),
                InvariantCreatePoolEvents::LogsFilter(element) => element.fmt(f),
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
    #[ethcall(name = "_getReserve", abi = "_getReserve(address,address)")]
    pub struct _GetReserveCall {
        pub hyper: ::ethers::core::types::Address,
        pub token: ::ethers::core::types::Address,
    }
    ///Container type for all input parameters for the `create_pool` function with signature `create_pool(uint256,uint128,uint128,uint24,uint32,uint32,uint32)` and selector `0x3c07bc65`
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
        name = "create_pool",
        abi = "create_pool(uint256,uint128,uint128,uint24,uint32,uint32,uint32)"
    )]
    pub struct CreatePoolCall {
        pub index: ::ethers::core::types::U256,
        pub price: u128,
        pub strike: u128,
        pub sigma: u32,
        pub maturity: u32,
        pub gamma: u32,
        pub priority_gamma: u32,
    }
    ///Container type for all input parameters for the `failed` function with signature `failed()` and selector `0xba414fa6`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
    #[ethcall(name = "getBalanceSum", abi = "getBalanceSum(address,address,address[])")]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
    #[ethcall(name = "getPhysicalBalance", abi = "getPhysicalBalance(address,address)")]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
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
    )]
    #[derive(Default)]
    #[ethcall(
        name = "getVirtualBalance",
        abi = "getVirtualBalance(address,address,address[])"
    )]
    pub struct GetVirtualBalanceCall {
        pub hyper: ::ethers::core::types::Address,
        pub token: ::ethers::core::types::Address,
        pub owners: ::std::vec::Vec<::ethers::core::types::Address>,
    }
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum InvariantCreatePoolCalls {
        IsTest(IsTestCall),
        Asset(AssetCall),
        Hyper(HyperCall),
        PoolId(PoolIdCall),
        Quote(QuoteCall),
        _GetBalance(_GetBalanceCall),
        _GetPool(_GetPoolCall),
        _GetPosition(_GetPositionCall),
        _GetReserve(_GetReserveCall),
        CreatePool(CreatePoolCall),
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
    }
    impl ::ethers::core::abi::AbiDecode for InvariantCreatePoolCalls {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded)
                = <IsTestCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(InvariantCreatePoolCalls::IsTest(decoded));
            }
            if let Ok(decoded)
                = <AssetCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(InvariantCreatePoolCalls::Asset(decoded));
            }
            if let Ok(decoded)
                = <HyperCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(InvariantCreatePoolCalls::Hyper(decoded));
            }
            if let Ok(decoded)
                = <PoolIdCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(InvariantCreatePoolCalls::PoolId(decoded));
            }
            if let Ok(decoded)
                = <QuoteCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(InvariantCreatePoolCalls::Quote(decoded));
            }
            if let Ok(decoded)
                = <_GetBalanceCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantCreatePoolCalls::_GetBalance(decoded));
            }
            if let Ok(decoded)
                = <_GetPoolCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantCreatePoolCalls::_GetPool(decoded));
            }
            if let Ok(decoded)
                = <_GetPositionCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantCreatePoolCalls::_GetPosition(decoded));
            }
            if let Ok(decoded)
                = <_GetReserveCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantCreatePoolCalls::_GetReserve(decoded));
            }
            if let Ok(decoded)
                = <CreatePoolCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantCreatePoolCalls::CreatePool(decoded));
            }
            if let Ok(decoded)
                = <FailedCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(InvariantCreatePoolCalls::Failed(decoded));
            }
            if let Ok(decoded)
                = <GetBalanceCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantCreatePoolCalls::GetBalance(decoded));
            }
            if let Ok(decoded)
                = <GetBalanceSumCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantCreatePoolCalls::GetBalanceSum(decoded));
            }
            if let Ok(decoded)
                = <GetCurveCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantCreatePoolCalls::GetCurve(decoded));
            }
            if let Ok(decoded)
                = <GetMaxSwapLimitCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantCreatePoolCalls::GetMaxSwapLimit(decoded));
            }
            if let Ok(decoded)
                = <GetPairCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantCreatePoolCalls::GetPair(decoded));
            }
            if let Ok(decoded)
                = <GetPhysicalBalanceCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantCreatePoolCalls::GetPhysicalBalance(decoded));
            }
            if let Ok(decoded)
                = <GetPoolCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantCreatePoolCalls::GetPool(decoded));
            }
            if let Ok(decoded)
                = <GetPositionCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantCreatePoolCalls::GetPosition(decoded));
            }
            if let Ok(decoded)
                = <GetPositionLiquiditySumCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantCreatePoolCalls::GetPositionLiquiditySum(decoded));
            }
            if let Ok(decoded)
                = <GetReserveCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantCreatePoolCalls::GetReserve(decoded));
            }
            if let Ok(decoded)
                = <GetStateCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantCreatePoolCalls::GetState(decoded));
            }
            if let Ok(decoded)
                = <GetVirtualBalanceCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantCreatePoolCalls::GetVirtualBalance(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for InvariantCreatePoolCalls {
        fn encode(self) -> Vec<u8> {
            match self {
                InvariantCreatePoolCalls::IsTest(element) => element.encode(),
                InvariantCreatePoolCalls::Asset(element) => element.encode(),
                InvariantCreatePoolCalls::Hyper(element) => element.encode(),
                InvariantCreatePoolCalls::PoolId(element) => element.encode(),
                InvariantCreatePoolCalls::Quote(element) => element.encode(),
                InvariantCreatePoolCalls::_GetBalance(element) => element.encode(),
                InvariantCreatePoolCalls::_GetPool(element) => element.encode(),
                InvariantCreatePoolCalls::_GetPosition(element) => element.encode(),
                InvariantCreatePoolCalls::_GetReserve(element) => element.encode(),
                InvariantCreatePoolCalls::CreatePool(element) => element.encode(),
                InvariantCreatePoolCalls::Failed(element) => element.encode(),
                InvariantCreatePoolCalls::GetBalance(element) => element.encode(),
                InvariantCreatePoolCalls::GetBalanceSum(element) => element.encode(),
                InvariantCreatePoolCalls::GetCurve(element) => element.encode(),
                InvariantCreatePoolCalls::GetMaxSwapLimit(element) => element.encode(),
                InvariantCreatePoolCalls::GetPair(element) => element.encode(),
                InvariantCreatePoolCalls::GetPhysicalBalance(element) => element.encode(),
                InvariantCreatePoolCalls::GetPool(element) => element.encode(),
                InvariantCreatePoolCalls::GetPosition(element) => element.encode(),
                InvariantCreatePoolCalls::GetPositionLiquiditySum(element) => {
                    element.encode()
                }
                InvariantCreatePoolCalls::GetReserve(element) => element.encode(),
                InvariantCreatePoolCalls::GetState(element) => element.encode(),
                InvariantCreatePoolCalls::GetVirtualBalance(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for InvariantCreatePoolCalls {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                InvariantCreatePoolCalls::IsTest(element) => element.fmt(f),
                InvariantCreatePoolCalls::Asset(element) => element.fmt(f),
                InvariantCreatePoolCalls::Hyper(element) => element.fmt(f),
                InvariantCreatePoolCalls::PoolId(element) => element.fmt(f),
                InvariantCreatePoolCalls::Quote(element) => element.fmt(f),
                InvariantCreatePoolCalls::_GetBalance(element) => element.fmt(f),
                InvariantCreatePoolCalls::_GetPool(element) => element.fmt(f),
                InvariantCreatePoolCalls::_GetPosition(element) => element.fmt(f),
                InvariantCreatePoolCalls::_GetReserve(element) => element.fmt(f),
                InvariantCreatePoolCalls::CreatePool(element) => element.fmt(f),
                InvariantCreatePoolCalls::Failed(element) => element.fmt(f),
                InvariantCreatePoolCalls::GetBalance(element) => element.fmt(f),
                InvariantCreatePoolCalls::GetBalanceSum(element) => element.fmt(f),
                InvariantCreatePoolCalls::GetCurve(element) => element.fmt(f),
                InvariantCreatePoolCalls::GetMaxSwapLimit(element) => element.fmt(f),
                InvariantCreatePoolCalls::GetPair(element) => element.fmt(f),
                InvariantCreatePoolCalls::GetPhysicalBalance(element) => element.fmt(f),
                InvariantCreatePoolCalls::GetPool(element) => element.fmt(f),
                InvariantCreatePoolCalls::GetPosition(element) => element.fmt(f),
                InvariantCreatePoolCalls::GetPositionLiquiditySum(element) => {
                    element.fmt(f)
                }
                InvariantCreatePoolCalls::GetReserve(element) => element.fmt(f),
                InvariantCreatePoolCalls::GetState(element) => element.fmt(f),
                InvariantCreatePoolCalls::GetVirtualBalance(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<IsTestCall> for InvariantCreatePoolCalls {
        fn from(var: IsTestCall) -> Self {
            InvariantCreatePoolCalls::IsTest(var)
        }
    }
    impl ::std::convert::From<AssetCall> for InvariantCreatePoolCalls {
        fn from(var: AssetCall) -> Self {
            InvariantCreatePoolCalls::Asset(var)
        }
    }
    impl ::std::convert::From<HyperCall> for InvariantCreatePoolCalls {
        fn from(var: HyperCall) -> Self {
            InvariantCreatePoolCalls::Hyper(var)
        }
    }
    impl ::std::convert::From<PoolIdCall> for InvariantCreatePoolCalls {
        fn from(var: PoolIdCall) -> Self {
            InvariantCreatePoolCalls::PoolId(var)
        }
    }
    impl ::std::convert::From<QuoteCall> for InvariantCreatePoolCalls {
        fn from(var: QuoteCall) -> Self {
            InvariantCreatePoolCalls::Quote(var)
        }
    }
    impl ::std::convert::From<_GetBalanceCall> for InvariantCreatePoolCalls {
        fn from(var: _GetBalanceCall) -> Self {
            InvariantCreatePoolCalls::_GetBalance(var)
        }
    }
    impl ::std::convert::From<_GetPoolCall> for InvariantCreatePoolCalls {
        fn from(var: _GetPoolCall) -> Self {
            InvariantCreatePoolCalls::_GetPool(var)
        }
    }
    impl ::std::convert::From<_GetPositionCall> for InvariantCreatePoolCalls {
        fn from(var: _GetPositionCall) -> Self {
            InvariantCreatePoolCalls::_GetPosition(var)
        }
    }
    impl ::std::convert::From<_GetReserveCall> for InvariantCreatePoolCalls {
        fn from(var: _GetReserveCall) -> Self {
            InvariantCreatePoolCalls::_GetReserve(var)
        }
    }
    impl ::std::convert::From<CreatePoolCall> for InvariantCreatePoolCalls {
        fn from(var: CreatePoolCall) -> Self {
            InvariantCreatePoolCalls::CreatePool(var)
        }
    }
    impl ::std::convert::From<FailedCall> for InvariantCreatePoolCalls {
        fn from(var: FailedCall) -> Self {
            InvariantCreatePoolCalls::Failed(var)
        }
    }
    impl ::std::convert::From<GetBalanceCall> for InvariantCreatePoolCalls {
        fn from(var: GetBalanceCall) -> Self {
            InvariantCreatePoolCalls::GetBalance(var)
        }
    }
    impl ::std::convert::From<GetBalanceSumCall> for InvariantCreatePoolCalls {
        fn from(var: GetBalanceSumCall) -> Self {
            InvariantCreatePoolCalls::GetBalanceSum(var)
        }
    }
    impl ::std::convert::From<GetCurveCall> for InvariantCreatePoolCalls {
        fn from(var: GetCurveCall) -> Self {
            InvariantCreatePoolCalls::GetCurve(var)
        }
    }
    impl ::std::convert::From<GetMaxSwapLimitCall> for InvariantCreatePoolCalls {
        fn from(var: GetMaxSwapLimitCall) -> Self {
            InvariantCreatePoolCalls::GetMaxSwapLimit(var)
        }
    }
    impl ::std::convert::From<GetPairCall> for InvariantCreatePoolCalls {
        fn from(var: GetPairCall) -> Self {
            InvariantCreatePoolCalls::GetPair(var)
        }
    }
    impl ::std::convert::From<GetPhysicalBalanceCall> for InvariantCreatePoolCalls {
        fn from(var: GetPhysicalBalanceCall) -> Self {
            InvariantCreatePoolCalls::GetPhysicalBalance(var)
        }
    }
    impl ::std::convert::From<GetPoolCall> for InvariantCreatePoolCalls {
        fn from(var: GetPoolCall) -> Self {
            InvariantCreatePoolCalls::GetPool(var)
        }
    }
    impl ::std::convert::From<GetPositionCall> for InvariantCreatePoolCalls {
        fn from(var: GetPositionCall) -> Self {
            InvariantCreatePoolCalls::GetPosition(var)
        }
    }
    impl ::std::convert::From<GetPositionLiquiditySumCall> for InvariantCreatePoolCalls {
        fn from(var: GetPositionLiquiditySumCall) -> Self {
            InvariantCreatePoolCalls::GetPositionLiquiditySum(var)
        }
    }
    impl ::std::convert::From<GetReserveCall> for InvariantCreatePoolCalls {
        fn from(var: GetReserveCall) -> Self {
            InvariantCreatePoolCalls::GetReserve(var)
        }
    }
    impl ::std::convert::From<GetStateCall> for InvariantCreatePoolCalls {
        fn from(var: GetStateCall) -> Self {
            InvariantCreatePoolCalls::GetState(var)
        }
    }
    impl ::std::convert::From<GetVirtualBalanceCall> for InvariantCreatePoolCalls {
        fn from(var: GetVirtualBalanceCall) -> Self {
            InvariantCreatePoolCalls::GetVirtualBalance(var)
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
    )]
    #[derive(Default)]
    pub struct IsTestReturn(pub bool);
    ///Container type for all return fields from the `__asset__` function with signature `__asset__()` and selector `0xd43c0f99`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct AssetReturn(pub ::ethers::core::types::Address);
    ///Container type for all return fields from the `__hyper__` function with signature `__hyper__()` and selector `0x3e81296e`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct HyperReturn(pub ::ethers::core::types::Address);
    ///Container type for all return fields from the `__poolId__` function with signature `__poolId__()` and selector `0xc6a68a47`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct PoolIdReturn(pub u64);
    ///Container type for all return fields from the `__quote__` function with signature `__quote__()` and selector `0x8dbc9651`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct QuoteReturn(pub ::ethers::core::types::Address);
    ///Container type for all return fields from the `_getBalance` function with signature `_getBalance(address,address,address)` and selector `0xcf7dee1f`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct _GetBalanceReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `_getPool` function with signature `_getPool(address,uint64)` and selector `0x09deb4d3`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct _GetPoolReturn(pub HyperPool);
    ///Container type for all return fields from the `_getPosition` function with signature `_getPosition(address,address,uint64)` and selector `0xdc723804`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct _GetPositionReturn(pub HyperPosition);
    ///Container type for all return fields from the `_getReserve` function with signature `_getReserve(address,address)` and selector `0x5a8be8b0`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct _GetReserveReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `failed` function with signature `failed()` and selector `0xba414fa6`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct FailedReturn(pub bool);
    ///Container type for all return fields from the `getBalance` function with signature `getBalance(address,address,address)` and selector `0xd6bd603c`
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
    ///Container type for all return fields from the `getBalanceSum` function with signature `getBalanceSum(address,address,address[])` and selector `0xff314c0a`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct GetBalanceSumReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getCurve` function with signature `getCurve(address,uint64)` and selector `0xd83410b6`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct GetCurveReturn(pub HyperCurve);
    ///Container type for all return fields from the `getMaxSwapLimit` function with signature `getMaxSwapLimit(bool)` and selector `0xcee2aaf5`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct GetMaxSwapLimitReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getPair` function with signature `getPair(address,uint24)` and selector `0x7b135ad1`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct GetPairReturn(pub HyperPair);
    ///Container type for all return fields from the `getPhysicalBalance` function with signature `getPhysicalBalance(address,address)` and selector `0x634e05e0`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct GetPhysicalBalanceReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getPool` function with signature `getPool(address,uint64)` and selector `0x273c329f`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct GetPoolReturn(pub HyperPool);
    ///Container type for all return fields from the `getPosition` function with signature `getPosition(address,address,uint64)` and selector `0xdd05e299`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct GetPositionReturn(pub HyperPosition);
    ///Container type for all return fields from the `getPositionLiquiditySum` function with signature `getPositionLiquiditySum(address,uint64,address[])` and selector `0x8828200d`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct GetPositionLiquiditySumReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getReserve` function with signature `getReserve(address,address)` and selector `0xcbc3ab53`
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
    ///Container type for all return fields from the `getState` function with signature `getState(address,uint64,address,address[])` and selector `0xf3140b1e`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct GetStateReturn(pub HyperState);
    ///Container type for all return fields from the `getVirtualBalance` function with signature `getVirtualBalance(address,address,address[])` and selector `0x6dce537d`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct GetVirtualBalanceReturn(pub ::ethers::core::types::U256);
}
