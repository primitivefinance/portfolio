pub use revert_catcher::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod revert_catcher {
    #![allow(clippy::enum_variant_names)]
    #![allow(dead_code)]
    #![allow(clippy::type_complexity)]
    #![allow(unused_imports)]
    ///RevertCatcher was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
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
    const __ABI: &str = "[{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper_\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"constructor\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"spender\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"approve\",\"outputs\":[]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"hyper\",\"outputs\":[{\"internalType\":\"contract HyperCatchReverts\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"data\",\"type\":\"bytes\",\"components\":[]}],\"stateMutability\":\"payable\",\"type\":\"function\",\"name\":\"jumpProcess\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"data\",\"type\":\"bytes\",\"components\":[]}],\"stateMutability\":\"payable\",\"type\":\"function\",\"name\":\"mockFallback\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"data\",\"type\":\"bytes\",\"components\":[]}],\"stateMutability\":\"payable\",\"type\":\"function\",\"name\":\"process\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"payable\",\"type\":\"receive\",\"outputs\":[]}]";
    /// The parsed JSON-ABI of the contract.
    pub static REVERTCATCHER_ABI: ::ethers::contract::Lazy<::ethers::core::abi::Abi> = ::ethers::contract::Lazy::new(||
    ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi"));
    /// Bytecode of the #name contract
    pub static REVERTCATCHER_BYTECODE: ::ethers::contract::Lazy<
        ::ethers::core::types::Bytes,
    > = ::ethers::contract::Lazy::new(|| {
        "0x608060405234801561001057600080fd5b5060405161046c38038061046c83398101604081905261002f91610054565b600080546001600160a01b0319166001600160a01b0392909216919091179055610084565b60006020828403121561006657600080fd5b81516001600160a01b038116811461007d57600080fd5b9392505050565b6103d9806100936000396000f3fe60806040526004361061004e5760003560e01c80637e5465ba1461005a57806380aa20191461007c578063928bc4b2146100a4578063b3b528a2146100b7578063cd5a62be146100ca57600080fd5b3661005557005b600080fd5b34801561006657600080fd5b5061007a6100753660046102a6565b610102565b005b61008f61008a3660046102d9565b61017b565b60405190151581526020015b60405180910390f35b61008f6100b23660046102d9565b610220565b61008f6100c53660046102d9565b610255565b3480156100d657600080fd5b506000546100ea906001600160a01b031681565b6040516001600160a01b03909116815260200161009b565b60405163095ea7b360e01b81526001600160a01b038281166004830152600019602483015283169063095ea7b3906044016020604051808303816000875af1158015610152573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610176919061034b565b505050565b600080546040516380aa201960e01b81526001600160a01b03909116906380aa20199034906101b09087908790600401610374565b6000604051808303818588803b1580156101c957600080fd5b505af1935050505080156101db575060015b610217573d808015610209576040519150601f19603f3d011682016040523d82523d6000602084013e61020e565b606091505b50805181602001fd5b50600192915050565b60008054604051634945e25960e11b81526001600160a01b039091169063928bc4b29034906101b09087908790600401610374565b600080546040516359da945160e11b81526001600160a01b039091169063b3b528a29034906101b09087908790600401610374565b80356001600160a01b03811681146102a157600080fd5b919050565b600080604083850312156102b957600080fd5b6102c28361028a565b91506102d06020840161028a565b90509250929050565b600080602083850312156102ec57600080fd5b823567ffffffffffffffff8082111561030457600080fd5b818501915085601f83011261031857600080fd5b81358181111561032757600080fd5b86602082850101111561033957600080fd5b60209290920196919550909350505050565b60006020828403121561035d57600080fd5b8151801515811461036d57600080fd5b9392505050565b60208152816020820152818360408301376000818301604090810191909152601f909201601f1916010191905056fea26469706673582212203ab42871b75f9a9ce0d4d786c6be231ef4401cd5a2cb0137f332876c93bfeeab64736f6c634300080d0033"
            .parse()
            .expect("invalid bytecode")
    });
    pub struct RevertCatcher<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for RevertCatcher<M> {
        fn clone(&self) -> Self {
            RevertCatcher(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for RevertCatcher<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for RevertCatcher<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(RevertCatcher)).field(&self.address()).finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> RevertCatcher<M> {
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
                    REVERTCATCHER_ABI.clone(),
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
                REVERTCATCHER_ABI.clone(),
                REVERTCATCHER_BYTECODE.clone().into(),
                client,
            );
            let deployer = factory.deploy(constructor_args)?;
            let deployer = ::ethers::contract::ContractDeployer::new(deployer);
            Ok(deployer)
        }
        ///Calls the contract's `approve` (0x7e5465ba) function
        pub fn approve(
            &self,
            token: ::ethers::core::types::Address,
            spender: ::ethers::core::types::Address,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([126, 84, 101, 186], (token, spender))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `hyper` (0xcd5a62be) function
        pub fn hyper(
            &self,
        ) -> ::ethers::contract::builders::ContractCall<
            M,
            ::ethers::core::types::Address,
        > {
            self.0
                .method_hash([205, 90, 98, 190], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `jumpProcess` (0x80aa2019) function
        pub fn jump_process(
            &self,
            data: ::ethers::core::types::Bytes,
        ) -> ::ethers::contract::builders::ContractCall<M, bool> {
            self.0
                .method_hash([128, 170, 32, 25], data)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `mockFallback` (0xb3b528a2) function
        pub fn mock_fallback(
            &self,
            data: ::ethers::core::types::Bytes,
        ) -> ::ethers::contract::builders::ContractCall<M, bool> {
            self.0
                .method_hash([179, 181, 40, 162], data)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `process` (0x928bc4b2) function
        pub fn process(
            &self,
            data: ::ethers::core::types::Bytes,
        ) -> ::ethers::contract::builders::ContractCall<M, bool> {
            self.0
                .method_hash([146, 139, 196, 178], data)
                .expect("method not found (this should never happen)")
        }
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>>
    for RevertCatcher<M> {
        fn from(contract: ::ethers::contract::Contract<M>) -> Self {
            Self::new(contract.address(), contract.client())
        }
    }
    ///Container type for all input parameters for the `approve` function with signature `approve(address,address)` and selector `0x7e5465ba`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
    #[ethcall(name = "approve", abi = "approve(address,address)")]
    pub struct ApproveCall {
        pub token: ::ethers::core::types::Address,
        pub spender: ::ethers::core::types::Address,
    }
    ///Container type for all input parameters for the `hyper` function with signature `hyper()` and selector `0xcd5a62be`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
    #[ethcall(name = "hyper", abi = "hyper()")]
    pub struct HyperCall;
    ///Container type for all input parameters for the `jumpProcess` function with signature `jumpProcess(bytes)` and selector `0x80aa2019`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
    #[ethcall(name = "jumpProcess", abi = "jumpProcess(bytes)")]
    pub struct JumpProcessCall {
        pub data: ::ethers::core::types::Bytes,
    }
    ///Container type for all input parameters for the `mockFallback` function with signature `mockFallback(bytes)` and selector `0xb3b528a2`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
    #[ethcall(name = "mockFallback", abi = "mockFallback(bytes)")]
    pub struct MockFallbackCall {
        pub data: ::ethers::core::types::Bytes,
    }
    ///Container type for all input parameters for the `process` function with signature `process(bytes)` and selector `0x928bc4b2`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
    )]
    #[derive(Default)]
    #[ethcall(name = "process", abi = "process(bytes)")]
    pub struct ProcessCall {
        pub data: ::ethers::core::types::Bytes,
    }
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum RevertCatcherCalls {
        Approve(ApproveCall),
        Hyper(HyperCall),
        JumpProcess(JumpProcessCall),
        MockFallback(MockFallbackCall),
        Process(ProcessCall),
    }
    impl ::ethers::core::abi::AbiDecode for RevertCatcherCalls {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded)
                = <ApproveCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(RevertCatcherCalls::Approve(decoded));
            }
            if let Ok(decoded)
                = <HyperCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref()) {
                return Ok(RevertCatcherCalls::Hyper(decoded));
            }
            if let Ok(decoded)
                = <JumpProcessCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(RevertCatcherCalls::JumpProcess(decoded));
            }
            if let Ok(decoded)
                = <MockFallbackCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(RevertCatcherCalls::MockFallback(decoded));
            }
            if let Ok(decoded)
                = <ProcessCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                ) {
                return Ok(RevertCatcherCalls::Process(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for RevertCatcherCalls {
        fn encode(self) -> Vec<u8> {
            match self {
                RevertCatcherCalls::Approve(element) => element.encode(),
                RevertCatcherCalls::Hyper(element) => element.encode(),
                RevertCatcherCalls::JumpProcess(element) => element.encode(),
                RevertCatcherCalls::MockFallback(element) => element.encode(),
                RevertCatcherCalls::Process(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for RevertCatcherCalls {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                RevertCatcherCalls::Approve(element) => element.fmt(f),
                RevertCatcherCalls::Hyper(element) => element.fmt(f),
                RevertCatcherCalls::JumpProcess(element) => element.fmt(f),
                RevertCatcherCalls::MockFallback(element) => element.fmt(f),
                RevertCatcherCalls::Process(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<ApproveCall> for RevertCatcherCalls {
        fn from(var: ApproveCall) -> Self {
            RevertCatcherCalls::Approve(var)
        }
    }
    impl ::std::convert::From<HyperCall> for RevertCatcherCalls {
        fn from(var: HyperCall) -> Self {
            RevertCatcherCalls::Hyper(var)
        }
    }
    impl ::std::convert::From<JumpProcessCall> for RevertCatcherCalls {
        fn from(var: JumpProcessCall) -> Self {
            RevertCatcherCalls::JumpProcess(var)
        }
    }
    impl ::std::convert::From<MockFallbackCall> for RevertCatcherCalls {
        fn from(var: MockFallbackCall) -> Self {
            RevertCatcherCalls::MockFallback(var)
        }
    }
    impl ::std::convert::From<ProcessCall> for RevertCatcherCalls {
        fn from(var: ProcessCall) -> Self {
            RevertCatcherCalls::Process(var)
        }
    }
    ///Container type for all return fields from the `hyper` function with signature `hyper()` and selector `0xcd5a62be`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct HyperReturn(pub ::ethers::core::types::Address);
    ///Container type for all return fields from the `jumpProcess` function with signature `jumpProcess(bytes)` and selector `0x80aa2019`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct JumpProcessReturn(pub bool);
    ///Container type for all return fields from the `mockFallback` function with signature `mockFallback(bytes)` and selector `0xb3b528a2`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct MockFallbackReturn(pub bool);
    ///Container type for all return fields from the `process` function with signature `process(bytes)` and selector `0x928bc4b2`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
    )]
    #[derive(Default)]
    pub struct ProcessReturn(pub bool);
}
