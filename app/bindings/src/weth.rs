pub use weth::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod weth {
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
    ///WETH was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
    use std::sync::Arc;
    #[rustfmt::skip]
    const __ABI: &str = "[{\"inputs\":[{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"spender\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Approval\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"from\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Deposit\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"from\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"address\",\"name\":\"to\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Transfer\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"to\",\"type\":\"address\",\"components\":[],\"indexed\":true},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[],\"indexed\":false}],\"type\":\"event\",\"name\":\"Withdrawal\",\"outputs\":[],\"anonymous\":false},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"DOMAIN_SEPARATOR\",\"outputs\":[{\"internalType\":\"bytes32\",\"name\":\"\",\"type\":\"bytes32\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"allowance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"spender\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"approve\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"balanceOf\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"decimals\",\"outputs\":[{\"internalType\":\"uint8\",\"name\":\"\",\"type\":\"uint8\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\",\"name\":\"deposit\",\"outputs\":[]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"name\",\"outputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"nonces\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"spender\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"value\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"deadline\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"v\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"bytes32\",\"name\":\"r\",\"type\":\"bytes32\",\"components\":[]},{\"internalType\":\"bytes32\",\"name\":\"s\",\"type\":\"bytes32\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"permit\",\"outputs\":[]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"symbol\",\"outputs\":[{\"internalType\":\"string\",\"name\":\"\",\"type\":\"string\",\"components\":[]}]},{\"inputs\":[],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"totalSupply\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"to\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"transfer\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"from\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"to\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"transferFrom\",\"outputs\":[{\"internalType\":\"bool\",\"name\":\"\",\"type\":\"bool\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\",\"components\":[]}],\"stateMutability\":\"nonpayable\",\"type\":\"function\",\"name\":\"withdraw\",\"outputs\":[]},{\"inputs\":[],\"stateMutability\":\"payable\",\"type\":\"receive\",\"outputs\":[]}]";
    /// The parsed JSON-ABI of the contract.
    pub static WETH_ABI: ::ethers::contract::Lazy<::ethers::core::abi::Abi> =
        ::ethers::contract::Lazy::new(|| {
            ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi")
        });
    /// Bytecode of the #name contract
    pub static WETH_BYTECODE: ::ethers::contract::Lazy<::ethers::core::types::Bytes> =
        ::ethers::contract::Lazy::new(|| {
            "0x60e06040523480156200001157600080fd5b50604080518082018252600d81526c2bb930b83832b21022ba3432b960991b6020808301918252835180850190945260048452630ae8aa8960e31b9084015281519192916012916200006791600091906200013c565b5081516200007d9060019060208501906200013c565b5060ff81166080524660a05262000093620000a0565b60c05250620002c1915050565b60007f8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f6000604051620000d491906200021e565b6040805191829003822060208301939093528101919091527fc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc660608201524660808201523060a082015260c00160405160208183030381529060405280519060200120905090565b8280546200014a90620001e2565b90600052602060002090601f0160209004810192826200016e5760008555620001b9565b82601f106200018957805160ff1916838001178555620001b9565b82800160010185558215620001b9579182015b82811115620001b95782518255916020019190600101906200019c565b50620001c7929150620001cb565b5090565b5b80821115620001c75760008155600101620001cc565b600181811c90821680620001f757607f821691505b6020821081036200021857634e487b7160e01b600052602260045260246000fd5b50919050565b600080835481600182811c9150808316806200023b57607f831692505b602080841082036200025b57634e487b7160e01b86526022600452602486fd5b8180156200027257600181146200028457620002b3565b60ff19861689528489019650620002b3565b60008a81526020902060005b86811015620002ab5781548b82015290850190830162000290565b505084890196505b509498975050505050505050565b60805160a05160c051610d50620002f1600039600061059e01526000610569015260006101c60152610d506000f3fe6080604052600436106100e15760003560e01c806370a082311161007f578063a9059cbb11610059578063a9059cbb1461027e578063d0e30db01461029e578063d505accf146102a6578063dd62ed3e146102c657600080fd5b806370a082311461020f5780637ecebe001461023c57806395d89b411461026957600080fd5b806323b872dd116100bb57806323b872dd146101745780632e1a7d4d14610194578063313ce567146101b45780633644e515146101fa57600080fd5b806306fdde03146100f5578063095ea7b31461012057806318160ddd1461015057600080fd5b366100f0576100ee6102fe565b005b600080fd5b34801561010157600080fd5b5061010a61033f565b6040516101179190610a28565b60405180910390f35b34801561012c57600080fd5b5061014061013b366004610a99565b6103cd565b6040519015158152602001610117565b34801561015c57600080fd5b5061016660025481565b604051908152602001610117565b34801561018057600080fd5b5061014061018f366004610ac3565b610439565b3480156101a057600080fd5b506100ee6101af366004610aff565b610519565b3480156101c057600080fd5b506101e87f000000000000000000000000000000000000000000000000000000000000000081565b60405160ff9091168152602001610117565b34801561020657600080fd5b50610166610565565b34801561021b57600080fd5b5061016661022a366004610b18565b60036020526000908152604090205481565b34801561024857600080fd5b50610166610257366004610b18565b60056020526000908152604090205481565b34801561027557600080fd5b5061010a6105c0565b34801561028a57600080fd5b50610140610299366004610a99565b6105cd565b6100ee6102fe565b3480156102b257600080fd5b506100ee6102c1366004610b3a565b610633565b3480156102d257600080fd5b506101666102e1366004610bad565b600460209081526000928352604080842090915290825290205481565b610308333461087c565b60405134815233907fe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c9060200160405180910390a2565b6000805461034c90610be0565b80601f016020809104026020016040519081016040528092919081815260200182805461037890610be0565b80156103c55780601f1061039a576101008083540402835291602001916103c5565b820191906000526020600020905b8154815290600101906020018083116103a857829003601f168201915b505050505081565b3360008181526004602090815260408083206001600160a01b038716808552925280832085905551919290917f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925906104289086815260200190565b60405180910390a350600192915050565b6001600160a01b03831660009081526004602090815260408083203384529091528120546000198114610495576104708382610c30565b6001600160a01b03861660009081526004602090815260408083203384529091529020555b6001600160a01b038516600090815260036020526040812080548592906104bd908490610c30565b90915550506001600160a01b0380851660008181526003602052604090819020805487019055519091871690600080516020610cfb833981519152906105069087815260200190565b60405180910390a3506001949350505050565b61052333826108d6565b60405181815233907f7fcf532c15f0a6db0bd6d0e038bea71d30d808c7d98cb3bf7268a95bf5081b659060200160405180910390a26105623382610938565b50565b60007f0000000000000000000000000000000000000000000000000000000000000000461461059b5761059661098e565b905090565b507f000000000000000000000000000000000000000000000000000000000000000090565b6001805461034c90610be0565b336000908152600360205260408120805483919083906105ee908490610c30565b90915550506001600160a01b03831660008181526003602052604090819020805485019055513390600080516020610cfb833981519152906104289086815260200190565b428410156106885760405162461bcd60e51b815260206004820152601760248201527f5045524d49545f444541444c494e455f4558504952454400000000000000000060448201526064015b60405180910390fd5b60006001610694610565565b6001600160a01b038a811660008181526005602090815260409182902080546001810190915582517f6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c98184015280840194909452938d166060840152608083018c905260a083019390935260c08083018b90528151808403909101815260e08301909152805192019190912061190160f01b6101008301526101028201929092526101228101919091526101420160408051601f198184030181528282528051602091820120600084529083018083525260ff871690820152606081018590526080810184905260a0016020604051602081039080840390855afa1580156107a0573d6000803e3d6000fd5b5050604051601f1901519150506001600160a01b038116158015906107d65750876001600160a01b0316816001600160a01b0316145b6108135760405162461bcd60e51b815260206004820152600e60248201526d24a72b20a624a22fa9a4a3a722a960911b604482015260640161067f565b6001600160a01b0390811660009081526004602090815260408083208a8516808552908352928190208990555188815291928a16917f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925910160405180910390a350505050505050565b806002600082825461088e9190610c47565b90915550506001600160a01b038216600081815260036020908152604080832080548601905551848152600080516020610cfb83398151915291015b60405180910390a35050565b6001600160a01b038216600090815260036020526040812080548392906108fe908490610c30565b90915550506002805482900390556040518181526000906001600160a01b03841690600080516020610cfb833981519152906020016108ca565b600080600080600085875af19050806109895760405162461bcd60e51b815260206004820152601360248201527211551217d514905394d1915497d19052531151606a1b604482015260640161067f565b505050565b60007f8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f60006040516109c09190610c5f565b6040805191829003822060208301939093528101919091527fc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc660608201524660808201523060a082015260c00160405160208183030381529060405280519060200120905090565b600060208083528351808285015260005b81811015610a5557858101830151858201604001528201610a39565b81811115610a67576000604083870101525b50601f01601f1916929092016040019392505050565b80356001600160a01b0381168114610a9457600080fd5b919050565b60008060408385031215610aac57600080fd5b610ab583610a7d565b946020939093013593505050565b600080600060608486031215610ad857600080fd5b610ae184610a7d565b9250610aef60208501610a7d565b9150604084013590509250925092565b600060208284031215610b1157600080fd5b5035919050565b600060208284031215610b2a57600080fd5b610b3382610a7d565b9392505050565b600080600080600080600060e0888a031215610b5557600080fd5b610b5e88610a7d565b9650610b6c60208901610a7d565b95506040880135945060608801359350608088013560ff81168114610b9057600080fd5b9699959850939692959460a0840135945060c09093013592915050565b60008060408385031215610bc057600080fd5b610bc983610a7d565b9150610bd760208401610a7d565b90509250929050565b600181811c90821680610bf457607f821691505b602082108103610c1457634e487b7160e01b600052602260045260246000fd5b50919050565b634e487b7160e01b600052601160045260246000fd5b600082821015610c4257610c42610c1a565b500390565b60008219821115610c5a57610c5a610c1a565b500190565b600080835481600182811c915080831680610c7b57607f831692505b60208084108203610c9a57634e487b7160e01b86526022600452602486fd5b818015610cae5760018114610cbf57610cec565b60ff19861689528489019650610cec565b60008a81526020902060005b86811015610ce45781548b820152908501908301610ccb565b505084890196505b50949897505050505050505056feddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3efa26469706673582212202a2096dfca2a63ec3695f691a75af041945958adb5a9eef59037c184051b252464736f6c634300080d0033"
            .parse()
            .expect("invalid bytecode")
        });
    pub struct WETH<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for WETH<M> {
        fn clone(&self) -> Self {
            WETH(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for WETH<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for WETH<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(WETH))
                .field(&self.address())
                .finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> WETH<M> {
        /// Creates a new contract instance with the specified `ethers`
        /// client at the given `Address`. The contract derefs to a `ethers::Contract`
        /// object
        pub fn new<T: Into<::ethers::core::types::Address>>(
            address: T,
            client: ::std::sync::Arc<M>,
        ) -> Self {
            Self(::ethers::contract::Contract::new(
                address.into(),
                WETH_ABI.clone(),
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
                WETH_ABI.clone(),
                WETH_BYTECODE.clone().into(),
                client,
            );
            let deployer = factory.deploy(constructor_args)?;
            let deployer = ::ethers::contract::ContractDeployer::new(deployer);
            Ok(deployer)
        }
        ///Calls the contract's `DOMAIN_SEPARATOR` (0x3644e515) function
        pub fn domain_separator(&self) -> ::ethers::contract::builders::ContractCall<M, [u8; 32]> {
            self.0
                .method_hash([54, 68, 229, 21], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `allowance` (0xdd62ed3e) function
        pub fn allowance(
            &self,
            p0: ::ethers::core::types::Address,
            p1: ::ethers::core::types::Address,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([221, 98, 237, 62], (p0, p1))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `approve` (0x095ea7b3) function
        pub fn approve(
            &self,
            spender: ::ethers::core::types::Address,
            amount: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<M, bool> {
            self.0
                .method_hash([9, 94, 167, 179], (spender, amount))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `balanceOf` (0x70a08231) function
        pub fn balance_of(
            &self,
            p0: ::ethers::core::types::Address,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([112, 160, 130, 49], p0)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `decimals` (0x313ce567) function
        pub fn decimals(&self) -> ::ethers::contract::builders::ContractCall<M, u8> {
            self.0
                .method_hash([49, 60, 229, 103], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `deposit` (0xd0e30db0) function
        pub fn deposit(&self) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([208, 227, 13, 176], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `name` (0x06fdde03) function
        pub fn name(&self) -> ::ethers::contract::builders::ContractCall<M, String> {
            self.0
                .method_hash([6, 253, 222, 3], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `nonces` (0x7ecebe00) function
        pub fn nonces(
            &self,
            p0: ::ethers::core::types::Address,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([126, 206, 190, 0], p0)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `permit` (0xd505accf) function
        pub fn permit(
            &self,
            owner: ::ethers::core::types::Address,
            spender: ::ethers::core::types::Address,
            value: ::ethers::core::types::U256,
            deadline: ::ethers::core::types::U256,
            v: u8,
            r: [u8; 32],
            s: [u8; 32],
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash(
                    [213, 5, 172, 207],
                    (owner, spender, value, deadline, v, r, s),
                )
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `symbol` (0x95d89b41) function
        pub fn symbol(&self) -> ::ethers::contract::builders::ContractCall<M, String> {
            self.0
                .method_hash([149, 216, 155, 65], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `totalSupply` (0x18160ddd) function
        pub fn total_supply(
            &self,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([24, 22, 13, 221], ())
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `transfer` (0xa9059cbb) function
        pub fn transfer(
            &self,
            to: ::ethers::core::types::Address,
            amount: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<M, bool> {
            self.0
                .method_hash([169, 5, 156, 187], (to, amount))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `transferFrom` (0x23b872dd) function
        pub fn transfer_from(
            &self,
            from: ::ethers::core::types::Address,
            to: ::ethers::core::types::Address,
            amount: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<M, bool> {
            self.0
                .method_hash([35, 184, 114, 221], (from, to, amount))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `withdraw` (0x2e1a7d4d) function
        pub fn withdraw(
            &self,
            amount: ::ethers::core::types::U256,
        ) -> ::ethers::contract::builders::ContractCall<M, ()> {
            self.0
                .method_hash([46, 26, 125, 77], amount)
                .expect("method not found (this should never happen)")
        }
        ///Gets the contract's `Approval` event
        pub fn approval_filter(&self) -> ::ethers::contract::builders::Event<M, ApprovalFilter> {
            self.0.event()
        }
        ///Gets the contract's `Deposit` event
        pub fn deposit_filter(&self) -> ::ethers::contract::builders::Event<M, DepositFilter> {
            self.0.event()
        }
        ///Gets the contract's `Transfer` event
        pub fn transfer_filter(&self) -> ::ethers::contract::builders::Event<M, TransferFilter> {
            self.0.event()
        }
        ///Gets the contract's `Withdrawal` event
        pub fn withdrawal_filter(
            &self,
        ) -> ::ethers::contract::builders::Event<M, WithdrawalFilter> {
            self.0.event()
        }
        /// Returns an [`Event`](#ethers_contract::builders::Event) builder for all events of this contract
        pub fn events(&self) -> ::ethers::contract::builders::Event<M, WETHEvents> {
            self.0.event_with_filter(Default::default())
        }
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>> for WETH<M> {
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
    #[ethevent(name = "Approval", abi = "Approval(address,address,uint256)")]
    pub struct ApprovalFilter {
        #[ethevent(indexed)]
        pub owner: ::ethers::core::types::Address,
        #[ethevent(indexed)]
        pub spender: ::ethers::core::types::Address,
        pub amount: ::ethers::core::types::U256,
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
    #[ethevent(name = "Deposit", abi = "Deposit(address,uint256)")]
    pub struct DepositFilter {
        #[ethevent(indexed)]
        pub from: ::ethers::core::types::Address,
        pub amount: ::ethers::core::types::U256,
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
    #[ethevent(name = "Transfer", abi = "Transfer(address,address,uint256)")]
    pub struct TransferFilter {
        #[ethevent(indexed)]
        pub from: ::ethers::core::types::Address,
        #[ethevent(indexed)]
        pub to: ::ethers::core::types::Address,
        pub amount: ::ethers::core::types::U256,
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
    #[ethevent(name = "Withdrawal", abi = "Withdrawal(address,uint256)")]
    pub struct WithdrawalFilter {
        #[ethevent(indexed)]
        pub to: ::ethers::core::types::Address,
        pub amount: ::ethers::core::types::U256,
    }
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum WETHEvents {
        ApprovalFilter(ApprovalFilter),
        DepositFilter(DepositFilter),
        TransferFilter(TransferFilter),
        WithdrawalFilter(WithdrawalFilter),
    }
    impl ::ethers::contract::EthLogDecode for WETHEvents {
        fn decode_log(
            log: &::ethers::core::abi::RawLog,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::Error>
        where
            Self: Sized,
        {
            if let Ok(decoded) = ApprovalFilter::decode_log(log) {
                return Ok(WETHEvents::ApprovalFilter(decoded));
            }
            if let Ok(decoded) = DepositFilter::decode_log(log) {
                return Ok(WETHEvents::DepositFilter(decoded));
            }
            if let Ok(decoded) = TransferFilter::decode_log(log) {
                return Ok(WETHEvents::TransferFilter(decoded));
            }
            if let Ok(decoded) = WithdrawalFilter::decode_log(log) {
                return Ok(WETHEvents::WithdrawalFilter(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData)
        }
    }
    impl ::std::fmt::Display for WETHEvents {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                WETHEvents::ApprovalFilter(element) => element.fmt(f),
                WETHEvents::DepositFilter(element) => element.fmt(f),
                WETHEvents::TransferFilter(element) => element.fmt(f),
                WETHEvents::WithdrawalFilter(element) => element.fmt(f),
            }
        }
    }
    ///Container type for all input parameters for the `DOMAIN_SEPARATOR` function with signature `DOMAIN_SEPARATOR()` and selector `0x3644e515`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "DOMAIN_SEPARATOR", abi = "DOMAIN_SEPARATOR()")]
    pub struct DomainSeparatorCall;
    ///Container type for all input parameters for the `allowance` function with signature `allowance(address,address)` and selector `0xdd62ed3e`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "allowance", abi = "allowance(address,address)")]
    pub struct AllowanceCall(
        pub ::ethers::core::types::Address,
        pub ::ethers::core::types::Address,
    );
    ///Container type for all input parameters for the `approve` function with signature `approve(address,uint256)` and selector `0x095ea7b3`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "approve", abi = "approve(address,uint256)")]
    pub struct ApproveCall {
        pub spender: ::ethers::core::types::Address,
        pub amount: ::ethers::core::types::U256,
    }
    ///Container type for all input parameters for the `balanceOf` function with signature `balanceOf(address)` and selector `0x70a08231`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "balanceOf", abi = "balanceOf(address)")]
    pub struct BalanceOfCall(pub ::ethers::core::types::Address);
    ///Container type for all input parameters for the `decimals` function with signature `decimals()` and selector `0x313ce567`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "decimals", abi = "decimals()")]
    pub struct DecimalsCall;
    ///Container type for all input parameters for the `deposit` function with signature `deposit()` and selector `0xd0e30db0`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "deposit", abi = "deposit()")]
    pub struct DepositCall;
    ///Container type for all input parameters for the `name` function with signature `name()` and selector `0x06fdde03`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "name", abi = "name()")]
    pub struct NameCall;
    ///Container type for all input parameters for the `nonces` function with signature `nonces(address)` and selector `0x7ecebe00`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "nonces", abi = "nonces(address)")]
    pub struct NoncesCall(pub ::ethers::core::types::Address);
    ///Container type for all input parameters for the `permit` function with signature `permit(address,address,uint256,uint256,uint8,bytes32,bytes32)` and selector `0xd505accf`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(
        name = "permit",
        abi = "permit(address,address,uint256,uint256,uint8,bytes32,bytes32)"
    )]
    pub struct PermitCall {
        pub owner: ::ethers::core::types::Address,
        pub spender: ::ethers::core::types::Address,
        pub value: ::ethers::core::types::U256,
        pub deadline: ::ethers::core::types::U256,
        pub v: u8,
        pub r: [u8; 32],
        pub s: [u8; 32],
    }
    ///Container type for all input parameters for the `symbol` function with signature `symbol()` and selector `0x95d89b41`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "symbol", abi = "symbol()")]
    pub struct SymbolCall;
    ///Container type for all input parameters for the `totalSupply` function with signature `totalSupply()` and selector `0x18160ddd`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "totalSupply", abi = "totalSupply()")]
    pub struct TotalSupplyCall;
    ///Container type for all input parameters for the `transfer` function with signature `transfer(address,uint256)` and selector `0xa9059cbb`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "transfer", abi = "transfer(address,uint256)")]
    pub struct TransferCall {
        pub to: ::ethers::core::types::Address,
        pub amount: ::ethers::core::types::U256,
    }
    ///Container type for all input parameters for the `transferFrom` function with signature `transferFrom(address,address,uint256)` and selector `0x23b872dd`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "transferFrom", abi = "transferFrom(address,address,uint256)")]
    pub struct TransferFromCall {
        pub from: ::ethers::core::types::Address,
        pub to: ::ethers::core::types::Address,
        pub amount: ::ethers::core::types::U256,
    }
    ///Container type for all input parameters for the `withdraw` function with signature `withdraw(uint256)` and selector `0x2e1a7d4d`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "withdraw", abi = "withdraw(uint256)")]
    pub struct WithdrawCall {
        pub amount: ::ethers::core::types::U256,
    }
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum WETHCalls {
        DomainSeparator(DomainSeparatorCall),
        Allowance(AllowanceCall),
        Approve(ApproveCall),
        BalanceOf(BalanceOfCall),
        Decimals(DecimalsCall),
        Deposit(DepositCall),
        Name(NameCall),
        Nonces(NoncesCall),
        Permit(PermitCall),
        Symbol(SymbolCall),
        TotalSupply(TotalSupplyCall),
        Transfer(TransferCall),
        TransferFrom(TransferFromCall),
        Withdraw(WithdrawCall),
    }
    impl ::ethers::core::abi::AbiDecode for WETHCalls {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded) =
                <DomainSeparatorCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(WETHCalls::DomainSeparator(decoded));
            }
            if let Ok(decoded) =
                <AllowanceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(WETHCalls::Allowance(decoded));
            }
            if let Ok(decoded) =
                <ApproveCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(WETHCalls::Approve(decoded));
            }
            if let Ok(decoded) =
                <BalanceOfCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(WETHCalls::BalanceOf(decoded));
            }
            if let Ok(decoded) =
                <DecimalsCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(WETHCalls::Decimals(decoded));
            }
            if let Ok(decoded) =
                <DepositCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(WETHCalls::Deposit(decoded));
            }
            if let Ok(decoded) = <NameCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(WETHCalls::Name(decoded));
            }
            if let Ok(decoded) =
                <NoncesCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(WETHCalls::Nonces(decoded));
            }
            if let Ok(decoded) =
                <PermitCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(WETHCalls::Permit(decoded));
            }
            if let Ok(decoded) =
                <SymbolCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(WETHCalls::Symbol(decoded));
            }
            if let Ok(decoded) =
                <TotalSupplyCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(WETHCalls::TotalSupply(decoded));
            }
            if let Ok(decoded) =
                <TransferCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(WETHCalls::Transfer(decoded));
            }
            if let Ok(decoded) =
                <TransferFromCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(WETHCalls::TransferFrom(decoded));
            }
            if let Ok(decoded) =
                <WithdrawCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(WETHCalls::Withdraw(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for WETHCalls {
        fn encode(self) -> Vec<u8> {
            match self {
                WETHCalls::DomainSeparator(element) => element.encode(),
                WETHCalls::Allowance(element) => element.encode(),
                WETHCalls::Approve(element) => element.encode(),
                WETHCalls::BalanceOf(element) => element.encode(),
                WETHCalls::Decimals(element) => element.encode(),
                WETHCalls::Deposit(element) => element.encode(),
                WETHCalls::Name(element) => element.encode(),
                WETHCalls::Nonces(element) => element.encode(),
                WETHCalls::Permit(element) => element.encode(),
                WETHCalls::Symbol(element) => element.encode(),
                WETHCalls::TotalSupply(element) => element.encode(),
                WETHCalls::Transfer(element) => element.encode(),
                WETHCalls::TransferFrom(element) => element.encode(),
                WETHCalls::Withdraw(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for WETHCalls {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                WETHCalls::DomainSeparator(element) => element.fmt(f),
                WETHCalls::Allowance(element) => element.fmt(f),
                WETHCalls::Approve(element) => element.fmt(f),
                WETHCalls::BalanceOf(element) => element.fmt(f),
                WETHCalls::Decimals(element) => element.fmt(f),
                WETHCalls::Deposit(element) => element.fmt(f),
                WETHCalls::Name(element) => element.fmt(f),
                WETHCalls::Nonces(element) => element.fmt(f),
                WETHCalls::Permit(element) => element.fmt(f),
                WETHCalls::Symbol(element) => element.fmt(f),
                WETHCalls::TotalSupply(element) => element.fmt(f),
                WETHCalls::Transfer(element) => element.fmt(f),
                WETHCalls::TransferFrom(element) => element.fmt(f),
                WETHCalls::Withdraw(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<DomainSeparatorCall> for WETHCalls {
        fn from(var: DomainSeparatorCall) -> Self {
            WETHCalls::DomainSeparator(var)
        }
    }
    impl ::std::convert::From<AllowanceCall> for WETHCalls {
        fn from(var: AllowanceCall) -> Self {
            WETHCalls::Allowance(var)
        }
    }
    impl ::std::convert::From<ApproveCall> for WETHCalls {
        fn from(var: ApproveCall) -> Self {
            WETHCalls::Approve(var)
        }
    }
    impl ::std::convert::From<BalanceOfCall> for WETHCalls {
        fn from(var: BalanceOfCall) -> Self {
            WETHCalls::BalanceOf(var)
        }
    }
    impl ::std::convert::From<DecimalsCall> for WETHCalls {
        fn from(var: DecimalsCall) -> Self {
            WETHCalls::Decimals(var)
        }
    }
    impl ::std::convert::From<DepositCall> for WETHCalls {
        fn from(var: DepositCall) -> Self {
            WETHCalls::Deposit(var)
        }
    }
    impl ::std::convert::From<NameCall> for WETHCalls {
        fn from(var: NameCall) -> Self {
            WETHCalls::Name(var)
        }
    }
    impl ::std::convert::From<NoncesCall> for WETHCalls {
        fn from(var: NoncesCall) -> Self {
            WETHCalls::Nonces(var)
        }
    }
    impl ::std::convert::From<PermitCall> for WETHCalls {
        fn from(var: PermitCall) -> Self {
            WETHCalls::Permit(var)
        }
    }
    impl ::std::convert::From<SymbolCall> for WETHCalls {
        fn from(var: SymbolCall) -> Self {
            WETHCalls::Symbol(var)
        }
    }
    impl ::std::convert::From<TotalSupplyCall> for WETHCalls {
        fn from(var: TotalSupplyCall) -> Self {
            WETHCalls::TotalSupply(var)
        }
    }
    impl ::std::convert::From<TransferCall> for WETHCalls {
        fn from(var: TransferCall) -> Self {
            WETHCalls::Transfer(var)
        }
    }
    impl ::std::convert::From<TransferFromCall> for WETHCalls {
        fn from(var: TransferFromCall) -> Self {
            WETHCalls::TransferFrom(var)
        }
    }
    impl ::std::convert::From<WithdrawCall> for WETHCalls {
        fn from(var: WithdrawCall) -> Self {
            WETHCalls::Withdraw(var)
        }
    }
    ///Container type for all return fields from the `DOMAIN_SEPARATOR` function with signature `DOMAIN_SEPARATOR()` and selector `0x3644e515`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct DomainSeparatorReturn(pub [u8; 32]);
    ///Container type for all return fields from the `allowance` function with signature `allowance(address,address)` and selector `0xdd62ed3e`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct AllowanceReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `approve` function with signature `approve(address,uint256)` and selector `0x095ea7b3`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct ApproveReturn(pub bool);
    ///Container type for all return fields from the `balanceOf` function with signature `balanceOf(address)` and selector `0x70a08231`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct BalanceOfReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `decimals` function with signature `decimals()` and selector `0x313ce567`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct DecimalsReturn(pub u8);
    ///Container type for all return fields from the `name` function with signature `name()` and selector `0x06fdde03`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct NameReturn(pub String);
    ///Container type for all return fields from the `nonces` function with signature `nonces(address)` and selector `0x7ecebe00`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct NoncesReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `symbol` function with signature `symbol()` and selector `0x95d89b41`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct SymbolReturn(pub String);
    ///Container type for all return fields from the `totalSupply` function with signature `totalSupply()` and selector `0x18160ddd`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct TotalSupplyReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `transfer` function with signature `transfer(address,uint256)` and selector `0xa9059cbb`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct TransferReturn(pub bool);
    ///Container type for all return fields from the `transferFrom` function with signature `transferFrom(address,address,uint256)` and selector `0x23b872dd`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct TransferFromReturn(pub bool);
}
