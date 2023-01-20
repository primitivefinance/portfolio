pub use do_jump::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod do_jump {
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
    ///DoJump was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
    use std::sync::Arc;
    #[rustfmt::skip]
    const __ABI: &str = "[{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"data\",\"type\":\"bytes\",\"components\":[]}],\"stateMutability\":\"payable\",\"type\":\"function\",\"name\":\"doJumpProcess\",\"outputs\":[]}]";
    /// The parsed JSON-ABI of the contract.
    pub static DOJUMP_ABI: ::ethers::contract::Lazy<::ethers::core::abi::Abi> =
        ::ethers::contract::Lazy::new(|| {
            ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi")
        });
    pub struct DoJump<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for DoJump<M> {
        fn clone(&self) -> Self {
            DoJump(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for DoJump<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for DoJump<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(DoJump))
                .field(&self.address())
                .finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> DoJump<M> {
        /// Creates a new contract instance with the specified `ethers`
        /// client at the given `Address`. The contract derefs to a `ethers::Contract`
        /// object
        pub fn new<T: Into<::ethers::core::types::Address>>(
            address: T,
            client: ::std::sync::Arc<M>,
        ) -> Self {
            Self(::ethers::contract::Contract::new(
                address.into(),
                DOJUMP_ABI.clone(),
                client,
            ))
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
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>> for DoJump<M> {
        fn from(contract: ::ethers::contract::Contract<M>) -> Self {
            Self::new(contract.address(), contract.client())
        }
    }
    ///Container type for all input parameters for the `doJumpProcess` function with signature `doJumpProcess(bytes)` and selector `0xe82b84b4`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "doJumpProcess", abi = "doJumpProcess(bytes)")]
    pub struct DoJumpProcessCall {
        pub data: ::ethers::core::types::Bytes,
    }
}
