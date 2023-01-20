pub use caller::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod caller {
    #![allow(clippy::enum_variant_names)]
    #![allow(dead_code)]
    #![allow(clippy::type_complexity)]
    #![allow(unused_imports)]
    ///Caller was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
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
    const __ABI: &str = "[{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"to\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"approve\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"target\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"bytes\",\"name\":\"data\",\"type\":\"bytes\",\"components\":[]}],\"stateMutability\":\"payable\",\"type\":\"function\",\"name\":\"forward\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]}]";
    /// The parsed JSON-ABI of the contract.
    pub static CALLER_ABI: ::ethers::contract::Lazy<::ethers::core::abi::Abi> = ::ethers::contract::Lazy::new(||
    ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi"));
    /// Bytecode of the #name contract
    pub static CALLER_BYTECODE: ::ethers::contract::Lazy<::ethers::core::types::Bytes> = ::ethers::contract::Lazy::new(||
    {
        "0x608060405234801561001057600080fd5b5061027c806100206000396000f3fe6080604052600436106100295760003560e01c80636fadcf721461002e578063e1f21c6714610055575b600080fd5b61004161003c366004610177565b610077565b604051901515815260200160405180910390f35b34801561006157600080fd5b506100756100703660046101fa565b6100f4565b005b6000806000856001600160a01b0316348686604051610097929190610236565b60006040518083038185875af1925050503d80600081146100d4576040519150601f19603f3d011682016040523d82523d6000602084013e6100d9565b606091505b5091509150816100eb57805181602001fd5b50949350505050565b60405163095ea7b360e01b81526001600160a01b0383811660048301526024820183905284169063095ea7b390604401600060405180830381600087803b15801561013e57600080fd5b505af1158015610152573d6000803e3d6000fd5b50505050505050565b80356001600160a01b038116811461017257600080fd5b919050565b60008060006040848603121561018c57600080fd5b6101958461015b565b9250602084013567ffffffffffffffff808211156101b257600080fd5b818601915086601f8301126101c657600080fd5b8135818111156101d557600080fd5b8760208285010111156101e757600080fd5b6020830194508093505050509250925092565b60008060006060848603121561020f57600080fd5b6102188461015b565b92506102266020850161015b565b9150604084013590509250925092565b818382376000910190815291905056fea26469706673582212201bcc6c47ad79600927cff86cf4f9e5e07e76872ac8cb355c4e5ed5f11cc9e97864736f6c634300080d0033"
            .parse()
            .expect("invalid bytecode")
    });
    pub struct Caller<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for Caller<M> {
        fn clone(&self) -> Self {
            Caller(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for Caller<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for Caller<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(Caller)).field(&self.address()).finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> Caller<M> {
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
                    CALLER_ABI.clone(),
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
                CALLER_ABI.clone(),
                CALLER_BYTECODE.clone().into(),
                client,
            );
            let deployer = factory.deploy(constructor_args)?;
            let deployer = ::ethers::contract::ContractDeployer::new(deployer);
            Ok(deployer)
        }
        ///Calls the contract's `approve` (0xe1f21c67) function
        pub fn approve(
            &self,
            token: ::ethers::core::types::Address,
            to: ::ethers::core::types::Address,
            amount: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([225, 242, 28, 103], (token, to, amount))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `forward` (0x6fadcf72) function
        pub fn forward(
            &self,
            target: ::ethers::core::types::Address,
            data: ::ethers::core::types::Bytes,
        ) -> ::ethers::contract::builders::ContractCall<M, bool> {
            self.0
                .method_hash([111, 173, 207, 114], (target, data))
                .expect("method not found (this should never happen)")
        }
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>>
    for Caller<M> {
        fn from(contract: ::ethers::contract::Contract<M>) -> Self {
            Self::new(contract.address(), contract.client())
        }
    }
    ///Container type for all input parameters for the `approve` function with signature `approve(address,address,uint256)` and selector `0xe1f21c67`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
    #[ethcall(name = "approve", abi = "approve(address,address,uint256)")]
    pub struct ApproveCall {
        pub token: ::ethers::core::types::Address,
        pub to: ::ethers::core::types::Address,
        pub amount: ::ethers::core::types::U256,
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
        pub target: ::ethers::core::types::Address,
        pub data: ::ethers::core::types::Bytes,
    }
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum CallerCalls {
        Approve(ApproveCall),
        Forward(ForwardCall),
    }
    impl ::ethers::core::abi::AbiDecode for CallerCalls {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded)
                = <ApproveCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(CallerCalls::Approve(decoded));
            }
            if let Ok(decoded)
                = <ForwardCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(CallerCalls::Forward(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for CallerCalls {
        fn encode(self) -> Vec<u8> {
            match self {
                CallerCalls::Approve(element) => element.encode(),
                CallerCalls::Forward(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for CallerCalls {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                CallerCalls::Approve(element) => element.fmt(f),
                CallerCalls::Forward(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<ApproveCall> for CallerCalls {
        fn from(var: ApproveCall) -> Self {
            CallerCalls::Approve(var)
        }
    }
    impl ::std::convert::From<ForwardCall> for CallerCalls {
        fn from(var: ForwardCall) -> Self {
            CallerCalls::Forward(var)
        }
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
