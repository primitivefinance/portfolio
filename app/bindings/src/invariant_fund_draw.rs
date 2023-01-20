pub use invariant_fund_draw::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod invariant_fund_draw {
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
    ///InvariantFundDraw was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
    use std::sync::Arc;
    #[rustfmt::skip]
    const __ABI: &str = "[{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper_\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"asset_\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"quote_\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"constructor\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidBalance\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_address\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint256[]\",\"name\":\"val\",\"type\":\"uint256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"int256[]\",\"name\":\"val\",\"type\":\"int256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address[]\",\"name\":\"val\",\"type\":\"address[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"\",\"type\":\"bytes\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_bytes\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_bytes32\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"int256\",\"name\":\"\",\"type\":\"int256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_int\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"val\",\"type\":\"address\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_address\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256[]\",\"name\":\"val\",\"type\":\"uint256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"int256[]\",\"name\":\"val\",\"type\":\"int256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"address[]\",\"name\":\"val\",\"type\":\"address[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"bytes\",\"name\":\"val\",\"type\":\"bytes\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_bytes\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"bytes32\",\"name\":\"val\",\"type\":\"bytes32\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_bytes32\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"int256\",\"name\":\"val\",\"type\":\"int256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"decimals\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_decimal_int\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"val\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"decimals\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_decimal_uint\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"int256\",\"name\":\"val\",\"type\":\"int256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_int\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"string\",\"name\":\"val\",\"type\":\"string\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_string\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"val\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_uint\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_string\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_uint\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"\",\"type\":\"bytes\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"logs\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"IS_TEST\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__asset__\",\"outputs\":[{\"internalType\":\"contract TestERC20\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__hyper__\",\"outputs\":[{\"internalType\":\"contract HyperTimeOverride\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__poolId__\",\"outputs\":[{\"internalType\":\"uint64\",\"name\":\"\",\"type\":\"uint64\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__quote__\",\"outputs\":[{\"internalType\":\"contract TestERC20\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"contract HyperLike\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"contract TestERC20\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"contract IHyperStruct\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getPool\",\"outputs\":[{\"internalType\":\"struct HyperPool\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"lastTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"lastTimestamp\",\"type\":\"uint32\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"controller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalReward\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"lastPrice\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"liquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"int128\",\"name\":\"stakedLiquidityDelta\",\"type\":\"int128\",\"components\":[]},{\"internalType\":\"struct HyperCurve\",\"name\":\"params\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]},{\"internalType\":\"struct HyperPair\",\"name\":\"pair\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]}]},{\"inputs\":[{\"internalType\":\"contract IHyperStruct\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"positionId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getPosition\",\"outputs\":[{\"internalType\":\"struct HyperPosition\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"uint128\",\"name\":\"freeLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"lastTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"stakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"unstakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthRewardLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuoteLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedQuote\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedReward\",\"type\":\"uint128\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"contract HyperLike\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"contract TestERC20\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getReserve\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"failed\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"index\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"fund_asset\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"index\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"fund_quote\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getBalanceSum\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getCurve\",\"outputs\":[{\"internalType\":\"struct HyperCurve\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"bool\",\"name\":\"sellAsset\",\"type\":\"bool\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getMaxSwapLimit\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint24\",\"name\":\"pairId\",\"type\":\"uint24\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPair\",\"outputs\":[{\"internalType\":\"struct HyperPair\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPhysicalBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPool\",\"outputs\":[{\"internalType\":\"struct HyperPool\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"lastTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"lastTimestamp\",\"type\":\"uint32\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"controller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalReward\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"lastPrice\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"liquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"int128\",\"name\":\"stakedLiquidityDelta\",\"type\":\"int128\",\"components\":[]},{\"internalType\":\"struct HyperCurve\",\"name\":\"params\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]},{\"internalType\":\"struct HyperPair\",\"name\":\"pair\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"positionId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPosition\",\"outputs\":[{\"internalType\":\"struct HyperPosition\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"uint128\",\"name\":\"freeLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"lastTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"stakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"unstakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthRewardLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuoteLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedQuote\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedReward\",\"type\":\"uint128\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPositionLiquiditySum\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getReserve\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"caller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getState\",\"outputs\":[{\"internalType\":\"struct HyperState\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"uint256\",\"name\":\"reserveAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"reserveQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"physicalBalanceAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"physicalBalanceQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalBalanceAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalBalanceQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalPositionLiquidity\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"callerPositionLiquidity\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalPoolLiquidity\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetPool\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuotePool\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetPosition\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuotePosition\",\"type\":\"uint256\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getVirtualBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]}]";
    /// The parsed JSON-ABI of the contract.
    pub static INVARIANTFUNDDRAW_ABI: ::ethers::contract::Lazy<::ethers::core::abi::Abi> =
        ::ethers::contract::Lazy::new(|| {
            ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi")
        });
    /// Bytecode of the #name contract
    pub static INVARIANTFUNDDRAW_BYTECODE: ::ethers::contract::Lazy<::ethers::core::types::Bytes> =
        ::ethers::contract::Lazy::new(|| {
            "0x60806040526000805460ff1916600117905560138054790100000000010000000000000000000000000000000000000000600160a01b600160e01b03199091161790553480156200004f57600080fd5b5060405162003ff638038062003ff68339810160408190526200007291620001d6565b60138054336001600160a01b0319918216179091556014805482166001600160a01b03868116918217909255601680548416868416908117909155601580549094169285169290921790925560405163095ea7b360e01b81526004810192909252600019602483015284918491849163095ea7b3906044016020604051808303816000875af11580156200010a573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019062000130919062000220565b5060155460405163095ea7b360e01b81526001600160a01b03858116600483015260001960248301529091169063095ea7b3906044016020604051808303816000875af115801562000186573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190620001ac919062000220565b505050505050506200024b565b80516001600160a01b0381168114620001d157600080fd5b919050565b600080600060608486031215620001ec57600080fd5b620001f784620001b9565b92506200020760208501620001b9565b91506200021760408501620001b9565b90509250925092565b6000602082840312156200023357600080fd5b815180151581146200024457600080fd5b9392505050565b613d9b806200025b6000396000f3fe608060405234801561001057600080fd5b50600436106101585760003560e01c8063cee2aaf5116100c3578063dd05e2991161007c578063dd05e299146102e1578063f3140b1e14610301578063f8c28267146103a7578063f9df4c3b146103bc578063fa7626d4146103cf578063ff314c0a146103dc57600080fd5b8063cee2aaf514610288578063cf7dee1f1461029b578063d43c0f99146102ae578063d6bd603c1461029b578063d83410b6146102c1578063dc723804146102e157600080fd5b80637b135ad1116101155780637b135ad1146101f85780638828200d146102185780638dbc96511461022b578063ba414fa61461023e578063c6a68a4714610256578063cbc3ab53146101b157600080fd5b806309deb4d31461015d578063273c329f1461015d5780633e81296e146101865780635a8be8b0146101b1578063634e05e0146101d25780636dce537d146101e5575b600080fd5b61017061016b366004612fcf565b6103ef565b60405161017d9190613061565b60405180910390f35b601454610199906001600160a01b031681565b6040516001600160a01b03909116815260200161017d565b6101c46101bf366004613173565b61051e565b60405190815260200161017d565b6101c46101e0366004613173565b61058c565b6101c46101f33660046132d5565b610598565b61020b610206366004613336565b6105c5565b60405161017d919061336c565b6101c46102263660046133ad565b610656565b601554610199906001600160a01b031681565b6102466106b7565b604051901515815260200161017d565b60135461027090600160a01b90046001600160401b031681565b6040516001600160401b03909116815260200161017d565b6101c46102963660046133e9565b6107e6565b6101c46102a9366004613406565b6107ff565b601654610199906001600160a01b031681565b6102d46102cf366004612fcf565b61087d565b60405161017d9190613451565b6102f46102ef36600461345f565b6108cd565b60405161017d91906134a6565b61031461030f366004613558565b6109d1565b60405161017d9190815181526020808301519082015260408083015190820152606080830151908201526080808301519082015260a0808301519082015260c0808301519082015260e08083015190820152610100808301519082015261012080830151908201526101408083015190820152610160808301519082015261018091820151918101919091526101a00190565b6103ba6103b53660046135ca565b610b52565b005b6103ba6103ca3660046135ca565b611067565b6000546102469060ff1681565b6101c46103ea3660046132d5565b6113f3565b6104a36040805161018081018252600080825260208083018290528284018290526060808401839052608080850184905260a080860185905260c080870186905260e0808801879052610100880187905261012088018790528851908101895286815294850186905296840185905291830184905282018390528101829052928301529061014082019081526040805160808101825260008082526020828101829052928201819052606082015291015290565b6040516322697c2160e21b81526001600160401b03831660048201526001600160a01b038416906389a5f084906024016102a060405180830381865afa1580156104f1573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061051591906137a0565b90505b92915050565b60405163c9a396e960e01b81526001600160a01b0382811660048301526000919084169063c9a396e990602401602060405180830381865afa158015610568573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610515919061387a565b60006105158284611441565b6000806105a68585856113f3565b6105b0868661051e565b6105ba91906138a9565b9150505b9392505050565b604080516080810182526000808252602082018190529181018290526060810191909152604051631791d98f60e21b815262ffffff831660048201526001600160a01b03841690635e47663c90602401608060405180830381865afa158015610632573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061051591906138c1565b60008060005b835181146106ae576106888685838151811061067a5761067a6138dd565b6020026020010151876108cd565b5161069c906001600160801b0316836138a9565b91506106a7816138f3565b905061065c565b50949350505050565b60008054610100900460ff16156106d75750600054610100900460ff1690565b6000737109709ecfa91a80626ff3989d68f67f5b1dd12d3b156107e157604051600090737109709ecfa91a80626ff3989d68f67f5b1dd12d907f667f9d70ca411d70ead50d8d5c22070dafc36ad75f3dcf5e7237b22ade9aecc49061074b9083906519985a5b195960d21b9060200161390c565b60408051601f19818403018152908290526107699291602001613955565b60408051601f198184030181529082905261078391613986565b6000604051808303816000865af19150503d80600081146107c0576040519150601f19603f3d011682016040523d82523d6000602084013e6107c5565b606091505b50915050808060200190518101906107dd91906139a2565b9150505b919050565b600081156107f657506000919050565b50600019919050565b60405163d4fac45d60e01b81526001600160a01b03838116600483015282811660248301526000919085169063d4fac45d90604401602060405180830381865afa158015610851573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610875919061387a565b949350505050565b6040805160e081018252600080825260208201819052918101829052606081018290526080810182905260a0810182905260c08101829052906108c084846103ef565b6101400151949350505050565b61095760405180610160016040528060006001600160801b0316815260200160006001600160801b0316815260200160008152602001600081526020016000815260200160008152602001600081526020016000815260200160006001600160801b0316815260200160006001600160801b0316815260200160006001600160801b031681525090565b604051635b4289f560e11b81526001600160a01b0384811660048301526001600160401b038416602483015285169063b68513ea9060440161016060405180830381865afa1580156109ad573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061087591906139bf565b610a3c604051806101a00160405280600081526020016000815260200160008152602001600081526020016000815260200160008152602001600081526020016000815260200160008152602001600081526020016000815260200160008152602001600081525090565b6000610a5186602887901c62ffffff166105c5565b80516040820151919250906000610a6889896103ef565b90506000610a778a898b6108cd565b90506000604051806101a00160405280610a918d8861051e565b8152602001610aa08d8761051e565b8152602001610aaf8d8861058c565b8152602001610abe8d8761058c565b8152602001610ace8d888c6113f3565b8152602001610ade8d878c6113f3565b8152602001610aee8d8d8c610656565b815260200183600001516001600160801b031681526020018460e001516001600160801b03168152602001846080015181526020018460a0015181526020018360c0015181526020018360e001518152509050809650505050505050949350505050565b610b6d8260016ec097ce7bc90715b34b9f100000000061152a565b601354604051631ad9ed5760e21b8152600481018490529193506000916001600160a01b0390911690636b67b55c90602401602060405180830381865afa158015610bbc573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610be09190613a6f565b6014546016546040516304dc68a960e41b81526001600160a01b039182166004820152929350600092911690634dc68a9090602401602060405180830381865afa158015610c32573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610c56919061387a565b6014546015546040516304dc68a960e41b81526001600160a01b039182166004820152929350600092911690634dc68a9090602401602060405180830381865afa158015610ca8573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610ccc919061387a565b9050610d1160008312156040518060400160405280601981526020017f6e656761746976652d6e65742d61737365742d746f6b656e7300000000000000815250611567565b610d5460008212156040518060400160405280601981526020017f6e656761746976652d6e65742d71756f74652d746f6b656e7300000000000000815250611567565b60405163ca669fa760e01b81526001600160a01b0384166004820152737109709ecfa91a80626ff3989d68f67f5b1dd12d9063ca669fa790602401600060405180830381600087803b158015610da957600080fd5b505af1158015610dbd573d6000803e3d6000fd5b505060165460145460405163095ea7b360e01b81526001600160a01b03928316945063095ea7b39350610df89290911690899060040161390c565b6020604051808303816000875af1158015610e17573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610e3b91906139a2565b50601654610e53906001600160a01b031684876115b0565b601454601654600091610e72916001600160a01b03918216911661051e565b601454601654919250600091610e96916001600160a01b03908116918891166107ff565b60405163ca669fa760e01b81526001600160a01b0387166004820152909150737109709ecfa91a80626ff3989d68f67f5b1dd12d9063ca669fa790602401600060405180830381600087803b158015610eee57600080fd5b505af1158015610f02573d6000803e3d6000fd5b5050601454601654604051633d8c1bef60e11b81526001600160a01b039283169450637b1837de9350610f3d92909116908b9060040161390c565b600060405180830381600087803b158015610f5757600080fd5b505af1158015610f6b573d6000803e3d6000fd5b505060145460165460009350610f8e92506001600160a01b03918216911661051e565b601454601654919250600091610fb2916001600160a01b03908116918a91166107ff565b90506110088187610fc38c876138a9565b610fcd91906138a9565b6040518060400160405280601881526020017f66756e642d64656c74612d61737365742d62616c616e636500000000000000008152506115c2565b61105c82866110178c886138a9565b61102191906138a9565b6040518060400160405280601881526020017f66756e642d64656c74612d61737365742d7265736572766500000000000000008152506115c2565b505050505050505050565b6110828260016ec097ce7bc90715b34b9f100000000061152a565b601354604051631ad9ed5760e21b8152600481018490529193506000916001600160a01b0390911690636b67b55c90602401602060405180830381865afa1580156110d1573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906110f59190613a6f565b60405163ca669fa760e01b81526001600160a01b0382166004820152909150737109709ecfa91a80626ff3989d68f67f5b1dd12d9063ca669fa790602401600060405180830381600087803b15801561114d57600080fd5b505af1158015611161573d6000803e3d6000fd5b505060155460145460405163095ea7b360e01b81526001600160a01b03928316945063095ea7b3935061119c9290911690879060040161390c565b6020604051808303816000875af11580156111bb573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906111df91906139a2565b506015546111f7906001600160a01b031682856115b0565b601454601554600091611216916001600160a01b03918216911661051e565b60145460155491925060009161123a916001600160a01b03908116918691166107ff565b60405163ca669fa760e01b81526001600160a01b0385166004820152909150737109709ecfa91a80626ff3989d68f67f5b1dd12d9063ca669fa790602401600060405180830381600087803b15801561129257600080fd5b505af11580156112a6573d6000803e3d6000fd5b5050601454601554604051633d8c1bef60e11b81526001600160a01b039283169450637b1837de93506112e19290911690899060040161390c565b600060405180830381600087803b1580156112fb57600080fd5b505af115801561130f573d6000803e3d6000fd5b50506014546015546000935061133292506001600160a01b03918216911661051e565b601454601554919250600091611356916001600160a01b03908116918891166107ff565b90506113a18161136689866138a9565b6040518060400160405280601881526020017f66756e642d64656c74612d71756f74652d62616c616e636500000000000000008152506115c2565b6113ea826113af89876138a9565b6040518060400160405280601881526020017f66756e642d64656c74612d71756f74652d7265736572766500000000000000008152506115c2565b50505050505050565b60008060005b835181146106ae5761142586858381518110611417576114176138dd565b6020026020010151876107ff565b61142f90836138a9565b915061143a816138f3565b90506113f9565b604080516001600160a01b0383811660248084019190915283518084039091018152604490920183526020820180516001600160e01b03166370a0823160e01b1790529151600092839283929187169161149b9190613986565b600060405180830381855afa9150503d80600081146114d6576040519150601f19603f3d011682016040523d82523d6000602084013e6114db565b606091505b50915091508115806114ef57508051602014155b1561150d5760405163c52e3eff60e01b815260040160405180910390fd5b80806020019051810190611521919061387a565b95945050505050565b600061153784848461160a565b90506105be6040518060400160405280600c81526020016b109bdd5b990814995cdd5b1d60a21b815250826117d3565b816115ac577f280f4446b28a1372417dda658d30b95b2992b12ac9c7f378535f29a97acf35838160405161159b9190613ab8565b60405180910390a16115ac8261187a565b5050565b6115bd83838360006118f1565b505050565b8183146115bd577f280f4446b28a1372417dda658d30b95b2992b12ac9c7f378535f29a97acf3583816040516115f89190613ab8565b60405180910390a16115bd8383611ad7565b6000818311156116875760405162461bcd60e51b815260206004820152603e60248201527f5374645574696c7320626f756e642875696e743235362c75696e743235362c7560448201527f696e74323536293a204d6178206973206c657373207468616e206d696e2e000060648201526084015b60405180910390fd5b8284101580156116975750818411155b156116a35750826105be565b60006116af8484613ae7565b6116ba9060016138a9565b9050600385111580156116cc57508481115b156116e3576116db85856138a9565b9150506105be565b6116f06003600019613ae7565b8510158015611709575061170685600019613ae7565b81115b156117245761171a85600019613ae7565b6116db9084613ae7565b8285111561177a5760006117388487613ae7565b905060006117468383613afe565b90508060000361175b578493505050506105be565b600161176782886138a9565b6117719190613ae7565b935050506117cb565b838510156117cb57600061178e8686613ae7565b9050600061179c8383613afe565b9050806000036117b1578593505050506105be565b6117bb8186613ae7565b6117c69060016138a9565b935050505b509392505050565b60006a636f6e736f6c652e6c6f676001600160a01b031683836040516024016117fd929190613b20565b60408051601f198184030181529181526020820180516001600160e01b0316632d839cb360e21b179052516118329190613986565b600060405180830381855afa9150503d806000811461186d576040519150601f19603f3d011682016040523d82523d6000602084013e611872565b606091505b505050505050565b806118ee577f41304facd9323d75b11bcdd609cb38effffdb05710f7caf0e9b16c6d9d709f506040516118de9060208082526017908201527f4572726f723a20417373657274696f6e204661696c6564000000000000000000604082015260600190565b60405180910390a16118ee611bfa565b50565b604080516001600160a01b0385811660248084019190915283518084039091018152604490920183526020820180516001600160e01b03166370a0823160e01b179052915160009287169161194591613986565b6000604051808303816000865af19150503d8060008114611982576040519150601f19603f3d011682016040523d82523d6000602084013e611987565b606091505b509150506000818060200190518101906119a1919061387a565b90506119d3846119cd876119c76370a0823160e01b6119c160058d611cff565b90611d24565b90611d41565b90611d69565b82156118725760408051600481526024810182526020810180516001600160e01b03166318160ddd60e01b17905290516000916001600160a01b03891691611a1b9190613986565b6000604051808303816000865af19150503d8060008114611a58576040519150601f19603f3d011682016040523d82523d6000602084013e611a5d565b606091505b50915050600081806020019051810190611a77919061387a565b905082861015611a9c57611a8b8684613ae7565b611a959082613ae7565b9050611ab3565b611aa68387613ae7565b611ab090826138a9565b90505b611acd816119cd6318160ddd60e01b6119c160058d611cff565b5050505050505050565b8082146115ac577f41304facd9323d75b11bcdd609cb38effffdb05710f7caf0e9b16c6d9d709f50604051611b489060208082526022908201527f4572726f723a2061203d3d2062206e6f7420736174697366696564205b75696e604082015261745d60f01b606082015260800190565b60405180910390a160408051818152600a81830152690808115e1c1958dd195960b21b60608201526020810183905290517fb2de2fbe801a0df6c0cbddfd448ba3c41d48a040ca35c56c8196ef0fcae721a89181900360800190a160408051818152600a8183015269080808081058dd1d585b60b21b60608201526020810184905290517fb2de2fbe801a0df6c0cbddfd448ba3c41d48a040ca35c56c8196ef0fcae721a89181900360800190a16115ac5b737109709ecfa91a80626ff3989d68f67f5b1dd12d3b15611cee57604051600090737109709ecfa91a80626ff3989d68f67f5b1dd12d907f70ca10bbd0dbfd9020a9f4b13402c16cb120705e0d1c0aeab10fa353ae586fc490611c6f9083906519985a5b195960d21b90600190602001613b42565b60408051601f1981840301815290829052611c8d9291602001613955565b60408051601f1981840301815290829052611ca791613986565b6000604051808303816000865af19150503d8060008114611ce4576040519150601f19603f3d011682016040523d82523d6000602084013e611ce9565b606091505b505050505b6000805461ff001916610100179055565b6005820180546001600160a01b0319166001600160a01b038316179055600082610515565b60038201805463ffffffff191660e083901c179055600082610515565b6002820180546001810182556000918252602082206001600160a01b03841691015582610515565b6115ac8282600582015460038301546004840154600285018054604080516020808402820181019092528281526001600160a01b039096169560e09590951b9460009390929091830182828015611ddf57602002820191906000526020600020905b815481526020019060010190808311611dcb575b50505050509050600083611df2836120bc565b604051602001611e03929190613955565b60408051601f198184030181528282526001600160a01b038816600090815260018b0160209081528382206001600160e01b03198a168352815292812091945090929091611e55918691889101613b63565b60408051601f198184030181529181528151602092830120835290820192909252016000205460ff16611e8d57611e8b87612162565b505b6001600160a01b0385166000908152602088815260408083206001600160e01b0319881684528252808320905190918391611ecc918791899101613b63565b6040516020818303038152906040528051906020012081526020019081526020016000205460001b9050600080876001600160a01b031684604051611f119190613986565b600060405180830381855afa9150503d8060008114611f4c576040519150601f19603f3d011682016040523d82523d6000602084013e611f51565b606091505b509150611f6a905081611f65886020613b9d565b61216d565b604051630667f9d760e41b815290925060009150737109709ecfa91a80626ff3989d68f67f5b1dd12d9063667f9d7090611faa908b90879060040161390c565b602060405180830381865afa158015611fc7573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190611feb919061387a565b905080821461200c5760405162461bcd60e51b815260040161167e90613bbc565b6040516370ca10bb60e01b8152737109709ecfa91a80626ff3989d68f67f5b1dd12d906370ca10bb90612047908b9087908e90600401613b42565b600060405180830381600087803b15801561206157600080fd5b505af1158015612075573d6000803e3d6000fd5b50505060058b0180546001600160a01b03191690555060038a01805463ffffffff191690556120a860028b016000612f71565b896004016000905550505050505050505050565b60606000825160206120ce9190613b9d565b6001600160401b038111156120e5576120e56131ac565b6040519080825280601f01601f19166020018201604052801561210f576020820181803683370190505b50905060005b835181101561215b576000848281518110612132576121326138dd565b602002602001015190508082602002602001840152508080612153906138f3565b915050612115565b5092915050565b6000610518826121ea565b60008060006020855111612182578451612185565b60205b905060005b818110156121e05761219d816008613b9d565b866121a883886138a9565b815181106121b8576121b86138dd565b01602001516001600160f81b031916901c9290921791806121d8816138f3565b91505061218a565b5090949350505050565b600581015460038201546004830154600284018054604080516020808402820181019092528281526000966001600160a01b03169560e01b94938793919290919083018282801561225a57602002820191906000526020600020905b815481526020019060010190808311612246575b5050506001600160a01b038716600090815260018a01602090815260408083206001600160e01b03198a16845282528083209051959650949193506122a492508591879101613b63565b60408051601f198184030181529181528151602092830120835290820192909252016000205460ff1615612340576001600160a01b0384166000908152602087815260408083206001600160e01b03198716845282528083209051909291612310918591879101613b63565b60405160208183030381529060405280519060200120815260200190815260200160002054945050505050919050565b60008361234c83612e5f565b60405160200161235d929190613955565b6040516020818303038152906040529050600080516020613d4683398151915260001c6001600160a01b031663266cf1096040518163ffffffff1660e01b8152600401600060405180830381600087803b1580156123ba57600080fd5b505af11580156123ce573d6000803e3d6000fd5b50505050600080866001600160a01b0316836040516123ed9190613986565b600060405180830381855afa9150503d8060008114612428576040519150601f19603f3d011682016040523d82523d6000602084013e61242d565b606091505b509150612446905081612441876020613b9d565b612efe565b6040516365bc948160e01b81526001600160a01b038916600482015290925060009150737109709ecfa91a80626ff3989d68f67f5b1dd12d906365bc9481906024016000604051808303816000875af11580156124a7573d6000803e3d6000fd5b505050506040513d6000823e601f3d908101601f191682016040526124cf9190810190613cb2565b5090508051600103612774576000600080516020613d4683398151915260001c6001600160a01b031663667f9d708984600081518110612511576125116138dd565b60200260200101516040518363ffffffff1660e01b815260040161253692919061390c565b602060405180830381865afa158015612553573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190612577919061387a565b9050806125d5577f080fc4a96620c4462e705b23f346413fe3796bb63c6f8d8591baec0e231577a588836000815181106125b3576125b36138dd565b602002602001015160001c6040516125cc92919061390c565b60405180910390a15b8083146125f45760405162461bcd60e51b815260040161167e90613bbc565b7f9c9555b1e3102e3cf48f427d79cb678f5d9bd1ed0ad574389461e255f95170ed8888878960405160200161262a929190613b63565b6040516020818303038152906040528051906020012085600081518110612653576126536138dd565b602002602001015160001c60405161266e9493929190613d15565b60405180910390a181600081518110612689576126896138dd565b6020908102919091018101516001600160a01b038a1660009081528c835260408082206001600160e01b03198c16835284528082209051929390926126d2918a918c9101613b63565b60408051601f1981840301815291815281516020928301208352828201939093529082016000908120939093556001600160a01b038b16835260018d810182528284206001600160e01b03198c1685528252828420925190939161273a918a918c9101613b63565b60408051808303601f19018152918152815160209283012083529082019290925201600020805460ff191691151591909117905550612cea565b600181511115612c7a5760005b8151811015612c74576000600080516020613d4683398151915260001c6001600160a01b031663667f9d708a8585815181106127bf576127bf6138dd565b60200260200101516040518363ffffffff1660e01b81526004016127e492919061390c565b602060405180830381865afa158015612801573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190612825919061387a565b905080612882577f080fc4a96620c4462e705b23f346413fe3796bb63c6f8d8591baec0e231577a589848481518110612860576128606138dd565b602002602001015160001c60405161287992919061390c565b60405180910390a15b600080516020613d4683398151915260001c6001600160a01b03166370ca10bb8a8585815181106128b5576128b56138dd565b602002602001015161133760f01b6040518463ffffffff1660e01b81526004016128e193929190613b42565b600060405180830381600087803b1580156128fb57600080fd5b505af115801561290f573d6000803e3d6000fd5b50505050600060608a6001600160a01b03168760405161292f9190613986565b600060405180830381855afa9150503d806000811461296a576040519150601f19603f3d011682016040523d82523d6000602084013e61296f565b606091505b509092509050612984816124418b6020613b9d565b9550818015612997575061133760f01b86145b15612bd2577f9c9555b1e3102e3cf48f427d79cb678f5d9bd1ed0ad574389461e255f95170ed8b8b8a8c6040516020016129d2929190613b63565b604051602081830303815290604052805190602001208888815181106129fa576129fa6138dd565b602002602001015160001c604051612a159493929190613d15565b60405180910390a1848481518110612a2f57612a2f6138dd565b6020908102919091018101516001600160a01b038d1660009081528f835260408082206001600160e01b03198f1683528452808220905192939092612a78918d918f9101613b63565b6040516020818303038152906040528051906020012081526020019081526020016000208190555060018d60010160008d6001600160a01b03166001600160a01b0316815260200190815260200160002060008c6001600160e01b0319166001600160e01b031916815260200190815260200160002060008a8c604051602001612b03929190613b63565b60405160208183030381529060405280519060200120815260200190815260200160002060006101000a81548160ff021916908315150217905550600080516020613d4683398151915260001c6001600160a01b03166370ca10bb8c878781518110612b7157612b716138dd565b6020026020010151866040518463ffffffff1660e01b8152600401612b9893929190613b42565b600060405180830381600087803b158015612bb257600080fd5b505af1158015612bc6573d6000803e3d6000fd5b50505050505050612c74565b600080516020613d4683398151915260001c6001600160a01b03166370ca10bb8c878781518110612c0557612c056138dd565b6020026020010151866040518463ffffffff1660e01b8152600401612c2c93929190613b42565b600060405180830381600087803b158015612c4657600080fd5b505af1158015612c5a573d6000803e3d6000fd5b505050505050508080612c6c906138f3565b915050612781565b50612cea565b6040805162461bcd60e51b81526020600482015260248101919091527f73746453746f726167652066696e642853746453746f72616765293a204e6f2060448201527f73746f726167652075736520646574656374656420666f72207461726765742e606482015260840161167e565b6001600160a01b038716600090815260018a01602090815260408083206001600160e01b03198a16845282528083209051909291612d2c9188918a9101613b63565b60408051601f198184030181529181528151602092830120835290820192909252016000205460ff16612db95760405162461bcd60e51b815260206004820152602f60248201527f73746453746f726167652066696e642853746453746f72616765293a20536c6f60448201526e3a143994903737ba103337bab7321760891b606482015260840161167e565b6005890180546001600160a01b031916905560038901805463ffffffff19169055612de860028a016000612f71565b600060048a018190556001600160a01b038816815260208a815260408083206001600160e01b03198a16845282528083209051909291612e2c9188918a9101613b63565b60405160208183030381529060405280519060200120815260200190815260200160002054975050505050505050919050565b6060600082516020612e719190613b9d565b6001600160401b03811115612e8857612e886131ac565b6040519080825280601f01601f191660200182016040528015612eb2576020820181803683370190505b50905060005b835181101561215b576000848281518110612ed557612ed56138dd565b602002602001015190508082602002602001840152508080612ef6906138f3565b915050612eb8565b60008060006020855111612f13578451612f16565b60205b905060005b818110156121e057612f2e816008613b9d565b86612f3983886138a9565b81518110612f4957612f496138dd565b01602001516001600160f81b031916901c929092179180612f69816138f3565b915050612f1b565b50805460008255906000526020600020908101906118ee91905b80821115612f9f5760008155600101612f8b565b5090565b6001600160a01b03811681146118ee57600080fd5b80356001600160401b03811681146107e157600080fd5b60008060408385031215612fe257600080fd5b8235612fed81612fa3565b9150612ffb60208401612fb8565b90509250929050565b805160020b8252602081015161ffff80821660208501528060408401511660408501528060608401511660608501528060808401511660808501528060a08401511660a0850152505063ffffffff60c08201511660c08301525050565b815160020b81526102a081016020830151613084602084018263ffffffff169052565b50604083015161309f60408401826001600160a01b03169052565b50606083015160608301526080830151608083015260a083015160a083015260c08301516130d860c08401826001600160801b03169052565b5060e08301516130f360e08401826001600160801b03169052565b50610100838101516001600160801b03169083015261012080840151600f0b908301526101408084015161312982850182613004565b505061016083015180516001600160a01b03908116610220850152602082015160ff908116610240860152604083015190911661026085015260608201511661028084015261215b565b6000806040838503121561318657600080fd5b823561319181612fa3565b915060208301356131a181612fa3565b809150509250929050565b634e487b7160e01b600052604160045260246000fd5b60405161018081016001600160401b03811182821017156131e5576131e56131ac565b60405290565b60405161016081016001600160401b03811182821017156131e5576131e56131ac565b604051601f8201601f191681016001600160401b0381118282101715613236576132366131ac565b604052919050565b60006001600160401b03821115613257576132576131ac565b5060051b60200190565b600082601f83011261327257600080fd5b813560206132876132828361323e565b61320e565b82815260059290921b840181019181810190868411156132a657600080fd5b8286015b848110156132ca5780356132bd81612fa3565b83529183019183016132aa565b509695505050505050565b6000806000606084860312156132ea57600080fd5b83356132f581612fa3565b9250602084013561330581612fa3565b915060408401356001600160401b0381111561332057600080fd5b61332c86828701613261565b9150509250925092565b6000806040838503121561334957600080fd5b823561335481612fa3565b9150602083013562ffffff811681146131a157600080fd5b60808101610518828460018060a01b0380825116835260ff60208301511660208401528060408301511660408401525060ff60608201511660608301525050565b6000806000606084860312156133c257600080fd5b83356133cd81612fa3565b925061330560208501612fb8565b80151581146118ee57600080fd5b6000602082840312156133fb57600080fd5b81356105be816133db565b60008060006060848603121561341b57600080fd5b833561342681612fa3565b9250602084013561343681612fa3565b9150604084013561344681612fa3565b809150509250925092565b60e081016105188284613004565b60008060006060848603121561347457600080fd5b833561347f81612fa3565b9250602084013561348f81612fa3565b915061349d60408501612fb8565b90509250925092565b81516001600160801b03168152610160810160208301516134d260208401826001600160801b03169052565b5060408301516040830152606083015160608301526080830151608083015260a083015160a083015260c083015160c083015260e083015160e08301526101008084015161352a828501826001600160801b03169052565b5050610120838101516001600160801b03908116918401919091526101409384015116929091019190915290565b6000806000806080858703121561356e57600080fd5b843561357981612fa3565b935061358760208601612fb8565b9250604085013561359781612fa3565b915060608501356001600160401b038111156135b257600080fd5b6135be87828801613261565b91505092959194509250565b600080604083850312156135dd57600080fd5b50508035926020909101359150565b8051600281900b81146107e157600080fd5b805163ffffffff811681146107e157600080fd5b80516107e181612fa3565b80516001600160801b03811681146107e157600080fd5b8051600f81900b81146107e157600080fd5b805161ffff811681146107e157600080fd5b600060e0828403121561366a57600080fd5b60405160e081018181106001600160401b038211171561368c5761368c6131ac565b60405290508061369b836135ec565b81526136a960208401613646565b60208201526136ba60408401613646565b60408201526136cb60608401613646565b60608201526136dc60808401613646565b60808201526136ed60a08401613646565b60a08201526136fe60c084016135fe565b60c08201525092915050565b805160ff811681146107e157600080fd5b60006080828403121561372d57600080fd5b604051608081018181106001600160401b038211171561374f5761374f6131ac565b8060405250809150825161376281612fa3565b81526137706020840161370a565b6020820152604083015161378381612fa3565b60408201526137946060840161370a565b60608201525092915050565b60006102a082840312156137b357600080fd5b6137bb6131c2565b6137c4836135ec565b81526137d2602084016135fe565b60208201526137e360408401613612565b6040820152606083015160608201526080830151608082015260a083015160a082015261381260c0840161361d565b60c082015261382360e0840161361d565b60e082015261010061383681850161361d565b90820152610120613848848201613634565b9082015261014061385b85858301613658565b9082015261386d84610220850161371b565b6101608201529392505050565b60006020828403121561388c57600080fd5b5051919050565b634e487b7160e01b600052601160045260246000fd5b600082198211156138bc576138bc613893565b500190565b6000608082840312156138d357600080fd5b610515838361371b565b634e487b7160e01b600052603260045260246000fd5b60006001820161390557613905613893565b5060010190565b6001600160a01b03929092168252602082015260400190565b60005b83811015613940578181015183820152602001613928565b8381111561394f576000848401525b50505050565b6001600160e01b0319831681528151600090613978816004850160208701613925565b919091016004019392505050565b60008251613998818460208701613925565b9190910192915050565b6000602082840312156139b457600080fd5b81516105be816133db565b600061016082840312156139d257600080fd5b6139da6131eb565b6139e38361361d565b81526139f16020840161361d565b602082015260408301516040820152606083015160608201526080830151608082015260a083015160a082015260c083015160c082015260e083015160e0820152610100613a4081850161361d565b90820152610120613a5284820161361d565b90820152610140613a6484820161361d565b908201529392505050565b600060208284031215613a8157600080fd5b81516105be81612fa3565b60008151808452613aa4816020860160208601613925565b601f01601f19169290920160200192915050565b60408152600560408201526422b93937b960d91b60608201526080602082015260006105156080830184613a8c565b600082821015613af957613af9613893565b500390565b600082613b1b57634e487b7160e01b600052601260045260246000fd5b500690565b604081526000613b336040830185613a8c565b90508260208301529392505050565b6001600160a01b039390931683526020830191909152604082015260600190565b825160009082906020808701845b83811015613b8d57815185529382019390820190600101613b71565b5050948252509092019392505050565b6000816000190483118215151615613bb757613bb7613893565b500290565b6020808252606f908201527f73746453746f726167652066696e642853746453746f72616765293a2050616360408201527f6b656420736c6f742e205468697320776f756c642063617573652064616e676560608201527f726f7573206f76657277726974696e6720616e642063757272656e746c79206960808201526e39b713ba1039bab83837b93a32b21760891b60a082015260c00190565b600082601f830112613c6857600080fd5b81516020613c786132828361323e565b82815260059290921b84018101918181019086841115613c9757600080fd5b8286015b848110156132ca5780518352918301918301613c9b565b60008060408385031215613cc557600080fd5b82516001600160401b0380821115613cdc57600080fd5b613ce886838701613c57565b93506020850151915080821115613cfe57600080fd5b50613d0b85828601613c57565b9150509250929050565b6001600160a01b039490941684526001600160e01b0319929092166020840152604083015260608201526080019056fe885cb69240a935d632d79c317109709ecfa91a80626ff3989d68f67f5b1dd12da264697066735822122072d547e1f13f3b0442e4e2784e4fcd9ecfd5883b90e1a16c0c3d04cdfd10f60764736f6c634300080d0033"
            .parse()
            .expect("invalid bytecode")
        });
    pub struct InvariantFundDraw<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for InvariantFundDraw<M> {
        fn clone(&self) -> Self {
            InvariantFundDraw(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for InvariantFundDraw<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for InvariantFundDraw<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(InvariantFundDraw))
                .field(&self.address())
                .finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> InvariantFundDraw<M> {
        /// Creates a new contract instance with the specified `ethers`
        /// client at the given `Address`. The contract derefs to a `ethers::Contract`
        /// object
        pub fn new<T: Into<::ethers::core::types::Address>>(
            address: T,
            client: ::std::sync::Arc<M>,
        ) -> Self {
            Self(::ethers::contract::Contract::new(
                address.into(),
                INVARIANTFUNDDRAW_ABI.clone(),
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
                INVARIANTFUNDDRAW_ABI.clone(),
                INVARIANTFUNDDRAW_BYTECODE.clone().into(),
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
        ///Calls the contract's `fund_asset` (0xf8c28267) function
        pub fn fund_asset(
            &self,
            amount: ::ethers::core::types::U256,
            index: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([248, 194, 130, 103], (amount, index))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `fund_quote` (0xf9df4c3b) function
        pub fn fund_quote(
            &self,
            amount: ::ethers::core::types::U256,
            index: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([249, 223, 76, 59], (amount, index))
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
        pub fn events(&self) -> ::ethers::contract::builders::Event<M, InvariantFundDrawEvents> {
            self.0.event_with_filter(Default::default())
        }
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>>
        for InvariantFundDraw<M>
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
    pub enum InvariantFundDrawEvents {
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
    impl ::ethers::contract::EthLogDecode for InvariantFundDrawEvents {
        fn decode_log(
            log: &::ethers::core::abi::RawLog,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::Error>
        where
            Self: Sized,
        {
            if let Ok(decoded) = LogFilter::decode_log(log) {
                return Ok(InvariantFundDrawEvents::LogFilter(decoded));
            }
            if let Ok(decoded) = LogAddressFilter::decode_log(log) {
                return Ok(InvariantFundDrawEvents::LogAddressFilter(decoded));
            }
            if let Ok(decoded) = LogArray1Filter::decode_log(log) {
                return Ok(InvariantFundDrawEvents::LogArray1Filter(decoded));
            }
            if let Ok(decoded) = LogArray2Filter::decode_log(log) {
                return Ok(InvariantFundDrawEvents::LogArray2Filter(decoded));
            }
            if let Ok(decoded) = LogArray3Filter::decode_log(log) {
                return Ok(InvariantFundDrawEvents::LogArray3Filter(decoded));
            }
            if let Ok(decoded) = LogBytesFilter::decode_log(log) {
                return Ok(InvariantFundDrawEvents::LogBytesFilter(decoded));
            }
            if let Ok(decoded) = LogBytes32Filter::decode_log(log) {
                return Ok(InvariantFundDrawEvents::LogBytes32Filter(decoded));
            }
            if let Ok(decoded) = LogIntFilter::decode_log(log) {
                return Ok(InvariantFundDrawEvents::LogIntFilter(decoded));
            }
            if let Ok(decoded) = LogNamedAddressFilter::decode_log(log) {
                return Ok(InvariantFundDrawEvents::LogNamedAddressFilter(decoded));
            }
            if let Ok(decoded) = LogNamedArray1Filter::decode_log(log) {
                return Ok(InvariantFundDrawEvents::LogNamedArray1Filter(decoded));
            }
            if let Ok(decoded) = LogNamedArray2Filter::decode_log(log) {
                return Ok(InvariantFundDrawEvents::LogNamedArray2Filter(decoded));
            }
            if let Ok(decoded) = LogNamedArray3Filter::decode_log(log) {
                return Ok(InvariantFundDrawEvents::LogNamedArray3Filter(decoded));
            }
            if let Ok(decoded) = LogNamedBytesFilter::decode_log(log) {
                return Ok(InvariantFundDrawEvents::LogNamedBytesFilter(decoded));
            }
            if let Ok(decoded) = LogNamedBytes32Filter::decode_log(log) {
                return Ok(InvariantFundDrawEvents::LogNamedBytes32Filter(decoded));
            }
            if let Ok(decoded) = LogNamedDecimalIntFilter::decode_log(log) {
                return Ok(InvariantFundDrawEvents::LogNamedDecimalIntFilter(decoded));
            }
            if let Ok(decoded) = LogNamedDecimalUintFilter::decode_log(log) {
                return Ok(InvariantFundDrawEvents::LogNamedDecimalUintFilter(decoded));
            }
            if let Ok(decoded) = LogNamedIntFilter::decode_log(log) {
                return Ok(InvariantFundDrawEvents::LogNamedIntFilter(decoded));
            }
            if let Ok(decoded) = LogNamedStringFilter::decode_log(log) {
                return Ok(InvariantFundDrawEvents::LogNamedStringFilter(decoded));
            }
            if let Ok(decoded) = LogNamedUintFilter::decode_log(log) {
                return Ok(InvariantFundDrawEvents::LogNamedUintFilter(decoded));
            }
            if let Ok(decoded) = LogStringFilter::decode_log(log) {
                return Ok(InvariantFundDrawEvents::LogStringFilter(decoded));
            }
            if let Ok(decoded) = LogUintFilter::decode_log(log) {
                return Ok(InvariantFundDrawEvents::LogUintFilter(decoded));
            }
            if let Ok(decoded) = LogsFilter::decode_log(log) {
                return Ok(InvariantFundDrawEvents::LogsFilter(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData)
        }
    }
    impl ::std::fmt::Display for InvariantFundDrawEvents {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                InvariantFundDrawEvents::LogFilter(element) => element.fmt(f),
                InvariantFundDrawEvents::LogAddressFilter(element) => element.fmt(f),
                InvariantFundDrawEvents::LogArray1Filter(element) => element.fmt(f),
                InvariantFundDrawEvents::LogArray2Filter(element) => element.fmt(f),
                InvariantFundDrawEvents::LogArray3Filter(element) => element.fmt(f),
                InvariantFundDrawEvents::LogBytesFilter(element) => element.fmt(f),
                InvariantFundDrawEvents::LogBytes32Filter(element) => element.fmt(f),
                InvariantFundDrawEvents::LogIntFilter(element) => element.fmt(f),
                InvariantFundDrawEvents::LogNamedAddressFilter(element) => element.fmt(f),
                InvariantFundDrawEvents::LogNamedArray1Filter(element) => element.fmt(f),
                InvariantFundDrawEvents::LogNamedArray2Filter(element) => element.fmt(f),
                InvariantFundDrawEvents::LogNamedArray3Filter(element) => element.fmt(f),
                InvariantFundDrawEvents::LogNamedBytesFilter(element) => element.fmt(f),
                InvariantFundDrawEvents::LogNamedBytes32Filter(element) => element.fmt(f),
                InvariantFundDrawEvents::LogNamedDecimalIntFilter(element) => element.fmt(f),
                InvariantFundDrawEvents::LogNamedDecimalUintFilter(element) => element.fmt(f),
                InvariantFundDrawEvents::LogNamedIntFilter(element) => element.fmt(f),
                InvariantFundDrawEvents::LogNamedStringFilter(element) => element.fmt(f),
                InvariantFundDrawEvents::LogNamedUintFilter(element) => element.fmt(f),
                InvariantFundDrawEvents::LogStringFilter(element) => element.fmt(f),
                InvariantFundDrawEvents::LogUintFilter(element) => element.fmt(f),
                InvariantFundDrawEvents::LogsFilter(element) => element.fmt(f),
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
    ///Container type for all input parameters for the `fund_asset` function with signature `fund_asset(uint256,uint256)` and selector `0xf8c28267`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "fund_asset", abi = "fund_asset(uint256,uint256)")]
    pub struct FundAssetCall {
        pub amount: ::ethers::core::types::U256,
        pub index: ::ethers::core::types::U256,
    }
    ///Container type for all input parameters for the `fund_quote` function with signature `fund_quote(uint256,uint256)` and selector `0xf9df4c3b`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "fund_quote", abi = "fund_quote(uint256,uint256)")]
    pub struct FundQuoteCall {
        pub amount: ::ethers::core::types::U256,
        pub index: ::ethers::core::types::U256,
    }
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
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum InvariantFundDrawCalls {
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
        FundAsset(FundAssetCall),
        FundQuote(FundQuoteCall),
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
    impl ::ethers::core::abi::AbiDecode for InvariantFundDrawCalls {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded) =
                <IsTestCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::IsTest(decoded));
            }
            if let Ok(decoded) =
                <AssetCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::Asset(decoded));
            }
            if let Ok(decoded) =
                <HyperCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::Hyper(decoded));
            }
            if let Ok(decoded) =
                <PoolIdCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::PoolId(decoded));
            }
            if let Ok(decoded) =
                <QuoteCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::Quote(decoded));
            }
            if let Ok(decoded) =
                <_GetBalanceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::_GetBalance(decoded));
            }
            if let Ok(decoded) =
                <_GetPoolCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::_GetPool(decoded));
            }
            if let Ok(decoded) =
                <_GetPositionCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::_GetPosition(decoded));
            }
            if let Ok(decoded) =
                <_GetReserveCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::_GetReserve(decoded));
            }
            if let Ok(decoded) =
                <FailedCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::Failed(decoded));
            }
            if let Ok(decoded) =
                <FundAssetCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::FundAsset(decoded));
            }
            if let Ok(decoded) =
                <FundQuoteCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::FundQuote(decoded));
            }
            if let Ok(decoded) =
                <GetBalanceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::GetBalance(decoded));
            }
            if let Ok(decoded) =
                <GetBalanceSumCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::GetBalanceSum(decoded));
            }
            if let Ok(decoded) =
                <GetCurveCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::GetCurve(decoded));
            }
            if let Ok(decoded) =
                <GetMaxSwapLimitCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::GetMaxSwapLimit(decoded));
            }
            if let Ok(decoded) =
                <GetPairCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::GetPair(decoded));
            }
            if let Ok(decoded) =
                <GetPhysicalBalanceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::GetPhysicalBalance(decoded));
            }
            if let Ok(decoded) =
                <GetPoolCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::GetPool(decoded));
            }
            if let Ok(decoded) =
                <GetPositionCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::GetPosition(decoded));
            }
            if let Ok(decoded) =
                <GetPositionLiquiditySumCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                )
            {
                return Ok(InvariantFundDrawCalls::GetPositionLiquiditySum(decoded));
            }
            if let Ok(decoded) =
                <GetReserveCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::GetReserve(decoded));
            }
            if let Ok(decoded) =
                <GetStateCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::GetState(decoded));
            }
            if let Ok(decoded) =
                <GetVirtualBalanceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantFundDrawCalls::GetVirtualBalance(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for InvariantFundDrawCalls {
        fn encode(self) -> Vec<u8> {
            match self {
                InvariantFundDrawCalls::IsTest(element) => element.encode(),
                InvariantFundDrawCalls::Asset(element) => element.encode(),
                InvariantFundDrawCalls::Hyper(element) => element.encode(),
                InvariantFundDrawCalls::PoolId(element) => element.encode(),
                InvariantFundDrawCalls::Quote(element) => element.encode(),
                InvariantFundDrawCalls::_GetBalance(element) => element.encode(),
                InvariantFundDrawCalls::_GetPool(element) => element.encode(),
                InvariantFundDrawCalls::_GetPosition(element) => element.encode(),
                InvariantFundDrawCalls::_GetReserve(element) => element.encode(),
                InvariantFundDrawCalls::Failed(element) => element.encode(),
                InvariantFundDrawCalls::FundAsset(element) => element.encode(),
                InvariantFundDrawCalls::FundQuote(element) => element.encode(),
                InvariantFundDrawCalls::GetBalance(element) => element.encode(),
                InvariantFundDrawCalls::GetBalanceSum(element) => element.encode(),
                InvariantFundDrawCalls::GetCurve(element) => element.encode(),
                InvariantFundDrawCalls::GetMaxSwapLimit(element) => element.encode(),
                InvariantFundDrawCalls::GetPair(element) => element.encode(),
                InvariantFundDrawCalls::GetPhysicalBalance(element) => element.encode(),
                InvariantFundDrawCalls::GetPool(element) => element.encode(),
                InvariantFundDrawCalls::GetPosition(element) => element.encode(),
                InvariantFundDrawCalls::GetPositionLiquiditySum(element) => element.encode(),
                InvariantFundDrawCalls::GetReserve(element) => element.encode(),
                InvariantFundDrawCalls::GetState(element) => element.encode(),
                InvariantFundDrawCalls::GetVirtualBalance(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for InvariantFundDrawCalls {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                InvariantFundDrawCalls::IsTest(element) => element.fmt(f),
                InvariantFundDrawCalls::Asset(element) => element.fmt(f),
                InvariantFundDrawCalls::Hyper(element) => element.fmt(f),
                InvariantFundDrawCalls::PoolId(element) => element.fmt(f),
                InvariantFundDrawCalls::Quote(element) => element.fmt(f),
                InvariantFundDrawCalls::_GetBalance(element) => element.fmt(f),
                InvariantFundDrawCalls::_GetPool(element) => element.fmt(f),
                InvariantFundDrawCalls::_GetPosition(element) => element.fmt(f),
                InvariantFundDrawCalls::_GetReserve(element) => element.fmt(f),
                InvariantFundDrawCalls::Failed(element) => element.fmt(f),
                InvariantFundDrawCalls::FundAsset(element) => element.fmt(f),
                InvariantFundDrawCalls::FundQuote(element) => element.fmt(f),
                InvariantFundDrawCalls::GetBalance(element) => element.fmt(f),
                InvariantFundDrawCalls::GetBalanceSum(element) => element.fmt(f),
                InvariantFundDrawCalls::GetCurve(element) => element.fmt(f),
                InvariantFundDrawCalls::GetMaxSwapLimit(element) => element.fmt(f),
                InvariantFundDrawCalls::GetPair(element) => element.fmt(f),
                InvariantFundDrawCalls::GetPhysicalBalance(element) => element.fmt(f),
                InvariantFundDrawCalls::GetPool(element) => element.fmt(f),
                InvariantFundDrawCalls::GetPosition(element) => element.fmt(f),
                InvariantFundDrawCalls::GetPositionLiquiditySum(element) => element.fmt(f),
                InvariantFundDrawCalls::GetReserve(element) => element.fmt(f),
                InvariantFundDrawCalls::GetState(element) => element.fmt(f),
                InvariantFundDrawCalls::GetVirtualBalance(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<IsTestCall> for InvariantFundDrawCalls {
        fn from(var: IsTestCall) -> Self {
            InvariantFundDrawCalls::IsTest(var)
        }
    }
    impl ::std::convert::From<AssetCall> for InvariantFundDrawCalls {
        fn from(var: AssetCall) -> Self {
            InvariantFundDrawCalls::Asset(var)
        }
    }
    impl ::std::convert::From<HyperCall> for InvariantFundDrawCalls {
        fn from(var: HyperCall) -> Self {
            InvariantFundDrawCalls::Hyper(var)
        }
    }
    impl ::std::convert::From<PoolIdCall> for InvariantFundDrawCalls {
        fn from(var: PoolIdCall) -> Self {
            InvariantFundDrawCalls::PoolId(var)
        }
    }
    impl ::std::convert::From<QuoteCall> for InvariantFundDrawCalls {
        fn from(var: QuoteCall) -> Self {
            InvariantFundDrawCalls::Quote(var)
        }
    }
    impl ::std::convert::From<_GetBalanceCall> for InvariantFundDrawCalls {
        fn from(var: _GetBalanceCall) -> Self {
            InvariantFundDrawCalls::_GetBalance(var)
        }
    }
    impl ::std::convert::From<_GetPoolCall> for InvariantFundDrawCalls {
        fn from(var: _GetPoolCall) -> Self {
            InvariantFundDrawCalls::_GetPool(var)
        }
    }
    impl ::std::convert::From<_GetPositionCall> for InvariantFundDrawCalls {
        fn from(var: _GetPositionCall) -> Self {
            InvariantFundDrawCalls::_GetPosition(var)
        }
    }
    impl ::std::convert::From<_GetReserveCall> for InvariantFundDrawCalls {
        fn from(var: _GetReserveCall) -> Self {
            InvariantFundDrawCalls::_GetReserve(var)
        }
    }
    impl ::std::convert::From<FailedCall> for InvariantFundDrawCalls {
        fn from(var: FailedCall) -> Self {
            InvariantFundDrawCalls::Failed(var)
        }
    }
    impl ::std::convert::From<FundAssetCall> for InvariantFundDrawCalls {
        fn from(var: FundAssetCall) -> Self {
            InvariantFundDrawCalls::FundAsset(var)
        }
    }
    impl ::std::convert::From<FundQuoteCall> for InvariantFundDrawCalls {
        fn from(var: FundQuoteCall) -> Self {
            InvariantFundDrawCalls::FundQuote(var)
        }
    }
    impl ::std::convert::From<GetBalanceCall> for InvariantFundDrawCalls {
        fn from(var: GetBalanceCall) -> Self {
            InvariantFundDrawCalls::GetBalance(var)
        }
    }
    impl ::std::convert::From<GetBalanceSumCall> for InvariantFundDrawCalls {
        fn from(var: GetBalanceSumCall) -> Self {
            InvariantFundDrawCalls::GetBalanceSum(var)
        }
    }
    impl ::std::convert::From<GetCurveCall> for InvariantFundDrawCalls {
        fn from(var: GetCurveCall) -> Self {
            InvariantFundDrawCalls::GetCurve(var)
        }
    }
    impl ::std::convert::From<GetMaxSwapLimitCall> for InvariantFundDrawCalls {
        fn from(var: GetMaxSwapLimitCall) -> Self {
            InvariantFundDrawCalls::GetMaxSwapLimit(var)
        }
    }
    impl ::std::convert::From<GetPairCall> for InvariantFundDrawCalls {
        fn from(var: GetPairCall) -> Self {
            InvariantFundDrawCalls::GetPair(var)
        }
    }
    impl ::std::convert::From<GetPhysicalBalanceCall> for InvariantFundDrawCalls {
        fn from(var: GetPhysicalBalanceCall) -> Self {
            InvariantFundDrawCalls::GetPhysicalBalance(var)
        }
    }
    impl ::std::convert::From<GetPoolCall> for InvariantFundDrawCalls {
        fn from(var: GetPoolCall) -> Self {
            InvariantFundDrawCalls::GetPool(var)
        }
    }
    impl ::std::convert::From<GetPositionCall> for InvariantFundDrawCalls {
        fn from(var: GetPositionCall) -> Self {
            InvariantFundDrawCalls::GetPosition(var)
        }
    }
    impl ::std::convert::From<GetPositionLiquiditySumCall> for InvariantFundDrawCalls {
        fn from(var: GetPositionLiquiditySumCall) -> Self {
            InvariantFundDrawCalls::GetPositionLiquiditySum(var)
        }
    }
    impl ::std::convert::From<GetReserveCall> for InvariantFundDrawCalls {
        fn from(var: GetReserveCall) -> Self {
            InvariantFundDrawCalls::GetReserve(var)
        }
    }
    impl ::std::convert::From<GetStateCall> for InvariantFundDrawCalls {
        fn from(var: GetStateCall) -> Self {
            InvariantFundDrawCalls::GetState(var)
        }
    }
    impl ::std::convert::From<GetVirtualBalanceCall> for InvariantFundDrawCalls {
        fn from(var: GetVirtualBalanceCall) -> Self {
            InvariantFundDrawCalls::GetVirtualBalance(var)
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
