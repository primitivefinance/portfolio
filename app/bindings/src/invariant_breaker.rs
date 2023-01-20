pub use invariant_breaker::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod invariant_breaker {
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
    ///InvariantBreaker was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
    use std::sync::Arc;
    #[rustfmt::skip]
    const __ABI: &str = "[{\"inputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_address\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint256[]\",\"name\":\"val\",\"type\":\"uint256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"int256[]\",\"name\":\"val\",\"type\":\"int256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address[]\",\"name\":\"val\",\"type\":\"address[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"\",\"type\":\"bytes\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_bytes\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_bytes32\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"int256\",\"name\":\"\",\"type\":\"int256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_int\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"address\",\"name\":\"val\",\"type\":\"address\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_address\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256[]\",\"name\":\"val\",\"type\":\"uint256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"int256[]\",\"name\":\"val\",\"type\":\"int256[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"address[]\",\"name\":\"val\",\"type\":\"address[]\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_array\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"bytes\",\"name\":\"val\",\"type\":\"bytes\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_bytes\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"bytes32\",\"name\":\"val\",\"type\":\"bytes32\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_bytes32\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"int256\",\"name\":\"val\",\"type\":\"int256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"decimals\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_decimal_int\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"val\",\"type\":\"uint256\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"decimals\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_decimal_uint\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"int256\",\"name\":\"val\",\"type\":\"int256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_int\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"string\",\"name\":\"val\",\"type\":\"string\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_string\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"key\",\"type\":\"string\",\"components\":[],\"indexed\":false},{\"internalType\":\"uint256\",\"name\":\"val\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_named_uint\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_string\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"log_uint\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"bytes\",\"name\":\"\",\"type\":\"bytes\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"logs\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"IS_TEST\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"failed\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"flag0\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"flag1\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"int256\",\"name\":\"val\",\"type\":\"int256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"set0\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"int256\",\"name\":\"val\",\"type\":\"int256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"set1\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]}]";
    /// The parsed JSON-ABI of the contract.
    pub static INVARIANTBREAKER_ABI: ::ethers::contract::Lazy<::ethers::core::abi::Abi> =
        ::ethers::contract::Lazy::new(|| {
            ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi")
        });
    /// Bytecode of the #name contract
    pub static INVARIANTBREAKER_BYTECODE: ::ethers::contract::Lazy<::ethers::core::types::Bytes> =
        ::ethers::contract::Lazy::new(|| {
            "0x60806040526000805460ff191660011790556013805461010161ffff1990911617905534801561002e57600080fd5b5061036d8061003e6000396000f3fe608060405234801561001057600080fd5b50600436106100625760003560e01c806349ed73941461006757806363297fdb1461008d578063ba414fa61461009a578063d90babde146100a2578063e48f28d2146100b5578063fa7626d4146100c8575b600080fd5b60135461007990610100900460ff1681565b604051901515815260200160405180910390f35b6013546100799060ff1681565b6100796100d5565b6100796100b0366004610268565b610200565b6100796100c3366004610268565b61022a565b6000546100799060ff1681565b60008054610100900460ff16156100f55750600054610100900460ff1690565b6000737109709ecfa91a80626ff3989d68f67f5b1dd12d3b156101fb5760408051737109709ecfa91a80626ff3989d68f67f5b1dd12d602082018190526519985a5b195960d21b82840152825180830384018152606083019093526000929091610183917f667f9d70ca411d70ead50d8d5c22070dafc36ad75f3dcf5e7237b22ade9aecc4916080016102bc565b60408051601f198184030181529082905261019d916102e0565b6000604051808303816000865af19150503d80600081146101da576040519150601f19603f3d011682016040523d82523d6000602084013e6101df565b606091505b50915050808060200190518101906101f791906102f3565b9150505b919050565b600061020d606483610315565b60000361021f576013805460ff191690555b505060135460ff1690565b6000610237600a83610315565b158015610247575060135460ff16155b15610258576013805461ff00191690555b5050601354610100900460ff1690565b60006020828403121561027a57600080fd5b5035919050565b6000815160005b818110156102a25760208185018101518683015201610288565b818111156102b1576000828601525b509290920192915050565b6001600160e01b03198316815260006102d86004830184610281565b949350505050565b60006102ec8284610281565b9392505050565b60006020828403121561030557600080fd5b815180151581146102ec57600080fd5b60008261033257634e487b7160e01b600052601260045260246000fd5b50079056fea2646970667358221220351b75a922dfcc400642901240953319ddfc34c46bd1dbaeadb2fb6eacb33d7e64736f6c634300080d0033"
            .parse()
            .expect("invalid bytecode")
        });
    pub struct InvariantBreaker<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for InvariantBreaker<M> {
        fn clone(&self) -> Self {
            InvariantBreaker(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for InvariantBreaker<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for InvariantBreaker<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(InvariantBreaker))
                .field(&self.address())
                .finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> InvariantBreaker<M> {
        /// Creates a new contract instance with the specified `ethers`
        /// client at the given `Address`. The contract derefs to a `ethers::Contract`
        /// object
        pub fn new<T: Into<::ethers::core::types::Address>>(
            address: T,
            client: ::std::sync::Arc<M>,
        ) -> Self {
            Self(::ethers::contract::Contract::new(
                address.into(),
                INVARIANTBREAKER_ABI.clone(),
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
                INVARIANTBREAKER_ABI.clone(),
                INVARIANTBREAKER_BYTECODE.clone().into(),
                client,
            );
            let deployer = factory.deploy(constructor_args)?;
            let deployer = ::ethers::contract::ContractDeployer::new(deployer);
            Ok(deployer)
        }
        ///Calls the contract's `IS_TEST` (0xfa7626d4) function
        pub fn is_test(&self) -> ::ethers::contract::builders::ContractCall<M, bool> {
            self.0
                .method_hash([250, 118, 38, 212], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `failed` (0xba414fa6) function
        pub fn failed(&self) -> ::ethers::contract::builders::ContractCall<M, bool> {
            self.0
                .method_hash([186, 65, 79, 166], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `flag0` (0x63297fdb) function
        pub fn flag_0(&self) -> ::ethers::contract::builders::ContractCall<M, bool> {
            self.0
                .method_hash([99, 41, 127, 219], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `flag1` (0x49ed7394) function
        pub fn flag_1(&self) -> ::ethers::contract::builders::ContractCall<M, bool> {
            self.0
                .method_hash([73, 237, 115, 148], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `set0` (0xd90babde) function
        pub fn set_0(
            &self,
            val: ::ethers::core::types::I256,
        ) -> ::ethers::contract::builders::ContractCall<M, bool> {
            self.0
                .method_hash([217, 11, 171, 222], val)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `set1` (0xe48f28d2) function
        pub fn set_1(
            &self,
            val: ::ethers::core::types::I256,
        ) -> ::ethers::contract::builders::ContractCall<M, bool> {
            self.0
                .method_hash([228, 143, 40, 210], val)
                .expect("method not found (this should never happen)")
        }
        ///Gets the contract's `log` event
        pub fn log_filter(&self) -> ::ethers::contract::builders::Event<M, LogFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_address` event
        pub fn log_address_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogAddressFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_array` event
        pub fn log_array_1_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogArray1Filter> {
            self.0.event()
        }
        ///Gets the contract's `log_array` event
        pub fn log_array_2_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogArray2Filter> {
            self.0.event()
        }
        ///Gets the contract's `log_array` event
        pub fn log_array_3_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogArray3Filter> {
            self.0.event()
        }
        ///Gets the contract's `log_bytes` event
        pub fn log_bytes_filter(&self) -> ::ethers::contract::builders::Event<M, LogBytesFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_bytes32` event
        pub fn log_bytes_32_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogBytes32Filter> {
            self.0.event()
        }
        ///Gets the contract's `log_int` event
        pub fn log_int_filter(&self) -> ::ethers::contract::builders::Event<M, LogIntFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_named_address` event
        pub fn log_named_address_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogNamedAddressFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_named_array` event
        pub fn log_named_array_1_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogNamedArray1Filter> {
            self.0.event()
        }
        ///Gets the contract's `log_named_array` event
        pub fn log_named_array_2_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogNamedArray2Filter> {
            self.0.event()
        }
        ///Gets the contract's `log_named_array` event
        pub fn log_named_array_3_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogNamedArray3Filter> {
            self.0.event()
        }
        ///Gets the contract's `log_named_bytes` event
        pub fn log_named_bytes_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogNamedBytesFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_named_bytes32` event
        pub fn log_named_bytes_32_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogNamedBytes32Filter> {
            self.0.event()
        }
        ///Gets the contract's `log_named_decimal_int` event
        pub fn log_named_decimal_int_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogNamedDecimalIntFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_named_decimal_uint` event
        pub fn log_named_decimal_uint_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogNamedDecimalUintFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_named_int` event
        pub fn log_named_int_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogNamedIntFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_named_string` event
        pub fn log_named_string_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogNamedStringFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_named_uint` event
        pub fn log_named_uint_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, LogNamedUintFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_string` event
        pub fn log_string_filter(&self) -> ::ethers::contract::builders::Event<M, LogStringFilter> {
            self.0.event()
        }
        ///Gets the contract's `log_uint` event
        pub fn log_uint_filter(&self) -> ::ethers::contract::builders::Event<M, LogUintFilter> {
            self.0.event()
        }
        ///Gets the contract's `logs` event
        pub fn logs_filter(&self) -> ::ethers::contract::builders::Event<M, LogsFilter> {
            self.0.event()
        }
        /// Returns an [`Event`](#ethers_contract::builders::Event) builder for all events of this contract
        pub fn events(&self) -> ::ethers::contract::builders::Event<M, InvariantBreakerEvents> {
            self.0.event_with_filter(Default::default())
        }
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>>
        for InvariantBreaker<M>
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
    #[ethevent(name = "log", abi = "log(string)")]
    pub struct LogFilter(pub String);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "log_address", abi = "log_address(address)")]
    pub struct LogAddressFilter(pub ::ethers::core::types::Address);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "log_array", abi = "log_array(uint256[])")]
    pub struct LogArray1Filter {
        pub val: Vec<::ethers::core::types::U256>,
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
    #[ethevent(name = "log_array", abi = "log_array(int256[])")]
    pub struct LogArray2Filter {
        pub val: Vec<::ethers::core::types::I256>,
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
    #[ethevent(name = "log_array", abi = "log_array(address[])")]
    pub struct LogArray3Filter {
        pub val: Vec<::ethers::core::types::Address>,
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
    #[ethevent(name = "log_bytes", abi = "log_bytes(bytes)")]
    pub struct LogBytesFilter(pub ::ethers::core::types::Bytes);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "log_bytes32", abi = "log_bytes32(bytes32)")]
    pub struct LogBytes32Filter(pub [u8; 32]);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "log_int", abi = "log_int(int256)")]
    pub struct LogIntFilter(pub ::ethers::core::types::I256);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "log_named_address", abi = "log_named_address(string,address)")]
    pub struct LogNamedAddressFilter {
        pub key: String,
        pub val: ::ethers::core::types::Address,
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
    #[ethevent(name = "log_named_array", abi = "log_named_array(string,uint256[])")]
    pub struct LogNamedArray1Filter {
        pub key: String,
        pub val: Vec<::ethers::core::types::U256>,
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
    #[ethevent(name = "log_named_array", abi = "log_named_array(string,int256[])")]
    pub struct LogNamedArray2Filter {
        pub key: String,
        pub val: Vec<::ethers::core::types::I256>,
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
    #[ethevent(name = "log_named_array", abi = "log_named_array(string,address[])")]
    pub struct LogNamedArray3Filter {
        pub key: String,
        pub val: Vec<::ethers::core::types::Address>,
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
    #[ethevent(name = "log_named_bytes", abi = "log_named_bytes(string,bytes)")]
    pub struct LogNamedBytesFilter {
        pub key: String,
        pub val: ::ethers::core::types::Bytes,
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
    #[ethevent(name = "log_named_bytes32", abi = "log_named_bytes32(string,bytes32)")]
    pub struct LogNamedBytes32Filter {
        pub key: String,
        pub val: [u8; 32],
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
    #[ethevent(
        name = "log_named_decimal_int",
        abi = "log_named_decimal_int(string,int256,uint256)"
    )]
    pub struct LogNamedDecimalIntFilter {
        pub key: String,
        pub val: ::ethers::core::types::I256,
        pub decimals: ::ethers::core::types::U256,
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
    #[ethevent(
        name = "log_named_decimal_uint",
        abi = "log_named_decimal_uint(string,uint256,uint256)"
    )]
    pub struct LogNamedDecimalUintFilter {
        pub key: String,
        pub val: ::ethers::core::types::U256,
        pub decimals: ::ethers::core::types::U256,
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
    #[ethevent(name = "log_named_int", abi = "log_named_int(string,int256)")]
    pub struct LogNamedIntFilter {
        pub key: String,
        pub val: ::ethers::core::types::I256,
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
    #[ethevent(name = "log_named_string", abi = "log_named_string(string,string)")]
    pub struct LogNamedStringFilter {
        pub key: String,
        pub val: String,
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
    #[ethevent(name = "log_named_uint", abi = "log_named_uint(string,uint256)")]
    pub struct LogNamedUintFilter {
        pub key: String,
        pub val: ::ethers::core::types::U256,
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
    #[ethevent(name = "log_string", abi = "log_string(string)")]
    pub struct LogStringFilter(pub String);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "log_uint", abi = "log_uint(uint256)")]
    pub struct LogUintFilter(pub ::ethers::core::types::U256);
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthEvent,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethevent(name = "logs", abi = "logs(bytes)")]
    pub struct LogsFilter(pub ::ethers::core::types::Bytes);
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum InvariantBreakerEvents {
        LogFilter(LogFilter),
        LogAddressFilter(LogAddressFilter),
        LogArray1Filter(LogArray1Filter),
        LogArray2Filter(LogArray2Filter),
        LogArray3Filter(LogArray3Filter),
        LogBytesFilter(LogBytesFilter),
        LogBytes32Filter(LogBytes32Filter),
        LogIntFilter(LogIntFilter),
        LogNamedAddressFilter(LogNamedAddressFilter),
        LogNamedArray1Filter(LogNamedArray1Filter),
        LogNamedArray2Filter(LogNamedArray2Filter),
        LogNamedArray3Filter(LogNamedArray3Filter),
        LogNamedBytesFilter(LogNamedBytesFilter),
        LogNamedBytes32Filter(LogNamedBytes32Filter),
        LogNamedDecimalIntFilter(LogNamedDecimalIntFilter),
        LogNamedDecimalUintFilter(LogNamedDecimalUintFilter),
        LogNamedIntFilter(LogNamedIntFilter),
        LogNamedStringFilter(LogNamedStringFilter),
        LogNamedUintFilter(LogNamedUintFilter),
        LogStringFilter(LogStringFilter),
        LogUintFilter(LogUintFilter),
        LogsFilter(LogsFilter),
    }
    impl ::ethers::contract::EthLogDecode for InvariantBreakerEvents {
        fn decode_log(
            log: &::ethers::core::abi::RawLog,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::Error>
        where
            Self: Sized,
        {
            if let Ok(decoded) = LogFilter::decode_log(log) {
                return Ok(InvariantBreakerEvents::LogFilter(decoded));
            }
            if let Ok(decoded) = LogAddressFilter::decode_log(log) {
                return Ok(InvariantBreakerEvents::LogAddressFilter(decoded));
            }
            if let Ok(decoded) = LogArray1Filter::decode_log(log) {
                return Ok(InvariantBreakerEvents::LogArray1Filter(decoded));
            }
            if let Ok(decoded) = LogArray2Filter::decode_log(log) {
                return Ok(InvariantBreakerEvents::LogArray2Filter(decoded));
            }
            if let Ok(decoded) = LogArray3Filter::decode_log(log) {
                return Ok(InvariantBreakerEvents::LogArray3Filter(decoded));
            }
            if let Ok(decoded) = LogBytesFilter::decode_log(log) {
                return Ok(InvariantBreakerEvents::LogBytesFilter(decoded));
            }
            if let Ok(decoded) = LogBytes32Filter::decode_log(log) {
                return Ok(InvariantBreakerEvents::LogBytes32Filter(decoded));
            }
            if let Ok(decoded) = LogIntFilter::decode_log(log) {
                return Ok(InvariantBreakerEvents::LogIntFilter(decoded));
            }
            if let Ok(decoded) = LogNamedAddressFilter::decode_log(log) {
                return Ok(InvariantBreakerEvents::LogNamedAddressFilter(decoded));
            }
            if let Ok(decoded) = LogNamedArray1Filter::decode_log(log) {
                return Ok(InvariantBreakerEvents::LogNamedArray1Filter(decoded));
            }
            if let Ok(decoded) = LogNamedArray2Filter::decode_log(log) {
                return Ok(InvariantBreakerEvents::LogNamedArray2Filter(decoded));
            }
            if let Ok(decoded) = LogNamedArray3Filter::decode_log(log) {
                return Ok(InvariantBreakerEvents::LogNamedArray3Filter(decoded));
            }
            if let Ok(decoded) = LogNamedBytesFilter::decode_log(log) {
                return Ok(InvariantBreakerEvents::LogNamedBytesFilter(decoded));
            }
            if let Ok(decoded) = LogNamedBytes32Filter::decode_log(log) {
                return Ok(InvariantBreakerEvents::LogNamedBytes32Filter(decoded));
            }
            if let Ok(decoded) = LogNamedDecimalIntFilter::decode_log(log) {
                return Ok(InvariantBreakerEvents::LogNamedDecimalIntFilter(decoded));
            }
            if let Ok(decoded) = LogNamedDecimalUintFilter::decode_log(log) {
                return Ok(InvariantBreakerEvents::LogNamedDecimalUintFilter(decoded));
            }
            if let Ok(decoded) = LogNamedIntFilter::decode_log(log) {
                return Ok(InvariantBreakerEvents::LogNamedIntFilter(decoded));
            }
            if let Ok(decoded) = LogNamedStringFilter::decode_log(log) {
                return Ok(InvariantBreakerEvents::LogNamedStringFilter(decoded));
            }
            if let Ok(decoded) = LogNamedUintFilter::decode_log(log) {
                return Ok(InvariantBreakerEvents::LogNamedUintFilter(decoded));
            }
            if let Ok(decoded) = LogStringFilter::decode_log(log) {
                return Ok(InvariantBreakerEvents::LogStringFilter(decoded));
            }
            if let Ok(decoded) = LogUintFilter::decode_log(log) {
                return Ok(InvariantBreakerEvents::LogUintFilter(decoded));
            }
            if let Ok(decoded) = LogsFilter::decode_log(log) {
                return Ok(InvariantBreakerEvents::LogsFilter(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData)
        }
    }
    impl ::std::fmt::Display for InvariantBreakerEvents {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                InvariantBreakerEvents::LogFilter(element) => element.fmt(f),
                InvariantBreakerEvents::LogAddressFilter(element) => element.fmt(f),
                InvariantBreakerEvents::LogArray1Filter(element) => element.fmt(f),
                InvariantBreakerEvents::LogArray2Filter(element) => element.fmt(f),
                InvariantBreakerEvents::LogArray3Filter(element) => element.fmt(f),
                InvariantBreakerEvents::LogBytesFilter(element) => element.fmt(f),
                InvariantBreakerEvents::LogBytes32Filter(element) => element.fmt(f),
                InvariantBreakerEvents::LogIntFilter(element) => element.fmt(f),
                InvariantBreakerEvents::LogNamedAddressFilter(element) => element.fmt(f),
                InvariantBreakerEvents::LogNamedArray1Filter(element) => element.fmt(f),
                InvariantBreakerEvents::LogNamedArray2Filter(element) => element.fmt(f),
                InvariantBreakerEvents::LogNamedArray3Filter(element) => element.fmt(f),
                InvariantBreakerEvents::LogNamedBytesFilter(element) => element.fmt(f),
                InvariantBreakerEvents::LogNamedBytes32Filter(element) => element.fmt(f),
                InvariantBreakerEvents::LogNamedDecimalIntFilter(element) => element.fmt(f),
                InvariantBreakerEvents::LogNamedDecimalUintFilter(element) => element.fmt(f),
                InvariantBreakerEvents::LogNamedIntFilter(element) => element.fmt(f),
                InvariantBreakerEvents::LogNamedStringFilter(element) => element.fmt(f),
                InvariantBreakerEvents::LogNamedUintFilter(element) => element.fmt(f),
                InvariantBreakerEvents::LogStringFilter(element) => element.fmt(f),
                InvariantBreakerEvents::LogUintFilter(element) => element.fmt(f),
                InvariantBreakerEvents::LogsFilter(element) => element.fmt(f),
            }
        }
    }
    ///Container type for all input parameters for the `IS_TEST` function with signature `IS_TEST()` and selector `0xfa7626d4`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "IS_TEST", abi = "IS_TEST()")]
    pub struct IsTestCall;
    ///Container type for all input parameters for the `failed` function with signature `failed()` and selector `0xba414fa6`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "failed", abi = "failed()")]
    pub struct FailedCall;
    ///Container type for all input parameters for the `flag0` function with signature `flag0()` and selector `0x63297fdb`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "flag0", abi = "flag0()")]
    pub struct Flag0Call;
    ///Container type for all input parameters for the `flag1` function with signature `flag1()` and selector `0x49ed7394`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "flag1", abi = "flag1()")]
    pub struct Flag1Call;
    ///Container type for all input parameters for the `set0` function with signature `set0(int256)` and selector `0xd90babde`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "set0", abi = "set0(int256)")]
    pub struct Set0Call {
        pub val: ::ethers::core::types::I256,
    }
    ///Container type for all input parameters for the `set1` function with signature `set1(int256)` and selector `0xe48f28d2`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "set1", abi = "set1(int256)")]
    pub struct Set1Call {
        pub val: ::ethers::core::types::I256,
    }
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum InvariantBreakerCalls {
        IsTest(IsTestCall),
        Failed(FailedCall),
        Flag0(Flag0Call),
        Flag1(Flag1Call),
        Set0(Set0Call),
        Set1(Set1Call),
    }
    impl ::ethers::core::abi::AbiDecode for InvariantBreakerCalls {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded) =
                <IsTestCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantBreakerCalls::IsTest(decoded));
            }
            if let Ok(decoded) =
                <FailedCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantBreakerCalls::Failed(decoded));
            }
            if let Ok(decoded) =
                <Flag0Call as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantBreakerCalls::Flag0(decoded));
            }
            if let Ok(decoded) =
                <Flag1Call as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantBreakerCalls::Flag1(decoded));
            }
            if let Ok(decoded) = <Set0Call as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantBreakerCalls::Set0(decoded));
            }
            if let Ok(decoded) = <Set1Call as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(InvariantBreakerCalls::Set1(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for InvariantBreakerCalls {
        fn encode(self) -> Vec<u8> {
            match self {
                InvariantBreakerCalls::IsTest(element) => element.encode(),
                InvariantBreakerCalls::Failed(element) => element.encode(),
                InvariantBreakerCalls::Flag0(element) => element.encode(),
                InvariantBreakerCalls::Flag1(element) => element.encode(),
                InvariantBreakerCalls::Set0(element) => element.encode(),
                InvariantBreakerCalls::Set1(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for InvariantBreakerCalls {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                InvariantBreakerCalls::IsTest(element) => element.fmt(f),
                InvariantBreakerCalls::Failed(element) => element.fmt(f),
                InvariantBreakerCalls::Flag0(element) => element.fmt(f),
                InvariantBreakerCalls::Flag1(element) => element.fmt(f),
                InvariantBreakerCalls::Set0(element) => element.fmt(f),
                InvariantBreakerCalls::Set1(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<IsTestCall> for InvariantBreakerCalls {
        fn from(var: IsTestCall) -> Self {
            InvariantBreakerCalls::IsTest(var)
        }
    }
    impl ::std::convert::From<FailedCall> for InvariantBreakerCalls {
        fn from(var: FailedCall) -> Self {
            InvariantBreakerCalls::Failed(var)
        }
    }
    impl ::std::convert::From<Flag0Call> for InvariantBreakerCalls {
        fn from(var: Flag0Call) -> Self {
            InvariantBreakerCalls::Flag0(var)
        }
    }
    impl ::std::convert::From<Flag1Call> for InvariantBreakerCalls {
        fn from(var: Flag1Call) -> Self {
            InvariantBreakerCalls::Flag1(var)
        }
    }
    impl ::std::convert::From<Set0Call> for InvariantBreakerCalls {
        fn from(var: Set0Call) -> Self {
            InvariantBreakerCalls::Set0(var)
        }
    }
    impl ::std::convert::From<Set1Call> for InvariantBreakerCalls {
        fn from(var: Set1Call) -> Self {
            InvariantBreakerCalls::Set1(var)
        }
    }
    ///Container type for all return fields from the `IS_TEST` function with signature `IS_TEST()` and selector `0xfa7626d4`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct IsTestReturn(pub bool);
    ///Container type for all return fields from the `failed` function with signature `failed()` and selector `0xba414fa6`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct FailedReturn(pub bool);
    ///Container type for all return fields from the `flag0` function with signature `flag0()` and selector `0x63297fdb`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct Flag0Return(pub bool);
    ///Container type for all return fields from the `flag1` function with signature `flag1()` and selector `0x49ed7394`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct Flag1Return(pub bool);
    ///Container type for all return fields from the `set0` function with signature `set0(int256)` and selector `0xd90babde`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct Set0Return(pub bool);
    ///Container type for all return fields from the `set1` function with signature `set1(int256)` and selector `0xe48f28d2`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct Set1Return(pub bool);
}
