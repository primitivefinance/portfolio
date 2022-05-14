import { ethers } from 'hardhat'
import { BigNumberish, Signer } from 'ethers'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { TestERC20 } from '../../typechain-types/test/TestERC20'
import { TestCompiler } from '../../typechain-types/test/TestCompiler'
import { TestEnigmaVirtualMachine } from '../../typechain-types/test/EnigmaVirtualMachine.t.sol/TestEnigmaVirtualMachine'
import { TestHyperSwap } from '../../typechain-types/test/HyperSwap.t.sol/TestHyperSwap'

export async function setupPool(
  contract: TestCompiler,
  poolId: number,
  tokenBase: string,
  tokenQuote: string,
  internalBase: BigNumberish,
  internalQuote: BigNumberish,
  internalLiquidity: BigNumberish
) {
  await contract.setTokens(poolId, tokenBase, tokenQuote)
  await contract.setLiquidity(poolId, internalBase, internalQuote, internalLiquidity)
  await contract.setTimestamp(100)
}

export async function mintAndApprove(token: TestERC20, user: string, spender: string, wad: BigNumberish) {
  await token.mint(user, wad)
  await token.approve(spender, ethers.constants.MaxUint256)
}

export interface Contracts {
  main: TestCompiler
  base: TestERC20
  quote: TestERC20
}

export interface Context {
  signers: Signer[]
  signer: Signer
  user: string
}

export async function deployTestEnigma(hre: HardhatRuntimeEnvironment): Promise<TestEnigmaVirtualMachine> {
  return (await (await hre.ethers.getContractFactory('TestEnigmaVirtualMachine')).deploy()) as TestEnigmaVirtualMachine
}

export async function deployTestHyperSwap(hre: HardhatRuntimeEnvironment): Promise<TestHyperSwap> {
  return (await (await hre.ethers.getContractFactory('TestHyperSwap')).deploy()) as TestHyperSwap
}

export async function contextFixture(hre: HardhatRuntimeEnvironment): Promise<Context> {
  const signers = await hre.ethers.getSigners()
  const signer = signers[0]
  const user = await signer.getAddress()
  return { signers, signer, user }
}

export async function fixture(hre: HardhatRuntimeEnvironment): Promise<Contracts> {
  const mainFac = await hre.ethers.getContractFactory('TestCompiler')
  const main = (await mainFac.deploy()) as TestCompiler
  await main.deployed()
  const base = (await (await hre.ethers.getContractFactory('TestERC20')).deploy('base', 'base', 18)) as TestERC20
  const quote = (await (await hre.ethers.getContractFactory('TestERC20')).deploy('quote', 'quote', 18)) as TestERC20
  await base.deployed()
  await quote.deployed()
  return { main, base, quote }
}
