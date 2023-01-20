use std::{env, sync::Arc};
// use tokio::*;
use eyre::Result;
// use ethers::providers::{Http, Provider};
use ethers::{abi::Address, prelude::*, providers::Provider};
use bindings::*;

// Need to get the correct address for the contract
const FACTORY: &str = "0x1F98431c8aD98523631AE4a59f267346ea31F984";
#[tokio::main]
async fn main() -> Result<()> {
    let provider = match env::var_os("PROVIDER") {
        Some(v) => Arc::new(Provider::<Http>::try_from(v.into_string().unwrap())?),
        None => get_provider().await,
    };
    let hyper_address = FACTORY.parse::<Address>().unwrap();
    let hyper = bindings::hyper::Hyper::new(hyper_address, provider);
    Ok(())

}

pub async fn get_provider() -> Arc<Provider<Http>> {
    Arc::new(
        Provider::try_from("https://eth-mainnet.g.alchemy.com/v2/I93POQk49QE9O-NuOz7nj7sbiluW76it")
            .unwrap(),
    )
}