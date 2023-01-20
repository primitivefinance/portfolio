pub use addresses::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod addresses {
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
    ///Addresses was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
    use std::sync::Arc;
    #[rustfmt::skip]
    const __ABI: &str = "[{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__hyper__\",\"outputs\":[{\"internalType\":\"contract HyperTimeOverride\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__token_18__\",\"outputs\":[{\"internalType\":\"contract TestERC20\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__usdc__\",\"outputs\":[{\"internalType\":\"contract TestERC20\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__user__\",\"outputs\":[{\"internalType\":\"contract User\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"__weth__\",\"outputs\":[{\"internalType\":\"contract WETH\",\"name\":\"\",\"type\":\"address\",\"components\":[]}]}]";
    /// The parsed JSON-ABI of the contract.
    pub static ADDRESSES_ABI: ::ethers::contract::Lazy<::ethers::core::abi::Abi> =
        ::ethers::contract::Lazy::new(|| {
            ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi")
        });
    /// Bytecode of the #name contract
    pub static ADDRESSES_BYTECODE: ::ethers::contract::Lazy<::ethers::core::types::Bytes> =
        ::ethers::contract::Lazy::new(|| {
            "0x608060405234801561001057600080fd5b50610101806100206000396000f3fe6080604052348015600f57600080fd5b506004361060505760003560e01c806328dd8e531460555780633e81296e14608357806342770c5e1460955780637d96b0381460a7578063bae63bb91460b9575b600080fd5b6001546067906001600160a01b031681565b6040516001600160a01b03909116815260200160405180910390f35b6002546067906001600160a01b031681565b6000546067906001600160a01b031681565b6003546067906001600160a01b031681565b6004546067906001600160a01b03168156fea264697066735822122067a6e10cff6f25a743cb01d444f299daf5a690dd8fb2812165352647d4068fb764736f6c634300080d0033"
            .parse()
            .expect("invalid bytecode")
        });
    pub struct Addresses<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for Addresses<M> {
        fn clone(&self) -> Self {
            Addresses(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for Addresses<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for Addresses<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(Addresses))
                .field(&self.address())
                .finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> Addresses<M> {
        /// Creates a new contract instance with the specified `ethers`
        /// client at the given `Address`. The contract derefs to a `ethers::Contract`
        /// object
        pub fn new<T: Into<::ethers::core::types::Address>>(
            address: T,
            client: ::std::sync::Arc<M>,
        ) -> Self {
            Self(::ethers::contract::Contract::new(
                address.into(),
                ADDRESSES_ABI.clone(),
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
                ADDRESSES_ABI.clone(),
                ADDRESSES_BYTECODE.clone().into(),
                client,
            );
            let deployer = factory.deploy(constructor_args)?;
            let deployer = ::ethers::contract::ContractDeployer::new(deployer);
            Ok(deployer)
        }
        ///Calls the contract's `__hyper__` (0x3e81296e) function
        pub fn hyper(
            &self,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::Address> {
            self.0
                .method_hash([62, 129, 41, 110], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `__token_18__` (0xbae63bb9) function
        pub fn token_18(
            &self,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::Address> {
            self.0
                .method_hash([186, 230, 59, 185], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `__usdc__` (0x7d96b038) function
        pub fn usdc(
            &self,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::Address> {
            self.0
                .method_hash([125, 150, 176, 56], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `__user__` (0x42770c5e) function
        pub fn user(
            &self,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::Address> {
            self.0
                .method_hash([66, 119, 12, 94], ())
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
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>> for Addresses<M> {
        fn from(contract: ::ethers::contract::Contract<M>) -> Self {
            Self::new(contract.address(), contract.client())
        }
    }
    ///Container type for all input parameters for the `__hyper__` function with signature `__hyper__()` and selector `0x3e81296e`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "__hyper__", abi = "__hyper__()")]
    pub struct HyperCall;
    ///Container type for all input parameters for the `__token_18__` function with signature `__token_18__()` and selector `0xbae63bb9`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "__token_18__", abi = "__token_18__()")]
    pub struct Token18Call;
    ///Container type for all input parameters for the `__usdc__` function with signature `__usdc__()` and selector `0x7d96b038`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "__usdc__", abi = "__usdc__()")]
    pub struct UsdcCall;
    ///Container type for all input parameters for the `__user__` function with signature `__user__()` and selector `0x42770c5e`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "__user__", abi = "__user__()")]
    pub struct UserCall;
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
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum AddressesCalls {
        Hyper(HyperCall),
        Token18(Token18Call),
        Usdc(UsdcCall),
        User(UserCall),
        Weth(WethCall),
    }
    impl ::ethers::core::abi::AbiDecode for AddressesCalls {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded) =
                <HyperCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(AddressesCalls::Hyper(decoded));
            }
            if let Ok(decoded) =
                <Token18Call as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(AddressesCalls::Token18(decoded));
            }
            if let Ok(decoded) = <UsdcCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(AddressesCalls::Usdc(decoded));
            }
            if let Ok(decoded) = <UserCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(AddressesCalls::User(decoded));
            }
            if let Ok(decoded) = <WethCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(AddressesCalls::Weth(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for AddressesCalls {
        fn encode(self) -> Vec<u8> {
            match self {
                AddressesCalls::Hyper(element) => element.encode(),
                AddressesCalls::Token18(element) => element.encode(),
                AddressesCalls::Usdc(element) => element.encode(),
                AddressesCalls::User(element) => element.encode(),
                AddressesCalls::Weth(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for AddressesCalls {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                AddressesCalls::Hyper(element) => element.fmt(f),
                AddressesCalls::Token18(element) => element.fmt(f),
                AddressesCalls::Usdc(element) => element.fmt(f),
                AddressesCalls::User(element) => element.fmt(f),
                AddressesCalls::Weth(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<HyperCall> for AddressesCalls {
        fn from(var: HyperCall) -> Self {
            AddressesCalls::Hyper(var)
        }
    }
    impl ::std::convert::From<Token18Call> for AddressesCalls {
        fn from(var: Token18Call) -> Self {
            AddressesCalls::Token18(var)
        }
    }
    impl ::std::convert::From<UsdcCall> for AddressesCalls {
        fn from(var: UsdcCall) -> Self {
            AddressesCalls::Usdc(var)
        }
    }
    impl ::std::convert::From<UserCall> for AddressesCalls {
        fn from(var: UserCall) -> Self {
            AddressesCalls::User(var)
        }
    }
    impl ::std::convert::From<WethCall> for AddressesCalls {
        fn from(var: WethCall) -> Self {
            AddressesCalls::Weth(var)
        }
    }
    ///Container type for all return fields from the `__hyper__` function with signature `__hyper__()` and selector `0x3e81296e`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct HyperReturn(pub ::ethers::core::types::Address);
    ///Container type for all return fields from the `__token_18__` function with signature `__token_18__()` and selector `0xbae63bb9`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct Token18Return(pub ::ethers::core::types::Address);
    ///Container type for all return fields from the `__usdc__` function with signature `__usdc__()` and selector `0x7d96b038`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct UsdcReturn(pub ::ethers::core::types::Address);
    ///Container type for all return fields from the `__user__` function with signature `__user__()` and selector `0x42770c5e`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct UserReturn(pub ::ethers::core::types::Address);
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
}
