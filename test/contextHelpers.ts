import { BigNumberish, Signer } from 'ethers'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { TestPrototypeHyper } from '../typechain-types'
import { TestERC20 } from '../typechain-types/test/TestERC20'
import { TestHyperLiquidity } from '../typechain-types/test/TestHyperLiquidity'
import { ethers } from 'hardhat'

export async function setupPool(
  contract: TestHyperLiquidity,
  poolId: number,
  tokenBase: string,
  tokenQuote: string,
  internalBase: BigNumberish,
  internalQuote: BigNumberish,
  internalLiquidity: BigNumberish
) {
  await contract.setTokens(poolId, tokenBase, tokenQuote)
  await contract.setLiquidity(poolId, internalBase, internalQuote, internalLiquidity)
}

export async function mintAndApprove(token: TestERC20, user: string, spender: string, wad: BigNumberish) {
  await token.mint(user, wad)
  await token.approve(spender, ethers.constants.MaxUint256)
}

export interface Contracts {
  main: TestPrototypeHyper
  pool: TestHyperLiquidity
  base: TestERC20
  quote: TestERC20
}

export interface Context {
  signers: Signer[]
  signer: Signer
  user: string
}

export async function contextFixture(hre: HardhatRuntimeEnvironment): Promise<Context> {
  const signers = await hre.ethers.getSigners()
  const signer = signers[0]
  const user = await signer.getAddress()
  return { signers, signer, user }
}

export async function fixture(hre: HardhatRuntimeEnvironment): Promise<Contracts> {
  const mainFac = await hre.ethers.getContractFactory('TestPrototypeHyper')
  const main = await mainFac.deploy()
  await main.deployed()
  const poolFac = await hre.ethers.getContractFactory('TestHyperLiquidity')
  const pool = await poolFac.deploy()
  await pool.deployed()
  const base = await (await hre.ethers.getContractFactory('TestERC20')).deploy('base', 'base', 18)
  const quote = await (await hre.ethers.getContractFactory('TestERC20')).deploy('quote', 'quote', 18)
  await base.deployed()
  await quote.deployed()
  return { main, pool, base, quote }
}
