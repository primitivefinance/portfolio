pub use helper_hyper_invariants::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod helper_hyper_invariants {
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
    ///HelperHyperInvariants was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
    use std::sync::Arc;
    #[rustfmt::skip]
    const __ABI: &str = "[{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}],\"type\":\"error\",\"name\":\"SettlementInvariantInvalid\",\"outputs\":[]}]";
    /// The parsed JSON-ABI of the contract.
    pub static HELPERHYPERINVARIANTS_ABI: ::ethers::contract::Lazy<::ethers::core::abi::Abi> =
        ::ethers::contract::Lazy::new(|| {
            ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi")
        });
    /// Bytecode of the #name contract
    pub static HELPERHYPERINVARIANTS_BYTECODE: ::ethers::contract::Lazy<
        ::ethers::core::types::Bytes,
    > = ::ethers::contract::Lazy::new(|| {
        "0x6080604052348015600f57600080fd5b50603f80601d6000396000f3fe6080604052600080fdfea26469706673582212200c3a0327f770cc3710756f61ceeb93b8620469223affe98d84c2c91d19e83aae64736f6c634300080d0033"
            .parse()
            .expect("invalid bytecode")
    });
    pub struct HelperHyperInvariants<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for HelperHyperInvariants<M> {
        fn clone(&self) -> Self {
            HelperHyperInvariants(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for HelperHyperInvariants<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for HelperHyperInvariants<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(HelperHyperInvariants))
                .field(&self.address())
                .finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> HelperHyperInvariants<M> {
        /// Creates a new contract instance with the specified `ethers`
        /// client at the given `Address`. The contract derefs to a `ethers::Contract`
        /// object
        pub fn new<T: Into<::ethers::core::types::Address>>(
            address: T,
            client: ::std::sync::Arc<M>,
        ) -> Self {
            Self(::ethers::contract::Contract::new(
                address.into(),
                HELPERHYPERINVARIANTS_ABI.clone(),
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
                HELPERHYPERINVARIANTS_ABI.clone(),
                HELPERHYPERINVARIANTS_BYTECODE.clone().into(),
                client,
            );
            let deployer = factory.deploy(constructor_args)?;
            let deployer = ::ethers::contract::ContractDeployer::new(deployer);
            Ok(deployer)
        }
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>>
        for HelperHyperInvariants<M>
    {
        fn from(contract: ::ethers::contract::Contract<M>) -> Self {
            Self::new(contract.address(), contract.client())
        }
    }
    ///Custom Error type `SettlementInvariantInvalid` with signature `SettlementInvariantInvalid(uint256,uint256)` and selector `0xb8719dce`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(
        name = "SettlementInvariantInvalid",
        abi = "SettlementInvariantInvalid(uint256,uint256)"
    )]
    pub struct SettlementInvariantInvalid(
        pub ::ethers::core::types::U256,
        pub ::ethers::core::types::U256,
    );
}
