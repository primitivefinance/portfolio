pub use gaussian::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod gaussian {
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
    ///Gaussian was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
    use std::sync::Arc;
    #[rustfmt::skip]
    const __ABI: &str = "[{\"inputs\":[],\"type\":\"error\",\"name\":\"Infinity\",\"outputs\":[]},{\"inputs\":[],\"type\":\"error\",\"name\":\"NegativeInfinity\",\"outputs\":[]}]";
    /// The parsed JSON-ABI of the contract.
    pub static GAUSSIAN_ABI: ::ethers::contract::Lazy<::ethers::core::abi::Abi> =
        ::ethers::contract::Lazy::new(|| {
            ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi")
        });
    /// Bytecode of the #name contract
    pub static GAUSSIAN_BYTECODE: ::ethers::contract::Lazy<::ethers::core::types::Bytes> =
        ::ethers::contract::Lazy::new(|| {
            "0x60566037600b82828239805160001a607314602a57634e487b7160e01b600052600060045260246000fd5b30600052607381538281f3fe73000000000000000000000000000000000000000030146080604052600080fdfea26469706673582212205164a6b5fa2ba81d80c6d9909772dd42a9fca9b209a6656422dce90d44ee051c64736f6c634300080d0033"
            .parse()
            .expect("invalid bytecode")
        });
    pub struct Gaussian<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for Gaussian<M> {
        fn clone(&self) -> Self {
            Gaussian(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for Gaussian<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for Gaussian<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(Gaussian))
                .field(&self.address())
                .finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> Gaussian<M> {
        /// Creates a new contract instance with the specified `ethers`
        /// client at the given `Address`. The contract derefs to a `ethers::Contract`
        /// object
        pub fn new<T: Into<::ethers::core::types::Address>>(
            address: T,
            client: ::std::sync::Arc<M>,
        ) -> Self {
            Self(::ethers::contract::Contract::new(
                address.into(),
                GAUSSIAN_ABI.clone(),
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
                GAUSSIAN_ABI.clone(),
                GAUSSIAN_BYTECODE.clone().into(),
                client,
            );
            let deployer = factory.deploy(constructor_args)?;
            let deployer = ::ethers::contract::ContractDeployer::new(deployer);
            Ok(deployer)
        }
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>> for Gaussian<M> {
        fn from(contract: ::ethers::contract::Contract<M>) -> Self {
            Self::new(contract.address(), contract.client())
        }
    }
    ///Custom Error type `Infinity` with signature `Infinity()` and selector `0x07a02127`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "Infinity", abi = "Infinity()")]
    pub struct Infinity;
    ///Custom Error type `NegativeInfinity` with signature `NegativeInfinity()` and selector `0x8bb56614`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "NegativeInfinity", abi = "NegativeInfinity()")]
    pub struct NegativeInfinity;
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum GaussianErrors {
        Infinity(Infinity),
        NegativeInfinity(NegativeInfinity),
    }
    impl ::ethers::core::abi::AbiDecode for GaussianErrors {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded) = <Infinity as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(GaussianErrors::Infinity(decoded));
            }
            if let Ok(decoded) =
                <NegativeInfinity as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(GaussianErrors::NegativeInfinity(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for GaussianErrors {
        fn encode(self) -> Vec<u8> {
            match self {
                GaussianErrors::Infinity(element) => element.encode(),
                GaussianErrors::NegativeInfinity(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for GaussianErrors {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                GaussianErrors::Infinity(element) => element.fmt(f),
                GaussianErrors::NegativeInfinity(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<Infinity> for GaussianErrors {
        fn from(var: Infinity) -> Self {
            GaussianErrors::Infinity(var)
        }
    }
    impl ::std::convert::From<NegativeInfinity> for GaussianErrors {
        fn from(var: NegativeInfinity) -> Self {
            GaussianErrors::NegativeInfinity(var)
        }
    }
}
