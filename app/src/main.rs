use std::sync::Arc;
// use tokio::*;
use eyre::Result;
// use ethers::providers::{Http, Provider};
use ethers::{
    abi::Address,
    prelude::*,
    providers::{Middleware, Provider},
};
use foundry_contracts::hyper::Hyper;

// Need to get the correct address for the contract
const FACTORY: &str = "0x1F98431c8aD98523631AE4a59f267346ea31F984";
#[tokio::main]
async fn main() -> Result<()> {
    let provider: std::sync::Arc<Provider<Http>> = get_provider().await;
    let hyper_address = FACTORY.parse::<Address>().unwrap();
    let hyper = Hyper::new(hyper_address, provider.clone());
    let block = provider.get_block(0).await?;
    println!("block: {:#?}", block.unwrap());
    println!("hyper: {hyper:#?}");
    Ok(())
}

pub async fn get_provider() -> Arc<Provider<Http>> {
    Arc::new(
        Provider::try_from("https://eth-mainnet.g.alchemy.com/v2/I93POQk49QE9O-NuOz7nj7sbiluW76it")
            .unwrap(),
    )
}
