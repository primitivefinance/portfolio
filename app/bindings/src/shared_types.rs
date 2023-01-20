///`HyperCurve(int24,uint16,uint16,uint16,uint16,uint16,uint32)`
#[derive(
    Clone,
    Debug,
    Default,
    Eq,
    PartialEq,
    ::ethers::contract::EthAbiType,
    ::ethers::contract::EthAbiCodec,
)]
pub struct HyperCurve {
    pub max_tick: i32,
    pub jit: u16,
    pub fee: u16,
    pub duration: u16,
    pub volatility: u16,
    pub priority_fee: u16,
    pub created_at: u32,
}
///`HyperPair(address,uint8,address,uint8)`
#[derive(
    Clone,
    Debug,
    Default,
    Eq,
    PartialEq,
    ::ethers::contract::EthAbiType,
    ::ethers::contract::EthAbiCodec,
)]
pub struct HyperPair {
    pub token_asset: ::ethers::core::types::Address,
    pub decimals_asset: u8,
    pub token_quote: ::ethers::core::types::Address,
    pub decimals_quote: u8,
}
///`HyperPosition(uint128,uint128,uint256,uint256,uint256,uint256,uint256,uint256,uint128,uint128,uint128)`
#[derive(
    Clone,
    Debug,
    Default,
    Eq,
    PartialEq,
    ::ethers::contract::EthAbiType,
    ::ethers::contract::EthAbiCodec,
)]
pub struct HyperPosition {
    pub free_liquidity: u128,
    pub staked_liquidity: u128,
    pub last_timestamp: ::ethers::core::types::U256,
    pub stake_timestamp: ::ethers::core::types::U256,
    pub unstake_timestamp: ::ethers::core::types::U256,
    pub fee_growth_reward_last: ::ethers::core::types::U256,
    pub fee_growth_asset_last: ::ethers::core::types::U256,
    pub fee_growth_quote_last: ::ethers::core::types::U256,
    pub tokens_owed_asset: u128,
    pub tokens_owed_quote: u128,
    pub tokens_owed_reward: u128,
}
///`HyperState(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)`
#[derive(
    Clone,
    Debug,
    Default,
    Eq,
    PartialEq,
    ::ethers::contract::EthAbiType,
    ::ethers::contract::EthAbiCodec,
)]
pub struct HyperState {
    pub reserve_asset: ::ethers::core::types::U256,
    pub reserve_quote: ::ethers::core::types::U256,
    pub physical_balance_asset: ::ethers::core::types::U256,
    pub physical_balance_quote: ::ethers::core::types::U256,
    pub total_balance_asset: ::ethers::core::types::U256,
    pub total_balance_quote: ::ethers::core::types::U256,
    pub total_position_liquidity: ::ethers::core::types::U256,
    pub caller_position_liquidity: ::ethers::core::types::U256,
    pub total_pool_liquidity: ::ethers::core::types::U256,
    pub fee_growth_asset_pool: ::ethers::core::types::U256,
    pub fee_growth_quote_pool: ::ethers::core::types::U256,
    pub fee_growth_asset_position: ::ethers::core::types::U256,
    pub fee_growth_quote_position: ::ethers::core::types::U256,
}
///`HyperPool(int24,uint32,address,uint256,uint256,uint256,uint128,uint128,uint128,int128,(int24,uint16,uint16,uint16,uint16,uint16,uint32),(address,uint8,address,uint8))`
#[derive(
    Clone,
    Debug,
    Default,
    Eq,
    PartialEq,
    ::ethers::contract::EthAbiType,
    ::ethers::contract::EthAbiCodec,
)]
pub struct HyperPool {
    pub last_tick: i32,
    pub last_timestamp: u32,
    pub controller: ::ethers::core::types::Address,
    pub fee_growth_global_reward: ::ethers::core::types::U256,
    pub fee_growth_global_asset: ::ethers::core::types::U256,
    pub fee_growth_global_quote: ::ethers::core::types::U256,
    pub last_price: u128,
    pub liquidity: u128,
    pub staked_liquidity: u128,
    pub staked_liquidity_delta: i128,
    pub params: HyperCurve,
    pub pair: HyperPair,
}
