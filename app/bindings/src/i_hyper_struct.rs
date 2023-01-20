pub use i_hyper_struct::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod i_hyper_struct {
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
    ///IHyperStruct was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
    use std::sync::Arc;
    #[rustfmt::skip]
    const __ABI: &str = "[{\"inputs\":[{\"internalType\":\"uint24\",\"name\":\"pairId\",\"type\":\"uint24\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"pairs\",\"outputs\":[{\"internalType\":\"struct HyperPair\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"pools\",\"outputs\":[{\"internalType\":\"struct HyperPool\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"lastTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"lastTimestamp\",\"type\":\"uint32\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"controller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalReward\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"lastPrice\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"liquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"int128\",\"name\":\"stakedLiquidityDelta\",\"type\":\"int128\",\"components\":[]},{\"internalType\":\"struct HyperCurve\",\"name\":\"params\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]},{\"internalType\":\"struct HyperPair\",\"name\":\"pair\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"positionId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"positions\",\"outputs\":[{\"internalType\":\"struct HyperPosition\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"uint128\",\"name\":\"freeLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"lastTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"stakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"unstakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthRewardLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuoteLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedQuote\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedReward\",\"type\":\"uint128\",\"components\":[]}]}]}]";
    /// The parsed JSON-ABI of the contract.
    pub static IHYPERSTRUCT_ABI: ::ethers::contract::Lazy<::ethers::core::abi::Abi> =
        ::ethers::contract::Lazy::new(|| {
            ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi")
        });
    pub struct IHyperStruct<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for IHyperStruct<M> {
        fn clone(&self) -> Self {
            IHyperStruct(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for IHyperStruct<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for IHyperStruct<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(IHyperStruct))
                .field(&self.address())
                .finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> IHyperStruct<M> {
        /// Creates a new contract instance with the specified `ethers`
        /// client at the given `Address`. The contract derefs to a `ethers::Contract`
        /// object
        pub fn new<T: Into<::ethers::core::types::Address>>(
            address: T,
            client: ::std::sync::Arc<M>,
        ) -> Self {
            Self(::ethers::contract::Contract::new(
                address.into(),
                IHYPERSTRUCT_ABI.clone(),
                client,
            ))
        }
        ///Calls the contract's `pairs` (0x5e47663c) function
        pub fn pairs(
            &self,
            pair_id: u32,
        ) -> ::ethers::contract::builders::ContractCall<M, HyperPair> {
            self.0
                .method_hash([94, 71, 102, 60], pair_id)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `pools` (0x89a5f084) function
        pub fn pools(
            &self,
            pool_id: u64,
        ) -> ::ethers::contract::builders::ContractCall<M, HyperPool> {
            self.0
                .method_hash([137, 165, 240, 132], pool_id)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `positions` (0xb68513ea) function
        pub fn positions(
            &self,
            owner: ::ethers::core::types::Address,
            position_id: u64,
        ) -> ::ethers::contract::builders::ContractCall<M, HyperPosition> {
            self.0
                .method_hash([182, 133, 19, 234], (owner, position_id))
                .expect("method not found (this should never happen)")
        }
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>> for IHyperStruct<M> {
        fn from(contract: ::ethers::contract::Contract<M>) -> Self {
            Self::new(contract.address(), contract.client())
        }
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
    pub struct PairsCall {
        pub pair_id: u32,
    }
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
    pub struct PoolsCall {
        pub pool_id: u64,
    }
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
    pub struct PositionsCall {
        pub owner: ::ethers::core::types::Address,
        pub position_id: u64,
    }
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum IHyperStructCalls {
        Pairs(PairsCall),
        Pools(PoolsCall),
        Positions(PositionsCall),
    }
    impl ::ethers::core::abi::AbiDecode for IHyperStructCalls {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded) =
                <PairsCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperStructCalls::Pairs(decoded));
            }
            if let Ok(decoded) =
                <PoolsCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperStructCalls::Pools(decoded));
            }
            if let Ok(decoded) =
                <PositionsCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperStructCalls::Positions(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for IHyperStructCalls {
        fn encode(self) -> Vec<u8> {
            match self {
                IHyperStructCalls::Pairs(element) => element.encode(),
                IHyperStructCalls::Pools(element) => element.encode(),
                IHyperStructCalls::Positions(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for IHyperStructCalls {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                IHyperStructCalls::Pairs(element) => element.fmt(f),
                IHyperStructCalls::Pools(element) => element.fmt(f),
                IHyperStructCalls::Positions(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<PairsCall> for IHyperStructCalls {
        fn from(var: PairsCall) -> Self {
            IHyperStructCalls::Pairs(var)
        }
    }
    impl ::std::convert::From<PoolsCall> for IHyperStructCalls {
        fn from(var: PoolsCall) -> Self {
            IHyperStructCalls::Pools(var)
        }
    }
    impl ::std::convert::From<PositionsCall> for IHyperStructCalls {
        fn from(var: PositionsCall) -> Self {
            IHyperStructCalls::Positions(var)
        }
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
    pub struct PairsReturn(pub HyperPair);
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
    pub struct PoolsReturn(pub HyperPool);
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
    pub struct PositionsReturn(pub HyperPosition);
}
