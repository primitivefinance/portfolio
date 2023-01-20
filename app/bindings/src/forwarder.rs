pub use forwarder::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod forwarder {
    #![allow(clippy::enum_variant_names)]
    #![allow(dead_code)]
    #![allow(clippy::type_complexity)]
    #![allow(unused_imports)]
    ///Forwarder was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
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
    #[rustfmt::skip]
    const __ABI: &str = "[{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"bytes\",\"name\":\"data\",\"type\":\"bytes\",\"components\":[]}],\"stateMutability\":\"payable\",\"type\":\"function\",\"name\":\"forward\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]}]";
    /// The parsed JSON-ABI of the contract.
    pub static FORWARDER_ABI: ::ethers::contract::Lazy<::ethers::core::abi::Abi> = ::ethers::contract::Lazy::new(||
    ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi"));
    /// Bytecode of the #name contract
    pub static FORWARDER_BYTECODE: ::ethers::contract::Lazy<
        ::ethers::core::types::Bytes,
    > = ::ethers::contract::Lazy::new(|| {
        "0x608060405234801561001057600080fd5b506101e2806100206000396000f3fe60806040526004361061001e5760003560e01c80636fadcf7214610023575b600080fd5b6100366100313660046100ec565b61004a565b604051901515815260200160405180910390f35b6000836001600160a01b031663e82b84b43485856040518463ffffffff1660e01b815260040161007b92919061017d565b6000604051808303818588803b15801561009457600080fd5b505af1935050505080156100a6575060015b6100e2573d8080156100d4576040519150601f19603f3d011682016040523d82523d6000602084013e6100d9565b606091505b50805181602001fd5b5060019392505050565b60008060006040848603121561010157600080fd5b83356001600160a01b038116811461011857600080fd5b9250602084013567ffffffffffffffff8082111561013557600080fd5b818601915086601f83011261014957600080fd5b81358181111561015857600080fd5b87602082850101111561016a57600080fd5b6020830194508093505050509250925092565b60208152816020820152818360408301376000818301604090810191909152601f909201601f1916010191905056fea26469706673582212208910f261d30970d772146975efc08ef063cc2dec11fde15631c6893f79ef156564736f6c634300080d0033"
            .parse()
            .expect("invalid bytecode")
    });
    pub struct Forwarder<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for Forwarder<M> {
        fn clone(&self) -> Self {
            Forwarder(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for Forwarder<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for Forwarder<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(Forwarder)).field(&self.address()).finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> Forwarder<M> {
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
                    FORWARDER_ABI.clone(),
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
                FORWARDER_ABI.clone(),
                FORWARDER_BYTECODE.clone().into(),
                client,
            );
            let deployer = factory.deploy(constructor_args)?;
            let deployer = ::ethers::contract::ContractDeployer::new(deployer);
            Ok(deployer)
        }
        ///Calls the contract's `forward` (0x6fadcf72) function
        pub fn forward(
            &self,
            hyper: ::ethers::core::types::Address,
            data: ::ethers::core::types::Bytes,
        ) -> ::ethers::contract::builders::ContractCall<M, bool> {
            self.0
                .method_hash([111, 173, 207, 114], (hyper, data))
                .expect("method not found (this should never happen)")
        }
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>>
    for Forwarder<M> {
        fn from(contract: ::ethers::contract::Contract<M>) -> Self {
            Self::new(contract.address(), contract.client())
        }
    }
    ///Container type for all input parameters for the `forward` function with signature `forward(address,bytes)` and selector `0x6fadcf72`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
    #[ethcall(name = "forward", abi = "forward(address,bytes)")]
    pub struct ForwardCall {
        pub hyper: ::ethers::core::types::Address,
        pub data: ::ethers::core::types::Bytes,
    }
    ///Container type for all return fields from the `forward` function with signature `forward(address,bytes)` and selector `0x6fadcf72`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct ForwardReturn(pub bool);
}
