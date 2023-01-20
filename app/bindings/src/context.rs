pub use context::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod context {
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
    ///Context was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
    use std::sync::Arc;
    #[rustfmt::skip]
    const __ABI: &str = "[{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__asset__\",\"outputs\":[{\"internalType\":\"contract TestERC20\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__quote__\",\"outputs\":[{\"internalType\":\"contract TestERC20\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__weth__\",\"outputs\":[{\"internalType\":\"contract TestERC20\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"addPoolId\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"time\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"customWarp\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"id\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getRandomPoolId\",\"outputs\":[{\"internalType\":\"uint64\",\"name\":\"\",\"type\":\"uint64\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"id\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getRandomUser\",\"outputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"setPoolId\",\"outputs\":[]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"users\",\"outputs\":[{\"internalType\":\"address[]\",\"name\":\"\",\"type\":\"address[]\",\"components\":[]}]}]";
    /// The parsed JSON-ABI of the contract.
    pub static CONTEXT_ABI: ::ethers::contract::Lazy<::ethers::core::abi::Abi> =
        ::ethers::contract::Lazy::new(|| {
            ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi")
        });
    pub struct Context<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for Context<M> {
        fn clone(&self) -> Self {
            Context(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for Context<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for Context<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(Context))
                .field(&self.address())
                .finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> Context<M> {
        /// Creates a new contract instance with the specified `ethers`
        /// client at the given `Address`. The contract derefs to a `ethers::Contract`
        /// object
        pub fn new<T: Into<::ethers::core::types::Address>>(
            address: T,
            client: ::std::sync::Arc<M>,
        ) -> Self {
            Self(::ethers::contract::Contract::new(
                address.into(),
                CONTEXT_ABI.clone(),
                client,
            ))
        }
        ///Calls the contract's `__asset__` (0xd43c0f99) function
        pub fn asset(
            &self,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::Address> {
            self.0
                .method_hash([212, 60, 15, 153], ())
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
        ///Calls the contract's `__weth__` (0x28dd8e53) function
        pub fn weth(
            &self,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::Address> {
            self.0
                .method_hash([40, 221, 142, 83], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `addPoolId` (0xce5b07c3) function
        pub fn add_pool_id(
            &self,
            pool_id: u64,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([206, 91, 7, 195], pool_id)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `customWarp` (0x71f76aac) function
        pub fn custom_warp(
            &self,
            time: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([113, 247, 106, 172], time)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getRandomPoolId` (0x1741369f) function
        pub fn get_random_pool_id(
            &self,
            id: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<M, u64> {
            self.0
                .method_hash([23, 65, 54, 159], id)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getRandomUser` (0x6b67b55c) function
        pub fn get_random_user(
            &self,
            id: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::Address> {
            self.0
                .method_hash([107, 103, 181, 92], id)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `setPoolId` (0xa209ff06) function
        pub fn set_pool_id(
            &self,
            pool_id: u64,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([162, 9, 255, 6], pool_id)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `users` (0xf2020275) function
        pub fn users(
            &self,
        ) -> ::ethers::contract::builders::ContractCall<
            M,
            ::std::vec::Vec<::ethers::core::types::Address>,
        > {
            self.0
                .method_hash([242, 2, 2, 117], ())
                .expect("method not found (this should never happen)")
        }
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>> for Context<M> {
        fn from(contract: ::ethers::contract::Contract<M>) -> Self {
            Self::new(contract.address(), contract.client())
        }
    }
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
    ///Container type for all input parameters for the `__weth__` function with signature `__weth__()` and selector `0x28dd8e53`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "__weth__", abi = "__weth__()")]
    pub struct WethCall;
    ///Container type for all input parameters for the `addPoolId` function with signature `addPoolId(uint64)` and selector `0xce5b07c3`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "addPoolId", abi = "addPoolId(uint64)")]
    pub struct AddPoolIdCall {
        pub pool_id: u64,
    }
    ///Container type for all input parameters for the `customWarp` function with signature `customWarp(uint256)` and selector `0x71f76aac`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "customWarp", abi = "customWarp(uint256)")]
    pub struct CustomWarpCall {
        pub time: ::ethers::core::types::U256,
    }
    ///Container type for all input parameters for the `getRandomPoolId` function with signature `getRandomPoolId(uint256)` and selector `0x1741369f`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getRandomPoolId", abi = "getRandomPoolId(uint256)")]
    pub struct GetRandomPoolIdCall {
        pub id: ::ethers::core::types::U256,
    }
    ///Container type for all input parameters for the `getRandomUser` function with signature `getRandomUser(uint256)` and selector `0x6b67b55c`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getRandomUser", abi = "getRandomUser(uint256)")]
    pub struct GetRandomUserCall {
        pub id: ::ethers::core::types::U256,
    }
    ///Container type for all input parameters for the `setPoolId` function with signature `setPoolId(uint64)` and selector `0xa209ff06`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "setPoolId", abi = "setPoolId(uint64)")]
    pub struct SetPoolIdCall {
        pub pool_id: u64,
    }
    ///Container type for all input parameters for the `users` function with signature `users()` and selector `0xf2020275`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "users", abi = "users()")]
    pub struct UsersCall;
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum ContextCalls {
        Asset(AssetCall),
        Quote(QuoteCall),
        Weth(WethCall),
        AddPoolId(AddPoolIdCall),
        CustomWarp(CustomWarpCall),
        GetRandomPoolId(GetRandomPoolIdCall),
        GetRandomUser(GetRandomUserCall),
        SetPoolId(SetPoolIdCall),
        Users(UsersCall),
    }
    impl ::ethers::core::abi::AbiDecode for ContextCalls {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded) =
                <AssetCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(ContextCalls::Asset(decoded));
            }
            if let Ok(decoded) =
                <QuoteCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(ContextCalls::Quote(decoded));
            }
            if let Ok(decoded) = <WethCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(ContextCalls::Weth(decoded));
            }
            if let Ok(decoded) =
                <AddPoolIdCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(ContextCalls::AddPoolId(decoded));
            }
            if let Ok(decoded) =
                <CustomWarpCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(ContextCalls::CustomWarp(decoded));
            }
            if let Ok(decoded) =
                <GetRandomPoolIdCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(ContextCalls::GetRandomPoolId(decoded));
            }
            if let Ok(decoded) =
                <GetRandomUserCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(ContextCalls::GetRandomUser(decoded));
            }
            if let Ok(decoded) =
                <SetPoolIdCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(ContextCalls::SetPoolId(decoded));
            }
            if let Ok(decoded) =
                <UsersCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(ContextCalls::Users(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for ContextCalls {
        fn encode(self) -> Vec<u8> {
            match self {
                ContextCalls::Asset(element) => element.encode(),
                ContextCalls::Quote(element) => element.encode(),
                ContextCalls::Weth(element) => element.encode(),
                ContextCalls::AddPoolId(element) => element.encode(),
                ContextCalls::CustomWarp(element) => element.encode(),
                ContextCalls::GetRandomPoolId(element) => element.encode(),
                ContextCalls::GetRandomUser(element) => element.encode(),
                ContextCalls::SetPoolId(element) => element.encode(),
                ContextCalls::Users(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for ContextCalls {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                ContextCalls::Asset(element) => element.fmt(f),
                ContextCalls::Quote(element) => element.fmt(f),
                ContextCalls::Weth(element) => element.fmt(f),
                ContextCalls::AddPoolId(element) => element.fmt(f),
                ContextCalls::CustomWarp(element) => element.fmt(f),
                ContextCalls::GetRandomPoolId(element) => element.fmt(f),
                ContextCalls::GetRandomUser(element) => element.fmt(f),
                ContextCalls::SetPoolId(element) => element.fmt(f),
                ContextCalls::Users(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<AssetCall> for ContextCalls {
        fn from(var: AssetCall) -> Self {
            ContextCalls::Asset(var)
        }
    }
    impl ::std::convert::From<QuoteCall> for ContextCalls {
        fn from(var: QuoteCall) -> Self {
            ContextCalls::Quote(var)
        }
    }
    impl ::std::convert::From<WethCall> for ContextCalls {
        fn from(var: WethCall) -> Self {
            ContextCalls::Weth(var)
        }
    }
    impl ::std::convert::From<AddPoolIdCall> for ContextCalls {
        fn from(var: AddPoolIdCall) -> Self {
            ContextCalls::AddPoolId(var)
        }
    }
    impl ::std::convert::From<CustomWarpCall> for ContextCalls {
        fn from(var: CustomWarpCall) -> Self {
            ContextCalls::CustomWarp(var)
        }
    }
    impl ::std::convert::From<GetRandomPoolIdCall> for ContextCalls {
        fn from(var: GetRandomPoolIdCall) -> Self {
            ContextCalls::GetRandomPoolId(var)
        }
    }
    impl ::std::convert::From<GetRandomUserCall> for ContextCalls {
        fn from(var: GetRandomUserCall) -> Self {
            ContextCalls::GetRandomUser(var)
        }
    }
    impl ::std::convert::From<SetPoolIdCall> for ContextCalls {
        fn from(var: SetPoolIdCall) -> Self {
            ContextCalls::SetPoolId(var)
        }
    }
    impl ::std::convert::From<UsersCall> for ContextCalls {
        fn from(var: UsersCall) -> Self {
            ContextCalls::Users(var)
        }
    }
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
    ///Container type for all return fields from the `__weth__` function with signature `__weth__()` and selector `0x28dd8e53`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct WethReturn(pub ::ethers::core::types::Address);
    ///Container type for all return fields from the `getRandomPoolId` function with signature `getRandomPoolId(uint256)` and selector `0x1741369f`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetRandomPoolIdReturn(pub u64);
    ///Container type for all return fields from the `getRandomUser` function with signature `getRandomUser(uint256)` and selector `0x6b67b55c`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetRandomUserReturn(pub ::ethers::core::types::Address);
    ///Container type for all return fields from the `users` function with signature `users()` and selector `0xf2020275`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct UsersReturn(pub ::std::vec::Vec<::ethers::core::types::Address>);
}
