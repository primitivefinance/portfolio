pub use i_hyper_actions::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod i_hyper_actions {
    #![allow(clippy::enum_variant_names)]
    #![allow(dead_code)]
    #![allow(clippy::type_complexity)]
    #![allow(unused_imports)]
    use ::ethers::contract::{
        builders::{ContractCall, Event},
        Contract, Lazy,
    };
    use ::ethers::core::{
        abi::{Abi, Detokenize, InvalidOutputType, Token, Tokenizable},
        types::*,
    };
    use ::ethers::providers::Middleware;
    ///IHyperActions was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
    use std::sync::Arc;
    #[rustfmt::skip]
    const __ABI: &str = "[{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaLiquidity\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"allocate\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"changeParameters\",\"outputs\":[]},{\"inputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\",\"name\":\"deposit\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"to\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"draw\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"fund\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"deltaLiquidity\",\"type\":\"uint128\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"stake\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"bool\",\"name\":\"sellAsset\",\"type\":\"bool\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"limit\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"swap\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"output\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"remainder\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"unallocate\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"deltaAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deltaQuote\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"deltaLiquidity\",\"type\":\"uint128\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"unstake\",\"outputs\":[]}]";
    /// The parsed JSON-ABI of the contract.
    pub static IHYPERACTIONS_ABI: ::ethers::contract::Lazy<::ethers::core::abi::Abi> =
        ::ethers::contract::Lazy::new(|| {
            ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi")
        });
    pub struct IHyperActions<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for IHyperActions<M> {
        fn clone(&self) -> Self {
            IHyperActions(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for IHyperActions<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for IHyperActions<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(IHyperActions))
                .field(&self.address())
                .finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> IHyperActions<M> {
        /// Creates a new contract instance with the specified `ethers`
        /// client at the given `Address`. The contract derefs to a `ethers::Contract`
        /// object
        pub fn new<T: Into<::ethers::core::types::Address>>(
            address: T,
            client: ::std::sync::Arc<M>,
        ) -> Self {
            Self(::ethers::contract::Contract::new(
                address.into(),
                IHYPERACTIONS_ABI.clone(),
                client,
            ))
        }
        ///Calls the contract's `allocate` (0x2c0f8903) function
        pub fn allocate(
            &self,
            pool_id: u64,
            delta_liquidity: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<
            M,
            (::ethers::core::types::U256, ::ethers::core::types::U256),
        > {
            self.0
                .method_hash([44, 15, 137, 3], (pool_id, delta_liquidity))
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
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>>
        for IHyperActions<M>
    {
        fn from(contract: ::ethers::contract::Contract<M>) -> Self {
            Self::new(contract.address(), contract.client())
        }
    }
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
        pub delta_liquidity: ::ethers::core::types::U256,
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
    pub enum IHyperActionsCalls {
        Allocate(AllocateCall),
        ChangeParameters(ChangeParametersCall),
        Deposit(DepositCall),
        Draw(DrawCall),
        Fund(FundCall),
        Stake(StakeCall),
        Swap(SwapCall),
        Unallocate(UnallocateCall),
        Unstake(UnstakeCall),
    }
    impl ::ethers::core::abi::AbiDecode for IHyperActionsCalls {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded) =
                <AllocateCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperActionsCalls::Allocate(decoded));
            }
            if let Ok(decoded) =
                <ChangeParametersCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperActionsCalls::ChangeParameters(decoded));
            }
            if let Ok(decoded) =
                <DepositCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperActionsCalls::Deposit(decoded));
            }
            if let Ok(decoded) = <DrawCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperActionsCalls::Draw(decoded));
            }
            if let Ok(decoded) = <FundCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperActionsCalls::Fund(decoded));
            }
            if let Ok(decoded) =
                <StakeCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperActionsCalls::Stake(decoded));
            }
            if let Ok(decoded) = <SwapCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperActionsCalls::Swap(decoded));
            }
            if let Ok(decoded) =
                <UnallocateCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperActionsCalls::Unallocate(decoded));
            }
            if let Ok(decoded) =
                <UnstakeCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(IHyperActionsCalls::Unstake(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for IHyperActionsCalls {
        fn encode(self) -> Vec<u8> {
            match self {
                IHyperActionsCalls::Allocate(element) => element.encode(),
                IHyperActionsCalls::ChangeParameters(element) => element.encode(),
                IHyperActionsCalls::Deposit(element) => element.encode(),
                IHyperActionsCalls::Draw(element) => element.encode(),
                IHyperActionsCalls::Fund(element) => element.encode(),
                IHyperActionsCalls::Stake(element) => element.encode(),
                IHyperActionsCalls::Swap(element) => element.encode(),
                IHyperActionsCalls::Unallocate(element) => element.encode(),
                IHyperActionsCalls::Unstake(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for IHyperActionsCalls {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                IHyperActionsCalls::Allocate(element) => element.fmt(f),
                IHyperActionsCalls::ChangeParameters(element) => element.fmt(f),
                IHyperActionsCalls::Deposit(element) => element.fmt(f),
                IHyperActionsCalls::Draw(element) => element.fmt(f),
                IHyperActionsCalls::Fund(element) => element.fmt(f),
                IHyperActionsCalls::Stake(element) => element.fmt(f),
                IHyperActionsCalls::Swap(element) => element.fmt(f),
                IHyperActionsCalls::Unallocate(element) => element.fmt(f),
                IHyperActionsCalls::Unstake(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<AllocateCall> for IHyperActionsCalls {
        fn from(var: AllocateCall) -> Self {
            IHyperActionsCalls::Allocate(var)
        }
    }
    impl ::std::convert::From<ChangeParametersCall> for IHyperActionsCalls {
        fn from(var: ChangeParametersCall) -> Self {
            IHyperActionsCalls::ChangeParameters(var)
        }
    }
    impl ::std::convert::From<DepositCall> for IHyperActionsCalls {
        fn from(var: DepositCall) -> Self {
            IHyperActionsCalls::Deposit(var)
        }
    }
    impl ::std::convert::From<DrawCall> for IHyperActionsCalls {
        fn from(var: DrawCall) -> Self {
            IHyperActionsCalls::Draw(var)
        }
    }
    impl ::std::convert::From<FundCall> for IHyperActionsCalls {
        fn from(var: FundCall) -> Self {
            IHyperActionsCalls::Fund(var)
        }
    }
    impl ::std::convert::From<StakeCall> for IHyperActionsCalls {
        fn from(var: StakeCall) -> Self {
            IHyperActionsCalls::Stake(var)
        }
    }
    impl ::std::convert::From<SwapCall> for IHyperActionsCalls {
        fn from(var: SwapCall) -> Self {
            IHyperActionsCalls::Swap(var)
        }
    }
    impl ::std::convert::From<UnallocateCall> for IHyperActionsCalls {
        fn from(var: UnallocateCall) -> Self {
            IHyperActionsCalls::Unallocate(var)
        }
    }
    impl ::std::convert::From<UnstakeCall> for IHyperActionsCalls {
        fn from(var: UnstakeCall) -> Self {
            IHyperActionsCalls::Unstake(var)
        }
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
