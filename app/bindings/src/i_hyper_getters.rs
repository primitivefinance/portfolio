pub use i_hyper_getters::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod i_hyper_getters {
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
    ///IHyperGetters was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
    use std::sync::Arc;
    #[rustfmt::skip]
    const __ABI: &str = "[{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"bool\",\"name\":\"sellAsset\",\"type\":\"bool\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amountIn\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getAmountOut\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getAmounts\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getLatestPrice\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"price\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"int128\",\"name\":\"deltaLiquidity\",\"type\":\"int128\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getLiquidityDeltas\",\"outputs\":[{\"internalType\":\"uint128\",\"name\":\"deltaAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"deltaQuote\",\"type\":\"uint128\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getMaxLiquidity\",\"outputs\":[{\"internalType\":\"uint128\",\"name\":\"deltaLiquidity\",\"type\":\"uint128\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getNetBalance\",\"outputs\":[{\"internalType\":\"int256\",\"name\":\"\",\"type\":\"int256\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPairNonce\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getReserve\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getVirtualReserves\",\"outputs\":[{\"internalType\":\"uint128\",\"name\":\"deltaAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"deltaQuote\",\"type\":\"uint128\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint24\",\"name\":\"pairId\",\"type\":\"uint24\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"pairs\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"pools\",\"outputs\":[{\"internalType\":\"int24\",\"name\":\"lastTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"lastTimestamp\",\"type\":\"uint32\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"controller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalReward\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"lastPrice\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"liquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"int128\",\"name\":\"stakedLiquidityDelta\",\"type\":\"int128\",\"components\":[]},{\"internalType\":\"struct HyperCurve\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]},{\"internalType\":\"struct HyperPair\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"positions\",\"outputs\":[{\"internalType\":\"uint128\",\"name\":\"freeLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"lastTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"stakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"unstakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthRewardLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuoteLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedQuote\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedReward\",\"type\":\"uint128\",\"components\":[]}]}]";
    /// The parsed JSON-ABI of the contract.
    pub static IHYPERGETTERS_ABI: ::ethers::contract::Lazy<::ethers::core::abi::Abi> =
        ::ethers::contract::Lazy::new(|| {
            ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi")
        });
    pub struct IHyperGetters<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for IHyperGetters<M> {
        fn clone(&self) -> Self {
            IHyperGetters(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for IHyperGetters<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for IHyperGetters<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(IHyperGetters))
                .field(&self.address())
                .finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> IHyperGetters<M> {
        /// Creates a new contract instance with the specified `ethers`
        /// client at the given `Address`. The contract derefs to a `ethers::Contract`
        /// object
        pub fn new<T: Into<::ethers::core::types::Address>>(
            address: T,
            client: ::std::sync::Arc<M>,
        ) -> Self {
            Self(::ethers::contract::Contract::new(
                address.into(),
                IHYPERGETTERS_ABI.clone(),
                client,
            ))
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
        ///Calls the contract's `getPairNonce` (0x078888d6) function
        pub fn get_pair_nonce(
            &self,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([7, 136, 136, 214], ())
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
            pair_id: u32,
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
                .method_hash([94, 71, 102, 60], pair_id)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `pools` (0x89a5f084) function
        pub fn pools(
            &self,
            pool_id: u64,
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
                .method_hash([137, 165, 240, 132], pool_id)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `positions` (0xb68513ea) function
        pub fn positions(
            &self,
            owner: ::ethers::core::types::Address,
            pool_id: u64,
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
                .method_hash([182, 133, 19, 234], (owner, pool_id))
                .expect("method not found (this should never happen)")
        }
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>>
        for IHyperGetters<M>
    {
        fn from(contract: ::ethers::contract::Contract<M>) -> Self {
            Self::new(contract.address(), contract.client())
        }
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
        pub pool_id: u64,
    }
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum IHyperGettersCalls {
        GetAmountOut(GetAmountOutCall),
        GetAmounts(GetAmountsCall),
        GetBalance(GetBalanceCall),
        GetLatestPrice(GetLatestPriceCall),
        GetLiquidityDeltas(GetLiquidityDeltasCall),
        GetMaxLiquidity(GetMaxLiquidityCall),
        GetNetBalance(GetNetBalanceCall),
        GetPairNonce(GetPairNonceCall),
        GetReserve(GetReserveCall),
        GetVirtualReserves(GetVirtualReservesCall),
        Pairs(PairsCall),
        Pools(PoolsCall),
        Positions(PositionsCall),
    }
    impl ::ethers::core::abi::AbiDecode for IHyperGettersCalls {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded) =
                <GetAmountOutCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperGettersCalls::GetAmountOut(decoded));
            }
            if let Ok(decoded) =
                <GetAmountsCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperGettersCalls::GetAmounts(decoded));
            }
            if let Ok(decoded) =
                <GetBalanceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperGettersCalls::GetBalance(decoded));
            }
            if let Ok(decoded) =
                <GetLatestPriceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperGettersCalls::GetLatestPrice(decoded));
            }
            if let Ok(decoded) =
                <GetLiquidityDeltasCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperGettersCalls::GetLiquidityDeltas(decoded));
            }
            if let Ok(decoded) =
                <GetMaxLiquidityCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperGettersCalls::GetMaxLiquidity(decoded));
            }
            if let Ok(decoded) =
                <GetNetBalanceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperGettersCalls::GetNetBalance(decoded));
            }
            if let Ok(decoded) =
                <GetPairNonceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperGettersCalls::GetPairNonce(decoded));
            }
            if let Ok(decoded) =
                <GetReserveCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperGettersCalls::GetReserve(decoded));
            }
            if let Ok(decoded) =
                <GetVirtualReservesCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperGettersCalls::GetVirtualReserves(decoded));
            }
            if let Ok(decoded) =
                <PairsCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperGettersCalls::Pairs(decoded));
            }
            if let Ok(decoded) =
                <PoolsCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperGettersCalls::Pools(decoded));
            }
            if let Ok(decoded) =
                <PositionsCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperGettersCalls::Positions(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for IHyperGettersCalls {
        fn encode(self) -> Vec<u8> {
            match self {
                IHyperGettersCalls::GetAmountOut(element) => element.encode(),
                IHyperGettersCalls::GetAmounts(element) => element.encode(),
                IHyperGettersCalls::GetBalance(element) => element.encode(),
                IHyperGettersCalls::GetLatestPrice(element) => element.encode(),
                IHyperGettersCalls::GetLiquidityDeltas(element) => element.encode(),
                IHyperGettersCalls::GetMaxLiquidity(element) => element.encode(),
                IHyperGettersCalls::GetNetBalance(element) => element.encode(),
                IHyperGettersCalls::GetPairNonce(element) => element.encode(),
                IHyperGettersCalls::GetReserve(element) => element.encode(),
                IHyperGettersCalls::GetVirtualReserves(element) => element.encode(),
                IHyperGettersCalls::Pairs(element) => element.encode(),
                IHyperGettersCalls::Pools(element) => element.encode(),
                IHyperGettersCalls::Positions(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for IHyperGettersCalls {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                IHyperGettersCalls::GetAmountOut(element) => element.fmt(f),
                IHyperGettersCalls::GetAmounts(element) => element.fmt(f),
                IHyperGettersCalls::GetBalance(element) => element.fmt(f),
                IHyperGettersCalls::GetLatestPrice(element) => element.fmt(f),
                IHyperGettersCalls::GetLiquidityDeltas(element) => element.fmt(f),
                IHyperGettersCalls::GetMaxLiquidity(element) => element.fmt(f),
                IHyperGettersCalls::GetNetBalance(element) => element.fmt(f),
                IHyperGettersCalls::GetPairNonce(element) => element.fmt(f),
                IHyperGettersCalls::GetReserve(element) => element.fmt(f),
                IHyperGettersCalls::GetVirtualReserves(element) => element.fmt(f),
                IHyperGettersCalls::Pairs(element) => element.fmt(f),
                IHyperGettersCalls::Pools(element) => element.fmt(f),
                IHyperGettersCalls::Positions(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<GetAmountOutCall> for IHyperGettersCalls {
        fn from(var: GetAmountOutCall) -> Self {
            IHyperGettersCalls::GetAmountOut(var)
        }
    }
    impl ::std::convert::From<GetAmountsCall> for IHyperGettersCalls {
        fn from(var: GetAmountsCall) -> Self {
            IHyperGettersCalls::GetAmounts(var)
        }
    }
    impl ::std::convert::From<GetBalanceCall> for IHyperGettersCalls {
        fn from(var: GetBalanceCall) -> Self {
            IHyperGettersCalls::GetBalance(var)
        }
    }
    impl ::std::convert::From<GetLatestPriceCall> for IHyperGettersCalls {
        fn from(var: GetLatestPriceCall) -> Self {
            IHyperGettersCalls::GetLatestPrice(var)
        }
    }
    impl ::std::convert::From<GetLiquidityDeltasCall> for IHyperGettersCalls {
        fn from(var: GetLiquidityDeltasCall) -> Self {
            IHyperGettersCalls::GetLiquidityDeltas(var)
        }
    }
    impl ::std::convert::From<GetMaxLiquidityCall> for IHyperGettersCalls {
        fn from(var: GetMaxLiquidityCall) -> Self {
            IHyperGettersCalls::GetMaxLiquidity(var)
        }
    }
    impl ::std::convert::From<GetNetBalanceCall> for IHyperGettersCalls {
        fn from(var: GetNetBalanceCall) -> Self {
            IHyperGettersCalls::GetNetBalance(var)
        }
    }
    impl ::std::convert::From<GetPairNonceCall> for IHyperGettersCalls {
        fn from(var: GetPairNonceCall) -> Self {
            IHyperGettersCalls::GetPairNonce(var)
        }
    }
    impl ::std::convert::From<GetReserveCall> for IHyperGettersCalls {
        fn from(var: GetReserveCall) -> Self {
            IHyperGettersCalls::GetReserve(var)
        }
    }
    impl ::std::convert::From<GetVirtualReservesCall> for IHyperGettersCalls {
        fn from(var: GetVirtualReservesCall) -> Self {
            IHyperGettersCalls::GetVirtualReserves(var)
        }
    }
    impl ::std::convert::From<PairsCall> for IHyperGettersCalls {
        fn from(var: PairsCall) -> Self {
            IHyperGettersCalls::Pairs(var)
        }
    }
    impl ::std::convert::From<PoolsCall> for IHyperGettersCalls {
        fn from(var: PoolsCall) -> Self {
            IHyperGettersCalls::Pools(var)
        }
    }
    impl ::std::convert::From<PositionsCall> for IHyperGettersCalls {
        fn from(var: PositionsCall) -> Self {
            IHyperGettersCalls::Positions(var)
        }
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
    pub struct GetAmountOutReturn(pub ::ethers::core::types::U256);
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
        pub p10: HyperCurve,
        pub p11: HyperPair,
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
}
