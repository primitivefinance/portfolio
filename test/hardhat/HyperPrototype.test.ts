import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { assert, expect } from 'chai'
import hre, { ethers } from 'hardhat'
import { Contract } from 'ethers'
import { parseEther } from 'ethers/lib/utils'

import HyperSDK from '../../compiler/sdk'
import * as instructions from '../../compiler/instructions'

import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'

// Default parameters for testing.
const params = {
  strike: parseEther('10'),
  volatility: 1e4,
  duration: 365,
  maturity: 31556953,
  fee: 1e2,
  priorityFee: 1e1,
  jit: 4,
  price: parseEther('10'),
  liquidity: parseEther('10'),
  maxTick: 23027, // ~$10, rounded up
}

/**
 * note: If tokens are not deployed, transactions will revert without returning data.
 *
 * @reverts With "NonExistentPool" error, if the `timestamp` public state variable of TestDecompiler is not set from zero.
 */
describe('HyperPrototype', function () {
  let sdk: HyperSDK
  let deployer: SignerWithAddress, signers: SignerWithAddress[]
  let tokens: [Contract, Contract]
  let weth: Contract
  let hyper: Contract

  async function deployFixture() {
    let [signer] = await hre.ethers.getSigners()
    let _sdk = new HyperSDK(
      signer,
      async (signer) => await hre.ethers.getContractFactory('TestHyperTime'),
      async (signer) => await hre.ethers.getContractFactory('HyperForwarderHelper')
    )

    let fac = await hre.ethers.getContractFactory('WETH')
    let _weth = await fac.deploy()
    await _weth.deployed()
    let _hyper = await _sdk.deploy(_weth.address) // Deploys Hyper protocol.

    return { sdk: _sdk, weth: _weth, hyper: _hyper }
  }

  // Setup
  before(async function () {
    signers = await ethers.getSigners()
    deployer = signers[0]
  })

  // Global context for every test.
  beforeEach(async function () {
    ;({ sdk, weth, hyper: this.hyper } = await loadFixture(deployFixture))
    assert(typeof sdk.instance != 'undefined', 'Hyper contract not there, did it get deployed?')
    assert(typeof sdk.forwarder != 'undefined', 'Forwarder contract not there, did it get deployed?')

    this.caller = await sdk.forwarder.caller()

    // --- Prerequisites for testing --- //

    // - IMPORTANT FOR TESTING - //
    // This internally sets the timestamp for the contract's _blockTimestamp() function.
    await this.hyper.set(1)

    // Deploys tokens.
    const factory = await hre.ethers.getContractFactory('TestERC20')
    tokens = await Promise.all([factory.deploy('Asset', 'AST', 18), factory.deploy('Quote', 'QT', 18)])
    this.tokens = tokens

    // Mints tokens to the forwarder's caller contract.
    await Promise.all([
      this.tokens[0].mint(this.caller, parseEther('100')),
      this.tokens[1].mint(this.caller, parseEther('100')),
    ])

    // Forwarder calls the caller's function to approve the token for the target address to pull from it
    await Promise.all([
      sdk.forwarder.approve(this.tokens[0].address, sdk.instance?.address),
      sdk.forwarder.approve(this.tokens[1].address, sdk.instance?.address),
    ])
  })

  describe('Create', function () {
    it('Creates a pair in the createPool call', async function () {
      const call = sdk.createPool(
        tokens[0].address,
        tokens[1].address,
        deployer.address,
        params.priorityFee,
        params.fee,
        params.volatility,
        params.duration,
        params.jit,
        params.maxTick,
        params.price
      )

      await expect(call)
        .to.emit(sdk.forwarder, 'Success')
        .to.emit(sdk.instance, 'CreatePair')
        .withArgs(1, tokens[0].address, tokens[1].address, await tokens[0].decimals(), await tokens[1].decimals())
    })

    it('Creates a pool in the createPool call', async function () {
      const call = sdk.createPool(
        tokens[0].address,
        tokens[1].address,
        deployer.address,
        params.priorityFee,
        params.fee,
        params.volatility,
        params.duration,
        params.jit,
        params.maxTick,
        params.price
      )

      await expect(call)
        .to.emit(sdk.forwarder, 'Success')
        .to.emit(sdk.instance, 'CreatePair')
        .to.emit(sdk.instance, 'CreatePool')
        .withArgs(0x0000010100000001, true, tokens[0].address, tokens[1].address, params.price)
    })

    it('Creates a pair directly', async function () {
      const { hex: data } = instructions.encodeCreatePair(tokens[0].address, tokens[1].address)

      await expect(deployer.sendTransaction({ to: sdk.instance?.address, data, value: BigInt(0) }))
        .to.emit(sdk.instance, 'CreatePair')
        .withArgs(1, tokens[0].address, tokens[1].address, await tokens[0].decimals(), await tokens[1].decimals())
    })

    it('Creates a pair with jump process', async function () {
      const { bytes: data, hex: instructionData } = instructions.encodeCreatePair(tokens[0].address, tokens[1].address)
      const { hex: jumpData } = instructions.encodeJumpInstruction([data])
      console.log(instructionData)
      console.log(jumpData)
      await expect(deployer.sendTransaction({ to: sdk.instance?.address, data: jumpData, value: BigInt(0) }))
        .to.emit(sdk.instance, 'CreatePair')
        .withArgs(1, tokens[0].address, tokens[1].address, await tokens[0].decimals(), await tokens[1].decimals())
    })
  })

  describe('Liquidity', function () {
    let poolId: number

    beforeEach(async function () {
      const call = sdk.createPool(
        tokens[0].address,
        tokens[1].address,
        deployer.address,
        params.priorityFee,
        params.fee,
        params.volatility,
        params.duration,
        params.jit,
        params.maxTick,
        params.price
      )

      await call

      poolId = await sdk?.forwarder?.getPoolId(1, true, 1)

      // mint tokens and approve hyper
    })

    it('adds liquidity', async function () {
      const call = sdk.allocate(poolId, params.liquidity)
      await expect(call).to.emit(sdk.instance, 'Allocate')
      expect(await this.tokens[0].balanceOf(sdk.instance?.address)).to.be.greaterThan(0)
      expect(await this.tokens[1].balanceOf(sdk.instance?.address)).to.be.greaterThan(0)
    })

    it('removes liquidity after adding it', async function () {
      let call = sdk.allocate(poolId, params.liquidity)
      await call

      await this.hyper.set(5)
      call = sdk.unallocate(false, poolId, params.liquidity)
      await expect(call).to.emit(sdk.instance, 'Unallocate')
    })
  })

  describe('Swap', function () {
    let poolId: number
    beforeEach(async function () {
      const call = sdk.createPool(
        tokens[0].address,
        tokens[1].address,
        deployer.address,
        params.priorityFee,
        params.fee,
        params.volatility,
        params.duration,
        params.jit,
        params.maxTick,
        params.price
      )

      await call

      poolId = await sdk?.forwarder?.getPoolId(1, true, 1)

      // mint tokens and approve hyper
    })

    it('swaps asset to quote', async function () {
      let call = sdk.allocate(poolId, params.liquidity)
      await call

      call = sdk.swapAssetToQuote(false, poolId, parseEther('1'), ethers.constants.MaxUint256)
      await expect(call).to.emit(sdk.instance, 'Swap')
    })
  })
})
