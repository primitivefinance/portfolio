pub use helper_hyper_view::*;
#[allow(clippy::too_many_arguments, non_camel_case_types)]
pub mod helper_hyper_view {
    #![allow(clippy::enum_variant_names)]
    #![allow(dead_code)]
    #![allow(clippy::type_complexity)]
    #![allow(unused_imports)]
    pub use super::super::shared_types::*;
    use ::ethers::contract::{
        builders::{ContractCall, Event},
        Contract, Lazy,
    };
    use ::ethers::core::{
        abi::{Abi, Detokenize, InvalidOutputType, Token, Tokenizable},
        types::*,
    };
    use ::ethers::providers::Middleware;
    ///HelperHyperView was auto-generated with ethers-rs Abigen. More information at: https://github.com/gakonst/ethers-rs
    use std::sync::Arc;
    #[rustfmt::skip]
    const __ABI: &str = "[{\"inputs\":[],\"type\":\"error\",\"name\":\"InvalidBalance\",\"outputs\":[]},{\"inputs\":[{\"internalType\":\"contract HyperLike\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"contract TestERC20\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"contract IHyperStruct\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getPool\",\"outputs\":[{\"internalType\":\"struct HyperPool\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"lastTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"lastTimestamp\",\"type\":\"uint32\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"controller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalReward\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"lastPrice\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"liquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"int128\",\"name\":\"stakedLiquidityDelta\",\"type\":\"int128\",\"components\":[]},{\"internalType\":\"struct HyperCurve\",\"name\":\"params\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]},{\"internalType\":\"struct HyperPair\",\"name\":\"pair\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]}]},{\"inputs\":[{\"internalType\":\"contract IHyperStruct\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"positionId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getPosition\",\"outputs\":[{\"internalType\":\"struct HyperPosition\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"uint128\",\"name\":\"freeLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"lastTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"stakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"unstakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthRewardLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuoteLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedQuote\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedReward\",\"type\":\"uint128\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"contract HyperLike\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"contract TestERC20\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"_getReserve\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getBalanceSum\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getCurve\",\"outputs\":[{\"internalType\":\"struct HyperCurve\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"bool\",\"name\":\"sellAsset\",\"type\":\"bool\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getMaxSwapLimit\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint24\",\"name\":\"pairId\",\"type\":\"uint24\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPair\",\"outputs\":[{\"internalType\":\"struct HyperPair\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPhysicalBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPool\",\"outputs\":[{\"internalType\":\"struct HyperPool\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"lastTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"lastTimestamp\",\"type\":\"uint32\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"controller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalReward\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthGlobalQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"lastPrice\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"liquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"int128\",\"name\":\"stakedLiquidityDelta\",\"type\":\"int128\",\"components\":[]},{\"internalType\":\"struct HyperCurve\",\"name\":\"params\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"int24\",\"name\":\"maxTick\",\"type\":\"int24\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"jit\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"fee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"duration\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"volatility\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint16\",\"name\":\"priorityFee\",\"type\":\"uint16\",\"components\":[]},{\"internalType\":\"uint32\",\"name\":\"createdAt\",\"type\":\"uint32\",\"components\":[]}]},{\"internalType\":\"struct HyperPair\",\"name\":\"pair\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"address\",\"name\":\"tokenAsset\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsAsset\",\"type\":\"uint8\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"tokenQuote\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint8\",\"name\":\"decimalsQuote\",\"type\":\"uint8\",\"components\":[]}]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"owner\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"positionId\",\"type\":\"uint64\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPosition\",\"outputs\":[{\"internalType\":\"struct HyperPosition\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"uint128\",\"name\":\"freeLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"stakedLiquidity\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"lastTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"stakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"unstakeTimestamp\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthRewardLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuoteLast\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedAsset\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedQuote\",\"type\":\"uint128\",\"components\":[]},{\"internalType\":\"uint128\",\"name\":\"tokensOwedReward\",\"type\":\"uint128\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getPositionLiquiditySum\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getReserve\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"uint64\",\"name\":\"poolId\",\"type\":\"uint64\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"caller\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getState\",\"outputs\":[{\"internalType\":\"struct HyperState\",\"name\":\"\",\"type\":\"tuple\",\"components\":[{\"internalType\":\"uint256\",\"name\":\"reserveAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"reserveQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"physicalBalanceAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"physicalBalanceQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalBalanceAsset\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalBalanceQuote\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalPositionLiquidity\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"callerPositionLiquidity\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"totalPoolLiquidity\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetPool\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuotePool\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthAssetPosition\",\"type\":\"uint256\",\"components\":[]},{\"internalType\":\"uint256\",\"name\":\"feeGrowthQuotePosition\",\"type\":\"uint256\",\"components\":[]}]}]},{\"inputs\":[{\"internalType\":\"address\",\"name\":\"hyper\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address\",\"name\":\"token\",\"type\":\"address\",\"components\":[]},{\"internalType\":\"address[]\",\"name\":\"owners\",\"type\":\"address[]\",\"components\":[]}],\"stateMutability\":\"view\",\"type\":\"function\",\"name\":\"getVirtualBalance\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\",\"components\":[]}]}]";
    /// The parsed JSON-ABI of the contract.
    pub static HELPERHYPERVIEW_ABI: ::ethers::contract::Lazy<::ethers::core::abi::Abi> =
        ::ethers::contract::Lazy::new(|| {
            ::ethers::core::utils::__serde_json::from_str(__ABI).expect("invalid abi")
        });
    /// Bytecode of the #name contract
    pub static HELPERHYPERVIEW_BYTECODE: ::ethers::contract::Lazy<::ethers::core::types::Bytes> =
        ::ethers::contract::Lazy::new(|| {
            "0x608060405234801561001057600080fd5b5061147d806100206000396000f3fe608060405234801561001057600080fd5b50600436106101005760003560e01c8063cee2aaf511610097578063dc72380411610066578063dc723804146101ee578063dd05e299146101ee578063f3140b1e1461020e578063ff314c0a146102b457600080fd5b8063cee2aaf5146101a8578063cf7dee1f146101bb578063d6bd603c146101bb578063d83410b6146101ce57600080fd5b80636dce537d116100d35780636dce537d146101625780637b135ad1146101755780638828200d14610195578063cbc3ab531461012e57600080fd5b806309deb4d314610105578063273c329f146101055780635a8be8b01461012e578063634e05e01461014f575b600080fd5b610118610113366004610a5e565b6102c7565b6040516101259190610af0565b60405180910390f35b61014161013c366004610c04565b6103f7565b604051908152602001610125565b61014161015d366004610c04565b610465565b610141610170366004610d45565b610471565b610188610183366004610da7565b61049c565b6040516101259190610ddd565b6101416101a3366004610e1e565b61052d565b6101416101b6366004610e4c565b61058e565b6101416101c9366004610e75565b6105ac565b6101e16101dc366004610a5e565b61062a565b6040516101259190610ec0565b6102016101fc366004610ece565b61067a565b6040516101259190610f15565b61022161021c366004610fc7565b61077f565b6040516101259190815181526020808301519082015260408083015190820152606080830151908201526080808301519082015260a0808301519082015260c0808301519082015260e08083015190820152610100808301519082015261012080830151908201526101408083015190820152610160808301519082015261018091820151918101919091526101a00190565b6101416102c2366004610d45565b610900565b61037b6040805161018081018252600080825260208083018290528284018290526060808401839052608080850184905260a080860185905260c080870186905260e0808801879052610100880187905261012088018790528851908101895286815294850186905296840185905291830184905282018390528101829052928301529061014082019081526040805160808101825260008082526020828101829052928201819052606082015291015290565b6040516322697c2160e21b815267ffffffffffffffff831660048201526001600160a01b038416906389a5f084906024016102a060405180830381865afa1580156103ca573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906103ee91906111f0565b90505b92915050565b60405163c9a396e960e01b81526001600160a01b0382811660048301526000919084169063c9a396e990602401602060405180830381865afa158015610441573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906103ee91906112ca565b60006103ee828461094e565b60008061047f858585610900565b61048986866103f7565b61049391906112f9565b95945050505050565b604080516080810182526000808252602082018190529181018290526060810191909152604051631791d98f60e21b815262ffffff831660048201526001600160a01b03841690635e47663c90602401608060405180830381865afa158015610509573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906103ee9190611311565b60008060005b835181146105855761055f868583815181106105515761055161132d565b60200260200101518761067a565b51610573906001600160801b0316836112f9565b915061057e81611343565b9050610533565b50949350505050565b6000811561059e57506000919050565b50600019919050565b919050565b60405163d4fac45d60e01b81526001600160a01b03838116600483015282811660248301526000919085169063d4fac45d90604401602060405180830381865afa1580156105fe573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061062291906112ca565b949350505050565b6040805160e081018252600080825260208201819052918101829052606081018290526080810182905260a0810182905260c081018290529061066d84846102c7565b6101400151949350505050565b61070460405180610160016040528060006001600160801b0316815260200160006001600160801b0316815260200160008152602001600081526020016000815260200160008152602001600081526020016000815260200160006001600160801b0316815260200160006001600160801b0316815260200160006001600160801b031681525090565b604051635b4289f560e11b81526001600160a01b03848116600483015267ffffffffffffffff8416602483015285169063b68513ea9060440161016060405180830381865afa15801561075b573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610622919061135c565b6107ea604051806101a00160405280600081526020016000815260200160008152602001600081526020016000815260200160008152602001600081526020016000815260200160008152602001600081526020016000815260200160008152602001600081525090565b60006107ff86602887901c62ffffff1661049c565b8051604082015191925090600061081689896102c7565b905060006108258a898b61067a565b90506000604051806101a0016040528061083f8d886103f7565b815260200161084e8d876103f7565b815260200161085d8d88610465565b815260200161086c8d87610465565b815260200161087c8d888c610900565b815260200161088c8d878c610900565b815260200161089c8d8d8c61052d565b815260200183600001516001600160801b031681526020018460e001516001600160801b03168152602001846080015181526020018460a0015181526020018360c0015181526020018360e001518152509050809650505050505050949350505050565b60008060005b8351811461058557610932868583815181106109245761092461132d565b6020026020010151876105ac565b61093c90836112f9565b915061094781611343565b9050610906565b604080516001600160a01b0383811660248084019190915283518084039091018152604490920183526020820180516001600160e01b03166370a0823160e01b179052915160009283928392918716916109a8919061140c565b600060405180830381855afa9150503d80600081146109e3576040519150601f19603f3d011682016040523d82523d6000602084013e6109e8565b606091505b50915091508115806109fc57508051602014155b15610a1a5760405163c52e3eff60e01b815260040160405180910390fd5b8080602001905181019061049391906112ca565b6001600160a01b0381168114610a4357600080fd5b50565b803567ffffffffffffffff811681146105a757600080fd5b60008060408385031215610a7157600080fd5b8235610a7c81610a2e565b9150610a8a60208401610a46565b90509250929050565b805160020b8252602081015161ffff80821660208501528060408401511660408501528060608401511660608501528060808401511660808501528060a08401511660a0850152505063ffffffff60c08201511660c08301525050565b815160020b81526102a081016020830151610b13602084018263ffffffff169052565b506040830151610b2e60408401826001600160a01b03169052565b50606083015160608301526080830151608083015260a083015160a083015260c0830151610b6760c08401826001600160801b03169052565b5060e0830151610b8260e08401826001600160801b03169052565b50610100838101516001600160801b03169083015261012080840151600f0b9083015261014080840151610bb882850182610a93565b505061016083015180516001600160a01b03908116610220850152602082015160ff90811661024086015260408301519091166102608501526060820151166102808401525092915050565b60008060408385031215610c1757600080fd5b8235610c2281610a2e565b91506020830135610c3281610a2e565b809150509250929050565b634e487b7160e01b600052604160045260246000fd5b604051610180810167ffffffffffffffff81118282101715610c7757610c77610c3d565b60405290565b604051610160810167ffffffffffffffff81118282101715610c7757610c77610c3d565b600082601f830112610cb257600080fd5b8135602067ffffffffffffffff80831115610ccf57610ccf610c3d565b8260051b604051601f19603f83011681018181108482111715610cf457610cf4610c3d565b604052938452858101830193838101925087851115610d1257600080fd5b83870191505b84821015610d3a578135610d2b81610a2e565b83529183019190830190610d18565b979650505050505050565b600080600060608486031215610d5a57600080fd5b8335610d6581610a2e565b92506020840135610d7581610a2e565b9150604084013567ffffffffffffffff811115610d9157600080fd5b610d9d86828701610ca1565b9150509250925092565b60008060408385031215610dba57600080fd5b8235610dc581610a2e565b9150602083013562ffffff81168114610c3257600080fd5b608081016103f1828460018060a01b0380825116835260ff60208301511660208401528060408301511660408401525060ff60608201511660608301525050565b600080600060608486031215610e3357600080fd5b8335610e3e81610a2e565b9250610d7560208501610a46565b600060208284031215610e5e57600080fd5b81358015158114610e6e57600080fd5b9392505050565b600080600060608486031215610e8a57600080fd5b8335610e9581610a2e565b92506020840135610ea581610a2e565b91506040840135610eb581610a2e565b809150509250925092565b60e081016103f18284610a93565b600080600060608486031215610ee357600080fd5b8335610eee81610a2e565b92506020840135610efe81610a2e565b9150610f0c60408501610a46565b90509250925092565b81516001600160801b0316815261016081016020830151610f4160208401826001600160801b03169052565b5060408301516040830152606083015160608301526080830151608083015260a083015160a083015260c083015160c083015260e083015160e083015261010080840151610f99828501826001600160801b03169052565b5050610120838101516001600160801b03908116918401919091526101409384015116929091019190915290565b60008060008060808587031215610fdd57600080fd5b8435610fe881610a2e565b9350610ff660208601610a46565b9250604085013561100681610a2e565b9150606085013567ffffffffffffffff81111561102257600080fd5b61102e87828801610ca1565b91505092959194509250565b8051600281900b81146105a757600080fd5b805163ffffffff811681146105a757600080fd5b80516105a781610a2e565b80516001600160801b03811681146105a757600080fd5b8051600f81900b81146105a757600080fd5b805161ffff811681146105a757600080fd5b600060e082840312156110b857600080fd5b60405160e0810181811067ffffffffffffffff821117156110db576110db610c3d565b6040529050806110ea8361103a565b81526110f860208401611094565b602082015261110960408401611094565b604082015261111a60608401611094565b606082015261112b60808401611094565b608082015261113c60a08401611094565b60a082015261114d60c0840161104c565b60c08201525092915050565b805160ff811681146105a757600080fd5b60006080828403121561117c57600080fd5b6040516080810181811067ffffffffffffffff8211171561119f5761119f610c3d565b806040525080915082516111b281610a2e565b81526111c060208401611159565b602082015260408301516111d381610a2e565b60408201526111e460608401611159565b60608201525092915050565b60006102a0828403121561120357600080fd5b61120b610c53565b6112148361103a565b81526112226020840161104c565b602082015261123360408401611060565b6040820152606083015160608201526080830151608082015260a083015160a082015261126260c0840161106b565b60c082015261127360e0840161106b565b60e082015261010061128681850161106b565b90820152610120611298848201611082565b908201526101406112ab858583016110a6565b908201526112bd84610220850161116a565b6101608201529392505050565b6000602082840312156112dc57600080fd5b5051919050565b634e487b7160e01b600052601160045260246000fd5b6000821982111561130c5761130c6112e3565b500190565b60006080828403121561132357600080fd5b6103ee838361116a565b634e487b7160e01b600052603260045260246000fd5b600060018201611355576113556112e3565b5060010190565b6000610160828403121561136f57600080fd5b611377610c7d565b6113808361106b565b815261138e6020840161106b565b602082015260408301516040820152606083015160608201526080830151608082015260a083015160a082015260c083015160c082015260e083015160e08201526101006113dd81850161106b565b908201526101206113ef84820161106b565b9082015261014061140184820161106b565b908201529392505050565b6000825160005b8181101561142d5760208186018101518583015201611413565b8181111561143c576000828501525b50919091019291505056fea2646970667358221220ab1e20d8c6574703a1b3e00b675ad15f01084176d4ebfca7774c230f6ec5fee764736f6c634300080d0033"
            .parse()
            .expect("invalid bytecode")
        });
    pub struct HelperHyperView<M>(::ethers::contract::Contract<M>);
    impl<M> Clone for HelperHyperView<M> {
        fn clone(&self) -> Self {
            HelperHyperView(self.0.clone())
        }
    }
    impl<M> std::ops::Deref for HelperHyperView<M> {
        type Target = ::ethers::contract::Contract<M>;
        fn deref(&self) -> &Self::Target {
            &self.0
        }
    }
    impl<M> std::fmt::Debug for HelperHyperView<M> {
        fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
            f.debug_tuple(stringify!(HelperHyperView))
                .field(&self.address())
                .finish()
        }
    }
    impl<M: ::ethers::providers::Middleware> HelperHyperView<M> {
        /// Creates a new contract instance with the specified `ethers`
        /// client at the given `Address`. The contract derefs to a `ethers::Contract`
        /// object
        pub fn new<T: Into<::ethers::core::types::Address>>(
            address: T,
            client: ::std::sync::Arc<M>,
        ) -> Self {
            Self(::ethers::contract::Contract::new(
                address.into(),
                HELPERHYPERVIEW_ABI.clone(),
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
                HELPERHYPERVIEW_ABI.clone(),
                HELPERHYPERVIEW_BYTECODE.clone().into(),
                client,
            );
            let deployer = factory.deploy(constructor_args)?;
            let deployer = ::ethers::contract::ContractDeployer::new(deployer);
            Ok(deployer)
        }
        ///Calls the contract's `_getBalance` (0xcf7dee1f) function
        pub fn _get_balance(
            &self,
            hyper: ::ethers::core::types::Address,
            owner: ::ethers::core::types::Address,
            token: ::ethers::core::types::Address,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([207, 125, 238, 31], (hyper, owner, token))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `_getPool` (0x09deb4d3) function
        pub fn _get_pool(
            &self,
            hyper: ::ethers::core::types::Address,
            pool_id: u64,
        ) -> ::ethers::contract::builders::ContractCall<M, HyperPool> {
            self.0
                .method_hash([9, 222, 180, 211], (hyper, pool_id))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `_getPosition` (0xdc723804) function
        pub fn _get_position(
            &self,
            hyper: ::ethers::core::types::Address,
            owner: ::ethers::core::types::Address,
            position_id: u64,
        ) -> ::ethers::contract::builders::ContractCall<M, HyperPosition> {
            self.0
                .method_hash([220, 114, 56, 4], (hyper, owner, position_id))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `_getReserve` (0x5a8be8b0) function
        pub fn _get_reserve(
            &self,
            hyper: ::ethers::core::types::Address,
            token: ::ethers::core::types::Address,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([90, 139, 232, 176], (hyper, token))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getBalance` (0xd6bd603c) function
        pub fn get_balance(
            &self,
            hyper: ::ethers::core::types::Address,
            owner: ::ethers::core::types::Address,
            token: ::ethers::core::types::Address,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([214, 189, 96, 60], (hyper, owner, token))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getBalanceSum` (0xff314c0a) function
        pub fn get_balance_sum(
            &self,
            hyper: ::ethers::core::types::Address,
            token: ::ethers::core::types::Address,
            owners: ::std::vec::Vec<::ethers::core::types::Address>,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([255, 49, 76, 10], (hyper, token, owners))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getCurve` (0xd83410b6) function
        pub fn get_curve(
            &self,
            hyper: ::ethers::core::types::Address,
            pool_id: u64,
        ) -> ::ethers::contract::builders::ContractCall<M, HyperCurve> {
            self.0
                .method_hash([216, 52, 16, 182], (hyper, pool_id))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getMaxSwapLimit` (0xcee2aaf5) function
        pub fn get_max_swap_limit(
            &self,
            sell_asset: bool,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([206, 226, 170, 245], sell_asset)
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getPair` (0x7b135ad1) function
        pub fn get_pair(
            &self,
            hyper: ::ethers::core::types::Address,
            pair_id: u32,
        ) -> ::ethers::contract::builders::ContractCall<M, HyperPair> {
            self.0
                .method_hash([123, 19, 90, 209], (hyper, pair_id))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getPhysicalBalance` (0x634e05e0) function
        pub fn get_physical_balance(
            &self,
            hyper: ::ethers::core::types::Address,
            token: ::ethers::core::types::Address,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([99, 78, 5, 224], (hyper, token))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getPool` (0x273c329f) function
        pub fn get_pool(
            &self,
            hyper: ::ethers::core::types::Address,
            pool_id: u64,
        ) -> ::ethers::contract::builders::ContractCall<M, HyperPool> {
            self.0
                .method_hash([39, 60, 50, 159], (hyper, pool_id))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getPosition` (0xdd05e299) function
        pub fn get_position(
            &self,
            hyper: ::ethers::core::types::Address,
            owner: ::ethers::core::types::Address,
            position_id: u64,
        ) -> ::ethers::contract::builders::ContractCall<M, HyperPosition> {
            self.0
                .method_hash([221, 5, 226, 153], (hyper, owner, position_id))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getPositionLiquiditySum` (0x8828200d) function
        pub fn get_position_liquidity_sum(
            &self,
            hyper: ::ethers::core::types::Address,
            pool_id: u64,
            owners: ::std::vec::Vec<::ethers::core::types::Address>,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([136, 40, 32, 13], (hyper, pool_id, owners))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getReserve` (0xcbc3ab53) function
        pub fn get_reserve(
            &self,
            hyper: ::ethers::core::types::Address,
            token: ::ethers::core::types::Address,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([203, 195, 171, 83], (hyper, token))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getState` (0xf3140b1e) function
        pub fn get_state(
            &self,
            hyper: ::ethers::core::types::Address,
            pool_id: u64,
            caller: ::ethers::core::types::Address,
            owners: ::std::vec::Vec<::ethers::core::types::Address>,
        ) -> ::ethers::contract::builders::ContractCall<M, HyperState> {
            self.0
                .method_hash([243, 20, 11, 30], (hyper, pool_id, caller, owners))
                .expect("method not found (this should never happen)")
        }
        ///Calls the contract's `getVirtualBalance` (0x6dce537d) function
        pub fn get_virtual_balance(
            &self,
            hyper: ::ethers::core::types::Address,
            token: ::ethers::core::types::Address,
            owners: ::std::vec::Vec<::ethers::core::types::Address>,
        ) -> ::ethers::contract::builders::ContractCall<M, ::ethers::core::types::U256> {
            self.0
                .method_hash([109, 206, 83, 125], (hyper, token, owners))
                .expect("method not found (this should never happen)")
        }
    }
    impl<M: ::ethers::providers::Middleware> From<::ethers::contract::Contract<M>>
        for HelperHyperView<M>
    {
        fn from(contract: ::ethers::contract::Contract<M>) -> Self {
            Self::new(contract.address(), contract.client())
        }
    }
    ///Custom Error type `InvalidBalance` with signature `InvalidBalance()` and selector `0xc52e3eff`
    #[derive(
        Clone,
        Debug,
        Default,
        Eq,
        PartialEq,
        ::ethers::contract::EthError,
        ::ethers::contract::EthDisplay,
    )]
    #[etherror(name = "InvalidBalance", abi = "InvalidBalance()")]
    pub struct InvalidBalance;
    ///Container type for all input parameters for the `_getBalance` function with signature `_getBalance(address,address,address)` and selector `0xcf7dee1f`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "_getBalance", abi = "_getBalance(address,address,address)")]
    pub struct _GetBalanceCall {
        pub hyper: ::ethers::core::types::Address,
        pub owner: ::ethers::core::types::Address,
        pub token: ::ethers::core::types::Address,
    }
    ///Container type for all input parameters for the `_getPool` function with signature `_getPool(address,uint64)` and selector `0x09deb4d3`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "_getPool", abi = "_getPool(address,uint64)")]
    pub struct _GetPoolCall {
        pub hyper: ::ethers::core::types::Address,
        pub pool_id: u64,
    }
    ///Container type for all input parameters for the `_getPosition` function with signature `_getPosition(address,address,uint64)` and selector `0xdc723804`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "_getPosition", abi = "_getPosition(address,address,uint64)")]
    pub struct _GetPositionCall {
        pub hyper: ::ethers::core::types::Address,
        pub owner: ::ethers::core::types::Address,
        pub position_id: u64,
    }
    ///Container type for all input parameters for the `_getReserve` function with signature `_getReserve(address,address)` and selector `0x5a8be8b0`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "_getReserve", abi = "_getReserve(address,address)")]
    pub struct _GetReserveCall {
        pub hyper: ::ethers::core::types::Address,
        pub token: ::ethers::core::types::Address,
    }
    ///Container type for all input parameters for the `getBalance` function with signature `getBalance(address,address,address)` and selector `0xd6bd603c`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getBalance", abi = "getBalance(address,address,address)")]
    pub struct GetBalanceCall {
        pub hyper: ::ethers::core::types::Address,
        pub owner: ::ethers::core::types::Address,
        pub token: ::ethers::core::types::Address,
    }
    ///Container type for all input parameters for the `getBalanceSum` function with signature `getBalanceSum(address,address,address[])` and selector `0xff314c0a`
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
        name = "getBalanceSum",
        abi = "getBalanceSum(address,address,address[])"
    )]
    pub struct GetBalanceSumCall {
        pub hyper: ::ethers::core::types::Address,
        pub token: ::ethers::core::types::Address,
        pub owners: ::std::vec::Vec<::ethers::core::types::Address>,
    }
    ///Container type for all input parameters for the `getCurve` function with signature `getCurve(address,uint64)` and selector `0xd83410b6`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getCurve", abi = "getCurve(address,uint64)")]
    pub struct GetCurveCall {
        pub hyper: ::ethers::core::types::Address,
        pub pool_id: u64,
    }
    ///Container type for all input parameters for the `getMaxSwapLimit` function with signature `getMaxSwapLimit(bool)` and selector `0xcee2aaf5`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getMaxSwapLimit", abi = "getMaxSwapLimit(bool)")]
    pub struct GetMaxSwapLimitCall {
        pub sell_asset: bool,
    }
    ///Container type for all input parameters for the `getPair` function with signature `getPair(address,uint24)` and selector `0x7b135ad1`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getPair", abi = "getPair(address,uint24)")]
    pub struct GetPairCall {
        pub hyper: ::ethers::core::types::Address,
        pub pair_id: u32,
    }
    ///Container type for all input parameters for the `getPhysicalBalance` function with signature `getPhysicalBalance(address,address)` and selector `0x634e05e0`
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
        name = "getPhysicalBalance",
        abi = "getPhysicalBalance(address,address)"
    )]
    pub struct GetPhysicalBalanceCall {
        pub hyper: ::ethers::core::types::Address,
        pub token: ::ethers::core::types::Address,
    }
    ///Container type for all input parameters for the `getPool` function with signature `getPool(address,uint64)` and selector `0x273c329f`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getPool", abi = "getPool(address,uint64)")]
    pub struct GetPoolCall {
        pub hyper: ::ethers::core::types::Address,
        pub pool_id: u64,
    }
    ///Container type for all input parameters for the `getPosition` function with signature `getPosition(address,address,uint64)` and selector `0xdd05e299`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getPosition", abi = "getPosition(address,address,uint64)")]
    pub struct GetPositionCall {
        pub hyper: ::ethers::core::types::Address,
        pub owner: ::ethers::core::types::Address,
        pub position_id: u64,
    }
    ///Container type for all input parameters for the `getPositionLiquiditySum` function with signature `getPositionLiquiditySum(address,uint64,address[])` and selector `0x8828200d`
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
        name = "getPositionLiquiditySum",
        abi = "getPositionLiquiditySum(address,uint64,address[])"
    )]
    pub struct GetPositionLiquiditySumCall {
        pub hyper: ::ethers::core::types::Address,
        pub pool_id: u64,
        pub owners: ::std::vec::Vec<::ethers::core::types::Address>,
    }
    ///Container type for all input parameters for the `getReserve` function with signature `getReserve(address,address)` and selector `0xcbc3ab53`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getReserve", abi = "getReserve(address,address)")]
    pub struct GetReserveCall {
        pub hyper: ::ethers::core::types::Address,
        pub token: ::ethers::core::types::Address,
    }
    ///Container type for all input parameters for the `getState` function with signature `getState(address,uint64,address,address[])` and selector `0xf3140b1e`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthCall,
        ::ethers::contract::EthDisplay,
        Default,
    )]
    #[ethcall(name = "getState", abi = "getState(address,uint64,address,address[])")]
    pub struct GetStateCall {
        pub hyper: ::ethers::core::types::Address,
        pub pool_id: u64,
        pub caller: ::ethers::core::types::Address,
        pub owners: ::std::vec::Vec<::ethers::core::types::Address>,
    }
    ///Container type for all input parameters for the `getVirtualBalance` function with signature `getVirtualBalance(address,address,address[])` and selector `0x6dce537d`
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
        name = "getVirtualBalance",
        abi = "getVirtualBalance(address,address,address[])"
    )]
    pub struct GetVirtualBalanceCall {
        pub hyper: ::ethers::core::types::Address,
        pub token: ::ethers::core::types::Address,
        pub owners: ::std::vec::Vec<::ethers::core::types::Address>,
    }
    #[derive(Debug, Clone, PartialEq, Eq, ::ethers::contract::EthAbiType)]
    pub enum HelperHyperViewCalls {
        _GetBalance(_GetBalanceCall),
        _GetPool(_GetPoolCall),
        _GetPosition(_GetPositionCall),
        _GetReserve(_GetReserveCall),
        GetBalance(GetBalanceCall),
        GetBalanceSum(GetBalanceSumCall),
        GetCurve(GetCurveCall),
        GetMaxSwapLimit(GetMaxSwapLimitCall),
        GetPair(GetPairCall),
        GetPhysicalBalance(GetPhysicalBalanceCall),
        GetPool(GetPoolCall),
        GetPosition(GetPositionCall),
        GetPositionLiquiditySum(GetPositionLiquiditySumCall),
        GetReserve(GetReserveCall),
        GetState(GetStateCall),
        GetVirtualBalance(GetVirtualBalanceCall),
    }
    impl ::ethers::core::abi::AbiDecode for HelperHyperViewCalls {
        fn decode(
            data: impl AsRef<[u8]>,
        ) -> ::std::result::Result<Self, ::ethers::core::abi::AbiError> {
            if let Ok(decoded) =
                <_GetBalanceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HelperHyperViewCalls::_GetBalance(decoded));
            }
            if let Ok(decoded) =
                <_GetPoolCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HelperHyperViewCalls::_GetPool(decoded));
            }
            if let Ok(decoded) =
                <_GetPositionCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HelperHyperViewCalls::_GetPosition(decoded));
            }
            if let Ok(decoded) =
                <_GetReserveCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HelperHyperViewCalls::_GetReserve(decoded));
            }
            if let Ok(decoded) =
                <GetBalanceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HelperHyperViewCalls::GetBalance(decoded));
            }
            if let Ok(decoded) =
                <GetBalanceSumCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HelperHyperViewCalls::GetBalanceSum(decoded));
            }
            if let Ok(decoded) =
                <GetCurveCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HelperHyperViewCalls::GetCurve(decoded));
            }
            if let Ok(decoded) =
                <GetMaxSwapLimitCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HelperHyperViewCalls::GetMaxSwapLimit(decoded));
            }
            if let Ok(decoded) =
                <GetPairCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HelperHyperViewCalls::GetPair(decoded));
            }
            if let Ok(decoded) =
                <GetPhysicalBalanceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HelperHyperViewCalls::GetPhysicalBalance(decoded));
            }
            if let Ok(decoded) =
                <GetPoolCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HelperHyperViewCalls::GetPool(decoded));
            }
            if let Ok(decoded) =
                <GetPositionCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HelperHyperViewCalls::GetPosition(decoded));
            }
            if let Ok(decoded) =
                <GetPositionLiquiditySumCall as ::ethers::core::abi::AbiDecode>::decode(
                    data.as_ref(),
                )
            {
                return Ok(HelperHyperViewCalls::GetPositionLiquiditySum(decoded));
            }
            if let Ok(decoded) =
                <GetReserveCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HelperHyperViewCalls::GetReserve(decoded));
            }
            if let Ok(decoded) =
                <GetStateCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HelperHyperViewCalls::GetState(decoded));
            }
            if let Ok(decoded) =
                <GetVirtualBalanceCall as ::ethers::core::abi::AbiDecode>::decode(data.as_ref())
            {
                return Ok(HelperHyperViewCalls::GetVirtualBalance(decoded));
            }
            Err(::ethers::core::abi::Error::InvalidData.into())
        }
    }
    impl ::ethers::core::abi::AbiEncode for HelperHyperViewCalls {
        fn encode(self) -> Vec<u8> {
            match self {
                HelperHyperViewCalls::_GetBalance(element) => element.encode(),
                HelperHyperViewCalls::_GetPool(element) => element.encode(),
                HelperHyperViewCalls::_GetPosition(element) => element.encode(),
                HelperHyperViewCalls::_GetReserve(element) => element.encode(),
                HelperHyperViewCalls::GetBalance(element) => element.encode(),
                HelperHyperViewCalls::GetBalanceSum(element) => element.encode(),
                HelperHyperViewCalls::GetCurve(element) => element.encode(),
                HelperHyperViewCalls::GetMaxSwapLimit(element) => element.encode(),
                HelperHyperViewCalls::GetPair(element) => element.encode(),
                HelperHyperViewCalls::GetPhysicalBalance(element) => element.encode(),
                HelperHyperViewCalls::GetPool(element) => element.encode(),
                HelperHyperViewCalls::GetPosition(element) => element.encode(),
                HelperHyperViewCalls::GetPositionLiquiditySum(element) => element.encode(),
                HelperHyperViewCalls::GetReserve(element) => element.encode(),
                HelperHyperViewCalls::GetState(element) => element.encode(),
                HelperHyperViewCalls::GetVirtualBalance(element) => element.encode(),
            }
        }
    }
    impl ::std::fmt::Display for HelperHyperViewCalls {
        fn fmt(&self, f: &mut ::std::fmt::Formatter<'_>) -> ::std::fmt::Result {
            match self {
                HelperHyperViewCalls::_GetBalance(element) => element.fmt(f),
                HelperHyperViewCalls::_GetPool(element) => element.fmt(f),
                HelperHyperViewCalls::_GetPosition(element) => element.fmt(f),
                HelperHyperViewCalls::_GetReserve(element) => element.fmt(f),
                HelperHyperViewCalls::GetBalance(element) => element.fmt(f),
                HelperHyperViewCalls::GetBalanceSum(element) => element.fmt(f),
                HelperHyperViewCalls::GetCurve(element) => element.fmt(f),
                HelperHyperViewCalls::GetMaxSwapLimit(element) => element.fmt(f),
                HelperHyperViewCalls::GetPair(element) => element.fmt(f),
                HelperHyperViewCalls::GetPhysicalBalance(element) => element.fmt(f),
                HelperHyperViewCalls::GetPool(element) => element.fmt(f),
                HelperHyperViewCalls::GetPosition(element) => element.fmt(f),
                HelperHyperViewCalls::GetPositionLiquiditySum(element) => element.fmt(f),
                HelperHyperViewCalls::GetReserve(element) => element.fmt(f),
                HelperHyperViewCalls::GetState(element) => element.fmt(f),
                HelperHyperViewCalls::GetVirtualBalance(element) => element.fmt(f),
            }
        }
    }
    impl ::std::convert::From<_GetBalanceCall> for HelperHyperViewCalls {
        fn from(var: _GetBalanceCall) -> Self {
            HelperHyperViewCalls::_GetBalance(var)
        }
    }
    impl ::std::convert::From<_GetPoolCall> for HelperHyperViewCalls {
        fn from(var: _GetPoolCall) -> Self {
            HelperHyperViewCalls::_GetPool(var)
        }
    }
    impl ::std::convert::From<_GetPositionCall> for HelperHyperViewCalls {
        fn from(var: _GetPositionCall) -> Self {
            HelperHyperViewCalls::_GetPosition(var)
        }
    }
    impl ::std::convert::From<_GetReserveCall> for HelperHyperViewCalls {
        fn from(var: _GetReserveCall) -> Self {
            HelperHyperViewCalls::_GetReserve(var)
        }
    }
    impl ::std::convert::From<GetBalanceCall> for HelperHyperViewCalls {
        fn from(var: GetBalanceCall) -> Self {
            HelperHyperViewCalls::GetBalance(var)
        }
    }
    impl ::std::convert::From<GetBalanceSumCall> for HelperHyperViewCalls {
        fn from(var: GetBalanceSumCall) -> Self {
            HelperHyperViewCalls::GetBalanceSum(var)
        }
    }
    impl ::std::convert::From<GetCurveCall> for HelperHyperViewCalls {
        fn from(var: GetCurveCall) -> Self {
            HelperHyperViewCalls::GetCurve(var)
        }
    }
    impl ::std::convert::From<GetMaxSwapLimitCall> for HelperHyperViewCalls {
        fn from(var: GetMaxSwapLimitCall) -> Self {
            HelperHyperViewCalls::GetMaxSwapLimit(var)
        }
    }
    impl ::std::convert::From<GetPairCall> for HelperHyperViewCalls {
        fn from(var: GetPairCall) -> Self {
            HelperHyperViewCalls::GetPair(var)
        }
    }
    impl ::std::convert::From<GetPhysicalBalanceCall> for HelperHyperViewCalls {
        fn from(var: GetPhysicalBalanceCall) -> Self {
            HelperHyperViewCalls::GetPhysicalBalance(var)
        }
    }
    impl ::std::convert::From<GetPoolCall> for HelperHyperViewCalls {
        fn from(var: GetPoolCall) -> Self {
            HelperHyperViewCalls::GetPool(var)
        }
    }
    impl ::std::convert::From<GetPositionCall> for HelperHyperViewCalls {
        fn from(var: GetPositionCall) -> Self {
            HelperHyperViewCalls::GetPosition(var)
        }
    }
    impl ::std::convert::From<GetPositionLiquiditySumCall> for HelperHyperViewCalls {
        fn from(var: GetPositionLiquiditySumCall) -> Self {
            HelperHyperViewCalls::GetPositionLiquiditySum(var)
        }
    }
    impl ::std::convert::From<GetReserveCall> for HelperHyperViewCalls {
        fn from(var: GetReserveCall) -> Self {
            HelperHyperViewCalls::GetReserve(var)
        }
    }
    impl ::std::convert::From<GetStateCall> for HelperHyperViewCalls {
        fn from(var: GetStateCall) -> Self {
            HelperHyperViewCalls::GetState(var)
        }
    }
    impl ::std::convert::From<GetVirtualBalanceCall> for HelperHyperViewCalls {
        fn from(var: GetVirtualBalanceCall) -> Self {
            HelperHyperViewCalls::GetVirtualBalance(var)
        }
    }
    ///Container type for all return fields from the `_getBalance` function with signature `_getBalance(address,address,address)` and selector `0xcf7dee1f`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct _GetBalanceReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `_getPool` function with signature `_getPool(address,uint64)` and selector `0x09deb4d3`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct _GetPoolReturn(pub HyperPool);
    ///Container type for all return fields from the `_getPosition` function with signature `_getPosition(address,address,uint64)` and selector `0xdc723804`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct _GetPositionReturn(pub HyperPosition);
    ///Container type for all return fields from the `_getReserve` function with signature `_getReserve(address,address)` and selector `0x5a8be8b0`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct _GetReserveReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getBalance` function with signature `getBalance(address,address,address)` and selector `0xd6bd603c`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetBalanceReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getBalanceSum` function with signature `getBalanceSum(address,address,address[])` and selector `0xff314c0a`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetBalanceSumReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getCurve` function with signature `getCurve(address,uint64)` and selector `0xd83410b6`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetCurveReturn(pub HyperCurve);
    ///Container type for all return fields from the `getMaxSwapLimit` function with signature `getMaxSwapLimit(bool)` and selector `0xcee2aaf5`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetMaxSwapLimitReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getPair` function with signature `getPair(address,uint24)` and selector `0x7b135ad1`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetPairReturn(pub HyperPair);
    ///Container type for all return fields from the `getPhysicalBalance` function with signature `getPhysicalBalance(address,address)` and selector `0x634e05e0`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetPhysicalBalanceReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getPool` function with signature `getPool(address,uint64)` and selector `0x273c329f`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetPoolReturn(pub HyperPool);
    ///Container type for all return fields from the `getPosition` function with signature `getPosition(address,address,uint64)` and selector `0xdd05e299`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetPositionReturn(pub HyperPosition);
    ///Container type for all return fields from the `getPositionLiquiditySum` function with signature `getPositionLiquiditySum(address,uint64,address[])` and selector `0x8828200d`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetPositionLiquiditySumReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getReserve` function with signature `getReserve(address,address)` and selector `0xcbc3ab53`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetReserveReturn(pub ::ethers::core::types::U256);
    ///Container type for all return fields from the `getState` function with signature `getState(address,uint64,address,address[])` and selector `0xf3140b1e`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetStateReturn(pub HyperState);
    ///Container type for all return fields from the `getVirtualBalance` function with signature `getVirtualBalance(address,address,address[])` and selector `0x6dce537d`
    #[derive(
        Clone,
        Debug,
        Eq,
        PartialEq,
        ::ethers::contract::EthAbiType,
        ::ethers::contract::EthAbiCodec,
        Default,
    )]
    pub struct GetVirtualBalanceReturn(pub ::ethers::core::types::U256);
}
