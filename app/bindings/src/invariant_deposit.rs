pub use invariant_deposit::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod invariant_deposit {
    #![allow(clippy::enum_variant_names)]
    #![allow(dead_code)]
    #![allow(clippy::type_complexity)]
    #![allow(unused_imports)]
    ///InvariantDeposit was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
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
    const __ABI: &str = "[{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper_\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"asset_\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"quote_\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"constructor\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidBalance\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_address\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint256[]\",\"name\":\"val\",\"type\":\"uint256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"int256[]\",\"name\":\"val\",\"type\":\"int256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address[]\",\"name\":\"val\",\"type\":\"address[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"\",\"type\":\"bytes\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_bytes\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_bytes32\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"int256\",\"name\":\"\",\"type\":\"int256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_int\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"val\",\"type\":\"address\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_address\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256[]\",\"name\":\"val\",\"type\":\"uint256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"int256[]\",\"name\":\"val\",\"type\":\"int256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"address[]\",\"name\":\"val\",\"type\":\"address[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"bytes\",\"name\":\"val\",\"type\":\"bytes\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_bytes\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"bytes32\",\"name\":\"val\",\"type\":\"bytes32\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_bytes32\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"int256\",\"name\":\"val\",\"type\":\"int256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"decimals\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_decimal_int\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"val\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"decimals\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_decimal_uint\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"int256\",\"name\":\"val\",\"type\":\"int256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_int\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"string\",\"name\":\"val\",\"type\":\"string\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_string\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"val\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_uint\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_string\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_uint\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"\",\"type\":\"bytes\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"logs\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"IS_TEST\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__asset__\",\"outputs\":[{\"internalType\":\"contract TestERC20\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__hyper__\",\"outputs\":[{\"internalType\":\"contract HyperTimeOverride\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__poolId__\",\"outputs\":[{\"internalType\":\"uint64\",\"name\":\"\",\"type\":\"uint64\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__quote__\",\"outputs\":[{\"internalType\":\"contract TestERC20\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"contract HyperLike\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"contract TestERC20\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"contract IHyperStruct\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getPool\",\"outputs\":[{\"internalType\":\"struct HyperPool\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"lastTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"lastTimestamp\",\"type\":\"uint32\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"controller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalReward\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"lastPrice\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"liquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"int128\",\"name\":\"stakedLiquidityDelta\",\"type\":\"int128\",\"components\":[]},{\"internalType\":\"struct HyperCurve\",\"name\":\"params\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]},{\"internalType\":\"struct HyperPair\",\"name\":\"pair\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]}]},{\"inputs\":[{\"internalType\":\"contract IHyperStruct\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"positionId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getPosition\",\"outputs\":[{\"internalType\":\"struct HyperPosition\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"uint128\",\"name\":\"freeLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"lastTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"stakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"unstakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthRewardLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuoteLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedQuote\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedReward\",\"type\":\"uint128\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"contract HyperLike\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"contract TestERC20\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getReserve\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"index\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"deposit\",\"outputs\":[]},{\"inputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"failed\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getBalanceSum\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getCurve\",\"outputs\":[{\"internalType\":\"struct HyperCurve\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"bool\",\"name\":\"sellAsset\",\"type\":\"bool\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getMaxSwapLimit\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint24\",\"name\":\"pairId\",\"type\":\"uint24\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPair\",\"outputs\":[{\"internalType\":\"struct HyperPair\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPhysicalBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPool\",\"outputs\":[{\"internalType\":\"struct HyperPool\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"lastTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"lastTimestamp\",\"type\":\"uint32\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"controller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalReward\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"lastPrice\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"liquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"int128\",\"name\":\"stakedLiquidityDelta\",\"type\":\"int128\",\"components\":[]},{\"internalType\":\"struct HyperCurve\",\"name\":\"params\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]},{\"internalType\":\"struct HyperPair\",\"name\":\"pair\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"positionId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPosition\",\"outputs\":[{\"internalType\":\"struct HyperPosition\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"uint128\",\"name\":\"freeLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"lastTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"stakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"unstakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthRewardLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuoteLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedQuote\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedReward\",\"type\":\"uint128\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPositionLiquiditySum\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getReserve\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"caller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getState\",\"outputs\":[{\"internalType\":\"struct HyperState\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"uint256\",\"name\":\"reserveAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"reserveQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"physicalBalanceAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"physicalBalanceQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalBalanceAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalBalanceQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalPositionLiquidity\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"callerPositionLiquidity\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalPoolLiquidity\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetPool\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuotePool\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetPosition\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuotePosition\",\"type\":\"uint256\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getVirtualBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]}]";
    /// The parsed JSON-ABI of the contract.
    pub static INVARIANTDEPOSIT_ABI: ::ethers::contract::Lazy<
        ::ethers::core::abi::Abi,
    > = ::ethers::contract::Lazy::new(|| {
        ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi")
    });
    /// Bytecode of the #name contract
    pub static INVARIANTDEPOSIT_BYTECODE: ::ethers::contract::Lazy<
        ::ethers::core::types::Bytes,
    > = ::ethers::contract::Lazy::new(|| {
        "0x60806040526000805460ff1916600117905560138054790100000000010000000000000000000000000000000000000000600160a01b600160e01b03199091161790553480156200004f57600080fd5b5060405162002360380380620023608339810160408190526200007291620001d6565b60138054336001600160a01b0319918216179091556014805482166001600160a01b03868116918217909255601680548416868416908117909155601580549094169285169290921790925560405163095ea7b360e01b81526004810192909252600019602483015284918491849163095ea7b3906044016020604051808303816000875af11580156200010a573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019062000130919062000220565b5060155460405163095ea7b360e01b81526001600160a01b03858116600483015260001960248301529091169063095ea7b3906044016020604051808303816000875af115801562000186573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190620001ac919062000220565b505050505050506200024b565b80516001600160a01b0381168114620001d157600080fd5b919050565b600080600060608486031215620001ec57600080fd5b620001f784620001b9565b92506200020760208501620001b9565b91506200021760408501620001b9565b90509250925092565b6000602082840312156200023357600080fd5b815180151581146200024457600080fd5b9392505050565b612105806200025b6000396000f3fe608060405234801561001057600080fd5b506004361061014d5760003560e01c8063cbc3ab53116100c3578063dc7238041161007c578063dc723804146102d8578063dd05e299146102d8578063e2bbb158146102f8578063f3140b1e1461030d578063fa7626d4146103b3578063ff314c0a146103c057600080fd5b8063cbc3ab53146101a6578063cee2aaf51461027f578063cf7dee1f14610292578063d43c0f99146102a5578063d6bd603c14610292578063d83410b6146102b857600080fd5b80636dce537d116101155780636dce537d146101da5780637b135ad1146101ed5780638828200d1461020d5780638dbc965114610220578063ba414fa614610233578063c6a68a471461024b57600080fd5b806309deb4d314610152578063273c329f146101525780633e81296e1461017b5780635a8be8b0146101a6578063634e05e0146101c7575b600080fd5b610165610160366004611590565b6103d3565b6040516101729190611622565b60405180910390f35b60145461018e906001600160a01b031681565b6040516001600160a01b039091168152602001610172565b6101b96101b4366004611736565b610503565b604051908152602001610172565b6101b96101d5366004611736565b610571565b6101b96101e8366004611877565b61057d565b6102006101fb3660046118d9565b6105aa565b604051610172919061190f565b6101b961021b366004611950565b61063b565b60155461018e906001600160a01b031681565b61023b61069c565b6040519015158152602001610172565b60135461026690600160a01b900467ffffffffffffffff1681565b60405167ffffffffffffffff9091168152602001610172565b6101b961028d36600461198c565b6107c7565b6101b96102a03660046119a9565b6107e0565b60165461018e906001600160a01b031681565b6102cb6102c6366004611590565b61085e565b60405161017291906119f4565b6102eb6102e6366004611a02565b6108ae565b6040516101729190611a49565b61030b610306366004611afb565b6109b3565b005b61032061031b366004611b1d565b610d78565b6040516101729190815181526020808301519082015260408083015190820152606080830151908201526080808301519082015260a0808301519082015260c0808301519082015260e08083015190820152610100808301519082015261012080830151908201526101408083015190820152610160808301519082015261018091820151918101919091526101a00190565b60005461023b9060ff1681565b6101b96103ce366004611877565b610ef9565b6104876040805161018081018252600080825260208083018290528284018290526060808401839052608080850184905260a080860185905260c080870186905260e0808801879052610100880187905261012088018790528851908101895286815294850186905296840185905291830184905282018390528101829052928301529061014082019081526040805160808101825260008082526020828101829052928201819052606082015291015290565b6040516322697c2160e21b815267ffffffffffffffff831660048201526001600160a01b038416906389a5f084906024016102a060405180830381865afa1580156104d6573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906104fa9190611d46565b90505b92915050565b60405163c9a396e960e01b81526001600160a01b0382811660048301526000919084169063c9a396e990602401602060405180830381865afa15801561054d573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906104fa9190611e20565b60006104fa8284610f47565b60008061058b858585610ef9565b6105958686610503565b61059f9190611e4f565b9150505b9392505050565b604080516080810182526000808252602082018190529181018290526060810191909152604051631791d98f60e21b815262ffffff831660048201526001600160a01b03841690635e47663c90602401608060405180830381865afa158015610617573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906104fa9190611e67565b60008060005b835181146106935761066d8685838151811061065f5761065f611e83565b6020026020010151876108ae565b51610681906001600160801b031683611e4f565b915061068c81611e99565b9050610641565b50949350505050565b60008054610100900460ff16156106bc5750600054610100900460ff1690565b6000737109709ecfa91a80626ff3989d68f67f5b1dd12d3b156107c25760408051737109709ecfa91a80626ff3989d68f67f5b1dd12d602082018190526519985a5b195960d21b8284015282518083038401815260608301909352600092909161074a917f667f9d70ca411d70ead50d8d5c22070dafc36ad75f3dcf5e7237b22ade9aecc491608001611ee2565b60408051601f198184030181529082905261076491611f13565b6000604051808303816000865af19150503d80600081146107a1576040519150601f19603f3d011682016040523d82523d6000602084013e6107a6565b606091505b50915050808060200190518101906107be9190611f2f565b9150505b919050565b600081156107d757506000919050565b50600019919050565b60405163d4fac45d60e01b81526001600160a01b03838116600483015282811660248301526000919085169063d4fac45d90604401602060405180830381865afa158015610832573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906108569190611e20565b949350505050565b6040805160e081018252600080825260208201819052918101829052606081018290526080810182905260a0810182905260c08101829052906108a184846103d3565b6101400151949350505050565b61093860405180610160016040528060006001600160801b0316815260200160006001600160801b0316815260200160008152602001600081526020016000815260200160008152602001600081526020016000815260200160006001600160801b0316815260200160006001600160801b0316815260200160006001600160801b031681525090565b604051635b4289f560e11b81526001600160a01b03848116600483015267ffffffffffffffff8416602483015285169063b68513ea9060440161016060405180830381865afa15801561098f573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906108569190611f4c565b6109ce8260016ec097ce7bc90715b34b9f1000000000611030565b601354604051631ad9ed5760e21b8152600481018490529193506000916001600160a01b0390911690636b67b55c90602401602060405180830381865afa158015610a1d573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610a419190611ffc565b60405163c88a5e6d60e01b81526001600160a01b038216600482015260248101859052909150737109709ecfa91a80626ff3989d68f67f5b1dd12d9063c88a5e6d90604401600060405180830381600087803b158015610aa057600080fd5b505af1158015610ab4573d6000803e3d6000fd5b505050506000601460009054906101000a90046001600160a01b03166001600160a01b031663ad5c46486040518163ffffffff1660e01b8152600401602060405180830381865afa158015610b0d573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610b319190611ffc565b601454909150600090610b4e906001600160a01b031684846107e0565b601454909150600090610b6a906001600160a01b031684610503565b60405163ca669fa760e01b81526001600160a01b0386166004820152909150737109709ecfa91a80626ff3989d68f67f5b1dd12d9063ca669fa790602401600060405180830381600087803b158015610bc257600080fd5b505af1158015610bd6573d6000803e3d6000fd5b50505050601460009054906101000a90046001600160a01b03166001600160a01b031663d0e30db0876040518263ffffffff1660e01b81526004016000604051808303818588803b158015610c2a57600080fd5b505af1158015610c3e573d6000803e3d6000fd5b505060145460009350610c5d92506001600160a01b0316905085610503565b601454909150600090610c7a906001600160a01b031687876107e0565b9050610cb482610c8a8a86611e4f565b6040518060400160405280600c81526020016b776574682d7265736572766560a01b81525061106d565b610cec81610cc28a87611e4f565b6040518060400160405280600c81526020016b776574682d62616c616e636560a01b81525061106d565b60145460408051808201909152600b81526a6574682d62616c616e636560a81b6020820152610d28916001600160a01b0316319060009061106d565b601454610d6e90610d42906001600160a01b031687610571565b836040518060400160405280600d81526020016c1dd95d1a0b5c1a1e5cda58d85b609a1b81525061106d565b5050505050505050565b610de3604051806101a00160405280600081526020016000815260200160008152602001600081526020016000815260200160008152602001600081526020016000815260200160008152602001600081526020016000815260200160008152602001600081525090565b6000610df886602887901c62ffffff166105aa565b80516040820151919250906000610e0f89896103d3565b90506000610e1e8a898b6108ae565b90506000604051806101a00160405280610e388d88610503565b8152602001610e478d87610503565b8152602001610e568d88610571565b8152602001610e658d87610571565b8152602001610e758d888c610ef9565b8152602001610e858d878c610ef9565b8152602001610e958d8d8c61063b565b815260200183600001516001600160801b031681526020018460e001516001600160801b03168152602001846080015181526020018460a0015181526020018360c0015181526020018360e001518152509050809650505050505050949350505050565b60008060005b8351811461069357610f2b86858381518110610f1d57610f1d611e83565b6020026020010151876107e0565b610f359083611e4f565b9150610f4081611e99565b9050610eff565b604080516001600160a01b0383811660248084019190915283518084039091018152604490920183526020820180516001600160e01b03166370a0823160e01b17905291516000928392839291871691610fa19190611f13565b600060405180830381855afa9150503d8060008114610fdc576040519150601f19603f3d011682016040523d82523d6000602084013e610fe1565b606091505b5091509150811580610ff557508051602014155b156110135760405163c52e3eff60e01b815260040160405180910390fd5b808060200190518101906110279190611e20565b95945050505050565b600061103d8484846110ba565b90506105a36040518060400160405280600c81526020016b109bdd5b990814995cdd5b1d60a21b81525082611282565b8183146110b5577f280f4446b28a1372417dda658d30b95b2992b12ac9c7f378535f29a97acf3583816040516110a39190612045565b60405180910390a16110b58383611329565b505050565b6000818311156111365760405162461bcd60e51b815260206004820152603e60248201527f5374645574696c7320626f756e642875696e743235362c75696e743235362c7560448201527f696e74323536293a204d6178206973206c657373207468616e206d696e2e0000606482015260840160405180910390fd5b8284101580156111465750818411155b156111525750826105a3565b600061115e8484612074565b611169906001611e4f565b90506003851115801561117b57508481115b156111925761118a8585611e4f565b9150506105a3565b61119f6003600019612074565b85101580156111b857506111b585600019612074565b81115b156111d3576111c985600019612074565b61118a9084612074565b828511156112295760006111e78487612074565b905060006111f5838361208b565b90508060000361120a578493505050506105a3565b60016112168288611e4f565b6112209190612074565b9350505061127a565b8385101561127a57600061123d8686612074565b9050600061124b838361208b565b905080600003611260578593505050506105a3565b61126a8186612074565b611275906001611e4f565b935050505b509392505050565b60006a636f6e736f6c652e6c6f676001600160a01b031683836040516024016112ac9291906120ad565b60408051601f198184030181529181526020820180516001600160e01b0316632d839cb360e21b179052516112e19190611f13565b600060405180830381855afa9150503d806000811461131c576040519150601f19603f3d011682016040523d82523d6000602084013e611321565b606091505b505050505050565b808214611450577f41304facd9323d75b11bcdd609cb38effffdb05710f7caf0e9b16c6d9d709f5060405161139a9060208082526022908201527f4572726f723a2061203d3d2062206e6f7420736174697366696564205b75696e604082015261745d60f01b606082015260800190565b60405180910390a160408051818152600a81830152690808115e1c1958dd195960b21b60608201526020810183905290517fb2de2fbe801a0df6c0cbddfd448ba3c41d48a040ca35c56c8196ef0fcae721a89181900360800190a160408051818152600a8183015269080808081058dd1d585b60b21b60608201526020810184905290517fb2de2fbe801a0df6c0cbddfd448ba3c41d48a040ca35c56c8196ef0fcae721a89181900360800190a1611450611454565b5050565b737109709ecfa91a80626ff3989d68f67f5b1dd12d3b1561154f5760408051737109709ecfa91a80626ff3989d68f67f5b1dd12d602082018190526519985a5b195960d21b9282019290925260016060820152600091907f70ca10bbd0dbfd9020a9f4b13402c16cb120705e0d1c0aeab10fa353ae586fc49060800160408051601f19818403018152908290526114ee9291602001611ee2565b60408051601f198184030181529082905261150891611f13565b6000604051808303816000865af19150503d8060008114611545576040519150601f19603f3d011682016040523d82523d6000602084013e61154a565b606091505b505050505b6000805461ff001916610100179055565b6001600160a01b038116811461157557600080fd5b50565b803567ffffffffffffffff811681146107c257600080fd5b600080604083850312156115a357600080fd5b82356115ae81611560565b91506115bc60208401611578565b90509250929050565b805160020b8252602081015161ffff80821660208501528060408401511660408501528060608401511660608501528060808401511660808501528060a08401511660a0850152505063ffffffff60c08201511660c08301525050565b815160020b81526102a081016020830151611645602084018263ffffffff169052565b50604083015161166060408401826001600160a01b03169052565b50606083015160608301526080830151608083015260a083015160a083015260c083015161169960c08401826001600160801b03169052565b5060e08301516116b460e08401826001600160801b03169052565b50610100838101516001600160801b03169083015261012080840151600f0b90830152610140808401516116ea828501826115c5565b505061016083015180516001600160a01b03908116610220850152602082015160ff90811661024086015260408301519091166102608501526060820151166102808401525092915050565b6000806040838503121561174957600080fd5b823561175481611560565b9150602083013561176481611560565b809150509250929050565b634e487b7160e01b600052604160045260246000fd5b604051610180810167ffffffffffffffff811182821017156117a9576117a961176f565b60405290565b604051610160810167ffffffffffffffff811182821017156117a9576117a961176f565b600082601f8301126117e457600080fd5b8135602067ffffffffffffffff808311156118015761180161176f565b8260051b604051601f19603f830116810181811084821117156118265761182661176f565b60405293845285810183019383810192508785111561184457600080fd5b83870191505b8482101561186c57813561185d81611560565b8352918301919083019061184a565b979650505050505050565b60008060006060848603121561188c57600080fd5b833561189781611560565b925060208401356118a781611560565b9150604084013567ffffffffffffffff8111156118c357600080fd5b6118cf868287016117d3565b9150509250925092565b600080604083850312156118ec57600080fd5b82356118f781611560565b9150602083013562ffffff8116811461176457600080fd5b608081016104fd828460018060a01b0380825116835260ff60208301511660208401528060408301511660408401525060ff60608201511660608301525050565b60008060006060848603121561196557600080fd5b833561197081611560565b92506118a760208501611578565b801515811461157557600080fd5b60006020828403121561199e57600080fd5b81356105a38161197e565b6000806000606084860312156119be57600080fd5b83356119c981611560565b925060208401356119d981611560565b915060408401356119e981611560565b809150509250925092565b60e081016104fd82846115c5565b600080600060608486031215611a1757600080fd5b8335611a2281611560565b92506020840135611a3281611560565b9150611a4060408501611578565b90509250925092565b81516001600160801b0316815261016081016020830151611a7560208401826001600160801b03169052565b5060408301516040830152606083015160608301526080830151608083015260a083015160a083015260c083015160c083015260e083015160e083015261010080840151611acd828501826001600160801b03169052565b5050610120838101516001600160801b03908116918401919091526101409384015116929091019190915290565b60008060408385031215611b0e57600080fd5b50508035926020909101359150565b60008060008060808587031215611b3357600080fd5b8435611b3e81611560565b9350611b4c60208601611578565b92506040850135611b5c81611560565b9150606085013567ffffffffffffffff811115611b7857600080fd5b611b84878288016117d3565b91505092959194509250565b8051600281900b81146107c257600080fd5b805163ffffffff811681146107c257600080fd5b80516107c281611560565b80516001600160801b03811681146107c257600080fd5b8051600f81900b81146107c257600080fd5b805161ffff811681146107c257600080fd5b600060e08284031215611c0e57600080fd5b60405160e0810181811067ffffffffffffffff82111715611c3157611c3161176f565b604052905080611c4083611b90565b8152611c4e60208401611bea565b6020820152611c5f60408401611bea565b6040820152611c7060608401611bea565b6060820152611c8160808401611bea565b6080820152611c9260a08401611bea565b60a0820152611ca360c08401611ba2565b60c08201525092915050565b805160ff811681146107c257600080fd5b600060808284031215611cd257600080fd5b6040516080810181811067ffffffffffffffff82111715611cf557611cf561176f565b80604052508091508251611d0881611560565b8152611d1660208401611caf565b60208201526040830151611d2981611560565b6040820152611d3a60608401611caf565b60608201525092915050565b60006102a08284031215611d5957600080fd5b611d61611785565b611d6a83611b90565b8152611d7860208401611ba2565b6020820152611d8960408401611bb6565b6040820152606083015160608201526080830151608082015260a083015160a0820152611db860c08401611bc1565b60c0820152611dc960e08401611bc1565b60e0820152610100611ddc818501611bc1565b90820152610120611dee848201611bd8565b90820152610140611e0185858301611bfc565b90820152611e13846102208501611cc0565b6101608201529392505050565b600060208284031215611e3257600080fd5b5051919050565b634e487b7160e01b600052601160045260246000fd5b60008219821115611e6257611e62611e39565b500190565b600060808284031215611e7957600080fd5b6104fa8383611cc0565b634e487b7160e01b600052603260045260246000fd5b600060018201611eab57611eab611e39565b5060010190565b60005b83811015611ecd578181015183820152602001611eb5565b83811115611edc576000848401525b50505050565b6001600160e01b0319831681528151600090611f05816004850160208701611eb2565b919091016004019392505050565b60008251611f25818460208701611eb2565b9190910192915050565b600060208284031215611f4157600080fd5b81516105a38161197e565b60006101608284031215611f5f57600080fd5b611f676117af565b611f7083611bc1565b8152611f7e60208401611bc1565b602082015260408301516040820152606083015160608201526080830151608082015260a083015160a082015260c083015160c082015260e083015160e0820152610100611fcd818501611bc1565b90820152610120611fdf848201611bc1565b90820152610140611ff1848201611bc1565b908201529392505050565b60006020828403121561200e57600080fd5b81516105a381611560565b60008151808452612031816020860160208601611eb2565b601f01601f19169290920160200192915050565b60408152600560408201526422b93937b960d91b60608201526080602082015260006104fa6080830184612019565b60008282101561208657612086611e39565b500390565b6000826120a857634e487b7160e01b600052601260045260246000fd5b500690565b6040815260006120c06040830185612019565b9050826020830152939250505056fea264697066735822122088fee3c05f0b0c2379dc2e10b52532ddd03097e081f1c27a74c3356128eb493264736f6c634300080d0033"
            .parse()
            .expect("invalid bytecode")
    });
    pub struct InvariantDeposit<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for InvariantDeposit<M> {
        fn clone(&self) -> Self {
            InvariantDeposit(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for InvariantDeposit<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for InvariantDeposit<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(InvariantDeposit)).field(&self.address()).finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> InvariantDeposit<M> {
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
                    INVARIANTDEPOSIT_ABI.clone(),
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
                INVARIANTDEPOSIT_ABI.clone(),
                INVARIANTDEPOSIT_BYTECODE.clone().into(),
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
        ///Calls the contract's `deposit` (0xe2bbb158) function
        pub fn deposit(
            &self,
            amount: ::ethers::core::types::U256,
            index: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([226, 187, 177, 88], (amount, index))
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
        ) -> ::ethers::contract::builders::Event<M, InvariantDepositEvents> {
            self.0.event_with_filter(Default::default())
        }
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>>
    for InvariantDeposit<M> {
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
    pub enum InvariantDepositEvents {
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
    impl ::ethers::contract::EthLogDecode for InvariantDepositEvents {
        fn decode_log(
            log: &::ethers::core::abi::RawLog,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::Error>
        where
            Self: Sized,
        {
            if let Ok(decoded) = LogFilter::decode_log(log) {
                return Ok(InvariantDepositEvents::LogFilter(decoded));
            }
            if let Ok(decoded) = LogAddressFilter::decode_log(log) {
                return Ok(InvariantDepositEvents::LogAddressFilter(decoded));
            }
            if let Ok(decoded) = LogArray1Filter::decode_log(log) {
                return Ok(InvariantDepositEvents::LogArray1Filter(decoded));
            }
            if let Ok(decoded) = LogArray2Filter::decode_log(log) {
                return Ok(InvariantDepositEvents::LogArray2Filter(decoded));
            }
            if let Ok(decoded) = LogArray3Filter::decode_log(log) {
                return Ok(InvariantDepositEvents::LogArray3Filter(decoded));
            }
            if let Ok(decoded) = LogBytesFilter::decode_log(log) {
                return Ok(InvariantDepositEvents::LogBytesFilter(decoded));
            }
            if let Ok(decoded) = LogBytes32Filter::decode_log(log) {
                return Ok(InvariantDepositEvents::LogBytes32Filter(decoded));
            }
            if let Ok(decoded) = LogIntFilter::decode_log(log) {
                return Ok(InvariantDepositEvents::LogIntFilter(decoded));
            }
            if let Ok(decoded) = LogNamedAddressFilter::decode_log(log) {
                return Ok(InvariantDepositEvents::LogNamedAddressFilter(decoded));
            }
            if let Ok(decoded) = LogNamedArray1Filter::decode_log(log) {
                return Ok(InvariantDepositEvents::LogNamedArray1Filter(decoded));
            }
            if let Ok(decoded) = LogNamedArray2Filter::decode_log(log) {
                return Ok(InvariantDepositEvents::LogNamedArray2Filter(decoded));
            }
            if let Ok(decoded) = LogNamedArray3Filter::decode_log(log) {
                return Ok(InvariantDepositEvents::LogNamedArray3Filter(decoded));
            }
            if let Ok(decoded) = LogNamedBytesFilter::decode_log(log) {
                return Ok(InvariantDepositEvents::LogNamedBytesFilter(decoded));
            }
            if let Ok(decoded) = LogNamedBytes32Filter::decode_log(log) {
                return Ok(InvariantDepositEvents::LogNamedBytes32Filter(decoded));
            }
            if let Ok(decoded) = LogNamedDecimalIntFilter::decode_log(log) {
                return Ok(InvariantDepositEvents::LogNamedDecimalIntFilter(decoded));
            }
            if let Ok(decoded) = LogNamedDecimalUintFilter::decode_log(log) {
                return Ok(InvariantDepositEvents::LogNamedDecimalUintFilter(decoded));
            }
            if let Ok(decoded) = LogNamedIntFilter::decode_log(log) {
                return Ok(InvariantDepositEvents::LogNamedIntFilter(decoded));
            }
            if let Ok(decoded) = LogNamedStringFilter::decode_log(log) {
                return Ok(InvariantDepositEvents::LogNamedStringFilter(decoded));
            }
            if let Ok(decoded) = LogNamedUintFilter::decode_log(log) {
                return Ok(InvariantDepositEvents::LogNamedUintFilter(decoded));
            }
            if let Ok(decoded) = LogStringFilter::decode_log(log) {
                return Ok(InvariantDepositEvents::LogStringFilter(decoded));
            }
            if let Ok(decoded) = LogUintFilter::decode_log(log) {
                return Ok(InvariantDepositEvents::LogUintFilter(decoded));
            }
            if let Ok(decoded) = LogsFilter::decode_log(log) {
                return Ok(InvariantDepositEvents::LogsFilter(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData)
        }
    }
    impl ::std::fmt::Display for InvariantDepositEvents {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                InvariantDepositEvents::LogFilter(element) => element.fmt(f),
                InvariantDepositEvents::LogAddressFilter(element) => element.fmt(f),
                InvariantDepositEvents::LogArray1Filter(element) => element.fmt(f),
                InvariantDepositEvents::LogArray2Filter(element) => element.fmt(f),
                InvariantDepositEvents::LogArray3Filter(element) => element.fmt(f),
                InvariantDepositEvents::LogBytesFilter(element) => element.fmt(f),
                InvariantDepositEvents::LogBytes32Filter(element) => element.fmt(f),
                InvariantDepositEvents::LogIntFilter(element) => element.fmt(f),
                InvariantDepositEvents::LogNamedAddressFilter(element) => element.fmt(f),
                InvariantDepositEvents::LogNamedArray1Filter(element) => element.fmt(f),
                InvariantDepositEvents::LogNamedArray2Filter(element) => element.fmt(f),
                InvariantDepositEvents::LogNamedArray3Filter(element) => element.fmt(f),
                InvariantDepositEvents::LogNamedBytesFilter(element) => element.fmt(f),
                InvariantDepositEvents::LogNamedBytes32Filter(element) => element.fmt(f),
                InvariantDepositEvents::LogNamedDecimalIntFilter(element) => {
                    element.fmt(f)
                }
                InvariantDepositEvents::LogNamedDecimalUintFilter(element) => {
                    element.fmt(f)
                }
                InvariantDepositEvents::LogNamedIntFilter(element) => element.fmt(f),
                InvariantDepositEvents::LogNamedStringFilter(element) => element.fmt(f),
                InvariantDepositEvents::LogNamedUintFilter(element) => element.fmt(f),
                InvariantDepositEvents::LogStringFilter(element) => element.fmt(f),
                InvariantDepositEvents::LogUintFilter(element) => element.fmt(f),
                InvariantDepositEvents::LogsFilter(element) => element.fmt(f),
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
    ///Container type for all input parameters for the `deposit` function with signature `deposit(uint256,uint256)` and selector `0xe2bbb158`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
    #[ethcall(name = "deposit", abi = "deposit(uint256,uint256)")]
    pub struct DepositCall {
        pub amount: ::ethers::core::types::U256,
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
    pub enum InvariantDepositCalls {
        IsTest(IsTestCall),
        Asset(AssetCall),
        Hyper(HyperCall),
        PoolId(PoolIdCall),
        Quote(QuoteCall),
        _GetBalance(_GetBalanceCall),
        _GetPool(_GetPoolCall),
        _GetPosition(_GetPositionCall),
        _GetReserve(_GetReserveCall),
        Deposit(DepositCall),
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
    impl ::ethers::core::abi::AbiDecode for InvariantDepositCalls {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded)
                = <IsTestCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(InvariantDepositCalls::IsTest(decoded));
            }
            if let Ok(decoded)
                = <AssetCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(InvariantDepositCalls::Asset(decoded));
            }
            if let Ok(decoded)
                = <HyperCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(InvariantDepositCalls::Hyper(decoded));
            }
            if let Ok(decoded)
                = <PoolIdCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(InvariantDepositCalls::PoolId(decoded));
            }
            if let Ok(decoded)
                = <QuoteCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(InvariantDepositCalls::Quote(decoded));
            }
            if let Ok(decoded)
                = <_GetBalanceCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantDepositCalls::_GetBalance(decoded));
            }
            if let Ok(decoded)
                = <_GetPoolCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantDepositCalls::_GetPool(decoded));
            }
            if let Ok(decoded)
                = <_GetPositionCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantDepositCalls::_GetPosition(decoded));
            }
            if let Ok(decoded)
                = <_GetReserveCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantDepositCalls::_GetReserve(decoded));
            }
            if let Ok(decoded)
                = <DepositCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantDepositCalls::Deposit(decoded));
            }
            if let Ok(decoded)
                = <FailedCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(InvariantDepositCalls::Failed(decoded));
            }
            if let Ok(decoded)
                = <GetBalanceCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantDepositCalls::GetBalance(decoded));
            }
            if let Ok(decoded)
                = <GetBalanceSumCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantDepositCalls::GetBalanceSum(decoded));
            }
            if let Ok(decoded)
                = <GetCurveCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantDepositCalls::GetCurve(decoded));
            }
            if let Ok(decoded)
                = <GetMaxSwapLimitCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantDepositCalls::GetMaxSwapLimit(decoded));
            }
            if let Ok(decoded)
                = <GetPairCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantDepositCalls::GetPair(decoded));
            }
            if let Ok(decoded)
                = <GetPhysicalBalanceCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantDepositCalls::GetPhysicalBalance(decoded));
            }
            if let Ok(decoded)
                = <GetPoolCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantDepositCalls::GetPool(decoded));
            }
            if let Ok(decoded)
                = <GetPositionCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantDepositCalls::GetPosition(decoded));
            }
            if let Ok(decoded)
                = <GetPositionLiquiditySumCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantDepositCalls::GetPositionLiquiditySum(decoded));
            }
            if let Ok(decoded)
                = <GetReserveCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantDepositCalls::GetReserve(decoded));
            }
            if let Ok(decoded)
                = <GetStateCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantDepositCalls::GetState(decoded));
            }
            if let Ok(decoded)
                = <GetVirtualBalanceCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(InvariantDepositCalls::GetVirtualBalance(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for InvariantDepositCalls {
        fn encode(self) -> Vec<u8> {
            match self {
                InvariantDepositCalls::IsTest(element) => element.encode(),
                InvariantDepositCalls::Asset(element) => element.encode(),
                InvariantDepositCalls::Hyper(element) => element.encode(),
                InvariantDepositCalls::PoolId(element) => element.encode(),
                InvariantDepositCalls::Quote(element) => element.encode(),
                InvariantDepositCalls::_GetBalance(element) => element.encode(),
                InvariantDepositCalls::_GetPool(element) => element.encode(),
                InvariantDepositCalls::_GetPosition(element) => element.encode(),
                InvariantDepositCalls::_GetReserve(element) => element.encode(),
                InvariantDepositCalls::Deposit(element) => element.encode(),
                InvariantDepositCalls::Failed(element) => element.encode(),
                InvariantDepositCalls::GetBalance(element) => element.encode(),
                InvariantDepositCalls::GetBalanceSum(element) => element.encode(),
                InvariantDepositCalls::GetCurve(element) => element.encode(),
                InvariantDepositCalls::GetMaxSwapLimit(element) => element.encode(),
                InvariantDepositCalls::GetPair(element) => element.encode(),
                InvariantDepositCalls::GetPhysicalBalance(element) => element.encode(),
                InvariantDepositCalls::GetPool(element) => element.encode(),
                InvariantDepositCalls::GetPosition(element) => element.encode(),
                InvariantDepositCalls::GetPositionLiquiditySum(element) => {
                    element.encode()
                }
                InvariantDepositCalls::GetReserve(element) => element.encode(),
                InvariantDepositCalls::GetState(element) => element.encode(),
                InvariantDepositCalls::GetVirtualBalance(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for InvariantDepositCalls {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                InvariantDepositCalls::IsTest(element) => element.fmt(f),
                InvariantDepositCalls::Asset(element) => element.fmt(f),
                InvariantDepositCalls::Hyper(element) => element.fmt(f),
                InvariantDepositCalls::PoolId(element) => element.fmt(f),
                InvariantDepositCalls::Quote(element) => element.fmt(f),
                InvariantDepositCalls::_GetBalance(element) => element.fmt(f),
                InvariantDepositCalls::_GetPool(element) => element.fmt(f),
                InvariantDepositCalls::_GetPosition(element) => element.fmt(f),
                InvariantDepositCalls::_GetReserve(element) => element.fmt(f),
                InvariantDepositCalls::Deposit(element) => element.fmt(f),
                InvariantDepositCalls::Failed(element) => element.fmt(f),
                InvariantDepositCalls::GetBalance(element) => element.fmt(f),
                InvariantDepositCalls::GetBalanceSum(element) => element.fmt(f),
                InvariantDepositCalls::GetCurve(element) => element.fmt(f),
                InvariantDepositCalls::GetMaxSwapLimit(element) => element.fmt(f),
                InvariantDepositCalls::GetPair(element) => element.fmt(f),
                InvariantDepositCalls::GetPhysicalBalance(element) => element.fmt(f),
                InvariantDepositCalls::GetPool(element) => element.fmt(f),
                InvariantDepositCalls::GetPosition(element) => element.fmt(f),
                InvariantDepositCalls::GetPositionLiquiditySum(element) => element.fmt(f),
                InvariantDepositCalls::GetReserve(element) => element.fmt(f),
                InvariantDepositCalls::GetState(element) => element.fmt(f),
                InvariantDepositCalls::GetVirtualBalance(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<IsTestCall> for InvariantDepositCalls {
        fn from(var: IsTestCall) -> Self {
            InvariantDepositCalls::IsTest(var)
        }
    }
    impl ::std::convert::From<AssetCall> for InvariantDepositCalls {
        fn from(var: AssetCall) -> Self {
            InvariantDepositCalls::Asset(var)
        }
    }
    impl ::std::convert::From<HyperCall> for InvariantDepositCalls {
        fn from(var: HyperCall) -> Self {
            InvariantDepositCalls::Hyper(var)
        }
    }
    impl ::std::convert::From<PoolIdCall> for InvariantDepositCalls {
        fn from(var: PoolIdCall) -> Self {
            InvariantDepositCalls::PoolId(var)
        }
    }
    impl ::std::convert::From<QuoteCall> for InvariantDepositCalls {
        fn from(var: QuoteCall) -> Self {
            InvariantDepositCalls::Quote(var)
        }
    }
    impl ::std::convert::From<_GetBalanceCall> for InvariantDepositCalls {
        fn from(var: _GetBalanceCall) -> Self {
            InvariantDepositCalls::_GetBalance(var)
        }
    }
    impl ::std::convert::From<_GetPoolCall> for InvariantDepositCalls {
        fn from(var: _GetPoolCall) -> Self {
            InvariantDepositCalls::_GetPool(var)
        }
    }
    impl ::std::convert::From<_GetPositionCall> for InvariantDepositCalls {
        fn from(var: _GetPositionCall) -> Self {
            InvariantDepositCalls::_GetPosition(var)
        }
    }
    impl ::std::convert::From<_GetReserveCall> for InvariantDepositCalls {
        fn from(var: _GetReserveCall) -> Self {
            InvariantDepositCalls::_GetReserve(var)
        }
    }
    impl ::std::convert::From<DepositCall> for InvariantDepositCalls {
        fn from(var: DepositCall) -> Self {
            InvariantDepositCalls::Deposit(var)
        }
    }
    impl ::std::convert::From<FailedCall> for InvariantDepositCalls {
        fn from(var: FailedCall) -> Self {
            InvariantDepositCalls::Failed(var)
        }
    }
    impl ::std::convert::From<GetBalanceCall> for InvariantDepositCalls {
        fn from(var: GetBalanceCall) -> Self {
            InvariantDepositCalls::GetBalance(var)
        }
    }
    impl ::std::convert::From<GetBalanceSumCall> for InvariantDepositCalls {
        fn from(var: GetBalanceSumCall) -> Self {
            InvariantDepositCalls::GetBalanceSum(var)
        }
    }
    impl ::std::convert::From<GetCurveCall> for InvariantDepositCalls {
        fn from(var: GetCurveCall) -> Self {
            InvariantDepositCalls::GetCurve(var)
        }
    }
    impl ::std::convert::From<GetMaxSwapLimitCall> for InvariantDepositCalls {
        fn from(var: GetMaxSwapLimitCall) -> Self {
            InvariantDepositCalls::GetMaxSwapLimit(var)
        }
    }
    impl ::std::convert::From<GetPairCall> for InvariantDepositCalls {
        fn from(var: GetPairCall) -> Self {
            InvariantDepositCalls::GetPair(var)
        }
    }
    impl ::std::convert::From<GetPhysicalBalanceCall> for InvariantDepositCalls {
        fn from(var: GetPhysicalBalanceCall) -> Self {
            InvariantDepositCalls::GetPhysicalBalance(var)
        }
    }
    impl ::std::convert::From<GetPoolCall> for InvariantDepositCalls {
        fn from(var: GetPoolCall) -> Self {
            InvariantDepositCalls::GetPool(var)
        }
    }
    impl ::std::convert::From<GetPositionCall> for InvariantDepositCalls {
        fn from(var: GetPositionCall) -> Self {
            InvariantDepositCalls::GetPosition(var)
        }
    }
    impl ::std::convert::From<GetPositionLiquiditySumCall> for InvariantDepositCalls {
        fn from(var: GetPositionLiquiditySumCall) -> Self {
            InvariantDepositCalls::GetPositionLiquiditySum(var)
        }
    }
    impl ::std::convert::From<GetReserveCall> for InvariantDepositCalls {
        fn from(var: GetReserveCall) -> Self {
            InvariantDepositCalls::GetReserve(var)
        }
    }
    impl ::std::convert::From<GetStateCall> for InvariantDepositCalls {
        fn from(var: GetStateCall) -> Self {
            InvariantDepositCalls::GetState(var)
        }
    }
    impl ::std::convert::From<GetVirtualBalanceCall> for InvariantDepositCalls {
        fn from(var: GetVirtualBalanceCall) -> Self {
            InvariantDepositCalls::GetVirtualBalance(var)
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
