pub use hyper_forwarder_helper::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod hyper_forwarder_helper {
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
    ///HyperForwarderHelper was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
    use std::sync::Arc;
    #[rustfmt::skip]
    const __ABI: &str = "[{\"inputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"constructor\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"reason\",\"type\":\"bytes\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Fail\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[],\"type\":\"event\",\"name\":\"Success\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"target\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"approve\",\"outputs\":[]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"caller\",\"outputs\":[{\"internalType\":\"contract Caller\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint24\",\"name\":\"pairId\",\"type\":\"uint24\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"curveId\",\"type\":\"uint32\",\"components\":[]}],\"stateMutability\":\"pure\",\"type\":\"function\",\"name\":\"getPoolId\",\"outputs\":[{\"internalType\":\"uint64\",\"name\":\"\",\"type\":\"uint64\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"target\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"bytes\",\"name\":\"data\",\"type\":\"bytes\",\"components\":[]}],\"stateMutability\":\"payable\",\"type\":\"function\",\"name\":\"pass\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]}]";
    /// The parsed JSON-ABI of the contract.
    pub static HYPERFORWARDERHELPER_ABI: ::ethers::contract::Lazy<::ethers::core::abi::Abi> =
        ::ethers::contract::Lazy::new(|| {
            ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi")
        });
    /// Bytecode of the #name contract
    pub static HYPERFORWARDERHELPER_BYTECODE: ::ethers::contract::Lazy<
        ::ethers::core::types::Bytes,
    > = ::ethers::contract::Lazy::new(|| {
        "0x608060405234801561001057600080fd5b5060405161001d9061005f565b604051809103906000f080158015610039573d6000803e3d6000fd5b50600080546001600160a01b0319166001600160a01b039290921691909117905561006c565b61029c8061059a83390190565b61051f8061007b6000396000f3fe60806040526004361061003f5760003560e01c806353406cd61461004457806375d4a5181461006c5780637e5465ba146100a5578063fc9c8d39146100c7575b600080fd5b6100576100523660046102fb565b6100ff565b60405190151581526020015b60405180910390f35b34801561007857600080fd5b5061008c61008736600461037e565b610219565b60405167ffffffffffffffff9091168152602001610063565b3480156100b157600080fd5b506100c56100c03660046103c8565b61026c565b005b3480156100d357600080fd5b506000546100e7906001600160a01b031681565b6040516001600160a01b039091168152602001610063565b600080546040516337d6e7b960e11b81526001600160a01b0390911690636fadcf72903490610136908890889088906004016103fb565b60206040518083038185885af193505050508015610171575060408051601f3d908101601f1916820190925261016e9181019061043b565b60015b6101e4573d80801561019f576040519150601f19603f3d011682016040523d82523d6000602084013e6101a4565b606091505b507f1b5b6f35459c46ae0ff032bd8b43f506c6a27daef08099ccf510d82f6e8f8013816040516101d4919061045d565b60405180910390a1805181602001fd5b506040517f395a9ab3d1230297d931e1fa224ca597ca0e45f620c1aeb74b512bfcc6f66aab90600090a15060015b9392505050565b6040516001600160e81b031960e884901b1660208201526001600160e01b031960e083901b166023820152600090602701604051602081830303815290604052610262906104b2565b60c01c9392505050565b60005460405163e1f21c6760e01b81526001600160a01b038481166004830152838116602483015260001960448301529091169063e1f21c6790606401600060405180830381600087803b1580156102c357600080fd5b505af11580156102d7573d6000803e3d6000fd5b505050505050565b80356001600160a01b03811681146102f657600080fd5b919050565b60008060006040848603121561031057600080fd5b610319846102df565b9250602084013567ffffffffffffffff8082111561033657600080fd5b818601915086601f83011261034a57600080fd5b81358181111561035957600080fd5b87602082850101111561036b57600080fd5b6020830194508093505050509250925092565b6000806040838503121561039157600080fd5b823562ffffff811681146103a457600080fd5b9150602083013563ffffffff811681146103bd57600080fd5b809150509250929050565b600080604083850312156103db57600080fd5b6103e4836102df565b91506103f2602084016102df565b90509250929050565b6001600160a01b03841681526040602082018190528101829052818360608301376000818301606090810191909152601f909201601f1916010192915050565b60006020828403121561044d57600080fd5b8151801515811461021257600080fd5b600060208083528351808285015260005b8181101561048a5785810183015185820160400152820161046e565b8181111561049c576000604083870101525b50601f01601f1916929092016040019392505050565b805160208201516001600160c01b031980821692919060088310156104e15780818460080360031b1b83161693505b50505091905056fea26469706673582212202fac8ff5a35885f2787273be0850a3fbb9c1f7cc413d888fcd4ddd292edbf3c864736f6c634300080d0033608060405234801561001057600080fd5b5061027c806100206000396000f3fe6080604052600436106100295760003560e01c80636fadcf721461002e578063e1f21c6714610055575b600080fd5b61004161003c366004610177565b610077565b604051901515815260200160405180910390f35b34801561006157600080fd5b506100756100703660046101fa565b6100f4565b005b6000806000856001600160a01b0316348686604051610097929190610236565b60006040518083038185875af1925050503d80600081146100d4576040519150601f19603f3d011682016040523d82523d6000602084013e6100d9565b606091505b5091509150816100eb57805181602001fd5b50949350505050565b60405163095ea7b360e01b81526001600160a01b0383811660048301526024820183905284169063095ea7b390604401600060405180830381600087803b15801561013e57600080fd5b505af1158015610152573d6000803e3d6000fd5b50505050505050565b80356001600160a01b038116811461017257600080fd5b919050565b60008060006040848603121561018c57600080fd5b6101958461015b565b9250602084013567ffffffffffffffff808211156101b257600080fd5b818601915086601f8301126101c657600080fd5b8135818111156101d557600080fd5b8760208285010111156101e757600080fd5b6020830194508093505050509250925092565b60008060006060848603121561020f57600080fd5b6102188461015b565b92506102266020850161015b565b9150604084013590509250925092565b818382376000910190815291905056fea26469706673582212201bcc6c47ad79600927cff86cf4f9e5e07e76872ac8cb355c4e5ed5f11cc9e97864736f6c634300080d0033"
            .parse()
            .expect("invalid bytecode")
    });
    pub struct HyperForwarderHelper<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for HyperForwarderHelper<M> {
        fn clone(&self) -> Self {
            HyperForwarderHelper(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for HyperForwarderHelper<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for HyperForwarderHelper<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(HyperForwarderHelper))
                .field(&self.address())
                .finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> HyperForwarderHelper<M> {
        /// Creates a new contract instance with the specified `ethers`
        /// client at the given `Address`. The contract derefs to a `ethers::Contract`
        /// object
        pub fn new<T: Into<::ethers::core::types::Address>>(
            address: T,
            client: ::std::sync::Arc<M>,
        ) -> Self {
            Self(::ethers::contract::Contract::new(
                address.into(),
                HYPERFORWARDERHELPER_ABI.clone(),
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
                HYPERFORWARDERHELPER_ABI.clone(),
                HYPERFORWARDERHELPER_BYTECODE.clone().into(),
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
            target: ::ethers::core::types::Address,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([126, 84, 101, 186], (token, target))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `caller` (0xfc9c8d39) function
        pub fn caller(
            &self,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::Address> {
            self.0
                .method_hash([252, 156, 141, 57], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getPoolId` (0x75d4a518) function
        pub fn get_pool_id(
            &self,
            pair_id: u32,
            curve_id: u32,
        ) -> ::ethers::contract::builders::ContractCall<M, u64> {
            self.0
                .method_hash([117, 212, 165, 24], (pair_id, curve_id))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `pass` (0x53406cd6) function
        pub fn pass(
            &self,
            target: ::ethers::core::types::Address,
            data: ::ethers::core::types::Bytes,
        ) -> ::ethers::contract::builders::ContractCall<M, bool> {
            self.0
                .method_hash([83, 64, 108, 214], (target, data))
                .expect("method not found (this should never happen)")
        }
        ///Gets the contract's `Fail` event
        pub fn fail_filter(&self) -> ::ethers::contract::builders::Event<M, FailFilter> {
            self.0.event()
        }
        ///Gets the contract's `Success` event
        pub fn success_filter(&self) -> ::ethers::contract::builders::Event<M, SuccessFilter> {
            self.0.event()
        }
        /// Returns an [`Event`](#ethers_contract::builders::Event) builder for all events of this contract
        pub fn events(&self) -> ::ethers::contract::builders::Event<M, HyperForwarderHelperEvents> {
            self.0.event_with_filter(Default::default())
        }
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>>
        for HyperForwarderHelper<M>
    {
        fn from(contract: ::ethers::contract::Contract<M>) -> Self {
            Self::new(contract.address(), contract.client())
        }
    }
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "Fail", abi = "Fail(bytes)")]
    pub struct FailFilter {
        pub reason: ::ethers::core::types::Bytes,
    }
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "Success", abi = "Success()")]
    pub struct SuccessFilter();
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum HyperForwarderHelperEvents {
        FailFilter(FailFilter),
        SuccessFilter(SuccessFilter),
    }
    impl ::ethers::contract::EthLogDecode for HyperForwarderHelperEvents {
        fn decode_log(
            log: &::ethers::core::abi::RawLog,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::Error>
        where
            Self: Sized,
        {
            if let Ok(decoded) = FailFilter::decode_log(log) {
                return Ok(HyperForwarderHelperEvents::FailFilter(decoded));
            }
            if let Ok(decoded) = SuccessFilter::decode_log(log) {
                return Ok(HyperForwarderHelperEvents::SuccessFilter(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData)
        }
    }
    impl ::std::fmt::Display for HyperForwarderHelperEvents {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                HyperForwarderHelperEvents::FailFilter(element) => element.fmt(f),
                HyperForwarderHelperEvents::SuccessFilter(element) => element.fmt(f),
            }
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
        Default,
    )]
    #[ethcall(name = "approve", abi = "approve(address,address)")]
    pub struct ApproveCall {
        pub token: ::ethers::core::types::Address,
        pub target: ::ethers::core::types::Address,
    }
    ///Container type for all input parameters for the `caller` function with signature `caller()` and selector `0xfc9c8d39`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "caller", abi = "caller()")]
    pub struct CallerCall;
    ///Container type for all input parameters for the `getPoolId` function with signature `getPoolId(uint24,uint32)` and selector `0x75d4a518`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getPoolId", abi = "getPoolId(uint24,uint32)")]
    pub struct GetPoolIdCall {
        pub pair_id: u32,
        pub curve_id: u32,
    }
    ///Container type for all input parameters for the `pass` function with signature `pass(address,bytes)` and selector `0x53406cd6`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "pass", abi = "pass(address,bytes)")]
    pub struct PassCall {
        pub target: ::ethers::core::types::Address,
        pub data: ::ethers::core::types::Bytes,
    }
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum HyperForwarderHelperCalls {
        Approve(ApproveCall),
        Caller(CallerCall),
        GetPoolId(GetPoolIdCall),
        Pass(PassCall),
    }
    impl ::ethers::core::abi::AbiDecode for HyperForwarderHelperCalls {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded) =
                <ApproveCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperForwarderHelperCalls::Approve(decoded));
            }
            if let Ok(decoded) =
                <CallerCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperForwarderHelperCalls::Caller(decoded));
            }
            if let Ok(decoded) =
                <GetPoolIdCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperForwarderHelperCalls::GetPoolId(decoded));
            }
            if let Ok(decoded) = <PassCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HyperForwarderHelperCalls::Pass(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for HyperForwarderHelperCalls {
        fn encode(self) -> Vec<u8> {
            match self {
                HyperForwarderHelperCalls::Approve(element) => element.encode(),
                HyperForwarderHelperCalls::Caller(element) => element.encode(),
                HyperForwarderHelperCalls::GetPoolId(element) => element.encode(),
                HyperForwarderHelperCalls::Pass(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for HyperForwarderHelperCalls {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                HyperForwarderHelperCalls::Approve(element) => element.fmt(f),
                HyperForwarderHelperCalls::Caller(element) => element.fmt(f),
                HyperForwarderHelperCalls::GetPoolId(element) => element.fmt(f),
                HyperForwarderHelperCalls::Pass(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<ApproveCall> for HyperForwarderHelperCalls {
        fn from(var: ApproveCall) -> Self {
            HyperForwarderHelperCalls::Approve(var)
        }
    }
    impl ::std::convert::From<CallerCall> for HyperForwarderHelperCalls {
        fn from(var: CallerCall) -> Self {
            HyperForwarderHelperCalls::Caller(var)
        }
    }
    impl ::std::convert::From<GetPoolIdCall> for HyperForwarderHelperCalls {
        fn from(var: GetPoolIdCall) -> Self {
            HyperForwarderHelperCalls::GetPoolId(var)
        }
    }
    impl ::std::convert::From<PassCall> for HyperForwarderHelperCalls {
        fn from(var: PassCall) -> Self {
            HyperForwarderHelperCalls::Pass(var)
        }
    }
    ///Container type for all return fields from the `caller` function with signature `caller()` and selector `0xfc9c8d39`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct CallerReturn(pub ::ethers::core::types::Address);
    ///Container type for all return fields from the `getPoolId` function with signature `getPoolId(uint24,uint32)` and selector `0x75d4a518`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetPoolIdReturn(pub u64);
    ///Container type for all return fields from the `pass` function with signature `pass(address,bytes)` and selector `0x53406cd6`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct PassReturn(pub bool);
}
