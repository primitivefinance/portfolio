pub use hyper_lib::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod hyper_lib {
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
    ///HyperLib was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
    use std::sync::Arc;
    #[rustfmt::skip]
    const __ABI: &str = "[]";
    /// The parsed JSON-ABI of the contract.
    pub static HYPERLIB_ABI: ::ethers::contract::Lazy<::ethers::core::abi::Abi> =
        ::ethers::contract::Lazy::new(|| {
            ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi")
        });
    pub struct HyperLib<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for HyperLib<M> {
        fn clone(&self) -> Self {
            HyperLib(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for HyperLib<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for HyperLib<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(HyperLib))
                .field(&self.address())
                .finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> HyperLib<M> {
        /// Creates a new contract instance with the specified `ethers`
        /// client at the given `Address`. The contract derefs to a `ethers::Contract`
        /// object
        pub fn new<T: Into<::ethers::core::types::Address>>(
            address: T,
            client: ::std::sync::Arc<M>,
        ) -> Self {
            Self(::ethers::contract::Contract::new(
                address.into(),
                HYPERLIB_ABI.clone(),
                client,
            ))
        }
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>> for HyperLib<M> {
        fn from(contract: ::ethers::contract::Contract<M>) -> Self {
            Self::new(contract.address(), contract.client())
        }
    }
}
